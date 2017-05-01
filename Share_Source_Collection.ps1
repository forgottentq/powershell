$menu =@"
1 - CIFS Source Collection.
2 - Split a Master CSV into Multiple CSVs.
Q - Quit.
"@
Write-Host "Select an option below:" -ForegroundColor Cyan
$r = Read-Host $menu
Switch ($r) {
"1" {
#
# Source Collection Script.
#
# Interactive mode:
$sources = $null
$date = (Get-Date).tostring("yyyyMMdd")
$sources = @()
$data = @()
do {
	$input = (Read-Host "Please enter each share location: IE:\\server\share and press enter.  When finished leave blank and press enter")
	if ($input -ne '') {$sources += $input}
}
until ($input -eq '')
# Interactive mode
#
# DEFINE ME!!! Hardcoded Sources
#	$sources = "\\serverexample\share", "\\serverexample2\share2", "\\serverexample3\share3"
# DEFINE ME!!! Hardcoded Sources
#
# DEFINE ME (CSV Output File Location)!!!!
	$location = "C:\output\$date'_'test.csv"
# DEFINE ME (CSV Output File Location)!!!!

foreach ($source in $sources) {
	try {
		Test-Path $source | out-null
	} catch {
		write-host "Unable to connect to $($source) , please check share access and path"
		Return
	}
	$data += New-Object PSobject -Property @{
					"FullName" = $source
				} | Select "FullName" 
}
$data | select "FullName" | Export-CSV -Path $location
;""
;""
write-host "--- Executing Split Master CSV ---"
	}
	
"2" {
	#### Master PDF Splitter v1
	#
	#
	#
	############################################# 
	# Split Master CSV into multiple CSVs # 
	############################################# 
	# 
	#
	#
	#
	#
	$linecount = 0 
	$filenumber = 1 
	$source = Read-Host "What is the full path to master CSV? IE:  C:\csvs\master.csv"
	try {
		Test-path $source
	} catch {
		Write-host "Unable to locate $source, check your input path." -foregroundcolor "red" -backgroundcolor "black"
		Return
	}
	;""
	$destination = Read-Host "Enter Path destination path for split CSVs:  IE: C:\csvs\splits\" 
	try {
		Test-path $destination
	} catch {
		Write-host "Unable to locate $destination, check your input path" -foregroundcolor "red" -backgroundcolor "black"
		Return
	}
	#
	Write-Host "Please wait while the line count is calculated." -foregroundcolor "green" -backgroundcolor "black"
	#
	$content = Get-Content $source
	$count = $content.count
	Write-Host "Your current file size is $count lines long" -foregroundcolor "yellow" -backgroundcolor "black"
	;""
	$split = Read-Host "Enter number of files you wish to split the master into. IE: 5 "
	$divided = $count/$split 
	$rounded = [math]::ceiling($divided)
	$maxsize = [int]$rounded 
	#
	$content = get-content $source | % { 
		Add-Content $destination\splitlog$filenumber.csv "$_" 
		$linecount ++ 
		If ($linecount -eq $maxsize) { 
			$filenumber++ 
			$linecount = 0 
		}
	}
	[gc]::collect()  
	[gc]::WaitForPendingFinalizers()
	write-host "!!! Don't forget to append header information into each split CSV prior to running migration script. !!!" -foregroundcolor "magenta"
	Return
	}	
	"Q" {
		Write-Host "Quitting" -ForegroundColor Green
	}
}
