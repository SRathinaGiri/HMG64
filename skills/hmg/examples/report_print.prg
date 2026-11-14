/*
 * Printing with HMG's print system: a small invoice to a printer of the user's choice with a
 * preview, or straight to a PDF file. The same @ ... PRINT commands serve both; units are
 * millimetres from the top-left corner of the page.
 * Build and run:  build64 report_print.prg
 */
#include "hmg.ch"

FUNCTION Main()

   DEFINE WINDOW Win_Main AT 0, 0 WIDTH 400 HEIGHT 170 TITLE "Print an invoice" MAIN
      @ 20, 20 BUTTON Btn_Preview CAPTION "Printer (with preview)" WIDTH 340 HEIGHT 30 ACTION PrintInvoice( .F. )
      @ 60, 20 BUTTON Btn_Pdf     CAPTION "Save as PDF..."         WIDTH 340 HEIGHT 30 ACTION PrintInvoice( .T. )
   END WINDOW

   Win_Main.Center
   Win_Main.Activate
RETURN NIL

STATIC PROCEDURE PrintInvoice( lPdf )
   LOCAL lOk := .F., cFile, aLines, a, nRow, nTotal := 0

   aLines := { { "Notebook A4",  4,  85.00 }, { "Pen set",     2, 120.00 }, { "Stapler", 1, 245.50 } }

   IF lPdf
      cFile := PutFile( { { "PDF files", "*.pdf" } }, "Save invoice", , .T., "invoice.pdf" )
      IF Empty( cFile )
         RETURN
      ENDIF
      SELECT PRINTER PDF cFile TO lOk
   ELSE
      SELECT PRINTER DIALOG TO lOk PREVIEW
   ENDIF
   IF ! lOk
      RETURN
   ENDIF

   START PRINTDOC NAME "Invoice"
      START PRINTPAGE
         @ 20, 20 PRINT "INVOICE" FONT "Arial" SIZE 20 BOLD
         @ 30, 20 PRINT "No. 2026-0042    Date: " + DToC( Date() ) FONT "Arial" SIZE 10
         @ 40, 20 PRINT LINE TO 40, 190 PENWIDTH 0.5
         @ 44, 20  PRINT "Item"   FONT "Arial" SIZE 10 BOLD
         @ 44, 120 PRINT "Qty"    FONT "Arial" SIZE 10 BOLD
         @ 44, 190 PRINT "Amount" FONT "Arial" SIZE 10 BOLD RIGHT
         nRow := 52
         FOR EACH a IN aLines
            @ nRow, 20  PRINT a[ 1 ] FONT "Arial" SIZE 10
            @ nRow, 120 PRINT hb_ntos( a[ 2 ] ) FONT "Arial" SIZE 10
            @ nRow, 190 PRINT Transform( a[ 2 ] * a[ 3 ], "99,999.99" ) FONT "Arial" SIZE 10 RIGHT
            nTotal += a[ 2 ] * a[ 3 ]
            nRow += 7
         NEXT
         @ nRow + 2, 120 PRINT LINE TO nRow + 2, 190
         @ nRow + 5, 120 PRINT "Total" FONT "Arial" SIZE 11 BOLD
         @ nRow + 5, 190 PRINT Transform( nTotal, "99,999.99" ) FONT "Arial" SIZE 11 BOLD RIGHT
         @ nRow + 20, 20 PRINT RECTANGLE TO nRow + 40, 190 PENWIDTH 0.3
         @ nRow + 24, 25 PRINT "Thank you for your business." FONT "Arial" SIZE 10 ITALIC
      END PRINTPAGE
   END PRINTDOC

   IF lPdf .AND. hb_FileExists( cFile )
      MsgInfo( "Saved: " + cFile, "Invoice" )
   ENDIF
RETURN
