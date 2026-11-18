/*
 * HMG5 5.2 - SPLITTER: a thin bar the mouse drags to share space between the controls
 * on its two sides (h_splitter.prg does the layout).
 *
 * INITSPLITTER( hParent, x, y, w, h, lVertical, lInvisible ) -> hWnd
 *   x, y, w, h in design units (HMG5's creation hook scales them for DPI)
 *
 * A press starts a drag (the mouse is captured); every move sends the bar's new place,
 * in the parent's client area and in design units, to Harbour:
 *   _HMG_SPLITTEREVENT( hWnd, nEvent, nPos )   nEvent 1 start, 2 move, 3 end
 * which keeps it within the limits, moves the controls and the bar. Esc during a drag
 * puts everything back (event 4).
 */

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <windowsx.h>
#include "hbapi.h"
#include "hbvm.h"
#include "hmg_dpi.h"

#define SPLIT_CLASS      TEXT( "HMG5_Splitter" )
#define SPLIT_VERTICAL   TEXT( "HMG5_SPLIT_V" )

static HWND s_hDrag   = NULL;
static int  s_nOffset = 0;   /* where in the bar it was pressed, pixels */
static int  s_nStart  = 0;   /* the bar's place when the drag began, design units */
static int  s_nLast   = 0;

static void split_event( HWND hWnd, int nEvent, int nPos )
{
   PHB_DYNS pSym = hb_dynsymFindName( "_HMG_SPLITTEREVENT" );
   if( pSym && hb_vmRequestReenter() )
   {
      hb_vmPushDynSym( pSym );
      hb_vmPushNil();
      hb_vmPushNumInt( ( HB_MAXINT ) ( HB_PTRUINT ) hWnd );
      hb_vmPushInteger( nEvent );
      hb_vmPushInteger( nPos );
      hb_vmDo( 3 );
      hb_vmRequestRestore();
   }
}

static BOOL split_vertical( HWND hWnd )
{
   return GetProp( hWnd, SPLIT_VERTICAL ) != NULL;
}

/* the bar's place in the parent's client area, design units */
static int split_place( HWND hWnd )
{
   RECT rc;
   GetWindowRect( hWnd, &rc );
   MapWindowPoints( HWND_DESKTOP, GetParent( hWnd ), ( LPPOINT ) &rc, 2 );
   return HMG_DpiUnscaleSize( hWnd, split_vertical( hWnd ) ? rc.left : rc.top );
}

static LRESULT CALLBACK split_proc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   switch( msg )
   {
      case WM_SETCURSOR:
         SetCursor( LoadCursor( NULL, split_vertical( hWnd ) ? IDC_SIZEWE : IDC_SIZENS ) );
         return TRUE;

      case WM_ERASEBKGND:
         return 1;

      case WM_PAINT:
      {
         PAINTSTRUCT ps;
         HDC         hDC = BeginPaint( hWnd, &ps );
         RECT        rc;
         HBRUSH      hBr;
         int         i, c;
         GetClientRect( hWnd, &rc );
         hBr = CreateSolidBrush( HMG_SysColor( COLOR_BTNFACE ) );
         FillRect( hDC, &rc, hBr );
         DeleteObject( hBr );
         /* a grip of three dots in the middle */
         hBr = CreateSolidBrush( HMG_SysColor( COLOR_BTNSHADOW ) );
         for( i = -1; i <= 1; i++ )
         {
            RECT d;
            if( split_vertical( hWnd ) )
            {
               c = ( rc.bottom / 2 ) + i * 6;
               SetRect( &d, rc.right / 2 - 1, c - 1, rc.right / 2 + 1, c + 1 );
            }
            else
            {
               c = ( rc.right / 2 ) + i * 6;
               SetRect( &d, c - 1, rc.bottom / 2 - 1, c + 1, rc.bottom / 2 + 1 );
            }
            FillRect( hDC, &d, hBr );
         }
         DeleteObject( hBr );
         EndPaint( hWnd, &ps );
         return 0;
      }

      case WM_LBUTTONDOWN:
         if( s_hDrag == NULL )
         {
            s_hDrag   = hWnd;
            s_nOffset = split_vertical( hWnd ) ? GET_X_LPARAM( lParam ) : GET_Y_LPARAM( lParam );
            s_nStart  = s_nLast = split_place( hWnd );
            SetCapture( hWnd );
            split_event( hWnd, 1, s_nStart );
         }
         return 0;

      case WM_MOUSEMOVE:
         if( s_hDrag == hWnd )
         {
            POINT pt;
            int   nPos;
            pt.x = GET_X_LPARAM( lParam );
            pt.y = GET_Y_LPARAM( lParam );
            MapWindowPoints( hWnd, GetParent( hWnd ), &pt, 1 );
            nPos = HMG_DpiUnscaleSize( hWnd, ( split_vertical( hWnd ) ? pt.x : pt.y ) - s_nOffset );
            if( nPos != s_nLast )
            {
               s_nLast = nPos;
               split_event( hWnd, 2, nPos );
            }
         }
         return 0;

      case WM_KEYDOWN:
         if( s_hDrag == hWnd && wParam == VK_ESCAPE )
         {
            s_hDrag = NULL;
            ReleaseCapture();
            split_event( hWnd, 4, s_nStart );   /* back where it was */
         }
         return 0;

      case WM_LBUTTONUP:
      case WM_CAPTURECHANGED:
         if( s_hDrag == hWnd )
         {
            s_hDrag = NULL;
            if( msg == WM_LBUTTONUP )
               ReleaseCapture();
            split_event( hWnd, 3, split_place( hWnd ) );
         }
         return 0;

      case WM_NCDESTROY:
         RemoveProp( hWnd, SPLIT_VERTICAL );
         if( s_hDrag == hWnd )
            s_hDrag = NULL;
         break;
   }
   return DefWindowProc( hWnd, msg, wParam, lParam );
}

HB_FUNC( INITSPLITTER )
{
   static BOOL s_bClass = FALSE;
   HWND hParent = ( HWND ) HMG_parnl( 1 );
   HWND hWnd;

   if( ! s_bClass )
   {
      WNDCLASS wc;
      memset( &wc, 0, sizeof( wc ) );
      wc.lpfnWndProc   = split_proc;
      wc.hInstance     = GetModuleHandle( NULL );
      wc.lpszClassName = SPLIT_CLASS;
      RegisterClass( &wc );
      s_bClass = TRUE;
   }
   hWnd = CreateWindowEx( 0, SPLIT_CLASS, TEXT( "" ),
                          WS_CHILD | WS_CLIPSIBLINGS | ( hb_parl( 7 ) ? 0 : WS_VISIBLE ),
                          hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ),
                          hParent, NULL, GetModuleHandle( NULL ), NULL );
   if( hWnd && hb_parl( 6 ) )
      SetProp( hWnd, SPLIT_VERTICAL, ( HANDLE ) 1 );
   HMG_retnl( ( LONG_PTR ) hWnd );
}

/* HMG_SPLITTERDRAG( hWnd ) -> lDragging (tests) */
HB_FUNC( HMG_SPLITTERDRAG )
{
   hb_retl( s_hDrag == ( HWND ) HMG_parnl( 1 ) );
}
