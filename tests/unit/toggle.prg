/*
 * Unit test for TOGGLE (HMG5 5.2, h_toggle.prg, c_toggle.c). No real mouse or keyboard:
 * clicks and keys are messages sent to the switch, as Windows sends them.
 */
#include "hmg.ch"

#define WM_KEYDOWN       0x0100
#define WM_LBUTTONDOWN   0x0201
#define WM_LBUTTONUP     0x0202
#define VK_SPACE         0x20
#define MK_LBUTTON       1

STATIC s_nPass := 0, s_nFail := 0, s_nChanged := 0, s_lSeen := NIL, s_cFocus := ""

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "toggle: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 40, 40 WIDTH 520 HEIGHT 420 TITLE "toggle test" MAIN ON INIT RunChecks()
      @ 10, 10 TOGGLE Tgl_A CAPTION "Dark mode" VALUE .T. WIDTH 200 ;
         ON CHANGE ( s_nChanged++, s_lSeen := This.Value ) ;
         ON GOTFOCUS s_cFocus += "+A" ON LOSTFOCUS s_cFocus += "-A"
      @ 50, 10 TOGGLE Tgl_B WIDTH 200
      @ 90, 10 TOGGLE Tgl_C CAPTION "Colours" WIDTH 200 BACKCOLOR { 255, 0, 0 } NOTABSTOP
      @ 130, 10 TEXTBOX Txt_1 WIDTH 100

      DEFINE TOGGLE Tgl_D
         ROW 170
         COL 10
         WIDTH 200
         CAPTION "Defined"
         VALUE .T.
      END TOGGLE

      DEFINE TAB Tab_1 AT 210, 10 WIDTH 300 HEIGHT 150
         PAGE "One"
            @ 40, 10 TOGGLE Tgl_P CAPTION "On a page" WIDTH 150
         END PAGE
         PAGE "Two"
         END PAGE
      END TAB
   END WINDOW
   Win_1.Activate
RETURN NIL

STATIC FUNCTION H( c )
RETURN GetControlHandle( c, "Win_1" )

STATIC PROCEDURE Click( c, lInside )
   LOCAL h := H( c )
   SENDMSG( h, WM_LBUTTONDOWN, MK_LBUTTON, MAKELP( 5, 5 ) )
   SENDMSG( h, WM_LBUTTONUP, 0, iif( hb_defaultValue( lInside, .T. ), MAKELP( 5, 5 ), MAKELP( 5, 500 ) ) )
RETURN

STATIC FUNCTION MAKELP( x, y )
RETURN x + y * 65536

STATIC PROCEDURE RunChecks()
   LOCAL n, nOn, nOff

   Check( "VALUE .T. and the default .F.", Win_1.Tgl_A.Value == .T. .AND. Win_1.Tgl_B.Value == .F. )
   Check( "Caption read", Win_1.Tgl_A.Caption == "Dark mode" .AND. Win_1.Tgl_B.Caption == "" )

   // Value := changes it without ON CHANGE
   Win_1.Tgl_A.Value := .F.
   Check( "Value := .F.", Win_1.Tgl_A.Value == .F. .AND. s_nChanged == 0 )
   Win_1.Tgl_A.Value := .T.

   // a click flips it and runs ON CHANGE, where This.Value is already the new value
   Click( "Tgl_A" )
   Check( "a click flips it", Win_1.Tgl_A.Value == .F. )
   Check( "ON CHANGE once, This.Value the new value", s_nChanged == 1 .AND. s_lSeen == .F. )
   Click( "Tgl_A" )
   Check( "a second click flips it back", Win_1.Tgl_A.Value == .T. .AND. s_nChanged == 2 .AND. s_lSeen == .T. )

   // released outside: nothing
   Click( "Tgl_A", .F. )
   Check( "released outside: no change", Win_1.Tgl_A.Value == .T. .AND. s_nChanged == 2 )

   // Space flips it; a repeating Space does not
   SENDMSG( H( "Tgl_A" ), WM_KEYDOWN, VK_SPACE, 1 )
   Check( "Space flips it", Win_1.Tgl_A.Value == .F. .AND. s_nChanged == 3 )
   SENDMSG( H( "Tgl_A" ), WM_KEYDOWN, VK_SPACE, 1 + 0x40000000 )
   Check( "a held Space flips it once", Win_1.Tgl_A.Value == .F. .AND. s_nChanged == 3 )

   // focus: the click above gave it the focus; moving it away and back runs both events
   s_cFocus := ""
   Win_1.Txt_1.SetFocus
   Win_1.Tgl_A.SetFocus
   Check( "ON LOSTFOCUS and ON GOTFOCUS (" + s_cFocus + ")", s_cFocus == "-A+A" )

   // tab stops
   Check( "a tab stop, NOTABSTOP not", HASTABSTOP( H( "Tgl_A" ) ) .AND. ! HASTABSTOP( H( "Tgl_C" ) ) )

   // Caption :=, Enabled
   Win_1.Tgl_B.Caption := "Later"
   Check( "Caption :=", Win_1.Tgl_B.Caption == "Later" )
   Win_1.Tgl_B.Enabled := .F.
   Check( "Enabled := .F.", ! Win_1.Tgl_B.Enabled .AND. ! ISWINDOWENABLED( H( "Tgl_B" ) ) )
   Win_1.Tgl_B.Enabled := .T.

   // what is drawn: the accent colour fills the track when on, not when off
   Win_1.Tgl_B.Value := .T.
   nOn := PAINTCOUNT( H( "Tgl_B" ), GETSYSCOLOR( 13 /* COLOR_HIGHLIGHT */ ) )
   Win_1.Tgl_B.Value := .F.
   nOff := PAINTCOUNT( H( "Tgl_B" ), GETSYSCOLOR( 13 ) )
   Check( "drawn on (" + hb_ntos( nOn ) + " accent pixels) and off (" + hb_ntos( nOff ) + ")", nOn > 200 .AND. nOff < 10 )
   Check( "BACKCOLOR is drawn", PAINTCOUNT( H( "Tgl_C" ), RGB( 255, 0, 0 ) ) > 2000 )
   Win_1.Tgl_C.BackColor := { 0, 0, 255 }
   Check( "BackColor :=", PAINTCOUNT( H( "Tgl_C" ), RGB( 0, 0, 255 ) ) > 2000 .AND. PAINTCOUNT( H( "Tgl_C" ), RGB( 255, 0, 0 ) ) == 0 )
   Check( "the font is set", GETFONTOF( H( "Tgl_A" ) ) != 0 )

   // DEFINE TOGGLE ... END TOGGLE
   Check( "DEFINE TOGGLE", Win_1.Tgl_D.Value == .T. .AND. Win_1.Tgl_D.Caption == "Defined" .AND. Win_1.Tgl_D.Row == 170 )

   // on a TAB page: hidden with its page
   Check( "on its TAB page: shown", ISWINDOWVISIBLE( H( "Tgl_P" ) ) )
   Win_1.Tab_1.Value := 2
   Check( "another page: hidden", ! ISWINDOWVISIBLE( H( "Tgl_P" ) ) )
   Win_1.Tab_1.Value := 1
   Check( "back: shown", ISWINDOWVISIBLE( H( "Tgl_P" ) ) )

   // release
   n := H( "Tgl_D" )
   Win_1.Tgl_D.Release
   Check( "Release", ! ISWINDOW( n ) .AND. ! IsControlDefined( Tgl_D, Win_1 ) )

   OutStd( "toggle: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "toggle: FAIL " + cName + hb_eol() )
   ENDIF
RETURN

#pragma BEGINDUMP
#include <windows.h>
#include "hbapi.h"

HB_FUNC( SENDMSG )
{
   SendMessageW( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), ( UINT ) hb_parni( 2 ), ( WPARAM ) hb_parnll( 3 ), ( LPARAM ) hb_parnll( 4 ) );
}

