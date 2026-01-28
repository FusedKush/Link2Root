@echo off
pushd
cd \Link2Root
call powershell -ExecutionPolicy Bypass -File "New-Link2Root.ps1" %*
popd
pause