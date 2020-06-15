resource "azurerm_public_ip" "appgw_public_ip" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku {
    name              = "Standard_v2"
    tier              = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity      = 0
    max_capacity      = 2
  }

  gateway_ip_configuration {
    name              = "${var.name}-ipconfig"
    subnet_id         = var.subnet_id
  }

  # Frontend configuration
  
  frontend_ip_configuration {
    name                           = "${var.name}-frontend-pip"
    public_ip_address_id           = azurerm_public_ip.appgw_public_ip.id
  }

  frontend_port {
    name                           = "${var.name}-frontend-port"
    port                           = 80
  }

  http_listener {
    name                           = "${var.name}-frontend-listener"
    frontend_ip_configuration_name = "${var.name}-frontend-pip"
    frontend_port_name             = "${var.name}-frontend-port"
    protocol                       = "Http"
  }

  # Backend configuration

  backend_address_pool {
    name                  = "${var.name}-backend-pool"
    ip_addresses          = ["10.100.1.4"]
  }

  probe {
    name                  = "${var.name}-backend-health-probe"
    protocol              = "Http"
    host                  = "localhost"
    path                  = "/"
    interval              = 30
    timeout               = 30
    unhealthy_threshold   = 3
  }

  backend_http_settings {
    name                  = "${var.name}-backend-http-setting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
    host_name             = "localhost"
    path                  = "/"
    probe_name            = "${var.name}-backend-health-probe"
  }

  # Request routing rules

  request_routing_rule {
    name                       = "${var.name}-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "${var.name}-frontend-listener"
    backend_address_pool_name  = "${var.name}-backend-pool"
    backend_http_settings_name = "${var.name}-backend-http-setting"
  }

}