/*
 * HMG5 5.2 - TOGGLE: an on/off switch (h_toggle.prg defines it).
 *
 * INITTOGGLE( hParent, cCaption, x, y, w, h, lValue, lInvisible, lNoTabStop ) -> hWnd
 *   x, y, w, h in design units (HMG5's creation hook scales them for DPI)
 * HMG_TOGGLEGET( hWnd ) -> lOn          HMG_TOGGLESET( hWnd, lOn )   (no event)
 *
 * Drawn here: a rounded track with a round knob (left: off, right: on), drawn four times
 * larger and shrunk with HALFTONE so the edges are smooth, and the caption on its right.
 * A click or Space flips it and calls Harbour:
 *   _HMG_TOGGLEEVENT( hWnd, nEvent )   1 changed by the user, 2 got the focus, 3 lost it
 * The colours are asked from Harbour when painting (the control's BACKCOLOR / FONTCOLOR,
 * else the form's BACKCOLOR):
 *   _HMG_TOGGLECOLORS( hWnd ) -> { nBack, nFore }   (-1: the default)
 */

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <windowsx.h>
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hmg_dpi.h"

#define TGL_CLASS   TEXT( "HMG5_Toggle" )
#define TGL_ON      TEXT( "HMG5_TGL_ON" )
#define TGL_FONT    TEXT( "HMG5_TGL_FONT" )
#define TGL_PRESSED TEXT( "HMG5_TGL_DOWN" )
#define TGL_SS      4   /* supersampling */

static PHB_ITEM tgl_call( const char * szFunc, HWND hWnd, int nEvent, BOOL bArg )
{
   PHB_DYNS pSym = hb_dynsymFindName( szFunc );
   PHB_ITEM pRet = NULL;
   if( pSym && hb_vmRequestReenter() )
   {
      hb_vmPushDynSym( pSym );
      hb_vmPushNil();
      hb_vmPushNumInt( ( HB_MAXINT ) ( HB_PTRUINT ) hWnd );
      if( bArg )
      {
         hb_vmPushInteger( nEvent );
         hb_vmDo( 2 );
      }
      else
         hb_vmDo( 1 );
      pRet = hb_itemNew( hb_param( -1, HB_IT_ANY ) );
      hb_vmRequestRestore();
   }
   return pRet;
}

static void tgl_event( HWND hWnd, int nEvent )
{
   PHB_ITEM p = tgl_call( "_HMG_TOGGLEEVENT", hWnd, nEvent, TRUE );
   if( p )
      hb_itemRelease( p );
}

static void tgl_colors( HWND hWnd, COLORREF * pBack, COLORREF * pFore )
{
   PHB_ITEM p = tgl_call( "_HMG_TOGGLECOLORS", hWnd, 0, FALSE );
   *pBack = HMG_SysColor( COLOR_BTNFACE );
   *pFore = HMG_SysColor( COLOR_BTNTEXT );
   if( p )
   {
      if( HB_IS_ARRAY( p ) && hb_arrayLen( p ) >= 2 )
      {
         if( hb_arrayGetNL( p, 1 ) >= 0 )
            *pBack = ( COLORREF ) hb_arrayGetNL( p, 1 );
         if( hb_arrayGetNL( p, 2 ) >= 0 )
            *pFore = ( COLORREF ) hb_arrayGetNL( p, 2 );
      }
      hb_itemRelease( p );
   }
}

static BOOL tgl_on( HWND hWnd )
{
   return GetProp( hWnd, TGL_ON ) != NULL;
}

static void tgl_set( HWND hWnd, BOOL bOn )
{
   if( bOn != tgl_on( hWnd ) )
   {
      if( bOn )
         SetProp( hWnd, TGL_ON, ( HANDLE ) 1 );
      else
         RemoveProp( hWnd, TGL_ON );
      InvalidateRect( hWnd, NULL, FALSE );
   }
}

static void tgl_flip( HWND hWnd )
{
   tgl_set( hWnd, ! tgl_on( hWnd ) );
   tgl_event( hWnd, 1 );
}

