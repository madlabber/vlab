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

# Settings
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

$wanip=""
$reldate=""
$gateway=get-vapp "$CURRENTVLAB" | get-vm | where { $_.Name -eq "gateway" }
if ( $gateway ) { $wanip=$gateway.guest.IPAddress[0] }
$relsnap=get-ncvol | where { $_.Name -eq "$CURRENTVLAB" } | get-ncsnapshot | where { $_.Name -eq "master" }
if ( $relsnap ) { $reldate=$relsnap.Created }
else { $reldate = "NOT RELEASED" }

Write-Host "<table>"
Write-Host "<tr><td><b>Name:</b></td><td> $CURRENTVLAB </td></tr>"
Write-Host "<tr><td><b>Date:</b></td><td> $reldate </td></tr>"
if ( $wanip ){ 
    $row='<tr><td><b>IP:</b></td><td><a href="rdp://'
    $row+="$wanip"
    $row+='=s:'+"$CURRENTVLAB"+':3389&audiomode=i:2&disable%20themes=i:1">'+"$wanip"+'</a></td></tr>' 
    Write-Host $row }
Write-Host "</table>"

Write-Host "<br><b>Virtual Machines:</b><br>"
Write-Host "<table>"
Write-Host "<tr><td><u>Name</u></td><td><u>PowerState</u></td><td><u>Num CPUs</u></td><td><u>MemoryGB</u></td></tr>"
$vms=get-vapp | where { $_.Name -eq "$CURRENTVLAB" } | get-vm | sort Name 
foreach ($vm in $vms) {
    Write-Host "<tr>"
    Write-Host "<td>"$vm.Name"</td>"
    Write-Host "<td>"$vm.PowerState"</td>"
    Write-Host "<td>"$vm.NumCpu"</td>"
    Write-Host "<td>"$vm.MemoryGB"</td>"
    Write-Host "</tr>"
}

Write-Host "</table>"

#}

