Function Get-AzureBackupStatus {

    <#
        
        .SYNOPSIS
        Get backup job status for given hours.

        .DESCRIPTION
        This script is designed to run and fetch the information of backup job status for given hours.

        .PARAMETER Subscriptions
        STRING. Subscriptions. Provide the subscription name.

        .PARAMETER OutputPath
        STRING. OutputPath. Provide the filepath to export information to a csv file name.

        .PARAMETER LastBackupHours
        Int. LastBackupHours. Provide the number of hours for which the backup details has to be fetched.

        .PARAMETER Logpath
        STRING. Logpath. Provide the filepath to track the logs.

        .EXAMPLE
        Get-AzureBackupStatus -Subscriptions "Subscription Name","Subscription Name 2" -LastBackupHours 48 -OutputPath "C:\Temp" -LogPath "C:\Temp" -Verbose

        .NOTES
        Author						Version			Date			Notes
        --------------------------------------------------------------------------------------------------------------------
        harish.b.karthic		    v1.0			12/09/2019		Initial script

    #>

    [CmdletBinding()]
    Param(

        [Parameter(Mandatory=$true)]
        [ValidateNotnullorEmpty()]
        [String[]]$Subscriptions,

        [Parameter(Mandatory=$true)]
        [ValidateNotnullorEmpty()]
        [Int]$LastBackupHours,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [String]$OutPutPath,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [String]$LogPath

    )

    Begin {
        
        #initialize function variables
        $FunctionName = $MyInvocation.MyCommand.Name
        $OutPutPath = $OutPutPath + "\Last$($LastBackupHours)HoursBackupDetails_$(Get-Date -Format dd-MM-yyyy).csv"
        $Logfile = $LogPath + "\Last$($LastBackupHours)HoursBackupDetails_$(Get-Date -Format dd-MM-yyyy).log"
        $CSV = @()

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function.."
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    }#Begin

    Process {

        try {
            
            Foreach($Subscription in $Subscriptions) {

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Selecting Subscription $($Subscription) to work with.."
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                #Select the given subscription
                Select-AzSubscription -Subscription $Subscription | Out-Null

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Fetching Vault information.."
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                #fetch information from all vaults
                $Vaults = Get-AzRecoveryServicesVault
        
                Foreach($Vault in $Vaults) {
                
                    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Working with Vault $($Vault.Name).."
                    Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                    $BackupStatus = Get-AzRecoveryServicesBackupJob -VaultId $Vault.ID -From (Get-Date).AddHours(-$($LastBackupHours)).ToUniversalTime()

                    #Get required values
                    Foreach($Status in $BackupStatus) {

                        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Fetching backup details of $($Status.WorkloadName).."
                        Write-Verbose $Message ; $Message | Out-File -Append $LogFile   

                        $CSV += [PSCustomObject]@{
                        
                            Name = $Status.WorkloadName
                            Operation = $Status.Operation
                            Status = $Status.Status
                            StartTime = $Status.StartTime
                            EndTime = $Status.EndTime
                            Duration = $Status.Duration
                            JobID = $Status.JobId
                            Subscription = $Subscription
                        
                        }
                        
                    }
                    
                }

            }

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Exporting Backup details to $($OutPutPath).."
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile
        
            $CSV | Export-Csv $OutPutPath -NoTypeInformation
        
        }
        Catch {
        
            Write-Verbose " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).."
            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        
        }#Catch
            
    }#Process

    end {

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End function.."
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

    }#end

#EOF
}
