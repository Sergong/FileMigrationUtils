#Requires -Version 2
<#

    Robocopy wrapper for File Migration Planning
    Calculates the total number of files/folder and size in GB

#>
param(
	# Parameter help description
	[Parameter(Mandatory=$true)]
	[string]
	$folder,
	[Parameter(Mandatory=$false)]
	[string]
	$Log = $null
)
if($log -eq ""){
	$Drive = $folder.substring(0,1)
	$t = $folder.split("\")
	$Log = ".\$Drive-$($t[$t.count-1]).log"
}

write-host "Running Robocopy in Virtual Mode on $folder..." -fore Yellow
$null = robocopy $folder "c:\temp" /zb /e /l /r:1 /w:1 /ndl /nfl /bytes /np /njh /log:$Log
$Content = cat $log
$Dirs = ($Content | Where-Object{ $_ -match "Dirs :"}).trim()
$tmp = $Dirs -match 'Dirs :\s+([0-9]+)'
$Dirs = $Matches[1]
$Files = ($Content | Where-Object{ $_ -match "Files :"}).trim()
$tmp = $Files -match 'Files :\s+([0-9]+)'
$Files = $Matches[1]
$Bytes = ($Content | Where-Object{ $_ -match "Bytes :"}).trim().split(" ")[2]

$record = "" | select Folders, Files, SizeGB
$record.Folders = "{0:N}" -f $Dirs
$record.Files = "{0:N}" -f $Files
$record.SizeGB = "{0:N2}" -f [math]::round($Bytes/1GB,2)


$record

<#

Switches Used:
/zb     Use restartable mode, if access denied use Backup mode
/e      Copy subdirectories, including Empty directories
/l      Specifies that files are only listed (not copied, deleted or time stanped)
/r:1    Number of retries
/w:1    Wait time in seconds
/nfl    File names are not logged
/ndl    Directory names are not logged
/nc     File Classes are not logged
/fp     Includes full path names of files in output
/bytes  Print sizes as bytes
/np     Progress of the copying operation will not be displayed
/hjh    No job header is displayed
/log:   File to Log to

#>
