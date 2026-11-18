/*
 * HMG5 5.2 - toast notifications.
 *
 * HMG_TOAST( cText [, cTitle] [, nSeconds] [, nIcon] ) -> hWnd
 *   A small window that slides in at the bottom right of the work area (the monitor of the
 *   active window) and fades out after nSeconds (default 4; 0: stays until clicked). It never
 *   takes the focus or activates. Several stack, the newest at the bottom; when one goes, the
 *   ones above it move down. A click closes it; while the mouse is on it, it stays.
 *   nIcon: 0 none (default), 1 information, 2 warning, 3 error.
 * HMG_TOASTCOUNT() -> n          toasts on the screen (tests)
 * HMG_TOASTCLOSEALL( [lNow] )    fades them out (lNow: closes them at once)
 *
 * Not the Windows notification centre: that needs an app identity and a Start menu shortcut.
 * Colours follow SET DARKMODE; sizes follow the monitor's DPI.
 */

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <windowsx.h>
#include "hbapi.h"
#include "hmg_dpi.h"

#define TST_CLASS    TEXT( "HMG5_Toast" )
#define TST_MAX      16
#define TST_ANIM     1      /* timer: 15 ms animation */
#define TST_LIFE     2      /* timer: time to live */
#define TST_W        360    /* width, 96 DPI pixels */
#define TST_MARGIN   12
#define TST_GAP      8
#define TST_PAD      14

typedef struct
{
   HWND   hWnd;
   TCHAR *pText;
   TCHAR *pTitle;
   int    nIcon;
   int    nSeconds;
   int    x, y, tx, ty;      /* where it is, where it goes */
   int    nAlpha;            /* 0..255 */
   BOOL   bClosing;
   BOOL   bHover;
   int    w, h;
   HFONT  hFont, hBold;
   int    nDpi;
} TOAST;

static TOAST * s_pToast[ TST_MAX ];   /* oldest first */
static int     s_nToast = 0;

static int tst_scale( TOAST * t, int v )
{
   return MulDiv( v, t->nDpi, 96 );
}

static TCHAR * tst_dup( const TCHAR * s )
{
   size_t  n = s ? lstrlen( s ) : 0;
   TCHAR * p = ( TCHAR * ) hb_xgrab( ( n + 1 ) * sizeof( TCHAR ) );
   if( n )
      memcpy( p, s, n * sizeof( TCHAR ) );
   p[ n ] = 0;
   return p;
}

static void tst_workarea( RECT * prc, UINT * pDpi )
{
   HWND        h = GetActiveWindow();
   HMONITOR    hMon;
   MONITORINFO mi;
   HDC         hDC;
   if( h == NULL )
      h = GetForegroundWindow();
   hMon = MonitorFromWindow( h, MONITOR_DEFAULTTOPRIMARY );
   mi.cbSize = sizeof( mi );
   GetMonitorInfo( hMon, &mi );
   *prc = mi.rcWork;
   {
      typedef HRESULT ( WINAPI * PFN )( HMONITOR, int, UINT *, UINT * );
      static PFN s_pfn = NULL;
      static BOOL s_bTried = FALSE;
      UINT dx = 0, dy = 0;
      if( ! s_bTried )
      {
         HMODULE hShcore = LoadLibrary( TEXT( "shcore.dll" ) );
         s_bTried = TRUE;
         if( hShcore )
            s_pfn = ( PFN ) ( void * ) GetProcAddress( hShcore, "GetDpiForMonitor" );
      }
      if( s_pfn && SUCCEEDED( s_pfn( hMon, 0 /* MDT_EFFECTIVE_DPI */, &dx, &dy ) ) && dy )
      {
         *pDpi = dy;
         return;
      }
   }
   hDC = GetDC( NULL );
   *pDpi = ( UINT ) GetDeviceCaps( hDC, LOGPIXELSY );
   ReleaseDC( NULL, hDC );
}

/* where every toast goes: the newest at the bottom right, the older ones above it */
static void tst_layout( void )
{
   RECT rcWork;
   UINT nDpi;
   int  i, y;
   tst_workarea( &rcWork, &nDpi );
   y = rcWork.bottom;
   for( i = s_nToast - 1; i >= 0; i-- )
   {
      TOAST * t = s_pToast[ i ];
      if( t->bClosing && t->nAlpha == 0 )
         continue;
      y -= tst_scale( t, i == s_nToast - 1 ? TST_MARGIN : TST_GAP ) + t->h;
      t->tx = rcWork.right - tst_scale( t, TST_MARGIN ) - t->w;
      t->ty = y;
   }
}

