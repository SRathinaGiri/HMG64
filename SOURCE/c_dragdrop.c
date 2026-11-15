/*
 * HMG5 - drag and drop between LISTBOX and GRID controls (5.1)
 *
 * Clauses DRAGSOURCE, DROPTARGET, DRAGREMOVE and ON DROP <action> (h_dragdrop.prg).
 * Inside one program only, so no OLE: the source control captures the mouse and runs a
 * short loop while a label follows the cursor and a line shows where the items will land.
 * The drop itself is handed to Harbour: _HMG_DRAGDROP( hSource, aItems, hTarget, nRow,
 * lCopy, lOutside ).
 *
 *  - LISTBOX: a press on an item and a move past the system drag distance start it.
 *  - GRID:    the list view sends LVN_BEGINDRAG to its parent; the parent is subclassed
 *             (once) to catch it before HMG's own handler.
 *  - Ctrl at the drop copies; Esc, the right button or losing the capture cancels.
 *  - Dropped away from every drop target, on a DRAGREMOVE source: lOutside = .T.
 */

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <windowsx.h>
#include <commctrl.h>
#include <tchar.h>
#include <stdlib.h>
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hmg_dpi.h"

#define DD_LIST          1
#define DD_GRID          2

#define DD_ID_CONTROL    0x484D4401u
#define DD_ID_PARENT     0x484D4402u

#define DD_NONE          0     /* nothing happens at this point */
#define DD_TARGET        1     /* dropped on a drop target */
#define DD_OUTSIDE       2     /* dropped away, the source removes the items */

#define DD_LABELMAX      300   /* characters shown in the label */

typedef struct
{
   HWND hWnd;
   int  nKind;
   BOOL bSource;
   BOOL bTarget;
   BOOL bRemove;
} DDREG;

static DDREG * s_pReg   = NULL;
static int     s_nReg   = 0;
static int     s_nAlloc = 0;

/* the drag in progress */
static BOOL    s_bDragging = FALSE;
static BOOL    s_bLost     = FALSE;
static HWND    s_hSrc      = NULL;
static HWND    s_hLabel    = NULL;
static HWND    s_hLine     = NULL;
static HFONT   s_hFont     = NULL;
static int     s_nMode     = DD_NONE;
static TCHAR   s_szLabel[ DD_LABELMAX + 40 ];
static TCHAR   s_szItem[ DD_LABELMAX + 1 ];
static int     s_nItems    = 0;

static LRESULT CALLBACK dd_ControlProc( HWND, UINT, WPARAM, LPARAM, UINT_PTR, DWORD_PTR );
static LRESULT CALLBACK dd_ParentProc( HWND, UINT, WPARAM, LPARAM, UINT_PTR, DWORD_PTR );
static void dd_Run( HWND hSrc );

/* ------------------------------------------------------------------------ */
/* registry of the controls that take part                                   */
/* ------------------------------------------------------------------------ */

static DDREG * dd_Find( HWND hWnd )
{
   int i;
   if( hWnd == NULL )
      return NULL;
   for( i = 0; i < s_nReg; i++ )
      if( s_pReg[ i ].hWnd == hWnd )
         return &s_pReg[ i ];
   return NULL;
}

static void dd_Forget( HWND hWnd )
{
   int i;
   for( i = 0; i < s_nReg; i++ )
   {
      if( s_pReg[ i ].hWnd == hWnd )
      {
         s_pReg[ i ] = s_pReg[ s_nReg - 1 ];
         s_nReg--;
         return;
      }
   }
}

static BOOL dd_IsMulti( HWND hWnd, int nKind )
{
   LONG_PTR nStyle = GetWindowLongPtr( hWnd, GWL_STYLE );
   if( nKind == DD_LIST )
      return ( nStyle & ( LBS_EXTENDEDSEL | LBS_MULTIPLESEL ) ) != 0;
   return ( nStyle & LVS_SINGLESEL ) == 0;
}

static int dd_Count( HWND hWnd, int nKind )
{
   if( nKind == DD_LIST )
      return ( int ) SendMessage( hWnd, LB_GETCOUNT, 0, 0 );
   return ( int ) SendMessage( hWnd, LVM_GETITEMCOUNT, 0, 0 );
}

