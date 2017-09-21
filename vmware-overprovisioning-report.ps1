
### This updated version will total all VM disks on a datastore where the disk file name matches the datastore name.  I had to
### update this from the previous version because datastore clustering and DRS would spread out VM disks between datastores which
### ended up skewing my report data. :). 

function vmware-provisioning {
	$cred = get-credential
	$viservers = "vcenter1", "vcenter2"
	$date = (Get-Date).tostring("yyyyMMdd")
	Add-PSSnapin Vmware.VIMAutomation.Core | Out-Null
	set-PowerCLIConfiguration -invalidCertificateAction "ignore" -confirm:$false | out-null
	foreach ($server in $viservers) {
		$datastores = $null
		$vms = $null
		$size = $null
		$output = $null
		$vm = $null
		$store = $null
		connect-viserver $server -credential $cred | out-null
		$datastores = get-datastore
		foreach ($store in $datastores) {
			$size = $null
			$output = $null
			$vms = $null
			$vms = get-vm -Datastore $store
			foreach ($vm in $vms){
				$vmsize = $null
				$vmsize = $vm | get-harddisk | where {$_.Persistence -eq "Persistent"} | Measure-Object CapacityGB -Sum | Select -expand Sum
				$size += $vmsize
			}
			$output = New-Object PSobject -Property @{
					"Name" = $store.name
					"Provisioned" = $size
					"Total Size" = $store.CapacityGB
					"Difference in GB" = $store.CapacityGB - $size
				} | Select Name, Provisioned, 'Total Size', 'Difference in GB' | export-csv C:\VMware_Provisioning.csv -Append
		}
		disconnect-viserver $server -confirm:$false -force | out-null
		start-sleep -Seconds 3
	}
}
