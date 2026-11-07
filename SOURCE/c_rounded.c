/*
 * c_rounded.c - ROUNDED <n> clause for FRAME, TEXTBOX, EDITBOX and RICHEDITBOX (HMG5)
 *
 * Feature and drawing method from HMG 3.7 (Daniel Maximiliano / Dr. Claudio Soto, 2026):
 * the native borders are square, and a GDI region is a 1-bit mask (stair-stepped arcs),
 * so the ring is drawn by hand from the signed distance to a rounded rectangle, with
 * per-pixel coverage blending (anti-aliasing).
 *
 * HMG5 changes against the 3.7 code:
 *  - Opt-in everywhere. 3.7 subclasses every FRAME at creation and draws it rounded and
 *    black; HMG5 leaves FRAME native unless ROUNDED is given, and ROUNDED 0 restores the
 *    native control exactly (subclass removed).
 *  - Faster paint. Straight edges are one FillRect each; only the four (r+2)-pixel corner
 *    squares are blended per pixel. 3.7 visited every pixel of the control (w*h loop) and,
 *    for FRAME, read each band pixel back with GetPixel. Here the background colour comes
 *    from the brush, so the paint never reads the screen.
 *  - SetWindowSubclass with a per-window data block (freed on WM_NCDESTROY) instead of
 *    SetWindowLongPtr plus five window properties.
 *  - One copy of the geometry (3.7 had it twice, in c_frame.c and c_textbox.c).
 *
 * Released under the HMG licence, as the rest of HMG.
 */

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <commctrl.h>
#include <tchar.h>
#include <math.h>
#include "hbapi.h"

#define HMG_ROUND_MAX       20
#define HMG_ROUND_TEXTPEN   RGB( 100, 100, 100 )   /* native edit border grey, measured by 3.7 */
#define HMG_ROUND_FRAMEPEN  RGB( 0, 0, 0 )
#define HMG_ID_TEXTRING     0x484D5201u
#define HMG_ID_FRAMERING    0x484D5202u
#define HMG_EM_GETBKCOLOR   ( WM_USER + 84 )       /* not in MinGW's richedit.h */

typedef struct
{
   int  nRadius;        /* requested radius 0..20 */
   BOOL lHadEdge;       /* control was created with WS_EX_CLIENTEDGE */
   int  nMarginOrig;    /* left margin before we touched it */
   int  nMarginSet;     /* left margin we set (-1 = untouched) */
} HMG_RINGDATA;

/* ------------------------------------------------------------------ geometry ---- */

/* signed distance from (px,py) to the outer edge of the rounded rect (0,0)-(w,h), < 0 inside */
static double RingSdf( double px, double py, double w, double h, double r )
{
   double hx = w * 0.5, hy = h * 0.5;
   double dx = fabs( px - hx ) - ( hx - r );
   double dy = fabs( py - hy ) - ( hy - r );
   double ax = dx > 0.0 ? dx : 0.0;
   double ay = dy > 0.0 ? dy : 0.0;
   double m  = dx > dy ? dx : dy;

   return sqrt( ax * ax + ay * ay ) + ( m < 0.0 ? m : 0.0 ) - r;
}

/* length of [d-0.5, d+0.5] inside [lo, hi] */
static double RingOverlap( double d, double lo, double hi )
{
   double a = d - 0.5, b = d + 0.5;

   if( a < lo ) a = lo;
   if( b > hi ) b = hi;
   return b > a ? b - a : 0.0;
}

static int RingClamp( int nRadius, int w, int h )
{
   int nMax = ( ( w < h ? w : h ) - 2 ) / 2;   /* r >= half the short side leaves gaps */

   if( nRadius > HMG_ROUND_MAX ) nRadius = HMG_ROUND_MAX;
   if( nRadius > nMax )          nRadius = nMax;
   return nRadius < 1 ? 0 : nRadius;
}

static COLORREF RingMix( COLORREF a, double fa, COLORREF b, double fb, COLORREF c, double fc )
{
   return RGB( ( int ) ( GetRValue( a ) * fa + GetRValue( b ) * fb + GetRValue( c ) * fc + 0.5 ),
               ( int ) ( GetGValue( a ) * fa + GetGValue( b ) * fb + GetGValue( c ) * fc + 0.5 ),
               ( int ) ( GetBValue( a ) * fa + GetBValue( b ) * fb + GetBValue( c ) * fc + 0.5 ) );
}

