#>
Write-Host "Loading Configuration"
# Settings
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=Get-Content "$ScriptDirectory\settings.cfg" | Out-String | ConvertFrom-StringData 
# Descriptions
$descriptions=Get-Content "$PSScriptRoot\cmdb\descriptions.tbl" | Out-String | ConvertFrom-StringData

Write-Host "Connecting to Resources"
& "$ScriptDirectory\Connect-vLabResources.ps1"

# List volumes that start with lab_
$labvols=get-ncvol -volume "lab_*" -vserver $conf.vserver -WarningAction silentlyContinue | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }
#$labvols | FT 	@{Label="Name";Expression={$_.Name};width=20}, 
#               @{Label="Description";Expression={$descriptions[$_.Name]}}

Write-Host "Starting Web Server"
nodemon .\vlab-node.js
