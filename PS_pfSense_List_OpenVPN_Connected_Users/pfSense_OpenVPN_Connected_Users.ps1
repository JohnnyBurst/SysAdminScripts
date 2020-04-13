#--------------------------------------------------------------------------------
# VIA3 CONSULTING - CONSULTORIA EM GESTÃO E TI
# Script para consultar usuários atualmente conectados na VPN do pfSense.
# Autor: via3lr - luciano.grodrigues@live.com
# Data: 10/04/2020  versão 1.0
#--------------------------------------------------------------------------------

<#
.SYNOPSIS
    This script connects to pfSense WebConfig and retrieve a list of OpenVPN connected users.

.NOTES
    Copyright (C) 2020  luciano.grodrigues@live.com
    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
#>


#--------------------------------------------------------------------------------
# User defined variables
#--------------------------------------------------------------------------------
# Create a pfSense user with only privilege to see page webgui-openvpn status
$pfsense_user = "VpnReadOnlyUserHere"

# Make a secure password for the user above
$pfsense_passwd = "PutYourPasswordHere"

# URL to access pfsense Landing Page. Do not put a leading '/'.
$pfsense_uri = "http://192.168.0.0"

# IP (or domain name) of the ActiveDirectory Server to query users displayName against.
$LDAPSERVER = "192.168.0.0"

# Default naming context of active directory (root DC) or sub organizational unit where to locate users
$DEFAULT_NAMING_CONTEXT = "DC=MyCompany,DC=local"

# Internationalization
# I use pt-br at my work...
$PROGRAM_TITLE = "Listar Conexões VPN - CUSTOMER"
$MSG_INVALID_USER = "Usuários ou senha inválidos!"
$MSG_EMPTY_USERNAME_OR_PASSWORD = "Usuários ou senha em branco!"
$COLUMN_USERNAME = "Usuário"
$COLUMN_REAL_IP = "IP Real"
$COLUMN_VIRTUAL_IP = "IP Virtual"
$COLUMN_CONNECTION_DATE = "Data Conexão"
$COLUMN_BYTES = "Bytes"


# Function ValidateUserCredencial
# Validate user supplied credential
# input: [string] $username
# input: [string] $password
# output: [boolean] success: true, otherwise false.
Function ValidateUserCredential
{
    
    $username = $Form.FindName("usrname").Text
    $password = $Form.FindName("usrpass").Password

    If($username -eq '' -or $password -eq '')
    {
        [Windows.MessageBox]::Show($MSG_EMPTY_USERNAME_OR_PASSWORD) | out-null
        Return $False
    }


    $de = New-Object System.DirectoryServices.DirectoryEntry -ArgumentList "LDAP://$LDAPSERVER/$DEFAULT_NAMING_CONTEXT", $username, $password
    if($de.psbase.name -ne $null)
    {
        Return $True
    }else{
        [Windows.MessageBox]::Show($MSG_INVALID_USER) | out-null
        Return $False
    }


}




# Function GetUserDisplayName
# Gets user displayname attribute from ActiveDirectory
# Input: [string] user samaccountname
# output: [string] user displayname property
Function GetUserDisplayName
{
    Param(
        [Parameter(Mandatory=$True)] [String] $usertosearch
    )

    # using the provided credential to connect to active directory.
    $username = $Form.FindName("usrname").Text
    $password = $Form.FindName("usrpass").Password

    try{
        $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry "LDAP://$LDAPSERVER/$DEFAULT_NAMING_CONTEXT", $username, $password
        $DirectorySearcher = New-Object System.DirectoryServices.DirectorySearcher $DirectoryEntry
        $DirectorySearcher.Filter = "(samaccountname=$usertosearch)"
        $user = $DirectorySearcher.FindOne()
        Return $user.Properties["DisplayName"]
    }catch{
        return $usertosearch
    }


}



