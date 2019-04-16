Param(
  [Parameter(Mandatory=$True,Position=1)][string]$key,
  [Parameter(Mandatory=$True,Position=2)][string]$value
)

$configfile=".\settings.cfg"

#load settings from file
$settings = Get-Content $configfile | Out-String | ConvertFrom-StringData

$settings.$key=$value

$result=New-Item $configfile -type file -force
$settings.keys | %{ Add-Content $configfile "$_`=$($settings.$_)"}

$settings