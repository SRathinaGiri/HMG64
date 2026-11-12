# Phase 4 design note: modern features

Status: branch `phase4`. **W (WebView2 control)**, **D (per-monitor DPI)**, **K (dark mode)**, **F (IFileDialog)** and **P (PDF through Windows printing)** implemented and tested (11/12-11-2026, sections 1.8, 2.6, 3.5, 4.4, 5.6); I (IDE) planned in section 6, source imported.

Phase 4 scope, from AUDIT.md §4 and PHASE3-DESIGN.md §5:

| # | Item | Order |
|---|---|---|
| W | **WebView2 HTML control** (replaces the removed QHTM) | 1 |
| D | Per-monitor DPI (PerMonitorV2) with layout scaling | 2 |
| K | Dark mode (opt-in) | 3 |
| F | `IFileDialog` for GetFile / PutFile / GetFolder (opt-in) | 4 |
| P | Modern PDF / print pipeline | 5 |
| I | IDE | 6 |

Rules carried over from Phases 1-3: **opt-in for anything visual**, no slot renumbered (new slots are appended), both library modes (ANSI and UNICODE) built and tested, a unit test per feature, design measured before it is optimised.

A second Phase 4 line was developed elsewhere (another machine) and will be compared with this one; this note records why this line made its choices, so the two can be benchmarked fairly.

---

## 1. WebView2 control

### 1.1 Decision: plain C against the WebView2 COM API, no C++ library

ADOPTION.md §6 proposed building on the `webview` C++ library (MIT) that HB_WebView wraps. This line does **not**, for these reasons:

| | `webview` C++ library | Plain C (chosen) |
|---|---|---|
| Language | C++17: every HMG app would need `-cpp` / libstdc++, or the control lives in a separate lib | C, like the rest of `SOURCE/` (`COBJMACROS` vtable calls) |
| Window model | owns a top-level window and message loop; the child mode was an afterthought (no resize, nested `GetMessage` loop until ready) | a real HMG child control; HMG's loop drives it; creation is **asynchronous** (no nested loop, so no re-entrancy) |
| Bridge | generic `bind` that the wrapper turned into macro evaluation | HMG's own allow-listed bridge (1.4) |
| Size | ~3,000 lines of C++ we would carry | ~1,200 lines of C + ~600 of PRG |

What we take from it: the **runtime loader** idea (1.2) and the integration notes in ADOPTION.md §6 (DevTools off by default, user-data folder, missing-runtime message).

The only external file is Microsoft's `WebView2.h` (WebView2 SDK, BSD-3-Clause), checked in as `INCLUDE/WebView2.h` with its licence. MinGW-w64 14 does not ship it.

### 1.2 Finding the runtime (no `WebView2Loader.dll` to ship)

