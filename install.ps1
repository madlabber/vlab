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
   write-Warning "Installation requires administrator priviledges.  Run from an administrator powershell session."     
   break
}
# Verify Powershell Version


#Install PowerCLI
Install-Module -Name VMware.PowerCLI

#Configure Powershell unrestricted execution policy
set-executionpolicy unrestricted

#Configure PowerCLI ignore certs
Set-PowerCLIConfiguration -scope AllUsers -InvalidCertificateAction Ignore -confirm:$false

#Configure PowerCLI not to show deprecation warnings
Set-PowerCLIConfiguration -scope AllUsers -DisplayDeprecationWarnings $false -confirm:$false

#Configure PowerCLI CIP option
Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCEIP $false -confirm:$false

#Configure Default vServer mode
Set-PowerCLIConfiguration -Scope AllUsers -DefaultVIServerMode Multiple -confirm:$false

#configure iis for myrtille:
$IISFeatures = "Web-Server","Web-WebServer","Web-Common-Http","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Health","Web-Http-Logging","Web-Performance","Web-Stat-Compression","Web-Security","Web-Filtering","Web-App-Dev","Web-Net-Ext45","Web-Asp-Net45","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-WebSockets","Web-Mgmt-Tools","Web-Mgmt-Console"
Install-WindowsFeature -Name $IISFeatures

# Install PSTK (Manual step)
# Install Node.js
# npm install nodemon -g

#Install express:
# cd c:\vlab
# npm install express

#Install myrtille, be sure to change the default port to 8083
$myrtille_url = "https://github.com/cedrozor/myrtille/releases/download/v2.3.1/Myrtille_2.3.1_x86_x64_Setup.exe"
$myrtille_exe = "$PSScriptRoot\setup\Myrtille_2.3.1_x86_x64_Setup.exe"
write-host "downloading the Myrtille for windows installer"
$result=New-Item -Path "$PSScriptRoot" -Name "setup" -ItemType "directory"
$start_time = Get-Date
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($myrtille_url, $myrtille_exe)
write-Output "Myrtille installer downloaded"
write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

#retreive myrtille password hash
#  https://localhost/myrtille/GetHash.aspx?password=P@ssw0rd
#configure settings.cfg
#use the menu to save creds
#
#Start the portal app
#  nodemon c:\vlab\vlab-node.js

#optional components:
#install sublime
#install github desktop
