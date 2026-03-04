param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.." )).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-SolutionProjects {
    param([string]$SlnPath)

    $projects = @()
    foreach ($line in Get-Content -Path $SlnPath) {
        if ($line -match '^Project\("\{[^\}]+\}"\)\s*=\s*"([^"]+)",\s*"([^"]+)",') {
            $projects += [PSCustomObject]@{
                Name = $Matches[1]
                RelativePath = $Matches[2].Replace('\\', '\')
            }
        }
    }
    return $projects
}

function Get-SolutionConfigurations {
    param([string]$SlnPath)

    $configs = @()
    $inSection = $false
    foreach ($line in Get-Content -Path $SlnPath) {
        if ($line -match '^\s*GlobalSection\(SolutionConfigurationPlatforms\)\s*=\s*preSolution\s*$') {
            $inSection = $true
            continue
        }

        if ($inSection -and $line -match '^\s*EndGlobalSection\s*$') {
            break
        }

        if ($inSection -and $line -match '^\s*([^=\s]+)\s*=') {
            $configs += $Matches[1]
        }
    }

    return ($configs | Sort-Object -Unique)
}

$solutions = @(
    "Generals\Code\RTS.sln",
    "GeneralsMD\Code\RTS.sln"
)

$expectedConfigs = @("Debug|Win32", "Release|Win32")
$summary = @()
$hasFailure = $false

Push-Location $RepoRoot
try {
    foreach ($solution in $solutions) {
        $solutionExists = Test-Path $solution
        $projectCount = 0
        $missingProjects = 0
        $configs = @()
        $configOnlyWin32 = $false

        if ($solutionExists) {
            $projects = Get-SolutionProjects -SlnPath $solution
            $projectCount = $projects.Count
            foreach ($project in $projects) {
                $projectPath = Join-Path (Split-Path $solution -Parent) $project.RelativePath
                if (-not (Test-Path $projectPath)) {
                    $missingProjects++
                }
            }

            $configs = Get-SolutionConfigurations -SlnPath $solution
            $configOnlyWin32 = (@(Compare-Object -ReferenceObject $expectedConfigs -DifferenceObject $configs).Count -eq 0)
        }

        if (-not $solutionExists -or $missingProjects -gt 0 -or -not $configOnlyWin32) {
            $hasFailure = $true
        }

        $summary += [PSCustomObject]@{
            Solution = $solution
            Exists = $solutionExists
            ProjectCount = $projectCount
            MissingProjects = $missingProjects
            Configurations = ($configs -join ", ")
            ConfigsRestrictedToWin32 = $configOnlyWin32
        }
    }
}
finally {
    Pop-Location
}

$summary | Format-Table -AutoSize

if ($hasFailure) {
    throw "Phase 2 validation failed. Review summary table and conversion logs."
}

Write-Host "Phase 2 validation passed."