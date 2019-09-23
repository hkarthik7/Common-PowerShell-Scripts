Function Get-AzureVMDetails {
<#

    .SYNOPSIS
    Gets VM name and IP information from Azure portal.

    .DESCRIPTION
    This script is designed to use with remote execution workflow and serves as an input file.
    Gets VM name and IP information from Azure portal for given subscription. For now this is
    designed to extract information from a single subscription.

    .PARAMETER
    .STRING. Subscription. Provide the subscription name.

    .PARAMETER
    .STRING. InputFile. Provide the inputfile name for which the necessary details has to be fetched.

    .PARAMETER
    .STRING. ExportPath. Provide the filepath to export information to a csv file name.

    .PARAMETER
    .STRING. Logpath. Provide the filepath to track the logs.

    .EXAMPLE
    Get-AzureVMDetails -Subscription "Subscription Name" -InputFile "C:\Temp\VMs.txt" -ExportPath "C:\Path\to\csvfile.csv" -LogPath "C:\Path\to\logfile" -Verbose

    .NOTES
	    Author						Version			Date			Notes
		--------------------------------------------------------------------------------------------------------------------
		harish.b.karthic		    v1.0			10/09/2019		Initial script
        harish.b.karthic		    v1.1			12/09/2019		Bug fixes and added additional checks. Modified the script to
                                                                    work with servers given in a text file.
        harish.b.karthic		    v1.2			13/09/2019		Bug fixes and minor tweaks
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullorEmpty()]
    [String]$Subscription,

    [Parameter(Mandatory=$false)]
    [String]$InputFile,

    [Parameter(Mandatory=$true)]
    [String]$ExportPath,

    [Parameter(Mandatory=$true)]
    [String]$LogPath

)

