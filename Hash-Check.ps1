<#

    Script to count files and check file hashes for a Sample set of files
    Run on the destination

#>
param(
    [Parameter(Mandatory=$false)]
    $InputCSV =".\check-input.csv",
    $outFile = ".\hash-files-exceptions.csv"
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

# Check file Hashes

$LogObj = @()

$SampleSet = Import-Csv -Path $InputCSV

$c = 1
foreach($file in $SampleSet){
    Write-Progress  -Activity "Processing $($file.FullName)" -PercentComplete (100 * ($c / $SampleSet.Count)) -Status "Comparing file hashes of $($SampleSet.Count) paths..."
	$srcHash = $file.Hash

    $dstFile = $file.FullName
    $dstTemp = (.\fciv -md5 $dstFile) # (Get-FileHash $dstFile).hash
	$dstTemp = $dstTemp[$dstTemp.Count-1] -match '(^[a-z0-9]+)\s.*'
	$dstHash = $Matches[1]


    if ($srcHash -ne $dstHash){
        $LogObj += AddToLog -Source $file.FullName -Status "NOK"
    } else {
        $LogObj += AddToLog -Source $file.FullName -Status "OK"
    }
    $c++
}

# Output Exceptions if there are any
$OutCsv = $LogObj | Where-Object{$_.status -ne "OK"}
$OutCsv
if($Null -ne $OutCsv){
    write-host "Some exceptions found, please check $OutFile" -ForegroundColor Red
    $OutCsv| Export-Csv -notypeinformation -path $OutFile
} else {
    write-host "No exception found, the md5 checksum of all $($SampleSet.Count) sampled files matched." -ForegroundColor Green
}

