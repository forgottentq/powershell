function GetOTX-Data {
        $otxkey = "YOUR_API_KEY_HERE"
        $URLs = $null
        $FileHashesEPO = $null
        $FileHashesPalo = $null
        $hostnames = $null
        $IPV4s = $null
        $Emails = $null
        $URLsHost = $null
        $URLsPathQuery = $null
        $hostnames = @()
        $IPV4s = @()
        $URLs = @()
        $URLsHost = @()
        $URLsPathQuery = @()
        $FileHashesEPO = @()
        $FileHashesPalo = @()
        $Emails = @()
        $exports = "C:\users\bayesw\desktop\exports\"
        $date = get-date
        $next = "https://otx.alienvault.com/api/v1/indicators/export?page=1"
        do {
                write-progress "Pulling all AlienVault indicators and exporting to CSVs"
                $indicators = invoke-webrequest -URI $next -UseBasicParsing -Headers @{"X-OTX-API-KEY"="$otxkey"} -UseDefaultCredentials
                $data = $indicators.Content | ConvertFrom-Json
                $next = $data.next
                write-host "$next"
                if ($data.Results){
                        foreach ($item in $data.Results){
                                # Gather Domain and Subdomain Names Indicators
                                if ($item.Type -eq "hostname" -or $item.type -eq "domain"){
                                        $hostnames += new-object PSObject -Property @{"Hostname"="$($item.Indicator)"}
                                }
                                #Gather All IPV4 Indicators
                                if ($item.Type -eq "IPv4"){
                                        $IPV4s += new-object PSObject -Property @{"IPv4 Address"="$($item.Indicator)"}
                                }
                                #Gather All IPV6 Indicators
                                if ($item.Type -eq "IPv6"){
                                        $IPV6s += new-object PSObject -Property @{"IPv6 Address"="$($item.Indicator)"}
                                }
                                #Gather All URL Indicators
                                if ($item.Type -eq "URL"){
                                        if ($item.indicator -like "*http://*" -or $item.indicator -like "*https://*"){
                                                [uri]$uri = $item.indicator
                                                $split = $uri.PathAndQuery.split("?")[0]
                                                $URLsHost += new-object PSObject -Property @{"URL Host"="$($uri.Host)"}
                                                $URLsPathQuery += new-object PSObject -Property @{"URL Path"="$($split)"}
                                        } else {
                                                [uri]$uri = "http://$($item.indicator)"
                                                if ($uri.PathAndQuery -eq '/'){
                                                        $blank = "blank"
                                                } else {
                                                        $split = $uri.PathAndQuery.split("?")[0]
                                                        $URLsHost += new-object PSObject -Property @{"URL Host"="$($uri.Host)"}
                                                        $URLsPathQuery += new-object PSObject -Property @{"URL Path"="$($split)"}
                                                }
                                        }
                                }
                                #Gather all File Hash Indicators
                                if ($item.Type -eq "FileHash-MD5" -or $item.Type -eq "FileHash-SHA1" -or $item.Type -eq "Filehash-SHA256"){
                                        $FileHashesEPO += new-object PSObject -Property @{"FileHash"="AppHash: $($item.Indicator)"}
                                        $FileHashesPalo += new-object PSObject -Property @{"FileHash"="$($item.Indicator)"}
                                }
                                #Gather all Email Indicators
                                if ($item.Type -eq "email"){
                                        $Emails += new-object PSObject -Property @{"Email"="$($item.Indicator)"}
                                }
                        }
                }
        } while ($next -ne $null)
        ## Export all indicators to CSVs.
        if ($hostnames -ne $null){
                $hostnames | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)hostnames_$($date.month)_$($date.day)_$($date.year).csv"
        }
        if ($IPV4s) {
                $IPV4s | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)IPV4s_$($date.month)_$($date.day)_$($date.year).csv"
        }
        if ($IPV6s) {
                $IPV6s | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)IPV6s_$($date.month)_$($date.day)_$($date.year).csv"
        }
        if ($URLsHost) {
                $URLsHost | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)URLsHost_$($date.month)_$($date.day)_$($date.year).csv"
        }
        if ($URLsPathQuery) {
                $URLsPathQuery | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)URLsPathQuery_$($date.month)_$($date.day)_$($date.year).csv"
        }
        if ($FileHashesEPO) {
                $FileHashesEPO | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)FileHashesEPO_$($date.month)_$($date.day)_$($date.year).csv"
        }
        if ($FileHashesPalo) {
                $FileHashesPalo | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)FileHashesPalo_$($date.month)_$($date.day)_$($date.year).csv"
        }
        if ($Emails){
                $Emails | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)Emails_$($date.month)_$($date.day)_$($date.year).csv"
        }
}
