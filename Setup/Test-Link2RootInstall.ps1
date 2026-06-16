<#
    .SYNOPSIS
    Test if Link2Root is installed or not.

    .DESCRIPTION
    Test if Link2Root is currently installed on the computer.

    By default, Link2Root will only be considered to be installed
    if it is present in the expected installation location, added
    to the current user's PowerShell Modules, and added to the user's PATH.
    To specify which aspects of the installation to test,
    use the `-TestInstall`, `-TestModule`, and `-TestPATH` switches.

    .INPUTS
    None.
    You cannot pipe objects to `Test-Link2RootInstall.ps1`.

    .OUTPUTS
    Bool.
    Returns `$true` if Link2Root is currently installed on the computer
    or `$false` if it is not.

    .EXAMPLE
    .\Test-Link2RootInstall.ps1
    False

    .EXAMPLE
    .\Test-Link2RootInstall.ps1 -TestModule
    True

    .EXAMPLE
    .\Test-Link2RootInstall.ps1 -TestInstall -TestPATH
    False
#>
param(
    <#
        Indicates that the existence of the
        Link2Root Installation Directory should be tested.
    #>
    [switch]$TestInstall,

    <#
        Skip checking the integrity of the Link2Root Installation Directory.

        By default and when this switch is omitted, the integrity of the
        Link2Root Installation Directory and all of the files within will
        be validated and compared against the files in the parent directory
        of this cmdlet.

        This switch is implied when invoking this cmdlet from within the
        Link2Root Installation Directory itself.
    #>
    [switch]$SkipInstallIntegrityCheck,
    
    <#
        Indicates that the existence of the
        Link2Root PowerShell Module should be tested.
    #>
    [switch]$TestModule,

    <#
        Skip checking the integrity of the Link2Root PowerShell Module.

        By default and when this switch is omitted, the integrity of the
        Link2Root PowerShell Module and all of the files within will
        be validated and compared against the files in the parent directory
        of this cmdlet.

        This switch is implied when invoking this cmdlet from within the
        Link2Root Installation Directory.
    #>
    [switch]$SkipModuleIntegrityCheck,
    
    <#
        Indicates that the existence of the
        Link2Root Installation Directory in the
        current user's PATH should be tested.
    #>
    [switch]$TestPATH,

    [switch]$Silent,
    [switch]$PassThru,

    [Parameter(DontShow)]
    [switch]$Internal
)


Import-Module "$PSScriptRoot\Utils.psm1" -Verbose:($VerbosePreference -and -not $Internal)

[bool]$result = $true
[string]$installLocation = & "$PSScriptRoot\Get-Link2RootInstall.ps1"


Write-Verbose "Testing Current Installation Status of Link2Root"

if (-not ($TestInstall -or $TestModule -or $TestPATH)) {
    $TestInstall = $TestModule = $TestPATH = $true
}

if ($TestInstall) {
    if (Test-Path $installLocation -Type Container) {
        [hashtable]$integrityCheckArgs = @{
            Source = "$PSScriptRoot/../"
            Install = $installLocation
            Exclude = $SETUP_FOLDER_IGNORED_FILES
            Verbose = $VerbosePreference
        }
        
        Write-Verbose "Link2Root IS installed in $installLocation"
        
        if (-not $SkipInstallIntegrityCheck -and (Split-Path $PSScriptRoot -Parent) -ieq $installLocation) {
            Write-Verbose "Skipping Link2Root Installation Integrity Check because no reference files are available."
            $SkipInstallIntegrityCheck = $true
        }

        if ($SkipInstallIntegrityCheck -or (Test-InstallIntegrity @integrityCheckArgs)) {    
            if (-not $Silent) {
                _wcp -Success
                _wc "Link2Root" -NoNewline
                Write-Host " Installed" -NoNewline -ForegroundColor Green
                Write-Host " in " -NoNewline
                _wp $installLocation
            }
        }
        else {
            Write-Verbose "Integrity Check Failed for $installLocation"

            if (-not $Silent) {
                _wcp -Failed
                _wc "Link2Root" -NoNewline
                Write-Host " has " -NoNewline
                Write-Host "Missing or Damaged Files" -NoNewline -ForegroundColor Red
                Write-Host " in " -NoNewline
                _wp $installLocation
                $result = $false
            }
        }
    }
    else {
        Write-Verbose "Link2Root is NOT installed in $installLocation"
        
        if (-not $Silent) {
            _wcp -Failed
            _wc "Link2Root" -NoNewline
            Write-Host " NOT Installed" -NoNewline -ForegroundColor Red
            Write-Host " in " -NoNewline
            _wp $installLocation
            $result = $false
        }
    }
}

