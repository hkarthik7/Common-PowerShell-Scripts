

#try{$TimeZone = (Get-TimeZone).DisplayName}catch{$TimeZone = "NA"}
try{$TimeZone = (("CST - "+((Get-TimeZone).DisplayName.Substring(1,9))).Replace("+","-")).Replace(":","-")}catch{$TimeZone = "NA"}
try{$DSubnetsAuthoritive = Get-ItemPropertyValue HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation -Name "DSubnetsAuthoritive"}catch{$DSubnetsAuthoritive = "NA"}
try{$Domainjoinstatus = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain}catch{$Domainjoinstatus = "NA"}
try{$WsusStartType = (Get-Service -Name wuauserv).StartType}catch{$WsusStartType = "NA"}
try{$WsusStatus = (Get-Service -Name wuauserv).Status}catch{$WsusStatus = "NA"}
try{
    $IpAddress=(Resolve-DnsName -Name $env:COMPUTERNAME |where {$_.type -eq 'A'}).IPAddress
    $ReverseLookup = (Resolve-DnsName $IPaddress[0]).NameHost}catch{$ReverseLookup = "NA"}
try{
    $DbHost = ($env:COMPUTERNAME).ToLower().replace("wap","wdb")
    $DbHost = $DbHost -replace ".{2}$"
    $DbHost = $DbHost+"01"+".krft.net"
    $TelnetConnection=(Test-NetConnection -ComputerName $DbHost -Port 1433)}catch{$TelnetConnection = "NA"}
try{
    $Adp = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd
    $Data = New-Object System.Data.DataSet
    $Adp.Fill($Data) | Out-Null

    if($Data.Tables -ne $null){
        $DSNconnection = "Open"
    }
    else{
        $DSNconnection = "Closed"
    }}catch{$DSNconnection = "NA"}

#try{$WindowsDefender=(Get-WindowsFeature |where {$_.name -eq "Windows-Defender-GUI"}).Installstate}catch{$WindowsDefender = "NA"}
try{$WindowsDefender = (Get-Service -Name wuauserv).Status}catch{$WindowsDefender = "NA"}
If($WindowsDefender -like "Running"){$WindowsDefender = "Yes"}elseif($WindowsDefender -like "Stopped"){$WindowsDefender = "No"}
try{$KeepAliveTime = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name KeepAliveTime -ErrorAction SilentlyContinue).keepalivetime}catch{$KeepAliveTime = "NA"}
try{$KeepAliveInterval = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name KeepAliveInterval -ErrorAction SilentlyContinue).KeepAliveInterval}catch{$KeepAliveTime = "NA"}
try{
    $CommVaultServicesToCheck = @("GxClMgrS(Instance001)", "GxCVD(Instance001)", "GXMMM(Instance001)", "GxFWD(Instance001)", "GxVssProv(Instance001)" )
    $CommvaultService = $null
    $CommvaultService=Get-Service -Name $servicesToCheck -ErrorAction SilentlyContinue
    if($CommvaultService -eq $null){
        $CommvaultServiceStatus = "NotFound"
    }
    Else {
        $CommvaultServiceStatus = "Present"
    }
}catch{$CommvaultServiceStatus = "NA"}
try{
    $HostFileData = Get-Content -path C:\Windows\System32\Drivers\etc\hosts | where {(!$_.StartsWith("#")) -and $_ -ne ""}
    if($HostFileData -ne $null){
        $HostFile = "exist"
    }
    else{
        $HostFile ="Not-exist"
    }}catch{$HostFile = "NA"}
