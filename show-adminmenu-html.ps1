<#
.SYNOPSIS
	This script returns a collection of vlab FlexClone volumes
.DESCRIPTION
	This script returns a collection of vlab FlexClone volumes
.EXAMPLE

.NOTES
    Parameters are supplied by configuration file.
#>
Param(
    [Parameter(Position=1)][string]$CURRENTVLAB
)

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Keep a session to maintain state
$session=get-pssession -ComputerName "localhost" -Name "node-vlab" | where { $_.State -eq "Disconnected" } | select-object -first 1
if ($session) { $result=$session | connect-pssession }
else { 
    $session=new-pssession -ComputerName "localhost" -Name "node-vlab" 
    $result=$session | connect-pssession
    $result=invoke-command -session $session -scriptblock {
        param($ScriptDirectory)
        $conf=. "$ScriptDirectory\get-vlabsettings.ps1"
        #& "$ScriptDirectory\Connect-vLabResources.ps1"
    } -ArgumentList $ScriptDirecoy
}

$result=invoke-command -session $session -scriptblock { 
param($CURRENTVLAB,
      $ScriptDirectory
)

# Settings
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
#& "$ScriptDirectory\Connect-vLabResources.ps1"

write-host "<a href=/config>Configuration Settings</a>"
write-host "<br><br><a href=https://$defaultVIServer` target=_blank>VMware vCenter</a>"
write-host "<br><br><a href=https://$CurrentNcController` target=_blank>OnCommand System Manager</a>"
write-host "<br>"

} -ArgumentList $CURRENTVLAB,$ScriptDirectory

$result=disconnect-pssession -Name "node-vlab" -IdleTimeoutSec 6000 -WarningAction silentlyContinue
#}

