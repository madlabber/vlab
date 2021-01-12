<#
.SYNOPSIS
	This script returns a set of vLab volumes
.DESCRIPTION
	this script returns a set of vLab volumes
.EXAMPLE

.NOTES

#>


$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    param($ScriptDirectory)   

    # Descriptions
    $descriptions=Get-Content "$ScriptDirectory\cmdb\descriptions.tbl" | Out-String | ConvertFrom-StringData

    #get power status
    $result=get-vapp | foreach { $powerstate = @{} } { $powerstate[$_.Name] = $_.Status }

    # Gather data
    $vols=get-ncvol
    #$labs=$vols | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | sort
    $instances=$vols | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | sort

    # Get the RDP password hash
	  $URI="http://localhost/myrtille/GetHash.aspx?password=$($conf.rdppassword)"
    $passwordhash=$(Invoke-WebRequest -URI "$URI").content

    # Build the output in HTML
    $output='<form action="" method="post"><table>'
    $output+="  <tr>"
    $output+="    <td width=10px align=right></td>" 
    $output+="    <td width=20%  align=left ><u>Name</u></td>"
    $output+="    <td                       ><u>Description</u></td>"     
    $output+="    <td                       ><u>Status</u></td>" 
    $output+="    <td            align=left ><u>Manage</u></td>"
    $output+="    <td            align=left ><u>Datastore</u></td>"
    $output+="    <td            align=left ><u>Controls</u></td>"
    $output+="    <td            align=left ><u>Sessions</u></td>"
 
    $output+="  </tr>"
    foreach($instance in $instances){
	  $parent=$instance.VolumeCloneAttributes.VolumeCloneParentAttributes.Name
	  if ( ! $parent ) { $parent=$instance.Name}
	  
	  # overrides
	  $labconf="$parent`.conf"
	  $overrides=Get-Content "$ScriptDirectory\cmdb\$labconf" | Out-String | ConvertFrom-StringData 

	  # RDP Credentials
	  $rdpdomain=$conf.rdpdomain
	  $rdpuser=$conf.rdpuser
	  $rdppassword=$conf.rdppassword
	  $rdphash=$passwordhash
	  # RDP Overrides
	  if ("$($overrides.rdpdomain)" -ne ""){$rdpdomain=$overrides.rdpdomain}
	  if ("$($overrides.rdpuser)" -ne ""){$rdpuser=$overrides.rdpuser}
	  if ("$($overrides.rdppassword)" -ne ""){
	      $rdppassword=$overrides.rdppassword
		  $URI="http://localhost/myrtille/GetHash.aspx?password=$($overrides.rdppassword)"
          $rdphash=$(Invoke-WebRequest -URI "$URI").content
	  }
	  
      $output+="<tr>" 
      if ( $powerstate[$instance.name] -eq "Started"){
          $output+="  <td valign=top align=right><font color=green>&#9864</font></td>"        
      }
      else {
          $output+="  <td></td>"        
      }

      if ("$($powerstate[$instance.Name])" -eq ""){$powerstate[$instance.Name]="Removed"}

      $output+='  <td valign=top><a href="/instance?'+$instance+'">'+$instance+'</a></td>' 
      $output+="  <td valign=top>"+$descriptions[$instance.Name]+"</td>"       
      $output+="  <td valign=top>"+$powerstate[$instance.Name]+"</td>" 
      #Action buttons:
      $output+="    <td>"
    # $output+="      <input type=button value=Start onclick=`"window.open('$starturl')`"/>"
      $output+="      <button type=`"submit`" formaction=`"/import?$($instance.name)`">Import</button>"
      $output+="      <button type=`"submit`" formaction=`"/destroy?$($instance.name)`">Remove</button>"
      $output+="      <button type=`"submit`" formaction=`"/newsnap?$($instance.name)`">Snapshot</button>"
      $output+="      <button type=`"submit`" formaction=`"/rename?$($instance.name)`">Rename</button>"  
      $output+="      <button type=`"submit`" formaction=`"/provision?$($instance.name)`">Provision</button>"         
      $output+="    </td><td>"      
      $output+="      <button type=`"submit`" formaction=`"/authoron?$($instance.name)`">Mount</button>"
      $output+="      <button type=`"submit`" formaction=`"/authoroff?$($instance.name)`">Unmount</button>"
      $output+="    </td><td>"      
      $output+="      <button type=`"submit`" formaction=`"/start?$($instance.name)`">Start</button>"
      $output+="      <button type=`"submit`" formaction=`"/stop?$($instance.name)`">Stop</button>"
      $output+="      <button type=`"submit`" formaction=`"/kill?$($instance.name)`">Kill</button>"
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
            $rdpurl+="&domain=$rdpdomain"
            $rdpurl+="&user=$rdpuser"
            $rdpurl+="&passwordHash=$($rdphash.trim())"
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
} -ArgumentList $PSScriptRoot

$result=$session | disconnect-pssession -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# Keep the powershell process alive so the output can reach the node.js front end.
start-sleep -Milliseconds 50
