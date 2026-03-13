<#
    .FORWARDHELPTARGETNAME Remove-Link2Root
#>
param()

Import-Module (Resolve-Path "$PSScriptRoot/../Link2Root.psm1")

if ($args.Count -gt 0)  { Remove-Link2Root @args }
else                    { Remove-Link2Root }