/* the selected items, 0-based, in order; NULL when none */
static int * dd_Selected( DDREG * r, int * pnCount )
{
   int * pItems = NULL;
   int   n = 0, i;

   if( r->nKind == DD_LIST )
   {
      if( dd_IsMulti( r->hWnd, DD_LIST ) )
      {
         n = ( int ) SendMessage( r->hWnd, LB_GETSELCOUNT, 0, 0 );
         if( n > 0 )
         {
            pItems = ( int * ) hb_xgrab( sizeof( int ) * n );
            n = ( int ) SendMessage( r->hWnd, LB_GETSELITEMS, ( WPARAM ) n, ( LPARAM ) pItems );
         }
      }
      else
      {
         i = ( int ) SendMessage( r->hWnd, LB_GETCURSEL, 0, 0 );
         if( i >= 0 )
         {
            pItems = ( int * ) hb_xgrab( sizeof( int ) );
            pItems[ 0 ] = i;
            n = 1;
         }
      }
   }
   else
   {
      int nSel = ( int ) SendMessage( r->hWnd, LVM_GETSELECTEDCOUNT, 0, 0 );
      if( nSel > 0 )
      {
         pItems = ( int * ) hb_xgrab( sizeof( int ) * nSel );
         i = -1;
         while( n < nSel && ( i = ( int ) SendMessage( r->hWnd, LVM_GETNEXTITEM, ( WPARAM ) i, MAKELPARAM( LVNI_SELECTED, 0 ) ) ) >= 0 )
            pItems[ n++ ] = i;
      }
   }
   if( n <= 0 && pItems )
   {
      hb_xfree( pItems );
      pItems = NULL;
      n = 0;
   }
   *pnCount = n;
   return pItems;
}

static void dd_ItemText( DDREG * r, int nItem, TCHAR * szText, int nMax )
{
   szText[ 0 ] = 0;
   if( r->nKind == DD_LIST )
   {
      int nLen = ( int ) SendMessage( r->hWnd, LB_GETTEXTLEN, ( WPARAM ) nItem, 0 );
      if( nLen >= 0 && nLen < nMax )
         SendMessage( r->hWnd, LB_GETTEXT, ( WPARAM ) nItem, ( LPARAM ) szText );
      else if( nLen >= nMax )
      {
         TCHAR * p = ( TCHAR * ) hb_xgrab( ( nLen + 1 ) * sizeof( TCHAR ) );
         SendMessage( r->hWnd, LB_GETTEXT, ( WPARAM ) nItem, ( LPARAM ) p );
         lstrcpyn( szText, p, nMax );
         hb_xfree( p );
      }
   }
   else
   {
      LVITEM lvi;
      int    nCol;
      /* the first column with text (an image grid shows only the picture in column 0) */
      for( nCol = 0; nCol < 4 && szText[ 0 ] == 0; nCol++ )
      {
         memset( &lvi, 0, sizeof( lvi ) );
         lvi.iSubItem   = nCol;
         lvi.pszText    = szText;
         lvi.cchTextMax = nMax;
         SendMessage( r->hWnd, LVM_GETITEMTEXT, ( WPARAM ) nItem, ( LPARAM ) &lvi );
      }
   }
}

/* ------------------------------------------------------------------------ */
/* the label that follows the cursor and the insertion line                 */
/* ------------------------------------------------------------------------ */

static LRESULT CALLBACK dd_PopupProc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   switch( msg )
   {
      case WM_NCHITTEST:
         return HTTRANSPARENT;
      case WM_ERASEBKGND:
         return 1;
      case WM_PAINT:
      {
         PAINTSTRUCT ps;
         HDC         hDC = BeginPaint( hWnd, &ps );
         RECT        rc;
         HBRUSH      hBr;

         GetClientRect( hWnd, &rc );
         if( hWnd == s_hLine )
         {
            hBr = CreateSolidBrush( HMG_SysColor( COLOR_HIGHLIGHT ) );
            FillRect( hDC, &rc, hBr );
            DeleteObject( hBr );
         }
         else
         {
            HFONT hOld = NULL;
            hBr = CreateSolidBrush( HMG_SysColor( s_nMode == DD_NONE ? COLOR_BTNFACE : COLOR_INFOBK ) );
            FillRect( hDC, &rc, hBr );
            DeleteObject( hBr );
            hBr = CreateSolidBrush( HMG_SysColor( COLOR_BTNSHADOW ) );
            FrameRect( hDC, &rc, hBr );
            DeleteObject( hBr );
            if( s_hFont )
               hOld = ( HFONT ) SelectObject( hDC, s_hFont );
            SetBkMode( hDC, TRANSPARENT );
            SetTextColor( hDC, HMG_SysColor( s_nMode == DD_NONE ? COLOR_GRAYTEXT : COLOR_INFOTEXT ) );
            InflateRect( &rc, -6, -2 );
            DrawText( hDC, s_szLabel, -1, &rc, DT_SINGLELINE | DT_VCENTER | DT_NOPREFIX | DT_END_ELLIPSIS );
            if( hOld )
               SelectObject( hDC, hOld );
         }
         EndPaint( hWnd, &ps );
         return 0;
      }
   }
   return DefWindowProc( hWnd, msg, wParam, lParam );
}

