param([Parameter(Mandatory=$True)]$bacpacDatabaseFile,
      [Parameter(Mandatory=$True)]$azurePackage,
      [Parameter(Mandatory=$True)]$databaseName,
      [Parameter(Mandatory=$True)]$serviceName,
      [Parameter(Mandatory=$True)]$storageAccountName,
	  $vmSize = "Medium",
	  $enableRemoteDesktopAccess = "true",
      $enableDiagnostics = "true",
      $enableSsl = "false",
      $deployDatabase = "true",
      $accountLocation = "West Europe")
      
. "$PSScriptRoot\Modules.ps1"

$serviceName = $serviceName.ToLower()
$storageAccountName = $storageAccountName.ToLower()

$deploymentLabel = "ContinuousDeploy to $servicename"
$slot = $config.azure.environment
$licenseDomains = "$serviceName.cloudapp.net"
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
    $certificatePath = Resolve-Path "$PSScriptRoot\$($config.certificate.path)"

	Write-Host "Cleaning up Azure Subscriptions"
	Get-AzureSubscription | % { Remove-AzureSubscription $_.SubscriptionName -Force } 

    #configure powershell with publishsettings for your subscription
    Import-AzurePublishSettingsFile $subscriptionPublishSettingsPath
    Set-AzureSubscription -CurrentStorageAccountName $storageAccountName -SubscriptionName $config.azure.subscription
    Select-AzureSubscription -SubscriptionName $config.azure.subscription
    $subscription = Get-AzureSubscription $config.azure.subscription

    LogMessage "Azure Cloud Service deploy script started."
    LogMessage "Preparing deployment of $deploymentLabel for $($subscription.subscriptionname) with Subscription ID $($subscription.subscriptionid)."
    
    if($deployDatabase -eq "true")
    {        
        DeleteAzureDatabase $sqlConfig.serverName $databaseName $sqlConfig.user $sqlConfig.password
	    DeployDatabasePackage $bacpacDatabaseFile $databaseName $sqlConfig.server $sqlConnectionUsername $sqlConfig.password
	    UpdateSQLAzureServerInfoData $databaseName $databaseName            
    }
    else
    {
        Write-Host "Deploy Database parameter set to: $deployDatabase. Skipping database deployment..."
    }
    
	$serv = CreateCloudService $serviceName $accountLocation
	$acc = CreateStorageAccount $storageAccountName $accountLocation
	UpdateAzureSubscriptionData $acc.AccountName  $serv.ServiceName  $acc.AccountName $accountLocation
	UpdateServiceConfigurationCloudData $acc.AccountName $acc.AccessKey
    if($enableSsl -eq "true" -or $enableRemoteDesktopAccess -eq "true")
    {        
        AddCertificateToService $serviceName $certificatePath $config.certificate.password
        AddCertificatesNode
    } else {
        DeleteCertificatesNode
    }
    ConfigureSsl -EnableSsl $enableSsl
    ConfigureRemoteDesktop -EnableRemoteDesktopAccess $enableRemoteDesktopAccess
	UpdateVMSize -ServiceDefinitionPath "$serviceDefinitionPath" -VMSize $vmSize
             
    Publish $serv.ServiceName $acc.AccountName $azurePackage $cloudConfigPath $config.azure.environment $deploymentLabel $config.azure.timeStampFormat $config.azure.alwaysDeleteExistingDeployments $config.azure.enableDeploymentUpgrade $config.azure.subscription $subscriptionPublishSettingsPath

    if($enableRemoteDesktopAccess -eq "true")
    {
        Generate-RdpAccessFile -serviceName $serviceName -outputPath $accessCredentialsOutputPath
    }

    if($enableDiagnostics -eq "true")
    {
        LogMessage "Setting AzureServiceDiagnosticsExtension..."
        $storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $config.azure.storageAccountKey   
        Set-AzureServiceDiagnosticsExtension -ServiceName $serviceName -DiagnosticsConfigurationPath $diagnosticsConfigPath -StorageContext $storageContext -Role $config.azure.roleName
    }
}
finally
{
    LogMessage "Azure deployment has completed."
}