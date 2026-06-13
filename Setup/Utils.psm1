# Shared Constants #

<#
    A hashtable containing the parameters to be passed
    to cmdlets in order to ensure none of the risk management
    parameters are used.

    This is typically used when calling internal functions
    to suppress redundant prompts and logging.
#>
[hashtable]$NO_RISK_PARAMS = @{
    WhatIf = $false
    Confirm = $false
}


# User PATH Management #

<#
    .SYNOPSIS
    Retrieve the current user's PATH.

    .DESCRIPTION
    Retrieves the value of the current user's
    PATH from the corresponding environment variable.

    By default, the contents of the current user's PATH
    are returned as an array of strings containing each
    individual path element. To retrieve the raw
    PATH string, use the `-AsString` switch.

    .NOTES
    Only the current user's PATH is returned, and the
    system PATH is NOT included in the returned path.

    .INPUTS
    None.
    You cannot pipe any objects to `Get-UserPATH`.

    .OUTPUTS
    string[].
    By default or when the `-AsArray` switch is used,
    `Get-UserPATH` returns an array of strings containing
    the individual path elements of the current user's PATH.

    .OUTPUTS
    string.
    When the `-AsString` switch is used, `Get-UserPATH` returns
    a string containing the current user's PATH, in which
    each individual path element is separated by a semicolon (;).

    .LINK
    Resolve-UserPATH

    .LINK
    Set-UserPATH

    .LINK
    Test-UserPATH
#>
function Get-UserPATH {

    [CmdletBinding(DefaultParameterSetName = "AsArray")]
    param(
        <#
            Indicates that the specified PATH should be resolved
            to a PATH string containing the individual path elements
            joined together with semicolons (;).
        #>
        [Parameter(ParameterSetName = "AsString", Mandatory)]
        [switch]$AsString,
        
        <#
            Indicates that the specified PATH should be resolved
            to an array containing the individual path elements
            making up the PATH.
        #>
        [Parameter(ParameterSetName = "AsArray")]
        [switch]$AsArray
    )

    if (-not $AsString -and -not $AsArray) {
        $PSBoundParameters["AsArray"] = $true
    }

    return (Resolve-UserPATH ([System.Environment]::GetEnvironmentVariable("PATH", "User")) @PSBoundParameters)

}

<#
    .SYNOPSIS
    Resolve the specified PATH to the designated format.

    .DESCRIPTION
    Resolves the value of the specified PATH to the designated format.

    In other words, regardless of the way the PATH is provided
    to the function, it will be returned in the specified format.
    
    .NOTES
    You must explicitly specify the format the PATH is
    to be resolved to using the `-ToString` or `-ToArray` switch.

    .INPUTS
    string.
    You can pipe a string to `Resolve-UserPATH` containing
    the PATH string to be resolved.

    Note that you CANNOT pipe an array containing the individual
    path elements making up the PATH string to `Resolve-UserPATH`,
    as each path element would be interpreted as a separate PATH.

    .OUTPUTS
    string.
    When the `-ToString` switch is used, `Resolve-UserPATH` returns
    a string containing the specified PATH, in which
    each individual path element is separated by a semicolon (;).
    
    .OUTPUTS
    string[].
    When the `-ToArray` switch is used, `Resolved-UserPATH` returns
    an array of strings containing the individual path elements of the
    specified PATH.

    .LINK
    Get-UserPATH

    .LINK
    Set-UserPATH

    .LINK
    Test-UserPATH
#>
function Resolve-UserPATH {

    [CmdletBinding()]
    param(
        <#
            The PATH being resolved, either as a string containing
            the entire PATH with each individual path element separated
            by a semicolon (;), or as an array of strings containing
            the individual path elements.
        #>
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string[]]$PATH,

        <#
            Indicates that the specified PATH should be resolved
            to a PATH string containing the individual path elements
            joined together with semicolons (;).
        #>
        [Alias("AsString")]
        [Parameter(ParameterSetName = "AsString", Mandatory)]
        [switch]$ToString,
        
        <#
            Indicates that the specified PATH should be resolved
            to an array containing the individual path elements
            making up the PATH.
        #>
        [Alias("AsArray")]
        [Parameter(ParameterSetName = "AsArray", Mandatory)]
        [switch]$ToArray
    )

    process {
        if ($ToString) {
            if ($PATH.Count -gt 1) { return $PATH.Where{ $_.Trim() } -join ";" }
            else                   { return $PATH }
        }
        else {
            if ($PATH.Count -gt 1) { return $PATH }
            else                   { return ($PATH -split ";").Where{ $_.Trim() } }
        }
    }

}

