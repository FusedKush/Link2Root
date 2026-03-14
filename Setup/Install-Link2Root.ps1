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
        Indicates that this function should return a boolean value
        indicating whether or not the installation was successful.

        By default and when this switch is omitted, this function
        does not generate any output.
    #>
    [switch]$PassThru,
    
    <#
        Suppress all non-error output.

        By default and when this switch is omitted, information will
        be output to the host indicating the progress and status
        of the installation and the individual components for Link2Root.
    #>
    [switch]$Silent,

    [switch]$NoRollBack
)


enum InstallVerb {
    Install
    Reinstall
}

[hashtable]$NO_RISK_PARAMS = @{
    WhatIf = $false
    Confirm = $false
}

function New-TemporaryFolder {

    [CmdletBinding()]
    [OutputType([string])]
    param()

    $name = (New-Guid).ToString()
    $tempPath = ([System.IO.Path]::GetTempPath())
    $tempFolder = Join-Path $tempPath $name

    New-Item -Path $tempFolder -ItemType Directory @NO_RISK_PARAMS | Out-Null
    Write-Verbose "Created Temporary Directory '$name' in $tempPath"
    return $tempFolder

}

function New-InstallDirectory {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]$Path,

        [Parameter(Mandatory, Position = 2)]
        [string]$Name,

        [switch]$PassThru
    )

    [hashtable]$newItemArgs = @{
        ItemType = "Directory"
        Path = $Path
        Name = $Name
    }

    Write-Verbose "Creating Directory '$Name' in $(Resolve-Path $Path)"
    New-Item @newItemArgs @NO_RISK_PARAMS | Out-Null

    if (-not (Test-Path "$Path\$Name")) {
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
        [string]$Path,

        [Parameter(Mandatory, Position = 2)]
        [string]$Destination,

        [string]$Filter
    )

    [hashtable]$copyItemArgs = @{
        Path = $Path
        Destination = $Destination
        Filter = $Filter
    }
    [string]$resolvedPath = Resolve-Path $Path

    if (Test-Path $resolvedPath -PathType Container) {
        $copyItemArgs["Container"] = $true
        $copyItemArgs["Recurse"] = $true
        
        Write-Verbose "Copying Files to Temporary Directory: $resolvedPath\"
    }
    else {
        Write-Verbose "Copying File to Temporary Directory: $resolvedPath"
    }

    Copy-Item @copyItemArgs @NO_RISK_PARAMS | Out-Null

    if (-not (Test-Path $Destination)) {
        throw "Failed to Copy $Path to $Destination"
    }

}

function Move-TemporaryFolder {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string]$TempFolder,

        [Parameter(Mandatory, Position = 2, ValueFromPipeline)]
        [string]$Destination
    )

    Write-Verbose "Moving Files from Temporary Directory '$(Split-Path $tempFolder -Leaf)' to $Destination"
    Move-Item -Path $tempFolder -Destination $Destination @NO_RISK_PARAMS | Out-Null

    if (-not (Test-Path $Destination)) {
        throw "Failed to Move Temporary Directory $tempFolder to $Destination"
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
        Write-Verbose "Removing Temporary Directory: $tempFolder"
        Remove-Item $tempFolder -Recurse -Force @NO_RISK_PARAMS

        if (Test-Path $tempFolder) {
            Write-Warning "Failed to Remove Temporary Directory $tempFolder"
        }
    }

}


if ((& "$PSScriptRoot\Test-Installation.ps1") -and -not $Reinstall) {
    if (-not $Silent) {
        Write-Host "Link2Root" -NoNewline -ForegroundColor Cyan
        Write-Host " is Already Installed!" -ForegroundColor Yellow
    }

    if ($PassThru) {
        return $false
    }
    else {
        return
    }
}

