param($websiteName = "sfazurewebsite",
      $location = "West Europe",
      $resourceGroupName = 'Default-Web-WestEurope',
      $sku = "Standard", # sku: "Free", "Shared", "Basic", "Standard", "Premium" (deafultValue is "Free")
      $workerSize = "1" # workerSize: "0", "1", "2" ("0" = Small, "1" = Medium, "2" = Large deafultValue is "0")
      ) 


Switch-AzureMode AzureResourceManager
#Switch-AzureMode AzureServiceManagement

#NOTE:
#The AzureResourceManager module requires Add-AzureAccount. A Publish Settings file is not sufficient.
Add-AzureAccount

$appServicePlanName = $websiteName + "_appServicePlan"
# Create a new App Service plan
$p=@{"name"= $appServicePlanName;"sku"= $sku;"workerSize"= $workerSize;"numberOfWorkers"= 1}
New-AzureResource -ApiVersion 2014-04-01 -Name $appServicePlanName -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/serverFarms -Location $location -PropertyObject $p -Verbose -Force

# Changing pricing tier
$p = @{ 'serverFarm' = $appServicePlanName }
Set-AzureResource -Name $websiteName -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/sites -ApiVersion 2014-04-01 -PropertyObject $p -Force

# Directly create site with the specific pricing plan and deploy package e.g.
#New-AzureResource -Name $websiteName -ResourceGroupName $resourceGroupName -Location $location -ResourceType Microsoft.Web/sites -ApiVersion 2014-04-01 -PropertyObject $p -Force

#Switch-AzureMode AzureServiceManagement
#Publish-AzureWebsiteProject -Name $websiteName -Package "C:\temp\azurewebsites\Projects\azurewebsitestest\pkg\_PublishedWebsites\SitefinityWebApp_Package\SitefinityWebApp.zip"