<#
.SYNOPSIS
	This script returns a set of vLab volumes
.DESCRIPTION
	this script returns a set of vLab volumes
.EXAMPLE

.NOTES

#>

# Settings
$conf=. "$PSScriptRoot\get-vlabsettings.ps1"
& "$PSScriptRoot\Connect-vLabResources.ps1"
	
# List volumes that start with lab_
get-ncvol | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }
 