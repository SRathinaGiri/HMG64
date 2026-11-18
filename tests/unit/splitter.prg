/*
 * Unit test for SPLITTER (HMG5 5.2, h_splitter.prg, c_splitter.c). No real mouse: a drag is a
 * press, moves and a release sent to the splitter (its own client coordinates), as Windows
 * sends them while the mouse is captured.
 */
#include "hmg.ch"

#define WM_KEYDOWN       0x0100
#define WM_MOUSEMOVE     0x0200
#define WM_LBUTTONDOWN   0x0201
#define WM_LBUTTONUP     0x0202
#define MK_LBUTTON       1

STATIC s_nPass := 0, s_nFail := 0, s_nChanged := 0

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "splitter: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 40, 40 WIDTH 820 HEIGHT 560 TITLE "splitter test" MAIN ON INIT RunChecks()
      @ 10, 10 GRID Grid_L WIDTH 290 HEIGHT 400 HEADERS { "A" } WIDTHS { 100 }
      @ 10, 300 SPLITTER Spl_V HEIGHT 400 BETWEEN { "Grid_L" } AND { "Edt_T", "Edt_B" } MINSIZE 50 ;
         ON CHANGE s_nChanged++
      @ 10, 306 EDITBOX Edt_T WIDTH 480 HEIGHT 194
      @ 204, 306 SPLITTER Spl_H WIDTH 480 HORIZONTAL BETWEEN { "Edt_T" } AND { "Edt_B" }
      @ 210, 306 EDITBOX Edt_B WIDTH 480 HEIGHT 200
   END WINDOW
   Win_1.Activate
RETURN NIL

/* a drag of the splitter by nDelta pixels (DPI scaling is off in the tests); lEsc: cancel it.
   The points are fixed on the screen; each is sent relative to where the bar is at that moment,
   as Windows reports a captured mouse */
STATIC PROCEDURE Drag( cSpl, nDelta, lEsc )
   LOCAL h := GetControlHandle( cSpl, "Win_1" ), lV := ( cSpl == "Spl_V" )
   LOCAL a := CLIENTTOSCREENXY( h, 3, 3 ), nX := a[ 1 ], nY := a[ 2 ]
   SENDMOUSESCREEN( h, WM_LBUTTONDOWN, nX, nY, MK_LBUTTON )
   SENDMOUSESCREEN( h, WM_MOUSEMOVE, nX + iif( lV, Int( nDelta / 2 ), 0 ), nY + iif( lV, 0, Int( nDelta / 2 ) ), MK_LBUTTON )
   SENDMOUSESCREEN( h, WM_MOUSEMOVE, nX + iif( lV, nDelta, 0 ), nY + iif( lV, 0, nDelta ), MK_LBUTTON )
   IF hb_defaultValue( lEsc, .F. )
      SENDMOUSE( h, WM_KEYDOWN, 27, 0, 0 )
   ELSE
      SENDMOUSESCREEN( h, WM_LBUTTONUP, nX + iif( lV, nDelta, 0 ), nY + iif( lV, 0, nDelta ), 0 )
   ENDIF
