# Quick and dirty script to clone a package repo. Only tested against OpenBSD.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$share = "\\172.16.10.99\wmfbshare\obsd_repo\"
$url = "https://ftp3.usa.openbsd.org/pub/OpenBSD/snapshots/packages/amd64/"
cd $share
$packages = Invoke-WebRequest -Uri  -UseBasicParsing $url
$dlfolder = "\\172.16.10.99\wmfbshare\obsd_repo\"
foreach ($package in $packages.links.href){
    if ((get-item $package -ErrorAction SilentlyContinue)){
        write-host "$package already downloaded"
    } else {
        write-host "Downlading $package"
        wget "$url/$package" -outfile "$dlfolder\$package"
    }
}
