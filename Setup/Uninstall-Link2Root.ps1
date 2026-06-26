<#
    .SYNOPSIS
    Uninstall Link2Root for the current user

    .DESCRIPTION
    Uninstall Link2Root from the current machine for the current user.

    Note that you will always be prompted for confirmation before
    beginning the uninstallation. If needed, the confirmation can be
    skipped using the `-Force` switch.

    By default, all of the individual Link2Root Setup Components are uninstalled.
    To specify which components should be uninstalled, use the `-Components` parameter.

    When you run the uninstaller, the removed files are immediately permanently deleted by default.
    However, when the `-EnableRollback` switch is passed to the script, the files are
    instead temporarily archived, and the script will return a Rollback Hash. This value
    can then be passed back to the script using the `-Rollback` parameter in order to rollback
    the changes made by the uninstaller and recover all of the Link2Root Setup Components
    that were previously uninstalled by the script.

    By default, the progress and results of the uninstallation will be printed
    to the console, as well as visualized using a progress bar. To control this
    behavior and disable output logging and/or progress bars, use the `-Silent`,
    `-NoOutput`, and `-NoProgress` switches.

    .NOTES
    In order to perform an Uninstallation Rollback, the following pre-requisites must be met:

       1. The `-EnableRollback` switch must be passed to the uninstaller when removing
          one or more Setup Components in order for the changes to be rolled back later.

       2. None of the Setup Components being rolled back can be installed already.
          If any of the designated components are already installed, the rollback will fail.

       3. For the "PATHUpdate" Setup Component, the User's PATH must be *identical*
          to the way the uninstaller left it after removing the Link2Root PATH Entries.

          If the User's PATH differs from the value the uninstaller set the
          User's Updated PATH to, the rollback will fail.

    When running an Uninstallation Rollback, all of the same options that can be passed to
    the uninstaller itself are supported, including:

       - `-NoOutput`, `-NoProgress`, and `-Silent` to suppress output
       - The `-Force`, `-Confirm`, and `-WhatIf` Risk-Management Parameters
       - The `-Components` Parameter to control which Setup Components are rolled back
       - The `-PassThru` Parameter to obtain the results of the rollback

    Despite their usefulness, Uninstallation Rollbacks are *not* intended to be a
    replacement for true backups, and they have several limitations that are
    important to keep in mind:

       - A maximum of 10 rollbacks can be stored at any given time, and a rollback
         can only be performed for up to 7 days after the corresponding
         uninstallation is performed.

       - Because the archived data used for rollbacks is stored in a
         temporary directory, it may be removed or disappear at any time.

       - The returned Rollback Hash is based on the Link2Root Setup Components
         being uninstalled and their associated files and data. As a result,
         multiple uninstallations can return the same Rollback Hash.
    
       - Do not manipulate any rollback archive data or attempt to rollback setup components
         from different versions of Link2Root. If used improperly, Uninstallation Rollbacks
         can leave the Link2Root Installation in a broken or corrupted state.

    .INPUTS
    string[].
    You can pipe the individual components of Link2Root
    to be uninstalled to `Uninstall-Link2Root.ps1`.

    .OUTPUTS
    None.
    By default, `Uninstall-Link2Root.ps1` doesn't generate any output.

    .OUTPUTS
    bool.
    When the `-PassThru` switch is used, `Uninstall-Link2Root.ps1` returns
    `$true` if the uninstallation or rollback was successful or `$false` if it was not.

    .EXAMPLE
    .\Uninstall-Link2Root.ps1

    Run the full Link2Root Uninstaller.

    .EXAMPLE
    .\Uninstall-Link2Root.ps1 -Components PowerShellModule -Silent -PassThru
    True

    Only uninstall the Link2Root PowerShell Module, don't print any information
    about the uninstallation to the console, and return the results of the uninstaller
    from the function.

    .EXAMPLE
    .\Uninstall-Link2Root.ps1 -EnableRollback -Components LocalInstall, PATHUpdate
    246A833BAFF301DCA34FA11A244337196D5D9A1754E53BD382468BC93CD9C8DA

    Uninstall the Local Link2Root Installation and update the User's PATH, temporarily
    archiving the removed files and data so the changes can be rolled back later.

    .EXAMPLE
    .\Uninstall-Link2Root.ps1 -Rollback 246A833BAFF301DCA34FA11A244337196D5D9A1754E53BD382468BC93CD9C8DA

    Roll back the changes made by a previous uninstallation and restore the
    installation to its previous state.
    
    .LINK
    Install-Link2Root.ps1

    .LINK
    Test-Link2RootInstall.ps1
