<#
.SYNOPSIS
	This script partially automates the setup of the portal
.DESCRIPTION
	This script partially automates the setup of the portal
.EXAMPLE

.NOTES

#>

# Must be run in an administrator session
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    write-error "Installation requires administrator priviledges.  Run from an administrator powershell session."
    break
}
# Verify Powershell Version
if (  $psversiontable.PSVersion.Major -lt 5 ){
    write-error "Minimum supported Powershell version is 5.1"
    break
}

# Install Powershell Modules
set-psrepository PSGallery  -InstallationPolicy trusted
Install-Module -Name VMware.PowerCLI
Install-Module -Name NetApp.ONTAP

# Configure Powershell unrestricted execution policy
set-executionpolicy unrestricted
# Configure PowerCLI CEIP option
Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCEIP $false -confirm:$false -erroraction:SilentlyContinue
# Configure PowerCLI ignore certs
Set-PowerCLIConfiguration -scope AllUsers -InvalidCertificateAction Ignore -confirm:$false
# Configure PowerCLI not to show deprecation warnings
Set-PowerCLIConfiguration -scope AllUsers -DisplayDeprecationWarnings $false -confirm:$false
# Configure Default vServer mode
Set-PowerCLIConfiguration -Scope AllUsers -DefaultVIServerMode Multiple -confirm:$false

# Configure iis for myrtille:
$IISFeatures = "Web-Server","Web-WebServer","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Health","Web-Http-Logging","Web-Performance","Web-Stat-Compression","Web-Security","Web-Filtering","Web-App-Dev","Web-Net-Ext45","Web-Asp-Net45","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-WebSockets","Web-Mgmt-Tools","Web-Mgmt-Console"
Install-WindowsFeature -Name $IISFeatures

# Create a directory for downloaded bits
If(!(Test-Path "$PSScriptRoot\setup")) { New-Item -Path "$PSScriptRoot\setup" -Name "setup" -ItemType "directory" }

# TLS
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# Install Node.js
$nodejs_url = "https://nodejs.org/dist/v14.15.3/node-v14.15.3-x64.msi"
$nodejs_exe = "$PSScriptRoot\setup\node-v14.15.3-x64.msi"
if(!(Test-Path "$nodejs_exe")){
    write-host "Downloading node.js."
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($nodejs_url, $nodejs_exe)
    write-Output "Download complete."
}
write-host
Write-host "Installing node.js"
Start-Process "msiexec.exe" -argumentlist "/qn /l* $PSScriptRoot\setup\node-log.txt /i $PSScriptRoot\setup\node-v14.15.3-x64.msi" -Wait
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# npm install nodemon -g
Write-host
Write-Host "Installing nodemon."
npm install nodemon -g
Write-host
Write-Host "Installing express."
npm install express

#Install myrtille, be sure to change the default port to 8083
$myrtille_url = "https://github.com/cedrozor/myrtille/releases/download/v2.9.2/Myrtille_2.9.2_x86_x64_Setup.msi"
#$myrtille_exe = "$PSScriptRoot\setup\Myrtille_2.3.1_x86_x64_Setup.exe"
$myrtille_msi = "$PSScriptRoot\setup\Myrtille.msi"
write-host "Downloading Myrtille."
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($myrtille_url, $myrtille_msi)
write-Output "Download complete."
write-host
#Write-host "Extracting Myrtille"
#Start-Process "$myrtille_exe" "-y" -Wait
#write-host
Write-host "Installing Myrtille"
Start-Process "msiexec.exe" -argumentlist "/qb /l* $PSScriptRoot\setup\myrtille-log.txt /i $PSScriptRoot\setup\myrtille.msi" -Wait

if (!(Test-Path "$PSScriptRoot\settings.cfg")){
    Write-Host "Creating default settings.cfg"
    copy "$PSScriptRoot\settings.cfg.sample" "$PSScriptRoot\settings.cfg"
}
if (!(Test-Path "$PSScriptRoot\cmdb\descriptions.tbl")){
    Write-Host "Creating default descriptions.tbl"
    copy "$PSScriptRoot\cmdb\descriptions.tbl.sample" "$PSScriptRoot\cmdb\descriptions.tbl"
}

$conf=Get-Content "$PSScriptRoot\settings.cfg" | Out-String | ConvertFrom-StringData

if (!(Test-Path "$PSScriptRoot\vicred.clixml" )){
    Write-Host "Enter Credentials for"$conf.vCenter
    $VICred = Get-Credential -message "Enter the credentials for vCenter server $($conf.vcenter)"
    $VICred | Export-CliXml "$PSScriptRoot\vicred.clixml"
}

if (!(Test-Path "$PSScriptRoot\nccred.clixml" )){
    Write-Host "Enter Credentials for Cluster:"$conf.cluster_mgmt
    $NCCred = Get-Credential -message "Enter the credentials for ONTAP Cluster $($conf.cluster_mgmt)"
    $NCCred | Export-CliXml "$PSScriptRoot\nccred.clixml"
}

#Start the portal app
#  nodemon c:\vlab\vlab-node.js
