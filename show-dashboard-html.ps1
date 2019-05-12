<#
.SYNOPSIS
	This script returns the html table for the admin menu
.DESCRIPTION
	This script returns the html table for the admin menu
.EXAMPLE

.NOTES
    Parameters are supplied by configuration file.
#>

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    param($ScriptDirectory)

    #$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
    
    # Manage the refresh timer
    $refresh=$false
    if(!$timer){$timer = [System.Diagnostics.Stopwatch]::StartNew()}
    if($timer.elapsed.minutes -ge 1){$refresh=$true}
    if(!$VMHosts){$refresh=$true}

    # Gather data
    if($refresh){

        #Collect Objects  
        $conf=. "$ScriptDirectory\get-vlabsettings.ps1"              
        $vols=get-ncvol
        $labs=$vols | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }
        $instances=$vols | where { $_.Name -like "lab_*" } | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }
        $VMHosts=get-cluster $conf.VICluster | get-vmhost
        $NCAggrs=$(foreach ($aggr in $(($vols | where  {$_.Name -like "lab_*"}).aggregate | sort-object | get-unique)){get-ncaggr $aggr})
        $running=get-vapp | where { $_.Name -like "lab_*" } | where {$_.Status -eq "Started"}

        # Measure Objects
        $CpuUsageMhz=($VMHosts | measure-object -property CpuUsageMhz -sum).sum
        $CpuTotalMhz=($VMHosts | measure-object -property CpuTotalMhz -sum).sum
        $MemoryUsageGB=($VMHosts | measure-object -property MemoryUsageGB -sum).sum
        $MemoryTotalGB=($VMHosts | measure-object -property MemoryTotalGB -sum).sum
        $TotalDisk=($NCAggrs | measure-object -property TotalSize -sum).sum / 1GB
        $AvailableDisk=($NCAggrs | measure-object -property Available -sum).sum / 1GB

        # reset the timer
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
    }
    # Build the dashboard in HTML
    Write-Host "<center><table style=`"display: inline-block;`">"
    Write-Host   "<tr>"
    Write-Host      "<td align=center>"
    Write-Host        "<table style=`"display: inline-block;`">"
    Write-Host          "<tr><td colspan=`"7`"><b><h3><center>Labs</center></h3></b></td>"
    Write-Host          "</tr><tr><td width=25px></td>"   
    Write-Host            "<td>Available</td>   <td width=25px></td>"
    Write-Host            "<td>Provisioned</td> <td width=25px></td>"
    Write-host            "<td>Running</td>     <td width=25px></td>"
    Write-Host          "</tr><tr><td width=25px></td>"
    Write-Host            "<td align=center><h1>$($labs.count)</h1></td>      <td width=25px></td>"
    Write-Host            "<td align=center><h1>$($instances.count)</h1></td> <td width=25px></td>"
    Write-Host            "<td align=center><h1>$($running.count)</h1></td>   <td width=25px></td>"
    Write-Host          "</tr><tr><td width=25px></td>"
    Write-Host            "<td><h6>:</h6></td><td width=25px></td>"
    Write-Host            "<td></td><td width=25px></td>"
    Write-host            "<td></td><td width=25px></td>"
    Write-Host          "</tr>"
    Write-Host        "</table>"
    Write-Host        "<table style=`"display: inline-block;`">"
    Write-Host          "<tr><td colspan=`"9`"><b><h3><center>Resources</center></h3></b></td>"
    Write-Host          "</tr><tr><td width=25px></td>" 
    Write-Host            "<td align=center>Hosts</td><td width=25px></td>"
    Write-Host            "<td align=center>CPU</td><td width=25px></td>"
    Write-Host            "<td align=center>Memory</td><td width=25px></td>"
    Write-host            "<td align=center>Storage</td><td width=25px></td>"
    Write-Host          "</tr><tr><td width=25px></td>"
    Write-Host            "<td align=center><h1>"$($VMHosts.count)"</h1></td><td width=25px></td>"
    Write-Host            "<td align=center><h1>"$($CpuUsageMhz/$CpuTotalMhz).tostring('p0').Replace(' ','')"</h1></td><td width=25px></td>"
    Write-Host            "<td align=center><h1>"$($MemoryUsageGB/$MemoryTotalGB).tostring('p0').Replace(' ','')"</h1></td><td width=25px></td>"
    Write-Host            "<td align=center><h1>"$(($TotalDisk-$AvailableDisk)/$TotalDisk).tostring('p0').Replace(' ','')"</h1></td><td width=25px></td>"
    Write-Host          "</tr><tr><td width=25px></td>"
    Write-Host            "<td align=center><h6> "$conf.VICluster"</h6></td><td width=25px></td>"
    Write-Host            "<td align=center><h6> "$CpuUsageMhz" / "$CpuTotalMhz" Mhz </h6></td><td width=25px></td>"
    Write-Host            "<td align=center><h6> "$MemoryUsageGB.tostring("n2")" / "$MemoryTotalGB.tostring("n2")"GB </h6></td><td width=25px></td>"
    Write-host            "<td align=center><h6> "$($TotalDisk-$AvailableDisk).tostring('n2')" / "$TotalDisk.tostring('n2')" GB </h6></td><td width=25px></td></tr>"
    Write-Host        "</table>"
    Write-Host      "</td>"
    Write-Host   "</tr>"
    Write-Host "</table></center>"

} -ArgumentList $ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue

#This keeps the powershell process from ending before all of the output has reached the node.js front end.
start-sleep -Milliseconds 50