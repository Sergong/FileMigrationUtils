<#
    Example Robocopy Script
#>
param(
    [Parameter(Mandatory=$true)]
    $src,
    [Parameter(Mandatory=$true)]
    $dest
)
# Strip trailing \
if($src.EndsWith("\")){ $src = $src.Substring(0,$src.Length -1) }
if($dest.EndsWith("\")){ $dest = $dest.Substring(0,$dest.Length -1) }

$log = ".\robologs"

$max_jobs = 2
$tstart = get-date

if((Test-Path -Path $src ))
{
	if(!(Test-Path -Path $log )){New-Item -ItemType directory -Path $log}
	if((Test-Path -Path $dest)){
		robocopy "$src" "$dest"
		$files = Get-ChildItem -Path $src -Directory
		
		$files | %{
			$ScriptBlock = {
                param($name, $src, $dest, $log)
                $log += "\$name-$(get-date -f yyyy-MM-dd-HH-mm-ss).log"
                Write-Host "Starting Copy of $src\$name..." -ForegroundColor Yellow
				robocopy "$src\$name" "$dest\$name" /MIR /COPYALL /SECFIX /R:1 /W:5 /ZB /MT:4 /LOG+:"$log"
                Write-Host "$src\$name completed" -ForegroundColor Green
			}
			$j = Get-Job -State "Running"
			while ($j.count -ge $max_jobs) 
			{
                Start-Sleep -Seconds 1
                $j = Get-Job -State "Running"
			}
			Get-job -State "Completed" | Receive-job
			Remove-job -State "Completed"
			$log = (get-item -path $log).FullName
			Start-Job $ScriptBlock -ArgumentList $_,$src,$dest,$log
		}

		While (Get-Job -State "Running") { Start-Sleep 2 }
		Remove-Job -State "Completed" 
		  Get-Job | Write-host

		$tend = get-date
		
		Write-host "Completed copy"
		Write-host "From: $src"
		Write-host "To: $Dest"
		new-timespan -start $tstart -end $tend
		
	} else {echo 'invalid Destination'}
}else {echo 'invalid Source'}