Workflow Invoke-RemoteScript {
    <#
        .SYNOPSIS
            Invoke a script on multiple servers
    
        .DESCRIPTION
            This function allows to execute script on multiple remote servers as a remote, background job.
            It runs on semi-pararell manner
    
        .PARAMETER ServerCsvPath
            Path to a CSV file which contains servers as input.
    
        .PARAMETER ScriptPathArgument
            Hashtable with list of script name and its Argument
            Path to the script intended to be executed.An array of argument passed to this script.
            Example:
            $ScriptPathWithArguments = @{
            Script1 = @{ScriptPath = "<path-for-First-File>\First.ps1"
                    ArgumentList = "","C:\Temp","C:\Temp\first.log"
                   }
            Script2 = @{ScriptPath = "<path-for-Second-File>\Second.ps1"
                    ArgumentList = "","C:\Temp","C:\Temp\second.log"
                   }
            }
        .PARAMETER ExportPath
            Directory to store script output CSV files.
        
        .PARAMETER Credential
            PSCredential object to authenticate into remote computer
    
        .PARAMETER MainLogFile
            Path to the function log.
    
        .PARAMETER OutputFile
            Name of output file which the script creates.
       
        .EXAMPLE                                                                                          
            Invoke-RemoteScript -ScriptPath $ScriptName -ServerList $ServerCsvPath -ExportPath $ExportPath -OutputFile C:\Outfilename.csv  -Verbose
    
        .NOTES
            Author              Date            Version       Comments
            -------------------------------------------------------------------------------------------------
            harish.b.karthic    11/09/2019      1.0.0          Initial Script
    
        #>                                                                                                                                             
        [CmdletBinding()]
        Param
        (
            
            [Parameter(Mandatory = $true)]
            [String]
            [ValidateNotNullOrEmpty()]
            $ServerCsvPath,
    
            [Parameter(Mandatory = $true)]
            [Hashtable] 
            [ValidateNotNullOrEmpty()]
            $ScriptPathArgument,
    
            [Parameter(Mandatory = $true)]
            [String] 
            [ValidateNotNullOrEmpty()]
            $ExportPath,

            [Parameter(Mandatory = $false)]
            [String[]] 
            $OutputFile,
    
            [Parameter(Mandatory = $true)]
            [PSObject]
            $Credential,

            [Parameter(Mandatory = $false)]
            [String]
            $MainLogFile
    
        )
    
        $WorkflowName = "Invoke-RemoteScript"
        $MainLogFile = $MainLogFile + "\Invoke-RemoteScript-Execution_$(Get-Date -Format dd-MM-yyyy).log"
        Write-Verbose -Message "$WorkflowName : Begin Workflow"
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$WorkflowName : Begin Workflow" | Out-File $MainLogFile
   
        $SessionOptions = InlineScript {New-PSSessionOption}
    
        #import list of servers to execute script
        $RemoteComputers = import-csv $ServerCsvPath
    
        try {
            Write-Verbose "$WorkflowName : Number of remote servers: $($RemoteComputers.Count)"
            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$WorkflowName : Number of remote servers: $($RemoteComputers.Count)" | Out-File -Append $MainLogFile
                
    
            #region start remote jobs
            $JobObjList = @{}
            ForEach -parallel -throttlelimit 25 ($Computer in $RemoteComputers) { 
                Sequence { 
                     
                    #region Prepare local variables
                   $StartTime = Get-Date -UFormat %Y/%m/%d_%H:%M:%S

                    if ($Computer.Name -ne $null) {
                        #region String to use the -ComputerName                       
                        $ComputerName = $Computer.Name                   
                        #endregion
    
                        $AzureVmName = $Computer.Name
                        $scripts =  InlineScript {$($using:ScriptPathArgument).GetEnumerator()}
    
    
                        foreach ($script in $scripts.Value)
                        {
                        $ScriptPath = $script.ScriptPath
                        $ArgumentList = $script.ArgumentList
                        $filename1 = Split-Path $ScriptPath -Leaf
                        $filename = [IO.Path]::GetFileNameWithoutExtension($filename1)
                        $JobName1 = "$($ComputerName)_$filename"
                        $Destination = $ArgumentList[1].Replace(":","$")
                        InlineScript {
                            
                            $JobName = $using:JobName1
                            Write-Verbose -Message "$using:WorkflowName : $using:filename : $using:ComputerName :  Invoking the  script with JobName : $JobName"
                            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$using:WorkflowName : $using:filename : $using:ComputerName :  Invoking the  script with JobName : $JobName" | Out-File -Append $using:MainLogFile 
                                
                             Invoke-Command `
                                -ComputerName $using:ComputerName `
                                -FilePath $using:ScriptPath `
                                -Credential $using:Credential `
                                -ArgumentList $using:ArgumentList `
                                -ErrorAction "SilentlyContinue" `
                                -AsJob `
                                -JobName $JobName | Out-Null

                            Get-Job -Name $JobName | Wait-Job -Timeout 120 |out-null 
                            $Result = $null
                            $JobCompleted = (Get-Job -Name $JobName).State
                            Write-Verbose -Message "$using:WorkflowName : $using:filename : $using:ComputerName : Status for Job $JobName : $JobCompleted"
                            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$using:WorkflowName : $using:filename : $using:ComputerName : Status for Job $JobName : $JobCompleted" | Out-File -Append $using:MainLogFile

                            if ($JobCompleted -eq "Failed") {
                                    $ErrorMessage = $error[0].ToString()
                                    Write-Verbose -Message "$using:WorkflowName : $using:filename : $using:ComputerName : Error message for Job $JobName : $ErrorMessage"
                                    "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$using:WorkflowName : $using:filename : $using:ComputerName : Error message for Job $JobName : $ErrorMessage" | Out-File -Append $using:MainLogFile
                            }
                            
                            If ($JobCompleted -ne $null) {
    
                                $resultCSVFilePath = "$using:ExportPath\$using:ComputerName-OSData.csv"
                                #$Destination = ($using:ExportPath).Replace(":","$")
                                #Copy-Item "\\$($using:ComputerName)\$($using:Destination)\$using:ComputerName-OSData.csv" -Destination $using:ExportPath

                                Copy-Item "\\$($using:ComputerName)\$($using:Destination)\$using:ComputerName-OSDetails.csv" -Destination $using:ExportPath

                                #$JobResult | Out-File $resultCSVFilePath
                                $Result = "Success"
                                Write-Verbose -Message "$using:WorkflowName : Result for Job $JobName exported to $resultCSVFilePath"
                                "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$using:WorkflowName : Result for Job $JobName exported to $resultCSVFilePath" | Out-File -Append $using:MainLogFile 
                                
                                }
                            
                            
                             }
    
                        }
                    }             
                   
                }
            }
        
    
        }
        catch {
         
                 Write-Verbose -Message "$using:WorkflowName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
                 "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$using:WorkflowName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $using:MainLogFile  
               }
    
        Write-Verbose "$WorkflowName : End Workflow"
        "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$WorkflowName : End Workflow" | Out-File -Append $MainLogFile
    }
    # End of Workflow

Function Merge-CSVs {
    <#
        .SYNOPSIS
        Merges CSVs.

        .DESCRIPTION
        Merges one or more CSVs with common headers to one master CSV.
        All CSVs to be merged must be within the same folder.
        All CSVs to be merged must have a common naming convention which can be regex matched.

        .PARAMETER InputPath
        The folder path to the CSV files.

        .PARAMETER Pattern
        Regex pattern to match all CSVs to be merged.

        .PARAMETER OutputPath
        The folder to export the merged CSV file. This defaults to InputPath if not provided

        .PARAMETER OutputName
        The name of the resultant file. The file will be date stamped.

        .EXAMPLE
        Merge-CSVs -InputPath "C:\Path\"' -Pattern "*OSData.csv"
        
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$InputPath,

        [Parameter(Mandatory=$true)]
        [String]$Pattern,

        [Parameter(Mandatory=$false)]
        [String]$OutputPath,

        [Parameter(Mandatory=$true)]
        [String]$OutputName
    )

    begin {
        # initialising varaibles
        $CSV = @()
        $CSVPaths = $null
        $InputPath = $InputPath.TrimEnd('\')
        
        if($OutputPath -eq $null) {
            $OutputPath = $InputPath
        } else {
            $OutputPath = $OutputPath.TrimEnd('\')
        }

        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : Begin function."
    }
    process {
        try {
            # creating full path list to these CSVs
            Write-Verbose -Message "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : Discovering CSVs to merge..."
            $CSVPaths = Get-ChildItem -Path $InputPath -Filter $Pattern | Select-Object @{N="Path";E={"$($_.Directory)\$($_.Name)"}}
            Write-Verbose -Message "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : Discovered $($CSVPaths.Count) CSVs."

            # accumulating and merging CSVs to $CSV
            Write-Verbose -Message "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : Merging CSVs..."
            $CSVPaths.Path | % {
                $CSV += @(Import-CSV -Path $_)
            }
            Write-Verbose -Message "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : Merged."

            # exporting merged CSVs as one CSV
            Write-Verbose -Message "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : Exporting merged CSV..."
            $CSV | Export-CSV -Path "$OutputPath\$OutputName-$(Get-Date -f "dd-MM-yyyy").csv" -NoTypeInformation -UseCulture
            Write-Verbose -Message "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : Exported."
        } catch {
            Write-Host "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : Exported." -ForegroundColor Red
        }
    }
    end {
        Write-Verbose -Message "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : End function."
    }
}

#EOF

#Main Script execution
$Credential = Import-Clixml C:\Temp\Mondelez\Store\Credential.xml
$Path = "C:\Temp\Mondelez\Results"
$Pattern = "*OSDetails.csv"

$ScriptPathWithArguments = @{
        Script1 = @{ScriptPath = "C:\Temp\Mondelez\Scripts\Get-WindowsOSDetails.ps1"
                ArgumentList = "","C:\Temp", "C:\Temp"
               }

        }

#Invoke the workflow
Invoke-RemoteScript -ScriptPathArgument $ScriptPathWithArguments `
                    -ServerCsvPath "C:\Temp\Mondelez\Inputs\Input.csv" `
                    -ExportPath "C:\Temp\Mondelez\Results" `
                    -Credential $Credential `
                    -MainLogFile  "C:\Temp\Mondelez\Logs" `
                    -Verbose

#Call merge csvs function
Merge-CSVs -InputPath "C:\Temp\Mondelez\Results" -Pattern $Pattern -OutputPath "C:\Temp\Mondelez\WindowsChecks" -OutputName "WindowsOSChecks" -Verbose



