# set-vlabcreds

# Settings
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"

Write-Host "Enter Credentials for"$conf.vCenter	
$VICred = Get-Credential
$VICred | Export-CliXml "$ScriptDirectory\vicred.clixml"

Write-Host "Enter Credentials for Cluster:"$conf.cluster_mgmt
$NCCred = Get-Credential
$NCCred | Export-CliXml "$ScriptDirectory\nccred.clixml"
