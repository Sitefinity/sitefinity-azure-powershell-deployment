# Sitefinity Azure PowerShell Deployment Scripts

The repository contains scripts for continuous deployment of Sitefinity sites to Azure. You can use the scripts to integrate your Sitefinity to scalable continues integration and automatic deployments. Scripts allow you to integrate uploads from source controls and repository tools like TFS, Git, and GitHub.
You can use scripts to publish Sitefinity directly from your local computer to Azure Web Apps (Azure Websites) and Azure Cloud Service.

# Features

- Azure Cloud Service Deployment -Highly available, scalable n-tier cloud apps with more control of the OS
- Azure Websites Deployment -Scalable Web Apps

Scripts automatically prepare your Sitefinity instance for deployment by modifying needed configurations. 

Scripts support configuration for
- Database instance - create SQL server or connect to existing one. If database doesn't exists new database is created and Sitefinity data is then imported to Azure Database.
- Redis Cache - create a new Redis Cache or use existing one. Note that it is better to use different Redis key prefixes for different instances in case you use one Redis Cache.
- Remote Desktop - option to connect to Cloud Service through remote desktop on the machine. This is not supported for Azure Websites.
- Extended Azure Logs - provides information about your Azure Role and thousands of metrics related to Azure environment
- NLB instances - allows to use Sitefinity in NLB scenario - your Sitefinity license must support NLB
- Azure Search - using Azure Search instead of built-in Lucene provider. Azure Search provides the engine for full-text search text analysis, advanced search features, search data storage, and a query command syntax
- Blob storage providers - use blob storage for your binary data instead of file system or database.  Blob storage service allows you to store Sitefinity large amounts of unstructured data, such as text or binary data( images or videos), that can be accessed from anywhere in the world via HTTP or HTTPS. You can use Blob storage to expose data publicly to the world, or to store application data privately
- Use of publish settings file (Management certificate authentication)

## Requirements
* Powershell 3.0+
* Microsoft Azure Powershell - https://github.com/Azure/azure-powershell/releases
* Microsoft Azure SDK 2.9.6 - https://www.microsoft.com/en-us/download/details.aspx?id=54289
  * Microsoft Azure Authoring Tools
  * Microsoft Azure Libraries for NET
* Data Tier Application (DAC) Framework - https://www.microsoft.com/en-us/download/confirmation.aspx?id=53013
* Web Deploy v.3.5 - https://www.microsoft.com/en-us/download/details.aspx?id=39277

## Azure Cloud Service Deployment

#### Update the **AzureSubscriptionData.config** file under **~\CloudConfigs** folder
 - Set your **SubscriptionId**
 - Set your **SubscriptionName**
 - Set your **DeploymentLabel**
 
#### Update the **Subscription1.publishsettings** file under **~\CloudConfigs** folder
 - Set your Subscription **Id**
 - Set your Subscription **Name**
 - Set your **ManagementCertificate**
 
#### Update the needed properties in the **config.json** file under **~\Scripts\Configuration** folder
- Set your azure **serverName**
- Set your azure **server**
- Set your azure **user**
- Set your azure **password**
- Set your azure **subscription**
- Set the **certificate** properties which is used for **Remote Desktop Access** and for **SSL endpoint**

### Using lower version of Azure SDK for .NET
If a lower version of Azure SDK for .NET than the specified in the requirements is used - make sure to update the **schemaVersion** attribute in:
-  CloudConfigs/ServiceConfiguration.Cloud.cscfg
-  CloudConfigs/ServiceConfiguration.Local.cscfg
-  CloudConfigs/ServiceDefinition.csdef

#### Run the script for Deploying Sitefinity to Azure Cloud Service
```powershell
.\DeploySitefinityToAzure.ps1 -websiteRootDirectory "C:\temp\SitefinityWebApp" -databaseName "SfDB1" -sqlServer ".\SQLSERVER" -serviceName "myservicename" -storageAccountName "mystorageaccname" -enableRemoteDesktopAccess "true" -enableSsl "false"
```
#### Run the script for cleaning the Azure storage, service and database
```powershell
.\CleanAzureData.ps1 -azureDatabaseName "SfDB1" -cloudServiceName "myservicename" -storageAccountName "mystorageaccname"
```
## Azure App Services Deployment

