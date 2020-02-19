<#

.SYNOPSIS
    This script checks a remote computer for pending windows updates.

.DESCRIPTION
	This script checks a remote computer for pending windows updates.
	More than one computer can be checked, just separate them with a comma (see example below).
	Note1: If more than one computer is checked, the whole process is run in parallel to speedup things.
	Note2: Timeout to connecting to computers defaults to 10 seconds.

.EXAMPLE
    .\PS_Remote_Check_WindowsUpdates.ps1 -Computer server1,server2,server3


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

Param(
	[Parameter(Mandatory=$True)] [String[]] $computers
)


$block_check_updates = {
	$SearchCriteria = "IsInstalled=0 And Type='Software' And IsHidden=0"
	$UpdateSession = New-Object -ComObject Microsoft.Update.Session
	$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
	$SearchResult = $UpdateSearcher.Search($SearchCriteria)

	#New-Object PSObject -Property @{Servidor=$env:computername; AtualizacoesDisponiveis=$SearchResult.Updates.Count}
	Return $env:computername + "`t" + $SearchResult.Updates.Count
}

$ErrorActionPreference = "Stop"
Write-Host -ForegroundColor Yellow "Searching for updates"
Write-Host "Server`t`tUpdates"

$TimeOut = New-PSSessionOption -OpenTimeout 10000
Invoke-Command -ComputerName $computers -ScriptBlock $block_check_updates -SessionOption $TimeOut
