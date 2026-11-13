/*
 * Regression test for the HFCL Grid PDF and Grid Print windows (HMG 5.0 known issue,
 * fixed in 5.0.1): pdfeditcoldetails() and editcoldetails() set "pdfgrid.size" /
 * "printgrid.size", controls those windows do not have, and stopped with a runtime
 * error. They now set the size cell of the column grid.
 *
 * The windows are modal: a timer of the (hidden) main window does the checks while
 * each one is open, then closes it. It acts only from a window's message loop, never
 * from the DO EVENTS HMG runs while a modal window is being activated (releasing a
 * window there stops the program). A print preview on top is closed first. The PDF
 * and reports.cfg the windows may write are removed at the end.
 */
#include "hmg.ch"

DECLARE WINDOW pdfgrid
DECLARE WINDOW printgrid

STATIC s_nPass := 0, s_nFail := 0, s_cStep := "", s_nTicks := 0, s_lCfg

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "gridtools: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ") at " + s_cStep + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   // the windows open from an event (as from a button), not from ON INIT: a modal window
   // closed there would end the main message loop too
   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 500 HEIGHT 300 TITLE "gridtools" MAIN NOSHOW
      @ 10, 10 GRID Grid_1 WIDTH 300 HEIGHT 150 HEADERS { "Name", "Amount" } WIDTHS { 150, 100 } ;
         ITEMS { { "Apple", "12.50" }, { "Banana", "3.75" }, { "Cherry", "120.00" } } JUSTIFY { 0, 1 }
      DEFINE TIMER Tmr_1 INTERVAL 300 ACTION OnTimer()
      DEFINE TIMER Tmr_Start INTERVAL 200 ACTION ( Win_1.Tmr_Start.Enabled := .F., RunChecks() )
   END WINDOW
   Win_1.Tmr_1.Enabled := .F.
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC PROCEDURE RunChecks()
   s_lCfg := hb_FileExists( "reports.cfg" )
   Win_1.Tmr_1.Enabled := .T.                   // OnTimer() checks and closes each window
   s_cStep := "pdf"
   s_nTicks := 0
   // the dialog as the user sees it (showwindow .T.); DoMethod( ..., "PDF" ) makes the PDF
   // at once and closes it
   _gridpdf( "Grid_1", "Win_1", NIL, NIL, NIL, NIL, NIL, .T. )   // modal
   Check( "grid pdf window checked and closed", s_nPass == 2 .AND. ! IsWindowDefined( pdfgrid ) )

   s_cStep := "print"
   s_nTicks := 0
   _gridprint( "Grid_1", "Win_1", NIL, NIL, NIL, NIL, .T. )
   Check( "grid print window checked and closed", s_nPass == 5 .AND. ! IsWindowDefined( printgrid ) )
   s_cStep := ""
   Win_1.Tmr_1.Enabled := .F.
   FErase( "Win_1_Grid_1.pdf" )
   IF ! s_lCfg
      FErase( "reports.cfg" )
   ENDIF
   OutStd( "gridtools: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE OnTimer()
   STATIC s_lIn := .F.
   LOCAL n := 1
   IF s_lIn .OR. Empty( s_cStep )
      RETURN
   ENDIF
   // only from a window's message loop: not from the DO EVENTS of a window being activated
   DO WHILE ! Empty( ProcName( n ) )
      IF ProcName( n ) == "DOEVENTS"
         RETURN
      ENDIF
      n++
   ENDDO
   s_lIn := .T.
   // the top modal window, active (the timer can fire while it is being activated)
   IF IsTop( "_HMG_PRINTER_SHOWPREVIEW" )
      _HMG_PRINTER_PreviewClose()             // Grid Print's preview, over printgrid
   ELSEIF s_cStep == "pdf" .AND. IsTop( "pdfgrid" )
      s_cStep := ""
      pdfgrid.columns.value := 2
      pdfgrid.columns.cell( 2, 2 ) := 0
      Check( "pdf: edit column details runs", HB_ISLOGICAL( pdfeditcoldetails() ) )
      Check( "pdf: size cell set", pdfgrid.columns.cell( 2, 2 ) > 0 )
      pdfgrid.Release
   ELSEIF s_cStep == "print" .AND. IsTop( "printgrid" )
      s_cStep := ""
      printgrid.columns.value := 2
      printgrid.columns.cell( 2, 2 ) := 0
      Check( "print: edit column details runs", HB_ISLOGICAL( editcoldetails() ) )
      Check( "print: size cell set", printgrid.columns.cell( 2, 2 ) > 0 )
      printgrid.Release
   ELSEIF ++s_nTicks > 50
      OutStd( "gridtools: FAIL the " + s_cStep + " window did not open" + hb_eol() )
      ExitProcess( 1 )
   ENDIF
   s_lIn := .F.
RETURN

STATIC FUNCTION IsTop( cForm )
RETURN _IsWindowDefined( cForm ) .AND. _IsWindowActive( cForm ) .AND. AScan( { 0, GetFormHandle( cForm ) }, _HMG_SYSDATA[ 167 ] ) > 0   // [167]: the active modal window

STATIC PROCEDURE Check( cName, lOk )
   IF lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "gridtools: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
