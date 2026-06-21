<#
    .SYNOPSIS
    Uninstall Link2Root for the current user

    .DESCRIPTION
    Uninstall Link2Root from the current machine for the current user.

    Note that you will always be prompted for confirmation before
    beginning the uninstallation. If needed, the confirmation can be
    skipped using the `-Force` switch.

    You can also specify which individual components for Link2Root are
    to be removed. To do so, you can either use the `-Confirm` switch
    and manually skip the necessary components, or use the `-KeepInstall`,
    `-KeepModule`, and `-KeepPATH` switches.

    By default, the progress and results of the uninstallation will be printed
    to the console, as well as visualized using a progress bar. To control this
    behavior and disable output logging and/or progress bars, use the `-Silent`,
    `-NoOutput`, and `-NoProgress` switches.

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
[CmdletBinding(DefaultParameterSetName = "WithOutput", SupportsShouldProcess)]
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
        Indicates that no output should be printed to the terminal
        by the script.

        By default and when neither this switch nor `-Silent` are used,
        the status and results of the script are printed to the terminal.

        Has no effect on progress bars or verbose output. To control the behavior
        of Progress Bars, use the `-NoProgress` or `-Silent` switch.
    #>
    [Parameter(ParameterSetName = "WithoutOutput", Mandatory)]
    [switch]$NoOutput,

    <#
        Indicates that no progress bars should be rendered
        in the terminal by the script.

        By default and when neither this switch nor `-Silent` are used,
        the status and progress of the script is reflected in one or
        more progress bars rendered within the terminal.

        Has no effect on progress bars created by built-in functions and cmdlets.
        To control the behavior of all PowerShell progress bars, use the
        `$ProgressPreference` automatic variable.
    #>
    [Alias("HideProgress")]
    [Parameter(ParameterSetName = "WithOutput")]
    [Parameter(ParameterSetName = "WithoutOutput")]
    [switch]$NoProgress,

    <#
        Indicates that no output or progress bars should be displayed
        in the terminal by the script.

        This switch is simply a shorthand for both `-NoOutput` and `-NoProgress`.

        By default and when neither this switch, nor the `-NoOutput` and `-NoProgress`
        switches, are used, the status, progress, and results of the script are
        reflected in output and progress bars displayed in the terminal.

        Has no effect on verbose output or progress bars created by built-in
        functions and cmdlets. To control the behavior of all PowerShell progress bars,
        use the `$ProgressPreference` automatic variable.
    #>
    [Parameter(ParameterSetName = "WithoutOutputOrProgress", Mandatory)]
    [switch]$Silent,

    <#
        Indicates that this function should return a boolean value
        indicating whether or not the uninstallation was successful.

        By default and when this switch is omitted, this function
        does not generate any output.
    #>
    [switch]$PassThru,

    <#
        An internal parameter used to flag that the script is being
        invoked internally, which is used to optimize the behavior
        of the script for internal calls.
    #>
    [Alias("Reinstall", "Rollback")]
    [Parameter(DontShow)]
    [switch]$Internal,

    <#
        An internal parameter used to specify the indentation
        level to use for output logging.
    #>
    [Parameter(DontShow)]
    [int]$Indentation = 0
)

Import-Module "$PSScriptRoot\Utils.psm1" -Verbose:($VerbosePreference -and -not $Internal)


# Script Variables #

[bool]$success = $false
[bool]$failed = $false
[bool]$yesToAll = $false
[bool]$noToAll = $false


# Main Script #

$ErrorActionPreference = "Stop"

if ($Force -and -not $PSBoundParameters.ContainsKey("Confirm")) {
    $ConfirmPreference = "None"
}

if ($Silent) {
    $NoOutput = $true
    $NoProgress = $true
}

