<# Snort Downloader / Parser.
   Witten by Wylie Bayes 3/5/2018
   Requires Winrar to be installed on local machine.

   Downloads latest snort tarball, extracts, and parses out only uncommented rules and creates new file for loading into snort. 
<#
function Get-SnortRules {
    write-progress "Gathering and Parsing Snort Rules...."
    # Define our awesome ASCII Pig
    $pig = @"
                                  ____
                                    \%%%%%%;.
                                     \%%%%%%%%;..
                       .\.           (%%%%%%%%%%%%;.
                     .;%%%;.        %%%%%%%%%%%%%%%%%;.
                     %%%%%%%%;     %%%%%%%%%%%%%%%%%%%%%;.
                     %%%%%%%%%)__(%%%%%%%%%%%%%%%%%%%%%%%%;.
                     ;%%%%%% /%%%%%\ %%%%%%%%%%%%%%%%%%%%%%%;
                      \%% /%/'''\%%%\ %%%%%%%%%%%%%%%%%%%%%%%;
                       '%%%%%%%\. \%%|/%%%%%%%%%%%%%%%%%%%%%%; %%
                     .;%%%%%%%%%%\|%%%%%%%%%%%%%%%%%%%%%%%%%% %%%
                    (%CCC%%%%CCC%\%%%%%%%%%%%%%%%%%%%%%%%%%/ %%%%
                   %%    !/       \%%%%%%%%%%%%%%%%%%%%%%/ %%%%%%
                  .%                %%% \%%%%%%%%%%%%%/'%%%%%%%%%
      .__\\/__. .%%%    o o         %%%% %%%%%%%%%%%/'%%%%%%%%%%%
   \.;%%%%%%%%%;.'%%                %%%% ,%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%/ %___.!.        /%%%% ,%%%%%%%% \%%%%%%%%%%%%%
 \%%     %%%     %%/ %%%%%%\      /%%%% ,%%%%%%%%% |%%%%%%%%%%%%%
/%%      %%%      %% %%%%%%%)?**&%%%% ,%%%%%%%%%%; |%%%%%%%%%%%%%
 %%      %%%      %% %%%%%%%%%%%%%/ ,%%%%%%%%%%%/ /%%%%%%%%%%%%%%
/%%%    %%%%%    %%% %%%%%%%;/',;/%%%%%%%%%;;../%%%%%%%%%%%%%%%%%
  %%%%%%/'''\%%%%%% ='''\\         \%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    //''     ''\\
"@
    #
    clear
    ;"" ;"" ;"" ;"" ;"" ;"" ;"" ;""
    write-host "Gathering and Parsing Snort Rules..." -Foregroundcolor "Green"
    #
    write-host "$pig"
    ;"" ;""
    # Create a date variable to use when naming output files.
    $date = get-date
    # Null our rules variable to ensure we start fresh.
    $rules = $null
    # Get current user account name
    $whoami = whoami
    $account = $whoami.split("\")[1]
    # Define our users Desktop path
    $desktop = "C:\users\$account\Desktop"
    # Remove temp folder on desktop and re-create fresh.
    Remove-Item "$desktop\Temp" -Recurse -Force -erroraction SilentlyContinue | out-null
    New-Item -ItemType Directory "$desktop\Temp" | out-null
    New-Item -ItemType Directory "$desktop\Temp\Extracted\" | out-null
    # Define Download URL
    $download = "https://www.snort.org/downloads/community/community-rules.tar.gz"
    # Define exports location
    $exports = "C:\Exports\"
    # Archive Previously parsed rules
    $archive = get-childitem "$exports\parsed\*.txt"
	if ($archive -ne $null){
		Move-Item $archive "$exports\parsed\archive\" -Force
		write-host "Archived previously parsed rules into archive folder" -foregroundcolor "Green"
	} else {
		write-host "No previous rules to archive. Continuing" -foregroundcolor "Yellow"
	}
    # Download new snort rules tarball
    Invoke-Webrequest -uri $download -Outfile "C:\users\$account\Desktop\Temp\community-rules.tar.gz" -UseBasicParsing -UseDefaultCredentials
    if ( (Get-FileHash -Algorithm SHA256 "$exports\community-rules.tar.gz").Hash -eq (Get-FileHash -Algorithm SHA256 "C:\users\$account\Desktop\Temp\community-rules.tar.gz").Hash){
        ;""
        write-host "Downloaded ruleset hash matches previously downloaded ruleset.  Rules are already current. Not continuing" -Foregroundcolor "Yellow"
        Remove-Item "$desktop\Temp" -Recurse -Force -erroraction silentlycontinue
        Break
    } else {
        ;""
        write-host "Downloaded ruleset is newer than previously downloaded ruleset.  Continuing" -Foregroundcolor "Green"
    }
    Copy-Item "C:\users\$account\Desktop\Temp\community-rules.tar.gz" $exports
    # Use WinRAR on local system to extract snort rules to temp desktop location
    start-process -FilePath "C:\Program Files\WinRAR\winrar.exe" -ArgumentList "x -ibck C:\users\$account\Desktop\Temp\community-rules.tar.gz *.* C:\users\$account\Desktop\Temp\Extracted\"
    Sleep 5
    $items = Get-Childitem "C:\users\$account\Desktop\Temp\Extracted\community-rules\"
    # Copy the extracted files from our temp location to our network share location.
    foreach ($item in $items){
        copy-item $item.FullName "$exports\Extracted\"
    }
    # Remove temp desktop folder after copying to share.
    Remove-Item "$desktop\Temp" -Recurse -Force -erroraction silentlycontinue
    # Import rules into a variable that don't start with comment hash #
    $rules = get-content "$exports\Extracted\community.rules" | Where { $_ -notmatch "^#" -and $_ -ne "" } 
    $rules | out-file "$exports\parsed\Snort_$($date.month)_$($date.day)_$($date.year)_parsed_rules.txt"
    # Write out rule count and open parsed folder.
    ;""
    write-host "Parsed $($rules.count) Rules... Opening share location..." -Foregroundcolor "Green"
    ii "$exports\Parsed\"
}
Get-SnortRules.txt
Displaying getotx-data.txt.
