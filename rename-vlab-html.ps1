<#
.SYNOPSIS
	This script stops a vLab vApp
.DESCRIPTION
	This script stops a vLab vApp
.PARAMETER	vApp
	Name of the vLab vApp
.EXAMPLE

.NOTES

#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$param
)



$session=.\get-vlabsession.ps1

#write-host "Parameters: $param"
$params = $param.split("=")
$oldName=$params[0]
$newName=$params[1]

# New name not specified, or new name is the same as old name
if ( ("$newName" -eq "") -or ( "$oldName" -eq "$newName" )) {
  "Current Name: <br><b> $($params[0])</b>",
  "<form action=`"/rename`">",
    "<label for=`"oldname`">New Name:</label>",
    "<input type=`"text`" id=`"newname`" name=`"$($params[0])`" value=`"$($params[0])`"><br>",
    "<br><hr><input type=`"submit`" value=`"Submit`"><hr>",
  "</form>"  | write-host

}
else{
    $result=invoke-command -session $session -scriptblock {
        param($ScriptRoot,$oldName,$newName)
       
        $errText=""
        if ( "$newName" -notlike "lab_*" ){
            $errText="$errText <b>Error: New name must begin with lab_ </b>"
        }

        if( $(get-vapp $oldName | get-vm | where { $_.PowerState -ne "PoweredOff" }).count -gt 0)
        {
            $errText="$errText <b>Error: Lab must be stopped before it can be renamed. </b><br>"
        }

        if( $(get-vapp $newName).count -gt 0){           
            $errText="$errText <b>Error: $newName alredy exists. </b><br>"
        }

        if( $(get-vapp $oldName).count -eq 0){
            $errText="$errText <b>Error: $oldName does not exist. </b><br>" 
        }

        if ($errText){
          "Current Name: <br><b> $oldName </b>",
          "<form action=`"/rename`">",
          "<label for=`"oldname`">New Name:</label>",
          "<input type=`"text`" id=`"newname`" name=`"$oldName`" value=`"$oldName`"><br>",
          "$errText",
          "<br><hr><input type=`"submit`" value=`"Submit`"><hr>",
          "</form>" | write-host  
        }
        else{
          $command = "$ScriptRoot\rename-vlab $oldName $newName"
          Invoke-Expression $command
          "<br><hr>:<hr>" | write-host 
          "<script type=`"text/javascript`">window.location = `"/admin`";</script>" | write-host           
        }

    
    } -ArgumentList $PSScriptRoot,$params[0],$params[1]    

}



# Disconnect from the session
$result=$session | disconnect-pssession -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# Keep the powershell process alive so the output can reach the node.js front end.
start-sleep -Milliseconds 50
