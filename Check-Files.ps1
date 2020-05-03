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

    $tempObj = [PSCustomObject]@{
        Source = $Source
        Status = $Status
    }
    Return $tempObj
}

$ErrorLog = ".\Check-Files-Error.log"
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

write-host "Gathering Destination Paths..." -ForegroundColor Yellow
$dstPaths = gci $dst -Recurse -ErrorVariable +ErrVar -ErrorAction SilentlyContinue
if($null -ne $errVar){
    $ErrorMsg = "One or more errors occurred, these could be access privilege related, please check $ErrorLog"
    write-host $ErrorMsg -fore Red
    write-output $errVar | out-file $ErrorLog -Append
}

# Check file counts
if($srcPaths.Count -ne $dstPaths.Count){
    write-host "Number of Files in Source and Destination does not match!" -ForegroundColor Red
    write-host "Source      : $($srcPaths.Count)" -ForegroundColor Red
    write-host "Destination : $($dstPaths.Count)" -ForegroundColor Red
} else {
    write-host "File counts of Source and Destination match!" -ForegroundColor Green
}


# Check file Hashes 
$LogObj = @()
$SampleSet = $srcPaths | Get-Random -Count $SampleSize
foreach($file in $SampleSet){
    $srcFile = $file.FullName
    $srcHash = (Get-FileHash $srcFile).hash
    #write-host "Source Path: $srcFile" -fore Cyan

    $dstFile = $file.FullName.Replace($src,$dst)
    #write-host "Dest Path:   $dstFile" -fore Cyan

    $dstHash = (Get-FileHash $dstFile).hash
    if ($srcHash -ne $dstHash){
        #write-host "The hash of the source file $($file.FullName) did not match the destination file hash!" -fore Red
        $LogObj += AddToLog -Source $file.FullName -Status "NOK"
    } else {
        #write-host "The hash of the source file $($file.FullName) matched the destination file hash." -fore Green
        $LogObj += AddToLog -Source $file.FullName -Status "OK"
    }
}

# Output Exceptions if there are any
$OutCsv = $LogObj | where status -ne "OK" 
if($Null -ne $OutCsv){
    write-host "Some exceptions found, please check $OutFile" -ForegroundColor Red
    $OutCsv| Export-Csv -notypeinformation -path $OutFile
} else {
    write-host "No exception found, All SHA256 hashed matched." -ForegroundColor Green
}

