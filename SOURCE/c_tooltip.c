/*
 * c_tooltip.c - tooltip custom draw and modern tooltip look (HMG5)
 *
 * TOOLTIP_CUSTOMDRAW and TOOLTIP_SETTITLE moved here from c_controlmisc.c (Dr. Claudio
 * Soto, 2014-2016). The owner-drawn look (gradient, rounded border, margins, theme off)
 * and the title cache are from HMG 3.7 (2026). HMG5 changes:
 *  - all of it runs only with SET TOOLTIPCUSTOMDRAW ON (HMG5 keeps 3.6's default OFF),
 *    so programs that never turn custom draw on keep the system tooltips;
 *  - the title cache is a hash in one window property, not two GlobalAlloc'd strings
 *    that were never freed, and the icon name is not copied into a 64-char buffer
 *    (3.7 overflowed it with a long file name).
 *
 * Released under the HMG licence, as the rest of HMG.
 */

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <commctrl.h>
#include <tchar.h>
#include "hbapi.h"
#include "hbthread.h"
extern HB_CRITICAL_T _HMG_Mutex;   // defined in c_Thread.c (used by HMG_DEFINE_DLL_FUNC)

/*  MinGW's TOOLINFO has no cchTextMax/iIcon. With the V3 cbSize, TTM_GETTOOLINFO copies the
    text and honours cchTextMax, which sits where MinGW has lpReserved (found by HMG 3.7). */
typedef struct {
   UINT      cbSize;
   DWORD     uFlags;
   HWND      hwnd;
   UINT_PTR  uId;
   RECT      rect;
   HINSTANCE hinst;
   LPTSTR    lpszText;
   LPARAM    lParam;
   int       cchTextMax;
   int       iIcon;
} HMG_TOOLINFO;

#ifdef UNICODE
   #define HMG_TOOLINFO_SIZE  ( ( UINT ) TTTOOLINFOW_V3_SIZE )
#else
   #define HMG_TOOLINFO_SIZE  ( ( UINT ) TTTOOLINFOA_V3_SIZE )
#endif

#define HMG_TT_TITLE_PROP  _TEXT( "HMG5ToolTipTitle" )

