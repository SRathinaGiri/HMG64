/*
 * HMG5 5.2 - files dropped from Explorer: ON DROPFILES (h_dropfiles.prg).
 *
 * HMG_DROPFILESREGISTER( hWnd, lOn ): the window or control accepts dropped files
 * (DragAcceptFiles, WS_EX_ACCEPTFILES) or stops. A drop arrives as WM_DROPFILES; the
 * subclass reads the paths (DragQueryFileW) and hands them to Harbour:
 * _HMG_DROPFILESEVENT( hWnd, aFiles ). No OLE. A drop on a child without its own
 * registration goes to the nearest parent that has one (Windows does that).
 * The program may run elevated: the drop messages are let through UIPI.
 */

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <shellapi.h>
#include <commctrl.h>
#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"

#define HMG_DROPFILES_ID   0x484D4446u

#ifndef MSGFLT_ALLOW
   #define MSGFLT_ALLOW    1
#endif
#ifndef WM_COPYGLOBALDATA
   #define WM_COPYGLOBALDATA   0x0049
#endif

static void dropfiles_event( HWND hWnd, HDROP hDrop )
{
   UINT     n = DragQueryFileW( hDrop, 0xFFFFFFFF, NULL, 0 ), i;
   PHB_ITEM pFiles = hb_itemArrayNew( n );
   PHB_DYNS pSym;

   for( i = 0; i < n; i++ )
   {
      UINT    nLen = DragQueryFileW( hDrop, i, NULL, 0 );
      WCHAR * w    = ( WCHAR * ) hb_xgrab( ( nLen + 1 ) * sizeof( WCHAR ) );
      char *  p;
      DragQueryFileW( hDrop, i, w, nLen + 1 );
      w[ nLen ] = 0;
      p = hb_osStrU16Decode( ( const HB_WCHAR * ) w );
      if( p )
         hb_arraySetCLPtr( pFiles, i + 1, p, strlen( p ) );
      else
         hb_arraySetC( pFiles, i + 1, "" );
      hb_xfree( w );
   }
   DragFinish( hDrop );

   pSym = hb_dynsymFindName( "_HMG_DROPFILESEVENT" );
   if( pSym && hb_vmRequestReenter() )
   {
      hb_vmPushDynSym( pSym );
      hb_vmPushNil();
      hb_vmPushNumInt( ( HB_MAXINT ) ( HB_PTRUINT ) hWnd );
      hb_vmPush( pFiles );
      hb_vmDo( 2 );
      hb_vmRequestRestore();
   }
   hb_itemRelease( pFiles );
}

static LRESULT CALLBACK dropfiles_proc( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam, UINT_PTR uId, DWORD_PTR dwRef )
{
   ( void ) dwRef;
   if( uMsg == WM_DROPFILES )
   {
      dropfiles_event( hWnd, ( HDROP ) wParam );
      return 0;
   }
   if( uMsg == WM_NCDESTROY )
      RemoveWindowSubclass( hWnd, dropfiles_proc, uId );
   return DefSubclassProc( hWnd, uMsg, wParam, lParam );
}

typedef BOOL ( WINAPI * PCHANGEFILTEREX )( HWND, UINT, DWORD, void * );

/* HMG_DROPFILESREGISTER( hWnd, lOn ) -> lOk */
HB_FUNC( HMG_DROPFILESREGISTER )
{
   HWND hWnd = ( HWND ) HMG_parnl( 1 );
   BOOL bOn  = hb_parldef( 2, HB_TRUE );

   if( ! IsWindow( hWnd ) )
   {
      hb_retl( HB_FALSE );
      return;
   }
   if( bOn )
   {
      static PCHANGEFILTEREX s_pFilter = NULL;
      static BOOL            s_bLooked = FALSE;
      if( ! s_bLooked )
      {
         s_pFilter = ( PCHANGEFILTEREX ) ( void * ) GetProcAddress( GetModuleHandleW( L"user32.dll" ), "ChangeWindowMessageFilterEx" );
         s_bLooked = TRUE;
      }
      if( s_pFilter )   /* an elevated program still gets drops from Explorer */
      {
         s_pFilter( hWnd, WM_DROPFILES, MSGFLT_ALLOW, NULL );
         s_pFilter( hWnd, WM_COPYDATA, MSGFLT_ALLOW, NULL );
         s_pFilter( hWnd, WM_COPYGLOBALDATA, MSGFLT_ALLOW, NULL );
      }
      SetWindowSubclass( hWnd, dropfiles_proc, HMG_DROPFILES_ID, 0 );
      DragAcceptFiles( hWnd, TRUE );
   }
   else
   {
      DragAcceptFiles( hWnd, FALSE );
      RemoveWindowSubclass( hWnd, dropfiles_proc, HMG_DROPFILES_ID );
   }
   hb_retl( HB_TRUE );
}
