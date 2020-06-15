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

  dynamic "frontend_port" {
    for_each = [for f in var.frontends: {
      name = f.name
      port = f.port  
    }]

    content {
      name                           = "${var.name}-${frontend_port.value.name}-frontend-port"
      port                           = frontend_port.value.port
    }
  
  }

  dynamic "http_listener" {
    for_each = [for f in var.frontends : {
      name     = f.name
      protocol = f.protocol
    }]

    content {
      name                           = "${var.name}-${http_listener.value.name}-frontend-listener"
      frontend_ip_configuration_name = "${var.name}-frontend-pip"
      frontend_port_name             = "${var.name}-${http_listener.value.name}-frontend-port"
      protocol                       = http_listener.value.protocol
    }
  }

  # Backend configuration

  dynamic "backend_address_pool" {
    for_each = [for b in var.backends : {
      name         = b.name
      ip_addresses = b.ip_addresses
    }]

    content {
      name                  = "${var.name}-${backend_address_pool.value.name}-backend-pool"
      ip_addresses          = backend_address_pool.value.ip_addresses
    }
  
  }

  dynamic "probe" {
    for_each = [for b in var.backends : {
      name        = b.name
      protocol    = b.protocol
      host_header = b.host_header
      path        = b.path
    }]

    content {
      name                  = "${var.name}-${probe.value.name}-backend-health-probe"
      protocol              = probe.value.protocol
      host                  = probe.value.host_header
      path                  = probe.value.path
      interval              = 30
      timeout               = 30
      unhealthy_threshold   = 3
    }
    
  }

  dynamic "backend_http_settings" {
    for_each = [for b in var.backends : {
      name                  = b.name
      port                  = b.port
      protocol              = b.protocol
      host_header           = b.host_header
      path                  = b.path
      cookie_based_affinity = b.cookie_based_affinity
    }]

    content {
      name                  = "${var.name}-${backend_http_settings.value.name}-backend-http-setting"
      cookie_based_affinity = backend_http_settings.value.cookie_based_affinity
      port                  = backend_http_settings.value.port
      protocol              = backend_http_settings.value.protocol
      request_timeout       = 20
      host_name             = backend_http_settings.value.host_header
      path                  = backend_http_settings.value.path
      probe_name            = "${var.name}-${backend_http_settings.value.name}-backend-health-probe"
    }

  }

  # Request routing rules

  dynamic "request_routing_rule" {
    for_each = [for r in var.routing_rules : {
      name     = r.name
      frontend = r.frontend
      backend  = r.backend
    }]

    content {
      name                       = "${var.name}-${request_routing_rule.value.name}-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "${var.name}-${request_routing_rule.value.frontend}-frontend-listener"
      backend_address_pool_name  = "${var.name}-${request_routing_rule.value.backend}-backend-pool"
      backend_http_settings_name = "${var.name}-${request_routing_rule.value.backend}-backend-http-setting"
    }
    
  }

}