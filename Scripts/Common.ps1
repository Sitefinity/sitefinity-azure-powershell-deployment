 $MsBuildExe = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe"

function Ensure-File([string]$path) {
    if ([System.IO.File]::Exists($path) -eq $false) {
        throw (New-Object 'System.IO.FileNotFoundException' -ArgumentList("${path} does not exist."))
    }
}

function LogMessage($message)
{
    $currentTime = Get-Date -Format "HH:mm:ss"
    Write-Host "[[$currentTime]]::LOG:: $message"
}

function Get-Settings([string]$settingsPath) {
    Ensure-File -path $settingsPath

    $json = Get-Content $settingsPath -Raw
    $instance = $json | ConvertFrom-Json    

    return $instance
}

function Get-AzureSdkPath {
	param($azureSdkPath)
    if(!$azureSdkPath) 
	{
        if(!(Test-Path "$env:ProgramFiles\Microsoft SDKs\Azure\.NET SDK"))
        {
            $azureSdkPath = (dir "$env:ProgramFiles\Microsoft SDKs\Windows Azure\.NET SDK" -ErrorAction SilentlyContinue | sort Name -desc | select -first 1 ).FullName
        }
        else
        {
            #Path is changed for Azure .NET SDk 2.4 and above.
            $azureSdkPath = (dir "$env:ProgramFiles\Microsoft SDKs\Azure\.NET SDK" -ErrorAction SilentlyContinue | sort Name -desc | select -first 1 ).FullName
        }
        
    } 

	if(!$azureSdkPath -or !(Test-Path $azureSdkPath)) 
    {
        throw "Azure SDK not found. Please specify the path to the Azure SDK in the AzureSdkPath parameter or modify the scrtips to get cspack.exe"
    }

    Write-Host "SDK path has been set to $azureSdkPath.";
    return $azureSdkPath
}

function Get-SqlPackageExePath
{
    $MSSQLx64Directory = "$env:ProgramFiles\Microsoft SQL Server"
    $MSSQLx86Directory = "${env:ProgramFiles(x86)}\Microsoft SQL Server"
    
    if($MSSQLx64Directory -eq $MSSQLx86Directory)
    {
        $MSSQLx64Directory = "${env:ProgramW6432}\Microsoft SQL Server"
    }
    
    if(Test-Path $MSSQLx64Directory)
    {
        $sqlPackageExe = Get-ChildItem $MSSQLx64Directory -Include SqlPackage.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -Last 1
        if($sqlPackageExe -ne $null)
        {
            return $sqlPackageExe
        }
    }
    if(Test-Path $MSSQLx86Directory)
    {
        $sqlPackageExe = Get-ChildItem $MSSQLx86Directory -Include SqlPackage.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -Last 1
        if($sqlPackageExe -ne $null)
        {
            return $sqlPackageExe
        }
    }
    throw "SqlPackage.exe was not found. Please ensure you have 'SqlPackage.exe' installed on your machine."
}

function BuildSln($sln, $target, $configuration, $paramsAsString)
{
	LogMessage "Start building '$sln'"
    & $MsBuildExe $sln /t:$target /p:Configuration=$configuration /p:$paramsAsString
}


function Generate-RandomUsername([int]$length)
{
    $capitalLetters = 65..90
    $lowercaseLetters = 97..122

    $username = -join ([char[]]($capitalLetters + $lowercaseLetters) | Get-Random -Count $length)

    return $username
}

function Generate-RandomPassword([int]$length)
{
    $digits = 48..57
    $capitalLetters = 65..90
    $lowercaseLetters = 97..122

    $password = -join ([char[]]($digits + $capitalLetters + $lowercaseLetters) | Get-Random -Count $length)

    return $password
}

function Get-Username([string]$credentialsFile)
{
    $usernameLine = Get-Content $credentialsFile | Select | Where {$_ -match "Username: "}

    if($usernameLine -ne $null)
    {
        $separatorIndex = $usernameLine.IndexOf(':') + 1
        $username = $usernameLine.Substring($separatorIndex, $usernameLine.IndexOf(';') - $separatorIndex).Trim()
    }
    else
    {
        throw "Username Line was not found at: $credentialsFile"
    }
    
    return $username 
}

function Get-Password([string]$credentialsFile)
{
    $passwordLine = Get-Content $credentialsFile | Select | Where {$_ -match "Password: "}

    if($passwordLine -ne $null)
    {
        $separatorIndex = $passwordLine.IndexOf(':') + 1
        $password = $passwordLine.Substring($separatorIndex, $passwordLine.IndexOf(';') - $separatorIndex).Trim()
    }
    else
    {
        throw "Password Line was not found at: $credentialsFile"
    }

    return $password
}

function Generate-AccessCredentialsFiles([string]$credentialsInfo, [string]$outputPath)
{
    $fileName = "SitefinityBackendCredentials.txt"
    $outputFilePath = Join-Path $outputPath $fileName
    
    if(!(Test-Path $outputFilePath))
    {
        New-Item $outputFilePath -ItemType File
    }
    Write-Warning "Sitefinity Backend Credentials are: $credentialsInfo"
    Write-Warning "Generating credentials file at: $outputFilePath"
    $credentialsInfo | Out-File $outputFilePath
}

function Generate-RdpAccessFile([string]$serviceName, [string]$outputPath)
{
    $instanceInfo = Get-AzureService $serviceName | Get-AzureDeployment -ErrorAction SilentlyContinue | % {
            $svcName = $_.ServiceName
            $_.RoleInstanceList | % {
                @{ InstanceName=$_.InstanceName; IpAddress=$_.IPAddress }
            }
        }

    $rdpExportFile = $accessCredentialsOutputPath + "\" + $($instanceInfo.InstanceName) + '.rdp'
    Get-AzureRemoteDesktopFile -ServiceName $serviceName -Name $($instanceInfo.InstanceName) -LocalPath $rdpExportFile
    if(Test-Path $rdpExportFile)
    {
        Write-Host "RDP File successfully generated at $outputPath"
    }
    else
    {
        Write-Host "RDP File was unable to be generated at $outputPath"
    }
}
