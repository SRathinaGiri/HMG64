/*
 * HMG5 5.2 - GRID export to CSV and to Excel (.xlsx), with no Excel and no extra library.
 *
 *   lOk := HMG_GridExportCSV( cForm, cGrid, cFile [, lHeaders] [, cSeparator] )
 *   lOk := HMG_GridExportXLSX( cForm, cGrid, cFile [, cSheet] [, lHeaders] )
 *   Form.Grid.ExportCSV( cFile [, lHeaders] [, cSeparator] )
 *   Form.Grid.ExportXLSX( cFile [, cSheet] [, lHeaders] )
 *
 * Every kind of GRID: items, VIRTUAL with ON QUERYDATA or a ROWSOURCE array, or a table
 * (ROWSOURCE "alias"). The values are the grid's own: what ON QUERYDATA, the array or the
 * table give (typed), not the text on screen.
 *
 * CSV: UTF-8 with a byte order mark (Excel then reads every language), CR LF, fields quoted
 * when they hold the separator, a quote, a line break or a leading or trailing space; text
 * without trailing spaces (as the grid shows it), numbers with a point and no trailing zeros,
 * dates as YYYY-MM-DD, logicals TRUE/FALSE.
 * XLSX: an Office Open XML workbook written here and zipped with hbmzip: numbers stay
 * numbers, dates are dates, logicals are TRUE/FALSE, the header row is bold and frozen and
 * the columns get the grid's widths.
 */

#include "hmg.ch"
#include "fileio.ch"

MEMVAR _HMG_SYSDATA

#define CRLF_   ( Chr( 13 ) + Chr( 10 ) )

/* ------------------------------------------------------------------------- */
/* the grid's values                                                         */
/* ------------------------------------------------------------------------- */

STATIC FUNCTION GridIndex( cForm, cGrid )
   LOCAL i := GetControlIndex( cGrid, cForm )
   IF i == 0 .OR. .NOT. ( _HMG_SYSDATA[ HMG_CTL_TYPE ][ i ] == "GRID" .OR. _HMG_SYSDATA[ HMG_CTL_TYPE ][ i ] == "MULTIGRID" )
      MsgHMGError( "Grid export: " + hb_CStr( cGrid ) + " Of " + hb_CStr( cForm ) + " is not a GRID. Program Terminated" )
   ENDIF
RETURN i

/* { aHeaders, aWidths, nRows, bCell } - bCell( nRow, nCol ) gives a typed value */
STATIC FUNCTION GridSource( idx )
   LOCAL hGrid    := _HMG_SYSDATA[ HMG_CTL_HANDLE ][ idx ]
   LOCAL aHeaders := AClone( _HMG_SYSDATA[ HMG_CTL_PAGEMAP ][ idx ] )
   LOCAL nCols    := Len( aHeaders ), aWidths := Array( nCols ), n
   LOCAL lVirtual := _HMG_SYSDATA[ HMG_CTL_MISCDATA2 ][ idx ][ 9 ]
   LOCAL nCacheRow := 0, aCacheRow := NIL, bCell

   FOR n := 1 TO nCols
      aWidths[ n ] := LISTVIEW_GETCOLUMNWIDTH( hGrid, n - 1 )
      IF ! HB_ISSTRING( aHeaders[ n ] )
         aHeaders[ n ] := hb_CStr( aHeaders[ n ] )
      ENDIF
   NEXT

   IF lVirtual
      bCell := {| nRow, nCol | VirtualCell( idx, nRow, nCol ) }
   ELSE
      bCell := {| nRow, nCol | iif( nRow == nCacheRow, NIL, ( nCacheRow := nRow, aCacheRow := _GetItem( , , nRow, idx ) ) ), ;
                               iif( HB_ISARRAY( aCacheRow ) .AND. nCol <= Len( aCacheRow ), aCacheRow[ nCol ], NIL ) }
   ENDIF
RETURN { aHeaders, aWidths, ListView_GetItemCount( hGrid ), bCell }

/* a VIRTUAL grid's cell as the in-place editor gets it: the table, the ROWSOURCE array
   or ON QUERYDATA (This.QueryRowIndex / QueryColIndex set, typed value in QueryData) */
STATIC FUNCTION VirtualCell( idx, nRow, nCol )
   LOCAL xValue
   _HMG_SYSDATA[ 201 ] := nRow
   _HMG_SYSDATA[ 202 ] := nCol
   _HMG_SYSDATA[ 230 ] := ""
   _HMG_SYSDATA[ 320 ] := .T.
   IF ValType( _HMG_SYSDATA[ HMG_CTL_MISCDATA2 ][ idx ][ 10 ] ) == "C"
      GetDataGridCellData( idx, .T. )
   ELSEIF _HMG_GridRowSourceGet( idx, nRow, nCol )
   ELSEIF HB_ISBLOCK( _HMG_SYSDATA[ HMG_CTL_PROCEDURE ][ idx ] )
      Eval( _HMG_SYSDATA[ HMG_CTL_PROCEDURE ][ idx ] )
   ENDIF
   _HMG_SYSDATA[ 320 ] := .F.
   xValue := _HMG_SYSDATA[ 230 ]
