<#
    .SYNOPSIS
    Install Link2Root for the current user

    .DESCRIPTION
    Install Link2Root on the current machine for the current user.

    By default, the installation will immediately be aborted
    if the specified components have already been installed
    for the current user on the computer. To force a reinstallation
    of the designated components, use the `-Reinstall` switch.

    Note that you will always be prompted for confirmation before
    beginning the installation. If needed, you can skip the confirmation
    using the `-Force` switch.

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
#>#>
[CmdletBinding(DefaultParameterSetName = "WithPATHUpdate", SupportsShouldProcess)]
param(
    <#
        Skip the installation of Link2Root in the
        current user's `AppData/Local` folder.

        Using this option will prevent you from being able to use
        Link2Root without having to move or navigate to the
        downloaded `Link2Root/` folder.

        When this switch is used, `-SkipPATHUpdate` is implicitly
        included as well.
    #>
    [switch]$SkipScriptInstall,
    
    <#
        Skip the installation of the Link2Root PowerShell Module
        in the current user's PowerShell Modules.

        Using this option will prevent you from being able to use
        `Link2Root` and `LinkThis2Root` without importing them into
        the PowerShell session or script.
    #>
    [switch]$SkipModuleInstall,
    
    <#
        Skip updating the current user's `PATH` to
        add the Link2Root Installation Directory.

        Using this option will prevent you from being able to use
        the `Link2Root` command without having to move or navigate to
        the downloaded `Link2Root/` folder.

        This switch has no effect when the `-SkipScriptInstall` switch is used.
    #>
    [switch]$SkipPATHUpdate,

    <#
        Indicates that all of the specified components of Link2Root
        should be reinstalled for the current user.

        By default and when this switch is omitted, this installation
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
        Suppress all non-error output.

        By default and when this switch is omitted, information will
        be output to the host indicating the progress and status
        of the installation and the individual components for Link2Root.
    #>
    [Parameter(ParameterSetName = "WithoutOutputOrProgress", Mandatory)]
    [switch]$Silent,
    
    [Parameter(ParameterSetName = "WithoutOutput", Mandatory)]
    [switch]$NoOutput,

    [Alias("HideProgress")]
    [Parameter(ParameterSetName = "WithOutput")]
    [Parameter(ParameterSetName = "WithoutOutput")]
    [switch]$NoProgress,

    <#
        Indicates that this function should return a boolean value
        indicating whether or not the installation was successful.

        By default and when this switch is omitted, this function
        does not generate any output.
    #>
    [switch]$PassThru,

    [switch]$NoRollBack
)


Import-Module "$PSScriptRoot\Utils.psm1"
 
enum InstallVerb {
    Install
    Reinstall
}

[InstallVerb]$installerVerb = "Install"
[InstallVerb]$installVerb = "Install"

function New-TemporaryFolder {

    [CmdletBinding()]
    [OutputType([string])]
    param()

    $name = (New-Guid).ToString()
    $tempPath = ([System.IO.Path]::GetTempPath())
    $tempFolder = Join-Path $tempPath $name

    New-Item -Path $tempFolder -ItemType Directory @NO_RISK_PARAMS | Out-Null
    Write-Verbose "$(_gis ($Indentation + 2))[+] Created Temporary Directory: $name"
    return $tempFolder

}

function New-InstallDirectory {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]$Path,

        [Parameter(Mandatory, Position = 2)]
        [string]$Name,

        [switch]$PassThru,

        [int]$InnerIndentation = 0
    )

    [hashtable]$newItemArgs = @{
        ItemType = "Directory"
        Path = $Path
        Name = $Name
    }

    New-Item @newItemArgs @NO_RISK_PARAMS | Out-Null
    
    if (Test-Path "$Path\$Name") {
        Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 3))[+] New Directory: $(Join-Path $Path $Name)"
    }
    else {
        throw "Failed to Create Directory '$Name' in $(Resolve-Path $Path)"
    }

    if ($PassThru) {
        return (Resolve-Path "$Path\$Name")
    }

}

