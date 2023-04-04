terraform {
  required_version = ">= 0.14.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
#    restapi = {
#      source  = "hashicorp/ fmontezuma/restapi"
#      version = ">= 1.14.1"
#    }
  }
}

//********************** use credentials as in terraform.tfvars ++***************//
provider "azurerm" {
  subscription_id     = var.subscription_id
  client_id           = var.client_id
  client_secret       = var.client_secret
  tenant_id           = var.tenant_id

  features {}
}

//********************** Resource Group Configuration **************************//
# ###########################################
# create resource group
# ###########################################
resource "azurerm_resource_group" "rg" {
  name                = var.resource_group_name
  location            = var.location
}

//********************** VNET, subnet, Public, IP, Interfaces ******************//
# ###########################################
# create a virtual network 
# ###########################################
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name 
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.subnet_prefixes
}

//********************** Security Group ****************************************//
# ###########################################
# create a network security Group to allow all 
# ###########################################
resource "azurerm_network_security_group" "nsg" {
  name                = "allow_all_nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAllInBound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    description                = "Allow all inbound connections"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ###########################################
# allocate public IP addresses
# ###########################################
resource "azurerm_public_ip" "PubIP1" {
  name                = "public_IP1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "PubIP2" {
  name                = "public_IP2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# ###########################################
# Create Subnet1 assign routing tabel and security group
# ###########################################
resource "azurerm_subnet" "External_subnet1"  {
  depends_on = [ azurerm_virtual_network.vnet  ]
  name                 = "subnet_Front1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ var.subnet_prefixes[0] ]
}
resource "azurerm_subnet_network_security_group_association" "External_subnet1" {
  depends_on = [ azurerm_subnet.External_subnet1  ]
  subnet_id                 = azurerm_subnet.External_subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_route_table" "External_subnet1" {
  depends_on = [ azurerm_subnet.External_subnet1  ]
  name                = "RT_Front1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name           = "Local-Subnet1"
    address_prefix = var.address_space
    next_hop_type  = "VnetLocal"
  }
  route {
    name           = "To-Internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
	  next_hop_in_ip_address = var.GW_interface_IP[0]
   }
}

resource "azurerm_subnet_route_table_association" "External_subnet1" {
  depends_on = [ azurerm_route_table.External_subnet1  ]
  subnet_id      = azurerm_subnet.External_subnet1.id
  route_table_id = azurerm_route_table.External_subnet1.id
}

# ###########################################
#  Create Subnet2 assign routing tabel and security group
# ###########################################
resource "azurerm_subnet" "External_subnet2"   {
  depends_on = [ azurerm_virtual_network.vnet  ]
  name                 = "subnet_Front2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ var.subnet_prefixes[1] ]
}
resource "azurerm_subnet_network_security_group_association" "External_subnet2" {
  depends_on = [ azurerm_subnet.External_subnet2  ]
  subnet_id                 = azurerm_subnet.External_subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_route_table" "External_subnet2" {
  depends_on = [ azurerm_subnet.External_subnet2  ]
  name                = "RT_Front2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name           = "Local-Subnet2"
    address_prefix = var.address_space
    next_hop_type  = "VnetLocal"
  }
  route {
    name           = "To-Internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
	  next_hop_in_ip_address = var.GW_interface_IP[1]
   }
}

resource "azurerm_subnet_route_table_association" "External_subnet2" {
  depends_on = [ azurerm_route_table.External_subnet2  ]
  subnet_id      = azurerm_subnet.External_subnet2.id
  route_table_id = azurerm_route_table.External_subnet2.id
}
# ###########################################
#  Create Subnet3 assign routing tabel and security group
# ###########################################
resource "azurerm_subnet" "Internal_subnet"  {
  depends_on = [ azurerm_virtual_network.vnet  ]
  name                 = "subnet-Back1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [ var.subnet_prefixes[2] ]
}

resource "azurerm_subnet_network_security_group_association" "Internal_subnets" {
  depends_on = [ azurerm_subnet.Internal_subnet  ]
  subnet_id                 = azurerm_subnet.Internal_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_route_table" "Internal_subnet" {
  depends_on = [ azurerm_subnet.Internal_subnet  ]
  name                = "Rt_Back1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name           = "To-Internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
	next_hop_in_ip_address = var.GW_interface_IP[2]
   }
}

resource "azurerm_subnet_route_table_association" "Internal_subnet" {
  depends_on = [ azurerm_route_table.Internal_subnet  ]
  subnet_id      = azurerm_subnet.Internal_subnet.id
  route_table_id = azurerm_route_table.Internal_subnet.id
}
//********************** create all interfaces and assign reserved IP  **********//
# ###########################################
#  Create Front-eth0 interface
# ###########################################
resource "azurerm_network_interface" "mgmtInterface" {
  depends_on = [ azurerm_public_ip.PubIP1  ]
  name                            = "NIC-Front1-eth0"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  enable_ip_forwarding            = "true"
  enable_accelerated_networking   = "true"

  ip_configuration {
    name                          = "ip-conf-ext1"
    subnet_id                     = azurerm_subnet.External_subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.GW_interface_IP[0]
    public_ip_address_id          = azurerm_public_ip.PubIP1.id
  }
  lifecycle {
    ignore_changes = [
      ip_configuration
    ]
  }
}

