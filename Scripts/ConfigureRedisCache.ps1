#Configures Redis cache in Sitefinity
param(
	[Parameter(Mandatory=$True)]
	[String]
	$systemConfig,
	[Parameter(Mandatory=$True)]
	[String]
    $redisCacheConnectionString
)

Write-Warning "Configuring redis cache..."

$doc = New-Object System.Xml.XmlDocument
$doc.Load($systemConfig)

$loadBalancingConfigNode = $doc.SelectSingleNode("//systemConfig/loadBalancingConfig")
if($loadBalancingConfigNode -eq $null)
{
    $loadBalancingConfigNode = $doc.CreateElement("loadBalancingConfig")
    $systemConfigNode = $doc.SelectSingleNode("//systemConfig")
    $systemConfigNode.AppendChild($loadBalancingConfigNode)
}

$redisSettingsNode = $doc.SelectSingleNode("//systemConfig/loadBalancingConfig/redisSettings")
if($redisSettingsNode -eq $null)
{
	$redisSettingsNode = $doc.CreateElement("redisSettings")
    $loadBalancingConfigNode.AppendChild($redisSettingsNode)
}

$redisSettingsNode.SetAttribute("ConnectionString", $redisCacheConnectionString)

$doc.Save($systemConfig)

Write-Warning "Redis cache has been configured."