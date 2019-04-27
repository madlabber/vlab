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

    # Catalog entries are vols that are not flexclones
    $labvols=get-ncvol | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }

    # Output in HTML format
    $output="<table>"
    $output+="<tr><td width=180px><u>Name</u></td><td></td><td><u>Description</u></td></tr>"
    foreach($labvol in $labvols){
        $output+='<tr><td><a href="/item?'+$labvol+'">'+$labvol+'</a></td>'      
        $output+="<td></td><td>"    
        $output+=$descriptions[$labvol.Name]
        $output+="</td></tr>"
    }
    $output+="</table>"
    $output | Write-Host
} -ArgumentList $ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue

#This keeps the powershell process from ending before all of the output has reached the node.js front end.
start-sleep -Milliseconds 50