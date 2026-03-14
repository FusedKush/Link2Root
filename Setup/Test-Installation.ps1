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
[CmdletBinding()]
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
    [switch]$TestPATH,

    [switch]$Silent,
    [switch]$PassThru
)


Import-Module "$PSScriptRoot\Utils.psm1"

[bool]$result = $true
[string]$installLocation = & "$PSScriptRoot\Get-InstallLocation.ps1"


Write-Verbose "Testing Current Installation Status of Link2Root"

if (-not ($TestInstall -or $TestModule -or $TestPATH)) {
    $TestInstall = $TestModule = $TestPATH = $true
}

if ($TestInstall) {
    if (Test-Path $installLocation -Type Container) {
        Write-Verbose "Link2Root IS installed in $installLocation"
        
        if (-not $Silent) {
            Write-ComponentUpdatePrefix -Success
            Write-Component "Link2Root" -NoNewline
            Write-Host " Installed" -NoNewline -ForegroundColor Green
            Write-Host " in " -NoNewline
            Write-Path $installLocation
        }
    }
    else {
        Write-Verbose "Link2Root is NOT installed in $installLocation"
        
        if (-not $Silent) {
            Write-ComponentUpdatePrefix -Failed
            Write-Component "Link2Root" -NoNewline
            Write-Host " NOT Installed" -NoNewline -ForegroundColor Red
            Write-Host " in " -NoNewline
            Write-Path $installLocation
            $result = $false
        }
    }
}
if ($TestModule) {
    [string]$modulePath = (& "$PSScriptRoot\Get-InstallLocation.ps1" -GetModulePath)
    
    if (Test-Path $modulePath -Type Container) {
        Write-Verbose "The Link2Root PowerShell Module IS installed in $modulePath"

        if (-not $Silent) {
            Write-ComponentUpdatePrefix -Success
            Write-Component "Link2Root PowerShell Module" -NoNewline
            Write-Host " Installed" -NoNewline -ForegroundColor Green
            Write-Host " in " -NoNewline
            Write-Path $modulePath
        }
    }
    else {
        Write-Verbose "The Link2Root PowerShell Module is NOT installed in $modulePath"

        if (-not $Silent) {
            Write-ComponentUpdatePrefix -Failed
            Write-Component "Link2Root PowerShell Module" -NoNewline
            Write-Host " NOT Installed" -NoNewline -ForegroundColor Red
            Write-Host " in " -NoNewline
            Write-Path $modulePath
            $result = $false
        }
    }
}
if ($TestPATH) {
    [string]$username = Get-FullyQualifiedUsername
    
    if (Test-UserPATH $installLocation) {
        Write-Verbose "Entry $installLocation FOUND in $username's PATH"

        if (-not $Silent) {
            Write-ComponentUpdatePrefix -Success
            Write-Component "Link2Root" -NoNewline
            Write-Host " Added" -NoNewline -ForegroundColor Green
            Write-Host " to " -NoNewline
            Write-Path "$username's PATH"
        }
    }
    else {
        Write-Verbose "Entry $installLocation NOT found in $username's PATH"

        if (-not $Silent) {
            Write-ComponentUpdatePrefix -Failed
            Write-Component "Link2Root" -NoNewline
            Write-Host " NOT Added" -NoNewline -ForegroundColor Red
            Write-Host " to " -NoNewline
            Write-Path "$username's PATH"
        }
        $result = $false
    }
}

if ($result) {
    Write-Verbose "Link2Root IS considered to be installed"
}
else {
    Write-Verbose "Link2Root is NOT considered to be installed"
}

if (-not $Silent) {
    Write-Component "Link2Root" -NoNewline
    Write-Host " is " -NoNewline

    if ($result) {
        Write-Host "Currently Installed!" -ForegroundColor Green
    }
    else {
        Write-Host "NOT Currently Installed!" -ForegroundColor Red
    }
}

if ($PassThru) {
    return $result
}