param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.." )).Path,
    [string]$Vs2003Devenv = "",
    [string]$VsModernDevenv = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.com",
    [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-DevenvPath {
    param(
        [string]$Preferred,
        [string[]]$FallbackCandidates,
        [string]$DisplayName
    )

    if (-not [string]::IsNullOrWhiteSpace($Preferred)) {
        if (Test-Path $Preferred) {
            return (Resolve-Path $Preferred).Path
        }
        throw "$DisplayName path not found: $Preferred"
    }

    foreach ($candidate in $FallbackCandidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    return ""
}

function Restrict-SolutionConfigurations {
    param(
        [string]$SlnPath
    )

    $lines = Get-Content -Path $SlnPath
    $updated = New-Object System.Collections.Generic.List[string]
    $inSolutionConfigs = $false
    $inProjectConfigs = $false

    foreach ($line in $lines) {
        if ($line -match '^\s*GlobalSection\(SolutionConfigurationPlatforms\)\s*=\s*preSolution\s*$') {
            $inSolutionConfigs = $true
            $updated.Add($line)
            continue
        }

        if ($line -match '^\s*GlobalSection\(ProjectConfigurationPlatforms\)\s*=\s*postSolution\s*$') {
            $inProjectConfigs = $true
            $updated.Add($line)
            continue
        }

        if ($line -match '^\s*EndGlobalSection\s*$') {
            $inSolutionConfigs = $false
            $inProjectConfigs = $false
            $updated.Add($line)
            continue
        }

        if ($inSolutionConfigs) {
            if ($line -match 'Debug\|Win32|Release\|Win32') {
                $updated.Add($line)
            }
            continue
        }

        if ($inProjectConfigs) {
            if ($line -match 'Debug\|Win32|Release\|Win32') {
                $updated.Add($line)
            }
            continue
        }

        $updated.Add($line)
    }

    Set-Content -Path $SlnPath -Value $updated -Encoding UTF8
}

$vs2003Candidates = @(
    "C:\Program Files (x86)\Microsoft Visual Studio .NET 2003\Common7\IDE\devenv.com",
    "C:\Program Files\Microsoft Visual Studio .NET 2003\Common7\IDE\devenv.com"
)

$vsModernCandidates = @(
    $VsModernDevenv,
    "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.com",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.com",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.com"
)

$resolvedVs2003 = Resolve-DevenvPath -Preferred $Vs2003Devenv -FallbackCandidates $vs2003Candidates -DisplayName "VS2003 devenv"
$resolvedVsModern = Resolve-DevenvPath -Preferred $VsModernDevenv -FallbackCandidates $vsModernCandidates -DisplayName "Modern VS devenv"

$missingVs2003 = [string]::IsNullOrWhiteSpace($resolvedVs2003)
$missingVsModern = [string]::IsNullOrWhiteSpace($resolvedVsModern)

$workspaces = @(
    "Generals\Code\RTS.dsw",
    "GeneralsMD\Code\RTS.dsw"
)

Write-Host "RepoRoot: $RepoRoot"
Write-Host "VS2003:  $resolvedVs2003"
Write-Host "VSModern: $resolvedVsModern"

if ($CheckOnly) {
    if ($missingVs2003) {
        Write-Warning "VS2003 devenv not found. Install VS .NET 2003, then rerun with -Vs2003Devenv <path>."
    }

    if ($missingVsModern) {
        Write-Warning "Modern Visual Studio devenv.com not found. Install VS 2015+ and rerun with -VsModernDevenv <path>."
    }

    Write-Host "Check-only mode complete."
    exit 0
}

if ($missingVs2003) {
    throw "VS2003 devenv not found. Install VS .NET 2003, then rerun with -Vs2003Devenv <path>."
}

if ($missingVsModern) {
    throw "Modern Visual Studio devenv.com not found. Install VS 2015+ and rerun with -VsModernDevenv <path>."
}

Push-Location $RepoRoot
try {
    foreach ($workspace in $workspaces) {
        Write-Host "[Phase2] Converting via VS2003: $workspace"
        & $resolvedVs2003 $workspace /Upgrade
        if ($LASTEXITCODE -ne 0) {
            throw "VS2003 conversion failed for $workspace (exit code $LASTEXITCODE)."
        }

        $slnPath = [System.IO.Path]::ChangeExtension($workspace, ".sln")
        if (-not (Test-Path $slnPath)) {
            throw "Expected solution not generated: $slnPath"
        }

        Write-Host "[Phase2] Upgrading in modern VS: $slnPath"
        & $resolvedVsModern $slnPath /Upgrade
        if ($LASTEXITCODE -ne 0) {
            throw "Modern VS upgrade failed for $slnPath (exit code $LASTEXITCODE)."
        }

        Write-Host "[Phase2] Restricting solution configurations to Debug|Win32 and Release|Win32: $slnPath"
        Restrict-SolutionConfigurations -SlnPath $slnPath
    }
}
finally {
    Pop-Location
}

Write-Host "Phase 2 conversion sequence completed. Run scripts/phase2/Test-Phase2Conversion.ps1 next."