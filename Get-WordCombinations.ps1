# function to pick random letters from alphabet library
Function Get-Alphabets($Number){

    $counter = 1
    $Word = ""

    While($counter -le $Number) { 
        $counter = $counter+1
        $Word += Get-Random $AlphabetsLibrary
    }
    return $Word
}

# Find number of possible words combination
Function Find-Combinations($newword) {
    
    $Length = 1..$newword.Length
    $Factorial = 1
    $Length | ForEach-Object {
        $Factorial *= $_
    }
    return $Factorial
}

# Find repeated letters in newly formed word
Function Find-RepeatedLetters($repeatedword) {

    $FinalWord = ""
    $repeatedword = ($repeatedword.ToCharArray() | Group-Object -NoElement).Name

    foreach($letter in $repeatedword) {
        $FinalWord += $letter
    }
    return $FinalWord
}

# Find string permutations
Function Find-StringPermutations($PermutationWord) {
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

            foreach($letter in Find-StringPermutations($RemainingLetters)) {
                $PermWord += $FirstLetter + $letter
            }          
        }
        return $PermWord
    }
}

# region Execute Functions

# Create alphabets library (Global variables)
$Alphabets = [Char[]](97..122)
$AlphabetsLibrary = @()

For($i=0; $i -lt $Alphabets.Count; $i++) {
    $AlphabetsLibrary += $Alphabets[$i]
}

# User input : Get the number of lettrs to be picked
$Number = Read-Host "Enter the number of Alphabets to be picked "

# Pick the random alphabets from alphabets library
$newword = Get-Alphabets -Number $Number

# Find possible number of combinations from picked letters/word
$Combinations = Find-Combinations -newword $newword
Write-Host "Possible number of Combinations from the formed word $($newword) is $($Combinations)" -ForeGroundColor Green

# Find the repeated letters in the formed word and select only unique letters in the word
$FinalWord = Find-RepeatedLetters -repeatedword $newword

# Find all possible combinations of letters in the word
Find-StringPermutations -PermutationWord $FinalWord

# endregion Execute Functions

## Additional Notes
## TODO : Check the combinations against an English dictionary to know the meaning of formed meaningful words