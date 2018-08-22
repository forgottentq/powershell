# This script will need to be run with administrator credentials in order for the start-process cmdlet to initiate the installer with proper privledges
# Check for existing paths. Create if not existant.  Kill script if write access to C: isn't available.
function install-webroot {
    try {
        $test = gci "C:\vxit\webroot" -ErrorAction SilentlyContinue
        if ($test -eq $true){
            write-host "Exe path exists continuing"
        } else {
            write-host "Exe path does not exist, creating"
            New-item -ItemType Directory -Path "C:\path1" -ErrorAction SilentlyContinue | out-null
            New-item -ItemType Directory -Path "C:\path1\webroot" -ErrorAction SilentlyContinue | out-null
        }
    } catch {
        write-host "Operation unsuccessfull, check write access permissions to C:\"
        Break
    }
    #
    # Set TLS 1.2.  Without this setting invoke-webrequest frequently returns an error saying the "The underlying connection was closed: An unexpected error occurred on a send"
    #
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    #
    # Initiate file download, overwrite if existing
    #
    Invoke-WebRequest -Uri "Your Full Download Url" -UseBasicParsing -OutFile "C:\vxit\webroot\wsasme.exe"
    Sleep 1
    #
    # Start installation process
    #
    Start-Process -FilePath "C:\vxit\webroot\wsasme.exe" -ArgumentList "/key=Your_product_key /group=-#yourgroup# /silent"
    #
    # Monitor the process for completion
    #
    do {
        write-progress -Activity "Installing Webroot AV..."
        $install = get-process | where {$_.Name -eq "wsasme"}
        Sleep 5
    } while ($install -ne $null)
    #
    # Finally write or do something indicating the install is complete
    #
    write-host "Installation Complete."
}
install-webroot
