<#
    .SYNOPSIS
    Test if Link2Root is installed or not.

    .DESCRIPTION
    Test if Link2Root is currently installed on the computer.

    By default, Link2Root will only be considered to be installed
    if it is present in the expected installation location, added
    to the current user's PowerShell Modules, and added to the user's PATH.
    To specify which aspects of the installation to test,
    use the `-TestInstall`, `-TestModule`, and `-TestPATH` switches.

    .INPUTS
    None.
    You cannot pipe objects to `Test-Installation.ps1`.

    .OUTPUTS
    Bool.
    Returns `$true` if Link2Root is currently installed on the computer
    or `$false` if it is not.

    .EXAMPLE
    .\Test-Installation.ps1
    False

    .EXAMPLE
    .\Test-Installation.ps1 -TestModule
    True

    .EXAMPLE
    .\Test-Installation.ps1 -TestInstall -TestPATH
    False
#>
param(
    <#
        Indicates that the existence of the
        Link2Root Installation Directory should be tested.
    #>
    [switch]$TestInstall,
    
    <#
        Indicates that the existence of the
        Link2Root PowerShell Module should be tested.
    #>
    [switch]$TestModule,
    
    <#
        Indicates that the existence of the
        Link2Root Installation Directory in the
        current user's PATH should be tested.
    #>
    [switch]$TestPATH
)


[string]$installLocation = & "$PSScriptRoot\Get-InstallLocation.ps1"


if (-not ($TestInstall -or $TestModule -or $TestPATH)) {
    $TestInstall = $TestModule = $TestPATH = $true
}

if ($TestInstall -and -not (Test-Path $installLocation -Type Container)) {
    return $false
}
if ($TestModule -and -not (Test-Path (& "$PSScriptRoot\Get-InstallLocation.ps1" -GetModulePath) -Type Container)) {
    return $false
}
if ($TestPATH -and -not ($env:PATH -split ";" -contains $installLocation)) {
    return $false
}

return $true