static void RingFill( HDC hdc, int x0, int y0, int x1, int y1, COLORREF c )
{
   RECT   rc;
   HBRUSH hbr;

   if( x1 <= x0 || y1 <= y0 )
      return;
   SetRect( &rc, x0, y0, x1, y1 );
   hbr = CreateSolidBrush( c );
   FillRect( hdc, &rc, hbr );
   DeleteObject( hbr );
}

/*
 * Draws a 1-px ring for the box (0,0)-(w,h) in "box coordinates". The DC shows the box
 * shifted: DC pixel (x,y) is box pixel (x+offX, y+offY), and only DC pixels inside
 * (0,0)-(dcW,dcH) are touched. cIn is the colour inside the ring, cOut outside it.
 * A straight edge is exactly one pen pixel wide (coverage 1 on the edge row, 0 next to it),
 * so it is filled; only the corner squares need blending.
 */
static void RingPaint( HDC hdc, int offX, int offY, int dcW, int dcH, int w, int h, int r,
                       COLORREF pen, COLORREF cIn, COLORREF cOut )
{
   int    nSq = r + 2, cx, cy, x, y;
   int    aX[ 2 ], aY[ 2 ];
   double dr = ( double ) r;

   if( r < 1 || w < 2 * nSq || h < 2 * nSq )
      return;

   /* straight edges, between the corner squares */
   RingFill( hdc, nSq - offX, 0 - offY,     w - nSq - offX, 1 - offY,     pen );   /* top    */
   RingFill( hdc, nSq - offX, h - 1 - offY, w - nSq - offX, h - offY,     pen );   /* bottom */
   RingFill( hdc, 0 - offX,     nSq - offY, 1 - offX,     h - nSq - offY, pen );   /* left   */
   RingFill( hdc, w - 1 - offX, nSq - offY, w - offX,     h - nSq - offY, pen );   /* right  */

   /* corners */
   aX[ 0 ] = 0; aX[ 1 ] = w - nSq;
   aY[ 0 ] = 0; aY[ 1 ] = h - nSq;
   for( cy = 0; cy < 2; cy++ )
      for( cx = 0; cx < 2; cx++ )
         for( y = aY[ cy ]; y < aY[ cy ] + nSq; y++ )
            for( x = aX[ cx ]; x < aX[ cx ] + nSq; x++ )
            {
               int    px = x - offX, py = y - offY;
               double d, t, o, i;

               if( px < 0 || py < 0 || px >= dcW || py >= dcH )
                  continue;
               d = RingSdf( x + 0.5, y + 0.5, ( double ) w, ( double ) h, dr );
               t = RingOverlap( d, -1.0, 0.0 );       /* the pen band     */
               o = RingOverlap( d, 0.0, 1.0e6 );      /* outside the box  */
               i = 1.0 - t - o;                       /* inside the box   */
               if( i >= 1.0 )
                  continue;                           /* leave the control's own pixels */
               SetPixelV( hdc, px, py, RingMix( pen, t, cIn, i, cOut, o ) );
            }
}

/* colour of a background brush: real solid brush, or the COLOR_xxx + 1 pseudo-brush */
static COLORREF RingBrushColor( HBRUSH hbr, COLORREF cDefault )
{
   LOGBRUSH lb;

   if( hbr == NULL || hbr == ( HBRUSH ) GetStockObject( NULL_BRUSH ) )
      return cDefault;
   if( ( ULONG_PTR ) hbr <= ( ULONG_PTR ) ( COLOR_MENUBAR + 1 ) )
      return GetSysColor( ( int ) ( ( ULONG_PTR ) hbr - 1 ) );
   if( GetObject( hbr, sizeof( lb ), &lb ) == 0 || lb.lbStyle != BS_SOLID )
      return cDefault;
   return lb.lbColor;
}

static HBRUSH RingParentBrush( HWND hWnd )
{
   HWND hParent = GetParent( hWnd );
   HBRUSH hbr = hParent ? ( HBRUSH ) GetClassLongPtr( hParent, GCLP_HBRBACKGROUND ) : NULL;

   return hbr ? hbr : ( HBRUSH ) ( LONG_PTR ) ( COLOR_BTNFACE + 1 );
}

static BOOL RingClassIs( HWND hWnd, LPCTSTR cPrefix, BOOL lExact )
{
   TCHAR  cClass[ 32 ];
   size_t n = _tcslen( cPrefix );

   if( GetClassName( hWnd, cClass, 32 ) <= 0 )
      return FALSE;
   if( lExact )
      return _tcsicmp( cClass, cPrefix ) == 0;
   return _tcsnicmp( cClass, cPrefix, n ) == 0;
}

