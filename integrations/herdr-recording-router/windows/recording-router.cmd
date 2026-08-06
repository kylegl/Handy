@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0recording-router.ps1" "%~1"
exit /b %ERRORLEVEL%