static void tst_remove( TOAST * t )
{
   int i, j;
   for( i = 0; i < s_nToast; i++ )
   {
      if( s_pToast[ i ] == t )
      {
         for( j = i; j < s_nToast - 1; j++ )
            s_pToast[ j ] = s_pToast[ j + 1 ];
         s_nToast--;
         break;
      }
   }
   tst_layout();
   for( i = 0; i < s_nToast; i++ )
      SetTimer( s_pToast[ i ]->hWnd, TST_ANIM, 15, NULL );
}

static void tst_colors( COLORREF * pBg, COLORREF * pEdge, COLORREF * pText, COLORREF * pSub )
{
   if( HMG_DarkIsOn() )
   {
      *pBg = RGB( 43, 43, 43 );   *pEdge = RGB( 75, 75, 75 );
      *pText = RGB( 240, 240, 240 ); *pSub = RGB( 205, 205, 205 );
   }
   else
   {
      *pBg = RGB( 249, 249, 249 ); *pEdge = RGB( 200, 200, 200 );
      *pText = RGB( 0, 0, 0 );    *pSub = RGB( 60, 60, 60 );
   }
}

static HICON tst_icon( TOAST * t )
{
   LPCTSTR id = NULL;
   switch( t->nIcon )
   {
      case 1: id = IDI_INFORMATION; break;
      case 2: id = IDI_WARNING;     break;
      case 3: id = IDI_ERROR;       break;
   }
   if( id == NULL )
      return NULL;
   return ( HICON ) LoadImage( NULL, id, IMAGE_ICON, tst_scale( t, 32 ), tst_scale( t, 32 ), LR_SHARED );
}

/* text sizes: sets t->w and t->h */
static void tst_measure( TOAST * t )
{
   HDC   hDC = GetDC( NULL );
   RECT  r;
   int   pad = tst_scale( t, TST_PAD ), x0 = pad, h = pad;
   int   nTextW;
   t->w = tst_scale( t, TST_W );
   if( t->nIcon )
      x0 += tst_scale( t, 32 ) + tst_scale( t, 12 );
   nTextW = t->w - x0 - pad;
   if( t->pTitle[ 0 ] )
   {
      SetRect( &r, 0, 0, nTextW, 0 );
      SelectObject( hDC, t->hBold );
      DrawText( hDC, t->pTitle, -1, &r, DT_CALCRECT | DT_WORDBREAK | DT_NOPREFIX );
      h += r.bottom + tst_scale( t, 4 );
   }
   SetRect( &r, 0, 0, nTextW, 0 );
   SelectObject( hDC, t->hFont );
   DrawText( hDC, t->pText[ 0 ] ? t->pText : TEXT( " " ), -1, &r, DT_CALCRECT | DT_WORDBREAK | DT_NOPREFIX );
   h += r.bottom + pad;
   if( t->nIcon && h < tst_scale( t, 32 ) + 2 * pad )
      h = tst_scale( t, 32 ) + 2 * pad;
   ReleaseDC( NULL, hDC );
   t->h = h;
}

static void tst_paint( TOAST * t, HDC hDC )
{
   RECT     rc, r;
   COLORREF cBg, cEdge, cText, cSub;
   HBRUSH   hBr;
   HDC      hMem;
   HBITMAP  hBmp, hOld;
   HICON    hIcon;
   int      pad = tst_scale( t, TST_PAD ), x0 = pad, y = pad;

   GetClientRect( t->hWnd, &rc );
   tst_colors( &cBg, &cEdge, &cText, &cSub );
   hMem = CreateCompatibleDC( hDC );
   hBmp = CreateCompatibleBitmap( hDC, rc.right, rc.bottom );
   hOld = ( HBITMAP ) SelectObject( hMem, hBmp );

   hBr = CreateSolidBrush( cBg );
   FillRect( hMem, &rc, hBr );
   DeleteObject( hBr );
   hBr = CreateSolidBrush( cEdge );
   FrameRect( hMem, &rc, hBr );
   DeleteObject( hBr );

   hIcon = tst_icon( t );
   if( hIcon )
   {
      DrawIconEx( hMem, pad, pad, hIcon, tst_scale( t, 32 ), tst_scale( t, 32 ), 0, NULL, DI_NORMAL );
      x0 += tst_scale( t, 32 ) + tst_scale( t, 12 );
   }
   SetBkMode( hMem, TRANSPARENT );
   if( t->pTitle[ 0 ] )
   {
      SetRect( &r, x0, y, rc.right - pad, rc.bottom );
      SelectObject( hMem, t->hBold );
      SetTextColor( hMem, cText );
      DrawText( hMem, t->pTitle, -1, &r, DT_CALCRECT | DT_WORDBREAK | DT_NOPREFIX );
      DrawText( hMem, t->pTitle, -1, &r, DT_WORDBREAK | DT_NOPREFIX );
      y = r.bottom + tst_scale( t, 4 );
   }
   SetRect( &r, x0, y, rc.right - pad, rc.bottom - pad );
   SelectObject( hMem, t->hFont );
   SetTextColor( hMem, t->pTitle[ 0 ] ? cSub : cText );
   DrawText( hMem, t->pText, -1, &r, DT_WORDBREAK | DT_NOPREFIX );

   BitBlt( hDC, 0, 0, rc.right, rc.bottom, hMem, 0, 0, SRCCOPY );
   SelectObject( hMem, hOld );
   DeleteObject( hBmp );
   DeleteDC( hMem );
}

