# Powershell script to execute scripts through UiCB agent
# Hamid MEDJAHED (c) for prologue 2015 

Param(
	[string]$path,
	[string]$argsList,
	[string]$arch,
	[int]$timeout = 900,
	[int]$keepaftertimeout = 0
	
)

Set-ExecutionPolicy Unrestricted
$fileDir = Split-Path $path
$fileNamec = Split-Path $path -Leaf
$fileName = $fileNamec.split(".")[0]
$CurrentDir = $(get-location).Path
if($fileDir)
{
	$CurrentDir = $fileDir
}
# Log file
$log = $CurrentDir + '\\' + $fileName + '.log'
# Transcription file
$transcriptpath = $CurrentDir + '\\' + $fileName + 'Transcript.txt'
# Create empty stamp file for script return code.
$stamp = $CurrentDir + '\\' + $fileName + ".XXX.stamp"
$transcriptpath
Start-Transcript -Path $transcriptpath -Force

$tolog = "keepaftertimeout: " + $keepaftertimeout
Add-Content $log $tolog

$tolog = "timeout: " + $timeout
Add-Content $log $tolog

# Return codes.
$RC_KILLED=124         # Timeout expired, the Script was killed.
$RC_ABANDON=125        # Timeout expired, the Script continues to run.
$RC_INVALID_SYNTAX=126 # Call syntax error
$RC_PATH_NOT_FOUND=127 # Script Path not found # Script exit status otherwise


if (Test-Path $path) {
	Add-Content $log "The path to the the file to execute exist"
}
else {
	Add-Content $log "The path to the the file to execute not found"
	stop-transcript
	exit $RC_PATH_NOT_FOUND
}

$afterTimeout = $false
if ($keepaftertimeout -eq 1) {
	$afterTimeout = $true
}
elseif( $keepaftertimeout -eq 0) {
	$afterTimeout = $false
}
else {
	Add-Content $log "Invalid option keep-after-timeout"
	stop-transcript
	exit $RC_INVALID_SYNTAX
}


$CurrentDirB = $(get-location).Path

$tolog = "Working Directory: " + $CurrentDirB
Add-Content $log $tolog
$date = Get-Date
$tolog = "start execution: " + $date
Add-Content $log $tolog
$tolog = "Executor: " + $MyInvocation.MyCommand.Name
Add-Content $log $tolog
$tolog = "Script: " +  $CurrentDir + '\\' + $fileNamec + " " + $argsList
Add-Content $log $tolog
$tolog = "Timeout: " + $timeout
Add-Content $log $tolog
$tolog = "Keep after timeout : " + $keepaftertimeout
Add-Content $log $tolog

$pathexec = $CurrentDirB + "\\" + $CurrentDir + "\\" + $fileNamec + " " + $argsList + ' /quiet'
$tolog = "Start execut script: " + $pathexec
Add-Content $log $tolog

if ($arch -eq "x86")
{
	$tolog = "changing from 64bit to 32bit powershell"
	Add-Content $log $tolog
	$powershell=Join-Path $PSHOME.tolower().replace("system32","syswow64") powershell.exe
}
elseif ($arch -eq "64")
{
	$tolog = "changing from 32bit to 64bit powershell"
	Add-Content $log $tolog
	$powershell=Join-Path $PSHOME.tolower().replace("syswow64","system32") powershell.exe
}
else
{
	$powershell="powershell.exe"
}

$tolog = "Powershell: " + $powershell
Add-Content $log $tolog

$ps = new-object System.Diagnostics.Process
$ps.StartInfo.Filename = $powershell
$ps.StartInfo.Arguments = $pathexec
$ps.StartInfo.RedirectStandardOutput = $True
$ps.StartInfo.UseShellExecute = $false
$ps.StartInfo.WorkingDirectory = $CurrentDir
$pStartTime = Get-Date
$ps.start()
$stopprocessing = $false
do{
	$hasExited = $ps.HasExited
	
	#check if there is still a record of the process
	Try { $proc = get-process -id $ps.Id -ErrorAction stop }
	Catch { $proc = $null }
	
	#sleep a bit
	start-sleep -seconds .5
	#check if we have timed out, unless the process has exited
	if( ( (Get-Date) - $pStartTime ).totalseconds -gt $timeout -and -not $hasExited -and $proc)
	{
		if ($afterTimeout) 
		{
			Add-Content $log "Timeout expired, script is in progress."
			exit ${RC_TIMEOUT_EXPIRED}
		}
		else
		{
			$stopprocessing = $true
			$tolog = "Timeout expired: script execution tooks longer than " + $timeout + " seconds to execute"
			Add-Content $log $tolog
			$ps.kill()
			Add-Content $log "Kill after timeout"
		}
	}
}
until($hasExited  -or $stopProcessing -or -not $proc)

[string] $Output = $ps.StandardOutput.ReadToEnd();
Add-Content $stamp $Output
$date = Get-Date
$tolog = "Exit from executor: " + $date
Add-Content $log $tolog
stop-transcript

