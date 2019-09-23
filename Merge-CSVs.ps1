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
            $CSV | Export-CSV -Path "$OutputPath\$OutputName-$(Get-Date -f "ddMMyy_hhmm").csv" -NoTypeInformation -UseCulture
            Write-Verbose -Message "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : Exported."
        } catch {
            Write-Host "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : Exported." -ForegroundColor Red
        }
    }
    end {
        Write-Verbose -Message "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)]$functionName : End function."
    }
}
Export-ModuleMember -Function Merge-CSVs