# Phase 1 Baseline — Inventory and Dependency Snapshot

Date: 2026-03-04
Source plan: [plan-commandConquerGeneralsZeroHour.prompt.md](plan-commandConquerGeneralsZeroHour.prompt.md)

## Scope and Outcome

This baseline completes Phase 1 actions:
1. Enumerate all `.dsw/.dsp` roots and classify by tree/category.
2. Capture dependency order from `RTS.dsw` workspace graphs.
3. Record legacy custom/post-build command patterns for migration planning.

## Inventory Summary

- Total VC6 project/workspace files discovered: **106**
- `.dsw`: **20**
- `.dsp`: **86**

### By Tree / Category

| Extension | Tree | Category | Count |
|---|---|---|---:|
| .dsw | Generals | core | 1 |
| .dsw | Generals | tool | 6 |
| .dsw | Generals | plugin | 1 |
| .dsw | GeneralsMD | core | 1 |
| .dsw | GeneralsMD | tool | 8 |
| .dsw | GeneralsMD | plugin | 1 |
| .dsw | GeneralsMD | library | 2 |
| .dsp | Generals | core | 3 |
| .dsp | Generals | library | 11 |
| .dsp | Generals | tool | 20 |
| .dsp | Generals | plugin | 2 |
| .dsp | GeneralsMD | core | 3 |
| .dsp | GeneralsMD | library | 24 |
| .dsp | GeneralsMD | tool | 21 |
| .dsp | GeneralsMD | plugin | 2 |

## `.dsw` Root Inventory

### Generals

| Category | Workspace |
|---|---|
| core | [Generals/Code/RTS.dsw](../Generals/Code/RTS.dsw) |
| tool | [Generals/Code/Tools/Babylon/noxstring.dsw](../Generals/Code/Tools/Babylon/noxstring.dsw) |
| tool | [Generals/Code/Tools/mangler/mangler.dsw](../Generals/Code/Tools/mangler/mangler.dsw) |
| tool | [Generals/Code/Tools/ParticleEditor/ParticleEditor.dsw](../Generals/Code/Tools/ParticleEditor/ParticleEditor.dsw) |
| tool | [Generals/Code/Tools/textureCompress/textureCompress.dsw](../Generals/Code/Tools/textureCompress/textureCompress.dsw) |
| tool | [Generals/Code/Tools/timingTest/timingTest.dsw](../Generals/Code/Tools/timingTest/timingTest.dsw) |
| tool | [Generals/Code/Tools/wolSetup/wolSetup.dsw](../Generals/Code/Tools/wolSetup/wolSetup.dsw) |
| plugin | [Generals/Code/Tools/WW3D/max2w3d/max2w3d.dsw](../Generals/Code/Tools/WW3D/max2w3d/max2w3d.dsw) |

### GeneralsMD

| Category | Workspace |
|---|---|
| core | [GeneralsMD/Code/RTS.dsw](../GeneralsMD/Code/RTS.dsw) |
| library | [GeneralsMD/Code/Libraries/Source/debug/debug.dsw](../GeneralsMD/Code/Libraries/Source/debug/debug.dsw) |
| library | [GeneralsMD/Code/Libraries/Source/profile/profile.dsw](../GeneralsMD/Code/Libraries/Source/profile/profile.dsw) |
| tool | [GeneralsMD/Code/Tools/Autorun/Autorun.dsw](../GeneralsMD/Code/Tools/Autorun/Autorun.dsw) |
| tool | [GeneralsMD/Code/Tools/Babylon/Babylon.dsw](../GeneralsMD/Code/Tools/Babylon/Babylon.dsw) |
| tool | [GeneralsMD/Code/Tools/DebugWindow/DebugWindow.dsw](../GeneralsMD/Code/Tools/DebugWindow/DebugWindow.dsw) |
| tool | [GeneralsMD/Code/Tools/mangler/mangler.dsw](../GeneralsMD/Code/Tools/mangler/mangler.dsw) |
| tool | [GeneralsMD/Code/Tools/ParticleEditor/ParticleEditor.dsw](../GeneralsMD/Code/Tools/ParticleEditor/ParticleEditor.dsw) |
| tool | [GeneralsMD/Code/Tools/textureCompress/textureCompress.dsw](../GeneralsMD/Code/Tools/textureCompress/textureCompress.dsw) |
| tool | [GeneralsMD/Code/Tools/timingTest/timingTest.dsw](../GeneralsMD/Code/Tools/timingTest/timingTest.dsw) |
| tool | [GeneralsMD/Code/Tools/wolSetup/wolSetup.dsw](../GeneralsMD/Code/Tools/wolSetup/wolSetup.dsw) |
| plugin | [GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsw](../GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsw) |

