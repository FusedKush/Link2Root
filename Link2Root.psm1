# Internal Helper Functions #

# The validation function used for `-Path` function parameters.
function Test-PathParameter {

    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "The specified path could not be found or accessed."
    }

    return $true

}

# The validation function used for `-Drive` function parameters.
function Test-DriveParameter {

    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Drive
    )

    if ($Drive.Length -ne 1 -or -not (Test-Path "${Drive}:\")) {
        throw "An invalid Drive Letter was specified."
    }

    return $true;

}


# Exported Functions #

<#
    .SYNOPSIS
    Get the path to a shortcut link at the root of the drive or the target of an existing one.

    .DESCRIPTION
    Get the path to a shortcut link of the given name on the designated disk drive.

    When the `-GetLinkedPath` switch is used, the linked path of the existing
    shortcut link on the root of the designated disk drive will be retrieved instead.

    .INPUTS
    None.
    You cannot pipe any objects to `Get-Link2Root`.

    .OUTPUTS
    string.
    `Get-Link2Root` returns a string containing either the path to the
    shortcut link of the given name on the designated drive, or
    the target of an existing one, depending on the presence or absence
    of the `-GetLinkedPath` switch.

    If the `-GetLinkedPath` switch is used and no shortcut link
    with the given name exists on the designated disk drive,
    `Get-Link2Root` returns `$null`.

    .EXAMPLE
    Get-Link2Root
    C:\$

    Retrieves the path to a shortcut link with the
    name of "$" on the `C:` drive.

    .EXAMPLE
    Get-Link2Root X myShortcut
    X:\myShortcut

    Retrieves the path to a shortcut link with the
    name of "myShortcut" on the `X:` drive.

    .EXAMPLE
    Get-Link2Root -GetLinkedPath
    C:\path\to\target

    Retrieves the linked path of an existing
    shortcut link with the name of "$" on the `C:` drive.

    .EXAMPLE
    Get-Link2Root -Drive x -GetLinkedPath
    ($null / No Output)

    Retrieves the linked path of an existing
    shortcut link with the name of "$" on the `X:` drive.

    .LINK
    Test-Link2Root

    .LINK
    New-Link2Root
#>
function Get-Link2Root {

    [CmdletBinding()]
    [OutputType([string])]
    param(
         <#
            The letter of the disk drive in which
            to retrieve the shortcut link at the root for.

            For example, `C` or `x`.
        #>
        [Alias("DriveLetter")]
        [Parameter(Position = 0)]
        [ValidateScript({ Test-DriveParameter $_ })]
        [PSDefaultValue(Help = "The Disk Drive of the Current Working Directory.")]
        [string]$Drive = (Split-Path (Resolve-Path $PWD) -Qualifier)[0],
        
        <#
            The name of the shortcut link to retrieve
            at the root of the designated drive.
        #>
        [Alias("Link")]
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Shortcut = "$",

        <#
            Indicates that the linked path of an existing
            shortcut with the given name on the designated drive
            should be returned instead.

            By default and when this parameter is omitted,
            this function returns the path to the shortcut itself.
        #>
        [switch]$GetLinkedPath
    )

    # The path to the shortcut link.
    [string]$path = (Join-Path "${Drive}:" $Shortcut)

    if (-not $GetLinkedPath) {
        return $path
    }
    else {
        if (-not (Test-Path $path)) {
            return $null
        }

        return (Get-Item $path).Target
    }

}

