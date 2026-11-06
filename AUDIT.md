# HMG 3.6 (64-bit) — Code Audit

Audit date: 06-11-2026 · Scope: `D:\hmg.3.6` (library, build system, bundled toolchain) · Auditor: Claude Code

Confidence tags: **[High]** = verified by running code or reading the exact lines; **[Medium]** = strong static evidence, not exercised; **[Low]** = inference.

---

## 1. What is in the box

| Component | Version found | Age / status |
|---|---|---|
| HMG library | 3.6, released 10-05-2023 (`changelog.txt`) | ~3.5 years without updates; the previous release was 3.4.4 (2017) |
| Harbour | 3.2.0dev r2304211101 (21-04-2023) | Upstream `harbour/core` 3.2 is still getting commits |
| MinGW-w64 GCC | 13.1.0, WinLibs build, **msvcrt** runtime, `mcf` threads | Current GCC is much newer; UCRT is now the recommended runtime |
| SQLite | 3.41.2 (22-03-2023) | Outdated |
| libcurl | **7.75.0** (Feb 2021) | Badly outdated, with many published CVEs |
| zlib | 1.2.13 | Outdated (the minizip CVE-2023-45853 was fixed later) |
| libpng | 1.6.39 | Outdated |
| libHaru (PDF) | **2.2.1** headers in `INCLUDE/` | 2.2.1 dates from about 2010; 2.4.x exists |
| QHTM (HFCL) | loaded at runtime as `qhtm.dll` | Closed-source and discontinued; the DLL is not shipped |
| IDE | `IDE/IDE.exe` (v1.2a) | **Binary only, no source in the tree** |

Size: about 103 K lines of PRG/C/CH in `SOURCE/` + `hfcl/`. The bundled toolchain is 670 MB (646 MB of it MinGW). The MinGW folder also carries gdb + Python 3.9, which the library doesn't need.

Not a git repository. There are no automated tests: `SAMPLES/` has 8 demo programs.

---

## 2. Build health (verified)

