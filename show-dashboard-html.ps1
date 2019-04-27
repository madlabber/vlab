<#
.SYNOPSIS
	This script returns the html table for the admin menu
.DESCRIPTION
	This script returns the html table for the admin menu
.EXAMPLE

.NOTES
    Parameters are supplied by configuration file.
#>

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    $conf=. "$ScriptDirectory\get-vlabsettings.ps1"

    write-host "<a href=/config>Configuration Settings</a>"
    write-host "<br><br><a href=https://$defaultVIServer` target=_blank>VMware vCenter</a>"
    write-host "<br><br><a href=https://$CurrentNcController` target=_blank>OnCommand System Manager</a>"
    write-host "<br>"

    $countHosts=(get-cluster $conf.VICluster | get-vmhost).count
    Write-Host "Hosts: $countHosts"
} -ArgumentList $ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue
