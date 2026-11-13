/*----------------------------------------------------------------------------
 HMG5 - dark mode (Phase 4 K, PHASE4-DESIGN.md section 3)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 Opt-in (SET DARKMODE ON | AUTO, before the first window). Without it every
 function here is a no-op. Pieces:

   - HMG_SysColor(): a dark palette for the system colours HMG uses as control
     defaults (COLOR_3DFACE, COLOR_WINDOW, COLOR_MENU, text colours). GETSYSCOLOR
     (used by Events() for every control without its own colours), the
     ROUNDED and modern-tab fallbacks go through it; explicit BACKCOLOR /
     FONTCOLOR still win.
   - WndProc (c_EventCB.c): on WM_CTLCOLOR* the DC gets dark defaults before
     Events() runs; if Events() does not answer, a dark brush is returned.
   - REGISTERWINDOW: forms without BACKCOLOR get a dark class brush.
   - a thread WH_CALLWNDPROCRET hook styles each window when its WM_CREATE
     returns, by class: dark title bar, dark themes (DarkMode_Explorer / _CFD /
     _ItemsView), list/tree colours, modern-drawn tabs, classic check boxes and
     radio buttons (themed ones ignore the text colour). Only windows inside an
     HMG form are touched: message boxes and common dialogs stay as Windows
     draws them.
   - popup menus follow the app mode (uxtheme ordinals 135/136, Windows 10 1903+;
     skipped when not present). The menu bar stays light.
---------------------------------------------------------------------------*/

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <commctrl.h>
#include <richedit.h>
#include <uxtheme.h>

#include "hbapi.h"
#include "hmg_dpi.h"

/* palette */
#define DK_BG       RGB(  32,  32,  32 )   /* forms, buttons face, labels          */
#define DK_INPUT    RGB(  45,  45,  45 )   /* edits, lists, grids (COLOR_WINDOW)   */
#define DK_MENU     RGB(  43,  43,  43 )   /* read-only edits (COLOR_MENU)         */
#define DK_TEXT     RGB( 235, 235, 235 )
#define DK_GRAY     RGB( 140, 140, 140 )
#define DK_STRIP    RGB(  24,  24,  24 )   /* tab strip behind the tabs            */
#define DK_EDGE     RGB(  80,  80,  80 )   /* border of text boxes, lists, grids   */
#define DK_EDGEFOCUS RGB(  0, 120, 215 )  /* ... while the control has the focus  */

typedef HRESULT ( WINAPI * PFN_DWMSETATTR )( HWND, DWORD, LPCVOID, DWORD );
typedef HRESULT ( WINAPI * PFN_SETWINDOWTHEME )( HWND, LPCWSTR, LPCWSTR );
typedef int     ( WINAPI * PFN_SETPREFERREDAPPMODE )( int );
typedef void    ( WINAPI * PFN_FLUSHMENUTHEMES )( void );
typedef BOOL    ( WINAPI * PFN_ALLOWDARKFORWINDOW )( HWND, BOOL );

static BOOL                   s_bDark      = FALSE;
static HHOOK                  s_hHook      = NULL;
static HBRUSH                 s_brBg       = NULL;
static HBRUSH                 s_brInput    = NULL;
static PFN_DWMSETATTR         s_pDwmAttr   = NULL;
static PFN_SETWINDOWTHEME     s_pSetTheme  = NULL;
static PFN_ALLOWDARKFORWINDOW s_pAllowWnd  = NULL;

BOOL HMG_TabApplyModern( HWND hTab, COLORREF cStrip, COLORREF cPill, COLORREF cText, COLORREF cTextSel );   /* c_tab.c */

/* ------------------------------------------------------------------------ */

BOOL HMG_DarkIsOn( void )
{
   return s_bDark;
}

