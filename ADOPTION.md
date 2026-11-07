# What HMG5 takes from HMG 3.7, Workspace and HB_WebView

Status: A2–A6 **ported** (07-11-2026, section 5); A1 (HB_WebView) reviewed, deferred to Phase 4 (section 6).

Sources looked at:

| Source | Where | Licence |
|---|---|---|
| HMG 3.7 (Daniel Maximiliano, Claudio Soto) | `D:\hmg.3.7` | HMG licence (GPL v2+ with linking exception), same as HMG5 |
| Workspace IDE (Daniel Maximiliano) | `D:\hmgworkspace\WorkSpace` | its `source\gui` is an HMG fork under the HMG licence |
| HB_WebView 6 (Claudio Soto) | hmgforum.com t=7659, `hb_webview_6.rar` | wrapper: GPL v2+ with Harbour exception; webview library: MIT |

## 1. How HMG 3.7 relates to HMG5

3.7 starts from the **original** 3.6 sources, so it has none of HMG5's Phase 1 fixes (string leak, buffer overflows, NULL crashes, DLL hijacking, shared temp file). Diffed against the pristine 3.6 import (`bcf17fa`), its real changes are new features in about 15 files plus small fixes. **Rule: port 3.7 features onto HMG5; never copy 3.7 files over HMG5 files.**

3.7 grows `_HMG_SYSDATA` from 518 to **521** slots (519 tooltip style, 520 tooltip font cache, 521 `ROUNDED` radius). HMG5 should use **the same slot numbers**, so programs and `.ch` files stay interchangeable between 3.7 and HMG5. This is append-only, so it keeps the S1 promise (no slot renumbered or removed).

## 2. Shortlist

### Adopt (recommended)

| # | What | From | Why | Notes |
|---|---|---|---|---|
| A1 | **HB_WebView** as an optional library, built from source | Claudio, t=7659 | HTML/JS user interfaces and reports from Harbour/HMG (bind Harbour functions to JavaScript, call JS from Harbour) | C++ (`hbmk2 -cpp`); WebView2 runtime is part of Windows 10/11; built-in WebView2 loader, so no `WebView2Loader.dll` to ship. Ship as `libhb_webview-64.a` + `hb_webview.ch` + demos; opt-in per project. Keep its licence files. |
| A2 | `SET MSGBOXMODERN` (TaskDialog message boxes) | 3.7 `c_msgbox.c` | Windows 10/11 look for MsgBox/MsgInfo/MsgYesNo… | 3.7 makes it **ON by default**. Proposed for HMG5: **OFF by default** (existing programs look and behave as before), opt-in with `SET MSGBOXMODERN ON`. **Decision needed.** |
| A3 | `ROUNDED <n>` for FRAME, TEXTBOX, EDITBOX, RICHEDITBOX | 3.7 | modern look, opt-in per control | slot 521. Port with HMG5's safety rules (bounded copies, frame-owned strings). |
| A4 | Tooltip styling: `SET TOOLTIPROUND / MARGIN / FONT / BORDERCOLOR / GRADIENT / THEME` | 3.7 | consistent modern tooltips | slots 519/520; custom-draw is switched on by default in 3.7 (`_HMG_SYSDATA[509] := .T.`): HMG5 keeps the 3.6 default unless set. |
| A5 | `SET MENUHOVER ON/OFF [OF form]` | 3.7 `h_menu.prg`, `c_windows.c` | opens menu popups on hover | opt-in; 3.7 left trace copies of `h_menu.prg` (`.pre-trace`, `.traced`, `.pre-dwell-poll`); not taken. |
| A6 | Modern TAB drawing (`TabSetModern`) | 3.7 `c_tab.c` | | opt-in |
| A7 | Small fixes: MsgBox array elements on separate lines; `€` accepted in numeric input masks | 3.7 `h_msgbox.prg`, `h_textbox.prg` | | |

### Consider later

| # | What | From | Why later |
|---|---|---|---|
| L1 | Scintilla code-editor control (`gui_scintilla.ch`) | Workspace | Valuable for the IDE (syntax colouring, folding); large (≈1,800 files of Scintilla source). Belongs with the IDE work. |
| L2 | Structured build diagnostics: hbmk2/GCC output parsed to file, line, severity; clickable errors | Workspace build service | Idea for the HMG5 IDE and `hmgbuild`; their code is a separate service architecture, so take the design, not the code. |
| L3 | IDE source documentation (`IDE_SourceCode\Source\*.md`, e.g. `_open.md`) | 3.7 | Explains the legacy IDE's form loader/saver; useful before touching the IDE. Spanish; would need translating. |
| L4 | **Revamp the HMG IDE** (Roberto Lopez's IDE; source published by Claudio Soto, copy in Workspace `Source`) | Daniel (07-11-2026) | Its `NewForm()` is thousands of IF statements per control and property: a candidate for table-driven code, measured first as in S2/S4. Workspace adds a `.frm` file (container of a project's `.fmg` forms, made by parsing the `.prg` files of an `.hbp`), so a project is `.hbp` + `.hbc` + `.rc` + `.frm`. Planned with the IDE work (test the IDE first). |

