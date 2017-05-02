
function vcenter-sessions {
	try {
		connect-viserver 52tdkp-vm-010vvvv -ErrorAction Stop
	} catch {
		Write-host "Unable to connect to specified vCenter - Not continuing."
		Break
	}
		$Now = Get-Date
		$Report = @()
		$svcRef = new-object VMware.Vim.ManagedObjectReference
		$svcRef.Type = "ServiceInstance"
		$svcRef.Value = "ServiceInstance"
		$serviceInstance = get-view $svcRef
		$sessMgr = get-view $serviceInstance.Content.sessionManager
		foreach ($sess in $sessMgr.SessionList){
			$time = $Now - $sess.LastActiveTime
			# Our time calculation returns a TimeSpan object instead of DateTime, therefore formatting needs to be done as follows:
			$SessionIdleTime = '{0:00}:{1:00}:{2:00}' -f $time.Hours, $time.Minutes, $time.Seconds
			$row = New-Object -Type PSObject -Property @{
			Name = $sess.UserName
			LoginTime = $sess.LoginTime
			IdleTime = $SessionIdleTime
			}
			## end New-Object
			$Report += $row
		}
	$Report
}
