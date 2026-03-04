@echo off
setlocal

set "VSROOT=C:\Program Files\Microsoft Visual Studio\2022"
set "VCVARS="

if exist "%VSROOT%\Community\VC\Auxiliary\Build\vcvarsall.bat" set "VCVARS=%VSROOT%\Community\VC\Auxiliary\Build\vcvarsall.bat"
if not defined VCVARS if exist "%VSROOT%\Professional\VC\Auxiliary\Build\vcvarsall.bat" set "VCVARS=%VSROOT%\Professional\VC\Auxiliary\Build\vcvarsall.bat"
if not defined VCVARS if exist "%VSROOT%\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" set "VCVARS=%VSROOT%\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
if not defined VCVARS if exist "%VSROOT%\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" set "VCVARS=%VSROOT%\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"

if not defined VCVARS (
  echo ERROR: Could not locate vcvarsall.bat under "%VSROOT%".
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-VersionTools.ps1"
if errorlevel 1 exit /b 1

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Test-Phase5CustomBuildMigration.ps1"
if errorlevel 1 exit /b 1

echo Phase 5 version-tool build+validation completed.
exit /b 0
