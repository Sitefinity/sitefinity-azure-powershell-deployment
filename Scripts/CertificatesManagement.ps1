function AddCertificateToService($serviceName, $certificate, $password)
{
	Add-AzureCertificate -serviceName $serviceName -certToDeploy $certificate –password $password
}

function ImportCertificate($certPath, $thumbPrint)
{
	$file = ( Get-ChildItem -Path $certPath )
	
	if ($file -eq $null) {
	   throw “Management certificate could not be found under $certPath”
	}
	
	$cert = Get-Item Cert:\CurrentUser\My\$thumbPrint
	if ($cert -eq $null) {
	   Write-Host “Management certificate was not found start importing to 'cert:\CurrentUser\My'”
	   $file | Import-Certificate -CertStoreLocation cert:\CurrentUser\My
	}
	return $cert	
}