<#
    .SYNOPSIS
    Test if a shortcut link exists on the root of the drive.

    .DESCRIPTION
    Test if a Hard Link or Directory Junction of the given name
    exists on the root of the designated disk drive.

    By default, this function only tests for the existence of
    a shortcut link with the given name on the designated drive.
    However, when the `-Path` parameter is provided, this function
    will also test if the existing link points to the same `-Path` or not.

    .INPUTS
    string.
    You can pipe a string containing a path to test
    the shortcut link for to `Test-Link2Root`.

    .OUTPUTS
    bool.
    `Test-Link2Root` returns `$true` if a shortcut link
    with the given name exists on the designated disk drive.

    If the `-Path` parameter is specified, the existing shortcut
    link must also be pointing to the same location as the
    specified `-Path`.

    Otherwise, `Test-Link2Root` returns `$false`.

    .EXAMPLE
    Test-Link2Root
    True

    Tests for the existence of a shortcut link
    with the name of "$" on the `C:` drive.

    .EXAMPLE
    Test-Link2Root "X" "myShortcut"
    False

    Tests for the existence of a shortcut link
    with the name of "myShortcut" on the `X:` drive.

    .EXAMPLE
    Test-Link2Root -Path "X:/path/to/target"
    True

    Tests for the existence of a shortcut link
    with the name of "$" on the `X:` drive
    that is pointing to "X:/path/to/target".

    .EXAMPLE
    Resolve-Path "./testing" | Test-Link -Drive X
    False

    Tests for the existence of a shortcut link
    with the name of "$" on the `X:` drive
    that is pointing to "C:/path/to/target/testing"

    .LINK
    Get-Link2Root

    .LINK
    New-Link2Root
#>
function Test-Link2Root {

    [CmdletBinding(DefaultParameterSetName = "WithDrive")]
    [OutputType([bool])]
    param(
        <#
            The letter of the disk drive in which
            to search for the shortcut link at the root of.

            For example, `C` or `x`.

            If omitted, defaults to the disk drive of
            the Current Working Directory.
        #>
        [Alias("DriveLetter")]
        [Parameter(Position = 0, ParameterSetName = "WithDrive")]
        [Parameter(Position = 0, ParameterSetName = "WithDriveAndPath")]
        [ValidateScript({ Test-DriveParameter $_ })]
        [PSDefaultValue(Help = "The Disk Drive of the Current Working Directory.")]
        [string]$Drive = (Split-Path (Resolve-Path $PWD) -Qualifier)[0],

        <#
            The name of the shortcut link to search for
            at the root of the designated drive.
        #>
        [Alias("Link")]
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Shortcut = "$",

        <#
            The target path to test any matching shortcut links for.

            When this parameter is specified, this function will also
            check if the existing shortcut link has the same path
            as this parameter value.
        #>
        [Alias("FilePath", "FolderPath", "DirectoryPath", "Target")]
        [Parameter(Mandatory, Position = 2, ValueFromPipeline, ParameterSetName = "WithPath")]
        [Parameter(Mandatory, Position = 2, ValueFromPipeline, ParameterSetName = "WithDriveAndPath")]
        [ValidateScript({ Test-PathParameter $_ })]
        [string]$Path
    )

    if ($PSCmdlet.ParameterSetName -eq "WithPath") {
        $Drive = (Split-Path (Resolve-Path $Path) -Qualifier)[0]
    }

    # The path to the shortcut link.
    [string]$shortcutPath = Get-Link2Root -Drive $Drive -Shortcut $Shortcut
    # Whether or not the shortcut link already exists
    [bool]$shortcutExists = (Test-Path $shortcutPath)

    if ($PSCmdlet.ParameterSetName -eq "WithDrive") {
        return $shortcutExists
    }
    else {
        return (
            $shortcutExists -and
            (Get-Link2Root -Drive $Drive -Shortcut $Shortcut -GetLinkedPath) -ieq (Resolve-Path $Path)
        )
    }

}

