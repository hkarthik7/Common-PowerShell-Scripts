Function Save-Credential {

    <#
        .SYNOPSIS
        .Saves the credential in xml file so that it can be automatically imported while running the script.

        .DESCRIPTION
        .This script is intented to run once initially to save the credentials securely in a xml file which can be
        imported while script execution. It is important to note that once the credential is encrypted, only using
        the same account the credential can be decrypted. So it is advised to use a common account to encrypt the 
        credential. eg. service account.

        .PARAMETER Path
        .STRING.Path. Provide the complete path with the name of the credential file to save the credential.

        .PARAMETER Credential
        .PSCredential. Credential. A pop windows appears where the credentials has to be entered. eg. DOMAIN\user1 and password.
    
        .NOTES
        AUTHOR                  DATE          VERSION          COMMENTS
        -------------------------------------------------------------------------------------------------
        harish.b.karthic        18/09/2019    1.0.0            Initial design
    #>
    
    Param(
        [Parameter(Mandatory=$true)]
        [String]$Path,

        [Parameter(Mandatory=$true)]
        [PSCredential]$Credential
    )
       
    #export it to xml file
    $Creds = $Credential | Export-Clixml $Path -Force
    
    return $Creds

}

Save-Credential
