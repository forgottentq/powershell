#
# This script uses Posh-SSH module and requires tcpdump be installed on the endpoint to function correctly. 
# Subsitute "dzdo" commands with sudo if you do not use Centrify in your organization
#
function captureLinux-endpoint {
        $date = get-date
        $stamp = "$($date.Month)_$($date.day)_$($date.year)_$($date.hour)_$($date.minute)"
        $whoami = whoami
        $account = $whoami.Split("\")[1]
        $endpoint = $(read-host "Enter Linux endpoint short name or FQDN")
        $duration = $(read-host "Enter desired capture duration in seconds")
        #Open SSH Session to endpoint.
        try {
                $session = New-SSHSession -computername $endpoint -Credential $zzmcred -AcceptKey -ErrorAction Stop
                $stream = New-SSHShellStream -SessionId $session.SessionId -ErrorAction Stop
        } catch {
                write-host "Unable to connect session to $($endpoint). Not continuing." -foregroundcolor "Red" -BackgroundColor "Black"
                Break
        }
        # Checking for Tcpdump on endpoint
        $tcpdump = invoke-sshcommand -sessionid $session.SessionID -command "whereis tcpdump"
        if ($tcpdump.output -notlike "*/usr/sbin*"){
                write-host "Tcpdump not installed on $($endpoint), not continuing." -foregroundcolor "Red" -BackgroundColor "Black"
                Remove-SSHSession -SessionID $session.SessionId | out-null
                Break
        }
        #Perform capture via tcpdump on endpoint
        write-host "Initating packet capture via SSH commands to file on local endpoint: $($endpoint)." -foregroundcolor "Cyan"
        $device = Invoke-SSHCommand -SessionId $session.SessionID -command "dzdo /sbin/ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d'"
        $command = Invoke-SSHCommandStream -SessionId $session.SessionID -Command "dzdo /usr/bin/timeout -s 15 $($duration) /usr/sbin/tcpdump -i $($device.output[0]) -n -tttt -S -s 65535 -w /home/$($account)/$($endpoint)_$($stamp).pcap"
        invoke-sshcommand -sessionid $session.SessionID -command "dzdo chown -R $($account):$($account) /home/$($account)"
        Remove-sshsession -sessionid $session.sessionid | out-null
        #Pull pcap file from endpoint back to local workstation.
        write-host "Capture complete, extracting pcap file to C:\Captures\" -foregroundcolor "Green" -BackgroundColor "black"
        $session = New-SFTPSession -Computername $endpoint -Credential $zzmcred -AcceptKey
        Get-SFTPFile -SFTPSession $session -RemoteFile "/home/$account/$($endpoint)_$($stamp).pcap" -LocalPath "C:\captures\"
        Remove-SFTPSession -sessionId $session.SessionID | out-null
        Get-SSHSession | Remove-SSHSession
        #Remove Local Pcap files on endpoint.
        $session = New-SSHSession -computername $endpoint -Credential $zzmcred -AcceptKey
        invoke-sshcommand -sessionid $session.SessionID -command "rm *.pcap"
        Remove-sshsession -sessionid $session.sessionid | out-null
        #Open capture folder folder containing newly capture pcap.
        write-host "Extraction complete, opening capture folder." -foregroundcolor "Green" -BackgroundColor "Black"
        ii "C:\captures\"
}
