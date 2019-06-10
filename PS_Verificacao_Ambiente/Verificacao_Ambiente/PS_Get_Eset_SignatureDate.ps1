# --------------------------------------------------------------------------
# OBTENDO VERSAO DO ANTIVIRUS (ATUALIZADO?)
# --------------------------------------------------------------------------
# Consulta o status do ESET Antivírus através do registro do windows.
# Quando as definições de vírus são atualizadas, a data das atualizações é lançada no registro.


Function Get-EsetSignatureDate{

	Param(
		[Parameter(Mandatory=$True)] [string[]] $servers
	)




	$AV_Versions = @()
	$failed = $False

	$remote_get_av_info = {
		# Caminho do eset no registro
		$key = "hklm:\software\eset\eset security\currentversion\info"
		
		# Lendo as registros
		$Atualizacao  = (Get-ItemProperty -Path $key -Name ScannerVersion).ScannerVersion
		$Antivirus      = (Get-ItemProperty -Path $key -Name ProductName).ProductName
		$Versao    = (Get-ItemProperty -Path $key -Name ProductVersion).ProductVersion 
		
		# Retornando o custom objeto com as informações compiladas.
		New-Object PSObject -Property @{Servidor=$env:computername; Antivirus=$Antivirus; Versao=$Versao; Atualizacao=$Atualizacao}
	}

	ForEach($server in $servers)
	{
		try{
			# Conectando remoto no servidor
			$remote_session = New-PSSession -Computername $server
			
			# Alimentando a lista de informações de AV.
			$result = Invoke-Command -Session $remote_session -ScriptBlock $remote_get_av_info
			$AV_Versions += [PSCustomObject] @{Servidor=$result.Servidor; Antivirus=$result.Antivirus; Versao=$result.Versao; Atualizacao=$result.Atualizacao}
			Remove-PSSession $remote_session
			
		}catch{
			Write-Host $_.Exception.Message
			Remove-PSSession $remote_session
			$failed = $True
		}
		
		
	}
	
	If($failed)
	{
		$Result = "FAIL"
	}else{
		$Result = "PASS"
	}
	
	Return New-Object PSObject -Property @{
		Result=$Result;
		AV_Versions=$AV_Versions
	}
	
}