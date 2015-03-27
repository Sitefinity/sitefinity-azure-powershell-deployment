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
        $azureSdkPath = (dir "$env:ProgramFiles\Microsoft SDKs\Windows Azure\.NET SDK" -ErrorAction SilentlyContinue | sort Name -desc | select -first 1 ).FullName
    } 

	if(!$azureSdkPath -or !(Test-Path $azureSdkPath)) 
    {
        throw "Azure SDK not found. Please specify the path to the Azure SDK in the AzureSdkPath parameter or modify the scrtips to get cspack.exe"
    }

    Write-Host "SDK path has been set to $azureSdkPath."
    Return $azureSdkPath
}

function Get-SqlPackageExePath
{
    $MSSQLx64Directory = "$env:ProgramFiles\Microsoft SQL Server"
    $MSSQLx86Directory = "${env:ProgramFiles(x86)}\Microsoft SQL Server"
    if(Test-Path $MSSQLx64Directory)
    {
        $sqlPackageExe = Get-ChildItem $MSSQLx64Directory -Include SqlPackage.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if($sqlPackageExe -ne $null)
        {
			Write-Host "SQL Package path has been set to $sqlPackageExe."
            return $sqlPackageExe
        }
    }
    if(Test-Path $MSSQLx86Directory)
    {
        $sqlPackageExe = Get-ChildItem $MSSQLx86Directory -Include SqlPackage.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if($sqlPackageExe -ne $null)
        {
			Write-Host "SQL Package path has been set to $sqlPackageExe."
            return $sqlPackageExe
        }
    }
	
    throw "SqlPackage.exe was not found. Please ensure you have 'SqlPackage.exe' installed on your machine."
}