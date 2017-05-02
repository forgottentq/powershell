
function getvmware-event {
	Add-PSSnapin Vmware.VIMAutomation.Core | Out-Null
	set-PowerCLIConfiguration -invalidCertificateAction "ignore" -confirm:$false
	connect-viserver $(read-host "Enter VIServer Name.")
	$vm = $(read-host "Enter Virtual Machine Name")
	$vmObj = Get-VM -Name $vm
	$daysbackinput = $(read-host "Enter Number of Days you want to go back")
	$daysBack = $daysbackinput
	$dateCurrent = Get-Date
	$si = get-view ServiceInstance
	$em = get-view $si.Content.EventManager
	$EventFilterSpec = New-Object VMware.Vim.EventFilterSpec
	$EventFilterSpec.Type = "VmReconfiguredEvent"
	$EventFilterSpec.Entity = New-Object VMware.Vim.EventFilterSpecByEntity
	$EventFilterSpec.Entity.Entity = ($vmObj | get-view).MoRef
	$EventFilterSpec.Time = New-Object VMware.Vim.EventFilterSpecByTime
	$EventFilterSpec.Time.BeginTime = $dateCurrent.adddays(-$daysBack)
	$EventFilterSpec.Time.EndTime = $dateCurrent
	$evts = $em.QueryEvents($EventFilterSpec)
	$deviceChangeEvts = $evts | ?{$_.ConfigSpec.DeviceChange}
	$deviceChangeEvts.Length
	$deviceChangeEvts | %{$_.ConfigSpec.DeviceChange} | select Operation,FileOperation,Device | ft -AutoSize
}
