$CURRENTVLAB=""

# Write-Header
function write-header {
		Param ([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]$msg)
		#       "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
		$border="--------------------------------------------------------------------------------------------------------------------"
		$txtbox="                                                                                             | vLAB Automation Kit |"
		$txtright=$txtbox.substring(($msg.length +1))
		
		cls
		Write-Host $border
		write-host " $msg$txtright"
		write-host $border
}

# Main Menu
function menuMain {
    do {
	    Write-Header "Main Menu"
	    #          #1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
    	Write-Host 
	    Write-Host "1. vLab Catalog"
	    Write-Host "2. vLab Instances"
	    Write-Host "3. Admin Menu"
	    Write-Host "X. Exit"
	    Write-Host
	    $input = Read-Host "::>"
	
	    switch ($input) {
	    	'1' { menu1vLabCatalog }
	    	'2' { menu2vLabInstances }
	    	'3' { menuAdminMenu }
	    	'x' { exit }
	    }
	    #pause
    } until ($input -eq 'q')	
}

# vLab Catalog
function menu1vLabCatalog {
	Write-Header "Loading..."
	$vlabCatalog=.\show-vlabcatalog.ps1
	$done=$false
	do {
		write-header "vLab Catalog"
		$vLabCatalog | Format-Table
		#          #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
		Write-Host "--------------------------------------------------------------------------------------------------------------------"
		Write-Host "Enter vLab Name for Details.                                                                    | [R]efresh [B]ack |"
		Write-Host "--------------------------------------------------------------------------------------------------------------------"
		$selection = Read-Host "::>"

		if     ( "$selection" -eq "b" ) { $done=$true }
		elseif ( "$selection" -eq "m" ) { menuMain }
		elseif ( "$selection" -eq "r" ) { $vlabCatalog=.\show-vlabcatalog.ps1 }	
		else {
			$result=.\get-vlabcatalog.ps1 | where { $_.Name -eq "$selection" }
			if ( !$result ) { 
				write-host "Lab "$selection" not found." 
				sleep 2 
			}
			else { 
				$CURRENTVLAB="$selection"
				menu4vLabCatalogDetail 
				$vlabcatalog=.\show-vlabcatalog.ps1 
			}
		}
	} until ( $done )
}

# vLab Instances
function menu2vLabInstances {
	write-header "loading..."
	$vLabList=.\show-vlabs.ps1
	$done=$false
	do {
		write-header "vLab Instances"
		#          #123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
		$vlabList | Format-Table
		Write-Host "--------------------------------------------------------------------------------------------------------------------"
		Write-Host "Enter vLab Name for Details.                                                                     | [R]efresh [B]ack "
		Write-Host "--------------------------------------------------------------------------------------------------------------------"
		$selection=Read-Host "::>"
		if     ( "$selection" -eq "b" ) { $done=$true }
		elseif ( "$selection" -eq "m" ) { menuMain }
		elseif ( "$selection" -eq "r" ) { $vlabList=.\show-vlabs.ps1 }
		else {
			$result=.\get-vlabs.ps1 | where { $_.Name -eq "$selection" }
			if ( !$result ) { 
				write-host "Lab "$selection" not found." 
				sleep 2 }
			else { 
				$CURRENTVLAB="$selection"
				menu3vLabDetail 
				$vlabList=.\show-vlabs.ps1 }
		}
	} until ( $done )
}