<#
    .SYNOPSIS
    Set the current user's PATH.

    .DESCRIPTION
    Change the value of the current user's
    PATH using the corresponding environment variable.

    .NOTES
    Only the current user's PATH is updated, and the
    system PATH will NOT modified.

    .INPUTS
    string.
    You can pipe a string containing the current user's new PATH
    in which each individual path element is joined together with
    semicolons (;) to `Set-UserPATH`.

    .INPUTS
    string[].
    You can pipe an array of strings containing the individual
    path elements to use for the current user's new PATH to `Set-UserPATH`.

    .OUTPUTS
    None.
    By default, `Set-UserPATH` does not generate any output.

    .OUTPUTS
    bool.
    When the `-PassThru` switch is used, `Set-UserPATH` returns
    `$true` if the current user's PATH was successfully updated
    or `$false` if it was not.

    .LINK
    Get-UserPATH
    
    .LINK
    Resolve-UserPATH

    .LINK
    Test-UserPATH
#>
function Set-UserPATH {

    [CmdletBinding()]
    param(
        <#
            The current user's new PATH, either as a string containing
            the entire PATH with each individual path element separated
            by a semicolon (;), or as an array of strings containing
            the individual path elements.
        #>
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string[]]$PATH,

        <#
            Indicates that the function should return a boolean
            value indicating whether or not the current user's PATH
            was successfully updated.

            By default and when this switch is omitted, this function
            does not generate any output.
        #>
        [switch]$PassThru
    )

    begin {
        # The full PATH, joined together from the PATH parameter
        # and individual pipeline contents.
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

        if ($PassThru) {
            return ((Get-UserPATH -Raw) -ieq $resolvedPATH)
        }
    }

}

<#
    .SYNOPSIS
    Test for the existence of an individual path element
    within the current user's PATH.

    .DESCRIPTION
    Test if an invididual path element currently
    exists within the current user's PATH.

    This function can be invoked without any parameters,
    which tests for the existence of the script installation location
    in the current user's PATH by default. However, both the
    individual path element and PATH being searched can be 
    manually specified and overridden if needed.

    .INPUTS
    string.
    You can pipe a string containing the individual path element
    to search for in the current user's PATH to `Test-UserPATH`.

    .OUTPUTS
    bool.
    `Test-UserPATH` returns `$true` if the specified
    individual path entry exists within the designated PATH
    or `$false` if it does not.
    
    .LINK
    Get-UserPATH

    .LINK
    Resolve-UserPATH

    .LINK
    Set-UserPATH
#>
function Test-UserPATH {

    [CmdletBinding()]
    param(
        [Parameter(Position = 1, ValueFromPipeline)]
        [PSDefaultValue(Help = "The Link2Root Installation Directory")]
        [string]$Entry = (& "$PSScriptRoot\Get-InstallLocation.ps1" -Internal),

        <#
            The PATH being searched, either as a string containing
            the entire PATH with each individual path element separated
            by a semicolon (;), or as an array of strings containing
            the individual path elements.
        #>
        [Parameter(Position = 2)]
        [PSDefaultValue(Help = "The Current User's PATH")]
        [string[]]$PATH = (Get-UserPATH)
    )
    
    process {
        return ((Resolve-UserPATH $PATH -ToArray) -contains $Entry)
    }

}


# File & Installation Integrity #

<#
    .SYNOPSIS
    Assert the integrity of the designated installation directory.

    .DESCRIPTION
    Compare the contents of the designated installation directory
    with the specified location containing the expected contents
    in order to verify the integrity of the specified install location,
    raising an error if the contents of the two directories do not match.

    To simply test the integrity of an installation directory and receive
    a corresponding boolean value, use the `Test-InstallIntegrity` function.

    .NOTES
    The integrity of the installation directory is determined by
    computing the hashes of the two directories using the `Get-FileHashRecursive` function
    and ensuring that the two hashes match.

    .INPUTS
    String.
    You can pipe a string containing the path to the installation directory
    whose integrity is being verified to `Assert-InstallIntegrity`.

    .OUTPUTS
    None.
    `Assert-InstallIntegrity` does not generate any output.

    .LINK
    Test-InstallIntegrity

    .LINK
    Get-FileHashRecursive
