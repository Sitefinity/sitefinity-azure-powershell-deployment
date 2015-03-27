param( [Parameter(Mandatory=$True)]$azureDatabaseName,
	   [Parameter(Mandatory=$True)]$cloudServiceName,
	   [Parameter(Mandatory=$True)]$storageAccountName
)

. "$PSScriptRoot\Common.ps1"
. "$PSScriptRoot\DatabaseAzure.ps1"
. "$PSScriptRoot\ManageAzureServices.ps1"
. "$PSScriptRoot\ManageAzureStorage.ps1"

DeleteAzureDatabase $config.azure.serverName $azureDatabaseName $config.azure.user $config.azure.password

RemoveCloudService $cloudServiceName 

RemoveStorageAccount $storageAccountName