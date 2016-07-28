. "$PSScriptRoot\Common.ps1"

function CreatePackage($serviceDefinitionPath, $outDir, $projectLocation, $roleName, $rolePropertiesFilePath)
{
    $out = [string]::Format("/out:{0}", $outDir)
	$role = [string]::Format("/role:{0};{1}", $roleName, $projectLocation)
	$sites = [string]::Format("/sites:{0};{1};{2}", $roleName, "Web", $projectLocation)
	$roleProperties = [string]::Format("/rolePropertiesFile:{0};{1}", $roleName, $rolePropertiesFilePath)

	LogMessage ("[Start] creating azure cloud package with the following properites: definition path {0}, out directory {1}, role {2}, sites {3}, role properties {4}" -f $serviceDefinitionPath, $out, $role, $sites, $roleProperties)
    
    $cspackExe = Get-ChildItem -Path (Get-AzureSdkPath) -Include "cspack.exe" -Recurse | select -first 1
    & $cspackExe $serviceDefinitionPath $out $role $sites $roleProperties
	LogMessage ("[Completed] creating azure cloud package")
}