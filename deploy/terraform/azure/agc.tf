# Application Gateway for Containers (bring-your-own deployment): Terraform creates the
# load balancer, its frontend and the subnet association; the ALB Controller in the cluster
# programs routes from the chart's Ingress.

resource "azurerm_application_load_balancer" "main" {
  name                = "agc-${var.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_application_load_balancer_frontend" "main" {
  name                         = "frontend"
  application_load_balancer_id = azurerm_application_load_balancer.main.id
}

resource "azurerm_application_load_balancer_subnet_association" "main" {
  name                         = "agc-subnet"
  application_load_balancer_id = azurerm_application_load_balancer.main.id
  subnet_id                    = azurerm_subnet.agc.id
}
