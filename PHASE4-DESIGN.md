# Phase 4 design note: modern features

Status: branch `phase4`. **W (WebView2 control) implemented and tested** (11-11-2026, section 1.8); D-I not started.

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

## 2. Later items (outline only)

- **D, DPI**: manifest `PerMonitorV2` behind an opt-in (`SET DPIAWARE PERMONITOR`); on `WM_DPICHANGED` scale each control's Row/Col/Width/Height/font from the stored design values (the `HMG_Control` API from S3 makes this one loop). Default stays system-aware, so existing layouts do not move.
- **K, dark mode**: `SET DARKMODE ON` → `DwmSetWindowAttribute(DWMWA_USE_IMMERSIVE_DARK_MODE)` for title bars, `SetWindowTheme(L"DarkMode_Explorer")` for lists/trees/scrollbars, default BackColor/FontColor from a dark palette; controls with explicit colours keep them.
- **F, IFileDialog**: `SET FILEDIALOG MODERN` makes `GetFile/PutFile/GetFolder` use `IFileOpenDialog`/`IFileSaveDialog`, same arguments and return values; long paths without the `MAX_PATH` buffers.
- **P, PDF/print** and **I, IDE**: to be designed after W-F; the IDE plan (ADOPTION.md L1-L4) needs the IDE sources, which are not on this machine.