COLORREF HMG_SysColor( int nIndex )
{
   if( s_bDark )
   {
      switch( nIndex )
      {
         case COLOR_3DFACE:          /* = COLOR_BTNFACE */
         case COLOR_APPWORKSPACE:
            return DK_BG;
         case COLOR_WINDOW:
         case COLOR_INFOBK:
            return DK_INPUT;
         case COLOR_MENU:
            return DK_MENU;
         case COLOR_WINDOWTEXT:
         case COLOR_BTNTEXT:
         case COLOR_MENUTEXT:
         case COLOR_INFOTEXT:
            return DK_TEXT;
         case COLOR_GRAYTEXT:
            return DK_GRAY;
      }
   }
   return GetSysColor( nIndex );
}

/* class brush for a form without BACKCOLOR (REGISTERWINDOW), NULL = keep COLOR_BTNFACE */
HBRUSH HMG_DarkFormBrush( void )
{
   return s_bDark ? CreateSolidBrush( DK_BG ) : NULL;
}

/* WM_CTLCOLOR*: dark defaults on the DC before Events() runs */
void HMG_DarkPrepareDC( UINT nMsg, HDC hDC )
{
   if( ! s_bDark || hDC == NULL )
      return;
   SetTextColor( hDC, DK_TEXT );
   SetBkColor( hDC, ( nMsg == WM_CTLCOLOREDIT || nMsg == WM_CTLCOLORLISTBOX ) ? DK_INPUT : DK_BG );
}

/* WM_CTLCOLOR* that Events() did not answer: a dark brush (shared, never deleted) */
HBRUSH HMG_DarkCtlBrush( UINT nMsg )
{
   if( ! s_bDark )
      return NULL;
   return ( nMsg == WM_CTLCOLOREDIT || nMsg == WM_CTLCOLORLISTBOX ) ? s_brInput : s_brBg;
}

/* ------------------------------------------------------------------------ */
/* Styling when a window is created                                          */
/* ------------------------------------------------------------------------ */

static void dk_theme( HWND h, LPCWSTR app, LPCWSTR ids )
{
   if( s_pAllowWnd )
      s_pAllowWnd( h, TRUE );            /* scroll bars follow the window's dark flag */
   if( s_pSetTheme )
      s_pSetTheme( h, app, ids );
}

static void dk_titleBar( HWND h )
{
   BOOL on = TRUE;
   if( s_pAllowWnd )
      s_pAllowWnd( h, TRUE );
   if( s_pDwmAttr && FAILED( s_pDwmAttr( h, 20 /* DWMWA_USE_IMMERSIVE_DARK_MODE */, &on, sizeof( on ) ) ) )
      s_pDwmAttr( h, 19 /* the same attribute on Windows 10 before 20H1 */, &on, sizeof( on ) );
}

/* Controls with WS_EX_CLIENTEDGE (text boxes, lists, grids, trees): Windows draws the
   2-pixel sunken edge with light system colours; it is painted over in dark grey after
   the default non-client painting (which also draws the scroll bars). */
#define DK_EDGE_ID  0x484D4B44

static LRESULT CALLBACK dk_EdgeProc( HWND h, UINT msg, WPARAM wParam, LPARAM lParam, UINT_PTR uId, DWORD_PTR dwRef )
{
   LRESULT r;

   HB_SYMBOL_UNUSED( dwRef );
   if( msg == WM_NCDESTROY )
   {
      RemoveWindowSubclass( h, dk_EdgeProc, uId );
      return DefSubclassProc( h, msg, wParam, lParam );
   }
   r = DefSubclassProc( h, msg, wParam, lParam );
   if( msg == WM_NCPAINT && ( GetWindowLongPtr( h, GWL_EXSTYLE ) & WS_EX_CLIENTEDGE ) )
   {
      HDC hdc = GetWindowDC( h );
      if( hdc )
      {
         RECT   rc;
         HBRUSH b1 = CreateSolidBrush( DK_EDGE );
         HBRUSH b2 = CreateSolidBrush( GetFocus() == h ? DK_EDGEFOCUS : DK_INPUT );
         GetWindowRect( h, &rc );
         OffsetRect( &rc, -rc.left, -rc.top );
         FrameRect( hdc, &rc, b1 );
         InflateRect( &rc, -1, -1 );
         FrameRect( hdc, &rc, b2 );
         DeleteObject( b1 );
         DeleteObject( b2 );
         ReleaseDC( h, hdc );
      }
   }
   else if( msg == WM_SETFOCUS || msg == WM_KILLFOCUS )
      RedrawWindow( h, NULL, NULL, RDW_FRAME | RDW_INVALIDATE );
   return r;
}

