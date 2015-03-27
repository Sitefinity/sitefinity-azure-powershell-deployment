# Sitefinity Azure PowerShell Deployment Scripts

The repository contains scripts for easily Sitefinity deployment on Azure

## Requirements
- Powershell 3.0+
- Microsoft Azure Authoring Tools
- Microsoft Azure Compute Emulator
- Microsoft Azure Libraries for .NET
- Microsoft Azure Powershell
- Microsoft Azure Storage Tools
- Microsoft Azure Storage Emulator
- Microsoft Azure Tools for Microsoft Visual Studio

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

## Running the scripts

#### Run the script for Deploying Sitefinity to Azure

.\DeploySitefinityToAzure.ps1 -websiteRootDirectory "C:\temp\SitefinityWebApp" -databaseName "SfDB1" -sqlServer ".\SQLSERVER" -serviceName "myservicename" -storageAccountName "mystorageaccname" -enableRemoteDesktopAccess "true" -enableSsl "false"


#### Run the script for cleaning the Azure storage, service and database

.\CleanAzureData.ps1 -azureDatabaseName "SfDB1" -cloudServiceName "myservicename" -storageAccountName "mystorageaccname"
