$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$configfile="$ScriptDirectory\cmdb\descriptions.tbl"

#load settings from file
$descriptions = Get-Content $configfile | Out-String | ConvertFrom-StringData


$descriptions