# HMG Web: early design notes (a separate project, not HMG5)

Status: ideas only, 12-11-2026. To be designed properly and started after the HMG 5.0 release. Nothing here changes HMG5.

## 1. Decision

HMG5 stays a **Windows desktop** library: forms at fixed positions, blocking code (`MsgYesNo()`), direct Win32. A browser version needs the opposite of each of these, so it will be a **separate product, "HMG Web"**, designed for the web from the start, not a web mode bolted onto HMG5.

The owner's words:

> "My dream is to make HMG a modern visualization tool also, where people can have the proper security by logging into an application. … host in a network (local), in a browser, any page that can be created by HMG code."
>
> "Login and roles can be decided by the user/developer from the database."
>
> "For [the] web version of HMG we may not require rows and columns. HMG way of handling cookies, client/server concepts, abstracting the server, segregating server events [and] client events, and [the] client shall reduce as much as possible the messages with [the] server; security; device responsiveness … When it comes to the HMG Web version, it may run even in Harbour Linux also."

## 2. Principles

| Topic | Direction |
|---|---|
| Platform | **Pure Harbour on the server**: sockets, threads, JSON; no Win32. Runs on Windows and **Linux**, tested on both from the first step. |
| Familiar feel | HMG-style declarations (`DEFINE PAGE … END PAGE`, `DEFINE TEXTBOX name … END TEXTBOX`, readable property names), so HMG developers feel at home. |
| Layout | **Responsive**, not pixel rows and columns: rows of columns with breakpoints (a 12-column grid), so one page works on phones, tablets and desktops. |
| Events | **Declared on two sides.** Browser-side: validation, input masks, enable/disable rules, simple calculations, run without a server round trip. Server-side: database work and business rules, in Harbour. The page says which is which, keeping traffic small. |
| Server | **Abstracted**: the developer writes pages and handlers, not HTTP. Sessions, cookies, HTTPS, request limits and logging are built in. |
| Login and roles | The **developer's**, from their own database, through a login hook. The framework provides the session and the checks, not the user table. |
| Browser runtime | A small script that draws pages from a description the server sends, and applies changes. Charts use Apache ECharts (as HMG5's CHART control does). |
| Security | Only handlers the page declares can be called (no function names from the browser); values checked against the declared type; HttpOnly, SameSite session cookie; CSRF token; LAN-only binding and HTTPS options; size and rate limits. |

## 3. What HMG5 and HMG Web share

**Business code, not screens.** Database access, calculations and reports written in plain Harbour modules with no UI can be used by an HMG5 desktop program and by an HMG Web app. That is the realistic way to reuse work across both.

Also shared: the Harbour language, the HMG naming style, and the ECharts option format (an HMG5 CHART option or a GraphPlus `:Option()` can be shown in HMG Web too).

## 4. Earlier idea, kept for reference: HMG5 forms in the browser

Considered on 12-11-2026 and set aside in favour of the separate product. Rendering existing HMG5 forms unchanged in a browser would work like this:
- one Harbour thread per session (own PUBLIC `_HMG_SYSDATA`);
- `_DefineXxx` recording virtual controls instead of Win32 windows;
- `ACTIVATE WINDOW` and `MsgYesNo()` blocking the session thread on browser events;
- absolutely positioned HTML.

**Why it was set aside:**
- It inherits pixel layouts (no responsiveness).
- Every event becomes a server round trip.
- It would need a web branch in the 51 `_DefineXxx` functions and in Get/SetProperty, plus making HMG's STATIC and C state per session.
- It ties the web side to Windows.

## 5. Next steps (after HMG 5.0)

1. A design note for the page description (JSON), the event model (browser and server), the layout grid and the security model.
2. A spike on Linux and Windows: one page, a TEXTBOX with a browser-side mask, a BUTTON with a server handler, a session cookie.
3. A decision on the server core: Harbour sockets, or the `hbhttpd` contrib.
