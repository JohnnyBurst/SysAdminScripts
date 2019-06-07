# ---------------------------------------------------------------------------------------
# Script para notificar via e-mail quando eventos de badlogon ocorrer em servidores de RDP
# Autor: luciano.rodrigues@v3c.com.br
# ---------------------------------------------------------------------------------------
# Este script deve ser configurado para ser executado pelo agendador de tarefas do windows
# Quando o evento com ID 4625 ocorrer.
# O Script vai obter os dados do último evento de falha de login e enviar por e-mail para
# que a TI seja capaz de auditar o acesso.


# Event Ids
# 4624 - logon successful
# 4625 - logon error

# logontypes
# 2 local logon interactive
# 3 network logon (printer, shares, nla)
# 10 logon throug rdp

# Dot sourcing script com funcao de envio de email.
. C:\scripts\send_email.ps1

# Obtendo o ultimo evento de erro de logon, que muito provavelmente vai ser o que gerou o evento... muito provavelmente haha
$LastEvent = Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=4625]] and *[EventData[Data[@Name='LogonType'] and (Data=2 or Data=3 or Data=10)]]" -Max 1

# Construindo o corpo html do email
$content = @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Security Event Notice</title>
</head><body>
<pre><strong>Foi detectado um evento de erro de logon (bad password), o que pode indicar uma tentativa de invasão!</strong></pre>
<br/>
Detalhes do evento:
<table border="1" cellspacing="0" cellpadding="5">
<tr><td>Data do evento</td><td> $(Get-Date $LastEvent.TimeCreated -Format 'dd/MM/yyyy HH:mm')</td></tr>
<tr><td>Computador</td><td> $($LastEvent.MachineName)</td></tr>
<tr><td>Palavras chave</td><td> $($LastEvent.KeywordsDisplayNames)</td></tr>
</table>
<br/>
Mensagem: 
<hr/>
<pre>$($LastEvent.Message)</pre>
</body></html>
"@

# Enviando o e-mail com as informações do evento
Send-Email -To luciano.rodrigues@v3c.com.br -Subject "[Security Event]" -Body $content


