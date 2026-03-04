param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.." )).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Text {
    param([System.Xml.XmlNode]$Node)
    if ($null -eq $Node) { return "" }
    return $Node.InnerText
}

$projectPaths = @(
    "Generals/Code/GameEngine/GameEngine.vcxproj",
    "Generals/Code/GameEngineDevice/GameEngineDevice.vcxproj",
    "Generals/Code/RTS/RTS.vcxproj",
    "GeneralsMD/Code/GameEngine/GameEngine.vcxproj",
    "GeneralsMD/Code/GameEngineDevice/GameEngineDevice.vcxproj",
    "GeneralsMD/Code/RTS/RTS.vcxproj"
)

$forbiddenFlags = @('/G6', '/GX', '/Gm', '/GZ', '/YX')
$summary = @()
$hasFailure = $false

foreach ($relativePath in $projectPaths) {
    $fullPath = Join-Path $RepoRoot $relativePath
    if (-not (Test-Path $fullPath)) {
        $hasFailure = $true
        $summary += [PSCustomObject]@{
            Project = $relativePath
            Exists = $false
            ForbiddenFlagsFound = "n/a"
            ConfigsOk = $false
            PchDebug = "missing"
            PchRelease = "missing"
            RuntimeDebug = "missing"
            RuntimeRelease = "missing"
        }
        continue
    }

    [xml]$xml = Get-Content -Path $fullPath -Raw
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace("msb", "http://schemas.microsoft.com/developer/msbuild/2003")

    $rawText = Get-Content -Path $fullPath -Raw
    $foundFlags = @()
    foreach ($flag in $forbiddenFlags) {
        if ($rawText -match [regex]::Escape($flag)) {
            $foundFlags += $flag
        }
    }

    $configNodes = $xml.SelectNodes('//msb:ProjectConfiguration', $ns)
    $configSet = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($cfg in $configNodes) {
        [void]$configSet.Add($cfg.GetAttribute('Include'))
    }

    $configsOk = ($configSet.Count -eq 2 -and $configSet.Contains('Debug|Win32') -and $configSet.Contains('Release|Win32'))

    $debugCondition = "'`$(Configuration)|`$(Platform)'=='Debug|Win32'"
    $releaseCondition = "'`$(Configuration)|`$(Platform)'=='Release|Win32'"

    $xpathDebugPch = "//msb:ItemDefinitionGroup[@Condition=`"$debugCondition`"]/msb:ClCompile/msb:PrecompiledHeader"
    $xpathReleasePch = "//msb:ItemDefinitionGroup[@Condition=`"$releaseCondition`"]/msb:ClCompile/msb:PrecompiledHeader"
    $xpathDebugRt = "//msb:ItemDefinitionGroup[@Condition=`"$debugCondition`"]/msb:ClCompile/msb:RuntimeLibrary"
    $xpathReleaseRt = "//msb:ItemDefinitionGroup[@Condition=`"$releaseCondition`"]/msb:ClCompile/msb:RuntimeLibrary"

    $pchDebug = Get-Text ($xml.SelectSingleNode($xpathDebugPch, $ns))
    $pchRelease = Get-Text ($xml.SelectSingleNode($xpathReleasePch, $ns))
    $runtimeDebug = Get-Text ($xml.SelectSingleNode($xpathDebugRt, $ns))
    $runtimeRelease = Get-Text ($xml.SelectSingleNode($xpathReleaseRt, $ns))

    $pchOk = ($pchDebug -eq 'NotUsing' -and $pchRelease -eq 'NotUsing')
    $runtimeOk = ($runtimeDebug -eq 'MultiThreadedDebugDLL' -and $runtimeRelease -eq 'MultiThreadedDLL')
    $forbiddenOk = ($foundFlags.Count -eq 0)

    if (-not ($configsOk -and $pchOk -and $runtimeOk -and $forbiddenOk)) {
        $hasFailure = $true
    }

    $summary += [PSCustomObject]@{
        Project = $relativePath
        Exists = $true
        ForbiddenFlagsFound = if ($foundFlags.Count -eq 0) { "" } else { ($foundFlags -join ', ') }
        ConfigsOk = $configsOk
        PchDebug = $pchDebug
        PchRelease = $pchRelease
        RuntimeDebug = $runtimeDebug
        RuntimeRelease = $runtimeRelease
    }
}

$summary | Format-Table -AutoSize

if ($hasFailure) {
    throw "Phase 3 normalization validation failed. Review the table output for mismatches."
}

Write-Host "Phase 3 normalization validation passed."