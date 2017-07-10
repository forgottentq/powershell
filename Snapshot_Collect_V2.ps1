## Collection script. 
# 
# User input controller information IP addresses or hostnames. 
$controllers = @() 
do { 
$input = (Read-Host "Please enter controller IPs, one at a time, on a new line.  Leave blank when finished and press enter.") 
if ($input -ne '') {$controllers += $input} 
} 
until ($input -eq '') 
# 
# Folder for CSV export  
$folder = $(read-host "Please Specify Path for CSV exports, E:  C:\reports\") 
# Prompt for credentials to connecto to netapp controllers. 
write-host "Please enter credentials to connect to Netapp Controllers" 
$cred = get-credential 
# 
$vms = $null 
$vms = @() 
# Begin collection, starting with first controller, and then looping through all controllers. 
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
######## Building volume information and adding new objects to $vms	 
 	foreach ($vol in $vols) { 
	$vms += New-Object PSOBject -Property @{ 
 			"Volume" = $vol.Name 
 		} 
 		$vmdirs = Read-NaDirectory -Path "/vol/$vol" | where {$_.Name -notlike "." -and $_.Name -notlike ".." -and $_.Type -eq "directory"} 
 		#### Building VM directory information where only directories on the root of each volume will be added, then adding new VMName objects to $vms 
 		foreach ($vm in $vmdirs) { 
 			$vms += New-Object PSObject -Property @{ 
 				"VMName" = $vm.Name 
 			} 
 			#### Building file information for each VM directory and adding new Path objects to $vms. 
 			$files = Read-NaDirectory -Path "/vol/$vol/$vm" | where {$_.Name -notlike "." -and $_.Name -notlike ".." -and $_.Name -notlike "*iorm.sf*" -and $_.Name -notlike "*iormstats.sf*" -and $_.Name -notlike "*.lck-686b000000000000"} 
 			foreach ($file in $files) { 
 				$location = get-NaFile -Path "/vol/$vol/$vm/$file"  
 				$vms += New-Object PSOBject -Property @{ 
 					"Path" = $location.Name 
 				}
 			}
 		}
 	}
 	#### Finally exporting all Volume, VMName, and Path objects out to CSV named with $folder which is defined at the top, and $controller that is in the loop. 
}  $vms | Select Volume,VMName,Path | Export-CSV $folder$controller.csv 
