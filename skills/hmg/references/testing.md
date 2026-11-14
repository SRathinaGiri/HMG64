# Testing HMG programs without a person clicking

GUI code can be tested automatically if the test never needs a mouse or a real dialog. The pattern
below is what HMG5's own test suite uses (`tests\unit\*.prg`).

## The pattern

```harbour
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   // a runtime error must end the test with a failure, not wait on a message box
   ErrorBlock( {| e | OutStd( "mytest: RUNTIME ERROR " + e:description + " in " + ;
                              ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 600 HEIGHT 400 TITLE "test" MAIN NOSHOW
      @ 10, 10 TEXTBOX Txt_1 VALUE "abc"
      @ 40, 10 GRID Grd_1 WIDTH 300 HEIGHT 150 HEADERS { "A" } WIDTHS { 200 } ITEMS { { "1" }, { "2" } }
      // run the checks from an event once the message loop runs (not from ON INIT if they
      // open modal windows - see pitfalls.md section 5)
      DEFINE TIMER Tmr_Start INTERVAL 200 ACTION ( Win_1.Tmr_Start.Enabled := .F., RunChecks() )
   END WINDOW
   Win_1.Activate
RETURN NIL

STATIC PROCEDURE RunChecks()
   Check( "textbox value", Win_1.Txt_1.Value == "abc" )
   Win_1.Grd_1.AddItem( { "3" } )
   Check( "grid rows", Win_1.Grd_1.ItemCount == 3 )
   // the summary line is the proof the test reached its end (HMG's fatal errors exit with 0)
   OutStd( "mytest: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "mytest: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
```

Build it as a console program so `OutStd` reaches the terminal: `build64 /n /c mytest.prg`, then
run `mytest.exe` **with a time limit** - a test that hits HMG's fatal-error box or never reaches
`ExitProcess` waits forever:

```powershell
$p = Start-Process .\mytest.exe -PassThru -NoNewWindow
if (-not $p.WaitForExit(30000)) { Stop-Process -Id $p.Id -Force; "TIMEOUT = FAIL" }
```

**Pass = exit code 0 AND the `PASS=` line printed** (a timeout is a failure).

A program that must stay a normal window can carry its own switch instead (`myprog.exe /selftest`):
under it, a timer drives the program through the same functions the buttons call, writes the
result to a file and calls `ExitProcess`.

## Rules

- `NOSHOW` main window: nothing appears on the screen, events and properties still work.
- Never call `MsgInfo`/`MsgYesNo`/`GetFile`... in a test: they wait for a person. Test the
  function behind the dialog instead, or give it a parameter that skips the dialog.
- Modal windows under test: open them from an event, and close them from a timer that acts only
  when the window is active and not from inside the activation's `DO EVENTS`:
  ```harbour
  IF IsWindowDefined( Win_Dlg ) .AND. _IsWindowActive( "Win_Dlg" )
     ... checks ...
     Win_Dlg.Release
  ENDIF
  ```
- A control that writes files (PDF, `reports.cfg`, DBF): write to `hb_DirTemp()` and delete
  afterwards.
- Add a check that **fails without your fix** when you test a bug fix: build once without the
  fix and see the test fail (HMG's fatal error box, or a FAIL line).
- If `ErrorLog.htm` appears in the current folder, an HMG fatal error happened - read it: it has
  the message and the call stack.

## Checking a form visually

When the layout matters, run the program and capture its window (on Windows, `PrintWindow`
from PowerShell/.NET captures one window, including WebView content) instead of guessing from
coordinates. Close only the process you started (by its process id).
