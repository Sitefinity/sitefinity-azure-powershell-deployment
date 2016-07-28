param(
    $WebsiteRootDirectory = "",
    $DatabaseName = "",
    $SqlServer = "",
    $ResourceGroupName = "",
    $AzureAccount = "",
    $AzureAccountPassword = "",
    $ResourceGroupLocation = "West Europe",
    $TemplateFile = "$PSScriptRoot\Templates\Default.json",
    $TemplateParameterFile = "$PSScriptRoot\Templates\Default.params.json",
    $BuildConfiguration = "Release"
)

. "$PSScriptRoot\Modules.ps1"

$templateParams = Get-Settings $TemplateParameterFile

$sitefinityProject = Join-Path $websiteRootDirectory "SitefinityWebApp.csproj"
$bacpacDatabaseFile = "$PSScriptRoot\temp\$DatabaseName.bacpac"
$sqlConnectionUser = $templateParams.parameters.sqlServerAdminLogin.value
$sqlConnectionServer = "$($templateParams.parameters.sqlServerName.value).database.windows.net"
$sqlConnectionUsername = "$sqlConnectionUser@$sqlConnectionServer" 

$systemConfigPath = Join-Path $websiteRootDirectory "App_Data\Sitefinity\Configuration\SystemConfig.config"
$outputPath = Join-Path $websiteRootDirectory "pkg"
$buildParameters = "OutputPath=$outputPath;IgnoreDeployManagedRuntimeVersion=true;FilesToIncludeForPublish=AllFilesInProjectFolder"

# Create new azure resource group
NewAzureResourceGroup -ResourceGroupName $ResourceGroupName `
                      -ResourceGroupLocation $ResourceGroupLocation `
                      -AzureAccount $AzureAccount `
                      -AzureAccountPassword $AzureAccountPassword `
                      -TemplateFile $TemplateFile `
                      -TemplateParameterFile $TemplateParameterFile

# Configure powershell with publishsettings for your subscription
Import-AzurePublishSettingsFile "$PSScriptRoot\$($config.files.subscriptionPublishSettings)"
Set-AzureSubscription -SubscriptionName $config.azure.subscription
Select-AzureSubscription -SubscriptionName $config.azure.subscription

CreateDatabasePackage $sqlServer $DatabaseName $bacpacDatabaseFile 
DeployDatabasePackage $bacpacDatabaseFile $templateParams.parameters.sqlDatabaseName.value $sqlConnectionServer $templateParams.parameters.sqlServerAdminLogin.value $templateParams.parameters.sqlServerAdminLoginPassword.value

# Update Sitefinity web.config and DataConfig.config with database settings.
UpdateSitefinityWebConfig $websiteRootDirectory
UpdateSitefinityDataConfig $websiteRootDirectory $sqlConnectionServer $sqlConnectionUsername $templateParams.parameters.sqlServerAdminLoginPassword.value $templateParams.parameters.sqlDatabaseName.value

# Configure Redis Cache
$redisCacheName = $templateParams.parameters.redisCacheName.value
$redisPrimaryKey = GetAzureRedisCacheKey -ResourceGroupName $ResourceGroupName -CacheName $redisCacheName
$redisCacheConnectionString = "$redisPrimaryKey@$redisCacheName.redis.cache.windows.net?ssl=true"
LogMessage "RedisCache connection string: '$redisCacheConnectionString'"
. "$PSScriptRoot\..\..\CommonScripts\PowerShell\Common\SitefinitySetup\ConfigureRedisCache.ps1" $systemConfigPath $redisCacheConnectionString
. "$PSScriptRoot\..\..\CommonScripts\PowerShell\Common\SitefinitySetup\ConfigureTestNlbHandlers.ps1" $systemConfigPath

# Configure Azure Search Service
#$azureServiceAdminKey TODO
#$azureSearchServiceName = $templateParams.parameters.azureSearchName.value
#ConfigureAzureSearchService $config.files.searchConfig $azureServiceAdminKey $azureSearchServiceName
#Copy-Item $config.files.searchConfig "$websiteRootDirectory\App_Data\Sitefinity\Configuration" -Force

# Build deployment package
BuildSln $sitefinityProject "Package" $BuildConfiguration $buildParameters

$sfPackageLocationPath =  Get-ChildItem $outputPath -Recurse -Include "SitefinityWebApp.zip"
LogMessage "Publishing deployment package '$sfPackageLocationPath'..."
Publish-AzureWebsiteProject -Name $templateParams.parameters.siteName.value -Package $sfPackageLocationPath