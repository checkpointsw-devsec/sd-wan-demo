//#PLEASE refer to the README.md for accepted values FOR THE VARIABLES BELOW
client_secret                   = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"                         
client_id                       = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"                         
tenant_id                       = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"                         
subscription_id                 = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"  
source_image_vhd_uri            = "noCustomUri"
resource_group_name             = "RGcheckpoint"
gateway_name                    = "gateway1"
location                        = "westeurope"
vnet_name                       = "checkpoint-vnet"
address_space                   = "10.50.0.0/16"
subnet_prefixes                 = ["10.50.10.0/24","10.50.20.0/24","10.50.100.0/24"]
GW_interface_IP                 = ["10.50.10.10","10.50.20.10","10.50.100.10"]
admin_password                  = "Cpwins1!"
sic_key                         = "Vpn1234567890"
vm_size                         = "Standard_D3_v2"
disk_size                       = "110"
publisher                       = "checkpoint"
vm_os_offer                     = "check-point-cg-r8110"
os_version                      = "R81.10"
vm_os_sku                       = "sg-byol"
allow_upload_download           = true
authentication_type             = "Password"
availability_type               = "Availability Zone"
enable_custom_metrics           = true
use_public_ip_prefix            = false
existing_public_ip_prefix_id    = ""
admin_shell                     = "/etc/cli.sh"

//#Windows Client Variables
Win10_name                      = "Win10-VM"
win_vm_size                     = "Standard_D3_v2"
ospublisher                     = "MicrosoftWindowsDesktop"
ms_os_offer                     = "Windows-10"
ms_sku                          = "win10-22h2-pro"
ms_admin_username               = "adminuser"
ms_admin_password               = "@$$w0rd1234!"
Win10_IP                        = "10.50.100.20"
