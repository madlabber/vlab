<#
.SYNOPSIS
	Disables vLab Authoring and removes the vlab datastore
.DESCRIPTION
	Disables vLab Authoring and removes the vlab datastore
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
	
#get-vapp $vApp | get-vm | start-vm
#Mounting a subfolder as a datastore
$datastore=$conf.VIDatastore
$cluster=get-cluster $conf.VICluster
$vlab=$vApp
$remotepath=$(get-datastore $datastore).RemotePath
$remotehost=$(get-datastore $datastore).RemoteHost

# this is the command that mounted it
#get-cluster $conf.VICluster | get-vmhost | foreach {new-datastore -VMHost $_.Name -Name "$vlab" -Path "$remotepath/$vlab" -NfsHost $remotehost}

# First get all the VM's in that datastore
$VMs=$cluster | get-datastore "$vlab" | get-vm

# Stop them all
$VMs | Where { $_.PowerState -ne "PoweredOff"} | stop-vmguest 

$running=$VMs | Where { $_.PowerState -ne "PoweredOff"}
if ($running.count > 0){start-sleep 120}

$VMs | Where { $_.PowerState -ne "PoweredOff"} | stop-vm

#for now just remove them
$result=$VMs | remove-vm -confirm:$false

# remove the datastore
$result=get-datastore "$vlab" | get-vmhost | remove-datastore "$vlab" -confirm:$false

# fixme later:
& "$ScriptDirectory\import-vlabtemplate.ps1" "$vlab"
