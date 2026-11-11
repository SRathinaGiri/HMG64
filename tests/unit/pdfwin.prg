/*
 * Unit test for SET PDFENGINE WINDOWS (PHASE4-DESIGN.md section 5, SOURCE/c_pdf.c, SOURCE/h_pdf.prg).
 * SELECT PRINTER PDF through the Windows PDF printer, and preview pages (EMF) to a vector PDF.
 * The files are checked as PDF: pages, paper size, embedded TrueType font, no page images.
 * Skipped (reported, not failed) when the "Microsoft Print to PDF" printer is not installed.
 */
#include "hmg.ch"

MEMVAR _HMG_SYSDATA

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   LOCAL cDir := hb_DirSepAdd( hb_DirTemp() ), cTag := hb_ntos( hb_RandomInt( 100000, 999999 ) )
   LOCAL cFile1 := cDir + "hmgpdf_" + cTag + "_1.pdf", cFile2 := cDir + "hmgpdf_" + cTag + "_2.pdf"
   LOCAL cFile3 := cDir + "hmgpdf_" + cTag + "_3.pdf", cFile4 := cDir + "hmgpdf_" + cTag + "_4.pdf"
   LOCAL cFile5 := cDir + "hmgpdf_" + cTag + "_5.pdf"
   LOCAL lOk := .F., cPdf, aBox, nSecs, aProps, hDC, aEmf := {}, i, cEmf, hMeta

   ErrorBlock( {| e | OutStd( "pdfwin: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   Check( "haru by default", HMG_PdfEngine() == "HARU" )

   IF Empty( HMG_PDF_PRINTERNAME() )
      OutStd( "pdfwin: SKIPPED - Microsoft Print to PDF is not installed" + hb_eol() )
      OutStd( "pdfwin: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
      ExitProcess( iif( s_nFail == 0, 0, 1 ) )
   ENDIF

   SET PDFENGINE WINDOWS
   Check( "windows engine", HMG_PdfEngine() == "WINDOWS" )

   // 1. A4 portrait, two pages, the same commands as a printout
   nSecs := Seconds()
   SELECT PRINTER PDF cFile1 TO lOk PAPERSIZE PRINTER_PAPER_A4
   Check( "select",           lOk )
   Check( "gdi path",         _HMG_SYSDATA [ 513 ] == .F. .AND. _HMG_SYSDATA [ 378 ] == .F. )
   START PRINTDOC NAME "hmg pdf test"
      START PRINTPAGE
         @ 20, 20 PRINT "SYNTHETIC INVOICE 2026-27" FONT "Arial" SIZE 16 BOLD
         @ 30, 20 PRINT "Rotated" FONT "Arial" SIZE 12 ANGLE 30
         @ 40, 20 PRINT LINE TO 40, 180 PENWIDTH 0.5
         @ 50, 20 PRINT RECTANGLE TO 80, 180 ROUNDED
         @ 90, 20 PRINT "Multi line text that wraps inside its box" TO 110, 60 FONT "Times New Roman" SIZE 11
      END PRINTPAGE
      START PRINTPAGE
         @ 20, 20 PRINT "Page 2" FONT "Arial" SIZE 12
      END PRINTPAGE
   END PRINTDOC
   OutStd( "pdfwin: document 1 written in " + hb_ntos( Round( Seconds() - nSecs, 1 ) ) + " s" + hb_eol() )

   cPdf := hb_MemoRead( cFile1 )   // END PRINTDOC returned: the file must be complete
   Check( "file complete",    Left( cPdf, 5 ) == "%PDF-" .AND. "%%EOF" $ Right( cPdf, 32 ) )
   Check( "two pages",        PageCount( cPdf ) == 2 )
   aBox := MediaBox( cPdf )
   Check( "A4 portrait",      Near( aBox[ 1 ], 595 ) .AND. Near( aBox[ 2 ], 842 ) )
   // Arial bold, Arial, Times New Roman, embedded (the printer renames them CIDFont+Fn)
   Check( "TrueType embedded", Occurs( cPdf, "/Subtype /CIDFontType2" ) == 3 .AND. "/FontFile2" $ cPdf )
   Check( "text extractable", "/ToUnicode" $ cPdf )
   Check( "vector, no image", Occurs( cPdf, "/Subtype /Image" ) == 0 )
   Check( "not libHaru",      ! "Haru" $ cPdf )

   // 2. landscape; a relative file name is made absolute (the spooler writes the file)
   hb_cwd( cDir )
   SELECT PRINTER PDF hb_FNameNameExt( cFile2 ) TO lOk ORIENTATION PRINTER_ORIENT_LANDSCAPE PAPERSIZE PRINTER_PAPER_A4
   START PRINTDOC
      START PRINTPAGE
         @ 20, 20 PRINT "Landscape" FONT "Arial" SIZE 12
      END PRINTPAGE
   END PRINTDOC
   cPdf := hb_MemoRead( cFile2 )
   aBox := MediaBox( cPdf )
   Check( "relative name",    lOk .AND. Left( cPdf, 5 ) == "%PDF-" )
   Check( "A4 landscape",     Near( aBox[ 1 ], 842 ) .AND. Near( aBox[ 2 ], 595 ) )

   // 3. ABORT PRINTDOC leaves no PDF behind and does not hang
   SELECT PRINTER PDF cFile3 TO lOk PAPERSIZE PRINTER_PAPER_LETTER
   START PRINTDOC
      START PRINTPAGE
         @ 20, 20 PRINT "aborted" FONT "Arial" SIZE 12
      END PRINTPAGE
   ABORT PRINTDOC
   hb_idleSleep( 1 )
   Check( "abort",            ! hb_FileExists( cFile3 ) .OR. hb_FSize( cFile3 ) == 0 )

   // 4. custom paper size: libHaru, as before
   SELECT PRINTER PDF cFile4 TO lOk PAPERSIZE 256 PAPERLENGTH 100 PAPERWIDTH 100
   Check( "custom -> haru",   lOk .AND. _HMG_SYSDATA [ 513 ] == .T. )
   START PRINTDOC
      START PRINTPAGE
         @ 20, 20 PRINT "custom" SIZE 12
      END PRINTPAGE
   END PRINTDOC
   Check( "haru file",        "Haru" $ hb_MemoRead( cFile4 ) )

   // 5. preview pages (EMF, as SELECT PRINTER ... PREVIEW records them) to a vector PDF
   aProps := _HMG_PRINTER_SetPrinterProperties( HMG_PDF_PRINTERNAME(), 1, PRINTER_PAPER_A4, -999, -999, -999, -999, -999, -999, -999, -999 )
   hDC := aProps[ 1 ]
   FOR i := 1 TO 3
      cEmf := cDir + "hmgpdf_" + cTag + "_p" + hb_ntos( i ) + ".emf"
      AAdd( aEmf, cEmf )
      hMeta := _HMG_PRINTER_STARTPAGE_PREVIEW( hDC, cEmf )
      _HMG_PRINTER_H_PRINT( hMeta, 20, 20, "Arial", 14, 0, 0, 0, "Preview page " + hb_ntos( i ), ;
                            .F., .F., .F., .F., .F., .T., .T., NIL, NIL )
      _HMG_PRINTER_ENDPAGE_PREVIEW( hMeta )
   NEXT
   Check( "emf pages",        Len( aEmf ) == 3 )
   Check( "fromemf",          HMG_PDF_FROMEMF( aEmf, cFile5 ) )
   cPdf := hb_MemoRead( cFile5 )
   aBox := MediaBox( cPdf )
   Check( "emf three pages",  PageCount( cPdf ) == 3 )
   Check( "emf A4",           Near( aBox[ 1 ], 595 ) .AND. Near( aBox[ 2 ], 842 ) )
   Check( "emf vector",       Occurs( cPdf, "/Subtype /Image" ) == 0 .AND. Occurs( cPdf, "/Subtype /CIDFontType2" ) == 1 )

   SET PDFENGINE HARU
   Check( "haru again",       HMG_PdfEngine() == "HARU" )

   IF Empty( hb_GetEnv( "PDFWIN_KEEP" ) )   // PDFWIN_KEEP=1 keeps the files for inspection
      AEval( { cFile1, cFile2, cFile3, cFile4, cFile5 }, {| f | FErase( f ) } )
   ENDIF
   AEval( aEmf, {| f | FErase( f ) } )

   OutStd( "pdfwin: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

/* plain searches: the file holds binary streams */

/* pages: "/Type /Page" objects (not "/Pages") */
STATIC FUNCTION PageCount( cPdf )
RETURN Occurs( cPdf, "/Type /Page" ) - Occurs( cPdf, "/Type /Pages" )

STATIC FUNCTION Occurs( cPdf, cWhat )
   LOCAL n := 0, nPos := 0
   DO WHILE ( nPos := hb_At( cWhat, cPdf, nPos + 1 ) ) > 0
      n++
   ENDDO
RETURN n

/* { width, height } in points of the first page */
STATIC FUNCTION MediaBox( cPdf )
   LOCAL nPos := hb_At( "/MediaBox", cPdf ), nEnd := 0, a
   IF nPos > 0
      nPos := hb_At( "[", cPdf, nPos )
   ENDIF
   IF nPos > 0
      nEnd := hb_At( "]", cPdf, nPos )
   ENDIF
   IF nEnd == 0
      RETURN { 0, 0 }
   ENDIF
   a := hb_ATokens( AllTrim( SubStr( cPdf, nPos + 1, nEnd - nPos - 1 ) ), " " )
   IF Len( a ) < 4
      RETURN { 0, 0 }
   ENDIF
RETURN { Val( a[ 3 ] ) - Val( a[ 1 ] ), Val( a[ 4 ] ) - Val( a[ 2 ] ) }

STATIC FUNCTION Near( a, b )
RETURN Abs( a - b ) <= 2

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "pdfwin: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