RETURN
STATIC PROCEDURE RunChecks()
   LOCAL n

   Check( "the bar is where it was defined", Win_1.Spl_V.Position == 300 .AND. Win_1.Spl_H.Position == 204 )

   // a drag to the left: the grid narrows, the editors start after the bar and keep their right edge
   Drag( "Spl_V", -100 )
   Check( "dragged 100 to the left", Win_1.Spl_V.Position == 200 )
   Check( "the control before ends at the bar", Win_1.Grid_L.Col == 10 .AND. Win_1.Grid_L.Width == 190 )
   Check( "the controls after start after it, right edge kept", ;
          Win_1.Edt_T.Col == 206 .AND. Win_1.Edt_T.Width == 580 .AND. Win_1.Edt_B.Col == 206 .AND. Win_1.Edt_B.Width == 580 )
   Check( "ON CHANGE once", s_nChanged == 1 )
   Check( "the drag is over", ! HMG_SPLITTERDRAG( GetControlHandle( "Spl_V", "Win_1" ) ) )

   // the limits: MINSIZE 50 on both sides
   Drag( "Spl_V", -1000 )
   Check( "not past MINSIZE on the left (" + hb_ntos( Win_1.Spl_V.Position ) + ")", Win_1.Spl_V.Position == 60 .AND. Win_1.Grid_L.Width == 50 )
   Drag( "Spl_V", 2000 )
   Check( "not past MINSIZE on the right (" + hb_ntos( Win_1.Spl_V.Position ) + ")", Win_1.Spl_V.Position == 786 - 50 - 6 .AND. Win_1.Edt_T.Width == 50 )

   // Esc puts it back, without ON CHANGE
   Win_1.Spl_V.Position := 400
   n := s_nChanged
   Drag( "Spl_V", -150, .T. )
   Check( "Esc puts everything back", Win_1.Spl_V.Position == 400 .AND. Win_1.Grid_L.Width == 390 .AND. Win_1.Edt_T.Col == 406 )
   Check( "no ON CHANGE after Esc, nor for Position :=", s_nChanged == n )

   // a click without a move changes nothing
   Drag( "Spl_V", 0 )
   Check( "a click: no change, no ON CHANGE", Win_1.Spl_V.Position == 400 .AND. s_nChanged == n )

   // Position := is kept within the limits too
   Win_1.Spl_V.Position := 5
   Check( "Position := within the limits", Win_1.Spl_V.Position == 60 )
   Win_1.Spl_V.Position := 300

   // a HORIZONTAL splitter: above and below
   Drag( "Spl_H", 60 )
   Check( "HORIZONTAL: dragged down", Win_1.Spl_H.Position == 264 )
   Check( "HORIZONTAL: the one above ends at the bar, the one below keeps its bottom", ;
          Win_1.Edt_T.Height == 254 .AND. Win_1.Edt_B.Row == 270 .AND. Win_1.Edt_B.Height == 140 )
   Check( "HORIZONTAL: default MINSIZE 20", ( Drag( "Spl_H", 500 ), Win_1.Spl_H.Position == 410 - 20 - 6 ) )

   OutStd( "splitter: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "splitter: FAIL " + cName + hb_eol() )
   ENDIF
RETURN

#pragma BEGINDUMP
#include <windows.h>
#include "hbapi.h"

/* SENDMOUSE( hWnd, nMsg, x, y, nKeys ): a mouse message as Windows sends it (x, y: the window's
   client coordinates); for WM_KEYDOWN, x is the key */
HB_FUNC( SENDMOUSE )
{
   HWND hWnd = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   UINT msg  = ( UINT ) hb_parni( 2 );
   if( msg == WM_KEYDOWN )
      SendMessageW( hWnd, msg, ( WPARAM ) hb_parni( 3 ), 1 );
   else
      SendMessageW( hWnd, msg, ( WPARAM ) hb_parni( 5 ), MAKELPARAM( ( short ) hb_parni( 3 ), ( short ) hb_parni( 4 ) ) );
}
/* SENDMOUSESCREEN( hWnd, nMsg, nScreenX, nScreenY, nKeys ): the point made relative to the window now */
HB_FUNC( SENDMOUSESCREEN )
{
   HWND  hWnd = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   POINT pt;
   pt.x = hb_parni( 3 );
   pt.y = hb_parni( 4 );
   ScreenToClient( hWnd, &pt );
   SendMessageW( hWnd, ( UINT ) hb_parni( 2 ), ( WPARAM ) hb_parni( 5 ), MAKELPARAM( ( short ) pt.x, ( short ) pt.y ) );
}

/* CLIENTTOSCREENXY( hWnd, x, y ) -> { nScreenX, nScreenY } */
HB_FUNC( CLIENTTOSCREENXY )
{
   POINT pt;
   pt.x = hb_parni( 2 );
   pt.y = hb_parni( 3 );
   ClientToScreen( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), &pt );
   hb_reta( 2 );
   hb_storvni( pt.x, -1, 1 );
   hb_storvni( pt.y, -1, 2 );
}
#pragma ENDDUMP
