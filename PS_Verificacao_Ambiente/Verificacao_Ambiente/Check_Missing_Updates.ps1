# -----------------------------------------------------------------------------------
# Script para download e instalação das atualizações do windows - automatico
# autor: luciano.grodrigues@live.com
# -----------------------------------------------------------------------------------

Param(
	[Parameter(Mandatory=$True)] [String[]] $servers
)


$block_check_updates = {
	$SearchCriteria = "IsInstalled=0 And Type='Software' And IsHidden=0"
	$UpdateSession = New-Object -ComObject Microsoft.Update.Session
	$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
	$SearchResult = $UpdateSearcher.Search($SearchCriteria)

	New-Object PSObject -Property @{Servidor=$env:computername; AtualizacoesDisponiveis=$SearchResult.Updates.Count}
}

$ErrorActionPreference = "Stop"
try{
	$session = New-PSSession -Computername $servers
	$Updates = Invoke-Command -Session $session -ScriptBlock $block_check_updates
	Remove-PSSession $session
	$Updates | Select-Object -Property Servidor,AtualizacoesDisponiveis
}catch{
	$_.Exception.Message
	Remove-PSSession $session
}