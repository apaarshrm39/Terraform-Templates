##################################################################################
# VARIABLES => WE WILL MOVE THE VALUES INTO NEW FILE
##################################################################################

variable "resource_group_name" { default = "ap-rg-demo-test" }
variable "resource_group_location" { default = "eastus" }
variable "storage_account_name" {default = "######"}
variable "container_name" {default = "######"}
variable "key" {default = "terraform.tfstate"}

##################################################################################
# PROVIDERS
##################################################################################
# Configure the Microsoft Azure Provider
terraform {
  backend "azurerm" {
    resource_group_name   = var.resource_group_name
    storage_account_name  = var.storage_account_name
    container_name        = var.container_name
    key                   = var.key
  }
}
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}

}


##################################################################################
# RESOURCES
##################################################################################
# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "resourcegroupmain" {
    name     = var.resource_group_name
    location = "eastus"

    tags = {
        environment = "First VM Deployment"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "virtualnetworkmain" {
    name                = "terraformdemovnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.resourcegroupmain.name

    tags = {
        environment = "First VM Deployment"
    }
}

# Create subnet
resource "azurerm_subnet" "subnetmain" {
    name                 = "terraformdemosubnet"
    resource_group_name  = azurerm_resource_group.resourcegroupmain.name
    virtual_network_name = azurerm_virtual_network.virtualnetworkmain.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "publicipmain" {
    name                         = "terraformdemopublicip"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.resourcegroupmain.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "First VM Deployment"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsgmain" {
    name                = "terraformdemonsg"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.resourcegroupmain.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "First VM Deployment"
    }
}

# Create network interface
resource "azurerm_network_interface" "nicmain" {
    name                      = "terraformdemonic"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.resourcegroupmain.name

    ip_configuration {
        name                          = "terraformdemonicConfiguration"
        subnet_id                     = azurerm_subnet.subnetmain.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.publicipmain.id
    }

    tags = {
        environment = "First VM Deployment"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsgnicmain" {
    network_interface_id      = azurerm_network_interface.nicmain.id
    network_security_group_id = azurerm_network_security_group.nsgmain.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.resourcegroupmain.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storageaccountmain" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.resourcegroupmain.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "First VM Deployment"
    }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "linuxvmmain" {
    name                  = "ubuntu1604-azurevm"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.resourcegroupmain.name
    network_interface_ids = [azurerm_network_interface.nicmain.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "mainOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "ubuntu1604-azurevm"
    admin_username = "azureuser"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIgqF3Wk2ijzH3c8+Voydz5MKkw1/mb4jWhPV1PrqY1s6JedFNeBoofnqdoadL63elur1lYzis9iwc5MRHbirNtFau+3BsJa5TBxhfZ5WT2LyOzE/3fGNVtqtW8X8oJlQxcRjoFrJSZPyMewOegOvz/5TC+QDwHRov25ATpMOMKoB9eWfdC2w0jZzQT6qXWNZsoDTF6IljoX8WPOTvBdLeVrXJlB5oiSPYuUcnhHRzfVBbdWOVh2PRFytZTIUF4tUE4ORg4mytYJ1X+xUWyo0uLMmwqI95i5TOryufKl67tmxzFU+yGA8BMsTUvt9FpPQPb8guJ4jJ8fEoBVqR2goB welcome@DESKTOP-45EFUIR"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storageaccountmain.primary_blob_endpoint
    }

    tags = {
        environment = "First VM Deployment"
    }
}

##################################################################################
# OUTPUT
##################################################################################

output "instance_public_dns" {
  value = azurerm_public_ip.publicipmain.ip_address
}
