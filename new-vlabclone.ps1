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
  [Parameter(Position=2)][string]$vAppNew,
  [Parameter][string]$VMHost
)

Write-Host "Authenticating."
#region Settings
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

# Settings
[int]$newID=$conf.newID

# Pick the host with the most free ram unless specified by config file or parameter
Write-Host "Selecting VM Host."
if ( ! $conf.vmwHost ){
 $conf.vmwHost=$(get-vmhost  | Select-Object Name, @{n='FreeMem';e={$_.MemoryTotalGB - $_.MemoryUsageGB}} | sort FreeMem | select-object -last 1).Name
}
if ( $VMHost ) { $conf.vmwHost=$VMHost }

# Use datastore from conf file, otherwise mount under vApp datastore
if ( $VIDatastore ) { $conf.VIDatastore=$VIDatastore }
if ( ! $conf.VIDatastore ) { $conf.VIDatastore="$vApp" }
if ( ! $VIDatastore ) { $VIDatastore=$conf.VIDatastore }

# Find next vAppID
Write-Host "Getting next vAppID."
$vApps=get-vapp
if ( ! $vAppNew ) {
	do {
		$newID++
		$vAppNew="$vApp"+"_"+"$newID"
		$result=$vApps | where { $_.Name -eq "$vAppNew" }
	} while ( $result )
} 
#endregion

# Feedback
Write-Host "Provisioning $vAppNew from $vApp on"$conf.vmwHost

$SnapshotName="master"
$snap=get-ncsnapshot -volume "$vApp" "master"
if (! $snap){
	$SnapshotName=get-date -format o
	$snap=new-ncsnapshot -volume "$vApp" "$SnapshotName"
}

# FlexClone the vApp volume
Write-Host "..Creating Volume FlexClone /$VIDatastore/$vAppNew"
$result=New-NcVolClone $vAppNew $vApp -JunctionPath "/$VIDatastore/$vAppNew" -ParentSnapshot $SnapshotName

# Create New vApp
write-host "..Creating vApp $vappnew"
$cloneApp=New-VApp -Name $vAppNew -Location (Get-Cluster $conf.VICluster)
$srcApp=Get-vApp $vApp

# Create New portgroups
# Hosts have a portgroup limit of 500ish
write-host "..Creating portgroups"
[int]$pgVLan=$conf.vlanbase
$virtualSwitches=get-cluster | ?{ $_.Name -eq $conf.VICluster } | get-vmhost | get-virtualswitch | ?{ $_.Name -eq $conf.vswitch}
$portGroups=$virtualSwitches | get-virtualportgroup
foreach($srcPortGroup in $( $srcApp | get-vm | get-virtualportgroup | where { $_.Name -like "$vApp*" })) {
	#Find next unused VLAN
	DO {
		$pgVLan++
		$result=$portGroups | where { $_.VLanID -eq $pgVLan }
	} while ( $result )

	# Created portgroup lab_%name%_%suffix%
	$pgName="$vAppNew"+$srcPortGroup.name.substring($vApp.length)
	Write-Host "....$srcPortGroup => $pgName"
	$result=$virtualSwitches | new-virtualportgroup -name $pgName -vlanid $pgVLan
}


Write-Host "..Searching for VMs"
# Searches for .VMX Files in datastore variable
$ds = Get-Datastore -Name $VIDatastore | %{Get-View $_.Id}
$SearchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
$SearchSpec.matchpattern = "*.vmx"
$dsBrowser = Get-View $ds.browser
$DatastorePath = "[" + $ds.Summary.Name + "]/$vAppNew"
 
# Find all .VMX file paths in Datastore variable and filters out .snapshot
$SearchResult = $dsBrowser.SearchDatastoreSubFolders($DatastorePath, $SearchSpec) | where {$_.FolderPath -notmatch ".snapshot"}

# Register all the VMs into the vApp
Write-Host "..Registering VMs"
# Register all .VMX files with vCenter
foreach($VMXFolder in $SearchResult) {
	foreach($VMXFile in $VMXFolder.File) {
		$vmx=$VMXFolder.FolderPath + $VMXFile.Path
		$VM=New-VM -VMFilePath $vmx -VMHost $conf.vmwHost -ResourcePool $cloneApp
		#$result=move-vm $VM -destination $cloneApp 
		#move-vm is broken in vCenter 6.7U2.  This API back door might work:
		$spec = New-Object VMware.Vim.VirtualMachineRelocateSpec
		$spec.Pool = $cloneApp.ExtensionData.MoRef
		$VM.ExtensionData.RelocateVM($spec, [VMware.Vim.VirtualMachineMovePriority]::defaultPriority)
		write-host "....$VM"
	}
}

