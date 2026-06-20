<#
    .SYNOPSIS
    Get the path to where Link2Root is or will be installed.

    .DESCRIPTION
    Retrieve the path to where Link2Root is or will be installed.

    By default, this function retrieves the path to the Link2Root Installation Directory.
    However, when the `-GetModulePath` switch is used, the path to the
    Link2Root PowerShell Module Directory will be retrieved instead.

    .NOTES
    This function will always return the same results, regardless of if
    Link2Root or the Link2Root PowerShell Module is currently installed.

    .INPUTS
    None.
    You cannot pipe objects to `Get-Link2RootInstall.ps1`.

    .OUTPUTS
    String.
    `Get-Link2RootInstall.ps1` returns a string containing the path to
    the Link2Root installation or module directory.

    If the `-GetModulePath` switch is used and no eligible PowerShell Module Path
    could be found, returns `$null`.

    .EXAMPLE
    .\Get-Link2RootInstall.ps1
    C:\Users\FusedKush\AppData\Local\PowerShell Link2Root

    Retrieves the path to where Link2Root is or will be installed.

    .EXAMPLE
    .\Get-Link2RootInstall.ps1 -GetModulePath
    C:\Users\FusedKush\Documents\PowerShell\Modules\Link2Root

    Retrieves the path to where the Link2Root PowerShell Module
    is or will be installed.
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    <#
        Indicates that the path to the Link2Root PowerShell Module should be
        returned instead of the path to the Link2Root Installation Directory.

        By default and when this switch is omitted, the path to the
        Link2Root Installation Directory will be returned instead.
    #>
    [switch]$GetModulePath,

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


# Constants #

[string]$PROGRAM_NAME = "Link2Root"
[string]$MODULE_NAME = "Link2Root"


# Main Script #

if ($Internal) {
    $VerbosePreference = $false
}

# Retrieve Installation Path
if (-not $GetModulePath) {
    return (Join-Path $env:LOCALAPPDATA $PROGRAM_NAME)
}
# Retrieve PowerShell Module Path
else {
    Write-Verbose "$(Get-IndentString $Indentation)[>] Determining Link2Root PowerShell Module Path..."

    # Search for the first user-specific module location
    foreach ($path in ($env:PSModulePath -split ";")) {
        if ($path -ilike "*\Documents\PowerShell*" -or $path -ilike "*\Documents\WindowsPowerShell*") {
            Write-Verbose "$(Get-IndentString ($Indentation + 1))[+] Checked Candidate Module Path: $path"
            Write-Verbose "$(Get-IndentString $Indentation)[+] Found Eligible PowerShell Module Path: $path"
            return (Join-Path $path $MODULE_NAME)
        }
        else {
            Write-Verbose "$(Get-IndentString ($Indentation + 1))[-] Checked Candidate Module Path: $path"
        }
    }

    Write-Verbose "$(Get-IndentString $Indentation)[-] No Eligible PowerShell Module Path Found!"
}