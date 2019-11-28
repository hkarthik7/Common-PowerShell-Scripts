Function Get-AzureVMDetails {
    <#

        .SYNOPSIS
        Gets VM name,IP and other information from Azure portal.

        .DESCRIPTION
        This script extracts the VM name, IP and other information from Azure portal for given subscription.
        Provide the servers in a text file to import information only for those servers. If the inpufile
        is not given then the script extracts for the given subscription.

        .PARAMETER
        .STRING. Subscription. Provide the subscription name.

        .PARAMETER
        .STRING. ExportPath. Provide the filepath to export information to a csv file name.

        .PARAMETER
        .STRING. Logpath. Provide the filepath to track the logs.

        .EXAMPLE
        Get-AzureVMDetails -Subscription "Subscription Name" -ExportPath "C:\Path\to\csvfile.csv" -LogPath "C:\Path\to\logfile" -Verbose

        .NOTES
            Author						Version			Date			Notes
            --------------------------------------------------------------------------------------------------------------------
            harish.b.karthic		    v1.0			10/09/2019		Initial script
            harish.b.karthic		    v1.1			13/09/2019		Added parameters

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [String]$Subscription,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
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

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Working with $($VM.Name)"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                $Name = $VM.Name
                $Sub = $Subscription
                $Region = $VM.Location
                $username = $VM.OSProfile.AdminUsername
                $VMManagedDisk = If($VM.StorageProfile.OsDisk.ManagedDisk) {"Yes"} else {"No"}                
                $License = $VM.LicenseType
                $ResourceGroup = $VM.ResourceGroupName
                $VMSize = $VM.HardwareProfile.VmSize
                $Platform = $VM.OSProfile
                $Platform = If($VM.OSProfile.WindowsConfiguration) {"Windows"} elseif($VM.OSProfile.LinuxConfiguration) {"Linux"} else {"Others"}
                $BootDiagnostics = $VM.DiagnosticsProfile.BootDiagnostics.Enabled
                $BootDiagnostics = If($BootDiagnostics -eq $true) {"Enabled"} else {"Disabled"}
                $GuestOSDiagnostics = Get-AzVMDiagnosticsExtension -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name
                $GuestOSDiagnostics = If($GuestOSDiagnostics) {"Enabled"} else {"Disabled"}

                $Hash = New-Object PSObject -Property ([Ordered]@{
                
                    Name = $Name
                    Subscription = $Sub
                    Region = $Region
                    ResourceGroup = $ResourceGroup
                    Username = $username
                    LicenseType = $License
                    VMSize = $VMSize
                    Platform = $Platform
                    VMManagedDisk = $VMManagedDisk                    
                    BootDiagnostics = $BootDiagnostics
                    GuestOSDiagnostics = $GuestOSDiagnostics

                })

                $CSV += $Hash

            }#foreach

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Exporting the VM details to a CSV file"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile
           
            $CSV | Export-Csv -Path $ExportPath -NoTypeInformation

        } 
        Catch {
            Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }

    }#process

    end {

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    }
}
#EOF