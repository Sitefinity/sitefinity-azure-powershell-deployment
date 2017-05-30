<#

.SYNOPSIS
Script to deploy web app to Azure App Services.

.DESCRIPTION
This Powershell Script applies the required modifications and deploys the database and the sitefinity web app
to Azure App Services.

.EXAMPLE
.\DeploySitefinityToAzureAppService.ps1 -$websiteRootDirectory "C:\SitefinityWebApp_10_0_6400_0\testdeployment" -databaseName "testdeploymentdb" -sqlServer ".\SQLSERVER" -websiteName "testdeployment"

#>
 param([Parameter(Mandatory=$True)]$websiteRootDirectory,
      [Parameter(Mandatory=$True)]$databaseName,
      [Parameter(Mandatory=$True)]$sqlServer,
      [Parameter(Mandatory=$True)]$websiteName,
      $redisCacheConnectionString,
      $websiteLocation = "West Europe",
      $deployDatabase = $true,
      $buildConfiguration = "Release",
      $launchWebsite = $true)

. "$PSScriptRoot\Modules.ps1"

$sitefinityProject = Join-Path $websiteRootDirectory "SitefinityWebApp.csproj"
$bacpacDatabaseFile = "$PSScriptRoot\temp\$databaseName.bacpac"

$sqlConfig = $config.azure.sql | Where-Object { $_.location -eq $websiteLocation }

Write-Host "Sql server is set to : $($sqlConfig.server)"
$sqlConnectionUser = $sqlConfig.user
$sqlConnectionServer = $sqlConfig.server
$sqlConnectionUsername = "$sqlConnectionUser@$sqlConnectionServer" 

$systemConfigPath = Join-Path $websiteRootDirectory "App_Data\Sitefinity\Configuration\SystemConfig.config"
$outputPath = Join-Path $websiteRootDirectory "pkg"
$buildParameters = "OutputPath=$outputPath;IgnoreDeployManagedRuntimeVersion=true;FilesToIncludeForPublish=AllFilesInProjectFolder"

# Configure powershell with publishsettings for your subscription
Import-AzurePublishSettingsFile "$PSScriptRoot\$($config.files.subscriptionPublishSettings)"
Set-AzureSubscription -SubscriptionName $config.azure.subscription
Select-AzureSubscription -SubscriptionName $config.azure.subscription
$subscription = Get-AzureSubscription $config.azure.subscription
LogMessage "Azure Cloud Service deploy script started."
LogMessage "Preparing deployment of $deploymentLabel for $($subscription.subscriptionname) with Subscription ID $($subscription.subscriptionid)."

LogMessage 'Add-AzureWebsite: Start'
$website = Get-AzureWebsite -Name $websiteName -ErrorAction SilentlyContinue

if ($website)
{
    LogMessage ('Add-AzureWebsite: An existing web site ' +
    $website.Name + ' was found')
}
else
{
    if (Test-AzureName -Website -Name $websiteName)
    {
       LogMessage ('Website {0} already exists' -f $websiteName)
    }
    else
    {
        $website = New-AzureWebsite -Name $websiteName -Location $websiteLocation -Verbose
    }
}

$website | Out-String | Write-Host
LogMessage 'Add-AzureWebsite: End'

# Deploying Sitefinity database 
# First the database is packed from local isntance and then imported to the destination Azure server
if($deployDatabase)
{
    CreateDatabasePackage $sqlServer $databaseName $bacpacDatabaseFile 
    DeployDatabasePackage $bacpacDatabaseFile $databaseName $sqlConfig.server $sqlConnectionUsername $sqlConfig.password 
}
else
{
    Write-Host "Deploy Database parameter set to: $deployDatabase. Skipping database deployment..."
}

# Update Sitefinity web.config and DataConfig.config with database settings.
UpdateSitefinityWebConfig $websiteRootDirectory
UpdateSitefinityDataConfig $websiteRootDirectory $sqlConfig.server $sqlConnectionUsername $sqlConfig.password $databaseName

if([string]::IsNullOrEmpty($redisCacheConnectionString))
{
	LogMessage "Redis connection string not specified. Skipping redis configuration"
}
else
{
	# Configure Redis Cache
	. "$PSScriptRoot\ConfigureRedisCache.ps1" $systemConfigPath $redisCacheConnectionString
	. "$PSScriptRoot\ConfigureTestNlbHandlers.ps1" $systemConfigPath
}

# Build deployment package
BuildSln $sitefinityProject "Package" $buildConfiguration $buildParameters

$sfPackageLocationPath =  Get-ChildItem $outputPath -Recurse -Include "SitefinityWebApp.zip"
LogMessage "Publishing deployment package '$sfPackageLocationPath'..."
Publish-AzureWebsiteProject -Name $websiteName -Package $sfPackageLocationPath

LogMessage "Azure websites deployment has completed."
if ($launchWebsite -eq "true")
{
    LogMessage "Opening '$websiteName' site..."
	Show-AzureWebsite -Name $websiteName
}
