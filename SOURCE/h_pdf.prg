/*----------------------------------------------------------------------------
 HMG5 - PDF engine choice (Phase 4 P), PRG side. C side and the rules: c_pdf.c.

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).
---------------------------------------------------------------------------*/

MEMVAR _HMG_SYSDATA

#include "hmg.ch"

STATIC s_cEngine := "HARU"

/* HMG_SetPdfEngine( "WINDOWS" | "HARU" ) -> cPrevious
   SET PDFENGINE WINDOWS / HARU. WINDOWS: SELECT PRINTER PDF and the preview's
   "Save as PDF" use the Windows PDF printer (same drawing as a printout).
   HARU (default): libHaru, as before. May be switched at any time. */
FUNCTION HMG_SetPdfEngine( cEngine )
   LOCAL cOld := s_cEngine
   IF HB_ISCHAR( cEngine ) .AND. Upper( AllTrim( cEngine ) ) $ "WINDOWS HARU"
      s_cEngine := Upper( AllTrim( cEngine ) )
   ENDIF
RETURN cOld

FUNCTION HMG_PdfEngine()
RETURN s_cEngine

/* SELECT PRINTER PDF <cFile> ... -> lSuccess
   WINDOWS engine: opens the Windows PDF printer like SELECT PRINTER does (no preview) and
   sends the next document to cFile. Falls back to libHaru when the printer is not
   installed or a custom paper size (PAPERLENGTH / PAPERWIDTH) is asked for. */
FUNCTION _HMG_PDF_SELECT( cFile, nOrientation, nPaperSize, nPaperLength, nPaperWidth, lLog )
   LOCAL cPrinter, aProps

   IF s_cEngine == "WINDOWS" .AND. nPaperLength == -999 .AND. nPaperWidth == -999 .AND. ;
      nPaperSize != 256 .AND. ! Empty( cPrinter := HMG_PDF_PRINTERNAME() )

      aProps := _HMG_PRINTER_SetPrinterProperties( cPrinter, nOrientation, nPaperSize, ;
                -999, -999, -999, -999, -999, -999, -999, -999 )
      IF HB_ISARRAY( aProps ) .AND. aProps [ 1 ] != 0
         _HMG_SYSDATA [ 513 ] := .F.
         _HMG_SYSDATA [ 373 ] := aProps
         _HMG_SYSDATA [ 374 ] := aProps [ 1 ]
         _HMG_SYSDATA [ 376 ] := aProps [ 3 ]
         _HMG_SYSDATA [ 377 ] := aProps [ 4 ]
         _HMG_SYSDATA [ 378 ] := .F.          // no preview
         _HMG_SYSDATA [ 505 ] := .F.
         _HMG_SYSDATA [ 506 ] := NIL
         _HMG_SYSDATA [ 507 ] := NIL
         _HMG_SYSDATA [ 508 ] := .F.
         _hmg_printer_InitUserMessages()
         _HMG_SYSDATA [ 379 ] := StrZero( Seconds() * 100, 8 )
         _HMG_SYSDATA [ 375 ] := cPrinter
         _HMG_SYSDATA [ 286 ] := .F.
         _HMG_SYSDATA [ 287 ] := .F.
         // the spooler writes the file: it needs a full path
         HMG_PDF_SETOUTPUT( _HMG_PDF_FULLPATH( cFile ), cPrinter, aProps [ 1 ] )
         RETURN .T.
      ENDIF
   ENDIF

   _HMG_SYSDATA [ 513 ] := .T.
RETURN _HMG_HPDF_INIT( cFile, nOrientation, nPaperSize, nPaperLength, nPaperWidth, lLog )

FUNCTION _HMG_PDF_FULLPATH( cFile )
   cFile := AllTrim( cFile )
   IF ! ( SubStr( cFile, 2, 1 ) == ":" .OR. Left( cFile, 2 ) == "\\" )
      cFile := hb_DirSepAdd( hb_cwd() ) + iif( Left( cFile, 1 ) == "\", SubStr( cFile, 2 ), cFile )
   ENDIF
RETURN cFile

FUNCTION _HMG_PDF_EMFPATHS( cFolder, aNames )
   LOCAL aPaths := Array( Len( aNames ) ), i
   FOR i := 1 TO Len( aNames )
      aPaths [ i ] := cFolder + aNames [ i ]
   NEXT
RETURN aPaths
