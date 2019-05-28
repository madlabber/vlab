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

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

#Mounting a subfolder as a datastore
$datastore=$conf.VIDatastore
$vlab=$vApp
$remotepath=$(get-datastore $datastore).RemotePath
$remotehost=$(get-datastore $datastore).RemoteHost
get-cluster $conf.VICluster | get-vmhost | foreach {new-datastore -VMHost $_.Name -Name "$vlab" -Path "$remotepath/$vlab" -NfsHost $remotehost}
