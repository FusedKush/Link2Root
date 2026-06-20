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
[CmdletBinding(DefaultParameterSetName = "WithOutput")]
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

    [switch]$Any,

    [Parameter(ParameterSetName = "WithoutOutputOrProgress", Mandatory)]
    [switch]$Silent,
    
    [Parameter(ParameterSetName = "WithoutOutput", Mandatory)]
    [switch]$NoOutput,

    [Alias("HideProgress")]
    [Parameter(ParameterSetName = "WithOutput")]
    [Parameter(ParameterSetName = "WithoutOutput")]
    [switch]$NoProgress,

    [Parameter(ParameterSetName = "WithOutput")]
    [Parameter(ParameterSetName = "WithoutOutput", Mandatory)]
    [Parameter(ParameterSetName = "WithoutOutputOrProgress", Mandatory)]
    [switch]$PassThru,

    [Parameter(DontShow)]
    [switch]$Internal,

    <#
        An internal parameter used to specify the indentation
        level to use for output logging.
    #>
    [Parameter(DontShow)]
    [int]$Indentation = 0
)


function Update-TestResult {
    param(
        [Parameter(ParameterSetName = "SuccessfulResult")]
        [switch]$Success,

        [Parameter(ParameterSetName = "FailureResult")]
        [switch]$Failure
    )

    if ($Failure -and -not $Any) {
        $script:result = $false
    }
    elseif ($Success -and $Any) {
        $script:result = $true
    }
}


Import-Module "$PSScriptRoot\Utils.psm1" -Verbose:($VerbosePreference -and -not $Internal)

[bool]$result = !$Any
[string]$installLocation = & "$PSScriptRoot\Get-Link2RootInstall.ps1"

if (-not ($TestInstall -or $TestModule -or $TestPATH)) {
    $TestInstall = $TestModule = $TestPATH = $true
}
if ($Silent) {
    $NoOutput = $true
    $NoProgress = $true
}

if (-not $NoProgress)   { Enable-ProgressBars }
else                    { Disable-ProgressBars }

Write-Verbose "$(Get-IndentString $Indentation)[>] Checking Current Installation Status of Link2Root..."
Add-ProgressBar -Name "Checking Link2Root Installation Status" -DefaultPercentageChange 40 -InitialSecondsRemaining 3
Update-ProgressBar -Status "Check Install Status" -CurrentOperation "Checking Status..." -PercentageChange 0

