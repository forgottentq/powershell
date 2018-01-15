#
# Usage:   Find-Streams "C:\"
#
function Find-Streams($location) {
	$files = get-childitem -Recurse -Path $location -erroraction SilentlyContinue
	foreach ($file in $files){
		$streams = get-item -path $file.Fullname -stream * | where {$_.Stream -ne ':$DATA' -and $_.Stream -ne 'Zone.Identifier'}
		if ($streams -ne $false){
			foreach ($stream in $streams){
				#Do other stuff.. Write to a sperate file.. Create a custom psobject and export to CSV at the end.. etc.
				write-host "$($file.Fullname) contains non-standard streams"
				get-content -path $file.fullname -stream $stream.Stream
				;""
			}
		}
	}
}
