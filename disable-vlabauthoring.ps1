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


$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    param($vApp,
          $ScriptDirectory
    )

    $conf=. "$ScriptDirectory\get-vlabsettings.ps1"
    & "$ScriptDirectory\Connect-vLabResources.ps1"

    # First get all the VM's in that datastore
    $VMs=get-cluster $conf.VICluster | get-datastore "$vApp" | get-vm

    # Stop them all - gracefully if possible
    Write-Host "Stopping any running VMs in $vApp"
    $VMs | Where { $_.PowerState -ne "PoweredOff"} | stop-vmguest 

    # Wait 2 minutes then kill the stragglers
    $running=$VMs | Where { $_.PowerState -ne "PoweredOff"}    
    if ($running.count > 0){start-sleep 120}
    $VMs | Where { $_.PowerState -ne "PoweredOff"} | stop-vm

    #for now just remove them
    write-host "Removing VMs from temporary datastore."
    $result=$VMs | remove-vm -confirm:$false

    # remove the datastore
    write-host "Removing temporary datastore."
    $result=get-datastore "$vApp" | get-vmhost | remove-datastore "$vApp" -confirm:$false

    # fixme later:
    write-host "Importing VMs from lab datastore."
    & "$ScriptDirectory\import-vlabtemplate.ps1" "$vApp"

} -ArgumentList $vApp,$psscriptroot

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue

#This keeps the powershell process from ending before all of the output has reached the node.js front end.
start-sleep -Milliseconds 50