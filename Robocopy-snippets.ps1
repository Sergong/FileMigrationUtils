<#

    This contains handy robocopy tricks

#>

# this should give you total foldersize in bytes
$folder = "c:\program files"
$totbytes = (robocopy $folder "c:\temp" /zb /e /l /r:1 /w:1 /nfl /ndl /nc /fp /bytes /np /njh | ? { $_ -match "Bytes :"}).trim().split(" ")[2]

write-host "$folder is $([math]::Round(($totbytes / 1GB ),2)) GB in size"

# send the bytes to log file
robocopy "large path name" "c:\temp" /zb /e /l /r:1 /w:1 /ndl /nfl /bytes /np /njh /log:size.log

