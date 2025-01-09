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

$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    param($CURRENTVLAB,
          $ScriptDirectory
    )
    # Load config
    $conf=Get-Content "$ScriptDirectory\settings.cfg" | Out-String | ConvertFrom-StringData

    # Descriptions
    $descriptions=Get-Content "$ScriptDirectory\cmdb\descriptions.tbl" | Out-String | ConvertFrom-StringData

    # Get this vApp
    $vApp=get-vapp "$CURRENTVLAB"
    #$vms=$vApp | get-vm | sort Name 

    # Find the WAN IP of the gateway VM
    $wanip=""
    $gateway=$vApp | get-vm | where { $_.Name -like "*gateway*" }
    if ( $gateway ) { $wanip=$gateway.guest.IPAddress[0] }

    # Find the master snapshot and date
    $labvol=get-ncvol -volume "$CURRENTVLAB" -vserver $conf.vserver -WarningAction silentlyContinue
    #$relsnap=$labvol | get-ncsnapshot | where { $_.Name -eq "master" }
    $relsnap=get-ncsnapshot -vserver $conf.vserver -volume "$CURRENTVLAB" | where { $_.Name -eq "master" }
    if ( $relsnap ) { $reldate=$relsnap.Created }
    else { $reldate = "-" }

    # Find the parent volume (primary key in the description table)
    $parent=$labvol.VolumeCloneAttributes.VolumeCloneParentAttributes.Name 
    if ( ! $parent ) { $parent=$CURRENTVLAB}
	
	# overrides
	$labconf="$parent`.conf"
    if( Test-Path "$ScriptDirectory\cmdb\$labconf" ){
	    $overrides=Get-Content "$ScriptDirectory\cmdb\$labconf" | Out-String | ConvertFrom-StringData 
        ForEach ($Key in $overrides.Keys) {$conf.$Key = $overrides.$Key}	
    }
	
 #    write-host "$ScriptDirectory\cmdb\$labconf"
	# write-host "$($conf.rdpprotocol)"
 #    write-host "$($conf.rdpdomain)"
 #    write-host "$($conf.rdpuser)"
 #    write-host "$($conf.rdppassword)"

    # Get the RDP password hash
	$URI="http://localhost/myrtille/GetHash.aspx?password=$($conf.rdppassword)"
    $rdphash=$(Invoke-WebRequest -URI "$URI" -UseBasicParsing).content

    # RDP URI link for old Safari and iOS
    $rdpuri="rdp://full%20address=s:$($wanip):3389&audiomode=i:2&disable%20themes=i:1"

    # RDP URL for Myrtille
    $rdpurl="$($conf.rdphost)/Myrtille/?__EVENTTARGET=&__EVENTARGUMENT="
    $rdpurl+="&server=$wanip"
    $rdpurl+="&domain=$($conf.rdpdomain)"
    $rdpurl+="&user=$($conf.rdpuser)"
    $rdpurl+="&passwordHash=$rdphash"
    $rdpurl+="&connect=Connect%21"

    # info table
    Write-Host "<table>"
    Write-Host "<tr><td><b>Name:</b></td><td> $CURRENTVLAB </td></tr>"
    Write-Host "<tr><td><b>Description:</b></td><td> $($descriptions[$parent]) </td></tr>"
    Write-Host "<tr><td><b>Date:</b></td><td> $reldate </td></tr>"
    if ( $wanip ){ 
        Write-Host "<tr><td><b>RDP:</b></td><td><a href=`"$rdpuri`">$wanip</a></td></tr>"
        Write-Host "<tr><td><b>Browser:</b></td><td><a href=`"$rdpurl`" target=_blank> Connect </a></td></tr>"
    }
    Write-Host "</table><br>"

    # Virtual Machines table
    Write-Host "<table style=`"display: inline-block;`"><tr><td valign=top>"
    Write-Host   "<table style=`"display: inline-block;`" valign=top><tr><td valign=top>"
    Write-Host     "<b>Virtual Machines:</b><hr>"
    Write-Host     "<table style=`"display: inline-block;`">"
    Write-Host       "<tr><td valign=top><u>Name</u></td><td><u>PowerState</u></td><td><u>CPUs</u></td><td><u>Ram(GB)</u></td></tr>"
    $vms=$vApp | get-vm | sort Name 
    $sumMemoryGB=0
    $sumCPUs=0
    foreach ($vm in $vms) {
        $shortname=$vm.Name
        if( $vm.Name.substring(0,$parent.length) -eq $parent ){
            $shortname=$vm.Name.substring($parent.length+1,($vm.Name.length-$parent.length-1))}
        Write-Host   "<tr>"
        Write-Host     "<td width=120px>"$shortname"</td>"
        Write-Host     "<td>"$vm.PowerState"</td>"
        Write-Host     "<td align=center> "$vm.NumCpu"</td>"
        Write-Host     "<td> "$vm.MemoryGB"</td>"
        Write-Host   "</tr>"
        $sumMemoryGB+=$vm.MemoryGB
        $sumCPUs+=$vm.NumCpu
    }
    Write-Host        "<tr><td width=120px><b>Total:</b></td><td></td><td align=center><b>$sumCPUs</b></td><td><b>$sumMemoryGB</b></td></tr>"
    Write-Host      "</table>"
    Write-Host   "</tr></td></table>"

    # Lab Topology Diagram
   # Write-Host "</td><td valign=top>"
    $diagram="$parent`.jpg"
    if ( Test-Path "$ScriptDirectory\cmdb\$diagram" -PathType Leaf ) {
      Write-Host    "<table style=`"display: inline-block;`">"
      Write-Host       "<tr><td valign=top><b>Topology:</b><hr></td></tr>"
      Write-Host       "<tr><td><img style=`"width: 600px;max-width: 100%;height: auto;`" src=$diagram alt=lab_diagram></td></tr>"
      Write-Host    "</table>"
    Write-Host   "</tr></td></table>"

    }
    Write-Host "</td></tr></table>"
} -ArgumentList $CURRENTVLAB,$psscriptroot

$result=$session | disconnect-pssession -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# Keep the powershell process alive so the output can reach the node.js front end.
start-sleep -Milliseconds 50