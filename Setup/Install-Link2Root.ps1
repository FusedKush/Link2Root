[CmdletBinding(SupportsShouldProcess)]
param(
    [Alias("Repair")]
    [switch]$Reinstall,
    
    [switch]$Force,
    
    [switch]$PassThru,
    
    [switch]$Silent,
    
    [bool]$SkipScriptInstall,
    
    [bool]$SkipModuleInstall,
    
    [bool]$SkipPATHUpdate
)

enum InstallerVerb {
    Install
    Repair
}

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

[InstallerVerb]$installerVerb = "Install"

try {
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
        $installerVerb = "Repair"
    }

    if ($Force -or $PSCmdlet.ShouldContinue("$installerVerb Link2Root", "Confirm", [ref]$yesToAll, [ref]$noToAll)) {
        [string]$currentPATH = [System.Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
        [bool]$scriptIsInstalled = (Test-Path $installLocation)
        [bool]$moduleIsInstalled = (Test-Path $modulePath)
        [bool]$isAddedToPATH = $currentPATH -contains $installLocation

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