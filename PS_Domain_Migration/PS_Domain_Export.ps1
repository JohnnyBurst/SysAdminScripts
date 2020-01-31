<#
.SYNOPSIS
    This script exports users, groups and it's association as an .xml file.

.DESCRIPTION
    This script exports users and groups information (and it's association users->groups and groups->groups) as an .xml to be later imported into a new domain controller.
    We export all user and group fields (except password). It should help you in the case of a domain migration or rebuild.



.NOTES
    Copyright (C) 2020  Luciano Rodrigues

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

#>




# Getting the current folder in which this script has been executed.
$script_path = Split-Path -Parent $MyInvocation.MyCommand.Path
$exportfile = "$script_path\exported_domain_info.xml" 


# List of user's fields to be exported.
$user_export_fields = $("name", "GivenName","Surname","Title","Initials","mail","SamAccountName","Company",
                "Department","Description","DisplayName","Division","EmailAddress","EmployeeID","EmployeeNumber",
                "HomeDirectory","Manager","MobilePhone","Office","OfficePhone","Organization","OtherName","PasswordNeverExpires",
                "ProfilePath","ScriptPath","State","StreetAddress","DistinguishedName","enabled")


# Blacklist of groups not to export | they are default Active Directory Groups and do not need to be recreated.
$blacklist_groups = @('WinRMRemoteWMIUsers__','Administrators','Users','Guests','Print Operators','Backup Operators','Replicator','Remote Desktop Users','Network Configuration Operators','Performance Monitor Users','Performance Log Users','Distributed COM Users','IIS_IUSRS','Cryptographic Operators','Event Log Readers','Certificate Service DCOM Access','RDS Remote Access Servers','RDS Endpoint Servers','RDS Management Servers','Hyper-V Administrators','Access Control Assistance Operators','Remote Management Users','Domain Computers','Domain Controllers','Schema Admins','Enterprise Admins','Cert Publishers','Domain Admins','Domain Users','Domain Guests','Group Policy Creator Owners','RAS and IAS Servers','Server Operators','Account Operators','Pre-Windows 2000 Compatible Access','Incoming Forest Trust Builders','Windows Authorization Access Group','Terminal Server License Servers','Allowed RODC Password Replication Group','Denied RODC Password Replication Group','Read-only Domain Controllers','Enterprise Read-only Domain Controllers','Cloneable Domain Controllers','Protected Users','DnsAdmins','DnsUpdateProxy','DHCP Administrators','DHCP Users','TelnetClients','HelpServicesGroup')

# Blacklist of users not to export | they are default Active Directory users and do not need to be recreated.
$blacklist_users = @('Administrator','Guest','krbtgt')
ForEach($user in (Get-ADUser -Filter {Name -like '*SUPPORT_*'}))
{
    $blacklist_users += $user.Name
}

# Blacklist of Organizational Units not to export.
$blacklist_ous = @('Domain Controllers')





# -------------------------------------------------------------------------------------------
#     -----------------------------------------------------------------------------
#                                 MAIN ROUTINE
#     -----------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# How does the magic works?
# 1. We discover the current domain
# 2. List the domain controllers in the current domain
# 3. Connect to PDC emulator server via ldap and retrieve the default naming context (dc=contoso,dc=corp)
# 4. Export all user/group and it's association that is down the default naming context (we try to export all users, seriously)
# 5. Save 
#

# Creating the xml object to hold our info
$xml = [xml]''
$xmlroot = $xml.appendChild($xml.CreateElement("Migration"))

# Getting current domain
$adsi_domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$sourcedomain = $adsi_domain.name                
$all_domain_controllers = $adsi_domain.DomainControllers
$dc = $adsi_domain.PdcRoleOwner
$RootDSE = [ADSI]"LDAP://$dc/RootDSE"
$default_naming_context = $RootDSE.DefaultNamingContext.Value
$basednsearch = $default_naming_context



# Appending source domain info to the xml
$xmlsourcedomainnode = $xmlroot.AppendChild($xml.CreateElement("sourcedomain"))
$xmlsourcedomainnode.AppendChild($xml.CreateTextNode($sourcedomain)) | out-null


# Appending source DefaultNamingContext info to the xml
$xmlnamingcontextnode = $xmlroot.AppendChild($xml.CreateElement("namingcontext"))
$xmlnamingcontextnode.AppendChild($xml.CreateTextNode($default_naming_context)) | out-null




# -------------------------------------------------------------------------------------------
# Exporting users
# -------------------------------------------------------------------------------------------
Write-Host "Exporting users..."
$ADUsers = Get-ADUser -Filter * -Properties * -SearchBase $basednsearch  | Where-Object {$_.Name -notin $blacklist_users}
Write-Host "Total of exportable users found: $($ADUsers.count)"

# Appending the main node of users to the xml
$xmlusersnode = $xmlroot.AppendChild($xml.CreateElement("users"))


# Appending each user to the xml
foreach($user in $ADUsers)
{
    # New user node
    $xmlusernode = $xmlusersnode.AppendChild($xml.CreateElement("user"))

    # Attributes
    foreach($field in $user_export_fields)
    {
        # Creating the attribute node and inserting it's value
        $xmluserfieldnode = $xmlusernode.appendChild($xml.CreateElement($field))
        $xmluserfieldnode.appendChild($xml.CreateTextNode($user.$field)) | out-null
    }

    # Adding a node associating the user with it's group memberships
    foreach($group in $user.memberof)
    {
        $parsedGroup = $group.replace( $sourceBaseDN, $targetBaseDN)
        $xmlusermemberofnode = $xmlusernode.appendChild($xml.CreateElement("memberof"))
        $xmlusermemberofnode.appendChild($xml.CreateTextNode($parsedGroup))  | out-null

    }
}


# -------------------------------------------------------------------------------------------
# Exporting groups
# -------------------------------------------------------------------------------------------
Write-Host "Exporting groups..."
$ADGroups = Get-ADGroup -Filter * -SearchBase $basednsearch -Properties * | Where-Object {$_.Name -notin $blacklist_groups} | Select-Object Name,GroupScope,GroupCategory,Description,Info,memberof,DistinguishedName
Write-Host "Total of exportable groups found: $($ADGroups.Count)"

# Creating the main groups node
$xmlgroupsnode = $xmlroot.appendChild($xml.CreateElement("groups"))

# List of fields to be exported from the groups
$groups_fields = @("Name","GroupScope","GroupCategory","Description","Info","DistinguishedName")


foreach($group in $ADGroups)
{
    $xmlgroupnode = $xmlgroupsnode.appendChild($xml.CreateElement("group"))
    
    foreach($field in $groups_fields)
    {
        # Creating the field element and inserting it's value
        $xmlgroupfieldnode = $xmlgroupnode.appendChild($xml.CreateElement($field))
        $xmlgroupfieldnode.appendChild($xml.CreateTextNode($group.$field)) | out-null
    }

    # Exporting the list of groups that this group is a member
    foreach($memberof in $group.memberof)
    {
        $parsedGroup = $memberof.replace( $sourceBaseDN, $targetBaseDN)
        $xmlgroupmemberofnode = $xmlgroupnode.appendChild($xml.CreateElement("memberof"))
        $xmlgroupmemberofnode.appendChild($xml.CreateTextNode($parsedGroup))  | out-null

    }


}


# -------------------------------------------------------------------------------------------
# Exporting Organizational Units
# -------------------------------------------------------------------------------------------
# fields to be exported
$ou_fields = @("Name","Description","DistinguishedName")

Write-Host "Exporting Organizational Units..."
$ADOUs = Get-ADOrganizationalUnit -Filter * -SearchBase $basednsearch -Properties Description | Where-Object {$_.Name -notin $blacklist_ous} | Select $ou_fields
Write-Host "Total de OU's encontradas: $($ADOUs.Count)"

# Creating main OU node
$xmlousnode = $xmlroot.appendChild($xml.CreateElement("ous"))



foreach($ou in $ADOUs)
{
    $xmlounode = $xmlousnode.appendChild($xml.CreateElement("ou"))
    
    foreach($field in $ou_fields)
    {
        # Creating the attribute element and giving it's value
        $xmloufieldnode = $xmlounode.appendChild($xml.CreateElement($field))
        $xmloufieldnode.appendChild($xml.CreateTextNode($ou.$field)) | out-null
    }

}




# -------------------------------------------------------------------------------------------
# Saving the .XML file with all exported information.
# -------------------------------------------------------------------------------------------
Write-Host "Saving the file $exportfile"
try{
    $xml.Save($exportfile)
}catch{
    $PSCmdlet.ThrowTerminatingError($_.Exception)
}