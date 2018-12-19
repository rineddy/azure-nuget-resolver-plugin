
[CmdletBinding()]
param()

# function SetProjectVariable {
#     param(
#         [string]$varName,
#         [string]$varValue
#     )

#     Write-Host ("Setting variable " + $varName + " to '" + $varValue + "'")
#     Write-Output ("##vso[task.setvariable variable=" + $varName + ";]" + $varValue )
# }
function Resolve-PackageVersion
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$packageId,
        [Parameter(Mandatory = $true)]
        [string]$packageSearchUrls
    )

    write-host "##[debug] ****** RESOLVE TARGET VERSION *********"
    $jsonResult = Invoke-RestMethod -Uri "https://api-v2v3search-0.nuget.org/query?q=PackageId:%22$packageId%22&prerelease=true"
    if ($jsonResult.totalHits -gt 0)
    {
        $newVersion = '[NO_VERSION]'
        write-host "##[debug] Search Package Versions for: $packageId"
        ForEach ($v in $jsonResult.data.versions)
        {
            write-host "##[debug] Found Version: $($v.version)"
            $newVersion = $v.version
        }
        return $newVersion
    }
}

function Get-PackageSearchUrlsFromNugetConfig
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$pathToNugetConfig
    )
    $packageSearchUrls = @()

    $nugetConfigFile = Get-ChildItem -Path "$srcDir\$pathToNugetConfig" -Recurse | Select-Object -First 1
    if (!$nugetConfigFile)
    {
        Write-Host "##vso[task.logissue type=warning;]Nuget.Config not found"
    }
    else
    {
        Write-Host "Reading NugetConfig file: $($nugetConfigFile.fullname)"
        $xmlDoc = New-Object -TypeName System.Xml.XmlDocument
        $xmlDoc.Load($nugetConfigFile)
        $xmlPackageSources = $xmlDoc.SelectNodes("/configuration/packageSources/add")
        foreach ($xmlPackageSource in $xmlPackageSources)
        {
            $packageSourceUrl = $xmlPackageSource.Value
            $packageSourceDetails = Invoke-RestMethod -Uri $packageSourceUrl
            if ($packageSourceDetails.resources)
            {
                $resources = $packageSourceDetails.resources | Where-Object { $_.'@type' -like '*SearchQueryService*' }
                foreach ($resource in $resources)
                {
                    "Adding package search Url: $resources"
                    $packageSearchUrls += $resources.'@id'
                }
            }
        }
    }

    return $packageSearchUrls
}


# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
Trace-VstsEnteringInvocation $MyInvocation
try
{
    write-host "##[section] ****** SET UP VARIABLES *********"
    $binDir = $env:BUILD_BINARIESDIRECTORY
    $srcDir = $env:BUILD_SOURCESDIRECTORY
    write-host "srcDir = $srcDir"
    write-host "binDir = $binDir"
    $pathToProjects = Get-VstsInput -Name pathToProjects -Require
    $versionToTarget = Get-VstsInput -Name versionToTarget -Require
    $pathToNugetConfig = Get-VstsInput -Name pathToNugetConfig -Require
    write-host "pathToProjects = $pathToProjects"
    write-host "projectToTarget = $versionToTarget"
    write-host "pathToNugetConfig = $pathToNugetConfig"

    write-host "##[section] ****** FIND PACKAGE SOURCES *********"
    $packageSearchUrls = Get-PackageSearchUrlsFromNugetConfig $pathToNugetConfig

    write-host "##[section] ****** MODIFY PROJECT FILES *********"
    $projectFiles = Get-ChildItem -Path "$srcDir\$pathToProjects" -Recurse
    if ($projectFiles.Count -eq 0) { Write-Host "##vso[task.logissue type=warning;]Project file not found" }

    foreach ($projectFile in $projectFiles)
    {
        Write-Host "Reading project file: $($projectFile.fullname)"
        $xmlDoc = New-Object -TypeName System.Xml.XmlDocument
        $xmlDoc.Load($projectFile)

        $packageRefs = $xmlDoc.GetElementsByTagName("PackageReference")
        if ($packageRefs.legnth -eq 0) { Write-Host "Package not found in $($fileName.name)" }

        foreach ($packageRef in $packageRefs)
        {
            $packageId = $packageRef.Attributes["Include"].Value
            $packageVersion = $packageRef.Attributes["Version"].Value
            if ($packageVersion -eq '*')
            {
                $packageVersion = Resolve-PackageVersion $packageId $packageSearchUrls
                $packageRef.SetAttribute("Version", $packageVersion)
                $isProjectFileModified = $true
            }
            write-host "Package: $packageId - Version: $packageVersion"
        }

        if ($isProjectFileModified)
        {
            Write-Host "Writing project file: $($projectFile.fullname)"
            $xmlDoc.Save($projectFile.fullname)
            $isProjectFileModified = $false
        }
    }
}
finally
{
    Trace-VstsLeavingInvocation $MyInvocation
}

