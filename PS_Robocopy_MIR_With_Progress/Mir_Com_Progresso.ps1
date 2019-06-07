
Write-Host @"
# ------------------------------------------------------------------------------------
# Script para copia de arquivos (Mirroring) com progresso
# ------------------------------------------------------------------------------------
"@

$pastas = @()

$Origem = $args[0]
$Destino = $args[1]

$pastas += $Origem

[Long] $TotalFiles = 0
[Long] $JaCopiados = 0

Write-Host @"
# ------------------------------------------------------------------------------------
# Escaneando arquivos
# Origem: $Origem
# Destino: $Destino
# ------------------------------------------------------------------------------------
"@
ForEach( $pasta in $pastas)
{
	
    Write-Host -ForegroundColor Yellow "`r`nEscaneando $Origem"
	$robocopy = Robocopy "$Origem" "$Destino" /MIR /NDL /NFL /NC /NP /R:0 /L
	
	#
	$Robocopy | %{if($_ -match 'Files :\s+(\d+)\s+(\d+)\s+\d+\s+\d+\s+(\d+)\s+\d+'){
        $Total = $Matches[1]
        $Copiados = $Matches[2]
        $Erros = $Matches[3]

        Write-Host "Arquivos: $($Matches[1])"
		
		$TotalFiles += $Copiados
     }}
}


Write-Host @"
`r`n
# ------------------------------------------------------------------------------------
# STATUS
# Arquivos para copiar: $TotalFiles
# ------------------------------------------------------------------------------------
"@


Write-Host @"
`r`n
# ------------------------------------------------------------------------------------
# COPIANDO OS ARQUIVOS
# ------------------------------------------------------------------------------------
"@
Write-Host "Iniciando copia..."
ForEach( $pasta in $pastas)
{
	
    Write-Host -ForegroundColor Yellow "`r`nCopiando Pasta $Origem"
	Start-Job -Name "$pasta" -ScriptBlock {Robocopy "$using:Origem" "$using:Destino" /MIR /NDL /R:0 } | out-null

	
	While($True)
	{
		# Obtendo status do job
		Start-Sleep 5


        If( (get-job "$pasta").state -eq "Completed" )
        {
            $files = ( (receive-job "$pasta" ) -match 'New File').count
            $JaCopiados += $files
            $progress = [Math]::Round( [float]( 100 / $TotalFiles) * $JaCopiados )
            Write-Host "$(Get-Date -format 's') Copiados $progress`%"
			Remove-Job -force "$pasta"
			Break
        }else{
            #Write-Host "job $pasta still running"
            $files = ( (receive-job "$pasta" ) -match 'New File').count
            $JaCopiados += $files
            $progress = [Math]::Round( [float]( 100 / $TotalFiles) * $JaCopiados )
            Write-Host "$(Get-Date -format 's') Copiados $progress`%"
            
        }

	
	}

}

Write-Host @"
`r`n
# ------------------------------------------------------------------------------------
# COPIA TERMINADA
# Arquivos escaneados: $TotalFiles
# Arquivos copiados  : $JaCopiados
# ------------------------------------------------------------------------------------
"@

