# --------------------------------------------------------------------------
# Script para verificar os logs do Dell OMSA. 
# --------------------------------------------------------------------------


Function Verifica-OMSA{
	Param(
		[Parameter(Mandatory=$True)][string]$omsauser,
		[Parameter(Mandatory=$True)][string]$omsapass,
		[Parameter(Mandatory=$True)][object[]] $servers
	)
	
	
	# Debug input information
	foreach($server in $servers)
	{
		Write-Host "Server: $($server.Server)`t OMSA: $($server.OMSAVersion)"
	}
	
	
	$ScriptPath = "C:\scripts\Verificacao_Ambiente"
	$Mozilla_Home = "C:\Program Files\Mozilla Firefox"
	
	
	
	# Adicionando a .dll do Selenium e incluindo o caminho do mozilla no path.
	Add-Type -Path "$ScriptPath\WebDriver.dll"
	$env:path += ";$ScriptPath"
	$env:path += ";$Mozilla_Home"
		 
	$results = @()
	
	# Iterando nos servidores
	ForEach($server in $servers)
	{
		$server_name = $server.Server
		$omsa_url = "https://$server_name`:1311"
		$omsa_version = $server.OMSAVersion
		
		# Instanciando o objeto Selenium Firefox
		$options = New-Object OpenQA.Selenium.Firefox.FirefoxOptions
		$options.AcceptInsecureCertificates = $true
		$options.LogLevel = "Fatal"
		$options.AddArgument("-headless")
		$ff = New-Object OpenQA.Selenium.Firefox.FirefoxDriver($options) 

		# acessando Dell OMSA auth page
		$ff.Navigate().GoToUrl($omsa_url)
		start-sleep 3
		$ff.SwitchTo().Frame($ff.FindElementsByTagName('frame')[0])  | out-null
		$ff.FindElementsByName("user").SendKeys($omsauser)
		$ff.FindElementsByName("password").SendKeys($omsapass)
		if($omsa_version -eq 6){ $ff.FindElementsByName("domain").SendKeys("BRANDT") }
		$ff.FindElementByID("login_submit").Click()
		start-sleep 3

		# Navegando entre os frames até achar o link de logs.
		$ff.SwitchTo().DefaultContent() | out-null
		$ff.SwitchTo().Frame(2)  | out-null
		start-sleep 2
		$ff.SwitchTo().Frame(2)  | out-null
		start-sleep 2

		# clicando no link de logs
		$ff.FindElementById("anchor_3").click()
		start-sleep 3


		# OMSA Version Specifics
		if($omsa_version -eq 9 -or $omsa_version -eq 6)
		{
			# navegando para o frame com o link de alertas(dentro de logs)
			$ff.SwitchTo().DefaultContent()  | out-null
			$ff.SwitchTo().Frame(2)  | out-null
			$ff.SwitchTo().Frame(3)  | out-null

			# clicando no link alertas.
			$ff.FindElementById("link_2").click()
			start-sleep 3
		}elseif($server.OMSAVersion -eq 8)
		{
			# not needed any further step at this time...
		}
		
		


		$ff.SwitchTo().DefaultContent()  | out-null
		$screenshot = "$ScriptPath\screenshots\omsa_$server_name.jpg"
		$ff.GetScreenshot().saveasfile($screenshot)
		$ff.quit()
		
		$results += New-Object PSObject -Property @{Server=$server_name; Screenshot=$screenshot}
		
	}
	# Retornando o resultado:
	Return $results

}

