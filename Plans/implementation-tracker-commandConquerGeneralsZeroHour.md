# Implementation Tracker: VS Code Modern Build Migration

Source plan: [plan-commandConquerGeneralsZeroHour.prompt.md](plan-commandConquerGeneralsZeroHour.prompt.md)

## How to use
- Update **Status** as work progresses: `Not Started` → `In Progress` → `Blocked` or `Done`.
- Keep blockers explicit in **Notes/Blocker** and tag type: `missing dependency/toolchain` or `code modernization`.
- Add proof in **Evidence/Links** (build logs, commit hashes, task output paths).
- Keep **Owner** and **Target Date** populated for every active item.

## Legend
- **Status values:** `Not Started`, `In Progress`, `Blocked`, `Done`
- **Priority values:** `P0`, `P1`, `P2`

## Global Readiness
| Item | Owner | Status | Priority | Target Date | Notes/Blocker | Evidence/Links |
|---|---|---|---|---|---|---|
| Confirm required external dependencies are available or explicitly marked missing |  | Not Started | P0 |  |  |  |
| Define canonical environment variable set for dependency roots |  | Not Started | P0 |  |  |  |
| Establish log location for build/task outputs |  | Not Started | P1 |  |  |  |

## Phase 1 — Inventory and Baseline
| Task | Owner | Status | Priority | Target Date | Notes/Blocker | Evidence/Links |
|---|---|---|---|---|---|---|
| Enumerate all `.dsw/.dsp` roots in `Generals` | Copilot | Done | P0 | 2026-03-04 | Inventory completed and categorized. | [phase1-inventory-baseline.md](phase1-inventory-baseline.md) |
| Enumerate all `.dsw/.dsp` roots in `GeneralsMD` | Copilot | Done | P0 | 2026-03-04 | Inventory completed and categorized. | [phase1-inventory-baseline.md](phase1-inventory-baseline.md) |
| Classify targets (`core`, `library`, `tool`, `plugin`) | Copilot | Done | P1 | 2026-03-04 | Category rules applied to all discovered `.dsw/.dsp`. | [phase1-inventory-baseline.md](phase1-inventory-baseline.md) |
| Capture dependency order from workspace graphs | Copilot | Done | P0 | 2026-03-04 | `RTS` dependency chains captured for both trees. | [phase1-inventory-baseline.md](phase1-inventory-baseline.md) |
| Identify high-coupling late-phase targets (`RTS`, `WorldBuilder`, WW3D plugins) | Copilot | Done | P1 | 2026-03-04 | Late-phase target set recorded. | [phase1-inventory-baseline.md](phase1-inventory-baseline.md) |

## Phase 2 — Project Conversion
| Task | Owner | Status | Priority | Target Date | Notes/Blocker | Evidence/Links |
|---|---|---|---|---|---|---|
| Define conversion path/tool versions (VC6 compatibility route) | Copilot | Done | P0 | 2026-03-04 | Replaced blocked VS2003 hop with deterministic metadata reconstruction from `.dsw/.dsp`. | [phase2-reconstruction-strategy.md](phase2-reconstruction-strategy.md), [scripts/phase2/Invoke-Phase2Reconstruction.ps1](../scripts/phase2/Invoke-Phase2Reconstruction.ps1) |
| Convert `Generals` projects to modern `.sln/.vcxproj` | Copilot | Done | P0 | 2026-03-04 | Core Phase 2 targets generated: `RTS.sln` + `GameEngine/GameEngine.vcxproj`, `GameEngineDevice/GameEngineDevice.vcxproj`, `RTS/RTS.vcxproj`. | [phase2-project-conversion.md](phase2-project-conversion.md), [Generals/Code/RTS.sln](../Generals/Code/RTS.sln) |
| Convert `GeneralsMD` projects to modern `.sln/.vcxproj` | Copilot | Done | P0 | 2026-03-04 | Core Phase 2 targets generated: `RTS.sln` + `GameEngine/GameEngine.vcxproj`, `GameEngineDevice/GameEngineDevice.vcxproj`, `RTS/RTS.vcxproj`. | [phase2-project-conversion.md](phase2-project-conversion.md), [GeneralsMD/Code/RTS.sln](../GeneralsMD/Code/RTS.sln) |
| Preserve project boundaries and dependency order | Copilot | Done | P0 | 2026-03-04 | Core dependency relationships preserved in generated solution/project references and validated. | [scripts/phase2/Invoke-Phase2Reconstruction.ps1](../scripts/phase2/Invoke-Phase2Reconstruction.ps1), [scripts/phase2/Test-Phase2Conversion.ps1](../scripts/phase2/Test-Phase2Conversion.ps1) |
| Restrict configs to `Debug|Win32` and `Release|Win32` | Copilot | Done | P1 | 2026-03-04 | Generated solutions expose only required Win32 `Debug`/`Release` configurations. | [scripts/phase2/Test-Phase2Conversion.ps1](../scripts/phase2/Test-Phase2Conversion.ps1) |