static HWND dd_Popup( void )
{
   static BOOL s_bClass = FALSE;
   HWND hWnd;

   if( ! s_bClass )
   {
      WNDCLASS wc;
      memset( &wc, 0, sizeof( wc ) );
      wc.lpfnWndProc   = dd_PopupProc;
      wc.hInstance     = GetModuleHandle( NULL );
      wc.hCursor       = LoadCursor( NULL, IDC_ARROW );
      wc.lpszClassName = TEXT( "HMG5_DragPopup" );
      RegisterClass( &wc );
      s_bClass = TRUE;
   }
   hWnd = CreateWindowEx( WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW | WS_EX_TOPMOST | WS_EX_NOACTIVATE,
                          TEXT( "HMG5_DragPopup" ), TEXT( "" ), WS_POPUP,
                          0, 0, 1, 1, NULL, NULL, GetModuleHandle( NULL ), NULL );
   if( hWnd )
      SetLayeredWindowAttributes( hWnd, 0, 225, LWA_ALPHA );
   return hWnd;
}

static void dd_SetLabel( void )
{
   TCHAR szMore[ 32 ];
   const TCHAR * szAct = TEXT( "" );

   if( s_nMode == DD_OUTSIDE )
      szAct = TEXT( "Remove: " );
   s_szLabel[ 0 ] = 0;
   lstrcat( s_szLabel, szAct );
   lstrcat( s_szLabel, s_szItem );
   if( s_nItems > 1 )
   {
      wsprintf( szMore, TEXT( "  (+%d)" ), s_nItems - 1 );
      lstrcat( s_szLabel, szMore );
   }
}

static void dd_ShowLabel( POINT pt, BOOL bCopy )
{
   HDC   hDC;
   HFONT hOld = NULL;
   SIZE  sz;
   int   nDpi = 96;
   TCHAR szText[ DD_LABELMAX + 48 ];

   if( s_hLabel == NULL )
      return;
   dd_SetLabel();
   if( bCopy && s_nMode == DD_TARGET )
   {
      lstrcpy( szText, TEXT( "+ " ) );
      lstrcat( szText, s_szLabel );
      lstrcpy( s_szLabel, szText );
   }
   hDC = GetDC( s_hLabel );
   if( s_hFont )
      hOld = ( HFONT ) SelectObject( hDC, s_hFont );
   GetTextExtentPoint32( hDC, s_szLabel, lstrlen( s_szLabel ), &sz );
   nDpi = GetDeviceCaps( hDC, LOGPIXELSX );
   if( hOld )
      SelectObject( hDC, hOld );
   ReleaseDC( s_hLabel, hDC );
   if( sz.cx > MulDiv( 320, nDpi, 96 ) )
      sz.cx = MulDiv( 320, nDpi, 96 );
   SetWindowPos( s_hLabel, HWND_TOPMOST, pt.x + MulDiv( 14, nDpi, 96 ), pt.y + MulDiv( 18, nDpi, 96 ),
                 sz.cx + 14, sz.cy + 6, SWP_NOACTIVATE | SWP_SHOWWINDOW );
   InvalidateRect( s_hLabel, NULL, FALSE );
   UpdateWindow( s_hLabel );
}

/* ------------------------------------------------------------------------ */
/* where the items would land                                                */
/* ------------------------------------------------------------------------ */

/* top of the item area (below a grid's header), client coordinates */
static int dd_ItemsTop( DDREG * t )
{
   if( t->nKind == DD_GRID )
   {
      HWND hHdr = ( HWND ) SendMessage( t->hWnd, LVM_GETHEADER, 0, 0 );
      if( hHdr && IsWindowVisible( hHdr ) )
      {
         RECT rc;
         GetWindowRect( hHdr, &rc );
         return rc.bottom - rc.top;
      }
   }
   return 0;
}

static BOOL dd_ItemRect( DDREG * t, int nItem, RECT * prc )
{
   if( t->nKind == DD_LIST )
      return SendMessage( t->hWnd, LB_GETITEMRECT, ( WPARAM ) nItem, ( LPARAM ) prc ) != LB_ERR;
   prc->left = LVIR_BOUNDS;
   return SendMessage( t->hWnd, LVM_GETITEMRECT, ( WPARAM ) nItem, ( LPARAM ) prc ) != 0;
}

/* 0-based insertion index (0..count), -1 for a sorted list box (no position).
   *pnLineY: the client y of the line, or -1 for no line. */
