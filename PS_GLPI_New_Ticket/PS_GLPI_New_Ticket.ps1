
#
# Inicializando bibliotecas externas
#
Add-Type -AssemblyName "System.Windows.Forms"


#
# Global Constants
#
$GLPI_URI = "http://suporte.v3c.com.br"
$GLPI_USER = "glpiuser"
$GLPI_PASSWORD = "glpipassword"

$global:csrf_token = $null
$global:websession = $null



#
# URI of importante pages
#
$landing_uri   = "$GLPI_URI/index.php"
$login_uri     = "$GLPI_URI/front/login.php" 
$newticket_uri = "$GLPI_URI/front/ticket.form.php"



#
# Sets the current _csrf_token
#
Function SetCsrfToken
{
    Param(
        [Parameter(Mandatory)] [string] $token
    )
    $global:csrf_token = $token
    Write-Host "Setting csrf_token to " $global:csrf_token
}



#
# Gets the current _csrf_token
#
Function GetCsrfToken
{
    Return $global:csrf_token
}

Function DoGLPILogin
{

    #
    # Retrieving the login form page
    #
    try{
        Write-Host "Retrieving GLPI landing page"
        $request = Invoke-WebRequest -Uri $landing_uri -SessionVariable 'websession' -Method Get -EA Stop
        $global:websession = $websession
    }catch{
        Throw $_
    }



    #
    # Getting the form random field names
    #
    $username_field_name = $request.InputFields.FindById("login_name").name
    Write-Host "username_field " $username_field_name
    $password_field_name = $request.InputFields.FindById("login_password").name
    Write-Host "password_field " $password_field_name
    


    #
    # Getting the CSRF_TOKEN data
    #
    $_csrf_token = $request.InputFields.FindByName("_glpi_csrf_token").value
    SetCsrfToken $_csrf_token
    Write-Host "csrf_token " $_csrf_token



    #
    # Preparing formdata to be submitted
    #
    $form_data = @{
        $username_field_name = $GLPI_USER
        $password_field_name = $GLPI_PASSWORD
        "_glpi_csrf_token"     = GetCsrfToken
    }



    #
    # Submit login form
    #
    $request = Invoke-WebRequest -Uri $login_uri -Method Post -ContentType "application/x-www-form-urlencoded" `
        -WebSession $global:websession -Body $form_data
    
    
    
    #
    # Checking if successful login
    #
    If( $request.Content -match 'GLPI - Acesso negado' )
    {
        # Bad Login
        Write-Host "Error logging on GLPI. Check USERNAME and PASSWORD"
        Return $false
    }else{
        # Setting the csrf_token
        SetCsrfToken $request.InputFields.FindByName("_glpi_csrf_token").Value
        Return $true
    }

    # Debug
    #$request.Content | Out-File file1.html; .\file1.html


}

if( DoGLPILogin )
{
    Write-Host "Successful login to GLPI"
}else{
    Write-Host "Error login to GLPI"
    Exit
}



Function CreateTicket
{

    #
    # Building necessary headers
    #
    $headers = New-Object System.Collections.Generic.Dictionary"[[string], [string]]"
    $headers.Add("Referer", "$GLPI_URI/front/ticket.form.php")
    

    #
    # Building content data
    #
    $ticket_data = @{
        "_date" = Get-Date -Format 'dd-MM-yyyy HH:mm'  #18-02-2020 20:59
        "date"  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'  #2020-02-18 20:59:30
        "_time_to_own" = "" 
        "time_to_own" = ""
        "slas_tto_id" = 0
        "_time_to_resolve" = "" 
        "time_to_resolve" = "" 
        "slas_ttr_id" = 0
        "_internal_time_to_own" = "" 
        "internal_time_to_own" = "" 
        "_internal_time_to_resolve" = ""
        "internal_time_to_resolve" = ""
        "olas_ttr_id" = 0
        "type"  =  2  # 2 for Request, 1 for incident
        "itilcategories_id" = 5  # Gerenciamento e Suporte
        "_users_id_requester" = 728   # via3lr requester
        "_users_id_requester_notif[use_notification][]" = 0  # nao notificar por email. 1 => notificar
        "_users_id_requester_notif[alternative_email][]" = "myemail@corp.com"  # solicitante email
        "entities_id" = 57   # abiackel
        "_users_id_observer[]" = 0   # no observers
        "_users_id_observer_notif[use_notification][]" = 1   # notify observers
        "_users_id_assign" = 728 # atribuido para
        "_users_id_assign_notif[use_notification][]" = 0  # notificar user atribuido?
        "_users_id_assign_notif[alternative_email][]" = "myemail@corp.com"  # email user atribuido
        "_groups_id_assign" = 0
        "status" = 1  # status novo
        "requesttypes_id" = 1  # requested from helpdesk website
        "urgency" = 3  # default urgency
        "impact" = 3   # default impact
        "_add_validation" = 0
        "validatortype" = 0
        "locations_id" = 0  # default location
        "priority" = 3   # default priority
        "my_items" = ""
        "itemtype" = 0
        "items_id" = 0
        "actiontime" = 0
        "name" = "My Custom Ticket"  # ticket title
        "content" = "My Custom Description Ticket"   # ticket description
        "_link[link]" =  1
        "_link[tickets_id_1]" = 0
        "_link[tickets_id_2]" = 0
        "filename[]" = ""
        "add" = "Adicionar"   # name of add button
        "_tickettemplates_id" = 1  # default ticket template
        "_predefined_fields" = "eyJpdGlsY2F0ZWdvcmllc19pZCI6IjUifQ=="
        "id" = 0
        "_glpi_csrf_token" = GetCsrfToken
    }

    $body = @"
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_date"

$($ticket_data._date)
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="date"

$($ticket_data.date)
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_time_to_own"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="time_to_own"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="time_to_own"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="slas_tto_id"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="slas_tto_id"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_time_to_resolve"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="time_to_resolve"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="time_to_resolve"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="slas_ttr_id"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="slas_ttr_id"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_internal_time_to_own"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="internal_time_to_own"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="internal_time_to_own"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_internal_time_to_resolve"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="internal_time_to_resolve"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="internal_time_to_resolve"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="olas_ttr_id"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="type"

2
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="itilcategories_id"

5
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_users_id_requester"

$($ticket_data._users_id_requester)
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_users_id_requester_notif[use_notification][]"

1
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_users_id_requester_notif[alternative_email][]"

luciano.rodrigues@v3c.com.br
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="entities_id"

$($ticket_data.entities_id)
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_users_id_observer[]"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_users_id_observer_notif[use_notification][]"

1
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_users_id_observer_notif[alternative_email][]"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_users_id_assign"

$($ticket_data._users_id_assign)
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_users_id_assign_notif[use_notification][]"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_users_id_assign_notif[alternative_email][]"

luciano.rodrigues@v3c.com.br
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_groups_id_assign"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="status"

1
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="requesttypes_id"

1
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="requesttypes_id"

1
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="urgency"

3
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="urgency"

3
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_add_validation"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="validatortype"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="impact"

3
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="impact"

3
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="locations_id"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="priority"

3
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="priority"

3
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="my_items"


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="itemtype"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="items_id"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="actiontime"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="actiontime"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="name"

titulo teste
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="content"

descricao teste
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_link[link]"

1
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_link[tickets_id_1]"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_link[tickets_id_2]"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="filename[]"; filename=""
Content-Type: application/octet-stream


------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="add"

Adicionar
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_tickettemplates_id"

1
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_predefined_fields"

eyJpdGlsY2F0ZWdvcmllc19pZCI6IjUifQ==
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="id"

0
------WebKitFormBoundaryzCn5JWK10xZoixBS
Content-Disposition: form-data; name="_glpi_csrf_token"

$($ticket_data._glpi_csrf_token)
------WebKitFormBoundaryzCn5JWK10xZoixBS--
"@

    $request = Invoke-WebRequest -Uri $newticket_uri -Method Post -WebSession $global:websession `
        -ContentType "multipart/form-data; boundary=----WebKitFormBoundaryzCn5JWK10xZoixBS" `
        -Body $body -Headers $headers -Verbose 

    
    If( $request.Content -match "<a href='/front/ticket.form.php\?id=(\d+)'>\d+</a>" )
    {
        Write-Host "Registrado Chamado "  $Matches[1] " com sucesso!"
    }Else{
        Write-Host -Foreground RED "Erro ao Registrar Chamado"
        $request.Content | Out-file file1.html; .\file1.html
    }


    
    
}


CreateTicket