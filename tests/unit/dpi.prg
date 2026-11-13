/*
 * Unit test for per-monitor DPI (PHASE4-DESIGN.md section 2, SOURCE/c_dpi.c, SOURCE/h_dpi.prg).
 * Rule under test: programs see design units (pixels at 96 DPI) everywhere; the real
 * window is scaled for its monitor's DPI, and again when the DPI changes.
 * A DPI change is simulated (HMG_DPI_SIMULATE runs the WM_DPICHANGED path), so the test
 * also runs on a one-monitor machine.
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0
STATIC s_nTxtFont96 := 0   // default-font height of Txt_1 at 96 DPI

FUNCTION Main()
   LOCAL lOn

   ErrorBlock( {| e | OutStd( "dpi: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   SET DPIAWARE PERMONITOR
   lOn := HMG_DPI_ISON()
   Check( "mode on", lOn )

   DEFINE WINDOW Win_1 AT 50, 50 WIDTH 400 HEIGHT 300 TITLE "dpi" MAIN NOSHOW ON INIT RunChecks()
      @ 10, 10 LABEL Lbl_1 VALUE "Label" WIDTH 100 HEIGHT 20 FONT "Arial" SIZE 10
      @ 40, 10 TEXTBOX Txt_1 VALUE "text" WIDTH 120 HEIGHT 24
      @ 80, 10 RADIOGROUP Rad_1 OPTIONS { "One", "Two" } WIDTH 80 SPACING 25
      @ 140, 10 SPINNER Spn_1 RANGE 1, 10 VALUE 5 WIDTH 80
      DEFINE TAB Tab_1 AT 10, 200 WIDTH 180 HEIGHT 150
         PAGE "P1"
            @ 40, 10 BUTTON Btn_1 CAPTION "OK" WIDTH 60 HEIGHT 24
         END PAGE
      END TAB
      @ 170, 100 GRID Grd_1 WIDTH 90 HEIGHT 60 HEADERS { "A", "B" } WIDTHS { 40, 70 } ITEMS { { "1", "x" } }
      DEFINE WINDOW Pnl_1 ROW 200 COL 200 WIDTH 150 HEIGHT 60 PANEL
         @ 10, 10 LABEL Lbl_P VALUE "in panel" WIDTH 80 HEIGHT 20
      END WINDOW
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC FUNCTION Px( n, nDpi )
RETURN Int( n * nDpi / 96 + 0.5 )

STATIC FUNCTION RawW( cCtl )
   LOCAL h := GetControlHandle( cCtl, "Win_1" ), a
   IF HB_ISARRAY( h )
      h := h[ 1 ]
   ENDIF
   a := HMG_DPI_RAWRECT( h )
RETURN a[ 3 ] - a[ 1 ]

STATIC FUNCTION RawFormW()
   LOCAL a := HMG_DPI_RAWRECT( GetFormHandle( "Win_1" ) )
RETURN a[ 3 ] - a[ 1 ]

STATIC FUNCTION Near( a, b )
RETURN Abs( a - b ) <= 1

STATIC PROCEDURE CheckAt( cWhen, nDpi )
   Check( cWhen + " form dpi",          HMG_GetFormDpi( "Win_1" ) == nDpi )
   Check( cWhen + " label raw width",   Near( RawW( "Lbl_1" ), Px( Win_1.Lbl_1.Width, nDpi ) ) )
   Check( cWhen + " label width prop",  Win_1.Lbl_1.Width == 200 .OR. Win_1.Lbl_1.Width == 100 )
   Check( cWhen + " textbox raw width", Near( RawW( "Txt_1" ), Px( 120, nDpi ) ) )
   Check( cWhen + " radio raw width",   Near( RawW( "Rad_1" ), Px( 80, nDpi ) ) )
   Check( cWhen + " tab button width",  Near( RawW( "Btn_1" ), Px( 60, nDpi ) ) )
   Check( cWhen + " form raw width",    Near( RawFormW(), Px( 400, nDpi ) ) )
   Check( cWhen + " form width prop",   Near( Win_1.Width, 400 ) )
   Check( cWhen + " label font",        HMG_DPI_FONTHEIGHT( GetControlHandle( "Lbl_1", "Win_1" ) ) == -Int( 10 * nDpi / 72 ) )
   Check( cWhen + " default font",      HMG_DPI_FONTHEIGHT( GetControlHandle( "Txt_1", "Win_1" ) ) == Round( s_nTxtFont96 * nDpi / 96, 0 ) )
   Check( cWhen + " panel raw width",   Near( HMG_DPI_RAWRECT( GetFormHandle( "Pnl_1" ) )[ 3 ] - HMG_DPI_RAWRECT( GetFormHandle( "Pnl_1" ) )[ 1 ], Px( 150, nDpi ) ) )
   Check( cWhen + " panel label width", Near( HMG_DPI_RAWRECT( GetControlHandle( "Lbl_P", "Pnl_1" ) )[ 3 ] - HMG_DPI_RAWRECT( GetControlHandle( "Lbl_P", "Pnl_1" ) )[ 1 ], Px( 80, nDpi ) ) )
   Check( cWhen + " panel dpi",         HMG_GetFormDpi( "Pnl_1" ) == nDpi )
   Check( cWhen + " grid column prop",  GetProperty( "Win_1", "Grd_1", "ColumnWidth", 2 ) == 70 )
   Check( cWhen + " grid column raw",   Near( LISTVIEW_GETCOLUMNWIDTH( GetControlHandle( "Grd_1", "Win_1" ), 1 ) * nDpi / 96, Px( 70, nDpi ) ) )
   Check( cWhen + " radio font",        HMG_DPI_FONTHEIGHT( GetControlHandle( "Rad_1", "Win_1" )[ 2 ] ) == ;
                                        HMG_DPI_FONTHEIGHT( GetControlHandle( "Rad_1", "Win_1" )[ 1 ] ) )
RETURN

STATIC FUNCTION RunChecks()
   LOCAL nDpi := HMG_GetFormDpi( "Win_1" ), n

   s_nTxtFont96 := Round( HMG_DPI_FONTHEIGHT( GetControlHandle( "Txt_1", "Win_1" ) ) * 96 / nDpi, 0 )
   OutStd( "dpi: monitor DPI " + hb_ntos( nDpi ) + ", scrollbar width " + hb_ntos( GETVSCROLLBARWIDTH() ) + " (design units)" + hb_eol() )

   // at the monitor's DPI
   Check( "label width prop",  Win_1.Lbl_1.Width == 100 .AND. Win_1.Lbl_1.Row == 10 .AND. Win_1.Lbl_1.Col == 10 )
   CheckAt( "start", nDpi )
   Check( "scrollbar metric",  GETVSCROLLBARWIDTH() == 17 )

   // set in design units, real size scaled
   Win_1.Lbl_1.Width := 200
   Check( "set width prop",    Win_1.Lbl_1.Width == 200 )
   Check( "set width raw",     Near( RawW( "Lbl_1" ), Px( 200, nDpi ) ) )

   // read-modify-write of the form size must not grow it
   FOR n := 1 TO 5
      SetProperty( "Win_1", "Width", GetProperty( "Win_1", "Width" ) )   // (dot syntax cannot express this: the <c> marker swallows it)
   NEXT
   Check( "form size stable",  Near( Win_1.Width, 400 ) )

   // move to a 200 % monitor and back
   HMG_DPI_SIMULATE( GetFormHandle( "Win_1" ), 192 )
   CheckAt( "192", 192 )
   Check( "192 label prop",    Win_1.Lbl_1.Width == 200 .AND. Win_1.Lbl_1.Row == 10 )
   HMG_DPI_SIMULATE( GetFormHandle( "Win_1" ), 144 )
   CheckAt( "144", 144 )
   HMG_DPI_SIMULATE( GetFormHandle( "Win_1" ), nDpi )
   CheckAt( "back", nDpi )

   // a control created after a DPI change gets that DPI
   HMG_DPI_SIMULATE( GetFormHandle( "Win_1" ), 192 )
   @ 200, 10 LABEL Lbl_2 OF Win_1 VALUE "late" WIDTH 50 HEIGHT 20
   Check( "late control raw",  Near( RawW( "Lbl_2" ), 100 ) )
   HMG_DPI_SIMULATE( GetFormHandle( "Win_1" ), nDpi )

   // the mode cannot be switched once windows exist
   Check( "no switch off",     HMG_SetPerMonitorDpi( .F. ) )

   OutStd( "dpi: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "dpi: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
