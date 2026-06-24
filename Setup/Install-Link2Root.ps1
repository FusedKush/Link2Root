<#
    .SYNOPSIS
    Install Link2Root for the current user

    .DESCRIPTION
    Install Link2Root on the current machine for the current user.

    Note that you will always be prompted for confirmation before
    beginning the installation. If needed, the confirmation can be
    skipped using the `-Force` switch.
    
    By default, the installation will immediately be aborted
    if the specified components have already been installed
    for the current user on the computer. To force a reinstallation
    of the designated components, use the `-Reinstall` switch.

    You can also specify which individual components for Link2Root are
    to be installed. To do so, you can either use the `-Confirm` switch
    and manually skip the necessary components, or use the `-SkipScriptInstall`,
    `-SkipModuleInstall`, and `SkipPATHUpdate` switches.

    .INPUTS
    You cannot pipe any objects to `Install-Link2Root.ps1`.

    .OUTPUTS
    None.
    By default, `Install-Link2Root.ps1` doesn't generate any output.

    .OUTPUTS
    bool.
    When the `-PassThru` switch is used, `Install-Link2Root.ps1` returns
    `$true` if the installation was successful or `$false` if it was not.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    <#
        The individual components of Link2Root to be installed.

        If no components are specified, all of the
        Default Setup Components will be installed.
    #>
    [ArgumentCompleter({
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Get-SetupComponentArgumentCompletions -Verbose:$false
        Get-SetupComponentArgumentCompletions @args
    })]
    [Parameter(Position = 0)]
    [ValidateScript({
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Test-SetupComponentParameter -Verbose:$false
        $_ | Test-SetupComponentParameter
    })]
    [string[]]$Components = (& {
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Get-SetupComponents -Verbose:$false
        Get-SetupComponents -Filter Default
    }),

    <#
        Indicates that all of the specified components of Link2Root
        should be reinstalled for the current user.

        By default and when this switch is omitted, the installation
        will immediately be aborted if all of the designed components
        for Link2Root are already installed.
    #>
    [Alias("Repair")]
    [switch]$Reinstall,
    
    <#
        Skip all confirmation prompts and immediately
        proceed with the Link2Root installation.

        If this switch is used with the `-Confirm` switch, only
        the *initial* confirmation prompt will be skipped,
        and you will still be prompted for confirmation before
        each individual component is installed.
    #>
    [switch]$Force,
    
    <#
        Indicates that no output should be printed to the terminal
        by the script.

        By default and when neither this switch nor `-Silent` are used,
        the status and results of the script are printed to the terminal.

        Has no effect on errors, verbose output, or progress bars. To control the behavior
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

        Has no effect on errors, verbose output, or progress bars created by built-in
        functions and cmdlets. To control the behavior of all PowerShell progress bars,
        use the `$ProgressPreference` automatic variable.
    #>
    [switch]$Silent,

    <#
        Indicates that this function should return a boolean value
        indicating whether or not the installation was successful.

        By default and when this switch is omitted, this function
        does not generate any output.
    #>
    [switch]$PassThru,

    <#
        Don't roll back the changes made by this script if an error occurs.

        By default and when this switch is omitted, any changes made by the
        script will be automatically rolled back if an error occurs during installation.
    #>
    [switch]$NoRollBack
)

Import-Module "$PSScriptRoot\Utils.psm1" -Verbose:$false


# Script Definitions #

<#
    An enumeration defining the available
    Installation Verbs, which are dependent on 
    the absence or presence of the `-Reinstall` switch.
#>
enum InstallVerb {
    Install
    Reinstall
}

<#
    The `InstallVerb` for the Link2Root Installer.
#>
[InstallVerb]$installerVerb = "Install"
<#
    The `InstallVerb` for the Current
    Link2Root Component being installed.
#>
[InstallVerb]$installVerb = "Install"
[string]$uninstallRollbackHash = $null

<#
    Create a new temporary directory to use
    during the Link2Root Setup.
#>
function New-TemporaryFolder {

    [CmdletBinding()]
    [OutputType([string])]
    param()

    [string]$name = (New-Guid).ToString()
    [string]$tempPath = "$(Get-TemporaryFileLocation)\Install"
    [string]$tempFolder = Join-Path $tempPath $name

    New-Item -Path $tempFolder -ItemType Directory @NO_RISK_PARAMS | Out-Null
    Write-Verbose "$(_gis ($Indentation + 2))[+] Created Temporary Directory: $name"
    return $tempFolder

}

<#
    Copy all of the files matching the specified pattern(s)
    to the designated temporary directory.
