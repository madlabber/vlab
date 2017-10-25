$CURRENTVLAB=""
#$vLabCatalog=.\get-vlabcatalog.ps1
#$vLabList=.\get-vlabs.ps1

# Write-Header
function write-header {
		Param ([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]$msg)
		#       "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
		$border="--------------------------------------------------------------------------------"
		$txtbox="                                                         | vLAB Automation Kit |"
		$txtright=$txtbox.substring(($msg.length +1))
		
		cls
		Write-Host $border
		write-host " $msg$txtright"
		write-host $border
}

write-header "loading..."

# vLab Catalog
function menu1vLabCatalog {
	Write-Header "Loading..."
	$vlabCatalog=.\get-vlabcatalog.ps1
	$done=$false
	do {
		write-header "vLab Templates"
		$vLabCatalog | Format-Table
		#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host "Enter vLab Name for Details.                                 | [R]efresh [B]ack "
		Write-Host "--------------------------------------------------------------------------------"
		$selection = Read-Host "::>"
		if ( "$selection" -eq "p" ) { 
			$selection = Read-Host "Enter the name of the lab to create"
			$result=$vLabCatalog | where { $_.Name -eq "$selection" }
			if ( !$result ) { 
				write-host "Lab "$selection" not found." 
				sleep 3 
			}
			else {
				cls
				#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
				Write-Host "--------------------------------------------------------------------------------"
				Write-Host " Provisioning...                                         | vLAB Automation Kit |"
				Write-Host "--------------------------------------------------------------------------------"	
				Write-Host
				Write-Host
				Write-Host
				Write-Host
				$result=.\new-vlab.ps1 $selection 
				$CURRENTVLAB=$result.Name
				menu3vLabDetail
				$done=$true
			} 
		}
		elseif ( "$selection" -eq "b" ) { $done=$true }
		elseif ( "$selection" -eq "r" ) { $vlabCatalog=.\get-vlabcatalog.ps1 }	
		else {
			$result=$vLabCatalog | where { $_.Name -eq "$selection" }
			if ( !$result ) { 
				write-host "Lab "$selection" not found." 
				sleep 2 
			}
			else { 
				$CURRENTVLAB="$selection"
				menu4vLabCatalogDetail 
				$vlabList=.\get-vlabs.ps1 
			}
		}
	} until ( $done )
}

# vLab Instances
function menu2vLabInstances {
	write-header "loading..."
	$vLabList=.\get-vlabs.ps1
	$done=$false
	do {
		write-header "vLab Instances"
		#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
		$vlabList | Format-Table
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host "Enter vLab Name for Details.                                 | [R]efresh [B]ack "
		Write-Host "--------------------------------------------------------------------------------"
		$selection=Read-Host "::>"
		if     ( "$selection" -eq "b" ) { $done=$true }
		elseif ( "$selection" -eq "r" ) { $vlabList=.\get-vlabs.ps1 }
		else {
			$result=$vLabList | where { $_.Name -eq "$selection" }
			if ( !$result ) { 
				write-host "Lab "$selection" not found." 
				sleep 2 }
			else { 
				$CURRENTVLAB="$selection"
				menu3vLabDetail 
				$vlabList=.\get-vlabs.ps1 }
		}
	} until ( $done )
}

# vLab Detail
function menu3vLabDetail {  
	$done=$false
	do { 	
		$wanip=$(get-vapp "$CURRENTVLAB" | get-vm | where { $_.Name -eq "gateway" }).guest.IPAddress[0]
		cls
		#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host " vLab Detail                                             | vLAB Automation Kit |"
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

# vLab Detail
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
		
		Write-header "vLab Catalog Detail"
		#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
		Write-Host
		Write-Host "vLAB    : $CURRENTVLAB"
		Write-Host "Released: $reldate"
		Write-Host "IP      : $wanip"  
		Write-Host 
		Write-Host "Virtual Machines:"
		get-vapp | where { $_.Name -eq "$CURRENTVLAB" } | get-vm | sort Name | format-table
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host " [P]rovision        | [S]tart  [U]Shutdown  [K]ill  [L]aunch | [R]efresh [B]ack "
		Write-Host "--------------------------------------------------------------------------------"
		$selection=Read-Host "::>"
		if     ( "$selection" -eq "b" ) { $done=$true }
		elseif ( "$selection" -eq "r" ) { $done=$false }
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
			$result=.\new-vlab.ps1 $CURRENTVLAB 
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
		write-host "Current Settings:"
		$conf=.\get-vlabsettings.ps1
		$conf 
		write-host
		#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
		Write-Host "--------------------------------------------------------------------------------"
		Write-Host "                                                             | [R]efresh [B]ack "
		Write-Host "--------------------------------------------------------------------------------"
		$selection = Read-Host "::>"
		if ( $selection -eq "b" ) { $done=$true }
	} until ( $done )
}
# Main Menu
do {
	Write-Header "Main Menu"
	#          #12345678901234567890123456789012345678901234567890123456789012345678901234567890
	Write-Host 
	Write-Host "1......vLAB Templates"
	Write-Host "2......vLAB Instances"
	Write-Host "3......Admin Menu"
	Write-Host "x......Exit"
	Write-Host
	$input = Read-Host "::>"
	
	switch ($input) {
		'1' { menu1vLabCatalog }
		'2' { menu2vLabInstances }
		'3' { menuAdminMenu }
		'x' { return }
	}
	#pause
} until ($input -eq 'q')
