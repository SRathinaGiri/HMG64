/*
 * Unit test for HMG_Toast (HMG5 5.2, c_toast.c). The toasts are real windows; the test waits
 * for their animations by pumping messages, and clicks them with messages.
 */
#include "hmg.ch"

#define WM_LBUTTONUP     0x0202

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "toast: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 40, 40 WIDTH 400 HEIGHT 200 TITLE "toast test" MAIN ON INIT RunChecks()
      @ 10, 10 TEXTBOX Txt_1 WIDTH 200
   END WINDOW
   Win_1.Activate
RETURN NIL

/* pumps messages for nMs */
STATIC PROCEDURE Pump( nMs )
   LOCAL nEnd := hb_MilliSeconds() + nMs
   DO WHILE hb_MilliSeconds() < nEnd
      DO EVENTS
      hb_idleSleep( 0.01 )
   ENDDO
RETURN

STATIC PROCEDURE RunChecks()
   LOCAL h1, h2, h3, a1, a2, aW, nGap, hFocus, hActive, nPlain, nTall, nLong, i, lHover

   Win_1.Txt_1.SetFocus
   hFocus := GETFOCUS()
   hActive := GETACTIVEWINDOW()

   h1 := HMG_Toast( "Saved 12 invoices", "Export" )
   Check( "a window, shown", ISWINDOW( h1 ) .AND. ISWINDOWVISIBLE( h1 ) .AND. HMG_ToastCount() == 1 )
   Check( "the focus and the active window stay", GETFOCUS() == hFocus .AND. GETACTIVEWINDOW() == hActive )
   Check( "no activation, on top, not in the taskbar", EXSTYLEHAS( h1, 0x08000000 ) .AND. EXSTYLEHAS( h1, 0x00000008 ) .AND. EXSTYLEHAS( h1, 0x00000080 ) )

   Pump( 600 )
   a1 := WINRECT( h1 )
   aW := WORKAREA( h1 )
   nGap := Round( ( a1[ 3 ] - a1[ 1 ] ) * 12 / 360, 0 )    // 12 at 96 DPI, the width 360
   Check( "slid in to the bottom right (" + hb_ValToExp( a1 ) + " in " + hb_ValToExp( aW ) + ")", ;
          Abs( a1[ 3 ] - ( aW[ 3 ] - nGap ) ) <= 1 .AND. Abs( a1[ 4 ] - ( aW[ 4 ] - nGap ) ) <= 1 )
   Check( "fully shown", LAYEREDALPHA( h1 ) == 255 )
   Check( "it draws its text", INKPIXELS( h1 ) > 50 )
   // not "the same focus": another program may be activated meanwhile; a toast never gets it
   Check( "no focus or activation for the toast after its animation", NoToastFocus( h1 ) )

   // a second one: at the bottom; the first moves up
   h2 := HMG_Toast( "Second" )
   Pump( 600 )
   a2 := WINRECT( h2 )
   a1 := WINRECT( h1 )
   Check( "the newest at the bottom, the older above it", ;
          Abs( a2[ 4 ] - ( aW[ 4 ] - nGap ) ) <= 1 .AND. a1[ 4 ] < a2[ 2 ] .AND. a2[ 2 ] - a1[ 4 ] <= nGap )

   // a click on the newest: it fades out, the older one moves down
   SENDMSG( h2, WM_LBUTTONUP, 0, 0 )
   Pump( 900 )
   a1 := WINRECT( h1 )
   Check( "a click closes it", ! ISWINDOW( h2 ) .AND. HMG_ToastCount() == 1 )
   Check( "the one above moved down", Abs( a1[ 4 ] - ( aW[ 4 ] - nGap ) ) <= 1 )

   // nSeconds: 1 closes by itself, 0 stays
   HMG_ToastCloseAll( .T. )
   h1 := HMG_Toast( "One second", , 1 )
   h2 := HMG_Toast( "Stays", , 0 )
   Pump( 2200 )
   // a toast stays while the mouse is on it: the real mouse may rest where the toasts are
   lHover := CURSORIN( h1 )
   Check( "nSeconds 1: gone by itself" + iif( lHover, " (the mouse is on it: it stays)", "" ), iif( lHover, ISWINDOW( h1 ), ! ISWINDOW( h1 ) ) )
   Check( "nSeconds 0: still there", ISWINDOW( h2 ) .AND. HMG_ToastCount() == iif( lHover, 2, 1 ) )
   HMG_ToastCloseAll( .T. )
   Check( "CloseAll( .T. )", ! ISWINDOW( h2 ) .AND. HMG_ToastCount() == 0 )

   // sizes: an icon and a title make it taller; long text wraps
   h1 := HMG_Toast( "Short", , 0 )
   nPlain := WINRECT( h1 )[ 4 ] - WINRECT( h1 )[ 2 ]
   h2 := HMG_Toast( "Short", "With a title", 0, 3 )
   nTall := WINRECT( h2 )[ 4 ] - WINRECT( h2 )[ 2 ]
   h3 := HMG_Toast( Replicate( "A long line of text that wraps. ", 8 ), , 0 )
   nLong := WINRECT( h3 )[ 4 ] - WINRECT( h3 )[ 2 ]
   Check( "title and icon taller (" + hb_ntos( nPlain ) + " < " + hb_ntos( nTall ) + ")", nTall > nPlain )
   Check( "long text wraps (" + hb_ntos( nLong ) + ")", nLong > nPlain * 2 )
   Check( "all the same width", WINRECT( h1 )[ 3 ] - WINRECT( h1 )[ 1 ] == WINRECT( h3 )[ 3 ] - WINRECT( h3 )[ 1 ] )

   // CloseAll() fades them all out
   HMG_ToastCloseAll()
   Pump( 900 )
   Check( "CloseAll() fades them out", HMG_ToastCount() == 0 .AND. ! ISWINDOW( h1 ) .AND. ! ISWINDOW( h3 ) )

   // at most 16: the oldest goes
   FOR i := 1 TO 18
      HMG_Toast( "Toast " + hb_ntos( i ), , 0 )
   NEXT
   Check( "at most 16 (" + hb_ntos( HMG_ToastCount() ) + ")", HMG_ToastCount() == 16 )
   HMG_ToastCloseAll( .T. )
   Check( "never the focus or the foreground for a toast", NoToastFocus( h1 ) .AND. NoToastFocus( h2 ) .AND. NoToastFocus( h3 ) )

   OutStd( "toast: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC FUNCTION NoToastFocus( h )
RETURN GETFOCUS() != h .AND. GETACTIVEWINDOW() != h .AND. GETFOREGROUNDWINDOW() != h .AND. ! ISACTIVATED( h )

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "toast: FAIL " + cName + hb_eol() )
   ENDIF
