resource "azapi_resource" "image-template" {
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2024-02-01"
  name      = "Win2022Web-template"
  parent_id = azurerm_resource_group.demo-rg.id
  location  = var.location
  body = {
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
          sourceUri   = azurerm_storage_blob.webpage.url
          destination = "C:\\ImageBuilderWebApp\\index.html"
        },
        {
          name        = "setupwebsite"
          type        = "PowerShell"
          scriptUri   = azurerm_storage_blob.pwshscript.url
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
        vmSize       = "Standard_D2s_v3"
        vnetConfig = {
          subnetId                  = azurerm_subnet.aib-subnet.id
          containerInstanceSubnetId = azurerm_subnet.aci-subnet.id
        }
      }
    }
  }
  depends_on = [azurerm_role_assignment.gallery-role-assignment, azurerm_role_assignment.storage-role-assignment, azurerm_role_assignment.vnet-role-assignment]
}

resource "terraform_data" "buildImage" {
  triggers_replace = [timestamp()]

  provisioner "local-exec" {
    command = "az resource invoke-action --resource-group ${azurerm_resource_group.demo-rg.name} --resource-type Microsoft.VirtualMachineImages/imageTemplates -n ${azapi_resource.image-template.name} --action Run"
  }

  depends_on = [
    azapi_resource.image-template
  ]
}
