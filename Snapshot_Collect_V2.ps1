## Collection script.
#
#
$controllers = @()
do {
 $input = (Read-Host "Please enter controller IPs, one at a time, on a new line.  Leave blank when finished and press enter.")
 if ($input -ne '') {$controllers += $input}
}
until ($input -eq '')


$folder = $(read-host "Please Specify Path for CSV exports, E:  C:\reports\")
write-host "Please enter credentials to connect to Netapp Controllers"
$cred = get-credential

$vms = $null
$vms = @()
foreach ($controller in $controllers) {
write-progress "Collecting all folder structure data except Vol0"
	try {
		connect-nacontroller -Name $controller -Credential $cred -Https | out-null
		write-host "!! Connected to $controller !!" -ForeGroundColor "Green"
	} catch {
		Write-host "Unable to connect to $($controller)" -Foregroundcolor "Red"
		Continue
	}
	$vols = get-navol | where {$_.Name -notlike "vol0"}
	foreach ($vol in $vols) {
		$vms += New-Object PSOBject -Property @{
			"Volume" = $vol.Name
		}
		$vmdirs = Read-NaDirectory -Path "/vol/$vol" | where {$_.Name -notlike "." -and $_.Name -notlike ".." }
		foreach ($vm in $vmdirs) {
			$vms += New-Object PSObject -Property @{
				"VMName" = $vm.Name
			}
			$files = Read-NaDirectory -Path "/vol/$vol/$vm" | where {$_.Name -notlike "." -and $_.Name -notlike ".."}
			foreach ($file in $files) {
				$location = get-NaFile -Path "/vol/$vol/$vm/$file" 
				$vms += New-Object PSOBject -Property @{
					"Path" = $location.Name
				}
			}
		}
	}
}  $vms | Select Volume,VMName,Path | Export-CSV $folder$controller.csv















