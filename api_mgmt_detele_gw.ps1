param (
    [Parameter(Mandatory=$true)][string] $gateway_name ,
    [Parameter(Mandatory=$true)][string] $mgmt_api_key,
    [Parameter(Mandatory=$true)][string]$smartoneInstance ,
    [Parameter(Mandatory=$true)][string]$smartoneContext ,
    [Parameter(Mandatory=$true)][string]$sickey,
    [Parameter(Mandatory=$true)][string]$version  
)

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# ##########################################################
# main URL
# ##########################################################
$URL = "https://"+$smartoneInstance+".maas.checkpoint.com/"+$smartoneContext+"/web_api/"

# ##########################################################
# authenticate and get token for all following API Calls
# ##########################################################
$Body=@{  "api-key" = $mgmt_api_key   }

$sid=((Invoke-RestMethod -Method Post  -Uri "$URL/login" -ContentType 'application/json' -Body ($Body|ConvertTo-Json)).sid)
$Headers=@{  
    'X-chkp-sid'=$sid 
}

# ##########################################################
# delete Gateway
# ##########################################################
$Body= @{ 
    "name"               =$gateway_name 
}
Invoke-RestMethod -Method Post -Uri "$URL/delete-simple-gateway" -ContentType 'application/json' -Headers $Headers -Body ($Body|ConvertTo-Json)


# ##########################################################
# publish changes
# ##########################################################
$Body= @{ 
}
Invoke-RestMethod -Method Post -Uri "$URL/publish" -ContentType 'application/json' -Headers $Headers -Body ($Body|ConvertTo-Json)

# ##########################################################
# logout
# ##########################################################
$Body= @{ 
}
Invoke-RestMethod -Method Post -Uri "$URL/logout" -ContentType 'application/json' -Headers $Headers -Body ($Body|ConvertTo-Json)





