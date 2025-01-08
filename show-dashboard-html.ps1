<#
.SYNOPSIS
	This script returns the html for the dashboard
.DESCRIPTION
	This script returns the html for the dashboard
.EXAMPLE

.NOTES
    Parameters are supplied by configuration file.
#>

$session=.\get-vlabsession.ps1
$result=invoke-command -session $session -scriptblock { 
    param($ScriptDirectory)
    
    # Manage the refresh timer
    $refresh=$false
    if(!$timer){$timer = [System.Diagnostics.Stopwatch]::StartNew()}
    if($timer.elapsed.minutes -ge 1){$refresh=$true}
    if(!$VMHosts){$refresh=$true}

    # Gather data
    if($refresh){
        #Collect Objects  
        $conf=Get-Content "$ScriptDirectory\settings.cfg" | Out-String | ConvertFrom-StringData            
        $vols=get-ncvol -volume "lab_*" -vserver $conf.vserver -WarningAction silentlyContinue
        $labs=$vols | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }
        $instances=$vols | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }
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
     "<center><table style=`"display: inline-block;`">",
       "<tr>",
          "<td align=center>",
            "<table style=`"display: inline-block;`">",
              "<tr><td colspan=`"7`"><b><h3><center>Labs</center></h3></b></td>",
              "</tr><tr><td width=25px></td>",  
                "<td>Available</td>   <td width=25px></td>",
                "<td>Provisioned</td> <td width=25px></td>",
                "<td>Running</td>     <td width=25px></td>",
              "</tr><tr><td width=25px></td>",
                "<td align=center><h1>$($labs.count)</h1></td>      <td width=25px></td>",
                "<td align=center><h1>$($instances.count)</h1></td> <td width=25px></td>",
                "<td align=center><h1>$($running.count)</h1></td>   <td width=25px></td>",
              "</tr><tr><td width=25px></td>",
                "<td><h6>:</h6></td><td width=25px></td>",
                "<td></td><td width=25px></td>",
                "<td></td><td width=25px></td>",
              "</tr>",
            "</table>",
            "<table style=`"display: inline-block;`">",
              "<tr><td colspan=`"9`"><b><h3><center>Resources</center></h3></b></td>",
              "</tr><tr><td width=25px></td>",
                "<td align=center>Hosts</td><td width=25px></td>",
                "<td align=center>CPU</td><td width=25px></td>",
                "<td align=center>Memory</td><td width=25px></td>",
                "<td align=center>Storage</td><td width=25px></td>",
              "</tr><tr><td width=25px></td>",
                "<td align=center><h1>$($VMHosts.count)</h1></td><td width=25px></td>",
                "<td align=center><h1>$($($CpuUsageMhz/$CpuTotalMhz).tostring('p0').Replace(' ',''))</h1></td><td width=25px></td>",
                "<td align=center><h1>$($($MemoryUsageGB/$MemoryTotalGB).tostring('p0').Replace(' ',''))</h1></td><td width=25px></td>",
                "<td align=center><h1>$($(($TotalDisk-$AvailableDisk)/$TotalDisk).tostring('p0').Replace(' ',''))</h1></td><td width=25px></td>",
              "</tr><tr><td width=25px></td>",
                "<td align=center><h6> $($conf.VICluster)</h6></td><td width=25px></td>",
                "<td align=center><h6> $($CpuUsageMhz) / $($CpuTotalMhz) Mhz </h6></td><td width=25px></td>",
                "<td align=center><h6> $($MemoryUsageGB.tostring("n2")) / $($MemoryTotalGB.tostring("n2"))GB </h6></td><td width=25px></td>",
                "<td align=center><h6> $($($TotalDisk-$AvailableDisk).tostring('n2')) / $($TotalDisk.tostring('n2')) GB </h6></td><td width=25px></td></tr>",
            "</table>",
          "</td>",
       "</tr>",
    "</table></center>" | Write-Host 

} -ArgumentList $PSScriptRoot

# Disconnect from the session
$result=$session | disconnect-pssession -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# Keep the powershell process alive so the output can reach the node.js front end.
start-sleep -Milliseconds 50