if ($TestInstall) {
    Write-Verbose "$(Get-IndentString ($Indentation + 1))[>] Checking Current Install Status..."

    if (Test-Path $installLocation -Type Container) {
        [hashtable]$mainCheckArgs = @{
            Source = "$PSScriptRoot/../"
            Install = $installLocation
            Exclude = "*[/\]Setup", "*[/\]Installation"
            Verbose = $VerbosePreference
            Indentation = ($Indentation + 2)
        }
        [hashtable]$setupCheckArgs = @{
            Source = "$PSScriptRoot/../Setup"
            Install = "$installLocation/Installation"
            Exclude = $SETUP_FOLDER_IGNORED_FILES
            Verbose = $VerbosePreference
            Indentation = ($Indentation + 2)
        }
        
        Write-Verbose "$(Get-IndentString ($Indentation + 2))[+] Link2Root IS installed in $installLocation"
        
        if (-not $SkipInstallIntegrityCheck -and (Split-Path $PSScriptRoot -Parent) -ieq $installLocation) {
            Write-Verbose "$(Get-IndentString ($Indentation + 2))[/] Skipping Link2Root Installation Integrity Check because no reference files are available."
            $SkipInstallIntegrityCheck = $true
        }

        if ($SkipInstallIntegrityCheck -or ((Test-InstallIntegrity @mainCheckArgs) -and (Test-InstallIntegrity @setupCheckArgs))) {
            Write-Verbose "$(Get-IndentString ($Indentation + 1))[+] Current Install Status: INSTALLED"
            Update-ProgressBar -Status "Check Install Status" -CurrentOperation "Component Installed!"
            Update-TestResult -Success
            
            if (-not $NoOutput) {
                _wcp -Success
                _wc "Link2Root" -NoNewline
                Write-Host " Installed" -NoNewline -ForegroundColor Green
                Write-Host " in " -NoNewline
                _wp $installLocation
            }
        }
        else {
            Write-Verbose "$(Get-IndentString ($Indentation + 2))[-] Integrity Check Failed for $installLocation"
            Write-Verbose "$(Get-IndentString ($Indentation + 1))[-] Current Install Status: NOT INSTALLED"
            Update-ProgressBar -Status "Check Install Status" -CurrentOperation "Component Damaged!"
            Update-TestResult -Failure

            if (-not $NoOutput) {
                _wcp -Failed
                _wc "Link2Root" -NoNewline
                Write-Host " has " -NoNewline
                Write-Host "Missing or Damaged Files" -NoNewline -ForegroundColor Red
                Write-Host " in " -NoNewline
                _wp $installLocation
            }

        }
    }
    else {
        Write-Verbose "$(Get-IndentString ($Indentation + 2))[-] Link2Root is NOT installed in $installLocation"
        Write-Verbose "$(Get-IndentString ($Indentation + 1))[-] Current Install Status: NOT INSTALLED"
        Update-ProgressBar -Status "Check Install Status" -CurrentOperation "Component Missing!"
        Update-TestResult -Failure
        
        if (-not $NoOutput) {
            _wcp -Failed
            _wc "Link2Root" -NoNewline
            Write-Host " NOT Installed" -NoNewline -ForegroundColor Red
            Write-Host " in " -NoNewline
            _wp $installLocation
        }
    }
}
else {
    Write-Verbose "$(Get-IndentString ($Indentation + 1))[/] Skipping Current Install Status Check"
    Update-ProgressBar -Status "Check Install Status" -CurrentOperation "Component Test Skipped"
}


Update-ProgressBar -Status "Check PowerShell Module Status" -CurrentOperation "Checking Status..." -PercentageChange 0

if ($TestModule) {
    Write-Verbose "$(Get-IndentString ($Indentation + 1))[>] Checking Current PowerShell Module Status..."
    
    [string]$modulePath = (& "$PSScriptRoot\Get-Link2RootInstall.ps1" -GetModulePath -Internal:$Internal -Indentation ($Indentation + 2))

    if (Test-Path $modulePath -Type Container) {
        [hashtable]$integrityCheckArgs = @{
            Source = "$PSScriptRoot/../"
            Install = $modulePath
            Filter = "Link2Root.ps*1"
            Verbose = $VerbosePreference
            Indentation = ($Indentation + 2)
        }

        Write-Verbose "$(Get-IndentString ($Indentation + 2))[+] The Link2Root PowerShell Module IS installed in $modulePath"

        if (-not $SkipModuleIntegrityCheck -and (Split-Path $PSScriptRoot -Parent) -ieq $installLocation) {
            Write-Verbose "$(Get-IndentString ($Indentation + 2))[/] Skipping Link2Root PowerShell Module Integrity Check because no reference files are available."
            $SkipModuleIntegrityCheck = $true
        }

        if ($SkipModuleIntegrityCheck -or (Test-InstallIntegrity @integrityCheckArgs)) {
            Write-Verbose "$(Get-IndentString ($Indentation + 1))[+] Current PowerShell Module Status: INSTALLED"
            Update-ProgressBar -Status "Check PowerShell Module Status" -CurrentOperation "Component Installed!" -PercentageChange 20
            Update-TestResult -Success
            
            if (-not $NoOutput) {
                _wcp -Success
                _wc "Link2Root PowerShell Module" -NoNewline
                Write-Host " Installed" -NoNewline -ForegroundColor Green
                Write-Host " in " -NoNewline
                _wp $modulePath
            }
        }
        else {
            Write-Verbose "$(Get-IndentString ($Indentation + 1))[-] Current PowerShell Module Status: NOT INSTALLED"
            Update-ProgressBar -Status "Check PowerShell Module Status" -CurrentOperation "Component Damaged!" -PercentageChange 20
            Update-TestResult -Failure
            
            if (-not $NoOutput) {
                _wcp -Failed
                _wc "Link2Root PowerShell Module" -NoNewline
                Write-Host " has " -NoNewline
                Write-Host "Missing or Damaged Files" -NoNewline -ForegroundColor Red
                Write-Host " in " -NoNewline
                _wp $installLocation
            }
        }
    }
    else {
        Write-Verbose "$(Get-IndentString ($Indentation + 2))[-] The Link2Root PowerShell Module is NOT installed in $modulePath"
        Write-Verbose "$(Get-IndentString ($Indentation + 1))[-] Current PowerShell Module Status: NOT INSTALLED"
        Update-ProgressBar -Status "Check PowerShell Module Status" -CurrentOperation "Component Missing!" -PercentageChange 20
        Update-TestResult -Failure

        if (-not $NoOutput) {
            _wcp -Failed
            _wc "Link2Root PowerShell Module" -NoNewline
            Write-Host " NOT Installed" -NoNewline -ForegroundColor Red
            Write-Host " in " -NoNewline
            _wp $modulePath
        }
    }
}
else {
    Write-Verbose "$(Get-IndentString ($Indentation + 1))[/] Skipping Current PowerShell Module Status Check"
    Update-ProgressBar -Status "Check PowerShell Module Status" -CurrentOperation "Component Test Skipped" -PercentageChange 20
}


