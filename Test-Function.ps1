<#

    Test Functions

#>

function Export-UTF8CSV {
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [psobject]
        $inputObj,
        [Parameter(Mandatory=$true)]
        $Path
    )
    # Export Header
    $fields = $inputObj | Get-Member | where{$_.MemberType -eq "Property" -or $_.MemberType -eq "NoteProperty"}
    $newLine = ""
    foreach($field in $fields){
        $NewLine += "`"$($field.Name)`","
    }
    $newLine = $newLine.Substring(0,$newLine.Length-1)
    $newLine | Out-File -FilePath $Path -Encoding utf8

    # Export Fields
    foreach($line in $inputObj){
        $newLine = ""
        foreach($field in $fields){
            $NewLine += "`"$($line.$($field.Name))`","
        }
        $newLine = $newLine.Substring(0,$newLine.Length-1)
        $newLine | Out-File -FilePath $Path -Encoding utf8 -Append
    }
}