# Connect nics to the new portgroups
write-host "..Connecting LAN Nics"
$cloneVMs=$cloneApp | get-vm
$srcPortGroups=$cloneVMs | get-virtualportgroup | where { $_.Name -like "$vApp*" }
$networkAdapters=$cloneVMs | get-networkadapter
$LANAdapters=$networkAdapters | where { $_.NetworkName -like "$vApp*"}
$WANAdapters=$networkAdapters | where { $_.NetworkName -notlike "$vApp*"} 
foreach($srcPortGroup in $srcPortGroups){
	$pgName="$vAppNew"+$srcPortGroup.name.substring($vApp.length)
	write-host "....$srcPortGroup => $pgName"
	$result=$LANAdapters | where {$_.NetworkName -eq $srcPortGroup } | set-networkadapter -NetworkName "$pgName" -confirm:$false
}
write-host "..Connected WAN Nics"
$result=$WANAdapters | set-networkadapter -NetworkName $conf.VIPortgroup -confirm:$false

#foreach ($adapter in $networkAdapters){
#	$pgName="$vAppNew"+$adapter.NetworkName.substring($vApp.length)
#	$result=$adapter | set-networkadapter -networkName "$pgName"
#}
#$result=$networkAdapters | set-networkadapter -NetworkName "$vAppNew"+$_.NetworkName.substring($vApp.length)
#$networkAdapters

#foreach($srcPortGroup in $($srcApp | get-vm | get-virtualportgroup | where { $_.Name -like "$vApp*" })) {
#	$pgName="$vAppNew"+$srcPortGroup.name.substring($vApp.length)
#	write-host "....$srcPortGroup => $pgName"	
#	$result=$networkAdapters | where {$_.NetworkName -eq $srcPortGroup } | set-networkadapter -NetworkName "$pgName" -confirm:$false
#}

# Connect the WAN interface
#$oldWAN=$(get-vapp $vAppNew | get-vm | ?{ $_.Name -eq "gateway"} | get-networkadapter | ?{ $_.NetworkName -notlike "$vAppNew*" }).NetworkName
#$newWAN=Get-VirtualPortGroup -Name $conf.VIPortgroup
#foreach($srcPortGroup in $(get-vapp $vApp | get-vm | get-virtualportgroup | where { $_.Name -eq $oldWAN })) {
#	$result=get-vapp $vAppNew | get-vm | get-networkadapter | where {$_.NetworkName -eq $srcPortGroup } | set-networkadapter -NetworkName $conf.VIPortgroup -confirm:$false
#}

# Fixup any named pipe serial ports
write-host "..Configuring serial ports"
$VMs=Get-vApp $vAppNew | get-vm
Foreach ($VM in $VMs){
	Foreach ($Device in ( $vm.ExtensionData.Config.Hardware.Device | where { $_.gettype().Name -eq "VirtualSerialPort" } )) {
			$pipeName=$Device.Backing.PipeName
			If ($pipeName -like "*$vApp*") {
				#$newPipeName=$pipeName+"_"+$newID	
				#write-host "Serial"$Device.UnitNumber" : $pipeName => $newPipeName"	
				$newPipeName=$vAppNew+$pipeName.substring($vApp.length)	
				write-host "....$VM`:serial$($Device.UnitNumber)`:: $pipeName => $newPipeName"					
				
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

# Configure uuid.action = "keep"
write-host "..Setting uuid.action = keep"
$result=get-vapp $vAppNew | get-vm | New-AdvancedSetting -Name uuid.action -Value "keep" -Confirm:$false -Force:$true -WarningAction SilentlyContinue

# Ack alarms on all those VMs
write-host "..Acknowledging alarms"
$alarmMgr = Get-View AlarmManager 
$result=Get-vApp $vAppNew | Get-VM | where {$_.ExtensionData.TriggeredAlarmState} | %{
    $vm = $_
    $vm.ExtensionData.TriggeredAlarmState | %{
        $alarmMgr.AcknowledgeAlarm($_.Alarm,$vm.ExtensionData.MoRef)
    }
}

# Create an affinity rule for the vApp
write-host "..Configuring Affinity"
$result=New-DrsRule -Cluster $conf.VICluster -Name $vAppNew -KeepTogether $true -VM (get-vapp $vAppNew | get-vm)

# Start the vApp (optional)
if ( $conf.autostart -eq "true" ){
	write-host "Starting $vAppNew"
	$result=get-vapp $vAppNew | get-vm | start-vm
}

# Drop the vApp into the pipeline
get-vapp $vAppNew
