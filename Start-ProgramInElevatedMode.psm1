Function Start-ProgramInElevatedMode {
    <#
        .SYNOPSIS
        This script opens a program in an elevated (administrator mode).

        .DESCRIPTION
        This script is designed to open the given program in administrator mode.

        .PARAMETER Program
        .STRING. Provide the program that has to be started in an elevated mode.

        Eg., powershell.exe

        .PARAMETER LogPath
        .STRING. Provide the filepath to track the logs.

        .EXAMPLE
        Start-ProgramInElevatedMode -Program "powershell_ise.exe" -LogPath "C:\TEMP" -Verbose

        .LINK
        https://github.com/hkarthik7

        .NOTES
        Author						Version			Date			Notes
        --------------------------------------------------------------------------------------------------------------------
        harish.karthic		        v1.0			11/12/2019		Initial script

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$Program,

        [Parameter(Mandatory=$true)]
        [String]$LogPath
    )

    begin {
        # initialize function variables
        $FunctionName = $MyInvocation.MyCommand.Name
        $Logfile = $LogPath + "\Start-ProgramInElevatedMode_$(Get-Date -Format dd-MM-yyyy).log"

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }

    process {

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Validating if $($Program) is running in elevated mode"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        try {

            $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
            $ISAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

            If($ISAdmin -eq $false) {

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : $($Program) is not running in elevated mode; Hence opening in elevated mode"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                Start-Process $Program -Verb RunAs -ArgumentList ('-noprofile')
            }

            else {
                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : $($Program) is running in elevated mode; No action to take"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile
            }
        }
        Catch {
            Write-Verbose " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).."
            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
        }
    }

    end {
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End Function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }
}
#EOF