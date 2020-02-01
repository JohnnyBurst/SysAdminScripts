<#
.SYNOPSIS
    This script checks and installs pending windows updates.

.DESCRIPTION
	This script checks if there is available windows updates and proceed to install.
	If necessary, the script will automatically reboot the computer after installation (for patches that
	require reboot).
	


.EXAMPLE
    .\PS_Install_WindowsUpdates.ps1 


.NOTES
    Copyright (C) 2020  luciano.grodrigues@live.com

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

#>


# Detecting current folder in which the scripting is executing
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path 

# Logfile
$LogFile = "$ScriptPath\Auto_Windows_Update_{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HH_mm')

# Search Criteria: Lookup for updates that's only software (no driver updates) and has not been hidden.
$SearchCriteria = "IsInstalled=0 And Type='Software' And IsHidden=0"



# Logging function with timestamp
Function Log()
{
	Param([string]$text)
	
	$date = Get-Date -Format 'yyyy/MM/dd HH:mm'
	Add-Content -Path $LogFile -Value "$($date): $($text)"
	Write-Host "$($date): $($text)"
}

# Logging function w/o timestamp
Function RawLog()
{
	Param([string]$text)
	
	Add-Content -Path $LogFile -Value $text
	Write-Host $text
}



# Writing the banner to log file
$computerinfo = Get-WMIObject Win32_ComputerSystem
$osinfo = Get-WMIObject Win32_OperatingSystem
Log("# -----------------------------------------------------------------------------------#")
Log("                                 WINDOWS UPDATE SCRIPT                                ")
Log("# -----------------------------------------------------------------------------------#")
Log("Starting At: " + (Get-Date -Format 'yyyy/MM/dd HH:ss'))
Log("Hostname: " + $computerinfo.Name)
Log("System: " + $osinfo.Caption)
Log("Domain: " + $computerinfo.Domain)
Log("Running as user: " + $env:username)
Log("`r`n")



# -----------------------------------------------------------------------------------
#                  MAIN SCRIPT ROUTINES
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# How this magic works:
# 1. Create a session object
# 2. From session object, create a update searcher object
# 3. Ask searcher object to search for updates with especified criteria.
# 4. If no updates found then exit, otherwise...
# 5. Create a update collection object
# 6. Add updates found on searcher object to and update collection object
# 7. Create a updates downloader object
# 8. Tell the downloader, the collection of updates that must be downloaded
# 9. Download the updates
# 10. Create a new update collection
# 11. Associate the downloaded updated to the newly update collection
# 12. From the session object, create an Installer object and tell it which collection 
# of donwloaded updates to install.
# 13. Ask the Installer object to 'install' updates.
# 14. Check exit code.
# 15. Does it need to reboot? Then reboot!
# -----------------------------------------------------------------------------------


# info
Log("Starting the searching for updates")
Log("Using Criteria: $($SearchCriteria)")

# Session Object
try{
	$UpdateSession = New-Object -ComObject Microsoft.Update.Session
	$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
	$SearchResult = $UpdateSearcher.Search($SearchCriteria)
}catch{
	Log("Error starting the search for updates. See exception below.")
	RawLog($_.Exception)
	Exit
}


# Do we found new updates?
If($SearchResult.Updates.Count -gt 0)
{
	Log("Found $($SearchResult.Updates.Count) updates to install. See below details.")
	
	# Which updates was it?
	ForEach($updt in $SearchResult.Updates)
	{
		RawLog("Update: $($updt.Title).")
	}
}Else{
	Log("No new updates found. Terminating the script...")
	Exit
}




# -----------------------------------------------------------------------------------
# Downloading the updates
# -----------------------------------------------------------------------------------
Log("Downloading updates...")
$UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
ForEach($update in $SearchResult.Updates)
{
	[void] $UpdatesToInstall.Add($update)
}

$UpdateDownloader = $UpdateSession.CreateUpdateDownloader()
$UpdateDownloader.Updates = $UpdatesToInstall
$DownloadResult = $UpdateDownloader.Download()

# Error during download?
If($DownloadResult.HResult -ne 0)
{
	Log("An error ocurred during updates download. Check it manually.")
	Exit
}



# Installing the updates...
Log("Updates downloaded. Ready to start installing it.")
$UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
ForEach($update in $UpdateDownloader.Updates)
{
	If($update.IsDownloaded){ $UpdatesToInstall.Add($update)}
}

Log("Total updates downloaded: $($UpdatesToInstall.Count)")

$UpdateInstaller = $UpdateSession.CreateUpdateInstaller()
$UpdateInstaller.Updates = $UpdatesToInstall
try{
	$InstallResult = $UpdateInstaller.Install()
}catch{
	Log("An error ocurred during updates install. See details below.")
	RawLog($_.Exception)
	Exit
}


# Errors during install?
if($InstallResult.HResult -ne 0)
{
	Log("An error ocurred during updates install. Check it manually.")
	Exit
}Else{
	Log("All updates installed successfully.")
}

If($InstallResult.RebootRequired)
{
	Log("Reboot required... Proceeding!")
	Restart-Computer -Force
}Else{
	Log("No reboots required.")
	Log("Terminating the script with success.")
	Exit
}

