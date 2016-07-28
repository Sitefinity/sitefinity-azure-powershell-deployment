param($defaultDrive = "E:\",
	  $logFileName = "ManageConfigACL")

$Logfile = "$PSScriptRoot\$logFileName.log"

function LogWrite
{
    Param ([string]$logstring)

    Add-content $Logfile -value $logstring
}

try{
    LogWrite "Start managing configuration ACL..."

	$drive = $defaultDrive
	$rootFolder = $PSScriptRoot
	$tokens = $rootFolder.Split(":")

	if($tokens.length -gt 0){
		$drive = "{0}:\" -f $tokens[0]
	}

	$configurationPath = Join-Path $drive "approot\App_Data\Sitefinity\Configuration\*"

	LogWrite "PSScriptRoot is '$PSScriptRoot'"
	LogWrite "drive is '$drive'"
	LogWrite "configurationPath is '$configurationPath'"

	LogWrite "Setting configuration ACL for '$configurationPath'"

	icacls $configurationPath '/grant' '"NT AUTHORITY\NetworkService":(w)'
}
catch [Exception]{
    $("$file.name: " + $_.Exception.Message) | out-file $Logfile -Append
    LogWrite $error
}
finally{
    LogWrite "Finished managing configuration ACL"
}