try {
    [hashtable]$installTestArgs = @{
        NoOutput = $true
        NoProgress = $NoProgress
        PassThru = $true
        SkipInstallIntegrityCheck = $true
        SkipModuleIntegrityCheck = $true
        Any = $true
        Internal = $true
        Indentation = ($Indentation + 2)
    }

    Write-Verbose "$(_gis $Indentation)[>] Running Link2Root Uninstaller..."
    Hide-ProgressBars $NoProgress
    Add-ProgressBar -Name "Uninstalling Link2Root" -DefaultPercentageChange 25 -InitialSecondsRemaining 3
    _upb -Status "Check Current Installation Status"


    # Check if Link2Root is already installed
    Write-Verbose "$(_gis ($Indentation + 1))[>] Checking for Uninstallation Eligibility..."

    if (-not $Internal) {
        if (-not (& "$PSScriptRoot\Test-Link2RootInstall.ps1" @installTestArgs)) {
            Write-Verbose "$(_gis ($Indentation + 1))[-] Ineligible for Uninstallation"
            Write-Verbose "$(_gis $Indentation)[-] Link2Root Uninstallation Aborted."
            _upb -Status "No Uninstallation Required" -PercentageChange 100
            
            if (-not $NoOutput) {
                _wc "Link2Root" -NoNewline
                Write-Host " is " -NoNewline
                Write-Host "Not Currently Installed!" -ForegroundColor DarkYellow
            }
        
            if ($PassThru) { return $false }
            else           { return }
        }
    }
    else {
        Write-Verbose "$(_gis ($Indentation + 2))[+] Internal Invocation"
    }

    Write-Verbose "$(_gis ($Indentation + 1))[+] Eligible for Uninstallation"


    # Prompt for confirmation unless -Force is used and
    # proceed with the uninstallation of Link2Root
    Write-Verbose "$(_gis ($Indentation + 1))[>] Requesting User Confirmation to Proceed with Uninstallation..."
    
    if ($Force -or $PSCmdlet.ShouldContinue("Uninstall Link2Root for $(Get-FullyQualifiedUsername)", "Confirm", [ref]$yesToAll, [ref]$noToAll)) {
        if (-not $Force)    { Write-Verbose "$(_gis ($Indentation + 1))[+] User Approved Confirmation." }
        else                { Write-Verbose "$(_gis ($Indentation + 1))[+] Confirmation Automatically Approved via -Force Flag." }

        [string]$installLocation = & "$PSScriptRoot\Get-Link2RootInstall.ps1" -Internal:$Internal

        
        # Uninstall the script from the current user's local appdata folder
        Write-Verbose "$(_gis ($Indentation + 1))[>] Removing Installation Files..."
        _upb -Status "Remove Install Files" -CurrentOperation "Check Uninstall Status" -PercentageChange 0
        
        if (-not $KeepInstall) {
            if (Test-Path $installLocation) {
                Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with Uninstallation of Install Files..."

                if ($yesToAll -or $PSCmdlet.ShouldProcess(
                    "$(_gis ($Indentation + 3))[+] Confirmation APPROVED",
                    "Uninstall Link2Root from $installLocation",
                    "Confirm`nAre you sure you want to perform this action?"
                )) {
                    if ($yesToAll) {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] Confirmation Automatically Approved via Previous `"Yes to All`" Response"
                    }
                    elseif ($ConfirmPreference -in @("None", "High")) {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] Confirmation Automatically Approved due to Current ConfirmPreference Level ($ConfirmPreference)"
                    }
                    else {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] User Approved Confirmation."
                    }

                    try {
                        _upb -Status "Remove Install Files" -CurrentOperation "Remove Files" -PercentageChange 0
                        Remove-Item -Path $installLocation -Recurse @NO_RISK_PARAMS
                        
                        Write-Verbose "$(_gis ($Indentation + 2))[+] Removed Installation Files from Location: $installLocation"
                        Write-Verbose "$(_gis ($Indentation + 1))[+] Installation Files were Successfully Removed"
                        _upb -Status "Remove Install Files" -CurrentOperation "Operation Completed Successfully"
                        $success = $true

                        if (-not $NoOutput) {
                            _wcp -Success
                            Write-Host "Successfully uninstalled " -NoNewline -ForegroundColor Green
                            _wc "Link2Root" -NoNewline
                            Write-Host " from " -NoNewline
                            _wp $installLocation
                        }
                    }
                    catch {
                        Write-Verbose "$(_gis ($Indentation + 2))[-] Failed to Remove Installation Files"
                        Write-Verbose "$(_gis ($Indentation + 1))[-] Installation Files were NOT Removed"
                        _upb -Status "Remove Install Files" -CurrentOperation "Operation Failed"
                        $failed = $true
            
                        if (-not $NoOutput) {
                            _wcp -Failed
                            Write-Host "Failed to uninstall " -NoNewline -ForegroundColor Red
                            _wc "Link2Root" -NoNewline
                            Write-Host " from " -NoNewline
                            _wp $installLocation -NoNewline
                            Write-Host "!"
                            $_ | Format-Indentation -Indentation 2 | Write-Host -ForegroundColor Red
                        }
                    }
                }
                elseif (-not $WhatIfPreference) {
                    Write-Verbose "$(_gis ($Indentation + 3))[-] Confirmation NOT Approved"
                    Write-Verbose "$(_gis ($Indentation + 2))[-] User Rejected Confirmation"
                    Write-Verbose "$(_gis ($Indentation + 1))[-] Installation Files were NOT Modified"
                    _upb -Status "Remove Install Files" -CurrentOperation "Operation Cancelled"

                    if (-not $NoOutput) {
                        _wcp
                        Write-Host "Skipped uninstallation" -NoNewline -ForegroundColor DarkYellow
                        Write-Host " of " -NoNewline
                        _wc "Link2Root" -NoNewline
                        Write-Host " from " -NoNewline
                        _wp $installLocation
                    }
                }
            }
            else {
                Write-Verbose "$(_gis ($Indentation + 2))[/] No Installation Files Found to Remove"
                Write-Verbose "$(_gis ($Indentation + 1))[+] Installation Files Removed Successfully"
                _upb -Status "Remove Install Files" -CurrentOperation "No Action Required"

                if (-not $NoOutput) {
                    _wcp
                    _wc "Link2Root" -NoNewline
                    Write-Host " is " -NoNewline
                    Write-Host "not currently installed" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " in " -NoNewline
                    Write-Host $installLocation -ForegroundColor Cyan
                }
            }
        }
        else {
            Write-Verbose "$(_gis ($Indentation + 2))[-] -KeepInstall Flag Passed to Uninstallation Script"
            Write-Verbose "$(_gis ($Indentation + 1))[-] Installation Files were NOT Modified"
            _upb -Status "Remove Install Files" -CurrentOperation "Action Skipped"

            if (-not $NoOutput) {
                _wcp
                Write-Host "Skipped uninstallation" -NoNewline -ForegroundColor DarkYellow
                Write-Host " of " -NoNewline
                _wc "Link2Root" -NoNewline
                Write-Host " from " -NoNewline
                _wp $installLocation
            }
        }
        

        # Uninstall the module from the current user's PowerShell Modules folder
        Write-Verbose "$(_gis ($Indentation + 1))[>] Removing PowerShell Module..."
        _upb -Status "Remove PowerShell Module" -CurrentOperation "Check Uninstall Status" -PercentageChange 0
        
        if (-not $KeepModule) {
            [string]$modulePath = & "$PSScriptRoot\Get-Link2RootInstall.ps1" `
                -GetModulePath `
                -Internal:$Internal `
                -Indentation ($Indentation + 2)
            [string]$modulesLocation = Split-Path $modulePath -Parent
            
            if (Test-Path $modulePath) {
                Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with Uninstallation of PowerShell Module..."

                if ($yesToAll -or $PSCmdlet.ShouldProcess(
                    "$(_gis ($Indentation + 3))[+] Confirmation APPROVED",
                    "Uninstall Link2Root PowerShell Module from $modulesLocation",
                    "Confirm`nAre you sure you want to perform this action?"
                )) {
                    if ($yesToAll) {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] Confirmation Automatically Approved via Previous `"Yes to All`" Response"
                    }
                    elseif ($ConfirmPreference -in @("None", "High")) {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] Confirmation Automatically Approved due to Current ConfirmPreference Level ($ConfirmPreference)"
                    }
                    else {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] User Approved Confirmation."
                    }

                    try {
                        _upb -Status "Remove PowerShell Module Files" -CurrentOperation "Remove Files" -PercentageChange 0
                        Remove-Item -Path $modulePath -Recurse @NO_RISK_PARAMS

                        Write-Verbose "$(_gis ($Indentation + 2))[+] Removed PowerShell Module from Location: $modulePath"
                        Write-Verbose "$(_gis ($Indentation + 1))[+] PowerShell Module were Successfully Removed"
                        _upb -Status "Remove PowerShell Module Files" -CurrentOperation "Operation Completed Successfully"
                        $success = $true
                        
                        if (-not $NoOutput) {
                            _wcp -Success
                            Write-Host "Successfully uninstalled" -NoNewline -ForegroundColor Green
                            Write-Host " the " -NoNewline
                            _wc "Link2Root PowerShell Module" -NoNewline
                            Write-Host " from " -NoNewline
                            _wp $modulePath
                        }
                    }
                    catch {
                        if ($_.ErrorDetails.Message -ilike "*Access to the path*is denied.") {
                            Write-Verbose "$(_gis ($Indentation + 2))[/] Insufficient Access to Remove PowerShell Module"
                            Write-Verbose "$(_gis ($Indentation + 1))[/] PowerShell Module Pending Manual Uninstallation"
                            _upb -Status "Remove PowerShell Module" -CurrentOperation "Operation Completed with Warnings"

                            if (-not $NoOutput) {
                                Write-Warning "PowerShell does not have permission to modify $modulePath. This often caused by Anti-Virus Software or Windows Security's `"Controlled Folder Access`" option."
    
                                _wcp
                                _wc "Link2Root PowerShell Module" -NoNewline
                                Write-Host " is " -NoNewline
                                Write-Host "Pending Manual Uninstallation" -NoNewline -ForegroundColor DarkYellow
                                Write-Host " from " -NoNewline
                                _wp $modulePath
                            }
                        }
                        else {
                            Write-Verbose "$(_gis ($Indentation + 2))[-] Failed to Remove PowerShell Module"
                            Write-Verbose "$(_gis ($Indentation + 1))[-] PowerShell Module was NOT Removed"
                            _upb -Status "Remove PowerShell Module" -CurrentOperation "Operation Failed"
                            $failed = $true
                
                            if (-not $NoOutput) {
                                _wcp -Failed
                                Write-Host "Failed to uninstall" -NoNewline -ForegroundColor Red
                                Write-Host " the " -NoNewline
                                _wc "Link2Root PowerShell Module" -NoNewline
                                Write-Host " from " -NoNewline
                                _wp $modulePath -NoNewline
                                Write-Host "!"
                                $_ | Format-Indentation -Indentation 2 | Write-Host -ForegroundColor Red
                            }
                        }
                    }
                }
                elseif (-not $WhatIfPreference) {
                    Write-Verbose "$(_gis ($Indentation + 3))[-] Confirmation NOT Approved"
                    Write-Verbose "$(_gis ($Indentation + 2))[-] User Rejected Confirmation"
                    Write-Verbose "$(_gis ($Indentation + 1))[-] PowerShell Module was NOT Modified"
                    _upb -Status "Remove PowerShell Module" -CurrentOperation "Operation Cancelled"

                    if (-not $NoOutput) {
                        _wcp
                        Write-Host "Skipped uninstallation" -NoNewline -ForegroundColor DarkYellow
                        Write-Host " of the " -NoNewline
                        _wc "Link2Root PowerShell Module" -NoNewline
                        Write-Host " from " -NoNewline
                        _wp $installLocation
                    }
                }
            }
            else {
                Write-Verbose "$(_gis ($Indentation + 2))[/] No PowerShell Module Files Found to Remove"
                Write-Verbose "$(_gis ($Indentation + 1))[+] PowerShell Module Removed Successfully"
                _upb -Status "Remove PowerShell Module" -CurrentOperation "No Action Required"

                if (-not $NoOutput) {
                    _wcp
                    Write-Host "The " -NoNewline
                    _wc "Link2Root PowerShell Module" -NoNewline
                    Write-Host " is " -NoNewline
                    Write-Host "not currently installed" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " in " -NoNewline
                    _wp $modulePath
                }
            }
        }
        else {
            Write-Verbose "$(_gis ($Indentation + 2))[-] -KeepModule Flag Passed to Uninstallation Script"
            Write-Verbose "$(_gis ($Indentation + 1))[-] PowerShell Module was NOT Modified"
            _upb -Status "Remove PowerShell Module" -CurrentOperation "Action Skipped"

            if (-not $NoOutput) {
                _wcp
                Write-Host "Skipped uninstallation" -NoNewline -ForegroundColor DarkYellow
                Write-Host " of the " -NoNewline
                _wc "Link2Root PowerShell Module" -NoNewline
                Write-Host " from " -NoNewline
                _wp $installLocation
            }
        }
    

        # Remove the installation directory from the Current User's PATH
        Write-Verbose "$(_gis ($Indentation + 1))[>] Updating User PATH..."
        _upb -Status "Update User PATH" -CurrentOperation "Check Uninstall Status" -PercentageChange 0
        
        if (-not $KeepPATH) {
            [string[]]$userPATH = Get-UserPATH
            [string]$username = Get-FullyQualifiedUsername
    
            if (Test-UserPATH -Entry $installLocation -PATH $userPATH) {
                Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with User PATH Update..."
                
                if ($yesToAll -or $PSCmdlet.ShouldProcess(
                    "$(_gis ($Indentation + 3))[+] Confirmation APPROVED",
                    "Remove $installLocation from $username's PATH",
                    "Confirm`nAre you sure you want to perform this action?"
                )) {
                    if ($yesToAll) {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] Confirmation Automatically Approved via Previous `"Yes to All`" Response"
                    }
                    elseif ($ConfirmPreference -in @("None", "High")) {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] Confirmation Automatically Approved due to Current ConfirmPreference Level ($ConfirmPreference)"
                    }
                    else {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] User Approved Confirmation."
                    }

                    try {
                        _upb -Status "Update User PATH" -CurrentOperation "Remove PATH Entry" -PercentageChange 0
                        $userPATH.Where({
    
                            if ($_ -ieq $installLocation) {
                                Write-Verbose "$(_gis ($Indentation + 3))[+] Removed Entry: $_"
                                return $false
                            }
    
                            return $true
                        
                        }) | Set-UserPATH -Verbose:$VerbosePreference -Indentation ($Indentation + 3);

                        Write-Verbose "$(_gis ($Indentation + 2))[+] Removed Matching Entries from User PATH: $installLocation"
                        Write-Verbose "$(_gis ($Indentation + 1))[+] User PATH was Successfully Modified"
                        _upb -Status "Update User PATH" -CurrentOperation "Operation Completed Successfully"
                        $success = $true
                        
                        if (-not $NoOutput) {
                            _wcp -Success
                            Write-Host "Successfully removed " -NoNewline -ForegroundColor Green
                            _wc "Link2Root" -NoNewline
                            Write-Host " from " -NoNewline
                            _wp "$username's PATH"
                        }
                    }
                    catch {
                        Write-Verbose "$(_gis ($Indentation + 2))[-] Failed to Update User PATH"
                        Write-Verbose "$(_gis ($Indentation + 1))[-] User PATH was NOT Modified"
                        _upb -Status "Update User PATH" -CurrentOperation "Operation Failed"
                        $failed = $true
                        
                        if (-not $NoOutput) {
                            _wcp -Failed
                            Write-Host "Failed to remove " -NoNewline -ForegroundColor Red
                            _wc "Link2Root" -NoNewline
                            Write-Host " from " -NoNewline
                            _wp "$username's PATH" -NoNewline
                            Write-Host "!"
                            $_ | Format-Indentation -Indentation 2 | Write-Host -ForegroundColor Red
                        }
                    }
                }
                elseif (-not $WhatIfPreference) {
                    Write-Verbose "$(_gis ($Indentation + 3))[-] Confirmation NOT Approved"
                    Write-Verbose "$(_gis ($Indentation + 2))[-] User Rejected Confirmation"
                    Write-Verbose "$(_gis ($Indentation + 1))[-] User PATH was NOT Modified"
                    _upb -Status "Update User PATH" -CurrentOperation "Operation Cancelled"

                    if (-not $NoOutput) {
                        _wcp
                        Write-Host "Skipped removal" -NoNewline -ForegroundColor DarkYellow
                        Write-Host " of " -NoNewline
                        _wc "Link2Root" -NoNewline
                        Write-Host " from " -NoNewline
                        _wp "$username's PATH"
                    }
                }
            }
            else {
                Write-Verbose "$(_gis ($Indentation + 2))[/] No PATH Entries Found to Remove"
                Write-Verbose "$(_gis ($Indentation + 1))[/] User PATH was NOT Modified"
                _upb -Status "Remove PATH Entry" -CurrentOperation "No Action Required"

                if (-not $NoOutput) {
                    _wcp
                    _wc "Link2Root" -NoNewline
                    Write-Host " is " -NoNewline
                    Write-Host "not currently present" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " in " -NoNewline
                    _wp "$username's PATH"
                }
            }
        }
        else {
            Write-Verbose "$(_gis ($Indentation + 2))[-] -KeepPATH Flag Passed to Uninstallation Script"
            Write-Verbose "$(_gis ($Indentation + 1))[-] User PATH was NOT Modified"
            _upb -Status "Update User PATH" -CurrentOperation "Action Skipped"

            if (-not $NoOutput) {
                _wcp
                Write-Host "Skipped removal" -NoNewline -ForegroundColor DarkYellow
                Write-Host " of " -NoNewline
                _wc "Link2Root" -NoNewline
                Write-Host " from " -NoNewline
                _wp "$username's PATH"
            }
        }
    }
    else {
        Write-Verbose "$(_gis ($Indentation + 1))[-] User Rejected Confirmation."
        Write-Verbose "$(_gis $Indentation)[-] Link2Root Uninstallation Aborted."
    }


    # Cleanup and print and/or return the results
    if (-not $success -and -not $failed)    { Write-Verbose "$(_gis $Indentation)[/] No Changes Made by the Link2Root Uninstaller" }
    else                                    { Write-Verbose "$(_gis $Indentation)[+] Link2Root Uninstaller Completed Successfully" }
    
    _upb -Status "Uninstallation Complete" -PercentageChange 100
    
    if (-not $NoOutput) {
        # Write-Host ""
        
        if ($success -and -not $failed) {
            Write-Host "Successfully uninstalled " -NoNewline -ForegroundColor Green
            _wc "Link2Root" -NoNewline
            Write-Host "!" -ForegroundColor Green
        }
        elseif ($success) {
            Write-Host "Only some components of " -NoNewline -ForegroundColor DarkYellow
            _wc "Link2Root" -NoNewline
            Write-Host " were successfully uninstalled." -ForegroundColor DarkYellow
        }
        elseif (-not $failed) {
            Write-Host "Nothing for " -NoNewline -ForegroundColor Yellow
            _wc "Link2Root" -NoNewline
            Write-Host " was uninstalled." -ForegroundColor Yellow
        }
        else {
            Write-Host "Failed to uninstall " -NoNewline -ForegroundColor Red
            _wc "Link2Root" -NoNewline
            Write-Host "!" -ForegroundColor Red
        }
        
        if ($success) {
            Write-EndRestartNotice
        }
    }
    
    if ($PassThru) {
        return $success -and -not $failed
    }
}
catch {
    Write-Verbose "$(_gis $Indentation)[-] Link2Root Uninstaller Failed"
    _upb -Status "Uninstallation Failed" -PercentageChange 100
    throw $_
}
finally {
    Remove-ProgressBar
}