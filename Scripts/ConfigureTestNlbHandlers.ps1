#Configures specific NLB Handlers for testing
param(
	[Parameter(Mandatory=$True)]
	[String]$systemConfig
)

Write-Warning "Registering test nlb handlers..."

$handlers = @("Telerik.Sitefinity.TestUtilities.CommonOperations.Nlb.TestPerformanceNlbHandler, Telerik.Sitefinity.TestUtilities, Version=1.0.0.0, Culture=neutral, PublicKeyToken=b28c218413bdf563",
            "Telerik.Sitefinity.TestUtilities.CommonOperations.Nlb.ExpectedMessagesNlbHandler, Telerik.Sitefinity.TestUtilities, Version=1.0.0.0, Culture=neutral, PublicKeyToken=b28c218413bdf563")

$doc = New-Object System.Xml.XmlDocument
$doc.Load($systemConfig)

$loadBalancingConfigNode = $doc.SelectSingleNode("//systemConfig/loadBalancingConfig")
if($loadBalancingConfigNode -eq $null)
{
    $loadBalancingConfigNode = $doc.CreateElement("loadBalancingConfig")
    $systemConfigNode = $doc.SelectSingleNode("//systemConfig")
    $systemConfigNode.AppendChild($loadBalancingConfigNode)
}

$handlersNode = $doc.SelectSingleNode("//systemConfig/loadBalancingConfig/handlers")
if($handlersNode -eq $null)
{
    $handlersNode = $doc.CreateElement("handlers")
    $loadBalancingConfigNode.AppendChild($handlersNode)
}

foreach($handler in $handlers)
{
    $addNode = $doc.SelectSingleNode("//systemConfig/loadBalancingConfig/handlers/add[@value='$handler']")
    if($addNode -eq $null)
    {
        $addNode = $doc.CreateElement("add")
        $addNode.SetAttribute("value", $handler)
        $handlersNode.AppendChild($addNode)
    }
}

$doc.Save($systemConfig)

Write-Warning "Test nlb handlers have been registered."