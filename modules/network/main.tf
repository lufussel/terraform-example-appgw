resource "azurerm_virtual_network" "network" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  tags = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = lookup(var.subnets[count.index], "subnet_name", "default")
  resource_group_name  = azurerm_virtual_network.network.resource_group_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefix       = lookup(var.subnets[count.index], "subnet_address_prefix", ["10.0.1.0/24"])
  count                = length(var.subnets)
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet[count.index].id
  network_security_group_id = lookup(var.subnets[count.index], "subnet_network_security_group_id", [])
  count                     = length(var.subnets)
}