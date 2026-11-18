/*
 * Unit test for HMG_Busy() (HMG5 5.2, h_busy.prg): a long job in a busy window with a
 * progress bar and Cancel. No real input: Cancel, Esc and the window's X are delivered by
 * posting to the busy window (a button click, its ON KEY ESCAPE hotkey, WM_CLOSE) from a
 * timer of the main window. A probe thread asks the busy window to answer (WM_NULL, as
 * Windows does before it shows "Not Responding") while a tight loop runs.
 */
#include "hmg.ch"

#define WM_CLOSE   0x0010

MEMVAR _HMG_SYSDATA

STATIC s_nPass := 0, s_nFail := 0
STATIC s_oBusy := NIL, s_nAction := 0, s_lMainEnabled := NIL

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "busy: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 60, 60 WIDTH 500 HEIGHT 300 TITLE "busy test" MAIN ON INIT RunChecks()
      @ 20, 20 LABEL Lbl_1 VALUE "main window" WIDTH 200
      DEFINE TIMER Tmr_Act INTERVAL 300 ACTION DoAction()
   END WINDOW
   Win_1.Tmr_Act.Enabled := .F.
   Win_1.Activate
RETURN NIL

STATIC PROCEDURE RunChecks()
   LOCAL x, nT, a

   // 1. a job with a known total: its value comes back, the window shows 100 % and goes
   x := HMG_Busy( "Counting", {| o | CountJob( o, 3000 ) } )
   Check( "the job's value comes back", x == "done 3000" )
   Check( "100 % at the end", s_oBusy:nPercent == 100 )
   Check( "not cancelled", ! s_oBusy:Cancelled )
   Check( "messages handled, but not on every step (" + hb_ntos( s_oBusy:nPumps ) + " of 3000)", ;
          s_oBusy:nPumps >= 1 .AND. s_oBusy:nPumps < 3000 )
   Check( "the busy window is gone", ! _IsWindowDefined( s_oBusy:cForm ) )
   Check( "the main window was disabled during the job", s_lMainEnabled == .F. )
   Check( "the main window is enabled again", IsWindowEnabled( GetFormHandle( "Win_1" ) ) )

   // 2. the text line and an unknown total (the bar moves)
   x := HMG_Busy( "Text", {| o | o:Text( "step one" ), s_oBusy := o, o:Step( 5 ), o:cText + iif( o:lMarquee, " marquee", "" ) } )
   Check( "Text() and an unknown total", x == "step one marquee" )

   // 3. Cancel, Esc and the window's X stop a job that would run 8 s
   FOR EACH a IN { { 1, "Cancel button" }, { 2, "Esc" }, { 3, "the window's X" } }
      s_nAction := a[ 1 ]
      Win_1.Tmr_Act.Enabled := .T.
      nT := hb_MilliSeconds()
      x := HMG_Busy( "Waiting", {| o | WaitJob( o, 8000 ) } )
      nT := hb_MilliSeconds() - nT
      Win_1.Tmr_Act.Enabled := .F.
      Check( a[ 2 ] + " cancels (" + hb_ntos( nT ) + " ms)", x == "cancelled" .AND. s_oBusy:Cancelled .AND. nT < 4000 )
   NEXT

   // 4. a tight loop: the busy window keeps answering Windows
   HANGPROBE_RESET()
   x := HMG_Busy( "Tight loop", {| o | TightJob( o, 1500 ) } )
   a := HANGPROBE_RESULT()
   Check( "the window answered Windows during a tight loop (" + hb_ntos( a[ 1 ] ) + " probes, " + ;
          hb_ntos( a[ 2 ] ) + " late)", a[ 1 ] >= 5 .AND. a[ 2 ] == 0 )

   // 5. without a Cancel button
   x := HMG_Busy( "No cancel", {| o | ( s_oBusy := o, _IsControlDefined( "Btn_Cancel", o:cForm ) ) }, .F. )
   Check( "no Cancel button when asked", x == .F. )

   OutStd( "busy: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC FUNCTION CountJob( o, nTotal )
   LOCAL n
   s_oBusy := o
   s_lMainEnabled := IsWindowEnabled( GetFormHandle( "Win_1" ) )
   FOR n := 1 TO nTotal
      IF ! o:Step( n, nTotal, "item " + hb_ntos( Int( n / 100 ) * 100 ) )
         RETURN "cancelled"
      ENDIF
   NEXT
RETURN "done " + hb_ntos( nTotal )

STATIC FUNCTION WaitJob( o, nMs )
   LOCAL nEnd := hb_MilliSeconds() + nMs
   s_oBusy := o
   DO WHILE hb_MilliSeconds() < nEnd
      IF ! o:Step( hb_MilliSeconds() - ( nEnd - nMs ), nMs )
         RETURN "cancelled"
      ENDIF
      hb_idleSleep( 0.005 )
   ENDDO
RETURN "finished"

STATIC FUNCTION TightJob( o, nMs )
   LOCAL nEnd := hb_MilliSeconds() + nMs, x := 0
   s_oBusy := o
   HANGPROBE_START( GetFormHandle( o:cForm ) )
   DO WHILE hb_MilliSeconds() < nEnd
      x += Sqrt( x + 1 )   // pure work, no sleeping
      o:Step( hb_MilliSeconds() - ( nEnd - nMs ), nMs )
   ENDDO
   HANGPROBE_STOP()
RETURN x

/* main window timer, while a busy window is up: deliver Cancel, Esc or the X */
STATIC PROCEDURE DoAction()
   LOCAL h, k
   IF s_oBusy == NIL .OR. ! _IsWindowDefined( s_oBusy:cForm )
      RETURN
   ENDIF
   Win_1.Tmr_Act.Enabled := .F.
   h := GetFormHandle( s_oBusy:cForm )
   SWITCH s_nAction
   CASE 1
      POSTCLICK( GetControlHandle( "Btn_Cancel", s_oBusy:cForm ) )
      EXIT
   CASE 2
      FOR k := 1 TO Len( _HMG_SYSDATA[ HMG_CTL_TYPE ] )
         IF _HMG_SYSDATA[ HMG_CTL_TYPE ][ k ] == "HOTKEY" .AND. _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ k ] == h .AND. ;
            ! _HMG_SYSDATA[ HMG_CTL_DELETED ][ k ] .AND. _HMG_SYSDATA[ HMG_CTL_VALUE ][ k ] == 27
            DoMethod( s_oBusy:cForm, "SetFocus" )
            POSTHOTKEY( h, _HMG_SYSDATA[ HMG_CTL_ID ][ k ], 27 )
            EXIT
         ENDIF
      NEXT
      EXIT
   CASE 3
      POSTMSG( h, WM_CLOSE )
      EXIT
   ENDSWITCH
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "busy: FAIL " + cName + hb_eol() )
   ENDIF
