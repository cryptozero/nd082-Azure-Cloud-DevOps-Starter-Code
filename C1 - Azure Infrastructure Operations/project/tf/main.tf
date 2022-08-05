provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "main" {
  name = var.udacity_resource_group.name
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/24"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = var.project_tags
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-internal"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-InternalAccess"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  security_rule {
    name                       = "${var.prefix}-VirtualNetwork_Traffic_Allowed"
    description                = "Allow VirtualNetwork traffic"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "${var.prefix}-AzureLoadBalancer_Traffic_Allowed"
    description                = "Allow AzureLoadBalancer traffic"
    priority                   = 1200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "${var.prefix}-Internet_Traffic_Denied"
    description                = "Deny Internet traffic"
    priority                   = 3000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = var.project_tags
}

resource "azurerm_subnet_network_security_group_association" "internalsubnet" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic${count.index}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  count               = var.vmcount

  ip_configuration {
    name                          = "internal-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.project_tags
}

resource "azurerm_public_ip" "lb_public_ip" {
  name                = "${var.prefix}-LB-Public-IP"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Dynamic"

  tags = var.project_tags
}
resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-LoadBalancer"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }

  tags = var.project_tags
}

resource "azurerm_lb_backend_address_pool" "lb_backend_address_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${var.prefix}-BackEndAddressPool"

}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "${var.prefix}-LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_address_pool.id, ]
  probe_id                       = azurerm_lb_probe.lb_probe.id
  # depends_on                     = ["azurerm_lb_probe.lb_probe"]
  # idle_timeout_in_minutes        = 1
}

resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "${var.prefix}-tcpProbe"
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_availability_set" "aset_webservice" {
  name                = "${var.prefix}-aset-webservice"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = var.project_tags
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.vmcount
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool.id
  ip_configuration_name   = azurerm_network_interface.nic[count.index].ip_configuration[0].name
  network_interface_id    = element(azurerm_network_interface.nic.*.id, count.index)
}

data "azurerm_image" "vm_image" {
  name                = var.vm_image
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm${count.index}"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  count = var.vmcount

  availability_set_id = azurerm_availability_set.aset_webservice.id

  source_image_id = data.azurerm_image.vm_image.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = var.project_tags
}

# resource "azurerm_managed_disk" "managed_disk" {
#   name                 = "managed-disk"
#   location             = azurerm_resource_group.main.location
#   resource_group_name  = azurerm_resource_group.main.name
#   storage_account_type = "Standard_LRS"
#   create_option        = "Empty"
#   disk_size_gb         = "1"

#   tags = {
#     environment = var.environment
#   }
# }
