# Configure Azure provider
provider "azurerm" {
  features {}
  subscription_id = "64a9a252-e2ca-4cc3-af56-31bf09b86699"
}

# Resource group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = var.tags
}

# Virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = var.tags
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}


# Network security group and rules
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-security-group"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = var.tags
}

# Allow inbound HTTP traffic on port 80
resource "azurerm_network_security_rule" "AllowInbound" {
  name                        = "${var.prefix}-AllowInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = 80
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "AllowInbound-LB" {
  name                        = "${var.prefix}-AllowInbound-LB"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

# resource "azurerm_network_security_rule" "DenyFromInternet" {
#   name                        = "${var.prefix}-DenyFromInternet"
#   priority                    = 300
#   direction                   = "Inbound"
#   access                      = "Deny"
#   protocol                    = "*"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.main.name
#   network_security_group_name = azurerm_network_security_group.main.name
# }

resource "azurerm_network_security_rule" "AllowOutbound" {
  name                        = "${var.prefix}-AllowOutbound"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

# Subnet network security group association
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}


# Network interface
resource "azurerm_network_interface" "main" {
  count               = var.VMnum
  name                = "${var.prefix}-nic${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Load balancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = var.tags
  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

# Load balancer probe
resource "azurerm_lb_probe" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = "${var.prefix}-probe"
  port            = "80"
  protocol        = "Tcp"
  interval_in_seconds = 5
}

# Load balancer rule for HTTP
resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "${var.prefix}-LBRule"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id,]
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "80"
  frontend_ip_configuration_name = "primary"
  probe_id                       = azurerm_lb_probe.main.id
}

# Load balancer backend pool
resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id     = azurerm_lb.main.id
  name                = "acctestpool"
}

# Network interface backend pool association
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.VMnum
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  domain_name_label   = azurerm_resource_group.main.name
  allocation_method   = "Static"
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.VMnum
  name                            = "${var.prefix}-vm${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "${var.admin_username}"
  admin_password                  = "${var.admin_password}"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]
  source_image_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.packer_resource_group}/providers/Microsoft.Compute/images/${var.packer_image_name}"

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  availability_set_id = azurerm_availability_set.main.id
  tags = var.tags
}

resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-availability-set"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  platform_fault_domain_count = 2  
  platform_update_domain_count = 5  
  tags = var.tags
}

resource "azurerm_managed_disk" "main" {
  count                = var.VMnum
  name                 = "${var.prefix}-managed_disk-${count.index}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"
  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count              = var.VMnum
  managed_disk_id    = azurerm_managed_disk.main[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
  lun                = 10*count.index
  caching            = "ReadWrite"
}

# Output for the load balancer public URL
output "lb_url" {
  value       = "http://${azurerm_public_ip.main.ip_address}/"
  description = "Public URL of the load balancer."
}