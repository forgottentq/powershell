# This function requires WinRM on remote machine to function properly and must be Windows 7sp1 or higher. 
#
function captureWindows-endpoint {
        $endpoint = $(read-host "Enter endpoint short name or FQDN")
        $duration = $(read-host "Enter desired capture duration in seconds")
        $date = get-date
        $file = "$($endpoint)_$($date.Month)_$($date.Day)_$($date.year)_$($date.Hour)_$($date.Minute).etl"
        # Remove any stale sessions remote and local
        invoke-command -computername $endpoint -scriptblock {Remove-NeteventSession}
        Remove-NetEventSession
        # Start new capture
        try {
                New-NetEventSession -CaptureMode SaveToFile -LocalFilePath "C:\$file" -CimSession $endpoint -Name $endpoint -erroraction Stop
        } catch {
                write-host "Unable to start Event Session via CimSession on $($endpoint), not continuing." -foregroundcolor "Red" -BackgroundColor "Black"
                Break
        }
        Add-NetEventPacketCaptureProvider -SessionName $endpoint -Level 4 -CaptureType Physical -CimSession $endpoint
        Start-NetEventSession -Name $endpoint -CimSession $endpoint
        Sleep $duration
        Stop-NetEventSession -Name $endpoint -CimSession $endpoint
        try {
                New-Item -type Directory "C:\captures\" -ErrorAction SilentlyContinue
                $captures = "C:\captures\"
        } catch {
                write-host "Captures directory already exists, continuing." -backgroundcolor "black" -foregroundcolor "green"
                $captures = "C:\captures\"
        }
        write-host "Copying endpoint capture file to local workstation!" -backgroundcolor "black" -foregroundcolor "green"
        Copy-item "\\$endpoint\c$\$file" $captures
        Remove-Item "\\$endpoint\c$\$file"
        # Remove local and remote sessions.
        invoke-command -computername $endpoint -scriptblock {Remove-NeteventSession}
        Remove-NetEventSession
        write-host "Opening capture directory" -backgroundcolor "black" -foregroundcolor "green"
        ii $captures
}
