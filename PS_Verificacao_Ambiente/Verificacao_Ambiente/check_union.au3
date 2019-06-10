#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=C:\scripts\Verificacao_Ambiente\check_union.exe
#AutoIt3Wrapper_Res_Description=Executa a verificação de funcionamento (executa e realiza login) do projetc union.
#AutoIt3Wrapper_Res_ProductName=CheckUnion
#AutoIt3Wrapper_Res_CompanyName=Via3 Consulting Consultoria em Gestao e TI
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;Region GlobalVariables
Local $unionUser = "leitor"
Local $unionPassword = "leitor"

;Region Functions

; -------------------------------------------------------------------------------------------------
; Function DieWithError
; Purpose: Exit cleanly the script
; Argument: Program PID/Handle
; Output: N/A
; -------------------------------------------------------------------------------------------------
Func DieWithError($uProc)
	ProcessClose($uProc)
	Exit 1
EndFunc
#EndRegion


#Region Global Variables
Local $iWaitResult

#EndRegion

;--------------------------------------------------------------------------------------------------
; Executar o union e aguardar tela de login
;--------------------------------------------------------------------------------------------------
Local $iUnionProc = Run("C:\ProjectUnion\ProjectUnion.exe")
$iWaitResult = WinWait("Login","", 60)
If($iWaitResult = 0) Then
	DieWithError($iUnionProc)
EndIf


;--------------------------------------------------------------------------------------------------
; Enviar usuário e senha, clicar em Login
;--------------------------------------------------------------------------------------------------
ControlSetText("Login","","[CLASS:TEdit; INSTANCE:2]", $unionUser)
ControlSetText("Login","","[CLASS:TEdit; INSTANCE:1]", $unionPassword)
ControlClick("Login","", "[CLASS:TBitBtn; INSTANCE:2]")


;--------------------------------------------------------------------------------------------------
;Aguardar tela de seleção de empresa. Selecionar empresa padrão (clicar em Selecionar).
;--------------------------------------------------------------------------------------------------
$iWaitResult = WinWait("Seleção da Organização","",30)
If($iWaitResult = 0) Then
	DieWithError($iUnionProc)
EndIf
Sleep(1000)
ControlClick("Seleção da Organização","","[CLASS:TBitBtn; INSTANCE:3]")
Sleep(1000)


;--------------------------------------------------------------------------------------------------
; Aguardar tela principal do union.
;--------------------------------------------------------------------------------------------------
$iWaitResult = WinWait("Project Union - Plataforma de Comunicação e Colaboração de Projetos","",30)
If($iWaitResult = 0) Then
	DieWithError($iUnionProc)
EndIf


;--------------------------------------------------------------------------------------------------
; Encerra o union - ja fomos longe demais... ;)
;--------------------------------------------------------------------------------------------------
; Fechando a janela principal
Local $iHndTarget = WinGetHandle("Project Union - Plataforma de Comunicação e Colaboração de Projetos","")
WinClose($iHndTarget)

; Primeira caixa de confirmação
$iWaitResult = WinWait("Confirmar","",30)
If($iWaitResult = 0) Then
	DieWithError($iUnionProc)
EndIf
ControlClick("Confirmar","","[CLASS:TButton; INSTANCE:2]")

; Segunda caixa de confirmação
$iWaitResult = WinWait("Confirmar","",30)
If($iWaitResult = 0) Then
	DieWithError($iUnionProc)
EndIf
ControlClick("Confirmar","","[CLASS:TButton; INSTANCE:2]")
Exit 0