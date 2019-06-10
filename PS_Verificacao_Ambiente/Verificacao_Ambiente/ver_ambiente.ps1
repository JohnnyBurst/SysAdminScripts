# -------------------------------------------------------------------------
# Script para executar a verificação de ambiente e enviar por e-mail
# author: luciano.rodrigues@v3c.com.br 03/05/2019
# -------------------------------------------------------------------------

#Region Global Variables
$Global:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Global:servers_get_logs = 		@("SERVER1", "SERVER2")
$Global:pfsense_url = ""
$Global:pfsense_adminuser = ""
$Global:pfsense_adminpass = ""
$Global:ocs_url = ""
$Global:ocs_admin_user = ""
$Global:ocs_admin_pass = ""
$Global:ocs_cliente_tag = ""
$Global:omsauser = ""
$Global:omsapass = ""
$Global:anexos = @()
#EndRegion




# -------------------------------------------------------------------------
# NÃO MODIFICAR DESTA LINHA PARA BAIXO
# -------------------------------------------------------------------------

# VERIFICAÇÃO DE VELOCIDADE DE INTERNET
. "$ScriptPath\PS_Verifica_Internet.ps1"
$Internet_Result = Verifica-Internet -ExpectedPing 40 -ExpectedDownload 100 -ExpectedUpload 9


# ---------------------  VERIFICAÇÃO DE GATEWAYS PFSENSE -----------------------------#
. "$ScriptPath\PS_Verifica_pfSense.ps1"
$pfsense_Result = Verifica-pfSense -pfSenseURL $pfsense_url -pfSenseAdminUser $pfsense_adminuser -pfSenseAdminPass $pfsense_adminpass



# --------------------------------------------------------------------------
# OBTENDO EVENTOS DO WINDOWS
# --------------------------------------------------------------------------
. "$ScriptPath\PS_Get_Event_Logs.ps1"
$Events_Result = Get-LogEvents -Servers $servers_get_logs



# --------------------------------------------------------------------------
# OBTENDO HORA DOS SERVIDORES
# --------------------------------------------------------------------------

