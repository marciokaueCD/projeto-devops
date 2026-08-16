project     = "statusboard"
environment = "lab"
location    = "East US 2"
acr_sku     = "Basic"


container_image = "acrstatusboardlab.azurecr.io/statusboard:v1.0"

min_replicas = 1
max_replicas = 2
