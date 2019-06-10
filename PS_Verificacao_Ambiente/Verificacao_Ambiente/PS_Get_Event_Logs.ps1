# --------------------------------------------------------------------------
# OBTENDO EVENTOS DO WINDOWS
# --------------------------------------------------------------------------


Function Get-LogEvents{

	Param(
		[Parameter(Mandatory=$True)][string[]] $servers
	)

	$ontem = (Get-Date).AddDays(-1)


	$logs = @("Application","System")
	$events = @()

	ForEach($server in $servers)
	{
		Write-Host "Iniciando coleta de logs para o servidor " -NoNewline
		Write-Host -ForegroundColor Yellow $server
		ForEach($log in $logs)
		{
			try{
				# Obtendo eventos Criticos
				$ErrorActionPreference = "SilentlyContinue"
				Get-WinEvent -FilterHashTable @{LogName=$log; StartTime=$ontem; Level=1} -Computername $server | 
					ForEach-Object {
						$events += [PSCustomObject]@{Server=$server;Logname=$_.LogName;TimeCreated=$_.TimeCreated;LevelDisplayName=$_.LevelDisplayName;Message=$_.Message}
					}
				
				# Obtendo eventos Error
				Get-WinEvent -FilterHashTable @{LogName=$log; StartTime=$ontem; Level=2} -Computername $server | 
					ForEach-Object {
						$events += [PSCustomObject]@{Server=$server;Logname=$_.LogName;TimeCreated=$_.TimeCreated;LevelDisplayName=$_.LevelDisplayName;Message=$_.Message}
					}
					
			}catch{
				Write-Host "Erro ao conectar no servidor. "
				Write-Host -ForegroundColor Red $_.Exception.Message
				#Return New-Object PSObject -Property @{Result="FAIL";Events=$null}
			}
		}
	}

	If($events.count -gt 0)
	{
		$Result = "FAIL"
	}else{
		$Result = "PASS"
	}

	Return New-Object PSObject -Property @{
		Result=$Result;
		Events=$events
	}
	
}