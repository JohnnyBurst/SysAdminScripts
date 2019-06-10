# --------------------------------------------------------------------------
# Verificando Computadores no inventario
# --------------------------------------------------------------------------

Function Get-OldOCSInventoryPCS
{

	Param(
		[Parameter(Mandatory=$True)] [string]$ocs_url,
		[Parameter(Mandatory=$True)] [string]$ocs_admin_user,
		[Parameter(Mandatory=$True)] [string]$ocs_admin_pass,
		[Parameter(Mandatory=$True)] [string]$ocs_cliente_tag
	)


	# Pasta onde o mozilla estรก instalado.
	$Mozilla_Home = "C:\Program Files (x86)\Mozilla Firefox"
	
	# pagina de visualização de computadores do ocs
	$ocs_page_visu_computers = [string]::Concat($ocs_url, "/?function=visu_computers")

	# Adicionando a .dll do Selenium e incluindo o caminho do mozilla no path.
	Add-Type -Path "$ScriptPath\WebDriver.dll"
	$env:path += ";$ScriptPath"
	$env:path += ";$Mozilla_Home"
	 
	# Instanciando o objeto Selenium Firefox
	$ff = New-Object "OpenQA.Selenium.Firefox.FirefoxDriver"

	$ff.Navigate().GoToUrl($ocs_url)

	# Preenchendo usuario e senha.
	$inputLogin = $ff.FindElementById("LOGIN")
	$inputLogin.SendKeys($ocs_admin_user)
	$inputPasswd = $ff.FindElementById("PASSWD")
	$inputPasswd.SendKeys($ocs_admin_pass)

	$subBtn = $ff.FindElementsByName("Valid_CNX").Click()
	Start-Sleep 3

	# Navegando ate a visualização de todos os computadores
	$ff.Navigate().GoToUrl($ocs_page_visu_computers)

	# Mudando a qtde de computadores da visualização para 100 (maximo)
	$ff.FindElementByName("list_show_all_length").sendkeys("500")
	Start-Sleep 3

	# Procurando apenas computadores da integratio
	$ff.FindElementsByClassName("input-sm")[1].SendKeys($ocs_cliente_tag)
	Start-Sleep 5

	$odds = $ff.FindElementsByClassName("odd")
	$evens = $ff.FindElementsByClassName("even")

	$pc_inventory = @()

	ForEach($odd in $odds)
	{
		$computername = $odd.FindElementByClassName("name").Text
		$lastcheck = $odd.FindElementByClassName("lastdate").Text
		$pc_inventory += New-Object PSObject -Property @{Computername=$computername; Lastcheck=$lastcheck}
	}

	ForEach($even in $evens)
	{
		$computername = $even.FindElementByClassName("name").Text
		$lastcheck = $even.FindElementByClassName("lastdate").Text
		$pc_inventory += New-Object PSObject -Property @{Computername=$computername; Lastcheck=$lastcheck}
	}
	
	# Quitting firefox cleanly
	$ff.Quit()

	# Selecionando apenas os computadores com mais de 30 dias sem inventariar
	$inventory_computers = ($pc_inventory | ?{(Get-Date -date $_.LastCheck) -lt (Get-Date).AddDays(-30)} )
	
	If($inventory_computers.count -gt 0)
	{
		$Result = "FAIL"
	}else{
		$Result = "PASS"
	}
	
	Return New-Object PSObject -Property @{
		Result=$Result;
		Inventory=$inventory_computers
	}


}