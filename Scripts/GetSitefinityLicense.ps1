##############################################################################
#.SYNOPSIS
#
#.DESCRIPTION
# Makes a call to a RESTful WCF service and retrieves the encrypted license content
# and creates a Sitefinity.lic file.
#
#.PARAMETER domains
# The domains which are going to be added to the license. When specifying more that one domain use ; to separate them. 
#
#.PARAMETER version
# The Sitefinity version that the license is going to be generated for.
#
#.PARAMETER licenseFilePath
# The location where the license is going to be generated.
#
#.PARAMETER serviceBaseUrl
# The location of the License service.
#
#.EXAMPLE
# GetSitefinityLicense -domains "http://architecture.sitefinity.com;portal.sitefinity.com" -version "8.1" -licenseFilePath "C:\MyFolder"
##############################################################################
function GetSitefinityLicense
{
    param([string]$domains,
          [string]$version,
          [string]$licenseFilePath,
          [string]$serviceBaseUrl)

    $licenseUrl = "{0}/License.svc/GetLicense?domains={1}&version={2}" -f $serviceBaseUrl, $domains, $version
    $licenseFileName = "Sitefinity.lic"

    try
    {
        $licenseResponse = Invoke-RestMethod -Uri $licenseUrl -Method Get -TimeoutSec 720
        $encryptedContent = $licenseResponse.GetLicenseResult
        New-Item -name $licenseFileName -path $licenseFilePath -type "file" -value $encryptedContent -force
    }
    catch 
	{		
		Write-Host "Cannot get license from '$licenseUrl' "
		throw $_.Exception
	}
}