static int dd_InsertAt( DDREG * t, POINT ptScreen, int * pnLineY )
{
   POINT pt = ptScreen;
   int   n, nTop, nIdx, nH, nItemsTop;
   RECT  rc, rcCli;

   *pnLineY = -1;
   ScreenToClient( t->hWnd, &pt );
   GetClientRect( t->hWnd, &rcCli );
   if( t->nKind == DD_LIST && ( GetWindowLongPtr( t->hWnd, GWL_STYLE ) & LBS_SORT ) )
      return -1;

   n         = dd_Count( t->hWnd, t->nKind );
   nItemsTop = dd_ItemsTop( t );
   if( n <= 0 )
   {
      *pnLineY = nItemsTop;
      return 0;
   }
   nTop = ( int ) SendMessage( t->hWnd, t->nKind == DD_LIST ? LB_GETTOPINDEX : LVM_GETTOPINDEX, 0, 0 );
   if( nTop < 0 || nTop >= n )
      nTop = 0;
   if( ! dd_ItemRect( t, nTop, &rc ) )
      return n;
   nH = rc.bottom - rc.top;
   if( nH <= 0 )
      nH = 1;
   nIdx = pt.y < rc.top ? nTop : nTop + ( pt.y - rc.top ) / nH;
   if( nIdx >= n )
   {
      if( dd_ItemRect( t, n - 1, &rc ) )
         *pnLineY = rc.bottom;
      nIdx = n;
   }
   else if( dd_ItemRect( t, nIdx, &rc ) )
   {
      if( pt.y > ( rc.top + rc.bottom ) / 2 )
      {
         nIdx++;
         *pnLineY = rc.bottom;
      }
      else
         *pnLineY = rc.top;
   }
   if( *pnLineY >= 0 )
   {
      if( *pnLineY < nItemsTop )
         *pnLineY = nItemsTop;
      if( *pnLineY > rcCli.bottom - 1 )
         *pnLineY = rcCli.bottom - 1;
   }
   return nIdx;
}

static void dd_ShowLine( DDREG * t, int nLineY )
{
   RECT  rc;
   POINT pt;

   if( s_hLine == NULL )
      return;
   if( t == NULL || nLineY < 0 )
   {
      ShowWindow( s_hLine, SW_HIDE );
      return;
   }
   GetClientRect( t->hWnd, &rc );
   pt.x = 0;
   pt.y = nLineY;
   ClientToScreen( t->hWnd, &pt );
   SetWindowPos( s_hLine, HWND_TOPMOST, pt.x + 1, pt.y - 1, rc.right - 2 > 1 ? rc.right - 2 : 1, 2,
                 SWP_NOACTIVATE | SWP_SHOWWINDOW );
}

/* the registered control at this screen point (a grid's header counts as the grid) */
static DDREG * dd_At( POINT pt, BOOL * pbOwn )
{
   HWND    hWnd = WindowFromPoint( pt );
   DDREG * r    = NULL;
   int     i;

   *pbOwn = ( hWnd != NULL && ( hWnd == s_hLine || hWnd == s_hLabel ) );
   for( i = 0; i < 3 && hWnd != NULL && r == NULL; i++ )
   {
      r = dd_Find( hWnd );
      if( r == NULL )
         hWnd = GetParent( hWnd );
   }
   return r;
}

/* handles, not registry pointers: the registry can change while the loop dispatches */
typedef struct
{
   HWND  hSrc;
   HWND  hTgt;
   int   nInsert;
   BOOL  bCopy;
   POINT ptLast;
} DDSTATE;

static void dd_Update( DDSTATE * s, POINT pt )
{
   BOOL    bOwn;
   DDREG * r = dd_At( pt, &bOwn );
   DDREG * pSrc = dd_Find( s->hSrc );
   int     nLineY = -1;

   s->ptLast = pt;
   if( pSrc == NULL )
   {
      s_bLost = TRUE;   /* the source is gone */
      return;
   }
   if( bOwn )
      return;   /* over the line or the label: keep what was shown */

   s->hTgt    = NULL;
   s->nInsert = -1;
   if( r && r->bTarget && IsWindowEnabled( r->hWnd ) && IsWindowVisible( r->hWnd ) )
   {
      s->hTgt    = r->hWnd;
      s->nInsert = dd_InsertAt( r, pt, &nLineY );
      s_nMode    = DD_TARGET;
   }
   else if( pSrc->bRemove && ( r == NULL || r->hWnd != s->hSrc ) )
      s_nMode = DD_OUTSIDE;
   else
      s_nMode = DD_NONE;

   dd_ShowLine( r && s->hTgt ? r : NULL, nLineY );
   dd_ShowLabel( pt, s->bCopy );
   SetCursor( LoadCursor( NULL, s_nMode == DD_NONE ? IDC_NO : IDC_ARROW ) );
}