## `.dsp` Inventory by Tree / Category

### Generals — core (3)

- [Generals/Code/GameEngine/GameEngine.dsp](../Generals/Code/GameEngine/GameEngine.dsp)
- [Generals/Code/GameEngineDevice/GameEngineDevice.dsp](../Generals/Code/GameEngineDevice/GameEngineDevice.dsp)
- [Generals/Code/RTS.dsp](../Generals/Code/RTS.dsp)

### Generals — library (11)

- [Generals/Code/Libraries/Source/Compression/Compression.dsp](../Generals/Code/Libraries/Source/Compression/Compression.dsp)
- [Generals/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp](../Generals/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp)
- [Generals/Code/Libraries/Source/WPAudio/WPAudio.dsp](../Generals/Code/Libraries/Source/WPAudio/WPAudio.dsp)
- [Generals/Code/Libraries/Source/WWVegas/WW3D2/ww3d2.dsp](../Generals/Code/Libraries/Source/WWVegas/WW3D2/ww3d2.dsp)
- [Generals/Code/Libraries/Source/WWVegas/WWAudio/WWAudio.dsp](../Generals/Code/Libraries/Source/WWVegas/WWAudio/WWAudio.dsp)
- [Generals/Code/Libraries/Source/WWVegas/WWDebug/wwdebug.dsp](../Generals/Code/Libraries/Source/WWVegas/WWDebug/wwdebug.dsp)
- [Generals/Code/Libraries/Source/WWVegas/WWDownload/WWDownload.dsp](../Generals/Code/Libraries/Source/WWVegas/WWDownload/WWDownload.dsp)
- [Generals/Code/Libraries/Source/WWVegas/WWLib/wwlib.dsp](../Generals/Code/Libraries/Source/WWVegas/WWLib/wwlib.dsp)
- [Generals/Code/Libraries/Source/WWVegas/WWMath/wwmath.dsp](../Generals/Code/Libraries/Source/WWVegas/WWMath/wwmath.dsp)
- [Generals/Code/Libraries/Source/WWVegas/WWSaveLoad/wwsaveload.dsp](../Generals/Code/Libraries/Source/WWVegas/WWSaveLoad/wwsaveload.dsp)
- [Generals/Code/Libraries/Source/WWVegas/Wwutil/wwutil.dsp](../Generals/Code/Libraries/Source/WWVegas/Wwutil/wwutil.dsp)

### Generals — tool (20)

