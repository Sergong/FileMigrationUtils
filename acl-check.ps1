<#

    Script to test ACLs of directory paths to make sure the source is the same as the destination
    Run on the destination

#>
param(
    [Parameter(Mandatory=$false)]
    $InputCSV =".\check-input.csv",
    $resultFile = ".\acl-exceptions.csv",
    $ErrorLog = ".\Acl-Check-Error.log"
)

Function AddToLog {
    param (
        $Source,
        $Status
    )

    $tempObj = "" | select Source, Status
    $tempObj.Source = $Source
    $tempObj.Status = $Status

    Return $tempObj
}

$srcFiles = Import-Csv -Path $InputCSV


$LogObj = @()
$Tot = $srcFiles.Count

# Iterate through the Set
$c = 1
Foreach($srcFile in $srcFiles){
    $Source = $srcFile.FullName
    Write-Progress -Activity "Processing $Source" -PercentComplete (100 * ($c / $Tot)) -Status "Comparing $Tot Source and Destination path ACLs"
    Try {
        $orgSddl = $srcFile.ACL
        $destSddl = (Get-Acl -Path $Source -ea Stop).Sddl
        if( $orgSddl -eq $destSddl){
            $LogObj += AddToLog -Source $Source -Status "OK"
        } elseif ($null -eq $destSddl){
            $LogObj += AddToLog -Source $Source -Status "Not Found"
        } elseif ($orgSddl -ne $destSddl){
            $LogObj += AddToLog -Source $Source -Status "ACL different"
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
$OutCsv = $LogObj | where{$_.status -ne "OK"}
if($Null -ne $OutCsv){
    write-host "Some exceptions found, please check $resultFile" -ForegroundColor Red
    $OutCsv | Export-Csv -notypeinformation -path $resultFile
} else {
    write-host "No exception found, the ACLs of all $sampleSize sampled files matched." -ForegroundColor Green
}