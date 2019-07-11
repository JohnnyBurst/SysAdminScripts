# -----------------------------------------------------------------------------------
# Script para download e instalação das atualizações do windows - automatico
# autor: luciano.grodrigues@live.com
# -----------------------------------------------------------------------------------


# -----------------------------------------------------------------------------------
# VARIAVEIS AJUSTAVEIS
# -----------------------------------------------------------------------------------
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path 

# Arquivo de log
$LogFile = "$ScriptPath\Auto_Windows_Update_{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HH_mm')

#Procurar por atualizações ainda não instaladas, apenas software (nao drives) e que não estejam marcadas como ocultas.
$SearchCriteria = "IsInstalled=0 And Type='Software' And IsHidden=0"




# -----------------------------------------------------------------------------------
# NÃO MODIFICAR DESTA LINHA PARA BAIXO...
# -----------------------------------------------------------------------------------

# Criando o objeto de logging
Function Log()
{
	Param([string]$text)
	
	$date = Get-Date -Format 'yyyy/MM/dd HH:mm'
	Add-Content -Path $LogFile -Value "$($date): $($text)"
	Write-Host "$($date): $($text)"
}
Function RawLog()
{
	Param([string]$text)
	
	Add-Content -Path $LogFile -Value $text
	Write-Host $text
}

# Banner
RawLog("#----------------------------------------------------------------------------#")
RawLog("#            VIA3 CONSULTING - CONSULTORIA EM GESTAO E TI                    #")
RawLog("#----------------------------------------------------------------------------#")
Log("Iniciando o script de atualizações automáticas")

# Objeto de sessao
$UpdateSession = New-Object -ComObject Microsoft.Update.Session

# -----------------------------------------------------------------------------------
# Procurando por atualizações
# -----------------------------------------------------------------------------------
Log("Iniciando busca por atualizações.")
Log("Criterio de pesquisa: $($SearchCriteria)")
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$SearchResult = $UpdateSearcher.Search($SearchCriteria)

# Atualizações encontradas?
If($SearchResult.Updates.Count -gt 0)
{
	Log("Total de Atualizações encontradas: $($SearchResult.Updates.Count).")
	
	# Mostrar quais atualizacoes foram encontradas
	ForEach($updt in $SearchResult.Updates)
	{
		RawLog("Atualizaçao: $($updt.Title).")
	}
}Else{
	Log("Nenhuma nova atualização encontrada... Terminando o script.")
	Exit
}




# -----------------------------------------------------------------------------------
# Baixando as atualizações
# -----------------------------------------------------------------------------------
Log("Baixando as atualizações.")
$UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
ForEach($update in $SearchResult.Updates)
{
	[void] $UpdatesToInstall.Add($update)
}

$UpdateDownloader = $UpdateSession.CreateUpdateDownloader()
$UpdateDownloader.Updates = $UpdatesToInstall
$DownloadResult = $UpdateDownloader.Download()

# Erros durante o download?
If($DownloadResult.HResult -ne 0)
{
	Log("Houveram erros durante o download das atualizações. Verifique manualmente.")
	Log("Erro fatal durante o download das atualizações... Encerrando o script.")
	Exit
}


# -----------------------------------------------------------------------------------
# Instalando as atualizações
# -----------------------------------------------------------------------------------
Log("Iniciando instalação das atualizações.")
$UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
ForEach($update in $UpdateDownloader.Updates)
{
	If($update.IsDownloaded){ $UpdatesToInstall.Add($update)}
}

Log("Total de atualizações baixadas: $($UpdatesToInstall.Count)")

$UpdateInstaller = $UpdateSession.CreateUpdateInstaller()
$UpdateInstaller.Updates = $UpdatesToInstall
$InstallResult = $UpdateInstaller.Install()

if($InstallResult.HResult -ne 0)
{
	Log("Houveram erros durante a instalação das atualizações. Revise manualmente.")
	Exit
}Else{
	Log("As atualizações foram instaladas com sucesso.")
}

If($InstallResult.RebootRequired)
{
	Log("Reinicialização pendente... reiniciando...")
	Restart-Computer -Force
}Else{
	Log("Não é necessária reinicialização do servidor...")
	Log("Atualização terminada com sucesso.")
	Exit
}

