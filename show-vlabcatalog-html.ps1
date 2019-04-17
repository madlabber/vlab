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
#& "$ScriptDirectory\Connect-vLabResources.ps1"
    $ncModule=get-module | where { $_.Name -eq "DataONTAP" }
    if ( !$ncModule ) { 
        import-module DataONTAP 
    }
    # Connect to NetApp Cluster 
    if ( $CurrentNcController.Name -ne $conf.cluster_mgmt ) {
        $NCCred = Import-CliXml "$ScriptDirectory\nccred.clixml"
        $result=$(Connect-NcController $conf.cluster_mgmt -vserver $conf.vserver -credential $NCCred )
    }

# Descriptions
$descriptions=. "$ScriptDirectory\get-vlabdescriptions.ps1"
#load settings from file
#$descriptions = Get-Content ".\descriptions.cfg" | Out-String | ConvertFrom-StringData

# Catalog entries are vols that are not flexclones
$labvols=get-ncvol | where { $_.Name -like "lab_*" } | where { ! $_.VolumeCloneAttributes.VolumeCloneParentAttributes.Name }

$output="<table>"
$output+="<tr><td><u>Name</u></td><td></td><td><u>Description</u></td></tr>"
foreach($labvol in $labvols){
    $output+='<tr><td><a href="/item?'+$labvol+'">'+$labvol+'</a></td>'      
    $output+="<td> : </td><td>"    
    $output+=$descriptions[$labvol.Name]
    $output+="</td></tr>"
}
$output+="</table>"
$output