$HorasServidores = @()
$servers = @()
$servers += [PSCustomObject] @{Servidor="BMABH05"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABH09"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABH11"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABH16"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABH18"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABHAPPL"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABHBD"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABHFS01"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABHFS02"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABHHOST07"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABHHOST1"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABHHOST2"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABHHOST3"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMABHHOST4"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="BMATVFW01"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="SRVUNION"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="TVBHHOST1"; Tipo="Windows"}
$servers += [PSCustomObject] @{Servidor="VIA301"; Tipo="Windows"}

# Exemplo Linux
#$servers += [PSCustomObject] @{Servidor="ITGBHHOST1"; Tipo="Linux"; Hostkey="29:22:f7:54:b3:1f:15:12:26:16:f9:5e:ea:9b:4f:03"}


ForEach($server in $servers)
{
	Write-Host "Obtendo hora para o servidor: " -NoNewLine
	Write-Host -ForegroundColor yellow $server.Servidor
	If($server.Tipo -eq "Windows")
	{
		$hora = Invoke-Command -Computername $server.Servidor -ScriptBlock {Get-Date -Format 'dd/MM/yyyy HH:mm'}
		$HorasServidores += [PSCustomObject] @{Servidor=$server.Servidor; Hora=$hora}
	}elseIf($server.Tipo -eq "Linux")
	{
		$hora = plink -pw "linuxrootpassword" -l root $server.Servidor -hostkey $server.HostKey "TZ=America/Sao_Paulo date '+%d/%m/%Y %H:%M'"
		$HorasServidores += [PSCustomObject] @{Servidor=$server.Servidor; Hora=$hora}
	}
	
}




# --------------------------------------------------------------------------
# VERIFICANDO TOP 10 CAIXAS DE EMAIL USADAS
# --------------------------------------------------------------------------
$TopCaixasEmail = &"$ScriptPath\PS_Get_Mailbox_Statistics.ps1" -AdminUser "office365_admin" -AdminPass "office365_password" -Top 10



# --------------------------------------------------------------------------
# Verificando logs do OpenManage Server Administrator dos servidores DELL
# --------------------------------------------------------------------------
. "$ScriptPath\PS_Verifica_OMSA.ps1"
$omsa_servers = @()
$omsa_servers += @{Server="BMABHFS01";OMSAVersion="9"}
$omsa_servers += @{Server="BMABHFS02";OMSAVersion="9"}
$omsa_servers += @{Server="BMABHHOST1";OMSAVersion="8"}
$omsa_servers += @{Server="BMABHHOST2";OMSAVersion="6"}
$omsa_servers += @{Server="BMABHHOST3";OMSAVersion="8"}
$omsa_servers += @{Server="BMABHHOST4";OMSAVersion="6"}
$omsa_servers += @{Server="BMABHHOST07";OMSAVersion="9"}
$omsa_servers += @{Server="TVBHHOST1";OMSAVersion="6"}

$omsauser = "bma_adm"
$omsapass = "aMb!secv3c@ "
$Omsa_Check = Verifica-OMSA -omsauser $omsauser -omsapass $omsapass -servers $omsa_servers

<#
//todo? retornar path spanshots, inserir nos anexos.
ForEach($check in $Omsa_Check){
	$Global:Anexos += $check.Screenshot
}
#>



# --------------------------------------------------------------------------
# Verificando atualizações pendentes no servidores
# --------------------------------------------------------------------------
$Servers = @("SEVER1", "SEVER2")
$Updates_Check = &"$ScriptPath\Check_Missing_Updates.ps1" $Servers


# --------------------------------------------------------------------------
# Verificando execução do Union
# --------------------------------------------------------------------------
$unionExec = Start-Process -FilePath "$ScriptPath\check_union.exe" -Wait -Passthru
$UnionCheck = @()
If($unionExec.ExitCode -eq 0)
{
	$UnionCheck += New-Object PSObject -Property @{Abertura="OK"; Login="OK"; "Operação"="OK" }
	
}Else{
	$UnionCheck += New-Object PSObject -Property @{Abertura="ERRO"; Login="ERRO"; "Operação"="ERRO" }
}



# --------------------------------------------------------------------------
# Verificando o acesso ao FileServer
# --------------------------------------------------------------------------
$net_folders = @(
	"\\brandt.local\arquivos\dadosbma", 
	"\\brandt.local\arquivos\mmq", 
	"\\brandt.local\arquivos\Project_Union\Projetos_Exportados", 
	"\\brandt.local\arquivos\Dados_Clientes", 
	"\\brandt.local\arquivos\users", 
	"\\brandt.local\arquivos\fotos", 
	"\\brandt.local\arquivos\Biblioteca_Brandt", 
	"\\brandt.local\arquivos\ppublicas", 
	"\\brandt.local\arquivos\temp1", 
	"\\brandt.local\arquivos\producao", 
	"\\brandt.local\arquivos\Rede_Estendida", 
	"\\brandt.local\arquivos\Morto", 
	"\\brandt.local\arquivos\union", 
	"\\brandt.local\arquivos\Gestao_Projetos"
)
$net_folder_result = @()
ForEach($folder in $net_folders)
{
	try{
		Get-Item -Path $folder
		$net_folder_result += New-Object PSObject -Property @{Pasta=$folder; Acesso="OK"}
	}catch{
		$net_folder_result += New-Object PSObject -Property @{Pasta=$folder; Acesso="ERRO"}
	}
}




# --------------------------------------------------------------------------
# Verificando cameras do DVR
# --------------------------------------------------------------------------
$dvr_screenshots = &"C:\Scripts\Verificacao_Ambiente\PS_Verifica_DVR.ps1"



# --------------------------------------------------------------------------
# Verificando Computadores no inventario
# --------------------------------------------------------------------------
. "$ScriptPath\PS_Verifica_OldPcs_OcsInventory.ps1"
$OldPcsInventario_Result = Get-OldOCSInventoryPCS -ocs_url $ocs_url -ocs_admin_user $ocs_admin_user -ocs_admin_pass $ocs_admin_pass -ocs_cliente_tag $ocs_cliente_tag
Write-HOst "debug pcs antigos no inventario " $OldPcsInventario_Result.Inventory.Count



# --------------------------------------------------------------------------
# ENVIANDO RELATÓRIO EM FORMATO HTML POR E-MAIL
# --------------------------------------------------------------------------
#$img_url_ok = "https://cdn0.iconfinder.com/data/icons/df_On_Stage_Icon_Set/128/Symbol_-_Check.png"
#$img_url_err = "


$html = @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>[VERIFICAÇÃO DE AMBIENTE] Integratio</title>
</head>
<body>
<h3> VERIFICAÇÃO DE INTERNET </h3>
Resultado: <strong>$($Internet_Result.Result)</strong><br/>
Ping: <strong>$($Internet_Result.Ping)</strong><br/>
Download: <strong>$($Internet_Result.Download)</strong><br/>
Upload: <strong>$($Internet_Result.Upload)</strong><br/>

<hr/><br/>
<h3> STATUS DOS LINKS NO FIREWALL </h3>
Resultado: <strong>$($pfsense_Result.Result)</strong><br/>
<table>
<tr><td>Name</td><td>Gateway</td><td>Status</td><td>Description</td></tr>
"@
ForEach($gw in $pfsense_Result.Gateways)
{
$html += @"
	<tr>$($gw.Name)</td><td>$($gw.Gateway)</td><td>$($gw.Status)</td><td>$($gw.Description)</td></tr>
"@
}

$html += @"
</table>
<hr/><br/>
<h3> LOGS DE EVENTOS RELEVANTES </h3>
Resultado: <strong>$($Events_Result.Result)</strong><br/>
$($Events_Result.Events | ConvertTo-HTML -Fragment)


<hr/><br/>
<h3> RELÓGIO DOS SERVIDORES</h3>
$($HorasServidores | ConvertTo-HTML -Fragment)

<hr/><br/>
<h3> TOP CAIXAS DE E-MAIL</h3>
$($TopCaixasEmail | ConvertTo-HTML -Fragment)

<hr/><br/>
<h3> ATUALIZAÇÕES PENDENTES NOS SERVIDORES</h3>
$($Updates_Check | ConvertTo-HTML -Fragment)

<hr/><br/>
<h3> VERIFICAÇÃO DO UNION</h3>
$($UnionCheck | ConvertTo-HTML -Fragment)


<hr/><br/>
<h3> VERIFICAÇÃO PASTAS DO FILESERVER</h3>
$($net_folder_result | ConvertTo-HTML -Fragment)

<hr/><br/>
<h3> VERIFICAÇÃO DE PCS ANTIGOS NO INVENTARIO</h3>
Resultado: <strong>$($OldPcsInventario_Result.Result)</strong><br/>
$($OldPcsInventario_Result.Inventory | ConvertTo-HTML -Fragment)



</body>
</html>
"@

# source email routines.
. "$ScriptPath\Send-Email.ps1"

$attachments = (get-childitem -path "$ScriptPath\screenshots"| %{$_.FullName})


# Enviando o e-mail
Send-Email -To "myuser@gmail.com" -Subject "[Verificacao de Ambiente] Brandt" -Body $html -Attachments $attachments

# Removendo os screenshots após ter enviado e-mail
get-childitem -path "$ScriptPath\screenshots"| remove-item
