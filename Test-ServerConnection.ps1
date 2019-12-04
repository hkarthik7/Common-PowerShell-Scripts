Function Test-ServerConnection {
    
    <#
        .SYNOPSIS
        Checks multiple server connection and generates a report in HTML file.

        .DESCRIPTION
        This script is designed to test the connectivity of multiple server given in a 
        text file. Once all the checks are done, it generates a HTML report with success
        and failure logs.

        .PARAMETER InputFilePath
        Provide the input file path which should be a text file and contains servers for
        which the connectivity has to be checked.
        Example : C:\Temp\servers.txt
        
        .PARAMETER ExportPath
        Provide the path to export the HTML report.
        Example : C:\Temp\

        .PARAMETER LogPath
        Provide that path to export log information.
        Example : C:\Temp\

        .EXAMPLE
        Test-ServerConnection -InputFilePath C:\Servers.txt -ExportPath C:\Temp -LogPath C:\Temp -Verbose

        .NOTES
        Author						Version			Date			Notes
        --------------------------------------------------------------------------------------------------------------------
        harish.karthic		        v1.0			04/12/2019		Initial script

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$InputFilePath,

        [Parameter(Mandatory=$true)]
        [String]$ExportPath,

        [Parameter(Mandatory=$true)]
        [String]$LogPath
    )

    begin {
        
        #initialise function variables
        $functionName = $MyInvocation.MyCommand.Name
        $ExportPath = $ExportPath.Trim("\") + "\Test-ServerConnection_$(Get-Date -f ddMMyyy).html"
        $LogFile = $LogPath.Trim("\") + "\Test-ServerConnection_$(Get-Date -f ddMMyyy).log"
        
        #region build html report
            $Output = "
            <HTML>
    	    <TITLE> CHECK SERVERS CONNECTIVITY STATUS </TITLE>
    	    <BODY background-color:peachpuff>
       	    <font color =""#B03A2E"" face=""Microsoft Tai le"">
       	    <H1> CHECK SERVERS CONNECTIVITY STATUS ( PING & RDP ) </H1>
    	    </font>
            <Table border=1 cellpadding=3 cellspacing=3><br>
            <TR bgcolor=#A9CCE3 align=center>
            <TD><B>Server Name</B></TD>
		    <TD><B>Ping Status</B></TD>
            <TD><B>RDP Status</B></TD>
            </TR> 
            "
        #endregion build html report

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function.."
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }

    process {
        
        #fetch the server names from the input file
        $Servers = Get-Content $InputFilePath

        try {
            
            Foreach($server in $Servers) {
                
                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Working with $($server).."
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                #server ping status and RDP status check
                $ServerConnection = Test-Connection -ComputerName $server -Quiet -ErrorAction SilentlyContinue
                $TCPConnection = Test-NetConnection -ComputerName $server -Port 3389 -WarningAction SilentlyContinue

                $Output += "<TR><TD align='center' >$($server)</TD>"

                If($ServerConnection -and $TCPConnection.TcpTestSucceeded) {
                    $Output += "<TD align='center' bgcolor=#17A589>$($ServerConnection)</TD>"
                    $Output += "<TD align='center' bgcolor=#17A589>$($TCPConnection.TcpTestSucceeded)</TD>"
                }

                else {
                    $Output += "<TD align='center' bgcolor=#EC7063>$($ServerConnection)</TD>"
                    $Output += "<TD align='center' bgcolor=#EC7063>$($TCPConnection.TcpTestSucceeded)</TD></TR>"
                }
            }

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Exporting the results to $($ExportPath).."
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            $Output | Out-File $ExportPath
        }
        Catch {
            Write-Verbose " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).."
            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).." | Out-File -Append $LogFile
        }
    }

    end {
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End function.."
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        Invoke-Item $ExportPath
    }
}