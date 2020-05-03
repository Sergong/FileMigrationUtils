<#

    Script to test ACLs of directory paths to make sure the source is the same as the destination

#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path -Path $_})]
    $src,
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path -Path $_})]
    $dst,
    $resultFile = ".\acl-exceptions.csv",
    $SampleSize = 100,
    $ErrorLog = ".\Acl-Check-Error.log"
)

Function AddToLog {
    param (
        $Source,
        $Status
    )

    $tempObj = [PSCustomObject]@{
        Source = $Source
        Status = $Status
    }
    Return $tempObj
}
$errVar = ""
# strip trailing \
if($src.EndsWith("\")){ $src = $src.Substring(0,$src.Length -1) }

$srcPaths = gci $src -Recurse -ErrorVariable +ErrVar -ErrorAction SilentlyContinue
if($null -ne $errVar){
    $ErrorMsg = "One or more errors occurred, these could be access privilege related, please check $ErrorLog"
    write-host $ErrorMsg -fore Red
    write-output $errVar | out-file $ErrorLog
}

$LogObj = @()
$Tot = $srcPaths.Count

if($SampleSize -gt $Tot){
    write-host "SampleSize is larger than the total nr of entries in $resultFile. Setting it to $Tot."
    $SampleSet = $srcPaths
    $SampleSize = $Tot
} else {
    # Build a Sample Set 
    $SampleSet = $srcPaths | Get-Random -Count $SampleSize
}

# Iterate through the Set
$c = 1
$SampleSet | %{
    Write-Progress -Activity "Processing $($_.FullName)" -PercentComplete (100 * ($c / $SampleSize)) -Status "Comparing $SampleSize Source and Destination path ACLs"
    $Source = $_.FullName
    $Destination = $_.FullName.Replace($src,$dst)
    Try {
        $orgACL = get-ACL -path $Source -ea Stop
        $destACL = Get-Acl -Path $Destination -ea Stop
        if( $orgACL.Sddl -eq $destACL.Sddl){
            $LogObj += AddToLog -Source $_.source -Status "OK"
        } elseif ($null -eq $destACL){
            $LogObj += AddToLog -Source $_.source -Status "Not Found"
        } elseif ($orgACL.Sddl -ne $destACL.Sddl){
            $LogObj += AddToLog -Source $_.source -Status "ACL different"
        }
    }
    Catch{
        $ErrorMsg = @"

An ACL Check Error occurred: $($_.Exception.Message)
With File: $Source
"@
        Write-Host "$ErrorMsg" -ForegroundColor Red
        $ErrorMsg | Out-File $ErrorLog -Append
    }
    $c++
}

# Output Exceptions if there are any
$OutCsv = $LogObj | where status -ne "OK" 
if($Null -ne $OutCsv){
    write-host "Some exceptions found, please check $resultFile" -ForegroundColor Red
    $OutCsv | Export-Csv -notypeinformation -path $resultFile
} else {
    write-host "No exception found, the SHA256 checksum of all $sampleSize sampled files matched." -ForegroundColor Green
}
