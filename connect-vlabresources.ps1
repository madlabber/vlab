<#
.SYNOPSIS
	This script established connection to vLab resources
.DESCRIPTION
	This script established connection to vLab resources
.EXAMPLE

.NOTES

#>

# Load config
$conf=Get-Content "$PSScriptRoot\settings.cfg" | Out-String | ConvertFrom-StringData

#region Import modules
  # NetApp Powershell Toolkit
  $ncModule=get-module | where { $_.Name -eq "DataONTAP" }
  if ( !$ncModule ) { 
    Import-Module "C:\Program Files (x86)\NetApp\NetApp PowerShell Toolkit\Modules\DataONTAP" 
  }
	
  # VMware PowerCLI module
  $viModule=get-module | where { $_.Name -eq "VMware.VimAutomation.Core" }
  if ( !$viModule ) {
     import-module VMware.VimAutomation.Core
  }
#endregion

#region Establish connections	
	# Connect to vCenter
	if (  $defaultVIServer.Name -ne $conf.vCenter ) {
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		$VICred = Import-CliXml "$PSScriptRoot\vicred.clixml"
		$result=$(Connect-VIServer -Server $conf.vCenter -credential $VICred )
	}
	if ( ! $defaultVIServer.IsConnected ) {
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		$VICred = Import-CliXml "$PSScriptRoot\vicred.clixml"
		$result=$(Connect-VIServer -Server $conf.vCenter -credential $VICred )
	}	
	# Connect to NetApp Cluster	
	if ( $CurrentNcController.Name -ne $conf.cluster_mgmt ) {
		$NCCred = Import-CliXml "$PSScriptRoot\nccred.clixml"
		$result=$(Connect-NcController $conf.cluster_mgmt -vserver $conf.vserver -credential $NCCred )
	}
#endregion
