<#
.SYNOPSIS
	This script returns the html table for the admin menu
.DESCRIPTION
	This script returns the html table for the admin menu
.EXAMPLE

.NOTES
    Parameters are supplied by configuration file.
#>

$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    param($ScriptRoot)

    #Collect Objects  
    $conf=Get-Content "$ScriptRoot\settings.cfg" | Out-String | ConvertFrom-StringData  
    $descriptions=Get-Content "$ScriptRoot\cmdb\descriptions.tbl" | Out-String | ConvertFrom-StringData            
    $vols=get-ncvol -volume "lab_*" -vserver $conf.vserver -WarningAction silentlyContinue | sort Name
    $labs=$vols | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }
    $instances=$vols | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }
    $VMHosts=get-cluster $conf.VICluster | get-vmhost
    $NCAggrs=$(foreach ($aggr in $(($vols | where  {$_.Name -like "lab_*"}).aggregate | sort-object | get-unique)){get-ncaggr $aggr})
    $vApps=get-vapp | where { $_.Name -like "lab_*" }
    $running=$vApps | where {$_.Status -eq "Started"}

    # Measure Objects
    $CpuUsageMhz=($VMHosts | measure-object -property CpuUsageMhz -sum).sum
    $CpuTotalMhz=($VMHosts | measure-object -property CpuTotalMhz -sum).sum
    $MemoryUsageGB=($VMHosts | measure-object -property MemoryUsageGB -sum).sum
    $MemoryTotalGB=($VMHosts | measure-object -property MemoryTotalGB -sum).sum
    $TotalDisk=($NCAggrs | measure-object -property TotalSize -sum).sum / 1GB
    $AvailableDisk=($NCAggrs | measure-object -property Available -sum).sum / 1GB

    # reset the timer
    $timer = [System.Diagnostics.Stopwatch]::StartNew()


} -ArgumentList $PSScriptRoot

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 3600 -WarningAction silentlyContinue
