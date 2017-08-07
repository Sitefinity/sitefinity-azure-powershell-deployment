<#

.SYNOPSIS
Script to deploy web app to Azure Cloud Services.

.DESCRIPTION
This Powershell Script applies the required modifications and deploys the database and the sitefinity web app
to Azure Cloud Services.

.EXAMPLE
.\DeploySitefinityToAzureCloudService.ps1 -$websiteRootDirectory "C:\SitefinityWebApp_10_0_6400_0\testdeployment" -databaseName "testdeploymentdb" -sqlServer ".\SQLSERVER" -serviceName "testdeployment" -storageAccountName "testdeployment"

#>
param([Parameter(Mandatory=$True)]$websiteRootDirectory,
      [Parameter(Mandatory=$True)]$databaseName,
      [Parameter(Mandatory=$True)]$sqlServer,
      [Parameter(Mandatory=$True)]$serviceName,
      [Parameter(Mandatory=$True)]$storageAccountName,
	  $vmSize = "Medium",
	  $enableRemoteDesktopAccess = "true",
      $enableDiagnostics = "true",
      $enableSsl = "false",
      $enableRedisCache = "false",
      $deployDatabase = "true",
      $instanceCount = '1',
      $accountLocation = "West Europe"
)
      
. "$PSScriptRoot\Modules.ps1"

$serviceName = $serviceName.ToLower()
$storageAccountName = $storageAccountName.ToLower()
New-Item "$PSScriptRoot\temp" -ItemType "Directory" -Force
$bacpacDatabaseFile = "$PSScriptRoot\temp\$databaseName.bacpac"
$azurePackage = "$PSScriptRoot\temp\cloud_package.cspkg"
$azureStartupTaskScripts = "$PSScriptRoot\..\CloudConfigs\StartupTasks"
$startupTasksTargetDirectory = Join-Path $websiteRootDirectory "\bin\"
$deploymentLabel = "ContinuousDeploy to $servicename"
$slot = $config.azure.environment
$serviceUrl = "$serviceName.cloudapp.net"
$azureTempFilesDir = Join-Path $env:APPDATA "Windows Azure Powershell"

$sqlConfig = $config.azure.sql | Where-Object { $_.location -eq $accountLocation }

Write-Host "Sql server is set to : $($sqlConfig.server)"
$sqlConnectionUser = $sqlConfig.user
$sqlConnectionServer = $sqlConfig.server
$sqlConnectionUsername = "$sqlConnectionUser@$sqlConnectionServer" 

