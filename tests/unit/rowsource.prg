/*
 * Unit test for GRID ... ROWSOURCE <aRows> (HMG5 5.2, c_grid.c HMG_GRIDSETROWSOURCE):
 * a VIRTUAL grid whose cells are read from an array in C, without ON QUERYDATA.
 * The text of every cell is compared with an ON QUERYDATA grid that returns the same
 * values (HMG's own formatting), the cells are read the way the grid paints them
 * (LVM_GETITEMTEXT -> LVN_GETDISPINFO), and the ROWSOURCE grid also has an ON QUERYDATA
 * that counts its calls: it must never run.
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0
STATIC s_aRows := NIL, s_nQueries := 0, s_nIgnored := 0, s_aBig := NIL
STATIC s_aEdit := NIL, s_aPending := NIL, s_xShown := NIL
MEMVAR _HMG_SYSDATA

FUNCTION Main()
   LOCAL aBig, n

   ErrorBlock( {| e | OutStd( "rowsource: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )
   SET DATE ANSI
   SET CENTURY ON

   // every value type HMG formats, a short row, a row that is not an array, trailing spaces
   s_aRows := { ;
      { "Apple   ", 12, 0d20261116, .T., NIL }, ;
      { "Pear", -3.5, 0d19991231, .F., { 1 } }, ;
      { "Ünïcödé €", 1234567, CToD( "" ), .T., "x" }, ;
      { "short" }, ;
      "single" }

   aBig := Array( 100000 )
   FOR n := 1 TO Len( aBig )
      aBig[ n ] := { "row " + hb_ntos( n ), n, n * 2 }
   NEXT
   s_aBig := aBig
   s_aEdit := { { "one", 1, 0d20260101, .T. }, { "two", 2, 0d20260202, .F. }, { "short" } }

   DEFINE WINDOW Win_1 AT 40, 40 WIDTH 900 HEIGHT 900 TITLE "rowsource test" MAIN ON INIT RunChecks( aBig )
      @ 10, 10 GRID Grid_R WIDTH 420 HEIGHT 200 ;
         HEADERS { "C", "N", "D", "L", "X" } WIDTHS { 90, 80, 90, 50, 60 } ;
         ROWSOURCE s_aRows ON QUERYDATA ( s_nIgnored++ )
      @ 10, 450 GRID Grid_Q WIDTH 420 HEIGHT 200 ;
         HEADERS { "C", "N", "D", "L", "X" } WIDTHS { 90, 80, 90, 50, 60 } ;
         VIRTUAL ITEMCOUNT Len( s_aRows ) ON QUERYDATA QueryCell()
      @ 230, 10 GRID Grid_Big WIDTH 420 HEIGHT 300 ;
         HEADERS { "Name", "N", "Double" } WIDTHS { 150, 100, 100 } ROWSOURCE aBig
      @ 540, 10 GRID Grid_BigQ WIDTH 420 HEIGHT 300 HEADERS { "Name", "N", "Double" } WIDTHS { 150, 100, 100 } ;
         VIRTUAL ITEMCOUNT Len( aBig ) ON QUERYDATA ( This.QueryData := s_aBig[ This.QueryRowIndex, This.QueryColIndex ] )
      @ 230, 450 GRID Grid_Alt WIDTH 420 HEIGHT 300 HEADERS { "A" } WIDTHS { 200 } VIRTUAL ITEMCOUNT 0 ;
         ON QUERYDATA ( This.QueryData := "query" )
      @ 650, 10 GRID Grid_E WIDTH 420 HEIGHT 120 ;
         HEADERS { "Text", "Number", "Date", "OK" } WIDTHS { 120, 80, 100, 60 } ;
         ROWSOURCE s_aEdit EDIT ;
         COLUMNCONTROLS { { 'TEXTBOX', 'CHARACTER' }, { 'TEXTBOX', 'NUMERIC', '9999' }, { 'DATEPICKER', 'DROPDOWN' }, { 'CHECKBOX', 'Yes', 'No' } }
      DEFINE TIMER Tmr_Edit INTERVAL 250 ACTION EditTimer()
      DEFINE GRID Grid_Def
         ROW 540
         COL 450
         WIDTH 420
         HEIGHT 100
         HEADERS { "D", "E" }
         WIDTHS { 150, 150 }
         ROWSOURCE { { "def 1", 1 }, { "def 2", 2 } }
      END GRID
   END WINDOW
   Win_1.Tmr_Edit.Enabled := .F.
   Win_1.Activate
RETURN NIL

/* an in-place edit as the user makes it: the row selected, the cell clicked, the editor
   opened; the timer records what the editor shows, types the new value and presses Enter */
