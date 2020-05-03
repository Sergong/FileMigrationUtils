#Requires -Version 4
<#

    More efficient Text Processing of Robocopy logs

#>
param( 
    [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})][String[]]$RoboLog
)
$SearchPattern = '[0-9] ERROR [0-9]'
$RoboError = @{ "0x00000002" = "The system cannot find the file specified" ; `
"0x00000003" = "The system cannot find the path specified" ; `
"0x00000005" = "Access is denied" ; `
"0x00000006" = "The handle is invalid" ; `
"0x00000020" = "The process cannot access the file because it is being used by another process" ; `
"0x00000033" = "Scanning Destination Directory: Windows cannot find the network path. Verify that the network path is correct and the destination computer is not busy or turned off. If Windows still cannot find the network path, contact your network administrator" ; `
"0x00000035" = "The network path was not found" ; `
"0x0000003A" = "Copying NTFS Security to Destination File:  The specified server cannot perform the requested operation" ; `
"0x00000040" = "The specified network name is no longer available" ; `
"0x00000070" = "There is not enough space on the disk" ; `
"0x00000079" = "The semaphore timeout period has expired" ; `
"0x0000054F" = "Scanning Source Directory:  An internal error occurred"}
$FileName = (gci $RoboLog).BaseName
$FailedFilesCSV = "$PSScriptRoot\Errors-$($FileName)-$(Get-Date -format yyyy-MM-dd_hh-mm-sstt).CSV"



$starttime = Get-Date
$reader = [System.IO.File]::OpenText($RoboLog)
$results = New-Object System.Collections.ArrayList
Write-Host "Processing File $RoboLog..." -ForegroundColor Green
$c = 0
try {
    for() {
        $line = $reader.ReadLine()
        if ($line -eq $null) { break }
        $c++
        # process the line
        if( $line -match $SearchPattern) {
            if ($line -match '.*\(([0-9a-z]{10})\).*') { $err = $Matches[1]}
            if ($line -match  '\\(.*)') { $file = $Matches[0] }
            if ($err -and $file) {
                $result = New-Object -TypeName PSObject -Property @{
                    "File" = $file
                    "Error" = $RoboError.$err
                }    
                [void]$results.Add($result)
            }
        }
    }
}
finally {
    $reader.Close()
}
$Stoptime = Get-Date
$Timing = New-TimeSpan -Start $starttime -End $Stoptime
Write-Host "This took: $($Timing.Minutes) Min $($Timing.Seconds) sec $($Timing.Milliseconds) ms" -ForegroundColor Yellow
Write-Host "Result is; " -ForegroundColor Cyan -NoNewline
write-Host "$($results.Count) " -ForegroundColor Yellow -NoNewline
Write-Host "errors in file. Processed " -ForegroundColor Cyan -NoNewline
Write-Host "$c " -ForegroundColor Yellow -NoNewline
Write-Host " Lines." -ForegroundColor Cyan
$results | ft -AutoSize
$results | Export-Csv $FailedFilesCSV -NoType

