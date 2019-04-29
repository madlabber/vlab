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

    #get power status
    $result=get-vapp | foreach { $powerstate = @{} } { $powerstate[$_.Name] = $_.Status }

    # Gather data
    $vols=get-ncvol
    #$labs=$vols | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | sort
    $instances=$vols | where { $_.Name -like "lab_*" } | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | sort

    # Build the output in HTML
    $output="<table>"
    $output+="<tr>" `
            +"<td width=180px><u>Name</u></td><td></td>" `
            +"<td><u>Status</u></td><td></td>" `
            +"<td><u>TotalSize</u></td><td></td>" `
            +"<td><u>Used</u></td><td></td>" `
            +"<td><u>Available</u></td>" `
            +"</tr>"
    foreach($instance in $instances){
        $output+="<tr>" `
               +'<tr><td><a href="/instance?'+$instance+'">'+$instance+'</a></td><td></td>' `
               +"<td>"+$powerstate[$instance.Name]+"</td><td></td>" `
               +"<td>"+($instance.TotalSize / 1GB).tostring("n1")+" GB</td><td></td>" `
               +"<td>"+$($instance.Used/100).tostring("p0")+"</td><td></td>" `
               +"<td>"+($instance.Available / 1GB).tostring("n1")+" GB</td>" `
               +"</tr>"
    }
    $output+="</table>"
    $output | Write-Host
} 

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue

#This keeps the powershell process from ending before all of the output has reached the node.js front end.
start-sleep -Milliseconds 50
