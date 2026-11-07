# Phase 3 design note: HMG internals without breaking HMG programs

Status: **accepted; S1 done** (06-11-2026). Layout frozen, as decision 1 below; slot numbers stay valid for user code.

## 1. Recommendation in one paragraph

Do **not** replace `_HMG_SYSDATA` in HMG5. Treat its slot layout as a **frozen public interface**, and build the improvements around it:

- give every slot a name;
- make lookups O(1) with hash indexes;
- add an optional control-object API on top;
- split the event dispatcher.

Every step leaves existing programs, including ones that read `_HMG_SYSDATA` directly, compiling and behaving the same. A real storage replacement can wait for a later major version, once nothing reads raw slot numbers any more.

This changes AUDIT.md Phase 3, step 1 ("Replace `_HMG_SYSDATA` … with a window/control object model"). Section 2 explains why.

## 2. What the code actually looks like

| Fact | Number | Where |
|---|---|---|
| Slots in `_HMG_SYSDATA` | 518 | `PUBLIC _HMG_SYSDATA [ 518 ]`, `SOURCE/h_init.prg:727` |
| Lines referencing it, library + headers | 10,971 in 80 files | `SOURCE`, `hfcl`, `INCLUDE` |
| Lines referencing it in the **public command headers** | ~1,850; `i_altsyntax.ch` alone has 1,517 | `INCLUDE/*.ch` |
| Most-used slots (occurrences) | `[371]` 975×, `[3]` 547×, `[150]` 540×, `[40]` 342×, `[1]` 306× | |
| Slot documentation | none: the comments say only "Control Data" | `SOURCE/h_init.prg:203-723` |
| Control storage | parallel arrays: `[1][k]` type, `[2][k]` name, `[3][k]` handle, `[4][k]` parent… | e.g. `SOURCE/h_button.prg` |
| Control lookup | macro-named PUBLIC vars: `GetControlIndex` evaluates `&('_' + Form + '_' + Control)` | `SOURCE/h_controlmisc.prg:1054` |
| Linear scans by handle | 24 `AScan( _HMG_SYSDATA[3], … )`, 15 of them in `h_windows.prg` | |
| A real accounting project (kept private, not in the repo) | reads `_HMG_SYSDATA[40][i][…]`, `[37][i]` etc. 27× in 5 files | GridPlus-style contrib code |

Two consequences decide the design:

1. **Compiled user programs contain slot numbers.** `DEFINE WINDOW`, `@ … TEXTBOX` and the other commands expand, in the user's own `.prg`, into `_HMG_SYSDATA[416]`, `[457]` and so on. Renumbering or removing slots breaks every program until it is rebuilt. Programs that use the commands and *also* read slots break even after a rebuild.
2. **Real code reads the slots directly.** Members' grid and search extensions do it, as shown above. An object model that hides the arrays would break exactly the people HMG exists for.

## 3. Options considered

| Option | What it means | Verdict |
|---|---|---|
| A. Replace the storage with objects, keep `_HMG_SYSDATA` as a façade | `_HMG_SYSDATA` becomes an object whose `[]` operator maps to objects | **Rejected.** Code does nested writes such as `_HMG_SYSDATA[1][k] := "BUTTON"`, so the first `[]` would have to return a live write-through proxy for every column. It is slow, fragile and hard to test, and is a big-bang change. |
| B. Freeze the layout, name it, index it, wrap it | Storage stays as it is; names, hashes and an object API are added around it | **Recommended.** Incremental; every step can be verified. |
| C. Leave it | | Rejected: lookups stay slow, and the code stays unreadable and unsafe to change. |

## 4. Proposed design (option B)

### 4.1 Name every slot (no behaviour change)
- **New header:** `INCLUDE/hmg_sysdata.ch` gets one `#define` per slot, e.g. `#define HMG_CTL_TYPE 1`, `#define HMG_CTL_NAME 2`, `#define HMG_CTL_HANDLE 3`.
  - Names come from how each slot is used: what `_DefineXxx()` stores in it and what reads it. Older MiniGUI sources used named arrays (`_HMG_aControlType` …) before HMG 3 numbered them, and they help with naming [Medium].
- **Library rewrite:** the library source moves from magic numbers to these names in a mechanical rewrite. User code may keep using the numbers; both mean the same slot.
- **Proof of no change:** the defines vanish at preprocessing. So the Harbour-generated C for every library `.prg` must be **byte-identical** before and after the rename, and CI compares it.

### 4.2 Faster property calls (re-scoped after measuring)
The original plan was two hash indexes (handle → index, `"FORM.CONTROL"` → index). Measuring first, at 1,000 controls on one form (07-11-2026), showed they would not pay:

