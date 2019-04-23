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

$wanip=""
$reldate=""
$gateway=get-vapp "$CURRENTVLAB" | get-vm | where { $_.Name -eq "gateway" }
if ( $gateway ) { $wanip=$gateway.guest.IPAddress[0] }
$relsnap=get-ncvol | where { $_.Name -eq "$CURRENTVLAB" } | get-ncsnapshot | where { $_.Name -eq "master" }
if ( $relsnap ) { $reldate=$relsnap.Created }
else { $reldate = "NOT RELEASED" }

Write-Host "<table><tr><td valign=top width=40%>"
Write-Host "<table>"
Write-Host "<tr><td><b>Name:</b></td><td> $CURRENTVLAB </td></tr>"
Write-Host "<tr><td><b>Date:</b></td><td> $reldate </td></tr>"
if ( $wanip ){ 
    $row='<tr><td><b>IP:</b></td><td><a href="rdp://full%20address=s:'
    $row+="$wanip"
    $row+=':3389&audiomode=i:2&disable%20themes=i:1">'+"$wanip"+'</a></td></tr>' 
    Write-Host $row }

Write-Host "</table>"

Write-Host "<br><b>Virtual Machines:</b><br>"
Write-Host "<table>"
Write-Host "<tr><td><u>Name</u></td><td><u>PowerState</u></td><td><u>vCPUs</u></td><td><u>MemoryGB</u></td></tr>"
$vms=get-vapp | where { $_.Name -eq "$CURRENTVLAB" } | get-vm | sort Name 
foreach ($vm in $vms) {
    Write-Host "<tr>"
    Write-Host "<td>"$vm.Name"</td>"
    Write-Host "<td>"$vm.PowerState"</td>"
    Write-Host "<td align=center> "$vm.NumCpu"</td>"
    Write-Host "<td> "$vm.MemoryGB"</td>"
    Write-Host "</tr>"
}

Write-Host "</table>"
Write-Host "</td><td  valign=top>"
$diagram="$CURRENTVLAB`.jpg"
if ( Test-Path "$ScriptDirectory\$diagram" -PathType Leaf ){
Write-Host "<img src=$diagram alt=lab_diagram width=500>"}
Write-Host "</td></tr></table>"
} -ArgumentList $CURRENTVLAB,$ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 6000 -WarningAction silentlyContinue
#}

