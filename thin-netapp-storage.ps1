function getthin-storage {
	$controllers = "controller1", "controller2", "controller3", "controller4" 
	$nacred = Import-clixml C:\users\forgotten\Documents\NACred.xml
	foreach ($controller in $controllers){
		connect-nacontroller -name $controller -credential $nacred | out-null 
		$vols = get-navol
		$luns = get-nalun
		write-host "$($controller)" -foregroundcolor "Green" -backgroundcolor "black"
		write-host "Volumes:" -foregroundcolor "Magenta" -backgroundcolor "black"
		foreach ($vol in $vols){
			$options = get-navoloption -Name $vol.Name
			if ($options.value -eq "none"){
			Write-host "!!! $($vol.name) Is Thin Provisioned!!!"
			}
		}
		write-host "LUNS:" -foregroundcolor "Magenta" -backgroundcolor "black"
		foreach ($lun in $luns){
			if ($lun.Thin -eq $true){
				write-host "!!! $($Lun.Path) Is Thin Provisioned !!!"
			}
		}
		; ""
		; ""
	}
}
