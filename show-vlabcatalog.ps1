<#
.SYNOPSIS
	This script returns a set of vLab volumes
.DESCRIPTION
	this script returns a set of vLab volumes
.EXAMPLE

.NOTES

#>

# Settings
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
& "$ScriptDirectory\Connect-vLabResources.ps1"

# Descriptions
$descriptions=. "$ScriptDirectory\get-vlabdescriptions.ps1"

#get power status
$result=get-vapp | foreach { $powerstate = @{} } { $powerstate[$_.Name] = $_.Status }
# List volumes that start with lab_
$labvols=get-ncvol | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }
#$report | format-table
$labvols | FT 	@{Label="Name";Expression={$_.Name};width=20}, 
#				@{Label="Status";Expression={$powerstate[$_.Name]};width=8;align='left'}, 
#				@{Label="TotalSize";Expression={($_.TotalSize / 1GB).tostring("n1")+" GB"};width=12;align='right'}, 
#				@{Label="Used";Expression={$($_.Used/100).tostring("p0")};width=5;align='right'}, 
#				@{Label="Available";Expression={($_.Available / 1GB).tostring("n1")+" GB"};width=12;align='right'},
                @{Label="Description";Expression={$descriptions[$_.Name]}}

