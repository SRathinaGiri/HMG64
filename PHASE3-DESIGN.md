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

### 4.2 O(1) lookups
- **Two hash indexes**, kept up to date wherever a control or window is defined or released:
  - handle → control index;
  - upper-case `"FORM.CONTROL"` → control index.
- **Fast paths:** `GetControlIndex`, `GetFormIndex` and the 24 handle scans use the hashes.
- **Compatibility:** the macro-named PUBLIC variables are still created, because user code may use them. A later switch (`SET HMG LEGACY VARS OFF`) can stop creating them.

### 4.3 Optional object API (new, additive)
- **Thin control objects:** `HMG_Control()` objects wrap a control index; they are not a copy of its data.
  - Accessors read and write the same slots: `oCtl:Name`, `oCtl:Handle`, `oCtl:Value`, `oCtl:Parent`.
  - Obtained through `HMG_GetControl( "Form1", "Text1" )`.
- **Purpose:** new code and contribs stop needing raw slot numbers. Nothing existing has to change.
- **`GetProperty` / `SetProperty` stay** as the main user API.

### 4.4 Event dispatch
- **Per-type handler table:** `Events()` (the giant `DO CASE` in `h_windows.prg`) gets a table keyed by control type for the hot messages: `WM_COMMAND`, `WM_NOTIFY`, `WM_CTLCOLOR*`.
- **Measured:** behaviour must stay the same, and the GUI smoke tests (section 6) run before and after.

### 4.5 Threads
- **Known gap:** `_HMG_SYSDATA` is one PUBLIC array shared by all threads, with no locking (AUDIT M1).
- **This phase:**
  - document that GUI calls belong on the main thread;
  - add a mutex around define and release, so the new hash indexes can't be corrupted.
- **Out of scope:** full thread safety.

## 5. Steps (one reviewed change each, tests green in ANSI and UNICODE)

| Step | Change | Done when |
|---|---|---|
| S1 | `hmg_sysdata.ch` + mechanical rename in the library | **Done**: 40 files, 5,334 references (`tools/sysdata-rename.pl`); generated C identical for all 75 `.prg` (`tools/pcode-snapshot.ps1`); matrix green. Not yet renamed: slots 41-64, 109-518, and the 4 files without an `hmg.ch` include |
| S2 | Hash indexes for handle and name lookup | matrix green; lookup benchmark (1,000 controls) shows the gain; corpus programs unchanged |
| S3 | `HMG_Control` object API + docs + unit tests | additive only; samples untouched |
| S4 | Table-driven `Events()` for the hot messages | GUI smoke tests pass before and after |
| S5 | Optional `SET HMG LEGACY VARS OFF` | default stays ON in HMG5 |

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
