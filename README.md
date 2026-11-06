# HMG64

A revamp of **HMG 3.6 (64-bit)**, the xBase GUI library for Windows built on Harbour and MinGW-w64. Upstream development stopped after the 3.6 release (10-05-2023).

- `AUDIT.md`: code audit of the 3.6 tree, findings and the revamp roadmap
- `TOOLCHAIN.md`: pinned Harbour and GCC versions, and how to get them (not stored in git)

## Quick start

```bat
rem after copying mingw64\ and harbour64\ in (see TOOLCHAIN.md)
hmgbuild all                      & rem check toolchain, build LIB-64, run tests
hmgbuild app SAMPLES\Basics\Hello_World\hello.hbp
```

`hmgbuild` is non-interactive and returns a non-zero exit code on failure. The original `build64.bat`, `BuildLib64.bat` and `BuildAllLib64.bat` are unchanged, because the IDE and the samples call them.

## Tests

`hmgbuild test` runs `tests\run.bat`:

- **smoke-\***: every project under `SAMPLES\Basics` must compile and link.
- **leakprobe-build**: the leak probe must compile.
- **leak**: regression test for AUDIT.md C1 (string conversion leak). It is listed in `tests\known-fail.txt` until Phase 1 fixes it.

## Status

| Phase | Scope | State |
|---|---|---|
| 0 | Baseline in git, single build entry point, smoke + regression tests | done |
| 1 | Fix leaks, buffer overflows, NULL crashes, XOR "crypt" | next |
| 2 | Toolchain refresh (GCC/UCRT, current Harbour and contrib libs), drop ANSI build, Win10+ target | planned |
| 3 | Replace `_HMG_SYSDATA` with an object model while keeping the command syntax | planned |

## License

HMG is distributed under the **GNU GPL v2 or later, with a linking exception**: applications linked with HMG are not covered by the GPL. See `license.txt` and `hfcl/license.txt`. Components carry their own notices (e.g. BosTaurus and the Unicode layer by Dr. Claudio Soto).