static COLORREF tgl_mix( COLORREF a, COLORREF b, int nPctB )
{
   return RGB( ( GetRValue( a ) * ( 100 - nPctB ) + GetRValue( b ) * nPctB ) / 100,
               ( GetGValue( a ) * ( 100 - nPctB ) + GetGValue( b ) * nPctB ) / 100,
               ( GetBValue( a ) * ( 100 - nPctB ) + GetBValue( b ) * nPctB ) / 100 );
}

/* the track: rcTrack in client pixels */
static void tgl_track( HWND hWnd, RECT * prc )
{
   RECT rc;
   int  h, w;
   GetClientRect( hWnd, &rc );
   h = HMG_DpiScaleSize( hWnd, 20 );
   if( h > rc.bottom - 2 )
      h = rc.bottom - 2;
   if( h < 6 )
      h = 6;
   w = h * 2;
   if( w > rc.right - 2 )
      w = rc.right - 2;
   prc->left   = 1;
   prc->top    = ( rc.bottom - h ) / 2;
   prc->right  = prc->left + w;
   prc->bottom = prc->top + h;
}

static void tgl_paint( HWND hWnd, HDC hDC )
{
   RECT     rc, rt, rTxt;
   HDC      hMem, hBig;
   HBITMAP  hBmp, hOldBmp, hBigBmp, hOldBig;
   HBRUSH   hBr;
   HPEN     hPen, hOldPen;
   HGDIOBJ  hOldBr, hOldFont = NULL;
   COLORREF cBack, cFore, cAccent, cTrack, cEdge, cKnob;
   BOOL     bOn = tgl_on( hWnd ), bEnabled = IsWindowEnabled( hWnd ), bDark = HMG_DarkIsOn();
   int      tw, th, bw, bh, d, pad;
   TCHAR    szText[ 512 ];
   HFONT    hFont = ( HFONT ) GetProp( hWnd, TGL_FONT );

   GetClientRect( hWnd, &rc );
   if( rc.right <= 0 || rc.bottom <= 0 )
      return;
   tgl_colors( hWnd, &cBack, &cFore );

   hMem    = CreateCompatibleDC( hDC );
   hBmp    = CreateCompatibleBitmap( hDC, rc.right, rc.bottom );
   hOldBmp = ( HBITMAP ) SelectObject( hMem, hBmp );
   hBr     = CreateSolidBrush( cBack );
   FillRect( hMem, &rc, hBr );
   DeleteObject( hBr );

   /* colours of the switch */
   cAccent = GetSysColor( COLOR_HIGHLIGHT );
   if( ! bEnabled )
   {
      cEdge  = tgl_mix( cBack, cFore, 35 );
      cTrack = bOn ? cEdge : cBack;
      cKnob  = bOn ? cBack : cEdge;
   }
   else if( bOn )
   {
      cEdge  = cAccent;
      cTrack = cAccent;
      cKnob  = RGB( 255, 255, 255 );
      if( bDark )
         cKnob = RGB( 0, 0, 0 );
   }
   else
   {
      cEdge  = tgl_mix( cBack, cFore, 70 );
      cTrack = cBack;
      cKnob  = cEdge;
   }

   /* the track and the knob, four times larger, then shrunk onto hMem */
   tgl_track( hWnd, &rt );
   tw = rt.right - rt.left;
   th = rt.bottom - rt.top;
   bw = tw * TGL_SS;
   bh = th * TGL_SS;
   hBig    = CreateCompatibleDC( hDC );
   hBigBmp = CreateCompatibleBitmap( hDC, bw, bh );
   hOldBig = ( HBITMAP ) SelectObject( hBig, hBigBmp );
   {
      RECT r = { 0, 0, bw, bh };
      hBr = CreateSolidBrush( cBack );
      FillRect( hBig, &r, hBr );
      DeleteObject( hBr );
   }
   hPen    = CreatePen( PS_SOLID, TGL_SS * HMG_DpiScaleSize( hWnd, 1 ), cEdge );
   hBr     = CreateSolidBrush( cTrack );
   hOldPen = SelectObject( hBig, hPen );
   hOldBr  = SelectObject( hBig, hBr );
   RoundRect( hBig, TGL_SS / 2, TGL_SS / 2, bw - TGL_SS / 2, bh - TGL_SS / 2, bh, bh );
   SelectObject( hBig, hOldBr );
   SelectObject( hBig, hOldPen );
   DeleteObject( hBr );
   DeleteObject( hPen );

   /* the knob: smaller when off, as Windows draws it */
   pad = bOn ? bh * 22 / 100 : bh * 27 / 100;
   d   = bh - 2 * pad;
   hBr    = CreateSolidBrush( cKnob );
   hPen   = CreatePen( PS_SOLID, 1, cKnob );
   hOldPen = SelectObject( hBig, hPen );
   hOldBr  = SelectObject( hBig, hBr );
   if( bOn )
      Ellipse( hBig, bw - pad - d, pad, bw - pad, pad + d );
   else
      Ellipse( hBig, pad, pad, pad + d, pad + d );
   SelectObject( hBig, hOldBr );
   SelectObject( hBig, hOldPen );
   DeleteObject( hBr );
   DeleteObject( hPen );

   SetStretchBltMode( hMem, HALFTONE );
   SetBrushOrgEx( hMem, 0, 0, NULL );
   StretchBlt( hMem, rt.left, rt.top, tw, th, hBig, 0, 0, bw, bh, SRCCOPY );
   SelectObject( hBig, hOldBig );
   DeleteObject( hBigBmp );
   DeleteDC( hBig );

   /* the caption */
   GetWindowText( hWnd, szText, ( int ) ( sizeof( szText ) / sizeof( TCHAR ) ) );
   rTxt.left   = rt.right + HMG_DpiScaleSize( hWnd, 8 );
   rTxt.top    = 0;
   rTxt.right  = rc.right;
   rTxt.bottom = rc.bottom;
   if( hFont )
      hOldFont = SelectObject( hMem, hFont );
   SetBkMode( hMem, TRANSPARENT );
   SetTextColor( hMem, bEnabled ? cFore : tgl_mix( cBack, cFore, 45 ) );
   if( szText[ 0 ] )
      DrawText( hMem, szText, -1, &rTxt, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_END_ELLIPSIS );

   /* the focus rectangle, unless Windows hides it until the keyboard is used */
   if( GetFocus() == hWnd && ! ( SendMessage( hWnd, WM_QUERYUISTATE, 0, 0 ) & UISF_HIDEFOCUS ) )
   {
      RECT rf;
      if( szText[ 0 ] )
      {
         RECT rCalc = rTxt;
         DrawText( hMem, szText, -1, &rCalc, DT_LEFT | DT_SINGLELINE | DT_CALCRECT );
         rf.left   = rTxt.left - 2;
         rf.right  = min( rCalc.right + 2, rc.right );
         rf.top    = ( rc.bottom - ( rCalc.bottom - rCalc.top ) ) / 2 - 1;
         rf.bottom = rf.top + ( rCalc.bottom - rCalc.top ) + 2;
      }
      else
      {
         rf = rt;
         InflateRect( &rf, 1, 1 );
      }
      SetTextColor( hMem, cFore );
      SetBkColor( hMem, cBack );
      DrawFocusRect( hMem, &rf );
   }
   if( hOldFont )
      SelectObject( hMem, hOldFont );

   BitBlt( hDC, 0, 0, rc.right, rc.bottom, hMem, 0, 0, SRCCOPY );
   SelectObject( hMem, hOldBmp );
   DeleteObject( hBmp );
   DeleteDC( hMem );
}