| Path, per call | Cost |
|---|---|
| `GetControlIndex` (memvar macro) | 0.7 µs |
| Same lookup through a Harbour hash (prototype) | 1.05 µs: **slower** |
| `AScan( _HMG_SYSDATA[3], h )`, last of 1,000 | 1.0 µs |
| `GetProperty( f, c, "Value" )` on a label | ~58 µs |
| one `SendMessage` (Win32 itself) | 8–11 µs |

Harbour already resolves memvars through its symbol table, and `AScan` runs in C, so hashes in `.prg` code add work. The time in `GetProperty` went to two Win32 messages (~22 µs, unavoidable) and to HMG re-validating the same control over and over: the GridEx, Tree and RichEditBox hooks each re-ran the full guard (~15 µs together), and the accessors evaluated their macro twice.

**Done instead (S2):**
- `GetProperty` / `SetProperty` / `DoMethod` evaluate the hooks' guard once and call only the hook for the control's type. The hooks keep their own guard, so direct calls behave as before.
- `GetControl*`, `_GetControlRow/Col/Width/Height`, `GetForm*`, `_IsWindowDefined`/`Active` and `GetWindowType` use the index they already computed instead of a second macro evaluation; `_IsControlDefined` calls `Type()` once.
- Result: `GetProperty( f, c, "Value" )` on a label 68 → 45 µs (same harness, back to back, `tests/unit/props`). Trade-off: properties the GridEx hook handles (`ColumnHeader`, `ColumnWidth` …) pay ~4 µs more, because the guard now runs in the caller and again in the hook; Tree-handled properties break even; all other control properties save ~10 µs.
- **Compatibility:** no slot, name or memvar changes; the macro-named PUBLIC variables are still created. `SET HMG LEGACY VARS OFF` (S5) stops creating them; only for programs that never read `_Form` / `_Form_Control` variables themselves.

### 4.3 Optional object API (new, additive) — done
- **Thin objects** (`SOURCE/h_hmgobject.prg`): `HMG_GetControl( cForm, cControl )` and `HMG_GetForm( cForm )` return an `HMG_Control` / `HMG_Form` object, or NIL if not defined. The object holds the slot index plus identity (name, handle, parent handle); it is not a copy of the control's data.
- **Properties and methods map 1:1 to the existing functions:** `oCtl:Value` = `GetProperty( f, c, "Value" )`, `oCtl:Value := x` = `SetProperty(...)`, `oCtl:Item( 2 )` passes the index argument, `oCtl:Get/Set/Do( cName, ... )` for names built at run time, `oCtl:Show()/Hide()/SetFocus()/Refresh()/Release()` call `DoMethod`. Same on `HMG_Form` (`oFrm:Title`, `oFrm:Control( c )`, `oFrm:Controls()`).
- **Identity check before every call:** a released control's slot can be reused by a new control. Every call first checks the slot still holds the same control (deleted flag, handle, parent handle, exact name); if not it raises error subsystem `HMG`, subCode 5501, so an old object never acts on the new control.
- **Cost:** about 2 µs per call on top of `GetProperty` (≈ 45 µs, mostly Win32 `SendMessage`), i.e. within run-to-run noise.
- **`GetProperty` / `SetProperty` / `DoMethod` and the `Form.Control.Property` syntax stay** as the main user API. Programs that do not call the new functions are unaffected.

### 4.4 Event dispatch (re-scoped after measuring) — done
The plan was a per-type handler table for `WM_COMMAND`, `WM_NOTIFY` and `WM_CTLCOLOR*` in `Events()` (`h_windows.prg`). Measuring first (07-11-2026, `Events()` called directly with real arguments, so Win32 and desktop noise are excluded) showed the table would not pay:

| Path, per message | 312 controls | 1,012 controls |
|---|---|---|
| unhandled message: the whole `DO CASE` | ≤ 1 µs | ≤ 1.7 µs |
| `WM_CTLCOLOREDIT` for a text box / `EN_CHANGE` | 1–7 µs | 1–5 µs |
| `WM_CTLCOLORSTATIC` for a radio option | **188 µs** | **465 µs** |
| `WM_CTLCOLOREDIT` from a window that is not a control | 133 µs | 423 µs |
| `WM_COMMAND` radio click / from an unknown window | 139 / 105 µs | 387 / 357 µs |
| one `SendMessage` on this PC (Win32 floor) | 12–26 µs | |

