<#
    .SYNOPSIS
    Test if Link2Root is currently installed.

    .DESCRIPTION
    Test if Link2Root is installed for the current user or not.

    By default, Link2Root will only be considered to be installed
    if it is present in the expected installation location, added
    to the current user's PowerShell Modules, and added to the user's PATH.

       - To specify which aspects of the installation to test,
         use the `-TestInstall`, `-TestModule`, and `-TestPATH` switches.
       
       - To specify that the presence of *any* component should indicate that Link2Root
         is currently installed, use the `-Any` switch.

    By default, the progress and results of the installation will be printed
    to the console, as well as visualized using a progress bar. To control this
    behavior and disable output logging and/or progress bars, use the `-Silent`,
    `-NoOutput`, and `-NoProgress` switches.

       - `-Silent` is shorthand for both `-NoOutput` and `-NoProgress`.

       - If you use the `-NoOutput` or `-Silent` switches, you must use the `-PassThru`
         switch to be able to obtain any results from the function.

    .INPUTS
    None.
    You cannot pipe objects to `Test-Link2RootInstall.ps1`.

    .OUTPUTS
    Bool.
    `Test-Link2RootInstall.ps1` returns `$true` if Link2Root is considered
    to be installed for the current user or `$false` if it is not.

    .EXAMPLE
    .\Test-Link2RootInstall.ps1
    [+] Link2Root Installed in C:\Users\FusedKush\AppData\Local\Link2Root
    [-] Link2Root PowerShell Module NOT Installed in C:\Libraries\FusedKush\Documents\PowerShell\Modules\Link2Root
    [+] Link2Root Added to My-PC\FusedKush's PATH
    Link2Root is NOT Currently Installed!

    Tests for the existence of the Link2Root Installation Files,
    the Link2Root PowerShell Module, AND Link2Root in the User's PATH.

    .EXAMPLE
    .\Test-Link2RootInstall.ps1
    [+] Link2Root Installed in C:\Users\FusedKush\AppData\Local\Link2Root -Any
    [-] Link2Root PowerShell Module NOT Installed in C:\Libraries\FusedKush\Documents\PowerShell\Modules\Link2Root
    [+] Link2Root Added to My-PC\FusedKush's PATH
    Link2Root is Currently Installed!

    Tests for the existence of the Link2Root Installation Files,
    the Link2Root PowerShell Module, OR Link2Root in the User's PATH.

    .EXAMPLE
    .\Test-Link2RootInstall.ps1 -TestModule -PassThru
    [-] Link2Root PowerShell Module Installed in C:\Libraries\FusedKush\Documents\PowerShell\Modules\Link2Root
    Link2Root is NOT Currently Installed!
    False

    Tests only for the existence of the Link2Root PowerShell Module while
    also returning the result of the test.

    .EXAMPLE
    .\Test-Link2RootInstall.ps1 -TestInstall -TestPATH -Silent -PassThru
    True

    Tests for the existence of both the Link2Root Installation Files
    and Link2Root in the User's PATH and only returns the result of the test
    without printing anything to the console.
