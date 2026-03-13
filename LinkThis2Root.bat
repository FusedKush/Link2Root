@ECHO off
@REM Link2Root must be installed in "C:\Users\YOUR_USERNAME\AppData\Local\PowerShell Link2Root"
@REM for this script to work properly.

SET "InstallPath=%LOCALAPPDATA%\PowerShell Link2Root"
SET "ScriptPath=%InstallPath%\Link2Root.bat"

IF NOT EXIST "%ScriptPath%" (
    ECHO ERROR: Link2Root is not properly installed.
    ECHO.
    ECHO In order to use this script, you must run the Install-Link2Root installer
    ECHO located in the Link2Root/Installation folder.
    PAUSE
    GOTO :EndOfScript
)

CALL "%ScriptPath%" %*

:EndOfScript