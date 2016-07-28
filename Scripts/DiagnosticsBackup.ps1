param(
    [Parameter(Mandatory=$True)]$databaseName,
    [Parameter(Mandatory=$True)]$sqlServer,
	[Parameter(Mandatory=$True)]$websiteDirectory,
    [Parameter(Mandatory=$True)]$outputDirectory,
    [Parameter(Mandatory=$True)]$buildNumber
)

$sqlScriptLocation = Join-Path $PSScriptRoot "InstallSitefinity\SQL.ps1"
. $sqlScriptLocation

$databaseOutputDirectory = Join-Path $outputDirectory "\$buildNumber\db"
$configOutputDirectory = Join-Path $outputDirectory "\$buildNumber\Configuration"

$configLocation = Join-Path $websiteDirectory "\App_Data\Sitefinity\Configuration"
$databaseBackupLocation = Join-Path $websiteDirectory "\App_Data"
$databaseBackupFile = Join-Path $databaseBackupLocation "$databaseName.bak"

Write-Warning "Backing up database..."
BackupDatabase $sqlServer $databaseName $databaseBackupLocation
New-Item -ItemType Directory -Path $databaseOutputDirectory -Force
if((Test-Path $databaseBackupFile) -and (Test-Path $databaseOutputDirectory))
{
	Move-Item -Path $databaseBackupFile -Destination $databaseOutputDirectory -Force -ErrorAction stop
}

Write-Warning "Backing up config files..."
Copy-Item -Path $configLocation -Destination $configOutputDirectory -Recurse -Force -ErrorAction stop