#>
function Assert-InstallIntegrity {

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        <#
            The path to the directory containing the expected files to be
            compared against the designated installation directory.
        #>
        [Parameter(Mandatory, Position = 1)]
        [string]$Source,

        <#
            The path to the installation directory
            whose integrity is being verified.
        #>
        [Parameter(Mandatory, Position = 2, ValueFromPipeline)]
        [string]$Install,

        <#
            Specifies a filter to qualify the `Source` and `Install` parameters.
            
            Filters are more efficient than other parameters. The provider applies the filter when the cmdlet
            gets the objects rather than having PowerShell filter the objects after they're retrieved.
            
            The filter string is passed to the .NET API to enumerate files.
            The API only supports * and ? wildcards.
        #>
        [string]$Filter,

        <#
            Specifies, as a string array, an item or items that this cmdlet includes in the operation.
            
            The value of this parameter qualifies the `Source` and `Install` parameters.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [string[]]$Include,

        <#
            Specifies, as a string array, an item or items that this cmdlet excludes in the operation.
            
            The value of this parameter qualifies the `Source` and `Install` parameters.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [string[]]$Exclude
    )

    if (-not (Test-InstallIntegrity @PSBoundParameters)) {
        throw "File Verification Failed"
    }

}

<#
    .SYNOPSIS
    Recursively compute the hash of a file or directory.

    .DESCRIPTION
    Recursively compute the hash of a file or the
    combined file hashes of all of the files within
    a given directory.

    If a single file is specified, its file hash is
    immediately computed and returned using the
    standard `Get-FileHash` function.

    If a directory is specified, the file hash of
    each file in the directory is computed, joined together, 
    and then itself hashed to create a hash for the directory.
    If the specified directory contains one or more sub-directories,
    their hashes will be recursively computed using `Get-FileHashRecursive`.

    If multiple paths are specified, their individual hashes
    will be computed, joined together, and then itself hashed
    to create a hash for the combination of paths.
    If any of the specified paths are directories that contain one or more sub-directories,
    their hashes will be recursively computed using `Get-FileHashRecursive`.

    You can use the `-Filter`, `-Include`, and `-Exclude` parameters,
    which are identical to those found on standard functions such as
    `Get-Item`, to limit which files are to be used to compute the
    file or directory hash.
    
    .NOTES
    If any of the specified paths are invalid, do not exist, or could
    not be accessed to be hashed, they will be silently skipped and will
    NOT be included in the final hash. This behavior is useful when using this function
    to create file and directory hashes that are used for verification, but can
    cause issues and must be kept in mind during active development
    if unexpected values are being generated.

    To see which files are being included in the computed hash,
    use the `-Verbose` switch.

    .INPUTS
    string.
    You can pipe a string containing the path to the
    file or directory whose hash is to be computed
    to `Get-FileHashRecursive`.

    .INPUTS
    string[].
    You can pipe an array of strings containing multiple paths
    to use when computing the hash to `Get-FileHashRecursive`.

    .OUTPUTS
    string.
    `Get-FileHashRecursive` returns a string containing
    the computed hash for the specified file or directory.

    If no valid files or directories were found to include in the hash,
    or if the specified file or directory is empty, the hash value
    `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`
    will be returned.