static LRESULT CALLBACK tgl_proc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   switch( msg )
   {
      case WM_ERASEBKGND:
         return 1;

      case WM_PAINT:
      {
         PAINTSTRUCT ps;
         HDC         hDC = BeginPaint( hWnd, &ps );
         tgl_paint( hWnd, hDC );
         EndPaint( hWnd, &ps );
         return 0;
      }

      case WM_PRINTCLIENT:
         tgl_paint( hWnd, ( HDC ) wParam );
         return 0;

      case WM_SETFONT:
         SetProp( hWnd, TGL_FONT, ( HANDLE ) wParam );
         if( LOWORD( lParam ) )
            InvalidateRect( hWnd, NULL, FALSE );
         return 0;

      case WM_GETFONT:
         return ( LRESULT ) GetProp( hWnd, TGL_FONT );

      case WM_SETTEXT:
      {
         LRESULT r = DefWindowProc( hWnd, msg, wParam, lParam );
         InvalidateRect( hWnd, NULL, FALSE );
         return r;
      }

      case WM_ENABLE:
      case WM_UPDATEUISTATE:
      {
         LRESULT r = DefWindowProc( hWnd, msg, wParam, lParam );
         InvalidateRect( hWnd, NULL, FALSE );
         return r;
      }

      case WM_SETFOCUS:
         InvalidateRect( hWnd, NULL, FALSE );
         tgl_event( hWnd, 2 );
         return 0;

      case WM_KILLFOCUS:
         RemoveProp( hWnd, TGL_PRESSED );
         InvalidateRect( hWnd, NULL, FALSE );
         tgl_event( hWnd, 3 );
         return 0;

      case WM_GETDLGCODE:
         return DLGC_BUTTON;

      case WM_LBUTTONDOWN:
      case WM_LBUTTONDBLCLK:
         if( GetFocus() != hWnd )
            SetFocus( hWnd );
         SetProp( hWnd, TGL_PRESSED, ( HANDLE ) 1 );
         SetCapture( hWnd );
         return 0;

      case WM_LBUTTONUP:
         if( GetProp( hWnd, TGL_PRESSED ) )
         {
            RECT  rc;
            POINT pt;
            RemoveProp( hWnd, TGL_PRESSED );
            ReleaseCapture();
            GetClientRect( hWnd, &rc );
            pt.x = GET_X_LPARAM( lParam );
            pt.y = GET_Y_LPARAM( lParam );
            if( PtInRect( &rc, pt ) )
               tgl_flip( hWnd );
         }
         return 0;

      case WM_CAPTURECHANGED:
         RemoveProp( hWnd, TGL_PRESSED );
         return 0;

      case WM_KEYDOWN:
         if( wParam == VK_SPACE )
         {
            if( ! ( lParam & 0x40000000 ) )   /* not when the key repeats */
               tgl_flip( hWnd );
            return 0;
         }
         break;

      case WM_CHAR:
         if( wParam == TEXT( ' ' ) )
            return 0;
         break;

      case WM_NCDESTROY:
         RemoveProp( hWnd, TGL_ON );
         RemoveProp( hWnd, TGL_FONT );
         RemoveProp( hWnd, TGL_PRESSED );
         break;
   }
   return DefWindowProc( hWnd, msg, wParam, lParam );
}

