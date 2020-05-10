<#

    Script to count files and check file hashes for a Sample set of files

#>
param(
    [Parameter(Mandatory=$true)]
    $src,
    [Parameter(Mandatory=$true)]
    $dst,
    $SampleSize = 250,
    $outFile = ".\check-files-exceptions.csv"
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

$ErrorLog = ".\Check-Files-Error.log"

# Strip trailing '\' if it is passed along
if($src.EndsWith("\")){ $src = $src.Substring(0,$src.Length -1) }
if($dst.EndsWith("\")){ $dst = $dst.Substring(0,$dst.Length -1) }


write-host "Gathering Source Paths..." -ForegroundColor Yellow
$srcPaths = gci $src -Recurse -ErrorVariable +ErrVar -ErrorAction SilentlyContinue

write-host "Gathering Destination Paths..." -ForegroundColor Yellow
$dstPaths = gci $dst -Recurse -ErrorVariable +ErrVar -ErrorAction SilentlyContinue

if($ErrVar.Count -ne 0){
    $ErrorMsg = "One or more errors occurred, these could be access privilege related, please check $ErrorLog"
    write-host $ErrorMsg -fore Red
    write-output $errVar | out-file $ErrorLog
}

# Check file counts
if($srcPaths.Count -ne $dstPaths.Count){
    write-host "Number of Files in Source and Destination do not match!" -ForegroundColor Red
    write-host "Source        : $($srcPaths.Count)" -ForegroundColor Red
    write-host "Destination   : $($dstPaths.Count)" -ForegroundColor Red
    $Diff = $srcPaths.Count - $dstPaths.Count
    write-host "Missing files : $Diff" -ForegroundColor Red
    Exit
} else {
    write-host "File counts of Source and Destination match!" -ForegroundColor Green
}

# Check file Hashes

$LogObj = @()

$SampleSet = $srcPaths | where{ $_.attributes -ne 'Directory'} | Get-Random -Count $SampleSize

$c = 1
foreach($file in $SampleSet){
    Write-Progress  -Activity "Processing $($file.FullName)" -PercentComplete (100 * ($c / $SampleSet.Count)) -Status "Comparing file hashes of $($SampleSet.Count) paths..."
    $srcFile = $file.FullName
    $srcTemp = (.\fciv -md5 $srcfile)    #(Get-FileHash $srcFile).hash
	$srcTemp = $srcTemp[$srcTemp.Count-1] -match '(^[a-z0-9]+)\s.*'
	$srcHash = $Matches[1]

    $dstFile = $file.FullName.Replace($src,$dst)
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
$OutCsv = $LogObj | where{$_.status -ne "OK"} 
$OutCsv
if($Null -ne $OutCsv){
    write-host "Some exceptions found, please check $OutFile" -ForegroundColor Red
    $OutCsv| Export-Csv -notypeinformation -path $OutFile
} else {
    write-host "No exception found, the md5 checksum of all $sampleSize sampled files matched." -ForegroundColor Green
}



.\acl-check.ps1 -src $src -dst $dst -SampleSize $SampleSize

