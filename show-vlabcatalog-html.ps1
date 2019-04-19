<#
.SYNOPSIS
	This script returns a set of vLab volumes
.DESCRIPTION
	this script returns a set of vLab volumes
.EXAMPLE

.NOTES

#>
# Keep a session to maintain state
$session=get-pssession -ComputerName "localhost" -Name "node-vlab" | where { $_.State -eq "Disconnected" } | select-object -first 1
if ($session) { $result=$session | connect-pssession }
else { 
    $session=new-pssession -ComputerName "localhost" -Name "node-vlab" 
    $result=$session | connect-pssession
}

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

$result=invoke-command -session $session -scriptblock { 
param($ScriptDirectory)

# Settings
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

# Descriptions
$descriptions=. "$ScriptDirectory\get-vlabdescriptions.ps1"

# Catalog entries are vols that are not flexclones
$labvols=get-ncvol | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }

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

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 6000 -WarningAction silentlyContinue