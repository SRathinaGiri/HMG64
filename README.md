# HMG64

A revamp of **HMG 3.6 (64-bit)**, the xBase GUI library for Windows built on Harbour and MinGW-w64. Upstream development stopped after the 3.6 release (10-05-2023).

- `AUDIT.md`: code audit of the 3.6 tree, findings and the revamp roadmap
- `PHASE4-DESIGN.md`: Phase 4 design (WebView2 control first)
- `HMGWEB-DESIGN.md`: early notes for HMG Web, a separate future product (HMG forms in the browser, Windows and Linux); not part of HMG5
- `TOOLCHAIN.md`: pinned Harbour and GCC versions, and how to get them (not stored in git)

## Quick start

```bat
powershell -ExecutionPolicy Bypass -File tools\setup-toolchain.ps1   & rem one-off: GCC + Harbour (see TOOLCHAIN.md)
hmgbuild all                      & rem check toolchain, build LIB-64 (UNICODE), run tests
hmgbuild lib ansi                 & rem ANSI-only library instead (as BuildLib64.bat /ansi)
hmgbuild matrix                   & rem build + test ANSI, then UNICODE
hmgbuild app SAMPLES\Basics\Hello_World\hello.hbp
```

Both library modes are supported and tested: **UNICODE** (default) and **ANSI-only**, which some members still use. `hmgbuild` is non-interactive and returns a non-zero exit code on failure. The original `build64.bat`, `BuildLib64.bat` and `BuildAllLib64.bat` are unchanged, because the IDE and the samples call them.

## HMG5 bundle (for HMG users)

**HMG5** is the name of the revamped HMG 3 line. It ships as one folder that works out of the box: HMG, a trimmed GCC (compiler and linker only, ~546 MB instead of 947 MB) and Harbour. Users only need `build64.bat` and the IDE, as in HMG 3.6.

```bat
powershell -ExecutionPolicy Bypass -File tools\make-dist.ps1 -Dest D:\HMG5   & rem assemble + test the folder
iscc dist\HMG5.iss                                                          & rem optional: HMG5-Setup.exe (Inno Setup 6)
```

`make-dist.ps1` refuses a destination that exists or sits inside the repo, and runs `hmgbuild test` inside the new folder. `dist\HMG5-README.txt` is the user-facing readme.

## Tests

`hmgbuild test` runs `tests\run.bat`:

- **smoke-\***: every project under `SAMPLES\Basics` must compile and link.
- **leakprobe-build** / **leak**: regression test for AUDIT.md C1 (string conversion leak). It must show no memory growth.
- **unit-\***: every `tests\unit\*.hbp` is built as a console app and must exit 0. `strings` checks conversion correctness (ASCII, 1 MB, 4 threads; plus accented, Tamil and ₹ in the UNICODE build) and the C3 no-crash cases.

## Status

| Phase | Scope | State |
|---|---|---|
| 0 | Baseline in git, single build entry point, smoke + regression tests | done |
| 1 | Fix leaks, buffer overflows, NULL crashes, DLL hijacking, temp-file race; deprecate XOR "crypt" | done (see AUDIT.md §6) |
| 2a | Toolchain refresh: GCC 16.2 / UCRT, Harbour 3.2.1 from source, current bundled libs; reproducible setup script; ANSI + UNICODE build matrix | done |
| HMG5 | Out-of-the-box folder (`tools\make-dist.ps1`) and Setup script (`dist\HMG5.iss`); version string "HMG 5.0 Test" | done (Setup.exe tested: silent install, build, uninstall) |
| 2b | Windows 10+ target (`_WIN32_WINNT`), long-path manifest, libHaru 2.3 headers (PerMonitorV2 moved to Phase 4; UTF-8 code page dropped: it breaks ANSI mode) | done |
| 3 | Name, index and wrap `_HMG_SYSDATA` (layout frozen), object API, event dispatch - see PHASE3-DESIGN.md | done (S1-S5) |
| 4 | Modern features: WebView2 control, per-monitor DPI, dark mode, IFileDialog, PDF/print, IDE - see PHASE4-DESIGN.md | in progress (branch `phase4`): WebView2 control, per-monitor DPI, dark mode, IFileDialog, PDF engine and CHART control (ECharts) done; IDE revamp in progress |

## License

HMG is distributed under the **GNU GPL v2 or later, with a linking exception**: applications linked with HMG are not covered by the GPL. See `license.txt` and `hfcl/license.txt`. Components carry their own notices (e.g. BosTaurus and the Unicode layer by Dr. Claudio Soto).