static void ToolTip_PaintOwnerDraw( LPNMTTCUSTOMDRAW lpNM, COLORREF BackColor, COLORREF TextColor,
                                    COLORREF BorderColor, int nRadius, HWND hWndTool, HFONT hFont,
                                    HWND hWndToolParent, UINT_PTR nToolId )
{
   HDC          hdc  = lpNM->nmcd.hdc;
   HWND         hTip = lpNM->nmcd.hdr.hwndFrom;
   RECT         rc   = lpNM->nmcd.rc, rcWin, rcText;
   int          nW, nH, y, nStep, t;
   int          nTopR, nTopG, nTopB, nBotR, nBotG, nBotB;
   HMG_TOOLINFO ti;
   TCHAR        szText[ 1024 ];

   GetClientRect( hTip, &rcWin );
   if( rc.right <= rc.left || rc.bottom <= rc.top )
      rc = rcWin;

   /* comctl32's text rect is one pixel tight: DrawText would wrap early; use the margin */
   rcText = rc;
   if( rcText.right < rcWin.right - 1 )   rcText.right  = rcWin.right - 1;
   if( rcText.bottom < rcWin.bottom - 1 ) rcText.bottom = rcWin.bottom - 1;

   nW = rcWin.right; nH = rcWin.bottom;
   if( nW <= 0 || nH <= 0 )
      return;

   /* vertical gradient: 25% lighter at the top, 8% darker at the bottom */
   nTopR = GetRValue( BackColor ) + ( 255 - GetRValue( BackColor ) ) / 4;
   nTopG = GetGValue( BackColor ) + ( 255 - GetGValue( BackColor ) ) / 4;
   nTopB = GetBValue( BackColor ) + ( 255 - GetBValue( BackColor ) ) / 4;
   nBotR = GetRValue( BackColor ) * 92 / 100;
   nBotG = GetGValue( BackColor ) * 92 / 100;
   nBotB = GetBValue( BackColor ) * 92 / 100;
   nStep = ( nH / 16 > 1 ) ? nH / 16 : 1;
   for( y = 0; y < nH; y += nStep )
   {
      RECT   band;
      HBRUSH hbr;

      SetRect( &band, 0, y, nW, ( y + nStep < nH ) ? y + nStep : nH );
      t   = ( nH > 1 ) ? y * 100 / ( nH - 1 ) : 0;
      hbr = CreateSolidBrush( RGB( nTopR + ( nBotR - nTopR ) * t / 100,
                                   nTopG + ( nBotG - nTopG ) * t / 100,
                                   nTopB + ( nBotB - nTopB ) * t / 100 ) );
      FillRect( hdc, &band, hbr );
      DeleteObject( hbr );
   }

   if( BorderColor != ( COLORREF ) -1 )
   {
      HPEN    hPen = CreatePen( PS_SOLID, 1, BorderColor );
      HGDIOBJ hOldPen = SelectObject( hdc, hPen );
      HGDIOBJ hOldBr  = SelectObject( hdc, GetStockObject( NULL_BRUSH ) );
      if( nRadius < 1 )
         nRadius = 1;
      RoundRect( hdc, 0, 0, nW, nH, nRadius * 2, nRadius * 2 );
      SelectObject( hdc, hOldBr );
      SelectObject( hdc, hOldPen );
      DeleteObject( hPen );
   }

   /* the text: a menu tooltip is registered as (form, MenuItemID); a control one as
      (parent, control) or (control, control) */
   memset( &ti, 0, sizeof( ti ) );
   ti.cbSize = HMG_TOOLINFO_SIZE;
   if( nToolId != 0 && hWndToolParent != NULL )
   {
      ti.uId  = nToolId;
      ti.hwnd = hWndToolParent;
   }
   else
   {
      ti.uId  = ( hWndTool != NULL ) ? ( UINT_PTR ) hWndTool : lpNM->nmcd.dwItemSpec;
      ti.hwnd = GetParent( ( HWND ) ti.uId );
   }
   ti.lpszText   = szText;
   ti.cchTextMax = ( int ) ( sizeof( szText ) / sizeof( TCHAR ) ) - 1;
   szText[ 0 ]   = 0;
   if( ! SendMessage( hTip, TTM_GETTOOLINFO, 0, ( LPARAM ) &ti ) )
   {
      ti.hwnd = ( HWND ) ti.uId;
      if( ! SendMessage( hTip, TTM_GETTOOLINFO, 0, ( LPARAM ) &ti ) )
         szText[ 0 ] = 0;
   }
   szText[ sizeof( szText ) / sizeof( TCHAR ) - 1 ] = 0;

   if( szText[ 0 ] != 0 )
   {
      HFONT   hF = hFont ? hFont : ( HFONT ) SendMessage( hTip, WM_GETFONT, 0, 0 );
      HGDIOBJ hOldFont = hF ? SelectObject( hdc, hF ) : NULL;

      SetBkMode( hdc, TRANSPARENT );
      if( TextColor != ( COLORREF ) -1 )
         SetTextColor( hdc, TextColor );
      DrawText( hdc, szText, -1, &rcText, DT_EDITCONTROL | DT_WORDBREAK | DT_EXPANDTABS | DT_LEFT );
      if( hOldFont != NULL )
         SelectObject( hdc, hOldFont );
   }
}

