/*----------------------------------------------------------------------------
 HMG5 - per-monitor DPI (Phase 4 D, PHASE4-DESIGN.md section 2)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 Opt-in (SET DPIAWARE PERMONITOR, before the first window). Rule: every size
 and position a program or the PRG library sees is in DESIGN UNITS (pixels at
 96 DPI); this file converts at the Win32 boundary:

   - the GUI thread runs Per-Monitor-V2 aware (SetThreadDpiAwarenessContext;
     the manifest stays system-aware, so the default is unchanged);
   - a thread CBT hook scales windows as they are created: a child of an HMG
     form (position and size) and an HMG top-level form (size only; screen
     positions stay in pixels);
   - MOVEWINDOW / SETWINDOWPOS scale the same way; GETWINDOWWIDTH/HEIGHT,
     GETWINDOWRECT (size part), GETCLIENTAREAWIDTH/HEIGHT and the scrollbar
     metrics return design units;
   - fonts are sized with the DPI of the window they are set on;
   - WM_DPICHANGED: the form takes the suggested rectangle, then
     _HMG_DPIRESCALE() re-places every control from its stored design values.

 An "HMG form" is any window whose class uses HMG's WndProc (forms, panels,
 split children). Windows that comctl32 creates inside controls (combo edit,
 list headers, up-down of a spinner created by comctl32) have a control as
 parent, so they are never touched: they size themselves in real pixels.
---------------------------------------------------------------------------*/

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <commctrl.h>

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hmg_dpi.h"

#ifndef WM_DPICHANGED
#define WM_DPICHANGED 0x02E0
#endif

#define HMG_DPI_PROP  _TEXT( "HMG5_DPI" )

LRESULT CALLBACK WndProc( HWND hWnd, UINT nMsg, WPARAM wParam, LPARAM lParam );   /* c_EventCB.c */

typedef DPI_AWARENESS_CONTEXT ( WINAPI * PFN_SETTHREADDPICTX )( DPI_AWARENESS_CONTEXT );
typedef UINT ( WINAPI * PFN_GETDPIFORWINDOW )( HWND );
typedef int ( WINAPI * PFN_GETSYSMETRICSFORDPI )( int, UINT );
typedef HRESULT ( WINAPI * PFN_GETDPIFORMONITOR )( HMONITOR, int, UINT *, UINT * );

static BOOL                    s_bOn          = FALSE;
static DWORD                   s_dwThread     = 0;
static HHOOK                   s_hHook        = NULL;
static PFN_GETDPIFORWINDOW     s_pDpiForWnd   = NULL;
static PFN_GETSYSMETRICSFORDPI s_pMetricsDpi  = NULL;
static PFN_GETDPIFORMONITOR    s_pDpiForMon   = NULL;

/* ------------------------------------------------------------------------ */

static BOOL dpi_isForm( HWND h )
{
   return h != NULL && ( WNDPROC ) GetClassLongPtr( h, GCLP_WNDPROC ) == WndProc;
}

static BOOL dpi_isChild( HWND h )
{
   return ( GetWindowLongPtr( h, GWL_STYLE ) & WS_CHILD ) != 0;
}

/* DPI of an HMG form: the value it was created / last rescaled for */
static UINT dpi_formDpi( HWND hForm )
{
   UINT dpi = ( UINT ) ( HB_PTRUINT ) GetProp( hForm, HMG_DPI_PROP );
   if( dpi == 0 && s_pDpiForWnd )
      dpi = s_pDpiForWnd( hForm );
   return dpi ? dpi : 96;
}

static UINT dpi_monitorDpi( int x, int y )
{
   POINT pt;
   UINT  dx = 96, dy = 96;
   pt.x = ( x == CW_USEDEFAULT ) ? 0 : x;
   pt.y = ( y == CW_USEDEFAULT ) ? 0 : y;
   if( s_pDpiForMon &&
       SUCCEEDED( s_pDpiForMon( MonitorFromPoint( pt, MONITOR_DEFAULTTOPRIMARY ), 0 /* MDT_EFFECTIVE_DPI */, &dx, &dy ) ) )
      return dy ? dy : 96;
   return 96;
}

static int dpi_scale( int v, UINT dpi )   { return ( v == CW_USEDEFAULT ) ? v : MulDiv( v, ( int ) dpi, 96 ); }
static int dpi_unscale( int v, UINT dpi ) { return MulDiv( v, 96, ( int ) dpi ); }

/* How sizes of window h are converted: 0 = not at all, 1 = size only
   (top-level form), 2 = position and size (child of a form). *pDpi gets the DPI. */
