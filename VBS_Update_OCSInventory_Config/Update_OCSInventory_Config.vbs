' ----------------------------------------------------------------------------------
' Via3 Consulting - Consultoria em Gestao e TI
' Script para atualizar o arquivo de configura��o do OCS Inventory
' Autor: luciano.rodrigues@v3c.com.br
' Data: 11/07/2019  Vers�o: 1.0 release inicial
' ----------------------------------------------------------------------------------
'On Erro Resume Next
'Option Explicit


' --------------------------------------------------------------------------------------
' Criando os objetos de acesso ao shell e filesystem
' --------------------------------------------------------------------------------------
Set wshShell = CreateObject("WSCript.Shell")
Set Wmi = GetObject("winMgmts:{ImpersonationLevel=Impersonate}!\\.\root\cimv2")
Set objFSO = CreateObject("Scripting.FileSystemObject")



' --------------------------------------------------------------------------------------
' Parando o servi�o do OCS inventory para poder sobrescrever o arquivo de configura��o.
' --------------------------------------------------------------------------------------
command = "cmd /c net stop " & chr(34) & "OCS Inventory Service" & chr(34)
wshSHell.Run command, 1, 1
WScript.Sleep(2000)

Set services = Wmi.ExecQuery("Select * from WIn32_Service where name='ocs inventory service' and State='Stopped'")
If services.Count <> 1 Then
    WSCript.Echo "[!] Erro ao parar o servi�o do OCS Inventory."
    WScript.Quit
Else
    WSCript.Echo "Servi�o parado com sucesso!"
End If



' --------------------------------------------------------------------------------------
' Copiando o arquivo de configura��o do servidor para a esta��o.
' --------------------------------------------------------------------------------------
config_path_network = "\\UTLBHHOST1\ocs-tmp$\ocsinventory.ini"
config_path_local = "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini"

' deleta o arquivo de configura��o local da maquina
If objFSO.FileExists(config_path_local) Then
    objFSO.DeleteFile config_path_local, True
    If Not objFSO.FileExists(config_path_local) Then
        WScript.Echo "Arquivo de configura��o antigo deletado com sucesso!"
    Else
        WScript.Echo "[!] Erro ao deletar arquivo de configura��o antigo."
        WScript.Quit
    End If
Else
    WScript.Echo "[!] Erro, arquivo de configura��o local n�o encontrado."
    WScript.Quit
End If


' copiando da rede para a maquina o arq. de configura��o.
objFSO.CopyFile config_path_network, config_path_local, True
If objFSO.FileExists(config_path_local) Then
    WScript.Echo "Arquivo de configura��o copiado com sucesso!"
Else
    WScript.Echo "[!] Erro ao copiar o arquivo de configura��o."
    WScript.Quit
End If



' --------------------------------------------------------------------------------------
' Iniciando novamente o servi�o do OCS.
' --------------------------------------------------------------------------------------
command = "cmd /c net start " & chr(34) & "ocs inventory service" & chr(34)
wshShell.Run command, 1, 1
WScript.Sleep(2000)

Set services = Wmi.ExecQuery("Select * from Win32_Service where name='Ocs Inventory Service' and State='Running'")
If services.Count <> 1 Then
    WSCript.Echo "[!] Erro ao iniciar o servi�o do OCS Inventory."
    WScript.Quit
Else
    WSCript.Echo "Servi�o iniciado com sucesso!"
End If




