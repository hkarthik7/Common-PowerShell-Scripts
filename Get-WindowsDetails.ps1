Function Get-WindowsOSDetails {

<#

    .SYNOPSIS
    Gets VM OS data.

    .DESCRIPTION
    This script is designed to run for a single server locally or remotely. It is designed to run as a parallel script
    with Invoke-RemoteScript-Workflow for Mondelez

    .PARAMETER
    .STRING. ExportPath. Provide the filepath to export information to a csv file.

    .PARAMETER
    .STRING. Logpath. Provide the filepath to track the logs.

    .EXAMPLE
    Get-WindowsOSDetails -ExportPath "C:\Path\to\outputfile" -LogPath "C:\Path\to\logfile" -Verbose

    .NOTES
	    Author						Version			Date			Notes
		--------------------------------------------------------------------------------------------------------------------
		harish.b.karthic		    v1.0.0			13/09/2019		Initial script
        harish.b.karthic		    v1.0.1			16/09/2019		Added more parameters as per build sheet
#>

[CmdletBinding()]
Param(

    [Parameter(Mandatory=$false)]
    [ValidateNotnullorEmpty()]
    [String]$ExportPath,

    [Parameter(Mandatory=$false)]
    [ValidateNotnullorEmpty()]
    [String]$LogPath

)

begin {

    #Initialize function variables
    $functionName = $MyInvocation.MyCommand.Name
    $ComputerName = $env:COMPUTERNAME

    #Create temp folder if not exists to save the report file
    $Folder = "C:\Temp"
    If(!(Test-Path $Folder)) {mkdir $Folder | Out-Null}

    #Set logpath if not provided
    If($LogPath -eq "") {$LogPath = $Folder}
    $Logfile = $LogPath + "\$($ComputerName)OSDataCollection_$(Get-Date -Format dd-MM-yyyy).log"

    #local hostname
    $ComputerName = $env:COMPUTERNAME

    #Set exportpath if not provided
    If($ExportPath -eq "") {$ExportPath = $Folder + "\$($ComputerName)-OSDetails.csv"} else {$ExportPath = $ExportPath + "\$($ComputerName)-OSDetails.csv"}

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

}

process {

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Fetching OS details"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #region extract details as per build sheet

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Time Format check.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #try to fetch 24hr time format
    try{$Time = (Get-ItemProperty 'HKCU:\Control Panel\International').sTimeFormat
    $TimeFormat = If(($Time -eq "HH:mm:ss") -or ($Time -eq "H:mm:ss")) {"24hr"} else {"12hr"}} Catch {"N/A"}

    #extract all installed softwared to iterate
    $InstalledSoftwares=Get-WmiObject -Class Win32_Product

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Software checks.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    
    #fetch details of needed softwares
    try{
        $RRegistry = Get-Item HKLM:\SOFTWARE\RedCloak
        If($RRegistry) {$RedCloadRegistry = $RRegistry} else{$RedCloadRegistry = "Remove"}
        $RedCloakVersion = "NA"
        foreach($software in $InstalledSoftwares){
           If($software.Name -like "*Red Cloak*") {$RedCloakVersion = $software.Version ;break} else {$RedCloakVersion = "Remove"}
        }}catch{$RedCloakVersion = "Remove";$RedCloadRegistry = "Remove"}
    
     try{
        $OMSAgent = "NA"
           If((Get-Service -Name HealthService).Status -eq "Running") {$OMSAgent = "Installed"} else {$OMSAgent = "Stopped or Removed"}
        }catch{$OMSAgent = "Remove"}

    try{
        $ODBCVersion = "NA"
        foreach($software in $InstalledSoftwares){
           If($software.Name -like "*ODBC*") {$ODBCVersion = $software.Version ;break} else {$ODBCVersion = "No"}
        }}catch{$ODBCVersion = "NA"}

    try{
        $CrowdStrikeDeviceControl = "NA"
        foreach($software in $InstalledSoftwares){
           If($software.Name -like "*CrowdStrike*") {$CrowdStrikeDeviceControl = $software.Version ;break} else {$CrowdStrikeDeviceControl = "No"}
        }}catch{$CrowdStrikeDeviceControl = "NA"}
    
    try{
        $SQLNativeClientVersion = "NA"
        foreach($software in $InstalledSoftwares){
           If($software.Name -like "*SQL Server 2012 Native Client*") {$SQLNativeClientVersion = $software.Version ;break} else {$SQLNativeClientVersion = "No"}
        }}catch{$SQLNativeClientVersion = "NA"}
    
    try{
        $CrowdStrikeSensorPlatform = ""
        $CrowdStrikeSensorPlatform = "NA"
        foreach($software in $InstalledSoftwares){
           If($software.Name -like "CrowdStrike Sensor Platform") {$CrowdStrikeSensorPlatform = $software.Version ;break} else {$CrowdStrikeSensorPlatform = "No"}
        }}catch{$CrowdStrikeSensorPlatform = "NA"}

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Mellanox Driver Version check.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #try to get Mellanox Driver Version
    $MellanoxDriverVersion = ""
    try{$MellanoxDriverVersion = (Get-WmiObject Win32_PnPSignedDriver | where {$_.DeviceName -like "*Mellanox*"}).DriverVersion}catch{$MellanoxDriverVersion = "NA"}

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Windows Defender check.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #try to get Windows Defender
    try{$WindowsDefender=(Get-WindowsFeature | Where-Object {$_.name -eq "Windows-Defender-GUI"}).Installstate
        If($WindowsDefender -eq "Available") {$WindowsDefender = "Remove"}
    }catch{$WindowsDefender = "NA"}

    #Fetch Windows defender exclusion details if installed
    If(((Get-WindowsFeature | Where-Object {$_.name -eq "Windows-Defender-GUI"}).Installstate) -eq "Installed") {
        
        $WindowsDefenderPreference = Get-MpPreference
        $WindowsDefenderExclusionExtension = ""
        $WindowsDefenderExclusionPath = ""
        $WindowsDefenderExclusionProcess = ""
        $WindowsDefenderExclusionExtension += $WindowsDefenderPreference.ExclusionExtension | % {$_ + ","}
        $WindowsDefenderExclusionPath += $WindowsDefenderPreference.ExclusionPath | % {$_ + ","}
        $WindowsDefenderExclusionProcess += $WindowsDefenderPreference.ExclusionProcess | % {$_ + ","}
       
    }

    else {
        $WindowsDefenderExclusionExtension = "NA"
        $WindowsDefenderExclusionPath = "NA"
        $WindowsDefenderExclusionProcess = "NA"
    }

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : CrowdStrike PNP driver Version check.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #try to get CrowdStrike PNP driver version
    try{$CSPNPdriverVersion = (Get-WmiObject Win32_PnPSignedDriver | Where-Object {$_.Manufacturer -like "*Crowd*"}).DriverVersion}catch{$CSPNPdriverVersion = "NA"}

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Services checks.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #fetch details of needed services
    try{$WindowsUpdate = (Get-Service -Name wuauserv).StartType}catch{$WindowsUpdate = "NA"}
    try{$XboxStartupType = (Get-Service XblAuthManager).StartType}catch{$XboxStartupType = "NA"}

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Windows Firewall check.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #find if windows firewall is enabled or not
    try{$WindowsFirewall = (Get-NetFirewallProfile -Name "Domain").Enabled
    $WinFirewall = If($WindowsFirewall) {"Enabled"} else {"Disabled"}
    } Catch{"N/A"}

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Certificates checks.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #fetch certificates details; 
    $CertificateReport = @()
    $LocalMachine = Get-ChildItem  Cert:\LocalMachine
                $i = 1
                $LocalMachine | % {
                
                    Get-ChildItem "$($_.PSDrive):\$($_.Location)\$($_.Name)" | % {
                    
                        if($_.PSParentPath.TrimStart("Microsoft.PowerShell.Security\Certificate::") -eq "LocalMachine\My"){
                             $IssuedTo = $_.GetNameInfo( 'SimpleName', $false)
                             $IssuedBy = $_.GetNameInfo( 'SimpleName', $true)
                             $CertificateReport += New-Object -TypeName PSObject -Property @{
                                IssuedTo = $IssuedTo
                                IssuedBy = $IssuedBy
                                Subject = $_.Subject
                                Issuer = $_.Issuer
                                DnsName = $_.DnsNameList.Unicode
                                FriendlyName = $_.FriendlyName
                                NotBefore= $_.NotBefore
                                NotAfter= $_.NotAfter
                            }

                            $i++
                        }
                    }
                }

    If(($CertificateReport.Subject) -like "*.krft.net*") {

        $Certificate = "Install"
    } else {$Certificate = "Not installed"}

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Windows patches check.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #find if list of patches are installed or not
    $WindowsPatchesToCheck = @("KB3199986", "KB4054590", "KB4132216", "KB4485447", "KB4503537", "KB4509091", "KB4512495")
    $WindowsInstalledPatches = (Get-HotFix).HotFIxID
    $WinPatchUpdate = ""

    Foreach($Patch in $WindowsPatchesToCheck) {
            If($WindowsInstalledPatches -contains $Patch) {
                $WindowsPatchUpdate = $Patch + " : " + $true + "`n"
            }
            else {
                $WindowsPatchUpdate = $Patch + " : " + $false + "`n"
            }
            $WinPatchUpdate += $WindowsPatchUpdate
        }
    
    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : OS Version check.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #Find OS version
    try{$OSVer = Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion'
    $OSVersion = $($OSVer.ReleaseId) + " " + "(" + $($OSVer.CurrentBuild) + "." + $($OSVer.UBR) + ")"}
    catch{"N/A"}

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Mandatory filepath checks.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #Find if the given paths are present or not
    $FilePath = @("C:\Software\Build", 
    "C:\Software\Build\ODBC-13-1-4414-46", 
    "C:\Software\Build\SQL Native Client", 
    "C:\Software\Build\Automic", 
    "C:\Software\Build\POST-PROVISIONIG",
	"C:\Software\Build\POST-PROVISIONIG\POSTVMBUILD.ps1",
	"C:\Software\Build\POST-PROVISIONIG\POSTDEPLOYMVQA.ps1",
	"C:\Software\Build\POST-PROVISIONIG\ImportExcel*.zip")

    $Paths = ""

    Foreach($Path in $FilePath) {
        If(Test-Path -Path $Path) {
            $Path = $Path + " : " + "Present" + "`n"
        }
        else {
            $Path = $Path + " : " + "Not Present" + "`n"
        }
        $Paths += $Path
    }

    #endregion extract details as per build sheet

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Completed all mandatory checks.."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Exporting the results to $($ExportPath).."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #region export data

    $Hash = [PSCustomObject]@{
        
            Name = $ComputerName
            TimeFormat = $TimeFormat
            WindowsUpdate = $WindowsUpdate
            WinFirewall = $WinFirewall
            Xbox = $XboxStartupType
            CrowdStrikePNPDrivers = $CSPNPdriverVersion
            CrowdStrikeDeviceControl = $CrowdStrikeDeviceControl
            CrowdStrikeSensor = $CrowdStrikeSensorPlatform
            RedCloakSoftware = $RedCloakVersion
            RedCloakRegistry = $RedCloadRegistry
            OMSAgentSoftware = $OMSAgent
            ODBC = $ODBCVersion
            SQLNativeClient = $SQLNativeClientVersion
            Mellanox = $MellanoxDriverVersion[0]
            WindowsDefender = $WindowsDefender
            WindowsDefenderExclusionExtension = $WindowsDefenderExclusionExtension
            WindowsDefenderExclusionPath = $WindowsDefenderExclusionPath
            WindowsDefenderExclusionProcess = $WindowsDefenderExclusionProcess
            WildcardCertificate = $Certificate
            WindowsUpdates = $WinPatchUpdate
            WindowsVersion = $OSVersion
            FileSystem = $Paths
        }

    $Hash | Export-Csv $ExportPath -NoTypeInformation
    return $Hash

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Results exported to $($ExportPath).."
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #endregion export data

}#process

end {
    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End function"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile
}#end

}
#EOF
Get-WindowsOSDetails -ErrorAction SilentlyContinue -Verbose