Function Start-AzureVMs {
    
    <#
        .SYNOPSIS
        This script is to automatically power on the Azure VMs.

        .DESCRIPTION
        This script is designed to automatically power on the Azure VMs in the portal.
        It can be used to power on multiple VMs.
        Make sure that the input csv file contains servers under "Name" column and resource
        groups under "ResourceGroupName" coulumn. Please specify the resource group name
        corresponding to the VM in which the VM is placed.

        .PARAMETER Subscription
        String. Provide the subscription from which the servers has to be powered on.

        .PARAMETER InputFilePath
        String. Provide the path of input csv file where all the servers are saved.
        Example : C:\TEMP\Servers.csv.The Servers.csv file should contain servers and resource group name.

        .PARAMETER ExportPath
        String. Provide the path to export the results.

        .PARAMETER LogPath
        String. Provide the path to export the log information.

        .EXAMPLE
        Start-AzureVMs -Subscription "Subscription Name" -InputFilePath "C:\TEMP\Servers.csv" -ExportPath "C:\TEMP" -LogPath "C:\TEMP" -Verbose

        .NOTES
        Author						Version			Date			Notes
		--------------------------------------------------------------------------------------------------------------------
		harish.b.karthic		    v1.0			30/11/2019		Initial script
    
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$Subscription,
        
        [Parameter(Mandatory=$true)]
        [String]$InputFilePath,

        [Parameter(Mandatory=$true)]
        [String]$ExportPath,

        [Parameter(Mandatory=$true)]
        [String]$LogPath
    )

    begin {
        $functionName = $MyInvocation.MyCommand.Name
        $ExportPath = $ExportPath + "\PoweredOnVMsReport_$(Get-Date -f ddMMyyyy).html"
        $LogFile = $LogPath + "\PoweredOnVMsReport-Log_$(Get-Date -f ddMMyyyy).log"
        
        #region build html report
            $Output = "
            <HTML>
    	    <TITLE> POWER ON AZURE VMs </TITLE>
    	    <BODY background-color:peachpuff>
       	    <font color =""#B03A2E"" face=""Microsoft Tai le"">
       	    <H1> POWER ON AZURE VMs </H1>
    	    </font>
            <Table border=1 cellpadding=3 cellspacing=3><br>
            <TR bgcolor=#A9CCE3 align=center>
            <TD><B>Server Name</B></TD>
		    <TD><B>Subscription</B></TD>
            <TD><B>Resource Group Name</B></TD>
		    <TD><B>Status</TD></B>
            </TR> 
            "
        #endregion build html report

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }

    process {
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Selecting given subscription $($Subscription)"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        Select-AzSubscription -Subscription $Subscription | Out-Null

        $VMs = Import-Csv $InputFilePath

        try {
            foreach($VM in $VMs) {
                
                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Working with $($VM.Name)"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                $Splat = @{
                    Name = $VM.Name
                    ResourceGroupName = $VM.ResourceGroupName
                }

                $PowerOn = Start-AzVM @Splat
    
                $Output += "<TR><TD align='center' >$($VM.Name)</TD>"
                $Output += "<TD align='center' >$($Subscription)</TD>"
                $Output += "<TD align='center' >$($VM.ResourceGroupName)</TD>"
                
                If($PowerOn.Status -eq "Succeeded") {
                    $Output += "<TD align='center' bgcolor=#17A589>$($PowerOn.Status)</TD>"
                } 
                else {
                    $Output += "<TD align='center' bgcolor=#EC7063>$($PowerOn.Status)</TD></TR>"
                }
            }

            $Output | Out-File $ExportPath

        }
        Catch {
            Write-Verbose " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).."
            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).." | Out-File -Append $LogFile
        }

    }

    end {
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End Function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        Invoke-Item $ExportPath
    }

}
#EOF