static void tst_close( TOAST * t )
{
   if( ! t->bClosing )
   {
      t->bClosing = TRUE;
      KillTimer( t->hWnd, TST_LIFE );
      SetTimer( t->hWnd, TST_ANIM, 15, NULL );
   }
}

/* one animation step: towards (tx, ty), alpha towards 255 or 0; FALSE when done */
static BOOL tst_step( TOAST * t )
{
   int  dx = t->tx - t->x, dy = t->ty - t->y;
   int  nTarget = t->bClosing ? 0 : 255;
   BOOL bMore = FALSE;

   if( dx || dy )
   {
      int sx = dx * 30 / 100, sy = dy * 30 / 100;
      if( sx == 0 && dx )
         sx = dx > 0 ? 1 : -1;
      if( sy == 0 && dy )
         sy = dy > 0 ? 1 : -1;
      t->x += sx;
      t->y += sy;
      SetWindowPos( t->hWnd, HWND_TOPMOST, t->x, t->y, 0, 0, SWP_NOSIZE | SWP_NOACTIVATE );
      bMore = TRUE;
   }
   if( t->nAlpha != nTarget )
   {
      int s = t->bClosing ? 26 : 40;
      t->nAlpha = t->nAlpha < nTarget ? min( nTarget, t->nAlpha + s ) : max( nTarget, t->nAlpha - s );
      SetLayeredWindowAttributes( t->hWnd, 0, ( BYTE ) t->nAlpha, LWA_ALPHA );
      bMore = TRUE;
   }
   return bMore;
}

static LRESULT CALLBACK tst_proc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   TOAST * t = ( TOAST * ) GetWindowLongPtr( hWnd, GWLP_USERDATA );

   switch( msg )
   {
      case WM_MOUSEACTIVATE:
         return MA_NOACTIVATE;

      case WM_ERASEBKGND:
         return 1;

      case WM_PAINT:
      {
         PAINTSTRUCT ps;
         HDC         hDC = BeginPaint( hWnd, &ps );
         if( t )
            tst_paint( t, hDC );
         EndPaint( hWnd, &ps );
         return 0;
      }

      case WM_PRINTCLIENT:
         if( t )
            tst_paint( t, ( HDC ) wParam );
         return 0;

      case WM_TIMER:
         if( t == NULL )
            break;
         if( wParam == TST_LIFE )
         {
            if( ! t->bHover )
               tst_close( t );
         }
         else if( wParam == TST_ANIM )
         {
            if( ! tst_step( t ) )
            {
               KillTimer( hWnd, TST_ANIM );
               if( t->bClosing )
                  DestroyWindow( hWnd );
            }
         }
         return 0;

      case WM_MOUSEMOVE:
         if( t && ! t->bHover )
         {
            TRACKMOUSEEVENT tme;
            t->bHover = TRUE;
            tme.cbSize = sizeof( tme );
            tme.dwFlags = TME_LEAVE;
            tme.hwndTrack = hWnd;
            tme.dwHoverTime = 0;
            TrackMouseEvent( &tme );
         }
         return 0;

      case WM_MOUSELEAVE:
         if( t )
         {
            t->bHover = FALSE;
            if( t->nSeconds > 0 && ! t->bClosing )
               SetTimer( hWnd, TST_LIFE, 1500, NULL );   /* a moment after the mouse leaves */
         }
         return 0;

      case WM_LBUTTONUP:
         if( t )
            tst_close( t );
         return 0;

      case WM_NCDESTROY:
         if( t )
         {
            SetWindowLongPtr( hWnd, GWLP_USERDATA, 0 );
            tst_remove( t );
            DeleteObject( t->hFont );
            DeleteObject( t->hBold );
            hb_xfree( t->pText );
            hb_xfree( t->pTitle );
            hb_xfree( t );
         }
         break;
   }
   return DefWindowProc( hWnd, msg, wParam, lParam );
}

