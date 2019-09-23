Function Compare-WindowsChecks {

<#

    .SYNOPSIS
    Compare Windows checks against VM image build sheet.

    .DESCRIPTION
    This script is designed to compare Windows results against VM image build sheet for Mondelez.
    Standards are formatted as json, so if any new checks are added to the build sheet can be
    appended to the json formatted checks and can be compared against the output.

    .PARAMETER
    .STRING. InputFilePath. Provide the inputfile name which contains necessary details that has to be compared.

    .PARAMETER
    .STRING. ExportPath. Provide the filepath to export information to a csv file name.

    .PARAMETER
    .STRING. Logpath. Provide the filepath to track the logs.

    .EXAMPLE
    Compare-WindowsChecks -InputFilePath "C:\Temp\WindowsOSData.csv" -ExportPath "C:\Path\to\csvfile.csv" -LogPath "C:\Path\to\logfile" -Verbose

    .NOTES
	    Author						Version			Date			Notes
		--------------------------------------------------------------------------------------------------------------------
		harish.b.karthic		    v1.0			13/09/2019		Initial script
        harish.b.karthic		    v1.1			16/09/2019		Bug fixes and added additional checks. 
        harish.b.karthic		    v1.2			17/09/2019		Bug fixes and minor tweaks. Added HTML report building variables.
#>

[CmdletBinding()]
Param(
    
    [Parameter(Mandatory=$true)]
    [String]$InputfilePath,

    [Parameter(Mandatory=$true)]
    [String]$ExportPath,
    
    [Parameter(Mandatory=$false)]
    [String]$ReportPath,

    [Parameter(Mandatory=$false)]
    [String]$LogPath

)

begin {

    #initialize function variables
    $functionName = $MyInvocation.MyCommand.Name
    $LogPath = If($LogPath -eq "") {$ExportPath}
    $LogFile = $LogPath + "\Windows-Comparison_$(Get-Date -Format ddMMyyyy).log"
    $ReportPath = $ExportPath +"\Windows-Comparison-Results_$(Get-Date -Format ddMMyyyy).htm"
    $ExportPath = $ExportPath +"\Windows-Comparison-Results_$(Get-Date -Format ddMMyyyy).csv"
    $WindowsOSData = Import-Csv $InputfilePath
    $CSV = @()

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin Function"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #region Standards formatted as json

$ClientStandards = @"
{
	"Header" : {
		"ClientName" : "Mondelez",
		"Classification" : "Highly Confidential",
		"Description" : "Mondelez post build checks for Windows. Formatted as per the build sheet provided.",
		"VersionHistory" : [
			{
				"Version" : "1.0.0",
				"Comment" : "Initial",
				"Date" : "13/09/2019",
				"Author" : "harish.b.karthic"
			}
		]
	},
	
	"Standards" : {
		"OSChecks" : {
			"Time" : {
					"Type": "Windows",
					"Name": "Time format validation",
					"Description": "Validate if 24hr time format is set",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships": "Domain, Workgroup",
					"Key": "Time",
					"Value": "Format",
					"Data": "24hr"
				},
			"WindowsDefender" :	{
					"Type": "Windows",
					"Name": "Roles and Features",
					"Description": "Validate if given Roles and Features are Installed",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships": "Domain, Workgroup",
					"Key": "Roles and Features",
					"Value": "Windows Defender",
					"Data": "Remove"
                },
            "WindowsDefenderExclusionExtension" :	{
					"Type": "Windows",
					"Name": "Roles and Features",
					"Description": "Validate if given Roles and Features are Installed",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships": "Domain, Workgroup",
					"Key": "Roles and Features",
					"Value": "Windows Defender Exclusion Extension",
					"Data": [".bak",".blg",".ldf",".mdf",".ndf",".mdmp",".trc",".trn",".xel",".xem"]
                },
            "WindowsDefenderExclusionPath" :	{
					"Type": "Windows",
					"Name": "Roles and Features",
					"Description": "Validate if given Roles and Features are Installed",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships": "Domain, Workgroup",
					"Key": "Roles and Features",
					"Value": "Windows Defender Exclusion Extension",
					"Data": ["C:\\usr\\sap\\DAA","C:\\Windows\\Cluster","E:\\Perfmon","D:\\Pagefile.sys","E:\\MSSQL"]
                },
            "WindowsDefenderExclusionProcess" :	{
					"Type": "Windows",
					"Name": "Roles and Features",
					"Description": "Validate if given Roles and Features are Installed",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships": "Domain, Workgroup",
					"Key": "Roles and Features",
					"Value": "Windows Defender Exclusion Extension",
                    "Data": [   "%ProgramFiles%\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Binn\\SQLAGENT.exe",
                                "%ProgramFiles%\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Binn\\sqllogship.exe",
                                "%ProgramFiles%\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Binn\\sqlmaint.exe",
                                "%ProgramFiles%\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Binn\\SQLServr.exe",
                                "%ProgramFiles%\\Microsoft SQL Server\\MSSQL13.MSSQLSERVER\\MSSQL\\Binn\\sqlwriter.exe"
                            ]
				},
			"Certificates" :	{
					"Type": "Windows",
					"Name": "Certificates",
					"Description": "Validate if given Certificate is Installed or not",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships": "Domain, Workgroup",
					"Key": "Certificates",
					"Value": "WildCard Certificate (*.krft.net)",
					"Data": "Install"
				},
			"WindowsPatches" :	{
					"Type": "Windows",
					"Name": "Windows Patches",
					"Description": "Validate if given list of Patches are Installed or not",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships": "Domain, Workgroup",
					"Key": "Windows Patches",
					"Value": "Updates",
					"Data": ["KB3199986 : True", "KB4054590 : True", "KB4132216 : True", "KB4485447 : True", "KB4503537 : True", "KB4509091 : True", "KB4512495 : True"]
				},
			"OSVersion" :	{
					"Type": "Windows",
					"Name": "Version",
					"Description": "Validate Windows Version",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships": "Domain, Workgroup",
					"Key": "Windows",
					"Value": "Version",
					"Data": "1607 (14393.3181)"
				},
			"FileSystem" :	{
					"Type":"Windows",
					"Name": "FileSystem",
					"Description": "Validate Windows FileSystem",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships": "Domain, Workgroup",
					"Key": "Windows",
					"Value": [	"C:\\Software\\Build : Present",
								"C:\\Software\\Build\\ODBC-13-1-4414-46 : Present", 
								"C:\\Software\\Build\\SQL Native Client : Present", 
								"C:\\Software\\Build\\Automic : Present", 
								"C:\\Software\\Build\\POST-PROVISIONIG : Present",
								"C:\\Software\\Build\\POST-PROVISIONIG\\POSTVMBUILD.ps1 : Present",
								"C:\\Software\\Build\\POST-PROVISIONIG\\POSTDEPLOYMVQA.ps1 : Present",
								"C:\\Software\\Build\\POST-PROVISIONIG\\ImportExcel*.zip : Present"	
							],
					"Data":  "Present"
				}
		},
		"Services" : {
			"WSUS" : {
					"Type": "Windows",
					"Name": "Services validation",
					"Description": "Validate given list of Windows services",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "Services",
					"Value": "Windows Update",
					"Data": "Disabled"
				},
			"Firewall" : {
					"Type": "Windows",
					"Name": "Services validation",
					"Description": "Validate given list of Windows services",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "Services",
					"Value": "Windows Firewall",
					"Data": "Disabled"
				},
			"Xbox" : {
					"Type": "Windows",
					"Name": "Services validation",
					"Description": "Validate given list of Windows services",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "Services",
					"Value": "Xbox",
					"Data": "Disabled"
				}
		},
		"Softwares" : {
			"CrowdStrikePNP" : {
					"Type": "Windows",
					"Name": "Softwares validation",
					"Description": "Validate given list of Windows Softwares",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "CrowdStrike",
					"Value": "PNP Drivers",
					"Data": "4.15.7851.0"
			},
			"CrowdStrikeDeviceControl" : {
					"Type": "Windows",
					"Name": "Softwares validation",
					"Description": "Validate given list of Windows Softwares",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "CrowdStrike",
					"Value": "Device Control",
					"Data": "4.17.8056.0"
			},
			"CrowdStrikeSensor" : {
					"Type": "Windows",
					"Name": "Softwares validation",
					"Description": "Validate given list of Windows Softwares",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "CrowdStrike",
					"Value": "Sensor",
					"Data": "4.24.8702.0"
			},
			"RedCloakSotware" :	{
					"Type": "Windows",
					"Name": "Softwares validation",
					"Description": "Validate given list of Windows Softwares",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "RedCloak",
					"Value": "Software",
					"Data": "Remove"
			},
			"RedCloakRegistry" : {
					"Type": "Windows",
					"Name": "Softwares validation",
					"Description": "Validate given list of Windows Softwares",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "RedCloak",
					"Value": "Registry",
					"Data": "Remove"
			},
			"OMS" :	{
					"Type": "Windows",
					"Name": "Softwares validation",
					"Description": "Validate given list of Windows Softwares",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "OMS Agent",
					"Value": "Software",
					"Data": "Installed"
			},
			"ODBC" : {
					"Type": "Windows",
					"Name": "Softwares validation",
					"Description": "Validate given list of Windows Softwares",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "Drivers",
					"Value": "ODBC",
					"Data": "13.1.4414.46"
			},
			"SQLNativeCLient": {
					"Type": "Windows",
					"Name": "Softwares validation",
					"Description": "Validate given list of Windows Softwares",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "Drivers",
					"Value": "SQL Native Client",
					"Data": "11.0.2100.60"
			},
			"Mellanox":	{
					"Type": "Windows",
					"Name": "Softwares validation",
					"Description": "Validate given list of Windows Softwares",
					"OperatingSystems": "2008,2008 R2,2012,2012 R2,2016",
					"Memberships":  "Domain, Workgroup",
					"Key": "Drivers",
					"Value": "Mellanox",
					"Data": "5.50.14688.0"
			}
		}
	}
}
"@

#endregion Standards formatted as json
    
    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Building html report"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #region build html report
    $Output = "
        <HTML>
    	<TITLE> WINDOWS COMPARISON RESULTS </TITLE>
    	<BODY background-color:peachpuff>
       	<font color =""#B03A2E"" face=""Microsoft Tai le"">
       	<H1> WINDOWS COMPARISON RESULTS </H1>
       	<H3> Base VM Image comparison post build <br></H3>
    	</font>
        <Table border=1 cellpadding=3 cellspacing=3><br>
        <TR bgcolor=#A9CCE3 align=center>
        <TD><B>Server Name</B></TD>
		<TD><B>Time Format</B></TD>
        <TD><B>Windows Update (WSUS) </B></TD>
		<TD><B>Windows Firewall</TD></B>
        <TD><B>Xbox</B></TD>
        <TD><B>CrowdStrike PNP Drivers</B></TD>
		<TD><B>CrowdStrike Device Control</B></TD>
        <TD><B>CrowdStrike Sensor</B></TD>
		<TD><B>RedCloak Software</TD></B>
        <TD><B>RedCloak Registry</B></TD>
        <TD><B>OMS Agent</B></TD>
		<TD><B>ODBC</B></TD>
        <TD><B>SQL Native Client</B></TD>
		<TD><B>Mellanox</TD></B>
        <TD><B>Windows Defender</B></TD>
        <TD><B>Windows Defender Exclusions - Extensions</B></TD>
        <TD><B>Windows Defender Exclusions - Folders</B></TD>
        <TD><B>Windows Defender Exclusions - Processes</B></TD>
        <TD><B>WildCard Certificate (*.krft.net)</B></TD>
		<TD><B>Windows Updates (Patches) </TD></B>
        <TD><B>Windows Version</B></TD>
        <TD><B>FileSystem</B></TD>
        </TR> 
    "
    #endregion build html report

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Done with building html report"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

}#begin

process {
    
    try {

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Comparing the standards against VM image sheet"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile  

    #region start comparison

    [PSCustomObject]$ClientJson = $ClientStandards | ConvertFrom-Json
    $AllStandards = $ClientJson.Standards
    $OSChecks = $AllStandards.OSChecks
    $ServicesChecks = $AllStandards.Services
    $SoftwareChecks = $AllStandards.Softwares

    Foreach($OSData in $WindowsOSData) {
    
        [String]$Patches = ""
        [String]$Files = ""
        [String]$WinDefExclusionExtension = ""
        [String]$WinDefExclusionPath = ""
        [String]$WinDefExclusionProcess = ""

        $Name = $OSData.Name
        $TimeFormat = $OSData.TimeFormat
        $CrowdStrikeDeviceControl = $OSData.CrowdStrikeDeviceControl
        $CrowdStrikePNPDrivers = $OSData.CrowdStrikePNPDrivers
        $CrowdStrikeSensor = $OSData.CrowdStrikeSensor
        $FileSystem = $OSData.FileSystem
        $Mellanox = $OSData.Mellanox
        $ODBC = $OSData.ODBC
        $OMSAgentSoftware = $OSData.OMSAgentSoftware
        $RedCloakRegistry = $OSData.RedCloakRegistry
        $RedCloakSoftware = $OSData.RedCloakSoftware
        $SQLNativeClient = $OSData.SQLNativeClient
        $WildcardCertificate = $OSData.WildcardCertificate
        $WindowsDefender = $OSData.WindowsDefender
        $WindowsDefenderExclusionExtension = $OSData.WindowsDefenderExclusionExtension
        $WindowsDefenderExclusionPath = $OSData.WindowsDefenderExclusionPath
        $WindowsDefenderExclusionProcess = $OSData.WindowsDefenderExclusionProcess
        $WindowsUpdate = $OSData.WindowsUpdate
        $WindowsUpdates = $OSData.WindowsUpdates
        $WindowsVersion = $OSData.WindowsVersion
        $WinFirewall = $OSData.WinFirewall
        $Xbox = $OSData.Xbox
    
        #Windows OS check validation
        $TFValidation = If($OSChecks.Time.Data -eq $TimeFormat) {$true} else {$false}
        $WDefender = If($OSChecks.WindowsDefender.Data -eq $WindowsDefender) {$true} else {$false}
        $Certs = If($OSChecks.Certificates.Data -eq $WildcardCertificate) {$true} else {$false}
            Foreach($Data in ($OSChecks.WindowsPatches.Data)) {
                $Patches += If(!($WindowsUpdates.Contains($Data))){$Data.Replace($true,$false) + "`n"}
            }
        $OSVer = If($OSChecks.OSVersion.Data -eq $WindowsVersion) {$true} else {$false}
            Foreach($file in ($OSChecks.FileSystem.Value)) {
                $Files += If(!($FileSystem.Contains($file))) {$file.Replace("Present","Not Present") + "`n"}
            }
        If($WDefender -eq $false) {
            Foreach($Extension in $OSChecks.WindowsDefenderExclusionExtension.Data) {
                $WinDefExclusionExtension += If(!($WindowsDefenderExclusionExtension.Contains($Extension))) {$Extension + " : " + $false + " " + "`n"}
            }

            Foreach($Path in $OSChecks.WindowsDefenderExclusionPath.Data) {
                $WinDefExclusionPath += If(!($WindowsDefenderExclusionPath.Contains($Path))) {$Path + " : " + $false + " " + "`n"}
            }

            Foreach($Process in $OSChecks.WindowsDefenderExclusionProcess.Data) {
                $WinDefExclusionProcess += If(!($WindowsDefenderExclusionProcess.Contains($Process))) {$Process + " : " + $false + " " + "`n"}
            }
            } 

        #Windows services validation
        $Fwall = If($ServicesChecks.Firewall.Data -eq $WinFirewall) {$true} else {$false}
        $WSUS = If($ServicesChecks.WSUS.Data -eq $WindowsUpdate) {$true} else {$false}
        $WinXbox = If($ServicesChecks.Xbox.Data -eq $Xbox) {$true} else {$false}

        #Windows softwares validation
        $CSDeviceControl = If($SoftwareChecks.CrowdStrikeDeviceControl.Data -eq $CrowdStrikeDeviceControl) {$true} else {$false}
        $CSPNP = If($SoftwareChecks.CrowdStrikePNP.Data -eq $CrowdStrikePNPDrivers) {$true} else {$false}
        $CSSensor = If($SoftwareChecks.CrowdStrikeSensor.Data -eq $CrowdStrikeSensor) {$true} else {$false}
        $RCloak = If($SoftwareChecks.RedCloakSotware.Data -eq $RedCloakSoftware) {$true} else {$false}
        $RRegistry = If($SoftwareChecks.RedCloakRegistry.Data -eq $RedCloakRegistry) {$true} else {$false}
        $OMS = If($SoftwareChecks.OMS.Data -eq $OMSAgentSoftware) {$true} else {$false}
        $ODBCVer = If($SoftwareChecks.ODBC.Data -eq $ODBC) {$true} else {$false}
        $SQLNC = If($SoftwareChecks.SQLNativeCLient.Data -eq $SQLNativeClient) {$true} else{$false}
        $MellanoxVer = If($SoftwareChecks.Mellanox.Data -eq $Mellanox) {$true} else {$false}

        #Collect all data for report extraction
        $Hash = [PSCustomObject]@{
    
            Name = $Name
            TFValidation = $TFValidation
            'Windows Update (WSUS) ' = $WSUS
            'Windows Firewall' = $Fwall
            Xbox = $WinXbox
            'CrowdStrike PNP Drivers' = $CSPNP
            'CrowdStrike Device Control' = $CSDeviceControl
            'CrowdStrike Sensor' = $CSSensor
            'RedCloak Software' = $RCloak
            'RedCloak Registry' = $RRegistry
            'OMS Agent Software' = $OMS
            'Drivers ODBC' = $ODBCVer
            'Drivers SQL Native Client' = $SQLNC
            'Drivers Mellanox' = $MellanoxVer
            'Windows Defender' = $WDefender
            'Windows Defender Exclusions - Extensions' = $WinDefExclusionExtension
            'Windows Defender Exclusions - Folders' = $WinDefExclusionPath
            'Windows Defender Exclusions - Processes' = $WinDefExclusionProcess
            'WildCard Certificate (*.krft.net)' = $Certs
            'Windows Updates (Patches) ' = $Patches
            'Windows Version' = $OSVer
            FileSystem = $Files
    
        }

        $CSV += $Hash
        
            #region add the collected parameters to HTML report
            #TODO : Make the HTML report more robust and re useable
            $Output += "<TR><TD align='center' >$($Name)</TD>"

            If($Hash.TFValidation -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'Windows Update (WSUS) ' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'Windows Firewall' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.Xbox -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'CrowdStrike PNP Drivers' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'CrowdStrike Device Control' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'CrowdStrike Sensor' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'RedCloak Software' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'RedCloak Registry' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'OMS Agent Software' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'Drivers ODBC' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'Drivers SQL Native Client' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'Drivers Mellanox' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If($Hash.'Windows Defender' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }

            If(($Hash.'Windows Defender Exclusions - Extensions')) {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$(($Hash.'Windows Defender Exclusions - Extensions'))</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center'>$(($Hash.'Windows Defender Exclusions - Extensions'))</TD>
                "
            }

            If(($Hash.'Windows Defender Exclusions - Folders')) {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$(($Hash.'Windows Defender Exclusions - Folders'))</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center'>$(($Hash.'Windows Defender Exclusions - Folders'))</TD>
                "
            }

            If(($Hash.'Windows Defender Exclusions - Processes')) {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$(($Hash.'Windows Defender Exclusions - Processes'))</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center'>$(($Hash.'Windows Defender Exclusions - Processes'))</TD>
                "
            }

            If($Hash.'WildCard Certificate (*.krft.net)' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }
        
            If(($Hash.'Windows Updates (Patches) ')) {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($Hash.'Windows Updates (Patches) ')</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 

            If($Hash.'Windows Version' -eq $true) {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($false)</TD>
                "
            }
        
            If(($Hash.FileSystem).Contains("Not Present")) {
    
                $Output += "
                    <TD align='center' bgcolor=#EC7063>$($Hash.FileSystem)</TD>
                "
            } 
            else {
    
                $Output += "
                    <TD align='center' bgcolor=#17A589>$($true)</TD></TR>
                "
            }           
            #endregion add the collected parameters to HTML report
    }

    } Catch {
        
        Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
    
    }
#endregion comparison
    
    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Exporting results"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    #region export reports

    $CSV | Export-Csv $ExportPath -NoTypeInformation
    $Output | Out-File $ReportPath

    #endregion export reports

}#process

end {
    
    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End Function"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    
    Invoke-Item $ReportPath
}

}

Compare-WindowsChecks -InputfilePath "C:\Temp\Mondelez\WindowsChecks\WindowsOSChecks-$(Get-Date -f "dd-MM-yyyy").csv" `
                      -ExportPath "C:\Temp\Mondelez\Comparison" `
                      -Verbose