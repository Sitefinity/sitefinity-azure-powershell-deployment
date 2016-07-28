function UpdateSitefinityWebConfig($websiteRootDirectory)
{
	$webConfig = Join-Path $websiteRootDirectory "\web.config"
    Set-ItemProperty $webConfig -name IsReadOnly -value $false
    $doc = New-Object System.Xml.XmlDocument
	$doc.Load($webConfig)    

	if($doc.SelectSingleNode("//configuration/configSections/sectionGroup[@name='telerik']") -eq $null)
	{
		$configSectionsNode = $doc.SelectSingleNode("//configuration/configSections")
		$sectionGroupNode = $doc.CreateElement("sectionGroup")
		$sectionGroupNode.SetAttribute("name","telerik")
		$configSectionsNode.AppendChild($sectionGroupNode)
		$sectionNode = $doc.CreateElement("section")
		$sectionNode.SetAttribute("name","sitefinity")
		$sectionNode.SetAttribute("type","Telerik.Sitefinity.Configuration.SectionHandler, Telerik.Sitefinity")
		$sectionNode.SetAttribute("requirePermission","false")
		$sectionGroupNode.AppendChild($sectionNode)
	}

	if($doc.SelectSingleNode("//configuration/telerik") -eq $null)
	{
		$configurationNode = $doc.SelectSingleNode("//configuration")
		$telerikNode = $doc.CreateElement("telerik")
		$sitefinityNode = $doc.CreateElement("sitefinity")
		$testingNode = $doc.CreateElement("testing")
		$testingNode.SetAttribute("enabled", "true")
		$testingNode.SetAttribute("loadBalancingSyncLoggingEnabled", "false") #disable nlb sync logging becase it is peformance overhead.
		$environmentNode = $doc.CreateElement("environment")
		$environmentNode.SetAttribute("platform", "WindowsAzure")
		$sitefinityConfigNode = $doc.CreateElement("sitefinityConfig")
		$sitefinityConfigNode.SetAttribute("storageMode", "Database")
		$sitefinityNode.AppendChild($testingNode)
		$sitefinityNode.AppendChild($environmentNode)
		$sitefinityNode.AppendChild($sitefinityConfigNode)
		$telerikNode.AppendChild($sitefinityNode)
		$configurationNode.AppendChild($telerikNode)
	}

	$doc.Save($webConfig)
}

function UpdateSitefinityDataConfig($websiteRootDirectory, $azureServer, $user, $password, $database)
{
	$dataConfig = Join-Path $websiteRootDirectory "\App_Data\Sitefinity\Configuration\DataConfig.config"
    Set-ItemProperty $dataConfig -name IsReadOnly -value $false
    $doc = New-Object System.Xml.XmlDocument
    $doc.Load($dataConfig)	
	$connectionString = "Server=$azureServer;User ID=$user;Password=$password;Database=$database; Trusted_Connection=False;Encrypt=True"
    $dbTypeAttr = $doc.SelectSingleNode("//dataConfig/connectionStrings/add/@dbType")
    $dbTypeAttr.Value = "SqlAzure"    
    $connectionStringAttr = $doc.SelectSingleNode("//dataConfig/connectionStrings/add/@connectionString")
    $connectionStringAttr.Value = $connectionString

    $doc.Save($dataConfig)
}

function EnableAzureTraceListener($websiteRootDirectory)
{
    $webConfig = Join-Path $websiteRootDirectory "\web.config"
    Set-ItemProperty $webConfig -name IsReadOnly -value $false
    $doc = New-Object System.Xml.XmlDocument
	$doc.Load($webConfig)

    
    if($doc.SelectSingleNode("//configuration/system.diagnostics/trace/listeners/add[@name='AzureDiagnostics']") -eq $null)
    {
        $traceListenersNode = $doc.SelectSingleNode("//configuration/system.diagnostics/trace/listeners")
        if($traceListenersNode -eq $null)
	    {
            $traceNode = $doc.SelectSingleNode("//configuration/system.diagnostics/trace")
            if($traceNode -eq $null)
	        {
                $diagnosticsNode = $doc.SelectSingleNode("//configuration/system.diagnostics")
                if($diagnosticsNode -eq $null)
                {
                    $diagnosticsNode = $doc.CreateElement("system.diagnostics")
                    $doc.SelectSingleNode("//configuration").AppendChild($diagnosticsNode)
                }
                $traceNode = $doc.CreateElement("trace")
                $diagnosticsNode.AppendChild($traceNode)
            }
            $traceListenersNode = $doc.CreateElement("listeners")
            $traceNode.AppendChild($traceListenersNode)
	    }
        $azureDiagnosticsNode = $doc.CreateElement("add")
        $azureDiagnosticsNode.SetAttribute("type", "Microsoft.WindowsAzure.Diagnostics.DiagnosticMonitorTraceListener, Microsoft.WindowsAzure.Diagnostics, Version=2.6.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")
        $azureDiagnosticsNode.SetAttribute("name", "AzureDiagnostics")
        $filterNode = $doc.CreateElement("filter")
        $filterNode.SetAttribute("type", "")
        $azureDiagnosticsNode.AppendChild($filterNode)
        $traceListenersNode.AppendChild($azureDiagnosticsNode)
        $doc.Save($webConfig)
    }
}

function ConfigureAzureSearchService($searchConfig, $azureServiceAdminKey, $azureSearchServiceName)
{
    Set-ItemProperty $searchConfig -name IsReadOnly -value $false
    $doc = New-Object System.Xml.XmlDocument
	$doc.Load($searchConfig)    
    $azureSearchServiceNode = $doc.SelectSingleNode("//searchConfig/searchServices/add")
    $azureSearchServiceNode.Attributes['azureServiceAdminKey'].Value = $azureServiceAdminKey
    $azureSearchServiceNode.Attributes['azureSearchServiceName'].Value = $azureSearchServiceName
    $doc.Save($searchConfig)
}