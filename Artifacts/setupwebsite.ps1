# Install IIS Website
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Setup IIS
Import-Module IISadministration
New-IISSite -name ImageBuilderWebApp -PhysicalPath C:\ImageBuilderWebApp -BindingInformation "*:8080:"