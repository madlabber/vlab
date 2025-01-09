<#
.SYNOPSIS
	This script removes a vLab vApp
.DESCRIPTION
	This script remove a vLab vApp, related PortGroups, and the associated FlexClone Volume.
.PARAMETER	vApp
	Name of the source vApp
.EXAMPLE

.NOTES

#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$vApp
)

$session=.\get-vlabsession.ps1
write-host "Removing $vApp ..."
$result=invoke-command -session $session -scriptblock {
    param($ScriptRoot,$vApp)


    # Power off the VMs
    Write-Host "Powering off VMs."
    get-vapp $vApp | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vm -confirm:$false

    # remove the portgroups
    Write-Host "Removing port groups."
    $portGroups=get-vapp $vApp | get-vm | get-virtualportgroup | where { $_.Name -like "$vApp*" }
    foreach ( $pg in $portGroups ) {
    	get-cluster | ?{ $_.Name -eq $conf.VICluster } | get-vmhost | get-virtualswitch | ?{ $_.Name -eq $conf.vswitch} | get-virtualportgroup | ?{ $_.Name -eq $pg.Name } | remove-virtualportgroup -confirm:$false
    	#get-vapp $vApp | get-vm | get-virtualportgroup | where { $_.Name -like "$vApp*" } | remove-virtualportgroup -confirm:$false
    }

    # remove the vApp
    Write-Host "Removing vApp."
    $result=get-vapp $vApp | remove-vApp -confirm:$false

    # remove datastore if mounted for authoring
    Write-Host "Removing Datastore."
    $result=Get-Datastore | where {$_.Name -eq "$vApp"} | remove-datastore -confirm:$false

    # dismount the volume
    $result=get-ncvol $vApp | dismount-ncvol 

    # remove the volume if it is a clone
    $result=get-ncvol $vApp | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | set-ncvol -offline | remove-ncvol -confirm:$false

    $timer=$null
} -ArgumentList $PSScriptRoot,$vApp

# Disconnect from the session
$result=$session | disconnect-pssession -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# Keep the powershell process alive so the output can reach the node.js front end.
start-sleep -Milliseconds 50