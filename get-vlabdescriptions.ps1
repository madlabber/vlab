$configfile=".\descriptions.cfg"

#load settings from file
$descriptions = Get-Content $configfile | Out-String | ConvertFrom-StringData


$descriptions