STATIC FUNCTION EditCell( nRow, nCol, xNew )
   s_xShown := NIL
   Win_1.Grid_E.Value := nRow
   _HMG_SYSDATA[ 195 ] := nRow   // This.CellRowIndex
   _HMG_SYSDATA[ 196 ] := nCol   // This.CellColIndex
   _HMG_SYSDATA[ 197 ] := 100 ; _HMG_SYSDATA[ 198 ] := 100 ; _HMG_SYSDATA[ 199 ] := 90 ; _HMG_SYSDATA[ 200 ] := 22
   s_aPending := { nCol, xNew }
   Win_1.Tmr_Edit.Enabled := .T.
   _HMG_GRIDINPLACEEDIT( GetControlIndex( "Grid_E", "Win_1" ) )
   Win_1.Tmr_Edit.Enabled := .F.
RETURN s_xShown

STATIC PROCEDURE EditTimer()
   LOCAL cCtl, h, k
   IF s_aPending == NIL .OR. ! IsWindowDefined( _HMG_GRID_InplaceEdit )
      RETURN
   ENDIF
   cCtl := { "t", "t", "d", "c" }[ s_aPending[ 1 ] ]
   s_xShown := GetProperty( "_HMG_GRID_InplaceEdit", cCtl, "Value" )
   SetProperty( "_HMG_GRID_InplaceEdit", cCtl, "Value", s_aPending[ 2 ] )
   s_aPending := NIL
   h := GetFormHandle( "_HMG_GRID_InplaceEdit" )
   FOR k := 1 TO Len( _HMG_SYSDATA[ HMG_CTL_TYPE ] )   // its ON KEY RETURN hotkey, as Windows delivers it
      IF _HMG_SYSDATA[ HMG_CTL_TYPE ][ k ] == "HOTKEY" .AND. _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ k ] == h .AND. ;
         ! _HMG_SYSDATA[ HMG_CTL_DELETED ][ k ] .AND. _HMG_SYSDATA[ HMG_CTL_VALUE ][ k ] == 13
         DoMethod( "_HMG_GRID_InplaceEdit", "SetFocus" )
         PostHotKey( h, _HMG_SYSDATA[ HMG_CTL_ID ][ k ], 13 )
         EXIT
      ENDIF
   NEXT
RETURN

STATIC PROCEDURE QueryCell()
   LOCAL aRow := s_aRows[ This.QueryRowIndex ], x := NIL
   s_nQueries++
   IF ValType( aRow ) == "A"
      IF This.QueryColIndex <= Len( aRow )
         x := aRow[ This.QueryColIndex ]
      ENDIF
   ELSEIF This.QueryColIndex == 1
      x := aRow
   ENDIF
   This.QueryData := x
RETURN

STATIC FUNCTION Cell( cGrid, nRow, nCol )   // 1-based, read as the grid paints it
RETURN LISTVIEW_GETITEMTEXT( GetControlHandle( cGrid, "Win_1" ), nRow - 1, nCol - 1 )