/* scrolls the target when the cursor is near its top or bottom edge; TRUE if it did */
static BOOL dd_AutoScroll( DDSTATE * s )
{
   POINT   pt = s->ptLast;
   RECT    rc, rcItem;
   int     nH, nTop, nDir = 0;
   DDREG * t = dd_Find( s->hTgt );
   UINT    uTop;

   if( t == NULL || dd_Count( t->hWnd, t->nKind ) == 0 )
      return FALSE;
   uTop = t->nKind == DD_LIST ? LB_GETTOPINDEX : LVM_GETTOPINDEX;
   ScreenToClient( t->hWnd, &pt );
   GetClientRect( t->hWnd, &rc );
   if( pt.x < 0 || pt.x > rc.right )
      return FALSE;
   nTop = ( int ) SendMessage( t->hWnd, uTop, 0, 0 );
   if( ! dd_ItemRect( t, nTop < 0 ? 0 : nTop, &rcItem ) )
      return FALSE;
   nH = rcItem.bottom - rcItem.top;
   if( nH < 4 )
      nH = 4;
   if( pt.y < dd_ItemsTop( t ) + nH / 2 && nTop > 0 )
      nDir = -1;
   else if( pt.y > rc.bottom - nH / 2 )
      nDir = 1;
   if( nDir == 0 )
      return FALSE;
   if( t->nKind == DD_LIST )
      SendMessage( t->hWnd, WM_VSCROLL, nDir < 0 ? SB_LINEUP : SB_LINEDOWN, 0 );
   else
      SendMessage( t->hWnd, LVM_SCROLL, 0, ( LPARAM ) ( nDir * nH ) );
   return nTop != ( int ) SendMessage( t->hWnd, uTop, 0, 0 );
}

/* ------------------------------------------------------------------------ */
/* the drag                                                                  */
/* ------------------------------------------------------------------------ */

static void dd_Drop( HWND hSrc, int * pItems, int nItems, HWND hTgt, int nInsert, BOOL bCopy, BOOL bOutside )
{
   PHB_DYNS pSym = hb_dynsymFindName( "_HMG_DRAGDROP" );
   if( pSym && hb_vmRequestReenter() )
   {
      PHB_ITEM pArr = hb_itemArrayNew( nItems );
      int      i;
      for( i = 0; i < nItems; i++ )
         hb_arraySetNI( pArr, i + 1, pItems[ i ] + 1 );
      hb_vmPushDynSym( pSym );
      hb_vmPushNil();
      hb_vmPushNumInt( ( HB_MAXINT ) ( HB_PTRUINT ) hSrc );
      hb_vmPush( pArr );
      hb_vmPushNumInt( ( HB_MAXINT ) ( HB_PTRUINT ) hTgt );
      hb_vmPushInteger( nInsert < 0 ? 0 : nInsert + 1 );
      hb_vmPushLogical( bCopy );
      hb_vmPushLogical( bOutside );
      hb_vmDo( 6 );
      hb_itemRelease( pArr );
      hb_vmRequestRestore();
   }
}

static void dd_Run( HWND hSrc )
{
   DDSTATE  s;
   DDREG  * pSrc = dd_Find( hSrc );
   int    * pItems;
   int      nItems = 0, nResult = DD_NONE;
   UINT_PTR nTimer;
   MSG      msg;
   HWND     hTgt;

   memset( &s, 0, sizeof( s ) );
   if( s_bDragging || pSrc == NULL || ! pSrc->bSource )
      return;
   s.hSrc = hSrc;
   pItems = dd_Selected( pSrc, &nItems );
   if( pItems == NULL )
      return;

   s_nItems = nItems;
   dd_ItemText( pSrc, pItems[ 0 ], s_szItem, DD_LABELMAX );
   s_hFont = ( HFONT ) SendMessage( hSrc, WM_GETFONT, 0, 0 );
   s_hLabel = dd_Popup();
   s_hLine  = dd_Popup();

   s_bDragging = TRUE;
   s_bLost     = FALSE;
   s_hSrc      = hSrc;
   s_nMode     = DD_NONE;
   SetCapture( hSrc );
   nTimer = SetTimer( NULL, 0, 60, NULL );
   GetCursorPos( &s.ptLast );

   for( ;; )
   {
      if( s_bLost || GetCapture() != hSrc )
         break;
      if( GetMessage( &msg, NULL, 0, 0 ) <= 0 )
      {
         PostQuitMessage( ( int ) msg.wParam );
         break;
      }
      if( msg.message == WM_MOUSEMOVE || msg.message == WM_LBUTTONUP )
      {
         POINT pt;
         pt.x = GET_X_LPARAM( msg.lParam );
         pt.y = GET_Y_LPARAM( msg.lParam );
         if( msg.hwnd )
            ClientToScreen( msg.hwnd, &pt );
         s.bCopy = ( msg.wParam & MK_CONTROL ) != 0;
         dd_Update( &s, pt );
         if( msg.message == WM_LBUTTONUP )
         {
            nResult = s_nMode;
            break;
         }
         continue;
      }
      if( msg.message == WM_TIMER && msg.hwnd == NULL && msg.wParam == nTimer )
      {
         if( dd_AutoScroll( &s ) )
            dd_Update( &s, s.ptLast );
         continue;
      }
      if( msg.message == WM_KEYDOWN || msg.message == WM_SYSKEYDOWN )
      {
         if( msg.wParam == VK_ESCAPE )
            break;
         if( msg.wParam == VK_CONTROL && ! s.bCopy )
         {
            s.bCopy = TRUE;
            dd_Update( &s, s.ptLast );
         }
         continue;
      }
      if( msg.message == WM_KEYUP || msg.message == WM_SYSKEYUP )
      {
         if( msg.wParam == VK_CONTROL && s.bCopy )
         {
            s.bCopy = FALSE;
            dd_Update( &s, s.ptLast );
         }
         continue;
      }
      if( msg.message == WM_RBUTTONDOWN || msg.message == WM_MBUTTONDOWN )
         break;
      if( ( msg.message >= WM_MOUSEFIRST && msg.message <= WM_MOUSELAST ) ||
          ( msg.message >= WM_KEYFIRST && msg.message <= WM_KEYLAST ) )
         continue;
      TranslateMessage( &msg );
      DispatchMessage( &msg );
   }

   KillTimer( NULL, nTimer );
   s_bDragging = FALSE;
   if( GetCapture() == hSrc )
      ReleaseCapture();
   DestroyWindow( s_hLine );
   DestroyWindow( s_hLabel );
   s_hLine  = NULL;
   s_hLabel = NULL;
   s_hSrc   = NULL;

   /* the registry may have changed (a control released while the loop dispatched) */
   hTgt = s.hTgt;
   if( nResult == DD_TARGET && hTgt && dd_Find( hTgt ) && dd_Find( hSrc ) )
      dd_Drop( hSrc, pItems, nItems, hTgt, s.nInsert, s.bCopy, FALSE );
   else if( nResult == DD_OUTSIDE && dd_Find( hSrc ) )
      dd_Drop( hSrc, pItems, nItems, NULL, -1, FALSE, TRUE );
   hb_xfree( pItems );
}

