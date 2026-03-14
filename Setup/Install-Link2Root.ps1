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

    process {
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


}

function Move-TemporaryFolder {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string]$TempFolder,

        [Parameter(Mandatory, Position = 2, ValueFromPipeline)]
        [string]$Destination,

        [Parameter(Position = 3)]
        [string]$Name
    )

    if ((Test-Path $Destination) -and $null -eq $Name) {
        throw "The -Name parameter must be specified to Move-TemporaryFolder when the -Destination already exists."
    }

    [string]$fullDestPath = $Destination

    if ($null -ne $Name) {
        $fullDestPath = Join-Path $fullDestPath $Name
    }

    Write-Verbose "Moving Files from Temporary Directory '$(Split-Path $tempFolder -Leaf)' to $fullDestPath"
    Move-Item -Path $tempFolder -Destination $fullDestPath @NO_RISK_PARAMS | Out-Null

    if (-not (Test-Path $fullDestPath)) {
        throw "Failed to Move $tempFolder to $fullDestPath"
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


if ((& "$PSScriptRoot\Test-Installation.ps1" -Silent -PassThru) -and -not $Reinstall) {
    if (-not $Silent) {
        Write-Path "Link2Root" -NoNewline
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
        Set-InstallVerb Reinstall
    }

    if ($Force -or $PSCmdlet.ShouldContinue("$(Get-InstallVerb -Installer) Link2Root", "Confirm", [ref]$yesToAll, [ref]$noToAll)) {
        [string[]]$userPATH = Get-UserPATH
        [bool]$scriptIsInstalled = (Test-Path $installLocation)
        [bool]$moduleIsInstalled = (Test-Path $modulePath)
        [bool]$isAddedToPATH = Test-UserPATH -Entry $installLocation -PATH $userPATH

        # Install the script in the current user's local appdata folder
        if (-not $SkipScriptInstall) {
            if (-not $scriptIsInstalled -or $Reinstall) {
                (& {
                    if (-not $scriptIsInstalled) { return "Install" }
                    else                         { return "Reinstall" }
                }) | Set-InstallVerb
        
                if ($yesToAll -or $PSCmdlet.ShouldProcess(
                    "$(Get-InstallVerb)ing Link2Root in $installLocation",
                    "$(Get-InstallVerb) Link2Root in $installLocation",
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
                            Write-Verbose "Removing Existing Link2Root Installation Files for Reinstall"
                            & "$PSScriptRoot\Uninstall-Link2Root.ps1" -KeepModule -KeepPATH -Silent -Force -Verbose:$VerbosePreference
                        }
            
                        Move-TemporaryFolder -TempFolder $tempFolder -Destination $installLocation
                        $success = $true
                    
                        if (-not $Silent) {
                            Write-ComponentUpdatePrefix -Success
                            Write-Host "Successfully $(Get-InstallVerb -lc)ed " -NoNewline -ForegroundColor Green
                            Write-Component "Link2Root" -NoNewline
                            Write-Host " in " -NoNewline
                            Write-Path $installLocation
                        }
                    }
                    catch {
                        if (-not $Silent) {
                            Write-ComponentUpdatePrefix -Failed
                            Write-Host "Failed to $(Get-InstallVerb -lc) " -NoNewline -ForegroundColor Red
                            Write-Component "Link2Root" -NoNewline
                            Write-Host " in " -NoNewline
                            Write-Path $installLocation
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
                    Write-ComponentUpdatePrefix -Failed
                    Write-Component "Link2Root" -NoNewline
                    Write-Host " was " -NoNewline
                    Write-Host "not $(Get-InstallVerb -lc)ed" -NoNewline -ForegroundColor Red
                    Write-Host " in " -NoNewline
                    Write-Path $installLocation
                }
            }
            else {
                if (-not $Silent) {
                    Write-ComponentUpdatePrefix
                    Write-Component "Link2Root" -NoNewline
                    Write-Host " is " -NoNewline
                    Write-Host "already installed" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " in " -NoNewline
                    Write-Path $installLocation
                }
            }
        }
        
        # Install the module in the current user's PowerShell Modules folder
        if (-not $SkipModuleInstall) {
            if (-not $moduleIsInstalled -or $Reinstall) {
                (& {
                    if (-not $moduleIsInstalled) { return "Install" }
                    else                         { return "Reinstall" }
                }) | Set-InstallVerb
        
                if ($yesToAll -or $PSCmdlet.ShouldProcess(
                    "$(Get-InstallVerb)ing Link2Root PowerShell Module in $modulesLocation",
                    "$(Get-InstallVerb) Link2Root PowerShell Module in $modulesLocation",
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
                                Write-Verbose "Removing Existing Link2Root PowerShell Module Files for Reinstall"
                                & "$PSScriptRoot\Uninstall-Link2Root.ps1" -KeepInstall -KeepPATH -Silent -Force
                            }
                
                            Move-TemporaryFolder -TempFolder $tempFolder -Destination $modulePath
                            $success = $true
                
                            if (-not $Silent) {
                                Write-ComponentUpdatePrefix -Success
                                Write-Host "Successfully $(Get-InstallVerb -lc)ed" -NoNewline -ForegroundColor Green
                                Write-Host " the " -NoNewline
                                Write-Component "Link2Root PowerShell Module" -NoNewline
                                Write-Host " in " -NoNewline
                                Write-Path $modulePath
                            }
                        }
                        else {
                            [string]$desktop = ([System.Environment]::GetFolderPath("Desktop"))

                            if (-not $Silent) {
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
                                            Move-TemporaryFolder -TempFolder $tempFolder -Name "Link2Root"
                                }
                            }
                            else {
                                Write-Verbose "PowerShell Module Folder already exists at $(Resolve-Path "$desktop\$psFolderName")"
                            }

                            if (-not $Silent) {
                                Write-ComponentUpdatePrefix
                                Write-Component "Link2Root PowerShell Module" -NoNewline
                                Write-Host " is " -NoNewline
                                Write-Host "Pending Manual $(Get-InstallVerb)ation" -NoNewline -ForegroundColor DarkYellow
                                Write-Host " from " -NoNewline
                                Write-Path "$desktop\$psFolderName"
                                Write-Host " to " -NoNewline
                                Write-Path $psFolder
                            }
                        }    
                    }
                    catch {
                        if (-not $Silent) {
                            Write-ComponentUpdatePrefix -Success
                            Write-Host "Failed to $(Get-InstallVerb -lc)" -NoNewline -ForegroundColor Red
                            Write-Host " the " -NoNewline
                            Write-Component "Link2Root PowerShell Module" -NoNewline
                            Write-Host " in " -NoNewline
                            Write-Path $modulePath
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
                    Write-ComponentUpdatePrefix -Failed
                    Write-Host "The " -NoNewline
                    Write-Component "Link2Root PowerShell Module" -NoNewline
                    Write-Host " was " -NoNewline
                    Write-Host "not $(Get-InstallVerb -lc)ed" -NoNewline -ForegroundColor Red
                    Write-Host " in " -NoNewline
                    Write-Path $modulePath
                }
            }
            else {
                if (-not $Silent) {
                    Write-ComponentUpdatePrefix
                    Write-Host "The " -NoNewline
                    Write-Component "Link2Root PowerShell Module" -NoNewline
                    Write-Host " is " -NoNewline
                    Write-Host "already installed" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " in " -NoNewline
                    Write-Path $modulePath
                }
            }
        }

        # Update the User's PATH
        if (-not $SkipPATHUpdate) {
            if (-not $isAddedToPATH -or $Reinstall) {
                [string]$username = Get-FullyQualifiedUsername
                [string]$installVerb = & {
                    if (-not $isAddedToPATH) { return "Add" }
                    else                     { return "Re-Add" }
                }
                
                if ($yesToAll -or $PSCmdlet.ShouldProcess(
                    "${installVerb}ing $installLocation to $username's PATH",
                    "$installVerb $installLocation to $username's PATH",
                    "Confirm`nAre you sure you want to perform this action?"
                )) {
                    if ($isAddedToPATH) {
                        Write-Verbose "Removing Link2Root from $username's PATH for Reinstall"
                        & "$PSScriptRoot\Uninstall-Link2Root.ps1" -KeepInstall -KeepModule -Silent -Force
                    }
    
                    Set-UserPATH ($userPATH + @($installLocation))
                    $success = $true
    
                    if (-not $Silent) {
                        Write-ComponentUpdatePrefix -Success
                        Write-Host "Successfully $(Get-InstallVerb -lc)ed " -NoNewline -ForegroundColor Green
                        Write-Component "Link2Root" -NoNewline
                        Write-Host " to " -NoNewline
                        Write-Path "$username's PATH"
                    }
                }
            }
            else {
                if (-not $Silent) {
                    Write-ComponentUpdatePrefix
                    Write-Component "Link2Root" -NoNewline
                    Write-Host " has " -NoNewline
                    Write-Host "already been added" -NoNewline -ForegroundColor DarkYellow
                    Write-Host " to " -NoNewline
                    Write-Path "$username's PATH"
                }
            }
        }
    }

    if (-not $Silent) {
        Write-Host ""

        if ($success) {
            Write-Host "Successfully $(Get-InstallVerb -Installer -Lowercase)ed " -NoNewline -ForegroundColor Green
            Write-Component "Link2Root" -NoNewline
            Write-Host "!" -ForegroundColor Green
            Write-EndRestartNotice
        }
        else {
            Write-Host "Nothing for " -NoNewline -ForegroundColor Yellow
            Write-Component "Link2Root" -NoNewline
            Write-Host " was $(Get-InstallVerb -Installer -Lowercase)ed." -ForegroundColor Yellow
        }
    }
    if ($PassThru) {
        return $true
    }
}
catch {
    if (-not $Silent) {
        Write-Host ""
        Write-Host "Failed to $(Get-InstallVerb -Installer -Lowercase) " -NoNewline -ForegroundColor Red
        Write-Component "Link2Root" -NoNewline
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