/* ----------------------------------------------------- TEXTBOX / EDITBOX / RICHEDIT ---- */

static BOOL TextIsRich( HWND hWnd ) { return RingClassIs( hWnd, _TEXT( "RichEdit" ), FALSE ); }

static void TextWinSize( HWND hWnd, int * w, int * h, int * insX, int * insY )
{
   RECT  wr;
   POINT pt = { 0, 0 };

   GetWindowRect( hWnd, &wr );
   ClientToScreen( hWnd, &pt );
   *w = wr.right - wr.left;  *h = wr.bottom - wr.top;
   *insX = pt.x - wr.left;   *insY = pt.y - wr.top;
}

/* background of the edit itself: asked from the parent the way Windows does
   (read-only and disabled edits use WM_CTLCOLORSTATIC); RichEdit keeps its own */
static COLORREF TextBack( HWND hWnd )
{
   HWND   hParent = GetParent( hWnd );
   HBRUSH hbr = NULL;
   HDC    hdc;

   if( TextIsRich( hWnd ) )
   {
      COLORREF c = ( COLORREF ) SendMessage( hWnd, HMG_EM_GETBKCOLOR, 0, 0 );
      return ( c != 0 && c != CLR_DEFAULT ) ? c : GetSysColor( COLOR_WINDOW );
   }
   if( hParent != NULL && ( hdc = GetDC( hWnd ) ) != NULL )
   {
      BOOL lStatic = ( GetWindowLong( hWnd, GWL_STYLE ) & ES_READONLY ) || ! IsWindowEnabled( hWnd );
      hbr = ( HBRUSH ) SendMessage( hParent, lStatic ? WM_CTLCOLORSTATIC : WM_CTLCOLOREDIT, ( WPARAM ) hdc, ( LPARAM ) hWnd );
      ReleaseDC( hWnd, hdc );
   }
   return RingBrushColor( hbr, GetSysColor( COLOR_WINDOW ) );
}

static int TextRadius( HWND hWnd, HMG_RINGDATA * p )
{
   int w, h, ix, iy;

   TextWinSize( hWnd, &w, &h, &ix, &iy );
   return RingClamp( p->nRadius, w, h );
}

/* the ring and WS_EX_CLIENTEDGE exclude each other; a box too small for the ring keeps
   its native edge, so it is never left without a border */
static void TextApplyEdge( HWND hWnd, HMG_RINGDATA * p )
{
   LONG lEx  = GetWindowLong( hWnd, GWL_EXSTYLE );
   BOOL lHas = ( lEx & WS_EX_CLIENTEDGE ) != 0;
   BOOL lWant = TextRadius( hWnd, p ) < 1 && p->lHadEdge;

   if( lWant == lHas )
      return;
   SetWindowLong( hWnd, GWL_EXSTYLE, lWant ? ( lEx | WS_EX_CLIENTEDGE ) : ( lEx & ~WS_EX_CLIENTEDGE ) );
   SetWindowPos( hWnd, NULL, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED );
}

/* left margin that keeps the first text line clear of the top-left arc (3.7: r - sqrt(4r-4)) */
static void TextApplyMargin( HWND hWnd, HMG_RINGDATA * p )
{
   int r = TextRadius( hWnd, p );
   int nWant;

   if( r < 1 )
   {
      if( p->nMarginSet < 0 )
         return;                                /* never touched: leave it alone */
      nWant = p->nMarginOrig;
   }
   else
   {
      double d = ( double ) r - sqrt( 4.0 * r - 4.0 );
      nWant = d > 0.0 ? ( int ) ceil( d ) : 0;
      if( nWant < p->nMarginOrig )
         nWant = p->nMarginOrig;
   }
   if( nWant == p->nMarginSet )
      return;
   SendMessage( hWnd, EM_SETMARGINS, EC_LEFTMARGIN, MAKELPARAM( nWant, 0 ) );
   p->nMarginSet = nWant;
}

