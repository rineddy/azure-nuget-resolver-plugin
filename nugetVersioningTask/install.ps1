###########################################################
# Install technical prerequisites
# for Powershell Build Task
###########################################################

Function install-psmodule($psmodule)
{
    New-Item ps_temp -ItemType Directory -Force
    New-Item ps_modules -ItemType Directory -Force

    Save-Module -Name $psmodule -Path ps_temp
    Move-Item ps_temp/$psmodule/** ps_modules/$psmodule

    Remove-Item ps_temp
}

install-psmodule VstsTaskSdk