try {
    [InstallVerb]$installerVerb = "Install"
    [string]$installLocation = & "$PSScriptRoot\Get-InstallLocation.ps1"
    [string]$modulePath = & "$PSScriptRoot\Get-InstallLocation.ps1" -GetModulePath
    [string]$modulesLocation = Split-Path $modulePath -Parent
    [string]$psFolder = Split-Path $modulesLocation -Parent
    [string]$psFolderName = Split-Path $psFolder -Leaf
    [bool]$success = $false
    [bool]$yesToAll = $false
    [bool]$noToAll = $false

    $ErrorActionPreference = "Stop"

    if ($Force -and -not $PSBoundParameters.ContainsKey("Confirm")) {
        $ConfirmPreference = "None"
    }
    if ($Reinstall -and ((Test-Path $installLocation) -or (Test-Path $modulePath))) {
        $installerVerb = "Reinstall"
    }

    if ($Force -or $PSCmdlet.ShouldContinue("$installerVerb Link2Root", "Confirm", [ref]$yesToAll, [ref]$noToAll)) {
        [string]$currentPATH = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        [string[]]$currentPATHContents = $currentPATH -split ";"
        [bool]$scriptIsInstalled = (Test-Path $installLocation)
        [bool]$moduleIsInstalled = (Test-Path $modulePath)
        [bool]$isAddedToPATH = $currentPATHContents -contains $installLocation

        # Install the script in the current user's local appdata folder
        if (-not $SkipScriptInstall) {
            if (-not $scriptIsInstalled -or $Reinstall) {
                [InstallVerb]$installVerb = & {
                    if (-not $scriptIsInstalled) {
                        return "Install"
                    }
                    else {
                        return "Reinstall"
                    }
                }
        
                if ($yesToAll -or $PSCmdlet.ShouldProcess(
                    "${installVerb}ing Link2Root in $installLocation",
                    "$installVerb Link2Root in $installLocation",
                    "Confirm`nAre you sure you want to perform this action?"
                )) {
                    [string]$tempFolder = ""

                    try {
                        $tempFolder = New-TemporaryFolder
                        [hashtable[]]$copyFileArgs = @(
                            @{
                                Path = "$PSScriptRoot\..\Link2Root.psm1"
                                Destination = "$tempFolder\Link2Root.psm1"
                            },
                            @{
                                Path = "$PSScriptRoot\..\Link2Root.bat"
                                Destination = "$tempFolder\Link2Root.bat"
                            },
                            @{
                                Path = "$PSScriptRoot\..\LinkThis2Root.bat"
                                Destination = "$tempFolder\LinkThis2Root.bat"
                            },
                            @{
                                Path = "$PSScriptRoot"
                                Destination = "$tempFolder\Installation"
                                Filter = "*Uninstall*"
                            },
                            @{
                                Path = "$PSScriptRoot\..\Scripts"
                                Destination = "$tempFolder\Scripts"
                            }
                        )
            
                        foreach ($copyArgs in $copyFileArgs) {
                            Copy-ToTemporaryFolder @copyArgs
                        }
            
                        if ($scriptIsInstalled) {
                            Write-Verbose "Removing Existing Link2Root Installation Files for Reinstall..."
                            & "$PSScriptRoot\Uninstall-Link2Root.ps1" -KeepModule -KeepPATH -Silent -Force -Verbose:$VerbosePreference
                        }
            
                        Move-TemporaryFolder -TempFolder $tempFolder -Destination $installLocation
                        $success = $true
                    
                        if (-not $Silent) {
                            Write-Host "[" -NoNewline
                            Write-Host "+" -NoNewline -ForegroundColor Green
                            Write-Host "] " -NoNewline
                            Write-Host "Successfully $($installVerb.ToString().ToLower())ed " -NoNewline -ForegroundColor Green
                            Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                            Write-Host " in " -NoNewline
                            Write-Host $installLocation -ForegroundColor Cyan
                        }
                    }
                    catch {
                        if (-not $Silent) {
                            Write-Host "[" -NoNewline
                            Write-Host "-" -NoNewline -ForegroundColor Green
                            Write-Host "] " -NoNewline
                            Write-Host "Failed to $($installVerb.ToString().ToLower()) " -NoNewline -ForegroundColor Red
                            Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                            Write-Host " in " -NoNewline
                            Write-Host $installLocation -ForegroundColor Cyan
                        }

                        throw $_
                    }
                    finally {
                        if ($null -ne $tempFolder) {
                            Remove-TemporaryFolder $tempFolder
                        }
                    }
                }
                elseif (-not $Silent) {
                    Write-Host "[" -NoNewline
                    Write-Host "-" -NoNewline -ForegroundColor Green
                    Write-Host "] " -NoNewline
                    Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                    Write-Host " was " -NoNewline
                    Write-Host "not $($installVerb.ToString().ToLower())ed" -NoNewline -ForegroundColor Red
                    Write-Host " in " -NoNewline
                    Write-Host $installLocation -ForegroundColor Cyan
                }
            }
            else {
                if (-not $Silent) {
                    Write-Host "[" -NoNewline
                    Write-Host "/" -NoNewline -ForegroundColor DarkYellow
                    Write-Host "] " -NoNewline
                    Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                    Write-Host " is " -NoNewline
                    Write-Host "already installed" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " in " -NoNewline
                    Write-Host $installLocation -ForegroundColor Cyan
                }
            }
        }
        
        # Install the module in the current user's PowerShell Modules folder
        if (-not $SkipModuleInstall) {
            if (-not $moduleIsInstalled -or $Reinstall) {
                [InstallVerb]$installVerb = & {
                    if (-not $moduleIsInstalled) {
                        return "Install"
                    }
                    else {
                        return "Reinstall"
                    }
                }
        
                if ($yesToAll -or $PSCmdlet.ShouldProcess(
                    "${installVerb}ing Link2Root PowerShell Module in $modulesLocation",
                    "$installVerb Link2Root PowerShell Module in $modulesLocation",
                    "Confirm`nAre you sure you want to perform this action?"
                )) {
                    [string]$tempFolder = ""

                    try {
                        [hashtable]$testFileArgs = @{
                            ItemType = "File"
                            Path = [System.Environment]::GetFolderPath("MyDocuments")
                            Name = "$(New-GUID).tmp"
                            ErrorAction = "SilentlyContinue"
                        }
                        
                        $tempFolder = New-TemporaryFolder

                        Copy-ToTemporaryFolder -Path "$PSScriptRoot\..\Link2Root.psm1" -Destination "$tempFolder\Link2Root.psm1"
                        Copy-ToTemporaryFolder -Path "$PSScriptRoot\..\Link2Root.psd1" -Destination "$tempFolder\Link2Root.psd1"

                        # Test if we can write to the /Documents folder or not
                        if ($testFile = (New-Item @testFileArgs @NO_RISK_PARAMS)) {
                            Remove-Item -Path $testFile

                            if (-not (Test-Path $modulesLocation)) {        
                                Write-Verbose "No Existing PowerShell Module Folder Found!"
                                Write-Verbose "Attempting to Create PowerShell Module Folder in $modulesLocation..."
        
                                if (-not (Test-Path $psFolder)) {
                                    New-InstallDirectory -Path (Split-Path $psFolder -Parent) -Name (Split-Path $psFolder -Leaf)
                                }
                                
                                New-InstallDirectory -Path $psFolder -Name (Split-Path $modulesLocation -Leaf)
                            }
                
                            if ($moduleIsInstalled) {
                                Write-Verbose "Removing Existing Link2Root PowerShell Module Files for Reinstall..."
                                & "$PSScriptRoot\Uninstall-Link2Root.ps1" -KeepInstall -KeepPATH -Silent -Force
                            }
                
                            Move-TemporaryFolder -TempFolder $tempFolder -Destination $modulePath
                            $success = $true
                
                            if (-not $Silent) {
                                Write-Host "[" -NoNewline
                                Write-Host "+" -NoNewline -ForegroundColor Green
                                Write-Host "] " -NoNewline
                                Write-Host "Successfully $($installVerb.ToString().ToLower())ed" -NoNewline -ForegroundColor Green
                                Write-Host " the " -NoNewline
                                Write-Host "Link2Root PowerShell Module" -NoNewline -ForegroundColor Yellow
                                Write-Host " in " -NoNewline
                                Write-Host $modulePath -ForegroundColor Cyan
                            }
                        }
                        else {
                            [string]$desktop = ([System.Environment]::GetFolderPath("Desktop"))

                            if (-not $Silent) {
                                Write-Warning "PowerShell does not have permission to modify $psFolder. This often caused by Anti-Virus Software or Windows Security's `"Controlled Folder Access`" option."
                            }
                        
                            if (-not (Test-Path "$desktop\$psFolderName")) {
                                if ($Force -or $yesToAll -or $PSCmdlet.ShouldContinue(
                                    "You will have to manually move the directory into your /Documents folder to install the PowerShell Module.",
                                    "Do you want to create the PowerShell Module Folder on the Desktop?",
                                    [ref]$yesToAll,
                                    [ref]$noToAll
                                )) {
                                    [string]$modulesFolderName = (Split-Path $modulesLocation -Leaf)
    
                                    New-InstallDirectory -Path $desktop -Name $psFolderName -PassThru |
                                        New-InstallDirectory -Name $modulesFolderName -PassThru |
                                            New-InstallDirectory -Name "Link2Root" -PassThru |
                                                Move-TemporaryFolder -TempFolder $tempFolder
                                }
                            }
                            else {
                                Write-Verbose "PowerShell Module Folder already exists at $(Resolve-Path "$desktop\$psFolderName")"
                            }

                            if (-not $Silent) {
                                Write-Host "[" -NoNewline
                                Write-Host "/" -NoNewline -ForegroundColor DarkYellow
                                Write-Host "] The " -NoNewline
                                Write-Host "Link2Root PowerShell Module" -NoNewline -ForegroundColor Yellow
                                Write-Host " is " -NoNewline
                                Write-Host "Pending Manual Installation" -NoNewline -ForegroundColor DarkYellow
                                Write-Host " from " -NoNewline
                                Write-Host "$desktop\$psFolderName" -ForegroundColor Cyan
                                Write-Host " to " -NoNewline
                                Write-Host $psFolder -ForegroundColor Cyan
                            }
                        }    
                    }
                    catch {
                        if (-not $Silent) {
                            Write-Host "[" -NoNewline
                            Write-Host "+" -NoNewline -ForegroundColor Green
                            Write-Host "] " -NoNewline
                            Write-Host "Failed to $($installVerb.ToString().ToLower())" -NoNewline -ForegroundColor Red
                            Write-Host " the " -NoNewline
                            Write-Host "Link2Root PowerShell Module" -NoNewline -ForegroundColor Yellow
                            Write-Host " in " -NoNewline
                            Write-Host $modulePath -ForegroundColor Cyan
                        }

                        throw $_
                    }
                    finally {
                        if ($null -ne $tempFolder) {
                            Remove-TemporaryFolder $tempFolder
                        }
                    }
                }
                elseif (-not $Silent) {
                    Write-Host "[" -NoNewline
                    Write-Host "-" -NoNewline -ForegroundColor Green
                    Write-Host "] " -NoNewline
                    Write-Host "The " -NoNewline
                    Write-Host "Link2Root PowerShell Module" -NoNewline -ForegroundColor Yellow
                    Write-Host " was " -NoNewline
                    Write-Host "not $($installVerb.ToString().ToLower())ed" -NoNewline -ForegroundColor Red
                    Write-Host " in " -NoNewline
                    Write-Host $modulePath -ForegroundColor Cyan
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
                    Write-Host "already installed" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " in " -NoNewline
                    Write-Host $modulePath -ForegroundColor Cyan
                }
            }
        }

        # Update the User's PATH
        if (-not $SkipPATHUpdate) {
            if (-not $isAddedToPATH -or $Reinstall) {
                [string]$installVerb = & {
                    if (-not $isAddedToPATH) {
                        return "Add"
                    }
                    else {
                        return "Re-Add"
                    }
                }
                
                if ($yesToAll -or $PSCmdlet.ShouldProcess(
                    "${installVerb}ing Link2Root to ${env:USERNAME}'s PATH",
                    "$installVerb Link2Root to ${env:USERNAME}'s PATH",
                    "Confirm`nAre you sure you want to perform this action?"
                )) {
                    if ($isAddedToPATH) {
                        Write-Verbose "Removing Link2Root from Current User's PATH for Reinstall..."
                        & "$PSScriptRoot\Uninstall-Link2Root.ps1" -KeepInstall -KeepModule -Silent -Force
                    }
    
                    [System.Environment]::SetEnvironmentVariable(
                        "PATH",
                        ($currentPATHContents + @($installLocation)) -join ";",
                        "User"
                    );

                    $success = $true
    
                    if (-not $Silent) {
                        Write-Host "[" -NoNewline
                        Write-Host "+" -NoNewline -ForegroundColor Green
                        Write-Host "] " -NoNewline
                        Write-Host "Successfully $($installVerb.ToLower())ed " -NoNewline -ForegroundColor Green
                        Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                        Write-Host " to " -NoNewline
                        Write-Host "${env:USERNAME}'s PATH" -ForegroundColor Cyan
                    }
                }
            }
            else {
                if (-not $Silent) {
                    Write-Host "[" -NoNewline
                    Write-Host "/" -NoNewline -ForegroundColor DarkYellow
                    Write-Host "] " -NoNewline
                    Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                    Write-Host " has " -NoNewline
                    Write-Host "already been added" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " to " -NoNewline
                    Write-Host "${env:USERNAME}'s PATH" -ForegroundColor Cyan
                }
            }
        }
    }

    if (-not $Silent) {
        Write-Host ""

        if ($success) {
            Write-Host "Successfully $($installerVerb.ToString().ToLower())ed " -NoNewline -ForegroundColor Green
            Write-Host "Link2Root" -NoNewline -ForegroundColor Cyan
            Write-Host "!" -ForegroundColor Green
            Write-Host "You may have to restart your console session or terminal window for changes to take effect." -ForegroundColor DarkYellow
        }
        else {
            Write-Host "Nothing for " -NoNewline -ForegroundColor Yellow
            Write-Host "Link2Root" -NoNewline -ForegroundColor Cyan
            Write-Host " was $($installerVerb.ToString().ToLower())ed." -ForegroundColor Yellow
        }
    }
    if ($PassThru) {
        return $true
    }
}
catch {
    if (-not $Silent) {
        Write-Host ""
        Write-Host "Failed to $($installerVerb.ToString().ToLower()) " -NoNewline -ForegroundColor Red
        Write-Host "Link2Root" -NoNewline -ForegroundColor Cyan
        Write-Host "!" -ForegroundColor Red
        
        if ($success -and -not $NoRollBack) {
            Write-Host "Rolling back changes..." -ForegroundColor Yellow
            & "$PSScriptRoot\Uninstall-Link2Root.ps1" -Silent -Force -Verbose:$VerbosePreference
        }

        Write-Host ""
    }

    if ($PassThru) {
        if (-not $Silent) {
            Write-Host $_ -ForegroundColor Red
        }

        return $false
    }
    else {
        throw $_
    }
}