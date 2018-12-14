write-host "****** VARIABLES *********"
$binDir=$env:AGENT_BINARIESDIRECTORY
$srcDir=$env:AGENT_SOURCESDIRECTORY
write-host "srcDir = $srcDir"
write-host "binDir = $binDir"
$searchProjectFile=$env:INPUT_SEARCHPROJECTFILE
$projectToTarget=$env:INPUT_PROJECTTOTARGET
write-host "searchProjectFile = $searchProjectFile"
write-host "projectToTarget = $projectToTarget"