# Function LoadVPNData
# Queries pfSense about currently connected vpn users
# input: none
# output: none
Function LoadVPNData
{

    If(-Not (ValidateUserCredential) )
    {
        Return $False
    }


    $baseuri = $pfsense_uri
    $vpnuri = "$baseuri/status_openvpn.php"


    $ProgressPreference = "SilentlyContinue"
    # Initial connection to pfsense webgui
    $req = invoke-webrequest -Uri $baseuri -Method GET -SessionVariable 'websess'



    # Setting login data
    $logindata = @{
	    usernamefld  = $pfsense_user;
	    passwordfld  = $pfsense_passwd;
	    login        = "Sign+In";
	    __csrf_magic = $req.InputFields.FindByName("__csrf_magic").Value
    }



    # Post to login uri
    $req = invoke-webrequest -Uri $baseuri -Method POST -WebSession $websess -Body $logindata -ContentType 'application/x-www-form-urlencoded'
            
		
	
    # Extracting token after login request
    $token = $req.InputFields.FindByName("__csrf_magic").Value



    # Acessing openvpn status page
    $req = Invoke-WebRequest -Uri $vpnuri -WebSession $websess



    # Getting returned Table containing connected users
    $tabledata = $req.ParsedHTML.getElementsByTagName("table")[0]
    
    
    # We don't count the last table entry (row)
    $rowscount = $tabledata.rows.length

    

    # $vpninfo holds while info from retrieved table
    $vpninfo = New-Object System.Collections.ArrayList


    
    for($i=1; $i -lt ($rowscount -1); $i++)
    {
        # Skipping first row (headers)
        # and last row (footer)

        $username = GetUserDisplayName( $tabledata.rows[$i].Cells[0].innerText.Split("`n")[0].trim() )
        $ipreal = $tabledata.rows[$i].Cells[1].innerText
        $ipvirtual = $tabledata.rows[$i].Cells[2].innerText
        $dataconexao = $tabledata.rows[$i].Cells[3].innerText
        $bytes = $tabledata.rows[$i].Cells[4].innerText

        $userinfo = [PSCustomObject] @{
            $COLUMN_USERNAME = $username
            $COLUMN_REAL_IP = $ipreal
            $COLUMN_VIRTUAL_IP = $ipvirtual
            $COLUMN_CONNECTION_DATE = $dataconexao
            $COLUMN_BYTES = $bytes
        }
            
        $vpninfo.Add($userinfo)
      
    }

    
    # Finding the grid wpf element
    $Grid = $Form.FindName("dataGrid1")


    # Sorting the grid by username
    $vpninfo = $vpninfo | sort-object -property $COLUMN_USERNAME
    
    
    # Populating the grid with data
    $Grid.ItemsSource = @($vpninfo)


}



#--------------------------------------------------------------------------------
#
# Main Routine starts here
#
#--------------------------------------------------------------------------------

# Loading Presentation Framework Assembly
Add-Type -AssemblyName PresentationFramework



# The XAML code to present the main form
[xml] $xaml = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$PROGRAM_TITLE" Height="431" Width="750">
    <Grid>
        <DataGrid AutoGenerateColumns="True" Margin="0,45,0,0" Name="dataGrid1" VerticalAlignment="Top" />
        <Label Content="Usuário" Height="28" HorizontalAlignment="Left" Margin="12,8,0,0" Name="label1" VerticalAlignment="Top" />
        <TextBox Height="23" HorizontalAlignment="Left" Margin="68,10,0,0" Name="usrname" VerticalAlignment="Top" Width="120" />
        <Label Content="Senha" Height="28" HorizontalAlignment="Left" Margin="215,8,0,0" Name="label2" VerticalAlignment="Top" />
        <PasswordBox Height="23" HorizontalAlignment="Left" Margin="263,10,0,0" Name="usrpass" VerticalAlignment="Top" Width="120" />
        <Button Content="Atualizar" Height="23" HorizontalAlignment="Left" Margin="398,10,0,0" Name="button1" VerticalAlignment="Top" Width="75" />
    </Grid>
</Window>

"@



# Loading the XAML form
$NR = [System.Xml.XMLNodeReader]::New($xaml)
$Form = [Windows.Markup.XamlReader]::Load($NR)



# Adding the click hoking to retrieve data
$btn1 = $Form.FindName("button1")
$btn1.Add_Click({ LoadVPNData })



# Displaing the main form
$Form.ShowDialog()
	