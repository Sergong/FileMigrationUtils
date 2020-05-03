<#

    Build a CSV file for ACL-Check

#>
param(
    [Parameter(Mandatory=$true)]
    $src,
    [Parameter(Mandatory=$true)]
    $dst,
    $outFile = ".\acl-check-input.csv"
)
$ErrorLog = ".\Build-Csv-Error.log"
# Strip trailing '\' if it is passed along
if($src.Substring($src.Length -1) -eq "\"){
    $src = $src.Substring(0,$src.Length -1)
}
if($dst.Substring($dst.Length -1) -eq "\"){
    $dst = $dst.Substring(0,$dst.Length -1)
}

write-host "Gathering Source Paths..." -ForegroundColor Yellow
$srcPaths = gci $src -Recurse -ErrorVariable +ErrVar -ErrorAction SilentlyContinue
if($null -ne $errVar){
    $ErrorMsg = "One or more errors occurred, these could be access privilege related, please check $ErrorLog"
    write-host $ErrorMsg -fore Red
    write-output $errVar | out-file $ErrorLog
}

$Tot = $srcPaths.Count
$csv = @()
$c = 1
$srcPaths | %{
    Write-Progress  -Activity "Processing $($_.FullName)" -PercentComplete (100 * ($c / $Tot)) -Status "Creating desitnation paths..."
    $record = [PSCustomObject]@{
        Source = $_.FullName
        Destination = $_.FullName.Replace($src,$dst)
    }
    $csv += $record
    $c++
}
write-host "Exporting to $outFile..." -ForegroundColor Yellow
$csv | Export-Csv -NoTypeInformation -Path $outFile