<#
    .SYNOPSIS
    Create a new shortcut link on the root of the drive.

    .DESCRIPTION
    Creates a new Hard Link or Directory Junction
    for the specified file or directory on the root
    of the designated disk drive.

    Such shortcuts are useful for quickly referring to
    long file paths during testing or debugging. For example,
    a directory junction could be created for the path,
    "X:\my-super-long-project-name\another-really-long-path\src\my-super-cool-module",
    accessible at "X:\$".

    If an existing shortcut already exists at the root of the drive,
    it will be automatically overwritten unless the `-NoClobber` switch is used.

    .INPUTS
    string.
    You can pipe a string containing the path to be linked to `New-Link2Root`.

    .OUTPUTS
    None.
    By default, `New-Link2Root` generates no output.

    .OUTPUTS
    bool.
    When the `-PassThru` switch is used, `New-Link2Root`
    returns `$true` if a link was successfully created on
    the designated drive root to the specified file or directory.

    Otherwise, `New-Link2Root` will return `$false`.

    .EXAMPLE
    New-Link2Root
    Creating Root Link: C:\$ ---> C:\... Success!

    Creates a Directory Junction via "$" on the `C:` drive
    to the current working directory.

    .EXAMPLE
    New-Link2Root "X:\my-super-long-project-name\src" "projects" "C"
    Creating Root Link: C:\projects ---> X:\my-super-long-project-name\src\... Success!

    Creates a Directory Junction via "projects" on the `C:` drive
    to "X:\my-super-long-project-name\src".

    .EXAMPLE
    "X:\my-super-long-project-name\src\index.js" | New-Link2Root -NoClobber
    Creating Root Link: X:\$ ---> X:\my-super-long-project-name\src\index.js... Success!
    Root Link X:\$ ---> X:\my-super-long-project-name\src already exists!

    Creates a Hard Link via "$" on the `X:` drive
    to "X:\my-super-long-project-name\src\index.js",
    while ensuring that any existing "$" shortcut
    on the `X:` drive won't be overwritten.

    .EXAMPLE
    $result = Join-Path X:\my-super-long-project-name src | New-Link2Root -PassThru -Silent

    Creates a Directory Junction via "$" on the `X:` drive
    to "X:\my-super-long-project-name\src", storing the
    result as a boolean in a variable and preventing the
    results of the function from being written to the host.

    .LINK
    Get-Link2Root

    .LINK
    Test-Link2Root
