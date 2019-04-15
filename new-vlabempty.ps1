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
$newID=100
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

# Register all the VMs into the vApp
Write-Host "Registering VMs"
#$ESXHost = Get-VMHost $conf.vmwHost

# Searches for .VMX Files in datastore variable
$ds = Get-Datastore -Name $VIDatastore | %{Get-View $_.Id}
$SearchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
$SearchSpec.matchpattern = "*.vmx"
$dsBrowser = Get-View $ds.browser
$DatastorePath = "[" + $ds.Summary.Name + "]/$vAppNew"
#$ClonePath = "[" + $ds.Summary.Name + "] /$vAppNew"
 
# Find all .VMX file paths in Datastore variable and filters out .snapshot
$SearchResult = $dsBrowser.SearchDatastoreSubFolders($DatastorePath, $SearchSpec) | where {$_.FolderPath -notmatch ".snapshot"}
 
# Register all .VMX files with vCenter
foreach($VMXFolder in $SearchResult) {
	foreach($VMXFile in $VMXFolder.File) {
		$vmx=$VMXFolder.FolderPath + $VMXFile.Path
		$VM=New-VM -VMFilePath $vmx -VMHost $conf.vmwHost -ResourcePool $vAppNew 
		#$VM=New-VM -VMFilePath $vmx -vApp (get-vapp $vAppNew) 
		$result=move-vm $VM (Get-vApp $vAppNew) 		
	}
}

#Connect nics to the new portgroups
write-host "Connecting Nics"
$pgID=1
$networkAdapters=get-vapp $vAppNew | get-vm | get-networkadapter
foreach($srcPortGroup in $(get-vapp $vApp | get-vm | get-virtualportgroup | where { $_.Name -like "$vApp*" })) {
	$pgName="$vAppNew"+"_$pgID"
	$result=$networkAdapters | where {$_.NetworkName -eq $srcPortGroup } | set-networkadapter -NetworkName "$pgName" -confirm:$false
	write-host "    $srcPortGroup => $pgName"
	$pgID++
}
# Connect the WAN interface
$oldWAN=$(get-vapp $vAppNew | get-vm | ?{ $_.Name -eq "gateway"} | get-networkadapter | ?{ $_.NetworkName -notlike "$vAppNew*" }).NetworkName
foreach($srcPortGroup in $(get-vapp $vApp | get-vm | get-virtualportgroup | where { $_.Name -eq $oldWAN })) {
	$result=get-vapp $vAppNew | get-vm | get-networkadapter | where {$_.NetworkName -eq $srcPortGroup } | set-networkadapter -NetworkName $conf.VIPortgroup -confirm:$false
}

# Fixup any named pipe serial ports
write-host "Configuring serial ports"
$VMs=Get-vApp $vAppNew | get-vm
Foreach ($VM in $VMs){
	Foreach ($Device in ( $vm.ExtensionData.Config.Hardware.Device | where { $_.gettype().Name -eq "VirtualSerialPort" } )) {
			$pipeName=$Device.Backing.PipeName
			If ($pipeName -like "*$vApp*") {
				$newPipeName=$pipeName+"_"+$newID	
				#write-host "Serial"$Device.UnitNumber" : $pipeName => $newPipeName"			
				
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
write-host "Setting uuid.action = keep"
$result=get-vapp $vAppNew | get-vm | New-AdvancedSetting -Name uuid.action -Value "keep" -Confirm:$false -Force:$true -WarningAction SilentlyContinue

# Ack alarms on all those VMs
write-host "Acknowledging alarms"
$alarmMgr = Get-View AlarmManager 
$result=Get-vApp $vAppNew | Get-VM | where {$_.ExtensionData.TriggeredAlarmState} | %{
    $vm = $_
    $vm.ExtensionData.TriggeredAlarmState | %{
        $alarmMgr.AcknowledgeAlarm($_.Alarm,$vm.ExtensionData.MoRef)
    }
}

# Create an affinity rule for the vApp
write-host "Configuring Affinity"
$result=New-DrsRule -Cluster $conf.VICluster -Name $vAppNew -KeepTogether $true -VM (get-vapp $vAppNew | get-vm)

# Remove the stagin folder
#$result=$viFolder | remove-folder

# Then we want to start up the VMs
# and do something like this to find the outside IP
# Get-VM | where { $_.Name -eq "gateway" } |Select Name, @{N="IP Address";E={@($_.guest.IPAddress[0])}}

if ( $conf.autostart -eq "true" ){
	write-host "starting $vAppNew"
	$result=get-vapp $vAppNew | get-vm | start-vm
}

# Drop the vApp into the pipeline
get-vapp $vAppNew