//        ToolTip_CustomDraw ( lParam, BackColor, TextColor, [ BorderColor ], [ nRadius ], [ nMode ],
//                             [ hWndTool ], [ hFont ], [ hWndToolParent ], [ nToolId ] )
//        nMode 0 = colours only, the control paints (classic HMG); 1 = owner drawn (3.7 look)
HB_FUNC ( TOOLTIP_CUSTOMDRAW )
{
   LPNMTTCUSTOMDRAW lpNM = ( LPNMTTCUSTOMDRAW ) HMG_parnl( 1 );
   COLORREF BackColor   = ( COLORREF ) hb_parni( 2 );
   COLORREF TextColor   = ( COLORREF ) hb_parni( 3 );
   COLORREF BorderColor = HB_ISNUM( 4 ) ? ( COLORREF ) hb_parni( 4 ) : ( COLORREF ) -1;
   int      nRadius     = HB_ISNUM( 5 ) ? hb_parni( 5 ) : 0;
   int      nMode       = HB_ISNUM( 6 ) ? hb_parni( 6 ) : 0;
   HWND     hWndTool    = HB_ISNUM( 7 ) ? ( HWND ) HMG_parnl( 7 ) : NULL;
   HFONT    hFont       = HB_ISNUM( 8 ) ? ( HFONT ) HMG_parnl( 8 ) : NULL;
   HWND     hWndParent  = HB_ISNUM( 9 ) ? ( HWND ) HMG_parnl( 9 ) : NULL;
   UINT_PTR nToolId     = HB_ISNUM( 10 ) ? ( UINT_PTR ) HMG_parnl( 10 ) : 0;
   DWORD    dwStage;

   if( lpNM == NULL )
   {
      hb_retni( CDRF_DODEFAULT );
      return;
   }
   dwStage = lpNM->nmcd.dwDrawStage;

   /* a tooltip may never send a plain item stage, so the owner-drawn look is painted in
      PREPAINT as well as in ITEMPREPAINT (| SUBITEM) */
   if( nMode == 1 && BackColor != ( COLORREF ) -1 &&
       ( dwStage == CDDS_PREPAINT || dwStage == CDDS_ITEMPREPAINT || dwStage == ( CDDS_ITEMPREPAINT | CDDS_SUBITEM ) ) )
   {
      ToolTip_PaintOwnerDraw( lpNM, BackColor, TextColor, BorderColor, nRadius, hWndTool, hFont, hWndParent, nToolId );
      hb_retni( CDRF_SKIPDEFAULT );
      return;
   }

   if( dwStage == CDDS_PREPAINT )
   {
      if( BackColor != ( COLORREF ) -1 )
         SetBkColor( lpNM->nmcd.hdc, BackColor );
      if( TextColor != ( COLORREF ) -1 )
         SetTextColor( lpNM->nmcd.hdc, TextColor );
      lpNM->uDrawFlags = DT_CALCRECT | DT_EDITCONTROL | DT_WORDBREAK;
   }
   hb_retni( CDRF_DODEFAULT );
}

/* FNV-1a over the title and the icon key, never 0 (0 = "no title applied") */
static ULONG_PTR ToolTip_TitleHash( LPCTSTR cTitle, LPCTSTR cIcon, INT nIcon )
{
   ULONG_PTR h = ( ULONG_PTR ) 2166136261u;
   LPCTSTR   p;

   for( p = cTitle ? cTitle : _TEXT( "" ); *p; p++ )
      h = ( h ^ ( ULONG_PTR ) *p ) * 16777619u;
   h = ( h ^ 0x1F ) * 16777619u;
   for( p = cIcon ? cIcon : _TEXT( "" ); *p; p++ )
      h = ( h ^ ( ULONG_PTR ) *p ) * 16777619u;
   h = ( h ^ ( ULONG_PTR ) ( unsigned ) nIcon ) * 16777619u;
   return h ? h : 1;
}