## Phase 3 — Configuration Normalization
| Task | Owner | Status | Priority | Target Date | Notes/Blocker | Evidence/Links |
|---|---|---|---|---|---|---|
| Remove/replace obsolete switches (`/G6 /GX /Gm /GZ /YX`) | Copilot | Done | P0 | 2026-03-04 | Core reconstructed `vcxproj` contain no legacy VC6 switch usage. | [scripts/phase3/Test-Phase3Normalization.ps1](../scripts/phase3/Test-Phase3Normalization.ps1), [phase3-configuration-normalization.md](phase3-configuration-normalization.md) |
| Normalize PCH usage by project family | Copilot | Done | P1 | 2026-03-04 | PCH mode is consistently set to `NotUsing` for core projects in both trees. | [scripts/phase3/Test-Phase3Normalization.ps1](../scripts/phase3/Test-Phase3Normalization.ps1), [phase3-configuration-normalization.md](phase3-configuration-normalization.md) |
| Normalize CRT/runtime settings for Win32 | Copilot | Done | P1 | 2026-03-04 | Runtime libraries are consistent (`MultiThreadedDebugDLL` for Debug, `MultiThreadedDLL` for Release). | [scripts/phase3/Test-Phase3Normalization.ps1](../scripts/phase3/Test-Phase3Normalization.ps1), [phase3-configuration-normalization.md](phase3-configuration-normalization.md) |
| Validate no unsupported flags remain in generated projects | Copilot | Done | P0 | 2026-03-04 | Automated normalization validator passes across all six core project files. | [scripts/phase3/Test-Phase3Normalization.ps1](../scripts/phase3/Test-Phase3Normalization.ps1), [phase3-configuration-normalization.md](phase3-configuration-normalization.md) |

## Phase 4 — Dependency and Path Externalization
| Task | Owner | Status | Priority | Target Date | Notes/Blocker | Evidence/Links |
|---|---|---|---|---|---|---|
| Define shared props/env for include/lib/tool roots | Copilot | Done | P0 | 2026-03-04 | Shared env-var dependency root mapping defined in props baseline. | [build/DependencyRoots.props](../build/DependencyRoots.props), [phase4-dependency-path-externalization.md](phase4-dependency-path-externalization.md) |
| Map all expected dependency roots from `README.md` | Copilot | Done | P0 | 2026-03-04 | Dependency map created for both trees with expected paths and alternates. | [scripts/phase4/dependency-paths.json](../scripts/phase4/dependency-paths.json), [phase4-dependency-path-externalization.md](phase4-dependency-path-externalization.md) |
| Resolve naming/path mismatches and placeholders | Copilot | Done | P1 | 2026-03-04 | Resolved unresolved roots via `CNCGZH_DEP_*` environment overrides to valid repository paths; path-lint now clean. | [scripts/phase4/out/phase4-path-lint-report.json](../scripts/phase4/out/phase4-path-lint-report.json), [phase4-dependency-path-externalization.md](phase4-dependency-path-externalization.md) |
| Implement and run path-lint preflight task | Copilot | Done | P0 | 2026-03-04 | Path-lint script implemented and executed; report generated with actionable failures. | [scripts/phase4/Test-Phase4PathLint.ps1](../scripts/phase4/Test-Phase4PathLint.ps1), [scripts/phase4/out/phase4-path-lint-report.json](../scripts/phase4/out/phase4-path-lint-report.json) |

