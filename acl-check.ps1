<#

    Script to test ACLs of directory paths

#>
param(
    [Parameter(Mandatory=$true)]
    $CsvPath,
    $resultFile = ".\acl-exceptions.csv",
    $SampleSize = 100
)

$csv = Import-Csv $CsvPath

$LogObj = @()
$Tot = $csv.Count
if($SampleSize -gt $Tot){
    write-host "SampleSize is larger than the total nr of entries in $resultFile. The setting it to $Tot."
    $SampleSet = $csv
} else {
    # Build a Sample Set 
    $SampleSet = $csv | Get-Random -Count $SampleSize
}

# Iterate through the Set
$c = 1
$SampleSet | %{
    Write-Progress -Activity "Processing $($_.source)" -PercentComplete (100 * ($c / $SampleSize)) -Status "Comparing Source and Destination ACLs"
    Try {
        $orgACL = get-ACL -path $_.source
        $destACL = Get-Acl -Path $_.destination
        if( $orgACL.Sddl -eq $destACL.Sddl){
            $LogObj += [PSCustomObject]@{
                Source = $_.source
                Status = "OK"
            }
        } elseif ($null -eq $destACL){
            $LogObj += [PSCustomObject]@{
                Source = $_.source
                Status = "Not Found"
            }
        } elseif ($orgACL.Sddl -ne $destACL.Sddl){
            $LogObj += [PSCustomObject]@{
                Source = $_.source
                Status = "ACL different"
            }
        }
    }
    Catch{
        $ErrorMsg = "An Error occurred: $($_.Exception.Message)"
        Write-Host "$ErrorMsg" -ForegroundColor Red
    }
    
    $c++
}
$OutCsv = $LogObj | where status -ne "OK" 
if($Null -ne $OutCsv){
    write-host "Some exceptions found, please check $resultFile" -ForegroundColor Red
    $OutCsv| Export-Csv -notypeinformation -path $resultFile
} else {
    write-host "No exception found, All passed." -ForegroundColor Green
}