# vLab Instance 
function menu3vLabDetail {  
	$done=$false
	do { 	
		$wanip=$(get-vapp "$CURRENTVLAB" | get-vm | where { $_.Name -eq "gateway" }).guest.IPAddress[0]
		cls
		#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host " vLab Instance                                           | vLAB Automation Kit |"
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host
		Write-Host "vLAB: $CURRENTVLAB"
		Write-Host "IP  : $wanip"  
		Write-Host 
		Write-Host "Virtual Machines:"
		get-vapp | where { $_.Name -eq "$CURRENTVLAB" } | get-vm | sort Name | format-table 
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host " [L]Launch            | [S]tart [U]Shutdown [K]ill [D]estroy | [R]efresh [B]ack "
		Write-Host "--------------------------------------------------------------------------------"
		$selection=Read-Host "::>"
		if     ( "$selection" -eq "b" ) { $done=$true }
		elseif ( "$selection" -eq "r" ) { $done=$false }
		elseif ( "$selection" -eq "m" ) { menuMain }
		elseif ( "$selection" -eq "s" ) { get-vapp "$CURRENTVLAB" | get-vm | start-vm }	
		elseif ( "$selection" -eq "k" ) { get-vapp "$CURRENTVLAB" | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vm }	
		elseif ( "$selection" -eq "u" ) { get-vapp "$CURRENTVLAB" | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vmguest }
		elseif ( "$selection" -eq "l" ) { 
			if ( $wanip ) { mstsc /v:"$wanip" /admin /f }
		}	
		elseif ( "$selection" -eq "d" ) {	
			$areusure = Read-Host "Type DESTROY to destroy vLab $CURRENTVLAB"
			if ( "$areusure" -eq "DESTROY" ) {
				get-vapp "$CURRENTVLAB" | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vm
				.\remove-vlab "$CURRENTVLAB"
				$CURRENTVLAB=""
				$done=$true
			}
		}
	} until ( $done )
}

# vLab Catalog Item
function menu4vLabCatalogDetail {  
	$done=$false
	do { 
		$wanip=""
		$reldate=""
		$gateway=get-vapp "$CURRENTVLAB" | get-vm | where { $_.Name -eq "gateway" }
		if ( $gateway ) { $wanip=$gateway.guest.IPAddress[0] }
		#$wanip=$(get-vapp "$CURRENTVLAB" | get-vm | where { $_.Name -eq "gateway" }).guest.IPAddress[0]
		$relsnap=get-ncvol | where { $_.Name -eq "$CURRENTVLAB" } | get-ncsnapshot | where { $_.Name -eq "master" }
		if ( $relsnap ) { $reldate=$relsnap.Created }
		else { $reldate = "NOT RELEASED" }
		
		Write-header "vLab Catalog Item"
		#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
		Write-Host
		Write-Host "vLAB    : $CURRENTVLAB"
		Write-Host "Released: $reldate"
		Write-Host "IP      : $wanip"  
		Write-Host 
		Write-Host "Virtual Machines:"
		get-vapp | where { $_.Name -eq "$CURRENTVLAB" } | get-vm | sort Name | format-table
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host " [P]rovision |                                     | [A]dmin | [R]efresh [B]ack "
		Write-Host "--------------------------------------------------------------------------------"
		$selection=Read-Host "::>"
		if     ( "$selection" -eq "b" ) { $done=$true }
		elseif ( "$selection" -eq "r" ) { $done=$false }
		elseif ( "$selection" -eq "m" ) { menuMain }
		elseif ( "$selection" -eq "a" ) { menu4vLabCatalogDetailAdmin }
		elseif ( "$selection" -eq "s" ) { get-vapp "$CURRENTVLAB" | get-vm | start-vm }	
		elseif ( "$selection" -eq "k" ) { get-vapp "$CURRENTVLAB" | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vm }	
		elseif ( "$selection" -eq "u" ) { get-vapp "$CURRENTVLAB" | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vmguest }
		elseif ( "$selection" -eq "l" ) { 
			if ( $wanip ) { mstsc /v:"$wanip" /admin /f }
		}	
		elseif ( "$selection" -eq "p" ) {	
			Write-Header "Provisioning..."
			Write-Host
			Write-Host
			Write-Host
			Write-Host
			$result=.\new-vlabclone.ps1 $CURRENTVLAB 
			$CURRENTVLAB=$result.Name
			menu3vLabDetail
			$done=$true
		}
	} until ( $done )
}

