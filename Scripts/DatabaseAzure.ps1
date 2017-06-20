. "$PSScriptRoot\Common.ps1"
$sqlpackageExe = Get-SqlPackageExePath

# e.g. $bacpacDatabaseFile="C:\temp\DatabaseName.bacpac"
function CreateDatabasePackage($sqlServer, $databaseName, $bacpacDatabaseFile)
{   
    LogMessage "Creating database package..."
    & $sqlpackageExe /a:Export /ssn:$sqlServer /sdn:$databaseName /tf:$bacpacDatabaseFile
    LogMessage "Database package has been created."
}

function DeployDatabasePackage($bacpacDatabaseFile, $databaseName, $azureServer, $user, $password)
{
    LogMessage "Importing database package..."
    try
    {
    & $sqlpackageExe /a:Import /sf:$bacpacDatabaseFile /tsn:$azureServer /tdn:$databaseName /tu:$user /tp:$password /p:DatabaseEdition="Basic"
    } catch {
        if(!($_.Exception.Message -ne $null -and $_.Exception.Message.Contains("compatibility issues with SQL Azure")))
        {
            throw $_.Exception
        }
    }
    LogMessage "Database package has been imported"
}

# The serverName must the be just the name of the azure server e.g. "servername" and not the full server address "vdxlfno62c.database.windows.net"
function DeleteAzureDatabase($serverName, $databaseName, $user, $password)
{
    $db_password = ConvertTo-SecureString -String $password -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $db_password
    $context = New-AzureSqlDatabaseServerContext -ServerName $serverName -Credential $credential
    LogMessage "Deleting $databaseName from Azure $serverName server..."
    Remove-AzureSqlDatabase -Context $context -DatabaseName $databaseName -Force
    LogMessage "$databaseName database deleted from Azure $serverName server."
}

function EnsureDBDeleted($sqlServer, $dbName)
{
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
    $Server = New-Object Microsoft.SqlServer.Management.Smo.Server($sqlServer)
    $DBObject = $Server.Databases[$dbName]
    if ($DBObject)
    {
	    LogMessage "Deleting '$dbName' database from '$sqlServer' SQL Server."
		$Server.KillAllProcesses($dbName)
	    $Server.KillDatabase($dbName)
    }
}

function ImportDatabaseFromAzure($azureServer, $databaseName, $user, $password, $sqlServer)
{
    LogMessage "Exporting '$databaseName' database from '$azureServer' azure server..."
    $bacpacDatabaseFile = "$PSScriptRoot\$databaseName.bacpac"
    & $sqlpackageExe /a:Export /ssn:$azureServer /sdn:$databaseName /su:$user /sp:$password /tf:$bacpacDatabaseFile

    EnsureDBDeleted $sqlServer $databaseName

    LogMessage "Importing '$databaseName' database from '$azureServer' azure server..."
    & $sqlpackageExe /a:Import /sf:$bacpacDatabaseFile /tdn:$databaseName /tsn:$sqlServer

    Remove-Item $bacpacDatabaseFile
}

function BackupDatabase($sqlServer, $databaseName, $bakupFolder)
{
    New-Item -ItemType Directory -Path $bakupFolder -Force
    $dbBakFullPath = $bakupFolder+"\" + $databaseName +".bak"
    SQLCMD.EXE -S $sqlServer -E -q "exit(BACKUP DATABASE [$databaseName] TO DISK='$dbBakFullPath')"
}