static void dk_style( HWND h )
{
   WCHAR    cls[ 64 ];
   HWND     hRoot;
   LONG_PTR style;

   if( GetClassNameW( h, cls, HB_SIZEOFARRAY( cls ) ) == 0 )
      return;

   /* tooltips are popups owned by the form */
   if( lstrcmpiW( cls, TOOLTIPS_CLASSW ) == 0 )
   {
      if( HMG_IsHmgForm( GetAncestor( h, GA_ROOTOWNER ) ) )
         dk_theme( h, L"DarkMode_Explorer", NULL );
      return;
   }

   hRoot = GetAncestor( h, GA_ROOT );
   if( ! HMG_IsHmgForm( hRoot ) )
      return;                                   /* message boxes, common dialogs */

   style = GetWindowLongPtr( h, GWL_STYLE );

   if( h != hRoot && ( GetWindowLongPtr( h, GWL_EXSTYLE ) & WS_EX_CLIENTEDGE ) )
      SetWindowSubclass( h, dk_EdgeProc, DK_EDGE_ID, 0 );

   if( h == hRoot )                             /* a top-level HMG form */
   {
      dk_titleBar( h );
      dk_theme( h, L"DarkMode_Explorer", NULL );   /* its scroll bars */
      return;
   }
   if( HMG_IsHmgForm( h ) )                      /* panel */
   {
      dk_theme( h, L"DarkMode_Explorer", NULL );
      return;
   }

   if( lstrcmpiW( cls, L"Button" ) == 0 )
   {
      switch( style & BS_TYPEMASK )
      {
         case BS_PUSHBUTTON:
         case BS_DEFPUSHBUTTON:
            dk_theme( h, L"DarkMode_Explorer", NULL );
            break;
         default:
            /* check box, radio, group box: themed ones draw their text black whatever
               WM_CTLCOLORSTATIC says; classic ones use the DC colours */
            dk_theme( h, L"", L"" );
      }
   }
   else if( lstrcmpiW( cls, L"Edit" ) == 0 )
      /* multi-line: the Explorer theme also darkens its scroll bars */
      dk_theme( h, ( style & ES_MULTILINE ) ? L"DarkMode_Explorer" : L"DarkMode_CFD", NULL );
   else if( lstrcmpiW( cls, L"ComboBox" ) == 0 )
      dk_theme( h, L"DarkMode_CFD", NULL );
   else if( lstrcmpiW( cls, L"ListBox" ) == 0 || lstrcmpiW( cls, L"ScrollBar" ) == 0 ||
            lstrcmpiW( cls, UPDOWN_CLASSW ) == 0 || lstrcmpiW( cls, L"ComboLBox" ) == 0 )
      dk_theme( h, L"DarkMode_Explorer", NULL );
   else if( lstrcmpiW( cls, WC_LISTVIEWW ) == 0 )
   {
      dk_theme( h, L"DarkMode_Explorer", NULL );
      ListView_SetBkColor( h, DK_INPUT );
      ListView_SetTextBkColor( h, DK_INPUT );
      ListView_SetTextColor( h, DK_TEXT );
   }
   else if( lstrcmpiW( cls, WC_HEADERW ) == 0 )
      dk_theme( h, L"DarkMode_ItemsView", NULL );
   else if( lstrcmpiW( cls, WC_TREEVIEWW ) == 0 )
   {
      dk_theme( h, L"DarkMode_Explorer", NULL );
      TreeView_SetBkColor( h, DK_INPUT );
      TreeView_SetTextColor( h, DK_TEXT );
   }
   else if( lstrcmpiW( cls, WC_TABCONTROLW ) == 0 )
      HMG_TabApplyModern( h, DK_STRIP, DK_BG, DK_GRAY, DK_TEXT );
   else if( _wcsnicmp( cls, L"RichEdit", 8 ) == 0 )
   {
      CHARFORMAT2W cf;
      SendMessageW( h, EM_SETBKGNDCOLOR, 0, ( LPARAM ) DK_INPUT );
      memset( &cf, 0, sizeof( cf ) );
      cf.cbSize      = sizeof( cf );
      cf.dwMask      = CFM_COLOR;
      cf.crTextColor = DK_TEXT;
      SendMessageW( h, EM_SETCHARFORMAT, SCF_ALL, ( LPARAM ) &cf );
      dk_theme( h, L"DarkMode_Explorer", NULL );
   }
}

