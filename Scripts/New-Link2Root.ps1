<#
    .FORWARDHELPTARGETNAME New-Link2Root
#>
param()

Import-Module (Resolve-Path "$PSScriptRoot/../Link2Root.psm1")

if ($args.Count -gt 0)  { New-Link2Root @args }
else                    { New-Link2Root }