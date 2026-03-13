<#
    .FORWARDHELPTARGETNAME Test-Link2Root
#>
param()

Import-Module (Resolve-Path "$PSScriptRoot/../Link2Root.psm1")

if ($args.Count -gt 0)  { Test-Link2Root @args }
else                    { Test-Link2Root }