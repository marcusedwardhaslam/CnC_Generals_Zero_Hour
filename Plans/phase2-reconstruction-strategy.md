# Phase 2 Reconstruction Strategy (No VS2003)

Date: 2026-03-04  
Owner: Copilot  
Related log: [phase2-project-conversion.md](phase2-project-conversion.md)

## Why this strategy was chosen

The original Phase 2 plan assumed a legacy conversion hop:

`VC6 (.dsw/.dsp) -> VS2003 -> modern VS`

That route is not executable in this environment because VS2003 tooling is unavailable, and direct modern Visual Studio upgrade (`devenv /upgrade`) does not recognize `.dsw` workspaces.

To prevent the migration from being blocked indefinitely, we selected a deterministic **metadata reconstruction** approach that uses the VC6 files as source-of-truth and generates modern project artifacts directly.

## Decision criteria

This route was selected because it is:

- **Toolchain-independent:** no dependence on obsolete IDE binaries.
- **Deterministic:** generator output is reproducible from committed source metadata.
- **Auditable:** migration logic is explicit in scripts, rather than hidden in one-time IDE conversion state.
- **Phased-compatible:** supports the existing migration phases (config normalization, path externalization, custom build migration).

## Scope implemented in this phase

Current reconstruction scope is intentionally constrained to Phase 2 core bring-up targets:

- `GameEngine`
- `GameEngineDevice`
- `RTS`

for both trees:

- `Generals/Code`
- `GeneralsMD/Code`

and restricted to:

- `Debug|Win32`
- `Release|Win32`

## Implementation details

Scripts:

- [scripts/phase2/New-Vc6Manifest.ps1](../scripts/phase2/New-Vc6Manifest.ps1)
  - Parses `.dsw` project definitions + dependencies.
  - Parses `.dsp` config blocks, include/define/link metadata, and source lists.
  - Emits tree-scoped manifests to `scripts/phase2/out/*.manifest.json`.

- [scripts/phase2/Invoke-Phase2Reconstruction.ps1](../scripts/phase2/Invoke-Phase2Reconstruction.ps1)
  - Consumes manifests.
  - Generates modern `RTS.sln` + core `*.vcxproj` for both trees.
  - Preserves dependency relationships among core targets.
  - Runs [scripts/phase2/Test-Phase2Conversion.ps1](../scripts/phase2/Test-Phase2Conversion.ps1).

## Trade-offs and accepted limitations

- Generated projects are **migration scaffolding**, not final compile-ready parity with VC6.
- Obsolete flags and custom build behavior are intentionally deferred to later phases.
- Current scope does not yet include all legacy tool/plugin projects.

These trade-offs are acceptable for Phase 2 because the objective is to establish modern-loadable project structure and dependency topology first.

## Operational commands

From repository root:

```powershell
.\scripts\phase2\Invoke-Phase2Reconstruction.ps1
```

Optional validation-only rerun:

```powershell
.\scripts\phase2\Test-Phase2Conversion.ps1
```

## Exit condition for this strategy in Phase 2

Phase 2 is considered complete for core targets when both trees have generated solutions/projects that:

1. Exist on disk and are loadable by modern VS tooling.
2. Resolve project paths and references for the reconstructed core set.
3. Expose only `Debug|Win32` and `Release|Win32` in solution configuration.

Expansion to additional targets (tools/plugins/libraries beyond core) can be performed using the same manifest+generator pattern.