try{$DnsSuffixCount = (Get-DnsClientGlobalSetting).SuffixSearchList.count}catch{$DnsSuffixCount = "NA"}
try{$MellanoxDriverVersion = (Get-WmiObject Win32_PnPSignedDriver | where {$_.DeviceName -like "*Mellanox*"}).DriverVersion}catch{$MellanoxDriverVersion = "NA"}
try{$CSPNPdriverVersion = (Get-WmiObject Win32_PnPSignedDriver | where {$_.DeviceName -like "*PNP*"}).DriverVersion}catch{$MellanoxDriverVersion = "NA"}
try{$ReceiveBufferSize = (Get-NetAdapterAdvancedProperty  -DisplayName "Receive Buffer*").RegistryValue}catch{$ReceiveBufferSize = "NA"}
try{$SendBufferSize = (Get-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size").RegistryValue}catch{$SendBufferSize = "NA"}
try{
    $Snare = (Get-Service -Name Snare -ComputerName $ComputerName -ErrorAction SilentlyContinue).Status
    $Snare = If(($Snare -eq "Running") -or ($Snare -eq "Stopped")) {"Yes"} else {"No"}}catch{$Snare = "NA"}
$InstalledSoftwares=Get-WmiObject -Class Win32_Product
try{
    $CrowdStrike = ""
    $CrowdStrikeDeviceControl = "NA"
    foreach($software in $InstalledSoftwares){
       If($software.Name -like "*CrowdStrike*") {$CrowdStrike = "Yes";$CrowdStrikeDeviceControl = $software.Version ;break} else {$CrowdStrike = "No"}
    }}catch{$CrowdStrike = "NA";$CrowdStrikeDeviceControl = "NA"}

try{
    $RedCloak = ""
    $RedCloakVersion = "NA"
    foreach($software in $InstalledSoftwares){
       If($software.Name -like "*Red Cloak*") {$RedCloak = "Yes";$RedCloakVersion = $software.Version ;break} else {$RedCloak = "No"}
    }}catch{$RedCloak = "NA";$RedCloakVersion = "NA"}

try{
    $Java = ""
    $JavaVersion = "NA"
    foreach($software in $InstalledSoftwares){
       If($software.Name -like "*Java*") {$Java = "Yes";$JavaVersion = $software.Version ;break} else {$Java = "No"}
    }}catch{$Java = "NA";$JavaVersion = "NA"}

try{
    $VisualC = ""
    $VisualCVersion = "NA"
    foreach($software in $InstalledSoftwares){
       If($software.Name -like "*Microsoft Visual C++ 2010*") {$VisualC = "Yes";$VisualCVersion = $software.Version ;break} else {$VisualC = "No"}
    }}catch{$VisualC = "NA";$VisualC = "NA"}
try{
    $ODBC = ""
    $ODBCVersion = "NA"
    foreach($software in $InstalledSoftwares){
       If($software.Name -like "*Java*") {$ODBC = "Yes";$ODBCVersion = $software.Version ;break} else {$ODBC = "No"}
    }}catch{$ODBC = "NA";$ODBCVersion = "NA"}

try{
    $SQLNativeClient = ""
    $SQLNativeClient = "NA"
    foreach($software in $InstalledSoftwares){
       If($software.Name -like "*SQL Server 2012 Native Client*") {$SQLNativeClient = "Yes";$SQLNativeClientVersion = $software.Version ;break} else {$SQLNativeClient = "No"}
    }}catch{$SQLNativeClient = "NA";$SQLNativeClientVersion = "NA"}

try{
$Drive = gwmi -Class win32_volume
$BlockSizeStatus = ""
foreach($disk in $drive){
    if(($disk.Label -ne "SYSTEM") -and ($disk.Label -ne "OSDisk")){
        if($disk.BlockSize -eq 4096){$BlockSizeStatus = "Yes"}else{$BlockSizeStatus = "No"}
    }
}}catch{$BlockSizeStatus = "NA"}
try{$XboxStartupType = (Get-Service XblAuthManager).StartType}catch{$XboxStartupType = "NA"}
try{$XboxServiceStatus = (Get-Service XblAuthManager).Status}catch{$XboxServiceStatus = "NA"}
try{$DomainFirewall = if((Get-NetFirewallProfile -Name "Domain").Enabled){"Yes"}else{"No"}}catch{$DomainFirewall = "NA"}

try{
    $DnsClient = Get-NetAdapter | Get-DnsClient
    if($DnsClient.count -eq 1){
        $UseSuffixWhenRegistering = $DnsClient.UseSuffixWhenRegistering
    }
    else{
        foreach($dns in $DnsClient){
            if($dns.UseSuffixWhenRegistering){$UseSuffixWhenRegistering = "True"}else{$UseSuffixWhenRegistering = "False";break}
        }
    }}catch{$UseSuffixWhenRegistering = "NA"}

$NicDetails = Get-NetIPInterface
if($NicDetails.Count -eq 1){
    if($NicDetails.AutomaticMetric){
        $Ethernet = if($NicDetails.InterfaceMetric -eq 10){"True"}else{"False"}
    }
}
else{
    foreach($nic in $NicDetails){
        if($NicDetails.AutomaticMetric){
            if($NicDetails.InterfaceMetric -eq 10){$Ethernet = "True"}else{$Ethernet = "False";break}
        }
        else{
            if($NicDetails.InterfaceMetric -eq 3){$Ethernet = "True"}else{$Ethernet = "False";break}
        }
    }
}

try{$PagefileSize = (get-wmiobject Win32_pagefileusage).AllocatedBaseSize}catch{$PagefileSize = "NA"}
try{$PageFileLocation = (get-wmiobject Win32_pagefileusage).caption}catch{$PageFileLocation = "NA"}
if($PageFileLocation -like "*D*"){$PageFileBS = $PagefileSize}else{$PageFileBS = "error"}
try{$ServicePackLevel = (Get-CimInstance Win32_OperatingSystem).ServicePackMajorVersion}catch{$ServicePackLevel = "NA"}
try{$IISFeatureEnablement = if((Get-WmiObject -Class Win32_Service -Filter "Name='W3SVC'") -ne $null){"Yes"}else{"No"}}catch{$IISFeatureEnablement = "NA"}

$Hash = [Ordered]@{
            ComputerName = $env:COMPUTERNAME
            "OS Time Zone" = $TimeZone
            DSubnetsAuthoritive = $DSubnetsAuthoritive
            Domainjoinstatus = $Domainjoinstatus
            WsusStartType = $WsusStartType
            WsusStatus = $WsusStatus
            ReverseLookup = $ReverseLookup
            TelnetConnection = $TelnetConnection
            DSNconnection = $DSNconnection
            'Windows Defender' = $WindowsDefender
            KeepAliveTime = $KeepAliveTime
            KeepAliveInterval = $KeepAliveInterval
            CommvaultServiceStatus = $CommvaultServiceStatus
            HostFile = $HostFile
            DnsSuffixCount = $DnsSuffixCount
            UseSuffixWhenRegistering = $UseSuffixWhenRegistering
            MellanoxDriverVersion = $MellanoxDriverVersion
            ReceiveBufferSize = $ReceiveBufferSize[0]
            SendBufferSize = $SendBufferSize
            Snare = $Snare
            CrowdStrike = $CrowdStrike
            CrowdStrikeDeviceControl = $CrowdStrikeDeviceControl
            Ethernet = $Ethernet
            BlockSizeStatus = $BlockSizeStatus
            XboxStartupType = $XboxStartupType
            XboxServiceStatus = $XboxServiceStatus
            DomainFirewall = $DomainFirewall
            CSPNPdriverVersion = $CSPNPdriverVersion
            PagefileSize = $PagefileSize
            PageFileLocation = $PageFileLocation
            "Page File(GB)(entire on d:\)" = $PageFileBS
            "Service Pack Level" = $ServicePackLevel
            RedCloak = $RedCloak
            "IIS Feature Enablement, Configure FTP" = $IISFeatureEnablement
            Java = $Java
            JavaVersion = $JavaVersion
            "Visual C++" = $VisualC
            "Visual C++ Version" = $VisualCVersion
            ODBC = $ODBC
            ODBCVersion = $ODBCVersion
            SQLNativeClient = $SQLNativeClient
            SQLNativeClientVersion = $SQLNativeClientVersion
        }

        $NewHash = New-Object PSObject -Property $Hash
        $NewHash | Export-Csv ./windows.csv -NoTypeInformation
        