static void TextPaintRing( HWND hWnd, HMG_RINGDATA * p, BOOL lNonClient )
{
   int w, h, ix, iy, r = 0;
   HDC hdc;

   TextWinSize( hWnd, &w, &h, &ix, &iy );
   if( ( r = RingClamp( p->nRadius, w, h ) ) < 1 )
      return;
   if( ( hdc = lNonClient ? GetWindowDC( hWnd ) : GetDC( hWnd ) ) == NULL )
      return;
   if( lNonClient )
      RingPaint( hdc, 0, 0, w, h, w, h, r, HMG_ROUND_TEXTPEN, TextBack( hWnd ),
                 RingBrushColor( RingParentBrush( hWnd ), GetSysColor( COLOR_3DFACE ) ) );
   else
   {
      RECT cr;
      GetClientRect( hWnd, &cr );
      RingPaint( hdc, ix, iy, cr.right, cr.bottom, w, h, r, HMG_ROUND_TEXTPEN, TextBack( hWnd ),
                 RingBrushColor( RingParentBrush( hWnd ), GetSysColor( COLOR_3DFACE ) ) );
   }
   ReleaseDC( hWnd, hdc );
}

static LRESULT CALLBACK TextRingProc( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam,
                                      UINT_PTR uId, DWORD_PTR dwRef )
{
   HMG_RINGDATA * p = ( HMG_RINGDATA * ) dwRef;
   LRESULT lRet;

   switch( uMsg )
   {
      case WM_PAINT:      /* let the control paint first (BeginPaint validates), then the ring */
         lRet = DefSubclassProc( hWnd, uMsg, wParam, lParam );
         TextPaintRing( hWnd, p, FALSE );
         return lRet;

      case WM_NCPAINT:    /* the ring part outside the client: scroll bars of an EDITBOX */
         lRet = DefSubclassProc( hWnd, uMsg, wParam, lParam );
         TextPaintRing( hWnd, p, TRUE );
         return lRet;

      case WM_SIZE:
         lRet = DefSubclassProc( hWnd, uMsg, wParam, lParam );
         TextApplyEdge( hWnd, p );
         TextApplyMargin( hWnd, p );
         RedrawWindow( hWnd, NULL, NULL, RDW_INVALIDATE | RDW_FRAME | RDW_ERASE );
         return lRet;

      case WM_SETFONT:
      case WM_ENABLE:
         lRet = DefSubclassProc( hWnd, uMsg, wParam, lParam );
         RedrawWindow( hWnd, NULL, NULL, RDW_INVALIDATE | RDW_FRAME | RDW_ERASE );
         return lRet;

      case WM_NCDESTROY:
         RemoveWindowSubclass( hWnd, TextRingProc, uId );
         LocalFree( p );
         break;
   }
   return DefSubclassProc( hWnd, uMsg, wParam, lParam );
}

static HMG_RINGDATA * TextData( HWND hWnd )
{
   DWORD_PTR dwRef = 0;

   return GetWindowSubclass( hWnd, TextRingProc, HMG_ID_TEXTRING, &dwRef ) ? ( HMG_RINGDATA * ) dwRef : NULL;
}

//        _SetTextBoxRounded( hWnd, nRadius ) --> nRadius stored (0..20; 0 when hWnd is not an edit box)
HB_FUNC( _SETTEXTBOXROUNDED )
{
   HWND hWnd = ( HWND ) HMG_parnl( 1 );
   int  nRadius = hb_parni( 2 );
   HMG_RINGDATA * p;

   if( hWnd == NULL || ! IsWindow( hWnd ) ||
       ! ( RingClassIs( hWnd, _TEXT( "Edit" ), TRUE ) || TextIsRich( hWnd ) ) )
   {
      hb_retni( 0 );
      return;
   }
   if( nRadius < 0 )             nRadius = 0;
   if( nRadius > HMG_ROUND_MAX ) nRadius = HMG_ROUND_MAX;

   p = TextData( hWnd );
   if( p == NULL )
   {
      if( nRadius == 0 )
      {
         hb_retni( 0 );           /* native already */
         return;
      }
      p = ( HMG_RINGDATA * ) LocalAlloc( LPTR, sizeof( HMG_RINGDATA ) );
      if( p == NULL )
      {
         hb_retni( 0 );
         return;
      }
      p->lHadEdge    = ( GetWindowLong( hWnd, GWL_EXSTYLE ) & WS_EX_CLIENTEDGE ) != 0;
      p->nMarginOrig = LOWORD( SendMessage( hWnd, EM_GETMARGINS, 0, 0 ) );
      p->nMarginSet  = -1;
      if( ! SetWindowSubclass( hWnd, TextRingProc, HMG_ID_TEXTRING, ( DWORD_PTR ) p ) )
      {
         LocalFree( p );
         hb_retni( 0 );
         return;
      }
   }

   p->nRadius = nRadius;
   TextApplyEdge( hWnd, p );
   TextApplyMargin( hWnd, p );

   if( nRadius == 0 )            /* back to the native control: drop the subclass */
   {
      RemoveWindowSubclass( hWnd, TextRingProc, HMG_ID_TEXTRING );
      LocalFree( p );
   }
   RedrawWindow( hWnd, NULL, NULL, RDW_INVALIDATE | RDW_FRAME | RDW_ERASE | RDW_UPDATENOW );
   hb_retni( nRadius );
}

