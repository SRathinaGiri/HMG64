/*
 * h_menuhover.prg - open menu-bar popups on mouse hover (HMG5)
 *
 * From HMG 3.7 (Oct 2026), where it lived in h_menu.prg. Opt-in per window:
 *    SET MENUHOVER [OF <form>] ON | OFF      ->  SetMenuBarHover( cForm, lOn )
 * Only windows registered with SetMenuBarHover() react. Hooks in Events (h_windows.prg):
 * WM_NCMOUSEMOVE -> HandleMenuBarHover, WM_TIMER -> HandleMenuBarHoverTimer,
 * WM_DESTROY -> ClearMenuBarHover. The C primitives are in c_menuhover.c.
 *
 * HMG5 changes against 3.7: English comments; the timer id is above the range of
 * _GetId() (random(65000)) so it can never be a TIMER control's id on the same form;
 * Events skips its control lookup for that id; the window list uses hb_ADel.
 *
 * Released under the HMG licence, as the rest of HMG.
 */

#include "hmg.ch"

MEMVAR _HMG_SYSDATA

#define HOVER_TIMERID   65521   // > 65000: never an HMG control/timer id (see _GetId)
#define HOVER_STEPS         3   // mouse moves over the bar before a popup opens
#define HOVER_DWELL       150   // ms the mouse must rest on the bar before opening
#define HOVER_MS           60   // watcher / poll period, ms
#define HOVER_EXIT          4   // watcher ticks outside bar and popup before closing

STATIC s_aHoverBar     := {}    // HWNDs with hover enabled
STATIC s_hHoverPend    := 0     // HWND collecting the hover delay
STATIC s_nHoverTick    := 0     // moves counted on s_hHoverPend
STATIC s_nHoverT0      := 0     // tick count of the first move of the run
STATIC s_lHoverTrack   := .F.   // .T. while our popup owns the message loop
STATIC s_hHoverOpen    := 0     // HWND whose popup is open
STATIC s_nHoverOpenIdx := -1    // bar item whose popup is open
STATIC s_nHoverOut     := 0     // consecutive watcher ticks outside everything
STATIC s_nHoverIntent  := 0     // why the watcher ended the popup: 0 none, 1 slide, 2 left
// The same timer id is also used as a "dwell poll" while no popup is open (see
// HandleMenuBarHover). s_hHoverPoll records the window it is set on, because another
// window can break the run and the poll would otherwise be orphaned.
STATIC s_hHoverPoll    := 0


*------------------------------------------------------------------------------*
FUNCTION SetMenuBarHover ( cFormName, lEnable )
*------------------------------------------------------------------------------*
// Enable/disable hover for a window's menu bar. Call it after the window exists.
LOCAL hWnd

   IF ValType ( lEnable ) != 'L'
      lEnable := .T.
   ENDIF

   // No name: the form being defined / the active form
   IF ValType ( cFormName ) != 'C' .OR. Empty ( cFormName )
      cFormName := _HMG_SYSDATA [ 223 ]
   ENDIF

   IF ValType ( cFormName ) != 'C' .OR. ! _IsWindowDefined ( cFormName )
      RETURN .F.     // unknown form: no error, as for a window that has no handle yet
   ENDIF

   hWnd := GetFormHandle ( cFormName )

   IF ValType ( hWnd ) != 'N' .OR. hWnd == 0
      RETURN .F.
   ENDIF

   IF lEnable
      IF AScan ( s_aHoverBar, hWnd ) == 0
         AAdd ( s_aHoverBar, hWnd )
      ENDIF
   ELSE
      ClearMenuBarHover ( hWnd )
   ENDIF

RETURN .T.


