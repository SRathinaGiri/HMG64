/*----------------------------------------------------------------------------
 HMG - Harbour Windows GUI library source code

 Copyright 2002-2017 Roberto Lopez <mail.box.hmg@gmail.com>
 http://sites.google.com/site/hmgweb/

 Head of HMG project:

      2002-2012 Roberto Lopez <mail.box.hmg@gmail.com>
      http://sites.google.com/site/hmgweb/

      2012-2017 Dr. Claudio Soto <srvet@adinet.com.uy>
      http://srvet.blogspot.com

 This program is free software; you can redistribute it and/or modify it under 
 the terms of the GNU General Public License as published by the Free Software 
 Foundation; either version 2 of the License, or (at your option) any later 
 version. 

 This program is distributed in the hope that it will be useful, but WITHOUT 
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with 
 this software; see the file COPYING. If not, write to the Free Software 
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA (or 
 visit the web site http://www.gnu.org/).

 As a special exception, you have permission for additional uses of the text 
 contained in this release of HMG.

 The exception is that, if you link the HMG library with other 
 files to produce an executable, this does not by itself cause the resulting 
 executable to be covered by the GNU General Public License.
 Your use of that executable is in no way restricted on account of linking the 
 HMG library code into it.

 Parts of this project are based upon:

	"Harbour GUI framework for Win32"
 	Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 	Copyright 2001 Antonio Linares <alinares@fivetech.com>
	www - http://www.harbour-project.org

	"Harbour Project"
	Copyright 1999-2008, http://www.harbour-project.org/

	"WHAT32"
	Copyright 2002 AJ Wos <andrwos@aust1.net> 

	"HWGUI"
  	Copyright 2001-2008 Alexander S.Kresin <alex@belacy.belgorod.su>

---------------------------------------------------------------------------*/



/* 
  The adaptation of the source code of this file to support UNICODE character set and WIN64 architecture was made 
  by Dr. Claudio Soto, November 2012 and June 2014 respectively. 
  mail: <srvet@adinet.com.uy>
  blog: http://srvet.blogspot.com
*/
#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"




//#define _WIN32_IE      0x0500
//#define HB_OS_WIN_32_USED
//#define _WIN32_WINNT   0x0400


#include <shlobj.h>
#include <windows.h>
#include <commctrl.h>
#include "hbapi.h"
#include "hmg_dpi.h"
//#include "hbvm.h"
//#include "hbstack.h"
//#include "hbapiitm.h"
//#include "winreg.h"
#include <tchar.h>


HIMAGELIST HMG_ImageListLoadFirst (TCHAR *FileName, int cGrow, int Transparent, int *nWidth, int *nHeight);
void HMG_ImageListAdd (HIMAGELIST hImageList, TCHAR *FileName, int Transparent);



HB_FUNC( INITTABCONTROL )
{

	HWND hwnd;
	HWND hbutton;
	TC_ITEM tie; 
	int l;
	int i;

	int Style = WS_CHILD | WS_VISIBLE ;

	if ( hb_parl (11) )
	{
		Style = Style | TCS_BUTTONS ;
	}

	if ( hb_parl (12) )
	{
		Style = Style | TCS_FLATBUTTONS ;
	}

	if ( hb_parl (13) )
	{
		Style = Style | TCS_HOTTRACK ;
	}

	if ( hb_parl (14) )
	{
		Style = Style | TCS_VERTICAL ;
	}

	if ( ! hb_parl (15) )
	{
		Style = Style | WS_TABSTOP ;
	}

	if ( hb_parl (16) )
	{
		Style = Style | TCS_MULTILINE ;
	}

	l = hb_parinfa( 7, 0 ) - 1 ;

	hwnd = (HWND) HMG_parnl (1);

	hbutton = CreateWindowEx( 0L , WC_TABCONTROL /*_TEXT("SysTabControl32")*/ , 
   TEXT("") , Style , 
	hb_parni(3), hb_parni(4) , hb_parni(5), hb_parni(6) ,
	hwnd,(HMENU) HMG_parnl (2), GetModuleHandle(NULL) , NULL ) ;

	tie.mask = TCIF_TEXT ; 
	tie.iImage = -1; 

	for (i = l ; i>=0 ; i=i-1 )
		{

		tie.pszText =  (LPTSTR) HMG_parvc ( 7 , i + 1 );

		TabCtrl_InsertItem(hbutton, 0, &tie); 
		}

	TabCtrl_SetCurSel( hbutton , hb_parni(8) - 1 );

	HMG_retnl ((LONG_PTR) hbutton);
}

