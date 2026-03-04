param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\.." )).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$cl = Get-Command cl -ErrorAction SilentlyContinue
if ($null -eq $cl) {
    throw "cl.exe not found on PATH. Run from a Visual Studio Developer Command Prompt or use Build-And-Validate-Phase5VersionTools.cmd."
}

$trees = @(
    @{
        Name = "Generals"
        VersionSrc = "Generals\Code\Tools\versionUpdate\versionUpdate.cpp"
        BuildSrc = "Generals\Code\Tools\buildVersionUpdate\buildVersionUpdate.cpp"
        RunDir = "Generals\Run"
    },
    @{
        Name = "GeneralsMD"
        VersionSrc = "GeneralsMD\Code\Tools\versionUpdate\versionUpdate.cpp"
        BuildSrc = "GeneralsMD\Code\Tools\buildVersionUpdate\buildVersionUpdate.cpp"
        RunDir = "GeneralsMD\Run"
    }
)

$outRoot = Join-Path $PSScriptRoot "out"
if (-not (Test-Path $outRoot)) {
    New-Item -ItemType Directory -Path $outRoot -Force | Out-Null
}

foreach ($tree in $trees) {
    $name = [string]$tree.Name
    $versionSrc = Join-Path $RepoRoot ([string]$tree.VersionSrc)
    $buildSrc = Join-Path $RepoRoot ([string]$tree.BuildSrc)
    $runDir = Join-Path $RepoRoot ([string]$tree.RunDir)
    $outDir = Join-Path $outRoot $name

    if (-not (Test-Path $versionSrc)) {
        throw "Missing source: $versionSrc"
    }
    if (-not (Test-Path $buildSrc)) {
        throw "Missing source: $buildSrc"
    }

    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
    if (-not (Test-Path $runDir)) {
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
    }

    Push-Location $outDir
    try {
        & $cl.Source "/nologo" "/O2" "/W3" "/DWIN32" "/D_WINDOWS" "/Fe:rtsver.exe" $versionSrc "/link" "/SUBSYSTEM:WINDOWS" "Advapi32.lib"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to compile rtsver.exe for $name"
        }

        & $cl.Source "/nologo" "/O2" "/W3" "/DWIN32" "/D_WINDOWS" "/Fe:rtsbuildver.exe" $buildSrc "/link" "/SUBSYSTEM:WINDOWS"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to compile rtsbuildver.exe for $name"
        }
    }
    finally {
        Pop-Location
    }

    $rtsVerBuilt = Join-Path $outDir "rtsver.exe"
    $rtsBuildVerBuilt = Join-Path $outDir "rtsbuildver.exe"

    if (-not (Test-Path $rtsVerBuilt)) {
        throw "Build did not produce $rtsVerBuilt"
    }
    if (-not (Test-Path $rtsBuildVerBuilt)) {
        throw "Build did not produce $rtsBuildVerBuilt"
    }

    Copy-Item -Path $rtsVerBuilt -Destination (Join-Path $runDir "rtsver.exe") -Force
    Copy-Item -Path $rtsBuildVerBuilt -Destination (Join-Path $runDir "rtsbuildver.exe") -Force

    Write-Host "Installed for ${name}:"
    Write-Host "  $(Join-Path $runDir "rtsver.exe")"
    Write-Host "  $(Join-Path $runDir "rtsbuildver.exe")"
}

Write-Host "Version tool build/install complete."
