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

robocopy "large path name" "c:\temp" /zb /e /l /r:1 /w:1 /ndl /nfl /bytes /np /njh /log:size.log

#>
