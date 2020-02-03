function Export-SqlDB {
    <#
    .SYNOPSIS
    This script exports database for the given subscription and place it in a blob storage.

    .DESCRIPTION
    This script is designed to export the database from the given subscription. It expects
    mandatory parameters to be passed to work with.

    .PARAMETER ResourceGroup
    Provide the resource group name.

    .PARAMETER StorageAccountName
    Provide the storage account name to place the exported database bacpac file.

    .PARAMETER StorageContainerName
    Provide the storage container name to select save the backup file.

    .PARAMETER SqlServerNames
    Provide the sql servers for which databases has to be exported.
    
    .PARAMETER AzureKeyVaultName
    Provide the Azure key vault name.

    .EXAMPLE
    Export-SqlDB `
                -ResourceGroup "ResourceGroupName" `
                -StorageAccountName "StorageAccountName" `
                -StorageContainerName "ContainerName" `
                -SqlServerNames ("SqlServer01","Sqlserver02") `
                -AzureKeyVaultName "AzureKeyValult01" `
                -Verbose

    .NOTES
    Author             Version		 Date			Notes
    ------------------------------------------------------------------------------------
    harish.karthic     1.0	        29/01/2020		Initial script
    harish.karthic     1.1	        30/01/2020		Minor tweak and adjusted 
                                                    the script to run in Azure Devops
    harish.karthic     1.2	        31/01/2020		Removed Credentials parameter and made
                                                    it to automatically retrieve the username
                                                    and password details from Azure key vault.

    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$ResourceGroup,

        [Parameter(Mandatory = $true)]
        [String]$StorageAccountName,

        [Parameter(Mandatory = $true)]
        [String]$StorageContainerName,

        [Parameter(Mandatory = $true)]
        [String[]]$SqlServerNames,

        [Parameter(Mandatory = $true)]
        [String]$AzureKeyVaultName
    )

    begin {
        # initialize function variables
        $functionName = $MyInvocation.MyCommand.Name
        $ContainerDetails = @()
        $sqlDB = @()

        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Begin function"
        Write-Verbose $Message
    }

    process {

        try {
            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Gathering storage account details for $($ResourceGroup)"
            Write-Verbose $Message

            #region gather storage account details

            $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName
            $StorageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccountName
            $StorageAccountContainer = Get-AzStorageContainer -Context $StorageAccount.Context -Name $StorageContainerName
            $Details = [PSCustomObject]@{
                ContainerName = $StorageAccountContainer.Name
                BlobUri       = $StorageAccountContainer.CloudBlobContainer.Uri.AbsoluteUri
            }
            $ContainerDetails += $Details

            #endregion gather storage account details

            #region fetch username and password from keyvault

            $kv = Get-AzKeyVault -VaultName $AzureKeyVaultName
            $VaultSecretUserName = $kv.VaultName.Split("-")[0] + "Sql01adminUsername"
            $VaultSecretPassword = $kv.VaultName.Split("-")[0] + "Sql01adminPassword"
            $Username = Get-AzKeyVaultSecret -VaultName $AzureKeyVaultName -Name $VaultSecretUserName
            $Password = Get-AzKeyVaultSecret -VaultName $AzureKeyVaultName -Name $VaultSecretPassword

            $Credentials = @{
                username = $Username.SecretValueText
                password = $Password.SecretValue
            }

            #endregion fetch username and password from keyvault

            #region start DB export

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Gathering DataBase details for the servers"
            Write-Verbose $Message

            foreach ($SqlServer in $SqlServerNames) {
                $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Working with $($SqlServer)"
                Write-Verbose $Message

                $sqlServers = Get-AzSqlServer -ResourceGroupName $ResourceGroup -ServerName $SqlServer
                foreach ($sqlServer in $sqlServers) {
                    $sqlDB += Get-AzSqlDatabase -ServerName $sqlServer.ServerName -ResourceGroupName $sqlServer.ResourceGroupName
                }               
            }

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Gathered DataBase details for the servers"
            Write-Verbose $Message

            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Starting DataBase export"
            Write-Verbose $Message

            foreach ($DB in $sqlDB) {

                if ($DB.DatabaseName -ne "master") {
                    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Working with $($DB.DatabaseName)"
                    Write-Verbose $Message

                    $Splat = @{
                        DatabaseName = $DB.DatabaseName
                        ServerName = $DB.ServerName
                        StorageKeyType = "StorageAccessKey"
                        StorageKey = $StorageAccountKeys.Value[0]
                        StorageUri = $ContainerDetails.BlobUri
                        ResourceGroupName = $DB.ResourceGroupName
                        AdministratorLogin = $Credentials.username
                        AdministratorLoginPassword = $Credentials.password
                    }

                    $sqlExport = New-AzSqlDatabaseExport @Splat
                    $ExportStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $sqlExport.OperationStatusLink
                    
                    $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Export Status for $($DB.DatabaseName) : $($ExportStatus.Status)"
                    Write-Verbose $Message
                } 
            }
            
            $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Done with DataBase Export"
            Write-Verbose $Message

            #end region start DB export
        }
        catch {
            Write-Host " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
            " [$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : Error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" | Out-File $LogFile -Append
        }
    }

    end {
        $Message = "[$(Get-Date -UFormat %Y/%m/%d_%H:%M:%S)] $functionName : End Function"
        Write-Verbose $Message
    }
}
#EOF

# initialise script variables
$Params = @{
    ResourceGroup = "Dev-Env-RSG"
    StorageAccountName = "sqltestaccount01"
    StorageContainerName = "sqltestcontainer"
    SqlServerNames = "wtestsql01"
    AzureKeyVaultName = "s102d01-kv-01"
    Verbose = $true
}
# Execute function
Export-SqlDB @Params
