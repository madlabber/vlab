# Keep a session to maintain state
$session=""
$session=get-pssession -ComputerName "localhost" -Name "node-vlab" | where { $_.State -eq "Disconnected" } | where { $_.Availability -eq "none" } | select-object -first 1
if ($session) { 
    $result=$session | connect-pssession }
else { 
    $session=new-pssession -ComputerName "localhost" -Name "node-vlab" 
    $result=$session | connect-pssession
}

# Make sure the session is logged into the resources
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$result=invoke-command -session $session -scriptblock {
    param($ScriptDirectory)
    & "$ScriptDirectory\Connect-vLabResources.ps1"
} -ArgumentList $ScriptDirectory

$session