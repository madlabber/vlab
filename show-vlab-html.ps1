<#
.SYNOPSIS
	This script returns a collection of vlab FlexClone volumes
.DESCRIPTION
	This script returns a collection of vlab FlexClone volumes
.EXAMPLE

.NOTES
    Parameters are supplied by configuration file.
#>
Param(
    [Parameter(Position=1)][string]$CURRENTVLAB
)

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Keep a session to maintain state
$session=get-pssession -ComputerName "localhost" -Name "node-vlab" | where { $_.State -eq "Disconnected" } | select-object -first 1
if ($session) { $result=$session | connect-pssession }
else { 
    $session=new-pssession -ComputerName "localhost" -Name "node-vlab" 
    $result=$session | connect-pssession
    $result=invoke-command -session $session -scriptblock {
        param($ScriptDirectory)
        $conf=. "$ScriptDirectory\get-vlabsettings.ps1"
        & "$ScriptDirectory\Connect-vLabResources.ps1"
    } -ArgumentList $ScriptDirecoy
}

$result=invoke-command -session $session -scriptblock { 
param($CURRENTVLAB,
      $ScriptDirectory
)

# Settings
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

# Descriptions
$descriptions=. "$ScriptDirectory\get-vlabdescriptions.ps1"

$wanip=""
$reldate=""
$gateway=get-vapp "$CURRENTVLAB" | get-vm | where { $_.Name -eq "gateway" }
if ( $gateway ) { $wanip=$gateway.guest.IPAddress[0] }
$labvol=get-ncvol | where { $_.Name -eq "$CURRENTVLAB" }
$relsnap=$labvol | get-ncsnapshot | where { $_.Name -eq "master" }
if ( $relsnap ) { $reldate=$relsnap.Created }
else { $reldate = "NOT RELEASED" }
$parent=$labvol.VolumeCloneAttributes.VolumeCloneParentAttributes.Name 
if ( ! $parent ) { $parent=$CURRENTVLAB}
#Write-Host $parent



Write-Host "<table>"
Write-Host "<tr><td><b>Name:</b></td><td> $CURRENTVLAB </td></tr>"
Write-Host "<tr><td><b>Description:</b></td><td> $($descriptions[$parent]) </td></tr>"
Write-Host "<tr><td><b>Date:</b></td><td> $reldate </td></tr>"
if ( $wanip ){ 
    $row='<tr><td><b>IP:</b></td><td><a href="rdp://full%20address=s:'
    $row+="$wanip"
    $row+=':3389&audiomode=i:2&disable%20themes=i:1">'+"$wanip"+'</a></td></tr>' 
    Write-Host $row }
Write-Host "</table><br>"

Write-Host "<table><tr><td valign=top width=40%>"
Write-Host "<b>Virtual Machines:</b><hr>"
Write-Host "<table>"
Write-Host "<tr><td><u>Name</u></td><td><u>PowerState</u></td><td><u>vCPUs</u></td><td><u>MemoryGB</u></td></tr>"
$vms=get-vapp | where { $_.Name -eq "$CURRENTVLAB" } | get-vm | sort Name 
$sumMemoryGB=0
$sumCPUs=0
foreach ($vm in $vms) {
    Write-Host "<tr>"
    Write-Host "<td width=120px>"$vm.Name"</td>"
    Write-Host "<td>"$vm.PowerState"</td>"
    Write-Host "<td align=center> "$vm.NumCpu"</td>"
    Write-Host "<td> "$vm.MemoryGB"</td>"
    Write-Host "</tr>"
    $sumMemoryGB+=$vm.MemoryGB
    $sumCPUs+=$vm.NumCpu
}

Write-Host "<tr><td width=120px><b>Total:</b></td><td></td><td align=center><b>$sumCPUs</b></td><td><b>$sumMemoryGB</b></td></tr>"
Write-Host "</table>"
Write-Host "</td><td width=10px></td><td  valign=top>"
$diagram="$parent`.jpg"
if ( Test-Path "$ScriptDirectory\cmdb\$diagram" -PathType Leaf ){
Write-Host "<b>Topology:</b><hr>"
Write-Host "<img src=cmdb/$diagram alt=lab_diagram width=500>"}
Write-Host "</td></tr></table>"
} -ArgumentList $CURRENTVLAB,$ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 6000 -WarningAction silentlyContinue
#}

