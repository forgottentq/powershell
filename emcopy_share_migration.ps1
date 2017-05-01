#
# Share Migration Script.
#
# This script requires you have "emcopy64.exe" in your C:\windows\system32\ folder.
#
#
#
try {
# DEFINE ME for CSVs location !!!
$csvlocation = "C:\Output\"
# DEFINE ME for CSVs location !!!
} catch {
	write-host "Unable to locate CSV, check source path.  Exiting"
	Return
}
#
$date = (Get-Date).tostring("yyyyMMdd")
$sourcecsv = $null
$sourcecsv = @()
$ans = $null
$menu =@"
1 - Import all CSVs and start single copy job of all CSVs.
2 - Import all CSVs and start multi-threaded copy job for each CSV.
3 - Select a single, or multiple CSVs from list and start single copy job of selected CSVs.
4 - Select a single, or multple CSVs from list and start a multi-threaded copy job of selected CSVs.
5 - Manually input source CSV Path and start single copy job, IE: C:\file.csv.
Q - Quit.
"@
#
Write-Host "Select an option below for CSV input" -ForegroundColor Cyan
$r = Read-Host $menu
Switch ($r) {
"1" {
    Write-Host "Importing all CSVs from $($csvlocation)" -ForegroundColor Green
    $csvs = gci -Path $csvlocation *.csv
	foreach ($csv in $csvs){
		$sourcecsv = Import-Csv $csv.FullName
		foreach ($item in $sourcecsv){
			try {
				Test-Path $item.Destination
			} catch {
				write-host "$($item.Destination) not accessiable, moving on to next item."
				Continue
			}
			$date = (Get-Date).tostring("yyyyMMdd")
			$name = $item.FullName.Split("\\")[2]
			emcopy64 $item.FullName $item.Destination /s /o /c /r:3 /w:5 /q /log+:C:\evt\log\$name'_'$date.log
		}
	}
	Return
}
#
"2" {
	write-host "Import all CSVs from $($csvlocation) and start multi-job copy for each CSV." 
	$csvs = gci -Path $csvlocation *.csv
	foreach ($csv in $csvs) {
		$sourcecsv = import-csv $csv.FullName
		Start-Job -ArgumentList $csv -scriptblock {
			param($csv)
			$sourcecsv = import-csv $csv.FullName
			foreach ($item in $sourcecsv){
			try {
				Test-Path $item.Destination
			} catch {
				write-host "$($item.Destination) not accessiable, moving on to next item."
				Continue
			}	
				$date = (Get-Date).tostring("yyyyMMdd")
				$name = $item.FullName.Split("\\")[2]
				emcopy64 $item.FullName $item.Destination /s /o /c /r:3 /w:5 /q /log+:C:\evt\log\$name'_'$date.log
			}
		}
	}
	$jobs = get-job | ? { $_.state -eq "running" }
	$total = $jobs.count
	$runningjobs = $jobs.count
	while($runningjobs -gt 0) {
		write-progress -activity "Migrating" -status "Progress:" -percentcomplete (($total-$runningjobs)/$total*100)
		$runningjobs = (get-job | ? { $_.state -eq "running" }).Count
	}
	Return
}
#
"3" {
    Write-Host "Choose which CSV files you wish to import:" -ForegroundColor Green
    $csvs = gci -Path $csvlocation *.csv
	$menu3 = @{}
	for ($i=1;$i -le $csvs.count; $i++) { 
		Write-Host "$i. $($csvs[$i-1].name)" 
		$menu3.Add($i,($csvs[$i-1].FullName))
	}
	do {
		$input = Read-Host ("Enter each selection on a single line and press enter.  Leave blank and press enter when finished.")
	if ($input -ne '') {[int[]]$ans += $input}
	}
	until ($input -eq '')
	$selection = @()
	foreach ($an in $ans){
		$selection += $menu3.Item($an)
		$sourcecsv += $selection
	}
	$sourcecsv = import-csv $selection
		foreach ($item in $sourcecsv){
		try {
			Test-Path $item.Destination
		} catch {
			write-host "$($item.Destination) not accessiable, moving on to next item."
			Continue
		}
		$date = (Get-Date).tostring("yyyyMMdd")
		$name = $item.FullName.Split("\\")[2]
		emcopy64 $item.FullName $item.Destination /s /o /c /r:3 /w:5 /q /log+:C:\evt\log\$name'_'$date.log
	}
	Return
}
#
"4" {
    Write-Host "Choose which CSV files you wish to import:" -ForegroundColor Green
    $csvs = gci -Path $csvlocation *.csv
	$menu3 = @{}
	for ($i=1;$i -le $csvs.count; $i++) { 
		Write-Host "$i. $($csvs[$i-1].name)" 
		$menu3.Add($i,($csvs[$i-1].FullName))
	}
	do {
		$input = Read-Host ("Enter each selection on a single line and press enter.  Leave blank and press enter when finished.")
	if ($input -ne '') {[int[]]$ans += $input}
	}
	until ($input -eq '')
	$selection = @()
	foreach ($an in $ans){
		$selection += $menu3.Item($an)
		$sourcecsv += $selection
	}
	foreach ($csv in $selection) {
		Start-Job -ArgumentList $csv -scriptblock {
			param($csv)
			$sourcecsv = import-csv $csv
			foreach ($item in $sourcecsv){
				try {
				Test-Path $item.Destination
				} catch {
				write-host "$($item.Destination) not accessiable, moving on to next item."
				Continue
				}
			}
			$date = (Get-Date).tostring("yyyyMMdd")
			$name = $item.FullName.Split("\\")[2]
			emcopy64 $item.FullName $item.Destination /s /o /c /r:3 /w:5 /q /log+:C:\evt\log\$name'_'$date.log
		}
	}
	$jobs = get-job | ? { $_.state -eq "running" }
	$total = $jobs.count
	$runningjobs = $jobs.count
	while($runningjobs -gt 0) {
		write-progress -activity "Migrating" -status "Progress:" -percentcomplete (($total-$runningjobs)/$total*100)
		$runningjobs = (get-job | ? { $_.state -eq "running" }).Count
	}
	Return
}
#
"5" {
    $sourcecsv = import-csv -Path $(read-host "Enter path to CSV Input, IE: C:\sharesource.csv") -ErrorAction Stop
		foreach ($item in $sourcecsv){
		try {
			Test-Path $item.Destination
		} catch {
			write-host "$($item.Destination) not accessiable, moving on to next item."
			Continue
		}
		$date = (Get-Date).tostring("yyyyMMdd")
		$name = $item.FullName.Split("\\")[2]
		emcopy64 $item.FullName $item.Destination /s /o /c /r:3 /w:5 /q /log+:C:\evt\log\$name'_'$date.log
	}
	Return
}
 
"Q" {
    Write-Host "Quitting" -ForegroundColor Green
}
#
default {
    Write-Host "I don't understand what you want to do." -ForegroundColor Yellow
}
} #end switch
