param([Parameter(Mandatory=$True)]$websiteRootDirectory,
      [Parameter(Mandatory=$True)]$databaseName,
      [Parameter(Mandatory=$True)]$sqlServer,
      [Parameter(Mandatory=$True)]$serviceName,
      [Parameter(Mandatory=$True)]$storageAccountName,
      $workDirectory = "",
      $enableRedisCache = "false",
      $deployDatabase = "true",
      $instanceCount = '1',
	  $licenseVersion = "9.1",
	  $accountLocation = "West Europe",
	  $createIrisUser = "false")
      
. "$PSScriptRoot\Modules.ps1"

$serviceName = $serviceName.ToLower()
$storageAccountName = $storageAccountName.ToLower()

New-Item "$PSScriptRoot\temp" -ItemType "Directory" -Force

if([System.String]::IsNullOrEmpty($workDirectory))
{
    $workDirectory = "$PSScriptRoot\temp"
}

$bacpacDatabaseFile = "$workDirectory\$databaseName.bacpac"
$azurePackage = "$workDirectory\cloud_package.cspkg"

$azureStartupTaskScripts = "$PSScriptRoot\..\CloudConfigs\StartupTasks"
$startupTasksTargetDirectory = Join-Path $websiteRootDirectory "\bin\"
$licenseTargetDirectory = Join-Path $websiteRootDirectory "\App_Data\Sitefinity"
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
    $rolePropertiesPath = Resolve-Path "$PSScriptRoot\$($config.files.roleProperties)"

    Write-Host "Cleaning up temp Azure Powershell Files from $azureTempFilesDir"
    Get-ChildItem $azureTempFilesDir | % { Remove-Item $_.FullName }

	Write-Host "Generating license with following parameters: $licenseDomains $licenseVersion $licenseTargetDirectory"
	GetSitefinityLicense -domains $licenseDomains -version $licenseVersion -licenseFilePath $licenseTargetDirectory

    if($deployDatabase -eq "true")
    {        
        $generatedCredentials = GenerateUniqueAdminCredentials $sqlServer $databaseName
        if($generatedCredentials -ne $null)
        {
            DeleteDefaultAdminUser $sqlServer $databaseName

            $accessCredentialsOutputPath = Join-Path $config.azure.accessCredentialsOutputPath $serviceName
            if(!(Test-Path $accessCredentialsOutputPath))
            {
                New-Item $accessCredentialsOutputPath -ItemType Directory
            }

            Generate-AccessCredentialsFiles -credentialsInfo $generatedCredentials -outputPath $accessCredentialsOutputPath
        }

		if($createIrisUser -eq "true")
		{
			GenerateAdminCredentials $sqlServer $databaseName $config.iris.adminUsername $config.iris.adminPassword
		}

	    CreateDatabasePackage $sqlServer $databaseName $bacpacDatabaseFile 
             
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

	Write-Host "Updating DataConfig file"
	Write-Host "WebsiteRootDirectory is '$websiteRootDirectory'"
	Write-Host "Server is '$($sqlConfig.server)'"
	Write-Host "SqlConnectionUsername is '$sqlConnectionUsername'"
	Write-Host "Password is '$($sqlConfig.password)'"
	Write-Host "DatabaseName is '$databaseName'"

	UpdateSitefinityDataConfig $websiteRootDirectory $sqlConfig.server $sqlConnectionUsername $sqlConfig.password $databaseName
    
    if($enableRedisCache -eq "true")
    {
        #The AzureResourceManager module requires Add-AzureAccount. A Publish Settings file is not sufficient.
        $secpassword = ConvertTo-SecureString $config.azure.azureAccountPassword -AsPlainText -Force
        $credentials = New-Object System.Management.Automation.PSCredential ($config.azure.azureAccount, $secpassword)
        Add-AzureAccount -Credential $credentials
        $redisCacheName = "$($serviceName)redis"
        $redisPrimaryKey = NewAzureRedisCache -CacheName $redisCacheName -ResourceGroupName $config.azure.resourceGroupName -Location $config.azure.accountsLocation
        $redisCacheConnectionString = "$redisPrimaryKey@$redisCacheName.redis.cache.windows.net?ssl=true"
        $systemConfigPath = "$websiteRootDirectory\App_Data\Sitefinity\Configuration\SystemConfig.config"
        LogMessage "RedisCache connection string: '$redisCacheConnectionString'"
        . "$PSScriptRoot\..\..\CommonScripts\PowerShell\Common\SitefinitySetup\ConfigureRedisCache.ps1" $systemConfigPath $redisCacheConnectionString
    }

    CreatePackage $serviceDefinitionPath $azurePackage $websiteRootDirectory $config.azure.roleName $rolePropertiesPath
}
finally
{
    LogMessage "Preparing Azure pacakge has completed."
}