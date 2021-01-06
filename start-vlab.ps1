<#
.SYNOPSIS
	This script start a vLab vApp
.DESCRIPTION
	This script start a vLab vApp
.PARAMETER	vApp
	Name of the vLab vApp
.EXAMPLE

.NOTES

#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$vApp
)

$session=.\get-vlabsession.ps1
write-host "Starting $vApp ..."
$result=invoke-command -session $session -scriptblock {
    param($ScriptRoot,$vApp)
    get-vapp $vApp | get-vm | start-vm
} -ArgumentList $PSScriptRoot,$vApp

# Disconnect from the session
$result=$session | disconnect-pssession -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# Keep the powershell process alive so the output can reach the node.js front end.
#start-sleep -Milliseconds 50