RETURN xValue

/* runs bWork with This set to the grid, as for its own events (ON QUERYDATA may use This) */
STATIC FUNCTION WithGrid( idx, bWork )
   LOCAL xResult
   _PushEventInfo()
   _HMG_SYSDATA[ 194 ] := AScan( _HMG_SYSDATA[ HMG_FRM_HANDLE ], _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ idx ] )
   _HMG_SYSDATA[ 231 ] := "C"
   _HMG_SYSDATA[ 203 ] := idx
   _HMG_SYSDATA[ 316 ] := iif( _HMG_SYSDATA[ 194 ] > 0, _HMG_SYSDATA[ HMG_FRM_NAME ][ _HMG_SYSDATA[ 194 ] ], "" )
   _HMG_SYSDATA[ 317 ] := _HMG_SYSDATA[ HMG_CTL_NAME ][ idx ]
   xResult := Eval( bWork )
   _HMG_SYSDATA[ 201 ] := 0
   _HMG_SYSDATA[ 202 ] := 0
   _HMG_SYSDATA[ 230 ] := ""
   _PopEventInfo()
RETURN xResult

STATIC FUNCTION ToUTF8( c )   /* UNICODE mode: already UTF-8; ANSI mode: from the Windows code page */
RETURN iif( HMG_SupportUnicode(), c, HMG_ACPTOUTF8( c ) )

/* ------------------------------------------------------------------------- */
/* CSV                                                                       */
/* ------------------------------------------------------------------------- */

FUNCTION HMG_GridExportCSV( cForm, cGrid, cFile, lHeaders, cSep )
   LOCAL idx := GridIndex( cForm, cGrid )
   hb_default( @lHeaders, .T. )
   hb_default( @cSep, "," )
RETURN WithGrid( idx, {|| WriteCSV( GridSource( idx ), cFile, lHeaders, cSep ) } )

STATIC FUNCTION WriteCSV( aSrc, cFile, lHeaders, cSep )
   LOCAL nH, nRow, nCol, nCols := Len( aSrc[ 1 ] ), aLine, cBuf := "", lOk := .T.

   IF ( nH := FCreate( cFile ) ) == F_ERROR
      RETURN .F.
   ENDIF
   cBuf := Chr( 0xEF ) + Chr( 0xBB ) + Chr( 0xBF )
   IF lHeaders
      aLine := Array( nCols )
      FOR nCol := 1 TO nCols
         aLine[ nCol ] := CsvField( aSrc[ 1 ][ nCol ], cSep )
      NEXT
      cBuf += JoinLine( aLine, cSep )
   ENDIF
   FOR nRow := 1 TO aSrc[ 3 ]
      aLine := Array( nCols )
      FOR nCol := 1 TO nCols
         aLine[ nCol ] := CsvField( Eval( aSrc[ 4 ], nRow, nCol ), cSep )
      NEXT
      cBuf += JoinLine( aLine, cSep )
      IF Len( cBuf ) > 65536
         lOk := lOk .AND. FWrite( nH, cBuf ) == Len( cBuf )
         cBuf := ""
      ENDIF
   NEXT
   lOk := lOk .AND. FWrite( nH, cBuf ) == Len( cBuf )
   lOk := FClose( nH ) .AND. lOk
RETURN lOk

STATIC FUNCTION JoinLine( aLine, cSep )
   LOCAL c := "", n
   FOR n := 1 TO Len( aLine )
      c += iif( n > 1, cSep, "" ) + aLine[ n ]
   NEXT
RETURN c + CRLF_

STATIC FUNCTION CsvField( x, cSep )
   LOCAL c
   SWITCH ValType( x )
   CASE "C"
   CASE "M"
      c := ToUTF8( RTrim( x ) )   /* as the grid shows it: a table's padding goes */
      IF cSep $ c .OR. '"' $ c .OR. Chr( 10 ) $ c .OR. Chr( 13 ) $ c .OR. ;
         ( Len( c ) > 0 .AND. ( Left( c, 1 ) == " " .OR. Right( c, 1 ) == " " ) )
         c := '"' + StrTran( c, '"', '""' ) + '"'
      ENDIF
      RETURN c
   CASE "N"
      RETURN NumText( x )
   CASE "D"
      RETURN iif( Empty( x ), "", hb_DToC( x, "yyyy-mm-dd" ) )
   CASE "T"
      RETURN iif( Empty( x ), "", hb_TToC( x, "yyyy-mm-dd", "hh:mm:ss" ) )
   CASE "L"
      RETURN iif( x, "TRUE", "FALSE" )
   ENDSWITCH
