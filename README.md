![Terraform Version](https://img.shields.io/badge/tf-%3E%3D0.12.0-blue.svg)

> Note: This module requires Terraform 0.12 or later. For earlier Terraform versions, see [0.11 Configuration Language](https://www.terraform.io/docs/configuration-0-11/index.html).

# terraform-example-appgw

## Create an Application Gateway V2 resource

Example module with dynamic blocks.

This Terraform module deploys an Application Gateway V2 to Azure with frontends, backend pools and routing rules as input parameters.

This example uses HTTP configuration, additional configuration will need to be added to use Keyvault for HTTPS configuration and certifivate selection.

## Usage

```hcl
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
```

## License

[MIT](LICENSE)