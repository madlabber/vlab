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
$vApp=$params[0]
$newDescription=$params[1]



$result=invoke-command -session $session -scriptblock {
  param($ScriptRoot,$vApp,$newDescription)
       
        $errText=""
        if($newDescription -match "[^a-zA-Z0-9_]") {
            $errText="$errText <b>Error: Only letters, numbers and underscore (_) characters are allowed. </b><br>"            
        }

        if("$newDescription" -eq ""){
            $errText="$errText <b>Error: Description should not be empty. </b><br>"            
        }

        if( $(get-vapp $vApp).count -eq 0){
            $errText="$errText <b>Error: $oldName does not exist. </b><br>" 
        }

        
        if ($errText){
          "Current Name: <br><b> $oldName </b>",
          "<form action=`"/updatedescription`">",
          "<label for=`"oldname`">New Description:</label>",
          "<input type=`"text`" id=`"newname`" name=`"$oldName`" value=`"$oldName`"><br>",
          "$errText",
          "<br><hr><input type=`"submit`" value=`"Submit`"><hr>",
          "</form>" | write-host  
        }
        else{
          #$command = "$ScriptRoot\rename-vlab $oldName $newName"
          #Invoke-Expression $command
          "<br><hr>:<hr>" | write-host 
          #"<script type=`"text/javascript`">window.location = `"/admin`";</script>" | write-host           
        }

    
} -ArgumentList $PSScriptRoot,$params[0],$params[1]    




# Disconnect from the session
$result=$session | disconnect-pssession -IdleTimeoutSec 3600 -WarningAction silentlyContinue

# Keep the powershell process alive so the output can reach the node.js front end.
start-sleep -Milliseconds 50
