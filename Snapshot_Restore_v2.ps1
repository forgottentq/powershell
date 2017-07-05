###### Restore script.
#
# User inputs controllers IP or hostname.
$controllers = @()
do {
 $input = (Read-Host "Please enter controller IPs, one at a time, on a new line.  Leave blank when finished and press enter.")
 if ($input -ne '') {$controllers += $input}
}
until ($input -eq '')
#
# Prompt for credentials to connect to Netapp Filers.
write-host "Please enter credentials to connect to Netapp Controllers"
$cred = get-credential 
# User enters the desired snapshot date they wish to restore to.
$dateinput = $(read-host "Please Enter the Snapshot date, IE:  7/2/2017")
$snapdate = get-date $dateinput 
# User enters the directory containing the controller Exports from the collection script.
$folder = $(read-host "Please specify location for CSV input IE: C:\reports\")
#
# Begin the restore process starting with the first controller, and looping through all controllers.
foreach ($controller in $controllers) {
	$pull = Import-CSV "$folder$controller.csv" | Select Path
	write-progress "Restoring all snapshots from $snapdate"
	try {
		connect-nacontroller -name $controller -credential $cred | out-null
		write-host "!! Connected to $controller !!" -foregroundcolor "Green"
	} catch {
		write-host "!! Unable to connect to $controller !!" -foregroundcolor "Red" 
		Continue
	}
	### Each individual file is restored using the Path property from the CSV that was imported. 
	foreach ($item in $pull){
		if ($item.Path){
			$vol = $item.Path.Split("/")[2]
			$snap = get-navol | where {$_.Name -eq $vol} | Get-NaSnapshot | where {$_.Created.Date -eq $snapdate}
			if ($snap){
				write-host $Item.Path "has a snapshot on $snapdate , restoring!!"
				Restore-NaSnapshotFile -Path $item.Path -SnapName $snap.Name -confirm:$false -ErrorAction SilentlyContinue
				write-host $item.Path.Split("/")[4] " has been Restored to $snapdate !!!" -Foregroundcolor "Green"
			}
		}
	}
}