# ###########################################
#  Create Front-eth1 interface
# ###########################################
resource "azurerm_network_interface" "gwexternal1" {
  depends_on = [ azurerm_subnet.External_subnet1  ]
  name                            = "NIC-Front2-eth1"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  enable_ip_forwarding            = "true"
  enable_accelerated_networking   = "true"
  ip_configuration {
    name                          = "ip-conf-ext2"
    subnet_id                     = azurerm_subnet.External_subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.GW_interface_IP[1]
    public_ip_address_id          = azurerm_public_ip.PubIP2.id
  }
}

# ###########################################
#  Create Back-eth2 interface
# ###########################################
resource "azurerm_network_interface" "gwinternal" {
  depends_on = [ azurerm_subnet.Internal_subnet  ]
  name                            = "NIC-Back1-eth2"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  enable_ip_forwarding            = "true"
  enable_accelerated_networking   = "true"
	ip_configuration {
    name                          = "ip-conf-int1"
    subnet_id                     = azurerm_subnet.Internal_subnet.id
    private_ip_address_allocation = "Static"
		private_ip_address            = var.GW_interface_IP[2]
  }
}

//********************** Gateway ***********************************************//
# ###########################################
# Generate random text for a unique storage account name
# ###########################################
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }
  byte_length = 8
}

# ###########################################
# Create storage account for boot diagnostics
# ###########################################
resource "azurerm_storage_account" "mystorageaccount" {
  name                        = "diag${random_id.randomId.hex}"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  account_tier                = "Standard"
  account_replication_type    = "LRS"
}

locals {
  custom_image_condition = var.source_image_vhd_uri == "noCustomUri" ? false : true
}


# Create virtual machine and Accept the agreement for selected offer and SKU
data "azurerm_marketplace_agreement" "Checkpointget" {
  offer               = var.vm_os_offer
  publisher           = var.publisher
  plan                = var.vm_os_sku  
}

locals {
  agreement_exists = length(data.azurerm_marketplace_agreement.Checkpointget) > 0
}

resource "azurerm_marketplace_agreement" "Checkpoint" {
  count = local.agreement_exists ? 0 : 1
  offer               = var.vm_os_offer
  publisher           = var.publisher
  plan                = var.vm_os_sku 
}

resource "azurerm_virtual_machine" "chkpgw" {
  depends_on = [
    azurerm_storage_account.mystorageaccount
  ]
  name                  = var.gateway_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  #network_interface_ids = [azurerm_network_interface.mgmtInterface.id, azurerm_network_interface.gwexternal1.id, azurerm_network_interface.gwinternal.id]
  network_interface_ids = [azurerm_network_interface.mgmtInterface.id, azurerm_network_interface.gwinternal.id]
  primary_network_interface_id = "${azurerm_network_interface.gwexternal1.id}"
  vm_size               = var.vm_size
  delete_os_disk_on_termination = "true"

  storage_os_disk {
    name              = "gatewayDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = var.publisher
    offer     = var.vm_os_offer
    sku       = var.vm_os_sku
    version   = "latest"
  }

  plan {
    name = var.vm_os_sku
    publisher = var.publisher
    product = var.vm_os_offer
  }
  os_profile {
    computer_name  = var.gateway_name 
    admin_username = "sdwanguru"
    admin_password = var.admin_password
    custom_data = file("customdata.sh") 
  }

  os_profile_linux_config {
   disable_password_authentication = false
  }

  boot_diagnostics {
    enabled = "true"
    storage_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

}

//********************** Windows Client ***********************************************//
# Create virtual machine and Accept the agreement for selected offer and SKU
data "azurerm_marketplace_agreement" "msget" {
  offer               = var.ms_os_offer
  publisher           = var.ospublisher
  plan                = var.ms_sku  
}

locals {
  msagreement_exists = length(data.azurerm_marketplace_agreement.msget) > 0
}

resource "azurerm_marketplace_agreement" "Win10Client" {
  count = local.msagreement_exists ? 0 : 1
  offer               = var.ms_os_offer
  publisher           = var.ospublisher
  plan                = var.ms_sku 
}

resource "azurerm_network_interface" "WinClientNic" {
  depends_on = [ azurerm_subnet.Internal_subnet  ]
  name                = "Win10_NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_ip_forwarding = "true"
	ip_configuration {
    name                          = "win-ip-conf-int1"
    subnet_id                     = azurerm_subnet.Internal_subnet.id
    private_ip_address_allocation = "Static"
		private_ip_address            = var.Win10_IP
  }
}

resource "azurerm_windows_virtual_machine" "Win10Client" {
  depends_on = [ 
    azurerm_network_interface.gwinternal,
    azurerm_network_interface.WinClientNic,
    azurerm_virtual_machine.chkpgw
  ]
  name                     = var.Win10_name
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  size                     = var.win_vm_size
  admin_username           = var.ms_admin_username
  admin_password           = var.admin_password
  

  network_interface_ids = [
    azurerm_network_interface.WinClientNic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.ospublisher
    offer     = var.ms_os_offer
    sku       = var.ms_sku
    version   = "latest"
  }
}

# //********************** Rest API ***********************************************//
# #resource "restapi_object" "name" {
# #  
# #}
