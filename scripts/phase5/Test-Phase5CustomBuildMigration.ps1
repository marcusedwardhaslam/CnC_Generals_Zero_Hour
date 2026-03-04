param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.." )).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-Xml {
    param([string]$Path)
    [xml]$doc = Get-Content -Path $Path -Raw
    return $doc
}

function Select-Nodes {
    param(
        [xml]$Doc,
        [string]$XPath
    )

    $ns = New-Object System.Xml.XmlNamespaceManager($Doc.NameTable)
    $ns.AddNamespace("msb", "http://schemas.microsoft.com/developer/msbuild/2003")
    return $Doc.SelectNodes($XPath, $ns)
}

$checks = @()
$hasFailure = $false

$rtsProjects = @(
    "Generals/Code/RTS/RTS.vcxproj",
    "GeneralsMD/Code/RTS/RTS.vcxproj"
)

foreach ($relative in $rtsProjects) {
    $full = Join-Path $RepoRoot $relative
    $exists = Test-Path $full
    $hookOk = $false

    if ($exists) {
        $xml = Read-Xml -Path $full
        $nodes = Select-Nodes -Doc $xml -XPath "//msb:PreBuildEvent/msb:Command"
        $text = @($nodes | ForEach-Object { $_.InnerText }) -join "`n"
        $hasVersionToolRef = ($text -match '(rtsver\.exe|versionUpdate\.exe)')
        $hasBuildVersionToolRef = ($text -match '(rtsbuildver\.exe|buildVersionUpdate\.exe)')
        $hookOk = ($hasVersionToolRef -and $hasBuildVersionToolRef)
    }

    if (-not ($exists -and $hookOk)) {
        $hasFailure = $true
    }

    $checks += [PSCustomObject]@{
        Category = "RTSVersionStep"
        Target = $relative
        Status = if ($exists -and $hookOk) { "ok" } else { "missing-hook" }
        Details = if ($exists) { "PreBuild contains rtsver/versionUpdate and rtsbuildver/buildVersionUpdate references" } else { "Project missing" }
    }
}

$gedProjects = @(
    "Generals/Code/GameEngineDevice/GameEngineDevice.vcxproj",
    "GeneralsMD/Code/GameEngineDevice/GameEngineDevice.vcxproj"
)

foreach ($relative in $gedProjects) {
    $full = Join-Path $RepoRoot $relative
    $exists = Test-Path $full
    $hookOk = $false

    if ($exists) {
        $xml = Read-Xml -Path $full
        $customBuildNodes = Select-Nodes -Doc $xml -XPath "//msb:CustomBuild"
        $txt = @($customBuildNodes | ForEach-Object { $_.OuterXml }) -join "`n"
        $hookOk = ($txt -match 'wave\.nvp' -and $txt -match 'wave\.nvv' -and $txt -match 'nvasm\.exe' -and $txt -match 'wave\.pso' -and $txt -match 'wave\.vso')
    }

    if (-not ($exists -and $hookOk)) {
        $hasFailure = $true
    }

    $checks += [PSCustomObject]@{
        Category = "NVASMShaderStep"
        Target = $relative
        Status = if ($exists -and $hookOk) { "ok" } else { "missing-hook" }
        Details = if ($exists) { "CustomBuild contains NVASM wave.nvp/wave.nvv compile steps" } else { "Project missing" }
    }
}

$particleScripts = @(
    "Generals/Code/Tools/ParticleEditor/post-build.bat",
    "GeneralsMD/Code/Tools/ParticleEditor/post-build.bat"
)

foreach ($relative in $particleScripts) {
    $full = Join-Path $RepoRoot $relative
    $exists = Test-Path $full
    if (-not $exists) {
        $hasFailure = $true
    }

    $checks += [PSCustomObject]@{
        Category = "ToolPostBuild"
        Target = $relative
        Status = if ($exists) { "ok" } else { "missing-script" }
        Details = "Legacy ParticleEditor post-build script presence"
    }
}

$externalChecks = @(
    @{
        Category = "ExternalTool"
        Label = "Generals/Run version updater"
        Candidates = @("Generals/Run/rtsver.exe", "Generals/Run/versionUpdate.exe")
    },
    @{
        Category = "ExternalTool"
        Label = "Generals/Run build-version updater"
        Candidates = @("Generals/Run/rtsbuildver.exe", "Generals/Run/buildVersionUpdate.exe")
    },
    @{
        Category = "ExternalTool"
        Label = "GeneralsMD/Run version updater"
        Candidates = @("GeneralsMD/Run/rtsver.exe", "GeneralsMD/Run/versionUpdate.exe")
    },
    @{
        Category = "ExternalTool"
        Label = "GeneralsMD/Run build-version updater"
        Candidates = @("GeneralsMD/Run/rtsbuildver.exe", "GeneralsMD/Run/buildVersionUpdate.exe")
    },
    @{
        Category = "ExternalTool"
        Label = "Generals NVASM"
        Candidates = @("Generals/Code/Tools/NVASM/nvasm.exe")
    },
    @{
        Category = "ExternalTool"
        Label = "GeneralsMD NVASM"
        Candidates = @("GeneralsMD/Code/Tools/NVASM/nvasm.exe")
    }
)

foreach ($check in $externalChecks) {
    $resolved = $null
    foreach ($candidate in $check.Candidates) {
        $full = Join-Path $RepoRoot $candidate
        if (Test-Path $full) {
            $resolved = $candidate
            break
        }
    }

    if ($null -eq $resolved) {
        $hasFailure = $true
    }

    $checks += [PSCustomObject]@{
        Category = [string]$check.Category
        Target = [string]$check.Label
        Status = if ($null -ne $resolved) { "ok" } else { "missing-exe" }
        Details = if ($null -ne $resolved) { "Resolved by $resolved" } else { "Missing all candidates: $($check.Candidates -join ', ')" }
    }
}

$checks | Format-Table -AutoSize

if ($hasFailure) {
    throw "Phase 5 validation found missing custom build hooks and/or missing external executables."
}

Write-Host "Phase 5 validation passed."