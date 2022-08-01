function Invoke-AzureDevOpsPipeline {
    <#
    .SYNOPSIS
        Invoke-AzureDevOpsPipeline helps to run the CI/CD in Azure pipelines.
    .DESCRIPTION
        This script is intented to deploy code once the environment is created. This helps to
        run the CI/CD pipeline in given order and for given environment/stage name.
    .EXAMPLE
        C:\> Invoke-AzureDevOpsPipeline `
            -OrganisationName "Azure DevOps organisation" `
            -ProjectName "Azure DevOps project name" `
            -PersonalAccessToken "Personal Access Token" `
            -CIPipelineName "Deploy-Code-To-WebApp-CI" `
            -BranchName "develop" `
            -CDPipelineName "Deploy-Code-To-WebApp-CD" `
            -EnvironmentName "Prod" `
            -Wait
        This will run the CI pipeline and wait till it is completed and kicks off the CD pipeline for given stage.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganisationName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectName,

        [Parameter(Mandatory, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $PersonalAccessToken,

        [Parameter(Mandatory, Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $CIPipelineName,

        [Parameter(Mandatory, Position = 4)]
        [ValidateNotNullOrEmpty()]
        [string] $BranchName,

        [Parameter(Position = 5)]
        [ValidateNotNullOrEmpty()]
        [string] $CDPipelineName,

        [Parameter(Position = 6)]
        [ValidateNotNullOrEmpty()]
        [string] $EnvironmentName,

        [switch] $CIOnly,

        [switch] $Wait
    )
    begin {
        $functioName = $MyInvocation.MyCommand.Name
        
        Write-Verbose "$functioName : Begin function.."

        if (!$CIOnly.IsPresent -and !$PSBoundParameters.ContainsKey('EnvironmentName')) {
            throw 'Please pass the stage name or environment name to trigger the release pipeline.'
        }

        if (!(Get-Module -Name 'VSTeam' -ListAvailable)) {
            Write-Verbose "$functioName : Installing dependency.."
            Install-Module -Name 'VSTeam' -Scope CurrentUser -Repository PSGallery -AllowClobber -SkipPublisherCheck -Force
        }
    }
    process {
        try {
            Write-Verbose "$functioName : Running pipeline $($CIPipelineName).."

            Set-VSTeamAccount -Account $OrganisationName -PersonalAccessToken $PersonalAccessToken
            Set-VSTeamDefaultProject -Project $ProjectName

            $ci = Add-VSTeamBuild -BuildDefinitionName $CIPipelineName -SourceBranch "refs/heads/$BranchName"

            if ($Wait.IsPresent) {
                while ($ci.InternalObject.status -eq 'notStarted') {
                    $build = Get-VSTeamBuild -Id $ci.Id
                    if (($build.InternalObject.status -eq 'completed') -and ($build.InternalObject.result -eq 'succeeded')) {
                        Write-Verbose "$functioName : Pipeline status $($build.InternalObject.result).."
                        break;
                    }
                    if (($build.InternalObject.status -eq 'completed') -and ($build.InternalObject.result -eq 'failed')) {
                        Write-Verbose "$functioName : Pipeline status $($build.InternalObject.result); Rectify the fault and manually run the pipeline.."
                        break;
                    }
                    else {
                        Write-Verbose "$functioName : Pipeline status $($build.InternalObject.status).."
                        Start-Sleep -Seconds 30
                        continue;
                    }
                }
            }

            else {
                $build = Get-VSTeamBuild -Id $ci.Id
                Write-Verbose "$functioName : Pipeline status $($build.InternalObject.status).."
            }
            
            if (!$CIOnly.IsPresent) {
                Write-Verbose "$functioName : Creating a release for pipeline $($CDPipelineName).."

                $instanceUrl = "$($env:TEAM_ACCT.TrimEnd("/"))/$($env:TEAM_PROJECT)/"

                $definition = Get-VSTeamReleaseDefinition -Expand artifacts | Where-Object { $_.Name -eq $CDPipelineName }

                $release = Add-VSTeamRelease -DefinitionId $definition.Id -ArtifactAlias $definition.Artifacts[0].alias -BuildId $ci.Id

                $instance = "$($instanceUrl.TrimEnd("/"))/_apis/Release/releases/{releaseId}/environments/{environmentId}?api-version=7.1-preview.7"

                $encodedToken = @{
                    Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)"))
                }

                $body = @{
                    status = 'inprogress'
                } | ConvertTo-Json -Depth 10

                Write-Verbose "$functioName : Deploying code.."

                $rel = Get-VSTeamRelease -id $release.Id -expand environments

                $environment = $rel.InternalObject.environments | Where-Object { $_.name -eq $EnvironmentName }

                $instance = $instance.Replace('{releaseId}', $rel.Id).Replace('{environmentId}', $environment.id)

                $result = Invoke-RestMethod -Method Patch -Uri $instance -Body $body -Headers $encodedToken -ContentType "application/json"

                Write-Verbose "$functioName : Release pipeline status $($result.status).."
            }
        }
        catch {
            throw "An error occurred: $($_.Exception.Message) at line number: $($_.InvocationInfo.ScriptLineNumber)"
        }
    }
    end {
        Write-Verbose "$functioName : End function.."
    }
}