RETURN ""

/* ------------------------------------------------------------------------- */
/* XLSX                                                                      */
/* ------------------------------------------------------------------------- */

FUNCTION HMG_GridExportXLSX( cForm, cGrid, cFile, cSheet, lHeaders )
   LOCAL idx := GridIndex( cForm, cGrid )
   hb_default( @cSheet, "Sheet1" )
   hb_default( @lHeaders, .T. )
RETURN WithGrid( idx, {|| WriteXLSX( GridSource( idx ), cFile, cSheet, lHeaders ) } )

STATIC FUNCTION WriteXLSX( aSrc, cFile, cSheet, lHeaders )
   LOCAL hZip, lOk := .T., aParts, aPart

   cSheet := SheetName( cSheet )
   aParts := { ;
      { "[Content_Types].xml", ;
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + CRLF_ + ;
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' + ;
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' + ;
        '<Default Extension="xml" ContentType="application/xml"/>' + ;
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' + ;
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' + ;
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' + ;
        '</Types>' }, ;
      { "_rels/.rels", ;
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + CRLF_ + ;
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + ;
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' + ;
        '</Relationships>' }, ;
      { "xl/workbook.xml", ;
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + CRLF_ + ;
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' + ;
        '<sheets><sheet name="' + XmlText( cSheet ) + '" sheetId="1" r:id="rId1"/></sheets></workbook>' }, ;
      { "xl/_rels/workbook.xml.rels", ;
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + CRLF_ + ;
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + ;
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>' + ;
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' + ;
        '</Relationships>' }, ;
      { "xl/styles.xml", ;
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + CRLF_ + ;
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' + ;
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>' + ;
        '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>' + ;
        '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' + ;
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' + ;
        '<cellXfs count="4">' + ;
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' + ;
        '<xf numFmtId="14" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>' + ;
        '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>' + ;
        '<xf numFmtId="22" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>' + ;
        '</cellXfs>' + ;
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>' + ;
        '</styleSheet>' }, ;
      { "xl/worksheets/sheet1.xml", SheetXml( aSrc, lHeaders ) } }

   FErase( cFile )
   hZip := hb_zipOpen( cFile )
   IF Empty( hZip )
      RETURN .F.
   ENDIF
   FOR EACH aPart IN aParts
      IF hb_zipFileCreate( hZip, aPart[ 1 ] ) != 0
         lOk := .F.
         EXIT
      ENDIF
      lOk := lOk .AND. hb_zipFileWrite( hZip, aPart[ 2 ] ) == 0
      lOk := hb_zipFileClose( hZip ) == 0 .AND. lOk
   NEXT
   lOk := hb_zipClose( hZip ) == 0 .AND. lOk
RETURN lOk

STATIC FUNCTION SheetXml( aSrc, lHeaders )
   LOCAL nCols := Len( aSrc[ 1 ] ), nRow, nCol, nXRow := 0, aRows := {}, cRow, n

   AAdd( aRows, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + CRLF_ + ;
                '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' + ;
                iif( lHeaders, '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" ' + ;
                               'activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>', "" ) )
   IF nCols > 0
      cRow := "<cols>"
      FOR nCol := 1 TO nCols   /* pixels to characters, roughly as Excel measures */
         n := Max( 2, Round( aSrc[ 2 ][ nCol ] / 7, 1 ) )
         cRow += '<col min="' + hb_ntos( nCol ) + '" max="' + hb_ntos( nCol ) + '" width="' + NumText( n ) + '" customWidth="1"/>'
      NEXT
      AAdd( aRows, cRow + "</cols>" )
   ENDIF
   AAdd( aRows, "<sheetData>" )
   IF lHeaders
      nXRow++
      cRow := '<row r="1">'
      FOR nCol := 1 TO nCols
         cRow += XlsxCell( ColName( nCol ) + "1", aSrc[ 1 ][ nCol ], 2 )
      NEXT
      AAdd( aRows, cRow + "</row>" )
   ENDIF
   FOR nRow := 1 TO aSrc[ 3 ]
      nXRow++
      cRow := '<row r="' + hb_ntos( nXRow ) + '">'
      FOR nCol := 1 TO nCols
         cRow += XlsxCell( ColName( nCol ) + hb_ntos( nXRow ), Eval( aSrc[ 4 ], nRow, nCol ), 0 )
      NEXT
      AAdd( aRows, cRow + "</row>" )
   NEXT
   AAdd( aRows, "</sheetData></worksheet>" )
RETURN JoinAll( aRows )

STATIC FUNCTION JoinAll( a )
   LOCAL c := "", x
   FOR EACH x IN a
      c += x
   NEXT
