param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [string[]]$ProjectFilter = @("GameEngine", "GameEngineDevice", "RTS")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Normalize-Slash {
    param([string]$Value)
    return ($Value -replace '/', '\\')
}

function Parse-ArgsFromLine {
    param([string]$Line)

    $args = @()
    $matches = [regex]::Matches($Line, '"[^"]+"|\S+')
    foreach ($m in $matches) {
        $token = $m.Value.Trim()
        if ($token.StartsWith('"') -and $token.EndsWith('"')) {
            $token = $token.Substring(1, $token.Length - 2)
        }
        $args += $token
    }
    return $args
}

function Parse-DspMetadata {
    param([string]$DspPath)

    $lines = Get-Content -Path $DspPath
    $projectName = [System.IO.Path]::GetFileNameWithoutExtension($DspPath)
    $targetType = "Application"
    $configs = @{}
    $sources = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($line in $lines) {
        if ($line -match '^# Microsoft Developer Studio Project File - Name="([^"]+)"') {
            $projectName = $Matches[1]
        }

        if ($line -match '^# TARGTYPE "Win32 \(x86\) Static Library"') {
            $targetType = "StaticLibrary"
        }

        if ($line -match '^SOURCE=(.+)$') {
            $raw = $Matches[1].Trim()
            if ($raw.StartsWith('"') -and $raw.EndsWith('"')) {
                $raw = $raw.Substring(1, $raw.Length - 2)
            }
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                [void]$sources.Add((Normalize-Slash $raw))
            }
        }
    }

    $currentCfg = ""
    foreach ($line in $lines) {
        if ($line -match '^!IF\s+"\$\(CFG\)"\s*==\s*"([^"]+)"' -or $line -match '^!ELSEIF\s+"\$\(CFG\)"\s*==\s*"([^"]+)"') {
            $currentCfg = $Matches[1]
            if (-not $configs.ContainsKey($currentCfg)) {
                $configs[$currentCfg] = [ordered]@{
                    Name = $currentCfg
                    OutputDir = ""
                    IntermediateDir = ""
                    AddCppLine = ""
                    AddLinkLine = ""
                    AddLibLine = ""
                }
            }
            continue
        }

        if ($line -match '^!ENDIF') {
            $currentCfg = ""
            continue
        }

        if ([string]::IsNullOrWhiteSpace($currentCfg)) {
            continue
        }

        if ($line -match '^# PROP Output_Dir "([^"]+)"') {
            $configs[$currentCfg].OutputDir = Normalize-Slash $Matches[1]
            continue
        }

        if ($line -match '^# PROP Intermediate_Dir "([^"]+)"') {
            $configs[$currentCfg].IntermediateDir = Normalize-Slash $Matches[1]
            continue
        }

        if ($line -match '^# ADD CPP\s+(.+)$') {
            $configs[$currentCfg].AddCppLine = $Matches[1]
            continue
        }

        if ($line -match '^# ADD LINK32\s+(.+)$') {
            $configs[$currentCfg].AddLinkLine = $Matches[1]
            continue
        }

        if ($line -match '^# ADD LIB32\s+(.+)$') {
            $configs[$currentCfg].AddLibLine = $Matches[1]
            continue
        }
    }

    $resultConfigs = @{}
    foreach ($cfgName in $configs.Keys) {
        if ($cfgName -notmatch ' - Win32 (Debug|Release)$') {
            continue
        }

        $shortCfg = if ($cfgName -like '*Win32 Debug') { 'Debug' } else { 'Release' }
        $cfg = $configs[$cfgName]

        $includeDirs = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
        $defines = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
        $libPaths = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
        $libs = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
        $runtime = if ($cfg.AddCppLine -match '/MDd') { 'MultiThreadedDebugDLL' } else { 'MultiThreadedDLL' }

        foreach ($token in (Parse-ArgsFromLine -Line $cfg.AddCppLine)) {
            if ($token -eq '/I') { continue }
        }

        $incMatches = [regex]::Matches($cfg.AddCppLine, '/I\s*"([^"]+)"|/I\s*([^\s"]+)')
        foreach ($m in $incMatches) {
            $value = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                [void]$includeDirs.Add((Normalize-Slash $value))
            }
        }

        $defMatches = [regex]::Matches($cfg.AddCppLine, '/D\s*"([^"]+)"|/D\s*([^\s"]+)')
        foreach ($m in $defMatches) {
            $value = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                [void]$defines.Add($value)
            }
        }

        $linkLine = if ([string]::IsNullOrWhiteSpace($cfg.AddLinkLine)) { $cfg.AddLibLine } else { $cfg.AddLinkLine }
        $libPathMatches = [regex]::Matches($linkLine, '/libpath:\s*"([^"]+)"|/libpath:\s*([^\s"]+)')
        foreach ($m in $libPathMatches) {
            $value = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                [void]$libPaths.Add((Normalize-Slash $value))
            }
        }

        foreach ($token in (Parse-ArgsFromLine -Line $linkLine)) {
            if ($token -like '*.lib') {
                [void]$libs.Add($token)
            }
        }

        $outFile = ""
        if ($targetType -eq 'StaticLibrary') {
            $outMatch = [regex]::Match($cfg.AddLibLine, '/out:\s*"([^"]+)"|/out:\s*([^\s"]+)')
            if ($outMatch.Success) {
                $rawOut = if ($outMatch.Groups[1].Success) { $outMatch.Groups[1].Value } else { $outMatch.Groups[2].Value }
                $outFile = Normalize-Slash $rawOut
            }
        }
        else {
            $outMatch = [regex]::Match($cfg.AddLinkLine, '/out:\s*"([^"]+)"|/out:\s*([^\s"]+)')
            if ($outMatch.Success) {
                $rawOut = if ($outMatch.Groups[1].Success) { $outMatch.Groups[1].Value } else { $outMatch.Groups[2].Value }
                $outFile = Normalize-Slash $rawOut
            }
        }

        $resultConfigs[$shortCfg] = [ordered]@{
            OutputDir = $cfg.OutputDir
            IntermediateDir = $cfg.IntermediateDir
            RuntimeLibrary = $runtime
            IncludeDirs = @($includeDirs)
            Defines = @($defines)
            LibPaths = @($libPaths)
            Libraries = @($libs)
            OutputFile = $outFile
        }
    }

    return [ordered]@{
        Name = $projectName
        DspPath = $DspPath
        TargetType = $targetType
        Configurations = $resultConfigs
        SourceFiles = @($sources)
    }
}

