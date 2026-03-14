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

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string[]]$PATH
    )

    begin {
        [string[]]$fullPATH = $PATH
    }
    process {
        if ($null -ne $_) {
            $fullPATH += @($_)
        }
    }
    end {
        [string]$resolvedPATH = (Resolve-UserPATH $fullPATH -ToString)
    
        Write-Verbose "Updating $(Get-FullyQualifiedUsername)'s PATH to: $resolvedPATH"
        [System.Environment]::SetEnvironmentVariable("PATH", $resolvedPATH, "USER")
    }

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

function Test-FilePattern {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string]$Path,

        [string]$Filter,
        [string[]]$Include,
        [string[]]$Exclude,

        [Parameter(DontShow)]
        [int]$Indentation = 0
    )

    foreach ($Pattern in $Exclude) {
        if ($Path -ilike $Pattern) {
            Write-Verbose "$('  ' * $Indentation)File Skipped due to Matching Exclusion Pattern:"
            Write-Verbose "$('  ' * $Indentation)  File: $Path"
            Write-Verbose "$('  ' * $Indentation)  Pattern: $Pattern"
            return $false
        }
    }

    if ($Include.Count -gt 0) {
        foreach ($Pattern in $Include) {
            if ($Path -ilike $Pattern) {
                Write-Verbose "$('  ' * $Indentation)File Included by Inclusion Pattern:"
                Write-Verbose "$('  ' * $Indentation)  File: $Path"
                Write-Verbose "$('  ' * $Indentation)  Pattern: $Pattern"
                return $true
            }
        }
        
        Write-Verbose "$('  ' * $Indentation)File Skipped due to Non-Matching Inclusion Pattern:"
        Write-Verbose "$('  ' * $Indentation)  File: $Path"
        Write-Verbose "$('  ' * $Indentation)  Patterns: $($Include -join ', ')"
        return $false
    }

    return $true

}

function Test-InstallIntegrity {

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string]$Source,

        [Parameter(Mandatory, Position = 2, ValueFromPipeline)]
        [string]$Install,

        [string]$Filter,
        [string[]]$Include,
        [string[]]$Exclude
    )


    [hashtable]$commonArgs = @{
        Filter = $Filter
        Include = $Include
        Exclude = $Exclude
    }
    [string]$resolvedInstallPath = Resolve-Path $Install

    
    Write-Verbose "Verifying Installation Integrity for: $resolvedInstallPath"

    [string]$sourceHash = Get-FileHashRecursive -Path $Source @commonArgs -Indentation 1
    [string]$installHash = Get-FileHashRecursive -Path $Install @commonArgs -Indentation 1
    [bool]$result = $sourceHash -eq $installHash
    [string]$resultVerb = & {
        if ($result) { return "Passed" }
        else         { return "Failed" }
    }

    Write-Verbose "Installation Integrity Verification Check $resultVerb for: $resolvedInstallPath"
    Write-Verbose "  Source Hash: $sourceHash"
    Write-Verbose "  Installation Hash: $installHash"
    return $result

}

function Assert-InstallIntegrity {

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 1)]
        [string]$Source,

        [Parameter(Mandatory, Position = 2, ValueFromPipeline)]
        [string]$Install,

        [string]$Filter,
        [string[]]$Include,
        [string[]]$Exclude
    )

    if (-not (Test-InstallIntegrity @PSBoundParameters)) {
        throw "File Verification Failed"
    }

}

function Get-FullyQualifiedUsername {

    [OutputType([string])]
    param()

    return "\\${env:USERDOMAIN}\${env:USERNAME}"

}

function Get-FileHashRecursive {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [SupportsWildcards()]
        [string[]]$Path,

        [string]$Filter,
        [string[]]$Include,
        [string[]]$Exclude,

        [Parameter(DontShow)]
        [int]$Indentation = 0
    )

    begin {
        [string[]]$allPaths = $Path
    }

    process {
        if ($null -ne $_) {
            $allPaths += @($_)
        }
    }

    end {
        [string[]]$resolvedPaths = Get-Item -Path $allPaths -Filter $Filter
        [System.Collections.Generic.SortedSet[string]]$childHashes = [System.Collections.Generic.SortedSet[string]]::new()
        [System.IO.MemoryStream]$joinedHashes = [System.IO.MemoryStream]::new()
        [System.IO.StreamWriter]$joinedHashesWriter = [System.IO.StreamWriter]::new($joinedHashes)

        foreach ($resolvedPath in $resolvedPaths) {
            if (Test-Path $resolvedPath -PathType Container) {
                Write-Verbose "$('  ' * $Indentation)Computing Hash for Directory: $resolvedPath..."

                [string]$directoryHash = Get-FileHashRecursive "$resolvedPath/*" -Filter $Filter -Include $Include -Exclude $Exclude -Indentation ($Indentation + 1)

                Write-Verbose "$('  ' * $Indentation)Computed Hash '$directoryhash' for Directory: $resolvedPath"
                $childHashes.Add($directoryHash) | Out-Null
            }
            else {
                if (Test-FilePattern $resolvedPath -Filter $Filter -Include $Include -Exclude $Exclude -Indentation ($Indentation + 1)) {
                    [string]$fileHash = (Get-FileHash -Path $resolvedPath).Hash
    
                    Write-Verbose "$('  ' * $Indentation)Computed Hash '$filehash' for File: $resolvedPath"
                    $childHashes.Add($fileHash) | Out-Null
                }
            }
        }

        if ($childHashes.Count -gt 0) {
            foreach ($hash in $childHashes) {
                $joinedHashesWriter.Write($hash)
            }

            $joinedHashesWriter.Flush()
            $joinedHashes.Position = 0
        }
        
        return (Get-FileHash -InputStream $joinedHashes).Hash
    }

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