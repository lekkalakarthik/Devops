terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }

  # Remote state can be enabled later
  backend "azurerm" {
     resource_group_name  = "kml_rg_main-95c566bd1f814df4"
     storage_account_name = "terraformstatefiles12345"
     container_name       = "terraformstatefiles"
     key                  = "prod.terraform.tfstate"
   }
}

# Azure Provider
#
# Authentication is handled through environment variables.
# For GitHub Actions, use Azure OIDC.
#
# Required environment variables:
# ARM_CLIENT_ID
# ARM_TENANT_ID
# ARM_SUBSCRIPTION_ID
# ARM_USE_OIDC=true

provider "azurerm" {
  features {}

  resource_provider_registrations = "none"

  # No client_secret here.
  # AzureRM automatically reads these from environment variables:
  #
  # ARM_CLIENT_ID
  # ARM_TENANT_ID
  # ARM_SUBSCRIPTION_ID
  # ARM_USE_OIDC
}

############################
# Variables
############################

variable "location" {
  type    = string
  default = "East US"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to SSH public key file"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM authentication"
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyYIuft31JR8wjARJb6Gvzv4eT/DNmzU4oU9ihnZGX5 azureuser-azure-vm"
}

variable "name" {
  type    = string
  default = "kiran"
}

variable "resource_group_name" {
  type    = string
  default = "kml_rg_main-95c566bd1f814df4"
}

############################
# Local Values
############################

locals {
  name                = upper(var.name)
  resource_group_name = var.resource_group_name

  vm_size = var.location == "East US" ? "Standard_B2s" : "Standard_B1s"
}

############################
# Resource Group
############################

# Resource group is assumed to already exist.
# If you want Terraform to create it, uncomment this resource
# and remove the resource_group_name variable.

# resource "azurerm_resource_group" "rg" {
#   name     = var.resource_group_name
#   location = var.location
# }

############################
# Virtual Network
############################

resource "azurerm_virtual_network" "vnet" {
  name                = "vm-vnet2"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = local.resource_group_name
}

############################
# Subnet
############################

resource "azurerm_subnet" "subnet" {
  name                 = "vm-subnet2"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

############################
# Public IP
############################

resource "azurerm_public_ip" "pip" {
  name                = "vm-public-ip2"
  location            = var.location
  resource_group_name = local.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"
}

############################
# Network Security Group
############################

resource "azurerm_network_security_group" "nsg" {
  name                = "vm-nsg2"
  location            = var.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22-2000"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }
}

############################
# Network Interface
############################

resource "azurerm_network_interface" "nic" {
  name                = "vm-nic2"
  location            = var.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

############################
# NSG Association
############################

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

############################
# Linux Virtual Machine
############################

resource "azurerm_linux_virtual_machine" "vm" {
  name                = local.name
  resource_group_name = local.resource_group_name
  location            = var.location
  size                = local.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

 admin_ssh_key {
  username   = var.admin_username
  public_key = var.ssh_public_key
}

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

############################
# Outputs
############################

output "public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_name" {
  description = "Virtual machine name"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "machine_id" {
  description = "Virtual machine resource ID"
  value       = azurerm_linux_virtual_machine.vm.virtual_machine_id
}