#>
function Copy-ToTemporaryFolder {

    [CmdletBinding()]
    param(
        <#
            One or more wildcard patterns specifying which files
            and directories to copy to the temporary directory.
        #>
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [SupportsWildcards()]
        [string[]]$Patterns,

        <#
            The location within the temporary directory where
            all matching files and directories are to be copied.
        #>
        [Parameter(Mandatory, Position = 1)]
        [string]$Destination,

        <#
            Rename all matching files and directories to the
            specified value.

            In general, this parameter should only be used
            when the specified `-Patterns` will only match
            a single file or directory.
        #>
        [Parameter(Position = 2)]
        [string]$Name,

        <#
            Specifies a filter to qualify the `Pattern` parameter.
            
            Filters are more efficient than other parameters. The provider applies the filter when the cmdlet
            gets the objects rather than having PowerShell filter the objects after they're retrieved.
            
            The filter string is passed to the .NET API to enumerate files.
            The API only supports * and ? wildcards.
        #>
        [SupportsWildcards()]
        [string]$Filter,

        <#
            Specifies, as a string array, an item or items that this cmdlet includes in the operation.
            
            The value of this parameter qualifies the `Pattern` parameter.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [SupportsWildcards()]
        [string[]]$Include,

        <#
            Specifies, as a string array, an item or items that this cmdlet excludes in the operation.
            
            The value of this parameter qualifies the `Pattern` parameter.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [SupportsWildcards()]
        [string[]]$Exclude,

        <#
            The inner indentation level to use for output logging.

            Applied on top of the script `-Indentation` level.
        #>
        [int]$InnerIndentation = 0
    )

    begin {
        [string[]]$allPatterns = @()
    }

    process {
        if ($null -ne $Patterns) {
            $allPatterns += $Patterns
        }
    }

    end {
        Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 3))[>] Copying Files to $Destination..."
        Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 4))[>] File Patterns:"

        foreach ($currentPattern in $allPatterns) {
            Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 5))[#] $currentPattern"
        }

        [string[]]$resolvedPaths = Get-Item $allPatterns -Filter $Filter

        Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 4))[>] Matched Files:"

        foreach ($currentPath in $resolvedPaths) {
            Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 5))[+] $currentPath"
        }

        Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 4))[>] Copying Files..."
        Add-ProgressBar -Name "Copying Files" -DefaultPercentageChange (100 / $resolvedPaths.Count)

        try {
            foreach ($resolvedPath in $resolvedPaths) {
                if (Test-Path $resolvedPath -PathType Container) {
                    [string]$newDestination = $Destination
    
                    _upb -Status $resolvedPath -CurrentOperation "Copy Directory" -PercentageChange 0
    
                    if ($Name.Trim() -ne "") { $newDestination += "\$Name" }
                    else                     { $newDestination += "\$(Split-Path $resolvedPath -Leaf)" }
    
                    Confirm-DirectoryExists -Path $newDestination -Indentation ($Indentation + $InnerIndentation + 5)                    
                    Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 5))[>] Copying Directory: $resolvedPath"
                    Copy-ToTemporaryFolder `
                        -Patterns (Get-ChildItem $resolvedPath -Filter $Filter).FullName `
                        -Destination $newDestination `
                        -Filter $Filter `
                        -Include $Include `
                        -Exclude $Exclude `
                        -InnerIndentation ($InnerIndentation + 3)
                    Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 5))[+] Copied Directory: $resolvedPath"
                    _upb -Status $resolvedPath -CurrentOperation "Directory Copied"
                }
                else {
                    $filePatternTestArgs = @{
                        Path = $resolvedPath
                        Filter = $Filter
                        Include = $Include
                        Exclude = $Exclude
                        Verbose = $VerbosePreference
                        Indentation = ($Indentation + $InnerIndentation + 5)
                    }

                    if (Test-FilePattern @filePatternTestArgs) {
                        [string]$newDestination = $Destination
    
                        _upb -Status $resolvedPath -CurrentOperation "Copy File" -PercentageChange 0
    
                        if ($Name.Trim() -ne "") {
                            $newDestination += "\$Name"
                            Write-Verbose "  New Name: $Name"
                        }
    
                        Copy-Item -Path $resolvedPath -Destination $newDestination @NO_RISK_PARAMS | Out-Null
                        Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 5))[+] Copied File: $resolvedPath"
                        _upb -Status $resolvedPath -CurrentOperation "File Copied"
    
                        if (-not (Test-Path $Destination)) {
                            Write-Verbose "$(_gis -Indentation 2)[-] File: $resolvedPath"
                            throw "Failed to Copy $resolvedPath to $Destination"
                        }
                    }
                }
            }

            Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 4))[+] Files Copied Successfully"
            Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 3))[+] Successfully Copied Files to $Destination"
        }
        catch {
            throw $_
        }
        finally {
            # Ensure the Progress Bar used to visualize
            # the progress of copying files to the temporary folder
            # is always removed at the end.
            Remove-ProgressBar
        }
    }

}

<#
    Move a temporary directory to the final installation location.
#>
function Move-TemporaryFolder {

    [CmdletBinding()]
    [OutputType([string])]
    param(
        <#
            The path to the temporary directory being moved.
        #>
        [Parameter(Mandatory, Position = 0)]
        [string]$TempFolder,

        <#
            THe path to the installation location the
            temporary directory is being moved to.

            If the specified location already exists, the `-Name`
            parameter must be specified to provide a name
            for the newly-moved directory. However, if the specified
            location does not currently exist, then the specified
            path will be used instead.
        #>
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]$Destination,

        <#
            The name of the newly-moved directory.

            Must be specified if the designated `-Destination` already exists.
            
        #>
        [Parameter(Position = 3)]
        [string]$Name,

        <#
            Indicates that this function should return the full path
            to the newly-moved directory on success.

            By default and when this switch is omitted, this function
            does not generate any output.
        #>
        [switch]$PassThru
    )

    if ((Test-Path $Destination) -and $null -eq $Name) {
        throw "The -Name parameter must be specified to Move-TemporaryFolder when the -Destination already exists."
    }

    [string]$fullDestPath = $Destination

    if ($Name.Trim() -ne "") {
        $fullDestPath = Join-Path $fullDestPath $Name
    }

    Move-Item -Path $tempFolder -Destination $fullDestPath @NO_RISK_PARAMS | Out-Null
    Write-Verbose "$(_gis ($Indentation + 2))[+] Files Copied to Installation Location: $fullDestPath"

    if (-not (Test-Path $fullDestPath)) {
        throw "Failed to Move $tempFolder to $fullDestPath"
    }

    if ($PassThru) {
        return Resolve-Path $fullDestPath
    }

}

