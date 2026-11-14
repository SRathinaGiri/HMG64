# Projects, building and the IDE (HMG5)

## Building

From the program's folder (HMG5 installs to `C:\HMG5`; `build64.bat` finds HMG from its own location):

```bat
C:\HMG5\build64 myprog.prg            :: build and run
C:\HMG5\build64 /n myprog.hbp         :: build only (no run)
C:\HMG5\build64 /n /c tool.prg        :: console program (GT driver instead of GUI)
C:\HMG5\build64 /n /d myprog.prg      :: with the debugger
C:\HMG5\build64 /n myprog.hbp myprog.hbc   :: also apply an .hbc
```

- Options go **before** the file and in this order: `/n`, `/d`, `/c`.
- The output is `<name>.exe` next to the source. Programs are 64-bit, multi-threaded (`-mt`), linked
  statically with the GCC runtime, need Windows 10+.
- `build.log` is written on success, **`error.log` only on failure** (compiler, linker or resource
  errors). Read the first error first. The `.exe` must not be running while you build (the build
  stops with "currently running").
- A `<name>.rc` resource script next to `<name>.prg`/`.hbp` is compiled automatically (icons,
  bitmaps, manifests). Missing files named in it make the link fail (`windres.log`).
- By-products to ignore: `_temp.rc`, `_temp.o`, `_hmg_resconfig.h`, `hbmk.log`, `windres.log`.

## .hbp (project) and .hbc (options)

`.hbp` - one item per line, read by hbmk2 and by the IDE. **The first `.prg` line is the main
module** (the one with `Main()`); the IDE marks it "(Main)". Save it with CR+LF line endings: the
IDE splits the file with `MemoLine()`, which ignores bare LF, so an LF-only `.hbp` builds fine with
`build64` but the IDE refuses it ("Project File is empty, invalid or no main module specified").

```
# my project
main.prg
customers.prg
reports.prg
-w3 -es2          # warnings level 3, warnings are errors (recommended for new code)
-lhmgsqlite-64    # an extra library
myprog.hbc        # pull in an .hbc (build64 does not read <name>.hbc by itself)
```

`.hbc` - key=value lines:

```
incpaths=inc
libpaths=lib
libs=hmgsqlite-64
libs=mylib
```

Libraries already linked for every program (`hmg64.hbc`): `hmg-64`, `hfcl-64`, `crypt-64`, `edit-64`,
`editex-64`, `graph-64`, `ini-64`, `report-64`, `hbvpdf-64`, `hbct`, `hbwin`, `hbmzip`, `minizip`,
`hbtip`, `hbmisc`, `hbmemio`, `sqlite3`, `hbsqlit3`, `rddsql`, `sddodbc`, `hbodbc`, `hbhpdf`
(libHaru PDF), `hbnetio`, `xhb`, `hbzebra` (barcodes). SQL bridges you add yourself:
`hmgsqlite-64`, `hmgmysql-64`, `hmgpgsql-64` (the MySQL/PostgreSQL ones also need the database's
64-bit client library, not bundled).

## Several source files

Each `.prg` is its own module: `STATIC` functions are private to it, windows defined in one module
are used from another with `DECLARE WINDOW Win_X` (for dot syntax) or `GetProperty`/`SetProperty`/
`DoMethod`. `#include "hmg.ch"` in every module.

## The IDE and .fmg forms

`C:\HMG5\IDE\IDE.exe` - project manager, forms designer, built-in code editor (colouring, completion
of keywords, `Form.` and `Form.Control.`), View > Forms and Controls (every form and control of the
project, and misspelt names), Build/Run.

- A `.fmg` is a form saved by the designer, in the alternate `DEFINE WINDOW TEMPLATE ... DEFINE BUTTON
  ... END BUTTON ... END WINDOW` syntax. Load it from code with `LOAD WINDOW Main` (reads `Main.fmg`)
  or `LOAD WINDOW Main AS Win_Copy`, then `Win_Copy.Activate`.
- Code-only projects (File > Code Only New Project) define windows in `.prg` with `DEFINE WINDOW`.
- When editing a `.fmg` by hand keep its format exactly (the designer rewrites it); prefer the
  designer, or move the form to code.

## Library builds (HMG maintainers)

`hmgbuild lib` (UNICODE, default), `hmgbuild lib ansi`, `hmgbuild ide`, `hmgbuild test` (smoke +
unit tests), `hmgbuild matrix` (both modes, all tests). Programs link against whatever `LIB-64`
holds: a program built after `hmgbuild lib ansi` is ANSI.

## Distributing a program

Copy the `.exe` and the files it opens at run time (DBFs, images not compiled into the `.rc`, `.ini`).
No HMG runtime is needed. Programs using WEBVIEW or CHART need the Microsoft Edge WebView2 Runtime,
which Windows 10/11 already has; check with `HMG_WebViewVersion()` (empty = missing).
