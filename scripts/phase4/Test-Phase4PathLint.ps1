param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.." )).Path,
    [string]$ConfigPath = (Join-Path $PSScriptRoot "dependency-paths.json"),
    [string]$ReportPath = (Join-Path $PSScriptRoot "out\phase4-path-lint-report.json")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $ConfigPath)) {
    throw "Path-lint config not found: $ConfigPath"
}

$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$trees = @("Generals", "GeneralsMD")
$results = @()

foreach ($tree in $trees) {
    $codeRoot = Join-Path $RepoRoot "$tree\Code"
    if (-not (Test-Path $codeRoot)) {
        $results += [PSCustomObject]@{
            Tree = $tree
            Dependency = "<code-root>"
            EnvVar = ""
            ExpectedPath = $codeRoot
            AlternatePath = ""
            Status = "missing-tree"
            Resolution = "Create or restore $tree/Code in repository"
        }
        continue
    }

    foreach ($dependency in $config.dependencies) {
        $envVarName = [string]$dependency.envVar
        $envValue = [Environment]::GetEnvironmentVariable($envVarName, "Process")
        if ([string]::IsNullOrWhiteSpace($envValue)) {
            $envValue = [Environment]::GetEnvironmentVariable($envVarName, "User")
        }
        if ([string]::IsNullOrWhiteSpace($envValue)) {
            $envValue = [Environment]::GetEnvironmentVariable($envVarName, "Machine")
        }

        $expectedPath = Join-Path $codeRoot ([string]$dependency.relativeExpected)
        $alternateHits = @()
        foreach ($alternate in $dependency.alternates) {
            $alternatePath = Join-Path $codeRoot ([string]$alternate)
            if (Test-Path $alternatePath) {
                $alternateHits += $alternatePath
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($envValue)) {
            $envExists = Test-Path $envValue
            $results += [PSCustomObject]@{
                Tree = $tree
                Dependency = [string]$dependency.label
                EnvVar = $envVarName
                ExpectedPath = $expectedPath
                AlternatePath = if ($alternateHits.Count -gt 0) { $alternateHits[0] } else { "" }
                Status = if ($envExists) { "ok-env" } else { "missing-env-target" }
                Resolution = if ($envExists) { "Resolved via environment variable" } else { "Set $envVarName to an existing path" }
            }
            continue
        }

        if (Test-Path $expectedPath) {
            $results += [PSCustomObject]@{
                Tree = $tree
                Dependency = [string]$dependency.label
                EnvVar = $envVarName
                ExpectedPath = $expectedPath
                AlternatePath = ""
                Status = "ok-repo"
                Resolution = "Resolved via repository relative path"
            }
            continue
        }

        if ($alternateHits.Count -gt 0) {
            $results += [PSCustomObject]@{
                Tree = $tree
                Dependency = [string]$dependency.label
                EnvVar = $envVarName
                ExpectedPath = $expectedPath
                AlternatePath = $alternateHits[0]
                Status = "mismatch"
                Resolution = "Path exists in alternate location; set $envVarName or normalize layout"
            }
            continue
        }

        $results += [PSCustomObject]@{
            Tree = $tree
            Dependency = [string]$dependency.label
            EnvVar = $envVarName
            ExpectedPath = $expectedPath
            AlternatePath = ""
            Status = "missing"
            Resolution = "Provide dependency at expected path or set $envVarName"
        }
    }
}

$outDir = Split-Path -Parent $ReportPath
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$results | ConvertTo-Json -Depth 6 | Set-Content -Path $ReportPath -Encoding UTF8

$results |
    Select-Object Tree, Dependency, Status, EnvVar, ExpectedPath, AlternatePath |
    Format-Table -AutoSize

$failureStatuses = @("missing", "missing-env-target", "missing-tree")
$failedItems = @($results | Where-Object { $failureStatuses -contains $_.Status })
$hasFailure = ($failedItems.Count -gt 0)

if ($hasFailure) {
    throw "Phase 4 path-lint found unresolved mandatory dependency paths. See report: $ReportPath"
}

Write-Host "Phase 4 path-lint passed. Report: $ReportPath"