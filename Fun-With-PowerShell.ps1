$WelcomeBanner = "

////////////////////////////////////////////////////////////////////////
/                                                                      /
/    WELCOME TO THIS SIMPLE ADDITION GAME!!                            /
/                                                                      /
/    --> IN THIS PROGRAM POWERSHELL IS GOING TO PREDECT THE RESULT OF  /
/        SERIES OF ADDITION THAT WE ARE GOING TO PERFORM               /
/                                                                      /
/    --> RULES                                                         /
/        1. ENTER ANY DIGITS OF NUMBERS                                /
/        2. STRICTLY NO NEGATIVE NUMBERS                               /
/                                                                      /
/                                                                      /
////////////////////////////////////////////////////////////////////////

"

Function Write-Message($Message, $Colour) {
    If ($Colour) {
        Write-Host $Message -ForegroundColor $Colour
    }
    else {
        Write-Host $Message
    }
}

Function Interval($Seconds) {
    Start-Sleep -Seconds $Seconds
}

Function Final-Output {
    # clear host
    Clear-Host

    # Write welcome message
    Write-Message -Message $WelcomeBanner -Colour Yellow

    # interval
    Interval -Seconds 3

    # Get first input
    [int]$FirstNumber = Read-Host "   Enter First Number"
    
    # Key variable
    [int]$Key = "9" * $FirstNumber.ToString().Length

    # Predict the result
    $ExpectedResult = "2" + $FirstNumber - 2

    Write-Message -Message "   Now PowerShell is going to predict the result of this addition.." -Colour Cyan

    $Layout = "
    ///////////////////////////////////////////////////
    /
    /   The predicted result is : $($ExpectedResult)
    /
    ///////////////////////////////////////////////////
    "
    Write-Message -Message $Layout -Colour Cyan

    # Get Second number
    [int]$SecondNumber = Read-Host "   Enter Second Number"

    # Message
    Write-Message -Message "   PowerShell is going to enter the consecutive number.."

    # interval
    Interval -Seconds 1

    # Enter Third number
    [int]$ThirdNumber = $Key - $SecondNumber
    Write-Message -Message "   Third Number : $($ThirdNumber)" -Colour Green

    # Get Fourth Number
    [int]$FourthNumber = Read-Host "   Enter Fourth Number"

    # Message
    Write-Message -Message "   PowerShell is going to enter the consecutive number.."

    # interval
    Interval -Seconds 1

    # Enter Fifth Number
    [int]$FifthNumber = $Key - $FourthNumber
    Write-Message -Message "   Fifth Number : $($FifthNumber)" -Colour Green

    # interval
    Interval -Seconds 1

    # Calculation Steps
    $Steps = "
    CALCULATION STEPS --> WATCH HERE -->
    1. ADDING FIRST AND SECOND NUMBER RESULTS IN --> $([int]$FirstNumber + [int]$SecondNumber)
    2. ADDING FIRST,SECOND AND THIRD NUMBER RESULTS IN --> $([int]$FirstNumber + [int]$SecondNumber +[int] $ThirdNumber)
    3. ADDING FIRST,SECOND,THIRD AND FOURTH NUMBER RESULTS IN --> $([int]$FirstNumber + [int]$SecondNumber + [int]$ThirdNumber + [int]$FourthNumber)
    4. ADDING ALL NUMBERS RESULTS IN --> $([int]$FirstNumber + [int]$SecondNumber + [int]$ThirdNumber + [int]$FourthNumber + [int]$FifthNumber)
    "

    # Final Result
    $Result = [int]$FirstNumber + [int]$SecondNumber + [int]$ThirdNumber + [int]$FourthNumber + [int]$FifthNumber

    # Write the calculation steps
    Write-Message -Message $Steps -Colour Cyan

    # interval
    Interval -Seconds 3

    # Print the result
    $ResultMessage = "
    /////////////////////////////////
    /                               
    /  The result is : $($Result)
    /                               
    /////////////////////////////////
    "
    Write-Message -Message $ResultMessage -Colour Green
}

# Function Execution
Final-Output

# Try again
$Tryagain = ''

While ($Tryagain -ne 'y' -or 'n') {

    Write-Message -Message "   Want to try again?"
    $Gameon = Read-Host "   Enter y/n"

    If ($Gameon -eq 'y') {
        Final-Output
    }
    else {
        Write-Message -Message "Thanks For Playing" -Colour Green
        exit 0
    }

}