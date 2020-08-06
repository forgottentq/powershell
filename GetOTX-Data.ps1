#
# Powershell script to pull indicators from Alien Vault Opensource Threat Exchange(OTX) and export to CSVs for importing into Arcsight or other SIEM.
# Written by Wylie Bayes 02/23/2018
#
# Define Main Function, set variables to Null, and then define as arrays. 
function GetOTX-Data {
	clear
	$otxkey = "YOUR API KEY GOES HERE!!"
	# Define export location.
	$exports = "C:\Exports\"
	$whitelists = "C:\Whitelists"
	# How old are indicators allowed to be in days
	$daysold = "30"
	#
	$FileHashesEPO = $null
	$FileHashesPalo = $null
	$hostnames = $null
	$IPV4s = $null
	$IPV6s = $null
	$Emails = $null
	$URLs = $null
	$CVEs = $null
	$counts = $null
	$total = $null
	$hostnames = @()
	$IPV4s = @()
	$IPV6s = @()
	$URLs = @()
	$FileHashesEPO = @()
	$FileHashesPalo = @()
	$Emails = @()
	$CVEs = @()
	$counts = @()
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
	# Write out pretty ascii art to the screen.
	write-host "$alien"
	# Define our Error preference.
	$ErrorActionPreference = "SilentlyContinue"
	# Archive previous days export into the archive folder.
	$archive = get-childitem "$exports\*.csv"
	if ($archive -ne $null){
		Move-Item $archive "$exports\archive\" -Force
		write-host "Archived previous CSVs into the archive folder" -foregroundcolor "Green"
	} else {
		write-host "No previous CSV's to archive. Continuing" -foregroundcolor "Yellow"
	}
	# Pull in White Lists for Exclusions
	$IPv4WL = Import-CSV "$whitelists\IPv4s.csv" | where {(get-date $_."WhiteListed Date") -gt (get-date).AddDays(-30)}
	$CVEWL = Import-CSV "$whitelists\CVEs.csv" | where {(get-date $_."WhiteListed Date") -gt (get-date).AddDays(-30)}
	$DomainOrHostnameWL = Import-CSV "$whitelists\DomainOrHostnames.csv" | where {(get-date $_."WhiteListed Date") -gt (get-date).AddDays(-30)}
	$EmailWL = Import-CSV "$whitelists\Emails.csv" | where {(get-date $_."WhiteListed Date") -gt (get-date).AddDays(-30)}
	$FileHashWL = Import-CSV "$whitelists\FileHashes.csv" | where {(get-date $_."WhiteListed Date") -gt (get-date).AddDays(-30)}
	$URLWL = Import-CSV "$whitelists\URLs.csv" | where {(get-date $_."WhiteListed Date") -gt (get-date).AddDays(-30)}
	# Get the date for naming CSV exports at the end.
	$date = get-date
	# Define a bit of regex for later
	$regex = "[^a-zA-Z]"
	# Define first page to begin.
	$next = "https://otx.alienvault.com/api/v1/pulses/subscribed/?limit=10&page=1"
	do {
		write-progress "Pulling all AlienVault indicators and exporting to CSVs. Processing page: $page"
		$indicators = invoke-webrequest -URI $next -UseBasicParsing -Headers @{"X-OTX-API-KEY"="$otxkey"} -UseDefaultCredentials
		# Convert JSON data received into powershell object.
		$data = $indicators.Content | ConvertFrom-Json
		# Populate the next page into $next variable.
		$next = $data.next
		$page = $next.split("&")[1].split("=")[1]
		#
		$filtered = $data.Results | where {$_.References -ne $null}
		if ($filtered){
			foreach ($item in $filtered){
				$name = $null
				$name = $item.Name -replace $regex
				$LastModified = get-date $item.Modified
				if ($LastModified -gt (get-date).AddDays("-$daysold")){
					foreach ($indicator in $Item.Indicators) {
						# Gather Domain and Subdomain Names Indicators
						if ($indicator.Type -eq "hostname" -or $indicator.type -eq "domain" -and $indicator.indicator -notin $DomainOrHostnameWL.DomainOrHostName){
							if ($item.References -like "*http*") {
								$hostnames += new-object PSObject -Property @{"Hostname"="$($indicator.Indicator)"; "Name"="$($name)"; "Reference"="$($item.References)"} | Select Hostname,Name,Reference
							}
						}
						# Gather All IPV4 Indicators
						if ($indicator.Type -eq "IPv4" -and $indicator.indicator -notin $IPv4WL."IPv4 Address"){
							if ($item.References -like "*http*"){
								$IPV4s += new-object PSObject -Property @{"IPv4 Address"="$($indicator.Indicator)"; "Name"="$($name)"; "Reference"="$($item.References)"} | Select "IPv4 Address",Name,Reference
							}
						}
						# Gather All IPV6 Indicators
						if ($indicator.Type -eq "IPv6"){
							if ($item.References -like "*http*"){
								$IPV6s += new-object PSObject -Property @{"IPv6 Address"="$($indicator.Indicator)"; "Name"="$($name)"; "Reference"="$($item.References)"} | Select "IPv6 Address",Name,Reference
							}
						}
						# Gather All URL Indicators
						if ($indicator.Type -eq "URL" -and $indicator.indicator -notin $URLWL.URL){
							if ($item.References -like "*http*"){
								$URLs += new-object PSObject -Property @{"URL"="$($indicator.indicator)"; "Name"="$($name)"; "Reference"="$($item.References)"} | Select URL,Name,Reference
							}
						}
						# Gather all File Hash Indicators
						if ($indicator.Type -eq "FileHash-MD5" -or $indicator.Type -eq "FileHash-SHA1" -or $indicator.Type -eq "Filehash-SHA256" -and $indicator.indicator -notin $FileHashWL.FileHash){
							if ($item.References -like "*http*"){
								if ($item.References -ne $null -and $item.References -like "*http*"){
									$FileHashesEPO += new-object PSObject -Property @{"FileHash"="AppHash: $($indicator.Indicator)"; "Name"="$($name)"; "Reference"="$($item.References)"} | Select FileHash,Name,Reference
									$FileHashesPalo += new-object PSObject -Property @{"FileHash"="$($indicator.Indicator)"; "Name"="$($name)"; "Reference"="$($item.References)"} | Select FileHash,Name,Reference
								}
							}
						}
						# Gather all Email Indicators
						if ($indicator.Type -eq "email" -and $indicator.indicator -notin $EmailWL."Email Address"){
							if ($item.References -like "*http*"){
								$Emails += new-object PSObject -Property @{"Email"="$($indicator.Indicator)"; "Name"="$($name)"; "Reference"="$($item.References)"} | Select Email,Name,Reference
							}
						}
						if ($indicator.Type -eq "CVE" -and $indicator.indicator -notin $CVEWL.CVE){
							if ($item.References -like "*http*"){
								$CVEs += new-object PSObject -Property @{"CVE"="$($indicator.Indicator)"; "Name"="$($name)"; "Reference"="$($item.References)"} | Select CVE,Name,Reference
							}
						}
					}
				}
			}
		}
	} while ($next -ne $null)
	# Export all indicators to CSVs if data exists in each object.
	if ($hostnames){
		$hostnames | ConvertTo-Csv -NoTypeInformation | Select -Skip 1 | Set-Content "$($exports)Hostnames_$($date.month)_$($date.day)_$($date.year).csv"
	}
	if ($IPV4s) {
		$IPV4s | ConvertTo-Csv -NoTypeInformation | Select -Skip 1 | Set-Content "$($exports)IPV4s_$($date.month)_$($date.day)_$($date.year).csv"
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
	# Total up the indicators and create a CSV just for number tracking.
	$total = $hostnames.count + $IPv4s.count + $URLs.count + $FileHashesEPO.count + $Emails.count + $CVEs.count
	$counts = new-object PSObject -Property @{"Hostnames"="$($hostnames.count)"; "IPv4s"="$($IPv4s.count)"; "URLs"="$($URLs.Count)"; "FileHashes"="$($FileHashesEPO.count)"; "Emails"="$($Emails.Count)"; "CVEs"="$($CVEs.count)"; "Total"="$($total)"} | Select Hostnames,IPv4s,URLs,FileHashes,Emails,CVEs,Total
	$counts | Export-csv "$($exports)Total_Numbers_$($date.month)_$($date.day)_$($date.year).csv" -NoTypeInformation
	# Open exports folder and complete the operation.
	write-host "Opening exports folder..." -foregroundcolor "green"
	ii $exports
}
