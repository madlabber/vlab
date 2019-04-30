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
    $output="<table>"
    $output+="  <tr>" 
    $output+="    <td width=180px><u>Name</u></td><td> </td>" 
    $output+="    <td><u>Status</u></td><td> </td>" 
    $output+="    <td><u>TotalSize</u></td><td> </td>" 
    $output+="    <td><u>Used</u></td><td> </td>" 
   # $output+="    <td><u>Available</u></td><td> </td>" 
    $output+="    <td><u>Description</u></td>" 
    $output+="  </tr>"
    foreach($instance in $instances){
      $output+="<tr>" 
      $output+='  <td><a href="/instance?'+$instance+'">'+$instance+'</a></td><td> </td>' 
      $output+="  <td>"+$powerstate[$instance.Name]+"</td><td> </td>" 
      $output+="  <td align=right>"+($instance.TotalSize / 1GB).tostring("n1")+" GB</td><td> </td>" 
      $output+="  <td>"+$($instance.Used/100).tostring("p0")+"</td><td> </td>" 
     # $output+="  <td>"+($instance.Available / 1GB).tostring("n1")+" GB</td><td> </td>" 
      $output+="  <td>"+$descriptions[$instance.VolumeCloneAttributes.VolumeCloneParentAttributes.Name]+"</td>" 
      $output+="</tr>"
    }
    $output+="</table>"
    $output | Write-Host
} -ArgumentList $ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue

#This keeps the powershell process from ending before all of the output has reached the node.js front end.
start-sleep -Milliseconds 50
