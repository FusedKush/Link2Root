@ECHO off
SETLOCAL EnableDelayedExpansion

SET "BASE_CMDLET_NAME=Link2Root"

SET "Args="
SET /A ArgCount=0
SET "CmdletName=New-%BASE_CMDLET_NAME%"
SET "CmdletType=Scripts"

:ProcessArgs
FOR %%A IN (%*) DO (
    SET /A "ArgCount+=1"
    SET /A ProcessedArg=0

    IF !ArgCount! EQU 1 (
        IF /I "%%~A" == "/N" (
            SET "CmdletName=New-%BASE_CMDLET_NAME%"
            SET "CmdletType=Scripts"
            SET /A ProcessedArg=1
        ) ELSE IF /I "%%~A" == "/New" (
            SET "CmdletName=New-%BASE_CMDLET_NAME%"
            SET "CmdletType=Scripts"
            SET /A ProcessedArg=1
        ) ELSE IF /I "%%~A" == "/G" (
            SET "CmdletName=Get-%BASE_CMDLET_NAME%"
            SET "CmdletType=Scripts"
            SET /A ProcessedArg=1
        ) ELSE IF /I "%%~A" == "/Get" (
            SET "CmdletName=Get-%BASE_CMDLET_NAME%"
            SET "CmdletType=Scripts"
            SET /A ProcessedArg=1
        ) ELSE IF /I "%%~A" == "/T" (
            SET "CmdletName=Test-%BASE_CMDLET_NAME%"
            SET "CmdletType=Scripts"
            SET /A ProcessedArg=1
        ) ELSE IF /I "%%~A" == "/Test" (
            SET "CmdletName=Test-%BASE_CMDLET_NAME%"
            SET "CmdletType=Scripts"
            SET /A ProcessedArg=1
        ) ELSE IF /I "%%~A" == "/R" (
            SET "CmdletName=Remove-%BASE_CMDLET_NAME%"
            SET "CmdletType=Scripts"
            SET /A ProcessedArg=1
        ) ELSE IF /I "%%~A" == "/Remove" (
            SET "CmdletName=Remove-%BASE_CMDLET_NAME%"
            SET "CmdletType=Scripts"
            SET /A ProcessedArg=1
        ) ELSE IF /I "%%~A" == "/I" (
            IF EXIST "%~dp0Setup" (
                SET "CmdletName=Install-%BASE_CMDLET_NAME%"
                SET "CmdletType=Setup"
                SET /A ProcessedArg=1
            )
        ) ELSE IF /I "%%~A" == "/Install" (
            IF EXIST "%~dp0Setup" (
                SET "CmdletName=Install-%BASE_CMDLET_NAME%"
                SET "CmdletType=Setup"
                SET /A ProcessedArg=1
            )
        ) ELSE IF /I "%%~A" == "/U" (
            SET "CmdletName=Uninstall-%BASE_CMDLET_NAME%"
            SET /A ProcessedArg=1

            IF EXIST "%~dp0Setup" (
                SET "CmdletType=Setup"
            ) ELSE (
                SET "CmdletType=Installation"
            )
        ) ELSE IF /I "%%~A" == "/Uninstall" (
            SET "CmdletName=Uninstall-%BASE_CMDLET_NAME%"
            SET /A ProcessedArg=1

            IF EXIST "%~dp0Setup" (
                SET "CmdletType=Setup"
            ) ELSE (
                SET "CmdletType=Installation"
            )
        )
    )

    IF !ProcessedArg! EQU 0 (
        IF /I "%%~A" == "/P" (
            SET /A NoPause=1
        ) ELSE IF /I "%%~A" == "/NoPause" (
            SET /A NoPause=1
        ) ELSE (
            SET "Args=!Args! %%A"
        )
    )
)

IF "%~1" == "/?" (
    GOTO :ShowScriptHelp
) ELSE IF "%~2" == "/?" (
    GOTO :ShowCmdletHelp
)

GOTO :CallCmdlet


:CallCmdlet
CALL powershell -ExecutionPolicy Bypass -File "%~dp0!CmdletType!\!CmdletName!.ps1" !Args!
GOTO :EndOfScript


:ShowScriptHelp
ECHO Facilitates the management of Hard Links or Directory Junctions
ECHO for the files and directories on the root of a disk drive.
ECHO.
ECHO Such shortcuts are useful for quickly referring to
ECHO long file paths during testing or debugging. For example,
ECHO a directory junction could be created for the path,
ECHO "X:\my-super-long-project-name\another-really-long-path\src\my-super-cool-module",
ECHO accessible at "X:\$".
ECHO.
ECHO This script is effectively just a shortcut for invoking the
ECHO PowerShell scripts located in the Link2Root/Scripts directory,
ECHO which is particularly useful on systems where the PowerShell Execution Policy
ECHO prohibits the direct invocation of untrusted PowerShell scripts.
ECHO.
ECHO Note that when passing arguments to this script, they will always be
ECHO prefixed with a '/' character, while arguments passed to the actual
ECHO PowerShell Cmdlet being invoked are prefixed with a '-' character or not prefixed at all.
ECHO E.g.,           Link2Root /New MyProject -Drive X
ECHO     Passed to Script ---^> /New 
ECHO                                MyProject -Drive X ^<--- Passed to Cmdlet
ECHO.
ECHO For more information on the behavior of a specific PowerShell Cmdlet,
ECHO specify the cmdlet using the appropriate switch followed by the /? switch.
ECHO E.g., Link2Root /Get /?
ECHO.
ECHO.
ECHO Syntax:

