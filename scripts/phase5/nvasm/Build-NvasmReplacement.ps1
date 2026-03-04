param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\.." )).Path,
    [switch]$UseGcc
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$src = Join-Path $PSScriptRoot "nvasm-new.c"
$outDir = Join-Path $PSScriptRoot "out"
$exe = Join-Path $outDir "nvasm.exe"

if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

if ($UseGcc) {
    $gcc = Get-Command gcc -ErrorAction SilentlyContinue
    if ($null -eq $gcc) {
        throw "gcc not found on PATH."
    }
    & $gcc.Source "-O2" "-o" $exe $src
} else {
    $cl = Get-Command cl -ErrorAction SilentlyContinue
    if ($null -eq $cl) {
        throw "cl.exe not found on PATH. Launch from a Visual Studio Developer Command Prompt or use -UseGcc."
    }
    Push-Location $outDir
    try {
        & $cl.Source "/nologo" "/O2" "/W3" "/Fe:nvasm.exe" $src
    }
    finally {
        Pop-Location
    }
}

if (-not (Test-Path $exe)) {
    throw "Build did not produce nvasm.exe at $exe"
}

$targets = @(
    (Join-Path $RepoRoot "Generals\Code\Tools\NVASM\nvasm.exe"),
    (Join-Path $RepoRoot "GeneralsMD\Code\Tools\NVASM\nvasm.exe")
)

foreach ($target in $targets) {
    $targetDir = Split-Path -Parent $target
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    Copy-Item -Path $exe -Destination $target -Force
    Write-Host "Installed: $target"
}

Write-Host "NVASM replacement build/install complete."