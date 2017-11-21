

<# Convert to Dedup
Requires -Version 3.0
Requires -RunAsAdministrator
Requires -Modules HPE3PARPSToolkit
Requires -Modules Posh-SSH #>

## Import Modules
import-module HPE3PARPSToolkit
import-module Posh-SSH

## Global variables
$date = (Get-Date).tostring("yyyyMMdd")
$folderName = "C:\3Par\logs"

## 3Par variables
$3pars = "72.76.185.13"
$cred = import-clixml "C:\3Par_cred.xml"

## Email variables
$smtpUsername = "";
$smtpPassword = "";
$smtpServer = ""
$smtpPort = "587"
$emailFrom = ""
$emailTo = ""
$emailSubject = "3Par Deduplication Conversation Status"
$emailBody = "Please see attached log files..."
$attachmentPath = "C:\3Par\logs\"


get-sshsession | remove-sshsession

function Send-ToEmail([string]$email, [string]$attachmentpath){
    $message = new-object Net.Mail.MailMessage;
    $message.From = $emailFrom ;
    $message.To.Add($email);
    $message.Subject = $emailSubject ;
    $message.Body = $emailBody ;
    $attachment = New-Object Net.Mail.Attachment($attachmentPath);
    $message.Attachments.Add($attachment1);
	$message.Attachments.Add($attachment2);
	$smtp = new-object Net.Mail.SmtpClient($smtpServer, $smtpPort);
    $smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $smtpPassword);
    $smtp.send($message);
    write-host "Mail Sent" ;
#    $attachment.Dispose();
 }
 
function Validate-Folder {

    [CmdletBinding(ConfirmImpact='Low')] 
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeLine=$true,
                   ValueFromPipeLineByPropertyName=$true,
                   Position=0)]
            [String]$FolderName, 
        [Parameter(Mandatory=$false,
                   Position=1)]
            [Switch]$NoCreate = $false
    )

    if ($FolderName.Length -gt 254) {
        Write-Error "Folder name '$FolderName' is too long - ($($FolderName.Length)) characters"
        break
    }
    if (Test-Path $FolderName) {
        Write-Verbose "Confirmed folder '$FolderName' exists"
        $true
    } else {
        Write-Verbose "Folder '$FolderName' does not exist"
        if ($NoCreate) {
            $false
            break  
        } else {
            Write-Verbose "Creating folder '$FolderName'"
            try {
                New-Item -Path $FolderName -ItemType directory -Force -ErrorAction Stop | Out-Null
                Write-Verbose "Successfully created folder '$FolderName'"
                $true
            } catch {
                Write-Error "Failed to create folder '$FolderName'"
                $false
            }
        }
    }
}

foreach ($3par in $3pars){
	$attachment1 = "C:\3Par\logs\$3par_3par_Task_Failure_$date.csv"
	$attachment2 = "C:\3Par\logs\$3par_3par_Task_Success_$date.csv"
	$session = New-3ParPoshSshConnection -SANIPAddress $3par -SANUserName $cred.username -SANPassword $cred.GetNetworkCredential().password
	$cpgs = get-3parcpg | where {$_.Volumes -ne "Name" -and $_.Volumes -ne "total"}
	foreach ($cpg in $cpgs){
		$vvs = Get-3parvv | where {$_.CPG -eq "$($cpg.Volumes)"}
		foreach ($vv in $vvs){
			$vvlist = get-3parvvList -vvName $vv.Name
			if ($vvlist.Name -notlike "*pswp*" -and $vvlist.Name -notlike "*vswp*"){
				$cmds = "tunevv usr_cpg $($cpg.volumes) -f -tdvv $($vvList.Name)"
				invoke-3parclicmd -connection $session -cmds $cmds
# Sleep 60
			}
		}
	}
	Validate-Folder -FolderName $folderName
	Get-3parTask -Task_type convert_vv -option done -Hours 1  | Export-CSV "$folderName\$($3par)_3par_Task_Success_$date.csv"
	Get-3parTask -Task_type convert_vv -option failed -Hours 1 | Export-CSV "$folderName\$($3par)_3par_Task_Failure_$date.csv"
	Remove-sshsession -sessionId $session.SessionID
	Send-ToEmail  -email $EmailTo -attachmentpath $path ;
}
##
