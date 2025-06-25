@echo off

pushd %~dp0
powershell.exe -command New-Item -Path "C:\SIE\Authorized\Applications\Temp" -ItemType Directory -Force -Verbose
powershell.exe -command Expand-Archive -Path "%~dp0SAMS-C2-v*.zip" -DestinationPath "C:\SIE\Authorized\Applications\Temp" -Force -Verbose
cd "C:\SIE\Authorized\Applications\Temp" && cd SAMS*
powershell.exe -command "& {Get-ChildItem -Path . -Recurse | Unblock-File -Verbose}" -executionpolicy bypass

powershell.exe -file "Apply_Monthly_Updates.ps1" -executionpolicy bypass -windowstyle hidden
popd && powershell.exe -command Remove-Item -Path "C:\SIE\Authorized\Applications\Temp\SAMS*" -Recurse -Force -Verbose