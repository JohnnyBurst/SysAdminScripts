<#
SCRIPT TO BACKUP PFSENSE FIREWALL WEBCONFIG

.DESCRIPTION
    Generate a .xml backup from webconfig.

.SYNOPSYS
    Generate a .xml backup from webconfig.

.EXAMPLE
	.\PS_Backup_pfSense_Configuration -destination C:\backup -server 192.168.0.1 -user admin -password P4ssw0rd -UseSSL
#>


Param(
    [Parameter(Mandatory=$false)] [string] $destination = "$pwd",
    [Parameter(Mandatory=$true)]  [string] $server = "",
    [Parameter(Mandatory=$true)]  [string] $user = "",
    [Parameter(Mandatory=$true)]  [string] $password = "",
    [Parameter(Mandatory=$false)] [switch] $UseSSL
)


#
# Preferences
#
$DebugPreference = "Continue"



#
# path to save the backup file
#
Write-Debug "saving file to dir: $destination"



#
# HTTP Schema
#
If($UseSSL)
{
    $schema = "https://"
}else{
    $schema = "http://"
}



#
# base uri
#
$baseuri   = $schema + $server
$backupuri = $baseuri + "/diag_backup.php"


Write-Debug "base uri: $baseuri"
Write-Debug "backup uri: $backupuri"



#
# Initial request to landing page
#
try{
    $req = invoke-webrequest -Uri $baseuri -Method GET -SessionVariable 'websess'
}catch{
    Write-Error "Error requesting initial landing page."
    Throw $_
}


# Filling login formdata
$logindata = @{
	usernamefld  = $user;
	passwordfld  = $password;
	login        = "Sign+In";
	__csrf_magic = $req.InputFields.FindByName("__csrf_magic").Value
}



#
# Sending login form
#
try{
    $req = invoke-webrequest -Uri $baseuri -Method POST `
        -WebSession $websess -Body $logindata -ContentType 'application/x-www-form-urlencoded'
}catch{
    Write-Error "Error sending login form data."
    Throw $_
}



#
# Extracting last _csrf token
#
$token = $req.InputFields.FindByName("__csrf_magic").Value
Write-Debug "extracted _csrc token: $token"


# Request backup file
try{
    $req = Invoke-WebRequest -Uri $backupuri -Method POST  `
        -ContentType 'multipart/form-data; boundary=---------------------------3203714523379' `
        -WebSession $websess -Body @"
-----------------------------3203714523379
Content-Disposition: form-data; name="__csrf_magic"

$token
-----------------------------3203714523379
Content-Disposition: form-data; name="backuparea"


-----------------------------3203714523379
Content-Disposition: form-data; name="donotbackuprrd"

yes
-----------------------------3203714523379
Content-Disposition: form-data; name="encrypt_password"


-----------------------------3203714523379
Content-Disposition: form-data; name="download"

Download configuration as XML
-----------------------------3203714523379
Content-Disposition: form-data; name="restorearea"


-----------------------------3203714523379
Content-Disposition: form-data; name="conffile"; filename=""
Content-Type: application/octet-stream


-----------------------------3203714523379
Content-Disposition: form-data; name="decrypt_password"


-----------------------------3203714523379--
"@
}catch{
    Write-Error "Error requesting backup file"
    Throw $_
}



#
# Saving the downloaded .xml file
#
try{
    $filename = $req.Headers.'content-disposition'.split(";")[1].split("=")[1]
    Write-Debug "filename from headers: $filename"
    $filepath = Join-Path -Path $destination -ChildPath $filename
    [System.Text.Encoding]::UTF8.GetString($req.Content) | Out-File -FilePath $filepath -Encoding utf8
}catch{
    Write-Error "Erro salvando o arquivo de backup"
    Throw $_
}

