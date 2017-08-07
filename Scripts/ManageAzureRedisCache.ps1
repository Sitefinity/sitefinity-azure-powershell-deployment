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

    Write-Host "Creating '$cacheName' azure redis cache..."
    $redisCache = New-AzureRmRedisCache -Location $location -Name $cacheName  -ResourceGroupName $resourceGroupName -Size 250MB -Sku $Sku

    # Wait until the Cache is provisioned.
    for ($i = 0; $i -le 60; $i++)
    {
        Start-Sleep -s 30
        $cacheGet = Get-AzureRmRedisCache -ResourceGroupName $resourceGroupName -Name $cacheName
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

    $cacheKeys = Get-AzureRmRedisCacheKey -ResourceGroupName $resourceGroupName  -Name $cacheName
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

	$cacheKeys = Get-AzureRmRedisCacheKey -ResourceGroupName $ResourceGroupName -Name $CacheName
    
    return $($cacheKeys.PrimaryKey)
}