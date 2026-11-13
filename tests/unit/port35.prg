/*
 * Regression test for the features ported from HMG 3.5 into HMG5 (so that the 3.5 samples build
 * and run): MonthCalendar colours, VIEW, RANGEMIN/RANGEMAX, VISIBLEMIN/VISIBLEMAX and
 * ON GETBOLDDAYS (@ and DEFINE syntax), Grid RowsPerPage, HMG_CHR/HMG_ASC/HMG_CESU8/HMG_UNCESU8,
 * and HPDFPRINT ... HEIGHTFIT GETBOTTOM.
 */
#include "hmg.ch"
#include "hmg_hpdf.ch"

STATIC s_nPass := 0, s_nFail := 0, s_nBoldCalls := 0

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "port35: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 700 HEIGHT 500 TITLE "port35" MAIN NOSHOW
      @ 10, 10 MONTHCALENDAR Cal_1 VALUE SToD( "20260615" ) ;
         RANGEMIN SToD( "20260101" ) RANGEMAX SToD( "20261231" ) ;
         FONTCOLOR { 10, 20, 30 } OUTERFONTCOLOR { 150, 150, 150 } BACKCOLOR { 250, 250, 240 } ;
         BORDERCOLOR { 200, 200, 255 } TITLEFONTCOLOR { 255, 255, 255 } TITLEBACKCOLOR { 0, 90, 160 } ;
         VIEW MCMV_MONTH ;
         ON GETBOLDDAYS { | dStart, dEnd | BoldDays( dStart, dEnd ) }
      DEFINE MONTHCALENDAR Cal_2
         ROW 10
         COL 300
         VALUE SToD( "20260301" )
         TITLEBACKCOLOR { 120, 0, 0 }
         OUTERFONTCOLOR { 1, 2, 3 }
         ON GETBOLDDAYS { | dS, dE | s_nBoldCalls++, { dS } }
      END MONTHCALENDAR
      @ 250, 10 GRID Grid_1 WIDTH 300 HEIGHT 200 HEADERS { "A" } WIDTHS { 200 } ;
         ITEMS { { "1" }, { "2" }, { "3" } }
   END WINDOW

   // ---- MonthCalendar ------------------------------------------------------------------
   Check( "value",             Win_1.Cal_1.Value == SToD( "20260615" ) )
   Check( "outer font colour", SameRGB( Win_1.Cal_1.OuterFontColor, { 150, 150, 150 } ) )
   Check( "title back colour", SameRGB( Win_1.Cal_1.TitleBackColor, { 0, 90, 160 } ) )
   Check( "title font colour", SameRGB( Win_1.Cal_1.TitleFontColor, { 255, 255, 255 } ) )
   Check( "border colour",     SameRGB( Win_1.Cal_1.BorderColor, { 200, 200, 255 } ) )
   Check( "font colour",       SameRGB( Win_1.Cal_1.FontColor, { 10, 20, 30 } ) )
   Check( "back colour",       SameRGB( Win_1.Cal_1.BackColor, { 250, 250, 240 } ) )
   Win_1.Cal_1.TitleBackColor := { 1, 128, 1 }
   Check( "set title back",    SameRGB( Win_1.Cal_1.TitleBackColor, { 1, 128, 1 } ) )
   Check( "range min",         GetProperty( "Win_1", "Cal_1", "RangeMin" ) == SToD( "20260101" ) )
   Check( "range max",         GetProperty( "Win_1", "Cal_1", "RangeMax" ) == SToD( "20261231" ) )
   SetProperty( "Win_1", "Cal_1", "RangeMax", SToD( "20270630" ) )
   Check( "set range max",     GetProperty( "Win_1", "Cal_1", "RangeMax" ) == SToD( "20270630" ) .AND. ;
                               GetProperty( "Win_1", "Cal_1", "RangeMin" ) == SToD( "20260101" ) )
   Check( "view",              Win_1.Cal_1.View == MCMV_MONTH )
   Win_1.Cal_1.View := MCMV_YEAR
   Check( "set view",          Win_1.Cal_1.View == MCMV_YEAR )
   Win_1.Cal_1.View := MCMV_MONTH
   Check( "visible range",     HB_ISDATE( Win_1.Cal_1.VisibleMin ) .AND. HB_ISDATE( Win_1.Cal_1.VisibleMax ) .AND. ;
                               Win_1.Cal_1.VisibleMin <= SToD( "20260615" ) .AND. Win_1.Cal_1.VisibleMax >= SToD( "20260615" ) )
   Check( "tab name slot kept", Empty( _HMG_SYSDATA [ HMG_CTL_RANGEMIN ] [ GetControlIndex( "Cal_1", "Win_1" ) ] ) )
   // the control asks for the bold days when it is created with ON GETBOLDDAYS
   Check( "bold days asked",   s_nBoldCalls > 0 )
   Check( "bold mask",         BoldDaysNumericArray( SToD( "20260501" ), SToD( "20260731" ), 3, ;
                                  { SToD( "20260601" ), SToD( "20260603" ), SToD( "20250101" ) } )[ 2 ] == 5 )
   // DEFINE syntax
   Check( "define: title back", SameRGB( Win_1.Cal_2.TitleBackColor, { 120, 0, 0 } ) )
   Check( "define: outer font", SameRGB( Win_1.Cal_2.OuterFontColor, { 1, 2, 3 } ) )
   Check( "define: slot reset", HB_ISHASH( _HMG_SYSDATA [ HMG_SYS_ALTCLAUSES ] ) .AND. Empty( _HMG_SYSDATA [ HMG_SYS_ALTCLAUSES ] ) )

   // ---- Grid --------------------------------------------------------------------------
   Check( "grid rows per page", HB_ISNUMERIC( Win_1.Grid_1.RowsPerPage ) .AND. Win_1.Grid_1.RowsPerPage > 3 )

   // ---- CESU-8 ------------------------------------------------------------------------
   CesuChecks()

   // ---- HPDF HEIGHTFIT / GETBOTTOM ------------------------------------------------------
   PdfChecks()

   OutStd( "port35: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC FUNCTION BoldDays( dStart, dEnd )
   s_nBoldCalls++
RETURN { dStart + 3, dEnd - 3 }

STATIC PROCEDURE CesuChecks()
   LOCAL cCake, cCesu, cText
   IF ! HMG_SupportUnicode()        // the ANSI library: plain Chr / Asc, no CESU-8 (as in HMG 3.5)
      Check( "ansi chr/asc",       HMG_CHR( 65 ) == "A" .AND. HMG_ASC( "A" ) == 65 .AND. HMG_CESU8( "abc" ) == "abc" .AND. HMG_UNCESU8( "abc" ) == "abc" )
      RETURN
   ENDIF
   cCake := HMG_CHR( 0x1F382 )
   Check( "chr 4 bytes",       Len( cCake ) == 4 .AND. Asc( cCake ) == 0xF0 )
   Check( "chr bmp",           HMG_CHR( 0x20B9 ) == hb_UTF8Chr( 0x20B9 ) )
   Check( "asc",               HMG_ASC( cCake ) == 0x1F382 .AND. HMG_ASC( "A" ) == 65 .AND. HMG_ASC( HMG_CHR( 0x20B9 ) ) == 0x20B9 )
   cCesu := HMG_CHR( 0x1F382, .T. )
   Check( "chr cesu 6 bytes",  Len( cCesu ) == 6 .AND. Asc( cCesu ) == 0xED )
   Check( "asc cesu",          HMG_ASC( cCesu ) == 0x1F382 )
   cText := "Birthday " + cCake + " Smile " + HMG_CHR( 0x1F60A ) + " ₹100"
   Check( "cesu8",             HMG_CESU8( cText ) == "Birthday " + cCesu + " Smile " + HMG_CHR( 0x1F60A, .T. ) + " ₹100" )
   Check( "uncesu8 round trip", HMG_UNCESU8( HMG_CESU8( cText ) ) == cText )
   Check( "plain text kept",   HMG_CESU8( "abc ₹" ) == "abc ₹" .AND. HMG_UNCESU8( "abc ₹" ) == "abc ₹" )
RETURN

STATIC PROCEDURE PdfChecks()
   LOCAL cFile := hb_DirTemp() + "hmg_port35_" + hb_ntos( hb_RandomInt( 100000, 999999 ) ) + ".pdf"
   LOCAL lOk := .F., nBottom := 0, cLong := Replicate( "A long paragraph that wraps over several lines. ", 12 )
   SELECT HPDFDOC cFile TO lOk PAPERSIZE HPDF_PAPER_A4
   Check( "pdf select", lOk )
   START HPDFDOC
      START HPDFPAGE
         @ 20, 15 HPDFPRINT cLong TO 25, 185 FONT "Helvetica" SIZE 10 JUSTIFY HEIGHTFIT GETBOTTOM @nBottom
         @ 20, 15 HPDFPRINT RECTANGLE TO nBottom, 185 PENWIDTH 0.1
      END HPDFPAGE
   END HPDFDOC
   Check( "heightfit bottom",  HB_ISNUMERIC( nBottom ) .AND. nBottom > 25 .AND. nBottom < 200 )
   Check( "pdf written",       hb_FileExists( cFile ) .AND. Left( hb_MemoRead( cFile ), 5 ) == "%PDF-" )
   FErase( cFile )
RETURN

STATIC FUNCTION SameRGB( a, b )
RETURN HB_ISARRAY( a ) .AND. Len( a ) >= 3 .AND. a[1] == b[1] .AND. a[2] == b[2] .AND. a[3] == b[3]

STATIC PROCEDURE Check( cName, lOk )
   IF lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "port35: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
