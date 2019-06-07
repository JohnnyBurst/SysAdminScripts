# --------------------------------------------------------------------------------------------------------
# Script para listar utilização de caixas de e-mail do exchange online (office 365).
# via3lr - luciano.rodrigues@v3c.com.br
# Usage: Invoque este script passando usuário e senha do administrador do office365 
# do cliente.
# Exemplo: powershell -file PS_Get_Mailboxes_Statistics.ps1 ti@cliente.com.br ClienteSenhaSuperSegura
# --------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------
# Parametros globais do script
# --------------------------------------------------------------------------------------------------------
Param(
    [Parameter(Mandatory=$True)] [string]$AdminUser,
    [Parameter(Mandatory=$True)] [string]$AdminPass
)


# --------------------------------------------------------------------------------------------------------
# Compilando usuário e senha recebidos como uma credencial segura
# --------------------------------------------------------------------------------------------------------
$user = $AdminUser
$pass = ConvertTo-SecureString -AsPlainText -Force $AdminPass
$UserCredential = New-Object System.Management.Automation.PSCredential($user, $pass)


# --------------------------------------------------------------------------------------------------------
# Conectando a uma sessão do exchange online
# --------------------------------------------------------------------------------------------------------
try{
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
    Import-PSSession $Session
}catch{
    Write-Host -ForegroundColor RED "Erro ao conectar ao Exchange Online. Encerrando o script."
    Write-Host $_.Exception.Message
    Exit
}

# --------------------------------------------------------------------------------------------------------
# Obtendo as caixas de e-mail e as estatísticas
# --------------------------------------------------------------------------------------------------------
Write-Host "Getting Mailboxes..."
$Mailboxes = Get-MailBox

$table = @()

Write-Host "Getting Statistics..."

$processed = 0
$Mailboxes | %{
    # --------------------------------------------------------------------------------------------------------
    # Obtem a caixa de e-mail e o campo TotalItemSize
    # É necessário converter o campo TotalItemSize para conseguirmos 
    # --------------------------------------------------------------------------------------------------------
  Write-Progress -Activity $_.Identity -PercentComplete ([math]::round(100/$Mailboxes.Count * $processed))
  $UsageMB = [math]::round( (Get-MailboxStatistics -Identity $_.Identity).TotalItemSize.Value.toString().Split("(")[1].split(" ")[0].replace(",","")/1MB )
  $table += [PSCustomObject]@{Email=$_.PrimarySmtpAddress; Usage=$UsageMB}
  $processed += 1

}


$table | Sort-Object -Property UsageMB -Descending | Out-GridView
