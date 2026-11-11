/*
 * Unit test for dark mode (PHASE4-DESIGN.md section 3, SOURCE/c_dark.c, SOURCE/h_dark.prg).
 * Checks the palette, the title bar, list colours and, through PrintWindow, the colours
 * controls actually paint: dark defaults, explicit colours kept.
 * Programs without SET DARKMODE are covered by the rest of the suite (light, unchanged).
 */
#include "hmg.ch"

#define DK_BG     RGB(  32,  32,  32 )
#define DK_INPUT  RGB(  45,  45,  45 )
#define DK_TEXT   RGB( 235, 235, 235 )

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "darkmode: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   Check( "off by default",  ! HMG_IsDarkMode() )
   Check( "light palette",   GetSysColor( 15 ) == GETSYSCOLOR_REAL( 15 ) )
   SET DARKMODE ON
   Check( "on",              HMG_IsDarkMode() )

   DEFINE WINDOW Win_1 AT 40, 40 WIDTH 500 HEIGHT 360 TITLE "darkmode" MAIN ON INIT RunChecks()
      @ 10, 10 LABEL Lbl_1 VALUE "" WIDTH 100 HEIGHT 20
      @ 40, 10 LABEL Lbl_C VALUE "" WIDTH 100 HEIGHT 20 BACKCOLOR { 200, 0, 0 }
      @ 70, 10 TEXTBOX Txt_1 VALUE "" WIDTH 120 HEIGHT 24
      @ 100, 10 TEXTBOX Txt_C VALUE "" WIDTH 120 HEIGHT 24 BACKCOLOR { 0, 0, 200 }
      @ 140, 10 GRID Grd_1 WIDTH 200 HEIGHT 80 HEADERS { "A" } WIDTHS { 150 } ITEMS { { "" }, { "" } }
      DEFINE TAB Tab_1 AT 10, 250 WIDTH 220 HEIGHT 150
         PAGE "P1"
            @ 40, 10 CHECKBOX Chk_1 CAPTION "" WIDTH 100 HEIGHT 24
         END PAGE
      END TAB
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

/* the real system colour, bypassing the dark palette */
STATIC FUNCTION GETSYSCOLOR_REAL( n )
RETURN HMG_DARK_REALSYSCOLOR( n )

/* colour painted at the centre-left of a control (client coordinates of the form) */
STATIC FUNCTION PixelIn( cCtl, nDx, nDy )
   LOCAL nRow := GetProperty( "Win_1", cCtl, "Row" ), nCol := GetProperty( "Win_1", cCtl, "Col" )
RETURN HMG_DARK_PIXEL( GetFormHandle( "Win_1" ), nCol + hb_defaultValue( nDx, 30 ), nRow + hb_defaultValue( nDy, 10 ) )

STATIC FUNCTION RunChecks()
   DO EVENTS
   Check( "palette 3DFACE",    GetSysColor( 15 ) == DK_BG )
   Check( "palette WINDOW",    GetSysColor( 5 ) == DK_INPUT )
   Check( "palette TEXT",      GetSysColor( 8 ) == DK_TEXT )
   Check( "title bar dark",    HMG_DARK_TITLEISDARK( GetFormHandle( "Win_1" ) ) )
   Check( "grid back colour",  HMG_DARK_LISTVIEWBK( GetControlHandle( "Grd_1", "Win_1" ) ) == DK_INPUT )

   Check( "form paints dark",       HMG_DARK_PIXEL( GetFormHandle( "Win_1" ), 300, 300 ) == DK_BG )
   Check( "label paints dark",      PixelIn( "Lbl_1" ) == DK_BG )
   Check( "label BACKCOLOR kept",   PixelIn( "Lbl_C" ) == RGB( 200, 0, 0 ) )
   Check( "textbox paints dark",    PixelIn( "Txt_1" ) == DK_INPUT )
   Check( "textbox BACKCOLOR kept", PixelIn( "Txt_C" ) == RGB( 0, 0, 200 ) )
   Check( "grid row paints dark",   PixelIn( "Grd_1", 60, 35 ) == DK_INPUT )
   Check( "tab page paints dark",   HMG_DARK_PIXEL( GetFormHandle( "Win_1" ), 250 + 150, 10 + 120 ) == DK_BG )
   // Chk_1 is at 40,10 inside the tab at 10,250
   Check( "checkbox in tab dark",   HMG_DARK_PIXEL( GetFormHandle( "Win_1" ), 250 + 10 + 60, 10 + 40 + 12 ) == DK_BG )

   // cannot be switched once windows exist
   Check( "no switch off",     HMG_SetDarkMode( "OFF" ) )

   OutStd( "darkmode: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "darkmode: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