HB_FUNC( INITTOGGLE )
{
   static BOOL s_bClass = FALSE;
   HWND  hParent = ( HWND ) HMG_parnl( 1 );
   HWND  hWnd;
   DWORD style = WS_CHILD | WS_CLIPSIBLINGS;

   if( ! s_bClass )
   {
      WNDCLASS wc;
      memset( &wc, 0, sizeof( wc ) );
      wc.style         = CS_DBLCLKS;
      wc.lpfnWndProc   = tgl_proc;
      wc.hInstance     = GetModuleHandle( NULL );
      wc.hCursor       = LoadCursor( NULL, IDC_ARROW );
      wc.lpszClassName = TGL_CLASS;
      RegisterClass( &wc );
      s_bClass = TRUE;
   }
   if( ! hb_parl( 8 ) )
      style |= WS_VISIBLE;
   if( ! hb_parl( 9 ) )
      style |= WS_TABSTOP;
   hWnd = CreateWindowEx( 0, TGL_CLASS, HMG_parc( 2 ), style,
                          hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ),
                          hParent, NULL, GetModuleHandle( NULL ), NULL );
   if( hWnd && hb_parl( 7 ) )
      SetProp( hWnd, TGL_ON, ( HANDLE ) 1 );
   HMG_retnl( ( LONG_PTR ) hWnd );
}

HB_FUNC( HMG_TOGGLEGET )
{
   hb_retl( tgl_on( ( HWND ) HMG_parnl( 1 ) ) );
}

HB_FUNC( HMG_TOGGLESET )
{
   tgl_set( ( HWND ) HMG_parnl( 1 ), hb_parl( 2 ) );
}
