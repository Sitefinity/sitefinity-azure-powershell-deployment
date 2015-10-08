#Updates Azure Subscription data file
function UpdateAzureSubscriptionData($currentStorageAccount, $cloudServiceName, $storageServiceName, $location)
{
	Set-ItemProperty $config.files.azureSubscriptionDataConfig -name IsReadOnly -value $false
	[Xml]$sdXml = Get-Content $config.files.azureSubscriptionDataConfig 

    #update Current storage account
    $sdXml.AzureSubscriptionData.CurrentStorageAccount = $currentStorageAccount
   
    #update could service data
    Foreach ($cloudService in $sdXml.AzureSubscriptionData.CloudService)
    {
       $cloudService.Name = $cloudServiceName
       $cloudService.Location = $location
    }

    #update storage service data
    Foreach ($storageService in $sdXml.AzureSubscriptionData.StorageService)
    {
       $storageService.Name =  $storageServiceName
    }

    $sdXml.Save($config.files.azureSubscriptionDataConfig)
}

function UpdateServiceConfigurationCloudData($AccountName, $AccountKey)
{
	Set-ItemProperty $config.files.cloudConfig -name IsReadOnly -value $false
	[Xml]$cscfgXml = Get-Content $config.files.cloudConfig 
	$connectionStringValue = [string]::Format("DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1}", $AccountName, $AccountKey) 

    $settingNode =  $cscfgXml.ServiceConfiguration.Role.ConfigurationSettings.Setting | where {$_.name -like 'Microsoft.WindowsAzure.Plugins.Diagnostics.ConnectionString'}
	$settingNode.Value = $connectionStringValue

	$cscfgXml.Save($config.files.cloudConfig)
}

# Example: UpdateVMSize -ServiceDefinitionPath "C:\Temp\Tools\AzureDeployment\CloudConfigs\ServiceDefinition.csdef" -VMSize "big"
function UpdateVMSize
{
	Param(
		[string]$ServiceDefinitionPath,
		[string]$VMSize
	)
	
	Set-ItemProperty $ServiceDefinitionPath -name IsReadOnly -value $false
	if ($ServiceDefinitionPath -eq $null)
	{
		Throw "Path to xml file is not provided."
	}
	
	if ($VMSize -eq $null)
	{
		Throw "VMSize is not provided as a parameter."
	}
	
	[Xml]$XMLfile = Get-Content $ServiceDefinitionPath
	$XMLFile.ServiceDefinition.WebRole.vmsize = $VMSize
	$XMLFile.save($ServiceDefinitionPath)
}

# Example: UpdateVMModules -ServiceDefinitionPath "C:\Temp\Tools\AzureDeployment\CloudConfigs\ServiceDefinition.csdef" -Modules @("RemoteAccess", "RemoteForwarder")
function UpdateVMModules
{
	Param(
		[string]$ServiceDefinitionPath,
		[array]$Modules
	)
	
	if ($ServiceDefinitionPath -eq $null)
	{
		Throw "Path to xml file is not provided."
	}
	
	if ($Modules -eq $null)
	{
		Throw "No modules were provided."
	}
	
	Set-ItemProperty $ServiceDefinitionPath -name IsReadOnly -value $false
	[Xml]$XMLfile = Get-Content $ServiceDefinitionPath
	$xdns = $XMLfile.DocumentElement.NamespaceURI
	Foreach ($module in $Modules)
	{        
        if(($XMLFile.ServiceDefinition.WebRole.Imports.Import | where {$_.moduleName -like $module}) -eq $null){
		    $newImport = $XMLfile.CreateElement("Import", $xdns)
		    $XMLFile.ServiceDefinition.WebRole.Imports.AppendChild($newImport)
		    $newImport.SetAttribute("moduleName", $module)
        }
	}
		
	$XMLFile.save($ServiceDefinitionPath)
}

function DeleteVMModules
{
	Param(
        [Parameter(Mandatory=$true)]
		[string]$ServiceDefinitionPath,
        [Parameter(Mandatory=$true)]
		[array]$Modules
	)
    
	Set-ItemProperty $ServiceDefinitionPath -name IsReadOnly -value $false
	[Xml]$XMLfile = Get-Content $ServiceDefinitionPath
    $nsmgr = New-Object Xml.XmlNamespaceManager $XMLfile.NameTable
    $nsmgr.AddNamespace("ns", $XMLfile.DocumentElement.NamespaceURI)
	foreach ($module in $Modules)
	{        
        $moduleNode = $XMLfile.SelectSingleNode("//ns:ServiceDefinition/ns:WebRole/ns:Imports/ns:Import[@moduleName='$module']", $nsmgr)
        if($moduleNode -ne $null) {   
            $moduleNode.ParentNode.RemoveChild($moduleNode)
        }
	}
		
	$XMLFile.save($ServiceDefinitionPath)
}

