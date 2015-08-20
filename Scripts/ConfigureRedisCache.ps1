param(
	[Parameter(Mandatory=$True)]
	[String]$systemConfig,
    [Parameter(Mandatory=$True)]
	[String]$redisCacheConnectionString
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

$redisSettingsNode = $doc.CreateElement("redisSettings")
$redisSettingsNode.SetAttribute("ConnectionString", $redisCacheConnectionString)

$loadBalancingConfigNode.AppendChild($redisSettingsNode)

$doc.Save($systemConfig)

Write-Warning "Redis cache has been configured."