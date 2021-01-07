# set-vlabcreds

# Settings
$conf=Get-Content "$PSScriptRoot\settings.cfg" | Out-String | ConvertFrom-StringData
$vcenter=$conf.vcenter
$ontap=$conf.cluster_mgmt

Write-Host "Enter Credentials for"$conf.vCenter	
$VICred = Get-Credential -message "Enter the credentials for vCenter server $vcenter"
$VICred | Export-CliXml "$PSScriptRoot\vicred.clixml"

Write-Host "Enter Credentials for Cluster:"$conf.cluster_mgmt
$NCCred = Get-Credential -message "Enter the credentials for ONTAP Cluster $ontap"
$NCCred | Export-CliXml "$PSScriptRoot\nccred.clixml"
