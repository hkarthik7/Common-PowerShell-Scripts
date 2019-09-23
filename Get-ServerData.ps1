<#
    .SYNOPSIS
    Extracts the defined data from individual server.

    .DESCRIPTION
    This script is designed to extracts multiple details from an individual server.
    It cannot be used for remote query as the script is purposely designed to
    run with Invoke-Command for parallel execution.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false)]
    [String]$outfilepath = $env:TEMP
)

#Create temp folder to save reports
If($outfilepath -eq "") {
    $outfilepath = $env:TEMP
}

#Define local computer name
$ComputerName = $env:COMPUTERNAME

#Common function to extract Registry values
Function Get-RegistryValue {

    <#
    .SYNOPSIS
    Function to get the registry value for given registry path.
    
    .DESCRIPTION
    Extracts registry value for the given path.
    
    .EXAMPLE
    Get-RegistryValue -RegistryPath HKLM:\Software

    #>

    [CmdletBinding()]
    Param(

    [Parameter(Mandatory=$true)]
    [String]$RegistryPath

    )
    
    Get-ItemProperty $RegistryPath

    return $RegistryPath
}

#Get all Services
Function Get-KVService {
    
    Param($ComputerName)

    $Output = @()
    $Services = @()

    foreach($service in (Get-Service)) {

        $Services += $service | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            Name, DisplayName, Status, StartType
    }

    $Output += [PSCustomObject]@{
        type = "Services"
        data = $Services
    }

    return $Output
}

#Get User Accounts
Function Get-KVLocalUser {

    Param($ComputerName)

    $Output = @()
    $LocalUsers = @()

    foreach($User in (Get-LocalUser)) {

        $LocalUsers += $User | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            Name, Description, Enabled, SID, ObjectClass
    }

    $Output += [PSCustomObject]@{
        type = "LocalUser"
        data = $LocalUsers
    }

    return $Output
}

#Get Local Group Members
Function Get-KVLocalGroupMember {
    
    Param($ComputerName)

    $Output = @()
    $LocalGroupMember = @()

    foreach($Member in (Get-LocalGroupMember -Group "Administrators")) {

        $LocalGroupMember += $Member | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, *
    }

    $Output += [PSCustomObject]@{
        type = "AdministratorGroupMembers"
        data = $LocalGroupMember
    }

    return $Output
}

#Get Operating System information
Function Get-KVOperatingSystem {
    
    Param($ComputerName)

    $Output = @()
    $OperatingSystem = @()

    foreach($entry in (Get-WmiObject -Class Win32_OperatingSystem)) {

        $OperatingSystem += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            Caption, ServicePackMajorVersion, ServicePackMinorVersion, Version
    }

    $Output += [PSCustomObject]@{
        type = "OperatingSystem"
        data = $OperatingSystem
    }

    return $Output
}

#Get Time Zone
Function Get-KVTimeZone {
    
    Param($ComputerName)

    $Output = @()
    $TimeZone = Get-TimeZone | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, *

    $Output += [PSCustomObject]@{
        type = "TimeZone"
        data = $TimeZone
    }

    return $Output
}

#Get Installed software
Function Get-KVSoftware {
    
    Param($ComputerName)

    $Output = @()
    $Softwares = @()

    foreach($Product in (Get-WmiObject -Class Win32_Product)) {

        $Softwares += $Product | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, Name, Version
    }

    $Output += [PSCustomObject]@{
        type = "InstalledSoftwares"
        data = $Softwares
    }

    return $Output
}

#Get Computer System information
Function Get-KVComputerSystem {
    
    Param($ComputerName)

    $Output = @()
    $ComputerSystem = @()

    foreach($entry in (Get-WmiObject -Class Win32_ComputerSystem)) {

        $ComputerSystem += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, PartOfDomain
    }

    $Output += [PSCustomObject]@{
        type = "ComputerSystem"
        data = $ComputerSystem
    }

    return $Output
}

#Get Disks information
Function Get-KVDisks {
    
    Param($ComputerName)

    $Output = @()
    $Disks = @()

    foreach($entry in (Get-WmiObject -Class Win32_Volume)) {

        $Disks += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            Name, 
            @{Name = "Capacity" ; Expression = { [Math]::Round($entry.Capacity/1GB) }}, 
            @{Name = "FreeSpace" ; Expression = { [Math]::Round($entry.FreeSpace/1GB) }}, Label, BlockSize
    }

    $Output += [PSCustomObject]@{
        type = "Disks"
        data = $Disks
    }

    return $Output
}

