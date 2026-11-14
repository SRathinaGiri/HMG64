---
name: hmg
description: Write, fix, build and test Windows desktop applications with HMG (HMG5 / HMG 3.x, "Harbour MiniGUI") in the Harbour (xBase/Clipper) language - forms, controls, menus, grids over DBF tables, printing and PDF, WebView2 screens and ECharts charts. Use this skill whenever the user mentions HMG, HMG5, MiniGUI, Harbour GUI, .prg files with DEFINE WINDOW or @ row,col BUTTON syntax, .hbp/.hbc/.fmg files, build64.bat, hmgforum, or asks for an xBase/Clipper-style Windows program - even if they only say "Harbour" or "my HMG app".
---

# Developing HMG applications

HMG is a free GUI library for Windows on top of the Harbour compiler (a modern Clipper/xBase).
A program is ordinary Harbour code plus HMG's commands (`DEFINE WINDOW`, `@ row,col BUTTON ...`)
which the Harbour preprocessor turns into function calls. **HMG5** is the current 64-bit line
(HMG 3.6 revamped): one folder with HMG, GCC 16 and Harbour 3.2.1, programs need Windows 10+.
Almost everything here also applies to HMG 3.x; HMG5-only features are marked.

## How to work

1. **Read the user's existing code first** if there is any - match its style (alternate `DEFINE`
   syntax or `@` syntax, naming, UNICODE/ANSI) rather than imposing a new one.
2. **Look up syntax, don't guess it.** Clause names are exact and the preprocessor gives poor
   error messages. Check `references/controls-syntax.md` (generated from HMG5's own headers) for a
   control's clauses and `references/properties-methods.md` for what you can get/set/call.
3. **Start from a working example** in `examples/` (all of them compile and run with HMG5).
4. **Build after every meaningful change**: `build64 /n myprog.prg` (or `.hbp`) and read
   `error.log` - it exists only when the build failed. Fix the first error first; later ones are
   often consequences.
5. **Before calling a task done**, check the traps in "Rules that prevent most bugs" below and,
   for anything non-trivial, run the program or an unattended test (`references/testing.md`).
   **Never wait for a GUI program without a time limit**: an HMG error shows a message box and a
   GUI program never exits by itself. Start it, wait a few seconds (or for a test's own exit, up to
   ~30 s), check, then kill the process you started by its process id.

## Where to look

| Need | File |
|---|---|
| Exact clauses of a control or window (`@ ... GRID`, `DEFINE WINDOW`, ...) | `references/controls-syntax.md` |
| Properties and methods of each control type and of windows | `references/properties-methods.md` |
| Building, `.hbp` / `.hbc` / `.rc`, libraries, UNICODE vs ANSI, the IDE and `.fmg` | `references/project-and-build.md` |
| HMG5 additions: WEBVIEW, CHART, dark mode, per-monitor DPI, PDF engine, object API | `references/hmg5-features.md` |
| Traps with their explanation (read when something behaves oddly) | `references/pitfalls.md` |
| Testing a GUI program without a person clicking | `references/testing.md` |
| Complete, compiling programs | `examples/*.prg` (hello, customers, menu_app, web_and_chart, report_print) |

## The shape of an HMG program

```harbour
#include "hmg.ch"

FUNCTION Main()
   DEFINE WINDOW Win_Main AT 0, 0 WIDTH 600 HEIGHT 400 TITLE "My program" MAIN
      @ 20, 20 TEXTBOX Txt_Name WIDTH 200
      @ 60, 20 BUTTON Btn_Ok CAPTION "OK" WIDTH 100 ACTION DoOk()
   END WINDOW
   Win_Main.Center
   Win_Main.Activate          // the message loop: returns when the MAIN window closes
RETURN NIL

STATIC PROCEDURE DoOk()
   MsgInfo( "Hello " + Win_Main.Txt_Name.Value )
RETURN
```

- Exactly one window is `MAIN`. Others are `CHILD` (independent, has its own taskbar presence
  rules), `MODAL` (blocks the others until released; `Activate` returns only then), `PANEL`
  (a window inside another), or plain (standard). `SPLITCHILD` lives in a SPLITBOX.
- Coordinates are **row, col** (y, x) in pixels, relative to the window's client area (or to the
  TAB page / panel the control is defined in).
- Every control has a name unique **within its window**; the window name is global. Refer to them
  as `WindowName.ControlName.Property`.
