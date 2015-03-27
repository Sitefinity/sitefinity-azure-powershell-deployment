param([Parameter(Mandatory=$True)]$websiteRootDirectory,
      [Parameter(Mandatory=$True)]$databaseName,
      [Parameter(Mandatory=$True)]$sqlServer,
      [Parameter(Mandatory=$True)]$serviceName,
      [Parameter(Mandatory=$True)]$storageAccountName,
	  $enableRemoteDesktopAccess = "true",
      $enableSsl = "false")
      
. "$PSScriptRoot\Modules.ps1"

$serviceName = $serviceName.ToLower()
$storageAccountName = $storageAccountName.ToLower()
New-Item "$PSScriptRoot\temp" -ItemType "Directory" -Force
$bacpacDatabaseFile = "$PSScriptRoot\temp\$databaseName.bacpac"
$azurePackage = "$PSScriptRoot\temp\cloud_package.cspkg"
$deploymentLabel = "ContinuousDeploy to $servicename"
$slot = $config.azure.environment

try
{
    #configure powershell with publishsettings for your subscription
    Import-AzurePublishSettingsFile $config.files.subscriptionPublishSettings
    Set-AzureSubscription -CurrentStorageAccount $storageAccountName -SubscriptionName $config.azure.subscription
    Select-AzureSubscription -SubscriptionName $config.azure.subscription
    $subscription = Get-AzureSubscription $config.azure.subscription
    LogMessage "Azure Cloud Service deploy script started."
    LogMessage "Preparing deployment of $deploymentLabel for $($subscription.subscriptionname) with Subscription ID $($subscription.subscriptionid)."
	CreateDatabasePackage $sqlServer $databaseName $bacpacDatabaseFile
	DeployDatabasePackage $bacpacDatabaseFile $databaseName $config.azure.server $config.azure.user $config.azure.password
	UpdateSQLAzureServerInfoData $databaseName $databaseName
	UpdateSitefinityWebConfig $websiteRootDirectory
	UpdateSitefinityDataConfig $websiteRootDirectory $config.azure.server $config.azure.user $config.azure.password $databaseName
	$serv = CreateCloudService $serviceName $config.azure.accountsLocation
	$acc = CreateStorageAccount $storageAccountName $config.azure.accountsLocation
	UpdateAzureSubscriptionData $acc.AccountName  $serv.ServiceName  $acc.AccountName $config.azure.accountsLocation
	UpdateServiceConfigurationCloudData $acc.AccountName $acc.AccessKey
    if($enableSsl -eq "true" -or $enableRemoteDesktopAccess -eq "true")
    {        
       AddCertificateToService $serviceName $config.certificate.path $config.certificate.password
       AddCertificatesNode
    } else {
       DeleteCertificatesNode
    }
    ConfigureSsl -EnableSsl $enableSsl
    ConfigureRemoteDesktop -EnableRemoteDesktopAccess $enableRemoteDesktopAccess
             
    CreatePackage $config.files.serviceDefinition $azurePackage $websiteRootDirectory $config.azure.roleName $config.files.roleProperties
    Publish $serv.ServiceName $acc.AccountName $azurePackage $config.files.cloudConfig $config.azure.environment $deploymentLabel $config.azure.timeStampFormat $config.azure.alwaysDeleteExistingDeployments $config.azure.enableDeploymentUpgrade $config.azure.subscription $config.files.subscriptionPublishSettings
}
finally
{
    LogMessage "Azure deployment has completed."
}