Update-ProgressBar -Status "Check PATH Status" -CurrentOperation "Checking Status..." -PercentageChange 0

if ($TestPATH) {
    [string]$username = Get-FullyQualifiedUsername

    Write-Verbose "$(Get-IndentString ($Indentation + 1))[>] Checking Current PATH..."
    
    if (Test-UserPATH $installLocation -Indentation ($Indentation + 2) -Verbose:$VerbosePreference) {
        # Write-Verbose "$(Get-IndentString ($Indentation + 2))[+] Entry $installLocation FOUND in $username's PATH"
        Write-Verbose "$(Get-IndentString ($Indentation + 1))[+] Current PATH Status: FOUND"
        Update-ProgressBar -Status "Check PATH Status" -CurrentOperation "Component Installed!"
        Update-TestResult -Success
        
        if (-not $NoOutput) {
            _wcp -Success
            _wc "Link2Root" -NoNewline
            Write-Host " Added" -NoNewline -ForegroundColor Green
            Write-Host " to " -NoNewline
            _wp "$username's PATH"
        }
    }
    else {
        Write-Verbose "$(Get-IndentString ($Indentation + 2))[-] Entry $installLocation NOT found in $username's PATH"
        Write-Verbose "$(Get-IndentString ($Indentation + 1))[-] Current PATH Status: NOT FOUND"
        Update-ProgressBar -Status "Check Install Status" -CurrentOperation "Component Missing!"
        Update-TestResult -Failure
        
        if (-not $NoOutput) {
            _wcp -Failed
            _wc "Link2Root" -NoNewline
            Write-Host " NOT Added" -NoNewline -ForegroundColor Red
            Write-Host " to " -NoNewline
            _wp "$username's PATH"
        }
    }
}
else {
    Write-Verbose "$(Get-IndentString ($Indentation + 1))[/] Skipping Current PATH Check"
    Update-ProgressBar -Status "Check PATH Status" -CurrentOperation "Component Test Skipped"
}


Remove-ProgressBar

if ($result) {
    Write-Verbose "$(Get-IndentString $Indentation)[+] Link2Root IS considered to be installed"
}
else {
    Write-Verbose "$(Get-IndentString $Indentation)[-] Link2Root is NOT considered to be installed"
}

if (-not $NoOutput) {
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