. "$PSScriptRoot\Common.ps1"
$sqlpackageExe = Get-SqlPackageExePath

# e.g. $bacpacDatabaseFile="C:\temp\DatabaseName.bacpac"
#Creates azure database package locally by exporting the data from Sitefinity's database
function CreateDatabasePackage($sqlServer, $databaseName, $bacpacDatabaseFile)
{   
    LogMessage "Creating database package..."
    & $sqlpackageExe /a:Export /ssn:$sqlServer /sdn:$databaseName /tf:$bacpacDatabaseFile
    LogMessage "Database package has been created."
}

#Deploys Azure database package to azure database server
function DeployDatabasePackage($bacpacDatabaseFile, $databaseName, $azureServer, $user, $password)
{
    LogMessage "Importing database package..."
    try
    {
    & $sqlpackageExe /a:Import /sf:$bacpacDatabaseFile /tsn:$azureServer /tdn:$databaseName /tu:$user /tp:$password
    } catch {
        if(!($_.Exception.Message -ne $null -and $_.Exception.Message.Contains("compatibility issues with SQL Azure")))
        {
            throw $_.Exception
        }
    }
    LogMessage "Database package has been imported"
}

# The serverName must the be just the name of the azure server e.g. "servername" and not the full server address "servername.database.windows.net"
function DeleteAzureDatabase($serverName, $databaseName, $user, $password)
{
    $db_password = ConvertTo-SecureString -String $password -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $db_password
    $context = New-AzureSqlDatabaseServerContext -ServerName $serverName -Credential $credential
    LogMessage "Deleting $databaseName from Azure $serverName server..."
    Remove-AzureSqlDatabase -Context $context -DatabaseName $databaseName -Force
    LogMessage "$databaseName database deleted from Azure $serverName server."
}