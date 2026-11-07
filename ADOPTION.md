# What HMG5 takes from HMG 3.7, Workspace and HB_WebView

Status: A2–A6 **ported** (07-11-2026, see section 5); A1 (HB_WebView) under review for Phase 4.

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

HB_WebView (A1) is reviewed separately for Phase 4 (WebView2 to replace QHTM).
