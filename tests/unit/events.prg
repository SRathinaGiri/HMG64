/*
 * Unit test for Phase 3 S4: Events() paths that used to scan every control in PRG
 * (radio options, spinner edit, messages from unknown windows) and HMG_ScanSubArray.
 * The results must be the same as before; only the lookup changed.
 */
#include "hmg.ch"

#define WM_COMMAND        0x0111
#define WM_CTLCOLOREDIT   0x0133
#define WM_CTLCOLORSTATIC 0x0138
#define EN_CHANGE         0x0300
#define BN_CLICKED        0

STATIC s_nPass := 0, s_nFail := 0, s_nRadio := 0

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "events: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 500 HEIGHT 400 TITLE "events" MAIN NOSHOW ON INIT RunChecks()
      @ 10, 10 TEXTBOX Text_1 VALUE "a" WIDTH 100
      @ 40, 10 RADIOGROUP Radio_1 OPTIONS { "x", "y", "z" } WIDTH 80 ON CHANGE s_nRadio++
      @ 140, 10 SPINNER Spin_1 RANGE 0, 10 VALUE 3 WIDTH 80 BACKCOLOR { 200, 220, 240 }
      @ 180, 10 RADIOGROUP Radio_2 OPTIONS { "p", "q" } WIDTH 80 BACKCOLOR { 255, 200, 200 }
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC FUNCTION RunChecks()
   LOCAL hForm := GetFormHandle( "Win_1" )
   LOCAL aR1 := GetControlHandle( "Radio_1", "Win_1" ), aR2 := GetControlHandle( "Radio_2", "Win_1" )
   LOCAL aSp := GetControlHandle( "Spin_1", "Win_1" )
   LOCAL hDC, x, n

   // HMG_ScanSubArray
   Check( "scan finds sub-array",   HMG_ScanSubArray( { 1, { 5, 6 }, { 7, 8 } }, 8, 1, @x ) == 3 .AND. x == 2 )
   Check( "scan from start",        HMG_ScanSubArray( { { 8 }, { 8 } }, 8, 2 ) == 2 )
   Check( "scan fixed position",    HMG_ScanSubArray( { { 1, 8 }, { 8, 1 } }, 8, 1, , 1 ) == 2 )
   Check( "scan pos beyond length", HMG_ScanSubArray( { { 8 } }, 8, 1, , 2 ) == 0 )
   Check( "scan not found",         HMG_ScanSubArray( { { 1 }, 8 }, 8 ) == 0 )
   Check( "scan skips non-numeric", HMG_ScanSubArray( { { "8", NIL, {} } }, 8 ) == 0 )
   Check( "scan bad args",          HMG_ScanSubArray( NIL, 8 ) == 0 .AND. HMG_ScanSubArray( {}, "x" ) == 0 )
   Check( "handles are arrays",     HB_ISARRAY( aR1 ) .AND. HB_ISARRAY( aSp ) )

   // radio click through Events(): ON CHANGE runs, for the right group only
   n := s_nRadio
   Events( hForm, WM_COMMAND, BN_CLICKED, aR1[ 3 ] )
   Check( "radio click -> ON CHANGE", s_nRadio == n + 1 )
   Events( hForm, WM_COMMAND, BN_CLICKED, aR2[ 2 ] )
   Check( "other group no ON CHANGE", s_nRadio == n + 1 )
   Events( hForm, WM_COMMAND, BN_CLICKED, hForm )
   Check( "unknown hwnd no ON CHANGE", s_nRadio == n + 1 )

   // colour messages
   hDC := GetDC( hForm )
   Check( "radio option brush",     Events( hForm, WM_CTLCOLORSTATIC, hDC, aR2[ 2 ] ) == ;
                                    _HMG_SYSDATA[ HMG_CTL_BRUSHHANDLE ][ GetControlIndex( "Radio_2", "Win_1" ) ] )
   Check( "spinner edit brush",     Events( hForm, WM_CTLCOLOREDIT, hDC, aSp[ 1 ] ) == ;
                                    _HMG_SYSDATA[ HMG_CTL_BRUSHHANDLE ][ GetControlIndex( "Spin_1", "Win_1" ) ] )
   Check( "spinner updown not edit", Events( hForm, WM_CTLCOLOREDIT, hDC, aSp[ 2 ] ) == 0 )
   Check( "unknown ctlcolor 0",     Events( hForm, WM_CTLCOLOREDIT, hDC, hForm ) == 0 )
   ReleaseDC( hForm, hDC )
   Check( "unknown command 0",      Events( hForm, WM_COMMAND, hb_bitShift( EN_CHANGE, 16 ), hForm ) == 0 )

   OutStd( "events: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "events: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