- Two syntaxes, same result: `@ row, col CONTROL Name CLAUSE value ...` (one statement, `;` for
  continuation lines) or the alternate form used by the IDE's `.fmg` files:
  ```harbour
  DEFINE BUTTON Btn_Ok
     ROW 60
     COL 20
     CAPTION "OK"
     ACTION DoOk()
  END BUTTON
  ```

## Talking to controls

```harbour
x := Win_Main.Txt_Name.Value                 // get a property
Win_Main.Txt_Name.Value := "Ravi"            // set a property
Win_Main.Grd_List.AddItem( { "A", "B" } )    // call a method
Win_Main.Release                             // window method
Win_Main.Title := "Saved"                    // window property

// the same through functions: names may be variables, works from any module
x := GetProperty( "Win_Main", "Txt_Name", "Value" )
SetProperty( "Win_Main", "Txt_Name", "Value", "Ravi" )
DoMethod( "Win_Main", "Grd_List", "AddItem", { "A", "B" } )
```

- Dot syntax only works for a window the compiler has already seen in this source file: its
  `DEFINE WINDOW` above, or `DECLARE WINDOW WindowName` at the top of the file. In other modules
  (or for names built at run time) use `GetProperty` / `SetProperty` / `DoMethod`.
- Inside an event, `This.Value`, `This.Name`, `ThisWindow.Name`, `ThisWindow.Release` refer to the
  control/window whose event is running.
- Before touching a window that may not exist: `IsWindowDefined( Win_X )`; for a control:
  `IsControlDefined( Ctl_Name, Win_X )`.
- Common values: TEXTBOX `Value` is a string (or a number with `NUMERIC`, a date with `DATE`);
  COMBOBOX/LISTBOX/RADIOGROUP `Value` is the 1-based **index** (`DisplayValue` / `Item( n )` give the
  text); GRID `Value` is the selected row number (0 = none) and `Cell( row, col )` / `Item( row )` its
  data; CHECKBOX `Value` is a logical; DATEPICKER a date. Colours are `{ r, g, b }` arrays.

## Events

Events are clauses: `ACTION`, `ON CHANGE`, `ON CLICK`, `ON DBLCLICK`, `ON ENTER`, `ON GOTFOCUS`,
`ON LOSTFOCUS`, window `ON INIT`, `ON RELEASE`, `ON INTERACTIVECLOSE` (return .F. to refuse),
`ON SIZE`, `ON PAINT`... The clause takes an **expression** (`ACTION DoSave()`), which HMG wraps
in a codeblock for you; you may also pass a codeblock (`ACTION {|| DoSave() }`), which is used as
is. Keep event code short - call a procedure.

Keyboard shortcuts: `ON KEY CONTROL+S ACTION DoSave()`, `ON KEY ESCAPE ACTION ThisWindow.Release`
inside the `DEFINE WINDOW` block. Periodic work: `DEFINE TIMER Tmr_1 INTERVAL 1000 ACTION ...`.

## Rules that prevent most bugs

Each of these has cost real debugging time; `references/pitfalls.md` has the details.

1. **An event can fire while its window is still being defined.** Setting a starting `VALUE` on a
   SPINNER, GRID, COMBOBOX... can run its `ON CHANGE` before later controls exist. If the handler
   touches other controls, guard it - the HMG idiom checks only the **last control defined** in the
   window (controls are created in order, so if the last exists, all do):
   `IF ! IsControlDefined( Lbl_Last, Win_X ) ; RETURN ; ENDIF`.
2. **Don't name your functions after commands.** A *statement* that begins with a command word is
   read as that command, not as a call to your function: `Go( x )` becomes `dbGoto( x )`, `Close( x )`
   closes a work area, `Release( x )` releases variables - and HMG's DEFINE-syntax clause words are
   commands too, so `Sort( x )`, `Center( x )`, `Open( x )`, `Width( x )`... silently assign to HMG's
   internal state. Use distinctive names (`OpenUrl()`, `SortCustomers()`); calls inside expressions
   (`x := Go( 1 )`, codeblocks) are not affected. List and explanation in `references/pitfalls.md`.
3. **Window names in dot syntax must be declared above their use** (see "Talking to controls").
4. **`MsgHMGError` ends the program with exit code 0.** HMG's own fatal errors ("Control ... Not
   defined. Program terminated") show a box and call `ExitProcess(0)`. Never treat exit code 0 alone
   as success in scripts or tests; see `references/testing.md`.
