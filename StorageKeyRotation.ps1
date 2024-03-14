# Function to extract all storage account details
function Export-StorageAccountDetail {
    [CmdletBinding()]
    param ( )
    
    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$(Get-Date -Format s)] : $functionName : Begin Function.."
    }
    
    process {
        try {
            Write-Verbose "[$(Get-Date -Format s)] : $functionName : Retrieving storage account details.."

            $storageAccounts = Get-AzStorageAccount

            $results = @()

            $storageAccounts | ForEach-Object {
                Write-Verbose "[$(Get-Date -Format s)] : $functionName : Working with $($_.StorageAccountName).."

                $results += [PSCustomObject]@{
                    ResourceGroupName  = $_.ResourceGroupName
                    StorageAccountName = $_.StorageAccountName
                    KeyVaultName       = $null
                    KeyVaultSecretName = $null
                    KeyName            = "key2"
                    ExpiryInMonth      = 3
                }
            }

            Write-Verbose "[$(Get-Date -Format s)] : $functionName : Exporting results.."

            $results | Export-Csv -Path "$($PWD.Path)\StorageKeyRotation.csv" -NoTypeInformation -Force
            
        }
        catch {
            throw "An error occurred: $($_.Exception.Message) at line number $($_.InvocationInfo.ScriptLineNumber)."
        }
    }
    
    end {
        Write-Verbose "[$(Get-Date -Format s)] : $functionName : End Function.."
    }
}

Export-StorageAccountDetail -Verbose


# Function to rotate storage keys.
# This rotates the storage keys for give storage accounts and updates the keys in keyvault.
function Invoke-StorageKeyRotation {
    [CmdletBinding()]
    param ( )
    
    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$(Get-Date -Format s)] : $functionName : Begin Function.."
    }
    
    process {
        try {
            Write-Verbose "[$(Get-Date -Format s)] : $functionName : Retrieving storage account details from source file.."

            $sourceFile = Get-ChildItem -Filter 'StorageKeyRotation.csv' -Recurse | Select-Object -ExpandProperty FullName

            $source = Import-Csv -Path $sourceFile
            
            foreach ($sa in $source) {
                if (![string]::IsNullOrEmpty($sa.KeyVaultName) -and ![string]::IsNullOrEmpty($sa.KeyVaultSecretName)) {
                    Write-Verbose "[$(Get-Date -Format s)] : $functionName : Working with storage account $($sa.StorageAccountName).."

                    $storageAccount = Get-AzStorageAccount -ResourceGroupName $sa.ResourceGroupName -Name $sa.StorageAccountName

                    Write-Verbose "[$(Get-Date -Format s)] : $functionName : Initiating key rotation.."
                    
                    $null = New-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName -KeyName $sa.KeyName

                    Write-Verbose "[$(Get-Date -Format s)] : $functionName : Key rotation successfully completed.."
            
                    $storageAccountKey = Get-AzStorageAccountKey -ResourceGroupName $sa.ResourceGroupName -Name $sa.StorageAccountName `
                    | Where-Object { $_.KeyName -eq $sa.KeyName } `
                    | Select-Object -ExpandProperty Value

                        
                        
                    Write-Verbose "[$(Get-Date -Format s)] : $functionName : Updating key vault with the new storage key - { ExpiryInMonths: $($sa.ExpiryInMonth) }.."
                        
                    $null = Set-AzKeyVaultSecret `
                        -VaultName $sa.KeyVaultName `
                        -Name $sa.KeyVaultSecretName `
                        -SecretValue ($storageAccountKey | ConvertTo-SecureString -AsPlainText -Force) `
                        -Expires (Get-Date).AddMonths($sa.ExpiryInMonth)
                        
                    Write-Verbose "[$(Get-Date -Format s)] : $functionName : Successfully set the secret value in keyvault.."

                    Write-Verbose "[$(Get-Date -Format s)] : $functionName : Disabling old keys.."

                    $existingSecrets = Get-AzKeyVaultSecret -VaultName $sa.KeyVaultName -Name $sa.KeyVaultSecretName -IncludeVersions
                    
                    $existingSecrets | ForEach-Object {
                        if (((Get-Date).Date -ne (Get-Date $_.Created).Date)) {
                            Write-Verbose "[$(Get-Date -Format s)] : $functionName : Disabling key for $($_.VaultName).."

                            $secret = Get-AzKeyVaultSecret -VaultName $_.VaultName -Name $_.Name -Version $_.Version
                            $null = Set-AzKeyVaultSecret -VaultName $secret.VaultName -Name $secret.Name -SecretValue $secret.SecretValue -Disable
                        }
                    }

                    Write-Verbose "[$(Get-Date -Format s)] : $functionName : Successfully disabled old keys.."
                }
            }
        }
        catch {
            throw "An error occurred: $($_.Exception.Message) at line number $($_.InvocationInfo.ScriptLineNumber)."
        }
    }
    
    end {
        Write-Verbose "[$(Get-Date -Format s)] : $functionName : End Function.."
    }
}

Invoke-StorageKeyRotation -Verbose

function Update-KeyVaultReference {
    [CmdletBinding()]
    param ( )
    
    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$(Get-Date -Format s)] : $functionName : Begin Function.."
    }
    
    process {
        try {
            Write-Verbose "[$(Get-Date -Format s)] : $functionName : Determining webapps in the environment.."

            $webApps = Get-AzWebApp

            Write-Verbose "[$(Get-Date -Format s)] : $functionName : Found $($webApps.Count) webapps.."

            Write-Verbose "[$(Get-Date -Format s)] : $functionName : Retrieving keyvault details from source file.."

            $sourceFile = Get-ChildItem -Filter 'StorageKeyRotation.csv' -Recurse | Select-Object -ExpandProperty FullName

            $source = Import-Csv -Path $sourceFile

            foreach ($webApp in $webApps) {
                Write-Verbose "[$(Get-Date -Format s)] : $functionName : Working with $($webApp.Name).."

                $app = Get-AzWebApp -ResourceGroupName $webApp.ResourceGroup -Name $webApp.Name

                foreach ($sa in $source) {
                    if ($app.SiteConfig.AppSettings | Where-Object { $_.Value -match $sa.KeyVaultSecretName }) {
                        Write-Verbose "[$(Get-Date -Format s)] : $functionName : Updating keyvault reference.."

                        $secret = Get-AzKeyVaultSecret -VaultName $_.VaultName -Name $_.Name -IncludeVersions | Where-Object { $_.Enabled -and ($_.Expires -gt (Get-Date)) }
                        
                        ($app.SiteConfig.AppSettings | Where-Object { $_.Value -match $sa.KeyVaultSecretName }).Value = "@Microsoft.KeyVault(SecretUri=$($secret.Id))"

                        $null = $app | Set-AzWebApp

                        Write-Verbose "[$(Get-Date -Format s)] : $functionName : Successfully updated keyvault reference.."
                    }
                }
            }
        }
        catch {
            throw "An error occurred: $($_.Exception.Message) at line number $($_.InvocationInfo.ScriptLineNumber)."
        }
    }
    
    end {
        Write-Verbose "[$(Get-Date -Format s)] : $functionName : End Function.."
    }
}

Update-KeyVaultReference -Verbose