//        _GetTextBoxRounded( hWnd ) --> nRadius (0 = native)
HB_FUNC( _GETTEXTBOXROUNDED )
{
   HMG_RINGDATA * p = TextData( ( HWND ) HMG_parnl( 1 ) );

   hb_retni( p ? p->nRadius : 0 );
}

/* ------------------------------------------------------------------------ FRAME ---- */

/*
 * FRAME is a BS_GROUPBOX drawn by the theme (square, light line, grey patch behind the
 * caption). With ROUNDED it is painted here: background band with the parent's class
 * brush, black 1-px rounded ring, caption in a gap of the top line. The interior is not
 * filled: the frame is WS_EX_TRANSPARENT and paints after its siblings, so filling it
 * would wipe the controls inside (found by 3.7).
 */

static void FramePaint( HWND hWnd, HMG_RINGDATA * p, HDC hdc )
{
   RECT       rc;
   TEXTMETRIC tm;
   HFONT      hFont = ( HFONT ) SendMessage( hWnd, WM_GETFONT, 0, 0 );
   HFONT      hOld  = hFont ? ( HFONT ) SelectObject( hdc, hFont ) : NULL;
   HBRUSH     hbrBack = RingParentBrush( hWnd );
   COLORREF   cBack = RingBrushColor( hbrBack, GetSysColor( COLOR_BTNFACE ) );
   int        w, h, nTop, nBoxH, r, nLen;

   GetClientRect( hWnd, &rc );
   w = rc.right; h = rc.bottom;
   if( ! GetTextMetrics( hdc, &tm ) )
      tm.tmHeight = 16;
   nTop = ( tm.tmHeight + 1 ) / 2;
   if( nTop > h - 3 ) nTop = h / 3;
   if( nTop < 1 )     nTop = 1;
   nBoxH = h - nTop;

   if( w >= 3 && nBoxH >= 2 )
   {
      r = RingClamp( p->nRadius, w, nBoxH );
      /* clear the 2-px band the ring and its blend touch (corner squares included) */
      {
         int  nSq = r + 2;
         HRGN hBand = CreateRectRgn( 0, nTop, w, h );
         HRGN hHole = CreateRectRgn( nSq, nTop + 2, w - nSq, h - 2 );
         HRGN hHole2 = CreateRectRgn( 2, nTop + nSq, w - 2, h - nSq );
         CombineRgn( hHole, hHole, hHole2, RGN_OR );
         CombineRgn( hBand, hBand, hHole, RGN_DIFF );
         FillRgn( hdc, hBand, hbrBack );
         DeleteObject( hBand ); DeleteObject( hHole ); DeleteObject( hHole2 );
      }
      if( r >= 1 )
         RingPaint( hdc, 0, -nTop, w, h, w, nBoxH, r, HMG_ROUND_FRAMEPEN, cBack, cBack );
   }

   /* caption, in a gap of the top line */
   nLen = GetWindowTextLength( hWnd );
   if( nLen > 0 )
   {
      LPTSTR pText = ( LPTSTR ) LocalAlloc( LPTR, ( nLen + 1 ) * sizeof( TCHAR ) );
      int    nX = p->nRadius > 6 ? p->nRadius + 2 : 8, nRight = w - 8;

      if( nX > w - 4 ) nX = 8;
      if( pText != NULL && nX < nRight - 8 )
      {
         HWND   hParent = GetParent( hWnd );
         HBRUSH hbrCap  = NULL;
         RECT   rcGap;
         LOGBRUSH lb;

         GetWindowText( hWnd, pText, nLen + 1 );
         SetRect( &rc, nX, 0, nRight, nTop + tm.tmHeight );
         DrawText( hdc, pText, nLen, &rc, DT_LEFT | DT_TOP | DT_SINGLELINE | DT_NOPREFIX | DT_CALCRECT | DT_END_ELLIPSIS );
         if( rc.right > nRight ) rc.right = nRight;
         rc.bottom = nTop + tm.tmHeight;

         /* WM_CTLCOLORSTATIC sets HMG's FONTCOLOR in the DC and returns the BACKCOLOR brush */
         if( hParent != NULL )
            hbrCap = ( HBRUSH ) SendMessage( hParent, WM_CTLCOLORSTATIC, ( WPARAM ) hdc, ( LPARAM ) hWnd );
         if( hbrCap == NULL || hbrCap == ( HBRUSH ) GetStockObject( NULL_BRUSH ) ||
             ( GetObject( hbrCap, sizeof( lb ), &lb ) != 0 && lb.lbStyle == BS_SOLID && lb.lbColor == GetSysColor( COLOR_3DFACE ) ) )
            hbrCap = hbrBack;

         SetRect( &rcGap, nX - 4, nTop, rc.right + 4, nTop + 1 );
         FillRect( hdc, &rcGap, hbrCap );
         SetBkMode( hdc, TRANSPARENT );
         DrawText( hdc, pText, nLen, &rc, DT_LEFT | DT_TOP | DT_SINGLELINE | DT_NOPREFIX | DT_END_ELLIPSIS );
      }
      if( pText != NULL )
         LocalFree( pText );
   }
   if( hOld != NULL )
      SelectObject( hdc, hOld );
}

