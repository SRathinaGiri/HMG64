# HMG 5.2 plan

Twelve items, done one at a time on `phase4`. Each item ends with its own tests passing,
the whole suite passing (`hmgbuild all`, `hmgbuild idetest`), a changelog line and, where
it is a new clause or function, the skill references (`skills\hmg\references`). The user
tries each item before the next starts. Released together as 5.2 (or earlier as 5.1.x
when an item is a fix).

Rules for every item, as in 5.0 and 5.1: opt-in (programs that do not use a new clause
behave exactly as before), the HMG way (a clause or a property, not a new framework),
64-bit, UNICODE and ANSI library modes both build, no new DLLs to ship.

| # | Item | Kind | Status |
|---|------|------|--------|
| 1 | VIRTUAL grid fed from an array: `ROWSOURCE` (and in-place editing) | speed | done |
| 2 | HTTPS without OpenSSL: `HMG_HttpGet()`, `HMG_HttpPost()` | feature | done |
| 3 | Long jobs without freezing: `HMG_Busy()` with progress and Cancel | feature | done |
| 4 | Grid export: `ExportCSV`, `ExportXLSX` | feature | done |
| 5 | Files dropped from Explorer: `ON DROPFILES` | feature | in progress |
| 6 | Hint text in empty boxes: `PLACEHOLDER` (TEXTBOX, COMBOBOX) | feature | |
| 7 | Harbour code compiled to C (`-gc3`): test, measure, document | speed | |
| 8 | `SPLITTER` control: two panes resized with the mouse | control | |
| 9 | `TOGGLE` control: an on/off switch | control | |
| 10 | Toast notifications: `HMG_Toast()` | feature | |
| 11 | IDE: linker errors in the Error List | IDE | |
| 12 | IDE: projects and forms with LF-only line endings | IDE | |

## 1. VIRTUAL grid fed from an array (`ROWSOURCE`)

A VIRTUAL grid asks for every cell it shows. Today each cell goes through HMG's Harbour
event dispatcher and ON QUERYDATA: about 500 round trips for one screen of 20 rows x 24
columns. Most programs only return `aRows[ This.QueryRowIndex, This.QueryColIndex ]`.

    @ 10, 10 GRID Grid_1 WIDTH 600 HEIGHT 300 HEADERS aHeaders WIDTHS aWidths ;
       ROWSOURCE aRows                       // VIRTUAL and ITEMCOUNT Len( aRows ) implied

    Form_1.Grid_1.RowSource := aOtherRows    // rebind: item count and repaint follow
    AAdd( aRows, { ... } ) ; Form_1.Grid_1.Refresh   // the same array changed: refresh

- The cells are read from the array in C (no Harbour code per cell), formatted exactly as
  HMG formats ON QUERYDATA values: character RTrim, number Str(), date DToC() with the
  current SET DATE, logical .T./.F., anything else empty. A short row shows empty cells.
- With IMAGE, column 1 of a row is the image index, as with ON QUERYDATA.
- The grid holds a reference to the array (no copy). Assigning a new array to the
  program's variable does not rebind the grid: assign `RowSource`.
- ON QUERYDATA and ROWSOURCE together: ROWSOURCE wins (documented).
- DEFINE GRID: `ROWSOURCE <aRows>`.
- Tests: `tests\unit\rowsource` - cell text for each value type equals the ON QUERYDATA
  formatting; short rows; rebind and refresh; no Harbour call per cell; 100,000 rows.

## 2. HTTPS without OpenSSL

`HMG_HttpGet( cUrl [, aHeaders] [, nTimeoutMs] ) -> { nStatus, cBody, cError }` and
`HMG_HttpPost( cUrl, cBody [, cContentType] [, aHeaders] [, nTimeoutMs] )`, on Windows'
WinHTTP (TLS included, the system's certificates). Bodies are bytes (UTF-8 stays UTF-8).
Tests against a local test server started by the test itself (no internet needed).

## 3. Long jobs without freezing

`HMG_Busy( cTitle, bJob )`: a small modal window with a progress bar and Cancel runs
`bJob( oBusy )`; the job calls `oBusy:Step( nDone, nTotal [, cText] )`, which repaints and
handles Cancel (messages pumped at most every 50 ms, so a tight loop stays fast), and reads
`oBusy:Cancelled`. Same thread: no thread-safety rules for the program to learn.

## 4. Grid export

`Form.Grid.ExportCSV( cFile [, lHeaders] [, cSep] )` (UTF-8 with BOM, quotes as Excel
expects) and `Form.Grid.ExportXLSX( cFile [, cSheet] )`, an own writer (hbmzip is already
linked): numbers stay numbers, dates become dates; no Excel needed. Both work for normal,
VIRTUAL (ON QUERYDATA or ROWSOURCE) and database grids.

## 5. Files dropped from Explorer

`ON DROPFILES <action>` on a window and on TEXTBOX, EDITBOX, LISTBOX, GRID and IMAGE;
`This.DroppedFiles` is the array of full paths. WM_DROPFILES (DragAcceptFiles), no OLE.

## 6. `PLACEHOLDER`

`PLACEHOLDER "Search..."` on TEXTBOX and COMBOBOX (DISPLAYEDIT): Windows' own cue banner
(EM_SETCUEBANNER, CB_SETCUEBANNER), shown while the box is empty; property `Placeholder`.

## 7. `-gc3`

Build the library, the samples and the test suite with Harbour's `-gc3` (functions
compiled to C), measure size and speed on a few programs, and document how to use it in
a project (`build64 ... -gc3` or a line in the .hbp) if it is safe; fix what breaks.

## 8. `SPLITTER`

`@ row, col SPLITTER Spl_1 VERTICAL|HORIZONTAL BETWEEN { "Ctl_A" } AND { "Ctl_B" }`
(a thin bar that the mouse drags; the controls on each side are moved and resized),
`MINSIZE`, `ON CHANGE`, property `Position`.

## 9. `TOGGLE`

`@ row, col TOGGLE Tgl_1 VALUE .T. CAPTION "Dark mode" ON CHANGE ...`: an owner-drawn
on/off switch (keyboard, focus rectangle, dark mode, DPI), Value is logical.

## 10. Toast notifications

`HMG_Toast( cText [, cTitle] [, nSeconds] [, nIcon] )`: a small window that slides in at
the bottom right of the work area and fades out, without taking the focus; several
stack. Not the Windows notification centre (that needs an app identity and shortcut).

## 11. IDE: linker errors in the Error List

When a build fails at the link step, the Error List shows the linker's lines (missing
libraries, undefined references) with the library or function named, not "empty".

## 12. IDE: LF-only line endings

The IDE reads `.hbp`, `.fmg` and report files with any line ending (CRLF, LF, CR) and
writes them back with CR+LF; until now LF-only files lost their lines (MlCount/MemoLine
break only at CR+LF). Deferred from 5.0 to 5.2 by decision.
