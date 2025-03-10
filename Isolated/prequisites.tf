resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_resource_group" "demo-rg" {
  location = var.location
  name     = "${var.resource_prefix}-demo-rg"
}

resource "azurerm_virtual_network" "demo-vnet" {
  name                = "${var.resource_prefix}-vnet"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.demo-rg.location
  resource_group_name = azurerm_resource_group.demo-rg.name
}

resource "azurerm_subnet" "aib-subnet" {
  name                                          = "aib-subnet"
  resource_group_name                           = azurerm_resource_group.demo-rg.name
  virtual_network_name                          = azurerm_virtual_network.demo-vnet.name
  address_prefixes                              = ["10.0.0.0/26"]
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "aci-subnet" {
  name                 = "aci-subnet"
  resource_group_name  = azurerm_resource_group.demo-rg.name
  virtual_network_name = azurerm_virtual_network.demo-vnet.name
  address_prefixes     = ["10.0.0.64/26"]
  delegation {
    name = "aci-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "vm-subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.demo-rg.name
  virtual_network_name = azurerm_virtual_network.demo-vnet.name
  address_prefixes     = ["10.0.0.128/26"]
}

resource "azurerm_storage_account" "demo-sa" {
  name                     = "${var.resource_prefix}sa${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.demo-rg.name
  location                 = azurerm_resource_group.demo-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "demo-container" {
  name                  = "${var.resource_prefix}-files"
  storage_account_id    = azurerm_storage_account.demo-sa.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "webpage" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.demo-sa.name
  storage_container_name = azurerm_storage_container.demo-container.name
  type                   = "Block"
  source                 = "../Artifacts/index.html"
}

resource "azurerm_storage_blob" "pwshscript" {
  name                   = "setupwebsite.ps1"
  storage_account_name   = azurerm_storage_account.demo-sa.name
  storage_container_name = azurerm_storage_container.demo-container.name
  type                   = "Block"
  source                 = "../Artifacts/setupwebsite.ps1"
}

resource "azurerm_shared_image_gallery" "demo-sig" {
  name                = "${var.resource_prefix}_${random_string.suffix.result}_gallery"
  resource_group_name = azurerm_resource_group.demo-rg.name
  location            = azurerm_resource_group.demo-rg.location
  description         = "Shared Image Gallery for demo"
}

resource "azurerm_shared_image" "demo-image" {
  name                     = "Win2022Web"
  resource_group_name      = azurerm_resource_group.demo-rg.name
  gallery_name             = azurerm_shared_image_gallery.demo-sig.name
  location                 = azurerm_resource_group.demo-rg.location
  os_type                  = "Windows"
  hyper_v_generation       = "V2"
  trusted_launch_supported = true
  identifier {
    publisher = "Contoso"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
  }
}

resource "azurerm_user_assigned_identity" "aibidentity" {
  location            = var.location
  name                = "${var.resource_prefix}-${random_string.suffix.result}-identity"
  resource_group_name = azurerm_resource_group.demo-rg.name
}

resource "azurerm_role_assignment" "storage-role-assignment" {
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.aibidentity.principal_id
  scope                = azurerm_resource_group.demo-rg.id
}

resource "azurerm_role_assignment" "gallery-role-assignment" {
  role_definition_name = "Compute Gallery Artifacts Publisher"
  principal_id         = azurerm_user_assigned_identity.aibidentity.principal_id
  scope                = azurerm_resource_group.demo-rg.id
}

resource "azurerm_role_assignment" "vnet-role-assignment" {
  principal_id         = azurerm_user_assigned_identity.aibidentity.principal_id
  role_definition_name = "Network Contributor"
  scope                = azurerm_resource_group.demo-rg.id
}

# Alternatively, you can create custom roles for more granular permission controls.

# resource "azurerm_role_definition" "image_creation_role" {
#   name        = "Azure Image Builder Service Image Creation Role"
#   description = "Image Builder access to create resources for the image build, you should delete or split out as appropriate"
#   scope       = "/subscriptions/${var.subscription_id}"
#   permissions {
#     actions = [
#       "Microsoft.Compute/galleries/read",
#       "Microsoft.Compute/galleries/images/read",
#       "Microsoft.Compute/galleries/images/versions/read",
#       "Microsoft.Compute/galleries/images/versions/write",

#       "Microsoft.Compute/images/write",
#       "Microsoft.Compute/images/read",
#       "Microsoft.Compute/images/delete"
#     ]
#     not_actions = []
#   }
# }

# resource "azurerm_role_assignment" "image_creation_role_assignment" {
#   role_definition_id = azurerm_role_definition.image_creation_role.role_definition_resource_id
#   principal_id       = azurerm_user_assigned_identity.aibidentity.principal_id
#   scope              = azurerm_resource_group.demo-rg.id
# }

# resource "azurerm_role_definition" "image_creation_vnet_role" {
#   name = "Azure Image Builder Service Networking Role"
#   description = "Image Builder vnet access to create resources for the image build"
#   scope = "/subscriptions/${var.subscription_id}"
#   permissions {
#     actions = [
#       "Microsoft.Network/virtualNetworks/subnets/join/action",
#       "Microsoft.Network/virtualNetworks/read"
#     ]
#     not_actions = []
#   }
# }

# resource "azurerm_role_assignment" "image_creation_vnet_role_assignment" {
#   role_definition_id = azurerm_role_definition.image_creation_vnet_role.role_definition_resource_id
#   principal_id       = azurerm_user_assigned_identity.aibidentity.principal_id
#   scope              = azurerm_resource_group.demo-rg.id
# }
