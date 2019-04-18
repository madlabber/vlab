$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$configfile="$ScriptDirectory\descriptions.cfg"

#load settings from file
$descriptions = Get-Content $configfile | Out-String | ConvertFrom-StringData


$descriptions