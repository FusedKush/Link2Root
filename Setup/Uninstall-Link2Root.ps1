<#
    .SYNOPSIS
    Uninstall Link2Root for the current user

    .DESCRIPTION
    Uninstall Link2Root from the current machine for the current user.

    Note that you will always be prompted for confirmation before
    beginning the uninstallation. If needed, you can skip the confirmation
    using the `-Force` switch.

    You can also specify which individual components for Link2Root are
    to be removed. To do so, you can either use the `-Confirm` switch
    and manually skip the necessary components, or use the `-KeepInstall`,
    `-KeepModule`, and `-KeepPATH` switches.

    .INPUTS
    You cannot pipe any objects to `Uninstall-Link2Root.ps1`.

    .OUTPUTS
    None.
    By default, `Uninstall-Link2Root.ps1` doesn't generate any output.

    .OUTPUTS
    bool.
    When the `-PassThru` switch is used, `Uninstall-Link2Root.ps1` returns
    `$true` if the uninstallation was successful or `$false` if it was not.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    <#
        Keep the installation of Link2Root in the
        current user's `AppData/Local` folder.

        Using this option will allow you to continue using Link2Root
        without having to move or navigate to the downloaded `Link2Root/` folder.
    #>
    [switch]$KeepInstall,

    <#
        Keep the installation of the Link2Root PowerShell Module
        in the current user's PowerShell Modules.

        Using this option will allow you to continue using `Link2Root`
        and `LinkThis2Root` without having to import them into
        the PowerShell session or script.
    #>
    [switch]$KeepModule,

    <#
        Keep the Link2Root Installation Directory within
        the current user's `PATH`.
        
        Using this option will allow you to continue using
        the `Link2Root` command without having to move or navigate
        to the downloaded `Link2Root/` folder.

        This switch can only be used if `-KeepInstall` is used as well.
    #>
    [switch]$KeepPATH,

    <#
        Skip all confirmation prompts and immediately
        proceed with the Link2Root uninstallation.

        If this switch is used with the `-Confirm` switch, only
        the *initial* confirmation prompt will be skipped,
        and you will still be prompted for confirmation before
        each individual component is uninstalled.
    #>
    [switch]$Force,

    <#
        Indicates that this function should return a boolean value
        indicating whether or not the uninstallation was successful.

        By default and when this switch is omitted, this function
        does not generate any output.
    #>
    [switch]$PassThru,
    
    <#
        Suppress all non-error output.

        By default and when this switch is omitted, information will
        be output to the host indicating the progress and status
        of the uninstallation and the individual components for Link2Root.
    #>
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
                    if ($_.ErrorDetails.Message -ilike "*Access to the path is denied.") {
                        if (-not $Silent) {
                            Write-Warning "PowerShell does not have permission to modify $modulePath. This often caused by Anti-Virus Software or Windows Security's `"Controlled Folder Access`" option."

                            Write-Host "[" -NoNewline
                            Write-Host "/" -NoNewline -ForegroundColor Red
                            Write-Host "] The " -NoNewline
                            Write-Host "Link2Root PowerShell Module" -NoNewline -ForegroundColor Yellow
                            Write-Host " is " -NoNewline
                            Write-Host "Pending Manual Installation" -NoNewline -ForegroundColor DarkYellow
                            Write-Host " from " -NoNewline
                            Write-Host $modulePath -ForegroundColor Cyan
                            Write-Host "."
                            Write-Host ""
                            Write-Host $_ -ForegroundColor Red
                        }
                    }
                    else {
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
        }
        else {
            if (-not $Silent) {
                Write-Host "[" -NoNewline
                Write-Host "/" -NoNewline -ForegroundColor DarkYellow
                Write-Host "] " -NoNewline
                Write-Host "The " -NoNewline
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
        [string[]]$currentPATHContents = $currentPATH -split ";"

        if ($currentPATHContents -contains $installLocation) {
            if ($yesToAll -or $PSCmdlet.ShouldProcess(
                "Removing Link2Root from ${env:USERNAME}'s PATH",
                "Remove Link2Root from ${env:USERNAME}'s PATH",
                "Confirm`nAre you sure you want to perform this action?"
            )) {
                try {
                    [System.Environment]::SetEnvironmentVariable(
                        "PATH",
                        $currentPATHContents.Where({

                            if ($_ -ieq $installLocation) {
                                Write-Verbose "Removing Entry from ${env:USERNAME}'s PATH: $_"
                                return $false
                            }

                            return $true
                        
                        }) -join ";",
                        [EnvironmentVariableTarget]::User
                    );
                    $success = $true
                    
                    if (-not $Silent) {
                        Write-Host "[" -NoNewline
                        Write-Host "+" -NoNewline -ForegroundColor Green
                        Write-Host "] " -NoNewline
                        Write-Host "Successfully removed " -NoNewline -ForegroundColor Green
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
                        Write-Host "Failed to remove " -NoNewline -ForegroundColor Red
                        Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                        Write-Host " from " -NoNewline
                        Write-Host "${env:USERNAME}'s PATH" -NoNewline -ForegroundColor Cyan
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
        Write-Host ""
        Write-Host "You may have to restart your console session or terminal window for changes to take effect." -ForegroundColor Yellow
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
        Write-Host ""
        Write-Host "You may have to restart your console session or terminal window for changes to take effect." -ForegroundColor Yellow
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