<#
.SYNOPSIS
	Enables vLab Authoring by mounting the lab volume as a datastore
.DESCRIPTION
	Enables vLab Authoring by mounting the lab volume as a datastore
.PARAMETER	vApp
	Name of the vLab vApp
.EXAMPLE

.NOTES

#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$vApp
)

$conf=. "$PSScriptRoot\get-vlabsettings.ps1"
& "$PSScriptRoot\Connect-vLabResources.ps1"

#Mounting a subfolder as a datastore
$datastore=$conf.VIDatastore
$remotepath=$(get-datastore $datastore).RemotePath
$remotehost=$(get-datastore $datastore).RemoteHost
get-cluster $conf.VICluster | get-vmhost | foreach {new-datastore -VMHost $_.Name -Name "$vApp" -Path "$remotepath/$vApp" -NfsHost $remotehost}
