#load settings from file
Get-Content "$PSScriptRoot\settings.cfg" | Out-String | ConvertFrom-StringData
