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

$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    param($CURRENTVLAB,
          $ScriptDirectory
    )

    # Descriptions
    $descriptions=. "$ScriptDirectory\get-vlabdescriptions.ps1"

    # Get this vApp
    $vApp=get-vapp "$CURRENTVLAB"
    #$vms=$vApp | get-vm | sort Name 

    # Find the WAN IP of the gateway VM
    $wanip=""
    $gateway=$vApp | get-vm "gateway"
    if ( $gateway ) { $wanip=$gateway.guest.IPAddress[0] }

    # Find the master snapshot and date
    $labvol=get-ncvol "$CURRENTVLAB" 
    $relsnap=$labvol | get-ncsnapshot | where { $_.Name -eq "master" }
    if ( $relsnap ) { $reldate=$relsnap.Created }
    else { $reldate = "NOT RELEASED" }

    # Find the parent volume (primary key in the description table)
    $parent=$labvol.VolumeCloneAttributes.VolumeCloneParentAttributes.Name 
    if ( ! $parent ) { $parent=$CURRENTVLAB}

    Write-Host "<table>"
    Write-Host "<tr><td><b>Name:</b></td><td> $CURRENTVLAB </td></tr>"
    Write-Host "<tr><td><b>Description:</b></td><td> $($descriptions[$parent]) </td></tr>"
    Write-Host "<tr><td><b>Date:</b></td><td> $reldate </td></tr>"
    if ( $wanip ){ 
        $row='<tr><td><b>IP:</b></td><td><a href="rdp://full%20address=s:'
        $row+="$wanip"
        $row+=':3389&audiomode=i:2&disable%20themes=i:1">'+"$wanip"+'</a></td></tr>' 
        Write-Host $row 
    }
    Write-Host "</table><br>"

    # Virtual Machines table
    Write-Host "<table><tr><td valign=top width=40%>"
    Write-Host "<b>Virtual Machines:</b><hr>"
    Write-Host "<table>"
    Write-Host "<tr><td><u>Name</u></td><td><u>PowerState</u></td><td><u>vCPUs</u></td><td><u>MemoryGB</u></td></tr>"
    $vms=$vApp | get-vm | sort Name 
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

    # Lab Topology Diagram
    Write-Host "</td><td width=10px></td><td  valign=top>"
    $diagram="$parent`.jpg"
    if ( Test-Path "$ScriptDirectory\cmdb\$diagram" -PathType Leaf ){
    Write-Host "<b>Topology:</b><hr>"
    Write-Host "<img src=cmdb/$diagram alt=lab_diagram width=500>"}
    Write-Host "</td></tr></table>"
} -ArgumentList $CURRENTVLAB,$ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue

#This keeps the powershell process from ending before all of the output has reached the node.js front end.
start-sleep -Milliseconds 50

#}

