# --------------------------------------------------------------------------
# Script para verificar a velocidade de internet (Ping, Download e Upload)
# --------------------------------------------------------------------------


Function Verifica-Internet{
	Param(
		[Parameter(Mandatory=$True)] [int32] $ExpectedPing,
		[Parameter(Mandatory=$True)] [int32] $ExpectedDownload,
		[Parameter(Mandatory=$True)] [int32] $ExpectedUpload
	)
	
	Write-Host "debug Expected Ping " $ExpectedPing " Download " $ExpectedDownload " Upload " $ExpectedUpload 
	
	# Pasta onde o mozilla está instalado.
	$Mozilla_Home = "C:\Program Files\Mozilla Firefox"

	# Adicionando a .dll do Selenium e incluindo o caminho do mozilla no path.
	Add-Type -Path "$ScriptPath\WebDriver.dll"
	$env:path += ";$ScriptPath"
	$env:path += ";$Mozilla_Home"
	 
	# Instanciando o objeto Selenium Firefox
	$ff = New-Object "OpenQA.Selenium.Firefox.FirefoxDriver"

	# acessando site da Vivo.
	$ff.Navigate().GoToUrl("http://vivo.speedtestcustom.com")

	# Encontrando o botao iniciar teste.
	$btnStart = $ff.FindElementByTagName("button")
	$btnStart.Click()

	# Aguardando tempo medio para medicao de download e upload #
	Start-Sleep 40

	# Obtendo Resultado: Ping
	$inet_ping = [int32]$ff.FindElementsByClassName("number")[0].text
	Write-Host "debug ping: " $inet_ping

	# Obtendo Resultado: Download
	$inet_download = [double]::Parse($ff.FindElementsByClassName("number")[2].text)
	Write-Host "debug download: " $inet_download

	# Obtendo Resultado: Upload
	$inet_upload = [double]::Parse($ff.FindElementsByClassName("number")[3].text)
	Write-Host "debug upload: " $inet_upload

	# Avaliando se a velocidade esta satisfatoria
	If( ($inet_ping -lt $ExpectedPing) -and ($inet_download -gt $ExpectedDownload) -and ($inet_upload -gt $ExpectedUpload) )
	{
		$Result = "PASS"
	}else{
		$Result = "FAIL"
	}
	
	# Cleanly close firefox
	$ff.Quit()
	
	# Retornando o resultado:
	Return New-Object PSObject -Property @{Result=$Result; Ping=$inet_ping; Download=$inet_download; Upload=$inet_upload}

}