function UpdateSQLAzureServerInfoData($rootDatabase, $targetDatabase)
{
	Set-ItemProperty $config.files.azureSqlServerInforFilePath -name IsReadOnly -value $false
	[Xml]$sdInfoXml = Get-Content $config.files.azureSqlServerInforFilePath

	$sdInfoXml.ServerInfo.ServerInstance = $config.azure.server
	$sdInfoXml.ServerInfo.Login = $config.azure.user
	$sdInfoXml.ServerInfo.Password = $config.azure.password
    $sdInfoXml.ServerInfo.RootDatabase = $rootDatabase
    $sdInfoXml.ServerInfo.TargetDatabase = $targetDatabase

    $sdInfoXml.Save($config.files.azureSqlServerInforFilePath)
}

function GenerateRemoteDesktopRequiredSettingsNodes($serviceConfigurationPath)
{   
    Set-ItemProperty $serviceConfigurationPath -name IsReadOnly -value $false
	[Xml]$cscfgXml = Get-Content $serviceConfigurationPath
    
    foreach($setting in $config.remoteAccessSettings)
    {
        $settingNode = $cscfgXml.ServiceConfiguration.Role.ConfigurationSettings.Setting | where {$_.name -like $setting.name}
        if($settingNode -ne $null){
            $settingNode.Value = $setting.value;
        }else{
	        $configSettings = $cscfgXml.ServiceConfiguration.Role.ConfigurationSettings; 
	        $xdNS = $cscfgXml.DocumentElement.NamespaceURI
	        $elem = $cscfgXml.CreateElement('Setting', $xdNS)
	        $elem.SetAttribute('name',$setting.name)
	        $elem.SetAttribute('value',$setting.value)
	        $configSettings.AppendChild($elem);
        }
    }

    $cscfgXml.Save($serviceConfigurationPath)
}

function RemoveRemoteDesktopRequiredSettingsNodes($serviceConfigurationPath)
{
    Set-ItemProperty $serviceConfigurationPath -name IsReadOnly -value $false
	[Xml]$cscfgXml = Get-Content $serviceConfigurationPath
    $nsmgr = New-Object Xml.XmlNamespaceManager $cscfgXml.NameTable
    $nsmgr.AddNamespace("ns", $cscfgXml.DocumentElement.NamespaceURI)
    
    foreach($setting in $config.remoteAccessSettings)
    {
        $settingNode = $cscfgXml.SelectSingleNode("//ns:ServiceConfiguration/ns:Role/ns:ConfigurationSettings/ns:Setting[@name='$($setting.name)']", $nsmgr)
        if($settingNode -ne $null) {   
            $settingNode.ParentNode.RemoveChild($settingNode)
        }
    }

    $cscfgXml.Save($serviceConfigurationPath)
}

function AddCertificatesNode
{
    Set-ItemProperty $config.files.cloudConfig -name IsReadOnly -value $false
	[Xml]$cscfgXml = Get-Content $config.files.cloudConfig

    $roleElement = $cscfgXml.ServiceConfiguration.Role
    $xdNS = $cscfgXml.DocumentElement.NamespaceURI
    $certificateElement = $cscfgXml.ServiceConfiguration.Role.Certificates
    if($certificateElement -eq $null){
        $certificateElement = $cscfgXml.CreateElement('Certificates', $xdNS)
        $roleElement.AppendChild($certificateElement);
    }
    $elem = $cscfgXml.ServiceConfiguration.Role.Certificates.Certificate | where {$_.name -like $config.certificate.name}
    if($elem -eq $null){
	    $elem = $cscfgXml.CreateElement('Certificate', $xdNS)
	    $certificateElement.AppendChild($elem);
    }
	$elem.SetAttribute('name', $config.certificate.name)
	$elem.SetAttribute('thumbprint', $config.certificate.thumbprint)
	$elem.SetAttribute('thumbprintAlgorithm', $config.certificate.thumbprintAlgorithm)

    $cscfgXml.Save($config.files.cloudConfig)
}

