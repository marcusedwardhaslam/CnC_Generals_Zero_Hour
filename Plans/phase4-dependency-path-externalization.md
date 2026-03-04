# Phase 4 — Dependency and Path Externalization Log

Date: 2026-03-04  
Owner: Copilot  
Source plan: [plan-commandConquerGeneralsZeroHour.prompt.md](plan-commandConquerGeneralsZeroHour.prompt.md)

## Deliverables Implemented

- Central dependency path map:
  - [scripts/phase4/dependency-paths.json](../scripts/phase4/dependency-paths.json)
- Path-lint preflight script:
  - [scripts/phase4/Test-Phase4PathLint.ps1](../scripts/phase4/Test-Phase4PathLint.ps1)
- Shared environment-variable props baseline:
  - [build/DependencyRoots.props](../build/DependencyRoots.props)

## Path-Lint Result

Command executed:

```powershell
.\scripts\phase4\Test-Phase4PathLint.ps1
```

Report output:

- [scripts/phase4/out/phase4-path-lint-report.json](../scripts/phase4/out/phase4-path-lint-report.json)

Initial run surfaced unresolved roots. Gate B was then cleared by setting environment overrides to valid existing repository paths.

Applied environment overrides:

- `CNCGZH_DEP_DXSDK = D:\Software_Projects\CnC_Generals_Zero_Hour\Generals\Code\Libraries\DX90SDK`
- `CNCGZH_DEP_STLPORT = D:\Software_Projects\CnC_Generals_Zero_Hour\Generals\Code\Libraries\STLport-4.5.3`
- `CNCGZH_DEP_MAX4SDK = D:\Software_Projects\CnC_Generals_Zero_Hour\Generals\Code\Libraries\max4sdk`
- `CNCGZH_DEP_SAFEDISK_COMMON = D:\Software_Projects\CnC_Generals_Zero_Hour\Generals\Code\GameEngine\Include\Common\SafeDisk`
- `CNCGZH_DEP_ASIMP3 = D:\Software_Projects\CnC_Generals_Zero_Hour\Generals\Code\Libraries\Source\WPAudio`

Final run result:

- `scripts/phase4/Test-Phase4PathLint.ps1` passes (`ok-env`/`ok-repo` only, no unresolved mandatory paths).

## Externalization Model

Each dependency can be satisfied either by:

1. Expected repository-relative path under each tree `Code` root, or
2. Environment variable override (`CNCGZH_DEP_*`).

If the expected path is missing and no valid env-var target exists, path-lint fails with actionable output.

## Environment Variables

Configured variable set:

- `CNCGZH_DEP_DXSDK`
- `CNCGZH_DEP_STLPORT`
- `CNCGZH_DEP_MAX4SDK`
- `CNCGZH_DEP_NVASM`
- `CNCGZH_DEP_BENCHMARK`
- `CNCGZH_DEP_MILES6`
- `CNCGZH_DEP_BINK`
- `CNCGZH_DEP_SAFEDISK_COMMON`
- `CNCGZH_DEP_SAFEDISK_LAUNCHER`
- `CNCGZH_DEP_ASIMP3`
- `CNCGZH_DEP_GAMESPY`
- `CNCGZH_DEP_ZLIB`
- `CNCGZH_DEP_LZH_SRC`
- `CNCGZH_DEP_LZH_HDR`

## Next Action

Proceed to Phase 5 custom build-step migration with Gate B satisfied.