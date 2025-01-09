<#
.SYNOPSIS
	This script clones a single volume vApp using FlexClone
.DESCRIPTION
	This script uses FlexClone technology to rapidly create an exact copy of an existing vApp
.PARAMETER	vApp
	(Manadatory)
	Name of the source vApp
.PARAMETER  VMHost
	IP Address (or hostname) of the ESX host.
.EXAMPLE

.NOTES

#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$vApp
)

Write-Host "Authenticating."
$conf=Get-Content "$PSScriptRoot\settings.cfg" | Out-String | ConvertFrom-StringData
& "$PSScriptRoot\Connect-vLabResources.ps1"

$snap=get-ncsnapshot -volume "$vApp" -vserver $conf.vserver  | where { $_.Name -eq "master" }
if ( $snap ){
	$result=rename-ncsnapshot -volume "$vApp" -snapshot "master" -newname "master.$(get-date -format o)"
}
$snap=new-ncsnapshot -volume "$vApp" -vserver $conf.vserver -snapshot "master"

# Drop the snap into the pipeline
$snap
