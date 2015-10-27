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
- Powershell 3.0+
- Microsoft Azure Authoring Tools
- Microsoft Azure Compute Emulator
- Microsoft Azure Libraries for .NET
- Microsoft Azure Powershell
- Microsoft Azure Storage Tools
- Microsoft Azure Storage Emulator
- Microsoft Azure Tools for Microsoft Visual Studio
- Microsoft Azure SDK 2.6 for .NET

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
## Azure WebApps Deployment

NOTE: #The AzureResourceManager module used for WebApps deployment requires Add-AzureAccount. A Publish Settings file is not sufficient. Microsoft account cannot be used with powershell credential object with the Add-AzureAccount command so for that purpose we use an azure user. Here is additional info: https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/
A resource group is a container that holds related resources for an application. The resource group could include all of the resources for an application, or only those resources that are logically grouped together. You can decide how you want to allocate resources to resource groups based on what makes the most sense for your organization. Azure Resource Manager templates enable you to quickly and easily provision your applications in Azure via declarative JSON. In a single JSON template, you can deploy multiple services, such as Virtual Machines, Virtual Networks, Storage, App Services, and databases. To simplify management of your application, you can organize all of the resources that share a common lifecycle into a single resource group.

#### Setup for Azure WebApps deployment

1. Fill in the data in the CloudConfigs -> Subscription1.publishsettings.
1. Set the **subscription** property in the Scripts -> Configuration -> config.json
1. Make sure there is a 'temp' folder inside Scripts. It is required when generating the database backup.
1. Create your own template file or use the Default one. Be careful with the values of some properties, because there are some policies. For example there are policies for the sqlServerName, sqlPassword and search index name.
1. (optional) To be able to sing-in to Azure with a non-work account via the script, in ManageAzureResourceGroup.ps1 remove the parameters for the **Add-AzureAccount** command. This way during execution a sign-in window will be shown instead.

#### Run the script for Deploying Sitefinity to Azure Websites
```powershell
.\CreateSitefinityAzureResourceGroup.ps1 -websiteRootDirectory "C:\temp\SitefinityWebApp" -databaseName "SfDB1" -sqlServer "SFSQLLOCALSERVER" -resourceGroupName "NAME_FOR_RESOURCE_GROUP" -azureAccount "AccountUsername" -azureAccountPassword "AccountPassword" -resourceGroupLocation "West Europe" -templateFile  "$PSScriptRoot\Templates\Default.json" -templateParameterFile "$PSScriptRoot\Templates\Default.params.json" -buildConfiguration "Release"
```
