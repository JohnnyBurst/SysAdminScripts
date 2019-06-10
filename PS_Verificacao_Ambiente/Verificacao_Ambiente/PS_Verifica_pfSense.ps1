# --------------------------------------------------------------------------
# Script para verificar a velocidade de internet (Ping, Download e Upload)
# --------------------------------------------------------------------------


Function Verifica-pfSense{
	Param(
		[Parameter(Mandatory=$True)] [string] $pfSenseURL,
		[Parameter(Mandatory=$True)] [string] $pfSenseAdminUser,
		[Parameter(Mandatory=$True)] [string] $pfSenseAdminPass
	)
	
	# Pasta onde o mozilla está instalado.
	$Mozilla_Home = "C:\Program Files\Mozilla Firefox"
	
	#
	$gateways_page = [string]::Concat($pfSenseURL,"/status_gateways.php")

	# Adicionando a .dll do Selenium e incluindo o caminho do mozilla no path.
	Add-Type -Path "$ScriptPath\WebDriver.dll"
	$env:path += ";$ScriptPath"
	$env:path += ";$Mozilla_Home"
	 
	# Instanciando o objeto Selenium Firefox
	$ff = New-Object "OpenQA.Selenium.Firefox.FirefoxDriver"

	# acessando webconfig do pfsense.
	$ff.Navigate().GoToUrl($pfSenseURL)

	# Realizando autenticação.
	$ff.FindElementById("usernamefld").SendKeys($pfSenseAdminUser)
	$ff.FindElementById("passwordfld").SendKeys($pfSenseAdminPass)
	$ff.FindElementByName("login").Click()
	
	# Navegando ate a pagina de gateways
	$pf_gateways = @()
	$ff.Navigate().GoToUrl($gateways_page)
	
	# Name Gateway Monitor RTT RTTsd Loss Status Description
	$trs = $ff.FindElementsByXPath("//table/tbody/tr")

	# Preenchendo o array com objetos contendo propriedades dos gateways.
	ForEach($tr in $trs)
	{
		$tds = $tr.FindElementsByTagName("td")
		$pf_gateways += New-Object PSObject -Property @{
			Name=$tds[0].Text; 
			Gateway=$tds[1].Text; 
			Monitor=$tds[2].Text;
			RTT = $tds[3].Text;
			RTTsd=$tds[4].Text;
			Loss=$tds[5].Text;
			Status=$tds[6].Text;
			Description=$tds[7].Text
		}
		
	}



	# Avaliando se Algum Gateway esta offline
	$offline = $False
	ForEach($gw in $pf_gateways)
	{
		if($gw.Status -ne "Online")
		{
			$Result = "FAIL"
		}else{
			# if result already failed, do not overwrite with success..
			if($Result -ne "FAIL") { $Result = "PASS" }
			
		}
	}
	
	# Cleanly close firefox
	$ff.Quit()
	
	# Retornando o resultado:
	Return New-Object PSObject -Property @{Result=$Result; Gateways=$pf_gateways}

}

