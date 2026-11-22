/*
 * Unit test for control ids and timers (HMG5 5.2.1, from a static review of 5.2):
 *  - a released TIMER, and a released status bar's clock, leave no Win32 timer behind
 *  - WM_TIMER runs the TIMER with that id, not the first control whose CTL_ID holds the number
 *  - _GetId() never gives 1..99 (WM_COMMAND IDOK = 1 comes with Enter)
 */
#include "hmg.ch"

#define WM_TIMER  0x0113

MEMVAR _HMG_SYSDATA

STATIC s_nPass := 0, s_nFail := 0, s_nTicks := 0

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "ctlids: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 40, 40 WIDTH 500 HEIGHT 300 TITLE "ctlids test" MAIN ON INIT RunChecks()
      @ 10, 10 GRID Grid_1 WIDTH 300 HEIGHT 120 HEADERS { "A" } WIDTHS { 100 }
      DEFINE TIMER Tmr_Gone INTERVAL 50 ACTION s_nTicks++
      DEFINE TIMER Tmr_Kept INTERVAL 60000 ACTION s_nTicks += 1000
      DEFINE STATUSBAR
         STATUSITEM "x"
         CLOCK
      END STATUSBAR
   END WINDOW
   Win_1.Activate
RETURN NIL

STATIC PROCEDURE RunChecks()
   LOCAL hForm := GetFormHandle( "Win_1" ), nId, nClock, kGrid, kTimer, nOld, i, nMin

   // a released TIMER: its Win32 timer is gone (KillTimer finds nothing to kill)
   nId := _HMG_SYSDATA[ HMG_CTL_ID ][ GetControlIndex( "Tmr_Gone", "Win_1" ) ]
   RELEASE CONTROL Tmr_Gone OF Win_1
   Check( "a released TIMER stops its Win32 timer", ! KILLTIMEROK( hForm, nId ) )

   // a released status bar: its clock timer too
   nClock := _HMG_SYSDATA[ HMG_CTL_ID ][ GetControlIndex( "StatusTimer", "Win_1" ) ]
   RELEASE CONTROL StatusBar OF Win_1
   Check( "a released status bar stops its clock", ! IsControlDefined( StatusTimer, Win_1 ) .AND. ! KILLTIMEROK( hForm, nClock ) )

   // WM_TIMER with an id that a control defined earlier also holds in CTL_ID (a grid keeps its
   // header's window handle there): the TIMER still runs
   kGrid  := GetControlIndex( "Grid_1", "Win_1" )
   kTimer := GetControlIndex( "Tmr_Kept", "Win_1" )
   nOld := _HMG_SYSDATA[ HMG_CTL_ID ][ kGrid ]
   _HMG_SYSDATA[ HMG_CTL_ID ][ kGrid ] := _HMG_SYSDATA[ HMG_CTL_ID ][ kTimer ]
   s_nTicks := 0
   SENDMSG( hForm, WM_TIMER, _HMG_SYSDATA[ HMG_CTL_ID ][ kTimer ], 0 )
   _HMG_SYSDATA[ HMG_CTL_ID ][ kGrid ] := nOld
   Check( "WM_TIMER runs the TIMER, not the grid sharing the number (" + hb_ntos( s_nTicks ) + ")", s_nTicks == 1000 )

   // ... and only a TIMER of that window: a number no timer has runs nothing
   s_nTicks := 0
   SENDMSG( hForm, WM_TIMER, nOld, 0 )
   Check( "WM_TIMER with a grid header's number runs nothing", s_nTicks == 0 )

   // ids never 1..99
   nMin := 65535
   FOR i := 1 TO 20000
      nMin := Min( nMin, _GetId() )
   NEXT
   Check( "_GetId() never below 100 (" + hb_ntos( nMin ) + ")", nMin >= 100 )

   OutStd( "ctlids: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "ctlids: FAIL " + cName + hb_eol() )
   ENDIF
RETURN

#pragma BEGINDUMP
#include <windows.h>
#include "hbapi.h"

/* KILLTIMEROK( hWnd, nId ) -> .T. when such a timer was still running (and is now killed) */
HB_FUNC( KILLTIMEROK )
{
   hb_retl( KillTimer( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), ( UINT_PTR ) hb_parnll( 2 ) ) );
}

HB_FUNC( SENDMSG )
{
   SendMessageW( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), ( UINT ) hb_parni( 2 ), ( WPARAM ) hb_parnll( 3 ), ( LPARAM ) hb_parnll( 4 ) );
}
#pragma ENDDUMP
