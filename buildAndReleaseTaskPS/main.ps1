
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

# For more information on the VSTS Task SDK:
# https://github.com/Microsoft/vsts-task-lib
Trace-VstsEnteringInvocation $MyInvocation
try
{
    write-host "****** ENV *********"
    $binDir = $env:BUILD_BINARIESDIRECTORY
    $srcDir = $env:BUILD_SOURCESDIRECTORY
    write-host "srcDir = $srcDir"
    write-host "binDir = $binDir"

    write-host "****** VARIABLES *********"
    $searchProjectFile = Get-VstsInput -Name searchProjectFile -Require
    $versionToTarget = Get-VstsInput -Name versionToTarget -Require
    write-host "searchProjectFile = $searchProjectFile"
    write-host "projectToTarget = $versionToTarget"

    write-host "****** SEARCH PROJECT *********"
    $filesFound = Get-ChildItem -Path $searchProjectFile -Recurse
    if ($filesFound.Count -eq 0) { Write-Warning "No files matching pattern found." }
    if ($filesFound.Count -gt 1) { Write-Warning "Multiple proj files found."       }

    foreach ($fileName in $filesFound)
    {
        Write-Host "Reading file: $($fileName.fullname)"
        $xmlDoc = New-Object -TypeName System.Xml.XmlDocument
        $xmlDoc.Load($fileName)

        $element = [System.Xml.XmlElement]($xmlDoc.GetElementsByTagName("PackageReference") | Select-Object -First 1)
        if ($element)
        {
            write-host "PackageReference: $($element.Attributes["Include"].Value) - Version: $($element.Attributes["Version"].Value)"

            write-host "****** RESOLVE TARGET VERSION *********"
            Get-PackageSource
            $res = Find-Package -Name *jquery* #-Source 'https://api.nuget.org/v3/index.json','http://www.nuget.org/api/v2/' -AllVersions
            Write-Host "Listing Packages: $($res.length)"
            $res | ForEach-Object {
                Write-Host "Found Package: $($_.name) - Version: $($_.version)"
            }

            write-host "****** UPDATE PACKAGE VERSION *********"
            $element.Attributes["Version"].Value = "4.0"
            write-host "PackageReference: $($element.Attributes["Include"].Value) - Version: $($element.Attributes["Version"].Value)"
            Write-Host "Writing file: $($fileName.fullname)"
            $xmlDoc.Save($fileName.fullname)
        }
        else
        {
            Write-Warning "No 'PackageReference' found in $($fileName.fullname)"
        }
    }

}
finally
{
    Trace-VstsLeavingInvocation $MyInvocation
}

