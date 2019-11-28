Function Export-ServerHealthDetails {
    <#
        .SYNOPSIS
        .This script exports the basic server health details.

        .DESCRIPTION
        .This is an advanced PowerShell script which exports servers health details and projects the data
        in a CSV report. This exports basic details such as server's uptime, automatic services which
        are in stopped state, average CPU & Memory usage and disk usage details.

        .PARAMETER InputFile
        .String. Path to inputfile where the server names are listed and saved. This has to be a text
        file and should contain only server names.

        .PARAMETER ExportPath
        .String. Path to export the report file.

        .PARAMETER LogPath
        .String. Path to save the logfile.

        .EXAMPLE
        Export-ServerHealthDetails -InputFile C:\TEMP\servers.txt -ExportPath C:\TEMP -LogPath C:\TEMP -Verbose

        .NOTES
        Author						Version			Date			Notes
        --------------------------------------------------------------------------------------------------------------------
        harish.b.karthic		    v1.0			12/04/2016		Initial script
        harish.b.karthic            v1.1            26/11/2019      Converted into advanced function and added CSV reporting 
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$InputFile,
        
        [Parameter(Mandatory=$true)]
        [String]$ExportPath,

        [Parameter(Mandatory=$true)]
        [String]$LogPath
    )

    begin {
        
        #initialize function variables
        $FunctionName = $MyInvocation.MyCommand.Name
        $ExportPath = $ExportPath + "\ServersHealthCheckDetails_$(Get-Date -Format dd-MM-yyyy).csv"
        $Logfile = $LogPath + "\ServerHealthCheckDetails_$(Get-Date -Format dd-MM-yyyy).log"
        $CSV = @()

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : Begin function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    
    }

    process {
        
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : Started extracting information for basic health check"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        #exporting the contents of input file
        $Servers = Get-Content $InputFile

        Foreach($Server in $Servers) {
            
            try {
                
                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : Working with $($Server)"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : Fetching average CPU usage"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                #region data collection

                #fetching average CPU usage
                $CPU = Get-WmiObject -Class Win32_Processor -ComputerName $Server | Measure-Object -property LoadPercentage -Average | Select-Object Average

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : Fetching average Memory usage"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile
                
                #fetching average memory usage
                $Memory = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Server | 
                Select-Object @{Name = "MemoryUsage"; Expression = {“{0:N2}” -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }}

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : Fetching Disk space usage"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                #fetching disk space usage
                $Drives = Get-WmiObject win32_logicaldisk -ComputerName $server -Filter "Drivetype=3"
                $DeviceID = ""
                $DiskSpace = ""
                $TotalDiskSize = ""

                Foreach($Drive in $Drives) {
                    $DeviceID += $Drive.DeviceID
                    $TotalDiskSize = ($Drive.Size/1GB -as [Int])
                    $DiskSpace += ($Drive.FreeSpace/1GB -as [Int])
                }

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : Fetching automatic stopped services"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                #fetching stopped automatic services
                $Services = Get-WmiObject -Class Win32_Service -ComputerName $server -Filter "State = 'Stopped'" | Where-Object {$_.StartMode -eq "Auto"} | Select-Object Name
                $StoppedServices = ""

                Foreach($Service in $Services) {
                    $StoppedServices += $Service.Name + "`n"
                }

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : Fetching Server last bootup time"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                #fetching server uptime
                $WMI = Get-WmiObject -class Win32_OperatingSystem -ComputerName $Server
                $BootTime = $WMI.ConvertToDateTime($WMI.Lastbootuptime)
                [TimeSpan]$Uptime = New-TimeSpan $BootTime $(get-date)
                $UptimeMessage = "$($Uptime.Days)Days $($Uptime.Hours)Hours $($Uptime.Minutes)Minutes $($Uptime.Seconds)Seconds"

                #endregion data collection

                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : Finished with fetching all the details"
                Write-Verbose $Message ; $Message | Out-File -Append $LogFile

                $Hash = [PSCustomObject]@{
                    
                    ServerName = $Server
                    CPUUsage = $CPU.Average
                    MemoryUsage = $Memory.MemoryUsage
                    DriveID = $DeviceID
                    "TotalVolumeSize(GB)" = $TotalDiskSize
                    "FreeSpaceAvailable(GB)" = $DiskSpace
                    StoppedAutomaticServices = ($StoppedServices).TrimEnd()
                    UpTime = $UptimeMessage
                                  
                }

                $CSV += $Hash
            }
            Catch {
                
                Write-Verbose " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).."
                "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
            }       
        }

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : Exporting report"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        #TODO : Validate the script and enhance it to export the results to HTML report
        $CSV | Export-Csv $ExportPath -NoTypeInformation    
    }

    end {
        
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $FunctionName : End Function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }
}
#EOF