# azure-image-builder-demos
Terraform code for the demos for Azure Image Builder.

## There are 3 demos for different networking options.

1. No VNET option: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-networking#deploy-without-specifying-an-existing-virtual-network

2. Existing VNET option: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-networking#deploy-using-an-existing-vnet

3. Isolated option (most secure): https://learn.microsoft.com/en-us/azure/virtual-machines/security-isolated-image-builds-image-builder

## Each demo creates a template and starts an image build for a Windows Server 2022 Azure Edition image from the Azure Marketplace with the below custimizations:

1. Install IIS service.
2. Install a index.html webpage in C:\ImageBuilderWebApp
3. Add a website listening on port 8080 (http) with the C:\ImageBuilderWebApp\index.html as the default homepage.
4. Run and install Windows updates.

### Before running Terraform, review the `variables.tf` file to change the default values of the variables or supply with a `terraform.tfvars` or `*.auto.tfvars` file in the same folder.