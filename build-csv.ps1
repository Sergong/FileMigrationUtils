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

$Tot = $srcPaths.Count
$csv = [System.Collections.ArrayList]@()
$c = 1
$SampleSet = $srcFiles | Where-Object{ $_.attributes -ne 'Directory'} | Get-Random -Count $SampleSize
$SampleSet | %{
    Write-Progress  -Activity "Processing $($_.FullName)" -PercentComplete (100 * ($c / $Tot)) -Status "Creating desitnation paths..."
    $srcFile = $file.FullName
    $srcTemp = (.\fciv -md5 $srcfile)    #(Get-FileHash $srcFile).hash
	$srcTemp = $srcTemp[$srcTemp.Count-1] -match '(^[a-z0-9]+)\s.*'
	$srcHash = $Matches[1]
    $record = [PSCustomObject]@{
        FullName = $_.FullName
        ACL = $(Get-Acl -Path $_.FullName -ea Stop).Sddl
        Hash = $srcHash
    }
    $null = $csv.Add($record)
    $c++
}
write-host "Exporting to $outFile..." -ForegroundColor Yellow
$csv | Export-Csv -NoTypeInformation -Path $outFile
