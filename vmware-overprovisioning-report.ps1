
function vmware-provisioning {
	$viservers = "vcenter1", "vcenter2", "vcenter3", "vcenter4"
	$ss = "\\share\e$\Storage_Reports\"
	$report = "C:\Vmware_Provisioning.csv"
	$date = (Get-Date).tostring("yyyyMMdd")
	Add-PSSnapin Vmware.VIMAutomation.Core | Out-Null
	set-PowerCLIConfiguration -invalidCertificateAction "ignore" -confirm:$false | out-null
	remove-item $report
	foreach ($server in $viservers) {
		$datastores = $null
		$vms = $null
		$size = $null
		$output = $null
		$vm = $null
		$store = $null
		connect-viserver $server | out-null
		$datastores = get-datastore
		foreach ($store in $datastores) {
			$output = $null
			$vms = get-vm -Datastore $store
			$size = $vms | Measure-Object ProvisionedSpaceGB -Sum | Select -expand Sum
			$output = New-Object PSobject -Property @{
				"Name" = $store.name
				"Provisioned" = $size
				"Total Size" = $store.CapacityGB
			} | Select Name, Provisioned, 'Total Size' | export-csv C:\VMware_Provisioning.csv -Append
		}
		disconnect-viserver $server -confirm:$false -force | out-null
		start-sleep -Seconds 3
	}
	copy-item $report -Destination "$ss'VMware_Provisioning_'$date.csv"
}