- **The library builds cleanly** with the bundled toolchain [High]. I rebuilt `hmg64.hbp` into a scratch directory with `-Wall -Wextra`. The result was 0 errors and 31 C warnings: 30 `-Wcast-function-type` (`GetProcAddress` casts, mostly benign) and 1 `-Wmisleading-indentation`.
- **Harbour `-w3` breaks the build** [High]. `hmg64.hbp` uses `-es2` (warnings are errors). At `-w3`, `dbgHB.prg` fails with W0001 (method declaration mismatch at lines 728 and 943) and W0032 (unused variables). The code is clean only at `-w2`.
- **The resource path is hard-coded** [High]. `RESOURCES/_hmg_resconfig.h` contains `#define HMGRPATH C:\hmg64\RESOURCES`. `build64.bat` regenerates this header in the project folder on every build. Any other route has to generate it too, and a build that puts `RESOURCES\` on the include path picks up the stale `C:\hmg64` copy and fails in `windres` (reproduced). The file is a generated artifact and is now git-ignored.
- **There are 4 separate build scripts** (`build64.bat`, `BuildLib64.bat`, `BuildAllLib64.bat`, per-folder `buildlib*.bat`). The ANSI/Unicode switch works by **copying a header over `INCLUDE/SET_COMPILE_HMG_UNICODE.ch`**, so the build mode is global mutable state in the source tree.
- `hmg64.hbc` links every application against about 30 libraries by default, including ODBC, SQLite, netio, tip, zebra, hpdf and vfw32. A "hello world" executable is about 1.5 MB.

---

## 3. Findings — by severity

### CRITICAL

**C1. Memory leak on every string crossing between Harbour and Win32 in the Unicode build (the default)** [High — measured]
- Root cause: `INCLUDE/HMG_UNICODE.h:66-82`.
  - `HMG_parc(n)` expands to `hb_osStrU16Encode(hb_parc(n))`. `HMG_retc(c)` expands to `hb_retc(hb_osStrU16Decode(c))`.
  - Both Harbour functions return **heap buffers the caller must free**. Harbour's own `hbwinuni.h:82-86` maps them to `HB_CHARDUP`/`HB_OSSTRDUP`.
  - HMG never frees them. There are 232 conversion call sites and only 23 `hb_xfree` calls in the whole `SOURCE/*.c`.
- Measured with a probe program (20,000 calls, 50 KB argument):
  - `HMG_ISALPHA()` leaked **+1,911 MB**: exactly the UTF-16 copy of the argument, every call.
  - `HMG_UPPER()` leaked **+2,868 MB**: the input copy plus the returned UTF-8 copy. The changelog says this leak was fixed in 3.4.4; it was not.
- Impact: long-running applications grow without bound. Every `SetProperty` of text, grid cell update, `GetProperty` value read and so on leaks. This is likely behind the "slows down / runs out of memory after hours" reports common for HMG apps [Medium].
- Fix: replace the macro layer with Harbour's handle-based API:
  - `hb_parstr_u16()`, then `hb_strfree()`
  - `hb_retstr_u16()` / `hb_itemPutStrU16()`
  - or the `HB_PARSTR`/`HB_RETSTR` macros from `hbwinuni.h`
  
  This is mechanical work, but it touches all `c_*.c` files.

**C2. Unbounded `lstrcpy` into fixed stack buffers (stack overflow from caller data)** [High — code read]

| Location | Buffer | Source |
|---|---|---|
| `SOURCE/c_controlmisc.c:799`, `:981` | `TCHAR FontName[32]` | `HMG_parc(4)`, a font name from PRG |
| `SOURCE/c_dialogs.c:191` | `lf.lfFaceName[32]` | `HMG_parc(2)` |
| `SOURCE/c_dialogs.c:390` | `TCHAR buffer[1024]` (PutFile default name) | `HMG_parc(5)` |
| `SOURCE/c_dialogs.c:623-624` | `cFindWhat/cReplaceWith[MAX_FINDREPLACE]` | `HMG_parc(8/9)` |
| `SOURCE/c_controlmisc.c:1939` | `DefaultPrinter[254]` | printer name from the spooler |

A font or file name longer than the buffer corrupts the stack. With a font name it is easy to trigger by accident, because face names are capped at 31 characters. There are 36 unsafe string-function calls in total (`lstrcpy/lstrcat/wsprintf/strcpy`).

**C3. NULL dereference when an argument is omitted or non-string** [High — code read]
- `SOURCE/c_UNICODE_String.c:78-107`: `HMG_ISALPHA/ISDIGIT/ISLOWER/ISUPPER/ISALPHANUMERIC` read `Text[0]` with no NULL check. `HMG_ISALPHA()` with no argument, or with a numeric argument, crashes the process (GPF) instead of raising a Harbour RTE.
- The same pattern is likely elsewhere, because `HMG_parc` returns NULL for non-strings [Medium].

### HIGH

**H1. `_ENCRYPT` / `FI_CODE` / `DB_ENCRYPT` are XOR, not encryption** [High]
- `SOURCE/Crypt/h_crypt.prg:14-31`: `CHARXOR(cStr, "<ORIGINAL>")`, then `CHARXOR(..., cPass)`. The fixed key is public, and repeating-key XOR falls to known-plaintext attacks (DBF headers are known plaintext).
- ⚠ Anyone who used this to "protect" client data (PAN, bank details, financials) has no real protection. Replace with AES-GCM (Windows CNG `BCrypt*`, no extra dependency), or mark it deprecated/obfuscation-only.

**H2. Outdated bundled network/compression libraries with known CVEs** [High for versions, Medium for exploitability]
- libcurl 7.75.0 (via `hbtip`/`hbcurl`), zlib/minizip 1.2.13 (`hbmzip` is linked by default), SQLite 3.41.2 and libpng 1.6.39.
- Any HMG app that downloads files or opens ZIP/PNG files from outside is exposed.

**H3. Stack-heavy file dialog** [Medium]
- `SOURCE/c_dialogs.c:267-268`: `buffer[1024*MAX_PATH]` + `cFullName[1024][MAX_PATH]` of `TCHAR` add up to **about 1.06 MB on the stack** in a single frame.
- That works on the main thread (the GNU ld default reserve is 2 MB), but it gets close to the limit in nested or secondary-thread calls.
- The filter loop at `:296-306` counts UTF-8 bytes against a WCHAR buffer and calls `HMG_CHAR_TO_WCHAR(p)` twice per segment, so it also leaks twice per segment.

**H4. Unqualified `LoadLibrary("qhtm.dll")`** [High]
- `hfcl/Source/c_qhtm.c:60-64`. The DLL search order lets a `qhtm.dll` planted in the current directory get loaded (DLL hijacking).
- Fix with `LoadLibraryEx(..., LOAD_LIBRARY_SEARCH_APPLICATION_DIR | LOAD_LIBRARY_SEARCH_SYSTEM32)`. Better still, drop QHTM, which is closed-source and discontinued.

**H5. Fixed, shared temp file** [High]
- `SOURCE/c_button.c:131-133` writes `%TEMP%\_HMG_tmp.BMP` on every image-button creation.
- Two HMG processes, or two threads, can race on it (wrong image, or a load failure).
- Use `GetTempFileName`, or skip the temp file entirely (`ImageList_Add` from the `HBITMAP` already in memory).

### MEDIUM — architecture and maintainability

**M1. Global state as one PUBLIC array with 518 positional slots** [High]
- `_HMG_SYSDATA[1..518]`, documented only in comments at `SOURCE/h_init.prg:203-723`, with **8,435 references** across the PRG sources. Slots are addressed by magic number: `_HMG_SYSDATA[2][i]` is a control name, `[3][i]` is a handle, and so on.
- Because it is a PUBLIC memvar, the "multi-thread" support (`c_Thread.c`, `-mt` by default) shares it across threads with no synchronisation at the PRG level.
- Any revamp has to replace this with real objects (window/control classes).

**M2. Control lookup by macro-evaluating generated memvar names** [High]
- `SOURCE/h_controlmisc.prg:1057-1078`: `GetControlIndex` builds `'_' + Form + '_' + Control` and evaluates it with `&mVar`. There are 29 macro evaluations in this file alone.
- This is slow, it creates one PUBLIC variable per control, and it can't be checked statically.

**M3. Monolithic event dispatcher** [High]
- `Events()` in `SOURCE/h_windows.prg:446` is about 3,200 lines and does 40 linear `ascan` scans over the global arrays.
- `WndProc` (`SOURCE/c_EventCB.c:73`) pushes every Windows message into the Harbour VM. With large forms, every `WM_MOUSEMOVE`/`WM_NOTIFY` pays O(controls) PRG work.

**M4. The target platform is Windows XP** [High]
- `INCLUDE/HMG_UNICODE.h:24-34` sets `WINVER/_WIN32_WINNT 0x0501` and `_WIN32_IE 0x0600`. That excludes per-monitor DPI, dark mode, modern dialogs (`IFileDialog`) and so on.
- The manifest (`RESOURCES/Windows7.Manifest`) declares only system-level `<dpiAware>true`. It has no `PerMonitorV2`, no `longPathAware`, and no UTF-8 `activeCodePage`, so apps look blurry or mis-scaled on mixed-DPI setups.

**M5. Dual ANSI/Unicode code paths** [High]
- Every string-handling C function has two compiled branches (`#ifdef COMPILE_HMG_UNICODE`), and the build switch is a header file overwrite.
- ANSI mode has no real use on modern Windows. Dropping it removes a large share of the conditional code.

**M6. Deprecated Harbour API** [High]
- 66 uses of `ISCHAR/ISNUM/ISNIL/ISLOG/ISARRAY/hb_parinfa`. These still compile, but they are deprecated in favour of the `HB_IS*` macros.

**M7. IDE is binary-only** [High]
- `IDE/IDE.exe` has no source in the tree, so it can't be maintained or rebuilt as part of a revamp. Plan to replace it (form designer → `.fmg`), or to recover its source from the HMG forum releases.

### LOW

- `-Wcast-function-type` ×30 (`c_winapimisc.c`, `c_BosTaurus.c`, `HMG_UNICODE.h`): cast through `(void(*)(void))` to silence them.
- `-Wmisleading-indentation` ×1 (see the build log).
- `unins000.exe/.dat` (5.5 MB) and `build.log` (from someone else's machine, `C:\Users\ADMIN\...`) sit at the root. They should not be in a source tree.
- gdb + Python 3.9 (1,700+ `.py` files) inside `mingw64/` are not needed to build HMG apps.
- `doc/` is 13 MB of hand-written HTML (487 pages), with no generator.

---

## 4. Revamp roadmap (recommended order)

**Phase 0 — Baseline (do first, low risk)**
1. `git init`. Commit the pristine tree with `mingw64/` and `harbour64/` **excluded**: track the toolchain versions in a manifest, not the binaries.
2. One build entry point: an `hbmk2` project file plus a small script that generates `_hmg_resconfig.h` from the actual install path every time.
3. Turn `SAMPLES/` into a smoke-test suite that builds headless, and add the leak probe used in this audit as a regression test.

**Phase 1 — Correctness and security (no API change for users)**
1. Fix C1: rewrite `HMG_UNICODE.h` around `hb_parstr_u16`/`hb_strfree`/`hb_retstr_u16`, then sweep all `c_*.c` files.
2. Fix C2/C3/H3/H4/H5: bounded copies (`lstrcpyn`/`StringCchCopy`), NULL guards that raise RTEs, a heap buffer for the file dialog, `LoadLibraryEx`, a unique temp file.
3. Replace or deprecate `h_crypt.prg` (H1) with CNG AES-GCM.
4. Make the build pass at Harbour `-w3 -es2`.

**Phase 2 — Toolchain refresh**
1. Upgrade MinGW-w64 to a current GCC with the **UCRT** runtime (WinLibs/MSYS2). Rebuild Harbour 3.2 from current `harbour/core` with it.
2. Rebuild the contribs against current SQLite, zlib, libpng and libcurl (or drop libcurl in favour of WinHTTP), and libHaru 2.4.x.
3. Drop the ANSI build (M5). Raise `_WIN32_WINNT` to Windows 10 (`0x0A00`). Switch the manifest to PerMonitorV2 + longPathAware + UTF-8 code page.

**Phase 3 — Architecture (breaking internally, keep the PRG command syntax)**
1. Replace `_HMG_SYSDATA` and the macro-named memvars with a window/control object model. Use hash lookups keyed by `HWND` and by `form.control` name.
2. Split `Events()` per control class. Dispatch from C only for messages a control actually subscribes to.
3. Keep `DEFINE WINDOW … END WINDOW` / `@ … BUTTON` / `GetProperty/SetProperty` as a compatibility layer, so existing user code compiles unchanged. That is the main value of HMG.

**Phase 4 — Modern features**
- Dark mode, per-monitor DPI scaling, `IFileDialog`, WebView2 to replace QHTM, a modern PDF and print pipeline.
- An IDE: rebuild it, or replace it with a VS Code extension (syntax + hbmk2 tasks + `.fmg` previewer).

---

## 5. What was and wasn't verified

- **Verified by running:** the library rebuilds with the bundled toolchain (`-Wall -Wextra`). The `-w3` failure. The resource-path failure. The C1 leak, measured with a probe program. The runtime DLL imports of a built executable (msvcrt, kernel32, user32, advapi32, winmm only; libgcc/pthread are static).
- **Verified by reading code:** C2, C3, H1, H3, H4, H5, M1–M7.
- **Not verified:** whether C2/C3 actually crash at runtime (not exercised, to avoid GUI fault dialogs). Exploitability of the library CVEs. Thread-safety races in M1. The behaviour of `IDE.exe`.

---

## 6. Phase 1 resolution log (branch `phase1-fixes`)

| Finding | Status | What changed |
|---|---|---|
| C1 string leak | **Fixed, measured** | `HMG_UNICODE.h` + `c_UNICODE.c`: every conversion (`HMG_parc/parvc/retc/storc/storvc`, `HMG_CHAR_TO_WCHAR`, `HMG_WCHAR_TO_CHAR`, `HMG_MBtoWC/WCtoMB`) is **owned by the current Harbour call frame**. The buffer sits in a GC pointer item on the HVM stack and is freed when the `HB_FUNC` returns. The 254+ call sites are unchanged. Leak probe: 191–287 MB → **0.0 MB**. |
| C1 side effect | Fixed | Two sites handed the converted pointer to Windows for *deferred* reading, and only worked because it leaked: virtual-grid `SETGRIDQUERYDATA` (XP branch) and toolbar `SHOWTOOLBUTTONTIP`. Both now copy (into the listview buffer, or a per-thread buffer). |
| C2 overflows | Fixed | New `HMG_STRCPY_BUF` (bounded, NULL-safe). Applied to font names (`c_controlmisc.c` ×2, `c_dialogs.c`, `c_richeditbox.c`), PutFile default name, find/replace text, tree item text ×2, tray tip ×2, default printer, BosTaurus GDI+ file name. |
| C3 NULL crashes | **Fixed, verified at runtime** | `HMG_ISALPHA/ISDIGIT/ISLOWER/ISUPPER/ISALPHANUMERIC` return `.F.` for non-strings; `HMG_GETUNICODEVALUE(NIL)` returns `{}`. The file-dialog filter builder handles a missing filter. The old library dies with ACCESS_VIOLATION on `HMG_ISALPHA()`; the new one passes `tests/unit/strings.prg`. |
| H1 XOR crypt | Documented | Deprecation and "not encryption" warning in `SOURCE/Crypt/h_crypt.prg`. Behaviour unchanged, so existing data can still be decrypted. **AES-GCM replacement still open.** |
| H3 file dialog | Fixed | Result buffer moved from the stack (~1 MB) to the heap. Full names are sized per file (the fixed `MAX_PATH` copies overflowed on long paths). No more double backslash for root folders. |
| H4 DLL hijacking | Fixed (wider than reported) | All 16 `LoadLibrary("x.dll")` calls plus `HMG_DEFINE_DLL_FUNC` now go through `HMG_LoadSystemLibrary` (System32 only). QHTM goes through `HMG_LoadAppLibrary` (app folder, then System32). Needs Win 8+, or Win 7 with KB2533623. |
| H5 temp file | Fixed | `c_button.c` and `c_image.c` use `GetTempFileName` (unique per call) instead of the shared `_HMG_tmp.BMP`. |
| -w3 build | Fixed (Phase 2) | The 2 W0001 declaration mismatches are fixed. The 282 W0032 dead stores and 2 W0033 are cleared, and `hmg64.hbp` now builds at `-w3 -es2`. Harbour 3.2's W0032 is a flow-based dead-store check, so it also fires on initialisers that are always overwritten. Rules used: a store with no side effects is removed; a call on the right-hand side is kept and only the assignment is dropped; `SELECT PRINTER ... TO lSuccess` and one division that may hit the error handler are kept and marked with `HB_SYMBOL_UNUSED`. `cPassword` and `FontHandle` are now initialised to NIL explicitly. A few pure query calls were dropped together with their dead store (`Alias()`, `HB_ULEFT`, `hb_ValToExp`/`CharRem`, `HMG_LEN`, `_HMG_HPDF_MM2Pixel`, the `HMG_Debugger():aCurrentLineInfo` accessor, and the C wrappers for `GetDesktopWindow`, `GetDeviceCaps` and `LVM_GETITEMCOUNT`). |

**Not verified:** the GUI paths touched by C2/H3/H4/H5 (file dialogs, tray icon, tree, toolbar tips, virtual grid, image buttons). They compile and link in all 8 samples but were not exercised interactively. The ANSI build was not rebuilt.
