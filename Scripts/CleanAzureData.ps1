param( [Parameter(Mandatory=$True)]$azureDatabaseName,
	   [Parameter(Mandatory=$True)]$cloudServiceName,
	   [Parameter(Mandatory=$True)]$storageAccountName
)

. "$PSScriptRoot\Modules.ps1"

DeleteAzureDatabase $config.azure.serverName $azureDatabaseName $config.azure.user $config.azure.password

RemoveCloudService $cloudServiceName 

RemoveStorageAccount $storageAccountName