`CreateCoreWebView2EnvironmentWithOptions` lives in `WebView2Loader.dll`, which MinGW cannot link statically (the SDK's static loader is an MSVC `.lib`). Order used:

1. `WebView2Loader.dll` **next to the exe** (`HMG_LoadAppLibrary`, never the current directory), if the developer ships it. This is the documented, supported path.
2. Otherwise the built-in loader: read the Evergreen runtime's version and folder from `HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}` (then `HKCU`), load `<folder>\<version>\EBWebView\x64\EmbeddedBrowserWebView.dll` by full path and call its `CreateWebViewEnvironmentWithOptionsInternal`. This is what the `webview` library and WebView2's own loader do; it is undocumented, hence step 1 first.
3. Neither: the control is created as an empty host window, `ONERROR` fires with "WebView2 runtime not found", `GetProperty( f, c, "Error" )` returns the text. `HMG_WebViewVersion()` returns `""` so a program can check before showing a form.

### 1.3 Control model

```
HMG form
 └─ host window, class "HMG_WebView" (the control's HMG handle: Row/Col/Width/Height/Visible work unchanged)
     └─ WebView2 controller (bounds = host client rect, updated on WM_SIZE)
```

- **Asynchronous creation.** `@ ... WEBVIEW` returns at once. Environment, then controller, are created in the background on the UI thread. Until the control is ready, `URL`, `HTML`, `ExecuteScript`, `Bind` and `PostMessage` are **queued** in C and applied in order when it is; `ONREADY` fires then. No nested message loop.
- **Events** are posted to the host window (`WM_APP+n`) and run from its window procedure through `_HMG_WebViewEvent()`, which finds the control by handle and evaluates its codeblock with `_DoControlEventProcedure` (so `This.*` works as for every control). COM callbacks never call into the HVM directly.
- **Strings**: UTF-16 at the COM boundary, Harbour strings via `hb_parstr_u16` / `hb_itemPutStrU16` (works in ANSI and UNICODE library modes). JSON in and out is `hb_jsonEncode` / `hb_jsonDecode`.
- **Release**: `ICoreWebView2Controller::Close`, all COM references released, queued items freed, host window destroyed; from `_EraseControl` and the form's `WM_DESTROY`.

### 1.4 JavaScript ↔ Harbour bridge (security)

HB_WebView let any page script run any Harbour code (ADOPTION.md §6). Rules here:

1. **Allow-list.** Only names bound by the program can be called: `DoMethod( f, c, "Bind", "total", {|a,b| a+b } )`. A binding is a **codeblock** stored in a per-control hash; there is no macro evaluation and no symbol lookup by a name that came from the page.
2. **Origin check.** A bridge message is accepted only when its source is the app's own content, at one of two private origins (`.example` never resolves on the internet, and every request to them is answered locally):
   - `https://html.hmg.example/`: the `HTML` property. The page is kept in memory and served through `WebResourceRequested`, not `NavigateToString`. **Measured:** a `NavigateToString` page and a `data:` page both report their source as `about:blank`, so `about:blank` cannot be trusted. Serving from memory also removes `NavigateToString`'s 2 MB limit.
   - `https://app.hmg.example/`: a local folder mapped with `FOLDER` (`SetVirtualHostNameToFolderMapping`).
   
   Other origins (any `URL` on the web, `data:`, `about:blank`) can display, but their calls are rejected with an error. `AllowOrigin` adds an origin explicitly.
3. **Errors never cross into C++.** The bound block runs inside `BEGIN SEQUENCE`; the JavaScript promise always settles: resolved with the result (JSON-encoded) or rejected with the error description.
4. **No raw pointers or code from PRG** (HB_WebView's `DISPATCH`); `ExecuteScript` sends text to the page, nothing else.

Page side, injected at document creation:

```js
const n = await hmg.call("total", 2, 3);   // -> 5, or throws Error(text)
hmg.post({ any: "json" });                  // -> ONMESSAGE
hmg.on(function (data) { ... });            // <- DoMethod( f, c, "PostMessage", xValue )
```

### 1.5 Privacy (client data)

- Default user-data folder: `%LOCALAPPDATA%\<exe name>\WebView2` (local, not roaming as in `webview`).
- `USERDATA <cFolder>` overrides it.
- `PRIVATE`: InPrivate profile, nothing (cookies, cache, local storage) is written to disk. Recommended for CA/accounting screens that show client data.
- DevTools and the default context menu are **off** unless `DEVTOOLS` is given.

### 1.6 HMG syntax

```
@ <row>, <col> WEBVIEW <name> [ OF <parent> ] WIDTH <w> HEIGHT <h>
      [ URL <cUrl> | HTML <cHtml> | FOLDER <cFolder> [ START <cFile> ] ]
      [ USERDATA <cFolder> ] [ PRIVATE ] [ DEVTOOLS ] [ INVISIBLE ]
      [ ON READY <bAction> ] [ ON NAVIGATE <bAction> ] [ ON MESSAGE <bAction> ]
      [ ON TITLE <bAction> ] [ ON ERROR <bAction> ]
```

| Kind | Names |
|---|---|
| Properties | `URL` (get/set: navigate), `HTML` (set), `Title` (get), `Ready`, `Error`, `CanGoBack`, `CanGoForward`, `ZoomFactor`, `UserDataFolder` + the usual Row/Col/Width/Height/Visible |
| Methods | `Navigate`, `SetHtml`, `Reload`, `Stop`, `GoBack`, `GoForward`, `ExecuteScript( cJs [, bResult( xValue, lOk ) ] )`, `Bind( cName, bBlock )`, `Unbind( cName )`, `PostMessage( xValue )`, `AllowOrigin( cOrigin )`, `SetFocus`, `Release`; `Print` later |
| Event data | `HMG_WebViewData()` returns a hash: READY `{ready}`, NAVIGATE `{url, success, status}`, MESSAGE `{value, source, trusted}`, TITLE `{title}`, ERROR `{error, code}` |
| Function | `HMG_WebViewVersion()`: runtime version, `""` if none |

Dot syntax: `Form.Web.URL := "..."`, `Form.Web.ExecuteScript( "..." )`, `Form.Web.Bind( "n", {|| ... } )` etc., in `i_window.ch` next to the other control rules. **Not `Form.Web.Title`:** a control-level `Title` rule also matches `Form.Title := Form.Title + x` (the `<c>` marker swallows `Title := Form`) and broke `h_edit.prg`, which is why HMG has never had one. Use `GetProperty( f, c, "Title" )`.

`DEFINE WEBVIEW ... END WEBVIEW` (alternate syntax, used by the IDE's `.fmg`) needs new `_HMG_SYSDATA` slots (522+, append-only); it is done after the `@` syntax has settled.

### 1.7 Tests

- `tests/unit/webview` (24 checks, hidden form, both library modes): runtime detection; operations queued before ready (Bind, ExecuteScript); `hmg.call` round trip with numbers and Unicode text; unbound name rejected; runtime error in a bound block rejects the promise with its text; HTML content trusted; `ExecuteScript` result; `PostMessage` → `hmg.on` echo; foreign (`data:`) page displayed but its call rejected; release (host window gone); release before ready; a new control after release; `FOLDER` app with a relative script, trusted, origin `https://app.hmg.example`. `PRIVATE` is used by the main test control.
- `SAMPLES/Controls/WebView`: HTML invoice screen bound to Harbour (data, add with validation error, confirm dialog, push update) and a small browser tab.

### 1.8 Status and open points (11-11-2026)

- Done: everything in 1.2-1.7. `hmgbuild matrix` green (20 suites per mode). `c_webview.c` builds with `-Wall -Wextra`, no warnings; `WebView2.h` (SDK 1.0.4314.35) is included unchanged through `hmg_webview2.h` (system header).
- Not verified: the no-runtime path (this PC has runtime 157; the code posts ERROR and the test has a branch for it); the `WebView2Loader.dll` path (only the built-in loader ran); a handle/memory count over many create/release cycles; behaviour inside a TAB page and a SPLITBOX (the sample uses a TAB, checked by eye only).
- Not done: `DEFINE WEBVIEW` alternate syntax (needs new slots 522+), `Print`, a check that `PRIVATE` leaves no profile data, NavigationStarting allow-list for `URL` navigation, docs page in `doc/`.
- Chromium prints `Failed to unregister class Chrome_WidgetWin_0` to stderr when a program ends with `ExitProcess` while a WebView is open (the unit tests do); harmless.

---

## 2. Per-monitor DPI

### 2.1 Problem (measured in the code)

- The manifest (`RESOURCES/Windows7.Manifest`) declares `<dpiAware>true</dpiAware>`: **system-DPI aware**.
- Fonts follow the system DPI (`PrepareFont` multiplies by the desktop's `LOGPIXELSY`), but every Row/Col/Width/Height is used as raw pixels. At 125-150 % text outgrows its controls; on a second monitor with another DPI Windows stretches the bitmap (blurry).
- HMG stores control positions in `_HMG_SYSDATA` (`HMG_CTL_ROW/COL/WIDTH/HEIGHT`) and reads them back from there; all writes go through `_SetControlSizePos` → `MOVEWINDOW`. Forms are read with `GetWindowRect` and written with `MoveWindow` (`_Get/_SetWindowSizePos`). PRG code mixes stored values with `GetWindowWidth()` and scrollbar metrics (spinner, browse scroll parts).

### 2.2 Decision: one rule, applied at the Win32 boundary

**Programs and the PRG library see design units (pixels at 96 DPI) everywhere; C converts.** Opt-in:

```
SET DPIAWARE PERMONITOR      // before the first DEFINE WINDOW; HMG_SetPerMonitorDpi( .T. ) -> lActive
```

Without it nothing changes (every conversion is a no-op; the matrix shows the old behaviour). The manifest is not changed: the GUI thread switches itself to Per-Monitor-V2 with `SetThreadDpiAwarenessContext`, which works on top of the system-aware manifest (Windows 10 1703+; older systems return `.F.`).

| Where (all in C) | Conversion |
|---|---|
| thread CBT hook, `HCBT_CREATEWND` | child of an HMG form: x, y, cx, cy × dpi/96; HMG top-level form: cx, cy × monitor dpi/96 (screen positions stay in pixels) |
| `MOVEWINDOW`, `SETWINDOWPOS` | same scaling (respects `SWP_NOMOVE` / `SWP_NOSIZE`) |
| `GETWINDOWWIDTH/HEIGHT`, size part of `GETWINDOWRECT`, `GETCLIENTAREAWIDTH/HEIGHT` | ÷ dpi/96 |
| `GETVSCROLLBARWIDTH`, `GETHSCROLLBARHEIGHT` | the 96-DPI metric (`GetSystemMetricsForDpi`) |
| `_SETFONT`, `SETFONTNAMESIZE` | font height for the window's DPI instead of the desktop's |
| list-view columns (`INITLISTVIEWCOLUMNS`, `LISTVIEW_ADDCOLUMN`, `LISTVIEW_SET/GETCOLUMNWIDTH`) | × / ÷ dpi/96 (negative auto-size codes pass through) |
| panels (`_Get/_SetWindowSizePos`, PRG) | client pixels from `ScreenToClient` ÷ dpi/96 |

"HMG form" = a window whose class uses HMG's `WndProc` (forms, panels, split children): an exact test, no list to maintain. Windows that comctl32 creates inside a control (combo edit, list header) have a control as parent, so they are never touched and size themselves.

Why a creation hook instead of changing each `Init*` function: one place covers all ~40 control types, HFCL and user C code that creates children of a form. The stored values in `_HMG_SYSDATA` stay design units, so `GetProperty`, the `HMG_Control` objects, the IDE's `.fmg` values and every `Form.Control.Row := ...` keep their meaning.

### 2.3 DPI change

`WndProc` (`c_EventCB.c`) passes `WM_DPICHANGED` to `HMG_DpiWndProc` (`c_dpi.c`): the form stores the new DPI (window property), takes Windows' suggested rectangle, then `_HMG_DPIRESCALE( hWnd, nOldDpi )` (`h_dpi.prg`):

- every control of the form: `_SetControlSizePos` with its stored design values (MOVEWINDOW converts for the new DPI; tabs, radio groups, spinners, browse use their existing code paths);
- grid/browse columns: widths × new/old;
- font: the control's **current** font (`WM_GETFONT` → `LOGFONT`) created again for the new DPI. This covers controls that store no font name (they use the `SET FONT` default; `HMG_CTL_FONTNAME` is NIL), found by a slot dump. Exact height when the control stores a size;
- panels: placed again from their pixels at the old DPI, then rescaled recursively.

### 2.4 API

| | |
|---|---|
| `SET DPIAWARE PERMONITOR` / `SYSTEM` | `HMG_SetPerMonitorDpi( lOn )` → active state; refused once a window exists |
| `HMG_GetFormDpi( cForm )` | DPI the form is laid out for (96 when off) |
| `HMG_DPI_SCALE( hWnd, n )`, `HMG_DPI_UNSCALE( hWnd, n )` | for user code that calls Win32 directly |
| `HMG_DPI_SIMULATE( hForm, nDpi )` | runs the `WM_DPICHANGED` path (tests; one-monitor machines) |

Dot-syntax note found while testing: `Form.Width := Form.Width` does not compile in HMG (the `<c>` marker swallows it, as with `Title` in 1.6); use `SetProperty/GetProperty`.

### 2.5 Tests

`tests/unit/dpi` (73 checks, both library modes): label, textbox, radio group, spinner, grid (columns), a button in a tab, a panel with a label, the form; at the monitor DPI, then simulated 192, 144 and back: real pixel widths = design × dpi/96, properties unchanged, form size stable over repeated read-modify-write, fonts (explicit and default) at the new height, a control created after a DPI change, the mode cannot be switched off. A visual check at a simulated 144 DPI (text, combo height, grid rows, tab) looked right.

### 2.6 Status and open points (11-11-2026)

- Done: 2.2-2.5. Matrix green (21 suites per mode).
- Not verified: a real second monitor with another DPI (this PC has one 96-DPI screen; the change path is exercised by simulation only), Windows older than 10 1703.
- Not scaled yet: toolbar button and image sizes, image lists (grid/tree/tab images), `IMAGE` pictures (scaled only by their control size), SPLITBOX bands, status-bar part widths, MonthCalendar font (`c_monthcal.c` calls `PrepareFont` without a window), `DRAW` / print preview coordinates. Each needs the same rule at its Win32 call.
- Windows created on other threads are not scaled (the hook is per thread; HMG GUI belongs on the main thread, PHASE3-DESIGN.md 4.5).

---

## 3. Dark mode

### 3.1 Decision

Opt-in, before the first window (form classes and control themes are set as windows are created):

```
SET DARKMODE ON | OFF | AUTO      // HMG_SetDarkMode( xMode ) -> lActive; AUTO = Windows' app mode
HMG_IsDarkMode() -> lOn
```

The lever is the **system colour**, not `Events()`. Events() (3,000 lines) paints every control that has no BACKCOLOR/FONTCOLOR with `GetSysColor(COLOR_3DFACE / COLOR_WINDOW / COLOR_MENU)` and sets no text colour. So (`c_dark.c`):

| Piece | Effect |
|---|---|
| `HMG_SysColor()` behind `GETSYSCOLOR` (and the ROUNDED / modern-tab fallbacks) | dark palette for 3DFACE, WINDOW, MENU, text and gray text; Events(), grids and user code that ask for system colours get dark ones |
| `WndProc`: on `WM_CTLCOLOR*`, dark text/background on the DC **before** Events() | controls without FONTCOLOR get light text; Events() still overrides with explicit colours |
| `WndProc`: colour message Events() did not answer | dark brush |
| `REGISTERWINDOW` | form without BACKCOLOR: dark class brush |
| thread `WH_CALLWNDPROCRET` hook on `WM_CREATE`, by class | dark title bar (DWM attribute 20, 19 before 20H1); `DarkMode_Explorer` / `DarkMode_CFD` / `DarkMode_ItemsView` themes; list-view and tree colours; tabs switched to the existing modern owner-drawn tab with dark colours; rich edit colours; check boxes, radio buttons and group boxes un-themed (themed ones draw black text whatever `WM_CTLCOLORSTATIC` says) |
| client-edge controls (text boxes, lists, grids, trees) | the light 3D edge is repainted dark grey after `WM_NCPAINT`; blue while focused |
| `_GETTABBRUSH` | solid form colour (controls on tab pages) |
| grid custom draw defaults (`h_GridEx.prg`) | palette instead of hard-coded white/black (only in dark mode) |
| popup menus | uxtheme `SetPreferredAppMode(ForceDark)` + `FlushMenuThemes` (ordinals 135/136, build ≥ 18362 only) |

Only windows inside an HMG form are styled (tooltips: owned by one): message boxes, TaskDialogs and common dialogs stay as Windows draws them. Palette: background 32,32,32; inputs 45,45,45; text 235,235,235.

### 3.2 Why not a different way

- Patching each colour branch in `Events()`: ~30 places, and members' code that calls `GetSysColor()` for its own drawing would stay light.
- Changing the manifest / a process-wide theme: Windows has no supported dark mode for classic Win32 controls; the theme names above are what Explorer and Notepad use.
- Owner-drawing check boxes and radios: possible later; un-theming gives correct colours now with the classic glyph.

### 3.3 Tests

`tests/unit/darkmode` (17 checks, both modes): off by default and light palette untouched; palette values; dark title bar (`DwmGetWindowAttribute`); grid back colour; and **rendered pixels** via `PrintWindow`: form, label, text box, grid row, tab page and a check box on a tab paint dark, while a label and a text box with BACKCOLOR keep their colour; the mode cannot be switched off once windows exist. Visual check of a form with 16 control types (screenshots during development).

### 3.4 Known gaps

- Menu bar stays light (needs undocumented UAH owner-draw messages); popup menus not verified visually (keyboard simulation did not open them).
- Light outlines remain on group boxes (FRAME), the tab control's border and spinner arrows; DATEPICKER, MONTHCALENDAR, status bar and toolbar stay light.
- Message boxes, TaskDialog (`SET MSGBOXMODERN`) and file dialogs (classic or modern, section 4) follow Windows, not the program.
- No switching at run time (needs restyling every existing window); AUTO reads the setting once.

### 3.5 Status (11-11-2026)

Done as above; matrix green (22 suites per mode).

---

## 4. File dialogs (IFileDialog)

### 4.1 Decision

`SET FILEDIALOG MODERN` (`HMG_SetFileDialog( "MODERN" | "CLASSIC" | lModern )`, `HMG_IsModernFileDialog()`) makes `GetFile`, `PutFile` and `GetFolder` use `IFileOpenDialog` / `IFileSaveDialog`. Default CLASSIC: nothing changes for existing programs. Unlike DPI and dark mode it can be switched at any time (no window depends on it).

The switch is at the C entry points (`C_GETFILE`, `C_PUTFILE`, `C_GETFOLDER` in `c_dialogs.c`), so the PRG wrappers and programs that call the C functions directly behave the same. `SOURCE/c_filedlg.c` holds the modern code: plain C COM (`COBJMACROS`), local GUIDs (user programs need no `libuuid`), strings converted to UTF-16 at the boundary in both library modes.

Same arguments and return values as the classic dialogs:

| | Classic | Modern |
|---|---|---|
| GetFile | `GetOpenFileName`, 1024 × `MAX_PATH` buffer | `IFileOpenDialog`, no buffer; one file → string, several → array (as before) |
| PutFile | `GetSaveFileName`, 1024-char buffer | `IFileSaveDialog`; default name may contain a folder; `@cExt` and `@nFilterIndex` returned as before |
| GetFolder | `SHBrowseForFolder` tree, `MAX_PATH` | Explorer folder picker (`FOS_PICKFOLDERS`), search, address bar, typed paths |
| Current directory | changed to the file's folder unless NOCHANGEDIR | the same, done explicitly (the dialog runs with `FOS_NOCHANGEDIR`) |
| Filters | `"name\0spec\0…"` | the same string turned into `COMDLG_FILTERSPEC`; index kept |

When the modern dialog cannot serve a call, the classic one runs: COM not usable on the thread (multithreaded apartment), or `GetFolder` asked for files, computers or printers (`BIF_BROWSEINCLUDEFILES`, `BIF_BROWSEFORCOMPUTER`, `BIF_BROWSEFORPRINTER`).

### 4.2 Differences that remain

- `GetFolder`: the picker has no root folder, so `nCSIDL_FolderType` becomes the starting folder when no `cInitPath` is given. The title is the window caption, not a line above the tree. The New Folder button is always there. An invalid typed name is reported by Windows, not with `cInvalidDataMsg`.
- On Windows 10/11 the classic `GetOpenFileName` without a hook already shows the Explorer-style window. The visible change is mostly in GetFolder; for GetFile/PutFile the gain is no fixed buffers and one code path for later work (custom places, events).

### 4.3 Tests

`tests/unit/filedlg` (28 checks, both modes). A helper thread (C in the test, `#pragma BEGINDUMP`) finds the dialog the process opened, types into the focused file-name box and presses OK or Cancel. If a dialog does not accept the answer it is cancelled, so the test cannot hang. Checked:

- classic and modern give the same result for the same answer;
- dialog kind (`HMG_FILEDIALOG_LASTKIND()`) and caption;
- NOCHANGEDIR, and the change of directory without it;
- multiselect with two files and with one;
- cancel;
- PutFile default extension, `@cExt` / `@nFilterIndex`, default name with a folder;
- GetFolder starting folder and result;
- fallback to the classic tree for `BIF_BROWSEINCLUDEFILES`;
- switching back to CLASSIC.

### 4.4 Status (12-11-2026)

Done as above; matrix green (23 suites per mode). Not tested: paths longer than `MAX_PATH` (they need long-path support enabled in Windows) and non-ASCII names typed into the dialog.

---

## 5. PDF through the Windows print pipeline

### 5.1 Problem (measured in the code)

HMG had two separate ways to make a PDF, and neither matches the printout:

- **`SELECT PRINTER PDF`** sends every `@ … PRINT` to a second drawing engine, libHaru (`h_HMG_HPDF.Prg`, 2,100 lines). It has its own fonts and positioning, its own subset of each command (no `ANGLE`, JPG/PNG images only, no transparency), and limited Unicode, so the PDF differs from print and preview.
- **The preview's "Save as PDF"** (and `SAVEAS "x.pdf"`) turns each page into a 300-DPI bitmap and saves it as JPEG inside a PDF. The files are large, the text can't be selected or searched, and it is blurred.

### 5.2 Decision: print to the Windows PDF printer

`SET PDFENGINE WINDOWS` (`HMG_SetPdfEngine()`, `HMG_PdfEngine()`); default `HARU`, so nothing changes otherwise. It can be switched at any time.

With WINDOWS:

- **`SELECT PRINTER PDF <file>`** opens the "Microsoft Print to PDF" printer, which is part of Windows 10/11. The printer is found by its driver name, because the queue can be renamed. Setup is the same as `SELECT PRINTER`, without preview; ORIENTATION and PAPERSIZE take the same values as before. `START/END PRINTDOC` and every `@ … PRINT` then run the normal GDI printer code, so the PDF is the printout: any Windows font embedded as TrueType, Unicode, rotated text, every image type, selectable text (`/ToUnicode`).
- **No Save dialog:** the file name goes to `StartDoc` (`DOCINFO.lpszOutput`), made absolute first because the spooler writes the file. It applies only to the DC that `SELECT PRINTER PDF` created, so a printer selected later is not affected.
- **`END PRINTDOC` waits** until the job has left the spooler queue and the file is closed, up to 60 s. The program can open or mail the file right after.
- **Preview "Save as PDF" / `SAVEAS`** sends the preview's EMF pages to the same printer (`HMG_PDF_FROMEMF`). Pages stay vector. The sheet is the standard size that holds the page (A5 to A3, Letter, Legal, Tabloid).
- **Falls back to libHaru**, as before, when the printer is not installed or when a custom size (`PAPERSIZE 256` / `PAPERLENGTH` / `PAPERWIDTH`) is asked for, which the Windows PDF printer cannot do. The preview save falls back to the raster pages.

C: `SOURCE/c_pdf.c`; hooks in `_HMG_PRINTER_STARTDOC/ENDDOC/ABORTDOC` (`c_controlmisc.c`). PRG: `SOURCE/h_pdf.prg` (`_HMG_PDF_SELECT`, called by both `SELECT PRINTER PDF` commands in `i_print.ch`).

### 5.3 Why not a different way

- **Updating libHaru and mapping each command better** keeps two engines and two sets of bugs; fonts and Unicode in libHaru need font files and encodings that HMG would have to manage.
- **A new PDF writer (e.g. GDI → PDF in Harbour)** is a large project for what Windows already does.
- **Direct2D / XPS printing** replaces the GDI drawing that print, preview and every user `OpenPrinterGetDC()` program rely on.

### 5.4 Tests

`tests/unit/pdfwin` (22 checks, both modes) reads the files it produces as PDF:

- default HARU; WINDOWS selects the GDI path;
- A4 portrait with two pages; the file is complete as soon as `END PRINTDOC` returns;
- three embedded TrueType fonts (bold, regular, Times New Roman), `/ToUnicode`, no page images, not libHaru;
- landscape, and a relative file name;
- `ABORT PRINTDOC` leaves no file;
- a custom size goes to libHaru;
- three EMF preview pages give a three-page vector A4 PDF.

The test is skipped, not failed, where the printer is not installed. The existing `hpdf` suite still covers libHaru.

### 5.5 Known gaps

- Size: fonts are embedded as subsets. A 2-page document with three fonts is about 230 KB, against a few KB for libHaru's base-14 fonts, which are not embedded.
- The PDF printer renames fonts (`CIDFont+F1`) and writes no title or author.
- No custom sheet sizes; the HARU engine stays for those.
- Needs the Print Spooler service and the "Microsoft Print to PDF" Windows feature (both on by default).
- The preview save places each page at the top-left of the sheet, as when the preview is printed on another printer.
- Not checked by eye in this session: no PDF renderer was available here. The checks are structural.

### 5.6 Status (12-11-2026)

Done as above; matrix green (24 suites per mode).

---

## 6. IDE revamp (plan)

### 6.1 Starting point (measured, 12-11-2026)

- **Source:** HMG IDE 1.3b (Roberto Lopez, GPL v2+ with the HMG exception), from the HMG 3.7 tree (`danielmaximiliano/HMG.3.7`, commit `7563ff9`, `source/IDE_SourceCode`). Imported unchanged to `SOURCE/IDE_SourceCode` (163 files).
- **Builds and starts** with the HMG5 toolchain and library without source changes: a UNICODE build of 6.1 MB. The only change needed was the resource paths in the `.rc`, which name files in `Resource\` without the folder.
- **One file is built:** `Source/IDE_SourceCode.prg`, 45,400 lines, with `#pragma -w2`. The other 15 `.prg`/`.txt` files in `Source` are copies of procedures from it, extracted for study (with Spanish notes, `*.md`); they are not built and would drift.
- **Size is in a few procedures:**

  | Procedure | Lines |
  |---|---|
  | `_Open` (`.fmg` loader) | 11,537 |
  | `PropertyEdit` | 8,398 |
  | `AddControl` | 2,291 |
  | `GenCode` | 1,260 |
  | `UpdateControlProperties` | 918 |

- **Style:**
  - 2,413 `IF` lines against 30 `CASE`; one branch per control type and property.
  - 125 `PUBLIC` and 83 `PRIVATE` variables, among them one counter per control type (`ButtonCount`, `GridCount` …).
  - 254 lines with `&` macros.
- **Defects seen in the first run:**
  - the status bar says "HMG 5.0 Test (32 bits)": `HMG_GetCompileVersion64()` in the library (`h_error.prg`) passes `.F.` as "is 64-bit";
  - a status-bar hint is hard-coded in Spanish, whatever the language;
  - `hmg.ini` / `editor.ini` in the source folder hold paths from another machine (`c:\hmg.3.7`). Without them the IDE takes the parent of its own folder as the HMG root, which is correct for `<HMG>\IDE\IDE.exe`.

### 6.2 Rules

- **No feature removed.** Every menu, builder, report designer and option keeps working.
- **The `.fmg` format does not change.** A form saved by HMG 3.x opens in the new IDE, and a form saved by the new IDE opens in HMG 3.x. Generated `.prg`/`.fmg` text stays the same unless a change is intended and documented.
- **A safety net before any rewrite** (step I2). Changes are measured as in Phase 3.
- **64-bit only** (owner's decision, 12-11-2026): no 32-bit build option, `build.bat` path or "32 bits" text.
- **Small HMG5 conveniences only**, no new IDE architecture.

### 6.3 Steps

| # | Step | Done when |
|---|---|---|
| I0 | **Baseline:** commit the import as-is; then a project file that builds `IDE\IDE.exe` (UNICODE and ANSI), resource paths fixed; extracted copies (`*.txt`, split `*.prg`) and the foreign `*.ini` removed; Spanish notes moved to `SOURCE/IDE_SourceCode/notes/` | `hmgbuild` builds the IDE; the IDE starts |
| I1 | **64-bit only:** Build menu (32/64) and `BuildIn64bits` removed, always `build64.bat`; library fix for "(32 bits)" | no 32-bit reference left; status bar right |
| I2 | **Safety net:** a test switch (`IDE.exe /roundtrip in.fmg out.fmg`) that opens a form in the designer and saves it; a test runs it over a corpus (samples, `Forms\`, synthetic forms with every control type and property) and compares | corpus round-trips unchanged, in `hmgbuild matrix` |
| I3 | **Modules, then table-driven core:** split the 45K-line file into modules by responsibility (main/menus, designer, `.fmg` loader, `.fmg` writer, property inspector, builders, report designer, project/build, C helpers); then one table per control type (properties, events, defaults, `.fmg` keywords) used by `_Open`, `Save`, `AddControl`, `PropertyEdit`, `UpdateControlProperties`; the per-type counters become one hash | I2 green after each move; line count and load/save time measured before and after |
| I4 | **HMG5 features in the designer:** WEBVIEW control; project options for `SET DPIAWARE`, `DARKMODE`, `FILEDIALOG`, `PDFENGINE`; the IDE itself DPI-aware with modern file dialogs | new controls round-trip in I2 |
| I5 | **Designer: snap to grid** (owner's request, 12-11-2026). It exists but is wrong: on create and move it adds `10 - last digit`, so 40 becomes 50 and 41 becomes 50 (always the *next* multiple); resize rounds down; the size is fixed at 10 in PRG and C. Fix: round to the **nearest** grid line on create, move and resize; grid size in Preferences (5, 8, 10, 16, 20); grid display on/off; arrow keys move the selection by 1 px (Ctrl: one grid step) | positions land on the grid (unit test on the rounding; `/addall` reference updated on purpose) |
| I6 | **Code editor** (owner's request). (a) **Done:** Notepad++ language file generated from HMG5's own headers (`tools/editor`, 3,185 words, folding of all `DEFINE … END` blocks). (b) **Built-in editor:** Scintilla + Lexilla (BSD-style licence) as an HMG control with an HMG5 lexer list from the same generator; needs the Scintilla sources downloaded (owner to approve) | (b) opens, colours and saves `.prg`/`.fmg`; external editor stays selectable |
| I7 | **Friendlier, light touch:** clickable build errors (file, line) from the build log (ADOPTION L2); recent projects; English hint texts from the language files | each item small, no forced change |

**Ideas from the owner (12-11-2026), to be designed; not committed to yet:**

| # | Idea | First thoughts |
|---|---|---|
| I8 | **Project-only mode:** many members write their forms in code and use the IDE only to manage `.hbp` projects and build them from a GUI. An option (View or Preferences) hides the toolbars, the Object Inspector and the default form, so the IDE becomes a project builder; one tool for both kinds of user | The pieces exist: project browser, `OpenProject`, `NewBuild`/`build64.bat`, the build log. Needs: a remembered mode, a list of recent projects (I7), and starting without creating a form. Could also manage a *collection* of projects (a workspace list of `.hbp` files) |
| I9 | **Grid behind the controls:** the dots are drawn with `GetDC` on top of everything after each move (`DRAWDESIGNGRID`) | Paint the grid as the design form's background, a dotted pattern brush of the grid size, so child controls cover it and nothing redraws it by hand; fits with I5 |
| I10 | **Object tree:** a window listing the form's controls (by tab page, frame, split box) to select the one being edited | `_HMG_SYSDATA` already holds parent and container per control; selecting calls the existing `SelectControl()` |
| I11 | **One main window** instead of three floating ones (main/toolbar, Project Browser, Object Inspector) | Largest change: dock the browser and inspector as panels of one resizable window (HMG `PANEL` windows or split boxes); the design form stays a separate window. After I3 (modules), so it touches small files |

The IDE is not in the library, so `hmg64.hbp` is unchanged. `hmgbuild ide` builds `IDE\IDE.exe` in the mode LIB-64 was built in, and `hmgbuild idetest` also runs the round trip. `hmgbuild matrix` builds the IDE in ANSI (build check) and in UNICODE (build + round trip).

### 6.4 Status (12-11-2026)

- **I0 done.**
  - The as-is import is commit `cc6c21e`.
  - `SOURCE/IDE_SourceCode/IDE.hbp` + `IDE.rc` (resource paths fixed, both mode bitmaps) replace the per-mode files that wrote to `c:\hmg.3.7`.
  - Removed: 22 extracted copies and the foreign `*.ini`.
  - The Spanish notes are in `notes/`.
- **I1 done.**
  - The Build menu, `BuildIn64bits` and `UseBuildBat.ini` are gone; `build64.bat` is always used.
  - Library: `HMG_GetCompileVersion64()` said "(32 bits)".
- **I2 done:** `tests/ide` (18 checks).
  - **Test modes:** `IDE.exe /roundtrip <in> <out>` opens a form in the designer and saves it; `IDE.exe /addall <in> <out>` first places one control of every palette type, as a click would. Both work from timers: the designer runs a nested message loop (`ACTIVATE WINDOW` without NOWAIT), as it does when used from the menu.
  - **Corpus (17 forms):** the IDE's 12 forms, 4 sample forms, and a synthetic form with all 27 control types.
  - **Each form must:** load and save without error, give the same text when saved twice (a fixed point), and match the reference.
  - **Found and fixed:** `LOCKCOLUMNS Nil` was read back as 0, so the text of a grid changed on every second save.
  - **Seen, kept as baseline:** Tree and Tab get fractional columns (`AT 180 , 600.00`); one palette entry adds no control on a plain form.

---

## 7. Later items (outline only)

- **Print preview window**: still the HMG 3 window (no DPI or dark styling of its own drawing, EMF files in the temp folder); a candidate for after the benchmark.