5. **One modal at a time, from an event.** Activate MODAL windows from events (button, menu, timer),
   not from the MAIN window's `ON INIT`: releasing a modal opened there ends the main message loop
   too. Release a window from its own buttons/keys, never inside its own `ON RELEASE`.
6. **Locking.** DBFs opened `SHARED` need `RLock()` before writing an existing record (`dbAppend()`
   locks the new one); unlock after `dbCommit()`.
7. **UNICODE strings are UTF-8.** HMG5's libraries are UNICODE by default: keep `.prg` files UTF-8,
   use `HMG_LEN`, `HMG_UPPER`, `HB_ULEFT`/`HB_USUBSTR` for text that may hold non-ASCII characters
   (`Len()` counts bytes). Characters above U+FFFF (emoji) need `HMG_CESU8()` before going into a
   Windows control.
8. **Don't write HMG's internal state.** `_HMG_SYSDATA` is HMG's internal array (layout frozen);
   read it only when nothing else exists, never assign to it.
9. **64-bit.** HMG5 is 64-bit only: handles are 64-bit integers; old 32-bit `.lib`/`.a` files and
   32-bit DLLs (old MySQL clients, ActiveX controls) cannot be linked or loaded.
10. **Write every file with Windows line endings (CR+LF).** The compiler accepts LF-only files, but
   the HMG IDE reads `.hbp`, `.fmg` and report files line by line with `MemoLine()`, which only
   breaks at CR+LF: an LF-only `.hbp` reads as one line and the IDE says "Project File is empty,
   invalid or no main module specified"; LF-only forms and reports load wrong. This applies to
   `.prg`, `.hbp`, `.hbc`, `.fmg`, `.rc`, `.ch` and `.bat`. If your file-writing tool produces LF,
   convert afterwards, for example in PowerShell from the project folder:
   ```powershell
   Get-ChildItem *.prg,*.hbp,*.hbc,*.fmg,*.rc,*.ch,*.bat | ForEach-Object {
      $t = [IO.File]::ReadAllText($_.FullName) -replace "`r?`n", "`r`n"
      [IO.File]::WriteAllText($_.FullName, $t) }
   ```

## Common building blocks

```harbour
MsgInfo( cText [, cTitle ] )             MsgStop( ... )   MsgExclamation( ... )
lYes := MsgYesNo( cText [, cTitle ] )    lOk := MsgOkCancel( ... )   MsgRetryCancel( ... )
cText := InputBox( cPrompt, cTitle, cDefault )
cFile := GetFile( { { "Text files", "*.txt" } }, "Open" )            // "" if cancelled
cFile := PutFile( { { "PDF", "*.pdf" } }, "Save as", , .T., "out.pdf" )
cDir  := GetFolder( "Choose a folder" )
```

Data: Harbour's RDDs work as in Clipper (`USE`, `INDEX ON`, `SEEK`, `REPLACE`, `dbAppend()`...).
Show tables with a GRID you fill yourself (see `examples/customers.prg`) or with `BROWSE` / a GRID
with `ROWSOURCE` bound to an alias. SQLite: link `hmgsqlite-64` (see `project-and-build.md`).

Printing (`examples/report_print.prg`): `SELECT PRINTER DIALOG TO lOk PREVIEW` (or `DEFAULT`, a
name, or `PDF cFile`), then `START PRINTDOC` / `START PRINTPAGE` / `@ row, col PRINT "text" FONT
"Arial" SIZE 10 [BOLD] [RIGHT]` / `@ r, c PRINT LINE TO r2, c2` / `PRINT RECTANGLE` / `PRINT IMAGE`
/ `END PRINTPAGE` / `END PRINTDOC`. Units are millimetres from the page's top-left corner.

## When writing a new program

- Name controls by type prefix: `Win_`, `Btn_`, `Txt_`, `Lbl_`, `Grd_`, `Cmb_`, `Chk_`, `Dtp_`, `Tab_`,
  `Tmr_`, `Ch_` (chart), `Web_` (webview). The IDE's completion and the project index read them better,
  and so does the next programmer.
- Put `STATIC` procedures under the window code; use `STATIC` variables (not PUBLIC) for module state.
- Give every window and dialog an Escape/Cancel path and a sensible default button.
- Size windows for 1366x768 screens at 125% scaling unless told otherwise; or use
  `SET DPIAWARE PERMONITOR` (HMG5) for sharp, correctly scaled forms.
- After writing, build it, then run it once (or test it unattended) before handing it over.