#>
[CmdletBinding(DefaultParameterSetName = "UninstallWithoutRollback", SupportsShouldProcess)]
param(
    <#
        The individual components of Link2Root to be uninstalled.

        If no components are specified, all of the
        Available Setup Components will be uninstalled.
    #>
    [ArgumentCompleter({
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Get-SetupComponentArgumentCompletions -Verbose:$false
        Get-SetupComponentArgumentCompletions @args
    })]
    [Parameter(Position = 0, ValueFromPipeline)]
    [ValidateScript({
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Test-SetupComponentParameter -Verbose:$false
        $_ | Test-SetupComponentParameter
    })]
    [string[]]$Components = (& {
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Get-SetupComponents -Verbose:$false
        Get-SetupComponents
    }),

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
    [switch]$Silent,

    <#
        Indicates that this function should return a boolean value
        indicating if the uninstallation or rollback was successful.

        By default and when this switch is omitted, this function
        does not generate any output.
    #>
    [Parameter(ParameterSetName = "UninstallWithoutRollback")]
    [Parameter(ParameterSetName = "RollbackPreviousUninstall")]
    [switch]$PassThru,
    
    <#
        Indicates that all of the Setup Components that have been
        designated for removal should be temporarily backed up
        instead of being immediately permanently deleted. This
        option allows for any changes made by the script
        to be rolled back later using the `-Rollback` option.

        By default and when this switch is omitted, all of the
        Setup Components that have been designated for removal will
        be immediately permanently deleted, making them ineligible
        to be recovered later using the `-Rollback` option.

        When this switch is used, the `-PassThru` switch is automatically
        implied, and a Rollback Hash will be returned by the function.
        To restore the previously-uninstalled Setup Components, the
        Rollback Hash is passed to the `-Rollback` parameter of
        the script.
    #>
    [Alias("AllowRollback")]
    [Parameter(ParameterSetName = "UninstallWithRollback", Mandatory)]
    [switch]$EnableRollback,
    
    <#
        Indicates that the previous uninstallation of Link2Root corresponding
        to the specified Rollback Hash should be rolled back, and any components
        that were removed should be restored.

        In order to use this option, the `-EnableRollback` option must be
        used when running the uninstallation, which will archive the
        removed components to be rolled back later, and return a Rollback Hash
        that can then be passed to this parameter to rollback the uninstallation.
    #>
    [Alias("RollbackFrom")]
    [Parameter(ParameterSetName = "RollbackPreviousUninstall", Mandatory)]
    [string]$Rollback,

    <#
        An internal parameter used to flag that the script is being
        invoked internally, which is used to optimize the behavior
        of the script for internal calls.
    #>
    [Parameter(DontShow)]
    [switch]$Internal,

    <#
        An internal parameter used to specify the indentation
        level to use for output logging.
    #>
    [Parameter(DontShow)]
    [int]$Indentation = 0
)