$workspacePathResolved = (Resolve-Path $WorkspacePath).Path
$workspaceDir = Split-Path -Parent $workspacePathResolved
$workspaceLines = Get-Content -Path $workspacePathResolved

$projects = [ordered]@{}
$currentProject = ""

foreach ($line in $workspaceLines) {
    if ($line -match '^Project:\s+"([^"]+)"=(.+?)-\s+Package Owner=<\d+>') {
        $name = $Matches[1]
        $relativeDsp = $Matches[2].Trim()
        $relativeDsp = $relativeDsp.Trim()
        $relativeDsp = Normalize-Slash $relativeDsp
        if ($relativeDsp.StartsWith('.\')) {
            $relativeDsp = $relativeDsp.Substring(2)
        }

        $fullDsp = Join-Path $workspaceDir $relativeDsp
        if (Test-Path $fullDsp) {
            $projects[$name] = [ordered]@{
                Name = $name
                RelativeDsp = $relativeDsp
                FullDsp = (Resolve-Path $fullDsp).Path
                Dependencies = @()
            }
            $currentProject = $name
        }
        else {
            $currentProject = ""
        }
        continue
    }

    if (-not [string]::IsNullOrWhiteSpace($currentProject) -and $line -match '^\s*Project_Dep_Name\s+(.+)$') {
        $dep = $Matches[1].Trim()
        $projects[$currentProject].Dependencies += $dep
    }
}

$filteredProjects = @{}
foreach ($projectName in $ProjectFilter) {
    if ($projects.Contains($projectName)) {
        $p = $projects[$projectName]
        $meta = Parse-DspMetadata -DspPath $p.FullDsp
        $filteredProjects[$projectName] = [ordered]@{
            Name = $projectName
            RelativeDsp = $p.RelativeDsp
            Dependencies = @($p.Dependencies)
            TargetType = $meta.TargetType
            Configurations = $meta.Configurations
            SourceFiles = $meta.SourceFiles
        }
    }
}

$manifest = [ordered]@{
    WorkspacePath = $workspacePathResolved
    WorkspaceDir = $workspaceDir
    ProjectFilter = $ProjectFilter
    Projects = $filteredProjects
}

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$manifest | ConvertTo-Json -Depth 12 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Manifest generated: $OutputPath"