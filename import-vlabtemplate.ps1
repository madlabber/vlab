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
  [Parameter][string]$VMHost
)

#region Settings
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

# Pick the host with the most free ram unless specified by config file or parameter
if ( ! $conf.vmwHost ){
	$conf.vmwHost=$(get-vmhost  | Select-Object Name, @{n='FreeMem';e={$_.MemoryTotalGB - $_.MemoryUsageGB}} | sort FreeMem | select-object -last 1).Name
}
if ( $VMHost ) { $conf.vmwHost=$VMHost }

# Use datastore from conf file, otherwise mount under vApp datastore
if ( $VIDatastore ) { $conf.VIDatastore=$VIDatastore }
if ( ! $conf.VIDatastore ) { $conf.VIDatastore="$vApp" }
if ( ! $VIDatastore ) { $VIDatastore=$conf.VIDatastore }

#endregion

# Feedback
Write-Host "Importing $vApp"

# Mount the vApp volume
Write-Host "Mounting Volume /$VIDatastore/$vApp"
$result=mount-ncvol -Name $vApp -JunctionPath "/$VIDatastore/$vApp" -erroraction:SilentlyContinue

# Create New vApp
write-host "Creating vApp $vapp"
$result=New-VApp -Name $vApp -Location (Get-Cluster $conf.VICluster) -erroraction:SilentlyContinue

$vAppNew=get-vapp -Name $vApp
# Register all the VMs into the vApp
Write-Host "Registering VMs"

# Search for .VMX Files in datastore
$ds = Get-Datastore -Name $VIDatastore | %{Get-View $_.Id}
$SearchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
$SearchSpec.matchpattern = "*.vmx"
$dsBrowser = Get-View $ds.browser
$DatastorePath = "[" + $ds.Summary.Name + "]/$vApp"
 
# Find all .VMX file paths in Datastore variable and filters out .snapshot
$SearchResult = $dsBrowser.SearchDatastoreSubFolders($DatastorePath, $SearchSpec) | where {$_.FolderPath -notmatch ".snapshot"}
 
# Register all .VMX files with vCenter
foreach($VMXFolder in $SearchResult) {
	foreach($VMXFile in $VMXFolder.File) {
		$vmx=$VMXFolder.FolderPath + $VMXFile.Path
		$VM=New-VM -VMFilePath $vmx -VMHost $conf.vmwHost -ResourcePool $vApp -erroraction:SilentlyContinue
		if ($VM){
			#$result=move-vm $VM -destination $vAppNew -erroraction:SilentlyContinue 
			#move-vm is broken in vCenter 6.7U2.  This API back door might work:
		    $spec = New-Object VMware.Vim.VirtualMachineRelocateSpec
		    $spec.Pool = $vAppNew.ExtensionData.MoRef
		    $VM.ExtensionData.RelocateVM($spec, [VMware.Vim.VirtualMachineMovePriority]::defaultPriority)	
		    write-host "....$VM"
		}	
	}
}

# Hosts have a portgroup limit of 500ish
write-host "Creating portgroups"
[int]$pgVLan=$conf.vlanbase
$virtualSwitches=get-cluster | ?{ $_.Name -eq $conf.VICluster } | get-vmhost | get-virtualswitch | ?{ $_.Name -eq $conf.vswitch}
$portGroups=$virtualSwitches | get-virtualportgroup
#foreach($srcPortGroup in $(get-vapp $vApp | get-vm | get-virtualportgroup | where { $_.Name -like "$vApp*" })) {
foreach($srcPortGroup in $(get-vapp $vApp | get-vm | get-networkadapter | where { $_.NetworkName -like "$vApp*" })) {
	#Find next unused VLAN
	DO {
		$pgVLan++
		$result=$portGroups | where { $_.VLanID -eq $pgVLan }
	} while ( $result )

	# If the portgroup is missing then create it
	$pgexists=$portGroups | where { $_.Name -eq $srcPortGroup.NetworkName }
	if ( ! $pgexists ){
		$result=$virtualSwitches | new-virtualportgroup -name $srcPortGroup.NetworkName -vlanid $pgVLan -erroraction SilentlyContinue
		$pgVLan++
	}
}



#Connect nics to the new portgroups
write-host "Connecting Nics"
$networkAdapters=get-vapp $vApp | get-vm | get-networkadapter
foreach($srcPortGroup in $(get-vapp $vApp | get-vm | get-virtualportgroup | where { $_.Name -like "$vApp*" })) {
	$result=$networkAdapters | where {$_.NetworkName -eq $srcPortGroup } | set-networkadapter -NetworkName "$srcPortGroup" -confirm:$false
}

# Connect the WAN interface
$oldWAN=$(get-vapp $vApp | get-vm | ?{ $_.Name -eq "gateway"} | get-networkadapter | ?{ $_.NetworkName -notlike "$vApp*" }).NetworkName
foreach($srcPortGroup in $(get-vapp $vApp | get-vm | get-virtualportgroup | where { $_.Name -eq $oldWAN })) {
	$result=get-vapp $vApp | get-vm | get-networkadapter | where {$_.NetworkName -eq $srcPortGroup } | set-networkadapter -NetworkName $conf.VIPortgroup -confirm:$false
}

# Fixup any named pipe serial ports
write-host "Configuring serial ports"
$VMs=Get-vApp $vApp | get-vm
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
$result=get-vapp $vApp | get-vm | New-AdvancedSetting -Name uuid.action -Value "keep" -Confirm:$false -Force:$true -WarningAction SilentlyContinue

# Ack alarms on all those VMs
write-host "Acknowledging alarms"
$alarmMgr = Get-View AlarmManager 
$result=Get-vApp $vApp | Get-VM | where {$_.ExtensionData.TriggeredAlarmState} | %{
    $vm = $_
    $vm.ExtensionData.TriggeredAlarmState | %{
        $alarmMgr.AcknowledgeAlarm($_.Alarm,$vm.ExtensionData.MoRef)
    }
}

# Create an affinity rule for the vApp
write-host "Configuring Affinity"
$result=get-drsrule -Cluster $conf.VICluster | where { $_.Name -eq "$vApp"} | remove-drsrule -confirm:$false
if ( $(get-vapp $vApp | get-vm).count -gt 0){
    $result=New-DrsRule -Cluster $conf.VICluster -Name $vApp -KeepTogether $true -VM (get-vapp $vApp | get-vm)
}
# Remove the stagin folder
#$result=$viFolder | remove-folder

# Then we want to start up the VMs
# and do something like this to find the outside IP
# Get-VM | where { $_.Name -eq "gateway" } |Select Name, @{N="IP Address";E={@($_.guest.IPAddress[0])}}

# Drop the vApp into the pipeline
get-vapp $vApp









