# =====================================================================
# Prologue : Copyright 2017
# Author   : Dzevel ROGOVIC
# =====================================================================

cls
Set-ExecutionPolicy Unrestricted

[string]$CurrentDir = $(get-location).Path
[string]$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
[string]$Depot = "https://raw.githubusercontent.com/jewelro/PSscripts/master/"

# Log file
[string]$fileName = "mainInstall"
[string]$logfile = $CurrentDir + '\\' + $fileName + '.log'

# Transcription file
[string]$transcriptPath = $CurrentDir + '\\' + $fileName + 'Transcript.txt'
Start-Transcript -Path $transcriptPath -Force -Append -NoClobber

#===================================
function Send-Email {
    Write-Output ">>> Email"
	$encodingMail = [System.Text.Encoding]::UTF8
	$Username = "drogovic@prologue.fr"
	$Password = ""
	$Priority = "High"
	$From = "userfrom <drogovic@prologue.fr>"
	$To = "userto <drogovic@prologue.fr>"
	$Cc = "drogovic@prologue.fr"
	$Attachment = "C:\\logo.png"
	$Subject = "Email Subject"
	$Body = "Insert body text here"
	$SMTPServer = "smtp.prologue.fr"
	$SMTPPort = "587"
	Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body `
	-SmtpServer $SMTPServer -port $SMTPPort -Attachments $Attachment `
	#-Credential ($Username, $Password) -Priority $Priority
	#-dno "onSuccess, onFailure"
}
# WritetoLog
function Write-toLog {
	[cmdletbinding()]
	param (
		[Parameter(Mandatory=$true)][string]$logMessage
	) 
	$date = Get-Date
	$logMessage2 = "> " + $date + " : User : " + $CurrentUser + " : Action : " + $logMessage
	Add-Content $logfile $logMessage2
	Write-Output $logMessage2
}

# Install function
function Install-GitFile {
	[cmdletbinding()]
	param (
		[Parameter(Mandatory=$true)][string]$installFile,
		[Parameter(Mandatory=$false)][string[]]$argList
	) 
	$logmess = "install: $installFile : args : $argList"
	Write-toLog -logMessage $logmess
	if ($argList){
		icm $executioncontext.InvokeCommand.NewScriptBlock((New-Object Net.WebClient).DownloadString($installFile)) -ArgumentList $argList
	}
	else {
		icm $executioncontext.InvokeCommand.NewScriptBlock((New-Object Net.WebClient).DownloadString($installFile)) 
	}
	#wait 2 seconds 
	Start-Sleep -m 2000
}

#===================================
Write-toLog -logMessage "start execution $fileName"

try {
	# install chocolatey
	$myfile=$Depot + "chocoInstall.ps1"
	#Install-GitFile -installFile $myfile

	# install 1
	$myfile = $Depot + "newDirectory.ps1"
	$targList = @("c:\azerty99","c:\test99")
	install-GitFile -installFile $myfile -argList $targList

	# install 2
	Write-toLog -logMessage "choco install vlc -y"
	#Invoke-Expression("choco install vlc -y --force")

	# install 3
	Write-toLog -logMessage "choco install tomcat -y"
	#Invoke-Expression("choco install tomcat -y")

	# install 4
	Write-toLog -logMessage "calc"
	Invoke-Expression("calc")

	#===================================
	# Exit
	Write-toLog -logMessage "end execution $fileName"
	stop-transcript
}
catch {
  Write-Output "EXCEPTION : "
  $ErrorMessage = $_.Exception.Message
  $FailedItem = $_.Exception.ItemName
  Write-toLog -logMessage $ErrorMessage
  #Send-Email
  stop-transcript
  Throw $_.Exception
}
######Restart-Computer

# Errors
#cls
#$error[0] | fl -force