# HMG pitfalls, with the reason behind each

Read this when something compiles but behaves strangely, or before reviewing HMG code.

## 1. Command words at the start of a statement

HMG and Harbour define many `#xcommand`s. The preprocessor matches a command at the **start of a
statement**, so a statement that begins with a command word is rewritten before your function is
ever considered:

| You write (as a statement) | It becomes |
|---|---|
| `Go( n )` | `dbGoto( n )` |
| `Close( x )` | `( x )->( dbCloseArea() )` |
| `Skip( n )` / `Select( n )` / `Use( x )` / `Seek( x )` / `Find( x )` | `dbSkip` / `dbSelectArea` / `dbUseArea` / `dbSeek` / `dbSeek` |
| `List( x )` / `Display( x )` / `Create( x )` | `__dbList(...)` / `__dbList(...)` / `__dbCreate(...)` |
| `Run( x )` / `Erase( x )` / `Type( x )` / `Wait( x )` / `Keyboard( x )` | `__Run` / `FErase` / `__TypeFile` / `__Wait` / `__Keyboard` |
| `Release( x )` | `__mvXRelease( "( x )" )` (releases memvars) |
| `Sort( x )`, `Center( x )`, `Open( x )`, `Width( x )`, `Value( x )`, `Caption( x )`, `Items( x )`, ... | `_HMG_SYSDATA[ n ] := x` - HMG's alternate-syntax clause commands (`DEFINE BUTTON ... CAPTION "x" ... END BUTTON`) |

(Checked with `harbour -p` against HMG5's headers. `Print( x )` and `Count( x )` happen not to match.)

Inside expressions the call is a normal function call (`x := Go( 1 )`, `Eval( {|| Go( 1 ) } )`,
`ACTION Go( 1 )` - HMG wraps the ACTION in a codeblock), which is why such bugs hide: the same
function works from a button and fails as a statement. **Fix:** give functions distinctive names.

## 2. Events that fire while a window is being defined

Controls are created one by one, in source order, while `DEFINE WINDOW ... END WINDOW` runs. Giving
a control its starting value (SPINNER `VALUE`, GRID `VALUE`, COMBOBOX `VALUE`, ...) can trigger its
`ON CHANGE` immediately - before the controls defined after it exist. A handler that reads or sets
those later controls then stops the program with
`Control: Lbl_X Of Win_Y Not defined. Program Terminated`.

**Fix (HMG idiom):** at the top of the handler, check the last control defined in that window -
if it exists, every earlier one does:

```harbour
STATIC PROCEDURE UpdatePreview()
   IF ! IsControlDefined( Lbl_Preview, Win_Font )   // Lbl_Preview is defined last
      RETURN
   ENDIF
   Win_Font.Lbl_Preview.FontSize := Win_Font.Spn_Size.Value
RETURN
```

## 3. Dot syntax needs the window declared above

`Win_X.Ctl.Value` is a preprocessor rule created by `DEFINE WINDOW Win_X` (or `DECLARE WINDOW
Win_X`). In a procedure written **above** the window's definition, or in another `.prg`, it is a
syntax error ("syntax error at '.'"). Add `DECLARE WINDOW Win_X` near the top of the file, or use
`GetProperty( "Win_X", "Ctl", "Value" )` / `SetProperty` / `DoMethod`.

## 4. HMG's fatal errors exit with code 0

`MsgHMGError()` (used for "... Not defined. Program terminated", "Window ... is not active", etc.)
writes `ErrorLog.htm` in the current folder, shows a message box, then calls `ExitProcess(0)`.
Batch files and test runners that only check `%ERRORLEVEL%` see success. Have the program print a
summary line (e.g. `PASS=3 FAIL=0`) at its normal end and treat a missing line as failure. A
Harbour runtime error goes through `ErrorBlock()` instead - set your own block in test programs.

## 5. Modal windows and the message loop

- `Activate` of a MODAL window runs a nested message loop and returns when the window is released.
  Read the dialog's result from a STATIC (or the return of a function you call after Activate).
- A modal activated from the MAIN window's `ON INIT` (before the main loop runs): releasing it
  posts a quit that also ends the main loop - the program exits. Start such dialogs from a timer
  or an event, or before activating the main window.
- While a modal is being activated HMG runs `DO EVENTS`; a timer firing there and releasing the
  window triggers "Window ... is not active". Act only when `_IsWindowActive( "Win" )` is true.
- Don't release a window inside its own `ON RELEASE`.

## 6. Values and types

- COMBOBOX, LISTBOX, RADIOGROUP: `Value` is the 1-based position; `0` = nothing selected.
  `DisplayValue` (COMBOBOX) / `Item( n )` give the text.
- GRID `Value` is the selected row (0 = none); `Item( n )` the row array; `Cell( r, c )` one cell. GRID
  rows hold what you `AddItem` - strings unless you declared column types (`COLUMNCONTROLS`).
- TEXTBOX: string by default; `NUMERIC` (with `INPUTMASK`) gives numbers, `DATE` gives dates.
- Colours are `{ r, g, b }`; fonts `FONT "Segoe UI" SIZE 10`.
- Sizes are pixels at 96 DPI. On a 125% screen without `SET DPIAWARE PERMONITOR`, Windows scales
  the whole window (slightly blurry but consistent).

## 7. Strings, UNICODE and ANSI

- HMG5 builds its libraries in UNICODE mode by default (`hmgbuild lib ansi` makes an ANSI build).
  In UNICODE mode strings are UTF-8: save `.prg` files as UTF-8 and use `HMG_LEN()`, `HMG_UPPER()`,
  `HMG_LOWER()`, `HB_ULEFT()`, `HB_USUBSTR()`, `HB_URIGHT()` for user text - `Len()` and `SubStr()`
  work in bytes.
- Characters above U+FFFF (emoji): `HMG_CHR( 0x1F382 )` makes one; Windows controls (UTF-16)
  need it as `HMG_CESU8( cText )`; `HMG_UNCESU8()` converts back (HMG5).
- C code in `#pragma BEGINDUMP` that uses HMG macros includes `HMG_UNICODE.h`; in HMG5 that
  header brings `hbapi.h` itself (GCC 14+ refuses undeclared functions).

## 8. DBF access in a GUI

- Open tables `SHARED` in multi-user programs; `RLock()` before changing an existing record,
  `dbAppend()` locks the new one; `dbCommit()` then `dbUnlock()`.
- Close tables in the MAIN window's `ON RELEASE` (`dbCloseAll()`).
- Don't fill a GRID with thousands of `AddItem`s while it repaints: wrap in
  `Win.Grid.DisableUpdate` / `Win.Grid.EnableUpdate`, or use a GRID with `ROWSOURCE` / `VIRTUAL`.

## 9. Things that are not there (HMG5)

- 32-bit only libraries and DLLs (old MySQL client libs, many ActiveX controls, QHTM) - HMG5 is 64-bit.
- `_HMG_SYSDATA` slots are internal; its layout is frozen and append-only. Use the documented
  functions and properties instead of indexes.
- One-letter macros `W()` / `U()` from HMG 3.5 are not defined; use `HMG_CHR( n, .T. )` / `HMG_CHR( n )`.