function Copy-ToTemporaryFolder {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [SupportsWildcards()]
        [string[]]$Path,

        [Parameter(Mandatory, Position = 2)]
        [string]$Destination,

        [Parameter(Position = 3)]
        [string]$Name,

        [string]$Filter,
        [string[]]$Include,
        [string[]]$Exclude,

        [int]$InnerIndentation = 0
    )

    begin {
        [string[]]$allPaths = $Path
    }

    process {
        if ($null -ne $_) {
            $allPaths += @($_)
        }
    }

    end {
        Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 3))[>] Copying Files to $Destination..."
        Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 4))[>] File Patterns:"

        foreach ($currentPath in $allPaths) {
            Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 5))[#] $currentPath"
        }

        [string[]]$resolvedPaths = Get-Item $allPaths -Filter $Filter

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
    
                    if ($Name.Trim() -ne "") {
                        $newDestination += "\$Name"
                    }
                    else {
                        $newDestination += "\$(Split-Path $resolvedPath -Leaf)"
                    }
    
                    if (-not (Test-Path $newDestination)) {
                        $newDestination = (
                            New-InstallDirectory `
                                -Path (Split-Path $newDestination -Parent) `
                                -Name (Split-Path $newDestination -Leaf) `
                                -PassThru `
                                -InnerIndentation $InnerIndentation
                        )
                    }
                    
                    Write-Verbose "$(_gis ($Indentation + $InnerIndentation + 5))[>] Copying Directory: $resolvedPath"
                    Copy-ToTemporaryFolder `
                        -Path (Get-ChildItem $resolvedPath -Filter $Filter).FullName `
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
            Remove-ProgressBar
        }
    }


}

function Move-TemporaryFolder {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string]$TempFolder,

        [Parameter(Mandatory, Position = 2, ValueFromPipeline)]
        [string]$Destination,

        [Parameter(Position = 3)]
        [string]$Name,

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

function Remove-TemporaryFolder {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string]$TempFolder
    )

    $tempLocation = [System.IO.Path]::GetTempPath()

    if ($TempFolder -ilike "$tempLocation*" -and (Test-Path $tempFolder)) {
        Remove-Item $tempFolder -Recurse -Force @NO_RISK_PARAMS
        Write-Verbose "$(_gis -Indentation 1)[+] Removed Temporary Directory: $tempFolder"

        if (Test-Path $tempFolder) {
            Write-Warning "Failed to Remove Temporary Directory: $tempFolder"
        }
    }

}

function Get-InstallVerb {

    [OutputType([string])]
    param(
        [Alias("Main")]
        [switch]$Installer,

        [Alias("lc")]
        [switch]$Lowercase
    )

    [string]$verb = & {
        if (-not $Installer) {
            return $installVerb
        }
        else {
            return $installerVerb
        }
    }

    if (-not $Lowercase) { return $verb }
    else                 { return $verb.ToLower() }

}

