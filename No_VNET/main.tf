resource "azapi_resource" "image-template" {
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2024-02-01"
  name      = "${var.resource_prefix}-template"
  parent_id = azurerm_resource_group.demo-rg.id
  location  = var.location
  body = jsonencode({
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        (azurerm_user_assigned_identity.aibidentity.id) = {}
      }
    }
    properties = {
      buildTimeoutInMinutes = 0
      customize = [
        {
          name = "create_folder"
          type = "PowerShell"
          inline = [
            "New-Item -ItemType Directory C:\\ImageBuilderWebApp"
          ]
          runAsSystem = false
          runElevated = true
        },
        {
          name        = "webpagefile"
          type        = "File"
          sourceUri   = "https://${azurerm_storage_blob.webpage.url}"
          destination = "C:\\ImageBuilderWebApp\\index.html"
        },
        {
          name        = "setupwebsite"
          type        = "PowerShell"
          scriptUri   = "https://${azurerm_storage_blob.pwshscript.url}"
          runAsSystem = false
          runElevated = true
        },
        {
          type        = "WindowsUpdate"
          updateLimit = 0
          filters = [
            "exclude:$_.Title -like '*Preview*'",
            "include:$true"
          ]
        },
        {
          type = "WindowsRestart"
        }
      ]
      distribute = [
        {
          artifactTags      = {}
          runOutputName     = "runOutputImageVersion"
          type              = "SharedImage"
          excludeFromLatest = false
          galleryImageId    = azurerm_shared_image.demo-image.id
          replicationRegions = [
            var.location
          ]
        }
      ]
      optimize = {
        vmBoot = {
          state = "Enabled"
        }
      }
      source = {
        type      = "PlatformImage"
        offer     = "WindowsServer"
        publisher = "MicrosoftWindowsServer"
        sku       = "2022-datacenter-azure-edition"
        version   = "latest"
      }
      vmProfile = {
        osDiskSizeGB = 127
        vmSize       = "Standard_DS1_v2"
      }
    }
  })
}
