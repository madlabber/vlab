# set-vlabcreds

# Settings
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
$vcenter=$conf.vcenter
$ontap=$conf.cluster_mgmt

Write-Host "Enter Credentials for"$conf.vCenter	
$VICred = Get-Credential -message "Enter the credentials for vCenter server $vcenter"
$VICred | Export-CliXml "$ScriptDirectory\vicred.clixml"

Write-Host "Enter Credentials for Cluster:"$conf.cluster_mgmt
$NCCred = Get-Credential -message "Enter the credentials for ONTAP Cluster $ontap"
$NCCred | Export-CliXml "$ScriptDirectory\nccred.clixml"
