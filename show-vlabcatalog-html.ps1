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

    # Manage the refresh timer
    $refresh=$false
    if(!$timer){$timer = [System.Diagnostics.Stopwatch]::StartNew()}
    if($timer.elapsed.minutes -ge 5){$refresh=$true}
    if(!$VMHosts){$refresh=$true}
    if(!$descriptions){$refresh=$true}

    # Gather data
    if($refresh){
        # config files
        $conf=. "$ScriptDirectory\get-vlabsettings.ps1" 

        # Descriptions
        $descriptions=. "$ScriptDirectory\get-vlabdescriptions.ps1"

        # Catalog entries are vols that are not flexclones
        $vols=get-ncvol
        $labs=$vols | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }
        $instances=$vols | where { $_.Name -like "lab_*" } | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }

        # reset the timer
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
    }

    # Output in HTML format
    $output="<table>"
    $output+="<tr><td width=10></td><td><u>Name</u></td><td width=5></td><td><u>Description</u></td></tr>"
    foreach($lab in $labs){
        $output+="<tr><td ></td>"
        $output+='<td nowrap valign="top"><a href="/item?'+$lab+'">'+$lab+'</a></td>'      
        $output+="<td></td><td>"    
        $output+=$descriptions[$lab.Name]
        $output+="</td></tr>"
    }
    $output+="</table>"
    $output | Write-Host
} -ArgumentList $ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# This keeps the powershell process from ending before all of the output has reached the node.js front end.
start-sleep -Milliseconds 50
