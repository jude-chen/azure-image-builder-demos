resource "random_string" "suffix" {
  length  = 4
  special = false
}

resource "azurerm_resource_group" "demo-rg" {
  location = var.location
  name     = "${var.resource_prefix}-demo-rg"
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
  name                = "${var.resource_prefix}-${random_string.suffix.result}-gallery"
  resource_group_name = azurerm_resource_group.demo-rg.name
  location            = azurerm_resource_group.demo-rg.location
  description         = "Shared Image Gallery for demo"
}

resource "azurerm_shared_image" "demo-image" {
  name                = "Win2022Web"
  resource_group_name = azurerm_resource_group.demo-rg.name
  gallery_name        = azurerm_shared_image_gallery.demo-sig.name
  location            = azurerm_resource_group.demo-rg.location
  os_type             = "Windows"
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

resource "azurerm_role_assignment" "gallery-role-assignment" {
  role_definition_name = "Compute Gallery Artifacts Publisher"
  principal_id         = azurerm_user_assigned_identity.aibidentity.principal_id
  scope                = azurerm_resource_group.demo-rg.id
}

resource "azurerm_role_assignment" "storage-role-assignment" {
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.aibidentity.principal_id
  scope                = azurerm_resource_group.demo-rg.id
}