Dispatch costs about 1 µs, so a table could save less than that. The time went to PRG loops over every control whenever the message's handle is not a control handle: radio options and the spinner edit (their handles are arrays), combo edit children, and any other child window. A full form repaint sends one `WM_CTLCOLORSTATIC` per radio option and two `WM_CTLCOLOREDIT` per text box.

**Done instead (S4):**
- `HMG_ScanSubArray()` (`SOURCE/c_scan.c`) finds the next control whose handle array holds a handle, in C. The seven scan loops in `Events()` (radio colour, spinner colour, spinner/radio/combo `WM_COMMAND`, mouse wheel) visit only those controls; each keeps its original checks (type, parent), so behaviour is unchanged. The combo loop uses `AScan` on the combo edit handles.
- Result: radio option colour 188 → 13 µs (312 controls) and 465 → 17 µs (1,012); unknown-window messages 105–423 → under 6 µs; cost no longer grows with the number of controls.
- Checked: `tests/unit/events` (16 checks; its 9 `Events()` checks give the same results on the pre-S4 library), matrix green in both modes.
- **Compatibility:** no slot, name or behaviour change; the `DO CASE` stays.

### 4.5 Threads
- **Known gap:** `_HMG_SYSDATA` is one PUBLIC array shared by all threads, with no locking (AUDIT M1).
- **This phase:**
  - document that GUI calls belong on the main thread;
  - add a mutex around define and release (less urgent now that S2 added no shared index).
- **Out of scope:** full thread safety.

## 5. Steps (one reviewed change each, tests green in ANSI and UNICODE)

| Step | Change | Done when |
|---|---|---|
| S1 | `hmg_sysdata.ch` + mechanical rename in the library | **Done**: 40 files, 5,334 references (`tools/sysdata-rename.pl`); generated C identical for all 75 `.prg` (`tools/pcode-snapshot.ps1`); matrix green. Not yet renamed: slots 41-64, 109-518, and the 4 files without an `hmg.ch` include |
| S2 | ~~Hash indexes~~ → one guard evaluation per property call, single macro evaluation in accessors (section 4.2) | **Done**: `tests/unit/props` 24 checks pass on the old and the new library; `GetProperty` 68 → 45 µs; matrix green; accounting project builds and starts |
| S3 | `HMG_Control` object API + docs + unit tests | **Done**: `SOURCE/h_hmgobject.prg`; `tests/unit/ctlapi` 45 checks (incl. slot reuse after release); additive only, samples untouched; matrix green |
| S4 | Faster `Events()` for the hot messages (re-scoped: C lookup instead of PRG scans, see 4.4) | **Done**: `SOURCE/c_scan.c`; `tests/unit/events` 16 checks, same results as before S4; matrix green |
| S5 | Optional `SET HMG LEGACY VARS OFF` | **Done**: `SOURCE/h_hmgvars.prg`; all 102 memvar sites (45 create, 50 read, 5 `Type()`, 2 reset; hfcl QHTM too) go through `_HMG_VarSet/Get/Type/Put`; default ON is the old code path (no measurable cost); OFF keeps the indexes in a case-insensitive hash, unknown names raise the same BASE/1003; must come before the first DEFINE WINDOW; `tests/unit/legacyvars` 24 checks; the accounting app runs with ON and OFF |

Per-monitor DPI scaling (PerMonitorV2) stays in **Phase 4**, as in AUDIT.md. It needs layout scaling, which is easier on top of S3.

## 6. How it is tested

- **Existing tests:** `hmgbuild matrix`, covering the smoke, leak, strings, hmgsqlite, AES and PDF suites.
- **Compatibility corpus:** real programs that must build and start unchanged after every step:
  - the samples;
  - a private accounting project, kept **outside the repo** and never committed;
  - 3–5 programs from members.
- **GUI smoke harness**, scripted with no screen capture:
  - start each program;
  - find windows by title and menus by text;
  - send menu commands, as the ShellAbout check did;
  - fail on any crash event or "Program Error" window.
- **S1 check:** byte-identical generated C.

## 7. Non-goals

- No change to the command syntax, `.fmg` forms, the IDE or the build scripts.
- No renumbering or removal of slots in HMG5.
- No Qt or other GUI toolkit (the HMG4 path stays closed).

## 8. Decisions needed

1. **Freeze the layout:** do you accept freezing the `_HMG_SYSDATA` slot layout as a public interface for HMG5, instead of replacing it?
2. **Corpus:** can you collect 3–5 members' programs for the compatibility corpus? They stay local and are never committed.
3. **Object API:** should the `HMG_Control` API (S3) be documented for users in HMG5, or stay internal until it has settled?
