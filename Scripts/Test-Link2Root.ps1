<#
    .FORWARDHELPTARGETNAME Test-Link2Root
#>
[CmdletBinding()]
param()

Push-Location
Set-Location "../"
Import-Module (Join-Path $PSScriptRoot "Link2Root.psm1")
Test-Link2Root @args
Pop-Location