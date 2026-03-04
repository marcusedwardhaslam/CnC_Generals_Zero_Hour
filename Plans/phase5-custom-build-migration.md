# Phase 5 — Custom Build Step Migration Log

Date: 2026-03-04  
Owner: Copilot  
Source plan: [plan-commandConquerGeneralsZeroHour.prompt.md](plan-commandConquerGeneralsZeroHour.prompt.md)

## Scope Covered

Phase 5 migration was executed for core reconstructed projects and representative tool script baseline:

- RTS legacy version increment steps
- GameEngineDevice NVASM shader compilation steps
- ParticleEditor legacy post-build script presence check

## Implemented Changes

Migration logic was added to the reconstruction generator:

- [scripts/phase2/Invoke-Phase2Reconstruction.ps1](../scripts/phase2/Invoke-Phase2Reconstruction.ps1)

Custom NVASM replacement implementation added:

- Source: [scripts/phase5/nvasm/nvasm-new.c](../scripts/phase5/nvasm/nvasm-new.c)
- Build/install helper: [scripts/phase5/nvasm/Build-NvasmReplacement.ps1](../scripts/phase5/nvasm/Build-NvasmReplacement.ps1)

Custom version-tool build/install helpers added:

- [scripts/phase5/versiontools/Build-VersionTools.ps1](../scripts/phase5/versiontools/Build-VersionTools.ps1)
- [scripts/phase5/versiontools/Build-And-Validate-Phase5VersionTools.cmd](../scripts/phase5/versiontools/Build-And-Validate-Phase5VersionTools.cmd)

Regenerated projects now include:

- RTS pre-build event invoking:
  - `rtsver.exe` (preferred) or `versionUpdate.exe` (fallback) against `Main/generatedVersion.h`
  - `rtsbuildver.exe` (preferred) or `buildVersionUpdate.exe` (fallback) against `Main/buildVersion.h`
- GameEngineDevice custom build entries for:
  - `wave.nvp` -> `wave.pso`
  - `wave.nvv` -> `wave.vso`
  using `Tools/NVASM/nvasm.exe` with Debug/Release output paths aligned to legacy behavior.

## Validation

Validator added:

- [scripts/phase5/Test-Phase5CustomBuildMigration.ps1](../scripts/phase5/Test-Phase5CustomBuildMigration.ps1)

Validation confirms hooks are present in generated `vcxproj` files for:

- `RTS` (both trees)
- `GameEngineDevice` (both trees)

and confirms legacy tool script exists for:

- `Tools/ParticleEditor/post-build.bat` (both trees)

## Current Blockers

No active Phase 5 blockers.

Renamed executables are now built from repository source and installed at expected runtime paths:

- `Generals/Run/rtsver.exe`
- `Generals/Run/rtsbuildver.exe`
- `GeneralsMD/Run/rtsver.exe`
- `GeneralsMD/Run/rtsbuildver.exe`

NVASM replacement status (updated):

- Built successfully with MSVC using:
  - `scripts/phase5/nvasm/Build-And-Validate-Phase5.cmd`
- Installed outputs:
  - `Generals/Code/Tools/NVASM/nvasm.exe`
  - `GeneralsMD/Code/Tools/NVASM/nvasm.exe`

To build replacement NVASM once a compiler shell is active:

```powershell
.\scripts\phase5\nvasm\Build-NvasmReplacement.ps1
```

Phase 5 validator now passes with renamed binaries in place.

## Next Action

When rebuilding tools in a fresh environment, run:

```powershell
.\scripts\phase5\versiontools\Build-And-Validate-Phase5VersionTools.cmd
```

Then proceed to Phase 6 task orchestration.