function DeleteCertificatesNode
{
    Set-ItemProperty $config.files.cloudConfig -name IsReadOnly -value $false
	[Xml]$cscfgXml = Get-Content $config.files.cloudConfig
    $nsmgr = New-Object Xml.XmlNamespaceManager $cscfgXml.NameTable
    $nsmgr.AddNamespace("ns", $cscfgXml.DocumentElement.NamespaceURI)
    $certificatesNode = $cscfgXml.SelectSingleNode("//ns:ServiceConfiguration/ns:Role/ns:Certificates", $nsmgr)
	if($certificatesNode -ne $null) {   
        $certificatesNode.ParentNode.RemoveChild($certificatesNode)
    }
    $cscfgXml.Save($config.files.cloudConfig)
}

#Configures RemoteDesktop for Cloud Service
function ConfigureRemoteDesktop
{
    Param(
        [Parameter(Mandatory=$true)]
        [string]$EnableRemoteDesktopAccess
	)

    Set-ItemProperty $config.files.cloudConfig -name IsReadOnly -value $false
	[Xml]$cscfgXml = Get-Content $config.files.cloudConfig 
    if($EnableRemoteDesktopAccess -eq "true")
    {
	    UpdateVMModules -ServiceDefinitionPath $config.files.serviceDefinition -Modules @("RemoteAccess", "RemoteForwarder")
        GenerateRemoteDesktopRequiredSettingsNodes $config.files.cloudConfig
    } else {
        DeleteVMModules -ServiceDefinitionPath $config.files.serviceDefinition -Modules @("RemoteAccess", "RemoteForwarder")
        RemoveRemoteDesktopRequiredSettingsNodes $config.files.cloudConfig
    }
}

#Ads SSL to the service definition. Remote Desktip Requires SSL
function ConfigureSsl
{	
	Param(
        [Parameter(Mandatory=$true)]
        [string]$EnableSsl
	)
	Set-ItemProperty $config.files.serviceDefinition -name IsReadOnly -value $false
    [Xml]$XMLfile = Get-Content $config.files.serviceDefinition
	$xdns = $XMLfile.DocumentElement.NamespaceURI
	
    if($EnableSsl -eq "true") {
        if(($XMLFile.ServiceDefinition.WebRole.Sites.Site.Bindings.Binding | where {$_.name -like $config.azure.sslEndpointName}) -eq $null){
	        $sslBinding = $XMLfile.CreateElement("Binding", $xdns)
	        $XMLFile.ServiceDefinition.WebRole.Sites.Site.Bindings.AppendChild($sslBinding)
	        $sslBinding.SetAttribute("name", $config.azure.sslEndpointName)
	        $sslBinding.SetAttribute("endpointName", $config.azure.sslEndpointName)
        }
        if(($XMLFile.ServiceDefinition.WebRole.Endpoints.InputEndpoint | where {$_.name -like $config.azure.sslEndpointName}) -eq $null){
	        $sslEndpoint = $XMLfile.CreateElement("InputEndpoint", $xdns)
	        $XMLFile.ServiceDefinition.WebRole.Endpoints.AppendChild($sslEndpoint)
	        $sslEndpoint.SetAttribute("name", $config.azure.sslEndpointName)
	        $sslEndpoint.SetAttribute("protocol", "https")
	        $sslEndpoint.SetAttribute("port", "443")
	        $sslEndpoint.SetAttribute("certificate", $config.certificate.name)
        }
    } else {
        $nsmgr = New-Object Xml.XmlNamespaceManager $XMLfile.NameTable
        $nsmgr.AddNamespace("ns", $xdns)
        $bindingNode = $XMLFile.SelectSingleNode("//ns:ServiceDefinition/ns:WebRole/ns:Sites/ns:Site/ns:Bindings/ns:Binding[@name='$SslEndpointName']", $nsmgr)
	    if($bindingNode -ne $null) {   
            $bindingNode.ParentNode.RemoveChild($bindingNode)
        }
        $endpointNode = $XMLFile.SelectSingleNode("//ns:ServiceDefinition/ns:WebRole/ns:Endpoints/ns:InputEndpoint[@name='$SslEndpointName']", $nsmgr)
	    if($endpointNode -ne $null) {
            $endpointNode.ParentNode.RemoveChild($endpointNode)
        } 
    }
		
	$XMLFile.save($config.files.serviceDefinition)
}