IF EXIST "%~dp0Setup" (
    ECHO Link2Root ^[/N ^| /New ^| /G ^| /Get ^| /T ^| /Test ^| /R ^| /Remove ^| /I ^| /Install ^| /U ^| /Uninstall]
) ELSE (
    ECHO Link2Root ^[/N ^| /New ^| /G ^| /Get ^| /T ^| /Test ^| /R ^| /Remove ^| /U ^| /Uninstall^]
)

ECHO           ^[/?^] ^[/P ^| /NoPause]^ ^[^<CmdletArgs^>^]
ECHO.
ECHO.
ECHO Options:
ECHO.
ECHO ^[/N ^| /New^]         Create a new Hard Link or Directory Junction.
ECHO                     This option is implied by default.
ECHO.
ECHO ^[/G ^| /Get^]         Retrieve the current Root Link on the specified drive.
ECHO.
ECHO ^[/T ^| /Test^]        Test if a Root Link exists on the specified drive or not.
ECHO.
ECHO ^[/R ^| /Remove^]      Remove an existing Root Link.
ECHO.

IF EXIST "%~dp0Setup" (
    ECHO ^[/I ^| /Install^]     Install Link2Root to be used anywhere on the current system.
    ECHO.
)

ECHO ^[/U ^| /Uninstall^]   Uninstall Link2Root so it can only be used portably once again.
ECHO.
ECHO ^[/?^]                Display help information for this script or the designated Cmdlet.
ECHO.
ECHO ^[/P ^| /NoPause]^     Skip pausing the script at the very end.
ECHO.
ECHO ^[^<CmdletArgs^>^]      Any arguments to be passed to the PowerShell Cmdlet being invoked.
ECHO.
ECHO.
ECHO Examples:
ECHO.
ECHO Example 1: Create a new Root Link on the Current Drive to the Current Working Directory:
ECHO X:\Projects\MyProject\Link2Root^> Link2Root
ECHO Creating Root Link: X:\$ ---^> X:\Projects\MyProject... Success^!
ECHO.
ECHO If Link2Root has been installed, Link2Root can be called from any location:
ECHO X:\Projects\MyProject^> Link2Root
ECHO Creating Root Link: X:\$ ---^> X:\Projects\MyProject... Success^!
ECHO.
ECHO.
ECHO Example 2: Create a new Root Link on the Current Drive to the Specified Location:
ECHO X:\Projects\Link2Root^> Link2Root -Path "../MyProject"
ECHO Creating Root Link: X:\$ ---^> X:\Projects\MyProject... Success^!
ECHO.
ECHO If Link2Root has been installed, Link2Root can be called from any location:
ECHO X:\Projects^> Link2Root -Path "MyProject"
ECHO Creating Root Link: X:\$ ---^> X:\Projects\MyProject... Success^!
ECHO.
ECHO.
ECHO Example 3: Retrieve the Current Root Link on the Current Drive:
ECHO X:\Projects\Link2Root^> Link2Root /Get
ECHO X:\Projects\MyProject
ECHO.
ECHO.
ECHO Example 4: Retrieve the Current Root Link on the Specified Drive:
ECHO C:\Link2Root^> Link2Root /Get -Drive X
ECHO X:\Projects\MyProject
ECHO.
ECHO.
ECHO Example 5: Test if a Root Link Exists on the Current Drive:
ECHO X:\Projects\Link2Root^> Link2Root /Test
ECHO True
ECHO.
ECHO.
ECHO Example 6: Test if a Root Link Exists on the Specified Drive:
ECHO C:\Link2Root^> Link2Root /Test -Drive X
ECHO True
ECHO.
ECHO.
ECHO Example 7: Remove the Root Link from the Current Drive:
ECHO X:\Projects\MyProject\Link2Root^> Link2Root /Remove
ECHO Removing Root Link: X:\$ ---^> X:\Projects\MyProject... Success^!
ECHO.
ECHO.
ECHO Example 8: Remove the Root Link from the Specified Drive:
ECHO C:\Link2Root^> Link2Root /Remove -Drive X
ECHO Removing Root Link: X:\$ ---^> X:\Projects\MyProject... Success^!
ECHO.
ECHO.
ECHO Example 9: Get Help Information about the New-Link2Root Cmdlet:
ECHO X:\Projects\MyProject^> Link2Root /New /?
ECHO NAME
ECHO New-Link2Root
ECHO.
ECHO SYNOPSIS
ECHO Create a new shortcut link on the root of the drive.
ECHO.
ECHO ...
ECHO.
ECHO.

IF EXIST "%~dp0Setup" (
    ECHO Example 10: Install Link2Root so it can be used anywhere on the system:
    ECHO C:\Link2Root^> Link2Root /Install
    ECHO.
    ECHO.
    ECHO Example 11: Uninstall Link2Root so it can only be used portably again:
    ECHO C:\Link2Root^> Link2Root /Uninstall
) ELSE (
    ECHO Example 10: Uninstall Link2Root so it can only be used portably again:
    ECHO C:\Link2Root^> Link2Root /Uninstall
)

GOTO :EndOfScript


:ShowCmdletHelp
IF "!CmdletType!" == "Scripts" (
    CALL powershell -Command "& { Import-Module '%~dp0Link2Root.psm1'; Get-Help !CmdletName! -Full; }"
) ELSE (
    CALL powershell -Command "Get-Help" "%~dp0Setup\!CmdletName!.ps1" -Full
)
GOTO :EndOfScript


:EndOfScript
IF NOT DEFINED NoPause (
    PAUSE
)
EndLocal