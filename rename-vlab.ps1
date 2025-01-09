<#
.SYNOPSIS
	This script a vLab template from a FlexVol Volume
.DESCRIPTION
	This script a vLab template from a FlexVol Volume
.PARAMETER	vApp
	Name of the source vApp
.PARAMETER  VMHost
	IP Address (or hostname) of the ESX host.
.EXAMPLE

.NOTES

#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$vApp,
  [Parameter(Mandatory=$True,Position=2)][string]$vAppNew,
  [Parameter][string]$VMHost
)


#stop vms
#mke new portgroups
#move nics to new portgroups
#make new serial pipes
#connect to new serial pipes
#unregister vms
#unmount datastore
#unmount Volume
#re-import Volume


#region Settings
$conf=Get-Content "$PSScriptRoot\settings.cfg" | Out-String | ConvertFrom-StringData
& "$PSScriptRoot\Connect-vLabResources.ps1"

# Make sure source vApp has been imported
$vAppOld=get-vapp | where { $_.Name -eq "$vApp"}
if ( ! $vAppOld) {
	Write-Host "Re-importing $vApp"
	$command = "$PSScriptRoot\import-vlabtemplate.ps1 $vApp"
    Invoke-Expression $command
}

# Make sure all the VMs are powered off
get-vapp | where { $_.Name -eq "$vApp"} | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vmguest -confirm:$false 

# First make new portgroups with the new naming convention
write-host "Creating portgroups"
[int]$pgVLan=$conf.vlanbase
$virtualSwitches=get-cluster | ?{ $_.Name -eq $conf.VICluster } | get-vmhost | get-virtualswitch | ?{ $_.Name -eq $conf.vswitch}
$portGroups=$virtualSwitches | get-virtualportgroup
foreach($srcPortGroup in $(get-vapp $vApp | get-vm | get-virtualportgroup | where { $_.Name -like "$vApp*" })) {
	#Find next unused VLAN
	DO {
		$pgVLan++
		$result=$portGroups | where { $_.VLanID -eq $pgVLan }
	} while ( $result )
	
	$netdesc=$srcPortGroup.Name.substring($vApp.length)
	$dstPortGroup=$vAppNew+$netdesc
	write-host "$srcPortGroup => $dstPortGroup"	

	# If the portgroup is missing then create it
	Write-Host "Creating PortGroup:$dstPortGroup, VLAN:$pgVLan"
	$result=$virtualSwitches | new-virtualportgroup -name $dstPortGroup -vlanid $pgVLan -erroraction SilentlyContinue  
	start-sleep -seconds 10 #chasing a timing problem

}

# Check portGroups
DO {
    $pgCount=$(get-cluster | ?{ $_.Name -eq $conf.VICluster } | get-vmhost | get-virtualswitch | ?{ $_.Name -eq $conf.vswitch} | get-virtualportgroup | where { $_.Name -like "$vAppNew*" }).count
    write-host "pgCount: $pgCount"
} While ( $pgCount -eq 0 )

# Now work on Serial ports while new-virtualportgroup does it's thing
write-host "Configuring serial ports"
$VMs=Get-vApp $vApp | get-vm
Foreach ($VM in $VMs){
	Foreach ($Device in ( $vm.ExtensionData.Config.Hardware.Device | where { $_.gettype().Name -eq "VirtualSerialPort" } )) {
			$pipeName=$Device.Backing.PipeName
			If ($pipeName -like "*$vApp*") {
				$newPipeName=$vAppNew+$pipeName.substring($vApp.length)	
				write-host $VM.Name	": Serial"$Device.UnitNumber" : $pipeName => $newPipeName"			
				
				#Now.. hackery begins
				$cfgSpec=New-Object VMware.Vim.VirtualMachineConfigSpec
				$serial=New-Object VMware.Vim.VirtualDeviceConfigSpec 
				$serial.device = [VMware.Vim.VirtualDevice]$Device
				$serial.device.Backing.PipeName=$newPipeName				
				$cfgSpec.deviceChange = $serial
				$serial.operation = "edit"				
				#Will it blend?
				$VM.ExtensionData.ReconfigVM($cfgSpec)		
			}		
	}
}

# then connect the nics to the new portgroups
# write-host "Connecting Nics"
# $networkAdapters=get-vapp $vApp | get-vm | get-networkadapter
# foreach($srcPortGroup in $(get-vapp $vApp | get-vm | get-virtualportgroup | where { $_.Name -like "$vApp*" })) {
# 	$netdesc=$srcPortGroup.Name.substring($vApp.length)
# 	$dstPortGroup=$vAppNew+$netdesc
# 	write-host "($srcPortGroup => $dstPortGroup)"	
# 	$result=$networkAdapters | where {$_.NetworkName -eq $srcPortGroup } | set-networkadapter -NetworkName $dstPortGroup -confirm:$false
# }

# Connect nics to the new portgroups
write-host "..Connecting LAN Nics"
$VMs=get-vapp $vApp | get-vm
$srcPortGroups=$VMs | get-virtualportgroup | where { $_.Name -like "$vApp*" }
$networkAdapters=$VMs | get-networkadapter
$LANAdapters=$networkAdapters | where { $_.NetworkName -like "$vApp*"}
foreach($srcPortGroup in $srcPortGroups){
	$pgName="$vAppNew"+$srcPortGroup.name.substring($vApp.length)
	write-host "....$srcPortGroup => $pgName"    
	$result=$LANAdapters | where {$_.NetworkName -eq $srcPortGroup } | set-networkadapter -PortGroup "$pgName" -confirm:$false
}

# then remove the vApp
get-vapp "$vApp" | remove-vapp -confirm:$false

# then remove the datastore (if mounted)
$ds=get-datastore "$vApp" -erroraction SilentlyContinue
if ($ds){ get-vmhost | remove-datastore $ds -confirm:$false}

# then dismount vol from namespace
dismount-ncvol "$vApp"

# then rename the vol
rename-ncvol "$vApp" "$vAppNew" -vserver $conf.vserver

# then re-import the vol
$command = "$PSScriptRoot\import-vlabtemplate.ps1 $vAppNew"
Invoke-Expression $command

exit








