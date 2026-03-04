param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.." )).Path,
    [switch]$SkipValidation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-DeterministicGuid {
    param([string]$Input)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Input)
        $hash = $md5.ComputeHash($bytes)
        return [guid]::New($hash)
    }
    finally {
        $md5.Dispose()
    }
}

function Escape-Xml {
    param([string]$Value)
    return [System.Security.SecurityElement]::Escape($Value)
}

function ConvertTo-Hashtable {
    param([Parameter(ValueFromPipeline = $true)]$InputObject)

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $hash = @{}
        foreach ($key in $InputObject.Keys) {
            $hash[$key] = ConvertTo-Hashtable $InputObject[$key]
        }
        return $hash
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        $arr = @()
        foreach ($item in $InputObject) {
            $arr += ,(ConvertTo-Hashtable $item)
        }
        return $arr
    }

    if ($InputObject -is [psobject]) {
        $hash = @{}
        $hasAnyProperty = $false
        foreach ($prop in $InputObject.PSObject.Properties) {
            $hasAnyProperty = $true
            $hash[$prop.Name] = ConvertTo-Hashtable $prop.Value
        }
        if ($hasAnyProperty) {
            return $hash
        }
    }

    return $InputObject
}

function Write-Vcxproj {
    param(
        [string]$ProjectPath,
        [hashtable]$Project,
        [guid]$ProjectGuid,
        [hashtable]$ProjectGuidByName
    )

    $projectDir = Split-Path -Parent $ProjectPath
    $configDebug = $Project.Configurations.Debug
    $configRelease = $Project.Configurations.Release

    if ($null -eq $configDebug -or $null -eq $configRelease) {
        throw "Project '$($Project.Name)' must have both Debug and Release Win32 configs in manifest."
    }

    $configurationType = if ($Project.TargetType -eq 'StaticLibrary') { 'StaticLibrary' } else { 'Application' }
    $isRtsProject = ($Project.Name -eq 'RTS')
    $isGameEngineDeviceProject = ($Project.Name -eq 'GameEngineDevice')
    $waveNvpPath = '.\Source\W3DDevice\GameClient\Water\wave.nvp'
    $waveNvvPath = '.\Source\W3DDevice\GameClient\Water\wave.nvv'

    $rtsVersionCommand = 'set "VER_TOOL=$(SolutionDir)..\Run\rtsver.exe" & if not exist "$(SolutionDir)..\Run\rtsver.exe" set "VER_TOOL=$(SolutionDir)..\Run\versionUpdate.exe" & set "BVER_TOOL=$(SolutionDir)..\Run\rtsbuildver.exe" & if not exist "$(SolutionDir)..\Run\rtsbuildver.exe" set "BVER_TOOL=$(SolutionDir)..\Run\buildVersionUpdate.exe" & if exist "%VER_TOOL%" if exist "%BVER_TOOL%" ( "%VER_TOOL%" "$(ProjectDir)Main\generatedVersion.h" & "%BVER_TOOL%" "$(ProjectDir)Main\buildVersion.h" ) else ( echo ERROR: Missing version update tools in $(SolutionDir)..\Run & exit /b 1 )'
    $wavePixelDebugCommand = 'if not exist "$(SolutionDir)..\Run\Shaders" mkdir "$(SolutionDir)..\Run\Shaders" & if exist "$(SolutionDir)Tools\NVASM\nvasm.exe" ( "$(SolutionDir)Tools\NVASM\nvasm.exe" -d "%(FullPath)" "$(SolutionDir)..\Run\Shaders\wave.pso" ) else ( echo ERROR: Missing NVASM tool at $(SolutionDir)Tools\NVASM\nvasm.exe & exit /b 1 )'
    $wavePixelReleaseCommand = 'if exist "$(SolutionDir)Tools\NVASM\nvasm.exe" ( "$(SolutionDir)Tools\NVASM\nvasm.exe" -d "%(FullPath)" "$(SolutionDir)..\Run\wave.pso" ) else ( echo ERROR: Missing NVASM tool at $(SolutionDir)Tools\NVASM\nvasm.exe & exit /b 1 )'
    $waveVertexDebugCommand = 'if not exist "$(SolutionDir)..\Run\Shaders" mkdir "$(SolutionDir)..\Run\Shaders" & if exist "$(SolutionDir)Tools\NVASM\nvasm.exe" ( "$(SolutionDir)Tools\NVASM\nvasm.exe" -d "%(FullPath)" "$(SolutionDir)..\Run\Shaders\wave.vso" ) else ( echo ERROR: Missing NVASM tool at $(SolutionDir)Tools\NVASM\nvasm.exe & exit /b 1 )'
    $waveVertexReleaseCommand = 'if exist "$(SolutionDir)Tools\NVASM\nvasm.exe" ( "$(SolutionDir)Tools\NVASM\nvasm.exe" -d "%(FullPath)" "$(SolutionDir)..\Run\wave.vso" ) else ( echo ERROR: Missing NVASM tool at $(SolutionDir)Tools\NVASM\nvasm.exe & exit /b 1 )'

    $compileFiles = @()
    $includeFiles = @()
    $resourceFiles = @()
    $noneFiles = @()

    foreach ($source in $Project.SourceFiles) {
        $ext = [System.IO.Path]::GetExtension($source).ToLowerInvariant()
        switch ($ext) {
            '.c' { $compileFiles += $source; break }
            '.cc' { $compileFiles += $source; break }
            '.cpp' { $compileFiles += $source; break }
            '.cxx' { $compileFiles += $source; break }
            '.h' { $includeFiles += $source; break }
            '.hpp' { $includeFiles += $source; break }
            '.inl' { $includeFiles += $source; break }
            '.rc' { $resourceFiles += $source; break }
            default { $noneFiles += $source; break }
        }
    }

    $projectRefs = @()
    foreach ($dep in $Project.Dependencies) {
        if ($ProjectGuidByName.ContainsKey($dep)) {
            $projectRefs += [ordered]@{
                Name = $dep
                Guid = $ProjectGuidByName[$dep]
            }
        }
    }

    $debugIncludes = (($configDebug.IncludeDirs + @('$(IncludePath)')) | Select-Object -Unique) -join ';'
    $releaseIncludes = (($configRelease.IncludeDirs + @('$(IncludePath)')) | Select-Object -Unique) -join ';'
    $debugDefs = (($configDebug.Defines + @('%(PreprocessorDefinitions)')) | Select-Object -Unique) -join ';'
    $releaseDefs = (($configRelease.Defines + @('%(PreprocessorDefinitions)')) | Select-Object -Unique) -join ';'

    $debugLibPaths = (($configDebug.LibPaths + @('$(LibraryPath)')) | Select-Object -Unique) -join ';'
    $releaseLibPaths = (($configRelease.LibPaths + @('$(LibraryPath)')) | Select-Object -Unique) -join ';'
    $debugLibs = (($configDebug.Libraries + @('%(AdditionalDependencies)')) | Select-Object -Unique) -join ';'
    $releaseLibs = (($configRelease.Libraries + @('%(AdditionalDependencies)')) | Select-Object -Unique) -join ';'

    $xml = New-Object System.Text.StringBuilder
    [void]$xml.AppendLine('<?xml version="1.0" encoding="utf-8"?>')
    [void]$xml.AppendLine('<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')
    [void]$xml.AppendLine('  <ItemGroup Label="ProjectConfigurations">')
    [void]$xml.AppendLine('    <ProjectConfiguration Include="Debug|Win32">')
    [void]$xml.AppendLine('      <Configuration>Debug</Configuration>')
    [void]$xml.AppendLine('      <Platform>Win32</Platform>')
    [void]$xml.AppendLine('    </ProjectConfiguration>')
    [void]$xml.AppendLine('    <ProjectConfiguration Include="Release|Win32">')
    [void]$xml.AppendLine('      <Configuration>Release</Configuration>')
    [void]$xml.AppendLine('      <Platform>Win32</Platform>')
    [void]$xml.AppendLine('    </ProjectConfiguration>')
    [void]$xml.AppendLine('  </ItemGroup>')
    [void]$xml.AppendLine('  <PropertyGroup Label="Globals">')
    [void]$xml.AppendLine("    <ProjectGuid>{$($ProjectGuid.ToString().ToUpperInvariant())}</ProjectGuid>")
    [void]$xml.AppendLine("    <Keyword>Win32Proj</Keyword>")
    [void]$xml.AppendLine("    <RootNamespace>$(Escape-Xml $Project.Name)</RootNamespace>")
    [void]$xml.AppendLine('    <WindowsTargetPlatformVersion>10.0</WindowsTargetPlatformVersion>')
    [void]$xml.AppendLine('  </PropertyGroup>')
    [void]$xml.AppendLine('  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />')
    [void]$xml.AppendLine('  <PropertyGroup Condition="''$(Configuration)|$(Platform)''==''Debug|Win32''" Label="Configuration">')
    [void]$xml.AppendLine("    <ConfigurationType>$configurationType</ConfigurationType>")
    [void]$xml.AppendLine('    <UseDebugLibraries>true</UseDebugLibraries>')
    [void]$xml.AppendLine('    <PlatformToolset>v143</PlatformToolset>')
    [void]$xml.AppendLine('    <CharacterSet>MultiByte</CharacterSet>')
    [void]$xml.AppendLine('  </PropertyGroup>')
    [void]$xml.AppendLine('  <PropertyGroup Condition="''$(Configuration)|$(Platform)''==''Release|Win32''" Label="Configuration">')
    [void]$xml.AppendLine("    <ConfigurationType>$configurationType</ConfigurationType>")
    [void]$xml.AppendLine('    <UseDebugLibraries>false</UseDebugLibraries>')
    [void]$xml.AppendLine('    <PlatformToolset>v143</PlatformToolset>')
    [void]$xml.AppendLine('    <WholeProgramOptimization>true</WholeProgramOptimization>')
    [void]$xml.AppendLine('    <CharacterSet>MultiByte</CharacterSet>')
    [void]$xml.AppendLine('  </PropertyGroup>')
    [void]$xml.AppendLine('  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />')
    [void]$xml.AppendLine('  <PropertyGroup Condition="''$(Configuration)|$(Platform)''==''Debug|Win32''">')
    [void]$xml.AppendLine("    <OutDir>$([System.Security.SecurityElement]::Escape($configDebug.OutputDir))\\</OutDir>")
    [void]$xml.AppendLine("    <IntDir>$([System.Security.SecurityElement]::Escape($configDebug.IntermediateDir))\\</IntDir>")
    [void]$xml.AppendLine('  </PropertyGroup>')
    [void]$xml.AppendLine('  <PropertyGroup Condition="''$(Configuration)|$(Platform)''==''Release|Win32''">')
    [void]$xml.AppendLine("    <OutDir>$([System.Security.SecurityElement]::Escape($configRelease.OutputDir))\\</OutDir>")
    [void]$xml.AppendLine("    <IntDir>$([System.Security.SecurityElement]::Escape($configRelease.IntermediateDir))\\</IntDir>")
    [void]$xml.AppendLine('  </PropertyGroup>')

    [void]$xml.AppendLine('  <ItemDefinitionGroup Condition="''$(Configuration)|$(Platform)''==''Debug|Win32''">')
    [void]$xml.AppendLine('    <ClCompile>')
    [void]$xml.AppendLine('      <WarningLevel>Level3</WarningLevel>')
    [void]$xml.AppendLine('      <Optimization>Disabled</Optimization>')
    [void]$xml.AppendLine('      <PrecompiledHeader>NotUsing</PrecompiledHeader>')
    [void]$xml.AppendLine("      <RuntimeLibrary>$($configDebug.RuntimeLibrary)</RuntimeLibrary>")
    [void]$xml.AppendLine("      <AdditionalIncludeDirectories>$([System.Security.SecurityElement]::Escape($debugIncludes))</AdditionalIncludeDirectories>")
    [void]$xml.AppendLine("      <PreprocessorDefinitions>$([System.Security.SecurityElement]::Escape($debugDefs))</PreprocessorDefinitions>")
    [void]$xml.AppendLine('    </ClCompile>')

    if ($configurationType -eq 'Application') {
        if ($isRtsProject) {
            [void]$xml.AppendLine('    <PreBuildEvent>')
            [void]$xml.AppendLine("      <Command>$([System.Security.SecurityElement]::Escape($rtsVersionCommand))</Command>")
            [void]$xml.AppendLine('    </PreBuildEvent>')
        }
        [void]$xml.AppendLine('    <Link>')
        [void]$xml.AppendLine("      <AdditionalDependencies>$([System.Security.SecurityElement]::Escape($debugLibs))</AdditionalDependencies>")
        [void]$xml.AppendLine("      <AdditionalLibraryDirectories>$([System.Security.SecurityElement]::Escape($debugLibPaths))</AdditionalLibraryDirectories>")
        if (-not [string]::IsNullOrWhiteSpace($configDebug.OutputFile)) {
            [void]$xml.AppendLine("      <OutputFile>$([System.Security.SecurityElement]::Escape($configDebug.OutputFile))</OutputFile>")
        }
        [void]$xml.AppendLine('      <SubSystem>Windows</SubSystem>')
        [void]$xml.AppendLine('      <GenerateDebugInformation>true</GenerateDebugInformation>')
        [void]$xml.AppendLine('    </Link>')
    }
    else {
        [void]$xml.AppendLine('    <Lib>')
        if (-not [string]::IsNullOrWhiteSpace($configDebug.OutputFile)) {
            [void]$xml.AppendLine("      <OutputFile>$([System.Security.SecurityElement]::Escape($configDebug.OutputFile))</OutputFile>")
        }
        [void]$xml.AppendLine('    </Lib>')
    }
    [void]$xml.AppendLine('  </ItemDefinitionGroup>')

    [void]$xml.AppendLine('  <ItemDefinitionGroup Condition="''$(Configuration)|$(Platform)''==''Release|Win32''">')
    [void]$xml.AppendLine('    <ClCompile>')
    [void]$xml.AppendLine('      <WarningLevel>Level3</WarningLevel>')
    [void]$xml.AppendLine('      <Optimization>MaxSpeed</Optimization>')
    [void]$xml.AppendLine('      <FunctionLevelLinking>true</FunctionLevelLinking>')
    [void]$xml.AppendLine('      <IntrinsicFunctions>true</IntrinsicFunctions>')
    [void]$xml.AppendLine('      <PrecompiledHeader>NotUsing</PrecompiledHeader>')
    [void]$xml.AppendLine("      <RuntimeLibrary>$($configRelease.RuntimeLibrary)</RuntimeLibrary>")
    [void]$xml.AppendLine("      <AdditionalIncludeDirectories>$([System.Security.SecurityElement]::Escape($releaseIncludes))</AdditionalIncludeDirectories>")
    [void]$xml.AppendLine("      <PreprocessorDefinitions>$([System.Security.SecurityElement]::Escape($releaseDefs))</PreprocessorDefinitions>")
    [void]$xml.AppendLine('    </ClCompile>')
    if ($isRtsProject) {
        [void]$xml.AppendLine('    <PreBuildEvent>')
        [void]$xml.AppendLine("      <Command>$([System.Security.SecurityElement]::Escape($rtsVersionCommand))</Command>")
        [void]$xml.AppendLine('    </PreBuildEvent>')
    }
    if ($configurationType -eq 'Application') {
        [void]$xml.AppendLine('    <Link>')
        [void]$xml.AppendLine("      <AdditionalDependencies>$([System.Security.SecurityElement]::Escape($releaseLibs))</AdditionalDependencies>")
        [void]$xml.AppendLine("      <AdditionalLibraryDirectories>$([System.Security.SecurityElement]::Escape($releaseLibPaths))</AdditionalLibraryDirectories>")
        if (-not [string]::IsNullOrWhiteSpace($configRelease.OutputFile)) {
            [void]$xml.AppendLine("      <OutputFile>$([System.Security.SecurityElement]::Escape($configRelease.OutputFile))</OutputFile>")
        }
        [void]$xml.AppendLine('      <SubSystem>Windows</SubSystem>')
        [void]$xml.AppendLine('      <GenerateDebugInformation>true</GenerateDebugInformation>')
        [void]$xml.AppendLine('    </Link>')
    }
    else {
        [void]$xml.AppendLine('    <Lib>')
        if (-not [string]::IsNullOrWhiteSpace($configRelease.OutputFile)) {
            [void]$xml.AppendLine("      <OutputFile>$([System.Security.SecurityElement]::Escape($configRelease.OutputFile))</OutputFile>")
        }
        [void]$xml.AppendLine('    </Lib>')
    }
    [void]$xml.AppendLine('  </ItemDefinitionGroup>')

    if ($compileFiles.Count -gt 0) {
        [void]$xml.AppendLine('  <ItemGroup>')
        foreach ($file in ($compileFiles | Sort-Object -Unique)) {
            [void]$xml.AppendLine("    <ClCompile Include=`"$([System.Security.SecurityElement]::Escape($file))`" />")
        }
        [void]$xml.AppendLine('  </ItemGroup>')
    }

    if ($includeFiles.Count -gt 0) {
        [void]$xml.AppendLine('  <ItemGroup>')
        foreach ($file in ($includeFiles | Sort-Object -Unique)) {
            [void]$xml.AppendLine("    <ClInclude Include=`"$([System.Security.SecurityElement]::Escape($file))`" />")
        }
        [void]$xml.AppendLine('  </ItemGroup>')
    }

    if ($resourceFiles.Count -gt 0) {
        [void]$xml.AppendLine('  <ItemGroup>')
        foreach ($file in ($resourceFiles | Sort-Object -Unique)) {
            [void]$xml.AppendLine("    <ResourceCompile Include=`"$([System.Security.SecurityElement]::Escape($file))`" />")
        }
        [void]$xml.AppendLine('  </ItemGroup>')
    }

    if ($noneFiles.Count -gt 0) {
        [void]$xml.AppendLine('  <ItemGroup>')
        foreach ($file in ($noneFiles | Sort-Object -Unique)) {
            if ($isGameEngineDeviceProject -and ($file -ieq $waveNvpPath -or $file -ieq $waveNvvPath)) {
                continue
            }
            [void]$xml.AppendLine("    <None Include=`"$([System.Security.SecurityElement]::Escape($file))`" />")
        }
        [void]$xml.AppendLine('  </ItemGroup>')
    }

    if ($isGameEngineDeviceProject) {
        [void]$xml.AppendLine('  <ItemGroup>')
        [void]$xml.AppendLine("    <CustomBuild Include=`"$waveNvpPath`">")
        [void]$xml.AppendLine("      <Command Condition=`"'`$(Configuration)|`$(Platform)'=='Debug|Win32'`">$([System.Security.SecurityElement]::Escape($wavePixelDebugCommand))</Command>")
        [void]$xml.AppendLine("      <Outputs Condition=`"'`$(Configuration)|`$(Platform)'=='Debug|Win32'`">`$(SolutionDir)..\Run\Shaders\wave.pso</Outputs>")
        [void]$xml.AppendLine("      <Command Condition=`"'`$(Configuration)|`$(Platform)'=='Release|Win32'`">$([System.Security.SecurityElement]::Escape($wavePixelReleaseCommand))</Command>")
        [void]$xml.AppendLine("      <Outputs Condition=`"'`$(Configuration)|`$(Platform)'=='Release|Win32'`">`$(SolutionDir)..\Run\wave.pso</Outputs>")
        [void]$xml.AppendLine('      <Message>Compile NVASM pixel shader</Message>')
        [void]$xml.AppendLine('    </CustomBuild>')
        [void]$xml.AppendLine("    <CustomBuild Include=`"$waveNvvPath`">")
        [void]$xml.AppendLine("      <Command Condition=`"'`$(Configuration)|`$(Platform)'=='Debug|Win32'`">$([System.Security.SecurityElement]::Escape($waveVertexDebugCommand))</Command>")
        [void]$xml.AppendLine("      <Outputs Condition=`"'`$(Configuration)|`$(Platform)'=='Debug|Win32'`">`$(SolutionDir)..\Run\Shaders\wave.vso</Outputs>")
        [void]$xml.AppendLine("      <Command Condition=`"'`$(Configuration)|`$(Platform)'=='Release|Win32'`">$([System.Security.SecurityElement]::Escape($waveVertexReleaseCommand))</Command>")
        [void]$xml.AppendLine("      <Outputs Condition=`"'`$(Configuration)|`$(Platform)'=='Release|Win32'`">`$(SolutionDir)..\Run\wave.vso</Outputs>")
        [void]$xml.AppendLine('      <Message>Compile NVASM vertex shader</Message>')
        [void]$xml.AppendLine('    </CustomBuild>')
        [void]$xml.AppendLine('  </ItemGroup>')
    }

    if ($projectRefs.Count -gt 0) {
        [void]$xml.AppendLine('  <ItemGroup>')
        foreach ($reference in $projectRefs) {
            $referencePath = "..\$($reference.Name)\$($reference.Name).vcxproj"
            [void]$xml.AppendLine("    <ProjectReference Include=`"$referencePath`">")
            [void]$xml.AppendLine("      <Project>{$($reference.Guid.ToString().ToUpperInvariant())}</Project>")
            [void]$xml.AppendLine('    </ProjectReference>')
        }
        [void]$xml.AppendLine('  </ItemGroup>')
    }

    [void]$xml.AppendLine('  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />')
    [void]$xml.AppendLine('</Project>')

    $projectXml = $xml.ToString()
    Set-Content -Path $ProjectPath -Value $projectXml -Encoding UTF8
}

function Write-Solution {
    param(
        [string]$SolutionPath,
        [hashtable]$Projects,
        [hashtable]$ProjectGuidByName
    )

    $vcProjectTypeGuid = '{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}'
    $slnGuid = (New-DeterministicGuid -Input $SolutionPath).ToString().ToUpperInvariant()

    $order = @('GameEngine', 'GameEngineDevice', 'RTS')

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('Microsoft Visual Studio Solution File, Format Version 12.00')
    [void]$sb.AppendLine('# Visual Studio Version 17')
    [void]$sb.AppendLine('VisualStudioVersion = 17.0.31903.59')
    [void]$sb.AppendLine('MinimumVisualStudioVersion = 10.0.40219.1')

    foreach ($name in $order) {
        if (-not $Projects.ContainsKey($name)) { continue }
        $projGuid = $ProjectGuidByName[$name].ToString().ToUpperInvariant()
        $projPath = "$name\$name.vcxproj"
        [void]$sb.AppendLine(("Project(`"{0}`") = `"{1}`", `"{2}`", `"{{{3}}}`"" -f $vcProjectTypeGuid, $name, $projPath, $projGuid))

        $deps = @()
        foreach ($dep in $Projects[$name].Dependencies) {
            if ($ProjectGuidByName.ContainsKey($dep)) {
                $deps += $dep
            }
        }

        if ($deps.Count -gt 0) {
            [void]$sb.AppendLine('    ProjectSection(ProjectDependencies) = postProject')
            foreach ($depName in $deps) {
                $depGuid = $ProjectGuidByName[$depName].ToString().ToUpperInvariant()
                [void]$sb.AppendLine("        {$depGuid} = {$depGuid}")
            }
            [void]$sb.AppendLine('    EndProjectSection')
        }

        [void]$sb.AppendLine('EndProject')
    }

    [void]$sb.AppendLine('Global')
    [void]$sb.AppendLine('    GlobalSection(SolutionConfigurationPlatforms) = preSolution')
    [void]$sb.AppendLine('        Debug|Win32 = Debug|Win32')
    [void]$sb.AppendLine('        Release|Win32 = Release|Win32')
    [void]$sb.AppendLine('    EndGlobalSection')
    [void]$sb.AppendLine('    GlobalSection(ProjectConfigurationPlatforms) = postSolution')

    foreach ($name in $order) {
        if (-not $Projects.ContainsKey($name)) { continue }
        $projGuid = $ProjectGuidByName[$name].ToString().ToUpperInvariant()
        [void]$sb.AppendLine("        {$projGuid}.Debug|Win32.ActiveCfg = Debug|Win32")
        [void]$sb.AppendLine("        {$projGuid}.Debug|Win32.Build.0 = Debug|Win32")
        [void]$sb.AppendLine("        {$projGuid}.Release|Win32.ActiveCfg = Release|Win32")
        [void]$sb.AppendLine("        {$projGuid}.Release|Win32.Build.0 = Release|Win32")
    }

    [void]$sb.AppendLine('    EndGlobalSection')
    [void]$sb.AppendLine('    GlobalSection(SolutionProperties) = preSolution')
    [void]$sb.AppendLine('        HideSolutionNode = FALSE')
    [void]$sb.AppendLine('    EndGlobalSection')
    [void]$sb.AppendLine('    GlobalSection(ExtensibilityGlobals) = postSolution')
    [void]$sb.AppendLine("        SolutionGuid = {$slnGuid}")
    [void]$sb.AppendLine('    EndGlobalSection')
    [void]$sb.AppendLine('EndGlobal')

    Set-Content -Path $SolutionPath -Value $sb.ToString() -Encoding UTF8
}

function Generate-Tree {
    param(
        [string]$TreeName,
        [string]$WorkspacePath
    )

    $manifestPath = Join-Path $RepoRoot "scripts\phase2\out\$TreeName.core.manifest.json"
    $generator = Join-Path $RepoRoot "scripts\phase2\New-Vc6Manifest.ps1"
    & $generator -WorkspacePath $WorkspacePath -OutputPath $manifestPath -ProjectFilter @('GameEngine', 'GameEngineDevice', 'RTS')

    $manifestObject = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
    $manifest = ConvertTo-Hashtable $manifestObject
    $workspaceDir = $manifest.WorkspaceDir
    $projects = $manifest.Projects

    $projectGuidByName = @{}
    foreach ($name in $projects.Keys) {
        $projectGuidByName[$name] = New-DeterministicGuid -Input "$TreeName::$name"
    }

    foreach ($name in @('GameEngine', 'GameEngineDevice', 'RTS')) {
        if (-not $projects.ContainsKey($name)) {
            throw "Expected project '$name' not present in manifest for $TreeName."
        }

        $targetDir = Join-Path $workspaceDir $name
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        $projectPath = Join-Path $targetDir "$name.vcxproj"
        Write-Vcxproj -ProjectPath $projectPath -Project $projects[$name] -ProjectGuid $projectGuidByName[$name] -ProjectGuidByName $projectGuidByName
    }

    $solutionPath = Join-Path $workspaceDir 'RTS.sln'
    Write-Solution -SolutionPath $solutionPath -Projects $projects -ProjectGuidByName $projectGuidByName
    Write-Host "Generated: $solutionPath"
}

Generate-Tree -TreeName 'Generals' -WorkspacePath (Join-Path $RepoRoot 'Generals\Code\RTS.dsw')
Generate-Tree -TreeName 'GeneralsMD' -WorkspacePath (Join-Path $RepoRoot 'GeneralsMD\Code\RTS.dsw')

if (-not $SkipValidation) {
    $validator = Join-Path $RepoRoot 'scripts\phase2\Test-Phase2Conversion.ps1'
    & $validator -RepoRoot $RepoRoot
}

Write-Host 'Phase 2 reconstruction generation complete.'