#>
function Get-FileHashRecursive {

    [CmdletBinding()]
    param(
        <#
            The path or paths whose hash is to be computed.

            If multiple paths are specified, they will also be used
            to compute a single hash for the combination of
            files and directories.
        #>
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [SupportsWildcards()]
        [string[]]$Path,

        <#
            Specifies the cryptographic hash function to use for computing the hash value of the contents of the specified file or stream.
            
            The acceptable values for this parameter are:
                - SHA1
                - SHA256
                - SHA384
                - SHA512
                - MD5

            For security reasons, MD5 and SHA1, which are no longer considered secure, should only be used for simple change validation,
            and should not be used to generate hash values for files that require protection from attack or tampering.
        #>
        [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MD5")]
        [string]$Algorithm = "SHA256",

        <#
            Specifies a filter to qualify the `Path` parameter.
            
            Filters are more efficient than other parameters. The provider applies the filter when the cmdlet
            gets the objects rather than having PowerShell filter the objects after they're retrieved.
            
            The filter string is passed to the .NET API to enumerate files.
            The API only supports * and ? wildcards.
        #>
        [string]$Filter,

        <#
            Specifies, as a string array, an item or items that this cmdlet includes in the operation.
            
            The value of this parameter qualifies the `Path` parameter.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [string[]]$Include,

        <#
            Specifies, as a string array, an item or items that this cmdlet excludes in the operation.
            
            The value of this parameter qualifies the `Path` parameter.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [string[]]$Exclude,

        <#
            An internal parameter used to specify the indentation
            level to use for output logging.
        #>
        [Parameter(DontShow)]
        [int]$Indentation = 0
    )

    begin {
        # All of the specified paths, joined together from the path parameter
        # and individual pipeline contents.
        [string[]]$allPaths = $Path
    }

    process {
        if ($null -ne $_) {
            $allPaths += @($_)
        }
    }

    end {
        [System.IO.FileInfo[]]$resolvedPaths = @()
        [System.Collections.Generic.SortedSet[string]]$childHashes = [System.Collections.Generic.SortedSet[string]]::new()
        [System.IO.MemoryStream]$joinedHashes = [System.IO.MemoryStream]::new()
        [System.IO.StreamWriter]$joinedHashesWriter = [System.IO.StreamWriter]::new($joinedHashes)

        foreach ($currentPath in $allPaths) {
            try {
                $resolvedPaths += Get-Item -Path $currentPath -Filter $Filter -ErrorAction Stop
            }
            catch {
                Write-Verbose "$(Get-IndentString $Indentation)No Files Matched Pattern: $currentPath"
            }
        }

        foreach ($resolvedPath in $resolvedPaths) {
            if (Test-Path $resolvedPath -PathType Container) {
                Write-Verbose "$(Get-IndentString $Indentation)Computing Hash for Directory: $resolvedPath..."

                [string]$directoryHash = Get-FileHashRecursive `
                    "$resolvedPath/*" `
                    -Algorithm $Algorithm `
                    -Filter $Filter `
                    -Include $Include `
                    -Exclude $Exclude `
                    -Indentation ($Indentation + 1)

                Write-Verbose "$(Get-IndentString $Indentation)Computed Hash '$directoryhash' for Directory: $resolvedPath"
                $childHashes.Add($directoryHash) | Out-Null
            }
            else {
                if (Test-FilePattern $resolvedPath -Filter $Filter -Include $Include -Exclude $Exclude -Indentation $Indentation) {
                    [string]$fileHash = (Get-FileHash -Path $resolvedPath -Algorithm $Algorithm).Hash
    
                    Write-Verbose "$(Get-IndentString $Indentation)Computed Hash '$filehash' for File: $resolvedPath"
                    $childHashes.Add($fileHash) | Out-Null
                }
            }
        }

        if ($childHashes.Count -gt 1) {
            foreach ($hash in $childHashes) {
                $joinedHashesWriter.Write($hash)
            }

            $joinedHashesWriter.Flush()
            $joinedHashes.Position = 0
        }
        elseif ($childHashes.Count -eq 1) {
            return $childHashes[0]
        }

        return (Get-FileHash -InputStream $joinedHashes -Algorithm $Algorithm).Hash
    }

}

<#
    .SYNOPSIS
    Verify the integrity of the designated installation directory.

    .DESCRIPTION
    Compare the contents of the designated installation directory
    with the specified location containing the expected contents
    in order to verify the integrity of the specified install location.

    To assert the integrity of an installation directory and raise
    an error if the integrity check fails, use the `Assert-InstallIntegrity` function.

    .NOTES
    The integrity of the installation directory is determined by
    computing the hashes of the two directories using the `Get-FileHashRecursive` function
    and ensuring that the two hashes match.

    .INPUTS
    String.
    You can pipe a string containing the path to the installation directory
    whose integrity is being verified to `Test-InstallIntegrity`.

    .OUTPUTS
    bool.
    `Test-InstallIntegrity` returns `$true` if the contents of the
    designated installation directory match those of the specified
    source location. Otherwise, returns `$false`.

    .LINK
    Assert-InstallIntegrity

    .LINK
    Get-FileHashRecursive
#>
function Test-InstallIntegrity {

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        <#
            The path to the directory containing the expected files to be
            compared against the designated installation directory.
        #>
        [Parameter(Mandatory, Position = 1)]
        [string]$Source,

        <#
            The path to the installation directory
            whose integrity is being verified.
        #>
        [Parameter(Mandatory, Position = 2, ValueFromPipeline)]
        [string]$Install,

        <#
            Specifies a filter to qualify the `Source` and `Install` parameters.
            
            Filters are more efficient than other parameters. The provider applies the filter when the cmdlet
            gets the objects rather than having PowerShell filter the objects after they're retrieved.
            
            The filter string is passed to the .NET API to enumerate files.
            The API only supports * and ? wildcards.
        #>
        [string]$Filter,

        <#
            Specifies, as a string array, an item or items that this cmdlet includes in the operation.
            
            The value of this parameter qualifies the `Source` and `Install` parameters.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [string[]]$Include,

        <#
            Specifies, as a string array, an item or items that this cmdlet excludes in the operation.
            
            The value of this parameter qualifies the `Source` and `Install` parameters.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
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


# Output Logging #

<#
    .SYNOPSIS
    Get an indentation string.

    .DESCRIPTION
    Get an string containing space characters that can be used
    an indent for a line, with the number of spaces determined
    by the specified indentation level.

    .INPUTS
    None.
    You cannot pipe any objects to `Get-IndentString`

    .OUTPUTS
    String.
    `Get-IndentString` returns an indentation string
    based on the specified indentation level.
#>
function Get-IndentString {

    param(
        <#
            The indentation level to use when determining how
            much to indent the line.

            Defaults to 1. If a value less than 1 is specified,
            an empty string will be returned.
        #>
        [Parameter(Position = 1)]
        [int]$Indentation = 1
    )

    return ("  " * [System.Math]::Max(0, $Indentation))

}

<#
    .SYNOPSIS
    Write a Component Prefix Update to the console.

    .DESCRIPTION
    Write a Component Prefix Update of the form
    "[+]", "[-]", or "[/]" to the console.

    Component Updates are typically used to communicate the status
    of operations being performed by a function or cmdlet, and this function is
    intended to be used immediately prior to one or more calls to
    the `Write-Component` function.

    The form of the Component Prefix Update is determined by
    the use or absence of the `-Success` and `-Failure` switches.
    If either of these switches are used, a Successful or Failed
    ("[+]" or "[-]") Component Prefix Update will be written the console,
    respectively. However, if both switches are omitted, a "[/]" will be
    written the console instead.

    .INPUTS
    None.
    You cannot pipe any objects to `Write-ComponentPrefix`.

    .OUTPUTS
    None.
    `Write-ComponentPrefix` does not generate any output.

    .LINK
    Write-Component
#>
function Write-ComponentPrefix {

    [Alias("_wcp")]
    [CmdletBinding(DefaultParameterSetName = "WithoutSuccessOrFailure")]
    param(
        <#
            Indicates that a Successful Component Prefix Update
            ("[+]") should be written to the console.

            Cannot be combined with the `-Failed` switch.
        #>
        [Parameter(ParameterSetName = "WithSuccess")]
        [switch]$Success,

        <#
            Indicates that a Failed Component Prefix Update
            ("[-]") should be written to the console.

            Cannot be combined with the `-Failed` switch.
        #>
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

<#
    .SYNOPSIS
    Write a Component Update to the console.

    .DESCRIPTION
    Write a formatted Component Update to the console,
    which is simply colored yellow.

    Component Updates are typically used to communicate the status
    of operations being performed by a function or cmdlet, and this function is intended
    to be used immediately following a call to the `Write-ComponentPrefix` function.

    .INPUTS
    string.
    You can pipe a string containing the Component Update
    to write to the console to `Write-Component`.

    .OUTPUTS
    None.
    `Write-Component` does not generate any output.

    .LINK
    Write-ComponentPrefix
#>
function Write-Component {

    [Alias("_wc")]
    [CmdletBinding()]
    param(
        <#
            The Component Update to write to the console.
        #>
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]$Component,

        <#
            Doesn't append a newline to the specified Component Update,
            allowing for more information to be written to the current line.

            By default and when this switch is omitted, a newline
            is always appended to the specified `-Component`.
        #>
        [switch]$NoNewline
    )

    process {
        Write-Host $Component -NoNewline:$NoNewline -ForegroundColor Yellow
    }

}

<#
    .SYNOPSIS
    Write a "Restart Required" informational message to the console.

    .DESCRIPTION
    Write a formatted message to the console indicating that the current console session
    or terminal window will have to be restarted for recently-made changes to be applied.

    .INPUTS
    None.
    You cannot pipe any objects to `Write-EndRestartNotice`.

    .OUTPUTS
    None.
    `Write-EndRestartNotice` does not generate any output.
#>
function Write-EndRestartNotice {

    Write-Host "You may have to restart your console session or terminal window for changes to take effect." -ForegroundColor DarkYellow

}

<#
    .SYNOPSIS
    Write a path to the console.

    .DESCRIPTION
    Write a formatted path to the console, which is simply colored cyan.

    .INPUTS
    string.
    You can pipe a string containing the path to be
    written to the console to `Write-Path`.

    .INPUTS
    object.
    You can pipe an object with a "Path" property
    containing the path to be written to the console
    to `Write-Path`.

    .OUTPUTS
    None.
    `Write-Path` does not generate any output.
#>
function Write-Path {

    [Alias("_wp")]
    [CmdletBinding()]
    param(
        <#
            The path to the written to the console.
        #>
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path,

        <#
            Doesn't append a newline to the specified path,
            allowing for more information to be written to the current line.

            By default and when this switch is omitted, a newline
            is always appended to the specified `-Path`.
        #>
        [switch]$NoNewline
    )

    process {
        Write-Host $Path -NoNewline:$NoNewline -ForegroundColor Cyan
    }

}


# Miscellaenous Helper Functions #

<#
    .SYNOPSIS
    Get the Current User's FQDN.

    .DESCRIPTION
    Get the Fully-Qualified Domain Name for the Current User,
    which is of the form "Domain\Username".

    .INPUTS
    None.
    You cannot pipe any objects to `Get-FullyQualifiedUsername`.

    .OUTPUTS
    String.
    `Get-FullyQualifiedUsername` returns a string containing the
    Current User's Fully-Qualified Domain name.
#>
function Get-FullyQualifiedUsername {

    [OutputType([string])]
    param()

    return "\\${env:USERDOMAIN}\${env:USERNAME}"

}

<#
    .SYNOPSIS
    Test if a file matches the specified pattern.

    .DESCRIPTION
    Test if a file path matches the specified `-Filter`,
    `-Include`, and `-Exclude` patterns.

    Detailed information about the pattern matching process
    can be retrieved by using the `-Verbose` switch.

    .INPUTS
    string.
    You can pipe a string containing the path to be tested to `Test-FilePattern`.

    .OUTPUTS
    bool.
    `Test-FilePattern` returns boolean `$true` if the specified file path matches
    the designated pattern or `$false` if it does not.
#>
function Test-FilePattern {

    [CmdletBinding()]
    param(
        <#
            The path or paths to be tested.
        #>
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [string]$Path,

        <#
            Specifies a filter to qualify the `Path` parameter.
            
            Filters are more efficient than other parameters. The provider applies the filter when the cmdlet
            gets the objects rather than having PowerShell filter the objects after they're retrieved.
            
            The filter string is passed to the .NET API to enumerate files.
            The API only supports * and ? wildcards.
        #>
        [string]$Filter,

        <#
            Specifies, as a string array, an item or items that this cmdlet includes in the operation.
            
            The value of this parameter qualifies the `Path` parameter.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [string[]]$Include,

        <#
            Specifies, as a string array, an item or items that this cmdlet excludes in the operation.
            
            The value of this parameter qualifies the `Path` parameter.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [string[]]$Exclude,

        <#
            An internal parameter used to specify the indentation
            level to use for output logging.
        #>
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


Export-ModuleMember -Function * -Variable * -Alias *