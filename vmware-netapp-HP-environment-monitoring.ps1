function check-env {
[System.Reflection.Assembly]::LoadWithPartialName("System.Diagnostics")
$sw = new-object system.diagnostics.stopwatch
$sw.Start()
############################################################
#### Set all static variables. 
$oas = "oa1", "oa2", "oa3", "oa4"
$controllers = "filer1", "filer2", "filer3", "filer4"
$viservers = "vcenter1", "vcenter2", "vcenter3", "vcenter4"
$nacred = Import-clixml C:\users\forgotten\Documents\NACred.xml
$oacred = import-clixml C:\users\forgotten\Documents\OACred.xml
$nothing = ''
$vms = $null
#### Check all HP Enclosures, Fans, OAs, Interconnects, Power,  and Blade health. 
	write-host "----- Checking all HP Onboard Administrators for alarms -----" -foregroundcolor "magenta" -backgroundcolor "black"
	foreach ($oa in $oas){
		write-progress "Checking HP OnBoard Administrators:"
		; ""
		; ""
		try {
			$con = Connect-HPOA -OA $oa -Credential $oacred -erroraction Stop
		} catch { 
				write-host "!!!!! Unable to connect to $oa , moving onto to next OA !!!!!" -foregroundcolor "yellow" -backgroundcolor "black"
				Continue
		}
		$health = Get-HPOAHealth $con
		$bladehealth = $health.bladehealth
		$fanhealth = $health.FanHealth
		$interconnecthealth = $health.InterconnectHealth
		$Powerhealth = $health.PowerSupplyHealth
		$OAhealth = $health.OnboardAdministratorHealth
		$messages = "Absent", "OK"
		### Check OA Blade Health
		foreach ($item in $bladehealth) {
			if ($item.Status -notin $messages) {
				write-host "$oa has not OK Blade status on Bay:" $item.bay -foregroundcolor "red" -backgroundcolor "black"
				$item.Status
				$item.CorrectiveAction ; "" ; ""
				$nothing = "something"
			} else {
				$nothing = ''
			}
		}
		if ($nothing -eq $null -or $nothing -eq '') {
				write-host "$oa has no active BLADE alarms or problems." -foregroundcolor "green" -backgroundcolor "black"
		} else {
			$whatever = "whatever"
		}
		### Check OA Fan Health
		foreach ($item in $fanhealth) {
			if ($item.Status -notin $messages) {
				write-host "$oa has not OK FAN status on Bay:" $item.bay -foregroundcolor "red" -backgroundcolor "black"
				$item.Status
				$item.CorrectiveAction ; "" ; ""
				$nothing = "something"
			} else {
				$nothing = ''
			}
		}
		if ($nothing -eq $null -or $nothing -eq '') {
				write-host "$oa has no active FAN alarms or problems." -foregroundcolor "green" -backgroundcolor "black"
		} else {
			$whatever = "whatever"
		}
		#### Check OA Interconnect Bay Health
		foreach ($item in $interconnecthealth) {
			if ($item.Status -notin $messages) {
				write-host "$oa has not OK Interconnect status on Bay:" $item.bay -foregroundcolor "red" -backgroundcolor "black"
				$item.Status
				$item.CorrectiveAction ; "" ; ""
				$nothing = "something"
			} else {
				$nothing = ''
			}
		}
		if ($nothing -eq $null -or $nothing -eq '') {
				write-host "$oa has no active INTERCONNECT BAY alarms or problems." -foregroundcolor "green" -backgroundcolor "black"
		} else {
			$whatever = "whatever"
		}
		### Check OA Power Supply Health
		foreach ($item in $powerhealth) {
			if ($item.Status -notin $messages) {
				write-host "$oa has not OK Power Supply status on Bay:" $item.bay -foregroundcolor "red" -backgroundcolor "black"
				$item.Status
				$item.CorrectiveAction ; "" ; ""
				$nothing = "something"
			} else {
				$nothing = ''
			}
		}
		if ($nothing -eq $null -or $nothing -eq '') {
				write-host "$oa has no active POWER SUPPLY alarms or problems." -foregroundcolor "green" -backgroundcolor "black"
		} else {
			$whatever = "whatever"
		}
		### Check Onboard Administrator Health
		foreach ($item in $OAhealth) {
			if ($item.Status -notin $messages) {
				write-host "$oa has NOT OK OA status on Bay:" $item.bay -foregroundcolor "red" -backgroundcolor "black"
				$item.Status
				$item.CorrectiveAction ; "" ; ""
				$nothing = "something"
			} else {
				$nothing = ''
			}
		}
		if ($nothing -eq $null -or $nothing -eq '') {
				write-host "$oa has no active OA bay alarms or problems." -foregroundcolor "green" -backgroundcolor "black"
		} else {
			$whatever = "whatever"
		}
	}
	"";
	"";
	#### Check NETAPP Controllers for Failed Disks, disconnected fiber connections, and channel failures.
	write-host "----- Checking all Netapp Filers for Failed Disks, Channel Failures, failed aggregates, and offline luns or volumes -----" -foregroundcolor "magenta" -backgroundcolor "black"
	; ""
	; ""
	foreach ($controller in $controllers) {
		$nothing = ''
		write-progress "Checking NetAPP Controllers for Failed Disks, Channel Failures, failed aggregates, and offline luns or volumes: "
		try {
			Connect-NaController -Name $controller -Credential $nacred -ErrorAction Stop | out-null
		} catch { 
				write-host "!!!!! Unable to connect to $controller , moving onto to next controller !!!!!" -foregroundcolor "yellow" -backgroundcolor "black"
				Continue
		}
		### Check for Failed Disks
		$disk = Get-NaDiskOwner | ? {$_.Failed -eq "True"} | ? {$_.Owner -eq $controller -or $_.Owner -eq $null}
		$shelfstatus = Get-NaShelf | Get-NaShelfEnvironment | where-object {$_.IsShelfChannelFailure -eq 1}
		if ($disk -eq $null) {
			write-host $controller "Has No Failed Disks." -foregroundcolor "green" -backgroundcolor "black" 
		} else {
			write-host "The following controller $($controller) has failed disks:" -foregroundcolor "red" -backgroundcolor "black"
			$disk | Select-Object -Property Name, SerialNumber, Owner, OwnerId, Pool, Failed | Format-Table -Wrap -Autosize
			$diskdata = get-nadisk $disk.Name
			$diskdata | Select-Object -Property Name, Shelf, Bay, Status, PhysSpace, RPM, FW, Model, Pool, Aggregate | Format-Table -Wrap -Autosize
			$drivesize = $diskdata.PhysSpace
			foreach ($drive in $drivesize){
				$converted = $drive/1TB
				foreach ($dis in $disk){
					write-host "Failed Drive:" $dis.Name "Size is:" -foregroundcolor "red" -backgroundcolor "black"
					$rounded = [math]::round($converted,2)
					write-host $rounded"TB" -foregroundcolor "red" -backgroundcolor "black"
				}
			}
			; ""
		}
		### Check for Shelf Channel Failures
		if ($shelfstatus -eq $null) {
			write-host "$controller has no Shelf Channel failures." -foregroundcolor "green" -backgroundcolor "black"
		} else {
			write-host "$controller has the following Shelf Channel failures:" -foregroundcolor "red" -backgroundcolor "black"
			$shelfstatus
		}
		### Check if cluster partnering is enabled. 
		$cfstatus = get-nacluster
		if ($cfstatus.State -ne 'CONNECTED' -and $cfstatus.IsEnabled -ne $true){
			write-host "!!!!!!!!!!!!!!!!! Failover is not enabled on $($controller) and does not have a connected partner. !!!!!!!!!!!!!!!!!" -foregroundcolor "red" -backgroundcolor "black"
		}
		### Check for Failed aggregates, offline Volumes and Luns.
		$aggs = get-naaggr
		$vols = get-navol
		$luns = get-nalun
		foreach ($agg in $aggs){
			if ($agg.State -ne 'Online'){
				write-host "$($controller) has the following aggreates offline:"
				write-host "!!!!!!!!!!!!!!!!! $($agg.Name) IS OFFLINE !!!!!!!!!!!!!!!!!" -foregroundcolor "red" -backgroundcolor "black"
			}
		}
		foreach ($vol in $vols){
			if ($vol.State -ne 'Online'){
				write-host "$($controller) has the following Volumes offline:"
				write-host "!!!!!!!!!!!!!!!!! $($vol.Name) IS OFFLINE !!!!!!!!!!!!!!!!!" -foregroundcolor "red" -backgroundcolor "black"
			}
		}
		foreach ($lun in $luns){
			if ($lun.Online -ne $true){
				write-host "$($controller) has the following LUNs offline:"
				write-host "!!!!!!!!!!!!!!!!! $($Lun.Path) IS OFFLINE !!!!!!!!!!!!!!!!!" -foregroundcolor "red" -backgroundcolor "black"
			}
		}
		### Check for disconnected FC Adaptors.
#		$fcadapters = ''
#		$fcadapters = get-nafcadapter
#		foreach ($adapter in $fcadapters){
#			if ($adapter.AdapterStatus -eq "offline"){
#				write-host "$controller has the following offline FC adaptors:" -foregroundcolor "red" -backgroundcolor "black"
#				$adapter
#			} else {
#				$nothing = "something"
#			}
#		}
#		if ($nothing -eq ''){
#			write-host "$controller has no offline FC Adaptors" -foregroundcolor "green" -backgroundcolor "black"
#		}
		;""
	}
	; ""
	; ""
##############################################################	
#### Check VMWare Clusters, Hosts, Datastores, and VM's for triggered Alarms and high value settings.
	Add-PSSnapin Vmware.VIMAutomation.Core | Out-Null
	set-PowerCLIConfiguration -invalidCertificateAction "ignore" -confirm:$false | out-null
	write-host "----- Checking VMWare Hosts, Datastores, and VM alarms -----" -foregroundcolor "magenta" -backgroundcolor "black"	
	foreach ($viserver in $viservers) {
		$vms = ''
		$vmwarehosts = ''
		$datastores = ''
		write-progress "Checking VMWare Clusters, Hosts, Datastores and VMs for Triggered Alarms and States: "
		; ""
		; ""
		try {
			connect-viserver $viserver -ErrorAction Stop | out-null
		} catch { 
				write-host "!!!!! Unable to connect to $viserver , moving onto to next vCenter !!!!!" -foregroundcolor "yellow" -backgroundcolor "black"
				Continue
		}
		
		#### Checking Cluster Settings HA/DRS.
		$clusters = $null
		$cluster = $null
		$clusters = get-cluster
		foreach ($cluster in $clusters){
			if ($cluster.HAEnabled -eq $false){
				write-host "!!!! $($viserver) - $($cluster.Name) does not have HA enabled !!!!" -foregroundcolor "red" -backgroundcolor "black"
			} else {
				write-host "$($viserver) - $($cluster.Name) has HA enabled" -foregroundcolor "green" -backgroundcolor "black"
			}
			if ($cluster.DRSAutomationLevel -notlike "*FullyAutomated*"){
				write-host "!!!! $($viserver) - $($cluster.Name) DRS is not fully automated !!!!" -foregroundcolor "red" -backgroundcolor "black"
			} else {
				write-host "$($viserver) - $($cluster.Name) DRS is fully automated" -foregroundcolor "green" -backgroundcolor "black"
			}
		}
		#### Checking Host alarms.
		$vmwarehosts = get-vmhost | get-view
		$alarm = ''
		$definition = ''
		foreach ($box in $vmwarehosts) {
			if ($box.TriggeredAlarmState -ne $null -or $box.TriggeredAlarmState -ne '') {
				$alarm = $box.TriggeredAlarmState.Alarm
				$definition = Get-AlarmDefinition -Id $alarm
				Write-host "$($box.Name) Has the following Host Alarms triggered:" -foregroundcolor "red" -backgroundcolor "black"
				Write-host $definition.Name -backgroundcolor "black" 
			}
		}
		$vmhosts = get-vmhost
		foreach ($boxen in $vmhosts){
			if ($boxen.ConnectionState -ne 'Connected'){
				write-host "!!!!! $($boxen.Name) has the following connection state: $($boxen.ConnectionState) !!!!!" -foregroundcolor "red" -backgroundcolor "black"
				$events = get-vievent -Entity $boxen.Name -MaxSamples 500
				foreach ($event in $events){
					if ($event.FullFormattedMessage -match "Task: Enter maintenance mode"){
						write-host "Host was put into maintenance mode on:  $($event.CreatedTime), by user: $($event.UserName)"
						
					}
				}
			}
		}
		if ($vmwarehosts.TriggeredAlarmState -eq $null -or $vmwarehosts.TriggeredAlarmState -eq '') {
			write-host "There are no active HOST alarms on:" $viserver -foregroundcolor "green" -backgroundcolor "black" 
		}
		#### Checking for dead HBA paths.
		$hosts = Get-VMHost | ? { $_.ConnectionState -eq "Connected" } | Sort-Object -Property Name
		foreach ($box in $hosts){
			$hbas = $box | get-vmhosthba -Type "FibreChannel"
			foreach ($hba in $hbas){
				$state = $hba | get-scsilun | get-scsilunpath
				if ($state.State -eq "Dead"){
					write-host "!!!!!!!! $($box) has dead HBA Paths go investigate !!!!!!!!" -foregroundcolor "red" -backgroundcolor "black"
				}
			}
		}
		#### Checking Datastore alarms.
		$datastores = get-datastore | get-view
		$alarm = ''
		$definition = ''
		foreach ($store in $datastores) {
			if ($store.TriggeredAlarmState -ne $null -or $store.TriggeredAlarmState -ne '') {
				$alarm = $store.TriggeredAlarmState.Alarm
				$definition = Get-AlarmDefinition -Id $alarm
				Write-host "$($store.Name) Has the following Storage Alarms triggered:" -foregroundcolor "red" -backgroundcolor "black"
				Write-host $definition.Name -backgroundcolor "black" 
			}
		}
		if ($datastores.TriggeredAlarmState -eq $null -or $datastores.TriggeredAlarmState -eq '') {
				write-host "There are no active DATASTORE alarms on:" $viserver -foregroundcolor "green" -backgroundcolor "black" 
		}
		#### Checking VM alarms and Snapshot dates. 
		$vms = get-vm | get-view
		$alarm = ''
		$definition = ''
		$snapdate = ''
		foreach ($vm in $vms) {
			if ($vm.TriggeredAlarmState -ne $null -or $vm.TriggeredAlarmState -ne '') {
				$alarm = $vm.TriggeredAlarmState.Alarm
				$definition = Get-AlarmDefinition -Id $alarm
				Write-host "$($vm.Name) Has the following VM alarms triggered:" -foregroundcolor "red" -backgroundcolor "black" 
				Write-host $definition.Name -backgroundcolor "black"
				#### If alarm is Snapshot, show Snapshot name and Creation Date.
				if ($definition.Name -eq "VMSnapshot Running") {
					$snapdate = get-snapshot -VM $vm.Name
					write-host "$($snapdate.Name) was created on:" $snapdate.Created -backgroundcolor "black"
					write-host "Snapshot is the following size in GB:" $snapdate.SizeGB -backgroundcolor "black"
					;""
				}
			}
		}
		if ($vms.TriggeredAlarmState -eq $null -or $vmview.TriggeredAlarmState -eq '') {
				write-host "There are no active VM alarms on" $viserver -foregroundcolor "green" -backgroundcolor "black" 

		}
		$vms = $null
		$vms = get-vm | where {$_.Name -like "*_old*" -or $_.Name -like "*_old*"} | out-null
		if ($vms -ne $null){
			write-host "The following VM's have old in their names:" -foregroundcolor "red" -backgroundcolor "black" 
			$vms.Name
			;""
		}
		$vms = $null
		$vms = Get-VM | Where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded}
		$tasks = get-task | out-null 
		if ($vms -ne $null){
			;""
			write-host "Consolidating any triggered VMs" -foregroundcolor "green" -backgroundcolor "black"
			foreach ($vm in $vms){
				if ($tasks.etensiondata.info.entityname -eq $vm -and $tasks.Name -eq "ConsolidateVMDisks_Task") {
					write-host "!!! Consolidation task for this VM already running !!!"
				} else {
				(Get-VM -Name $vm.Name).ExtensionData.ConsolidateVMDisks_Task() | out-null
				write-host "Task sent for consolidation of the following VM: $($vm.Name) sent to vCenter"
				}
			}
		}
		disconnect-viserver $viserver -confirm:$false | out-null 
		;""
		;""
	}
	$sw.stop()
	write-host "All of your sweet checks took this much time to run:" -foregroundcolor "green" -backgroundcolor "black"
	$sw.Elapsed
}