# vLab Catalog Item Admin
function menu4vLabCatalogDetailAdmin {  
	$done=$false
	do { 
		$wanip=""
		$reldate=""
		$gateway=get-vapp "$CURRENTVLAB" | get-vm | where { $_.Name -eq "gateway" }
		if ( $gateway ) { $wanip=$gateway.guest.IPAddress[0] }
		#$wanip=$(get-vapp "$CURRENTVLAB" | get-vm | where { $_.Name -eq "gateway" }).guest.IPAddress[0]
		$relsnap=get-ncvol | where { $_.Name -eq "$CURRENTVLAB" } | get-ncsnapshot | where { $_.Name -eq "master" }
		if ( $relsnap ) { $reldate=$relsnap.Created }
		else { $reldate = "NOT RELEASED" }
		
		Write-header "vLab Catalog Item Admin"
		#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
		Write-Host
		Write-Host "vLAB    : $CURRENTVLAB"
		Write-Host "Released: $reldate"
		Write-Host "IP      : $wanip"  
		Write-Host 
		Write-Host "Virtual Machines:"
		get-vapp | where { $_.Name -eq "$CURRENTVLAB" } | get-vm | sort Name | format-table 
		Write-Host "Virtual Networks:"
		get-virtualportgroup | where { $_.Name -like "$CURRENTVLAB*" } | sort Name | format-table -Property Name,VlanID -Autosize
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host " [P]rovision | [S]tart [U]Shutdown [K]ill [L]aunch | [A]dmin | [R]efresh [B]ack "
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host " [D]isable [E]nable"
		Write-Host "--------------------------------------------------------------------------------"		
		$selection=Read-Host "::>"
		if     ( "$selection" -eq "b" ) { $done=$true }
		elseif ( "$selection" -eq "r" ) { $done=$false }
		elseif ( "$selection" -eq "m" ) { menuMain }
		elseif ( "$selection" -eq "d" ) { .\remove-vlab "$CURRENTVLAB" }
		elseif ( "$selection" -eq "e" ) { .\import-vlabtemplate "$CURRENTVLAB" }
		elseif ( "$selection" -eq "s" ) { get-vapp "$CURRENTVLAB" | get-vm | start-vm }	
		elseif ( "$selection" -eq "k" ) { get-vapp "$CURRENTVLAB" | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vm }	
		elseif ( "$selection" -eq "u" ) { get-vapp "$CURRENTVLAB" | get-vm | where { $_.PowerState -eq "PoweredOn" } | stop-vmguest }
		elseif ( "$selection" -eq "l" ) { 
			if ( $wanip ) { mstsc /v:"$wanip" /admin /f }
		}	
		elseif ( "$selection" -eq "p" ) {	
			Write-Header "Provisioning..."
			Write-Host
			Write-Host
			Write-Host
			Write-Host
			$result=.\new-vlabclone.ps1 $CURRENTVLAB 
			$CURRENTVLAB=$result.Name
			menu3vLabDetail
			$done=$true
		}
	} until ( $done )
}

# Admin Menu
function menuAdminMenu {
	$done=$false
	do {
		Write-Header "Admin Menu"
		write-host
		write-host " 1. Configuration Settings"
		write-host " 2. Set Credentials"
		write-host
		write-host
		write-host		
		#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host "                                                             | [R]efresh [B]ack "
		Write-Host "--------------------------------------------------------------------------------"
		$selection = Read-Host "::>"
		if ( $selection -eq "b" ) { $done=$true }
		if ( $selection -eq "1" ) { menuSettingsMenu }
		if ( $selection -eq "2" ) { .\set-vlabcreds.ps1 }
	} until ( $done )
}

# Settings Menu
function menuSettingsMenu {
	$done=$false
	do {
		Write-Header "Configuration Settings:"
		write-host
		$conf=.\get-vlabsettings.ps1
		$conf | format-table
		write-host
		#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host "Enter setting to change                                      | [R]efresh [B]ack "
		Write-Host "--------------------------------------------------------------------------------"
		$selection = Read-Host "::>"
		if ( $selection -eq "b" ) { $done=$true }
		if ( $conf[$selection] ) { 
			$key=$selection
			$oldval=$conf[$selection]
			$newval = Read-Host "Enter $selection [ $oldval ]"
			if ( $newval ) { $result=.\set-vlabsettings.ps1 -key "$key" -value "$newval" }
		}
	} until ( $done )
}

write-header "loading..."
menuMain
