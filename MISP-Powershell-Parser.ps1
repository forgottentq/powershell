function Get-MISPData{
    # MISP (Malware Information Sharing Platform) Powershell IOC Parser.
    $links = $null
    $ipdsts = $null
    $linkss = $null
    $regkeys = $null
    $filenames = $null
    $sha256s = $null
    $sha1s = $null
    $md5s = $null
    $urls = $null
    #
    $ipdsts = @()
    $linkss = @()
    $regkeys = @()
    $filenames = @()
    $sha256s = @()
    $sha1s = @()
    $md5s = @()
    $urls = @()
    #
    clear
    ;""
    ;""
    ;""
    ;""
    ;""
    ;""
    ;""
    $logo = @'
    ___  ________ ___________  ______                          _          _ _ 
    |  \/  |_   _/  ___| ___ \ | ___ \                        | |        | | |
    | .  . | | | \ `--.| |_/ / | |_/ /____      _____ _ __ ___| |__   ___| | |
    | |\/| | | |  `--. \  __/  |  __/ _ \ \ /\ / / _ \ '__/ __| '_ \ / _ \ | |
    | |  | |_| |_/\__/ / |     | | | (_) \ V  V /  __/ |  \__ \ | | |  __/ | |
    \_|  |_/\___/\____/\_|     \_|  \___/ \_/\_/ \___|_|  |___/_| |_|\___|_|_|
     _____                                                                    
    | ___ \                                                                   
    | |_/ /_ _ _ __ ___  ___ _ __                                             
    |  __/ _` | '__/ __|/ _ \ '__|                                            
    | | | (_| | |  \__ \  __/ |                                               
    \_|  \__,_|_|  |___/\___|_|      
'@
    write-host $logo 
    $exports = "C:\users\forgo\Desktop\MISP\Exports\"
    $date = get-date
    #
    $links = Invoke-WebRequest -Uri "https://www.circl.lu/doc/misp/feed-osint/" -UseBasicParsing
    foreach ($link in $links.links.href | where {$_ -notlike "*Parent*" -and $_ -ne "manifest.json" -and $_ -ne "hashes.csv" -and $_ -notlike "*?C*" -and $_ -ne "/doc/misp/"}){
        $IOCs = Invoke-RestMethod -uri "https://www.circl.lu/doc/misp/feed-osint/$($link)" -UseBasicParsing
        foreach ($event in $IOCs.Event.Attribute | where {$_.Comment -ne ""}){
            write-progress -Activity "Processing Event $($event.Comment)"
            if ($event.type -eq "ip-dst"){
                $ipdsts += New-Object PSObject -Property @{"ip-dst"="$($event.value)"; "Comment"="$($event.Comment)"} | Select ip-dst,Comment
            }
            if ($event.type -eq "link"){
                $linkss += New-Object PSObject -Property @{"link"="$($event.value)"; "Comment"="$($event.Comment)"} | Select link,Comment
            }
            if ($event.type -eq "regkey"){
                $regkeys += New-Object PSObject -Property @{"regkey"="$($event.value)"; "Comment"="$($event.Comment)"} | Select regkey,Comment
            }
            if ($event.type -eq "filename"){
                $filenames += New-Object PSObject -Property @{"filename"="$($event.value)"; "Comment"="$($event.Comment)"} | Select filename,Comment
            }
            if ($event.type -eq "sha256"){
                $sha256s += New-Object PSObject -Property @{"sha256"="$($event.value)"; "Comment"="$($event.Comment)"} | Select sha256,Comment
            }
            if ($event.type -eq "sha1"){
                $sha1s += New-Object PSObject -Property @{"sha1"="$($event.value)"; "Comment"="$($event.Comment)"} | Select sha1,Comment
            }
            if ($event.type -eq "md5"){
                $md5s += New-Object PSObject -Property @{"md5"="$($event.value)"; "Comment"="$($event.Comment)"} | Select md5,Comment
            }
            if ($event.type -eq "url"){
                $urls += New-Object PSObject -Property @{"url"="$($event.value)"; "Comment"="$($event.Comment)"} | Select url,Comment
            }  
        }
    }
    if ($ipdsts){
        $ipdsts | Export-CSV -Path "$($exports)MISP_Export_IPs_$($date.month)_$($date.day)_$($date.year).csv"
    }
    if ($linkss){
        $linkss | Export-CSV -Path "$($exports)MISP_Export_Links_$($date.month)_$($date.day)_$($date.year).csv"
    }
    if ($regkeys){
        $regkeys | Export-CSV -Path "$($exports)MISP_Export_Regkeys_$($date.month)_$($date.day)_$($date.year).csv"
    }
    if ($filenames){
        $filenames | Export-CSV -Path "$($exports)MISP_Export_Filenames_$($date.month)_$($date.day)_$($date.year).csv"
    }
    if ($sha256s){
        $sha256s | Export-CSV -Path "$($exports)MISP_Export_sha256s_$($date.month)_$($date.day)_$($date.year).csv"
    }
    if ($sha1s){
        $sha1s | Export-CSV -Path "$($exports)MISP_Export_sha1s_$($date.month)_$($date.day)_$($date.year).csv"
    }
    if ($md5s){
        $md5s | Export-CSV -Path "$($exports)MISP_Export_md5s_$($date.month)_$($date.day)_$($date.year).csv"
    }
    if ($urls){
        $urls | Export-CSV -Path "$($exports)MISP_Export_urls_$($date.month)_$($date.day)_$($date.year).csv"
    }
    ;""
    write-host "Parsing complete, exports located at: $exports"
}
