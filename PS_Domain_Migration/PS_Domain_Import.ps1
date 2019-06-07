# -----------------------------------------------------------------------------------------------
# Script para importar ous,groups,usuarios e relações de usuários-> grupos
# Autor: luciano.rodrigues@v3c.com.br
# Este script deve ser utilizado para importar o arquivo .xml gerado com o script Export-AD.PS1
# -----------------------------------------------------------------------------------------------
clear-host

# -----------------------------------------------------------------------------------------------
# Parametros Modificaveis
# -----------------------------------------------------------------------------------------------

# Senha padrão para as contas importadas.
$default_user_password = "P4ssw0rd"

# LogFile
$data = Get-Date -Format 'yyyy_MM_dd_HH_mm'
$logfile = "C:\windows\temp\Importa-AD_$data`_.txt"



# -------------------------------------------------------------------------------------------
#     -----------------------------------------------------------------------------
#              !!! NÃO MODIFIQUE DESETA LINHA PARA BAIXO !!!
#     -----------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------
# Function: Log - Registra o evento no arquivo de logs e na tela do usuário.
# -------------------------------------------------------------------------------------------
# @Argument: [string]$text = Texto a ser registrado.
# -------------------------------------------------------------------------------------------
Function Log($text)
{
    $data = Get-Date -Format 'yyyy/MM/dd HH:mm'
    Write-Host "$data`: $text"
    Add-Content -Path $logfile -Value "$data`: $text"
}
Function RawLog($text)
{
    Write-Host $text
    Add-Content -Path $logfile -Value $text
}



# Caminho do arquivo .xml gerado anteriormente.
$script_path = Split-Path -Parent $MyInvocation.MyCommand.Path
$importfile = "$script_path\domain_export.xml"
Log("Script Path: $script_path")
Log("Importando o arquivo: $importfile")


# Declarando o objeto xml e carregando o arquivo .xml
$xml = [xml]''
$xml.Load($importfile)



# -------------------------------------------------------------------------------------------
# Obtendo informações do ambiente Active Directory LOCAL
# -------------------------------------------------------------------------------------------
# Nome do domínio e controlador de domínio PDC Emulator ("primário")
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$target_domain = $domain.Name
$dc = $domain.PdcRoleOwner.Name
Log("Utilizando servidor AD Primario: $dc")
Log("Dominio detectado: $target_domain")

# Default Context naming
$RootDSE = [ADSI]"LDAP://$dc/RootDSE"
$default_naming_context = $RootDSE.DefaultNamingContext.Value
$target_basedn = $default_naming_context
Log("Naming context detectado: $target_basedn")



# -------------------------------------------------------------------------------------------
# Obtendo informações do ambiente Active Directory de onde foi exportado o .XML
# -------------------------------------------------------------------------------------------
$old_basedn = $xml.Migration.namingcontext
$old_domain = $xml.Migration.sourcedomain
Log("Old BaseDN do dominio: $old_basedn")
Log("Old Domain do dominio: $old_domain")





# -----------------------------------------------------------------------------------------------
# Importando as Unidades Organizacionais
# -----------------------------------------------------------------------------------------------
Log("Iniciando importação de Unidades Organizacionais")
ForEach($ou in $xml.SelectNodes("//Migration/ous/ou"))
{
    # Ajustando o DN da OU
    $ou_fixed_dn = [regex]::replace($ou.DistinguishedName, $old_basedn, $target_basedn)
    $ou_path = [regex]::replace($ou_fixed_dn, "OU=$($ou.name),", "")

    try{
        New-ADOrganizationalUnit -Name $ou.Name -Path $ou_path -Description $ou.Description
    }catch{
        "Erro ao criar a Unidade Organizacional $ou_fixed_dn"
    }
}




# -----------------------------------------------------------------------------------------------
# Importando os Grupos
# -----------------------------------------------------------------------------------------------
Log("Iniciando importação de Grupos")
ForEach($group in $xml.SelectNodes("//Migration/groups/group"))
{
    $groupname = $group.Name; Log("Criando grupo: $groupname")
    # Corrigindo o caminho do grupo
    $group_fixed_dn = [regex]::replace($group.DistinguishedName, $old_basedn, $target_basedn)
    $group_path = [regex]::replace($group_fixed_dn, "CN=$($group.name),", "")

    try{
        New-ADGroup -Name $group.Name -GroupScope $group.GroupScope -GroupCategory $group.GroupCategory -Path $group_path
        if($group.Description -ne $null) { Set-ADGroup -Identity $group.Name -Description $group.Description }
        if($group.Info -ne $null)   { Set-ADGroup -Identity $group.Name  -OtherAttributes @{Info=$group.Info} }

        ForEach($member in $group.memberof)
        {
            $group_new_dn = [regex]::replace($member, $old_basedn, $target_basedn)
            Log("Adicionando o grupo "+$grupo.Name +" ao grupo: "+$group_new_dn)
            Add-ADGroupMember -Identity $group_new_dn -Members $group.Name
        }

    }catch{
        #"Erro ao criar o grupo $group_fixed_dn"
        $_.Exception.Message
    }
}




# -----------------------------------------------------------------------------------------------
# Importando os Usuarios
# -----------------------------------------------------------------------------------------------
Log("Iniciando importação de usuários")
ForEach($user in $xml.SelectNodes("//Migration/users/user"))
{
    Log("Criando usuario: "+$user.name)
    # Ajustando o path onde o usuário será criado (ou).
    $user_fixed_dn = [regex]::replace($user.DistinguishedName, $old_basedn, $target_basedn)
    $user_path = [regex]::replace($user_fixed_dn, "CN=$($user.name),", "")

    try{
        New-ADUser -Name $user.Name `
            -GivenName $user.GivenName `
            -Surname $user.Surname `
            -Title $user.Title `
            -Initials $user.Initials `
            -SamAccountName $user.sAMAccountName `
            -UserPrincipalName $user.SamAccountName `
            -Department $user.Department `
            -Company $user.Company `
            -Description $user.Description `
            -DisplayName $user.DisplayName `
            -Division $user.Division `
            -EmailAddress $user.EmailAddress `
            -EmployeeID $user.EmployeeID `
            -EmployeeNumber $user.EmployeeNumber `
            -HomeDirectory $user.HomeDirectory `
            -MobilePhone $user.MobilePhone `
            -Office $user.Office `
            -OfficePhone $user.OfficePhone `
            -Organization $user.Organization `
            -OtherName $user.OtherName `
            -PasswordNeverExpires $(if($user.PasswordNeverExpires -eq "False"){$false}else{$true}) `
            -ProfilePath $user.ProfilePath `
            -ScriptPath $user.ScriptPath `
            -State $user.State `
            -StreetAddress $user.StreetAddress `
            -Path $user_path `
            -AccountPassword (ConvertTo-SecureString -AsPlainText -Force $default_user_password) `
            -Enabled $(if($user.Enabled -eq 'True'){$True}else{$False} )

            if($user.Manager -ne ''){Set-ADUser -Identity $user.SamAccountName -Manager $user.Manager}

            # Adicionando o usuario aos grupos que ele pertence
            ForEach($group in $user.memberof)
            {
                $group_new_dn = [regex]::replace($group, $old_basedn, $target_basedn)
                Log("Adicionando o usuario "+$user.samacccountname+" ao grupo: "+$group_new_dn)
                Add-ADGroupMember -Identity $group_new_dn -Members $user.SamAccountName
            }
        }catch{
            $_.Exception.Message
        }
}
Log("Terminado!")