NOTE: #The AzureResourceManager module used for WebApps deployment requires Add-AzureAccount. A Publish Settings file is not sufficient. Microsoft account cannot be used with powershell credential object with the Add-AzureAccount command so for that purpose we use an azure user. Here is additional info: https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/
A resource group is a container that holds related resources for an application. The resource group could include all of the resources for an application, or only those resources that are logically grouped together. You can decide how you want to allocate resources to resource groups based on what makes the most sense for your organization. Azure Resource Manager templates enable you to quickly and easily provision your applications in Azure via declarative JSON. In a single JSON template, you can deploy multiple services, such as Virtual Machines, Virtual Networks, Storage, App Services, and databases. To simplify management of your application, you can organize all of the resources that share a common lifecycle into a single resource group.

#### Setup for Azure App Services deployment
1. Set Subscription Information
   1. Run ```Get-AzurePublishSettingsFile``` powershell command or simply navigate to https://manage.windowsazure.com/publishsettings/index?client=powershell to download the publish settings file for your subscription.
1. Replace the content of **.\CloudConfigs\Subscription1.publishsettings** with the content from the publishsettings you have download in the previous step.
1. Open .\CloudConfigs\AzureSubscriptionData.config and set the following values:
   1. **CertificateData** - located in the Subscription1.publishsettings file in the ManagementCertificate node
   1. **SubscriptionId** - located in the Subscription1.publishsettings file in the Id node.
   1. **SubscriptionName** - located in the Subscription1.publishsettings file in the Name node.
   1. **DeploymentLabel** - label by your choice.
1. Set SQL Server information in **.\Scripts\Configurations\config.json** under azure.sql
   1. **location** - this value is to differentiate multiple SQL Server instances in different location. Afterwards the script will know which SQL Server to choose by passing a location parameter. E.g. West Europe
   1. **serverName** - Azure SQL Server name in Azure (e.g. sitefinitysql)
   1. **server** - Full connection string of the Azure SQL Server (e.g. sitefinitysql.database.windows.net)
   1. **user** - Azure SQL user
   1. **password** - Azure SQL password
1. Open a new powershell session and run the script by specyfing the following parameters:
   1. **websiteRootDirectory** - path to the SitefinityWebApp
   1. **sqlServer** - the local instance of SQL Server (e.g. ".\SQLSERVER")
   1. **databaseName** - the database name of the SitefinityWebApp you will deploy
   1. **websiteName** - the app service name (website name) that will be created in azure
   1. **[Optional]redisCacheConnectionString** - set this if you want to use redis cache. The correct format of the connection string is the following: ```primaryAccessKey@redisCacheName.redis.cache.windows.net?ssl=true```
   1. **[Optional]websiteLocation** - Set where the location of the app service will be. This should match the SQL location property in the config.json you had applied in step. Default value is West Europe.
   1. **[Optional]buildConfiguration** - Set the build configuration in which your project will be built - Debug/Release/ReleasePro... Default value is Release
   1. **[Optional]launchWebsite** - if set, after the deployment finishes, powershell will make a request to the deployed website. Default value is $true
  

 **NOTE:** The scripts use default template file located in **.\Scripts\Templates\** You can use your own template file, but be careful with some of the properties, because there are some policies. For example there are policies for the sqlServerName, sqlPassword and search index name.
  

#### Run the script for Deploying Sitefinity to Azure App Services
```powershell
 .\DeploySitefinityToAzureAppService.ps1 -websiteRootDirectory "C:\Tests\Sitefinity_10_0_HF3\Projects\azureAppServiceDemo" -databaseName "azureAppServiceDemoDb" -sqlServer ".\SQLSERVER" -websiteName "azureappsvcsfdemo" -redisCacheConnectionString "l6b65PIJza3zamYsNto8/cvtwtvvs1G4ffPBL3V6ybo=@sfdemoredis.redis.cache.windows.net?ssl=true" -websiteLocation "West Europe" -deployDatabase $true -buildConfiguration "Release" -launchWebsite $true
```
