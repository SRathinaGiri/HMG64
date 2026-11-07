/*
 * c_menuhover.c - open menu-bar popups on mouse hover (HMG5)
 *
 * From HMG 3.7 (Oct 2026), where it lived in c_windows.c. Used by h_menuhover.prg
 * (SET MENUHOVER / SetMenuBarHover). Opt-in per window; nothing here runs unless a
 * program turns it on.
 *
 * Why the popup is opened with TrackPopupMenu: synthesising a click on the menu bar
 * does not put the window into menu mode (3.7 measured this; the ALT key does, posted
 * messages do not). TrackPopupMenu is modal, so while the popup is open no
 * WM_NCMOUSEMOVE reaches Events; WM_TIMER still does, which is how the PRG side
 * slides between bar items and closes the popup when the mouse leaves.
 *
 * HMG5 changes against 3.7:
 *  - the bar item is highlighted with HiliteMenuItem (documented user32 API) instead of
 *    the undocumented MenuSelect export looked up at run time;
 *  - comments translated to English; HB_FUNC names and parameters unchanged.
 *
 * Released under the HMG licence, as the rest of HMG.
 */

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <windowsx.h>
#include "hbapi.h"


//        MenubarHitIndex ( hWnd, nLParam ) --> nIndex | -1
//  nLParam is the raw WM_NCMOUSEMOVE lParam (screen coordinates). Returns the
//  zero-based index of the top-level menu item under that point, or -1.
HB_FUNC ( MENUBARHITINDEX )
{
   HWND   hWnd   = (HWND) HMG_parnl ( 1 );
   LPARAM lParam = (LPARAM) HMG_parnl ( 2 );
   HMENU  hMenu  = GetMenu ( hWnd );
   POINT  pt;
   int    n, nCount;

   if ( hMenu != NULL )
   {
      pt.x = GET_X_LPARAM ( lParam );
      pt.y = GET_Y_LPARAM ( lParam );
      nCount = GetMenuItemCount ( hMenu );
      for ( n = 0; n < nCount; n++ )
      {
         RECT rc;
         if ( GetMenuItemRect ( hWnd, hMenu, (UINT) n, &rc ) && PtInRect ( &rc, pt ) )
         {
            hb_retni ( n );
            return;
         }
      }
   }

   hb_retni ( -1 );
}


//        MenubarOpenPopup ( hWnd, nIndex ) --> nCommand
//  Drops down the popup of bar item nIndex and blocks while the user is in it.
//  TPM_RETURNCMD stops the system from sending the command, so it is posted here as
//  WM_COMMAND and HMG dispatches the MENUITEM action exactly as for a real click.
//  0 = closed without a choice (or the item has no popup).
HB_FUNC ( MENUBAROPENPOPUP )
{
   HWND  hWnd   = (HWND) HMG_parnl ( 1 );
   int   nItem  = hb_parni ( 2 );
   HMENU hMenu  = GetMenu ( hWnd );
   HMENU hPopup = NULL;
   RECT  rc;
   int   nCmd   = 0;

   if ( hMenu != NULL && nItem >= 0 && GetMenuItemRect ( hWnd, hMenu, (UINT) nItem, &rc ) )
      hPopup = GetSubMenu ( hMenu, nItem );

   if ( hPopup != NULL )
   {
      HiliteMenuItem ( hWnd, hMenu, (UINT) nItem, MF_BYPOSITION | MF_HILITE );
      nCmd = (int) TrackPopupMenu ( hPopup,
               TPM_LEFTALIGN | TPM_TOPALIGN | TPM_LEFTBUTTON | TPM_RETURNCMD,
               rc.left, rc.bottom, 0, hWnd, NULL );
      HiliteMenuItem ( hWnd, hMenu, (UINT) nItem, MF_BYPOSITION | MF_UNHILITE );
      if ( nCmd != 0 )
         PostMessage ( hWnd, WM_COMMAND, (WPARAM) nCmd, 0 );
   }

   hb_retni ( nCmd );
}


//        MenubarCursorPoint () --> nLParam
//  Current cursor position packed like an NC mouse lParam, so it can go back into
//  MenubarHitIndex (sliding from one popup to the next).
HB_FUNC ( MENUBARCURSORPOINT )
{
   POINT pt;

   if ( GetCursorPos ( &pt ) )
      hb_retnl ( (long) MAKELONG ( (WORD) pt.x, (WORD) pt.y ) );
   else
      hb_retnl ( 0L );
}


//        MenubarPointInWindow ( hWnd, nLParam ) --> lInside
//  Guard: the screen point must be over this window (or one of its children), so
//  hovering another application that overlaps it does not open anything.
HB_FUNC ( MENUBARPOINTINWINDOW )
{
   HWND  hWnd = (HWND) HMG_parnl ( 1 );
   POINT pt;
   HWND  hWndPoint;

   pt.x = GET_X_LPARAM ( (LPARAM) HMG_parnl ( 2 ) );
   pt.y = GET_Y_LPARAM ( (LPARAM) HMG_parnl ( 2 ) );

   hWndPoint = WindowFromPoint ( pt );

   hb_retl ( hWndPoint != NULL && ( hWndPoint == hWnd || GetAncestor ( hWndPoint, GA_ROOT ) == hWnd ) );
}


