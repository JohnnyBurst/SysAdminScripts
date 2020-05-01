:: ------------------------------------------------------------------------|
:: Script to backup MSSQL Databases.
:: @autor: luciano.grodrigues@live.com
:: @date: 27/02/2020	@versão 1.0
:: ------------------------------------------------------------------------|
:: How this scripts works:
:: It deletes the local temporary folder contents.
:: It gets the datetime used to name the output file.
:: Remove possibles left over files from last run.
:: For Each Database: connects to remote sql server and issue a backup command
:: the backup is pointed to a temporary folder shared by local computer as 'TMP$'
::
:: ------------------------------------------------------------------------|
@echo off


::
:: Adjustable variables
::
SET TMPPATH=D:\TMP
SET SQLSERVER=DBSERVER01
SET SQLUSER=sa
SET SQLPASS=P4ssw0rd
SET DATABASES=KAV ADVWIN MASTER
SET THISERVER=
for /f %%i in ('cmd /c hostname') do @SET THISERVER=%%i




:: -----------------------------------------------------------------------
::
:: Getting datetime using external powershell
::
:: -----------------------------------------------------------------------
SET FILEDATE=
for /f "usebackq" %%i in (`powershell -c get-date -format 'yyyyMMddHHmm'`) do SET FILEDATE=%%i




:: -----------------------------------------------------------------------
::
:: Remove folders and files from older backup
::
:: -----------------------------------------------------------------------
DEL /Q /S %TMPPATH%\*.*
forfiles /p %TMPPATH% /c "cmd /c rmdir /q /s @path"



:: -----------------------------------------------------------------------
::
:: Creating the timestamped folder to backup to
::
:: -----------------------------------------------------------------------
mkdir %TMPPATH%\%FILEDATE%




:: ------------------------------------------------------------------------
::
:: Hard Work goes here
:: Iterate on given database names, then for each one connects to remote
:: sql server and backup database pointing to a local temporary shared folder.
:: Note: The temporary share need to be hidden, see below.
:: Note2: The temporary share need to be given write permission to the remote 
:: sql server computer account. something like account name: SQL1$
::
:: -----------------------------------------------------------------------
FOR %%I IN (%DATABASES%) do (
    echo Backing up %%I
    winrs -r:%SQLSERVER% sqlcmd -U %SQLUSER% -P %SQLPASS% -Q "SET NOCOUNT ON BACKUP DATABASE [%%I] TO DISK='\\%THISERVER%\TMP$\%FILEDATE%\%%I.BAK'"
)


exit /b %errorlevel%

