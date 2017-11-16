
$3pars = "server1", "server2"
$cred = import-clixml "C:\cred.xml"
foreach ($3par in $3pars){
	$session = New-3ParPoshSshConnection -SANIPAddress $3par -SANUserName $cred.username -SANPassword $cred.GetNetworkCredential().password
	$cpgs = get-3parcpg | where {$_.Volumes -ne "Name" -and $_.Volumes -ne "total"}
	foreach ($cpg in $cpgs){
		$vvs = Get-3parvv | where {$_.CPG -eq "$($cpg.Volumes)"}
		foreach ($vv in $vvs){
			$vvlist = get-3parvvList -vvName $vv.Name
			if ($vvlist.Prov -ne "pswp" -and $vvlist.Prov -ne "vswpc"){
				$cmds = "tunevv usr_cpg $($cpg.volumes) -f -tdvv $($vvList.Name)"
				invoke-3parclicmd -connection $session -cmds $cmds	
			}
		}
	}
	Get-3parTask
	Remove-sshsession -sessionId $session.SessionID
}
