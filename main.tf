resource "azurerm_resource_group" "rg" {
  name     = "RG_PowerBI_Gateway"
  location = var.location
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "myTFVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "myTFSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "myTFPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "myTFNSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                = "myNIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = var.size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.sku
    version   = "latest"
  }
}

data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_windows_virtual_machine.vm.resource_group_name
  depends_on          = [azurerm_windows_virtual_machine.vm]
}

resource "azurerm_storage_account" "pbigateway_storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_windows_virtual_machine.vm.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "pbi_gateway_container" {
  name                  = var.storage_container_name
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
  depends_on = [
    azurerm_storage_account.pbigateway_storage_account
  ]
}

resource "azurerm_storage_blob" "pbi_gateway_setup_util_script" {
  name                   = "logUtil.ps1"
  storage_account_name   = var.storage_account_name
  storage_container_name = var.storage_container_name
  type                   = "Block"
  source                 = "scripts/logUtil.ps1"
  depends_on = [
    azurerm_storage_container.pbi_gateway_container
  ]
}

resource "azurerm_storage_blob" "pbi_gateway_setup_script" {
  name                   = "setup.ps1"
  storage_account_name   = var.storage_account_name
  storage_container_name = var.storage_container_name
  type                   = "Block"
  source                 = "scripts/setup.ps1"
  depends_on = [
    azurerm_storage_container.pbi_gateway_container
  ]
}

resource "azurerm_storage_blob" "pbi_gateway_install_script" {
  name                   = "pbiGatewayInstall.ps1"
  storage_account_name   = var.storage_account_name
  storage_container_name = var.storage_container_name
  type                   = "Block"
  source                 = "scripts/pbiGatewayInstall.ps1"
  depends_on = [
    azurerm_storage_container.pbi_gateway_container
  ]
}

resource "azurerm_virtual_machine_extension" "pbi_gateway_install" {
  name                 = "gatewayinstall"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings             = <<SETTINGS
    {
        "fileUris": [
          "https://${var.storage_account_name}.blob.core.windows.net/${var.storage_container_name}/logUtil.ps1",
          "https://${var.storage_account_name}.blob.core.windows.net/${var.storage_container_name}/pbiGatewayInstall.ps1",
          "https://${var.storage_account_name}.blob.core.windows.net/${var.storage_container_name}/setup.ps1"
        ]
    }
SETTINGS
  protected_settings   = jsonencode(
    {
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File setup.ps1 -AppId ${var.aad_app_id} -GatewayName ${var.gateway_name} -Secret ${var.aad_app_secret} -TenantId ${var.tenant_id} -Region ${var.gateway_region_key} -RecoveryKey ${var.gateway_recovery_key} -GatewayAdminUserIds ${var.gateway_admin_ids}",
        "storageAccountName": var.storage_account_name,
        "storageAccountKey": azurerm_storage_account.pbigateway_storage_account.primary_access_key
    }
  )
  depends_on = [
    azurerm_storage_blob.pbi_gateway_install_script,
    azurerm_storage_blob.pbi_gateway_setup_script,
    azurerm_storage_blob.pbi_gateway_setup_util_script
  ]
}
