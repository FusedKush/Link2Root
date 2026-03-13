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
    
    <#
        Skip the installation of Link2Root in the
        current user's `AppData/Local` folder.

        Using this option will prevent you from being able to use
        Link2Root without having to move or navigate to the
        downloaded `Link2Root/` folder.

        When this switch is used, `-SkipPATHUpdate` is implicitly
        included as well.
    #>
    [bool]$SkipScriptInstall,
    
    <#
        Skip the installation of the Link2Root PowerShell Module
        in the current user's PowerShell Modules.

        Using this option will prevent you from being able to use
        `Link2Root` and `LinkThis2Root` without importing them into
        the PowerShell session or script.
    #>
    [bool]$SkipModuleInstall,
    
    <#
        Skip updating the current user's `PATH` to
        add the Link2Root Installation Directory.

        Using this option will prevent you from being able to use
        the `Link2Root` command without having to move or navigate to
        the downloaded `Link2Root/` folder.

        This switch has no effect when the `-SkipScriptInstall` switch is used.
    #>
    [bool]$SkipPATHUpdate
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

    $name = (New-Guid).ToString("N")
    $tempFolder = Join-Path ([System.IO.Path]::GetTempPath()) $name

    New-Item -Path $tempFolder -ItemType Directory | Out-Null
    Write-Verbose "Created Temporary Directory: $tempFolder"
    return $tempFolder

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
    [hashtable]$itemParams = & {
        $itemParams = $NO_RISK_PARAMS.Clone()
        
        # $itemParams["Force"] = $true
        return $itemParams
    }
    [bool]$success = $false
    [bool]$yesToAll = $false
    [bool]$noToAll = $false
    [hashtable]$tempFolders = @{}

    $ErrorActionPreference = "Stop"

    if ($Force -and -not $PSBoundParameters.ContainsKey("Confirm")) {
        $ConfirmPreference = "None"
    }
    if ($Reinstall -and ((Test-Path $installLocation) -or (Test-Path $modulePath))) {
        $installerVerb = "Reinstall"
    }

    if ($Force -or $PSCmdlet.ShouldContinue("$installerVerb Link2Root", "Confirm", [ref]$yesToAll, [ref]$noToAll)) {
        [string]$currentPATH = [System.Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
        [bool]$scriptIsInstalled = (Test-Path $installLocation)
        [bool]$moduleIsInstalled = (Test-Path $modulePath)
        [bool]$isAddedToPATH = $currentPATH -split ";" -contains $installLocation

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
                            Path = "$PSScriptRoot\"
                            Destination = "$tempFolder\Installation"
                            Container = $true
                            Recurse = $true
                            Filter = "*Uninstall*"
                        },
                        @{
                            Path = "$PSScriptRoot\..\Scripts"
                            Destination = "$tempFolder\Scripts"
                            Container = $true
                            Recurse = $true
                        }
                    )
                    # New-Item -Path $installLocation -ItemType Directory @itemParams | Out-Null
        
                    foreach ($copyArgs in $copyFileArgs) {
                        $fullArgs = $copyArgs + $itemParams
        
                        Write-Verbose "Copying $(Resolve-Path $fullArgs["Path"]) to Temporary Install Location..."
                        Copy-Item @fullArgs | Out-Null
                    }
        
                    if ($scriptIsInstalled) {
                        Write-Verbose "Removing Existing Link2Root Installation Files for Reinstall..."
                        & "$PSScriptRoot\Uninstall-Link2Root.ps1" -KeepModule -KeepPATH -Silent -Force
                        # Remove-Item -Path $installLocation -Recurse @NO_RISK_PARAMS
                    }
        
                    $tempFolders.Add($tempFolder, $installLocation)
                    # Write-Verbose "Moving Files to Install Location..."
                    # Move-Item -Path $tempFolder -Destination $installLocation | Out-Null
                    $success = $true
                
                    if (-not $Silent) {
                        # Write-Host ""
                        Write-Host "[" -NoNewline
                        Write-Host "+" -NoNewline -ForegroundColor Green
                        Write-Host "] " -NoNewline
                        Write-Host "Successfully $($installVerb.ToString().ToLower())ed " -NoNewline -ForegroundColor Green
                        Write-Host "Link2Root" -NoNewline -ForegroundColor Yellow
                        Write-Host " in " -NoNewline
                        Write-Host $installLocation -ForegroundColor Cyan
                    }
                }
                elseif (-not $Silent) {
                    # Write-Host ""
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
                    $tempFolder = New-TemporaryFolder
        
                    if (-not (Test-Path $modulesLocation)) {
                        Write-Verbose "No Existing PowerShell Module Folder Found!"
                        Write-Verbose "Creating PowerShell Module Folder in $modulesLocation..."
                        New-Item -Path $modulesLocation -ItemType Directory @itemParams
                    }
                
                    # New-Item -Path $modulePath -ItemType Directory @itemParams | Out-Null
                    Write-Verbose "Copying $(Resolve-Path $PSScriptRoot\..\Link2Root.psm1) to Temporary Install Location..."
                    Copy-Item -Path "$PSScriptRoot\..\Link2Root.psm1" -Destination "$tempFolder\Link2Root.psm1" @itemParams | Out-Null
        
                    if ($moduleIsInstalled) {
                        Write-Verbose "Removing Existing Link2Root PowerShell Module Files for Reinstall..."
                        & "$PSScriptRoot\Uninstall-Link2Root.ps1" -KeepInstall -KeepPATH -Silent -Force
                        # Remove-Item -Path $modulePath -Recurse @NO_RISK_PARAMS
                    }
        
                    $tempFolders.Add($tempFolder, $modulePath)
                    # Write-Verbose "Moving Files to PowerShell Modules Folder..."
                    # Move-Item -Path $tempFolder -Destination $modulePath | Out-Null
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
                elseif (-not $Silent) {
                    # Write-Host ""
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
                        # $currentPATHContents = $currentPATH -split ";"
    
                        # $currentPATHContents.Remove($installLocation)
                        # [System.Environment]::SetEnvironmentVariable("PATH", $currentPATHContents -join ";");
                    }
    
                    Write-Verbose "Updating Current User's PATH..."
                    [System.Environment]::SetEnvironmentVariable(
                        "PATH",
                        "$currentPATH;$installLocation",
                        [EnvironmentVariableTarget]::User
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

        # Only once all installation tasks have completed successfully
        # will we move the temporary folders to their actual destinations.
        foreach ($tempFolder in $tempFolders.Keys) {
            Write-Verbose "Moving Files from $tempFolder to $($tempFolders[$tempFolder])..."
            Move-Item -Path $tempFolder -Destination $tempFolders[$tempFolder] | Out-Null
        }
    }

    if (-not $Silent) {
        if ($success) {
            Write-Host "Successfully $($installerVerb.ToString().ToLower())ed " -NoNewline -ForegroundColor Green
            Write-Host "Link2Root" -NoNewline -ForegroundColor Cyan
            Write-Host "!" -ForegroundColor Green
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
        Write-Host "Failed to $($installerVerb.ToString().ToLower()) " -NoNewline -ForegroundColor Red
        Write-Host "Link2Root" -NoNewline -ForegroundColor Cyan
        Write-Host "!" -ForegroundColor Red
        Write-Host ""
    }
    
    if ($PassThru) {
        Write-Host $_ -ForegroundColor Red
        return $false
    }
    else {
        throw $_
    }
}