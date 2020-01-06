## Processing all modules
Get-ChildItem -Path "$($PSScriptRoot)\*.ps1" | % {.$_.FullName}

##Importing string manager class to work with
[ScriptBlock]::Create('Using Module StringManager')