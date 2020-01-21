<#
    .NOTE
    This is an example script to import Start-ProgramInElevatedMode.psm1 script.
    The right way to do it is to place Start-ProgramInElevatedMode.psm1 in 
    C:\Users\<username>\Documents\WindowsPowerShell\Modules\Start-ProgramInElevatedMode.psm1
    and import it in the powershell window and run it.

    This example script is designed to be interactive and user friendly.
    Just right click and select run with powershell option or navigate to the path in
    powershell console where this script is placed and run it.
#>

$ModulePath = Read-Host "Enter the complete path of Start-ProgramInElevatedMode.psm1 with script name "
$ProgramToRun = Read-Host "Enter the name of program to open in elevated mode. E.g. powershell.exe/cmd.exe "
$LogPath = Read-Host "Enter the Log Path to save log file "

# Importing module
Import-Module $ModulePath

Start-ProgramInElevatedMode -Program $ProgramToRun -LogPath $LogPath -Verbose