begin {
    Import-Module "$PSScriptRoot\Utils.psm1" -Verbose:$false


    # Script Definitions #
    
    [int]$MAX_ROLLBACK_COUNT = 10
    [int]$MAX_ROLLBACK_AGE = 7
    
    [bool]$success = $false
    [bool]$failed = $false
    [bool]$yesToAll = $false
    [bool]$noToAll = $false
    [string]$installLocation = & "$PSScriptRoot\Get-Link2RootInstall.ps1" -Internal:$Internal
    [string]$baseRollbackLocation = "$(Get-TemporaryFileLocation)\Uninstall"
    [link2rootSetupComponent[]]$uninstallComponents = @()
    
    function Remove-RollbackDirectory {
    
        param(
            [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
            [string]$RollbackDirectory,
    
            [int]$Indentation = 0
        )
    
        [string]$directoryName = Split-Path $RollbackDirectory -Leaf
    
        try {
            Write-Verbose "$(_gis $Indentation)[>] Removing Rollback Directory '$directoryName'..."
            Remove-Item $RollbackDirectory -Recurse -Force -ErrorAction Ignore @NO_RISK_PARAMS
            Write-Verbose "$(_gis ($Indentation + 1))[+] Removed Directory: $RollbackDirectory"
            Write-Verbose "$(_gis $Indentation)[+] Removed Rollback Directory '$directoryName'"
        }
        catch {
            Write-Verbose "$(_gis ($Indentation + 1))[-] Error: $_"
            Write-Verbose "$(_gis $Indentation)[-] Failed to Remove Rollback Directory '$directoryName'"
        }
    
    }
    
    function Optimize-Rollbacks {
    
        param(
            [int]$Indentation = 0
        )
    
        [System.IO.DirectoryInfo[]]$rollbacks = Get-ChildItem $baseRollbackLocation -Directory | Sort-Object -Property CreationTime
    
        if ($rollbacks) {
            if ($rollbacks.Count -gt $MAX_ROLLBACK_COUNT -or (New-TimeSpan $rollbacks[-1].CreationTime).Days -gt $MAX_ROLLBACK_AGE) {
                [int]$requiredPruneCount = ($rollbacks.Count - $MAX_ROLLBACK_COUNT)
                [int]$i = 0
        
                Write-Verbose "$(_gis $Indentation)[>] Pruning Existing Rollbacks..."
        
                while ((New-TimeSpan $rollbacks[$i].CreationTime).Days -gt $MAX_ROLLBACK_AGE -or $requiredPruneCount -gt 0) {
                    try {
                        $rollbacks[$i].Delete($true)
                        Write-Verbose "$(_gis ($Indentation + 1))[+] Pruned: $($rollbacks[$i].BaseName)"
            
                        if ($requiredPruneCount -gt 0) {
                            $requiredPruneCount--
                        }
                    }
                    catch {
                        Write-Verbose "$(_gis ($Indentation + 1))[-] Failed to Prune: $($rollbacks[$i].BaseName)"
                    }
                    finally {
                        $i++
                    }
                }
        
                Write-Verbose "$(_gis $Indentation)[+] Pruned Existing Rollbacks: $i"
            }
        }
    
    }
}

process {
    $uninstallComponents += $Components
}

end {
    # Main Script #
    
    $ErrorActionPreference = "Stop"
    
    if ($Force -and -not $PSBoundParameters.ContainsKey("Confirm")) {
        $ConfirmPreference = "None"
    }
    
    if ($Silent) {
        $NoOutput = $true
        $NoProgress = $true
    }
    
    
    # Uninstall Link2Root
    if (-not $Rollback) {
        [string]$rollbackId = New-Guid
        [string]$rollbackDirectory = "$baseRollbackLocation\$rollbackId"
    
        function Remove-InstallDirectory {
    
            param(
                [string]$Path,
                [string]$Component,
                [int]$Indentation
            )
    
            try {
                if ($EnableRollback) {
                    Move-Item -Path $Path -Destination "$rollbackDirectory\$Component" @NO_RISK_PARAMS
                    Write-Verbose "$(_gis $Indentation)[+] Archived Files for Future Rollback: $rollbackId\$Component"
                }
                else {
                    Remove-Item -Path $Path -Recurse @NO_RISK_PARAMS
                }
    
                Write-Verbose "$(_gis $Indentation)[+] Removed Installation Files from Location: $Path"
            }
            catch {
                Write-Verbose "$(_gis $Indentation)[-] Removed Installation Files from Location: $Path"
                throw $_
            }
    
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
        
        
            # Check if Link2Root is currently installed
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
                try {
                    if (-not $Force) { Write-Verbose "$(_gis ($Indentation + 1))[+] User Approved Confirmation." }
                    else             { Write-Verbose "$(_gis ($Indentation + 1))[+] Confirmation Automatically Approved via -Force Flag." }
            
            
                    # Create the Rollback Directory if necessary
                    if ($EnableRollback) {
                        Write-Verbose "$(_gis ($Indentation + 1))[+] Using Option 'EnableRollback'"
                        Optimize-Rollbacks -Indentation ($Indentation + 1)
                        Write-Verbose "$(_gis ($Indentation + 1))[>] Creating Rollback Directory..."
                        Confirm-DirectoryExists -Path $rollbackDirectory -MaxDepth 3 -Indentation ($Indentation + 1)
                        Write-Verbose "$(_gis ($Indentation + 1))[+] Created Rollback Directory: $(Split-Path $rollbackDirectory -Leaf)"
                    }
            
                    
                    # Uninstall the script from the current user's local appdata folder
                    Write-Verbose "$(_gis ($Indentation + 1))[>] Removing Installation Files..."
                    _upb -Status "Remove Install Files" -CurrentOperation "Check Uninstall Status" -PercentageChange 0
                    
                    if ($uninstallComponents -icontains "LocalInstall") {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] 'LocalInstall' Component Included in Uninstall"
            
                        if (Test-Path $installLocation) {
                            Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with Uninstallation of Install Files..."
            
                            if ($yesToAll -or $PSCmdlet.ShouldProcess(
                                (_gvcpd `
                                    -WhatIfValue $WhatIfPreference `
                                    -WhatIfDescription "Uninstall Link2Root from $installLocation" `
                                    -Indentation ($Indentation + 3)
                                ),
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
                                    # Remove-Item -Path $installLocation -Recurse @NO_RISK_PARAMS
                                    Remove-InstallDirectory `
                                        -Path $installLocation `
                                        -Component "LocalInstall" `
                                        -Indentation ($Indentation + 2)
                                    
                                    # Write-Verbose "$(_gis ($Indentation + 2))[+] Removed Installation Files from Location: $installLocation"
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
                        Write-Verbose "$(_gis ($Indentation + 2))[-] 'LocalInstall' Component Excluded from Uninstall"
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
                    
                    if ($uninstallComponents -icontains "PowerShellModule") {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] 'PowerShellModule' Component Included in Uninstall"
            
                        [string]$modulePath = & "$PSScriptRoot\Get-Link2RootInstall.ps1" `
                            -GetModulePath `
                            -Internal:$Internal `
                            -Indentation ($Indentation + 2)
                        [string]$modulesLocation = Split-Path $modulePath -Parent
                        
                        if (Test-Path $modulePath) {
                            Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with Uninstallation of PowerShell Module..."
            
                            if ($yesToAll -or $PSCmdlet.ShouldProcess(
                                (_gvcpd `
                                    -WhatIfValue $WhatIfPreference `
                                    -WhatIfDescription "Uninstall Link2Root PowerShell Module from $modulesLocation" `
                                    -Indentation ($Indentation + 3)
                                ),
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
                                    # Remove-Item -Path $modulePath -Recurse @NO_RISK_PARAMS
                                    Remove-InstallDirectory `
                                        -Path $modulePath `
                                        -Component "PowerShellModule" `
                                        -Indentation ($Indentation + 2)
            
                                    # Write-Verbose "$(_gis ($Indentation + 2))[+] Removed PowerShell Module from Location: $modulePath"
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
                        Write-Verbose "$(_gis ($Indentation + 2))[-] 'PowerShellModule' Component Excluded from Uninstall"
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
                    [string]$username = Get-FullyQualifiedUsername

                    if ($uninstallComponents -icontains "PATHUpdate") {
                        Write-Verbose "$(_gis ($Indentation + 2))[+] 'PATHUpdate' Component Included in Uninstall"
            
                        [string[]]$userPATH = Get-UserPATH
                
                        if (Test-UserPATH -Entry $installLocation -PATH $userPATH) {
                            Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with User PATH Update..."
                            
                            if ($yesToAll -or $PSCmdlet.ShouldProcess(
                                (_gvcpd `
                                    -WhatIfValue $WhatIfPreference `
                                    -WhatIfDescription "Remove $installLocation from $username's PATH" `
                                    -Indentation ($Indentation + 3)
                                ),
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
        
                                    Write-Verbose "$(_gis ($Indentation + 2))[>] Removing Matching Entries from User PATH..."
        
                                    [string[]]$updatedPATH = $userPATH.Where({
                
                                        if ($_ -ieq $installLocation) {
                                            Write-Verbose "$(_gis ($Indentation + 3))[+] Removed Entry: $_"
                                            return $false
                                        }
                
                                        return $true
                                    
                                    });
                                    
                                    if ($EnableRollback) {
                                        [string]$rollbackFile = "$rollbackDirectory\PATHUpdate"
                                        [string]$expectedPATHHash = $updatedPATH | Get-StringHash
                                        
                                        Write-Verbose "$(_gis ($Indentation + 2))[>] Archiving User PATH for Future Rollback..."
        
                                        $expectedPATHHash | Out-File $rollbackFile
                                        Write-Verbose "$(_gis ($Indentation + 3))[#] Required PATH Hash for Rollback: $expectedPATHHash"
                                        
                                        Resolve-UserPATH $userPATH -AsString | Out-File $rollbackFile -Append -NoNewline 
                                        Write-Verbose "$(_gis ($Indentation + 2))[+] Archived User PATH for Future Rollback: $rollbackId\PATHUpdate"
                                    }
        
                                    Set-UserPATH -PATH $updatedPATH -Verbose:$VerbosePreference -Indentation ($Indentation + 3)
                                    Write-Verbose "$(_gis ($Indentation + 2))[+] Removed Matching Entries from User PATH"
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
                        Write-Verbose "$(_gis ($Indentation + 2))[-] 'PATHUpdate' Component Excluded from Uninstall"
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
                catch {
                    Remove-RollbackDirectory $rollbackDirectory -Indentation ($Indentation + 1)
                    throw $_
                }
            }
            else {
                Write-Verbose "$(_gis ($Indentation + 1))[-] User Rejected Confirmation."
                Write-Verbose "$(_gis $Indentation)[-] Link2Root Uninstallation Aborted."
            }
        
        
            # Cleanup and print and/or return the results
            [string]$rollbackHash = $null
        
            if ($success -or $failed) {
                if ($EnableRollback) {
                    Write-Verbose "$(_gis $Indentation)[>] Generating Rollback Hash..."
                    $rollbackHash = Get-FileHashRecursive `
                        -Path $rollbackDirectory `
                        -Indentation ($Indentation + 1) `
                        -Verbose:$VerbosePreference
                    Write-Verbose "$(_gis $Indentation)[+] Generated Rollback Hash: $rollbackHash"
                }
        
                Write-Verbose "$(_gis $Indentation)[+] Link2Root Uninstaller Completed Successfully"
            }
            else {
                Write-Verbose "$(_gis $Indentation)[/] No Changes Made by the Link2Root Uninstaller"
            }
            
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
            
            if ($EnableRollback) { return $rollbackHash }
            elseif ($PassThru)   { return $success -and -not $failed }
        }
        catch {
            Write-Verbose "$(_gis $Indentation)[-] Link2Root Uninstaller Failed"
            _upb -Status "Uninstallation Failed" -PercentageChange 100
            throw $_
        }
        finally {
            Remove-ProgressBar
        }
    }
    # Rollback a Previous Uninstall
    else {
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
        
            Write-Verbose "$(_gis $Indentation)[>] Running Link2Root Uninstaller Rollback..."
            Hide-ProgressBars $NoProgress
            Add-ProgressBar -Name "Rolling Back Link2Root Uninstallation..." -DefaultPercentageChange 15 -InitialSecondsRemaining 5
    
    
            # Check if Link2Root is currently installed
            # Write-Verbose "$(_gis ($Indentation + 1))[>] Checking for Rollback Eligibility..."
        
            # if (-not $Internal) {
            #     _upb -Status "Check Current Installation Status"
    
            #     if ((& "$PSScriptRoot\Test-Link2RootInstall.ps1" @installTestArgs)) {
            #         Write-Verbose "$(_gis ($Indentation + 1))[-] Ineligible for Rollback: Already Installed"
            #         Write-Verbose "$(_gis $Indentation)[-] Link2Root Uninstallation Rollback Aborted."
            #         _upb -Status "No Uninstallation Required" -PercentageChange 100
                    
            #         if (-not $NoOutput) {
            #             _wc "Link2Root" -NoNewline
            #             Write-Host " is " -NoNewline
            #             Write-Host "Already Installed!" -ForegroundColor DarkYellow
            #         }
                
            #         if ($PassThru) { return $false }
            #         else           { return }
            #     }
            # }
            # else {
            #     Write-Verbose "$(_gis ($Indentation + 2))[/] Internal Invocation: Delaying Eligibility Check"
            # }
        
            # Write-Verbose "$(_gis ($Indentation + 1))[+] Eligible for Rollback"
    
    
            # Locate the designated rollback based on the specified rollback hash
            Write-Verbose "$(_gis ($Indentation + 1))[>] Searching for Rollback '$Rollback'..."
            _upb -Status "Locate Rollback '$Rollback'"
            Optimize-Rollbacks -Indentation ($Indentation + 1)
    
            [string]$rollbackDirectory = & {
    
                $candidates = (Get-ChildItem $baseRollbackLocation | Sort-Object -Property CreationTime -Descending)
    
                if ($candidates) {
                    foreach ($candidate in $candidates) {
                        [string]$candidateHash = Get-FileHashRecursive `
                            -Path $candidate.FullName `
                            -Verbose:$VerbosePreference `
                            -Indentation ($Indentation + 3)
    
                        if ($candidateHash -eq $Rollback) {
                            Write-Verbose "$(_gis ($Indentation + 2))[+] Found Matching Rollback: $($candidate.BaseName)"
                            return $candidate.FullName
                        }
                        else {
                            Write-Verbose "$(_gis ($Indentation + 2))[-] Checked Candidate Rollback: $($candidate.BaseName)"
                        }
                    }
                }
                else {
                    Write-Verbose "$(_gis ($Indentation + 2))[-] No Rollbacks Available"
                }
    
                return $null
    
            }
    
            if ($rollbackDirectory) {
                Write-Verbose "$(_gis ($Indentation + 1))[+] Located Rollback '$Rollback': $(Split-Path $rollbackDirectory -Leaf)"
                
                [string[]]$rollbackComponents = (Get-ChildItem $rollbackDirectory).BaseName
                Write-Verbose "$(_gis ($Indentation + 1))[#] Components Included in Rollback: $($rollbackComponents -join ', ')"
    
                # if ($Internal) {
                Write-Verbose "$(_gis ($Indentation + 1))[>] Checking Rollback Eligibility..."
                _upb -Status "Check Rollback Eligibility"
                [link2rootSetupComponent[]]$conflictingComponents = & "$PSScriptRoot\Test-Link2RootInstall.ps1" `
                    -Components $rollbackComponents `
                    -PassThruType Installed `
                    @installTestArgs
    
                if ($conflictingComponents) {
                    foreach ($component in $conflictingComponents) {
                        Write-Verbose "$(_gis ($Indentation + 2))[-] Conflicting Component Install: $component"
                        _wcp -Failed
                        Write-Host "Conflicting Component Installed: " -NoNewline -ForegroundColor Red
                        _wc $component
                    }
    
                    Write-Verbose "$(_gis ($Indentation + 1))[-] Ineligible for Rollback: Conflicting Components Installed"
                    Write-Verbose "$(_gis $Indentation)[-] Link2Root Uninstallation Rollback Aborted."
                    _upb -Status "Ineligible for Rollback" -PercentageChange 100
                    
                    if (-not $NoOutput) {
                        _wc "Link2Root" -NoNewline
                        Write-Host " is " -NoNewline
                        Write-Host "Already Installed!" -ForegroundColor DarkYellow
                    }
                
                    if ($PassThru) { return $false }
                    else           { return }
                }
    
                Write-Verbose "$(_gis ($Indentation + 1))[+] Eligible for Rollback"
                # }
    
                if ($Force -or $PSCmdlet.ShouldContinue(
                    "Rollback Link2Root Uninstallation '$Rollback' for $(Get-FullyQualifiedUsername)",
                    "Confirm",
                    [ref]$yesToAll,
                    [ref]$noToAll
                )) {
                    [int]$rolledBackComponents = 0
    
                    if (-not $Force) { Write-Verbose "$(_gis ($Indentation + 1))[+] User Approved Confirmation." }
                    else             { Write-Verbose "$(_gis ($Indentation + 1))[+] Confirmation Automatically Approved via -Force Flag." }
    
                    Add-ProgressBar `
                        -Name "Rollback Component" `
                        -DefaultPercentageChange ([Math]::Round(100 / $rollbackComponents.Count)) `
                        -InitialSecondsRemaining 3
                    
                    foreach ($component in $rollbackComponents) {
                        Write-Verbose "$(_gis ($Indentation + 1))[>] Roll Back Component '$component'..."
    
                        try {
                            if ($component -ine "PATHUpdate") {
                                [string]$rolledBackDirectory = & {
                                    switch ($component) {
                                        "LocalInstall" {
                                            return $installLocation
                                        }
                                        "PowerShellModule" {
                                            return & "$PSScriptRoot\Get-Link2RootInstall.ps1" `
                                                -GetModulePath `
                                                -Internal:$Internal `
                                                -Indentation ($Indentation + 2)
                                        }
                                    }
                                }
        
                                _upb -Status $component -CurrentOperation "Restore Directory: $rolledBackDirectory"
                                Move-Item -Path "$rollbackDirectory\$Component" -Destination $rolledBackDirectory @NO_RISK_PARAMS
                                Write-Verbose "$(_gis ($Indentation + 2))[+] Restore Directory: $rolledBackDirectory"
    
                                if (-not $NoOutput) {
                                    _wcp -Success
                                    Write-Host "Successfully restored" -NoNewline -ForegroundColor Green
                                    Write-Host " the " -NoNewline
                                    _wc "Link2Root $($component -creplace "(?<!Powe)([^A-Z])([A-Z])(?!hell)","`$1 `$2")" -NoNewline
                                    Write-Host " to " -NoNewline
                                    _wp $rolledBackDirectory
                                }
                            }
                            else {
                                _upb -Status $component -CurrentOperation "Restore User PATH: $rolledBackDirectory"
                                [string[]]$fileContents = ((Get-Content "$rollbackDirectory\$Component") -split "`n")
    
                                if ($fileContents.Length -eq 2) {
                                    [string]$expectedPATHHash = $fileContents[0]
                                    [string]$rollbackPATH = $fileContents[1]
    
                                    if ((Get-UserPATH | Get-StringHash) -eq $expectedPATHHash) {
                                        Set-UserPATH `
                                            -PATH $rollbackPATH `
                                            -Verbose:$VerbosePreference `
                                            -Indentation ($Indentation + 2)
            
                                        if (-not $NoOutput) {
                                            _wcp -Success
                                            Write-Host "Successfully restored" -NoNewline -ForegroundColor Green
                                            Write-Host " the " -NoNewline
                                            _wc "Link2Root $($component -creplace "(?<!Powe)([^A-Z])([A-Z])(?!hell)","`$1 `$2")" -NoNewline
                                            Write-Host " to " -NoNewline
                                            _wp "$(Get-FullyQualifiedUsername)'s PATH"
                                        }
                                    }
                                    else {
                                        throw "User PATH has been modified since uninstallation was performed"
                                    }
                                }
                                else {
                                    throw "PATH Rollback File Data is corrupt and cannot be restored"
                                }
                            }
                            
                            Write-Verbose "$(_gis ($Indentation + 1))[+] Rolled Back Component '$component'"
                            _upb -Status $component -CurrentOperation "Operation Completed Successfully"
                            $success = $true
                            $rolledBackComponents++
                        }
                        catch {
                            Write-Verbose "$(_gis ($Indentation + 2))[-] Error: $_"
                            Write-Verbose "$(_gis ($Indentation + 1))[-] Failed to Roll Back Component '$component'"
                            $failed = $true
    
                            if (-not $NoOutput) {
                                _wcp -Success
                                Write-Host "Failed to roll back " -NoNewline -ForegroundColor Red
                                _wc "Link2Root" -NoNewline
                                Write-Host " to " -NoNewline
                                _wp $installLocation
                            }
                        }
                    }
    
                    Remove-RollbackDirectory $rollbackDirectory -Indentation ($Indentation + 1)
                    Write-Verbose "$(_gis ($Indentation + 1))[+] Components Rolled Back: $rolledBackComponents"
                    Remove-ProgressBar
                }
                else {
                    Write-Verbose "$(_gis ($Indentation + 1))[-] User Rejected Confirmation."
                    Write-Verbose "$(_gis $Indentation)[-] Link2Root Uninstallation Rollback Aborted."
                }
            }
            else {
                Write-Verbose "$(_gis ($Indentation + 1))[-] Failed to Locate Rollback '$Rollback'"
                $failed = $true
    
                if (-not $NoOutput) {
                    _wcp -Failed
                    Write-Host "Failed to Locate" -NoNewline -ForegroundColor Red
                    Write-Host " a " -NoNewline
                    _wc "Link2Root Uninstallation Rollback" -NoNewline
                    Write-Host " with a Rollback Hash of " -NoNewline
                    _wp $Rollback
                }
            }
    
    
            if ($success -or $failed) {
                Write-Verbose "$(_gis $Indentation)[+] Link2Root Uninstallation Rollback Completed Successfully"
            }
            else {
                Write-Verbose "$(_gis $Indentation)[/] No Changes Made during the Link2Root Uninstallation Rollback"
            }
    
            if (-not $NoOutput) {
                # Write-Host ""
                
                if ($success -and -not $failed) {
                    Write-Host "Successfully rolled back uninstallation of " -NoNewline -ForegroundColor Green
                    _wc "Link2Root" -NoNewline
                    Write-Host "!" -ForegroundColor Green
                }
                elseif ($success) {
                    Write-Host "Only some components of " -NoNewline -ForegroundColor DarkYellow
                    _wc "Link2Root" -NoNewline
                    Write-Host " were successfully rolled back." -ForegroundColor DarkYellow
                }
                elseif (-not $failed) {
                    Write-Host "Nothing for " -NoNewline -ForegroundColor Yellow
                    _wc "Link2Root" -NoNewline
                    Write-Host " was rolled back." -ForegroundColor Yellow
                }
                else {
                    Write-Host "Failed to roll back uninstallation of " -NoNewline -ForegroundColor Red
                    _wc "Link2Root" -NoNewline
                    Write-Host "!" -ForegroundColor Red
                }
                
                if ($success) {
                    Write-EndRestartNotice
                }
            }
    
            if ($PassThru) {
                return ($success -and -not $failed)
            }
        }
        catch {
            Write-Verbose "$(_gis $Indentation)[-] Link2Root Uninstaller Rollback Failed"
            _upb -Status "Uninstallation Rollback Failed" -PercentageChange 100
            throw $_
        }
        finally {
            Remove-ProgressBar
        }
    }
}