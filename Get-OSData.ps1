Function Get-OSData {
    <#

        .SYNOPSIS
        Gets VM OS data.

        .DESCRIPTION
        This script is designed to run for a single server locally or remotely. It is designed to run as a parallel script
        with Invoke-RemoteScript-Workflow for Mondelez

        .PARAMETER
        .STRING. ComputerName. Provide the ComputerName name.

        .PARAMETER
        .STRING. ExportPath. Provide the filepath to export information to a csv file.

        .PARAMETER
        .STRING. Logpath. Provide the filepath to track the logs.

        .EXAMPLE
        Get-OSData -ExportPath "C:\Path\to\outputfile" -LogPath "C:\Path\to\logfile" -Verbose

        .NOTES
            Author						Version			Date			Notes
            --------------------------------------------------------------------------------------------------------------------
            harish.b.karthic		    v1.0			10/09/2019		Initial script
            prajwal.g.l                 v1.1            11/09/2019      Added parameteres for checks

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [String]$ComputerName,
        [Parameter(Mandatory=$false)]
        [String]$ExportPath,
        [Parameter(Mandatory=$false)]
        [String]$LogPath
    )

    begin{
        #Initialize function variables
        $function = $MyInvocation.MyCommand.Name
        $Folder = "C:\Temp"
        If(!(Test-Path $Folder)) {mkdir $Folder | Out-Null}
        If($LogPath -eq "") {$LogPath = $Folder}
        $Logfile = $LogPath + "\OSDataCollection_$(Get-Date -Format ddMMyyyy).log"
        If($ComputerName -eq "") {$ComputerName = $env:COMPUTERNAME}
        If($ExportPath -eq "") {$ExportPath = $Folder + "\$($ComputerName)-OSData.csv"} else {$ExportPath = $ExportPath + "\$($ComputerName)-OSData.csv"}

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }
    process {
    
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Fetching OS data"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Working with $($ComputerName)"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        #region data collection

        $IPV4Address = (Test-Connection -ComputerName $ComputerName -Count 1).IPV4Address.IPAddressToString
        $WindowsLicense = Get-WindowsLicense
        $WindowsLicense = If($WindowsLicense -eq "Licensed") {"Yes"} else {"No"}
        $OSVersion = (Get-WmiObject -Class Win32_OperatingSystem).Caption
        try{$TimeZone = (("CST - "+((Get-TimeZone).DisplayName.Substring(1,9))).Replace("+","-")).Replace(":","-")}catch{$TimeZone = "NA"}
        try{$DSubnetsAuthoritive = Get-ItemPropertyValue HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation -Name "DSubnetsAuthoritive"}catch{$DSubnetsAuthoritive = "NA"}
        try{$Domainjoinstatus = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain}catch{$Domainjoinstatus = "NA"}
        try{$WsusStartType = (Get-Service -Name wuauserv).StartType}catch{$WsusStartType = "NA"}
        try{$WsusStatus = (Get-Service -Name wuauserv).Status}catch{$WsusStatus = "NA"}
        try{
            $IpAddress=(Resolve-DnsName -Name $env:COMPUTERNAME |where {$_.type -eq 'A'}).IPAddress
            $IpAddress | % {
                $IP = $_
                try{$ReverseLookup = (Resolve-DnsName $IP -ErrorAction SilentlyContinue).NameHost} Catch {$ReverseLookup = "NA"}
            } 
        } catch{$ReverseLookup = "NA"}
            
        try{
            $DbHost = ($env:COMPUTERNAME).ToLower().replace("wap","wdb")
            $DbHost = $DbHost -replace ".{2}$"
            $DbHost = $DbHost+"01"+".krft.net"
            $TelnetConnection=((Test-NetConnection -ComputerName $DbHost -Port 1433)).TcpTestSucceeded}catch{$TelnetConnection = "NA"}
        try{
            $Adp = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd
            $Data = New-Object System.Data.DataSet
            $Adp.Fill($Data) | Out-Null

            if($Data.Tables -ne $null){
                $DSNconnection = "Open"
            }
            else{
                $DSNconnection = "Closed"
            }
        }catch{$DSNconnection = "NA"}

        try{$WindowsDefender=(Get-WindowsFeature |where {$_.name -eq "Windows-Defender-GUI"}).Installstate}catch{$WindowsDefender = "NA"}
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
            }
        }catch{$HostFile = "NA"}
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
            }
        }catch{$CrowdStrike = "NA";$CrowdStrikeDeviceControl = "NA"}

        try{
            $RedCloak = ""
            $RedCloakVersion = "NA"
            foreach($software in $InstalledSoftwares){
                If($software.Name -like "*Red Cloak*") {$RedCloak = "Yes";$RedCloakVersion = $software.Version ;break} else {$RedCloak = "No"}
            }
        }catch{$RedCloak = "NA";$RedCloakVersion = "NA"}

        try{
            $Java = ""
            $JavaVersion = "NA"
            foreach($software in $InstalledSoftwares){
                If($software.Name -like "*Java*") {$Java = "Yes";$JavaVersion = $software.Version ;break} else {$Java = "No"}
            }
        }catch{$Java = "NA";$JavaVersion = "NA"}

        try{
            $ODBC = ""
            $ODBCVersion = "NA"
            foreach($software in $InstalledSoftwares){
                If($software.Name -like "*Java*") {$ODBC = "Yes";$ODBCVersion = $software.Version ;break} else {$ODBC = "No"}
            }
        }catch{$ODBC = "NA";$ODBCVersion = "NA"}

        try{
            $SQLNativeClient = ""
            $SQLNativeClient = "NA"
            foreach($software in $InstalledSoftwares){
                If($software.Name -like "*SQL Server 2012 Native Client*") {$SQLNativeClient = "Yes";$SQLNativeClientVersion = $software.Version ;break} else {$SQLNativeClient = "No"}
            }
        }catch{$SQLNativeClient = "NA";$SQLNativeClientVersion = "NA"}

        try{
            $Drive = gwmi -Class win32_volume
            $BlockSizeStatus = ""
            foreach($disk in $drive){
                if(($disk.Label -ne "SYSTEM") -and ($disk.Label -ne "OSDisk")){
                    if($disk.BlockSize -eq 4096){$BlockSizeStatus = "Yes"}else{$BlockSizeStatus = "No"}
                }
            }
        }catch{$BlockSizeStatus = "NA"}
        try{$XboxStartupType = (Get-Service XblAuthManager).StartType}catch{$XboxStartupType = "NA"}
        try{$XboxServiceStatus = (Get-Service XblAuthManager).Status}catch{$XboxServiceStatus = "NA"}
        try{$DomainFirewall = if((Get-NetFirewallProfile -Name "Domain").Enabled){"Yes"}else{"No"}}catch{$DomainFirewall = "NA"}

        try{
            $DnsClient = Get-NetAdapter -ErrorAction SilentlyContinue | Get-DnsClient -ErrorAction SilentlyContinue
            if($DnsClient.count -eq 1){
                $UseSuffixWhenRegistering = $DnsClient.UseSuffixWhenRegistering
            }
            else{
                foreach($dns in $DnsClient){
                    if($dns.UseSuffixWhenRegistering){$UseSuffixWhenRegistering = "True"}else{$UseSuffixWhenRegistering = "False";break}
                }
            }
        }
        catch{$UseSuffixWhenRegistering = "NA"}

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
        try{$ServicePackLevel = (Get-CimInstance Win32_OperatingSystem).ServicePackMajorVersion}catch{$ServicePackLevel = "NA"}
        try{$IISFeatureEnablement = if((Get-WmiObject -Class Win32_Service -Filter "Name='W3SVC'") -ne $null){"Yes"}else{"No"}}catch{$IISFeatureEnablement = "NA"}


        #endregion data collection

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Done with fetching OS data"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Exporting the available data to $($ExportPath)"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        #region export data

        $Hash = [PSCustomObject]@{
            
                Name = $ComputerName
                IPAddress = $IPV4Address
                'Win License' = $WindowsLicense
                OSVersion = $OSVersion
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
                SendBufferSize = $SendBufferSize[0]
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
                ServicePackLevel = $ServicePackLevel
                RedCloak = $RedCloak
                IISFeatureEnablement = $IISFeatureEnablement
                Java = $Java
                JavaVersion = $JavaVersion
                ODBC = $ODBC
                ODBCVersion = $ODBCVersion
                SQLNativeClient = $SQLNativeClient
                SQLNativeClientVersion = $SQLNativeClientVersion

        }

        $Hash | Export-Csv $ExportPath -NoTypeInformation
        return $Hash

        #endregion export data

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Exported the available data to $($ExportPath)"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }#process

    end {
        
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End Function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    }
        
}

#Function to fetch Windows License details
Function Get-WindowsLicense {
$LicenseData = Get-WmiObject SoftwareLicensingProduct `
-Filter "ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" `
-Property LicenseStatus -ErrorAction Stop
$data = New-Object psobject -Property @{
Status = [string]::Empty;
}
if ($LicenseData) {
:outer foreach($item in $LicenseData) {
switch ($item.LicenseStatus) {
0 {$data.Status = "Unlicensed"}
1 {$data.Status = "Licensed"; break outer}
2 {$data.Status = "Out-Of-Box Grace Period"; break outer}
3 {$data.Status = "Out-Of-Tolerance Grace Period"; break outer}
4 {$data.Status = "Non-Genuine Grace Period"; break outer}
5 {$data.Status = "Notification"; break outer}
6 {$data.Status = "Extended Grace"; break outer}
default {$data.Status = "Unknown value"}
}
}
} else { $data.Status = $status.Message }
$LicenseStatus = $data.Status
return $LicenseStatus 
}
Get-OSData -Verbose