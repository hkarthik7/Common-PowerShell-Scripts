Function Convert-WordToOdt {
    <#
        .SYNOPSIS
        This script converts word document to open document text.

        .DESCRIPTION
        This script converts the word documents in given path and to open document text files.
        Provide the path where .docx or .doc is placed and the script converts it to .odt
        without missing the text.

        .PARAMETER FilePath
        Provide the path where the word documents are saved.

        .PARAMETER Pattern
        Provide the pattern such as .docx or doc to convert to .odt

        .PARAMETER LogPath
        Provide the path to save the logfile

        .EXAMPLE
        Convert-WordToOdt -FilePath "C:\Temp" -Pattern ".docx" -LogPath "C:\Temp" -Verbose

        .NOTES
        Author						Version			Date			Notes
        --------------------------------------------------------------------------------------------------------------------
        harish.karthic		    v1.0			09/12/2019		Initial script
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$FilePath,

        [Parameter(Mandatory=$true)]
        [String]$Pattern,

        [Parameter(Mandatory=$true)]
        [String]$LogPath    
    )

    begin {
        $functionName = $MyInvocation.MyCommand.Name
        $LogFile = $LogPath + "\Convert-WordToOdt_$(Get-Date -Format dd-MM-yyyy).log"

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }

    process {
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Converting files in given path $($FilePath)"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        $Files = Get-ChildItem -Path $FilePath -Filter "*$pattern" | Select-Object Name, FullName

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : $($Files.Count) files found in $($FilePath) to convert"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        foreach($file in $Files) {

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Working with $($file.Name)"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            try {
                $Word = New-Object -ComObject Word.Application
                $OpenDoc = $Word.Documents.Open($file.FullName)
                $OpenDoc.SaveAs(($file.FullName).Replace(".docx",".odt"),[ref][Microsoft.Office.Interop.Word.WdSaveFormat]::wdFormatOpenDocumentText) | Out-Null
                $OpenDoc.Close()
                $Word.Quit()
            }
            Catch {
                Write-Verbose " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message).."
                "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File -Append $LogFile
            }
        }

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Converted all the files in path $($FilePath)"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }

    end {
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End Function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }
}