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

$conf=. "$psscriptroot\get-vlabsettings.ps1"
& "$psscriptroot\Connect-vLabResources.ps1"

if ( $kill ){
    Write-Host "Powering off $vApp"
    get-vapp $vApp | get-vm | where { $_.PowerState -ne "PoweredOff" } | stop-vm -confirm:$false    
}
else {
    Write-Host "Shutting down $vApp"
    get-vapp $vApp | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vmguest -confirm:$false    
}
