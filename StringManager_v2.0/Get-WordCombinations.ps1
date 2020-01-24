Function Get-WordCombinations {

    <#
        .SYNOPSIS
        This function helps to find string permutations and it's synonyms.

        .DESCRIPTION
        This script is designed to work with String Manager class which ideally
        provides the functionalities of picking alphabets randomly and form a word
        with that, finding the factorial(or number of possible combinations that
        can be made with the word.), string permutations and synonyms for the
        formed words.

        This script is intended to get input from user to choose the number of
        alphabets to pick from alphabets library, find it's permutations and
        retrieve synonyms for the formed words.

        .PARAMETER Number
        Provide the number to pick up alphabets randomly.

        .PARAMETER LogPath
        Provide the path to save log files.

        .EXAMPLE
        Get-WordCombinations -Number 3 -LogPath "C:\TEMP" -Verbose

        .EXAMPLE
        Get-WordCombinations -Number 3 -LogPath "C:\TEMP"

        .EXAMPLE
        Get-WordCombinations -Number 3

        .EXAMPLE
        Get-WordCombinations

        .NOTES
        Author                      Version         Date            Notes
        --------------------------------------------------------------------------------------------------------------------
        harish.b.karthic            v1.0            02/01/2020      Initial script

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [int]$Number,

        [Parameter(Mandatory=$false)]
        [string]$LogPath
    )

    begin {
        # initialise function variables
        $functionName = $MyInvocation.MyCommand.Name       

        if (-not $PSBoundParameters.ContainsKey("Number")) {
            $Number = Read-Host "Enter the number to select alphabets from alphabets library "
        }
        if (-not $PSBoundParameters.ContainsKey("LogPath")) {
            $LogFile = $env:TEMP + "\GetWordCombinations_$(Get-Date -Format ddMMyyyy).log"
        }
        else {
            $LogFile = $LogPath + "\GetWordCombinations_$(Get-Date -Format ddMMyyyy).log"
        }

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile
    }

    process {       

        try {
            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Trying to process the given number $($Number)"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile
            
            # Instantiating the class
            $StringManagerClass = [StringManager]::new($Number)

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Picking random alphabets"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            # Picking random alphabets
            $Word = $StringManagerClass.GetRandomAlphabets($StringManagerClass.Number)

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Picked [ $($Word) ] from library"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Getting number of possible combinations from [ $($Word) ]"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            # Getting number of combinations from the picked word
            $Factorial = $StringManagerClass.GetFactorial($Word.Length)

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : [ $($Factorial) ] combinations can be formed from the word [ $($Word) ]"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Removing duplicate alphabets if any in [ $($Word) ]"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            # Removing duplicate letter from word
            $repeatedword = $StringManagerClass.RemoveDuplicateLetters($Word)

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Finding all possible combinations from picked word [ $($Word) ]"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            # Generating all possible permutations of the word
            $Permutations = $StringManagerClass.GetPermutations($repeatedword)

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : String Permutations formed are : [ $($Permutations -Join ",") ]"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Getting synonyms for meaningful words"
            Write-Verbose $Message ; $Message | Out-File -Append $LogFile

            # Getting synonyms for generated permutations
            $Synonyms = $StringManagerClass.GetSynonyms($Permutations)
        }
        catch {
            Write-Verbose " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : $($_.Exception.Message).."
            "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : $($_.Exception.Message)" | Out-File -Append $LogFile
        }
    }

    end { 
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End function"
        Write-Verbose $Message ; $Message | Out-File -Append $LogFile

        return $Synonyms
    }

}
Export-ModuleMember -Function Get-WordCombinations