RETURN

#pragma BEGINDUMP
#include <windows.h>
#include "hbapi.h"
#include "hbapiitm.h"

static HWND          s_hProbe = NULL;
static volatile LONG s_lRun = 0, s_nProbes = 0, s_nLate = 0;
static HANDLE        s_hThread = NULL;

static DWORD WINAPI probe_thread( LPVOID p )
{
   ( void ) p;
   while( s_lRun )
   {
      DWORD_PTR r;
      if( ! SendMessageTimeoutW( s_hProbe, WM_NULL, 0, 0, SMTO_ABORTIFHUNG, 200, &r ) )
         InterlockedIncrement( &s_nLate );
      InterlockedIncrement( &s_nProbes );
      Sleep( 100 );
   }
   return 0;
}

HB_FUNC( HANGPROBE_RESET ) { s_nProbes = 0; s_nLate = 0; }
HB_FUNC( HANGPROBE_START )
{
   s_hProbe = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   s_lRun = 1;
   s_hThread = CreateThread( NULL, 0, probe_thread, NULL, 0, NULL );
}
HB_FUNC( HANGPROBE_STOP )
{
   s_lRun = 0;
   if( s_hThread )
   {
      /* the probe may be waiting for this (the busy) thread: keep answering until it ends */
      while( MsgWaitForMultipleObjects( 1, &s_hThread, FALSE, 1000, QS_SENDMESSAGE ) == WAIT_OBJECT_0 + 1 )
      {
         MSG m;
         PeekMessageW( &m, NULL, 0, 0, PM_NOREMOVE );
      }
      CloseHandle( s_hThread );
      s_hThread = NULL;
   }
}
HB_FUNC( HANGPROBE_RESULT )
{
   PHB_ITEM a = hb_itemArrayNew( 2 );
   hb_arraySetNL( a, 1, s_nProbes );
   hb_arraySetNL( a, 2, s_nLate );
   hb_itemReturnRelease( a );
}
HB_FUNC( POSTCLICK )  { PostMessageW( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), BM_CLICK, 0, 0 ); }
HB_FUNC( POSTMSG )    { PostMessageW( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), ( UINT ) hb_parni( 2 ), 0, 0 ); }
HB_FUNC( POSTHOTKEY ) { PostMessageW( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), WM_HOTKEY, ( WPARAM ) hb_parni( 2 ), MAKELPARAM( 0, hb_parni( 3 ) ) ); }
#pragma ENDDUMP
