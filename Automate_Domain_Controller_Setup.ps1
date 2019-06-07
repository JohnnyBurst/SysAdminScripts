# ------------------------------------------------------
# Script para automação de instalação de servidores.
# ------------------------------------------------------

# Parametros ajustaveis
$Domain = "DARKSTAR.CORP"
$safemodeadminpassword = "adm123456@"


# Obtendo o Adaptador de rede padrão (windows en-us)
$net_adapter = Get-NetAdapter -Name Ethernet

# Alterando o IP de dhcp (padrao) para estático
Remove-NetIPAddress -InterfaceIndex $net_adapter.InterfaceIndex -Confirm:$false
New-NetIpAddress -InterfaceIndex $net_adapter.InterfaceIndex -IPAddress 10.0.2.11 -PrefixLength 24 -AddressFamily IPv4 -DefaultGateway 10.0.2.2 -Confirm:$false
Set-DnsClientServerAddress -InterfaceAlias $net_adapter.InterfaceAlias -ServerAddress 127.0.0.1,8.8.8.8


# Instalando a função ActiveDirectory
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -IncludeAllSubFeature 


# Subindo o ActiveDirectory

$safeadmpass = ConvertTo-SecureString -Force -AsPlainText $safemodeadminpassword 
Install-ADDSForest -DomainName $Domain -SkipPreChecks -SafeModeAdministratorPassword $safeadmpass -DomainMode Win2012R2 -InstallDns -Confirm:$False -Force -NoRebootOnCompletion
Restart-Computer -Force