function Set-InstallVerb {

    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [InstallVerb]$Verb,

        [Alias("Main")]
        [switch]$Installer
    )

    if (-not $Installer) {
        $script:installVerb = $Verb
    }
    else {
        $script:installerVerb = $Verb
    }

}


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

        Write-Verbose "$(_gis ($Indentation + 1))[>] Requesting User Confirmation to Proceed with $(Get-InstallVerb -)ation..."
    
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

            if (-not $SkipScriptInstall) {
                if (-not $scriptIsInstalled -or $Reinstall) {                    
                    Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with $(Get-InstallVerb -Installer)ation of Link2Root Files..."
            
                    if ($yesToAll -or $PSCmdlet.ShouldProcess(
                        "$(_gis ($Indentation + 3))[+] Confirmation APPROVED",
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
                            _upb -Status "Copy Link2Root Files" -CurrentOperation "Create Temporary Folder" -PercentageChange 5
    
                            $tempFolder = New-TemporaryFolder
                            [hashtable[]]$copyFileArgs = @(
                                @{
                                    Path = @(
                                        "$PSScriptRoot\..\Link*Root.*",
                                        "$PSScriptRoot\..\README.md"
                                    )
                                    Destination = $tempFolder
                                },
                                @{
                                    Path = $PSScriptRoot
                                    Destination = $tempFolder
                                    Name = "Installation"
                                    Exclude = $SETUP_FOLDER_IGNORED_FILES
                                },
                                @{
                                    Path = "$PSScriptRoot\..\Scripts"
                                    Destination = $tempFolder
                                }
                            )
                
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
    
                            _upb -Status "Copy Link2Root Files" -CurrentOperation "Validate File Integrity" -PercentageChange 5
                            Assert-InstallIntegrity `
                                -Source "$PSScriptRoot/../" `
                                -Install $tempFolder `
                                -Exclude $SETUP_FOLDER_IGNORED_FILES `
                                -Verbose:$VerbosePreference `
                                -Indentation ($Indentation + 2)
                             
                            if ($scriptIsInstalled) {
                                Write-Verbose "$(_gis ($Indentation + 2))[>] Removing Existing Installation Files for Reinstall..."
                                _upb -Status "Copy Link2Root Files" -CurrentOperation "Remove Existing Files" -PercentageChange 0
                                & "$PSScriptRoot\Uninstall-Link2Root.ps1" `
                                    -Reinstall `
                                    -Force `
                                    -KeepModule `
                                    -KeepPATH `
                                    -NoOutput `
                                    -NoProgress:$NoProgress `
                                    -Verbose:$VerbosePreference `
                                    -Indentation ($Indentation + 3)
                                Write-Verbose "$(_gis ($Indentation + 2))[+] Removed Existing Installation Files for Reinstall"
                            }

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
                Write-Verbose "$(_gis ($Indentation + 2))[-] -SkipScriptInstall Flag Passed to Installation Script"
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

            if (-not $SkipModuleInstall) {
                if (-not $moduleIsInstalled -or $Reinstall) {
                    Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with $(Get-InstallVerb -Installer)ation of PowerShell Module..."
            
                    if ($yesToAll -or $PSCmdlet.ShouldProcess(
                        "$(_gis ($Indentation + 3))[+] Confirmation APPROVED",
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
                                Name = "$(New-GUID).tmp"
                                ErrorAction = "SilentlyContinue"
                            }
                            
                            _upb -Status "Install PowerShell Module" -CurrentOperation "Create Temporary Folder" -PercentageChange 5
                            $tempFolder = New-TemporaryFolder
    
                            Write-Verbose "$(_gis ($Indentation + 2))[>] Copy Installation Files to Temporary Directory..."
                            _upb -Status "Install PowerShell Module" -CurrentOperation "Copy PowerShell Module Files" -PercentageChange 5
                            Copy-ToTemporaryFolder -Path "$PSScriptRoot\..\Link2Root.ps?1" -Destination $tempFolder
                            Write-Verbose "$(_gis ($Indentation + 2))[+] Copied Installation Files to Temporary Directory"
                            
                            _upb -Status "Install PowerShell Module" -CurrentOperation "Verify File Integrity" -PercentageChange 5
                            Assert-InstallIntegrity `
                                -Source "$PSScriptRoot/../" `
                                -Install $tempFolder `
                                -Filter "Link2Root.ps?1" `
                                -Verbose:$VerbosePreference `
                                -Indentation ($Indentation + 2)
                                
                            # Test if we can write to the /Documents folder or not
                            if ($testFile = (New-Item @testFileArgs @NO_RISK_PARAMS)) {
                                Write-Verbose "$(_gis ($Indentation + 2))[+] Permissions Sufficient to make changes to Documents Directory"
                                Remove-Item -Path $testFile @NO_RISK_PARAMS

                                Write-Verbose "$(_gis ($Indentation + 2))[>] Locating PowerShell Modules Directory..."

                                if (-not (Test-Path $modulesLocation)) {
                                    Write-Verbose "$(_gis ($Indentation + 3))[-] Existing PowerShell Modules Directory NOT Found"
                                    _upb -Status "Install PowerShell Module" -CurrentOperation "Create PowerShell Folders" -PercentageChange 0
            
                                    if (-not (Test-Path $psFolder)) {
                                        New-InstallDirectory -Path (Split-Path $psFolder -Parent) -Name (Split-Path $psFolder -Leaf)
                                    }
                                    
                                    New-InstallDirectory -Path $psFolder -Name (Split-Path $modulesLocation -Leaf)
                                }
                                else {
                                    Write-Verbose "$(_gis ($Indentation + 3))[+] Existing PowerShell Modules Directory FOUND"
                                }

                                Write-Verbose "$(_gis ($Indentation + 2))[+] PowerShell Modules Directory Located: $modulesLocation"
                    
                                if ($moduleIsInstalled) {
                                    Write-Verbose "$(_gis ($Indentation + 2))[>] Removing Existing PowerShell Module Files for Reinstall..."
                                    _upb -Status "Install PowerShell Module" -CurrentOperation "Remove Existing Files" -PercentageChange 0
                                    & "$PSScriptRoot\Uninstall-Link2Root.ps1" `
                                        -Reinstall `
                                        -KeepInstall `
                                        -KeepPATH `
                                        -NoOutput `
                                        -NoProgress:$NoProgress `
                                        -Force `
                                        -Verbose:$VerbosePreference `
                                        -Indentation ($Indentation + 3)
                                    Write-Verbose "$(_gis ($Indentation + 2))[+] Removed Existing PowerShell Module Files for Reinstall"
                                }
                    
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
    
                                if (-not $NoOutput) {
                                    Write-Warning "PowerShell does not have permission to modify $psFolder. This often caused by Anti-Virus Software or Windows Security's `"Controlled Folder Access`" option."
                                }
                            
                                if (-not (Test-Path "$desktop\$psFolderName")) {
                                    if ($Force -or $yesToAll -or $PSCmdlet.ShouldContinue(
                                        "You will have to manually move the directory into your /Documents folder to $(Get-InstallVerb -lc) the PowerShell Module.",
                                        "Do you want to create the PowerShell Module Folder on the Desktop?",
                                        [ref]$yesToAll,
                                        [ref]$noToAll
                                    )) {
                                        [string]$modulesFolderName = (Split-Path $modulesLocation -Leaf)
        
                                        New-InstallDirectory -Path $desktop -Name $psFolderName -PassThru |
                                            New-InstallDirectory -Name $modulesFolderName -PassThru |
                                                Move-TemporaryFolder -TempFolder $tempFolder -Name "Link2Root" -PassThru |
                                                    Assert-InstallIntegrity -Source "$PSScriptRoot/../" -Filter "Link2Root.ps?1" -Verbose:$VerbosePreference
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
                Write-Verbose "$(_gis ($Indentation + 2))[-] -SkipModuleInstall Flag Passed to Installation Script"
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
            
            if (-not $SkipPATHUpdate) {
                if (-not $isAddedToPATH -or $Reinstall) {
                    Write-Verbose "$(_gis ($Indentation + 2))[>] Requesting User Confirmation to Proceed with Modifying User PATH..."
                    
                    if ($yesToAll -or $PSCmdlet.ShouldProcess(
                        "$(_gis ($Indentation + 3))[+] Confirmation APPROVED",
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

                        if ($isAddedToPATH) {
                            Write-Verbose "$(_gis ($Indentation + 2))[>] Removing Link2Root from $username's PATH for Reinstall..."
                            _upb -Status "Update User PATH" -CurrentOperation "Remove Existing PATH Entry" -PercentageChange 0
                            & "$PSScriptRoot\Uninstall-Link2Root.ps1" `
                                -Reinstall `
                                -Force `
                                -KeepInstall `
                                -KeepModule `
                                -NoOutput `
                                -NoProgress:$NoProgress `
                                -Verbose:$VerbosePreference `
                                -Indentation ($Indentation + 3)
                            Write-Verbose "$(_gis ($Indentation + 2))[+] Removed Link2Root from $username's PATH for Reinstall"
                        }
        
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
                            Write-Host "Successfully $(Get-InstallVerb -lc)ed " -NoNewline -ForegroundColor Green
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
                Write-Verbose "$(_gis ($Indentation + 2))[-] -SkipPATHUpdate Flag Passed to Installation Script"
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
    Remove-ProgressBar
}