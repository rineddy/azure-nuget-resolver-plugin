###########################################################
# Install technical prerequisites
# for Powershell Build Task
###########################################################

Function install-psmodule($psmodule)
{
    Remove-Item ps_temp -force -Recurse -ErrorAction SilentlyContinue
    New-Item ps_temp -ItemType Directory -Force
    New-Item ps_modules -ItemType Directory -Force

    write-host "save module: $psmodule" -ForegroundColor Green
    Remove-Item "ps_modules/$psmodule" -force -Recurse -ErrorAction SilentlyContinue
    Save-Module -Name $psmodule -Path ps_temp -Force
    Move-Item "ps_temp/$psmodule/**" "ps_modules/$psmodule" -Force

    Remove-Item ps_temp -force -Recurse
}


install-psmodule VstsTaskSdk