/* ------------------------------------------------------------------------ */
/* subclass procedures                                                       */
/* ------------------------------------------------------------------------ */

/* LISTBOX: a press on an item, then a move past the system drag distance, starts the drag.
   A press on an item that is already selected is held back from the list box, so a
   multiple selection is kept; if the button comes up without a move, the list box gets the
   press and the release (an ordinary click). */
static HWND   s_hPress    = NULL;
static BOOL   s_bPressSel = FALSE;
static WPARAM s_wPress    = 0;
static LPARAM s_lPress    = 0;

static LRESULT dd_ListButtonDown( HWND hWnd, WPARAM wParam, LPARAM lParam )
{
   DWORD dw   = ( DWORD ) SendMessage( hWnd, LB_ITEMFROMPOINT, 0, lParam );
   int   nIdx = LOWORD( dw );
   int   n    = ( int ) SendMessage( hWnd, LB_GETCOUNT, 0, 0 );
   BOOL  bSel;

   s_hPress = NULL;
   if( HIWORD( dw ) || nIdx >= n || ( wParam & ( MK_SHIFT | MK_CONTROL ) ) )
      return DefSubclassProc( hWnd, WM_LBUTTONDOWN, wParam, lParam );

   if( dd_IsMulti( hWnd, DD_LIST ) )
      bSel = SendMessage( hWnd, LB_GETSEL, ( WPARAM ) nIdx, 0 ) > 0;
   else
      bSel = ( int ) SendMessage( hWnd, LB_GETCURSEL, 0, 0 ) == nIdx;

   s_bPressSel = bSel;
   s_wPress    = wParam;
   s_lPress    = lParam;
   if( bSel )
   {
      if( GetFocus() != hWnd )
         SetFocus( hWnd );
      SetCapture( hWnd );
      s_hPress = hWnd;
      return 0;
   }
   {
      LRESULT lr = DefSubclassProc( hWnd, WM_LBUTTONDOWN, wParam, lParam );
      s_hPress = hWnd;
      return lr;
   }
}

/* TRUE when the move started a drag (the message is then consumed) */
static BOOL dd_ListMouseMove( HWND hWnd, WPARAM wParam, LPARAM lParam )
{
   int dx, dy;

   if( s_hPress != hWnd )
      return FALSE;
   if( ! ( wParam & MK_LBUTTON ) )
   {
      s_hPress = NULL;
      return FALSE;
   }
   dx = GET_X_LPARAM( lParam ) - GET_X_LPARAM( s_lPress );
   dy = GET_Y_LPARAM( lParam ) - GET_Y_LPARAM( s_lPress );
   if( abs( dx ) <= GetSystemMetrics( SM_CXDRAG ) && abs( dy ) <= GetSystemMetrics( SM_CYDRAG ) )
      return s_bPressSel;   /* held press: the list box does not see these moves */
   s_hPress = NULL;
   if( ! s_bPressSel )
      DefSubclassProc( hWnd, WM_LBUTTONUP, s_wPress & ~MK_LBUTTON, s_lPress );   /* ends its own tracking */
   dd_Run( hWnd );
   return TRUE;
}

