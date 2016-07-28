param($startMode='AlwaysRunning',
      $idleTimeout='0',
      $logFileName="ConfigureIISAppPool")

$Logfile = "$PSScriptRoot\$logFileName.log"

try{
    Import-Module WebAdministration
}catch [Exception]{
    Import-Module WebAdministration
}

function LogWrite
{
    Param ([string]$logstring)

    Add-content $Logfile -value $logstring
}

try{
    LogWrite "Start Updating Application Pool Defaults Settings ..."

    LogWrite "Setting Start Mode to `"$startMode`"..."
    Set-WebConfigurationProperty /system.applicationHost/applicationPools/applicationPoolDefaults[1] -name startMode -value $startMode

    LogWrite "Setting Idle Timeout to `"$idleTimeout`"..."
    Set-WebConfigurationProperty /system.applicationHost/applicationPools/applicationPoolDefaults[1]/processModel[1] -name idleTimeout -value $idleTimeout
}
catch [Exception]{
    $("$file.name: " + $_.Exception.Message) | out-file $Logfile -Append
    Add-Content $Logfile  $error
}
finally{
    LogWrite "Finished Updating Application Pool Defaults Settings"
}