HB_FUNC (TABCTRL_SETCURSEL)
{

	HWND hwnd;
	int s;

	hwnd = (HWND) HMG_parnl (1);

	s = hb_parni (2);

	TabCtrl_SetCurSel( hwnd , s-1 );

}

HB_FUNC (TABCTRL_GETCURSEL)
{
	HWND hwnd;
	hwnd = (HWND) HMG_parnl (1);
	hb_retni ( TabCtrl_GetCurSel( hwnd ) + 1 ) ;
}

HB_FUNC (TABCTRL_INSERTITEM)
{
	HWND hwnd ; 
	TC_ITEM tie ; 
	int i ;

	hwnd = (HWND) HMG_parnl (1);
	i = hb_parni (2) ;

	tie.mask = TCIF_TEXT ; 
	tie.iImage = -1 ; 
	tie.pszText = (LPTSTR) HMG_parc(3) ;

	TabCtrl_InsertItem(hwnd, i, &tie) ; 

}

HB_FUNC (TABCTRL_DELETEITEM)
{
	HWND hwnd ; 
	int i ;

	hwnd = (HWND) HMG_parnl (1);
	i = hb_parni (2) ;

	TabCtrl_DeleteItem(hwnd, i) ; 

}

HB_FUNC( SETTABCAPTION )
{

	TC_ITEM tie; 

	tie.mask = TCIF_TEXT ; 

	tie.pszText =  (LPTSTR) HMG_parc(3) ;

	TabCtrl_SetItem ( (HWND) HMG_parnl (1), hb_parni (2)-1 , &tie); 

}


HB_FUNC ( ADDTABBITMAP )
{
   HWND hTab = (HWND) HMG_parnl (1);
   TC_ITEM TCI; 
   HIMAGELIST hImageList = NULL;
   TCHAR *FileName;
   int nCount, i;

   nCount = hb_parinfa (2, 0);

   if ( nCount > 0 )
   {
      int Transparent = hb_parl(3) ? 0 : 1;

      for (i=1; i <= nCount; i++)
      {
         FileName = (TCHAR*) HMG_parvc (2, i);
         if ( hImageList == NULL )
            hImageList = HMG_ImageListLoadFirst (FileName, nCount, Transparent, NULL, NULL);
         else
            HMG_ImageListAdd (hImageList, FileName, Transparent);
      }

      if (hImageList != NULL)
         SendMessage (hTab, TCM_SETIMAGELIST, (WPARAM) 0, (LPARAM) hImageList);

      for ( i = 0 ; i < nCount ; i++ )
      {
         TCI.mask   = TCIF_IMAGE ; 
         TCI.iImage = i; 
         TabCtrl_SetItem (hTab, i, &TCI); 
      }
   }

   HMG_retnl ((LONG_PTR) hImageList );
}


HB_FUNC(IMAGELIST_DESTROY)
{
   hb_retl ((BOOL) ImageList_Destroy ( (HIMAGELIST) HMG_parnl (1) ) );
}


// by Dr. Claudio Soto, April 2015

HB_FUNC ( TABCTRL_ADJUSTRECT )
{
   HWND hWnd    = (HWND) HMG_parnl (1);
   BOOL fLarger = (BOOL) hb_parl   (2);
   RECT Rect = {0,0,0,0};
   TabCtrl_AdjustRect( hWnd, fLarger, &Rect );
   hb_reta (4);
   hb_storvnl (Rect.left,   -1, 1);
   hb_storvnl (Rect.top,    -1, 2);
   hb_storvnl (Rect.right,  -1, 3);
   hb_storvnl (Rect.bottom, -1, 4);
   
}


HB_FUNC ( TABCTRL_GETITEMRECT )
{
   HWND hWnd   = (HWND) HMG_parnl (1);
   INT  nItem  = (INT)  hb_parni  (2);
   RECT Rect = {0,0,0,0};
   TabCtrl_GetItemRect (hWnd, nItem, &Rect);
   hb_reta (4);
   hb_storvnl (Rect.left,   -1, 1);
   hb_storvnl (Rect.top,    -1, 2);
   hb_storvnl (Rect.right,  -1, 3);
   hb_storvnl (Rect.bottom, -1, 4);
}