- [Generals/Code/Tools/Autorun/Autorun English.dsp](../Generals/Code/Tools/Autorun/Autorun%20English.dsp)
- [Generals/Code/Tools/Babylon/noxstring.dsp](../Generals/Code/Tools/Babylon/noxstring.dsp)
- [Generals/Code/Tools/buildVersionUpdate/buildVersionUpdate.dsp](../Generals/Code/Tools/buildVersionUpdate/buildVersionUpdate.dsp)
- [Generals/Code/Tools/Compress/Compress.dsp](../Generals/Code/Tools/Compress/Compress.dsp)
- [Generals/Code/Tools/CRCDiff/CRCDiff.dsp](../Generals/Code/Tools/CRCDiff/CRCDiff.dsp)
- [Generals/Code/Tools/DebugWindow/DebugWindow.dsp](../Generals/Code/Tools/DebugWindow/DebugWindow.dsp)
- [Generals/Code/Tools/GUIEdit/GUIEdit.dsp](../Generals/Code/Tools/GUIEdit/GUIEdit.dsp)
- [Generals/Code/Tools/ImagePacker/ImagePacker.dsp](../Generals/Code/Tools/ImagePacker/ImagePacker.dsp)
- [Generals/Code/Tools/Launcher/DatGen/DatGen.dsp](../Generals/Code/Tools/Launcher/DatGen/DatGen.dsp)
- [Generals/Code/Tools/Launcher/launcher.dsp](../Generals/Code/Tools/Launcher/launcher.dsp)
- [Generals/Code/Tools/mangler/mangler.dsp](../Generals/Code/Tools/mangler/mangler.dsp)
- [Generals/Code/Tools/mangler/manglertest.dsp](../Generals/Code/Tools/mangler/manglertest.dsp)
- [Generals/Code/Tools/MapCacheBuilder/MapCacheBuilder.dsp](../Generals/Code/Tools/MapCacheBuilder/MapCacheBuilder.dsp)
- [Generals/Code/Tools/ParticleEditor/ParticleEditor.dsp](../Generals/Code/Tools/ParticleEditor/ParticleEditor.dsp)
- [Generals/Code/Tools/PATCHGET/patchgrabber.dsp](../Generals/Code/Tools/PATCHGET/patchgrabber.dsp)
- [Generals/Code/Tools/textureCompress/textureCompress.dsp](../Generals/Code/Tools/textureCompress/textureCompress.dsp)
- [Generals/Code/Tools/timingTest/timingTest.dsp](../Generals/Code/Tools/timingTest/timingTest.dsp)
- [Generals/Code/Tools/versionUpdate/versionUpdate.dsp](../Generals/Code/Tools/versionUpdate/versionUpdate.dsp)
- [Generals/Code/Tools/wolSetup/wolSetup.dsp](../Generals/Code/Tools/wolSetup/wolSetup.dsp)
- [Generals/Code/Tools/WorldBuilder/WorldBuilder.dsp](../Generals/Code/Tools/WorldBuilder/WorldBuilder.dsp)

### Generals — plugin (2)

- [Generals/Code/Tools/WW3D/max2w3d/max2w3d.dsp](../Generals/Code/Tools/WW3D/max2w3d/max2w3d.dsp)
- [Generals/Code/Tools/WW3D/pluglib/pluglib.dsp](../Generals/Code/Tools/WW3D/pluglib/pluglib.dsp)

### GeneralsMD — core (3)

- [GeneralsMD/Code/GameEngine/GameEngine.dsp](../GeneralsMD/Code/GameEngine/GameEngine.dsp)
- [GeneralsMD/Code/GameEngineDevice/GameEngineDevice.dsp](../GeneralsMD/Code/GameEngineDevice/GameEngineDevice.dsp)
- [GeneralsMD/Code/RTS.dsp](../GeneralsMD/Code/RTS.dsp)

### GeneralsMD — library (24)

