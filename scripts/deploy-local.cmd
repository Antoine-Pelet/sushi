@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0deploy-local.ps1" %*
endlocal