#>
function New-Link2Root {
    
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        <#
            The path to create a link at the root of the drive to.

            The path can point to either a file or directory.
        #>
        [Alias("FilePath", "FolderPath", "DirectoryPath", "Target")]
        [Parameter(ValueFromPipeline)]
        [ValidateScript({ Test-PathParameter $_ })]
        [string]$Path = $PWD,

        <#
            The name of the shortcut link to create
            at the root of the designated drive.
        #>
        [Alias("Link")]
        [ValidateNotNullOrEmpty()]
        [string]$Shortcut = "$",
        
        <#
            The letter of the disk drive in which
            to place the shortcut link at the root of.

            For example, `C` or `x`.
        #>
        [ValidateScript({ Test-DriveParameter $_ })]
        [PSDefaultValue(Help = "The Disk Drive containing the specified -Path.")]
        [string]$Drive = (Split-Path (Resolve-Path $Path) -Qualifier)[0],

        <#
            Indicates that if an existing shortcut link of the
            same name already exists on the designated drive,
            it will not be overwritten.

            By default and when this switch is omitted, existing shortcuts
            of the same name will automatically be overwritten.
        #>
        [switch]$NoClobber,

        <#
            Indicates that this function should return a boolean value
            indicating whether or not the specified location was successfully
            linked to the root of the designated drive or not.

            By default and when this switch is omitted,
            this function does not return anything.
        #>
        [switch]$PassThru,
    )
    

    # Variables #

    # The console color to use for the links in the output.
    [System.ConsoleColor]$LINK_COLOR = [System.ConsoleColor]::Cyan
    # The console color to use for arrows in the output.
    [System.ConsoleColor]$ARROW_COLOR = [System.ConsoleColor]::Yellow

    # The resolved target path to be linked.
    [string]$resolvedPath = (Resolve-Path $Path)
    # The path to the shortcut link to be created.
    [string]$shortcutPath = (Join-Path "${Drive}:" $Shortcut)
    

    # Helper Functions #
    
    <#
        Link the shortcut at the root of the
        `-Drive` passed to `New-Link2Root` and with
        the specified `-Shortcut` name to the
        designated `-Path`.

        If an existing shortcut of the same name already
        exists on the designated disk drive, the shortcut
        may be overwritten or an exception may be thrown instead,
        depending on the presence or absence of the `-NoClobber` switch
        when `New-Link2Root` was called.
    #>
    function Set-RootLink {
    
        [CmdletBinding(SupportsShouldProcess)]
        [OutputType([bool])]
        param()

        # The type of shortcut being created.
        [string]$pathType = & {

            if (Test-Path $resolvedPath -Type Container) {
                return "Junction"
            }
            else {
                return "HardLink"
            }

        }

        if (Test-Link2Root -Drive $Drive -Shortcut $Shortcut) {
            # The linked path of the existing shortcut link.
            [string]$existingLink = Get-Link2Root -Drive $Drive -Shortcut $Shortcut -GetLinkedPath

            if (-not $NoClobber) {
                Write-Verbose "Root Link Already Exists: $shortcutPath ---> $existingLink"
                
                if ($PSCmdlet.ShouldProcess(
                    "Removing Existing Root Link: $shortcutPath ---> $existingLink",
                    "Remove Existing Root Link: $shortcutPath ---> $existingLink",
                    "Confirm`nAre you sure you want to perform this action?"
                )) {
                    (Get-Item $shortcutPath).Delete()

                    # if (Test-Path $shortcutPath -Type Container) {
                    #     [System.IO.Directory]::Delete($shortcutPath)
                    # }
                    # else {
                    #     [System.IO.File]::Delete($shortcutPath)
                    # }
                }
                elseif (!$WhatIfPreference) {
                    throw "The operation was cancelled."
                }
            }
            else {
                throw "Root Link $shortcutPath ---> $existingLink already exists!"
            }
        }
    
        if ($PSCmdlet.ShouldProcess(
            "Creating Root Link: $shortcutPath ---> $resolvedPath",
            "Create Root Link: $shortcutPath ---> $resolvedPath",
            "Confirm`nAre you sure you want to perform this action?"
        )) {
            New-Item -ItemType $pathType -Path $shortcutPath -Target (Resolve-Path $Path) -WhatIf:$false -Confirm:$false | Out-Null
            return $true
        }
        elseif (!$WhatIfPreference) {
            throw "The operation was cancelled."
        }

        return $false

    }
    
    
    # Main Function #

    if (-not (Test-Link2Root -Drive $Drive -Shortcut $Shortcut -Path $Path)) {
        # Indicates if the -Confirm switch is being used.
        [bool]$confirm = ([int]$ConfirmPreference -le [int][System.Management.Automation.ConfirmImpact]::Medium)
        # Indicates if the -Verbose or -WhatIf switches are being used.
        [bool]$useVerboseOutput = ($VerbosePreference -or $WhatIfPreference -or $confirm)

        try {
            Write-Host "Creating Root Link: " -NoNewline
            Write-Host $shortcutPath -ForegroundColor $LINK_COLOR -NoNewline
            Write-Host " ---> " -ForegroundColor $ARROW_COLOR -NoNewline
            Write-Host $resolvedPath -ForegroundColor $LINK_COLOR -NoNewline
            Write-Host "... " -NoNewline

            if ($useVerboseOutput) {
                Write-Host ""
            }

            if (Set-RootLink -Verbose:$VerbosePreference) {
                if ($useVerboseOutput) {
                    if ($confirm) {
                        Write-Host ""
                    }

                    Write-Host "Successfully" -ForegroundColor Green -NoNewline
                    Write-Host " linked " -NoNewline
                    Write-Host $shortcutPath -ForegroundColor $LINK_COLOR -NoNewline
                    Write-Host " to " -NoNewline
                    Write-Host $resolvedPath -ForegroundColor $LINK_COLOR
                }
                else {
                    Write-Host "Success!" -ForegroundColor Green
                }
    
                if ($PassThru) {
                    return $true
                }
            }
        }
        catch {
            if ($useVerboseOutput) {
                if ($confirm) {
                    Write-Host ""
                }

                Write-Host "Failed" -ForegroundColor Red -NoNewline
                Write-Host " to link " -NoNewline
                Write-Host $shortcutPath -ForegroundColor $LINK_COLOR -NoNewline
                Write-Host " to " -NoNewline
                Write-Host $resolvedPath -ForegroundColor $LINK_COLOR
            }
            else {
                Write-Host "Failed!" -ForegroundColor Red
            }

            Write-Host ""
            # Write-Host $_ -ForegroundColor Red
            Write-Error $_
        }
    }
    else {
        Write-Host $shortcutPath -ForegroundColor $LINK_COLOR -NoNewline
        Write-Host " is already linked to " -NoNewline
        Write-Host $resolvedPath -ForegroundColor $LINK_COLOR

        if ($PassThru) {
            return $true
        }
    }

    if ($PassThru) {
        return $false
    }
}


# Exports #

Export-ModuleMember -Function Get-Link2Root, Test-Link2Root, New-Link2Root