$configfile=".\settings.cfg"

#load settings from file
$settings = Get-Content $configfile | Out-String | ConvertFrom-StringData

Write-Host "<table>"
Write-Host "<tr><td><u>Name</u></td><td><u>Value</u></td></tr>"
foreach ( $key in $settings.keys ){
    Write-Host "<tr>"
    Write-Host "<td>"$key"</td>"
    Write-Host "<td>"$settings[$key]"</td>"
    Write-Host "</tr>"
}
Write-Host "</table>"

$TotalVMs=(get-vm).count


#This keeps the powershell process from ending before all of the output has reached the node.js front end.
start-sleep -Milliseconds 100