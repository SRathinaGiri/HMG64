/*
 * HMG5 5.2 - PLACEHOLDER: the grey hint text Windows shows in an empty TEXTBOX or COMBOBOX
 * (cue banner: EM_SETCUEBANNER / CB_SETCUEBANNER, common controls 6). h_placeholder.prg.
 *
 * HMG_SETCUEBANNER( hWnd, cText, lCombo ) -> lOk
 * HMG_GETCUEBANNER( hWnd, lCombo ) -> cText
 */

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <commctrl.h>
#include "hbapi.h"

#ifndef EM_SETCUEBANNER
   #define EM_SETCUEBANNER   0x1501
#endif
#ifndef EM_GETCUEBANNER
   #define EM_GETCUEBANNER   0x1502
#endif
#ifndef CB_SETCUEBANNER
   #define CB_SETCUEBANNER   0x1703
#endif
#ifndef CB_GETCUEBANNER
   #define CB_GETCUEBANNER   0x1704
#endif

HB_FUNC( HMG_SETCUEBANNER )
{
   HWND       hWnd = ( HWND ) HMG_parnl( 1 );
   HB_WCHAR * w    = hb_osStrU16Encode( hb_parc( 2 ) ? hb_parc( 2 ) : "" );
   LRESULT    r;

   if( hb_parl( 3 ) )
      r = SendMessageW( hWnd, CB_SETCUEBANNER, 0, ( LPARAM ) w );
   else   /* TRUE: still shown while the box has the focus, until something is typed */
      r = SendMessageW( hWnd, EM_SETCUEBANNER, ( WPARAM ) TRUE, ( LPARAM ) w );
   hb_xfree( w );
   InvalidateRect( hWnd, NULL, TRUE );
   hb_retl( r != 0 );
}

HB_FUNC( HMG_GETCUEBANNER )
{
   HWND  hWnd = ( HWND ) HMG_parnl( 1 );
   WCHAR w[ 512 ];
   char * p;

   w[ 0 ] = 0;
   if( hb_parl( 2 ) )
      SendMessageW( hWnd, CB_GETCUEBANNER, ( WPARAM ) w, ( LPARAM ) 511 );
   else
      SendMessageW( hWnd, EM_GETCUEBANNER, ( WPARAM ) w, ( LPARAM ) 511 );
   w[ 511 ] = 0;
   p = hb_osStrU16Decode( ( const HB_WCHAR * ) w );
   if( p )
      hb_retc_buffer( p );
   else
      hb_retc( "" );
}
