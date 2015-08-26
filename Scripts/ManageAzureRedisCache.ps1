# Creates new redis cache in an already existing resource group
# The AzureResourceManager module requires Add-AzureAccount
function NewAzureRedisCache
{
    Param( 
        [Parameter(Mandatory=$true)]
        [String] 
        $CacheName 
    , 
        [Parameter(Mandatory=$true)]
        [String] 
        $ResourceGroupName
    ,
        [Parameter(Mandatory=$true)]
        [String] 
        $Location
    ,
        [ValidateSet("Basic","Standard")] 
        [String] 
        $Sku="Basic"
    )

    Switch-AzureMode AzureResourceManager
    Write-Host "Creating '$cacheName' azure redis cache..."
    $redisCache = New-AzureRedisCache -Location $location -Name $cacheName  -ResourceGroupName $resourceGroupName -Size 250MB -Sku $Sku

    # Wait until the Cache is provisioned.
    for ($i = 0; $i -le 60; $i++)
    {
        Start-Sleep -s 30
        $cacheGet = Get-AzureRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName
        Write-Host "'$cacheName' redis cache current state is '$($cacheGet[0].ProvisioningState)'..."
        if ([string]::Compare("succeeded", $cacheGet[0].ProvisioningState, $True) -eq 0)
        {       
            break
        }
        If($i -eq 60)
        {
            exit
        }
    }

    $cacheKeys = Get-AzureRedisCacheKey -ResourceGroupName $resourceGroupName  -Name $cacheName
    Switch-AzureMode AzureServiceManagement
    return $($cacheKeys.PrimaryKey)
}

function GetAzureRedisCacheKey
{
	Param( 
        [Parameter(Mandatory=$true)]
        [String] 
        $CacheName 
    , 
        [Parameter(Mandatory=$true)]
        [String] 
        $ResourceGroupName
    )
	Switch-AzureMode AzureResourceManager

	$cacheKeys = Get-AzureRedisCacheKey -ResourceGroupName $ResourceGroupName -Name $CacheName
    
	Switch-AzureMode AzureServiceManagement
    return $($cacheKeys.PrimaryKey)
}