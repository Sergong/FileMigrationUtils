<#

    Build a CSV file for ACL-Check and Hash-Check on the Source....
    This minimizes the chances of getting path too long errors
    Run on the Source

#>
param(
    [Parameter(Mandatory=$true)]
    $src,
    $SampleSize = 1000,
    $outFile = ".\check-input.csv"
)
#######   Start Functions ########
function Export-UTF8CSV {
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [psobject]
        $inputObj,
        [Parameter(Mandatory=$true)]
        $Path
    )
    # Export Header
    $fields = $inputObj | Get-Member | where{$_.MemberType -eq "Property" -or $_.MemberType -eq "NoteProperty"}
    $newLine = ""
    foreach($field in $fields){
        $NewLine += "`"$($field.Name)`","
    }
    $newLine = $newLine.Substring(0,$newLine.Length-1)
    $newLine | Out-File -FilePath $Path -Encoding utf8

    # Export Fields
    foreach($line in $inputObj){
        $newLine = ""
        foreach($field in $fields){
            $NewLine += "`"$($line.$($field.Name))`","
        }
        $newLine = $newLine.Substring(0,$newLine.Length-1)
        $newLine | Out-File -FilePath $Path -Encoding utf8 -Append
    }
}
#######   End Functions  ##########


$ErrorLog = ".\Build-Csv-Error.log"
# Strip trailing '\' if it is passed along
if($src.EndsWith("\")){ $src = $src.Substring(0,$src.Length -1) }

write-host "Gathering Source Paths..." -ForegroundColor Yellow
$srcFiles = gci $src -Recurse -ErrorVariable +ErrVar -ErrorAction SilentlyContinue
if($null -ne $errVar){
    $ErrorMsg = "One or more errors occurred, these could be access privilege related, please check $ErrorLog"
    write-host $ErrorMsg -fore Red
    write-output $errVar | out-file $ErrorLog
}


$csv = New-Object System.Collections.ArrayList
$c = 1
$SampleSet = $srcFiles | Where-Object{ $_.attributes -ne 'Directory'} | Get-Random -Count $SampleSize
$Tot = $SampleSet.Count
$SampleSet | %{
    Write-Progress  -Activity "Processing $($_.FullName)" -PercentComplete (100 * ($c / $Tot)) -Status "Building source path file..."
    $srcFile = $_.FullName
    $srcTemp = (.\fciv -md5 $srcfile)    #(Get-FileHash $srcFile).hash
	$srcTemp = $srcTemp[$srcTemp.Count-1] -match '(^[a-z0-9]+)\s.*'
	$srcHash = $Matches[1]
    $record = New-Object -TypeName PSObject -Property @{
        "FullName" = $_.FullName
        "ACL" = $(Get-Acl -Path $_.FullName -ea Stop).Sddl
        "Hash" = $srcHash
    }
    [void]$csv.Add($record)
    $c++
}
write-host "Exporting to $outFile..." -ForegroundColor Yellow
#$csv | Export-Csv -NoTypeInformation -Path $outFile # Doesn't work with extended character set...

# write UTF8 CSV file
# write header out
Export-UTF8CSV -Path $outFile -inputObj $csv
