## Test-port, and Test-port-Ping functions for testing TCP connections/Responses (Success or Fail)
function test-port {
    Param([string]$srv,$port,$timeout=2000,[switch]$verbose)
    $ErrorActionPreference = "SilentlyContinue"
    $tcpclient = new-Object system.Net.Sockets.TcpClient
    $iar = $tcpclient.BeginConnect($srv,$port,$null,$null)
    $wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
    if(!$wait){
        $tcpclient.Close()
        if($verbose){Write-Host "Connection Timeout"}
        Return $false
    } else {
        $error.Clear()
        $tcpclient.EndConnect($iar) | out-Null
        if(!$?){if($verbose){write-host $error[0]};$failed = $true}
        $tcpclient.Close()
    }
    if($failed){
		return $false
	}else{
		return $true
	}
}

function test-port-ping($ip, $port) {
## Usage:  test-port-ping ip.ip.ip.ip 443
	$count = read-host "Enter Ping Count You wish to test:"
	$negative = $null
	do {
		$test = test-port $ip $port
		$count = $count - 1
		if ($test -eq $false){
			$negative += 1
		}
		write-host "TCP response came back: $test"
	}
	while ($count -gt 0)
	if ($negative -gt 0){
		write-host "A total of $negative reponses came back False"
	} else {
		write-host "All responses came back successful!"
	}
}
