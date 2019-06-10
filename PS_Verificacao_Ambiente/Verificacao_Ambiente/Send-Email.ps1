##############################################################################
#  Script: Send-EMail.ps1
#    Date: 7.Sept.2007
# Version: 1.3
#  Author: Jason Fossen (www.WindowsPowerShellTraining.com)
# Purpose: Send e-mail using SMTP or SMTPS.
#   Notes: If multiple addresses to the addressing fields, separate with commas.
#          Use the -useintegrated switch to use NTLM or Kerberos with the
#          credentials of the person running the script.  If you add an 
#          attachment, you must specify full path to file.
#   Legal: Script provided "AS IS" without warranties or guarantees of any
#          kind.  USE AT YOUR OWN RISK.  Public domain, no rights reserved.
##############################################################################

Function Send-Email {
    Param(
		[Parameter(Mandatory=$True)][string]$To, 
		[Parameter(Mandatory=$True)][string]$Subject, 
		[Parameter(Mandatory=$True)][string]$Body,
		[Parameter(Mandatory=$False)][string[]]$Attachments
	)

   # Write-Host "Sending E-mail to $To`nSubject $Subject`n`n$Body"

    $mail = New-Object System.Net.Mail.MailMessage
    $mail.To.Add($to)       
    $mail.From = "user@gmail.com"   
    
    $mail.IsBodyHtml = $true 
    $mail.Body = $body
    $mail.Subject = $subject
	
	foreach($anexo in $attachments)
	{
		If(! (Test-Path $anexo) ){ Write-Host "Erro ao anexar arquivo $anexo"; Continue}
		$mail.Attachments.Add($anexo)
	}
    
    $smtpclient = new-object System.Net.Mail.SmtpClient
    $smtpclient.Host = "smtp.outlook.com"
    $smtpclient.Timeout = 30000  #milliseconds

    $smtpclient.EnableSSL = $true
    $smtpclient.Port = 587

    $smtpclient.Credentials = new-object System.Net.NetworkCredential("user@gmail.com", "securepassword") 
 
    $smtpclient.Send($mail)
   
}
           
          