/* TRUE when the release ended a held press (replayed as a click) */
static BOOL dd_ListButtonUp( HWND hWnd, WPARAM wParam, LPARAM lParam )
{
   if( s_hPress != hWnd )
      return FALSE;
   s_hPress = NULL;
   if( ! s_bPressSel )
      return FALSE;
   if( GetCapture() == hWnd )
      ReleaseCapture();
   DefSubclassProc( hWnd, WM_LBUTTONDOWN, s_wPress, s_lPress );
   DefSubclassProc( hWnd, WM_LBUTTONUP, wParam, lParam );
   return TRUE;
}

static LRESULT CALLBACK dd_ControlProc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam,
                                        UINT_PTR uId, DWORD_PTR dwRef )
{
   DDREG * r;
   HB_SYMBOL_UNUSED( dwRef );

   switch( msg )
   {
      case WM_NCDESTROY:
         dd_Forget( hWnd );
         RemoveWindowSubclass( hWnd, dd_ControlProc, uId );
         break;

      case WM_CAPTURECHANGED:
         if( s_bDragging && hWnd == s_hSrc && ( HWND ) lParam != hWnd )
            s_bLost = TRUE;
         else if( ! s_bDragging && s_hPress == hWnd && s_bPressSel && ( HWND ) lParam != hWnd )
            s_hPress = NULL;   /* a held press lost its capture (Alt+Tab ...) */
         break;

      case WM_SETCURSOR:
         if( s_bDragging )
         {
            SetCursor( LoadCursor( NULL, s_nMode == DD_NONE ? IDC_NO : IDC_ARROW ) );
            return TRUE;
         }
         break;

      case WM_LBUTTONDOWN:
         r = dd_Find( hWnd );
         if( r && r->nKind == DD_LIST && r->bSource && ! s_bDragging && IsWindowEnabled( hWnd ) )
            return dd_ListButtonDown( hWnd, wParam, lParam );
         break;

      case WM_MOUSEMOVE:
         if( ! s_bDragging && dd_ListMouseMove( hWnd, wParam, lParam ) )
            return 0;
         break;

      case WM_LBUTTONUP:
         if( ! s_bDragging && dd_ListButtonUp( hWnd, wParam, lParam ) )
            return 0;
         break;
   }
   return DefSubclassProc( hWnd, msg, wParam, lParam );
}

/* the parent of a GRID: LVN_BEGINDRAG from a registered grid starts the drag */
static LRESULT CALLBACK dd_ParentProc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam,
                                       UINT_PTR uId, DWORD_PTR dwRef )
{
   HB_SYMBOL_UNUSED( dwRef );

   if( msg == WM_NOTIFY && lParam )
   {
      NMHDR * pnm = ( NMHDR * ) lParam;
      if( pnm->code == LVN_BEGINDRAG )
      {
         DDREG * r = dd_Find( pnm->hwndFrom );
         if( r && r->nKind == DD_GRID && r->bSource && ! s_bDragging )
         {
            dd_Run( pnm->hwndFrom );
            return 0;
         }
      }
   }
   else if( msg == WM_NCDESTROY )
      RemoveWindowSubclass( hWnd, dd_ParentProc, uId );
   return DefSubclassProc( hWnd, msg, wParam, lParam );
}

/* ------------------------------------------------------------------------ */
/* Harbour API                                                               */
/* ------------------------------------------------------------------------ */

/* HMG_DRAGREGISTER( hWnd, nKind (1 list box, 2 grid), lSource, lTarget, lRemove ) -> lOk */
HB_FUNC( HMG_DRAGREGISTER )
{
   HWND    hWnd = ( HWND ) HMG_parnl( 1 );
   int     nKind = hb_parni( 2 );
   DDREG * r;

   if( ! IsWindow( hWnd ) || ( nKind != DD_LIST && nKind != DD_GRID ) )
   {
      hb_retl( FALSE );
      return;
   }
   r = dd_Find( hWnd );
   if( r == NULL )
   {
      if( s_nReg == s_nAlloc )
      {
         s_nAlloc += 16;
         s_pReg = ( DDREG * ) ( s_pReg ? hb_xrealloc( s_pReg, sizeof( DDREG ) * s_nAlloc )
                                       : hb_xgrab( sizeof( DDREG ) * s_nAlloc ) );
      }
      r = &s_pReg[ s_nReg++ ];
   }
   r->hWnd    = hWnd;
   r->nKind   = nKind;
   r->bSource = hb_parl( 3 ) || hb_parl( 5 );
   r->bTarget = hb_parl( 4 );
   r->bRemove = hb_parl( 5 );
   SetWindowSubclass( hWnd, dd_ControlProc, DD_ID_CONTROL, 0 );
   if( nKind == DD_GRID && r->bSource && GetParent( hWnd ) )
      SetWindowSubclass( GetParent( hWnd ), dd_ParentProc, DD_ID_PARENT, 0 );
   hb_retl( TRUE );
}

