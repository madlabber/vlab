<#
.SYNOPSIS
	This script returns a set of vLab volumes
.DESCRIPTION
	this script returns a set of vLab volumes
.EXAMPLE

.NOTES

#>

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    param($ScriptDirectory)   

    # Descriptions
    $descriptions=. "$ScriptDirectory\get-vlabdescriptions.ps1"

    #conf
    $conf=. "$ScriptDirectory\get-vlabsettings.ps1"

    #get power status
    $result=get-vapp | foreach { $powerstate = @{} } { $powerstate[$_.Name] = $_.Status }

    # Gather data
    $vols=get-ncvol
    #$labs=$vols | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | sort
    $instances=$vols | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | sort

    $passwordhash=$(Invoke-WebRequest -URI http://localhost/myrtille/GetHash.aspx?password=P@ssw0rd).content

    # Build the output in HTML
    $output='<form action="" method="post"><table>'
    $output+="  <tr>"
    $output+="    <td width=10px align=right></td>" 
    $output+="    <td width=20%  align=left ><u>Name</u></td>"
    $output+="    <td                       ><u>Description</u></td>"     
    $output+="    <td                       ><u>Status</u></td>" 
    $output+="    <td            align=left ><u>Controls</u></td>"
    $output+="    <td            align=left ><u>Authoring</u></td>"
    $output+="    <td            align=left ><u>Session</u></td>"
 
    $output+="  </tr>"
    foreach($instance in $instances){
      $output+="<tr>" 
      if ( $powerstate[$instance.name] -eq "Started"){
          $output+="  <td valign=top align=right><font color=green>&#9864</font></td>"        
      }
      else {
          $output+="  <td></td>"        
      }

      $output+='  <td valign=top><a href="/instance?'+$instance+'">'+$instance+'</a></td>' 
      $output+="  <td valign=top>"+$descriptions[$instance.Name]+"</td>"       
      $output+="  <td valign=top>"+$powerstate[$instance.Name]+"</td>" 
      #Action buttons:
      $output+="    <td>"
    # $output+="      <input type=button value=Start onclick=`"window.open('$starturl')`"/>"
      $output+="      <button type=`"submit`" formaction=`"/start?$($instance.name)`">Start</button>"
      $output+="      <button type=`"submit`" formaction=`"/stop?$($instance.name)`">Stop</button>"
      $output+="      <button type=`"submit`" formaction=`"/kill?$($instance.name)`">Kill</button>"
      $output+="    </td><td>"      
      $output+="      <button type=`"submit`" formaction=`"/authoron?$($instance.name)`">Enable</button>"
      $output+="      <button type=`"submit`" formaction=`"/authoroff?$($instance.name)`">Disable</button>"
      $output+="      <button type=`"submit`" formaction=`"/import?$($instance.name)`">Import</button>"
      $output+="    </td>"
      $rdpurl=""
      if ( $powerstate[$instance.name] -eq "Started"){
        # Find the WAN IP of the gateway VM
        $wanip=""
        $gateway=get-vapp $instance.name | get-vm "gateway"
        if ( $gateway ) { 
            $wanip=$gateway.guest.IPAddress[0]
            $rdpurl="$($conf.rdphost)/Myrtille/?__EVENTTARGET=&__EVENTARGUMENT="
            $rdpurl+="&server=$wanip"
            $rdpurl+="&domain=$($conf.rdpdomain)"
            $rdpurl+="&user=$($conf.rdpuser)"
            #$rdpurl+="&passwordHash=$($conf.passwordhash)"
            $rdpurl+="&passwordHash=$passwordhash"
            $rdpurl+="&connect=Connect%21"
        }
      }
      if ( $rdpurl -and $wanip ){
          $output+="<td valign=top>"
          $output+="<input type=button style=`"background-color:green;color:white`" value=Connect onclick=`"window.open('$rdpurl')`"/>"
          $output+="</td>"
      }
      else {
          $output+="<td></td>"
      }
      $output+="</tr>"
    }
    $output+="</table></form>"
    $output | Write-Host
} -ArgumentList $ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# This keeps the powershell process from ending before all of the output has reached the node.js front end.
start-sleep -Milliseconds 50
