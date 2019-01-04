
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
function Get-PackageVersions
{
    param(
        [Parameter(Mandatory = $true)]
        $packageData
    )
    $packageVersions = $packageData.Versions | foreach-object { $_.Version }
    # format first and last package versions
    $packageVersionBounds = @(
        $packageVersions[0],
        $packageVersions[$packageVersions.length - 1]
    ) | foreach-object {
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
    # compare first and last package versions to determine current order
    $areOrderedByDESC = $packageVersionBounds[0].CompareTo($packageVersionBounds[1]) -gt 0
    # reorder them if necessary
    if ($areOrderedByDESC)
    {
        write-host "##[debug] Reordering versions (ASC)"
        [array]::Reverse($packageVersions)
    }
    return $packageVersions
}

function Resolve-PackageVersion
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$packageName,
        [Parameter(Mandatory = $true)]
        [string]$versionToTarget,
        [Parameter(Mandatory = $true)][Alias("From")]
        [string[]]$packageSearchUrls
    )

    write-host "##[debug] ****** RESOLVE PACKAGE VERSION *********"
    $newVersion = '[NO_VERSION]'
    if ($versionToTarget -eq 'stable') {$prerelease = 'false'} else {$prerelease = 'true'}
    foreach ($packageSearchUrl in $packageSearchUrls)
    {
        $searchQuery = "$packageSearchUrl`?q=$packageName&prerelease=$prerelease"
        write-host "##[debug] Package search query: $searchQuery"
        $searchResults = Invoke-RestMethod -Uri $searchQuery
        if ($searchResults.totalHits -gt 0)
        {
            $packageData = $searchResults.data | Where-Object { $_.id -eq $packageName } ## Filter packageName
            $packageVersions = Get-PackageVersions $packageData                          ## Sort semantic version X.Y.Z.Rev-Prerelease
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

function Test-PackageToResolve
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$packageName,
        [Parameter(Mandatory = $true)][Alias("Include")]
        [string]$includedPackages,
        [Parameter(Mandatory = $true)][Alias("Exclude")]
        [string]$excludedPackages
    )

    $isPackageToResolve = $false

    return $isPackageToResolve
}

# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
Trace-VstsEnteringInvocation $MyInvocation
try
{
    write-host "##[section] ****** SET UP VARIABLES *********"
    $srcDir = $env:BUILD_SOURCESDIRECTORY
    $binDir = $env:BUILD_BINARIESDIRECTORY
    $pathToProjects = Get-VstsInput -Name pathToProjects -Require
    $versionToTarget = Get-VstsInput -Name versionToTarget -Require
    $pathToNugetConfig = Get-VstsInput -Name pathToNugetConfig -Require
    $logVerbosity = Get-VstsInput -Name logVerbosity -Require
    $whitelistedPackageNames = Get-VstsInput -Name whitelistedPackageNames -Require
    $blacklistedPackageNames = Get-VstsInput -Name blacklistedPackageNames -Require
    write-host "srcDir = $srcDir"
    write-host "binDir = $binDir"
    write-host "pathToProjects = $pathToProjects"
    write-host "versionToTarget = $versionToTarget"
    write-host "pathToNugetConfig = $pathToNugetConfig"
    write-host "logVerbosity = $logVerbosity"
    write-host "whitelistedPackageNames = $whitelistedPackageNames"
    write-host "blacklistedPackageNames = $blacklistedPackageNames"

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
            $packageName = $packageRef.Attributes["Include"].Value
            $packageVersion = $packageRef.Attributes["Version"].Value
            $isPackageToResolve = Test-PackageToResolve $packageName -Include $whitelistedPackageNames -Exclude $blacklistedPackageNames
            if ($isPackageToResolve) #$packageVersion -contains '*')
            {
                $packageVersion = Resolve-PackageVersion $packageName $versionToTarget -From $packageSearchUrls
                $packageRef.SetAttribute("Version", $packageVersion)
                $isProjectFileModified = $true
            }
            write-host "Package: $packageName - Version: $packageVersion"
        }

        if ($isProjectFileModified)
        {
            Write-Host "Saving project file: $($projectFile.fullname)"
            $xmlDoc.Save($projectFile.fullname)
            $isProjectFileModified = $false
        }
    }
}
finally
{
    Trace-VstsLeavingInvocation $MyInvocation
}

