param()

return (
    (Test-Path (& "$PSScriptRoot\Get-InstallLocation.ps1") -Type Container) -and
    (Test-Path (& "$PSScriptRoot\Get-InstallLocation.ps1" -GetModulePath) -Type Container)
)