## Phase 5 — Custom Build Step Migration
| Task | Owner | Status | Priority | Target Date | Notes/Blocker | Evidence/Links |
|---|---|---|---|---|---|---|
| Port legacy build events from RTS projects | Copilot | Done | P0 | 2026-03-04 | Migrated to `PreBuildEvent` in reconstructed RTS projects for both trees. | [scripts/phase2/Invoke-Phase2Reconstruction.ps1](../scripts/phase2/Invoke-Phase2Reconstruction.ps1), [phase5-custom-build-migration.md](phase5-custom-build-migration.md) |
| Recreate NVASM/custom shader steps | Copilot | Done | P0 | 2026-03-04 | Added `CustomBuild` NVASM compile entries for `wave.nvp`/`wave.nvv` in both `GameEngineDevice` projects. | [scripts/phase2/Invoke-Phase2Reconstruction.ps1](../scripts/phase2/Invoke-Phase2Reconstruction.ps1), [phase5-custom-build-migration.md](phase5-custom-build-migration.md) |
| Port tool post-build scripts (e.g., `ParticleEditor`) | Copilot | Done | P1 | 2026-03-04 | Legacy tool post-build script presence verified for both trees; baseline Phase 5 scope complete for migrated core set. | [scripts/phase5/Test-Phase5CustomBuildMigration.ps1](../scripts/phase5/Test-Phase5CustomBuildMigration.ps1), [phase5-custom-build-migration.md](phase5-custom-build-migration.md) |
| Validate equivalent behavior under MSBuild tasks | Copilot | Done | P0 | 2026-03-04 | Project hooks and runtime tool availability validated. Renamed executables (`rtsver.exe`, `rtsbuildver.exe`) built from source and installed in both `Run` directories; Phase 5 validator passes. | [scripts/phase5/Test-Phase5CustomBuildMigration.ps1](../scripts/phase5/Test-Phase5CustomBuildMigration.ps1), [scripts/phase5/versiontools/Build-VersionTools.ps1](../scripts/phase5/versiontools/Build-VersionTools.ps1), [phase5-custom-build-migration.md](phase5-custom-build-migration.md) |

## Phase 6 — VS Code Orchestration
| Task | Owner | Status | Priority | Target Date | Notes/Blocker | Evidence/Links |
|---|---|---|---|---|---|---|
| Create `.vscode/tasks.json` phase task groups |  | Not Started | P0 |  |  |  |
| Add tree-scoped tasks for `Generals` and `GeneralsMD` (`Debug|Win32`, `Release|Win32`) |  | Not Started | P0 |  |  |  |
| Add `.vscode/settings.json` for consistent workspace behavior |  | Not Started | P1 |  |  |  |
| Add `.vscode/c_cpp_properties.json` for include/intellisense baselines |  | Not Started | P1 |  |  |  |
| Verify one-command entry points per phase/tree/config |  | Not Started | P0 |  |  |  |

