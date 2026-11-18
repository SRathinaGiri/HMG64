/*
 * Unit test for ON DROPFILES (HMG5 5.2, h_dropfiles.prg, c_dropfiles.c). No real drag: a
 * drop package (HDROP, as Explorer delivers it) is built and sent as WM_DROPFILES to the
 * window or control, which is what Windows does when the mouse is released over it.
 */
#include "hmg.ch"

#define GWL_EXSTYLE        ( -20 )
#define WS_EX_ACCEPTFILES  0x00000010

STATIC s_nPass := 0, s_nFail := 0
STATIC s_cWho := "", s_aGot := NIL

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "dropfiles: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 60, 60 WIDTH 600 HEIGHT 400 TITLE "dropfiles test" MAIN ON INIT RunChecks()
      ON DROPFILES ACTION Got( "window " + ThisWindow.Name )
      @ 20, 20 TEXTBOX Txt_A WIDTH 300 HEIGHT 24
      ON DROPFILES CONTROL Txt_A ACTION Got( "control " + This.Name )
      @ 60, 20 TEXTBOX Txt_B WIDTH 300 HEIGHT 24
      @ 100, 20 GRID Grid_1 WIDTH 300 HEIGHT 150 HEADERS { "File" } WIDTHS { 280 }
   END WINDOW
   Win_1.Activate
RETURN NIL

STATIC PROCEDURE Got( cWho )
   s_cWho := cWho
   s_aGot := This.DroppedFiles
RETURN

STATIC FUNCTION Drop( hWnd, aFiles )
   s_cWho := ""
   s_aGot := NIL
   SENDDROP( hWnd, aFiles )
RETURN s_cWho

STATIC FUNCTION Accepts( hWnd )
RETURN hb_bitAnd( GETWINDOWLONG_EX( hWnd ), WS_EX_ACCEPTFILES ) != 0

STATIC PROCEDURE RunChecks()
   LOCAL aFiles := { "C:\data\sales 2026.xlsx", 'D:\reports\a,b "q".txt' }
   LOCAL cUni := iif( HMG_SupportUnicode(), "C:\नमस्ते\₹ bill.pdf", "C:\caf" + Chr( 233 ) + "\bill.pdf" )
   LOCAL hWin := GetFormHandle( "Win_1" ), hA := GetControlHandle( "Txt_A", "Win_1" )
   LOCAL hB := GetControlHandle( "Txt_B", "Win_1" ), hG := GetControlHandle( "Grid_1", "Win_1" )

   Check( "the window accepts files", Accepts( hWin ) )
   Check( "the control with ON DROPFILES accepts files", Accepts( hA ) )
   Check( "a control without stays as it was (its drops go to the window)", ! Accepts( hB ) )

   Check( "a drop on the window runs the window's action", Drop( hWin, aFiles ) == "window Win_1" )
   Check( "This.DroppedFiles holds the paths", HB_ISARRAY( s_aGot ) .AND. Len( s_aGot ) == 2 .AND. ;
          s_aGot[ 1 ] == aFiles[ 1 ] .AND. s_aGot[ 2 ] == aFiles[ 2 ] )
   Check( "a drop on the control runs the control's action", Drop( hA, { cUni } ) == "control Txt_A" )
   Check( "a path beyond ASCII", HB_ISARRAY( s_aGot ) .AND. Len( s_aGot ) == 1 .AND. s_aGot[ 1 ] == cUni )
   Check( "outside an action This.DroppedFiles is empty", Len( This.DroppedFiles ) == 0 )

   // after the window is defined, for a control
   ON DROPFILES OF Win_1 CONTROL Grid_1 ACTION Got( "grid " + This.Name )
   Check( "ON DROPFILES OF ... CONTROL after END WINDOW", Accepts( hG ) .AND. Drop( hG, { "x.csv" } ) == "grid Grid_1" )

   // released
   RELEASE DROPFILES OF Win_1 CONTROL Txt_A
   Check( "RELEASE DROPFILES: the control no longer accepts", ! Accepts( hA ) .AND. Drop( hA, { "y" } ) == "" )
   Check( "the window still does", Accepts( hWin ) .AND. Drop( hWin, { "z" } ) == "window Win_1" )
   RELEASE DROPFILES OF Win_1
   Check( "RELEASE DROPFILES OF the window", ! Accepts( hWin ) .AND. Drop( hWin, { "z" } ) == "" )

   // the function form
   HMG_DropFiles( "Win_1", "Txt_B", {|| Got( "function " + This.Name ) } )
   Check( "HMG_DropFiles()", Accepts( hB ) .AND. Drop( hB, { "w" } ) == "function Txt_B" )

   OutStd( "dropfiles: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "dropfiles: FAIL " + cName + hb_eol() )
   ENDIF
RETURN

#pragma BEGINDUMP
#include <windows.h>
#include <shlobj.h>
#include "hbapi.h"

/* SENDDROP( hWnd, aFiles ): a drop package (DROPFILES + the wide paths, double 0) sent as
   WM_DROPFILES; the receiver frees it with DragFinish, or it is freed here if nobody did */
HB_FUNC( SENDDROP )
{
   HWND     hWnd = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   PHB_ITEM pArr = hb_param( 2, HB_IT_ARRAY );
   HB_SIZE  i, n = pArr ? hb_arrayLen( pArr ) : 0, nChars = 1;
   WCHAR ** aw = ( WCHAR ** ) hb_xgrab( sizeof( WCHAR * ) * ( n + 1 ) );
   HGLOBAL  hg;
   char *   p;
   WCHAR *  pw;
   for( i = 0; i < n; i++ )
   {
      aw[ i ] = ( WCHAR * ) hb_osStrU16Encode( hb_arrayGetCPtr( pArr, i + 1 ) );
      nChars += wcslen( aw[ i ] ) + 1;
   }
   hg = GlobalAlloc( GHND, sizeof( DROPFILES ) + nChars * sizeof( WCHAR ) );
   p  = ( char * ) GlobalLock( hg );
   ( ( DROPFILES * ) p )->pFiles = sizeof( DROPFILES );
   ( ( DROPFILES * ) p )->fWide  = TRUE;
   pw = ( WCHAR * ) ( p + sizeof( DROPFILES ) );
   for( i = 0; i < n; i++ )
   {
      wcscpy( pw, aw[ i ] );
      pw += wcslen( aw[ i ] ) + 1;
      hb_xfree( aw[ i ] );
   }
   *pw = 0;
   GlobalUnlock( hg );
   hb_xfree( aw );
   SendMessageW( hWnd, WM_DROPFILES, ( WPARAM ) hg, 0 );
   if( GlobalFlags( hg ) != GMEM_INVALID_HANDLE )   /* not taken (DragFinish frees it) */
      GlobalFree( hg );
}

HB_FUNC( GETWINDOWLONG_EX )
{
   hb_retnll( ( HB_LONGLONG ) GetWindowLongPtrW( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), GWL_EXSTYLE ) );
}
#pragma ENDDUMP
