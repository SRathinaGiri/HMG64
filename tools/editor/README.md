# HMG5 syntax highlighting for Notepad++

`HMG5_Notepad++.xml` is a Notepad++ "User Defined Language" for HMG5 programs (`.prg`, `.ch`, `.fmg`).

## Install

1. Notepad++: **Language > User Defined Language > Define your language… > Import…**
2. Choose `tools\editor\HMG5_Notepad++.xml` and restart Notepad++.
3. `.prg`, `.ch` and `.fmg` files open as **HMG5**. Any other file can be switched from the **Language** menu.

The HMG5 IDE has its own code editor, which uses the same word lists (`hmg5_keywords.txt`, written by the same generator and built into the IDE). To use Notepad++ instead: in the IDE, open **Tools > Preferences**, enter the path to `notepad++.exe` as the program editor, and clear **Use the built-in editor**.

## What is coloured

| Group | Examples | Source |
|---|---|---|
| Harbour language | `FUNCTION`, `LOCAL`, `IF`, `DO CASE`, `BEGIN SEQUENCE` | fixed list |
| HMG commands and controls | `DEFINE`, `END`, `ACTIVATE`, `LOAD`, `WINDOW`, `BUTTON`, `WEBVIEW` | `INCLUDE\*.ch` (`#command` / `#xcommand`) |
| HMG clauses and properties | `ROW`, `CAPTION`, `ON CHANGE`, `FONTNAME`, `.Value`, `AddItem` | the words of the command patterns |
| HMG functions | `MsgInfo`, `GetProperty`, `HMG_SetPdfEngine` | public functions in `SOURCE\*.prg` |
| Harbour functions | `AllTrim`, `hb_ntos`, `DbSeek` | `harbour64\include\harbour.hbx` |
| Preprocessor | `#include`, `#define`, `#xcommand` | fixed list |
| Constants | `.T.`, `NIL`, `COLOR_Red` | one-word translates that stand for a literal |

**Folding** covers:
- `IF`, `FOR`, `DO CASE`, `DO WHILE`, `SWITCH` and `BEGIN SEQUENCE`;
- `PAGE`, `POPUP` and `NODE`;
- every `DEFINE <x> … END <x>` block that HMG defines (windows, controls, menus, tabs, toolbars, status bars, split boxes, reports).

**Comments:** `//`, `&&` and `/* … */`.

## Limits

- `*` comment lines are not coloured. Notepad++ can't tell a comment at the start of a line from `*` used as multiplication.
- `IF( cond, a, b )` used as a function opens a fold that is never closed.
- A one-line `DEFINE TIMER … ACTION …` has no `END TIMER`, so `DEFINE TIMER` is not a fold opener.

## Regenerate

Regenerate when HMG gains commands or functions:

```bat
hbmk2 tools\editor\make_npp_udl.prg -otools\editor\make_npp_udl
tools\editor\make_npp_udl.exe
```

Run both commands from the HMG5 folder. The generator reads the headers and sources and rewrites the XML and `hmg5_keywords.txt`. Rebuild the IDE (`hmgbuild ide`) afterwards, so that its editor gets the new words.