//        ToolTip_SetTitle ( hwndToolTip, [ cTitle ] , [ cIconName | nIconName ] )
//        Called on every custom-draw notification: TTM_SETTITLE forces a relayout, so it is
//        sent only when title or icon changed (cache idea from HMG 3.7).
HB_FUNC ( TOOLTIP_SETTITLE )
{
   HWND      hwndToolTip = ( HWND ) HMG_parnl( 1 );
   LPCTSTR   cTitle      = HMG_parc( 2 );
   LPCTSTR   cIconName   = HB_ISNUM( 3 ) ? NULL : HMG_parc( 3 );
   INT       nIconName   = HB_ISNUM( 3 ) ? hb_parni( 3 ) : 0;
   ULONG_PTR hWant, hHave;
   HICON     hIcon = NULL;
   WPARAM    wIcon = ( WPARAM ) nIconName;

   if( hwndToolTip == NULL )
      return;
   if( cTitle != NULL && *cTitle == 0 )
      cTitle = NULL;                      /* only NULL clears a title; "" still counts as one */
   if( cIconName != NULL && *cIconName == 0 )
      cIconName = NULL;

   hWant = ( cTitle == NULL && cIconName == NULL && nIconName == 0 ) ? 0 : ToolTip_TitleHash( cTitle, cIconName, nIconName );
   hHave = ( ULONG_PTR ) GetProp( hwndToolTip, HMG_TT_TITLE_PROP );
   if( hWant == hHave )
      return;

   if( cIconName != NULL )
   {
      hIcon = ( HICON ) LoadImage( GetModuleHandle( NULL ), cIconName, IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | LR_LOADTRANSPARENT );
      if( hIcon == NULL )
         hIcon = ( HICON ) LoadImage( NULL, cIconName, IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | LR_LOADFROMFILE | LR_LOADTRANSPARENT );
      wIcon = ( WPARAM ) hIcon;
   }
   SendMessage( hwndToolTip, TTM_SETTITLE, wIcon, ( LPARAM ) cTitle );
   if( hIcon != NULL )
      DestroyIcon( hIcon );               /* TTM_SETTITLE keeps its own copy */

   if( hWant == 0 )
      RemoveProp( hwndToolTip, HMG_TT_TITLE_PROP );
   else
      SetProp( hwndToolTip, HMG_TT_TITLE_PROP, ( HANDLE ) hWant );
}

//        ToolTip_ApplyStyle ( hWndToolTip, nRadius )  rounded window region; <= 1 = rectangle.
//        Balloons keep comctl32's own region (it holds the stem).
HB_FUNC ( TOOLTIP_APPLYSTYLE )
{
   HWND hTip    = ( HWND ) HMG_parnl( 1 );
   int  nRadius = hb_parni( 2 );

   if( hTip == NULL || ( GetWindowLong( hTip, GWL_STYLE ) & TTS_BALLOON ) != 0 )
      return;
   if( nRadius > 1 )
   {
      RECT rc;
      GetWindowRect( hTip, &rc );
      SetWindowRgn( hTip, CreateRoundRectRgn( 0, 0, rc.right - rc.left + 1, rc.bottom - rc.top + 1, nRadius * 2, nRadius * 2 ), TRUE );
   }
   else
      SetWindowRgn( hTip, NULL, TRUE );     /* the system owns and frees the region */
}

//        ToolTip_SetMargin ( hWndToolTip, nMarginX, nMarginY )
//        TTM_SETMARGIN reads right/bottom of the RECT as the margins.
HB_FUNC ( TOOLTIP_SETMARGIN )
{
   HWND hTip = ( HWND ) HMG_parnl( 1 );
   RECT rc;

   if( hTip == NULL )
      return;
   SetRect( &rc, 0, 0, hb_parni( 2 ), hb_parni( 3 ) );
   SendMessage( hTip, TTM_SETMARGIN, 0, ( LPARAM ) &rc );
}

HMG_DEFINE_DLL_FUNC ( win_ToolTipSetWindowTheme,
                      "uxtheme.dll",
                      HRESULT,
                      WINAPI,
                      "SetWindowTheme",
                      ( HWND hWnd, LPCWSTR SubAppName, LPCWSTR SubIdList ),
                      ( hWnd, SubAppName, SubIdList ),
                      -1
                    )

//        ToolTip_SetUiTheme ( hWndToolTip, lOff )
//        A themed tooltip ignores TTM_SETMARGIN; .T. switches the theme off so HMG's margins
//        apply, .F. gives the native theme back.
HB_FUNC ( TOOLTIP_SETUITHEME )
{
   HWND hTip = ( HWND ) HMG_parnl( 1 );

   if( hTip == NULL )
      return;
   if( hb_parl( 2 ) )
      win_ToolTipSetWindowTheme( hTip, L"", L"" );
   else
      win_ToolTipSetWindowTheme( hTip, NULL, NULL );
}
