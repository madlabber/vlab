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
    $conf=. "$ScriptDirectory\get-vlabsettings.ps1"

    #write-host "<a href=/config>Configuration Settings</a>"
    #write-host "<br><br><a href=https://$defaultVIServer` target=_blank>VMware vCenter</a>"
    #write-host "<br><br><a href=https://$CurrentNcController` target=_blank>OnCommand System Manager</a>"
    #write-host "<br>"

    $VMHosts=get-cluster $conf.VICluster | get-vmhost
    $CpuUsageMhz=($VMHosts | measure-object -property CpuUsageMhz -sum).sum
    $CpuTotalMhz=($VMHosts | measure-object -property CpuTotalMhz -sum).sum
    $MemoryUsageGB=($VMHosts | measure-object -property MemoryUsageGB -sum).sum
    $MemoryTotalGB=($VMHosts | measure-object -property MemoryTotalGB -sum).sum
    $NCAggrs=$(foreach ($aggr in $((get-ncvol | where  {$_.Name -like "lab_*"}).aggregate | sort-object | get-unique)){get-ncaggr $aggr})
    Write-Host "</center><table><tr><td align=center>Hosts</td><td> </td><td align=center>CPU</td><td> </td><td align=center>Memory</td><td> </td><td width=25% align=center>Storage</td></tr>"
    Write-Host "<tr>"
    Write-Host "<td align=center><h1> "$VMHosts.count" <h1></td><td width=25px> </td>"
    Write-Host "<td align=center><h1> "$($CpuUsageMhz/$CpuTotalMhz).tostring('p0').Replace(' ','')" </h1></td><td width=25px> </td>"
    Write-Host "<td align=center><h1> "$($MemoryUsageGB/$MemoryTotalGB).tostring('p0').Replace(' ','')" </h1></td><td width=25px> </td>"
    Write-Host "<td align=center> -- </td>" 
    Write-Host "<tr><td align=center></td><td></td>"
    Write-Host "<td align=center><h6> "$CpuUsageMhz" / "$CpuTotalMhz" Mhz </h6></td><td> </td>"
    Write-Host "<td align=center><h6> "$MemoryUsageGB.tostring("n2")" /"$MemoryTotalGB.tostring("n2")"GB </h6></td><td width=25px> </td>"
    Write-Host "<td align=center> -- </td>" 
    Write-Host "</tr></table></center>"
    # foreach ($aggr in $((get-ncvol | where  {$_.Name -like "lab_*"}).aggregate | sort-object | get-unique)){get-ncaggr $aggr}
    # (foreach ($aggr in $((get-ncvol | where  {$_.Name -like "lab_*"}).aggregate | sort-object | get-unique)){get-ncaggr $aggr}).TotalSize
} -ArgumentList $ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue
