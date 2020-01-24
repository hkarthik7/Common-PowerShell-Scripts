<#
    Defining main class [StringManager]:
    
    // Using Classes to develop the word combinations :: NOTES ::
        What is a class? - A Class is a blueprint which is used to create the instance of an object at run time.
        That is, when a class is instantiated the object is the instance of your class with certain properties
        and methods.
        Why classes? - There are many advantages of using classes in the script. The main advantage of using classes
        is code reuse-ability and redundancy. All the instances can be encapsulated in a single class and the main
        advantage is that formatting output.

    // Use Case ::
        The StringManager class gives the flexibility of picking the random alphabets from alphabet library
        and it actually forms all possible words with it. And finally it finds the synonyms for the words formed
        which are meaningful and return as an object. 
        Now, the result can be formatted to various outputs for better visualisation.

    // Class Functionality ::
        StringManager class have multiple functionalities. They are - 
            1. Pick alphabets for given number/s randomly and forms a word from the randomly picked alphabets
                E.g. "abc"
            2. Find the factorial of formed word. Plainly, it can give the number of possible combinations
            that can be formed from the formed word.
                E.g. Possible combinations that can be made from "abc" is 6. 
            3. Remove the repeated letters in the word.
                E.g. "aabbc" Will be formatted to "abc"
            4. Find the word combinations or permutations for the word.
                E.g. for "abc" the word combinations are ( "abc","acb","bac","bca","cab","cba")
            5. Find the synonyms for meaningful word.
                E.g. Synonym for "cab" is taxi.

    // Notes ::
        Author : B Harish Karthic
        Date : 03/01/2020
        Version : v1.1
        Comments : Initial Script

    // Examples ::
        Instantiating the class -
        E.g. Instantiating a new class without passing arguments -
        $MyString = [StringManager]::new()

        Instantiating a new class by passing one argument -
        $MyString = [StringManager]::new(3)
        
        Instantiating a new class by passing two arguments -
        $MyString = [StringManager]::new(3,"Fun")

        Getting random alphabets from alphabets library
        $Word = $MyString.GetRandomAlphabets(3)

        Assigning the property to get random alphabets
        $Word = $MyString.GetRandomAlphabets($MyString.Number)
        
        Getting number of combinations that can be made from the word
        $MyString.GetFactorial($Word.Length)

        Removing repeated letters from the word
        $MyString.RemoveDuplicateLetters($Word)

        Generating all possible permutations of the word
        $Permutations = $MyString.GetPermutations($Word)

        Getting synonyms for generated permutations
        $MyString.GetSynonyms($Word)
#>

## Defining main class StringManager
Class StringManager {

    ## Defining Properties
    [int]$Number = 0
    [string]$String = "StringManager"

    ## hidden property
    hidden [array]$AlphabetsLibrary = @(for($i=0;$i -lt ([Char[]](97..122)).Count;$i++) { ([Char[]](97..122))[$i] })

    ## Constructors
    StringManager() {
        ## pass
    }

    StringManager([int]$Number) {
        $this.Number = $Number
    }

    StringManager([int]$Number,[string]$String) {
        $this.Number = $Number
        $this.String = $String
    }

    ## getting factorial of given number
    [bigint] GetFactorial([bigint]$number) {

        if($number -le 1) {
            return $number
        }
        else {
            return $number * $this.GetFactorial($number-1)           
        }        
    }

    ## getting random letters from AlphabetsLibrary
    [String] GetRandomAlphabets([int]$Number) {

        if($Number -lt 1) {
            return ""
        }
        else {
            $counter = 1
            $Word = ""

            While($counter -le $Number) { 
                $counter = $counter+1
                $Word += Get-Random $this.AlphabetsLibrary
            }
            return $Word
        }
    }

    ## removing repeated letters in the string
    [string] RemoveDuplicateLetters([string]$Word) {

        if(-not $PSBoundParameters.ContainsKey("Word")) {
            return ""
        }
        else {
            $FinalWord = ""
            $Word = ($Word.ToCharArray() | Group-Object -NoElement).Name

            foreach($letter in $Word) {
                $FinalWord += $letter
            }
            $FinalWord = $FinalWord -replace " ",""
            return $FinalWord
        }
    }

    ## finding string permutations
    [array] GetPermutations([string]$PermutationWord) {

        if ($PermutationWord.Length -eq 0) {
            return ""
        }
    
        elseif ($PermutationWord.Length -eq 1) {
            return $PermutationWord
        }
    
        else {
            $PermWord = @()
            $counter = $PermutationWord.Length
        
            for($i=0;$i -lt $PermutationWord.Length;$i++) {
                $FirstLetter = $PermutationWord[$i]
                $RemainingLetters = $PermutationWord.Substring(0,$i) + $PermutationWord.Substring(($i+1),($counter-1))
                $counter -= 1
    
                foreach($letter in $this.GetPermutations($RemainingLetters)) {
                    $PermWord += $FirstLetter + $letter
                }          
            }
            return $PermWord
        }
    }

    ## finding synonyms of the word/s
    [array] GetSynonyms([String[]]$Words) {
        
        $result = @()
        $Uri = "https://www.synonym.com/synonyms"

        foreach($Word in $Words) {

            try {
                $WebRequest = Invoke-WebRequest -Uri "$($Uri)/$($Word)" -UseBasicParsing
        
                $startingIndex = $WebRequest.Content.IndexOf("synonyms:")
                $endingIndex = $WebRequest.Content.IndexOf("| ")
                $synonym = $WebRequest.Content.Substring($startingIndex,$endingIndex)
                $antonym = $synonym.IndexOf("antonyms")
                $synonyms_new = $synonym.Substring(0,$antonym) -split "," -replace "|",""
                $Synonyms = foreach($item in $synonyms_new) { if($item.Contains("|")) { $item.Replace("|","") } }
                $Hash = [PSCustomObject]@{
                    "Words" = $Word
                    "Synonyms" = $Synonyms
                }
                $result += $Hash
            }
            catch {
                $Hash = [PSCustomObject]@{
                    "Words" = $Word
                    "Synonyms" = "No synonym for the word!"
                }
                $result += $Hash
            }
        }
        return $result
    }

}