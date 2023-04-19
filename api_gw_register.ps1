param (
     [Parameter(Mandatory=$false)][string]$gateway ,
     [Parameter(Mandatory=$true)][string]$clientid ,
     [Parameter(Mandatory=$true)][string]$secretkey ,
     [Parameter(Mandatory=$true)][string]$command 
)

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#$clientid = 'b19cb4560878480fb1091ab332a7eb74'
#$password = '000196b1c7944ee4a96773d85691c122'
# ##########################################################
# main URL
# ##########################################################
$global:URL = "https://cloudinfra-gw.portal.checkpoint.com" 

$global:gateway= "$gateway"
$authURL="$URL/auth/external"
$GatewaysURL="$URL/app/maas/api/v1/gateways"
$del_gatewayURL="$URL/app/maas/api/v1/gateways/"+$global:gateway+"?deleteObjectFromConfiguration=true"

# ##########################################################
# authenticate and get token for all following API Calls
# ##########################################################
$Body=@{  
        "clientId"  = $clientid
        "accessKey" = $secretkey 
}


$global:token=((Invoke-RestMethod -Method Post -ContentType 'application/json' -Uri $authURL -Body ($Body|ConvertTo-Json)).data.token)

$global:Headers=@{  'Authorization' = "Bearer $global:token" }

# ##########################################################
# three possible cases: show_all, register, delete
# ##########################################################
function showall {
    $Body= @{  }

    $response=(Invoke-RestMethod -Method Get -ContentType "application/json" -Uri $GatewaysURL -Headers $global:Headers -Body $Body)
    Write-Host $response
    #foreach ($gateway in ($response | ConvertFrom-Json)) {
    #    write-host "$($gateway.name) , $($gateway.statusDetails)"
    #}   
}

function reg_gw {
    if ($global:gateway -ne '') {
        $Body= @{  }
        $Body = @"
        {
            "name": "$global:gateway",
            "description": "Marketing Branch Gateway"
}
"@
        $response=(Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $GatewaysURL -Headers $global:Headers -Body $Body).data.token
        $response | Out-File -FilePath "$PSScriptRoot\maas_token.txt" -Encoding ASCII  -NoNewline
    }
    else {
        write-Host "The Gateway name is required, please specify the -n flag."
    }
}

function del_gw {
    if ($global:gateway -ne '') {
        $Body= @{  }
        $response=(Invoke-RestMethod -Method DELETE -ContentType "application/json" -Headers $global:Headers  -Uri $del_gatewayURL -Body $Body)
        write-host $response.text
    }
    else {
        write-Host "The Gateway name is required, please specify the -n flag." 
    }
}


switch ($command) {        
    show_all { showall }
    register { reg_gw }
    delete { del_gw }
    Default {}
}