- [GeneralsMD/Code/Libraries/Source/Benchmark/Benchmark.dsp](../GeneralsMD/Code/Libraries/Source/Benchmark/Benchmark.dsp)
- [GeneralsMD/Code/Libraries/Source/Compression/Compression.dsp](../GeneralsMD/Code/Libraries/Source/Compression/Compression.dsp)
- [GeneralsMD/Code/Libraries/Source/debug/debug.dsp](../GeneralsMD/Code/Libraries/Source/debug/debug.dsp)
- [GeneralsMD/Code/Libraries/Source/debug/debug_dlg/debug_dlg.dsp](../GeneralsMD/Code/Libraries/Source/debug/debug_dlg/debug_dlg.dsp)
- [GeneralsMD/Code/Libraries/Source/debug/netserv/netserv.dsp](../GeneralsMD/Code/Libraries/Source/debug/netserv/netserv.dsp)
- [GeneralsMD/Code/Libraries/Source/debug/test1/test1.dsp](../GeneralsMD/Code/Libraries/Source/debug/test1/test1.dsp)
- [GeneralsMD/Code/Libraries/Source/debug/test2/test2.dsp](../GeneralsMD/Code/Libraries/Source/debug/test2/test2.dsp)
- [GeneralsMD/Code/Libraries/Source/debug/test3/test3.dsp](../GeneralsMD/Code/Libraries/Source/debug/test3/test3.dsp)
- [GeneralsMD/Code/Libraries/Source/debug/test4/test4.dsp](../GeneralsMD/Code/Libraries/Source/debug/test4/test4.dsp)
- [GeneralsMD/Code/Libraries/Source/debug/test5/test5.dsp](../GeneralsMD/Code/Libraries/Source/debug/test5/test5.dsp)
- [GeneralsMD/Code/Libraries/Source/debug/test6/test6.dsp](../GeneralsMD/Code/Libraries/Source/debug/test6/test6.dsp)
- [GeneralsMD/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp](../GeneralsMD/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp)
- [GeneralsMD/Code/Libraries/Source/profile/profile.dsp](../GeneralsMD/Code/Libraries/Source/profile/profile.dsp)
- [GeneralsMD/Code/Libraries/Source/profile/test1/test1.dsp](../GeneralsMD/Code/Libraries/Source/profile/test1/test1.dsp)
- [GeneralsMD/Code/Libraries/Source/WPAudio/WPAudio.dsp](../GeneralsMD/Code/Libraries/Source/WPAudio/WPAudio.dsp)
- [GeneralsMD/Code/Libraries/Source/WWVegas/WW3D2/ww3d2.dsp](../GeneralsMD/Code/Libraries/Source/WWVegas/WW3D2/ww3d2.dsp)
- [GeneralsMD/Code/Libraries/Source/WWVegas/WWAudio/WWAudio.dsp](../GeneralsMD/Code/Libraries/Source/WWVegas/WWAudio/WWAudio.dsp)
- [GeneralsMD/Code/Libraries/Source/WWVegas/WWDebug/wwdebug.dsp](../GeneralsMD/Code/Libraries/Source/WWVegas/WWDebug/wwdebug.dsp)
- [GeneralsMD/Code/Libraries/Source/WWVegas/WWDownload/WWDownload.dsp](../GeneralsMD/Code/Libraries/Source/WWVegas/WWDownload/WWDownload.dsp)
- [GeneralsMD/Code/Libraries/Source/WWVegas/WWLib/wwlib.dsp](../GeneralsMD/Code/Libraries/Source/WWVegas/WWLib/wwlib.dsp)
- [GeneralsMD/Code/Libraries/Source/WWVegas/WWMath/wwmath.dsp](../GeneralsMD/Code/Libraries/Source/WWVegas/WWMath/wwmath.dsp)
- [GeneralsMD/Code/Libraries/Source/WWVegas/WWSaveLoad/wwsaveload.dsp](../GeneralsMD/Code/Libraries/Source/WWVegas/WWSaveLoad/wwsaveload.dsp)
- [GeneralsMD/Code/Libraries/Source/WWVegas/wwshade/wwshade.dsp](../GeneralsMD/Code/Libraries/Source/WWVegas/wwshade/wwshade.dsp)
- [GeneralsMD/Code/Libraries/Source/WWVegas/Wwutil/wwutil.dsp](../GeneralsMD/Code/Libraries/Source/WWVegas/Wwutil/wwutil.dsp)

### GeneralsMD — tool (21)

