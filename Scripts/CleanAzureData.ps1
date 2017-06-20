param($azureDatabaseName,
	  $cloudServiceName,
	  $storageAccountName,
      $accountLocation = "West Europe")

. "$PSScriptRoot\Modules.ps1"


$sqlConfig = $config.azure.sql | Where-Object { $_.location -eq $accountLocation }


if($azureDatabaseName)
{
	DeleteAzureDatabase $sqlConfig.serverName $azureDatabaseName $sqlConfig.user $sqlConfig.password
}
else
{
	Write-Host "Database name is empty. Database cleanup will be skipped." -ForegroundColor Red
}

if($cloudServiceName)
{
	RemoveCloudService $cloudServiceName 
}
else
{
	Write-Host "Cloud Service name is empty. Cloud Service cleanup will be skipped." -ForegroundColor Red
}

if($storageAccountName)
{
	RemoveStorageAccount $storageAccountName
}
else
{
	Write-Host "Storage Account name is empty. Storage Account cleanup will be skipped." -ForegroundColor Red
}