*------------------------------------------------------------------------------*
FUNCTION ClearMenuBarHover ( hWnd )
*------------------------------------------------------------------------------*
// Removes hover from a window and every trace of it in the module state. Also
// called from WM_DESTROY, so the list does not grow and a recycled HWND does not
// inherit hover from a dead window.
LOCAL k

   IF ValType ( hWnd ) != 'N' .OR. hWnd == 0
      RETURN .F.
   ENDIF

   k := AScan ( s_aHoverBar, hWnd )
   IF k > 0
      hb_ADel ( s_aHoverBar, k, .T. )
   ENDIF

   IF s_hHoverPend == hWnd
      s_hHoverPend := 0
      s_nHoverTick := 0
      s_nHoverT0   := 0
   ENDIF

   // Turned off from an ACTION: the popup watcher must not survive
   KillTimer ( hWnd, HOVER_TIMERID )
   IF s_hHoverPoll == hWnd
      s_hHoverPoll := 0
   ENDIF

   IF s_hHoverOpen == hWnd
      s_hHoverOpen    := 0
      s_nHoverOpenIdx := -1
      s_nHoverOut     := 0
      s_nHoverIntent  := 0
   ENDIF

RETURN k > 0


STATIC FUNCTION MenubarKillPoll ()
   // Idempotent: KillTimer on a timer that is not set is a no-op
   IF s_hHoverPoll != 0
      KillTimer ( s_hHoverPoll, HOVER_TIMERID )
      s_hHoverPoll := 0
   ENDIF
RETURN .F.


STATIC FUNCTION MenubarResetRun ()
   s_hHoverPend := 0
   s_nHoverTick := 0
   MenubarKillPoll ()
RETURN .F.


*------------------------------------------------------------------------------*
FUNCTION HandleMenuBarHover ( hWnd, nLParam )
*------------------------------------------------------------------------------*
// Called from WM_NCMOUSEMOVE with the raw lParam (screen coordinates). Returns .T.
// when it took over the popup loop (the user may still close it without choosing).
LOCAL nIdx, nNext, nGuard

   // Fast exit for every program that never turned hover on
   IF Len ( s_aHoverBar ) == 0
      RETURN .F.
   ENDIF

   // TrackPopupMenu runs its own loop and WM_NCMOUSEMOVE can arrive again during
   // it: do not nest popups.
   IF s_lHoverTrack
      RETURN .F.
   ENDIF

   IF AScan ( s_aHoverBar, hWnd ) == 0
      RETURN .F.
   ENDIF

   // The native bar does not react on a window that is not in front either.
   // Without this, hovering the bar of a covered window opened its popup.
   IF GetForegroundWindow () != hWnd
      RETURN MenubarResetRun ()
   ENDIF

   // A real click already put the window in menu mode: the system slides itself.
   IF MenubarMenuActive ()
      RETURN .F.
   ENDIF

   // The point must be over our window (not over another app on top of it)
   IF ! MenubarPointInWindow ( hWnd, nLParam )
      RETURN MenubarResetRun ()
   ENDIF

   nIdx := MenubarHitIndex ( hWnd, nLParam )
   IF nIdx < 0
      RETURN MenubarResetRun ()
   ENDIF

   // Delay: count moves AND require real resting time (see MenubarElapsedMs)
   IF s_hHoverPend == hWnd
      s_nHoverTick++
   ELSE
      // A run of another window: its poll must die here
      MenubarKillPoll ()
      s_hHoverPend := hWnd
      s_nHoverTick := 1
      s_nHoverT0   := MenubarElapsedMs ( 0 )   // current tick count
   ENDIF

   IF s_nHoverTick < HOVER_STEPS .OR. MenubarElapsedMs ( s_nHoverT0 ) < HOVER_DWELL
      // Not yet. If the mouse now rests, no further WM_NCMOUSEMOVE arrives and the
      // popup would never open, so the timer is set as a poll and
      // HandleMenuBarHoverTimer re-runs this decision with the real cursor position.
      InitTimer ( hWnd, HOVER_TIMERID, HOVER_MS )
      s_hHoverPoll := hWnd
      RETURN .F.
   ENDIF

   s_hHoverPend  := 0
   s_nHoverTick  := 0
   s_lHoverTrack := .T.
   // The timer turns from poll into watcher
   MenubarKillPoll ()

   // Watcher: inside TrackPopupMenu's modal loop WM_NCMOUSEMOVE does not arrive,
   // but the thread's WM_TIMER messages are dispatched.
   InitTimer ( hWnd, HOVER_TIMERID, HOVER_MS )

   // Safety cap against the cursor ping-ponging on the edge between two items; each
   // round needs a different item, so 200 covers any human sweep along the bar.
   nGuard := 0
   DO WHILE nGuard < 200
      s_hHoverOpen    := hWnd
      s_nHoverOpenIdx := nIdx
      s_nHoverOut     := 0
      s_nHoverIntent  := 0

      IF MenubarOpenPopup ( hWnd, nIdx ) != 0
         EXIT      // the user chose an item
      ENDIF

      // Chain only when the watcher closed the popup to slide; not when the mouse left
      IF s_nHoverIntent != 1
         EXIT
      ENDIF

      nNext := MenubarHitIndex ( hWnd, MenubarCursorPoint () )
      IF nNext < 0 .OR. nNext == nIdx
         EXIT
      ENDIF
      nIdx := nNext
      nGuard++
   ENDDO

   KillTimer ( hWnd, HOVER_TIMERID )
   MenubarKillPoll ()

   s_hHoverOpen    := 0
   s_nHoverOpenIdx := -1
   s_nHoverOut     := 0
   s_nHoverIntent  := 0
   s_lHoverTrack   := .F.

