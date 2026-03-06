[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$KeepInstall,

    [switch]$KeepModule,

    [switch]$KeepPATH,

    [switch]$Force,

    [switch]$PassThru,
    
    [switch]$Silent
)

[hashtable]$NO_RISK_PARAMS = @{
    WhatIf = $false
    Confirm = $false
}

[string]$installLocation = & "$PSScriptRoot\Get-InstallLocation.ps1"
[string]$modulePath = & "$PSScriptRoot\Get-InstallLocation.ps1" -GetModulePath
[string]$modulesLocation = Split-Path $modulePath -Parent
[bool]$success = $false
[bool]$failed = $false
[bool]$yesToAll = $false
[bool]$noToAll = $false

$ErrorActionPreference = "Stop"

if ($Force -and -not $PSBoundParameters.ContainsKey("Confirm")) {
    $ConfirmPreference = "None"
}

if ($Force -or $PSCmdlet.ShouldContinue("Uninstall Link2Root", "Confirm", [ref]$yesToAll, [ref]$noToAll)) {
    $currentPATH = [System.Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)

    # Uninstall the script in the current user's local appdata folder
    if (-not $KeepInstall) {
        if (Test-Path $installLocation) {
            if ($yesToAll -or $PSCmdlet.ShouldProcess(
                "Uninstalling Link2Root from $installLocation",
                "Uninstall Link2Root from $installLocation",
                "Confirm`nAre you sure you want to perform this action?"
            )) {
                try {
                    Remove-Item -Path $installLocation -Recurse @NO_RISK_PARAMS
                    $success = $true
        
                    if (-not $Silent) {
                        Write-Host "[" -NoNewline
                        Write-Host "+" -NoNewline -ForegroundColor Green
                        Write-Host "] " -NoNewline
                        Write-Host "Successfully uninstalled " -NoNewline -ForegroundColor Green
                        Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                        Write-Host " from " -NoNewline
                        Write-Host $installLocation -ForegroundColor Cyan
                    }
                }
                catch {
                    $failed = $true
        
                    if (-not $Silent) {
                        Write-Host "[" -NoNewline
                        Write-Host "-" -NoNewline -ForegroundColor Red
                        Write-Host "] " -NoNewline
                        Write-Host "Failed to uninstall " -NoNewline -ForegroundColor Red
                        Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                        Write-Host " from " -NoNewline
                        Write-Host $installLocation -ForegroundColor Cyan
                        Write-Host "!"
                        Write-Host ""
                        Write-Host $_ -ForegroundColor Red
                    }
                }
            }
        }
        else {
            if (-not $Silent) {
                Write-Host "[" -NoNewline
                Write-Host "/" -NoNewline -ForegroundColor DarkYellow
                Write-Host "] " -NoNewline
                Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                Write-Host " is " -NoNewline
                Write-Host "not currently installed" -NoNewline -ForegroundColor DarkYellow
                Write-Host " in " -NoNewline
                Write-Host $installLocation -ForegroundColor Cyan
            }
        }
    }
    
    # Uninstall the module in the current user's PowerShell Modules folder
    if (-not $KeepModule) {
        if (Test-Path $modulePath) {
            if ($yesToAll -or $PSCmdlet.ShouldProcess(
                "Uninstalling Link2Root PowerShell Module from $modulesLocation",
                "Uninstall Link2Root PowerShell Module from $modulesLocation",
                "Confirm`nAre you sure you want to perform this action?"
            )) {
                try {
                    Remove-Item -Path $modulePath -Recurse @NO_RISK_PARAMS
                    $success = $true
                    
                    if (-not $Silent) {
                        Write-Host "[" -NoNewline
                        Write-Host "+" -NoNewline -ForegroundColor Green
                        Write-Host "] " -NoNewline
                        Write-Host "Successfully uninstalled" -NoNewline -ForegroundColor Green
                        Write-Host " the " -NoNewline
                        Write-Host "Link2Root PowerShell Module" -NoNewline -ForegroundColor Yellow
                        Write-Host " from " -NoNewline
                        Write-Host $modulePath -ForegroundColor Cyan
                    }
                }
                catch {
                    $failed = $true
        
                    if (-not $Silent) {
                        Write-Host "[" -NoNewline
                        Write-Host "-" -NoNewline -ForegroundColor Red
                        Write-Host "] " -NoNewline
                        Write-Host "Failed to uninstall" -NoNewline -ForegroundColor Red
                        Write-Host " the " -NoNewline
                        Write-Host "Link2Root PowerShell Module" -NoNewline -ForegroundColor Yellow
                        Write-Host " from " -NoNewline
                        Write-Host $modulePath -ForegroundColor Cyan
                        Write-Host "!"
                        Write-Host ""
                        Write-Host $_ -ForegroundColor Red
                    }
                }
            }
        }
        else {
            if (-not $Silent) {
                Write-Host "[" -NoNewline
                Write-Host "/" -NoNewline -ForegroundColor DarkYellow
                Write-Host "] " -NoNewline
                Write-Host "The "
                Write-Host "Link2Root PowerShell Module" -NoNewline -ForegroundColor Yellow
                Write-Host " is " -NoNewline
                Write-Host "not currently installed" -NoNewline -ForegroundColor DarkYellow
                Write-Host " in " -NoNewline
                Write-Host $modulePath -ForegroundColor Cyan
            }
        }
    }

    # Remove the installation directory from the Current User's PATH
    if (-not $KeepPATH) {
        if ($currentPATH -contains $installLocation) {
            if ($yesToAll -or $PSCmdlet.ShouldProcess(
                "Removing Link2Root from ${env:USERNAME}'s PATH",
                "Remove Link2Root from ${env:USERNAME}'s PATH",
                "Confirm`nAre you sure you want to perform this action?"
            )) {
                try {
                    [string[]]$currentPATHContents = $currentPATH -split ";"

                    $currentPATHContents.Remove($installLocation)
                    [System.Environment]::SetEnvironmentVariable(
                        "PATH",
                        $currentPATHContents -join ";",
                        [EnvironmentVariableTarget]::User
                    );
                    $success = $true
                    
                    if (-not $Silent) {
                        Write-Host "[" -NoNewline
                        Write-Host "+" -NoNewline -ForegroundColor Green
                        Write-Host "] " -NoNewline
                        Write-Host "Successfully removed" -NoNewline -ForegroundColor Green
                        Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                        Write-Host " from " -NoNewline
                        Write-Host "${env:USERNAME}'s PATH" -ForegroundColor Cyan
                    }
                }
                catch {
                    $failed = $true
        
                    if (-not $Silent) {
                        Write-Host "[" -NoNewline
                        Write-Host "-" -NoNewline -ForegroundColor Red
                        Write-Host "] " -NoNewline
                        Write-Host "Failed to remove" -NoNewline -ForegroundColor Red
                        Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                        Write-Host " from " -NoNewline
                        Write-Host "${env:USERNAME}'s PATH" -ForegroundColor Cyan
                        Write-Host "!"
                        Write-Host ""
                        Write-Host $_ -ForegroundColor Red
                    }
                }
            }
        }
        else {
            if (-not $Silent) {
                Write-Host "[" -NoNewline
                Write-Host "/" -NoNewline -ForegroundColor DarkYellow
                Write-Host "] " -NoNewline
                Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                Write-Host " is " -NoNewline
                Write-Host "not currently present" -NoNewline -ForegroundColor DarkYellow
                Write-Host " in " -NoNewline
                Write-Host "${env:USERNAME}'s PATH" -ForegroundColor Cyan
            }
        }
    }
}

if (-not $Silent) {
    if ($success -and -not $failed) {
        Write-Host "Successfully uninstalled " -NoNewline -ForegroundColor Green
        Write-Host "Link2Root" -NoNewline -ForegroundColor Cyan
        Write-Host "!" -ForegroundColor Green
    }
    elseif (-not $failed) {
        Write-Host "Nothing for " -NoNewline -ForegroundColor Yellow
        Write-Host "Link2Root" -NoNewline -ForegroundColor Cyan
        Write-Host " was uninstalled." -ForegroundColor Yellow
    }
    elseif ($success) {
        Write-Host "Only some components of " -NoNewline -ForegroundColor DarkYellow
        Write-Host "Link2Root" -NoNewline -ForegroundColor Cyan
        Write-Host " were successfully uninstalled." -ForegroundColor DarkYellow
    }
    else {
        Write-Host "Failed to uninstall " -NoNewline -ForegroundColor Red
        Write-Host "Link2Root" -NoNewline -ForegroundColor Cyan
        Write-Host "!" -ForegroundColor Red
    }
}

if ($PassThru) {
    return $success -and -not $failed
}