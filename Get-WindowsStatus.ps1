workflow Get-WindowsStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $InputPath,

        [Parameter(Mandatory = $true)]
        [string] $ExportPath,

        [Parameter(Mandatory = $true)]
        [pscredential] $Credential,

        [int] $HopCount = 2
    )

    # initialize function variables
    $functionName = "Get-WindowsStatus"
    $ExportPath = $ExportPath.TrimEnd("\")
    $tempPath = "$ExportPath\WinStatusFiles"
    
    if (!(Test-Path $tempPath)) { $dir = New-Item -Path $tempPath -ItemType Directory }  

    # assuming that the servers are in text file or in csv without any headers
    $servers = Get-Content -Path $InputPath
    $result = @()
    InlineScript { $sessionOption = New-PSSessionOption }

    Write-Verbose "[$(Get-Date -Format s)] : $functionName : Begin Function.."

    Write-Verbose "[$(Get-Date -Format s)] : $functionName : Getting Windows status information from $($servers.Count) servers.."
    
    foreach -parallel ($server in $servers) {
        if (Test-Connection -ComputerName $server -Count $HopCount -Quiet) {

            Write-Verbose "[$(Get-Date -Format s)] : $functionName : Working with $($server).."

            InlineScript {
                $job = Invoke-Command `
                        -AsJob `
                        -Credential $using:Credential `
                        -SessionOption $using:sessionOption `
                        -ComputerName $using:server `
                        -ScriptBlock { Get-CimInstance SoftwareLicensingProduct| Where-Object { $_.LicenseStatus -eq 1 } | Select-Object Name, Description, LicenseStatus } | Wait-Job

                $windowsStatus = Receive-Job -Id $job.Id

                $windowsStatus | Export-Csv -Path "$($using:tempPath)\$($using:server).csv" -NoTypeInformation -Force
            }
        }
    }

    # merge csv
    Write-Verbose "[$(Get-Date -Format s)] : $functionName : Merging CSVs.."

    $files = Get-ChildItem -Path $tempPath -Filter "*.csv"
    $result = Import-Csv -Path $files.FullName

    $result | Export-Csv -Path "$($ExportPath)\WindowsStatusReport_$(Get-Date -Format ddMMyyyy).csv" -NoTypeInformation -Force

    # cleaning up
    Remove-Item -Path $tempPath -Recurse -Force

    Write-Verbose "[$(Get-Date -Format s)] : $functionName : End Function.." 
}

Get-WindowsStatus -InputPath "C:\TEMP\servers.txt" -ExportPath "C:\TEMP" -Verbose
