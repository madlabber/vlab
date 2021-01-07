<#
.SYNOPSIS
	This script clones a single volume vApp using FlexClone
.DESCRIPTION
	This script uses FlexClone technology to rapidly create an exact copy of an existing vApp
.PARAMETER	vApp
	(Manadatory)
	Name of the source vApp
.PARAMETER  VMHost
	IP Address (or hostname) of the ESX host.
.EXAMPLE

.NOTES

#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$network
)

#region Settings
$conf=Get-Content "$PSScriptRoot\settings.cfg" | Out-String | ConvertFrom-StringData
& "$PSScriptRoot\Connect-vLabResources.ps1"

# FIXME: Make sure they portgroup name is not in uses

# Create New portgroups
write-host "Creating portgroup $network"

$virtualSwitches=get-cluster | ?{ $_.Name -eq $conf.VICluster } | get-vmhost | get-virtualswitch | ?{ $_.Name -eq $conf.vswitch}
$portGroups=$virtualSwitches | get-virtualportgroup

[int]$pgVLan=$conf.vlanbase
#Find next unused VLAN
DO {
	$pgVLan++
	$result=$portGroups | where { $_.VLanID -eq $pgVLan }
} while ( $result )

#PortGroups are sequential independant of VLAN ID
$virtualSwitches | new-virtualportgroup -name $network -vlanid $pgVLan
