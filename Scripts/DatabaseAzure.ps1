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

function EnsureDBDeleted($sqlServer, $dbName)
{
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
    $Server = New-Object Microsoft.SqlServer.Management.Smo.Server($sqlServer)
    $DBObject = $Server.Databases[$dbName]
    if ($DBObject)
    {
	    LogMessage "Deleting '$dbName' database from '$sqlServer' SQL Server."
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

function GenerateUniqueAdminCredentials([string]$sqlServer, [string]$databaseName, [int]$usernameLength = 10, [int]$passwordLength = 12)
{
    $username = Generate-RandomUsername -length $usernameLength
    $password = Generate-RandomPassword -length $passwordLength
    
	$result = GenerateAdminCredentials $sqlServer $databaseName $username $password

    return $result
}

function GenerateAdminCredentials([string]$sqlServer, [string]$databaseName, [string]$username, [string]$password)
{
	$email = "$username@progress.com"
    $id = [guid]::NewGuid()
    $result = $null

    $resourcesPath = Resolve-Path "$PSScriptRoot\Resources"
    $createUserSqlQueryPath = Resolve-Path "$resourcesPath\CreateUser.sql"
    $outputQueryPath = Join-Path $resourcesPath "createUserOutputQuery.txt"

    SQLCMD.EXE -S $sqlServer -E -v DatabaseName=$databaseName Username=$username Password=$password Email=$email Id=$id -i $createUserSqlQueryPath -o $outputQueryPath

    if((Test-Path $outputQueryPath) -and (IsQuerySuccessfullyExecuted -outputQueryPath $outputQueryPath -databaseName $databaseName -numberOfAffectedRows 2))
    {
        $result = "Username: $username;`r`nPassword: $password;`r`nEmail: $email;`r`nId: $id;`r`nCreatedBy: $env:USERDNSDOMAIN\$env:USERNAME"
        Write-Warning "Successfully created user with: $result"
    }
    else
    {
        Write-Error "No output from query found at $outputQueryPath."
    }

	return $result
}

function DeleteDefaultAdminUser([string]$sqlServer, [string]$databaseName, [string]$username="admin")
{
    $resourcesPath = Resolve-Path "$PSScriptRoot\Resources"
    $deleteDefaultAdminQueryPath = Resolve-Path "$resourcesPath\DeleteDefaultAdminUser.sql"
    $outputQueryPath = Join-Path $resourcesPath "deleteDefaultAdminOutputQuery.txt"

    SQLCMD.EXE -S $sqlServer -E -v DatabaseName=$databaseName Username=$username -i $deleteDefaultAdminQueryPath -o $outputQueryPath

    if((Test-Path $outputQueryPath) -and (IsQuerySuccessfullyExecuted -outputQueryPath $outputQueryPath -databaseName $databaseName -numberOfAffectedRows 2))
    {
        $result = "Default Administrator User with username: $username has been successfully deleted."
        Write-Warning $result
    }

    return $result
}

function IsQuerySuccessfullyExecuted([string]$outputQueryPath, [string]$databaseName, [int]$numberOfAffectedRows)
{  
    $result = $false
    #Ensure query completed successfully.
    $databaseContextChanged = Get-Content $outputQueryPath | Select | Where {$_ -eq "Changed database context to '$databaseName'."}
    $rowsAffected = Get-Content $outputQueryPath | Select | Where {$_ -eq "(1 rows affected)"}
    if($databaseContextChanged -and $rowsAffected.Count -eq $numberOfAffectedRows)
    {
        Write-Warning "Query execution finished."
        $result = $true    
    }
    else
    {
        Write-Error "Query executed with errors. Query output: $(Get-Content $outputQueryPath)" 
    }
    
    return $result
}