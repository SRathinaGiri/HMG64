# Toolchain (pinned)

The `mingw64\` and `harbour64\` folders are **not stored in git**. `tools\setup-toolchain.ps1` builds them reproducibly from the pins below and links them into the tree as directory junctions. `hmgbuild check` warns if your copy differs.

Pins as at 06-11-2026. They live in three places that must change together: this file, `tools\setup-toolchain.ps1` and the `PIN_*` block in `hmgbuild.bat`.

| Tool | Pinned version | Source |
|---|---|---|
| GCC (MinGW-w64) | **16.2.0**, WinLibs r3, `x86_64-ucrt-posix-seh`, mingw-w64 14.0.0 | `brechtsanders/winlibs_mingw` release `16.2.0posix-23.1.3-14.0.0-ucrt-r3` |
| GNU binutils | 2.47 (bundled with the GCC above) | |
| Harbour | **3.2.1dev r2610242111**, commit `694428e1c12f726675b19324d62167fa77d68185` (2026-10-24) | `harbour/core`, built from source with the GCC above; C flags `-DHB_GUI -DHB_NO_TRACE -DHB_MEMO_SAFELOCK`, same as HMG 3.6 |

Bundled C libraries, from the Harbour source at that commit: SQLite 3.53.4, zlib 1.3.1, libpng 1.6.50, libHaru 2.3.0RC2, PCRE 8.x, minizip. **libcurl is not included**: `hbcurl` is only built when a libcurl SDK is present, and HMG does not link it by default.

Runtime: executables now link against the **UCRT** (`api-ms-win-crt-*.dll`), which is part of Windows 10 and later. `libgcc` and `winpthread` are linked statically, as before (see `build64.bat`).

## Set up on a fresh clone

```bat
powershell -ExecutionPolicy Bypass -File tools\setup-toolchain.ps1
hmgbuild matrix
```

The script needs Git for Windows and an internet connection (~263 MB GCC download plus a ~143 MB Harbour clone). The Harbour build takes about 7 minutes. Everything goes into a `hmg-toolchain` folder next to the HMG tree (`-ToolchainDir` overrides this). It:

1. downloads the GCC zip and **verifies its SHA-256** (it stops on a mismatch);
2. extracts it and checks the GCC version;
3. clones `harbour/core` and checks out the pinned commit;
4. builds and installs Harbour, then runs Harbour's own `hbtest` (it stops on any failure);
5. links `mingw64\` and `harbour64\` into the HMG tree. It never deletes a real folder: if the old HMG 3.6 toolchain is there, it tells you to rename it.

Re-running is safe; completed steps are skipped (`-Rebuild` forces a new Harbour build).

## Checksums

```
3c69305081e4a647144339a936244fcf7d3d9e558319e1ad7be2cd2886d4b6a1  winlibs-x86_64-posix-seh-gcc-16.2.0-mingw-w64ucrt-14.0.0-r3.zip
7e7ed95e0333c76afa593cbb732a4f22c37a9420b091a66b0ebb27077bf3a9b4  mingw64/bin/gcc.exe
10f5a42bf947f20cd635920f82b8dbd57472b0cfcf9b43b26ce34fec8585311e  mingw64/bin/ld.exe
e0e5eb6a69bb706d9d0b7360d64ab7f35ca3ee84abc938b4f29618ee571d4fbc  mingw64/bin/windres.exe
```

`harbour.exe`/`hbmk2.exe` are built locally and embed the build date, so their hashes differ on every build. Harbour is pinned by commit and checked by its reported revision instead.

## Previous toolchain (HMG 3.6 as shipped)

Harbour 3.2.0dev r2304211101 with GCC 13.1.0 (WinLibs, msvcrt, mcf threads). The Phase 1 code builds and passes all tests on both toolchains.
