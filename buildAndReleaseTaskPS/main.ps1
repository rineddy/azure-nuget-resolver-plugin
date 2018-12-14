
Import-PowerShellDataFile .\ps_modules\VstsTaskSdk\VstsTaskSdk.psd1
Import-Module .\ps_modules\VstsTaskSdk\VstsTaskSdk.psm1

write-host "****** VARIABLES *********"
$binDir = $env:AGENT_BINARIESDIRECTORY
$srcDir = $env:AGENT_SOURCESDIRECTORY
write-host "srcDir = $srcDir"
write-host "binDir = $binDir"
$searchProjectFile = $env:INPUT_SEARCHPROJECTFILE
$projectToTarget = $env:INPUT_PROJECTTOTARGET
write-host "searchProjectFile = $searchProjectFile"
write-host "projectToTarget = $projectToTarget"

write-host $(Get-TaskVariable "Agent.BinariesDirectory")
write-host $(Get-TaskVariable "AGENT_BINARIESDIRECTORY")

write-host $(Get-VstsInput "Agent.BinariesDirectory")
write-host $(Get-VstsInput "AGENT_BINARIESDIRECTORY")