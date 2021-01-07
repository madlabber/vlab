<#
.SYNOPSIS
	This script returns a collection of vlab FlexClone volumes
.DESCRIPTION
	This script returns a collection of vlab FlexClone volumes
.EXAMPLE

.NOTES
    Parameters are supplied by configuration file.
#>

$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    param($ScriptDirectory)   

    # Descriptions
    $descriptions=Get-Content "$ScriptDirectory\cmdb\descriptions.tbl" | Out-String | ConvertFrom-StringData

    #conf
    $conf=Get-Content "$ScriptDirectory\settings.cfg" | Out-String | ConvertFrom-StringData 

    #get power status
    $result=get-vapp | foreach { $powerstate = @{} } { $powerstate[$_.Name] = $_.Status }

    # Gather data
    $vols=get-ncvol
    $instances=$vols | where { $_.Name -like "lab_*" } | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name  -or $_.Name -like "lab__*" } | sort

    # Get the RDP password hash
	  $URI="http://localhost/myrtille/GetHash.aspx?password=$($conf.rdppassword)"
    $passwordhash=$(Invoke-WebRequest -URI "$URI").content

    # Build the output in HTML
    # Table Header:
    $output='<form action="" method="post"><table>'
    $output+="  <tr>"
    $output+="    <td width=10px align=right></td>" 
    $output+="    <td width=20%  align=left ><u>Name</u></td>"
    $output+="    <td width=45%             ><u>Description</u></td>"     
    $output+="    <td width=7%              ><u>Status</u></td>" 
    $output+="    <td width=15%  align=left ><u>Controls</u></td>"
    $output+="    <td            align=left ><u>Session</u></td>"
    $output+="  </tr>"

    #Assemble Table Rows
    foreach($instance in $instances){
	    $parent=$instance.VolumeCloneAttributes.VolumeCloneParentAttributes.Name
	    if ( ! $parent ) { $parent=$instance.Name}
	  
	    # overrides
	    $labconf="$parent`.conf"
        if( Test-Path "$ScriptDirectory\cmdb\$labconf" ){
	      $overrides=Get-Content "$ScriptDirectory\cmdb\$labconf" | Out-String | ConvertFrom-StringData }

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

      $rdpurl=""
      $InstanceState=$powerstate[$instance.name]
      if ( $InstanceState -eq "Started"){
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
      if ( $rdpurl -and $wanip ){ $InstanceState="Running" }
      $led="red"
      if ( $InstanceState -eq "Started" -or $InstanceState -eq "Running"){ $led="green" }

      # Construct Table Row
      $output+="<tr>" 
      $output+="  <td valign=top align=right><font color=$led>&#9864</font></td>"        
      $output+='  <td valign=top><a href="/instance?'+$instance+'">'+$instance+'</a></td>' 
      $output+="  <td valign=top>"+$descriptions[$parent]+"</td>"       
      $output+="  <td valign=top>"+$InstanceState+"</td>" 
      #Action buttons:
      $output+="    <td nowrap>"
      $output+="      <button type=`"submit`" formaction=`"/start?$($instance.name)`">Start</button>"
      $output+="      <button type=`"submit`" formaction=`"/stop?$($instance.name)`">Stop</button>"
      $output+="      <button type=`"submit`" formaction=`"/kill?$($instance.name)`">Kill</button>"
      $output+="    </td>"
      #Connect Button
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

#$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue
$result=$session | disconnect-pssession -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# Keep the powershell process alive so the output can reach the node.js front end.
start-sleep -Milliseconds 50