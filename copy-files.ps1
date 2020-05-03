<#
    Example Robocopy Script
#>
param(
    [Parameter(Mandatory=$true)]
    $src,
    [Parameter(Mandatory=$true)]
    $dst
)

# Strip trailing '\' if it is passed along
if($src.EndsWith("\"){ $src = $src.Substring(0,$src.Length -1) }
if($dst.EndsWith("\"){ $dst = $dst.Substring(0,$dst.Length -1) }
$dateStamp = get-Date -f 'yyyy-MM-dd-HH-mm'
$log = ".\robocopy_$dateStamp.log"
#write-host "Source:      $src" -fore Cyan
#write-host "Destination: $dst" -fore Cyan
robocopy "$src" "$dst" /MIR /COPYALL /SECFIX /R:1 /W:5 /ZB /MT:4 /LOG+:"$log"   # add /secfix to catch changes to NTFS ACLs

# Display the stats
Get-Content $log -Head 14 
Get-Content $log -Tail 14 