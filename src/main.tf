# Configure providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = "TechChallengeRG"
  location = "eastus2"
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name = "TechChallengeVNet"
  resource_group_name = azurerm_resource_group.rg.name
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.rg.location
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name = "TechChallengeSubnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

# Create publuc IP address to access server
resource "azurerm_public_ip" "publicIP" {
  name = "TechChallengePubIP"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  allocation_method = "Dynamic"
}

# Create security group with rules for http, https, and ssh
resource "azurerm_network_security_group" "securityGroup" {
  name = "TechChallengeSecurityGroup"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  security_rule {
    name = "http"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "https"
       priority = 200
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "443"
       source_address_prefix = "*"
       destination_address_prefix = "*"
  }

  security_rule {
       name = "ssh"
       priority = 300
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "22"
       source_address_prefix = "*"
       destination_address_prefix = "*"
   }
}

# Create network interface
resource "azurerm_network_interface" "netInterface" {
  name = "TechChallengeNetInterface"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  ip_configuration {
       name = "internal"
       private_ip_address_allocation = "Dynamic"
       subnet_id = azurerm_subnet.subnet.id
       public_ip_address_id = azurerm_public_ip.publicIP.id
   }
}

# Associate network interface to security group
resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id = azurerm_network_interface.netInterface.id
  network_security_group_id = azurerm_network_security_group.securityGroup.id
}

# Generate random id for storage accoutn
resource "random_id" "random_id" {
  keepers = {
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account with unique name
resource "azurerm_storage_account" "storageAccount" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Generate ssh key pair to access to VM
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Create VM
resource "azurerm_linux_virtual_machine" "vm" {
  name = "TechChallengeVM"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  network_interface_ids = [azurerm_network_interface.netInterface.id]
  size = "Standard_B1s"

  os_disk {
    name = "TechChallengeDisk"
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "0001-com-ubuntu-server-jammy"
    sku = "22_04-lts-gen2"
    version = "latest"
  }

  computer_name = "TechChallengeServer"
  admin_username = "tcAdmin"
  disable_password_authentication = true

  admin_ssh_key {
    username = "tcAdmin"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storageAccount.primary_blob_endpoint
  }
}