static int dpi_scope( HWND h, UINT * pDpi )
{
   HWND hParent;

   if( ! s_bOn || h == NULL || GetWindowThreadProcessId( h, NULL ) != s_dwThread )
      return 0;
   if( dpi_isChild( h ) )
   {
      hParent = GetParent( h );
      if( dpi_isForm( hParent ) )
      {
         *pDpi = dpi_formDpi( hParent );
         return 2;
      }
      return 0;
   }
   if( dpi_isForm( h ) )
   {
      *pDpi = dpi_formDpi( h );
      return 1;
   }
   return 0;
}

/* exported for c_font.c: DPI to size a font for window h, 0 = old behaviour */
UINT HMG_DpiForFont( HWND h )
{
   UINT dpi = 0;
   HWND hForm;

   if( ! s_bOn || h == NULL )
      return 0;
   hForm = dpi_isForm( h ) ? h : GetParent( h );
   if( hForm && dpi_isForm( hForm ) )
      dpi = dpi_formDpi( hForm );
   return dpi;
}

BOOL HMG_DpiIsOn( void )
{
   return s_bOn;
}

/* ------------------------------------------------------------------------ */
/* Creation hook                                                             */
/* ------------------------------------------------------------------------ */

static LRESULT CALLBACK dpi_CbtProc( int nCode, WPARAM wParam, LPARAM lParam )
{
   if( nCode == HCBT_CREATEWND && s_bOn )
   {
      HWND             hNew = ( HWND ) wParam;
      LPCREATESTRUCT   cs   = ( ( LPCBT_CREATEWND ) lParam )->lpcs;

      if( ( cs->style & WS_CHILD ) && dpi_isForm( cs->hwndParent ) )
      {
         UINT dpi = dpi_formDpi( cs->hwndParent );
         if( dpi != 96 )
         {
            cs->x  = dpi_scale( cs->x, dpi );
            cs->y  = dpi_scale( cs->y, dpi );
            cs->cx = dpi_scale( cs->cx, dpi );
            cs->cy = dpi_scale( cs->cy, dpi );
         }
         if( dpi_isForm( hNew ) )                /* a panel: same DPI as its parent */
            SetProp( hNew, HMG_DPI_PROP, ( HANDLE ) ( HB_PTRUINT ) dpi );
      }
      else if( ! ( cs->style & WS_CHILD ) && dpi_isForm( hNew ) )
      {
         UINT dpi = dpi_monitorDpi( cs->x, cs->y );
         SetProp( hNew, HMG_DPI_PROP, ( HANDLE ) ( HB_PTRUINT ) dpi );
         if( dpi != 96 )
         {
            cs->cx = dpi_scale( cs->cx, dpi );
            cs->cy = dpi_scale( cs->cy, dpi );
         }
      }
   }
   return CallNextHookEx( s_hHook, nCode, wParam, lParam );
}

/* ------------------------------------------------------------------------ */
/* WndProc pre-handler (called from c_EventCB.c)                             */
/* ------------------------------------------------------------------------ */

BOOL HMG_DpiWndProc( HWND hWnd, UINT nMsg, WPARAM wParam, LPARAM lParam, LRESULT * pResult )
{
   if( nMsg == WM_NCDESTROY )
   {
      RemoveProp( hWnd, HMG_DPI_PROP );
      return FALSE;
   }
   if( nMsg == WM_DPICHANGED && s_bOn )
   {
      UINT   dpi = HIWORD( wParam );
      UINT   old = dpi_formDpi( hWnd );
      RECT * rc  = ( RECT * ) lParam;

      if( dpi == 0 )
         dpi = LOWORD( wParam );
      SetProp( hWnd, HMG_DPI_PROP, ( HANDLE ) ( HB_PTRUINT ) dpi );
      if( rc )
         SetWindowPos( hWnd, NULL, rc->left, rc->top, rc->right - rc->left, rc->bottom - rc->top,
                       SWP_NOZORDER | SWP_NOACTIVATE );
      {
         PHB_DYNS pSym = hb_dynsymFindName( "_HMG_DPIRESCALE" );
         if( pSym && hb_vmRequestReenter() )
         {
            hb_vmPushDynSym( pSym );
            hb_vmPushNil();
            hb_vmPushNumInt( ( HB_MAXINT ) ( HB_PTRUINT ) hWnd );
            hb_vmPushInteger( ( int ) old );
            hb_vmDo( 2 );
            hb_vmRequestRestore();
         }
      }
      *pResult = 0;
      return TRUE;
   }
   return FALSE;
}

/* ------------------------------------------------------------------------ */
/* Harbour API                                                               */
/* ------------------------------------------------------------------------ */