static LRESULT CALLBACK dk_RetProc( int nCode, WPARAM wParam, LPARAM lParam )
{
   if( nCode == HC_ACTION && s_bDark )
   {
      const CWPRETSTRUCT * p = ( const CWPRETSTRUCT * ) lParam;
      if( p->message == WM_CREATE && p->lResult != -1 )
         dk_style( p->hwnd );
   }
   return CallNextHookEx( s_hHook, nCode, wParam, lParam );
}

/* ------------------------------------------------------------------------ */
/* Harbour API                                                               */
/* ------------------------------------------------------------------------ */

/* HMG_DARK_SYSTEMISDARK() -> lDark   Windows' "app mode" setting (Settings > Colours) */
HB_FUNC( HMG_DARK_SYSTEMISDARK )
{
   HKEY  hKey;
   DWORD val = 1, cb = sizeof( val ), type = 0;
   if( RegOpenKeyExW( HKEY_CURRENT_USER, L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
                      0, KEY_READ, &hKey ) == ERROR_SUCCESS )
   {
      if( RegQueryValueExW( hKey, L"AppsUseLightTheme", NULL, &type, ( LPBYTE ) &val, &cb ) != ERROR_SUCCESS || type != REG_DWORD )
         val = 1;
      RegCloseKey( hKey );
   }
   hb_retl( val == 0 );
}

/* HMG_DARK_ENABLE() -> lOn   switch dark mode on for this (the GUI) thread */
HB_FUNC( HMG_DARK_ENABLE )
{
   HMODULE hUx, hDwm;

   if( s_bDark )
   {
      hb_retl( HB_TRUE );
      return;
   }
   hUx  = HMG_LoadSystemLibrary( _TEXT( "uxtheme.dll" ) );
   hDwm = HMG_LoadSystemLibrary( _TEXT( "dwmapi.dll" ) );
   if( hUx )
   {
      OSVERSIONINFOW ov;
      s_pSetTheme = ( PFN_SETWINDOWTHEME ) ( void * ) GetProcAddress( hUx, "SetWindowTheme" );

      /* undocumented, used by Explorer and Notepad: only from 1903 (build 18362), where
         ordinal 135 is SetPreferredAppMode. RtlGetVersion is not shimmed. */
      memset( &ov, 0, sizeof( ov ) );
      ov.dwOSVersionInfoSize = sizeof( ov );
      {
         typedef LONG ( WINAPI * PFN_RTLGETVERSION )( OSVERSIONINFOW * );
         PFN_RTLGETVERSION pGet = ( PFN_RTLGETVERSION ) ( void * ) GetProcAddress( GetModuleHandleW( L"ntdll.dll" ), "RtlGetVersion" );
         if( pGet )
            pGet( &ov );
      }
      if( ov.dwMajorVersion >= 10 && ov.dwBuildNumber >= 18362 )
      {
         PFN_SETPREFERREDAPPMODE pMode  = ( PFN_SETPREFERREDAPPMODE ) ( void * ) GetProcAddress( hUx, MAKEINTRESOURCEA( 135 ) );
         PFN_FLUSHMENUTHEMES     pFlush = ( PFN_FLUSHMENUTHEMES ) ( void * ) GetProcAddress( hUx, MAKEINTRESOURCEA( 136 ) );
         s_pAllowWnd = ( PFN_ALLOWDARKFORWINDOW ) ( void * ) GetProcAddress( hUx, MAKEINTRESOURCEA( 133 ) );
         if( pMode )
            pMode( 2 /* ForceDark */ );
         if( pFlush )
            pFlush();
      }
   }
   if( hDwm )
      s_pDwmAttr = ( PFN_DWMSETATTR ) ( void * ) GetProcAddress( hDwm, "DwmSetWindowAttribute" );

   s_brBg    = CreateSolidBrush( DK_BG );
   s_brInput = CreateSolidBrush( DK_INPUT );
   s_hHook   = SetWindowsHookEx( WH_CALLWNDPROCRET, dk_RetProc, NULL, GetCurrentThreadId() );
   s_bDark   = ( s_hHook != NULL );
   hb_retl( s_bDark );
}

