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


Import-Module "$PSScriptRoot\Utils.psm1"

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

if (-not (& "$PSScriptRoot\Test-Installation.ps1" -Silent -PassThru)) {
    if (-not $Silent) {
        Write-Component "Link2Root" -NoNewline
        Write-Host " is " -NoNewline
        Write-Host "not currently installed!" -ForegroundColor Yellow
    }

    if ($PassThru) {
        return $false
    }
    else {
        return
    }
}

if ($Force -or $PSCmdlet.ShouldContinue("Uninstall Link2Root", "Confirm", [ref]$yesToAll, [ref]$noToAll)) {
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
                        Write-ComponentUpdatePrefix -Success
                        Write-Host "Successfully uninstalled " -NoNewline -ForegroundColor Green
                        Write-Component "Link2Root" -NoNewline
                        Write-Host " from " -NoNewline
                        Write-Path $installLocation
                    }
                }
                catch {
                    $failed = $true
        
                    if (-not $Silent) {
                        Write-ComponentUpdatePrefix -Failed
                        Write-Host "Failed to uninstall " -NoNewline -ForegroundColor Red
                        Write-Component "Link2Root" -NoNewline
                        Write-Host " from " -NoNewline
                        Write-Path $installLocation
                        Write-Host "!"
                        Write-Host ""
                        Write-Host $_ -ForegroundColor Red
                    }
                }
            }
        }
        else {
            if (-not $Silent) {
                Write-ComponentUpdatePrefix
                Write-Component "Link2Root" -NoNewline
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
                        Write-ComponentUpdatePrefix -Success
                        Write-Host "Successfully uninstalled" -NoNewline -ForegroundColor Green
                        Write-Host " the " -NoNewline
                        Write-Component "Link2Root PowerShell Module" -NoNewline
                        Write-Host " from " -NoNewline
                        Write-Path $modulePath
                    }
                }
                catch {
                    if ($_.ErrorDetails.Message -ilike "*Access to the path*is denied.") {
                        if (-not $Silent) {
                            Write-Warning "PowerShell does not have permission to modify $modulePath. This often caused by Anti-Virus Software or Windows Security's `"Controlled Folder Access`" option."

                            Write-ComponentUpdatePrefix
                            Write-Component "Link2Root PowerShell Module" -NoNewline
                            Write-Host " is " -NoNewline
                            Write-Host "Pending Manual Uninstallation" -NoNewline -ForegroundColor DarkYellow
                            Write-Host " from " -NoNewline
                            Write-Path $modulePath -NoNewline
                        }
                    }
                    else {
                        $failed = $true
            
                        if (-not $Silent) {
                            Write-ComponentUpdatePrefix -Failed
                            Write-Host "Failed to uninstall" -NoNewline -ForegroundColor Red
                            Write-Host " the " -NoNewline
                            Write-Component "Link2Root PowerShell Module" -NoNewline
                            Write-Host " from " -NoNewline
                            Write-Path $modulePath
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
                Write-ComponentUpdatePrefix
                Write-Host "The " -NoNewline
                Write-Component "Link2Root PowerShell Module" -NoNewline
                Write-Host " is " -NoNewline
                Write-Host "not currently installed" -NoNewline -ForegroundColor DarkYellow
                Write-Host " in " -NoNewline
                Write-Path $modulePath
            }
        }
    }

    # Remove the installation directory from the Current User's PATH
    if (-not $KeepPATH) {
        [string[]]$userPATH = Get-UserPATH
        [string]$username = Get-FullyQualifiedUsername

        if (Test-UserPATH -Entry $installLocation -PATH $userPATH) {
            if ($yesToAll -or $PSCmdlet.ShouldProcess(
                "Removing $installLocation from $username's PATH",
                "Remove $installLocation from $username's PATH",
                "Confirm`nAre you sure you want to perform this action?"
            )) {
                try {
                    $userPATH.Where({

                        if ($_ -ieq $installLocation) {
                            Write-Verbose "Removing Entry from $username's PATH: $_"
                            return $false
                        }

                        return $true
                    
                    }) | Set-UserPATH;
                    $success = $true
                    
                    if (-not $Silent) {
                        Write-ComponentUpdatePrefix -Success
                        Write-Host "Successfully removed " -NoNewline -ForegroundColor Green
                        Write-Component "Link2Root" -NoNewline
                        Write-Host " from " -NoNewline
                        Write-Path "$username's PATH"
                    }
                }
                catch {
                    $failed = $true
        
                    if (-not $Silent) {
                        Write-ComponentUpdatePrefix -Failed
                        Write-Host "Failed to remove " -NoNewline -ForegroundColor Red
                        Write-Component "Link2Root" -NoNewline
                        Write-Host " from " -NoNewline
                        Write-Path "$username's PATH" -NoNewline
                        Write-Host "!"
                        Write-Host ""
                        Write-Host $_ -ForegroundColor Red
                    }
                }
            }
        }
        else {
            if (-not $Silent) {
                Write-ComponentUpdatePrefix
                Write-Component "Link2Root" -NoNewline
                Write-Host " is " -NoNewline
                Write-Host "not currently present" -NoNewline -ForegroundColor DarkYellow
                Write-Host " in " -NoNewline
                Write-Path "$username's PATH"
            }
        }
    }
}

if (-not $Silent) {
    Write-Host ""
    
    if ($success -and -not $failed) {
        Write-Host "Successfully uninstalled " -NoNewline -ForegroundColor Green
        Write-Component "Link2Root" -NoNewline
        Write-Host "!" -ForegroundColor Green
    }
    elseif ($success) {
        Write-Host "Only some components of " -NoNewline -ForegroundColor DarkYellow
        Write-Component "Link2Root" -NoNewline
        Write-Host " were successfully uninstalled." -ForegroundColor DarkYellow
    }
    elseif (-not $failed) {
        Write-Host "Nothing for " -NoNewline -ForegroundColor Yellow
        Write-Component "Link2Root" -NoNewline
        Write-Host " was uninstalled." -ForegroundColor Yellow
    }
    else {
        Write-Host "Failed to uninstall " -NoNewline -ForegroundColor Red
        Write-Component "Link2Root" -NoNewline
        Write-Host "!" -ForegroundColor Red
    }
    
    if ($success) {
        Write-EndRestartNotice
    }
}

if ($PassThru) {
    return $success -and -not $failed
}