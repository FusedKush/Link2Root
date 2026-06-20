<#
    .SYNOPSIS
    Get the path to where Link2Root is or will be installed.

    .DESCRIPTION
    Retrieve the path to where Link2Root is or will be installed.

    By default, this function retrieves the path to the Link2Root Installation Directory.
    However, when the `-GetModulePath` switch is used, the path to the
    Link2Root PowerShell Module Directory will be retrieved instead.

    This function will always return the same results, regardless of if
    Link2Root is currently installed or not.

    .INPUTS
    None.
    You cannot pipe objects to `Get-Link2RootInstall.ps1`.

    .OUTPUTS
    String.
    `Get-Link2RootInstall.ps1` returns a string containing the path to
    the Link2Root installation or module directory.

    .EXAMPLE
    .\Get-Link2RootInstall.ps1
    C:\Users\FusedKush\AppData\Local\PowerShell Link2Root

    .EXAMPLE
    .\Get-Link2RootInstall.ps1 -GetModulePath
    C:\Users\FusedKush\Documents\PowerShell\Modules\Link2Root
#>
[CmdletBinding()]
param(
    <#
        Indicates that the path to the Link2Root PowerShell Module should be
        returned instead of the path to the Link2Root Installation Directory.

        By default and when this switch is omitted, the path to the
        Link2Root Installation Directory will be returned instead.
    #>
    [switch]$GetModulePath,

    [Parameter(DontShow)]
    [switch]$Internal,

    <#
        An internal parameter used to specify the indentation
        level to use for output logging.
    #>
    [Parameter(DontShow)]
    [int]$Indentation = 0
)


if ($Internal) {
    $VerbosePreference = $false
}


[string]$PROGRAM_NAME = "Link2Root"
[string]$MODULE_NAME = "Link2Root"


if (-not $GetModulePath) {
    return (Join-Path $env:LOCALAPPDATA $PROGRAM_NAME)
}
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