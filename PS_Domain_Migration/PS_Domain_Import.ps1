<#
.SYNOPSIS
    This script import users, groups and organizational units and it's association from an .xml file.

.DESCRIPTION
    This script imports users, groups (and it's association users->groups and groups->groups) and organizational units from an .xml file created with the "PS_Domain_Export.PS1" script.
    We import all user, group and OU fields. User's passwords should be informed and will be default for all users.

.PARAMETER DefaultUserPassword
    This parameter specifies the default password for newly created users.


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


Param(
    [Parameter(Mandatory=$True)] $default_user_password = "P4ssw0rd"
)



# LogFile
$data = Get-Date -Format 'yyyy_MM_dd_HH_mm'
$logfile = "C:\windows\temp\PS_Domain_Import_$data`_.txt"



# -------------------------------------------------------------------------------------------
#     -----------------------------------------------------------------------------
#                                 MAIN SCRIPT ROUTINES
#     -----------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------
# Function: Log - Record and event in the logfile and on the screen with timestamp.
# -------------------------------------------------------------------------------------------
# @Argument: [string]$text = event to be recorded.
# -------------------------------------------------------------------------------------------
Function Log($text)
{
    $data = Get-Date -Format 'yyyy/MM/dd HH:mm'
    Write-Host "$data`: $text"
    Add-Content -Path $logfile -Value "$data`: $text"
}

# -------------------------------------------------------------------------------------------
# Function: RawLog - Record and event in the logfile and on the screen but w/o timestamp.
# -------------------------------------------------------------------------------------------
# @Argument: [string]$text = event to be recorded.
# -------------------------------------------------------------------------------------------
Function RawLog($text)
{
    Write-Host $text
    Add-Content -Path $logfile -Value $text
}



# Caminho do arquivo .xml gerado anteriormente.
$script_path = Split-Path -Parent $MyInvocation.MyCommand.Path
$importfile = "$script_path\exported_domain_info.xml"
Log("Script Path: $script_path")
Log("Importing info from file: $importfile")


# Creating the xml object and loading the info
$xml = [xml]''
$xml.Load($importfile)



# -------------------------------------------------------------------------------------------
# Obtaining info from the local domain
# -------------------------------------------------------------------------------------------
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$target_domain = $domain.Name
$dc = $domain.PdcRoleOwner.Name
Log("Domain Found: $target_domain")
Log("Using Domain Controller: $dc")


# Default Context naming
$RootDSE = [ADSI]"LDAP://$dc/RootDSE"
$default_naming_context = $RootDSE.DefaultNamingContext.Value
$target_basedn = $default_naming_context



# -------------------------------------------------------------------------------------------
# Getting information from source domain (the domain which the information was exporteds)
# -------------------------------------------------------------------------------------------
$old_basedn = $xml.Migration.namingcontext
$old_domain = $xml.Migration.sourcedomain
Log("Old Domain: $old_domain")
Log("Old BaseDN domain: $old_basedn")




# -----------------------------------------------------------------------------------------------
# Importing Organizational Units first
# -----------------------------------------------------------------------------------------------
Log("Starting import of organinzational units")
ForEach($ou in $xml.SelectNodes("//Migration/ous/ou"))
{
    # Adjusting the DN of old OU to reflect new environment
    $ou_fixed_dn = [regex]::replace($ou.DistinguishedName, $old_basedn, $target_basedn)
    $ou_path = [regex]::replace($ou_fixed_dn, "OU=$($ou.name),", "")

    try{
        New-ADOrganizationalUnit -Name $ou.Name -Path $ou_path -Description $ou.Description
    }catch{
        Log("ATTENTION: Error creating Organizational Unit: $ou_fixed_dn")
    }
}




# -----------------------------------------------------------------------------------------------
# Importing Groups
# -----------------------------------------------------------------------------------------------
Log("Starting group import")
ForEach($group in $xml.SelectNodes("//Migration/groups/group"))
{
    $groupname = $group.Name; Log("Creating group: $groupname")
    # Fixing group DN (ajust from source to reflect new env)
    $group_fixed_dn = [regex]::replace($group.DistinguishedName, $old_basedn, $target_basedn)
    $group_path = [regex]::replace($group_fixed_dn, "CN=$($group.name),", "")

    # Creating the group with it's info
    try{
        New-ADGroup -Name $group.Name -GroupScope $group.GroupScope -GroupCategory $group.GroupCategory -Path $group_path
        if($group.Description -ne $null) { Set-ADGroup -Identity $group.Name -Description $group.Description }
        if($group.Info -ne $null)   { Set-ADGroup -Identity $group.Name  -OtherAttributes @{Info=$group.Info} }

        # re-establishing the group membership
        ForEach($member in $group.memberof)
        {
            $group_new_dn = [regex]::replace($member, $old_basedn, $target_basedn)
            Log("Adding group "+$grupo.Name +" the the group: "+$group_new_dn)
            Add-ADGroupMember -Identity $group_new_dn -Members $group.Name
        }

    }catch{
        Log($_.Exception.Message)
    }
}




# -----------------------------------------------------------------------------------------------
# Import Users
# -----------------------------------------------------------------------------------------------
Log("Starting users import")
ForEach($user in $xml.SelectNodes("//Migration/users/user"))
{
    Log("Creating user: "+$user.name)
    # Adjusting the new DN of user.
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

            # Re-establishing the user memberships
            ForEach($group in $user.memberof)
            {
                $group_new_dn = [regex]::replace($group, $old_basedn, $target_basedn)
                Log("Adding user " + $user.name + " to the group: " + $group_new_dn)
                Add-ADGroupMember -Identity $group_new_dn -Members $user.SamAccountName
            }
        }catch{
            Log($_.Exception.Message)
        }
}
Log("Finished!")