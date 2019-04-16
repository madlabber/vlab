$configfile=".\vlab.cfg"

#load settings from file
$settings = Get-Content $configfile | Out-String | ConvertFrom-StringData

$settings