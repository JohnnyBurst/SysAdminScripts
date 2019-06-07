# ----------------------------------------------------------------------------
# Script para exportar em XML dados do AD (usuarios, grupos,ou's, members)
# Autor: luciano.rodrigues@v3c.com.br
# Ajuste os parametros variaveis e execute este script como administrador.
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
# Parametros modificaveis
# ----------------------------------------------------------------------------
# Arquivo de saída. Por padrão é criado na pasta Documentos do usuário logado.
$script_path = Split-Path -Parent $MyInvocation.MyCommand.Path
$exportfile = "$script_path\domain_export.xml" 


# Campos que serão exportados dos usuarios
$export_fields = $("name", "GivenName","Surname","Title","Initials","mail","SamAccountName","Company","Department","Description","DisplayName","Division","EmailAddress","EmployeeID","EmployeeNumber","HomeDirectory","Manager","MobilePhone","Office","OfficePhone","Organization","OtherName","PasswordNeverExpires","ProfilePath","ScriptPath","State","StreetAddress","DistinguishedName","enabled")


# Lista de grupos para não copiar | grupos padrão do active directory
$blacklist_groups = @('WinRMRemoteWMIUsers__','Administrators','Users','Guests','Print Operators','Backup Operators','Replicator','Remote Desktop Users','Network Configuration Operators','Performance Monitor Users','Performance Log Users','Distributed COM Users','IIS_IUSRS','Cryptographic Operators','Event Log Readers','Certificate Service DCOM Access','RDS Remote Access Servers','RDS Endpoint Servers','RDS Management Servers','Hyper-V Administrators','Access Control Assistance Operators','Remote Management Users','Domain Computers','Domain Controllers','Schema Admins','Enterprise Admins','Cert Publishers','Domain Admins','Domain Users','Domain Guests','Group Policy Creator Owners','RAS and IAS Servers','Server Operators','Account Operators','Pre-Windows 2000 Compatible Access','Incoming Forest Trust Builders','Windows Authorization Access Group','Terminal Server License Servers','Allowed RODC Password Replication Group','Denied RODC Password Replication Group','Read-only Domain Controllers','Enterprise Read-only Domain Controllers','Cloneable Domain Controllers','Protected Users','DnsAdmins','DnsUpdateProxy','DHCP Administrators','DHCP Users','TelnetClients','HelpServicesGroup')

# Lista de usuários para não copiar | usuários ipadrão do active directory
$blacklist_users = @('Administrator','Guest','krbtgt')
ForEach($user in (Get-ADUser -Filter {Name -like '*SUPPORT_*'}))
{
    $blacklist_users += $user.Name
}

# Lista de OU's para não copiar | ous padrão do active directory
$blacklist_ous = @('Domain Controllers')





# -------------------------------------------------------------------------------------------
#     -----------------------------------------------------------------------------
#              !!! NÃO MODIFIQUE DESETA LINHA PARA BAIXO !!!
#     -----------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------

# Declarando o objeto XML e atribuindo o nó root
$xml = [xml]''
$xmlroot = $xml.appendChild($xml.CreateElement("Migration"))

# Conexão ADSI
$adsi_domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()

# Dominio do AD de origem
$sourcedomain = $adsi_domain.name                

# Obtendo o servidor AD com a função de PDC
$all_domain_controllers = $adsi_domain.DomainControllers
$dc = $adsi_domain.PdcRoleOwner

# Carregando o default naming context da particao do AD
$RootDSE = [ADSI]"LDAP://$dc/RootDSE"
$default_naming_context = $RootDSE.DefaultNamingContext.Value

# base de procura por objetos -> rootdsr/defaultnamingcontext
$basednsearch = $default_naming_context


# -------------------------------------------------------------------------------------------
# Inserindo no XML informações do ambiente de origem.
# -------------------------------------------------------------------------------------------

# SourceDomain
$xmlsourcedomainnode = $xmlroot.AppendChild($xml.CreateElement("sourcedomain"))
$xmlsourcedomainnode.AppendChild($xml.CreateTextNode($sourcedomain)) | out-null


# DefaultNamingContext
$xmlnamingcontextnode = $xmlroot.AppendChild($xml.CreateElement("namingcontext"))
$xmlnamingcontextnode.AppendChild($xml.CreateTextNode($default_naming_context)) | out-null




# -------------------------------------------------------------------------------------------
# Obtendo a lista de usuarios
# -------------------------------------------------------------------------------------------
Write-Host "Exportando lista de usuarios..."
$ADUsers = Get-ADUser -Filter * -Properties * -SearchBase $basednsearch  | Where-Object {$_.Name -notin $blacklist_users}
Write-Host "Total de usuarios encontrados: $($ADUsers.count)"

