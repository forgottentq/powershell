function Invoke-ItsAlwaysDNS([array]$inputfile){

    $art = @"
    
    
    
    
    
    
    
    
    
        ______ _          ___    __                             
       /  _/ /( )_____   /   |  / /      ______ ___  _______    
       / // __/// ___/  / /| | / / | /| / / __ `/ / / / ___/    
     _/ // /_  (__  )  / ___ |/ /| |/ |/ / /_/ / /_/ (__  )     
    /___/\__/ /____/__/_/  |_/_/ |__/|__/\__,_/\__, /____/      
       / __ \/ | / / ___/                     /____/            
      / / / /  |/ /\__ \                                        
     / /_/ / /|  /___/ /                                        
    /_____/_/ |_//____/                                                                 
"@
write-host "$art" -ForegroundColor Yellow  
    
    # WOuld love to convert this into / learn ArrayLists for performance. 
    #$datalist =  @()
    #$datalist = [System.Collections.ArrayList]@()
    $dataset = @()
    $subdomains = get-content $inputfile | where {$_ -notlike "*com*"}
    $count1 = 0
    foreach ($subdomain in $subdomains){
        $count1++
        Write-Progress -Id 0 -Activity 'Running DNS Queries on all known sub-domains:' -Status "Processing $($count1) of $($subdomains.count)" -CurrentOperation $subdomain -PercentComplete (($count1/$subdomains.Count) * 100)
        $lookup = $null
        $ptr = $null
        $ptr6 = $null
        try {
            #$lookup = Resolve-DnsName -name $subdomain".$domain" -DnsOnly -ErrorAction SilentlyContinue
            $lookup = Resolve-DnsName -name $subdomain -DnsOnly -ErrorAction SilentlyContinue
            $ptr = Resolve-DnsName -Type PTR $lookup.ip4address -DnsOnly -ErrorAction SilentlyContinue
            $ptr6 = Resolve-DnsName -Type PTR "$($lookup.ip6address)" -DnsOnly -ErrorAction SilentlyContinue
        } catch {
            # write-host "No record exists for $subdomain"
        }
        if ($lookup -ne "") {
            foreach ($ip in $lookup){
                if ($ip.type -eq "A"){
                    $dataset += New-Object PSObject -Property @{"Hostname"="$($subdomain)"; "IPAddress"="$($ip.IP4Address)"; "Type"="A"; "Reverse Record"="$($ptr.NameHost)"} | Where-Object { $_.PSObject.Properties.Value -ne '' } | Select Hostname,IPAddress,Type,"Reverse Record"
                        # Attempt at an ArrayList here.
                        # $datalist.Add( @{Hostname=("$($subdomain)"); IP4Address=("$($lookup.IP4Address)"); PTR=("$($ptr.Namehost)")})
                } elseif ($ip.type -eq "AAA"){
                    $dataset += New-Object PSObject -Property @{"Hostname"="$($subdomain)"; "IPAddress"="$($ip.IP6Address)"; "Type"="AAA"; "Reverse Record"="$($ptr6.NameHost)"} | Where-Object { $_.PSObject.Properties.Value -ne '' } | Select Hostname,IPAddress,Type,"Reverse Record" | Sort-Object -Property City
                }
            }
        }


    }
    # Get whois/location info on each IPv4 IP and build new dataset
    $whoisdataset = @()
    $ipv4 = $dataset | where {$_.Type -eq "A"}
    foreach ($item in $ipv4){
        write-progress "Getting whois and city data"
        $whois = get-whois -IPAddress "$($item.IPAddress)" -ErrorAction SilentlyContinue
        $whoisdataset += New-Object PSObject -Property @{"Hostname"="$($item.hostname)"; "IPAddress"="$($item.IPAddress)"; "Organization"="$($whois.RegisteredOrganization)"; "City"="$($whois.city)"} | Select Hostname,IPAddress,Organization,City

    }
    $date = get-date
    $dataset  | Export-CSV -NoTypeInformation "LookupData_$($domain)_$($date.month)_$($date.day)_$($date.year).csv"
    $whoisdataset | Export-CSV -NoTypeInformation "WhoisMap_$($domain)_$($date.month)_$($date.day)_$($date.year).csv"
    #$datalist | Export-CSV -NoTypeInformation .\Export_Test_List.csv
}

function Get-Netstat { 
    $properties = "Protocol","LocalAddress","LocalPort" 
    $properties += "RemoteAddress","RemotePort","State","ProcessName","PID"

    netstat -ano | Select-String -Pattern "\s+(TCP|UDP)" | ForEach-Object {

        $item = $_.line.split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)

        if($item[1] -notmatch "^\[::") 
        {            
            if (($la = $item[1] -as [ipaddress]).AddressFamily -eq "InterNetworkV6") 
            { 
               $localAddress = $la.IPAddressToString 
               $localPort = $item[1].split("\]:")[-1] 
            } 
            else 
            { 
                $localAddress = $item[1].split(":")[0] 
                $localPort = $item[1].split(":")[-1] 
            } 

            if (($ra = $item[2] -as [ipaddress]).AddressFamily -eq "InterNetworkV6") 
            { 
               $remoteAddress = $ra.IPAddressToString 
               $remotePort = $item[2].split("\]:")[-1] 
            } 
            else 
            { 
               $remoteAddress = $item[2].split(":")[0] 
               $remotePort = $item[2].split(":")[-1] 
            } 

            New-Object PSObject -Property @{ 
                PID = $item[-1] 
                ProcessName = (Get-Process -Id $item[-1] -ErrorAction SilentlyContinue).Name 
                Protocol = $item[0] 
                LocalAddress = $localAddress 
                LocalPort = $localPort 
                RemoteAddress =$remoteAddress 
                RemotePort = $remotePort 
                State = if($item[0] -eq "tcp") {$item[3]} else {$null} 
            } | Select-Object -Property $properties 
        } 
    } 
}
