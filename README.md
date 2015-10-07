# Sitefinity Azure PowerShell Deployment Scripts

The repository contains scripts for easily Sitefinity deployment on Azure. You can use the scripts to integrate your Sitefinity to scalable continues integration and automatic deployments. 
Scripts support deployment to 
- Azure Cloud Service 
- Azure Websites

Scripts automatically prepare your Sitefinity instance for deployment by modifying needed settings. 

Scripts support configuration for
- Database instance - create SQL server or connect to existing one. If database doesn't exists new database is created and Sitefinity data then imported.
- Redis Cache - create a new Redis Cache or use existing one. Note that it is better to use different Redis key prefixes for different instances in case you use one Redis Cache
- Remote Desktop - option to connect to Cloud Service through remote desktop on the machine. This is not supported for Azure Websites
- Extended Azure Logs - provides information about your Azure Role and thousands of metrics related to Azure environment
- NLB instances - allows to use Sitefinity in NLB scenario - your Sitefinity license must support NLB
- Azure Search - using Azure Search instead of built-in Lucene provider
- Blob storage providers - use blob storage for your binary data instead of file system or database

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

## Getting Started

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

## Running the scripts

#### Run the script for Deploying Sitefinity to Azure

.\DeploySitefinityToAzure.ps1 -websiteRootDirectory "C:\temp\SitefinityWebApp" -databaseName "SfDB1" -sqlServer ".\SQLSERVER" -serviceName "myservicename" -storageAccountName "mystorageaccname" -enableRemoteDesktopAccess "true" -enableSsl "false"


#### Run the script for cleaning the Azure storage, service and database

.\CleanAzureData.ps1 -azureDatabaseName "SfDB1" -cloudServiceName "myservicename" -storageAccountName "mystorageaccname"
