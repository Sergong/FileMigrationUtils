#Requires -Version 4
<#

	Wrapper script for Process-RoboLog.ps1

#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path -Path $_})][String[]]$LogPath
)

##### ----------- Start Functions -------------- #####

Function Process-RoboLog(){
	param( 
		[Parameter(Mandatory=$true)]
		[ValidateScript({Test-Path -Path $_})][String[]]$RoboLog,
		[Parameter(Mandatory=$true)]
		[string]$ErrorPath
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
	#$temp = (gci $RoboLog).DirectoryName.Split("\")
	#$ErrorPath = "Errors-" + ($temp[$temp.count-1])
	<#if( !(Test-Path -Path ("$PSScriptRoot\$ErrorPath")) ){
		$null = mkdir "$PSScriptRoot\$ErrorPath"
	}#>
	$FailedFilesCSV = "$PSScriptRoot\$ErrorPath\Errors-$($FileName)-$(Get-Date -format yyyy-MM-dd_hh-mm-ss).CSV"


	$starttime = Get-Date
	$reader = [System.IO.File]::OpenText($RoboLog)
	$results = New-Object System.Collections.ArrayList
	Write-Host "Processing File $RoboLog..." -ForegroundColor Yellow
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
	if($results.count -gt 0){
		write-Host "$($results.Count) " -ForegroundColor Red -NoNewline
	} else {
		write-Host "$($results.Count) " -ForegroundColor Yellow -NoNewline
	}
	Write-Host "errors in file. Processed " -ForegroundColor Cyan -NoNewline
	Write-Host "$c " -ForegroundColor Yellow -NoNewline
	Write-Host " Lines." -ForegroundColor Cyan

	if($results.count -gt 0){
		$results | ft -AutoSize
		$results | Export-Csv $FailedFilesCSV -NoType
	}
	Return $results.count
}

##### ----------- End Functions -------------- #####

$files = gci -path $LogPath
$TotErrors = 0
$temp = $files[0].DirectoryName.Split("\")
$ErrorPath = "Errors-" + ($temp[$temp.count-1])
if( !(Test-Path -Path ("$PSScriptRoot\$ErrorPath")) ){
	$null = mkdir "$PSScriptRoot\$ErrorPath"
}

Foreach($file in $files){
	$TotErrors += Process-RoboLog -RoboLog $file.FullName -ErrorPath $ErrorPath
}
if($TotErrors -gt 0){
	write-Host "Total Errors across all Files: $TotErrors" -Fore Magenta
} else {
	write-host "No Errors detected across all Log files" -Fore Magenta
	rm -r "$PSScriptRoot\$ErrorPath"
}

