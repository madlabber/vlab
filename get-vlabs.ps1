<#
.SYNOPSIS
	This script returns a collection of vlab FlexClone volumes
.DESCRIPTION
	This script returns a collection of vlab FlexClone volumes
.EXAMPLE

.NOTES
    Parameters are supplied by configuration file.
#>

# Settings
$conf=Get-Content "$PSScriptRoot\settings.cfg" | Out-String | ConvertFrom-StringData
& "$PSScriptRoot\Connect-vLabResources.ps1"

# List volumes that start with lab_ that are NOT flexclones
get-ncvol | where { $_.Name -like "lab_*" } | where { $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name } | sort
