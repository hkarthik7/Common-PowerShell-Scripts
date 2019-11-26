Function Get-AzureBackup {

    <#
        
        .SYNOPSIS
        Gets VM name Backup information from Azure portal.

        .DESCRIPTION
        This script is designed to extract complete backup information for given subscription.

        .PARAMETER Subscriptions
        .STRING Array. Subscriptions. Provide the subscription name.

        .PARAMETER ExportPath
        .STRING. ExportPath. Provide the filepath to export information to a csv file name.

        .PARAMETER Logpath
        .STRING. Logpath. Provide the filepath to track the logs.

        .EXAMPLE
        Get-AzureBackup -Subscription ("Subscription Name","Subscription Name1") -ExportPath "C:\Temp" -LogPath "C:\Temp" -Verbose

        .NOTES
        Author						Version			Date			Notes
        --------------------------------------------------------------------------------------------------------------------
        harish.b.karthic		    v1.0			12/09/2019		Initial script

    #>

    [CmdletBinding()]
    Param(
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [String[]]$Subscriptions,

        [Parameter(Mandatory=$true)]
        [String]$ExportPath,

        [Parameter(Mandatory=$true)]
        [String]$LogPath

    )

    begin {

        #initialize function variables
        $functionName = $MyInvocation.MyCommand.Name
        $Logfile = $LogPath + "\Backup_$($Subscription)_$(Get-Date -Format dd-MM-yyyy).log"
        $ExportPath = $ExportPath.TrimEnd("\")
        $ExportPath = $ExportPath + "\Backup_$($Subscription)_$(Get-Date -Format dd-MM-yyyy).csv"

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function.."
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        $CSV = @()

    }#begin

    process {

        try {
            
            foreach($Subscription in $Subscriptions) {

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Selecting the given Subscription $($Subscription).."
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                Select-AzSubscription -Subscription $Subscription | Out-Null

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Fetching Vault details.."
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                $Vaults = Get-AzRecoveryServicesVault

                Foreach($Vault in $Vaults) {
                    
                    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Working with Vault $($Vault.Name).."
                    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                    #Set current vault from which the details has to be fetched
                    Set-AzRecoveryServicesVaultContext -Vault $Vault -WarningAction SilentlyContinue
                    $Containers = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -Status "Registered.."

                    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Fetching backup information from available containers.."
                    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                    Foreach($Container in $Containers) {
                    
                        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Fetching backup information for $($Container.FriendlyName).."
                        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
                        
                        $BackupState = Get-AzRecoveryServicesBackupItem -Container $Container -WorkloadType AzureVM
                        $BackupVMName = ($BackupState.VirtualMachineId).Split("/")[-1]
                        $Backupenabled = If($BackupState.ProtectionState -eq "Protected"){"Enabled"} else {"Disabled"}
                        $BackupPolicy = $BackupState.ProtectionPolicyName

                        $Hash = [PSCustomObject]@{
            
                            BackupVMName = $BackupVMName
                            Backupenabled = $Backupenabled
                            BackupPolicy = $BackupPolicy
                        }
                        $CSV += $Hash

                    }

                }#foreach

            }#foreach

            $CSV | Export-Csv $ExportPath -NoTypeInformation

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Backup information is fetched and saved to $($ExportPath).."
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        } 
        Catch{
            Write-Verbose " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).."
            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).." | Out-File -Append $LogFile
        }

    }#process

    end {

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End Function.."
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    }

}
#EOF
