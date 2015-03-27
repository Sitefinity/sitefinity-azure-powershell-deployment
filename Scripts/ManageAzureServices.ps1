function CreateCloudService($Name, $Location)
{ 
	$service = Get-AzureService | where { $_.ServiceName -eq $Name }
	if(!$service)
	{
		LogMessage ("[Start] creating cloud service {0} in location {1}" -f $Name, $Location)
		New-AzureService -ServiceName $Name -Location $Location
		LogMessage ("[Finish] creating cloud service {0} in location {1}" -f $Name, $Location)
	}
	else
	{
		LogMessage ("Cloud service '{0}' exists. New cloud service hasn't been created" -f $Name)
	}
	
	Return @{ServiceName = $Name}
}

function RemoveCloudService($Name)
{
	LogMessage ("[Start] removing cloud service {0}" -f $Name)
	$service = Get-AzureService | where { $_.ServiceName -eq $Name }
	if($service)
	{
		LogMessage ("[InProgress] cloud service found {0}" -f $Name)
		$stat = Remove-AzureService $service.ServiceName -Force
		if($stat.OperationStatus -eq "Succeeded")
		{
			LogMessage ("[Finish] removing cloud service {0}" -f $Name)
		}
		else
		{
			LogMessage ("Removing cloud service '{0}' failed" -f $Name)
		}
	}
	else
	{
		LogMessage ("Cloud service '{0}' not found" -f $Name)
	}
}