<#
    Remove a new temporary directory used
    during the Link2Root Setup.
#>
function Remove-TemporaryFolder {

    [CmdletBinding()]
    param(
        <#
            The path to the temporary directory being removed.
        #>
        [CmdletBinding()]
        [Parameter(Mandatory, Position = 0)]
        [string]$TempFolder
    )

    if ($TempFolder -ilike "$([System.IO.Path]::GetTempPath())*" -and (Test-Path $tempFolder)) {
        Remove-Item $tempFolder -Recurse -Force @NO_RISK_PARAMS
        Write-Verbose "$(_gis -Indentation 1)[+] Removed Temporary Directory: $tempFolder"

        if (Test-Path $tempFolder) {
            Write-Warning "Failed to Remove Temporary Directory: $(Resolve-Path $tempFolder)"
        }
    }

}

<#
    Get the Current Installer or Install Verb.
#>
function Get-InstallVerb {

    [CmdletBinding(DefaultParameterSetName = "AsEnum")]
    [OutputType([InstallVerb], ParameterSetName = "AsEnum")]
    [OutputType([string], ParameterSetName = "AsString")]
    param(
        <#
            Indicates that the Installer Verb should be
            returned instead of the Current Install Verb.

            By default and if omitted, the Install Verb
            for the current Link2Root Component being installed
            is returned. 
        #>
        [Alias("Main")]
        [switch]$Installer,

        <#
            Indicates that the Installation or Install Verb
            should be returned as a lowercase string.

            By default and if neither this nor the `-AsString` switch
            are used, an `InstallVerb` enumeration member will be returned.
        #>
        [Alias("lc")]
        [Parameter(ParameterSetName = "AsString")]
        [switch]$Lowercase,

        <#
            Indicates that the Installation or Install Verb
            should be returned as a string.

            By default and if neither this nor the `Lowercase` switch
            are used, an `InstallVerb` enumeration member will be returned.

            This switch is implied if `-Lowercase` is used.
        #>
        [Parameter(ParameterSetName = "AsString")]
        [switch]$AsString
    )

    [InstallVerb]$verb = & {
        if (-not $Installer) { return $installVerb }
        else                 { return $installerVerb }
    }

    if ($Lowercase -or $AsString) { return $verb.ToString().ToLower() }
    else                          { return $verb }

}

<#
    Set the Current Installer or Install Verb.
