# ip-api.com Batch Collector

#$api = "http://ip-api.com/batch?fields=21229119"
#
$logo = @"
_____ _____               _____ _____    ____        _       _      
|_   _|  __ \        /\   |  __ \_   _| |  _ \      | |     | |     
  | | | |__) |_____ /  \  | |__) || |   | |_) | __ _| |_ ___| |__   
  | | |  ___/______/ /\ \ |  ___/ | |   |  _ < / _` | __/ __| '_ \  
 _| |_| |         / ____ \| |    _| |_  | |_) | (_| | || (__| | | | 
|_____|_|    _ _ /_/    \_\_|   |_____| |____/ \__,_|\__\___|_| |_| 
 / ____|    | | |         | |                                       
| |     ___ | | | ___  ___| |_ ___  _ __                            
| |    / _ \| | |/ _ \/ __| __/ _ \| '__|                           
| |___| (_) | | |  __/ (__| || (_) | |                              
 \_____\___/|_|_|\___|\___|\__\___/|_|                                                                                                                                         
"@
#
#
#
#
#
function invoke-api {
    write-host $logo
    $sw = new-object system.diagnostics.stopwatch
    $sw.Start()
    $ips = $null
    $ips = @()
    $ips = get-content "C:\Users\forgo\Desktop\Jon API Whois Collector\sample_ips.csv"
    $api = "http://ip-api.com/batch?fields=21229119"
    $bulkdata = $null
    $bulkdata = @()
    #
    for ($i = 0; $i -lt $ips.length; $i+=99) { 
        $batch = $ips[$i..($i + 99)]
        $Body = $null
        $ip_list = $batch
        $temp = $null
        $temp += '"'
        $temp += $ip_list -join '", "'
        $temp += '"'
        $body = "[$temp]"
        $Results = $null
        $Results = invoke-restmethod -Method 'Post' -uri $api -Body $body
        foreach ($result in $results){
            $bulkdata += New-Object PSObject -Property @{
                "IPAddress"=$Result.query
                "ISP"=$Result.isp
                "Organization"=$Result.org
                "AutonomousSystem"=$Result.as
                "City"=$Result.city
                "Country"=$Result.country
                "CountryCode"=$Result.countryCode
                "Region"=$Result.region
                "RegionName"=$Result.regionName
                "Status"=$Result.status
                "ZipCode"=$Result.zip
                "Mobile"=$Result.mobile
                "Proxy"=$Result.proxy
                "Hosting"=$Result.hosting
            } | Select IPAddress,ISP,Organization,AutonomousSystem,City,CountryCode,Region,RegionName,Status,ZipCode,Mobile,Proxy,Hosting
        }
            sleep 4
        }
        $date = get-date
        $bulkdata | Export-CSV -NoTypeInformation -path ".\Bulk_Results_$($date.month)_$($date.day)_$($date.year).csv"
        $sw.stop()
        write-host "You processed $($ips.count) IP Addresses in:" -foregroundcolor "green" -backgroundcolor "black"
        write-host ;""
        $sw.Elapsed
        write-host ;""
        write-host ;""
        write-host "Results have been successfully exported!" -ForegroundColor Green
    }