#>
[CmdletBinding(DefaultParameterSetName = "WithOutput", PositionalBinding = $false)]
param(
    <#
        The individual components of the Link2Root Installation to be tested.

        If no components are specified, all of the
        Default Setup Components will be tested.
    #>
    [ArgumentCompleter({
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Get-SetupComponentArgumentCompletions
        Get-SetupComponentArgumentCompletions @args
    })]
    [Parameter(Position = 0)]
    [ValidateScript({
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Test-SetupComponentParameter
        $_ | Test-SetupComponentParameter
    })]
    [string[]]$Components = (& {
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Get-SetupComponents
        Get-SetupComponents -Filter Default
    }),

    <#
        Skip checking the integrity of the Link2Root Installation Directory.

        By default and when this switch is omitted, the integrity of the
        Link2Root Installation Directory and all of the files within will
        be validated and compared against the files in the parent directory
        of this script.

        This switch is implied when invoking the script from within the
        Link2Root Installation Directory itself.
    #>
    [switch]$SkipInstallIntegrityCheck,

    <#
        Skip checking the integrity of the Link2Root PowerShell Module.

        By default and when this switch is omitted, the integrity of the
        Link2Root PowerShell Module and all of the files within will
        be validated and compared against the files in the parent directory
        of this script.

        This switch is implied when invoking the script from within the
        Link2Root Installation Directory.
    #>
    [switch]$SkipModuleIntegrityCheck,

    <#
        Indicates that the existence of any specified component should
        reflect a valid Link2Root installation for the current user.
        
        By default and when this switch is omitted, ALL of the specified
        components have to be present in order for Link2Root to be
        considered to be installed for the current user.
    #>
    [switch]$Any,
    
    <#
        Indicates that no output should be printed to the terminal
        by the script.

        By default and when neither this switch nor `-Silent` are used,
        the status and results of the script are printed to the terminal.

        If this switch is used, it MUST be combined with `-PassThru` in order
        to obtain any results from this script.

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

        If this switch is used, it MUST be combined with `-PassThru` in order
        to obtain any results from this script.

        Has no effect on verbose output or progress bars created by built-in
        functions and cmdlets. To control the behavior of all PowerShell progress bars,
        use the `$ProgressPreference` automatic variable.
    #>
    [Parameter(ParameterSetName = "WithoutOutputOrProgress", Mandatory)]
    [switch]$Silent,

    <#
        Indicates that the script should return the results of the
        test as a boolean value.

        By default and when this switch is omitted, this function
        does not generate any output.

        If the `-NoOutput` or `-Silent` switches are used, this switch
        MUST be used in order to obtain any results from the script.
    #>
    [Parameter(ParameterSetName = "WithOutput")]
    [Parameter(ParameterSetName = "WithoutOutput", Mandatory)]
    [Parameter(ParameterSetName = "WithoutOutputOrProgress", Mandatory)]
    [switch]$PassThru,

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

Import-Module "$PSScriptRoot\Utils.psm1" -Verbose:($VerbosePreference -and -not $Internal)


# Variables and Helper Functions #

# The final result of the test, managed by `Update-TestResult`
[bool]$result = !$Any
# The location where Link2Root is supposed to be installed
[string]$installLocation = & "$PSScriptRoot\Get-Link2RootInstall.ps1"

<#
    Update the final result of the test based
    on the result of testing a specific component and
    the presence or absence of the `-Any` switch to the script.
#>
function Update-TestResult {
    param(
        <#
            Indicates that the component test passed.
        #>
        [Parameter(ParameterSetName = "SuccessfulResult")]
        [switch]$Success,

        <#
            Indicates that the component test failed.
        #>
        [Parameter(ParameterSetName = "FailureResult")]
        [switch]$Failure
    )

    if ($Failure -and -not $Any) { $script:result = $false }
    elseif ($Success -and $Any)  { $script:result = $true }
}


# Main Script #

if ($Silent) {
    $NoOutput = $NoProgress = $true
}

Write-Verbose "$(_gis $Indentation)[>] Checking Current Installation Status of Link2Root..."
Hide-ProgressBars $NoProgress
Add-ProgressBar -Name "Checking Link2Root Installation Status" -DefaultPercentageChange 40 -InitialSecondsRemaining 3


# Check for the presence and validity of the Link2Root Installation Files
_upb -Status "Check Install Status" -CurrentOperation "Checking Status..." -PercentageChange 0
Write-Verbose "$(_gis ($Indentation + 1))[>] Checking Current Install Status..."

if ($Components -icontains "LocalInstall") {
    Write-Verbose "$(_gis ($Indentation + 2))[+] 'LocalInstall' Component Included in Test"

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
        
        Write-Verbose "$(_gis ($Indentation + 2))[+] Link2Root IS installed in $installLocation"
        
        if (-not $SkipInstallIntegrityCheck -and (Split-Path $PSScriptRoot -Parent) -ieq $installLocation) {
            Write-Verbose "$(_gis ($Indentation + 2))[/] Skipping Link2Root Installation Integrity Check because no reference files are available."
            $SkipInstallIntegrityCheck = $true
        }

        if ($SkipInstallIntegrityCheck -or ((Test-InstallIntegrity @mainCheckArgs) -and (Test-InstallIntegrity @setupCheckArgs))) {
            Write-Verbose "$(_gis ($Indentation + 1))[+] Current Install Status: INSTALLED"
            _upb -Status "Check Install Status" -CurrentOperation "Component Installed!"
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
            Write-Verbose "$(_gis ($Indentation + 2))[-] Integrity Check Failed for $installLocation"
            Write-Verbose "$(_gis ($Indentation + 1))[-] Current Install Status: NOT INSTALLED"
            _upb -Status "Check Install Status" -CurrentOperation "Component Damaged!"
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
        Write-Verbose "$(_gis ($Indentation + 2))[-] Link2Root is NOT installed in $installLocation"
        Write-Verbose "$(_gis ($Indentation + 1))[-] Current Install Status: NOT INSTALLED"
        _upb -Status "Check Install Status" -CurrentOperation "Component Missing!"
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
    Write-Verbose "$(_gis ($Indentation + 2))[-] 'LocalInstall' Component Excluded from Test"
    Write-Verbose "$(_gis ($Indentation + 1))[/] Skipping Current Install Status Check"
    _upb -Status "Check Install Status" -CurrentOperation "Component Test Skipped"
}


# Check for the presence and validity of the Link2Root PowerShell Module
_upb -Status "Check PowerShell Module Status" -CurrentOperation "Checking Status..." -PercentageChange 0
Write-Verbose "$(_gis ($Indentation + 1))[>] Checking Current PowerShell Module Status..."

if ($Components -icontains "PowerShellModule") {
    Write-Verbose "$(_gis ($Indentation + 2))[+] 'PowerShellModule' Component Included in Test"
    
    [string]$modulePath = (
        & "$PSScriptRoot\Get-Link2RootInstall.ps1" `
            -GetModulePath `
            -Internal:$Internal `
            -Indentation ($Indentation + 2)
    )

    if (Test-Path $modulePath -Type Container) {
        [hashtable]$integrityCheckArgs = @{
            Source = "$PSScriptRoot/../"
            Install = $modulePath
            Filter = "Link2Root.ps*1"
            Verbose = $VerbosePreference
            Indentation = ($Indentation + 2)
        }

        Write-Verbose "$(_gis ($Indentation + 2))[+] The Link2Root PowerShell Module IS installed in $modulePath"

        if (-not $SkipModuleIntegrityCheck -and (Split-Path $PSScriptRoot -Parent) -ieq $installLocation) {
            Write-Verbose "$(_gis ($Indentation + 2))[/] Skipping Link2Root PowerShell Module Integrity Check because no reference files are available."
            $SkipModuleIntegrityCheck = $true
        }

        if ($SkipModuleIntegrityCheck -or (Test-InstallIntegrity @integrityCheckArgs)) {
            Write-Verbose "$(_gis ($Indentation + 1))[+] Current PowerShell Module Status: INSTALLED"
            _upb -Status "Check PowerShell Module Status" -CurrentOperation "Component Installed!" -PercentageChange 20
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
            Write-Verbose "$(_gis ($Indentation + 1))[-] Current PowerShell Module Status: NOT INSTALLED"
            _upb -Status "Check PowerShell Module Status" -CurrentOperation "Component Damaged!" -PercentageChange 20
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
        Write-Verbose "$(_gis ($Indentation + 2))[-] The Link2Root PowerShell Module is NOT installed in $modulePath"
        Write-Verbose "$(_gis ($Indentation + 1))[-] Current PowerShell Module Status: NOT INSTALLED"
        _upb -Status "Check PowerShell Module Status" -CurrentOperation "Component Missing!" -PercentageChange 20
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
    Write-Verbose "$(_gis ($Indentation + 2))[-] 'PowerShellModule' Component Excluded from Test"
    Write-Verbose "$(_gis ($Indentation + 1))[/] Skipping Current PowerShell Module Status Check"
    _upb -Status "Check PowerShell Module Status" -CurrentOperation "Component Test Skipped" -PercentageChange 20
}


# Check for the presence of Link2Root in the User's PATH
_upb -Status "Check PATH Status" -CurrentOperation "Checking Status..." -PercentageChange 0
Write-Verbose "$(_gis ($Indentation + 1))[>] Checking Current PATH..."

if ($Components -icontains "PATHUpdate") {
    [string]$username = Get-FullyQualifiedUsername
    
    Write-Verbose "$(_gis ($Indentation + 2))[+] 'PATHUpdate' Component Included in Test"
    
    if (Test-UserPATH $installLocation -Indentation ($Indentation + 2) -Verbose:$VerbosePreference) {
        Write-Verbose "$(_gis ($Indentation + 1))[+] Current PATH Status: FOUND"
        _upb -Status "Check PATH Status" -CurrentOperation "Component Installed!"
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
        Write-Verbose "$(_gis ($Indentation + 2))[-] Entry $installLocation NOT found in $username's PATH"
        Write-Verbose "$(_gis ($Indentation + 1))[-] Current PATH Status: NOT FOUND"
        _upb -Status "Check Install Status" -CurrentOperation "Component Missing!"
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
    Write-Verbose "$(_gis ($Indentation + 2))[-] 'PATHUpdate' Component Excluded from Test"
    Write-Verbose "$(_gis ($Indentation + 1))[/] Skipping Current PATH Check"
    _upb -Status "Check PATH Status" -CurrentOperation "Component Test Skipped"
}


# Cleanup and print and/or return the results
Remove-ProgressBar

if ($result) { Write-Verbose "$(_gis $Indentation)[+] Link2Root IS considered to be installed" }
else         { Write-Verbose "$(_gis $Indentation)[-] Link2Root is NOT considered to be installed" }

if (-not $NoOutput) {
    _wc "Link2Root" -NoNewline
    Write-Host " is " -NoNewline

    if ($result) { Write-Host "Currently Installed!" -ForegroundColor Green }
    else         { Write-Host "NOT Currently Installed!" -ForegroundColor Red }
}

if ($PassThru) {
    return $result
}