STATIC PROCEDURE RunChecks( aBig )
   LOCAL nRow, nCol, lSame := .T., cWhy := "", nT, a, aNew

   // 1. the same text as ON QUERYDATA, cell by cell
   FOR nRow := 1 TO Len( s_aRows )
      FOR nCol := 1 TO 5
         IF ! Cell( "Grid_R", nRow, nCol ) == Cell( "Grid_Q", nRow, nCol )
            lSame := .F.
            cWhy += " [" + hb_ntos( nRow ) + "," + hb_ntos( nCol ) + "] '" + Cell( "Grid_R", nRow, nCol ) + "' <> '" + Cell( "Grid_Q", nRow, nCol ) + "'"
         ENDIF
      NEXT
   NEXT
   Check( "same text as ON QUERYDATA" + cWhy, lSame )
   Check( "the query grid did run", s_nQueries > 0 )
   Check( "character trimmed", Cell( "Grid_R", 1, 1 ) == "Apple" )
   Check( "number as Str()", Cell( "Grid_R", 1, 2 ) == Str( 12 ) )
   Check( "date as DToC()", Cell( "Grid_R", 1, 3 ) == DToC( 0d20261116 ) )
   Check( "logical", Cell( "Grid_R", 1, 4 ) == ".T." .AND. Cell( "Grid_R", 2, 4 ) == ".F." )
   Check( "NIL and arrays empty", Cell( "Grid_R", 1, 5 ) == "" .AND. Cell( "Grid_R", 2, 5 ) == "" )
   Check( "unicode text", Cell( "Grid_R", 3, 1 ) == "Ünïcödé €" )
   Check( "short row: empty cells", Cell( "Grid_R", 4, 1 ) == "short" .AND. Cell( "Grid_R", 4, 2 ) == "" )
   Check( "a row that is not an array is column 1", Cell( "Grid_R", 5, 1 ) == "single" .AND. Cell( "Grid_R", 5, 2 ) == "" )
   Check( "item count from the array", Win_1.Grid_R.ItemCount == Len( s_aRows ) )
   Check( "ON QUERYDATA of a ROWSOURCE grid never runs", s_nIgnored == 0 )
   Check( "DEFINE GRID ... ROWSOURCE", Win_1.Grid_Def.ItemCount == 2 .AND. Cell( "Grid_Def", 2, 1 ) == "def 2" .AND. AllTrim( Cell( "Grid_Def", 2, 2 ) ) == "2" )

   // 2. the same array, not a copy: a change shows after Refresh
   s_aRows[ 1, 1 ] := "Banana"
   AAdd( s_aRows, { "added", 1 } )
   Win_1.Grid_R.Refresh
   Check( "a changed cell shows", Cell( "Grid_R", 1, 1 ) == "Banana" )
   Check( "Refresh follows rows added", Win_1.Grid_R.ItemCount == Len( s_aRows ) .AND. Cell( "Grid_R", 6, 1 ) == "added" )
   ASize( s_aRows, 2 )
   Win_1.Grid_R.Refresh
   Check( "Refresh follows rows removed", Win_1.Grid_R.ItemCount == 2 )
   Check( "beyond the array: empty", Cell( "Grid_R", 3, 1 ) == "" )

   // 3. the RowSource property
   a := Win_1.Grid_R.RowSource
   Check( "RowSource returns the same array", ValType( a ) == "A" .AND. Len( a ) == 2 .AND. a[ 1, 1 ] == "Banana" )
   aNew := { { "new 1" }, { "new 2" }, { "new 3" } }
   Win_1.Grid_R.RowSource := aNew
   Check( "RowSource := rebinds", Win_1.Grid_R.ItemCount == 3 .AND. Cell( "Grid_R", 3, 1 ) == "new 3" )
   Check( "RowSource of a query grid is NIL", Win_1.Grid_Alt.RowSource == NIL )
   Win_1.Grid_Alt.RowSource := { { "from an array" } }
   Check( "RowSource := on an ON QUERYDATA grid takes over", Win_1.Grid_Alt.ItemCount == 1 .AND. Cell( "Grid_Alt", 1, 1 ) == "from an array" )
   Win_1.Grid_Alt.RowSource := NIL
   Win_1.Grid_Alt.ItemCount := 2
   Check( "RowSource := NIL gives the cells back to ON QUERYDATA", Cell( "Grid_Alt", 2, 1 ) == "query" )

   // 4. 100,000 rows: bound at once, any row readable, fast
   lSame := .T.
   Check( "100,000 rows", Win_1.Grid_Big.ItemCount == 100000 )
   nT := hb_MilliSeconds()
   FOR nRow := 99001 TO 100000
      IF ! Cell( "Grid_Big", nRow, 1 ) == "row " + hb_ntos( nRow ) .OR. ! AllTrim( Cell( "Grid_Big", nRow, 3 ) ) == hb_ntos( nRow * 2 )
         lSame := .F.
      ENDIF
   NEXT
   nT := hb_MilliSeconds() - nT
   a := hb_MilliSeconds()
   FOR nRow := 99001 TO 100000
      Cell( "Grid_BigQ", nRow, 1 )
      Cell( "Grid_BigQ", nRow, 3 )
   NEXT
   a := hb_MilliSeconds() - a
   OutStd( "rowsource: 2,000 cells read in " + hb_ntos( nT ) + " ms with ROWSOURCE, " + hb_ntos( a ) + " ms with ON QUERYDATA" + hb_eol() )
   nT := hb_MilliSeconds()
   FOR nRow := 1 TO 20
      RedrawWindow( GetControlHandle( "Grid_Big", "Win_1" ) )
   NEXT
   nT := hb_MilliSeconds() - nT
   a := hb_MilliSeconds()
   FOR nRow := 1 TO 20
      RedrawWindow( GetControlHandle( "Grid_BigQ", "Win_1" ) )
   NEXT
   a := hb_MilliSeconds() - a
   OutStd( "rowsource: 20 full repaints in " + hb_ntos( nT ) + " ms with ROWSOURCE, " + hb_ntos( a ) + " ms with ON QUERYDATA" + hb_eol() )
   Check( "last rows of 100,000 correct", lSame )
   Win_1.Grid_Big.Value := 100000
   DO EVENTS
   Check( "the grid shows the last row", Win_1.Grid_Big.Value == 100000 )

   // 5. in-place editing: the editor gets the typed value, the edit goes into the array
   Check( "edit text: the editor shows it", EditCell( 1, 1, "edited" ) == "one" )
   Check( "edit text: kept in the array", s_aEdit[ 1, 1 ] == "edited" .AND. Cell( "Grid_E", 1, 1 ) == "edited" )
   Check( "edit number: the editor gets a number", EditCell( 2, 2, 42 ) == 2 )
   Check( "edit number: a number in the array", ValType( s_aEdit[ 2, 2 ] ) == "N" .AND. s_aEdit[ 2, 2 ] == 42 .AND. AllTrim( Cell( "Grid_E", 2, 2 ) ) == "42" )
   Check( "edit date: the editor gets a date", EditCell( 1, 3, 0d20261231 ) == 0d20260101 )
   Check( "edit date: a date in the array", s_aEdit[ 1, 3 ] == 0d20261231 )
   Check( "edit logical", EditCell( 2, 4, .T. ) == .F. .AND. s_aEdit[ 2, 4 ] == .T. .AND. Cell( "Grid_E", 2, 4 ) == ".T." )
   EditCell( 3, 2, 7 )
   Check( "edit a short row: it grows", Len( s_aEdit[ 3 ] ) >= 2 .AND. s_aEdit[ 3, 2 ] == 7 .AND. s_aEdit[ 3, 1 ] == "short" )

   OutStd( "rowsource: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "rowsource: FAIL " + cName + hb_eol() )
   ENDIF
RETURN

#pragma BEGINDUMP
#include <windows.h>
#include "hbapi.h"
HB_FUNC( POSTHOTKEY )   /* ( hWnd, nId, nVK ): a hotkey, posted as Windows posts it */
{
   PostMessageW( ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 ), WM_HOTKEY, ( WPARAM ) hb_parni( 2 ), MAKELPARAM( 0, hb_parni( 3 ) ) );
}
#pragma ENDDUMP