- [GeneralsMD/Code/Tools/assetcull/assetcull.dsp](../GeneralsMD/Code/Tools/assetcull/assetcull.dsp)
- [GeneralsMD/Code/Tools/Autorun/Autorun.dsp](../GeneralsMD/Code/Tools/Autorun/Autorun.dsp)
- [GeneralsMD/Code/Tools/Babylon/Babylon.dsp](../GeneralsMD/Code/Tools/Babylon/Babylon.dsp)
- [GeneralsMD/Code/Tools/buildVersionUpdate/buildVersionUpdate.dsp](../GeneralsMD/Code/Tools/buildVersionUpdate/buildVersionUpdate.dsp)
- [GeneralsMD/Code/Tools/Compress/Compress.dsp](../GeneralsMD/Code/Tools/Compress/Compress.dsp)
- [GeneralsMD/Code/Tools/CRCDiff/CRCDiff.dsp](../GeneralsMD/Code/Tools/CRCDiff/CRCDiff.dsp)
- [GeneralsMD/Code/Tools/DebugWindow/DebugWindow.dsp](../GeneralsMD/Code/Tools/DebugWindow/DebugWindow.dsp)
- [GeneralsMD/Code/Tools/GUIEdit/GUIEdit.dsp](../GeneralsMD/Code/Tools/GUIEdit/GUIEdit.dsp)
- [GeneralsMD/Code/Tools/ImagePacker/ImagePacker.dsp](../GeneralsMD/Code/Tools/ImagePacker/ImagePacker.dsp)
- [GeneralsMD/Code/Tools/Launcher/DatGen/DatGen.dsp](../GeneralsMD/Code/Tools/Launcher/DatGen/DatGen.dsp)
- [GeneralsMD/Code/Tools/Launcher/launcher.dsp](../GeneralsMD/Code/Tools/Launcher/launcher.dsp)
- [GeneralsMD/Code/Tools/mangler/mangler.dsp](../GeneralsMD/Code/Tools/mangler/mangler.dsp)
- [GeneralsMD/Code/Tools/mangler/manglertest.dsp](../GeneralsMD/Code/Tools/mangler/manglertest.dsp)
- [GeneralsMD/Code/Tools/MapCacheBuilder/MapCacheBuilder.dsp](../GeneralsMD/Code/Tools/MapCacheBuilder/MapCacheBuilder.dsp)
- [GeneralsMD/Code/Tools/ParticleEditor/ParticleEditor.dsp](../GeneralsMD/Code/Tools/ParticleEditor/ParticleEditor.dsp)
- [GeneralsMD/Code/Tools/PATCHGET/patchgrabber.dsp](../GeneralsMD/Code/Tools/PATCHGET/patchgrabber.dsp)
- [GeneralsMD/Code/Tools/textureCompress/textureCompress.dsp](../GeneralsMD/Code/Tools/textureCompress/textureCompress.dsp)
- [GeneralsMD/Code/Tools/timingTest/timingTest.dsp](../GeneralsMD/Code/Tools/timingTest/timingTest.dsp)
- [GeneralsMD/Code/Tools/versionUpdate/versionUpdate.dsp](../GeneralsMD/Code/Tools/versionUpdate/versionUpdate.dsp)
- [GeneralsMD/Code/Tools/wolSetup/wolSetup.dsp](../GeneralsMD/Code/Tools/wolSetup/wolSetup.dsp)
- [GeneralsMD/Code/Tools/WorldBuilder/WorldBuilder.dsp](../GeneralsMD/Code/Tools/WorldBuilder/WorldBuilder.dsp)

### GeneralsMD — plugin (2)

- [GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsp](../GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsp)
- [GeneralsMD/Code/Tools/WW3D/pluglib/pluglib.dsp](../GeneralsMD/Code/Tools/WW3D/pluglib/pluglib.dsp)

## Workspace Dependency Order (`RTS`)

### Generals `RTS` dependency chain