RETURN c

/* one cell; nStyle 2 = bold (the header) */
STATIC FUNCTION XlsxCell( cRef, x, nStyle )
   LOCAL cS := iif( nStyle > 0, ' s="' + hb_ntos( nStyle ) + '"', "" )
   SWITCH ValType( x )
   CASE "C"
   CASE "M"
      x := RTrim( x )   /* as the grid shows it: a table's padding goes */
      IF Len( x ) == 0
         RETURN ""
      ENDIF
      RETURN '<c r="' + cRef + '"' + cS + ' t="inlineStr"><is><t xml:space="preserve">' + XmlText( ToUTF8( x ) ) + '</t></is></c>'
   CASE "N"
      RETURN '<c r="' + cRef + '"' + cS + '><v>' + NumText( x ) + '</v></c>'
   CASE "D"
      IF Empty( x )
         RETURN ""
      ENDIF
      RETURN '<c r="' + cRef + '" s="1"><v>' + hb_ntos( x - hb_SToD( "18991230" ) ) + '</v></c>'
   CASE "T"
      IF Empty( x )
         RETURN ""
      ENDIF
      RETURN '<c r="' + cRef + '" s="3"><v>' + hb_ntos( hb_TToN( x ) - hb_TToN( hb_SToT( "18991230000000" ) ) ) + '</v></c>'
   CASE "L"
      RETURN '<c r="' + cRef + '"' + cS + ' t="b"><v>' + iif( x, "1", "0" ) + '</v></c>'
   ENDSWITCH
RETURN ""

/* a number with a point and no trailing zeros: 12.50 -> 12.5, -3.00 -> -3 (a table's
   field decimals or an item's mask do not change the value) */
STATIC FUNCTION NumText( n )
   LOCAL c := hb_ntos( n )
   IF "." $ c .AND. ! "e" $ Lower( c )
      DO WHILE Right( c, 1 ) == "0"
         c := hb_StrShrink( c, 1 )
      ENDDO
      IF Right( c, 1 ) == "."
         c := hb_StrShrink( c, 1 )
      ENDIF
   ENDIF
RETURN iif( c == "-0", "0", c )

STATIC FUNCTION ColName( n )   /* 1 -> A, 27 -> AA */
   LOCAL c := ""
   DO WHILE n > 0
      c := Chr( Asc( "A" ) + ( n - 1 ) % 26 ) + c
      n := Int( ( n - 1 ) / 26 )
   ENDDO
RETURN c

/* XML text: & < > " escaped, characters XML does not allow removed */
STATIC FUNCTION XmlText( c )
   LOCAL n
   c := StrTran( c, "&", "&amp;" )
   c := StrTran( c, "<", "&lt;" )
   c := StrTran( c, ">", "&gt;" )
   c := StrTran( c, '"', "&quot;" )
   FOR n := 0 TO 31
      IF n != 9 .AND. n != 10 .AND. n != 13 .AND. Chr( n ) $ c
         c := StrTran( c, Chr( n ), "" )
      ENDIF
   NEXT
RETURN c

/* Excel's sheet names: 1 to 31 characters, none of : \ / ? * [ ] */
STATIC FUNCTION SheetName( c )
   LOCAL x
   c := iif( HB_ISSTRING( c ), c, "Sheet1" )
   FOR EACH x IN { ":", "\", "/", "?", "*", "[", "]" }
      c := StrTran( c, x, "_" )
   NEXT
   c := AllTrim( c )
RETURN iif( Empty( c ), "Sheet1", Left( c, 31 ) )

#pragma BEGINDUMP
#include <windows.h>
#include "hbapi.h"

/* HMG_ACPTOUTF8( cAnsi ) -> cUtf8: text in the Windows code page (HMG's ANSI mode) to UTF-8 */
HB_FUNC( HMG_ACPTOUTF8 )
{
   const char * s = hb_parc( 1 );
   int          n = ( int ) hb_parclen( 1 ), w, u;
   WCHAR *      pw;
   char *       pu;
   if( ! s || n == 0 )
   {
      hb_retc( "" );
      return;
   }
   w  = MultiByteToWideChar( CP_ACP, 0, s, n, NULL, 0 );
   pw = ( WCHAR * ) hb_xgrab( ( w + 1 ) * sizeof( WCHAR ) );
   MultiByteToWideChar( CP_ACP, 0, s, n, pw, w );
   u  = WideCharToMultiByte( CP_UTF8, 0, pw, w, NULL, 0, NULL, NULL );
   pu = ( char * ) hb_xgrab( u + 1 );
   WideCharToMultiByte( CP_UTF8, 0, pw, w, pu, u, NULL, NULL );
   hb_xfree( pw );
   hb_retclen_buffer( pu, u );
}
#pragma ENDDUMP
