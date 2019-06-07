# --------------------------------------------------------------------------------------------------------
# Script para Iniciar o arquivamento da caixa de e-mail.
# via3lr - luciano.rodrigues@v3c.com.br
# --------------------------------------------------------------------------------------------------------

# Script Parameters
Param(
    [Parameter(Mandatory=$True)] [string]$AdminUser,
    [Parameter(Mandatory=$True)] [string]$AdminPass,
    [Parameter(Mandatory=$True)] [string]$mailbox
)



# --------------------------------------------------------------------------------------------------------
# Compilando usuário e senha recebidos como uma credencial segura
# --------------------------------------------------------------------------------------------------------
$pass = ConvertTo-SecureString -AsPlainText -Force $AdminPass
$UserCredential = New-Object System.Management.Automation.PSCredential($AdminUser, $pass)


# --------------------------------------------------------------------------------------------------------
# Conectando a uma sessão do exchange online
# --------------------------------------------------------------------------------------------------------
try{
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $UserCredential -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}catch{
    Write-Host -ForegroundColor RED "Erro ao conectar ao Exchange Online. Encerrando o script."
    Write-Host $_.Exception.Message
    Exit
}

Start-ManagedFolderAssistant -Identity $mailbox