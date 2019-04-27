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
  [Parameter(Mandatory=$True,Position=1)][string]$vApp,
  [Parameter(Position=2)][int]$pgCount,
  [Parameter(Position=3)][int]$sizeGB,
  [Parameter][string]$VMHost
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

# Feedback
Write-Host "Provisioning $vAppNew from $vApp on"$conf.vmwHost

# FlexClone the vApp volume
Write-Host "Creating Volume FlexClone /$VIDatastore/$vAppNew"
$result=New-NcVol $vApp -JunctionPath "/$VIDatastore/$vApp" -aggregate (get-ncvol vLabs).aggregate -size $sizeGB"GB"

# Create New vApp
write-host "Creating vApp $vappnew"
$result=New-VApp -Name $vApp -Location (Get-Cluster $conf.VICluster)

# Create New portgroups
# Hosts have a portgroup limit of 500ish
write-host "Creating portgroups"
$pgID=1
[int]$pgVLan=$conf.vlanbase
$virtualSwitches=get-cluster | ?{ $_.Name -eq $conf.VICluster } | get-vmhost | get-virtualswitch | ?{ $_.Name -eq $conf.vswitch}
$portGroups=$virtualSwitches | get-virtualportgroup
do{
	#Find next unused VLAN
	DO {
		$pgVLan++
		$result=$portGroups | where { $_.VLanID -eq $pgVLan }
	} while ( $result )

	#PortGroups are sequential independant of VLAN ID
	$pgName="$vApp"+"_net$pgID"
	$result=$virtualSwitches | new-virtualportgroup -name $pgName -vlanid $pgVLan
	$pgID++
	$pgVLan++
}while ( $pgID -le $pgCount )

exit