begin {

    #initialize function variables
    $functionName = $MyInvocation.MyCommand.Name
    $Logfile = $LogPath + "\VM_$($Subscription)_$(Get-Date -Format dd-MM-yyyy).log"
    $ExportPath = $ExportPath.TrimEnd("\")
    $ExportPath = $ExportPath + "\VM_$($Subscription)_$(Get-Date -Format dd-MM-yyyy).csv"

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    
    #$AzureVMs = Get-AzVM
    $CSV = @()

}#begin

process {
    
    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Fetching VM details from Azure portal"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    try {

    Select-AzSubscription -Subscription $Subscription | Out-Null

    If($InputFile -ne "") {
        $AzureVMs = @()
        $VMs = Get-Content $InputFile
        Foreach($Server in $VMs) {
        $AzureVMs += Get-AzVM -Name $Server
        }

        } 
    else {$AzureVMs = Get-AzVM}

    #Fetch VM details
    Foreach($VM in $AzureVMs){
        
        #$VM = Get-AzVM -Name $AzureVM

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Working with $($VM.Name)"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile
        
        $Name = $VM.Name
        $State = $VM.ProvisioningState
        $Sub = $Subscription
        $Region = $VM.Location
        $username = $VM.OSProfile.AdminUsername
        $VMManagedDisk = If($VM.StorageProfile.OsDisk.ManagedDisk) {"Yes"} else {"No"}
        $VMSKU = $VM.StorageProfile.ImageReference.Sku
        $VMOSDisk = $VM.StorageProfile.OsDisk.DiskSizeGB
        $VMManagedDisks = $VM.StorageProfile.OsDisk.ManagedDisk
        $VMTags = ""
        $Tags = $VM.Tags
        If($Tags) {$Tags.GetEnumerator() | % { $VMTags += $_.Key +" "+ ":" +" "+ $_.Value + "`n" } } else {"N/A"}
       try{ $VMDisks = $VM.StorageProfile.DataDisks.GetEnumerator()
        If($VMDisks) {
            $DataDiskName = ""
            $DataDiskSize = ""
            Foreach($Disk in $VMDisks) {
                $DataDiskName += $Disk.Name + "`n"
                $DataDiskSize += ($Disk.DiskSizeGB).ToString() + "`n" 
                $DataDiskSize = $DataDiskSize
                } 
            } else {"N/A"} } Catch {Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }
        $License = $VM.LicenseType
        $ResourceGroup = $VM.ResourceGroupName
        $VMSize = $VM.HardwareProfile.VmSize
        $Platform = $VM.OSProfile
        $Platform = If($VM.OSProfile.WindowsConfiguration) {"Windows"} elseif($VM.OSProfile.LinuxConfiguration) {"Linux"} else {"Others"}

        try{$AvailabilitySet = If($VM.AvailabilitySetReference) {($VM.AvailabilitySetReference.Id).Split("/")[-1]} else {"N/A"}} Catch{
        Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }

        try{$NetworkId = ($VM.NetworkProfile.NetworkInterfaces.Id).Split("/")[-1]} Catch{
        Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }
        try{$NetworkInterface = Get-AzNetworkInterface -Name $NetworkId -ResourceGroupName $ResourceGroup} Catch{
        Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }

        $LoadBalancer = $NetworkInterface.IpConfigurations.LoadBalancerBackendAddressPools
    
    If(!([String]::IsNullOrEmpty($LoadBalancer))) {

        $LoadBalancerName = ($LoadBalancer.Id).Split("/")[-3]
        $LoadBalancerResourceGroup = ($LoadBalancer.Id).Split("/")[4]
        $LoadBalancerFrontEndIP = $LoadBalancer.FrontendIpConfigurations.PrivateIpAddress
        $LoadBalancerIPAllocationMethod = $LoadBalancer.FrontendIpConfigurations.PrivateIpAllocationMethod
        #$LoadBalancerBackendPool = ($LoadBalancer.Id).Split("/")[-1]
        $LoadBalancerFrontEndPort = $LoadBalancer.LoadBalancingRules.FrontendPort
        $LoadBalancerLoadDistribution = $LoadBalancer.LoadBalancingRules.LoadDistribution
        $LoadBalancerBackEndPort = $LoadBalancer.LoadBalancingRules.FrontendPort
        $LoadBalancerProtocol = $LoadBalancer.LoadBalancingRules.Protocol
        $LoadBalancerProbeProtocol = $LoadBalancer.Probes.Protocol
        $LoadBalancerProbePort = $LoadBalancer.Probes.Port
        $LoadBalancerSKU = $LoadBalancer.SkU.Name
        $LoadBalancerFloatingIP = $LoadBalancer.LoadBalancingRules.EnableFloatingIP
        $LoadBalancerIdleTimeoutInMinutes = $LoadBalancer.LoadBalancingRules.IdleTimeoutInMinutes

                    } 
        else {
        
            $LoadBalancerName = "N/A"
            $LoadBalancerResourceGroup = "N/A"
            $LoadBalancerFrontEndIP = "N/A"
            $LoadBalancerIPAllocationMethod = "N/A"
            #$LoadBalancerBackendPool = "N/A"
            $LoadBalancerFrontEndPort = "N/A"
            $LoadBalancerLoadDistribution = "N/A"
            $LoadBalancerBackEndPort = "N/A"
            $LoadBalancerProtocol = "N/A"
            $LoadBalancerProbeProtocol = "N/A"
            $LoadBalancerProbePort = "N/A"
            $LoadBalancerSKU = "N/A"
            $LoadBalancerFloatingIP = "N/A"
            $LoadBalancerIdleTimeoutInMinutes = "N/A"
            
            }

        try{$VirtualNetwork = ($NetworkInterface.IpConfigurations.Subnet.Id).Split("/")[-3]} Catch{
        Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }

        try{$Subnet = ($NetworkInterface.IpConfigurations.Subnet.Id).Split("/")[-1]} Catch{
        Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }

        try{$IP = $NetworkInterface.IpConfigurations.PrivateIpAddress} Catch{
        Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }

        $Acceleratednetworking = $NetworkInterface.EnableAcceleratedNetworking
        $Acceleratednetworking = If($Acceleratednetworking -eq $true) {"Enabled"} else {"Disabled"}

        $ET = $VM.Extensions

        try{$Extensions = ($ET.Id).Split("/")[-1]} Catch{
        Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }

        If($Extensions -like "AzureCATExtensionHandler") {$Extensions = "Azure Monitoring Extension for SAP"} 
        elseif($Extensions -eq $null) {$Extensions = "No Extensions found"}
        else {$Extensions = "Others"}

        try{$ETOMS = ($ET.Id).Split("/")[-1]} Catch{
        Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }

        $ETOMS = If($ETOMS -eq $null) {"No Extensions found"} else {$ETOMS}
        $BootDiagnostics = $VM.DiagnosticsProfile.BootDiagnostics.Enabled
        $BootDiagnostics = If($BootDiagnostics -eq $true) {"Enabled"} else {"Disabled"}
        $GuestOSDiagnostics = Get-AzVMDiagnosticsExtension -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name
        $GuestOSDiagnostics = If($GuestOSDiagnostics) {"Enabled"} else {"Disabled"}
        $OMS = If(($ETOMS -like "*MMA*") -or ($ETOMS -like "*OMS*") -or ($ETOMS -like "*Monitoring*")) {"Yes"} else {"No"}

        $Hash = New-Object PSObject -Property ([Ordered]@{
            
            Servername = $Name
            State = $State
            Subscription = $Sub
            Region = $Region
            ResourceGroup = $ResourceGroup
            "VM SKU" = $VMSKU
            "VM Size" = $VMSize
            OSDISK = $VMOSDisk
            "MgdDisks" = $VMManagedDisk
            AvailabilitySet = $AvailabilitySet
            VirtualNetwork = $VirtualNetwork
            Subnet = $Subnet
            "Accel. Networking" = $Acceleratednetworking
            "Boot Diags" = $BootDiagnostics
            TAGS = $VMTags
            Disks = $DataDiskName
            DiskSize = $DataDiskSize
            Extensions = $Extensions
            LBname = $LoadBalancerName
            LBresourcegroup = $LoadBalancerResourceGroup
            FrontendPrivateIpAddress = $LoadBalancerFrontEndIP
            LBIPallocationmethod = $LoadBalancerIPAllocationMethod
            Frontendport = $LoadBalancerFrontEndPort
            Loaddistribution = $LoadBalancerLoadDistribution
            backendport = $LoadBalancerBackEndPort
            LBprotocol = $LoadBalancerProtocol
            Probeprotocol = $LoadBalancerProbeProtocol
            Probeport = $LoadBalancerProbePort
            LBSKU = $LoadBalancerSKU
            floatingIP = $LoadBalancerFloatingIP
            IdleTimeoutInMinutes = $LoadBalancerIdleTimeoutInMinutes
            Platform = $Platform
            "IP address" = $IP
            'Guest OS Diags ' = $GuestOSDiagnostics
            OMS = $OMS

        })
        
        $CSV += $Hash
        
    }#foreach

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Exporting the VM details to a CSV file"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    $CSV | Export-Csv -Path $ExportPath -NoTypeInformation

    } Catch {
            Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }

}#process

end {

    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End function"
    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    }
}

Get-AzureVMDetails -Subscription "mg-main01-prod" `
                   -InputFile "C:\Users\h.i.balasubramanian\OneDrive - Accenture\Mondelez\Inputs\Input.txt" `
                   -ExportPath "C:\Users\h.i.balasubramanian\OneDrive - Accenture\Mondelez\AzureChecks" `
                   -LogPath "C:\Users\h.i.balasubramanian\OneDrive - Accenture\Mondelez\Logs" `
                   -Verbose