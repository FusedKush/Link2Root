param(
    [switch]$GetModulePath
)

$PROGRAM_NAME = "PowerShell Link2Root"
$MODULE_NAME = "Link2Root"

if (-not $GetModulePath) {
    return (Join-Path $env:LOCALAPPDATA $PROGRAM_NAME)
}
else {
    # Search for the first user-specific module location
    foreach ($path in ($env:PSModulePath -split ";")) {
        if ($path -inotlike "C:\Program Files*" -and $path -inotlike "C:\Windows*") {
            return (Join-Path $path $MODULE_NAME)
        }
    }
}