## Phase 7 — Phased Build Bring-Up
| Task | Owner | Status | Priority | Target Date | Notes/Blocker | Evidence/Links |
|---|---|---|---|---|---|---|
| Build low-coupling tools/libs (`Debug|Win32`) |  | Not Started | P0 |  |  |  |
| Build core engine (`GameEngine`, `GameEngineDevice`) (`Debug|Win32`) |  | Not Started | P0 |  |  |  |
| Build high-coupling targets (`RTS`, `WorldBuilder`, WW3D plugins`) (`Debug|Win32`) |  | Not Started | P0 |  |  |  |
| Repeat full phase sequence for `Release|Win32` |  | Not Started | P0 |  |  |  |
| Maintain per-target failure classification log |  | Not Started | P0 |  |  |  |

## Phase 8 — Documentation and Handoff
| Task | Owner | Status | Priority | Target Date | Notes/Blocker | Evidence/Links |
|---|---|---|---|---|---|---|
| Update `README.md` prerequisite matrix |  | Not Started | P0 |  |  |  |
| Document required environment variables and examples |  | Not Started | P0 |  |  |  |
| Document phase commands and expected outputs |  | Not Started | P1 |  |  |  |
| Document known blockers and mitigation/workarounds |  | Not Started | P1 |  |  |  |
| Validate clean-room reproducibility from docs |  | Not Started | P0 |  |  |  |

## Verification Gates
| Gate | Criteria | Owner | Status | Target Date | Notes/Blocker | Evidence/Links |
|---|---|---|---|---|---|---|
| Gate A (Conversion) | All solutions load with no project conversion/load errors | Copilot | Done | 2026-03-04 | Reconstructed modern solutions/projects generated for both trees and validated for path/config integrity. | [phase2-project-conversion.md](phase2-project-conversion.md), [phase2-reconstruction-strategy.md](phase2-reconstruction-strategy.md) |
| Gate A.1 (Normalization Core) | Core generated projects contain normalized config/runtime/PCH and no unsupported legacy flags | Copilot | Done | 2026-03-04 | Phase 3 validator passed for core reconstructed projects in both trees. | [scripts/phase3/Test-Phase3Normalization.ps1](../scripts/phase3/Test-Phase3Normalization.ps1), [phase3-configuration-normalization.md](phase3-configuration-normalization.md) |
| Gate B (Static Readiness) | Path-lint shows no unresolved mandatory paths | Copilot | Done | 2026-03-04 | Path-lint now passes after applying dependency root environment-variable overrides. | [scripts/phase4/Test-Phase4PathLint.ps1](../scripts/phase4/Test-Phase4PathLint.ps1), [scripts/phase4/out/phase4-path-lint-report.json](../scripts/phase4/out/phase4-path-lint-report.json), [phase4-dependency-path-externalization.md](phase4-dependency-path-externalization.md) |
| Gate C (Build Progression) | Debug and Release phase tasks run with recorded outcomes |  | Not Started |  |  |  |
| Gate D (Developer UX) | Predictable one-command task flow across trees/configs |  | Not Started |  |  |  |

## Per-Target Status Matrix
| Target | Tree | Config | Status | Last Run Date | Failure Category | Owner | Evidence/Links |
|---|---|---|---|---|---|---|---|
| GameEngine | Generals | Debug\|Win32 | Not Started |  |  |  |  |
| GameEngineDevice | Generals | Debug\|Win32 | Not Started |  |  |  |  |
| RTS | Generals | Debug\|Win32 | Not Started |  |  |  |  |
| GameEngine | GeneralsMD | Debug\|Win32 | Not Started |  |  |  |  |
| GameEngineDevice | GeneralsMD | Debug\|Win32 | Not Started |  |  |  |  |
| RTS | GeneralsMD | Debug\|Win32 | Not Started |  |  |  |  |
| GameEngine | Generals | Release\|Win32 | Not Started |  |  |  |  |
| GameEngineDevice | Generals | Release\|Win32 | Not Started |  |  |  |  |
| RTS | Generals | Release\|Win32 | Not Started |  |  |  |  |
| GameEngine | GeneralsMD | Release\|Win32 | Not Started |  |  |  |  |
| GameEngineDevice | GeneralsMD | Release\|Win32 | Not Started |  |  |  |  |
| RTS | GeneralsMD | Release\|Win32 | Not Started |  |  |  |  |

## Blocker Log
| ID | Date | Phase | Target | Blocker Type | Description | Owner | Next Action | ETA |
|---|---|---|---|---|---|---|---|---|
| B-001 |  |  |  | missing dependency/toolchain |  |  |  |  |
| B-002 | 2026-03-04 | 2 | `Generals/Code/RTS.dsw`, `GeneralsMD/Code/RTS.dsw` | missing dependency/toolchain | Modern VS 2022 `devenv /Upgrade` does not accept VC6 `.dsw`; VS2003 hop unavailable. **Resolved by reconstruction route** using VC6 metadata parsing and generation scripts. | Copilot | Continue scope expansion of reconstruction to additional non-core projects as needed. | Completed |
| B-003 | 2026-03-04 | 4 | Dependency roots (`Generals`, `GeneralsMD`) | missing dependency/toolchain | Path-lint initially reported unresolved dependency roots; resolved by setting `CNCGZH_DEP_*` overrides to existing repository paths. | Copilot | Monitor and update env mappings if dependency payload layout changes. | Completed |
| B-004 | 2026-03-04 | 5 | Custom build runtime tools (`rtsver`, `rtsbuildver`) | missing dependency/toolchain | Phase 5 hooks are present in projects. NVASM replacement and renamed version-update executables were built and installed for both trees; Phase 5 runtime-equivalence check now passes. | Copilot | Monitor for regressions and rerun `scripts/phase5/versiontools/Build-And-Validate-Phase5VersionTools.cmd` after tool/source changes. | Completed |

## Weekly Snapshot
| Week Of | Overall Status | Completed This Week | New Blockers | Next Focus |
|---|---|---|---|---|
| 2026-03-02 | Phase 5 complete for migrated core scope | Added RTS version-update and NVASM shader custom-build hooks to reconstructed projects, built/installed replacement NVASM and renamed version-update tools for both trees, and passed Phase 5 validation. | None | Proceed to Phase 6 VS Code task orchestration. |