HB_FUNC( HASTABSTOP )
{
   hb_retl( ( GetWindowLongPtr( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), GWL_STYLE ) & WS_TABSTOP ) != 0 );
}

HB_FUNC( ISWINDOW )
{
   hb_retl( IsWindow( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ) ) );
}

HB_FUNC( GETFONTOF )
{
   hb_retnll( ( HB_LONGLONG ) SendMessageW( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), WM_GETFONT, 0, 0 ) );
}

/* PAINTCOUNT( hWnd, nColor ) -> pixels of that colour (within 8 per channel) when the control
   paints itself into a bitmap (WM_PRINTCLIENT) */
HB_FUNC( PAINTCOUNT )
{
   HWND       hWnd = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   COLORREF   c    = ( COLORREF ) hb_parnl( 2 );
   RECT       rc;
   HDC        hScr, hMem;
   HBITMAP    hBmp, hOld;
   BITMAPINFO bi;
   DWORD *    px;
   int        i, n = 0, cnt;

   GetClientRect( hWnd, &rc );
   hScr = GetDC( NULL );
   memset( &bi, 0, sizeof( bi ) );
   bi.bmiHeader.biSize        = sizeof( BITMAPINFOHEADER );
   bi.bmiHeader.biWidth       = rc.right;
   bi.bmiHeader.biHeight      = -rc.bottom;
   bi.bmiHeader.biPlanes      = 1;
   bi.bmiHeader.biBitCount    = 32;
   bi.bmiHeader.biCompression = BI_RGB;
   hBmp = CreateDIBSection( hScr, &bi, DIB_RGB_COLORS, ( void ** ) &px, NULL, 0 );
   hMem = CreateCompatibleDC( hScr );
   hOld = ( HBITMAP ) SelectObject( hMem, hBmp );
   SendMessageW( hWnd, WM_PRINTCLIENT, ( WPARAM ) hMem, PRF_CLIENT );
   GdiFlush();
   cnt = rc.right * rc.bottom;
   for( i = 0; i < cnt; i++ )
   {
      int r = ( px[ i ] >> 16 ) & 0xFF, g = ( px[ i ] >> 8 ) & 0xFF, b = px[ i ] & 0xFF;
      if( abs( r - GetRValue( c ) ) <= 8 && abs( g - GetGValue( c ) ) <= 8 && abs( b - GetBValue( c ) ) <= 8 )
         n++;
   }
   SelectObject( hMem, hOld );
   DeleteObject( hBmp );
   DeleteDC( hMem );
   ReleaseDC( NULL, hScr );
   hb_retni( n );
}
#pragma ENDDUMP