#Get Domain Subnets
Function Get-KVDomainSubnets {
    
    Param($ComputerName,$RegistryPath)

    $Output = @()
    $DomainSubnets = @()

    foreach($entry in (Get-RegistryValue -RegistryPath $RegistryPath)) {

        $DomainSubnets += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            DSubnetsAuthoritive, DomainSubnets
    }

    $Output += [PSCustomObject]@{
        type = "DomainSubnets"
        data = $DomainSubnets
    }

    return $Output
}

#Get Firewall Status
Function Get-KVWindowsFirewall {
    
    Param($ComputerName)

    $Output = @()
    $WindowsFirewall = @()

    foreach($entry in (Get-NetFirewallProfile)) {

        $WindowsFirewall += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            Name, Enabled
    }

    $Output += [PSCustomObject]@{
        type = "WindowsFirewall"
        data = $WindowsFirewall
    }

    return $Output
}

#Get Windows Activation Status
Function Get-KVWindowsActivation {
    
    Param($ComputerName)

    $Output = @()
    $WindowsActivation = @()

    foreach($entry in (Get-CimInstance -ClassName SoftwareLicensingProduct)) {

        $WindowsActivation += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            Name, PartialProductKey
    }

    $Output += [PSCustomObject]@{
        type = "WindowsActivation"
        data = $WindowsActivation
    }

    return $Output
}

#Get DNS Status
Function Get-KVDNS {
    
    Param($ComputerName)

    $Output = @()
    $DNS = @()

    foreach($entry in (Get-NetAdapter | Get-DnsClient -ErrorAction SilentlyContinue)) {

        $DNS += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            InterfaceAlias, InterfaceIndex, ConnectionSpecificSuffix, 
            ConnectionSpecificSuffixSearchList, RegisterThisConnectionsAddress, 
            UseSuffixWhenRegistering
    }

    $Output += [PSCustomObject]@{
        type = "DNS"
        data = $DNS
    }

    return $Output
}

#Get Default IP Gateway
Function Get-KVDefaultIPGateway {
    
    Param($ComputerName)

    $Output = @()
    $DefaultIPGateway = @()

    foreach($entry in (Get-WMIObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true})) {

        $DefaultIPGateway += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            DHCPEnabled, IPAddress, DefaultIPGateway, DNSDomain, ServiceName, Description
    }

    $Output += [PSCustomObject]@{
        type = "DefaultIPGateway"
        data = $DefaultIPGateway
    }

    return $Output
}

#Get Page file details
Function Get-KVPageFile {
    
    Param($ComputerName)

    $Output = @()
    $PageFile = @()

    foreach($entry in (Get-WmiObject -Class Win32_pagefileusage)) {

        $PageFile += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            Name, CurrentUsage, AllocatedBaseSize, PeakUsage, TempPageFile
    }

    $Output += [PSCustomObject]@{
        type = "PageFile"
        data = $PageFile
    }

    return $Output
}

#Get Network Interface details
Function Get-KVNetIPInterface {
    
    Param($ComputerName)

    $Output = @()
    $NetIPInterface = @()

    foreach($entry in (Get-NetIPInterface | where {$_.AddressFamily -like "IPV4"})) {

        $NetIPInterface += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            AutomaticMetric, ifIndex, InterfaceAlias, InterfaceMetric, AddressFamily, Dhcp, ConnectionState, 
            PolicyStore
    }

    $Output += [PSCustomObject]@{
        type = "NetIPInterface"
        data = $NetIPInterface
    }

    return $Output
}

#Get Windows Patches
Function Get-KVWindowsPatches {
    
    Param($ComputerName)

    $Output = @()
    $WindowsPatches = @()

    foreach($entry in (Get-HotFix)) {

        $WindowsPatches += $entry | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            Description, HotFixID, InstalledBy, InstalledOn
    }

    $Output += [PSCustomObject]@{
        type = "WindowsPatches"
        data = $WindowsPatches
    }

    return $Output
}

#Get Installed Drivers
Function Get-KVDrivers {
    
    Param($ComputerName)

    $Output = @()

    $Drivers = Get-WmiObject Win32_PnPSignedDriver | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
            Description, DeviceName, DriverVersion, DriverProviderName

    $Output += [PSCustomObject]@{
        type = "Drivers"
        data = $Drivers
    }

    return $Output
}

#Get Net Adapter Properties
Function Get-KVNetAdapterAdvancedProperty {
    
    Param($ComputerName)

    $Output = @()

    $NetAdapterAdvancedProperty = Get-NetAdapterAdvancedProperty | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
        Caption, Description, Name, DisplayName, ValueName, ValueData, DisplayValue   

    $Output += [PSCustomObject]@{
        type = "NetAdapterAdvancedProperty"
        data = $NetAdapterAdvancedProperty
    }

    return $Output
}

