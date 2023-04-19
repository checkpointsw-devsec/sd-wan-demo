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

function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)   
}

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
# set sic
# ##########################################################
$Body= @{ 
    "name"               =$gateway_name 
    "one-time-password"  =$sickey
    "version"            =$version
}
Invoke-RestMethod -Method Post -Uri "$URL/set-simple-gateway" -ContentType 'application/json' -Headers $Headers -Body ($Body|ConvertTo-Json)


# ##########################################################
# publish changes
# ##########################################################
$Body= @{ 
}
$taskid=(Invoke-RestMethod -Method Post -Uri "$URL/publish" -ContentType 'application/json' -Headers $Headers -Body ($Body|ConvertTo-Json)).'task-id'

# ##########################################################
# wait for publish befor logout
# ##########################################################
$Body = @{
    "task-id" = "$taskid"
}
$status =''
while ($status -eq '') {
    Start-Sleep -s 5
    $TaskStatusArr=(Invoke-RestMethod -Method Post -Uri "$URL/show-task" -ContentType "application/json"  -Headers $Headers  -Body ($Body|ConvertTo-Json))
    $task = $TaskStatusArr.tasks | Where-Object { $_.'task-id' -eq $taskid }
    $status=$task.status
    write-host "$(Get-TimeStamp) publish status: " $status
    if ($status -ne 'succeeded') { $status = ''}
}

# ##########################################################
# logout
# ##########################################################
$Body= @{ 
}
Invoke-RestMethod -Method Post -Uri "$URL/logout" -ContentType 'application/json' -Headers $Headers -Body ($Body|ConvertTo-Json)

# ##########################################################
# Install policy
# ##########################################################
#$Body= @{ 
#    "policy-package"    = "Standard"
#    "targets"           = $gateway_name
#    "access"            = "True"
#    "threat-prevention" = "false"
#}
#Invoke-RestMethod -Method Post -Uri "$URL/install-policy" -ContentType 'application/json' -Headers $Headers -Body ($Body|ConvertTo-Json)



