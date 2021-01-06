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

    # Manage the refresh timer
    $refresh=$false
    if(!$timer){$timer = [System.Diagnostics.Stopwatch]::StartNew()}
    if($timer.elapsed.minutes -ge 5){$refresh=$true}
    if(!$VMHosts){$refresh=$true}
    if(!$descriptions){$refresh=$true}

    # Gather data
    if($refresh){
        # config files
        $conf=Get-Content "$ScriptDirectory\settings.cfg" | Out-String | ConvertFrom-StringData 

        # Descriptions
        $descriptions=Get-Content "$ScriptDirectory\cmdb\descriptions.tbl" | Out-String | ConvertFrom-StringData

        # Catalog entries are vols that are not flexclones
        $vols=get-ncvol
        $labs=$vols | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | where { $_.Name -notlike "lab__*" }
        $instances=$vols | where { $_.Name -like "lab_*" } | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name -or $_.Name -like "lab__*" }
        #$vApps=get-vapp |  where { $_.Name -like "lab_*" } 
        # reset the timer
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
    }
    $vApps=get-vapp |  where { $_.Name -like "lab_*" } 
    # Output in HTML format
    $output="<table>"
    $output+="  <tr>"
    $output+="    <td width=3% align=left ></td>" 
    $output+="    <td width=20%  align=left ><u>Name</u></td>"
    $output+="    <td width=50%  align=left ><u>Description</u></td>"      
    $output+="  </tr>"
    foreach($lab in $labs){
        if ( ($vApps | where { $_.Name -eq "$lab" }).count -gt 0){
            $output+="<tr>"
            $output+="  <td></td>"
            $output+='  <td nowrap valign="top"><a href="/item?'+$lab+'">'+$lab+'</a></td>'      
            $output+="  <td>$($descriptions[$lab.Name])</td>"
            $output+="</tr>"
        }
    }
    $output+="</table>"
    $output | Write-Host
} -ArgumentList $psscriptroot

# Disconnect from the session
$result=$session | disconnect-pssession -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# Keep the powershell process alive so the output can reach the node.js front end.
start-sleep -Milliseconds 50
