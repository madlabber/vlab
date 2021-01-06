<#
.SYNOPSIS
	This script start a vLab vApp
.DESCRIPTION
	This script start a vLab vApp
.PARAMETER	vApp
	Name of the vLab vApp
.EXAMPLE

.NOTES

#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$vApp
)

$conf=Get-Content "$PSScriptRoot\settings.cfg" | Out-String | ConvertFrom-StringData 
& "$psscriptroot\Connect-vLabResources.ps1"
	
get-vapp $vApp | get-vm | start-vm
