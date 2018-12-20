
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

function Get-SortedSemanticVersions
{
    param(
        [Parameter(Mandatory = $true)]
        $packageDataVersions
    )
    # get first and last package versions
    $formattedVersions = @(
        $packageDataVersions[0].Version,
        $packageDataVersions[$packageDataVersions.length - 1].Version
    )
    # convert them into comparable format
    $formattedVersions = $formattedVersions | foreach-object {
        $parts = $_.Split('-')
        $version = $parts[0]
        if ($parts.length -eq 1) {$prerelease = 'stable'} else {$prerelease = "pre-" + $parts[1]}

        for ($i = ($version.Split('.').Length - 1); $i -lt 4; $i++)
        {
            $version = $version + ".0"
        }
        $version = $version -replace "(\d+)", "00000000`$1"
        $version = $version -replace "\d*(\d{8})", "`$1"
        return "$version $prerelease"
    }
    # compare them to determine the current order
    $areOrderedByDESC = $formattedVersions[0].CompareTo($formattedVersions[1]) -gt 0
    # list all versions and reorder them if necessary
    $versions = $packageDataVersions | foreach-object { $_.Version }
    if ($areOrderedByDESC)
    {
        write-host "##[debug] Reordering versions (ASC)"
        [array]::Reverse($versions)
    }
    return $versions
}

function Resolve-PackageVersion
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$packageId,
        [Parameter(Mandatory = $true)]
        [string]$versionToTarget,
        [Parameter(Mandatory = $true)][Alias("From")]
        [string[]]$packageSearchUrls
    )

    write-host "##[debug] ****** RESOLVE TARGET VERSION *********"
    $newVersion = '[NO_VERSION]'
    if ($versionToTarget -eq 'stable') {$prerelease = 'false'} else {$prerelease = 'true'}
    foreach ($packageSearchUrl in $packageSearchUrls)
    {
        $searchQuery = "$packageSearchUrl`?q=$packageId&prerelease=$prerelease"
        write-host "##[debug] Package search query: $searchQuery"
        $searchResults = Invoke-RestMethod -Uri $searchQuery
        if ($searchResults.totalHits -gt 0)
        {
            $packageData = $searchResults.data |Where-Object { $_.id -eq $packageId } ## Filter packageId
            $packageVersions = Get-SortedSemanticVersions $packageData.versions       ## Sort semantic version X.Y.Z.Rev-Prerelease
            ForEach ($packageVersion in $packageVersions)
            {
                write-host "##[debug] Found Version: $packageVersion"
                $newVersion = $packageVersion
            }
        }
        if ($newVersion -ne '[NO_VERSION]') { break }
    }
    return $newVersion
}

function Get-PackageSearchUrlsFromNugetConfig
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$pathToNugetConfig
    )
    [string[]]$packageSearchUrls = @()

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
                    $packageSearchUrl = $resource.'@id'
                    $packageSearchUrls += $packageSearchUrl
                    Write-Host "Found package search Url: $($packageSearchUrl)"
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
    write-host "versionToTarget = $versionToTarget"
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
                $packageVersion = Resolve-PackageVersion $packageId $versionToTarget -From $packageSearchUrls
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

