#
#
# Greynoise Powershell Parser
# Writen by Wylie Bayes
# 09/05/2019
#
#
$apikey = "YOUR API KEY GOES HERE"
$actors = Invoke-RestMethod -uri "https://api.greynoise.io/v2/research/actors" -Headers @{"key"="$apikey"}
#
foreach ($ip in $actors.ips){
    $actor = Invoke-RestMethod -uri "https://api.greynoise.io/v2/noise/context/$ip" -Headers @{"key"="$apikey"}
    if ($actor.classification -ne "benign"){
        write-host "$($actor.actor) with an IP of: $($actor.ip) has a classification of: $($actor.classification)"
    }
}
