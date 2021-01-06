<#
.SYNOPSIS
	This script stops a vLab vApp
.DESCRIPTION
	This script stops a vLab vApp
.PARAMETER	vApp
	Name of the vLab vApp
.EXAMPLE

.NOTES

#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$vApp,
  [switch]$kill
)

$session=.\get-vlabsession.ps1
if ( $kill ){
    Write-Host "Powering off $vApp"
    $result=invoke-command -session $session -scriptblock {
        param($ScriptRoot,$vApp)
        get-vapp $vApp | get-vm | where { $_.PowerState -ne "PoweredOff" } | stop-vm -confirm:$false 
    } -ArgumentList $PSScriptRoot,$vApp   
}
else {
    Write-Host "Shutting down $vApp"
    $result=invoke-command -session $session -scriptblock {
        param($ScriptRoot,$vApp)
        get-vapp $vApp | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vmguest -confirm:$false 
    } -ArgumentList $PSScriptRoot,$vApp   
}

# Disconnect from the session
$result=$session | disconnect-pssession -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# Keep the powershell process alive so the output can reach the node.js front end.
#start-sleep -Milliseconds 50
