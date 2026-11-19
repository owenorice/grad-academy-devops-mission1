# =============================================================================
# GTA 6 DevOps Academy — Mission 1: The Vanilla Deployment
# =============================================================================
# Your first Terraform project. This single file creates everything you need to
# deploy the "Social Hub" app to Azure:
#
#   Internet -> Public IP -> NSG (firewall) -> NIC -> Linux VM (runs Docker)
#
# Read it top to bottom. Every resource maps to one box in that diagram.
# Deploy with:  terraform init  ->  terraform apply
# Tear down with: terraform destroy
# =============================================================================


# -----------------------------------------------------------------------------
# 1. Terraform + provider setup
# -----------------------------------------------------------------------------
# Tell Terraform which "provider" (cloud plugin) to use. We use Azure.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
  }
}

provider "azurerm" {
  features {}
  # Authentication comes from the Azure CLI. Run `az login` first and, if you
  # have more than one subscription, `az account set --subscription "<name>"`.
}


# -----------------------------------------------------------------------------
# 2. Variables — the knobs you can tune (see terraform.tfvars.example)
# -----------------------------------------------------------------------------
variable "prefix" {
  description = "Your group's prefix — the ONLY value you need to set. It picks the pre-made resource group (named <prefix>-rg) you deploy into, and names every resource you create."
  type        = string
  default     = "vice-city"
}

variable "vm_size" {
  description = "VM size. B1s = 1 vCPU / 1 GB — plenty for one small container."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin user created on the VM (used for SSH)."
  type        = string
  default     = "rockstar"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key. Run `ssh-keygen` if you don't have one."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "repo_url" {
  description = "Git repo the VM clones on first boot to build and run the app. Must be reachable from the VM (public, or include an access token in the URL)."
  type        = string
  default     = "https://github.com/owenorice/grad-academy-devops-mission1.git"
}

# A locals block holds values we reuse. These tags get stamped on every
# resource so they are easy to find (and delete) in the Azure portal.
locals {
  tags = {
    project = "gta6-devops-academy"
    mission = "vanilla-deployment"
    managed = "terraform"
  }
}


# -----------------------------------------------------------------------------
# 3. Resource Group — your pre-made group (we look it up, we don't create it)
# -----------------------------------------------------------------------------
# Your instructor has already created a resource group named "<prefix>-rg" for
# your group. This `data` block LOOKS IT UP (rather than creating one) so every
# resource below lands inside it. Change `prefix` and you switch groups.
data "azurerm_resource_group" "main" {
  name = "${var.prefix}-rg"
}


# -----------------------------------------------------------------------------
# 4. Network — Virtual Network + Subnet
# -----------------------------------------------------------------------------
# A private network for our VM to live in (like your home Wi-Fi network).
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}


# -----------------------------------------------------------------------------
# 5. Firewall — Network Security Group
# -----------------------------------------------------------------------------
# Controls what traffic can reach the VM. We allow web traffic (port 80) so
# players can load the app, and SSH (port 22) so you can log in to the box.
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# Attach the firewall rules to the subnet.
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}


# -----------------------------------------------------------------------------
# 6. Public IP + Network Interface — how the VM gets on the internet
# -----------------------------------------------------------------------------
# A fixed public address that players type into their browser.
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# The virtual "network card" that plugs the VM into the subnet and public IP.
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}


# -----------------------------------------------------------------------------
# 7. The Virtual Machine — a Linux box that runs our app in Docker
# -----------------------------------------------------------------------------
# cloud-init (custom_data) bootstraps the VM on first boot: it installs Docker,
# clones this repo, and starts the Flask container. See cloud-init/.
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.prefix}-social-hub"
  computer_name       = "social-hub"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = local.tags

  network_interface_ids = [azurerm_network_interface.main.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Render the cloud-init script. On boot the VM clones repo_url and runs the
  # app from its app/ folder, so this repo stays the single source of truth.
  custom_data = base64encode(templatefile("${path.module}/cloud-init/social-club.yaml.tftpl", {
    admin_username = var.admin_username
    repo_url       = var.repo_url
  }))
}


# -----------------------------------------------------------------------------
# 8. Outputs — values printed after `terraform apply`
# -----------------------------------------------------------------------------
output "social_hub_url" {
  description = "Open this in your browser to see the deployed app."
  value       = "http://${azurerm_public_ip.main.ip_address}"
}

output "vm_public_ip" {
  description = "Public IP of the VM."
  value       = azurerm_public_ip.main.ip_address
}

output "ssh_command" {
  description = "Command to SSH into the VM."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}
