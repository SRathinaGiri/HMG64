/*
 * Unit test for GRID export (HMG5 5.2, h_gridexport.prg): HMG_GridExportCSV / XLSX and the
 * methods Form.Grid.ExportCSV / ExportXLSX, for every kind of grid - items, VIRTUAL with a
 * ROWSOURCE array, VIRTUAL with ON QUERYDATA, and a table (ROWSOURCE "alias"). All four hold
 * the same values, so their CSV files must be identical; the .xlsx is unzipped and its
 * parts and cells checked.
 */
#include "hmg.ch"

#define CRLF_   ( Chr( 13 ) + Chr( 10 ) )

STATIC s_nPass := 0, s_nFail := 0
STATIC s_aRows := NIL, s_cDir := ""
// text beyond ASCII: UNICODE mode any language (UTF-8); ANSI mode the Windows code page.
// The exported file holds it as UTF-8 either way.
STATIC s_cText := "", s_cTextUtf8 := ""

FUNCTION Main()
   LOCAL aCtl := { { 'TEXTBOX', 'CHARACTER' }, { 'TEXTBOX', 'NUMERIC', '9999999.99' }, { 'DATEPICKER', 'DROPDOWN' }, { 'CHECKBOX', 'Yes', 'No' } }
   LOCAL aRec

   ErrorBlock( {| e | OutStd( "gridexport: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )
   SET DATE ANSI
   SET CENTURY ON
   SET DELETED ON

   IF HMG_SupportUnicode()
      s_cText := s_cTextUtf8 := "नमस्ते ₹ Ünï"
   ELSE
      s_cText     := Chr( 220 ) + "n" + Chr( 239 ) + " caf" + Chr( 233 )   // "Ünï café" in Windows-1252
      s_cTextUtf8 := "Ünï café"
   ENDIF

   s_cDir := hb_DirSepAdd( hb_DirTemp() ) + "hmgexp" + hb_ntos( hb_RandomInt( 100000, 999999 ) ) + hb_ps()
   hb_DirCreate( s_cDir )

   s_aRows := { ;
      { "Apple, red", 12.5, 0d20261116, .T. }, ;
      { 'He said "hi"', -3, 0d19991231, .F. }, ;
      { "two" + Chr( 13 ) + Chr( 10 ) + "lines", 1234567, CToD( "" ), .T. }, ;
      { " edge ", 0, 0d20260101, .F. }, ;
      { s_cText, 0.25, 0d20260228, .T. } }

   // the same rows as a table
   dbCreate( s_cDir + "t1.dbf", { { "NAME", "C", 40, 0 }, { "QTY", "N", 12, 2 }, { "DAT", "D", 8, 0 }, { "OK", "L", 1, 0 } } )
   USE ( s_cDir + "t1.dbf" ) ALIAS T1 NEW EXCLUSIVE
   FOR EACH aRec IN s_aRows
      APPEND BLANK
      T1->NAME := aRec[ 1 ]
      T1->QTY  := aRec[ 2 ]
      T1->DAT  := aRec[ 3 ]
      T1->OK   := aRec[ 4 ]
   NEXT
   GO TOP

   DEFINE WINDOW Win_1 AT 40, 40 WIDTH 900 HEIGHT 700 TITLE "gridexport test" MAIN ON INIT RunChecks()
      @ 10, 10 GRID Grid_I WIDTH 420 HEIGHT 150 HEADERS { "Name", "Qty", "Date", "OK" } WIDTHS { 140, 80, 100, 60 } ;
         ITEMS s_aRows COLUMNCONTROLS aCtl
      @ 10, 450 GRID Grid_R WIDTH 420 HEIGHT 150 HEADERS { "Name", "Qty", "Date", "OK" } WIDTHS { 140, 80, 100, 60 } ;
         ROWSOURCE s_aRows
      @ 180, 10 GRID Grid_Q WIDTH 420 HEIGHT 150 HEADERS { "Name", "Qty", "Date", "OK" } WIDTHS { 140, 80, 100, 60 } ;
         VIRTUAL ITEMCOUNT Len( s_aRows ) ON QUERYDATA ( This.QueryData := s_aRows[ This.QueryRowIndex, This.QueryColIndex ] )
      @ 180, 450 GRID Grid_T WIDTH 420 HEIGHT 150 HEADERS { "Name", "Qty", "Date", "OK" } WIDTHS { 140, 80, 100, 60 } ;
         ROWSOURCE "T1" COLUMNFIELDS { "NAME", "QTY", "DAT", "OK" }
   END WINDOW
   Win_1.Activate
RETURN NIL

STATIC PROCEDURE RunChecks()
   LOCAL cExpect, cGot, cFile, aZip, cSheet, nSerial, cG, nT, aBig, n

   cExpect := Chr( 0xEF ) + Chr( 0xBB ) + Chr( 0xBF ) + ;
      'Name,Qty,Date,OK' + CRLF_ + ;
      '"Apple, red",12.5,2026-11-16,TRUE' + CRLF_ + ;
      '"He said ""hi""",-3,1999-12-31,FALSE' + CRLF_ + ;
      '"two' + CRLF_ + 'lines",1234567,,TRUE' + CRLF_ + ;
      '" edge",0,2026-01-01,FALSE' + CRLF_ + ;   // trailing spaces go, as the grid shows text
      s_cTextUtf8 + ',0.25,2026-02-28,TRUE' + CRLF_

   // 1. CSV: the same file from every kind of grid
   FOR EACH cG IN { "Grid_R", "Grid_Q", "Grid_T", "Grid_I" }
      cFile := s_cDir + cG + ".csv"
      Check( cG + ": ExportCSV returns .T.", HMG_GridExportCSV( "Win_1", cG, cFile ) )
      cGot := hb_MemoRead( cFile )
      Check( cG + ": CSV as expected" + iif( cGot == cExpect, "", " - got: " + hb_StrToHex( Left( cGot, 300 ), " " ) ), cGot == cExpect )
   NEXT

   // 2. options: no headers, a semicolon; and the method form
   cFile := s_cDir + "opt.csv"
   HMG_GridExportCSV( "Win_1", "Grid_R", cFile, .F., ";" )
   cGot := hb_MemoRead( cFile )
   Check( "no header row, semicolons", hb_LeftEq( cGot, Chr( 0xEF ) + Chr( 0xBB ) + Chr( 0xBF ) + "Apple, red;12.5;2026-11-16;TRUE" + CRLF_ ) )
   cFile := s_cDir + "method.csv"
   Win_1.Grid_R.ExportCSV( cFile )
   Check( "Form.Grid.ExportCSV( cFile )", hb_MemoRead( cFile ) == cExpect )

   // 3. XLSX: the parts and the cells
   cFile := s_cDir + "rows.xlsx"
   Check( "ExportXLSX returns .T.", HMG_GridExportXLSX( "Win_1", "Grid_R", cFile, "My: Rows" ) )
   aZip := UnzipAll( cFile )
   Check( "xlsx parts", hb_HHasKey( aZip, "[Content_Types].xml" ) .AND. hb_HHasKey( aZip, "_rels/.rels" ) .AND. ;
          hb_HHasKey( aZip, "xl/workbook.xml" ) .AND. hb_HHasKey( aZip, "xl/_rels/workbook.xml.rels" ) .AND. ;
          hb_HHasKey( aZip, "xl/styles.xml" ) .AND. hb_HHasKey( aZip, "xl/worksheets/sheet1.xml" ) )
   cSheet := hb_HGetDef( aZip, "xl/worksheets/sheet1.xml", "" )
   nSerial := 0d20261116 - 0d18991230
   Check( "sheet name made valid", '<sheet name="My_ Rows"' $ hb_HGetDef( aZip, "xl/workbook.xml", "" ) )
   Check( "header bold", '<c r="A1" s="2" t="inlineStr"><is><t xml:space="preserve">Name</t></is></c>' $ cSheet )
   Check( "text escaped", '<t xml:space="preserve">He said &quot;hi&quot;</t>' $ cSheet )
   Check( "number stays a number", '<c r="B2"><v>12.5</v></c>' $ cSheet )
   Check( "date is a date (serial " + hb_ntos( nSerial ) + ")", '<c r="C2" s="1"><v>' + hb_ntos( nSerial ) + '</v></c>' $ cSheet )
   Check( "logical", '<c r="D2" t="b"><v>1</v></c>' $ cSheet .AND. '<c r="D3" t="b"><v>0</v></c>' $ cSheet )
   Check( "empty date: no cell", ! '<c r="C4"' $ cSheet )
   Check( "header row frozen, column widths", 'state="frozen"' $ cSheet .AND. '<col min="1" max="1" width="20" customWidth="1"/>' $ cSheet )
   Check( "text beyond ASCII written as UTF-8", s_cTextUtf8 $ cSheet )
   Win_1.Grid_Q.ExportXLSX( s_cDir + "query.xlsx" )
   Check( "Form.Grid.ExportXLSX: the same cells from ON QUERYDATA", hb_HGetDef( UnzipAll( s_cDir + "query.xlsx" ), "xl/worksheets/sheet1.xml", "" ) == cSheet )

   // 4. 20,000 rows
   aBig := Array( 20000 )
   FOR n := 1 TO Len( aBig )
      aBig[ n ] := { "row " + hb_ntos( n ), n, 0d20260101 + ( n % 365 ), n % 2 == 0 }
   NEXT
   Win_1.Grid_R.RowSource := aBig
   nT := hb_MilliSeconds()
   HMG_GridExportXLSX( "Win_1", "Grid_R", s_cDir + "big.xlsx" )
   HMG_GridExportCSV( "Win_1", "Grid_R", s_cDir + "big.csv" )
   nT := hb_MilliSeconds() - nT
   OutStd( "gridexport: 20,000 rows to .xlsx and .csv in " + hb_ntos( nT ) + " ms" + hb_eol() )
   Check( "20,000 rows", MLCount( hb_MemoRead( s_cDir + "big.csv" ), 254 ) >= 20001 .AND. ;
          '<row r="20001">' $ hb_HGetDef( UnzipAll( s_cDir + "big.xlsx" ), "xl/worksheets/sheet1.xml", "" ) )

   IF GetEnv( "HMG_KEEP_EXPORT" ) == "1"
      OutStd( "gridexport: files kept in " + s_cDir + hb_eol() )
   ELSE
      AEval( hb_Directory( s_cDir + "*.*" ), {| a | FErase( s_cDir + a[ 1 ] ) } )
   ENDIF
   OutStd( "gridexport: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   dbCloseAll()
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

/* every file of a zip, by name */
STATIC FUNCTION UnzipAll( cFile )
   LOCAL h := { => }, hUnzip, nErr, cName, nSize, cBuf
   hUnzip := hb_unzipOpen( cFile )
   IF Empty( hUnzip )
      RETURN h
   ENDIF
   nErr := hb_unzipFileFirst( hUnzip )
   DO WHILE nErr == 0
      hb_unzipFileInfo( hUnzip, @cName, , , , , , @nSize )
      IF hb_unzipFileOpen( hUnzip ) == 0
         cBuf := Space( nSize )
         hb_unzipFileRead( hUnzip, @cBuf, nSize )
         hb_unzipFileClose( hUnzip )
         h[ cName ] := cBuf
      ENDIF
      nErr := hb_unzipFileNext( hUnzip )
   ENDDO
   hb_unzipClose( hUnzip )
RETURN h

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "gridexport: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