# Criando o nó master de usuarios
$xmlusersnode = $xmlroot.AppendChild($xml.CreateElement("users"))


# Adicionando cada usuario com suas propriedades
foreach($user in $ADUsers)
{
    # Criando o nó usuario
    $xmlusernode = $xmlusersnode.AppendChild($xml.CreateElement("user"))

    # Adicionando os atributos
    foreach($field in $export_fields)
    {
        # Criando o nó do atributo do usuário.
        $xmluserfieldnode = $xmlusernode.appendChild($xml.CreateElement($field))
        
        # Inserindo o valor do atributo do usuário.
        $xmluserfieldnode.appendChild($xml.CreateTextNode($user.$field)) | out-null
    }

    # Adicionando os grupos, necessario codigo separado para manipular esta funcao
    foreach($group in $user.memberof)
    {
        $parsedGroup = $group.replace( $sourceBaseDN, $targetBaseDN)
        # Adicionando os grupos (memberof) ao usuario no xml.
        $xmlusermemberofnode = $xmlusernode.appendChild($xml.CreateElement("memberof"))
        $xmlusermemberofnode.appendChild($xml.CreateTextNode($parsedGroup))  | out-null

    }
}


# -------------------------------------------------------------------------------------------
# Obtendo a lista de Grupos
# -------------------------------------------------------------------------------------------
#Obtendo os grupos do AD
Write-Host "Processando Grupos..."
$ADGroups = Get-ADGroup -Filter * -SearchBase $basednsearch -Properties * | Where-Object {$_.Name -notin $blacklist_groups} | Select Name,GroupScope,GroupCategory,Description,Info,memberof,DistinguishedName
Write-Host "Total de grupos encontrados: $($ADGroups.Count)"

# Criando o nó master de grupos
$xmlgroupsnode = $xmlroot.appendChild($xml.CreateElement("groups"))

# campos exportados dos grupos
$groups_fields = @("Name","GroupScope","GroupCategory","Description","Info","DistinguishedName")


foreach($group in $ADGroups)
{
    $xmlgroupnode = $xmlgroupsnode.appendChild($xml.CreateElement("group"))
    
    foreach($field in $groups_fields)
    {
        # Criando o nó do atributo do grupo.
        $xmlgroupfieldnode = $xmlgroupnode.appendChild($xml.CreateElement($field))

        # Inserindo o valor do atributo do grupo.
        $xmlgroupfieldnode.appendChild($xml.CreateTextNode($group.$field)) | out-null
    }

    # Manipulando o atributo memberof dos grupos (Grupos contidos em outros Grupos).
    foreach($memberof in $group.memberof)
    {
        $parsedGroup = $memberof.replace( $sourceBaseDN, $targetBaseDN)
        # Adicionando os grupos (memberof) ao grupo no xml.
        $xmlgroupmemberofnode = $xmlgroupnode.appendChild($xml.CreateElement("memberof"))
        $xmlgroupmemberofnode.appendChild($xml.CreateTextNode($parsedGroup))  | out-null

    }


}


# -------------------------------------------------------------------------------------------
# Obtendo a lista de Unidades Organizacionais
# -------------------------------------------------------------------------------------------

# campos exportados das ou's
$ou_fields = @("Name","Description","DistinguishedName")

# Obtendo a lista de OU's do Demônio
Write-Host "Processando OU's..."
$ADOUs = Get-ADOrganizationalUnit -Filter * -SearchBase $basednsearch -Properties Description | Where-Object {$_.Name -notin $blacklist_ous} | Select $ou_fields
Write-Host "Total de OU's encontradas: $($ADOUs.Count)"

# Criando o nó master de ou's
$xmlousnode = $xmlroot.appendChild($xml.CreateElement("ous"))




foreach($ou in $ADOUs)
{
    $xmlounode = $xmlousnode.appendChild($xml.CreateElement("ou"))
    
    foreach($field in $ou_fields)
    {
        # Criando o nó do atributo do grupo.
        $xmloufieldnode = $xmlounode.appendChild($xml.CreateElement($field))

        # Inserindo o valor do atributo do grupo.
        $xmloufieldnode.appendChild($xml.CreateTextNode($ou.$field)) | out-null
    }

}




# -------------------------------------------------------------------------------------------
# Salvando o arquivo .XML final
# -------------------------------------------------------------------------------------------
Write-Host "Salvando o arquivo $exportfile"
$xml.Save($exportfile)