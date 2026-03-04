## Plan: VS Code Modern Build Migration (FINAL)

This is the execution baseline for migrating the legacy VC6 build to a modern Visual Studio + VS Code workflow. It keeps scope to `Win32` (`Debug` and `Release`) across both game trees (`Generals`, `GeneralsMD`) and included tools, with phased bring-up to isolate blockers early.

**Goal**
- Produce modern `.sln/.vcxproj` projects that load and build from VS Code tasks.
- Standardize configuration and dependency resolution across both trees.
- Track blockers as either `missing dependency/toolchain` or `code modernization`.

**In Scope**
- `Generals/Code/*` and `GeneralsMD/Code/*` project/workspace migration.
- Core targets: `GameEngine`, `GameEngineDevice`, `RTS`.
- Representative tool targets, including `ParticleEditor`, `WorldBuilder`, and WW3D-related plugins/tools.
- VS Code build orchestration files in `.vscode/`.

**Out of Scope**
- x64 migration.
- Functional refactors unrelated to compile/build bring-up.
- Binary parity guarantees against historical retail binaries.

## Phase 1 — Inventory and Baseline

**Inputs**
- [Generals/Code/RTS.dsw](Generals/Code/RTS.dsw)
- [GeneralsMD/Code/RTS.dsw](GeneralsMD/Code/RTS.dsw)
- Standalone tool workspaces (for example [Generals/Code/Tools/ParticleEditor/ParticleEditor.dsw](Generals/Code/Tools/ParticleEditor/ParticleEditor.dsw), [GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsw](GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsw))

**Actions**
1. Enumerate all `.dsw/.dsp` roots and classify by tree (`Generals`, `GeneralsMD`) and category (`core`, `library`, `tool`, `plugin`).
2. Capture dependency order from workspace graphs in [Generals/Code/RTS.dsw](Generals/Code/RTS.dsw#L345-L421) and [GeneralsMD/Code/RTS.dsw](GeneralsMD/Code/RTS.dsw#L381-L455).
3. Record legacy custom build/post-build commands for later migration.

**Exit Criteria**
- Complete inventory list with target category and dependency chain.
- Identified high-coupling targets (`RTS`, `WorldBuilder`, WW3D plugins) marked for late-phase bring-up.

## Phase 2 — Project Conversion

**Actions**
1. Convert VC6 projects through a supported upgrade path (VC6 → VS2003 compatibility path → modern VS).
2. Generate `.sln/.vcxproj` for both trees, preserving original project boundaries and dependency order.
3. Restrict configurations to `Debug|Win32` and `Release|Win32` unless a project requires transitional extras.

**Exit Criteria**
- All converted solutions open in modern Visual Studio without project-load errors.
- Dependency graph in converted solutions matches source `.dsw` order.

## Phase 3 — Configuration Normalization

**Actions**
1. Replace obsolete compiler switches (`/G6 /GX /Gm /GZ /YX`) with modern equivalents and remove unsupported flags.
2. Normalize precompiled-header behavior and runtime library settings per project family.
3. Preserve x86 assumptions documented in [Generals/Code/RTS.dsp](Generals/Code/RTS.dsp#L47-L57) and [GeneralsMD/Code/GameEngine/GameEngine.dsp](GeneralsMD/Code/GameEngine/GameEngine.dsp#L46-L70).

**Exit Criteria**
- No unsupported toolset flags in generated project files.
- PCH and CRT settings are internally consistent within each solution.

## Phase 4 — Dependency and Path Externalization

**Actions**
1. Define shared dependency roots via environment variables and/or shared props.
2. Map required SDK/library/include/tool locations based on [README.md](README.md#L6-L23).
3. Resolve naming/location mismatches and placeholders (for example [GeneralsMD/Code/Libraries/Lib/.gitignore](GeneralsMD/Code/Libraries/Lib/.gitignore)).

**Exit Criteria**
- Path-lint can report unresolved include/lib/tool paths before compile.
- Dependency root definitions are centralized and documented.

## Phase 5 — Custom Build Step Migration

**Actions**
1. Port legacy build events from [Generals/Code/RTS.dsp](Generals/Code/RTS.dsp#L135-L167).
2. Recreate NVASM shader/custom steps from [GeneralsMD/Code/GameEngineDevice/GameEngineDevice.dsp](GeneralsMD/Code/GameEngineDevice/GameEngineDevice.dsp#L379-L407).
3. Port tool-specific copy/post-build scripts (for example [Generals/Code/Tools/ParticleEditor/post-build.bat](Generals/Code/Tools/ParticleEditor/post-build.bat)).

**Exit Criteria**
- Converted projects execute equivalent build/post-build behavior under MSBuild.
- Missing external tool executables are surfaced as explicit blockers.

## Phase 6 — VS Code Orchestration

**Actions**
1. Create [.vscode/tasks.json](.vscode/tasks.json) with task groups:
	- `conversion-check`
	- `path-lint`
	- `build-tools-lowdep`
	- `build-libs`
	- `build-engine`
	- `build-apps`
2. Add tree-scoped tasks for `Generals` and `GeneralsMD` in both `Debug|Win32` and `Release|Win32`.
3. Add `.vscode` settings/intellisense files as needed: [.vscode/settings.json](.vscode/settings.json), [.vscode/c_cpp_properties.json](.vscode/c_cpp_properties.json).

**Exit Criteria**
- One-command task entry points exist for each phase and each tree/config.
- Task outputs clearly show target-level pass/fail.

## Phase 7 — Phased Build Bring-Up

**Build Order**
1. Low-coupling tools and libs.
2. Core engine targets: `GameEngine`, `GameEngineDevice`.
3. Application/high-coupling targets: `RTS`, `WorldBuilder`, WW3D plugins.

**Actions**
1. Run `Debug|Win32` phase tasks first.
2. Repeat with `Release|Win32` after Debug baseline is stable.
3. Log each failure with root-cause category: `missing dependency/toolchain` or `code modernization`.

**Exit Criteria**
- Per-target status matrix for both configs.
- Known blockers are categorized with clear remediation owner/action.

## Phase 8 — Documentation and Handoff

**Actions**
1. Update [README.md](README.md) with:
	- Prerequisite matrix
	- Required environment variables
	- Phase task commands
	- Known blockers and workaround notes
2. Document expected run-output destinations:
	- [Generals/Run/place_steam_build_here.txt](Generals/Run/place_steam_build_here.txt)
	- [GeneralsMD/Run/place_steam_build_here.txt](GeneralsMD/Run/place_steam_build_here.txt)

**Exit Criteria**
- A clean-room teammate can run the same VS Code task flow using only repository docs + dependencies.

## Verification Gates

- **Gate A (Conversion):** all solutions load without project conversion/load errors.
- **Gate B (Static Readiness):** path-lint reports no unresolved mandatory paths.
- **Gate C (Build Progression):** Debug and Release task groups run per phase with recorded outcomes.
- **Gate D (Developer UX):** task naming and grouping provide predictable one-command execution.

## Final Success Criteria

- Modernized Win32 `Debug` and `Release` builds are reproducible from VS Code tasks for both trees once external dependencies are available.
- Blockers are explicit, categorized, and actionable.
- Workflow is documented and maintainable for future contributors.