/* HMG_DPI_ENABLE() -> lOk   Per-Monitor-V2 for this (the GUI) thread. Windows 10 1703+. */
HB_FUNC( HMG_DPI_ENABLE )
{
   HMODULE hUser = GetModuleHandle( _TEXT( "user32.dll" ) );
   PFN_SETTHREADDPICTX pSet;

   if( s_bOn )
   {
      hb_retl( HB_TRUE );
      return;
   }
   pSet          = ( PFN_SETTHREADDPICTX ) ( void * ) GetProcAddress( hUser, "SetThreadDpiAwarenessContext" );
   s_pDpiForWnd  = ( PFN_GETDPIFORWINDOW ) ( void * ) GetProcAddress( hUser, "GetDpiForWindow" );
   s_pMetricsDpi = ( PFN_GETSYSMETRICSFORDPI ) ( void * ) GetProcAddress( hUser, "GetSystemMetricsForDpi" );
   {
      HMODULE hShcore = HMG_LoadSystemLibrary( _TEXT( "shcore.dll" ) );
      if( hShcore )
         s_pDpiForMon = ( PFN_GETDPIFORMONITOR ) ( void * ) GetProcAddress( hShcore, "GetDpiForMonitor" );
   }
   if( pSet == NULL || s_pDpiForWnd == NULL || pSet( DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 ) == NULL )
   {
      hb_retl( HB_FALSE );
      return;
   }
   s_dwThread = GetCurrentThreadId();
   s_hHook    = SetWindowsHookEx( WH_CBT, dpi_CbtProc, NULL, s_dwThread );
   s_bOn      = ( s_hHook != NULL );
   hb_retl( s_bOn );
}

/* HMG_DPI_ISON() -> lOn */
HB_FUNC( HMG_DPI_ISON )
{
   hb_retl( s_bOn );
}

/* HMG_DPI_FORMDPI( hForm [, nNewDpi ] ) -> nDpi   (96 when the mode is off) */
HB_FUNC( HMG_DPI_FORMDPI )
{
   HWND h = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   if( ! s_bOn || ! dpi_isForm( h ) )
   {
      hb_retni( 96 );
      return;
   }
   if( HB_ISNUM( 2 ) && hb_parni( 2 ) >= 48 )
      SetProp( h, HMG_DPI_PROP, ( HANDLE ) ( HB_PTRUINT ) ( UINT ) hb_parni( 2 ) );
   hb_retni( ( int ) dpi_formDpi( h ) );
}

/* HMG_DPI_SIMULATE( hForm, nDpi ) -> NIL   Runs the WM_DPICHANGED path as if the form
   moved to a monitor with nDpi (for tests: one-monitor machines cannot do it for real). */
HB_FUNC( HMG_DPI_SIMULATE )
{
   HWND    h   = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   UINT    dpi = ( UINT ) hb_parni( 2 );
   UINT    old;
   RECT    rc;
   LRESULT r;

   if( ! s_bOn || ! dpi_isForm( h ) || dpi < 48 )
      return;
   old = dpi_formDpi( h );
   GetWindowRect( h, &rc );
   rc.right  = rc.left + MulDiv( rc.right - rc.left, ( int ) dpi, ( int ) old );
   rc.bottom = rc.top + MulDiv( rc.bottom - rc.top, ( int ) dpi, ( int ) old );
   HMG_DpiWndProc( h, WM_DPICHANGED, MAKEWPARAM( dpi, dpi ), ( LPARAM ) &rc, &r );
}

/* HMG_DPI_SCALE( hWnd, n ) / HMG_DPI_UNSCALE( hWnd, n ): design units <-> pixels of the
   form hWnd (a form handle, or a control: its parent form). Unchanged when the mode is off. */
static UINT dpi_ofParam( int n )
{
   HWND h = ( HWND ) ( HB_PTRUINT ) hb_parnll( n );
   if( ! s_bOn || h == NULL )
      return 96;
   if( ! dpi_isForm( h ) )
      h = GetParent( h );
   return dpi_isForm( h ) ? dpi_formDpi( h ) : 96;
}

HB_FUNC( HMG_DPI_SCALE )
{
   hb_retni( dpi_scale( hb_parni( 2 ), dpi_ofParam( 1 ) ) );
}

HB_FUNC( HMG_DPI_UNSCALE )
{
   hb_retni( dpi_unscale( hb_parni( 2 ), dpi_ofParam( 1 ) ) );
}

/* HMG_DPI_RAWRECT( hWnd ) -> { left, top, right, bottom } in real pixels (tests, diagnostics) */
HB_FUNC( HMG_DPI_RAWRECT )
{
   RECT     rc = { 0, 0, 0, 0 };
   PHB_ITEM a  = hb_itemArrayNew( 4 );
   GetWindowRect( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), &rc );
   hb_arraySetNI( a, 1, rc.left );
   hb_arraySetNI( a, 2, rc.top );
   hb_arraySetNI( a, 3, rc.right );
   hb_arraySetNI( a, 4, rc.bottom );
   hb_itemReturnRelease( a );
}

