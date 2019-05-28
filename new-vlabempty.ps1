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
  [Parameter(Position=3)][int]$sizeGB
)

# Load settings.cfg
$conf=. "$psscriptroot\get-vlabsettings.ps1"

# Connect to resources
& "$psscriptroot\Connect-vLabResources.ps1"

# Default number of portgroups (private virtual networks) is 1
if ( ! $pgCount ){$pgCount=1}

# Default size is 100gb
if ( ! $sizeGB ){$sizeGB=100}

# Use datastore from conf file
$VIDatastore=$conf.VIDatastore

# Feedback
Write-Host "Creating new vlab $vApp in "$conf.VICluster

# Create the new vApp volume
Write-Host "Creating Volume /$VIDatastore/$vApp"
$result=New-NcVol $vApp -JunctionPath "/$VIDatastore/$vApp" -aggregate (get-ncvol $VIDatastore).aggregate -size $sizeGB"GB"

# Create New vApp
write-host "Creating vApp $vApp"
$result=New-VApp -Name $vApp -Location (Get-Cluster $conf.VICluster)

# Create New portgroups
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

# Enable authoring by mounting the volume as a datastore
$remotepath=$(get-datastore $VIDatastore).RemotePath
$remotehost=$(get-datastore $VIDatastore).RemoteHost
write-host $RemotePath
write-host $remotehost
get-cluster $conf.VICluster | get-vmhost | foreach {new-datastore -VMHost $_.Name -Name "$vApp" -Path "$remotepath/$vApp" -NfsHost $remotehost}

# Drop the vApp into the pipeline
get-vapp $vApp