/* ===========================================================================
   TAB with a "TabView" look (from HMG 3.7, Oct 2026): accent-coloured strip
   behind the tabs and the selected tab drawn as a rounded pill.

      TabSetModern ( hTab, [nR,nG,nB strip], [nR,nG,nB pill], [nR,nG,nB text],
                     [nR,nG,nB selected text], [nMinTabWidth] ) --> lOk
      TabClearModern ( hTab ) --> lOk          back to the native look
      IsTabModern ( hTab ) --> lModern
      TabDrawItem ( lParam ) --> lHandled      called from Events on WM_DRAWITEM

   What 3.7 measured on a themed tab (comctl32 6.10):
     - SysTabControl32 sends no NM_CUSTOMDRAW, but TCS_OWNERDRAWFIXED works and can
       be switched on at run time (SetWindowLongPtr + SWP_FRAMECHANGED): the parent
       then gets WM_DRAWITEM with CtlType ODT_TAB;
     - the strip behind the tabs is not an item, so it is painted from a subclass
       answering WM_ERASEBKGND;
     - TCM_SETMINTABWIDTH widens the tabs.
   Owner-drawn tabs show text only (no tab images).

   HMG5 changes against 3.7: the colours live in per-window data hung on the
   subclass (dwRefData) instead of a fixed 64-slot table, so there is no limit, no
   stale "already subclassed" flag when a slot is reused, and the data is freed on
   WM_NCDESTROY; brushes are created once per TabSetModern, not on every erase.
   ========================================================================= */

#define HMG_MODERNTAB_ID   0x484D5203

typedef struct {
	COLORREF  cStrip;
	COLORREF  cPill;
	COLORREF  cText;
	COLORREF  cTextSel;
	HBRUSH    hStrip;
	HBRUSH    hPill;
} HMG_MODERN_TAB;

static LRESULT CALLBACK HMG_ModernTabProc ( HWND, UINT, WPARAM, LPARAM, UINT_PTR, DWORD_PTR );

static HMG_MODERN_TAB * HMG_ModernTabGet ( HWND hWnd )
{
	DWORD_PTR dwRef = 0;

	if( hWnd != NULL && GetWindowSubclass( hWnd, HMG_ModernTabProc, HMG_MODERNTAB_ID, &dwRef ) )
		return (HMG_MODERN_TAB *) dwRef;

	return NULL;
}

static void HMG_ModernTabFreeBrushes ( HMG_MODERN_TAB * p )
{
	if( p->hStrip ) { DeleteObject( p->hStrip ); p->hStrip = NULL; }
	if( p->hPill  ) { DeleteObject( p->hPill );  p->hPill  = NULL; }
}

static LRESULT CALLBACK HMG_ModernTabProc ( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam,
											UINT_PTR uIdSubclass, DWORD_PTR dwRefData )
{
	HMG_MODERN_TAB * p = (HMG_MODERN_TAB *) dwRefData;

	switch( msg )
	{
		case WM_ERASEBKGND:
		{
			RECT rc, rcDisp;

			GetClientRect( hWnd, &rc );

			/* The page area gets the pill colour so the selected tab (same colour)
			   looks joined to its content. Body first, then only the tab strip (top
			   of the control down to the top of the display rectangle): the other
			   way round, the margins the control leaves around the display area
			   would stay accent-coloured and look like a frame. */
			rcDisp = rc;
			SendMessage( hWnd, TCM_ADJUSTRECT, (WPARAM) FALSE, (LPARAM) &rcDisp );

			FillRect( (HDC) wParam, &rc, p->hPill );
			rc.bottom = rcDisp.top;
			FillRect( (HDC) wParam, &rc, p->hStrip );
			return 1;
		}

		case WM_NCDESTROY:
			RemoveWindowSubclass( hWnd, HMG_ModernTabProc, uIdSubclass );
			HMG_ModernTabFreeBrushes( p );
			LocalFree( (HLOCAL) p );
			break;
	}

	return DefSubclassProc( hWnd, msg, wParam, lParam );
}