/* HMG_DPI_FONTHEIGHT( hWnd ) -> lfHeight of the window's current font (0 if none) */
HB_FUNC( HMG_DPI_FONTHEIGHT )
{
   HFONT   hf = ( HFONT ) SendMessage( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), WM_GETFONT, 0, 0 );
   LOGFONT lf;
   if( hf && GetObject( hf, sizeof( lf ), &lf ) )
      hb_retni( lf.lfHeight );
   else
      hb_retni( 0 );
}

/* HMG_DPI_REFONT( hWnd, nOldDpi, nNewDpi [, nPointSize ] ) -> hNewFont (0 if the window has no font)
   Creates the window's current font again for nNewDpi (same face, weight, style) and sets it.
   With nPointSize the height is exact (-size*dpi/72, as PrepareFont); otherwise the current
   height is scaled. The old font is not deleted: the caller owns it. */
HB_FUNC( HMG_DPI_REFONT )
{
   HWND    h     = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   int     nOld  = hb_parni( 2 );
   int     nNew  = hb_parni( 3 );
   HFONT   hf    = ( HFONT ) SendMessage( h, WM_GETFONT, 0, 0 );
   HFONT   hNew  = NULL;
   LOGFONT lf;

   if( hf && nOld > 0 && nNew > 0 && GetObject( hf, sizeof( lf ), &lf ) )
   {
      if( HB_ISNUM( 4 ) && hb_parni( 4 ) > 0 )
         lf.lfHeight = -( ( hb_parni( 4 ) * nNew ) / 72 );
      else
         lf.lfHeight = MulDiv( lf.lfHeight, nNew, nOld );
      lf.lfWidth = 0;
      hNew = CreateFontIndirect( &lf );
      if( hNew )
         SendMessage( h, WM_SETFONT, ( WPARAM ) hNew, TRUE );
   }
   hb_retnll( ( HB_LONGLONG ) ( HB_PTRUINT ) hNew );
}

/* ------------------------------------------------------------------------ */
/* Helpers for c_windows.c                                                   */
/* ------------------------------------------------------------------------ */

/* scale the arguments of a MoveWindow / SetWindowPos on h */
void HMG_DpiScaleRect( HWND h, int * x, int * y, int * w, int * hgt, BOOL bMove, BOOL bSize )
{
   UINT dpi = 96;
   int  scope = dpi_scope( h, &dpi );
   if( scope == 0 || dpi == 96 )
      return;
   if( scope == 2 && bMove )
   {
      *x = dpi_scale( *x, dpi );
      *y = dpi_scale( *y, dpi );
   }
   if( bSize )
   {
      *w   = dpi_scale( *w, dpi );
      *hgt = dpi_scale( *hgt, dpi );
   }
}

/* a design-unit size inside window h (e.g. a list-view column) -> pixels; negative values
   (LVSCW_AUTOSIZE and similar codes) pass through */
int HMG_DpiScaleSize( HWND h, int v )
{
   UINT dpi = 96;
   if( v <= 0 || dpi_scope( h, &dpi ) == 0 || dpi == 96 )
      return v;
   return dpi_scale( v, dpi );
}

/* HMG_DPI_RESCALECOLUMNS( hListView, nOldDpi, nNewDpi ) -> NIL   column widths for a DPI change */
HB_FUNC( HMG_DPI_RESCALECOLUMNS )
{
   HWND h    = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   int  nOld = hb_parni( 2 ), nNew = hb_parni( 3 ), n, i;
   HWND hHdr = ListView_GetHeader( h );

   if( hHdr == NULL || nOld <= 0 || nNew <= 0 || nOld == nNew )
      return;
   n = Header_GetItemCount( hHdr );
   for( i = 0; i < n; i++ )
      ListView_SetColumnWidth( h, i, MulDiv( ListView_GetColumnWidth( h, i ), nNew, nOld ) );
}

/* a real-pixel size of h -> design units (unchanged when h is not in scope) */
int HMG_DpiUnscaleSize( HWND h, int v )
{
   UINT dpi = 96;
   if( dpi_scope( h, &dpi ) == 0 || dpi == 96 )
      return v;
   return dpi_unscale( v, dpi );
}

/* client-area size of a form -> design units */
int HMG_DpiUnscaleClient( HWND h, int v )
{
   if( ! s_bOn || ! dpi_isForm( h ) )
      return v;
   return dpi_unscale( v, dpi_formDpi( h ) );
}

/* a system metric in design units: the value Windows uses at 96 DPI */
int HMG_DpiSystemMetric( int nIndex )
{
   if( s_bOn && s_pMetricsDpi )
      return s_pMetricsDpi( nIndex, 96 );
   return GetSystemMetrics( nIndex );
}