/* HMG_DRAGUNREGISTER( hWnd ): the control no longer takes part */
HB_FUNC( HMG_DRAGUNREGISTER )
{
   HWND hWnd = ( HWND ) HMG_parnl( 1 );
   if( dd_Find( hWnd ) )
   {
      dd_Forget( hWnd );
      RemoveWindowSubclass( hWnd, dd_ControlProc, DD_ID_CONTROL );
   }
}

/* HMG_DRAGISSORTED( hWnd ) -> lSorted: a list box with SORT (dropped items go where it sorts them) */
HB_FUNC( HMG_DRAGISSORTED )
{
   HWND hWnd = ( HWND ) HMG_parnl( 1 );
   hb_retl( IsWindow( hWnd ) && ( GetWindowLongPtr( hWnd, GWL_STYLE ) & LBS_SORT ) != 0 );
}

/* HMG_DRAGISACTIVE() -> lDragging */
HB_FUNC( HMG_DRAGISACTIVE )
{
   hb_retl( s_bDragging );
}

/* HMG_DRAGBEGIN( hWnd ): starts the drag of the selected items, as a press and a move on
   the control would (tests: the moves and the release are posted to the control first) */
HB_FUNC( HMG_DRAGBEGIN )
{
   dd_Run( ( HWND ) HMG_parnl( 1 ) );
}

/* HMG_DRAGINSERTAT( hWnd, nScreenX, nScreenY ) -> nRow: where items dropped at that point
   would go (1-based, 0 for a sorted list box, -1 if hWnd is not a drop target) */
HB_FUNC( HMG_DRAGINSERTAT )
{
   DDREG * r = dd_Find( ( HWND ) HMG_parnl( 1 ) );
   POINT   pt;
   int     nLineY, n;

   if( r == NULL || ! r->bTarget )
   {
      hb_retni( -1 );
      return;
   }
   pt.x = hb_parni( 2 );
   pt.y = hb_parni( 3 );
   n = dd_InsertAt( r, pt, &nLineY );
   hb_retni( n < 0 ? 0 : n + 1 );
}

/* ------------------------------------------------------------------------ */
/* test helpers (tests\unit\dragdrop.prg): no real mouse input is used       */
/* ------------------------------------------------------------------------ */

/* _HMG_DRAGROWPOINT( hWnd, nRow, hRelative ) -> { x, y }: a point a quarter into row nRow
   (1-based; past the last row: just below it), in hRelative's client coordinates */
HB_FUNC( _HMG_DRAGROWPOINT )
{
   DDREG *  r    = dd_Find( ( HWND ) HMG_parnl( 1 ) );
   HWND     hRel = ( HWND ) HMG_parnl( 3 );
   POINT    pt   = { 0, 0 };
   RECT     rc;
   int      nRow = hb_parni( 2 ) - 1, n;
   PHB_ITEM pArr;

   if( r )
   {
      n = dd_Count( r->hWnd, r->nKind );
      GetClientRect( r->hWnd, &rc );
      pt.x = rc.right / 2;
      if( n == 0 )
         pt.y = dd_ItemsTop( r ) + 3;
      else if( nRow >= n )
      {
         dd_ItemRect( r, n - 1, &rc );
         pt.y = rc.bottom + 3;
      }
      else
      {
         dd_ItemRect( r, nRow < 0 ? 0 : nRow, &rc );
         pt.y = rc.top + ( rc.bottom - rc.top ) / 4;
      }
      ClientToScreen( r->hWnd, &pt );
      if( hRel )
         ScreenToClient( hRel, &pt );
   }
   pArr = hb_itemArrayNew( 2 );
   hb_arraySetNI( pArr, 1, pt.x );
   hb_arraySetNI( pArr, 2, pt.y );
   hb_itemReturnRelease( pArr );
}

/* _HMG_DRAGPOST( hWnd, nMsg, nWParam, x, y ): posts a message to one of this program's windows */
HB_FUNC( _HMG_DRAGPOST )
{
   hb_retl( PostMessage( ( HWND ) HMG_parnl( 1 ), ( UINT ) hb_parni( 2 ), ( WPARAM ) hb_parnl( 3 ),
                         MAKELPARAM( ( short ) hb_parni( 4 ), ( short ) hb_parni( 5 ) ) ) );
}