RETURN

#pragma BEGINDUMP
#include <windows.h>
#include "hbapi.h"

#define HW( n ) ( ( HWND ) ( HB_PTRUINT ) hb_parnll( n ) )

HB_FUNC( SENDMSG )
{
   SendMessageW( HW( 1 ), ( UINT ) hb_parni( 2 ), ( WPARAM ) hb_parnll( 3 ), ( LPARAM ) hb_parnll( 4 ) );
}
HB_FUNC( ISWINDOW )        { hb_retl( IsWindow( HW( 1 ) ) ); }
/* CURSORIN( hWnd ): the mouse pointer is on the window */
HB_FUNC( CURSORIN )
{
   POINT pt;
   RECT  r;
   hb_retl( IsWindow( HW( 1 ) ) && GetCursorPos( &pt ) && GetWindowRect( HW( 1 ), &r ) && PtInRect( &r, pt ) );
}
/* ISACTIVATED( hWnd ): Windows shows it as the active window */
HB_FUNC( ISACTIVATED )
{
   WINDOWINFO wi;
   wi.cbSize = sizeof( wi );
   hb_retl( IsWindow( HW( 1 ) ) && GetWindowInfo( HW( 1 ), &wi ) && wi.dwWindowStatus == WS_ACTIVECAPTION );
}
HB_FUNC( EXSTYLEHAS )      { hb_retl( ( GetWindowLongPtr( HW( 1 ), GWL_EXSTYLE ) & hb_parnl( 2 ) ) != 0 ); }

static void ret_rect( RECT * r )
{
   hb_reta( 4 );
   hb_storvni( r->left, -1, 1 );
   hb_storvni( r->top, -1, 2 );
   hb_storvni( r->right, -1, 3 );
   hb_storvni( r->bottom, -1, 4 );
}
HB_FUNC( WINRECT )
{
   RECT r;
   GetWindowRect( HW( 1 ), &r );
   ret_rect( &r );
}
HB_FUNC( WORKAREA )
{
   MONITORINFO mi;
   mi.cbSize = sizeof( mi );
   GetMonitorInfo( MonitorFromWindow( HW( 1 ), MONITOR_DEFAULTTOPRIMARY ), &mi );
   ret_rect( &mi.rcWork );
}
HB_FUNC( LAYEREDALPHA )
{
   BYTE  a = 0;
   DWORD f = 0;
   GetLayeredWindowAttributes( HW( 1 ), NULL, &a, &f );
   hb_retni( a );
}
/* INKPIXELS( hWnd ) -> dark pixels when the window paints itself into a bitmap */
HB_FUNC( INKPIXELS )
{
   HWND       hWnd = HW( 1 );
   RECT       rc;
   HDC        hScr = GetDC( NULL ), hMem;
   HBITMAP    hBmp, hOld;
   BITMAPINFO bi;
   DWORD *    px;
   int        i, n = 0;
   GetClientRect( hWnd, &rc );
   memset( &bi, 0, sizeof( bi ) );
   bi.bmiHeader.biSize = sizeof( BITMAPINFOHEADER );
   bi.bmiHeader.biWidth = rc.right;
   bi.bmiHeader.biHeight = -rc.bottom;
   bi.bmiHeader.biPlanes = 1;
   bi.bmiHeader.biBitCount = 32;
   hBmp = CreateDIBSection( hScr, &bi, DIB_RGB_COLORS, ( void ** ) &px, NULL, 0 );
   hMem = CreateCompatibleDC( hScr );
   hOld = ( HBITMAP ) SelectObject( hMem, hBmp );
   SendMessageW( hWnd, WM_PRINTCLIENT, ( WPARAM ) hMem, PRF_CLIENT );
   GdiFlush();
   for( i = 0; i < rc.right * rc.bottom; i++ )
      if( ( ( px[ i ] >> 16 ) & 0xFF ) < 100 && ( ( px[ i ] >> 8 ) & 0xFF ) < 100 && ( px[ i ] & 0xFF ) < 100 )
         n++;
   SelectObject( hMem, hOld );
   DeleteObject( hBmp );
   DeleteDC( hMem );
   ReleaseDC( NULL, hScr );
   hb_retni( n );
}
#pragma ENDDUMP
