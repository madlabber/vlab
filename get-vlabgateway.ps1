<#
.SYNOPSIS
	This script returns the WAN IP of the vLab Gateway
.DESCRIPTION
	This script returns the WAN IP of the vLab Gateway
.PARAMETER	vApp
	Name of the source vApp
.EXAMPLE

.NOTES

#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$vApp
)

# Settings
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

$i = 1
DO {
$wanip=$(get-vapp $vApp | get-vm | where { $_.Name -eq "gateway" }).guest.IPAddress[0]
$i++
} While ( $i -lt 120 -and "$wanip" -eq "" )
write-host $wanip 
