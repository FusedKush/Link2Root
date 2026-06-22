# Miscellaneous Constants #

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

<#
    An array of wildcard patterns specifying which files are to
    be ignored and skipped entirely during the setup process.
#>
[string[]]$SETUP_FOLDER_IGNORED_FILES = @("*[/\]Install-Link2Root.ps1")


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
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
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

    [CmdletBinding(PositionalBinding = $false)]
    param(
        <#
            The current user's new PATH, either as a string containing
            the entire PATH with each individual path element separated
            by a semicolon (;), or as an array of strings containing
            the individual path elements.
        #>
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string[]]$PATH,

        <#
            Indicates that the function should return a boolean
            value indicating whether or not the current user's PATH
            was successfully updated.

            By default and when this switch is omitted, this function
            does not generate any output.
        #>
        [switch]$PassThru,

        <#
            An internal parameter used to specify the indentation
            level to use for output logging.
        #>
        [Parameter(DontShow)]
        [int]$Indentation = 0
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
        Write-Verbose "$(_gis $Indentation)[>] Updating $(Get-FullyQualifiedUsername)'s PATH..."
        Write-Verbose "$(_gis ($Indentation + 1))[#] Original PATH: $(Get-UserPATH -AsString)"
        
        [string]$resolvedPATH = (Resolve-UserPATH $fullPATH -ToString)
        Write-Verbose "$(_gis ($Indentation + 1))[#] Modified Value: $resolvedPATH"

        [System.Environment]::SetEnvironmentVariable("PATH", $resolvedPATH, "USER")
        Write-Verbose "$(_gis ($Indentation + 1))[#] Updated PATH: $(Get-UserPATH -AsString)"
        Write-Verbose "$(_gis $Indentation)[+] Updated $(Get-FullyQualifiedUsername)'s PATH"

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

    [CmdletBinding(PositionalBinding = $false)]
    param(
        <#
            The entry to search for within the PATH.
        #>
        [Parameter(Position = 0, ValueFromPipeline)]
        [PSDefaultValue(Help = "The Link2Root Installation Directory")]
        [string]$Entry = (& "$PSScriptRoot\Get-Link2RootInstall.ps1" -Internal),

        <#
            The PATH being searched, either as a string containing
            the entire PATH with each individual path element separated
            by a semicolon (;), or as an array of strings containing
            the individual path elements.
        #>
        [Parameter(Position = 1)]
        [PSDefaultValue(Help = "The Current User's PATH")]
        [string[]]$PATH = (Get-UserPATH),

        <#
            Indicates that no progress bars should be rendered
            in the terminal by the script.

            By default and when this switch is omitted, the status and progress
            of the function is reflected in one or more progress bars
            rendered within the terminal.

            Has no effect on progress bars created by built-in functions and cmdlets.
            To control the behavior of all PowerShell progress bars, use the
            `$ProgressPreference` automatic variable.
        #>
        [Alias("HideProgress")]
        [switch]$NoProgress,

        <#
            An internal parameter used to specify the indentation
            level to use for output logging.
        #>
        [Parameter(DontShow)]
        [int]$Indentation = 0
    )
    
    process {
        [array]$pathArray = (Resolve-UserPATH $PATH -ToArray)

        Add-ProgressBar `
            -Name "Checking $(Get-FullyQualifiedUsername)'s PATH" `
            -DefaultPercentageChange (100 / $pathArray.Count) `
            -Hidden:$NoProgress

        foreach ($currentPath in $pathArray) {
            _upb -Status $currentPath -CurrentOperation "Checking for Match..." -PercentageChange 0

            if ($currentPath -ieq $Entry) {
                Write-Verbose "$(_gis $Indentation)[+] $currentPath"
                _upb -Status $currentPath -CurrentOperation "Match FOUND" -PercentageChange 100
                Remove-ProgressBar
                return $true
            }
            else {
                Write-Verbose "$(_gis $Indentation)[-] $currentPath"
                _upb -Status $currentPath -CurrentOperation "Match NOT Found"
            }
        }

        Remove-ProgressBar
        return $false
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

    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([bool])]
    param(
        <#
            The path to the directory containing the expected files to be
            compared against the designated installation directory.
        #>
        [Parameter(Mandatory, Position = 0)]
        [string]$Source,

        <#
            The path to the installation directory
            whose integrity is being verified.
        #>
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
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
        [string[]]$Exclude,

        <#
            An internal parameter used to specify the indentation
            level to use for output logging.
        #>
        [Parameter(DontShow)]
        [int]$Indentation = 0
    )

    if (-not (Test-InstallIntegrity @PSBoundParameters)) {
        throw "File Verification Failed for $Install"
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

    [CmdletBinding(PositionalBinding = $false)]
    param(
        <#
            The path or paths whose hash is to be computed.

            If multiple paths are specified, they will also be used
            to compute a single hash for the combination of
            files and directories.
        #>
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
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
        [int]$Indentation = 0,

        <#
            An internal parameter used to flag recursive calls
            in order to properly handle filtering and output behavior.
        #>
        [Parameter(DontShow)]
        [switch]$RecursiveCall
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
        [System.IO.FileSystemInfo[]]$resolvedPaths = @()
        [System.Collections.Generic.SortedSet[string]]$childHashes = [System.Collections.Generic.SortedSet[string]]::new()
        [System.IO.MemoryStream]$joinedHashes = [System.IO.MemoryStream]::new()
        [System.IO.StreamWriter]$joinedHashesWriter = [System.IO.StreamWriter]::new($joinedHashes)

        foreach ($currentPath in $allPaths) {
            try {
                $resolvedPaths += Get-Item -Path $currentPath -Filter $Filter -ErrorAction Stop
            }
            catch {
                Write-Verbose "$(_gis $Indentation)[-] No Files Matched Pattern: $currentPath"
            }
        }

        if ($resolvedPaths.Count -gt 0) {
            Add-ProgressBar `
                -Name "Retrieve Current File Hash" `
                -DefaultPercentageChange (100 / $resolvedPaths.Count) `
                -InitialSecondsRemaining 1
    
            foreach ($resolvedPath in $resolvedPaths) {
                if (-not $RecursiveCall -or (Test-FilePattern $resolvedPath -Filter $Filter -Include $Include -Exclude $Exclude -Indentation $Indentation)) {
                    if (Test-Path $resolvedPath -PathType Container) {
                        $displayPath = & {
                            if ($RecursiveCall) { return (Split-Path $resolvedPath -Leaf) }
                            else                { return $resolvedPath }
                        }

                        Write-Verbose "$(_gis $Indentation)[>] Computing Hash for Directory: $displayPath..."
                        _upb `
                            -Status (Split-Path $resolvedPath -Leaf) `
                            -CurrentOperation "Computing Directory Hash..." `
                            -PercentageChange 0
                        [string]$directoryHash = Get-FileHashRecursive `
                            -Path "$resolvedPath/*" `
                            -Algorithm $Algorithm `
                            -Filter $Filter `
                            -Include $Include `
                            -Exclude $Exclude `
                            -Indentation ($Indentation + 1) `
                            -RecursiveCall
        
                        Write-Verbose "$(_gis $Indentation)[+] Computed Hash '$directoryhash' for Directory: $displayPath"
                        _upb `
                            -Status (Split-Path $resolvedPath -Leaf) `
                            -CurrentOperation "Got Directory Hash: $directoryHash"
                        $childHashes.Add($directoryHash) | Out-Null
                    }
                    else {
                        _upb `
                            -Status (Split-Path $resolvedPath -Leaf) `
                            -CurrentOperation "Computing File Hash..." `
                            -PercentageChange 0
                        [string]$fileHash = (Get-FileHash -Path $resolvedPath -Algorithm $Algorithm).Hash
        
                        Write-Verbose "$(_gis $Indentation)[#] Computed Hash '$filehash' for File: $(Split-Path $resolvedPath -Leaf)"
                        _upb `
                            -Status (Split-Path $resolvedPath -Leaf) `
                            -CurrentOperation "Got File Hash: $fileHash"
                        $childHashes.Add($fileHash) | Out-Null
                    }
                }
            }

            Remove-ProgressBar
        }

        if ($childHashes.Count -eq 1) {
            return $childHashes[0]
        }
        else {
            foreach ($hash in $childHashes) {
                $joinedHashesWriter.Write($hash)
            }
    
            $joinedHashesWriter.Flush()
            $joinedHashes.Position = 0
    
            return (Get-FileHash -InputStream $joinedHashes -Algorithm $Algorithm).Hash
        }
        
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

    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([bool])]
    param(
        <#
            The path to the directory containing the expected files to be
            compared against the designated installation directory.
        #>
        [Parameter(Mandatory, Position = 0)]
        [string]$Source,

        <#
            The path to the installation directory
            whose integrity is being verified.
        #>
        [Parameter(Mandatory, Position = 1, ValueFromPipeline)]
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
        [string[]]$Exclude,

        <#
            An internal parameter used to specify the indentation
            level to use for output logging.
        #>
        [Parameter(DontShow)]
        [int]$Indentation = 0
    )

    [hashtable]$commonArgs = @{
        Filter = $Filter
        Include = $Include
        Exclude = $Exclude
        Indentation = ($Indentation + 2)
    }
    [string]$resolvedInstallPath = Resolve-Path $Install
    [string]$resultIcon = ""
    [string]$resultVerb = ""
    [bool]$result = $false


    Write-Verbose "$(_gis $Indentation)[>] Verifying Installation Integrity for: $resolvedInstallPath"
    Add-ProgressBar `
        -Name "Check File Integrity" `
        -DefaultPercentageChange 50 `
        -InitialSecondsRemaining 1
    
    Write-Verbose "$(_gis ($Indentation + 1))[>] Computing Expected Install Hash..."
    _upb -Status "Get Expected Install Hash" -PercentageChange 0
    [string]$sourceHash = Get-FileHashRecursive -Path $Source @commonArgs
    Write-Verbose "$(_gis ($Indentation + 1))[+] Source Hash: $sourceHash"
    _upb -Status "Got Expected Install Hash: $sourceHash"

    Write-Verbose "$(_gis ($Indentation + 1))[>] Computing Actual Install Hash..."
    _upb -Status "Get Actual Install Hash" -PercentageChange 0
    [string]$installHash = Get-FileHashRecursive -Path $Install @commonArgs
    _upb -Status "Got Actual Install Hash: $sourceHash"
    
    $result = $sourceHash -eq $installHash

    if ($result) {
        $resultIcon = "+"
        $resultVerb = "PASSED"
    }
    else {
        $resultIcon = "-"
        $resultVerb = "FAILED"
    }

    Write-Verbose "$(_gis ($Indentation + 1))[$resultIcon] Install Hash: $installHash"
    Write-Verbose "$(_gis $Indentation)[$resultIcon] Installation Integrity Verification Check $resultVerb for: $resolvedInstallPath"
    Remove-ProgressBar
    return $result

}


# Output Logging & Formatting #

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

    .LINK
    Format-Indentation
#>
function Get-IndentString {

    [Alias("_gis")]
    param(
        <#
            The indentation level to use when determining how
            much to indent the line.

            Each indentation level corresponds to 2 spaces of indentation.

            Defaults to 1. If a value less than 1 is specified,
            an empty string will be returned.
        #>
        [Parameter(Position = 0)]
        [int]$Indentation = 1
    )

    return ("  " * [System.Math]::Max(0, $Indentation))

}

<#
    .SYNOPSIS
    Format the indentation of a string

    .DESCRIPTION
    Format and set the indentation level for all lines
    of the specified string.

    The indentation for all lines of the specified string will be
    adjusted to match the designated indentation level. Lines will less
    indentation than specified will be padded to the designated amount,
    while those with more indentation than specified will be reduced to
    reach the designated base indentation level.

    .NOTES
    Only the *base* indentation level of the specified string will be modified.
    In other words, if the specified string already contains any indentation,
    this function will only modify the *base* indentation level, and all
    remaining indentation is generally left unchanged.

    To set the indentation level of *all* lines to the same value,
    you can manually pipe each line of the string to `Format-Indentation`
    (e.g., ($myString -split "`n" | Format-Indentation) -join "`n").

    .INPUTS
    String.
    You can pipe a string to be formatted to `Format-Indentation`.

    .OUTPUTS
    String.
    `Format-Indentation` returns a copy of the specified string formatted
    to the designated indentation level.

    .LINK
    Get-IndentString
#>
function Format-Indentation {

    param(
        <#
            The string to be formatted.
        #>
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$String,

        <#
            The indentation level to use when determining how
            much to indent each line of the string.

            Each indentation level corresponds to 2 spaces of indentation.

            Defaults to 1. If a value less than 1 is specified,
            the returned string will have no base indentation.
        #>
        [Parameter(Mandatory, Position = 1)]
        [int]$Indentation
    )

    process {
        [int]$baseIndentation = (
            [regex]::Matches($String, "(^|\n+)( *)") |
                ForEach-Object { $_.Groups[2] } |
                    Measure-Object -Property Length -Minimum
        ).Minimum
    
        return $String -replace "(^|\n+)( {0,$baseIndentation})","`$1$(Get-IndentString $Indentation)"
    }


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
    param(
        <#
            The Component Update to write to the console.
        #>
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
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


# Progress Bars #

<#
    An internal class representing a Progress Bar
    rendered in the terminal during the Link2Root Setup.
#>
class Link2RootProgressBar {

    <#
        The name of the Progress Bar, which is used for
        the `-Action` parameter when calling `Write-Progress`.
    #>
    [Alias("Action")]
    [ValidateNotNullOrEmpty()]
    [string]$Name = "Running Operation"

    <#
        The current percentage of the Progress Bar,
        stored as a floating-point number between 0 and 100.
    #>
    [ValidateRange(0, 100)]
    [float]$CurrentPercentage = 0

    <#
        The default amount of progress that the Progress Bar
        will make every time that `Update-ProgressBar` is called
        unless a specified `-PercentageChange` is specified,
        stored as a floating-point number between 0 and 100.
    #>
    [ValidateRange(0, 100)]
    [float]$DefaultPercentageChange = 1

    <#
        A positive, nonzero floating-point number representing the initial amount
        of time remaining for the action visualized by the
        Progress Bar in seconds.
    #>
    [ValidateRange(0, 999)]
    [float]$InitialSecondsRemaining = 1

    <#
        Indicates that the Progress Bar is to be hidden and not
        rendered in the terminal.

        This value is used by functions and cmdlets to selectively render
        Progress Bars based on the presence or absence of a switch
        passed to the functon or cmdlet.
    #>
    [bool]$Hidden = $false

    <#
        Indicates if any calls have been made to `Update-ProgressBar`
        with this Progress Bar active since its creation.

        This value is used to delay updating the Progress Bar until
        after the first update made to it used to display it for the first time.
    #>
    [bool]$FirstUpdate = $false
    
}

<#
    Indicates if any Setup Progress Bars can currently be
    rendered in the terminal or not.
    
    Managed by the `Enable-ProgressBars` and `Disable-ProgressBars` functions.
#>
[bool]$progressBarsEnabled = $true
<#
    A stack of `Link2RootProgressBar`s used to manage
    all of the Active Setup Progress Bars.
#>
[System.Collections.Generic.Stack[Link2RootProgressBar]]$activeProgressBars = [System.Collections.Generic.Stack[Link2RootProgressBar]]::new()

<#
    .SYNOPSIS
    Add a new Setup Progress Bar.

    .DESCRIPTION
    Add a new Progress Bar used to visualize the
    current status and progress of setting up Link2Root.

    Progress Bars are nested, such that Progress Bars created
    by later calls to `Add-ProgressBar` are nested under those
    created by the earlier function calls.

    Once created, the Progress Bar can be updated as long as it
    is the Active Setup Progress Bar using `Update-ProgressBar`.

    Every call to `Add-ProgressBar` should be matched with a
    call to `Remove-ProgressBar` later in the code.

    If a specified Setup Progress Bar is or is not to be rendered in the terminal,
    it can be specified during its creation using the `-Hidden` or `-Disabled` switch.

    .INPUTS
    None.
    You cannot pipe any objects to `Add-ProgressBar`.

    .OUTPUTS
    None.
    `Add-ProgressBar` does not generate any output.

    .LINK
    Update-ProgressBar

    .LINK
    Remove-ProgressBar

    .LINK
    Enable-ProgressBar

    .LINK
    Disable-ProgressBar
#>
function Add-ProgressBar {

    param(
        <#
            The name of the Progress Bar, which is used for
            the `-Action` parameter when calling `Write-Progress`.
        #>
        [Alias("Action")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        <#
            The default amount of progress that the Progress Bar
            will make every time that `Update-ProgressBar` is called
            unless a specified `-PercentageChange` is specified,
            stored as a floating-point number between 0 and 100.

            To prevent the Progress Bar from making any progress
            unless explicitly specified, specify a value of 0 for this parameter.
        #>
        [ValidateRange(0, 100)]
        [float]$DefaultPercentageChange = 1,

        <#
            A positive, nonzero floating-point number representing the initial amount
            of time remaining for the action visualized by the
            Progress Bar in seconds.
        #>
        [ValidateRange(0, 999)]
        [float]$InitialSecondsRemaining = 1,

        <#
            Indicates that the Progress Bar is to be hidden and not
            rendered in the terminal.

            This switch can be used by functions and cmdlets to selectively render
            Progress Bars based on the presence or absence of a switch
            passed to the functon or cmdlet.
        #>
        [Alias("Disabled")]
        [switch]$Hidden
    )

    $script:activeProgressBars.Push((New-Object Link2RootProgressBar -Property $PSBoundParameters))

}

<#
    .SYNOPSIS
    Set the Global Visibility of Setup Progress Bars.

    .DESCRIPTION
    Globally Show or Hide Progress Bars used to visualize
    progress during the Link2Root Setup.

    After calling this function, all subsequent calls to `Update-ProgressBar`
    will not cause any Progress Bars to appear or be updated until the
    `Enable-ProgressBars` function has been called.

    This function has no effect on Setup Progress Bars that have been
    selectively hidden using the `-Hidden` switch when calling `Add-ProgressBar`,
    or on progress bars created by built-in functions and cmdlets. To control the
    behavior of all PowerShell progress bars, use the `$ProgressPreference` automatic variable.

    .INPUTS
    None.
    You cannot pipe any objects to `Hide-ProgressBar`.

    .OUTPUTS
    None.
    `Hide-ProgressBar` does not generate any output.

    .LINK
    Add-ProgressBar

    .LINK
    Update-ProgressBar

    .LINK
    Remove-ProgressBar
#>
function Hide-ProgressBars {

    param(
        <#
            Indicates whether or not Setup Progress Bars are to
            be rendered in the terminal.
        #>
        [Alias("Disabled", "NoProgress", "HideProgress", "Silent")]
        [Parameter(Mandatory, Position = 0)]
        [bool]$Hidden
    )

    $script:progressBarsEnabled = (-not $Hidden)

}

<#
    .SYNOPSIS
    Remove the Active Setup Progress Bar.

    .DESCRIPTION
    Remove the Active Setup Progress Bar used to visualize the
    current status and progress of setting up Link2Root.

    Every call to `Remove-ProgressBar` should be preceeded with a
    call to `Add-ProgressBar` prior in the code. If `Remove-ProgressBar`
    is called when there are no Active Setup Progress Bars,
    an exception will be thrown.

    .INPUTS
    None.
    You cannot pipe any objects to `Remove-ProgressBar`.

    .OUTPUTS
    None.
    `Remove-ProgressBar` does not generate any output.

    .LINK
    Add-ProgressBar
    
    .LINK
    Update-ProgressBar

    .LINK
    Enable-ProgressBar

    .LINK
    Disable-ProgressBar
#>
function Remove-ProgressBar {

    if ($script:activeProgressBars.Count -eq 0) {
        throw "No Progress Bar is Currently Active to Remove!"
    }
    
    Update-ProgressBar -PercentageChange 100 -Completed
    $script:activeProgressBars.Pop() | Out-Null

}

<#
    .SYNOPSIS
    Update the Active Setup Progress Bar.

    .DESCRIPTION
    Update the Active Setup Progress Bar used to visualize the
    current status and progress of setting up Link2Root.

    The contents of the Progress Bar can be set using the
    `-Action` and `-CurrentOperation` parameters. The previous contents
    of the Progress Bar are NOT maintained between calls to `Update-ProgressBar`,
    and each function call will overwrite the current contents of the Progress Bar.

    The progress made on the Progress Bar and the corresponding change in the
    Estimated Time Remaining can also be specified using the `-PercentageChange` parameter.
    If omitted, the Default Percentage Change specified for the Progress Bar using the
    `-DefaultPercentageChange` parameter of `Add-ProgressBar` will be used instead.
    To prevent the progress of the Progress Bar from changing between calls to `Update-ProgressBar`,
    pass `-PercentageChange 0` to the function or `-DefaultPercentageChange 0` to `Add-ProgressBar`.

    The visibility of the Progress Bar is also updated by this function. If the `-Hidden`, `-Disabled`,
    or `-Completed` switches are used, the Progress Bar will be hidden. If none of the switches are
    specified, the Progress Bar will be displayed. However, if `$ProgressPreference` is set to "SilentlyContinue",
    if the Progress Bar was created using the `-Hidden` or `-Disabled` option when calling `Add-ProgressBar`,
    or if Setup Progress Bars have been Globally Disabled using `Disable-ProgressBars`, no progress bars will be
    displayed or updated by this function, even if none of the above switches are specified.

    Every call to `Update-ProgressBar` should be preceeded with a
    call to `Add-ProgressBar` prior in the code. If `Update-ProgressBar`
    is called when there are no Active Setup Progress Bars,
    an exception will be thrown.

    .INPUTS
    String.
    You cannot pipe any objects to `Update-ProgressBar`.

    .OUTPUTS
    None.
    `Update-ProgressBar` does not generate any output.

    .LINK
    Add-ProgressBar
    
    .LINK
    Remove-ProgressBar

    .LINK
    Enable-ProgressBar

    .LINK
    Disable-ProgressBar
#>
function Update-ProgressBar {

    [Alias("_upb")]
    param(
        <#
            The current state of the operation being visualized.

            Rendered as the second line of text in the heading of the Progress Bar.
            
            Unlike the `-CurrentOperation`, the status is always rendered in the Progress Bar,
            even when the Progress View is `Minimal`.
        #>
        [string]$Status,

        <#
            The current operation taking place.

            Rendered as the line of text rendered below the Progress Bar.
            
            Unlike the `-CurrentOperation`, the current operation will not be
            rendered in the Progress Bar when the Progress View is `Minimal`.
        #>
        [string]$CurrentOperation,

        <#
            The amount of progress that the Progress Bar will make
            as a floating-point number between 0 and 100.

            To prevent the Progress Bar from making any progress
            during the current update, specify a value of 0 for this parameter.
        #>
        [ValidateRange(0, 100)]
        [Nullable[int]]$PercentageChange,

        <#
            Indicates that the Progress Bar is to be hidden and not
            rendered in the terminal until a subsequent call to `Update-ProgressBar`
            without the switch.
        #>
        [Alias("Disabled", "Hidden")]
        [switch]$Completed
    )

    if ($script:activeProgressBars.Count -gt 0) {
        [ref]$pb = $script:activeProgressBars.Peek()
        
        if ($null -eq $PercentageChange) {
            $PercentageChange = $pb.Value.DefaultPercentageChange
        }
        
        [hashtable]$progressArgs = @{
            Activity = $pb.Value.Name
            Id = ($script:activeProgressBars.Count - 1)
            ParentId = ($script:activeProgressBars.Count - 2)
            Completed = ($Completed -or -not $script:progressBarsEnabled -or $pb.Value.Hidden)
        }
    
        if ($pb.Value.FirstUpdate) {
            $progressArgs["PercentComplete"] = [Math]::Round(($pb.Value.CurrentPercentage += [Math]::Min($PercentageChange, (100 - $pb.Value.CurrentPercentage))))
            $progressArgs["SecondsRemaining"] = [Math]::Round($pb.Value.InitialSecondsRemaining - (($pb.Value.CurrentPercentage / 100) * ($pb.Value.InitialSecondsRemaining - 1)))
        }
        else {
            $progressArgs["PercentComplete"] = 0
            $progressArgs["SecondsRemaining"] = [Math]::Round($pb.Value.InitialSecondsRemaining)
            $pb.Value.FirstUpdate = $true
        }
    
        if ($CurrentOperation) {
            $progressArgs["CurrentOperation"] = $CurrentOperation
        }
        if ($Status) {
            $progressArgs["Status"] = $Status
        }
    
        Write-Progress @progressArgs
    }
    else {
        throw "No Progress Bar is Currently Active to Update!"
    }

}


# Setup Components #

<#
    An enumeration defining the individual components
    that can be installed, tested, and uninstalled
    during the Link2Root Setup.
#>
enum SetupComponent {
    LocalInstall
    PowerShellModule
    PATHUpdate
}
[psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Add(
    "link2rootSetupComponent",
    [SetupComponent]
)

<#
    .SYNOPSIS
    Get Setup Component Argument Completion Suggestions.

    .DESCRIPTION
    Get the Setup Component Argument Completion Suggestions
    for a Setup Function or Cmdlet.

    This function serves as an `ArgumentCompleter` for the
    `-Components` Parameter added to Setup Functions and Cmdlets.

    .INPUTS
    None.
    You cannot pipe any objects to `Get-SetupComponentArgumentCompletions`.

    .OUTPUTS
    string
    `Get-SetupComponentArgumentCompletions` returns a
    Setup Component Argument Completion Suggestion.

    .EXAMPLE
    [ArgumentCompleter({
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Get-SetupComponentArgumentCompletions
        Get-SetupComponentArgumentCompletions @args
    })]
    [string[]]$Components

    .LINK
    Get-SetupComponents

    .Link
    Test-SetupComponent

    .Link
    Test-SetupComponentParameter
#>
function Get-SetupComponentArgumentCompletions {

    param (
        <#
            The name of the command for which the function
            is providing tab completion.
        #>
        [string]$commandName,
        
        <#
            The parameter whose value requires tab completion.
        #>
        [string]$parameterName,

        <#
            The value the user has provided before they pressed `Tab`.
        #>
        [string]$wordToComplete,

        <#
            The Abstract Syntax Tree (AST) for the current input line.
        #>
        [System.Management.Automation.Language.Ast]$commandAst,

        <#
            A hashtable containing the `$PSBoundParameters` for the cmdlet,
            before the user pressed `Tab`. 
        #>
        [hashtable]$fakeBoundParameters
    )
    
    $components = Get-SetupComponents
    $suggestions = @(@(), @(), @())
    
    if ($fakeBoundParameters.ContainsKey("Components")) {
        $components = (Compare-Object $components $fakeBoundParameters["Components"]).InputObject
    }

    foreach ($component in $components) {
        if ($component -ine $wordToComplete) {
            if ($component -ilike "$wordToComplete*") {
                $suggestions[0] += $component
            }
            elseif ($component[0].ToString().ToLower() -lt $wordToComplete[0].ToString().ToLower()) {
                $suggestions[2] += $component
            }
            else {
                $suggestions[1] += $component
            }
        }
    }

    $suggestions | ForEach-Object { $_ } | ForEach-Object { $_ }
    
}

<#
    .SYNOPSIS
    Get the Link2Root Setup Components.

    .DESCRIPTION
    Get a list of the individual components that can be
    installed, tested, and uninstalled during the Link2Root Setup.

    By default, all of the available Setup Components are returned.
    To filter the list of Setup Components, use the `-Filter` parameter.

    .INPUTS
    None.
    You cannot pipe any objects to `Get-SetupComponents`.

    .OUTPUTS
    SetupComponent[]
    `Get-SetupComponents` returns an array of `SetupComponent` enumeration values
    representing the various Link2Root Setup Components matching the designated `-Filter` (if specified.)

    .EXAMPLE
    [string[]]$Components = (& {
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Get-SetupComponents
        Get-SetupComponents -Filter Default
    })

    .LINK
    Get-SetupComponentArgumentCompletions

    .Link
    Test-SetupComponent

    .Link
    Test-SetupComponentParameter
#>
function Get-SetupComponents {

    [OutputType([SetupComponent[]])]
    param(
        <#
            Optionally filter the returned Setup Components.

            The available options include:
            - "Default": The Setup Components installed, tested, and uninstalled by default.
            - "Non-Default": All of the Setup Components that are NOT installed, tested, and uninstalled by default.
        #>
        [ValidateSet("Default", "Non-Default")]
        [string]$Filter
    )

    $components = [System.Enum]::GetNames([SetupComponent])

    if ($Filter -ieq "Default")         { return $components }
    elseif ($Filter -ieq "Non-Default") { return @() }
    else                                { return $components }

}

<#
    .SYNOPSIS
    Test if a string is a valid Link2Root Setup Component.

    .DESCRIPTION
    Test if a string can be converted to a valid
    `SetupComponent` enumeration value corresponding
    to a Link2Root Setup Component.

    .INPUTS
    None.
    You cannot pipe any objects to `Test-SetupComponent`.

    .OUTPUTS
    bool.
    `Test-SetupComponent` returns `$true` if the specified string
    is a valid Link2Root Setup Component or `$false` if it is not.

    .Link
    Test-SetupComponentParameter

    .Link
    Get-SetupComponents
    
    .LINK
    Get-SetupComponentArgumentCompletions

#>
function Test-SetupComponent {

    param(
        <#
            The value being tested.
        #>
        [Parameter(Position = 0)]
        [string]$Value
    )

    process {
        [System.Enum]::IsDefined([SetupComponent], $Value)
    }

}

<#
    .SYNOPSIS
    Test if a string parameter value matches a valid Link2Root Setup Component.

    .DESCRIPTION
    Test if a string parameter value can be converted to a valid
    `SetupComponent` enumeration value corresponding
    to a Link2Root Setup Component.

    .INPUTS
    string.
    You can pipe the string parameter value
    to be tested to `Test-SetupComponentParameter`.

    .OUTPUTS
    bool.
    `Test-SetupComponentParameter` returns `$true` if the specified string
    parameter value is a valid Link2Root Setup Component or `$false` if it is not.

    .EXAMPLE
    [ValidateScript({
        Import-Module "$PSScriptRoot\Utils.psm1" -Function Test-SetupComponentParameter
        $_ | Test-SetupComponentParameter
    })]
    [string[]]$Components

    .Link
    Test-SetupComponent

    .Link
    Get-SetupComponents
    
    .LINK
    Get-SetupComponentArgumentCompletions
#>
function Test-SetupComponentParameter {

    [OutputType([bool])]
    param(
        <#
            The string parameter value being tested.
        #>
        [Parameter(Position = 0, ValueFromPipeline)]
        [string]$Component
    )

    process {
        if (-not (Test-SetupComponent $component)) {
            throw "Unrecognized Setup Component Specified: $component"
        }
    }

    end {
        return $true
    }

}


# Miscellaenous Helper Functions #

<#
    .SYNOPSIS
    Get the Dynamic Verbose Description for a Confirmation Prompt

    .DESCRIPTION
    Get the Verbose Description for a PowerShell Confirmation Prompt, which is
    generated dynamically based on the `-WhatIfValue` passed to the function.

    .INPUTS
    None.
    You cannot pipe any objects to `Get-VerboseConfirmationPromptDescription`.

    .OUTPUTS
    String.
    `Get-VerboseConfirmationPromptDescription` returns a string to be used
    as the Verbose Description for a PowerShell Confirmation Prompt.

    .EXAMPLE
    if ($PSCmdlet.ShouldProcess(
        (Get-VerboseConfirmationPromptDescription `
            -Value $WhatIfPreference `
            -Description "Copying Install Files" `
            -Indent 2
        ),
        "Copy Install Files",
        "Confirm`nAre you sure you want to perform this action?"
    )) {
        // ...    
    }
#>
function Get-VerboseConfirmationPromptDescription {

    [Alias("_gvcpd")]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        <#
            The value of the `$WhatIfPreference` Preference Variable.
        #>
        [Alias("Value")]
        [Parameter(Mandatory, Position = 0)]
        [bool]$WhatIfValue,

        <#
            The description to use if the `-WhatIfValue` is `$true`.
        #>
        [Alias("Description")]
        [Parameter(Position = 1)]
        [string]$WhatIfDescription,
        
        <#
            The indentation level to use when the `-WhatIfValue` is `$false`.
        #>
        [Alias("Indent")]
        [Parameter(Position = 2)]
        [int]$Indentation = 5
    )

    if (-not $WhatIfValue) { return "$(_gis $Indentation)[+] Confirmation APPROVED" }
    else                   { return "$WhatIfDescription" }

}

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

    return "${env:USERDOMAIN}\${env:USERNAME}"

}

<#
    .SYNOPSIS
    Test if a file matches the specified pattern.

    .DESCRIPTION
    Test if a file path matches the specified `-Filter`,
    `-Include`, and `-Exclude` patterns.

    .INPUTS
    string.
    You can pipe a string containing the path to be tested to `Test-FilePattern`.

    .OUTPUTS
    bool.
    `Test-FilePattern` returns boolean `$true` if the specified file path matches
    the designated pattern or `$false` if it does not.
#>
function Test-FilePattern {

    [CmdletBinding(PositionalBinding = $false)]
    param(
        <#
            The path to be tested.
        #>
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Path,

        <#
            Specifies a filter to qualify the `Path` parameter.
            
            Filters are more efficient than other parameters. The provider applies the filter when the cmdlet
            gets the objects rather than having PowerShell filter the objects after they're retrieved.
            
            The filter string is passed to the .NET API to enumerate files.
            The API only supports * and ? wildcards.
        #>
        [SupportsWildcards()]
        [string]$Filter,

        <#
            Specifies, as a string array, an item or items that this cmdlet includes in the operation.
            
            The value of this parameter qualifies the `Path` parameter.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [SupportsWildcards()]
        [string[]]$Include,

        <#
            Specifies, as a string array, an item or items that this cmdlet excludes in the operation.
            
            The value of this parameter qualifies the `Path` parameter.
            
            Enter a path element or pattern, such as *.txt. Wildcard characters are permitted.
        #>
        [SupportsWildcards()]
        [string[]]$Exclude,

        <#
            An internal parameter used to specify the indentation
            level to use for output logging.
        #>
        [Parameter(DontShow)]
        [int]$Indentation = 0
    )

    [string]$fileType = & {
        if ((Test-Path $Path -PathType Container)) { return "Directory" }
        else                                       { return "File" }
    }
    [string]$fileName = Split-Path $Path -Leaf

    foreach ($Pattern in $Exclude) {
        if ($Path -ilike $Pattern -or $fileName -ilike $Pattern) {
            Write-Verbose "$(_gis $Indentation)[/] Skipped ${fileType}: $Path"
            Write-Verbose "$(_gis ($Indentation + 1))[#] Matched Exclusion Pattern: $Pattern"
            return $false
        }
    }

    if ($Include.Count -gt 0) {
        foreach ($pattern in $Include) {
            if ($Path -ilike $pattern -or $fileName -ilike $pattern) {
                return $true
            }
        }
        
        Write-Verbose "$(_gis ($Indentation + 1))[>] No Match for Inclusion Patterns:"

        foreach ($pattern in $Include) {
            Write-Verbose "$(_gis ($Indentation + 2))[#] $pattern"
        }

        return $false
    }

    return $true

}


# Exports #

Export-ModuleMember `
    -Alias * `
    -Function * `
    -Variable NO_RISK_PARAMS, SETUP_FOLDER_IGNORED_FILES