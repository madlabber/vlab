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
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

# Settings
[int]$newID=$conf.newID

# Pick the host with the most free ram unless specified by config file or parameter
if ( ! $conf.vmwHost ){
 $conf.vmwHost=$(get-vmhost  | Select-Object Name, @{n='FreeMem';e={$_.MemoryTotalGB - $_.MemoryUsageGB}} | sort FreeMem | select-object -last 1).Name
}
if ( $VMHost ) { $conf.vmwHost=$VMHost }

# Use datastore from conf file, otherwise mount under vApp datastore
if ( $VIDatastore ) { $conf.VIDatastore=$VIDatastore }
if ( ! $conf.VIDatastore ) { $conf.VIDatastore="$vApp" }
if ( ! $VIDatastore ) { $VIDatastore=$conf.VIDatastore }

# Find next vAppID
do {
	$newID++
	$vAppNew="$vApp"+"_"+"$newID"
	$result=get-vapp | where { $_.Name -eq "$vAppNew" }
} while ( $result ) 
#endregion

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









