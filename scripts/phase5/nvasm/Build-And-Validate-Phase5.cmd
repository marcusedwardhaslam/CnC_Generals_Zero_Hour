@echo off
setlocal

set "VCVARS=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"

if not exist "%VCVARS%" (
  echo ERROR: vcvarsall.bat not found at "%VCVARS%"
  exit /b 1
)

call "%VCVARS%" x86
if errorlevel 1 (
  echo ERROR: failed to initialize MSVC environment.
  exit /b 1
)

where cl >nul 2>nul
if errorlevel 1 (
  echo ERROR: cl.exe still not available after vcvarsall.
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-NvasmReplacement.ps1"
if errorlevel 1 exit /b 1

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Test-Phase5CustomBuildMigration.ps1"
if errorlevel 1 exit /b 1

echo Phase 5 build+validation completed.
exit /b 0