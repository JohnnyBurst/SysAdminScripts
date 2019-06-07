# ---------------------------------------------------------------------------------------------------------------------------
# Script para remover arquivos de determinada extensao (.combo)
# Autor: via3lr - luciano.rodrigues@v3c.com.br
# Usage: Invoque o script (como Administrador) passando as extensoes dos arquivos entre aspas, como no exemplo abaixo:
#        .\PS_Remove_Encrypted_Files.ps1 "*.combo" "*.darkcrypt" "*.uranium"
# ---------------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------
# Os parametros obrigatórios são uma lista de strings com a extensão a ser procurada.
# Veja a descrição e exemplo acima do script.
# ---------------------------------------------------------------------------------------------------
# Validando a quantidade de argumentos
f($args.count -lt 1)
{
	Write-Host -ForegroundColor RED "ERRO: Voce deve fornecer ao menos uma extensao de arquivo para procurar."
	Write-Host @"
Exemplo:
.\$($MyInvocation.MyCommand.Name) "*.extensao1" "*.extensao2" "*.extensao3"	
"@
	Exit
}

# Organizando os argumentos e validando a syntaxe.
# As extensões devem estar no formato "*.extensao1"
$lookupfiles = @()
ForEach($arg in $args) { 
	If([regex]::match($arg, "\*\.\w+").Success)
	{
		$lookupfiles += $arg 
	}else{
		Write-Host -ForegroundColor RED "Erro ao interpretar extensao $arg"
		Write-Host -ForegroundColor YELLOW "O formato da extensao deve ser: `"*.extensao`""
		Exit
	}
}


# Arquivo de Log
$LogFile = "$env:userprofile\documents\PS_Remove_Encrypted_Files.txt"



# -----------------------------------------------------------------------------------
# !!!@ NÃO MODIFICAR DESTA LINHA PARA BAIXO... @!!!
# -----------------------------------------------------------------------------------

# Default Error Action: Don't stop even if we got a access denied.
$ErrorActionPreference = "SilentlyContinue"


# Criando a função de logging
Function Log()
{
	Param([string]$text)
	
	$date = Get-Date -Format 'yyyy/MM/dd HH:mm'
	Write-host "$($date): $($text)"
	Add-Content -Path $LogFile -Value "$($date): $($text)"
}
Function RawLog()
{
	Param([string]$text)
	Write-host $text
	Add-Content -Path $LogFile -Value $text
}

# Banner
RawLog("#----------------------------------------------------------------------------#")
RawLog("#            VIA3 CONSULTING - CONSULTORIA EM GESTAO E TI                    #")
RawLog("#----------------------------------------------------------------------------#")
Log("Iniciando o script de remoção de arquivos criptografados.")


# Obtendo as partições de disco disponíveis/acessíveis.
$AvailableDrives = Get-PSDrive -PSProvider FileSystem | Select -ExpandProperty Root
Log("Particoes encontradas: $($AvailableDrives.split(''))")

# Percorrendo cada particao encontrada em busca dos arquivos.
ForEach($drive in $AvailableDrives)
{
	# Validando o acesso ao drive (dvd rom inacessível?)
	IF(-Not (Test-Path $drive))
	{
		Log("Erro ao acessar o Drive $drive . Pulando para o proximo...")
		Continue
	}

	Log("Iniciando busca na unidade $drive por arquivos $($lookupfiles.split(''))")
	Get-ChildItem -Path $drive -Force -Recurse -Include $lookupfiles | ForEach-Object{
		Log("Removendo o arquivo $($_.FullName)");
		Start-Process cmd.exe -ArgumentList "/c del /q /s /a `"$($_.FullName)`"" -NoNewWindow -Wait
	}
}