try
{
    $serviceDefinitionPath = Resolve-Path "$PSScriptRoot\$($config.files.serviceDefinition)"
    $cloudConfigPath = Resolve-Path "$PSScriptRoot\$($config.files.cloudConfig)"
    $subscriptionPublishSettingsPath = Resolve-Path "$PSScriptRoot\$($config.files.subscriptionPublishSettings)"
    $rolePropertiesPath = Resolve-Path "$PSScriptRoot\$($config.files.roleProperties)"
    $diagnosticsConfigPath = Resolve-Path "$PSScriptRoot\$($config.files.diagnosticsConfig)"

	Write-Host "Cleaning up Azure Subscriptions"
	Get-AzureSubscription | % { Remove-AzureSubscription $_.SubscriptionName -Force } 

    Write-Host "Cleaning up temp Azure Powershell Files from $azureTempFilesDir"
    Get-ChildItem $azureTempFilesDir | % { Remove-Item $_.FullName }

    #configure powershell with publishsettings for your subscription
    Import-AzurePublishSettingsFile $subscriptionPublishSettingsPath

    $acc = CreateStorageAccount $storageAccountName $accountLocation
    Set-AzureSubscription -CurrentStorageAccountName $storageAccountName -SubscriptionName $config.azure.subscription
    Select-AzureSubscription -SubscriptionName $config.azure.subscription
    $subscription = Get-AzureSubscription $config.azure.subscription

    LogMessage "Azure Cloud Service deploy script started."
    LogMessage "Preparing deployment of $deploymentLabel for $($subscription.subscriptionname) with Subscription ID $($subscription.subscriptionid)."
    
    if($deployDatabase -eq "true")
    {        
		CreateDatabasePackage $sqlServer $databaseName $bacpacDatabaseFile 
		DeployDatabasePackage $bacpacDatabaseFile $databaseName $sqlConfig.server $sqlConnectionUsername $sqlConfig.password
		UpdateSQLAzureServerInfoData $databaseName $databaseName             
    }
    else
    {
        Write-Host "Deploy Database parameter set to: $deployDatabase. Skipping database deployment..."
    }
    
    #Copies all startup task scripts to the website binaries directory.
	robocopy $azureStartupTaskScripts $startupTasksTargetDirectory

    UpdateInstancesCount $instanceCount

    if([int]$instanceCount -gt 1)
    {
	UpdateSitefinityWebConfig $websiteRootDirectory
    }
    if($enableDiagnostics -eq "true")
    {
        EnableAzureTraceListener $websiteRootDirectory
    }

	UpdateSitefinityDataConfig $websiteRootDirectory $sqlConfig.server $sqlConnectionUsername $sqlConfig.password $databaseName
    
    if($enableRedisCache -eq "true")
    {
        #The AzureResourceManager module requires Add-AzureAccount. A Publish Settings file is not sufficient.
        $secpassword = ConvertTo-SecureString $config.azure.azureAccountPassword -AsPlainText -Force
        $credentials = New-Object System.Management.Automation.PSCredential ($config.azure.azureAccount, $secpassword)
        Add-AzureRmAccount -Credential $credentials
		Select-AzureSubscription $config.azure.subscription
        $redisCacheName = "$($serviceName)redis"
        $redisPrimaryKey = NewAzureRedisCache -CacheName $redisCacheName -ResourceGroupName $config.azure.resourceGroupName -Location $config.azure.accountsLocation
        $redisCacheConnectionString = "$redisPrimaryKey@$redisCacheName.redis.cache.windows.net?ssl=true"
        $systemConfigPath = "$websiteRootDirectory\App_Data\Sitefinity\Configuration\SystemConfig.config"
        LogMessage "RedisCache connection string: '$redisCacheConnectionString'"
        . "$PSScriptRoot\..\..\CommonScripts\PowerShell\Common\SitefinitySetup\ConfigureRedisCache.ps1" $systemConfigPath $redisCacheConnectionString
    }
    
	$serv = CreateCloudService $serviceName $accountLocation

	UpdateAzureSubscriptionData $acc.AccountName  $serv.ServiceName  $acc.AccountName $accountLocation
	UpdateServiceConfigurationCloudData $acc.AccountName $acc.AccessKey
    if($enableSsl -eq "true" -or $enableRemoteDesktopAccess -eq "true")
    {  
       $certificatePath = Resolve-Path "$PSScriptRoot\$($config.certificate.path)"
       AddCertificateToService $serviceName $certificatePath $config.certificate.password
       AddCertificatesNode
    } else {
       DeleteCertificatesNode
    }
    ConfigureSsl -EnableSsl $enableSsl
    ConfigureRemoteDesktop -EnableRemoteDesktopAccess $enableRemoteDesktopAccess
	UpdateVMSize -ServiceDefinitionPath "$serviceDefinitionPath" -VMSize $vmSize
             
    CreatePackage $serviceDefinitionPath $azurePackage $websiteRootDirectory $config.azure.roleName $rolePropertiesPath
    Publish $serv.ServiceName $acc.AccountName $azurePackage $cloudConfigPath $config.azure.environment $deploymentLabel $config.azure.timeStampFormat $config.azure.alwaysDeleteExistingDeployments $config.azure.enableDeploymentUpgrade $config.azure.subscription $subscriptionPublishSettingsPath

    if($enableDiagnostics -eq "true")
    {
        LogMessage "Setting AzureServiceDiagnosticsExtension..."
        $storageAccountKey = (Get-AzureStorageKey -StorageAccountName $storageAccountName).Primary
        $storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey   
        Set-AzureServiceDiagnosticsExtension -ServiceName $serviceName -DiagnosticsConfigurationPath $diagnosticsConfigPath -StorageContext $storageContext -Role $config.azure.roleName
    }
}
finally
{
    LogMessage "Azure deployment has completed."
}