HB_FUNC( HMG_TOAST )
{
   static BOOL s_bClass = FALSE;
   TOAST *    t;
   RECT       rcWork;
   UINT       nDpi;
   NONCLIENTMETRICS ncm;

   if( ! s_bClass )
   {
      WNDCLASS wc;
      memset( &wc, 0, sizeof( wc ) );
      wc.lpfnWndProc   = tst_proc;
      wc.hInstance     = GetModuleHandle( NULL );
      wc.hCursor       = LoadCursor( NULL, IDC_HAND );
      wc.lpszClassName = TST_CLASS;
      RegisterClass( &wc );
      s_bClass = TRUE;
   }

   /* the oldest goes at once when there is no room for another */
   if( s_nToast >= TST_MAX )
      DestroyWindow( s_pToast[ 0 ]->hWnd );

   t = ( TOAST * ) hb_xgrabz( sizeof( TOAST ) );
   t->pText    = tst_dup( HB_ISCHAR( 1 ) ? HMG_parc( 1 ) : NULL );
   t->pTitle   = tst_dup( HB_ISCHAR( 2 ) ? HMG_parc( 2 ) : NULL );
   t->nSeconds = HB_ISNUM( 3 ) ? hb_parni( 3 ) : 4;
   t->nIcon    = HB_ISNUM( 4 ) ? hb_parni( 4 ) : 0;
   if( t->nIcon < 0 || t->nIcon > 3 )
      t->nIcon = 0;

   tst_workarea( &rcWork, &nDpi );
   t->nDpi = ( int ) nDpi;

   ncm.cbSize = sizeof( ncm );
   SystemParametersInfo( SPI_GETNONCLIENTMETRICS, sizeof( ncm ), &ncm, 0 );
   {
      LOGFONT lf = ncm.lfMessageFont;
      HDC     hDC = GetDC( NULL );
      int     nSys = GetDeviceCaps( hDC, LOGPIXELSY );
      ReleaseDC( NULL, hDC );
      lf.lfHeight = MulDiv( lf.lfHeight, t->nDpi, nSys );   /* the monitor's DPI */
      t->hFont = CreateFontIndirect( &lf );
      lf.lfWeight = FW_SEMIBOLD;
      t->hBold = CreateFontIndirect( &lf );
   }
   tst_measure( t );

   s_pToast[ s_nToast++ ] = t;
   tst_layout();
   t->x = rcWork.right;                     /* slides in from the right edge */
   t->y = t->ty;
   t->nAlpha = 0;

   t->hWnd = CreateWindowEx( WS_EX_TOOLWINDOW | WS_EX_TOPMOST | WS_EX_NOACTIVATE | WS_EX_LAYERED,
                             TST_CLASS, TEXT( "" ), WS_POPUP,
                             t->x, t->y, t->w, t->h, NULL, NULL, GetModuleHandle( NULL ), NULL );
   if( t->hWnd == NULL )
   {
      s_nToast--;
      DeleteObject( t->hFont );
      DeleteObject( t->hBold );
      hb_xfree( t->pText );
      hb_xfree( t->pTitle );
      hb_xfree( t );
      HMG_retnl( 0 );
      return;
   }
   SetWindowLongPtr( t->hWnd, GWLP_USERDATA, ( LONG_PTR ) t );
   {
      /* Windows 11: rounded corners (ignored elsewhere) */
      typedef HRESULT ( WINAPI * PFN )( HWND, DWORD, LPCVOID, DWORD );
      HMODULE hDwm = GetModuleHandle( TEXT( "dwmapi.dll" ) );
      PFN     pfn;
      if( hDwm == NULL )
         hDwm = LoadLibrary( TEXT( "dwmapi.dll" ) );
      pfn = hDwm ? ( PFN ) ( void * ) GetProcAddress( hDwm, "DwmSetWindowAttribute" ) : NULL;
      if( pfn )
      {
         DWORD v = 2;   /* DWMWA_WINDOW_CORNER_PREFERENCE = 33, DWMWCP_ROUND */
         pfn( t->hWnd, 33, &v, sizeof( v ) );
      }
   }
   SetLayeredWindowAttributes( t->hWnd, 0, 0, LWA_ALPHA );
   ShowWindow( t->hWnd, SW_SHOWNOACTIVATE );
   SetTimer( t->hWnd, TST_ANIM, 15, NULL );
   if( t->nSeconds > 0 )
      SetTimer( t->hWnd, TST_LIFE, ( UINT ) t->nSeconds * 1000, NULL );
   {
      int i;   /* the older ones move up */
      for( i = 0; i < s_nToast - 1; i++ )
         SetTimer( s_pToast[ i ]->hWnd, TST_ANIM, 15, NULL );
   }
   HMG_retnl( ( LONG_PTR ) t->hWnd );
}

HB_FUNC( HMG_TOASTCOUNT )
{
   hb_retni( s_nToast );
}

HB_FUNC( HMG_TOASTCLOSEALL )
{
   BOOL bNow = hb_parl( 1 );
   while( bNow && s_nToast > 0 )
      DestroyWindow( s_pToast[ s_nToast - 1 ]->hWnd );
   if( ! bNow )
   {
      int i;
      for( i = 0; i < s_nToast; i++ )
         tst_close( s_pToast[ i ] );
   }
}
