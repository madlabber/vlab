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
  [Parameter(Mandatory=$True,Position=1)][string]$vApp,
  [switch]$kill
)

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

if ( $kill ){
    Write-Host "Powering off $vApp"
    get-vapp $vApp | get-vm | where { $_.PowerState -ne "PoweredOff" } | stop-vm -confirm:$false    
}
else {
    Write-Host "Shutting down $vApp"
    get-vapp $vApp | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vmguest -confirm:$false    
}