### Not adopted

| What | Why |
|---|---|
| Workspace `gui.ch` header split (per-control headers, `GUI/*.ch`) | renames every include; HMG5 keeps `hmg.ch` / `minigui.ch` for compatibility |
| Workspace's bundled Harbour/hbmk2 tree, service executables | HMG5 has its own toolchain and one-folder setup |
| 3.7 versions of files HMG5 already fixed (e.g. `c_button.c`/`c_image.c` temp file, `c_tree.c` `lstrcpy`, `LoadLibrary` instead of `HMG_LoadSystemLibrary`) | would undo Phase 1 security fixes |

## 3. Practices worth copying

- **Opt-in for anything visual** (3.7 does this for `ROUNDED`): existing programs must look the same after upgrading.
- **Comment the slot use next to the code** (3.7 lists 519–521 in `h_init.prg`); HMG5 now does this centrally in `INCLUDE/hmg_sysdata.ch`.
- **One responsibility per component, stable public contract** (Workspace "Service Design Guidelines"): matches S3 (a small public control API over private storage).
- **Written design notes before large changes** (Workspace `Foundation\`): HMG5 already does this (`PHASE3-DESIGN.md`, this file).

## 4. Decisions needed

1. `SET MSGBOXMODERN`: default **OFF** (proposed) or ON as in 3.7? — implemented as OFF; one line to change if you prefer ON.
2. Ship **HB_WebView** in the HMG5 setup as an optional library (proposed: yes)?
3. Order: port A2–A7 before or after S3–S5? — done after S3.

## 5. Port status (07-11-2026)

A2–A6 are ported onto HMG5 (3.7 code reviewed, not copied). All opt-in: a program that does not use them looks and behaves as with 3.6. Test: `tests/unit/port37` (41 checks, both modes), plus a visual check of rounded controls, the modern tab and hover menus.

| # | Ported as | HMG5 corrections / optimisations against 3.7 |
|---|---|---|
| A2 | `SET MSGBOXMODERN ON/OFF/TO`, `SetMsgBoxModern()` → previous value; `c_msgbox.c` | Default **OFF**. Works in the ANSI library too (3.7 read `HMG_parc` as `WCHAR*`); comctl32 found via `GetModuleHandle`/`HMG_LoadSystemLibrary` (3.7: `LoadLibrary`); TaskDialog only for OK/OKCANCEL/YESNO/YESNOCANCEL/RETRYCANCEL, other styles keep `MessageBox` and its localised buttons; timeout uses wrap-safe tick arithmetic. |
| A3 | `ROUNDED <n>` on TEXTBOX/EDITBOX/RICHEDITBOX/FRAME, `GetProperty/SetProperty(...,"Rounded")`, `Form.Control.Rounded` | New `c_rounded.c`. 3.7's SetProperty compared against type names that do not exist (`TEXTBOX`, `EDITBOX`), so it never applied — fixed. Painting fills straight edges with `FillRect` and blends only the corners (3.7 looped over every pixel with `GetPixel`); per-control data hangs on the subclass and is freed on `WM_NCDESTROY`; `ROUNDED 0` removes the subclass; radius clamped to 0..20. Frames are rounded only with `ROUNDED` (3.7 rounds every frame). Dot syntax added (3.7 has only Get/SetProperty). |
| A4 | `SET TOOLTIPROUND / MARGIN / FONT / BORDERCOLOR / GRADIENT / THEME`; `c_tooltip.c`, `h_tooltip.prg` | Applied only while `SET TOOLTIPCUSTOMDRAW ON` (slot 509 keeps the 3.6 default `.F.`); `SET TOOLTIPCUSTOMDRAW OFF` gives existing tooltips their native theme back. `ToolTip_SetTitle`: no fixed 64-char buffer (3.7 overflowed it) and no leaked window props. Slots 519/520/521 as in 3.7. |
| A5 | `SET MENUHOVER [OF form] ON/OFF`, `SetMenuBarHover()`; `c_menuhover.c`, `h_menuhover.prg` | Timer id 65521 (3.7 used 23163, which `_GetId()` can hand to a TIMER control on the same form); bar highlight with the documented `HiliteMenuItem` (3.7 looked up an undocumented `MenuSelect` export); menu mode detected with `GetGUIThreadInfo`; unknown form returns `.F.` instead of a runtime error; fast exit in `WM_NCMOUSEMOVE` when no window uses hover. |
| A6 | `TabSetModern( hTab, [strip RGB], [pill RGB], [text RGB], [selected-text RGB], [nMinWidth] )`, `TabClearModern()`, `IsTabModern()` | Colours in per-window data on the subclass instead of a fixed 64-slot table (3.7: limit of 64 tabs, and a reused slot never re-subclassed because the flag survived `WM_NCDESTROY`); brushes created once, not on every erase; a missing colour triple means the system colour (3.7: black). Owner-drawn tabs show text only. |
| A7 | not taken | `€` in numeric masks: already in 3.6/HMG5; 3.7's UTF-8 re-encoding turned it into U+FFFD. MsgBox array elements on separate lines: changes existing output (`MsgInfo( { "Total: ", n } )`). |

Also from 3.7: `TOOLTIP_MENUDISPLAY` hides the tooltip on separators and unknown items; the default-printer lookup no longer uses `_tcstok`; a self-assignment in the menu tooltip code is fixed.

HB_WebView (A1): see section 6.

## 6. HB_WebView review (for Phase 4: WebView2 control to replace QHTM)

Reviewed: `hb_webview.prg` / `hb_webview.ch` (wrapper 1.1.0, Claudio Soto) and the bundled webview library 0.12.0 (MIT, `webview-master`). **Decision: not added to HMG5 now.** It is a standalone-window library (its own `webview_run` message loop), not an HMG control, and its bridge has security problems that must not ship. It is the right base for Phase 4: use the webview core (MIT) and its built-in WebView2 loader, and write a new HMG control around it, taking the points below.

**Must fix before anything ships (wrapper):**

| Issue | Where | Fix for HMG5 |
|---|---|---|
| **Any page script can run any Harbour code.** The bridge builds a string from the page's JSON and runs it with `&cCodeInvoke`; in "indirect" mode the function name itself comes from JavaScript, and "macro" mode runs any macro text. A remote page, or HTML built from data (e.g. a client name containing `<script>`), can call `hb_run()`, `FErase()` and so on. | `hb_webview_HbBridgeJS` | Call only functions the program binds by name (allow-list); call them with `hb_dynsymFindName` + `hb_vmDo` and the decoded values, no macro. Accept bridge messages only from the app's own content (virtual host mapping or `NavigateToString`); check the source origin. |
| Buffer overflow: `strcpy` into `func_name[256]` and into a global `[256]` buffer; NULL `hb_parc` crashes | `HB_WEBVIEW_CREATE_CONTEXT`, `HB_WEBVIEW_SET_CALLHB_FUNC` | `hb_strncpy` / store the name as a Harbour string |
| A Harbour runtime error inside a bound function unwinds through C++ webview frames (undefined behaviour); a non-string result never calls `webview_return`, so the JavaScript promise hangs | `hb_callFunc` | `BEGIN SEQUENCE` in the bridge; always call `webview_return` (status 1 + error text on failure) |
| Bind contexts are `hb_xgrab`'d and never freed; a freed context can still be bound (use-after-free) | `hb_webview_bind2` | Own the contexts per control; free on unbind and on control release |
| `HB_WEBVIEW_DISPATCH` calls any raw pointer passed from PRG as a function | | Do not expose; dispatch a Harbour codeblock instead |

**Integration notes for the HMG control:**
- Embedding works by passing a parent HWND to `webview_create`: the library creates a child "webview_widget" filling the parent's client area and does not call `CoInitialize` or set DPI awareness in that mode (HMG must). It only follows the parent's size when it owns the window, so the HMG control must resize the widget itself on Width/Height/WM_SIZE.
- Do not call `webview_run`: HMG's message loop drives it. Initialisation pumps a nested `GetMessage` loop until WebView2 is ready, so the control must not be created from inside an event that cannot be re-entered.
- User data folder defaults to `%APPDATA%\<exe name>` (cookies, cache, local storage). For CA tools this holds client data: allow a per-app folder and a "clear on exit" option, and say so in the docs.
- DevTools on only when `debug` is set: keep it off in release builds.
- Build: needs C++ (`-cpp`), `-lshlwapi`, static libstdc++. Put the C++ in its own `.cpp` file instead of `#pragma BEGINDUMP` in a `.prg` (faster builds, proper warnings). Use the WebView2 SDK header inside `webview-master` (6,500 lines, current) and drop the separately bundled 2020 `WebView2.h`.
- Character sets: the wrapper's UTF-8 ↔ ANSI handling (`hb_UTF8ToStr` / `hb_StrToUTF8` with a chosen codepage) fits HMG5's two library modes and can be kept.
- WebView2 runtime ships with Windows 10/11; detect it (the library reports `WEBVIEW_ERROR_MISSING_DEPENDENCY`) and show a clear message instead of failing silently.
