terraform {
  required_version      = ">= 0.12"
}

provider "azurerm" {
  version  = "= 2.0.0"
  features {}
}

resource "azurerm_resource_group" "appgw_rg" {
  name     = "dev-appgw-rg"
  location = var.location
}

# NSG for app gateway subnet

module "gw-nsg" {
  source              = "./modules/network-security-group"

  name                = "dev-appgw-gw-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.appgw_rg.name
  tags                = var.tags

  rules = [
            {
              name                    = "allow-appgw-ports"
              priority                = "1000"
              protocol                = "*"
              source_address_prefix   = "Internet"
              destination_port_range  = "65200-65535"
              description             = "Allow App Gateway V2 required ports"
            },
            {
              name                    = "allow-http"
              priority                = "1010"
              protocol                = "Tcp"
              source_address_prefix   = "*"
              destination_port_range  = "80"
              description             = "Allow HTTP"
            },
            {
              name                    = "allow-https"
              priority                = "1020"
              protocol                = "Tcp"
              source_address_prefix   = "*"
              destination_port_range  = "443"
              description             = "Allow HTTPS"
            },
            {
              name                    = "allow-http-imageapp"
              priority                = "1030"
              protocol                = "Tcp"
              source_address_prefix   = "*"
              destination_port_range  = "88"
              description             = "Allow port 88 for imageapp HTTP requests"
            }
  ]
  
}

# Dynamic block app gateway example

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "AppGateway"
  resource_group_name  = azurerm_resource_group.appgw_rg.name
  virtual_network_name = module.network.name
  address_prefix       = "10.100.2.0/24"
}

module "app-gateway-dynamic" {
  source              = "./modules/app-gateway-dynamic"

  name                = "dev-appgw-tf-dyn"
  resource_group_name = azurerm_resource_group.appgw_rg.name
  location            = var.location
  subnet_id           = azurerm_subnet.appgw_subnet.id
  tags                = var.tags

  frontends           = [
                          {
                            name = "webapp1"
                            port = 80
                            protocol = "Http"
                          },
                          {
                            name = "imageapp"
                            port = 88
                            protocol = "Http"
                          }
  ]

  backends            = [
                          {
                            name                  = "webapp1"
                            ip_addresses          = ["10.100.1.4"]
                            port                  = 80
                            protocol              = "Http"
                            host_header           = "localhost"
                            path                  = "/"
                            cookie_based_affinity = "Disabled"
                          },
                          {
                            name                  = "imageapp"
                            ip_addresses          = ["10.100.1.4"]
                            port                  = 80
                            protocol              = "Http"
                            host_header           = "localhost"
                            path                  = "/images/"
                            cookie_based_affinity = "Disabled"
                          }
  ]

  routing_rules       = [
                          {
                            name                  = "webapp1"
                            frontend              = "webapp1"
                            backend               = "webapp1"
                          },
                          {
                            name                  = "imageapp"
                            frontend              = "imageapp"
                            backend               = "imageapp"
                          }
  ]

}

# Environment setup

module "web-nsg" {
  source              = "./modules/network-security-group"

  name                = "dev-appgw-web-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.appgw_rg.name
  tags                = var.tags

  rules = [
            {
              name                    = "allow-http"
              priority                = "1000"
              protocol                = "Tcp"
              source_address_prefix   = "VirtualNetwork"
              destination_port_range  = "80"
              description             = "Allow HTTP"
            },
            {
              name                    = "allow-https"
              priority                = "1010"
              protocol                = "Tcp"
              source_address_prefix   = "VirtualNetwork"
              destination_port_range  = "443"
              description             = "Allow HTTPS"
            },
            {
              name                    = "allow-rdp"
              priority                = "1020"
              protocol                = "*"
              source_address_prefix   = "*"
              destination_port_range  = "3389"
              description             = "Allow RDP"
            }
  ]
  
}

module "network" {
  source              = "./modules/network"

  name                = "dev-appgw-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.appgw_rg.name
  address_space       = ["10.100.0.0/22"]
  dns_servers         = []
  tags                = var.tags

  subnets             = [
                          {
                            subnet_name                      = "app-gateway"
                            subnet_address_prefix            = "10.100.0.0/24"
                            subnet_network_security_group_id = module.gw-nsg.id
                          },
                          {
                            subnet_name                      = "web"
                            subnet_address_prefix            = "10.100.1.0/24"
                            subnet_network_security_group_id = module.web-nsg.id
                          }
  ]

}

# Basic app gateway module example

# module "app-gateway" {
#   source              = "./modules/app-gateway"

#   name                = "dev-appgw-tf"
#   resource_group_name = azurerm_resource_group.appgw_rg.name
#   location            = var.location
#   subnet_id           = azurerm_subnet.appgw_subnet.id
#   tags                = var.tags
# }