static LRESULT CALLBACK FrameRingProc( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam,
                                       UINT_PTR uId, DWORD_PTR dwRef )
{
   HMG_RINGDATA * p = ( HMG_RINGDATA * ) dwRef;

   switch( uMsg )
   {
      case WM_PAINT:
      {
         PAINTSTRUCT ps;
         HDC hdc = BeginPaint( hWnd, &ps );
         FramePaint( hWnd, p, hdc );
         EndPaint( hWnd, &ps );
         return 0;
      }
      case WM_ERASEBKGND:
         return 1;

      case WM_SIZE:
      case WM_SETTEXT:
      case WM_SETFONT:
      {
         LRESULT lRet = DefSubclassProc( hWnd, uMsg, wParam, lParam );
         InvalidateRect( hWnd, NULL, FALSE );
         return lRet;
      }
      case WM_NCDESTROY:
         RemoveWindowSubclass( hWnd, FrameRingProc, uId );
         LocalFree( p );
         break;
   }
   return DefSubclassProc( hWnd, uMsg, wParam, lParam );
}

static HMG_RINGDATA * FrameData( HWND hWnd )
{
   DWORD_PTR dwRef = 0;

   return GetWindowSubclass( hWnd, FrameRingProc, HMG_ID_FRAMERING, &dwRef ) ? ( HMG_RINGDATA * ) dwRef : NULL;
}

//        _SetFrameRounded( hWnd, nRadius ) --> nRadius stored (0 = native group box)
HB_FUNC( _SETFRAMEROUNDED )
{
   HWND hWnd = ( HWND ) HMG_parnl( 1 );
   int  nRadius = hb_parni( 2 );
   HMG_RINGDATA * p;

   if( hWnd == NULL || ! IsWindow( hWnd ) || ! RingClassIs( hWnd, WC_BUTTON, TRUE ) )
   {
      hb_retni( 0 );
      return;
   }
   if( nRadius < 0 )             nRadius = 0;
   if( nRadius > HMG_ROUND_MAX ) nRadius = HMG_ROUND_MAX;

   p = FrameData( hWnd );
   if( nRadius == 0 )
   {
      if( p != NULL )
      {
         RemoveWindowSubclass( hWnd, FrameRingProc, HMG_ID_FRAMERING );
         LocalFree( p );
      }
   }
   else
   {
      if( p == NULL )
      {
         p = ( HMG_RINGDATA * ) LocalAlloc( LPTR, sizeof( HMG_RINGDATA ) );
         if( p == NULL || ! SetWindowSubclass( hWnd, FrameRingProc, HMG_ID_FRAMERING, ( DWORD_PTR ) p ) )
         {
            if( p != NULL )
               LocalFree( p );
            hb_retni( 0 );
            return;
         }
      }
      p->nRadius = nRadius;
   }
   InvalidateRect( hWnd, NULL, TRUE );
   hb_retni( nRadius );
}

//        _GetFrameRounded( hWnd ) --> nRadius (0 = native)
HB_FUNC( _GETFRAMEROUNDED )
{
   HMG_RINGDATA * p = FrameData( ( HWND ) HMG_parnl( 1 ) );

   hb_retni( p ? p->nRadius : 0 );
}