1. `GameEngine`
2. `GameEngineDevice`
3. `wwmath`
4. `ww3d2`
5. `wwdebug`
6. `wwlib`
7. `wwutil`
8. `wwsaveload`
9. `GameSpyHTTP`
10. `GameSpyPatching`
11. `WWDownload`
12. `EABrowserDispatch`
13. `GameSpyPeer`
14. `GameSpyPresence`
15. `GameSpyStats`
16. `Benchmark`
17. `versionUpdate`
18. `launcher`
19. `DebugWindow`
20. `ParticleEditor`
21. `Compression`
22. `buildVersionUpdate`

Source: [Generals/Code/RTS.dsw](../Generals/Code/RTS.dsw)

### GeneralsMD `RTS` dependency chain

1. `GameEngine`
2. `GameEngineDevice`
3. `wwmath`
4. `ww3d2`
5. `wwdebug`
6. `wwlib`
7. `wwutil`
8. `wwsaveload`
9. `GameSpyHTTP`
10. `GameSpyPatching`
11. `WWDownload`
12. `EABrowserDispatch`
13. `GameSpyPeer`
14. `GameSpyPresence`
15. `GameSpyStats`
16. `Benchmark`
17. `wwshade`
18. `profile`
19. `debug`
20. `buildVersionUpdate`
21. `versionUpdate`
22. `launcher`

Source: [GeneralsMD/Code/RTS.dsw](../GeneralsMD/Code/RTS.dsw)

## High-Coupling Late-Phase Targets

Marked for late-phase bring-up in Phase 7:

- `RTS` application targets
  - [Generals/Code/RTS.dsp](../Generals/Code/RTS.dsp)
  - [GeneralsMD/Code/RTS.dsp](../GeneralsMD/Code/RTS.dsp)
- `WorldBuilder`
  - [Generals/Code/Tools/WorldBuilder/WorldBuilder.dsp](../Generals/Code/Tools/WorldBuilder/WorldBuilder.dsp)
  - [GeneralsMD/Code/Tools/WorldBuilder/WorldBuilder.dsp](../GeneralsMD/Code/Tools/WorldBuilder/WorldBuilder.dsp)
- WW3D plugins
  - [Generals/Code/Tools/WW3D/max2w3d/max2w3d.dsp](../Generals/Code/Tools/WW3D/max2w3d/max2w3d.dsp)
  - [Generals/Code/Tools/WW3D/pluglib/pluglib.dsp](../Generals/Code/Tools/WW3D/pluglib/pluglib.dsp)
  - [GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsp](../GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsp)
  - [GeneralsMD/Code/Tools/WW3D/pluglib/pluglib.dsp](../GeneralsMD/Code/Tools/WW3D/pluglib/pluglib.dsp)

## Legacy Custom/Post-Build Command Baseline

Discovery snapshot:

- Unique command patterns found: **41**
- Files containing custom/post-build directives: **17**

### High-impact command families to migrate first

1. **Version stamping / build-number bump**
   - Command forms:
     - `$(TargetDir)\versionUpdate.exe $(InputPath)`
     - `$(TargetDir)\buildVersionUpdate.exe .\Main\buildVersion.h`
   - Sources:
     - [Generals/Code/RTS.dsp](../Generals/Code/RTS.dsp)
     - [GeneralsMD/Code/RTS.dsp](../GeneralsMD/Code/RTS.dsp)

2. **NVASM shader compilation**
   - Command form:
     - `..\tools\nvasm\nvasm -d $(InputPath) <output .pso/.vso>`
   - Representative sources:
     - [Generals/Code/GameEngineDevice/GameEngineDevice.dsp](../Generals/Code/GameEngineDevice/GameEngineDevice.dsp)
     - [GeneralsMD/Code/GameEngineDevice/GameEngineDevice.dsp](../GeneralsMD/Code/GameEngineDevice/GameEngineDevice.dsp)