#Resolve DNS Name
Function Get-KVResolveDNSName {
    
    Param($ComputerName)

    $Output = @()

    $ResolveDNSName = Resolve-DnsName -Name $ComputerName | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
        IPAddress, Type, Name

    $Output += [PSCustomObject]@{
        type = "ResolveDNSName"
        data = $ResolveDNSName
    }

    return $Output
}

#Get Windows Feature
Function Get-KVWindowsFeature {
    
    Param($ComputerName)

    $Output = @()

    $WindowsFeature = Get-WindowsFeature | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
        Name, Description, Installed, InstallState, FeatureType

    $Output += [PSCustomObject]@{
        type = "WindowsFeature"
        data = $WindowsFeature
    }

    return $Output
}

#Get cluster Node details
Function Get-KVClusterNode {
    
    Param($ComputerName)

    $Output = @()

    $ClusterNode = Get-ClusterNode | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
        Name, Cluster, NodeName, State, StatusInformation

    $Output += [PSCustomObject]@{
        type = "ClusterNode"
        data = $ClusterNode
    }

    return $Output
}

#Get cluster Group details
Function Get-KVClusterGroup {
    
    Param($ComputerName)

    $Output = @()

    $ClusterGroup = Get-ClusterGroup | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
        Name, Cluster, OwnerNode, State

    $Output += [PSCustomObject]@{
        type = "ClusterGroup"
        data = $ClusterGroup
    }

    return $Output
}

#Get Keep alive time and interval from registry value
Function Get-KVKeepAliveTimeInterval {
    
    Param($ComputerName,$RegistryPath)

    $Output = @()

    $KeepAliveTimeInterval = Get-RegistryValue -RegistryPath $RegistryPath | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
        KeepAliveTime, KeepAliveInterval

    $Output += [PSCustomObject]@{
        type = "KeepAliveTimeInterval"
        data = $KeepAliveTimeInterval
    }

    return $Output
}

#Get DnsClientGlobalSetting
Function Get-KVDnsClientGlobalSetting {
    
    Param($ComputerName)

    $Output = @()

    $DnsClientGlobalSetting = Get-DnsClientGlobalSetting | Select-Object @{Name = "ServerName" ; Expression = { $ComputerName }}, 
        UseSuffixSearchList, SuffixSearchList, UseDevolution, DevolutionLevel

    $Output += [PSCustomObject]@{
        type = "DnsClientGlobalSetting"
        data = $DnsClientGlobalSetting
    }

    return $Output
}

#Get Windows Event Log

#CONTENTS HERE

#Main script flow

$Output = @()
$datestamp = Get-Date -Format "yyyy-MM-dd"

$Output += Get-KVOperatingSystem -ComputerName $ComputerName
$Output += Get-KVService -ComputerName $ComputerName
$Output += Get-KVLocalUser -ComputerName $ComputerName
$Output += Get-KVLocalGroupMember -ComputerName $ComputerName
$Output += Get-KVTimeZone -ComputerName $ComputerName
$Output += Get-KVSoftware -ComputerName $ComputerName
$Output += Get-KVComputerSystem -ComputerName $ComputerName
$Output += Get-KVDisks -ComputerName $ComputerName
$Output += Get-KVDomainSubnets -ComputerName $ComputerName -RegistryPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkIsolation"
$Output += Get-KVWindowsActivation -ComputerName $ComputerName
$Output += Get-KVWindowsFirewall -ComputerName $ComputerName
$Output += Get-KVDNS -ComputerName $ComputerName
$Output += Get-KVDefaultIPGateway -ComputerName $ComputerName
$Output += Get-KVPageFile -ComputerName $ComputerName
$Output += Get-KVNetIPInterface -ComputerName $ComputerName
$Output += Get-KVWindowsPatches -ComputerName $ComputerName
$Output += Get-KVDrivers -ComputerName $ComputerName
$Output += Get-KVNetAdapterAdvancedProperty -ComputerName $ComputerName
$Output += Get-KVResolveDNSName -ComputerName $ComputerName
$Output += Get-KVWindowsFeature -ComputerName $ComputerName
$Output += Get-KVClusterNode -ComputerName $ComputerName
$Output += Get-KVClusterGroup -ComputerName $ComputerName
$Output += Get-KVKeepAliveTimeInterval -ComputerName $ComputerName -RegistryPath "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$Output += Get-KVDnsClientGlobalSetting -ComputerName $ComputerName

#looping over each data in output
foreach ($table in $output) {
    $outfile = "{0}\{1}-{2}_{3}.csv" -f $outfilepath, $ComputerName, $table.type, $datestamp
    "`n$outfile`n"
    $table.data | ConvertTo-Csv -NoTypeInformation
    $table.data | Export-Csv -NoTypeInformation -path $outfile
}
