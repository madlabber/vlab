# Keep a session to maintain state

# Search for an existing session
$session=""
$session=get-pssession -ComputerName "localhost" -Name "node-vlab" | where { $_.State -eq "Disconnected" } | where { $_.Availability -eq "none" } | select-object -first 1

# if a session exists, attempt to connect to it
if ($session.count -gt 0) { 
    $result=$session | connect-pssession }

# if no session exists, or the connection attempt failed, start a new session
if ($result.count -ne 1) { 
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