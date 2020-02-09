function Start-SFTPTransfer {
    <#
        .SYNOPSIS
        This script downloads files from SFTP server.

        .DESCRIPTION
        This script is designed to download files from SFTP server for given SSH finger print, hostname
        and credentials. Source and destination path has to be provided to download and save the files.

        .PARAMETER WinSCPPath
        Provide the complete path of WinSCPnet.dll.
        E.g., "C:\Program Files\WinSCP\WinSCPnet.dll"

        .PARAMETER SourcePath
        Provide the path of source files.
        E.g., "/home/user/"

        .PARAMETER ComputerName
        Provide the SFTP server name or IP to download files from.
        E.g., "sftpservername" or "10.0.0.0"

        .PARAMETER SSHHostKeyFingerPrint
        Provide the SSH finger print key of SFTP server.
        E.g., "ssh-ras-1024-x"

        .PARAMETER Credential
        Provide the Credentials. You will be popped up for credentials automatically.

        .PARAMETER Destination
        Provide the destination path to save downloaded files.
        E.g., "C:\SFTP\Downloads\"

        .PARAMETER LogPath
        Provide the path to logfile to track the script progress information.
        E.g., "C:\Path\To\Folder"

        .EXAMPLE
        Start-SFTPTransfer -WinSCPPath "C:\Program Files (x86)\WinSCP\WinSCPnet.dll" `
                    -SourcePath "/home/usr/" `
                    -ComputerName "10.0.0.0" `
                    -SSHHostKeyFingerPrint "ssh-ras-1024-x" `
                    -Credential (Get-Credential) `
                    -Destination "C:\TEMP" `
                    -LogPath "C:\TEMP" `
                    -Verbose
        
        .NOTES
        Author						Version			    Date			Notes
        --------------------------------------------------------------------------------------------------
        harish.karthic		        v1.0    			09/02/2020		Initial script
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ })]
        [String]$WinSCPPath,

        [Parameter(Mandatory = $true)]
        [String]$SourcePath,

        [Parameter(Mandatory = $true)]
        [String]$ComputerName,

        [Parameter(Mandatory = $true)]
        [String]$SSHHostKeyFingerPrint,

        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $true)]
        [String]$Destination,

        [Parameter(Mandatory = $false)]
        [String]$LogPath
    )

    begin {
        #initialise function variables
        $functionName = $MyInvocation.MyCommand.Name
        $LogFile = "$env:TMP\Start_SFTP_Transfer_$(Get-Date -Format ddMMyyyy).log"
        $SourcePath = $SourcePath.TrimEnd("/")
        $Destination = $Destination.TrimEnd("\")

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }

    process {
        try {
            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Trying to load WinSCPnet.dll"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            Add-Type -Path $WinSCPPath

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : WinSCPnet.dll has been loaded successfully"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Setting up session to download files"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            $SessionProperties = @{
                Protocol = [WinSCP.Protocol]::Sftp
                HostName = $ComputerName
                UserName = $Credential.UserName
                Password = $Credential.GetNetworkCredential().Password
                SSHHostKeyFingerPrint = $SSHHostKeyFingerPrint
            }

            $SessionOption = New-Object WinSCP.SessionOptions -Property $SessionProperties

            $WinSCPSession = New-Object WinSCP.Session

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : WinSCP session is successfully setup"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            try {
                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Connecting to SFTP to download files"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                $WinSCPSession.Open($SessionOption)

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Setting up transfer options"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                $SFTPTransferOptions = New-Object WinSCP.TransferOptions
                $SFTPTransferOptions.TransferMode = [WinSCP.TransferMode]::Binary

                $SFTPTransferResult = $WinSCPSession.GetFiles("$SourcePath/*", "$Destination\*", $false, $SFTPTransferOptions)

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Verifying transfer results from SFTP server"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Result : $($SFTPTransferResult.Check())"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                foreach ($file in $SFTPTransferOptions.Transfers) {
                    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Downloaded $($file.FileName)"
                    Write-Verbose $Message ; $Message | Out-File -Append $LogFile
                }
            }

            catch {
                Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).." -ForegroundColor Red
                " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).." | Out-File $LogFile -Append
            }
        }

        catch {
            Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).." -ForegroundColor Red
            " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).." | Out-File $LogFile -Append
        }
    }

    end {
        # cleaning up
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Disposing the connection"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        $WinSCPSession.Dispose()

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End Function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }
}
#EOF