// A popup menu window has the system class "#32768".
static BOOL HMG_IsMenuWindow ( HWND hWnd )
{
   WCHAR szClass[ 16 ];

   if ( hWnd == NULL )
      return FALSE;

   return GetClassNameW ( hWnd, szClass, 16 ) > 0 && lstrcmpW ( szClass, L"#32768" ) == 0;
}


//        MenubarPointInMenu ( nLParam ) --> lInside
//  .T. when the point is over the open popup or any open submenu. This is a z-order
//  hit test: if another window covers the popup it answers .F. even with the cursor
//  inside, which is the TOPMOST-owner case handled by MenubarKeepPopupOnTop. (3.7
//  tried comparing the popup's owner with hWnd; for a TrackPopupMenu popup neither
//  GW_OWNER nor GA_ROOT returns the owner, so that test cannot work.)
HB_FUNC ( MENUBARPOINTINMENU )
{
   POINT pt;

   pt.x = GET_X_LPARAM ( (LPARAM) HMG_parnl ( 1 ) );
   pt.y = GET_Y_LPARAM ( (LPARAM) HMG_parnl ( 1 ) );

   hb_retl ( HMG_IsMenuWindow ( WindowFromPoint ( pt ) ) );
}


typedef struct { POINT pt; int nRaised; } HMG_RAISE_CTX;

static BOOL CALLBACK HMG_RaisePopupCB ( HWND hWnd, LPARAM lParam )
{
   HMG_RAISE_CTX * pCtx = ( HMG_RAISE_CTX * ) lParam;
   RECT            rc;

   if ( HMG_IsMenuWindow ( hWnd ) && GetWindowRect ( hWnd, &rc ) && PtInRect ( &rc, pCtx->pt ) )
   {
      SetWindowPos ( hWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE );
      pCtx->nRaised++;
   }

   return TRUE;
}


//        MenubarKeepPopupOnTop ( nLParam ) --> nRaised
//  When the owner window is TOPMOST, the popup (also created topmost by the system)
//  can end up below its owner; 3.7 measured WindowFromPoint switching from #32768 to
//  the form within ~20 ms while the popup was still open, so the watcher read "cursor
//  left" and closed the menu. This re-asserts the z-order of this thread's menu
//  windows that cover the point. Only meaningful inside TrackPopupMenu's modal loop.
HB_FUNC ( MENUBARKEEPPOPUPONTOP )
{
   HMG_RAISE_CTX ctx;

   ctx.pt.x    = GET_X_LPARAM ( (LPARAM) HMG_parnl ( 1 ) );
   ctx.pt.y    = GET_Y_LPARAM ( (LPARAM) HMG_parnl ( 1 ) );
   ctx.nRaised = 0;

   if ( ! HMG_IsMenuWindow ( WindowFromPoint ( ctx.pt ) ) )
      EnumThreadWindows ( GetCurrentThreadId (), HMG_RaisePopupCB, ( LPARAM ) &ctx );

   hb_retni ( ctx.nRaised );
}


//        MenubarMenuActive () --> lActive
//  Guard: .T. when the thread is already in menu mode (a real click on the bar), so
//  our own TrackPopupMenu is not nested inside the system's menu loop.
HB_FUNC ( MENUBARMENUACTIVE )
{
   GUITHREADINFO gti;

   gti.cbSize = sizeof ( gti );
   if ( GetGUIThreadInfo ( GetCurrentThreadId (), &gti ) && ( gti.flags & ( GUI_INMENUMODE | GUI_POPUPMENUMODE ) ) )
      hb_retl ( TRUE );
   else
      hb_retl ( HMG_IsMenuWindow ( GetForegroundWindow () ) );
}


//        MenubarEndMenu () --> lOk
//  Ends TrackPopupMenu's modal loop from inside the thread (the only documented way).
HB_FUNC ( MENUBARENDMENU )
{
   hb_retl ( EndMenu () );
}


//        MenubarElapsedMs ( nStart ) --> nMilliseconds
//  Unsigned 32-bit difference, so it stays right when GetTickCount wraps (~49 days).
//  MenubarElapsedMs( 0 ) returns the current tick count as the start value. Real time
//  is needed for the hover delay: a fast sweep across the bar sends dozens of
//  WM_NCMOUSEMOVE in 20 ms, so counting messages alone opened popups in passing.
HB_FUNC ( MENUBARELAPSEDMS )
{
   hb_retnl ( (long) ( GetTickCount () - (DWORD) hb_parnl ( 1 ) ) );
}
