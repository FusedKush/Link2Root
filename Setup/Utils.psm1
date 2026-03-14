[hashtable]$NO_RISK_PARAMS = @{
    WhatIf = $false
    Confirm = $false
}

function Get-UserPATH {

    param(
        [switch]$Raw
    )

    [string]$path = [System.Environment]::GetEnvironmentVariable("PATH", "User")

    if ($Raw) {
        return $path
    }

    return $path -split ";"

}

function Resolve-UserPATH {

    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string[]]$PATH,

        [Parameter(ParameterSetName = "AsString", Mandatory)]
        [switch]$ToString,
        
        [Parameter(ParameterSetName = "AsArray", Mandatory)]
        [switch]$ToArray
    )

    process {
        if ($ToString) {
            if ($PATH.Count -gt 1) { return $PATH -join ";" }
            else                   { return $PATH }
        }
        else {
            if ($PATH.Count -gt 1) { return $PATH }
            else                   { return $PATH -split ";" }
        }
    }

}

function Set-UserPATH {

    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string[]]$PATH
    )

    [System.Environment]::SetEnvironmentVariable(
        "PATH",
        (Resolve-UserPATH $PATH -ToString),
        "USER"
    )

}

function Test-UserPATH {

    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]$Entry,

        [Parameter(Position = 2)]
        [string[]]$PATH = (Get-UserPATH)
    )

    process {
        return ((Resolve-UserPATH $PATH -ToArray) -contains $Entry)
    }

}

function Get-FullyQualifiedUsername {

    [OutputType([string])]
    param()

    return "\\${env:USERDOMAIN}\${env:USERNAME}"

}

function Write-ComponentUpdatePrefix {

    [CmdletBinding(DefaultParameterSetName = "WithoutSuccessOrFailure")]
    param(
        [Parameter(ParameterSetName = "WithSuccess")]
        [switch]$Success,

        [Parameter(ParameterSetName = "WithFailure")]
        [switch]$Failed
    )

    $writeHostArgs = @{}

    if ($Success) {
        $writeHostArgs["Object"] = "+"
        $writeHostArgs["ForegroundColor"] = "Green"
    }
    elseif ($Failed) {
        $writeHostArgs["Object"] = "-"
        $writeHostArgs["ForegroundColor"] = "Red"
    }
    else {
        $writeHostArgs["Object"] = "/"
        $writeHostArgs["ForegroundColor"] = "DarkYellow"
    }

    Write-Host "[" -NoNewline
    Write-Host @writeHostArgs -NoNewline
    Write-Host "] " -NoNewline

}

function Write-EndRestartNotice {

    Write-Host "You may have to restart your console session or terminal window for changes to take effect." -ForegroundColor DarkYellow

}

function Write-Path {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path,

        [switch]$NoNewline
    )

    process {
        Write-Host $Path -NoNewline:$NoNewline -ForegroundColor Cyan
    }

}

function Write-Component {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]$Component,

        [switch]$NoNewline
    )

    process {
        Write-Host $Component -NoNewline:$NoNewline -ForegroundColor Yellow
    }

}

Export-ModuleMember -Function * -Variable *