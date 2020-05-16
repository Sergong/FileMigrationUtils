<#

    This contains handy robocopy tricks

#>

function Calculate-FolderSize() {
    param(
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [string]
        $folder
    )

    # this should give you total foldersize in bytes
    $totbytes = (robocopy $folder $env:temp /zb /e /l /r:1 /w:1 /nfl /ndl /nc /fp /bytes /np /njh |  Where-Object{ $_ -match "Bytes :"}).trim().split(" ")[2]
    Return [math]::Round(($totbytes / 1GB ),2)
}


# write-host "$folder is $() GB in size"

<# send the bytes to log file

robocopy "large path name" $env:temp /zb /e /l /r:1 /w:1 /ndl /nfl /bytes /np /njh /log:size.log

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
