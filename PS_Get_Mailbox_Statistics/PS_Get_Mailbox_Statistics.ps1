<#
.SYNOPSIS
    This script connects to Office365 and retrieve all mailboxes usage statistics.

.DESCRIPTION
    This script connects to Office365 using the provided AdminUser and AdminPassword then retrieve all user mailboxes 
    (created on the AdminUser tenant) and it's usage statistics.
    The results are displayed into a Output Grid Table.


.EXAMPLE
    .\PS_Get_Mailboxes_Statistics.ps1 Admin@contoso.onmicrosoft.com SuperSecureP4ssword


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


Param(
    [Parameter(Mandatory=$True)] [string]$AdminUser,
    [Parameter(Mandatory=$True)] [string]$AdminPass
)


# Transforming the plaintext provided password into a PSCredential
$user = $AdminUser
$pass = ConvertTo-SecureString -AsPlainText -Force $AdminPass
$UserCredential = New-Object System.Management.Automation.PSCredential($user, $pass)


# Connecting to Online Exchange
try{
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}catch{
    Write-Host -ForegroundColor RED "Erro ao conectar ao Exchange Online. Encerrando o script."
    Write-Host $_.Exception.Message
    Exit
}

# Retrieving list of available mailboxes
Write-Host "Getting Mailboxes..."
$Mailboxes = Get-MailBox

$table = @()

Write-Host "Getting Statistics..."

$processed = 0
$Mailboxes | ForEach-Object{
    # --------------------------------------------------------------------------------------------------------
    # Actually, we need some kind of magic here! As we are in a remote ps-session, we cannot directly convert 
    # the serialized value into bytes to show as GB... so the magic must happen!
    # --------------------------------------------------------------------------------------------------------
  Write-Progress -Activity $_.Identity -PercentComplete ([math]::round(100/$Mailboxes.Count * $processed))
  $UsageMB = [math]::round( (Get-MailboxStatistics -Identity $_.Identity).TotalItemSize.Value.toString().Split("(")[1].split(" ")[0].replace(",","")/1MB )
  $table += [PSCustomObject]@{Email=$_.PrimarySmtpAddress; Usage=$UsageMB}
  $processed += 1

}


# Showing the results...
$table | Sort-Object -Property UsageMB -Descending | Out-GridView

Remove-PSSession $Session
