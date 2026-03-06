<#
    .FORWARDHELPTARGETNAME Get-Link2Root
#>
param()

Import-Module (Resolve-Path "$PSScriptRoot/../Link2Root.psm1")

if ($args.Count -gt 0) {
    Get-Link2Root @args
}
else {
    Get-Link2Root
}