3. **Tool post-build copy/batch steps**
   - Command forms:
     - `PostBuild_Cmds=post-build-release.bat`
     - `PostBuild_Cmds=copy Release\PatchGrabber.exe ..\..\..\Run\patchget.dat`
     - `PostBuild_Cmds=del release\Babylon.obj`
   - Representative sources:
     - [GeneralsMD/Code/Tools/ParticleEditor/ParticleEditor.dsp](../GeneralsMD/Code/Tools/ParticleEditor/ParticleEditor.dsp)
     - [GeneralsMD/Code/Tools/PATCHGET/patchgrabber.dsp](../GeneralsMD/Code/Tools/PATCHGET/patchgrabber.dsp)
     - [GeneralsMD/Code/Tools/Babylon/Babylon.dsp](../GeneralsMD/Code/Tools/Babylon/Babylon.dsp)
     - [Generals/Code/Tools/Babylon/noxstring.dsp](../Generals/Code/Tools/Babylon/noxstring.dsp)

4. **MIDL generation for browser dispatch interfaces**
   - Command form:
     - `midl.exe /out ..\..\Include\EABrowserDispatch ...`
   - Sources:
     - [Generals/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp](../Generals/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp)
     - [GeneralsMD/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp](../GeneralsMD/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp)

5. **WW3D plugin deployment copy to MAX plugin folders**
   - Command forms:
     - `Copy $(TargetPath) "$(MAXDIR)\Plugins\Westwood\$(TargetName).dle"`
     - `Copy $(TargetPath) D:\3dsmax4\Plugins\Westwood\$(TargetName).dle`
   - Source:
     - [GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsp](../GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsp)

### Files with custom/post-build entries (17)

- [Generals/Code/GameEngineDevice/GameEngineDevice.dsp](../Generals/Code/GameEngineDevice/GameEngineDevice.dsp)
- [Generals/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp](../Generals/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp)
- [Generals/Code/Libraries/Source/WPAudio/WPAudio.dsp](../Generals/Code/Libraries/Source/WPAudio/WPAudio.dsp)
- [Generals/Code/RTS.dsp](../Generals/Code/RTS.dsp)
- [Generals/Code/Tools/Babylon/noxstring.dsp](../Generals/Code/Tools/Babylon/noxstring.dsp)
- [Generals/Code/Tools/PATCHGET/patchgrabber.dsp](../Generals/Code/Tools/PATCHGET/patchgrabber.dsp)
- [GeneralsMD/Code/GameEngineDevice/GameEngineDevice.dsp](../GeneralsMD/Code/GameEngineDevice/GameEngineDevice.dsp)
- [GeneralsMD/Code/Libraries/Source/debug/debug.dsp](../GeneralsMD/Code/Libraries/Source/debug/debug.dsp)
- [GeneralsMD/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp](../GeneralsMD/Code/Libraries/Source/EABrowserDispatch/EABrowserDispatch.dsp)
- [GeneralsMD/Code/Libraries/Source/profile/profile.dsp](../GeneralsMD/Code/Libraries/Source/profile/profile.dsp)
- [GeneralsMD/Code/Libraries/Source/WPAudio/WPAudio.dsp](../GeneralsMD/Code/Libraries/Source/WPAudio/WPAudio.dsp)
- [GeneralsMD/Code/Libraries/Source/WWVegas/wwshade/wwshade.dsp](../GeneralsMD/Code/Libraries/Source/WWVegas/wwshade/wwshade.dsp)
- [GeneralsMD/Code/RTS.dsp](../GeneralsMD/Code/RTS.dsp)
- [GeneralsMD/Code/Tools/Babylon/Babylon.dsp](../GeneralsMD/Code/Tools/Babylon/Babylon.dsp)
- [GeneralsMD/Code/Tools/ParticleEditor/ParticleEditor.dsp](../GeneralsMD/Code/Tools/ParticleEditor/ParticleEditor.dsp)
- [GeneralsMD/Code/Tools/PATCHGET/patchgrabber.dsp](../GeneralsMD/Code/Tools/PATCHGET/patchgrabber.dsp)
- [GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsp](../GeneralsMD/Code/Tools/WW3D/max2w3d/max2w3d.dsp)
