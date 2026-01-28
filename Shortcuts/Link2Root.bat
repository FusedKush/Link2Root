@echo off
pushd
cd ../
call powershell -ExecutionPolicy Bypass -File "New-Link2Root.ps1" %*
popd
pause