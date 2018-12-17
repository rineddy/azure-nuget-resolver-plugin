
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
try {
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

    foreach ($fileName in $filesFound) {
        Write-Host "Reading file: $($fileName.fullname)"
        $xmlDoc = New-Object -TypeName System.Xml.XmlDocument
        $xmlDoc.Load($fileName)

        $element = [System.Xml.XmlElement]($xmlDoc.GetElementsByTagName("PackageReference") | Select-Object -First 1)
        if ($element) {
            write-host "Package: $($element.Attributes["Include"]) - Version: $($element.Attributes["Version"])"
        }
        else {
            Write-Warning "No 'PackageReference' found in $($fileName.fullname)"
        }
    }

}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}

