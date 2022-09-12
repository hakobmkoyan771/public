
# Azure Kubernetes Cluster

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_role_assignment" "main" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name

  default_node_pool {
    name                  = "worker"
    node_count            = var.node_count
    vm_size               = var.node_wm_size
    type                  = var.node_type
    enable_auto_scaling   = var.enable_auto_scaling
    enable_node_public_ip = true
  }
  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
      key_data = file("~/.ssh/devtask.pub")
    }
  }



  identity {
    type = var.identity_type
  }

  network_profile {
    load_balancer_sku = var.load_balancer_sku
    network_plugin    = var.network_plugin
  }
}

resource "local_file" "kubeconfig" {
  depends_on = [azurerm_kubernetes_cluster.main]
  filename   = "config"
  content    = azurerm_kubernetes_cluster.main.kube_config_raw
}
