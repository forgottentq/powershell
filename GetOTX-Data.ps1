
#
# Powershell script to pull indicators from Alien Vault Opensource Threat Exchange and export to CSVs for importing into Arcsight or other SIEM.
#
#
# Define Main Function, set variables to Null, and then define as arrays. 
function GetOTX-Data {
	$otxkey = "YOUR API KEY GOES HERE"
        $exports = "C:\Exports\" #Define your Export Location Here!
	$FileHashesEPO = $null
	$FileHashesPalo = $null
	$hostnames = $null
	$IPV4s = $null
	$IPV6s = $null
	$Emails = $null
	$URLs = $null
	$CVEs = $null
	$hostnames = @()
	$IPV4s = @()
	$IPV6s = @()
	$URLs = @()
	$FileHashesEPO = @()
	$FileHashesPalo = @()
	$Emails = @()
	$CVEs = @()
	;""
	;""
	;""
	#Populate our awesome ascii art into an array
	$alien = @"
				      Alien Vault
		
.     .       .  .   . .   .   . .    +  .
  .     .  :     .    .. :. .___---------___.
       .  .   .    .  :.:. _".^ .^ ^.  '.. :"-_. .
    .  :       .  .  .:../:            . .^  :.:\.
        .   . :: +. :.:/: .   .    .        . . .:\
 .  :    .     . _ :::/:               .  ^ .  . .:\
  .. . .   . - : :.:./.                        .  .:\
  .      .     . :..|:                    .  .  ^. .:|
    .       . : : ..||        .                . . !:|
  .     . . . ::. ::\(                           . :)/
 .   .     : . : .:.|. ######              .#######::|
  :.. .  :-  : .:  ::|.#######           ..########:|
 .  .  .  ..  .  .. :\ ########          :######## :/
  .        .+ :: : -.:\ ########       . ########.:/
    .  .+   . . . . :.:\. #######       #######..:/
      :: . . . . ::.:..:.\           .   .   ..:/
   .   .   .  .. :  -::::.\.       | |     . .:/
      .  :  .  .  .-:.":.::.\             ..:/
 .      -.   . . . .: .:::.:.\.           .:/
.   .   .  :      : ....::_:..:\   ___.  :/
   .   .  .   .:. .. .  .: :.:.:\       :/
     +   .   .   : . ::. :.:. .:.|\  .:/|
     .         +   .  .  ...:: ..|  --.:|
.      . . .   .  .  . ... :..:.."(  ..)"
 .   .       .      :  .   .: ::/  .  .::\

"@
	#Write out pretty ascii art to the screen.
	write-host "$alien"
	#Define our Error preference.
	$ErrorActionPreference = "SilentlyContinue"
	#Archive previous days export into the archive folder.
	$archive = get-childitem "$exports\*.csv"
	if ($archive -ne $null){
		Move-Item $archive "$exports\archive\" -Force
		write-host "Archived previous CSVs into the archive folder" -foregroundcolor "Green"
	} else {
		write-host "No previous CSV's to archive. Continuing" -foregroundcolor "Yellow"
	}
	#Get the date for naming CSV exports at the end.
	$date = get-date
	#Define first page to begin.
	$next = "https://otx.alienvault.com/api/v1/pulses/subscribed/?limit=50&page=1"
	do {
		write-progress "Pulling all AlienVault indicators and exporting to CSVs"
		$indicators = invoke-webrequest -URI $next -UseBasicParsing -Headers @{"X-OTX-API-KEY"="$otxkey"} -UseDefaultCredentials
		# Convert JSON data received into powershell object.
		$data = $indicators.Content | ConvertFrom-Json
		# Populate the next page into $next variable.
		$next = $data.next
		if ($data.Results){
			write-progress "Processing:  $next"
			foreach ($item in $data.Results.indicators){
				# Gather Domain and Subdomain Names Indicators
				if ($item.Type -eq "hostname" -or $item.type -eq "domain"){
					#$hostnames += new-object PSObject -Property @{"Hostname"="$($item.Indicator)"; b="b"}
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
						$URLs += new-object PSObject -Property @{"URL"="$($item.indicator)"}
					} else {
						$URLs += new-object PSObject -Property @{"URL"="http://$($item.indicator)"}
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
				if ($item.Type -eq "CVE"){
					$CVEs += new-object PSObject -Property @{"Email"="$($item.Indicator)"}
				}
			}
		}
	} while ($next -ne $null)
	## Export all indicators to CSVs if data exists in each object.
	if ($hostnames){
		$hostnames | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)hostnames_$($date.month)_$($date.day)_$($date.year).csv"
	}
	if ($IPV4s) {
		$IPV4s | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)IPV4s_$($date.month)_$($date.day)_$($date.year).csv"
	}
	if ($IPV6s) {
		$IPV6s | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)IPV6s_$($date.month)_$($date.day)_$($date.year).csv"
	}
	if ($URLs) {
		$URLs | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)URLs_$($date.month)_$($date.day)_$($date.year).csv"
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
	if ($CVEs){
		$CVEs | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Set-Content "$($exports)CVEs_$($date.month)_$($date.day)_$($date.year).csv"
	}
}
#