RETURN .T.


*------------------------------------------------------------------------------*
FUNCTION HandleMenuBarHoverTimer ( nWParam )
*------------------------------------------------------------------------------*
// Called from WM_TIMER. Returns .T. when wParam is the hover timer (Events then skips
// its TIMER-control lookup). While the popup is open this is the only code of the
// thread that runs, so it decides slide / close here.
LOCAL hWnd, nPt, nIdx

   IF nWParam != HOVER_TIMERID
      RETURN .F.
   ENDIF

   IF ! s_lHoverTrack
      // Dwell poll (no popup open, run still pending because no further
      // WM_NCMOUSEMOVE arrived): re-run the decision with the real cursor position.
      // The poll is killed BEFORE re-dispatching, so if HandleMenuBarHover declines
      // through another guard the timer does not keep firing for nothing.
      hWnd := s_hHoverPend
      IF hWnd == 0 .OR. hWnd != s_hHoverPoll
         MenubarKillPoll ()
         RETURN .T.
      ENDIF
      MenubarKillPoll ()
      HandleMenuBarHover ( hWnd, MenubarCursorPoint () )
      RETURN .T.
   ENDIF

   hWnd := s_hHoverOpen
   IF ValType ( hWnd ) != 'N' .OR. hWnd == 0
      RETURN .T.
   ENDIF

   nPt := MenubarCursorPoint ()

   // Over the popup or a submenu: nothing to do
   IF MenubarPointInMenu ( nPt )
      s_nHoverOut := 0
      RETURN .T.
   ENDIF

   // TOPMOST owner: the popup may have dropped below it, so the hit test above says
   // .F. with the cursor inside. Re-assert the popup's z-order and ask again.
   IF MenubarKeepPopupOnTop ( nPt ) > 0 .AND. MenubarPointInMenu ( nPt )
      s_nHoverOut := 0
      RETURN .T.
   ENDIF

   nIdx := MenubarHitIndex ( hWnd, nPt )

   IF nIdx >= 0
      s_nHoverOut := 0
      // Another bar item: end this popup so the loop reopens on that one
      IF nIdx != s_nHoverOpenIdx
         s_nHoverOpenIdx := nIdx
         s_nHoverIntent  := 1
         MenubarEndMenu ()
      ENDIF
      RETURN .T.
   ENDIF

   // Outside the bar and the popup: count, then close
   s_nHoverOut++
   IF s_nHoverOut >= HOVER_EXIT
      s_nHoverIntent := 2
      MenubarEndMenu ()
   ENDIF

RETURN .T.
