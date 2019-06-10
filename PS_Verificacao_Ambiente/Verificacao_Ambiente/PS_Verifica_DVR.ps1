# --------------------------------------------------------------------------
# Script para verificar cameras DVR
# --------------------------------------------------------------------------
# !!! IMPORTANTE
# É necessário desabilitar o modo protegido do IE para todas as zonas...
# também é necessário setar o registro abaixo:
<#
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BFCACHE]
"iexplore.exe"=dword:00000000
#>


$ScriptPath = "C:\scripts\Verificacao_Ambiente"
add-type -path "$ScriptPath\webdriver.dll"
add-type -path "$ScriptPath\WebDriver.Support.dll"
add-type -path "$ScriptPath\Selenium.WebDriverBackedSelenium.dll"

$ieopt = New-Object OpenQA.Selenium.ie.InternetExplorerOptions
$ieopt.InitialBrowserUrl = "about:blank"
$ieopt.RequireWindowFocus = $False

$ie = New-Object OpenQA.Selenium.ie.InternetExplorerDriver($ieopt)

$ie.Navigate().GoToURL("http://10.2.8.11")
start-sleep 3
# limpando usuario caso tenha salvo digitado...
while($ie.FindElementById("username").getProperty("value") -ne "")
{
	$ie.FindElementById("username").SendKeys([OpenQA.Selenium.Keys]::Backspace)
}
$ie.FindElementById("username").SendKeys("admin")
$ie.FindElementById("password").SendKeys("bma123")
$ie.FindElementById("loginBT").Click()
start-sleep 5

$pictures_path = "C:\Program Files (x86)\NetSurveillance\Pictures"
# removendo snaps se tiver algum na pasta de snaps
get-childitem -path $pictures_path | remove-item

# tirando os prints e movendo para a pasta de screenshots
0..15 | %{
	$camnum = [int32]$_
	$snap = "camera_$($camnum+1).bmp"
	$ie.FindElementById("c$camnum").click()
	start-sleep 3
	$ie.FindElementById("snap").click()
	start-sleep 3
	get-childitem -path $pictures_path | %{rename-item -path $_.fullname -newname $snap }
	Move-Item -Path (join-path $pictures_path $snap) -Destination "$scriptpath\screenshots"
	get-childitem -path $pictures_path | remove-item
}

$ie.Quit()
$ie.Dispose()
