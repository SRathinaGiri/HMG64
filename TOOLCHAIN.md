# Toolchain (pinned)

The `mingw64\` (646 MB) and `harbour64\` (23 MB) folders are **not stored in git**. This file records the exact versions this tree is built and tested with. `hmgbuild check` warns if your copy differs.

| Tool | Version | Notes |
|---|---|---|
| Harbour | 3.2.0dev **r2304211101** (ChangeLog 2023-04-21, ID `f38464361cc8`) | built with `-gc0`, C flags `-DHB_GUI -DHB_NO_TRACE -DHB_MEMO_SAFELOCK` |
| GCC (MinGW-w64) | **13.1.0**, WinLibs build by Brecht Sanders, `x86_64-msvcrt-mcf-seh` | msvcrt runtime, mcfgthread thread model, SEH |
| GNU binutils | 2.40 | `ld`, `windres` |

Bundled C libraries (inside `harbour64\lib\win\mingw64`): SQLite 3.41.2, libpng 1.6.39, zlib 1.2.13, libcurl 7.75.0, libHaru 2.2.1. These are outdated; see AUDIT.md H2. They get upgraded in Phase 2.

## SHA-256 of the reference binaries

```
55230d2660b33e3f9afcbb3db10937a60f19ab996127b00efd9989b657c46295  harbour64/bin/harbour.exe
0c4c776a8b798e5c7d4a79eff7a78aa534154b2fea77773114fb5c98674c6a82  harbour64/bin/hbmk2.exe
da5d15c0f98a82121b3f3a53b8c2239da302f9d3d5c77523d05e69d773a07cb0  mingw64/bin/gcc.exe
0986e698fe45e13ab2c29cfde71258ad2f33d96474c2db867e2e63ec6db4e339  mingw64/bin/ld.exe
f75e9229cfb0d1412f531acda0a398d801c53a773f76db7f02f5a0ca843ebc3a  mingw64/bin/windres.exe
```

## Getting the toolchain onto a fresh clone

1. Install HMG 3.6 (64-bit, 2023-05-10) from the HMG forum (hmgforum.com), or copy an existing install.
2. Copy its `mingw64\` and `harbour64\` folders into the root of this clone.
3. Run `hmgbuild all`. This checks the versions, builds `LIB-64\`, and runs the tests.

Phase 2 of the roadmap (AUDIT.md §4) replaces this manual step with a scripted download of a pinned GCC/UCRT build and a source build of Harbour.
