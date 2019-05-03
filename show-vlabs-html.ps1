<#
.SYNOPSIS
	This script returns a collection of vlab FlexClone volumes
.DESCRIPTION
	This script returns a collection of vlab FlexClone volumes
.EXAMPLE

.NOTES
    Parameters are supplied by configuration file.
#>

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    param($ScriptDirectory)   

    # Descriptions
    $descriptions=. "$ScriptDirectory\get-vlabdescriptions.ps1"

    #get power status
    $result=get-vapp | foreach { $powerstate = @{} } { $powerstate[$_.Name] = $_.Status }

    # Gather data
    $vols=get-ncvol
    #$labs=$vols | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | sort
    $instances=$vols | where { $_.Name -like "lab_*" } | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | sort

    # Build the output in HTML
    $output='<form action=""><table>'
    $output+="  <tr>"
    $output+="    <td width=10></td>" 
    $output+="    <td width=180px><u>Name</u></td><td> </td>"
    $output+="    <td width=360px><u>Description</u></td>"     
    $output+="    <td width=60px><u>Status</u></td><td width=10></td>" 
#    $output+="    <td width=70px align=right><u>TotalSize</u></td><td> </td>" 
#    $output+="    <td width=60px align=right><u>Used</u></td><td width=10> </td>" 
    $output+="    <td width=60px align=left><u>Session</u></td><td width=10></td>"
   # $output+="    <td><u>Available</u></td><td> </td>" 
 
    $output+="  </tr>"
    foreach($instance in $instances){
      $output+="<tr>" 
      if ( $powerstate[$instance.name] -eq "Started"){
      $output+="  <td><font color=green>&#9864</font></td>"        
      }
      else {
      $output+="  <td></td>"        
      }

      $output+='  <td><a href="/instance?'+$instance+'">'+$instance+'</a></td><td> </td>' 
      $output+="  <td>"+$descriptions[$instance.VolumeCloneAttributes.VolumeCloneParentAttributes.Name]+"</td>"       
      $output+="  <td>"+$powerstate[$instance.Name]+"</td><td> </td>" 
#      $output+="  <td align=right>"+($instance.TotalSize / 1GB).tostring("n1")+" GB</td><td> </td>" 
#      $output+="  <td align=right>"+$($instance.Used/100).tostring("p0")+"</td><td> </td>" 
    
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
            $rdpurl+="&passwordHash=$($conf.passwordhash)"
            $rdpurl+="&connect=Connect%21"
        }
      }
      if ( $rdpurl ){
          $output+="<td>"
        #  $output+="<a href=`"$rdpurl`" target=_blank>Connect</a>"
          $output+="<input type=button style=`"background-color:green;color:white`" value=Connect onclick=`"window.open('$rdpurl')`"/>"
          $output+='</td><td></td>'
      }
      else {
          $output+="<td></td><td></td>"
      }
    # $output+="  <td>"+($instance.Available / 1GB).tostring("n1")+" GB</td><td> </td>" 
      $output+="</tr>"
    }
    $output+="</table></form>"
    $output | Write-Host
} -ArgumentList $ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue

#This keeps the powershell process from ending before all of the output has reached the node.js front end.
start-sleep -Milliseconds 50