if ($TestModule) {
    [string]$modulePath = (& "$PSScriptRoot\Get-Link2RootInstall.ps1" -GetModulePath -Internal:$Internal)
    
    if (Test-Path $modulePath -Type Container) {
        [hashtable]$integrityCheckArgs = @{
            Source = "$PSScriptRoot/../"
            Install = $modulePath
            Filter = "Link2Root.ps*1"
            Verbose = $VerbosePreference
        }

        Write-Verbose "The Link2Root PowerShell Module IS installed in $modulePath"

        if (-not $SkipModuleIntegrityCheck -and (Split-Path $PSScriptRoot -Parent) -ieq $installLocation) {
            Write-Verbose "Skipping Link2Root PowerShell Module Integrity Check because no reference files are available."
            $SkipModuleIntegrityCheck = $true
        }

        if ($SkipModuleIntegrityCheck -or (Test-InstallIntegrity @integrityCheckArgs)) {
            if (-not $Silent) {
                _wcp -Success
                _wc "Link2Root PowerShell Module" -NoNewline
                Write-Host " Installed" -NoNewline -ForegroundColor Green
                Write-Host " in " -NoNewline
                _wp $modulePath
            }
        }
        else {
            Write-Verbose "Integrity Check Failed for $modulePath"

            if (-not $Silent) {
                _wcp -Failed
                _wc "Link2Root PowerShell Module" -NoNewline
                Write-Host " has " -NoNewline
                Write-Host "Missing or Damaged Files" -NoNewline -ForegroundColor Red
                Write-Host " in " -NoNewline
                _wp $installLocation
                $result = $false
            }
        }
    }
    else {
        Write-Verbose "The Link2Root PowerShell Module is NOT installed in $modulePath"

        if (-not $Silent) {
            _wcp -Failed
            _wc "Link2Root PowerShell Module" -NoNewline
            Write-Host " NOT Installed" -NoNewline -ForegroundColor Red
            Write-Host " in " -NoNewline
            _wp $modulePath
            $result = $false
        }
    }
}

if ($TestPATH) {
    [string]$username = Get-FullyQualifiedUsername
    
    if (Test-UserPATH $installLocation) {
        Write-Verbose "Entry $installLocation FOUND in $username's PATH"

        if (-not $Silent) {
            _wcp -Success
            _wc "Link2Root" -NoNewline
            Write-Host " Added" -NoNewline -ForegroundColor Green
            Write-Host " to " -NoNewline
            _wp "$username's PATH"
        }
    }
    else {
        Write-Verbose "Entry $installLocation NOT found in $username's PATH"

        if (-not $Silent) {
            _wcp -Failed
            _wc "Link2Root" -NoNewline
            Write-Host " NOT Added" -NoNewline -ForegroundColor Red
            Write-Host " to " -NoNewline
            _wp "$username's PATH"
        }
        $result = $false
    }
}


if ($result) {
    Write-Verbose "Link2Root IS considered to be installed"
}
else {
    Write-Verbose "Link2Root is NOT considered to be installed"
}

if (-not $Silent) {
    _wc "Link2Root" -NoNewline
    Write-Host " is " -NoNewline

    if ($result) {
        Write-Host "Currently Installed!" -ForegroundColor Green
    }
    else {
        Write-Host "NOT Currently Installed!" -ForegroundColor Red
    }
}

if ($PassThru) {
    return $result
}