static void HMG_DrawModernTabItem ( HMG_MODERN_TAB * p, LPDRAWITEMSTRUCT pDI )
{
	TCHAR  szText [ 256 ];
	TCITEM tii;
	HFONT  hFont, hOldFont = NULL;
	RECT   rcText = pDI->rcItem;

	szText [ 0 ] = 0;
	tii.mask       = TCIF_TEXT;
	tii.pszText    = szText;
	tii.cchTextMax = 255;
	TabCtrl_GetItem( pDI->hwndItem, pDI->itemID, &tii );

	hFont = (HFONT) SendMessage( pDI->hwndItem, WM_GETFONT, 0, 0 );
	if( hFont != NULL )
		hOldFont = (HFONT) SelectObject( pDI->hDC, hFont );

	SetBkMode( pDI->hDC, TRANSPARENT );

	if( pDI->itemState & ODS_SELECTED )
	{
		HPEN    hPen  = CreatePen( PS_SOLID, 1, p->cPill );
		HGDIOBJ hOldB = SelectObject( pDI->hDC, p->hPill );
		HGDIOBJ hOldP = SelectObject( pDI->hDC, hPen );

		/* the selected tab's rcItem is taller than the others and the control
		   already reserves the border, so the pill is sunk by a couple of pixels */
		RoundRect( pDI->hDC, pDI->rcItem.left + 2, pDI->rcItem.top + 2,
				   pDI->rcItem.right - 2, pDI->rcItem.bottom - 1, 8, 8 );

		SelectObject( pDI->hDC, hOldB );
		SelectObject( pDI->hDC, hOldP );
		DeleteObject( hPen );

		SetTextColor( pDI->hDC, p->cTextSel );
	}
	else
		SetTextColor( pDI->hDC, p->cText );

	rcText.left  += 8;
	rcText.right -= 4;
	DrawText( pDI->hDC, szText, -1, &rcText, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_END_ELLIPSIS );

	if( hOldFont != NULL )
		SelectObject( pDI->hDC, hOldFont );
}

/* The controls of a TAB PAGE are siblings (children of the form) placed over the
   display area: repainting the whole TAB covers them. So the TAB is repainted first,
   then, bottom to top in z-order, the visible siblings that overlap it. */
static void HMG_RepaintModernTab ( HWND hTab )
{
	HWND hParent = GetParent( hTab );
	HWND hSib;
	RECT rcTab, rcSib;

	InvalidateRect( hTab, NULL, TRUE );
	if( hParent == NULL )
		return;

	GetWindowRect( hTab, &rcTab );
	UpdateWindow( hTab );

	for( hSib = GetWindow( hTab, GW_HWNDPREV ); hSib != NULL; hSib = GetWindow( hSib, GW_HWNDPREV ) )
	{
		if( ! IsWindowVisible( hSib ) )
			continue;

		GetWindowRect( hSib, &rcSib );   /* both in screen coordinates */
		if( IntersectRect( &rcSib, &rcSib, &rcTab ) )
			RedrawWindow( hSib, NULL, NULL, RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW );
	}
}

static BOOL HMG_IsTabControl ( HWND hWnd )
{
	TCHAR aClass [ 32 ];

	return IsWindow( hWnd ) && GetClassName( hWnd, aClass, 31 ) > 0 && _tcsicmp( aClass, WC_TABCONTROL ) == 0;
}

static COLORREF HMG_ModernTabColor ( int nParam, int nSysColor )
{
	if( HB_ISNUM( nParam ) && HB_ISNUM( nParam + 1 ) && HB_ISNUM( nParam + 2 ) )
		return RGB( hb_parni( nParam ), hb_parni( nParam + 1 ), hb_parni( nParam + 2 ) );

	return HMG_SysColor( nSysColor );   /* Phase 4: dark palette in dark mode */
}

/* Phase 4 (c_dark.c): the same as TabSetModern, callable from C */
static BOOL HMG_TabModernApply ( HWND hWnd, COLORREF cStrip, COLORREF cPill, COLORREF cText, COLORREF cTextSel, int nMinWidth );

BOOL HMG_TabApplyModern ( HWND hTab, COLORREF cStrip, COLORREF cPill, COLORREF cText, COLORREF cTextSel )
{
	return HMG_IsTabControl( hTab ) && HMG_TabModernApply( hTab, cStrip, cPill, cText, cTextSel, -1 );
}