/* HMG_DARK_ISON() -> lOn */
HB_FUNC( HMG_DARK_ISON )
{
   hb_retl( s_bDark );
}

/* HMG_DARK_TITLEISDARK( hWnd ) -> lDark   (tests) */
HB_FUNC( HMG_DARK_TITLEISDARK )
{
   BOOL on = FALSE;
   typedef HRESULT ( WINAPI * PFN_DWMGETATTR )( HWND, DWORD, PVOID, DWORD );
   HMODULE hDwm = GetModuleHandleW( L"dwmapi.dll" );
   PFN_DWMGETATTR pGet = hDwm ? ( PFN_DWMGETATTR ) ( void * ) GetProcAddress( hDwm, "DwmGetWindowAttribute" ) : NULL;
   if( pGet && FAILED( pGet( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), 20, &on, sizeof( on ) ) ) )
      on = FALSE;
   hb_retl( on );
}

/* HMG_DARK_LISTVIEWBK( hWnd ) -> nColor   (tests) */
HB_FUNC( HMG_DARK_LISTVIEWBK )
{
   hb_retnl( ( long ) ListView_GetBkColor( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ) ) );
}

/* HMG_DARK_PIXEL( hWnd, x, y ) -> nColor   the colour at client point x,y as the window
   renders itself (PrintWindow, children included); -1 on failure. For tests. */
HB_FUNC( HMG_DARK_PIXEL )
{
   HWND     h = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   RECT     rc;
   HDC      hdc, hMem;
   HBITMAP  hBmp, hOld;
   COLORREF c = ( COLORREF ) -1;

   if( ! IsWindow( h ) || ! GetClientRect( h, &rc ) || rc.right <= 0 || rc.bottom <= 0 )
   {
      hb_retnl( -1 );
      return;
   }
   hdc  = GetDC( h );
   hMem = CreateCompatibleDC( hdc );
   hBmp = CreateCompatibleBitmap( hdc, rc.right, rc.bottom );
   hOld = ( HBITMAP ) SelectObject( hMem, hBmp );
   if( PrintWindow( h, hMem, PW_CLIENTONLY | 2 /* PW_RENDERFULLCONTENT */ ) )
      c = GetPixel( hMem, hb_parni( 2 ), hb_parni( 3 ) );
   SelectObject( hMem, hOld );
   DeleteObject( hBmp );
   DeleteDC( hMem );
   ReleaseDC( h, hdc );
   hb_retnl( c == CLR_INVALID ? -1 : ( long ) c );
}

/* HMG_DARK_REALSYSCOLOR( nIndex ) -> nColor   the Windows colour, bypassing the dark palette */
HB_FUNC( HMG_DARK_REALSYSCOLOR )
{
   hb_retnl( ( long ) GetSysColor( hb_parni( 1 ) ) );
}
