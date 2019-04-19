<#
.SYNOPSIS
	This script returns a collection of vlab FlexClone volumes
.DESCRIPTION
	This script returns a collection of vlab FlexClone volumes
.EXAMPLE

.NOTES
    Parameters are supplied by configuration file.
#>

# Keep a session to maintain state
$session=get-pssession -ComputerName "localhost" -Name "node-vlab" | where { $_.State -eq "Disconnected" } | select-object -first 1
if ($session) { $result=$session | connect-pssession }
else { 
    $session=new-pssession -ComputerName "localhost" -Name "node-vlab" 
    $result=$session | connect-pssession
    $result=invoke-command -session $session -scriptblock {
        param($ScriptDirectory)
        $conf=. "$ScriptDirectory\get-vlabsettings.ps1"
        & "$ScriptDirectory\Connect-vLabResources.ps1"
    } -ArgumentList $ScriptDirecoy
}

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

$result=invoke-command -session $session -scriptblock { 
param($ScriptDirectory)

# Settings
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

#get power status
$result=get-vapp | foreach { $powerstate = @{} } { $powerstate[$_.Name] = $_.Status }
# List volumes that start with lab_ that are NOT flexclones
$labvols=get-ncvol | where { $_.Name -like "lab_*" } | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | sort

$output="<table>"
$output+="<tr>" `
        +"<td width=180px><u>Name</u></td><td></td>" `
        +"<td><u>Status</u></td><td></td>" `
        +"<td><u>TotalSize</u></td><td></td>" `
        +"<td><u>Used</u></td><td></td>" `
        +"<td><u>Available</u></td>" `
        +"</tr>"
foreach($labvol in $labvols){
    $output+="<tr>" `
            +'<tr><td><a href="/instance?'+$labvol+'">'+$labvol+'</a></td><td></td>' `
            +"<td>"+$powerstate[$labvol.Name]+"</td><td></td>" `
            +"<td>"+($labvol.TotalSize / 1GB).tostring("n1")+" GB</td><td></td>" `
            +"<td>"+$($labvol.Used/100).tostring("p0")+"</td><td></td>" `
            +"<td>"+($labvol.Available / 1GB).tostring("n1")+" GB</td>" `
            +"</tr>"
}
$output+="</table>"
$output | Write-Host
} -ArgumentList $ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 6000 -WarningAction silentlyContinue