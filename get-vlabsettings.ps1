$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$configfile="$ScriptDirectory\settings.cfg"

#load settings from file
$settings = Get-Content $configfile | Out-String | ConvertFrom-StringData

$settings