HB_FUNC( TABSETMODERN )
{
	HWND hWnd = (HWND) HMG_parnl( 1 );

	if( ! HMG_IsTabControl( hWnd ) )
	{
		hb_retl( FALSE );
		return;
	}

	/* colours: each RGB triple is optional; missing -> system colour */
	hb_retl( HMG_TabModernApply( hWnd,
	                             HMG_ModernTabColor(  2, COLOR_HIGHLIGHT ),
	                             HMG_ModernTabColor(  5, COLOR_WINDOW ),
	                             HMG_ModernTabColor(  8, COLOR_HIGHLIGHTTEXT ),
	                             HMG_ModernTabColor( 11, COLOR_WINDOWTEXT ),
	                             HB_ISNUM( 14 ) ? hb_parni( 14 ) : -1 ) );
}

static BOOL HMG_TabModernApply ( HWND hWnd, COLORREF cStrip, COLORREF cPill, COLORREF cText, COLORREF cTextSel, int nMinWidth )
{
	HMG_MODERN_TAB * p;
	LONG_PTR         lStyle;

	p = HMG_ModernTabGet( hWnd );
	if( p == NULL )
	{
		p = (HMG_MODERN_TAB *) LocalAlloc( LPTR, sizeof( HMG_MODERN_TAB ) );
		if( p == NULL || ! SetWindowSubclass( hWnd, HMG_ModernTabProc, HMG_MODERNTAB_ID, (DWORD_PTR) p ) )
		{
			if( p != NULL )
				LocalFree( (HLOCAL) p );
			return FALSE;
		}
	}

	p->cStrip   = cStrip;
	p->cPill    = cPill;
	p->cText    = cText;
	p->cTextSel = cTextSel;

	HMG_ModernTabFreeBrushes( p );
	p->hStrip = CreateSolidBrush( p->cStrip );
	p->hPill  = CreateSolidBrush( p->cPill );

	if( nMinWidth >= 0 )
		SendMessage( hWnd, TCM_SETMINTABWIDTH, 0, (LPARAM) nMinWidth );

	lStyle = GetWindowLongPtr( hWnd, GWL_STYLE );
	if( ! ( lStyle & TCS_OWNERDRAWFIXED ) )
	{
		SetWindowLongPtr( hWnd, GWL_STYLE, lStyle | TCS_OWNERDRAWFIXED );
		SetWindowPos( hWnd, NULL, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED );
	}

	HMG_RepaintModernTab( hWnd );

	return TRUE;
}

HB_FUNC( TABCLEARMODERN )
{
	HWND             hWnd = (HWND) HMG_parnl( 1 );
	HMG_MODERN_TAB * p    = HMG_ModernTabGet( hWnd );
	LONG_PTR         lStyle;

	if( p == NULL )
	{
		hb_retl( FALSE );
		return;
	}

	RemoveWindowSubclass( hWnd, HMG_ModernTabProc, HMG_MODERNTAB_ID );
	HMG_ModernTabFreeBrushes( p );
	LocalFree( (HLOCAL) p );

	lStyle = GetWindowLongPtr( hWnd, GWL_STYLE );
	if( lStyle & TCS_OWNERDRAWFIXED )
	{
		SetWindowLongPtr( hWnd, GWL_STYLE, lStyle & ~TCS_OWNERDRAWFIXED );
		SetWindowPos( hWnd, NULL, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED );
	}

	SendMessage( hWnd, TCM_SETMINTABWIDTH, 0, (LPARAM) -1 );   /* -1: default minimum width */

	HMG_RepaintModernTab( hWnd );

	hb_retl( TRUE );
}

HB_FUNC( TABDRAWITEM )
{
	LPDRAWITEMSTRUCT pDI = (LPDRAWITEMSTRUCT) HMG_parnl( 1 );
	HMG_MODERN_TAB * p;

	if( pDI == NULL || pDI->CtlType != ODT_TAB || ( p = HMG_ModernTabGet( pDI->hwndItem ) ) == NULL )
	{
		hb_retl( FALSE );
		return;
	}

	HMG_DrawModernTabItem( p, pDI );

	hb_retl( TRUE );
}

HB_FUNC( ISTABMODERN )
{
	hb_retl( HMG_ModernTabGet( (HWND) HMG_parnl( 1 ) ) != NULL );
}
