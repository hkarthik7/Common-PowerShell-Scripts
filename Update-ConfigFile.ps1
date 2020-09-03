using namespace System;
using namespace System.IO;
using namespace System.Management.Automation;

function Update-ConfigFile {
    <#
    .SYNOPSIS
        Updates the config file.

    .DESCRIPTION
        This function updates the config file with given string. For instance, if you want to update the name or email in the
        .gitconfig file you can pass the values to be updated in the form or key and value pair.

        Example, name = "Your name"; You can the pass name to $Key paramater and value to be replaced to $Value parameter.
        
        Additionally, there may be scenarios where we want to update only a particular string in the file. In that case
        you can pass the values as said above and specify the special signs like "=", ".", "/" to $ConcatenateWith
        parameter which concatenates your input $Key and $Value with  the $ConcatenateWith parameter and updates the
        config file.
        
        Example, say that your name and email id starts with same name in that case you can use $ConcatenateWith to replace
        only your name = "Your name" without affecting email = "Your name@gmail.com".
    
    .PARAMETER FilePath
        Provide the path of config file.

    .PARAMETER Key
        Provide the value to be updated in config file.

    .PARAMETER Value
        Provide the value to be replaced in the config file.

    .PARAMETER ConcatenateWith
        Provide the seperator in the config file to identify the value as whole string and replace it.
        Example: If your condif file has below settings then "=" should be passed to this parameter.

    .PARAMETER ShowOutput
        If provided 

    .EXAMPLE
        PS C:\> Update-ConfigFile -FilePath "$($env:USERPROFILE)\.gitconfig" -Key "name" -Value "New Name"

        This updates the name in .gitconfig file.
        PS C:\> Update-ConfigFile -FilePath "$($env:USERPROFILE)\.gitconfig" -Key "email" -Value "New.Name@gmail.com" -ConcatenateWith " = " -ShowOutput

        This updates the email in .gitconfig file and shows the updated output.

        Name                           Value
        ----                           -----
        name                           name = New Name
        email                          email = New.Name@gmail.com
        sslVerify                      sslVerify = false
        proxy                          proxy = http://yourproxy:8080

        The config file is expected to be in the format: seperator can be "=" 0r ";" or "," (all allowed values)
        [someheading1]
        key seperator value

        [someheading2]
        key seperator value

        [someheading3]
        key seperator value

    .NOTES
        Author						Version			Date			Notes
        --------------------------------------------------------------------------------------------------------------------
        harish.karthic		        v0.1.0			03/09/2020		Initial script

    .Link
        https://github.com/hkarthik7/Common-PowerShell-Scripts/blob/master/Update-ConfigFile.ps1
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter(
            Mandatory = $true, 
            Position = 0, 
            ValueFromPipeline = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Default")]
        [Parameter(Mandatory = $true, ParameterSetName = "Concatenate")]
        [ValidateNotNullOrEmpty()]
        [string] $FilePath,

        [Parameter(
            Mandatory = $true, 
            Position = 1, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Default")]
        [Parameter(Mandatory = $true, ParameterSetName = "Concatenate")]
        [ValidateNotNullOrEmpty()]
        [string] $Key,

        [Parameter(
            Mandatory = $true, 
            Position = 2, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Default")]
        [Parameter(Mandatory = $true, ParameterSetName = "Concatenate")]
        [ValidateNotNullOrEmpty()]
        [string] $Value,

        [Parameter(Mandatory = $true, ParameterSetName = "Concatenate")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("=", ";", ",")]
        [string] $ConcatenateWith,

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Concatenate")]
        [switch] $ShowOutput
    )
    
    begin {

        Write-Verbose "Begin Function"
        function GetConfigContents ([string] $File) {
            $ConfigPath = Convert-Path $File
            return [File]::ReadAllLines($ConfigPath)
        }
        
        function GetConfigKV ([string] $File,[string] $Seperator = "=", [switch] $Custom) {
     
            $h = [ordered]@{  }
        
            if ($Custom.IsPresent) {
                switch -Regex -File $File  {
                    "^\[(.+)\]$" {
                        $Tag = $Matches[1].Trim()
                    }
                    "(.+)$Seperator(.+)" {
                        if (![string]::IsNullOrWhiteSpace($Tag)) {
                            $k,$v = $Matches[1].Trim(), $Matches[0].Trim()
                            $h[$k] = $v.Trim()
                        }
                    }
                }
            }
        
            else {
                switch -Regex -File $File  {
                    "^\[(.+)\]$" {
                        $Tag = $Matches[1].Trim()
                    }
                    "(.+)$Seperator(.+)" {
                        if (![string]::IsNullOrWhiteSpace($Tag)) {
                            $k,$v = $Matches[1].Trim(), $Matches[2].Trim()
                            $h[$k] = $v.Trim()
                        }
                    }
                }
            }
        
            return $h
        }
        
        function UpdateConfig ([string] $File, [string] $Key, [string] $Value, [switch] $Custom) {

            if ($Custom.IsPresent) {
                $ConfigKV = GetConfigKV $File -Custom
            } else {
                $ConfigKV = GetConfigKV $File
            }
            
            $ConfigContents = GetConfigContents $File
        
            if ($ConfigKV.Keys -ccontains $Key) {
                $ConfigContents -replace ($ConfigKV[$Key]), $Value | Set-Content $File
            }
        }        
    }
    
    process {
        try {

            Write-Verbose "Updating config file"

            if ($PSCmdlet.ParameterSetName -eq "Default") {
            
                if (![File]::Exists($FilePath)) {
                    Write-Error `
                        -Exception ItemNotFoundException `
                        -Message "Can't find file $FilePath" `
                        -ErrorId "PathNotFound,ConfigFile\Update-ConfigFile" `
                        -Category "ObjectNotFound"
                }

                else {
                    $ConfigKV = GetConfigKV $FilePath

                    if ($ConfigKV.Keys -notcontains $Key) {
                        Write-Error `
                        -Exception ArgumentExceptionn `
                        -Message  "Could not find '$($Key)' in given config file '$($FilePath)'" `
                        -ErrorId "InvalidKeyType,ConfigFile\Update-ConfigFile" `
                        -Category "InvalidArgument"
                    }

                    else {
                        UpdateConfig -File $FilePath -Key $Key -Value $Value

                        if ($ShowOutput.IsPresent) {
                            GetConfigKV $FilePath
                        }
                    }                
                }
            }
            
            elseif ($PSCmdlet.ParameterSetName -eq "Concatenate") {
            
                if (![File]::Exists($FilePath)) {
                    Write-Error `
                        -Exception ItemNotFoundException `
                        -Message "Can't find file $FilePath" `
                        -ErrorId "PathNotFound,ConfigFile\Update-ConfigFile" `
                        -Category "ObjectNotFound"
                }

                else {
                    $ConfigKV = GetConfigKV $FilePath -Custom
                    $ValueToReplace = [string]::Join($ConcatenateWith, $Key, $Value)

                    if ($ConfigKV.Keys -notcontains $Key) {
                        Write-Error `
                        -Exception ArgumentExceptionn `
                        -Message  "Could not find '$($Key)' in given config file '$($FilePath)'" `
                        -ErrorId "InvalidKeyType,ConfigFile\Update-ConfigFile" `
                        -Category "InvalidArgument"
                    }

                    else {
                        UpdateConfig -File $FilePath -Key $Key -Value $ValueToReplace -Custom

                        if ($ShowOutput.IsPresent) {
                            GetConfigKV $FilePath -Custom
                        }
                    }                
                }
            }
        }
        catch {
            throw "Error at line $($_.InvocationInfo.ScriptLineNumber) : $($_.Exception.Message)."
        }
    }
    
    end {
        Write-Verbose "End Function"
    }
}
# EOF