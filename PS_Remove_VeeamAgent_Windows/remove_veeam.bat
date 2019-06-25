@echo off
title REMOVENDO VEEAM BACKUP WINDOWS AGENT
echo '-----------------------------------------------------------------------------
echo ' VIA3 CONSULTING - CONSULTORIA EM GESTAO E TI
echo '-----------------------------------------------------------------------------
echo.

echo Removendo Veeam Agent for Microsoft Windows
WMIC PRODUCT WHERE "Caption='Veeam Agent for Microsoft Windows'" CALL UNINSTALL >nul

echo Removendo Microsoft SQL Server 2012 Express LocalDB
WMIC PRODUCT WHERE "Caption='Microsoft SQL Server 2012 Express LocalDB'" CALL UNINSTALL >nul

echo Removendo Microsoft SQL Server 2012 Management Objects 
WMIC PRODUCT WHERE "Caption='Microsoft SQL Server 2012 Management Objects  (x64)'" CALL UNINSTALL >nul


echo Removendo Microsoft System CLR Types for SQL Server
WMIC PRODUCT WHERE "Caption='Microsoft System CLR Types for SQL Server 2012 (x64)'" CALL UNINSTALL >nul
echo.


echo TERMINADO
pause>nul



