/*
 * Unit test for PLACEHOLDER (HMG5 5.2, h_placeholder.prg, c_placeholder.c): the hint text
 * of an empty TEXTBOX or COMBOBOX, as a clause (@ and DEFINE forms, inside a TAB page) and
 * as the Placeholder property. Windows must also draw it: the empty box is captured
 * (PrintWindow) with and without a hint, and the hint adds pixels.
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "placeholder: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 60, 60 WIDTH 700 HEIGHT 460 TITLE "placeholder test" MAIN ON INIT RunChecks()
      @ 10, 10 TEXTBOX Txt_Search WIDTH 250 HEIGHT 24 PLACEHOLDER "Search customers..."
      @ 40, 10 TEXTBOX Txt_Plain WIDTH 250 HEIGHT 24
      @ 70, 10 TEXTBOX Txt_Num WIDTH 250 HEIGHT 24 NUMERIC PLACEHOLDER "Amount"
      @ 100, 10 COMBOBOX Cmb_List WIDTH 250 ITEMS { "Chennai", "Mumbai" } PLACEHOLDER "Choose a city"
      @ 130, 10 COMBOBOX Cmb_Edit WIDTH 250 ITEMS { "Red", "Blue" } DISPLAYEDIT PLACEHOLDER "Type or choose"

      DEFINE TEXTBOX Txt_Def
         ROW 160
         COL 10
         WIDTH 250
         HEIGHT 24
         PLACEHOLDER "From DEFINE"
      END TEXTBOX
      DEFINE COMBOBOX Cmb_Def
         ROW 190
         COL 10
         WIDTH 250
         ITEMS { "a", "b" }
         PLACEHOLDER "Combo from DEFINE"
      END COMBOBOX
      DEFINE TEXTBOX Txt_DefNone
         ROW 220
         COL 10
         WIDTH 250
         HEIGHT 24
      END TEXTBOX

      DEFINE TAB Tab_1 AT 10, 300 WIDTH 360 HEIGHT 200
         PAGE "One"
            @ 40, 20 TEXTBOX Txt_InTab WIDTH 250 HEIGHT 24 PLACEHOLDER "Inside a tab"
         END PAGE
      END TAB
   END WINDOW
   Win_1.Activate
RETURN NIL

STATIC PROCEDURE RunChecks()
   LOCAL cUni := iif( HMG_SupportUnicode(), "खोजें ₹ Ünï", "Sch" + Chr( 252 ) + "ssel" ), nWith, nWithout

   Check( "@ TEXTBOX ... PLACEHOLDER", Win_1.Txt_Search.Placeholder == "Search customers..." )
   Check( "a TEXTBOX without one", Win_1.Txt_Plain.Placeholder == "" )
   Check( "NUMERIC TEXTBOX", Win_1.Txt_Num.Placeholder == "Amount" )
   Check( "COMBOBOX (list)", Win_1.Cmb_List.Placeholder == "Choose a city" )
   Check( "COMBOBOX DISPLAYEDIT", Win_1.Cmb_Edit.Placeholder == "Type or choose" )
   Check( "DEFINE TEXTBOX ... PLACEHOLDER", Win_1.Txt_Def.Placeholder == "From DEFINE" )
   Check( "DEFINE COMBOBOX ... PLACEHOLDER", Win_1.Cmb_Def.Placeholder == "Combo from DEFINE" )
   Check( "a DEFINE TEXTBOX after them has none", Win_1.Txt_DefNone.Placeholder == "" )
   Check( "inside a TAB page", Win_1.Txt_InTab.Placeholder == "Inside a tab" )

   Win_1.Txt_Plain.Placeholder := cUni
   Check( "the property sets it (text beyond ASCII)", Win_1.Txt_Plain.Placeholder == cUni )
   Win_1.Cmb_List.Placeholder := "Pick one"
   Check( "the property on a COMBOBOX", Win_1.Cmb_List.Placeholder == "Pick one" )

   // Windows draws it: an empty box with a hint has more ink than the same box without
   Win_1.Txt_Plain.Placeholder := ""
   nWithout := INKPIXELS( GetControlHandle( "Txt_Plain", "Win_1" ) )
   Win_1.Txt_Plain.Placeholder := "WWWWWWWWWW"
   nWith := INKPIXELS( GetControlHandle( "Txt_Plain", "Win_1" ) )
   Check( "Windows draws the hint (" + hb_ntos( nWithout ) + " -> " + hb_ntos( nWith ) + " pixels)", nWith > nWithout + 30 )
   Win_1.Txt_Plain.Value := "typed"
   Check( "typed text replaces it", INKPIXELS( GetControlHandle( "Txt_Plain", "Win_1" ) ) != nWith )

   OutStd( "placeholder: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "placeholder: FAIL " + cName + hb_eol() )
   ENDIF
RETURN

#pragma BEGINDUMP
#include <windows.h>
#include "hbapi.h"

/* INKPIXELS( hWnd ) -> the pixels inside the control that differ from the colour just
   inside its border (the background), from a capture of its whole window (PrintWindow
   with full content: a single edit control does not render itself this way) */
HB_FUNC( INKPIXELS )
{
   HWND    hWnd  = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   HWND    hRoot = GetAncestor( hWnd, GA_ROOT );
   RECT    rcRoot, rcCtl;
   HDC     hScreen, hMem;
   HBITMAP hBmp, hOld;
   int     x, y, n = 0, x0, y0, x1, y1;
   COLORREF bg;

   RedrawWindow( hWnd, NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW | RDW_ERASE | RDW_FRAME );
   GetWindowRect( hRoot, &rcRoot );
   GetWindowRect( hWnd, &rcCtl );
   hScreen = GetDC( NULL );
   hMem    = CreateCompatibleDC( hScreen );
   hBmp    = CreateCompatibleBitmap( hScreen, rcRoot.right - rcRoot.left, rcRoot.bottom - rcRoot.top );
   hOld    = ( HBITMAP ) SelectObject( hMem, hBmp );
   PrintWindow( hRoot, hMem, 2 /* PW_RENDERFULLCONTENT */ );
   x0 = rcCtl.left - rcRoot.left + 3;
   y0 = rcCtl.top - rcRoot.top + 3;
   x1 = rcCtl.right - rcRoot.left - 3;
   y1 = rcCtl.bottom - rcRoot.top - 3;
   bg = GetPixel( hMem, x0, y0 );
   for( y = y0; y < y1; y++ )
      for( x = x0; x < x1; x++ )
         if( GetPixel( hMem, x, y ) != bg )
            n++;
   SelectObject( hMem, hOld );
   DeleteObject( hBmp );
   DeleteDC( hMem );
   ReleaseDC( NULL, hScreen );
   hb_retni( n );
}
#pragma ENDDUMP