#>
function Set-InstallVerb {

    param(
        <#
            The new Current Installation or Install Verb.
        #>
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [InstallVerb]$Verb,

        <#
            Indicates that the Installer Verb should be
            updated instead of the Current Install Verb.

            By default and if omitted, the Install Verb
            for the current Link2Root Component being installed
            is modified.
        #>
        [Alias("Main")]
        [switch]$Installer
    )

    if (-not $Installer) { $script:installVerb = $Verb }
    else                 { $script:installerVerb = $Verb }

}


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
        Internal = $true
        Indentation = ($Indentation + 2)
    }

    Write-Verbose "$(_gis $Indentation)[>] Running Link2Root Installer..."
    Hide-ProgressBars $NoProgress
    Add-ProgressBar -Name "Installing Link2Root" -DefaultPercentageChange 25 -InitialSecondsRemaining 5
    _upb -Status "Check Current Installation Status"


    # Check if Link2Root is already installed
    Write-Verbose "$(_gis ($Indentation + 1))[>] Checking for Installation Eligibility..."
    
    if ((& "$PSScriptRoot\Test-Link2RootInstall.ps1" @installTestArgs) -and -not $Reinstall) {
        Write-Verbose "$(_gis ($Indentation + 1))[-] Ineligible for Installation"
        Write-Verbose "$(_gis $Indentation)[-] Link2Root Installation Aborted."
        _upb -Status "No Installation Required" -PercentageChange 100

        if (-not $NoOutput) {
            _wc "Link2Root" -NoNewline
            Write-Host " is " -NoNewline
            Write-Host "Already Installed!" -ForegroundColor DarkYellow
        }
    
        if ($PassThru) {
            return $false
        }
        else {
            return
        }
    }

    Write-Verbose "$(_gis ($Indentation + 1))[+] Eligible for Installation"
    
    try {
        [string]$installLocation = & "$PSScriptRoot\Get-Link2RootInstall.ps1"
        [string]$modulePath = & "$PSScriptRoot\Get-Link2RootInstall.ps1" -GetModulePath -Indentation ($Indentation + 1)
        [string]$modulesLocation = Split-Path $modulePath -Parent
        [string]$psFolder = Split-Path $modulesLocation -Parent
        [string]$psFolderName = Split-Path $psFolder -Leaf
        [string]$username = Get-FullyQualifiedUsername
        [bool]$success = $false
        [bool]$yesToAll = $false
        [bool]$noToAll = $false

        if ($Reinstall -and ((Test-Path $installLocation) -or (Test-Path $modulePath))) {
            Set-InstallVerb Reinstall
        }


        # Prompt for confirmation unless -Force is used and
        # proceed with the installation of Link2Root
        Write-Verbose "$(_gis ($Indentation + 1))[>] Requesting User Confirmation to Proceed with $(Get-InstallVerb -Installer)ation..."
    
        if ($Force -or $PSCmdlet.ShouldContinue("$(Get-InstallVerb -Installer) Link2Root for $(Get-FullyQualifiedUsername)", "Confirm", [ref]$yesToAll, [ref]$noToAll)) {
            if (-not $Force)    { Write-Verbose "$(_gis ($Indentation + 1))[+] User Approved Confirmation." }
            else                { Write-Verbose "$(_gis ($Indentation + 1))[+] Confirmation Automatically Approved via -Force Flag." }

            [bool]$scriptIsInstalled = Test-Path $installLocation
            [bool]$moduleIsInstalled = Test-Path $modulePath
            [bool]$isAddedToPATH = Test-UserPATH -Entry $installLocation -NoProgress
            

            # Install the script in the current user's local appdata folder
            Write-Verbose "$(_gis ($Indentation + 1))[>] Copy Link2Root Files..."
            _upb -Status "Copy Link2Root Files" -CurrentOperation "Check Install Status" -PercentageChange 0
            (& {
                if (-not $scriptIsInstalled) { return "Install" }
                else                         { return "Reinstall" }
            }) | Set-InstallVerb

            if ($Components -icontains "LocalInstall") {
                Write-Verbose "$(_gis ($Indentation + 2))[+] 'LocalInstall' Component Included in Install"

                if (-not $scriptIsInstalled -or $Reinstall) {
                    Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with $(Get-InstallVerb -Installer)ation of Link2Root Files..."
            
                    if ($yesToAll -or $PSCmdlet.ShouldProcess(
                        (_gvcpd `
                            -WhatIfValue $WhatIfPreference `
                            -WhatIfDescription "$(Get-InstallVerb) Link2Root in $installLocation" `
                            -Indentation ($Indentation + 3)
                        ),
                        "$(Get-InstallVerb) Link2Root in $installLocation",
                        "Confirm`nAre you sure you want to perform this action?"
                    )) {
                        [string]$tempFolder = ""

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
                            # Create a temporary folder to copy the install files to
                            _upb -Status "Copy Link2Root Files" -CurrentOperation "Create Temporary Folder" -PercentageChange 5
    
                            $tempFolder = New-TemporaryFolder
                            [hashtable[]]$copyFileArgs = @(
                                @{
                                    Patterns = @(
                                        "$PSScriptRoot\..\Link*Root.*",
                                        "$PSScriptRoot\..\README.md"
                                    )
                                    Destination = $tempFolder
                                },
                                @{
                                    Patterns = $PSScriptRoot
                                    Destination = $tempFolder
                                    Name = "Installation"
                                    Exclude = $SETUP_FOLDER_IGNORED_FILES
                                },
                                @{
                                    Patterns = "$PSScriptRoot\..\Scripts"
                                    Destination = $tempFolder
                                }
                            )
                
                            
                            # Copy the install files to the temporary folder
                            try {
                                Write-Verbose "$(_gis ($Indentation + 2))[>] Copy Installation Files to Temporary Directory..."

                                foreach ($copyArgs in $copyFileArgs) {
                                    Copy-ToTemporaryFolder @copyArgs
                                }

                                Write-Verbose "$(_gis ($Indentation + 2))[+] Copied Installation Files to Temporary Directory"
                            }
                            catch {
                                throw $_
                            }
                            finally {
                                _upb -Status "Copy Link2Root Files" -CurrentOperation "Copy Installation Files" -PercentageChange 15
                            }
    

                            # Validate the integrity of the copied files
                            _upb -Status "Copy Link2Root Files" -CurrentOperation "Validate File Integrity" -PercentageChange 5
                            Assert-InstallIntegrity `
                                -Source "$PSScriptRoot/../" `
                                -Install $tempFolder `
                                -Exclude $SETUP_FOLDER_IGNORED_FILES `
                                -Verbose:$VerbosePreference `
                                -Indentation ($Indentation + 2)
                             
                            
                            # Remove existing install files if necessary
                            if ($scriptIsInstalled) {
                                Write-Verbose "$(_gis ($Indentation + 2))[>] Removing Existing Installation Files for Reinstall..."
                                _upb -Status "Copy Link2Root Files" -CurrentOperation "Remove Existing Files" -PercentageChange 0
                                & "$PSScriptRoot\Uninstall-Link2Root.ps1" `
                                    -Reinstall `
                                    -Force `
                                    -Components LocalInstall `
                                    -NoOutput `
                                    -NoProgress:$NoProgress `
                                    -Verbose:$VerbosePreference `
                                    -Indentation ($Indentation + 3)
                                Write-Verbose "$(_gis ($Indentation + 2))[+] Removed Existing Installation Files for Reinstall"
                            }


                            # Move the temporary directory to the final install location
                            _upb -Status "Copy Link2Root Files" -CurrentOperation "Finalize Changes" -PercentageChange 15
                            Move-TemporaryFolder -TempFolder $tempFolder -Destination $installLocation
                            
                            Write-Verbose "$(_gis ($Indentation + 1))[+] Link2Root Files Copied"
                            _upb -Status "Copy Link2Root Files" -CurrentOperation "Operation Completed Successfully" -PercentageChange 10
                            $success = $true

                            if (-not $NoOutput) {
                                _wcp -Success
                                Write-Host "Successfully $(Get-InstallVerb -lc)ed " -NoNewline -ForegroundColor Green
                                _wc "Link2Root" -NoNewline
                                Write-Host " in " -NoNewline
                                _wp $installLocation
                            }
                        }
                        catch {
                            Write-Verbose "$(_gis ($Indentation + 2))[-] Failed to Copy Installation Files"
                            Write-Verbose "$(_gis ($Indentation + 1))[-] Link2Root Files were NOT Copied"
                            _upb -Status "Copy Link2Root Files" -CurrentOperation "Operation Failed" -PercentageChange 100
                            
                            if (-not $NoOutput) {
                                _wcp -Failed
                                Write-Host "Failed to $(Get-InstallVerb -lc) " -NoNewline -ForegroundColor Red
                                _wc "Link2Root" -NoNewline
                                Write-Host " in " -NoNewline
                                _wp $installLocation
                            }
    
                            throw $_
                        }
                        finally {
                            # Ensure the temporary directory is always removed at the end.
                            if ($null -ne $tempFolder) {
                                Remove-TemporaryFolder $tempFolder
                            }
                        }
                    }
                    elseif (-not $WhatIfPreference) {
                        Write-Verbose "$(_gis ($Indentation + 3))[-] Confirmation NOT Approved"
                        Write-Verbose "$(_gis ($Indentation + 2))[-] User Rejected Confirmation"
                        Write-Verbose "$(_gis ($Indentation + 1))[-] Link2Root Files were NOT Copied"
                        _upb -Status "Copy Link2Root Files" -CurrentOperation "Operation Skipped"
                        
                        if (-not $NoOutput) {
                            _wcp
                            Write-Host "Skipped $(Get-InstallVerb -lc)ation" -NoNewline -ForegroundColor DarkYellow
                            Write-Host " of " -NoNewline
                            _wc "Link2Root" -NoNewline
                            Write-Host " in " -NoNewline
                            _wp $installLocation
                        }
                    }
                }
                else {
                    Write-Verbose "$(_gis ($Indentation + 2))[/] Existing Installation Files Found"
                    Write-Verbose "$(_gis ($Indentation + 1))[+] Link2Root Files Copied Successfully"
                    _upb -Status "Copy Link2Root Files" -CurrentOperation "No Action Required"
                    
                    if (-not $NoOutput) {
                        _wcp
                        _wc "Link2Root" -NoNewline
                        Write-Host " is " -NoNewline
                        Write-Host "already installed" -NoNewline -ForegroundColor DarkYellow
                        Write-Host " in " -NoNewline
                        _wp $installLocation
                    }
                }
            }
            else {
                Write-Verbose "$(_gis ($Indentation + 2))[-] 'LocalInstall' Component Excluded from Install"
                Write-Verbose "$(_gis ($Indentation + 1))[-] Link2Root Files were NOT Copied"
                _upb -Status "Copy Link2Root Files" -CurrentOperation "Action Skipped"

                if (-not $NoOutput) {
                     _wcp
                    Write-Host "Skipped $(Get-InstallVerb -lc)ation" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " of " -NoNewline
                    _wc "Link2Root" -NoNewline
                    Write-Host " in " -NoNewline
                    _wp $installLocation
                }
            }
            

            # Install the module in the current user's PowerShell Modules folder
            Write-Verbose "$(_gis ($Indentation + 1))[>] Install PowerShell Module..."
            _upb -Status "Install PowerShell Module" -CurrentOperation "Check Install Status" -PercentageChange 0
            (& {
                if (-not $moduleIsInstalled) { return "Install" }
                else                         { return "Reinstall" }
            }) | Set-InstallVerb

            if ($Components -icontains "PowerShellModule") {
                Write-Verbose "$(_gis ($Indentation + 2))[+] 'PowerShellModule' Component Included in Install"

                if (-not $moduleIsInstalled -or $Reinstall) {
                    Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with $(Get-InstallVerb -Installer)ation of PowerShell Module..."
            
                    if ($yesToAll -or $PSCmdlet.ShouldProcess(
                        (_gvcpd `
                            -WhatIfValue $WhatIfPreference `
                            -WhatIfDescription "$(Get-InstallVerb) Link2Root PowerShell Module in $modulesLocation" `
                            -Indentation ($Indentation + 3)
                        ),
                        "$(Get-InstallVerb) Link2Root PowerShell Module in $modulesLocation",
                        "Confirm`nAre you sure you want to perform this action?"
                    )) {
                        [string]$tempFolder = ""

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
                            [hashtable]$testFileArgs = @{
                                ItemType = "File"
                                Path = [System.Environment]::GetFolderPath("MyDocuments")
                                Name = "$(New-GUID).test.tmp"
                                ErrorAction = "SilentlyContinue"
                            }
                            
                            
                            # Create a temporary folder to copy the module files to
                            _upb -Status "Install PowerShell Module" -CurrentOperation "Create Temporary Folder" -PercentageChange 5
                            $tempFolder = New-TemporaryFolder
    

                            # Copy the module files to the temporary folder
                            Write-Verbose "$(_gis ($Indentation + 2))[>] Copy Installation Files to Temporary Directory..."
                            _upb -Status "Install PowerShell Module" -CurrentOperation "Copy PowerShell Module Files" -PercentageChange 5
                            Copy-ToTemporaryFolder -Patterns "$PSScriptRoot\..\Link2Root.ps?1" -Destination $tempFolder
                            Write-Verbose "$(_gis ($Indentation + 2))[+] Copied Installation Files to Temporary Directory"
                            
                            
                            # Verify the integrity of the copied module files
                            _upb -Status "Install PowerShell Module" -CurrentOperation "Verify File Integrity" -PercentageChange 5
                            Assert-InstallIntegrity `
                                -Source "$PSScriptRoot/../" `
                                -Install $tempFolder `
                                -Filter "Link2Root.ps?1" `
                                -Verbose:$VerbosePreference `
                                -Indentation ($Indentation + 2)
                            

                            # Determine if we can write to the /Documents folder or not
                            if ($testFile = (New-Item @testFileArgs @NO_RISK_PARAMS)) {
                                Write-Verbose "$(_gis ($Indentation + 2))[+] Permissions Sufficient to make changes to Documents Directory"
                                Remove-Item -Path $testFile @NO_RISK_PARAMS


                                # Locate where the PowerShell Modules are located for the current user
                                Write-Verbose "$(_gis ($Indentation + 2))[>] Locating PowerShell Modules Directory..."

                                # Create the missing PowerShell Modules folder if necessary
                                if (-not (Test-Path $modulesLocation)) {
                                    Write-Verbose "$(_gis ($Indentation + 3))[-] Existing PowerShell Modules Directory NOT Found"
                                    _upb -Status "Install PowerShell Module" -CurrentOperation "Create PowerShell Folders" -PercentageChange 0
            
                                    Confirm-DirectoryExists $psFolder -MaxDepth 2 -Indentation ($Indentation + 3)
                                }
                                else {
                                    Write-Verbose "$(_gis ($Indentation + 3))[+] Existing PowerShell Modules Directory FOUND"
                                }

                                Write-Verbose "$(_gis ($Indentation + 2))[+] PowerShell Modules Directory Located: $modulesLocation"
                    

                                # Remove the existing module files if needed
                                if ($moduleIsInstalled) {
                                    Write-Verbose "$(_gis ($Indentation + 2))[>] Removing Existing PowerShell Module Files for Reinstall..."
                                    _upb -Status "Install PowerShell Module" -CurrentOperation "Remove Existing Files" -PercentageChange 0
                                    & "$PSScriptRoot\Uninstall-Link2Root.ps1" `
                                        -Reinstall `
                                        -Components PowerShellModule `
                                        -NoOutput `
                                        -NoProgress:$NoProgress `
                                        -Force `
                                        -Verbose:$VerbosePreference `
                                        -Indentation ($Indentation + 3)
                                    Write-Verbose "$(_gis ($Indentation + 2))[+] Removed Existing PowerShell Module Files for Reinstall"
                                }


                                # Move the temporary folder to the final module location
                    
                                _upb -Status "Install PowerShell Module" -CurrentOperation "Finalize Changes" -PercentageChange 5
                                Move-TemporaryFolder -TempFolder $tempFolder -Destination $modulePath
                                $success = $true
    
                                Write-Verbose "$(_gis ($Indentation + 1))[+] PowerShell Module Installed"
                                _upb -Status "Install PowerShell Module" -CurrentOperation "Operation Completed Successfully" -PercentageChange 5
                    
                                if (-not $NoOutput) {
                                    _wcp -Success
                                    Write-Host "Successfully $(Get-InstallVerb -lc)ed" -NoNewline -ForegroundColor Green
                                    Write-Host " the " -NoNewline
                                    _wc "Link2Root PowerShell Module" -NoNewline
                                    Write-Host " in " -NoNewline
                                    _wp $modulePath
                                }
                            }
                            else {
                                [string]$desktop = ([System.Environment]::GetFolderPath("Desktop"))
                                [string]$desktopCopyPath = "$desktop\$psFolderName"
    
                                if (-not $NoOutput) {
                                    Write-Warning "PowerShell does not have permission to modify $psFolder. This often caused by Anti-Virus Software or Windows Security's `"Controlled Folder Access`" option."
                                }
                            
                                if (-not (Test-Path $desktopCopyPath)) {
                                    if ($Force -or $yesToAll -or $PSCmdlet.ShouldContinue(
                                        "You will have to manually move the directory into your /Documents folder to $(Get-InstallVerb -lc) the PowerShell Module.",
                                        "Do you want to create the PowerShell Module Folder on the Desktop?",
                                        [ref]$yesToAll,
                                        [ref]$noToAll
                                    )) {
                                        Confirm-DirectoryExists -Path $desktopCopyPath -MaxDepth 2 -Indentation ($Indentation + 3)
        
                                        Move-TemporaryFolder `
                                            -TempFolder $tempFolder `
                                            -Destination $desktopCopyPath `
                                            -Name "Link2Root" `
                                            -PassThru |
                                            Assert-InstallIntegrity `
                                                -Source "$PSScriptRoot/../" `
                                                -Filter "Link2Root.ps?1" `
                                                -Verbose:$VerbosePreference
                                    }
                                }
                                else {
                                    Write-Verbose "PowerShell Module Folder already exists at $(Resolve-Path "$desktop\$psFolderName")"
                                }
    
                                _upb -Status "Update User PATH" -CurrentOperation "Operation Completed with Warnings" -PercentageChange 15
    
                                if (-not $NoOutput) {
                                    _wcp
                                    _wc "Link2Root PowerShell Module" -NoNewline
                                    Write-Host " is " -NoNewline
                                    Write-Host "Pending Manual $(Get-InstallVerb)ation" -NoNewline -ForegroundColor DarkYellow
                                    Write-Host " from " -NoNewline
                                    _wp "$desktop\$psFolderName"
                                    Write-Host " to " -NoNewline
                                    _wp $psFolder
                                }
                            }    
                        }
                        catch {
                            Write-Verbose "$(_gis ($Indentation + 2))[-] Failed to Install PowerShell Module"
                            Write-Verbose "$(_gis ($Indentation + 1))[-] PowerShell Module was NOT Installed"
                            _upb -Status "Install PowerShell Module" -CurrentOperation "Operation Failed" -PercentageChange 100
                            
                            if (-not $NoOutput) {
                                _wcp -Success
                                Write-Host "Failed to $(Get-InstallVerb -lc)" -NoNewline -ForegroundColor Red
                                Write-Host " the " -NoNewline
                                _wc "Link2Root PowerShell Module" -NoNewline
                                Write-Host " in " -NoNewline
                                _wp $modulePath
                            }
    
                            throw $_
                        }
                        finally {
                            # Ensure the temporary directory is always removed at the end.
                            if ($null -ne $tempFolder) {
                                Remove-TemporaryFolder $tempFolder
                            }
                        }
                    }
                    elseif (-not $WhatIfPreference) {
                        Write-Verbose "$(_gis ($Indentation + 3))[-] Confirmation NOT Approved"
                        Write-Verbose "$(_gis ($Indentation + 2))[-] User Rejected Confirmation"
                        Write-Verbose "$(_gis ($Indentation + 1))[-] PowerShell Module was NOT Installed"
                        _upb -Status "Install PowerShell Module" -CurrentOperation "Operation Skipped"
                        
                        if (-not $NoOutput) {
                            _wcp
                            Write-Host "Skipped $(Get-InstallVerb -lc)ation" -NoNewline -ForegroundColor DarkYellow
                            Write-Host " of the " -NoNewline
                            _wc "Link2Root PowerShell Module" -NoNewline
                            Write-Host " in " -NoNewline
                            _wp $installLocation
                        }
                    }
                }
                else {
                    Write-Verbose "$(_gis ($Indentation + 2))[/] Existing PowerShell Module Files Found"
                    Write-Verbose "$(_gis ($Indentation + 1))[+] PowerShell Module Installed Successfully"
                    _upb -Status "Install PowerShell Module" -CurrentOperation "No Action Required"
                    
                    if (-not $NoOutput) {
                        _wcp
                        Write-Host "The " -NoNewline
                        _wc "Link2Root PowerShell Module" -NoNewline
                        Write-Host " is " -NoNewline
                        Write-Host "already installed" -NoNewline -ForegroundColor DarkYellow
                        Write-Host " in " -NoNewline
                        _wp $modulePath
                    }
                }
            }
            else {
                Write-Verbose "$(_gis ($Indentation + 2))[-] 'PowerShellModule' Component Excluded from Install"
                Write-Verbose "$(_gis ($Indentation + 1))[-] PowerShell Module was NOT Installed"
                _upb -Status "Install PowerShell Module" -CurrentOperation "Action Skipped"

                if (-not $NoOutput) {
                     _wcp
                    Write-Host "Skipped $(Get-InstallVerb -lc)ation" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " of the " -NoNewline
                    _wc "Link2Root PowerShell Module" -NoNewline
                    Write-Host " in " -NoNewline
                    _wp $installLocation
                }
            }
    
            # Update the User's PATH
            Write-Verbose "$(_gis ($Indentation + 1))[>] Update User PATH..."
            _upb -Status "Update User PATH" -CurrentOperation "Check Install Status" -PercentageChange 0
            [string]$installVerb = & {
                if (-not $isAddedToPATH) { return "Add" }
                else                     { return "Re-Add" }
            }
            
            if ($Components -icontains "PATHUpdate") {
                Write-Verbose "$(_gis ($Indentation + 2))[+] 'PATHUpdate' Component Included in Install"

                if (-not $isAddedToPATH -or $Reinstall) {
                    Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with Modifying User PATH..."
                    
                    if ($yesToAll -or $PSCmdlet.ShouldProcess(
                        (_gvcpd `
                            -WhatIfValue $WhatIfPreference `
                            -WhatIfDescription "${installVerb} Link2Root to $username's PATH" `
                            -Indentation ($Indentation + 3)
                        ),
                        "$installVerb $installLocation to $username's PATH",
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

                        # Remove existing PATH Entries if any are present
                        if ($isAddedToPATH) {
                            Write-Verbose "$(_gis ($Indentation + 2))[>] Removing Link2Root from $username's PATH for Reinstall..."
                            _upb -Status "Update User PATH" -CurrentOperation "Remove Existing PATH Entry" -PercentageChange 0
                            & "$PSScriptRoot\Uninstall-Link2Root.ps1" `
                                -Reinstall `
                                -Force `
                                -Components PATHUpdate `
                                -NoOutput `
                                -NoProgress:$NoProgress `
                                -Verbose:$VerbosePreference `
                                -Indentation ($Indentation + 3)
                            Write-Verbose "$(_gis ($Indentation + 2))[+] Removed Link2Root from $username's PATH for Reinstall"
                        }
        
                        # Update the user's PATH
                        _upb -Status "Update User PATH" -CurrentOperation "Add PATH Entry" -PercentageChange 10
                        Set-UserPATH `
                            -PATH ((Get-UserPATH) + @($installLocation)) `
                            -Verbose:$VerbosePreference `
                            -Indentation ($Indentation + 2)

                        Write-Verbose "$(_gis ($Indentation + 1))[+] User PATH Updated"
                        _upb -Status "Update User PATH" -CurrentOperation "Operation Completed Successfully" -PercentageChange 15
                        $success = $true
        
                        if (-not $NoOutput) {
                            _wcp -Success
                            Write-Host "Successfully ${installVerb}ed " -NoNewline -ForegroundColor Green
                            _wc "Link2Root" -NoNewline
                            Write-Host " to " -NoNewline
                            _wp "$username's PATH"
                        }
                    }
                    elseif (-not $WhatIfPreference) {
                        Write-Verbose "$(_gis ($Indentation + 3))[-] Confirmation NOT Approved"
                        Write-Verbose "$(_gis ($Indentation + 2))[-] User Rejected Confirmation"
                        Write-Verbose "$(_gis ($Indentation + 1))[-] User PATH was NOT Modified"
                        _upb -Status "Update User PATH" -CurrentOperation "Operation Skipped" -PercentageChange 25
    
                        if (-not $NoOutput) {
                            _wcp
                            Write-Host "Skipped $($installVerb.ToLower())ing " -NoNewline -ForegroundColor DarkYellow
                            _wc "Link2Root" -NoNewline
                            Write-Host " to " -NoNewline
                            _wp "$username's PATH"
                        }
                    }
                }
                else {
                    Write-Verbose "$(_gis ($Indentation + 2))[/] Existing PATH Entries Found"
                    Write-Verbose "$(_gis ($Indentation + 1))[+] User PATH Successfully Modified"
                    _upb -Status "Update User PATH" -CurrentOperation "No Action Required" -PercentageChange 25
                    
                    if (-not $NoOutput) {
                        _wcp
                        _wc "Link2Root" -NoNewline
                        Write-Host " has " -NoNewline
                        Write-Host "already been added" -NoNewline -ForegroundColor DarkYellow
                        Write-Host " to " -NoNewline
                        _wp "$username's PATH"
                    }
                }
            }
            else {
                Write-Verbose "$(_gis ($Indentation + 2))[-] 'PATHUpdate' Component Excluded from Install"
                Write-Verbose "$(_gis ($Indentation + 1))[-] User PATH was NOT Modified"
                _upb -Status "Install PowerShell Module" -CurrentOperation "Action Skipped"

                if (-not $NoOutput) {
                     _wcp
                    Write-Host "Skipped $($installVerb.ToLower())ing " -NoNewline -ForegroundColor DarkYellow
                    _wc "Link2Root" -NoNewline
                    Write-Host " to " -NoNewline
                    _wp "$username's PATH"
                }
            }


            if ($success)   { Write-Verbose "$(_gis $Indentation)[+] Link2Root Installer Completed Successfully" }
            else            { Write-Verbose "$(_gis $Indentation)[/] No Changes Made by the Link2Root Installer" }
        }
        else {
            Write-Verbose "$(_gis ($Indentation + 1))[-] User Rejected Confirmation."
            Write-Verbose "$(_gis $Indentation)[-] Link2Root Installation Aborted."
        }


        # Cleanup and print and/or return the results
        _upb -Status "Installation Complete" -PercentageChange 100
    
        if (-not $NoOutput) {
            # Write-Host ""
    
            if ($success) {
                Write-Host "Successfully $(Get-InstallVerb -Installer -Lowercase)ed " -NoNewline -ForegroundColor Green
                _wc "Link2Root" -NoNewline
                Write-Host "!" -ForegroundColor Green
                Write-EndRestartNotice
            }
            else {
                Write-Host "Nothing for " -NoNewline -ForegroundColor Yellow
                _wc "Link2Root" -NoNewline
                Write-Host " was $(Get-InstallVerb -Installer -Lowercase)ed." -ForegroundColor Yellow
            }
        }
        if ($PassThru) {
            return $true
        }
    }
    catch {
        _upb -Status "Installation Failed" -PercentageChange 100

        if (-not $NoOutput) {
            Write-Host ""
            Write-Host "Failed to $(Get-InstallVerb -Installer -Lowercase) " -NoNewline -ForegroundColor Red
            _wc "Link2Root" -NoNewline
            Write-Host "!" -ForegroundColor Red
        }
    
        if ($success -and -not $NoRollBack -and -not $Reinstall) {
            Write-Host "Rolling back changes..." -ForegroundColor DarkYellow
            & "$PSScriptRoot\Uninstall-Link2Root.ps1" -Rollback -Silent -Force -Verbose:$VerbosePreference
        }
    
        if (-not $NoOutput) {
            Write-Host ""
        }
    
        if ($PassThru) {
            if (-not $NoOutput) {
                Write-Host $_ -ForegroundColor Red
            }
    
            return $false
        }
        else {
            throw $_
        }
    }
}
catch {
    throw $_
}
finally {
    # Ensure the Main Installation Progress Bar is
    # always removed at the end.
    Remove-ProgressBar
}