/*----------------------------------------------------------------------------
 HMG5 - PDF through the Windows printing pipeline (Phase 4 P), see PHASE4-DESIGN.md
 section 5.

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 SET PDFENGINE WINDOWS: SELECT PRINTER PDF opens the "Microsoft Print to PDF"
 printer (part of Windows 10/11) and the document is drawn by the same GDI code
 as a printout, so the PDF matches print and preview: every Windows font,
 Unicode text, rotated text, all image types, selectable text.

 - The file name goes to StartDoc (DOCINFO.lpszOutput): no Save dialog.
 - The spooler writes the file after EndDoc; END PRINTDOC waits until the job
   has left the queue and the file is closed, so the program can use it at once.
 - The print preview's "Save as PDF" sends its EMF pages through the same
   printer (vector) instead of 300-DPI JPEG pages.
---------------------------------------------------------------------------*/

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <winspool.h>

#include "hbapi.h"
#include "hbapiitm.h"

static TCHAR * s_cOutput  = NULL;   // file for the next StartDoc
static TCHAR * s_cPrinter = NULL;   // printer it is printed on
static DWORD   s_nJob     = 0;      // job of the running document
static HDC     s_hDC      = NULL;   // printer DC it applies to (SELECT PRINTER PDF)

static TCHAR * pdf_dup( LPCTSTR c )
{
   TCHAR * p = NULL;
   if( c && *c )
   {
      p = ( TCHAR * ) hb_xgrab( ( lstrlen( c ) + 1 ) * sizeof( TCHAR ) );
      lstrcpy( p, c );
   }
   return p;
}

static void pdf_clear( void )
{
   if( s_cOutput )
      hb_xfree( s_cOutput );
   if( s_cPrinter )
      hb_xfree( s_cPrinter );
   s_cOutput  = NULL;
   s_cPrinter = NULL;
   s_nJob     = 0;
   s_hDC      = NULL;
}

/* name of the installed "Microsoft Print To PDF" printer (found by driver, the
   queue may be renamed), into cName; FALSE when there is none */
static BOOL pdf_printerName( TCHAR * cName, DWORD nName )
{
   DWORD nNeeded = 0, nCount = 0, i;
   PRINTER_INFO_2 * pInfo;
   BOOL lFound = FALSE;

   EnumPrinters( PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, NULL, 2, NULL, 0, &nNeeded, &nCount );
   if( nNeeded == 0 )
      return FALSE;
   pInfo = ( PRINTER_INFO_2 * ) hb_xgrab( nNeeded );
   if( EnumPrinters( PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, NULL, 2, ( LPBYTE ) pInfo, nNeeded, &nNeeded, &nCount ) )
   {
      for( i = 0; i < nCount && ! lFound; i++ )
      {
         if( pInfo[ i ].pDriverName && lstrcmpi( pInfo[ i ].pDriverName, _TEXT( "Microsoft Print To PDF" ) ) == 0
             && pInfo[ i ].pPrinterName && ( DWORD ) lstrlen( pInfo[ i ].pPrinterName ) < nName )
         {
            lstrcpy( cName, pInfo[ i ].pPrinterName );
            lFound = TRUE;
         }
      }
   }
   hb_xfree( pInfo );
   return lFound;
}

/* wait until the spooler has finished job nJob and cFile is complete (closed) */
static BOOL pdf_wait( LPCTSTR cPrinter, DWORD nJob, LPCTSTR cFile, DWORD nTimeoutMs )
{
   DWORD nStart = GetTickCount();
   HANDLE hPrinter = NULL;
   BOOL lDone = FALSE;

   if( cPrinter && nJob && OpenPrinter( ( LPTSTR ) cPrinter, &hPrinter, NULL ) )
   {
      for( ;; )
      {
         DWORD nNeeded = 0;
         if( ! GetJob( hPrinter, nJob, 1, NULL, 0, &nNeeded ) && GetLastError() != ERROR_INSUFFICIENT_BUFFER )
            break;   // the job has left the queue
         if( nNeeded )
         {
            JOB_INFO_1 * pJob = ( JOB_INFO_1 * ) hb_xgrab( nNeeded );
            BOOL lGot = GetJob( hPrinter, nJob, 1, ( LPBYTE ) pJob, nNeeded, &nNeeded );
            DWORD nStatus = lGot ? pJob->Status : 0;
            hb_xfree( pJob );
            if( ! lGot )
               break;
            if( nStatus & ( JOB_STATUS_ERROR | JOB_STATUS_DELETED | JOB_STATUS_DELETING ) )
            {
               ClosePrinter( hPrinter );
               return FALSE;
            }
            if( nStatus & ( JOB_STATUS_PRINTED | JOB_STATUS_COMPLETE ) )
               break;
         }
         if( GetTickCount() - nStart > nTimeoutMs )
         {
            ClosePrinter( hPrinter );
            return FALSE;
         }
         Sleep( 50 );
      }
      ClosePrinter( hPrinter );
   }

   // the file exists and nobody writes it any more
   while( cFile && ! lDone )
   {
      HANDLE h = CreateFile( cFile, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL );
      if( h != INVALID_HANDLE_VALUE )
      {
         lDone = GetFileSize( h, NULL ) > 0;
         CloseHandle( h );
      }
      if( ! lDone )
      {
         if( GetTickCount() - nStart > nTimeoutMs )
            break;
         Sleep( 50 );
      }
   }
   return lDone;
}

/* --- called from c_controlmisc.c (_HMG_PRINTER_STARTDOC / ENDDOC / ABORTDOC) --- */

LPCTSTR HMG_PdfOutput( HDC hdc )
{
   return ( s_cOutput && hdc == s_hDC ) ? s_cOutput : NULL;
}

void HMG_PdfJobStarted( HDC hdc, int nJob )
{
   if( s_cOutput && hdc == s_hDC )
   {
      if( nJob > 0 )
         s_nJob = ( DWORD ) nJob;
      else
         pdf_clear();
   }
}

void HMG_PdfJobEnded( HDC hdc, BOOL lAborted )
{
   if( s_cOutput && hdc == s_hDC )
   {
      if( ! lAborted )
         pdf_wait( s_cPrinter, s_nJob, s_cOutput, 60000 );
      pdf_clear();
   }
}

/* HMG_PDF_PRINTERNAME() -> cName of the Windows PDF printer, "" when not installed */
HB_FUNC( HMG_PDF_PRINTERNAME )
{
   TCHAR cName[ 512 ];
   if( pdf_printerName( cName, 512 ) )
      HMG_retc( cName );
   else
      hb_retc( "" );
}

/* HMG_PDF_SETOUTPUT( cFile, cPrinter, hDC ): the next document printed on hDC (a DC of
   cPrinter, from SELECT PRINTER) goes to cFile.
   HMG_PDF_SETOUTPUT() cancels it. */
HB_FUNC( HMG_PDF_SETOUTPUT )
{
   pdf_clear();
   if( HB_ISCHAR( 1 ) && hb_parclen( 1 ) > 0 && HB_ISCHAR( 2 ) && hb_parclen( 2 ) > 0 && HMG_parnl( 3 ) != 0 )
   {
      s_hDC      = ( HDC ) HMG_parnl( 3 );
      s_cOutput  = pdf_dup( HMG_parc( 1 ) );
      s_cPrinter = pdf_dup( HMG_parc( 2 ) );
      DeleteFile( s_cOutput );   // a stale file would satisfy the wait for the new one
   }
}

/* paper (DMPAPER_*) and orientation for a page of w x h (0.01 mm, printable area of the
   printer the preview was made for); the closest standard sheet that holds it */
static void pdf_paperFor( LONG w, LONG h, short * pnPaper, short * pnOrient )
{
   static const struct { short n; LONG w, h; } s_aPaper[] = {
      { DMPAPER_A5,        14800, 21000 },
      { DMPAPER_B5,        18200, 25700 },
      { DMPAPER_EXECUTIVE, 18415, 26670 },
      { DMPAPER_A4,        21000, 29700 },
      { DMPAPER_LETTER,    21590, 27940 },
      { DMPAPER_LEGAL,     21590, 35560 },
      { DMPAPER_TABLOID,   27940, 43180 },
      { DMPAPER_A3,        29700, 42000 } };
   LONG nShort = w < h ? w : h, nLong = w < h ? h : w, nBest = -1;
   size_t i;

   *pnOrient = ( w > h ) ? DMORIENT_LANDSCAPE : DMORIENT_PORTRAIT;
   *pnPaper  = DMPAPER_A4;
   for( i = 0; i < sizeof( s_aPaper ) / sizeof( s_aPaper[ 0 ] ); i++ )
   {
      LONG dw = s_aPaper[ i ].w - nShort, dh = s_aPaper[ i ].h - nLong;
      if( dw >= -100 && dh >= -100 && dw <= 2500 && dh <= 2500 )   // fits (1 mm slack), margins up to 25 mm
      {
         if( nBest < 0 || dw + dh < nBest )
         {
            nBest = dw + dh;
            *pnPaper = s_aPaper[ i ].n;
         }
      }
   }
}

static HDC pdf_createDC( LPCTSTR cPrinter, short nPaper, short nOrient )
{
   HANDLE hPrinter = NULL;
   HDC hdc = NULL;
   if( OpenPrinter( ( LPTSTR ) cPrinter, &hPrinter, NULL ) )
   {
      LONG nSize = DocumentProperties( NULL, hPrinter, ( LPTSTR ) cPrinter, NULL, NULL, 0 );
      if( nSize > 0 )
      {
         DEVMODE * pdm = ( DEVMODE * ) hb_xgrab( nSize );
         if( DocumentProperties( NULL, hPrinter, ( LPTSTR ) cPrinter, pdm, NULL, DM_OUT_BUFFER ) == IDOK )
         {
            pdm->dmFields     |= DM_PAPERSIZE | DM_ORIENTATION;
            pdm->dmPaperSize   = nPaper;
            pdm->dmOrientation = nOrient;
            if( DocumentProperties( NULL, hPrinter, ( LPTSTR ) cPrinter, pdm, pdm, DM_IN_BUFFER | DM_OUT_BUFFER ) == IDOK )
               hdc = CreateDC( NULL, cPrinter, NULL, pdm );
         }
         hb_xfree( pdm );
      }
      ClosePrinter( hPrinter );
   }
   return hdc;
}

/* HMG_PDF_FROMEMF( aEmfFiles, cPdfFile [, cDocName] ) -> lOk
   One PDF page per EMF page (vector), on the standard sheet that fits the first page. */
HB_FUNC( HMG_PDF_FROMEMF )
{
   PHB_ITEM pFiles = hb_param( 1, HB_IT_ARRAY );
   TCHAR cPrinter[ 512 ];
   HENHMETAFILE hFirst;
   ENHMETAHEADER emh;
   short nPaper, nOrient;
   HDC hdc;
   DOCINFO di;
   int nJob;
   HB_SIZE n, i;
   BOOL lOk = TRUE;
   TCHAR * cOut;

   hb_retl( FALSE );
   if( ! pFiles || ( n = hb_arrayLen( pFiles ) ) == 0 || ! HB_ISCHAR( 2 ) || ! pdf_printerName( cPrinter, 512 ) )
      return;

   hFirst = GetEnhMetaFile( HMG_arrayGetCPtr( pFiles, 1 ) );
   if( ! hFirst )
      return;
   GetEnhMetaFileHeader( hFirst, sizeof( emh ), &emh );
   DeleteEnhMetaFile( hFirst );
   pdf_paperFor( emh.rclFrame.right - emh.rclFrame.left, emh.rclFrame.bottom - emh.rclFrame.top, &nPaper, &nOrient );

   hdc = pdf_createDC( cPrinter, nPaper, nOrient );
   if( ! hdc )
      return;

   cOut = pdf_dup( HMG_parc( 2 ) );
   DeleteFile( cOut );   // a stale file would satisfy the wait below
   ZeroMemory( &di, sizeof( di ) );
   di.cbSize      = sizeof( di );
   di.lpszDocName = HB_ISCHAR( 3 ) ? HMG_parc( 3 ) : _TEXT( "HMG" );
   di.lpszOutput  = cOut;
   nJob = StartDoc( hdc, &di );
   if( nJob > 0 )
   {
      int w = GetDeviceCaps( hdc, HORZRES ), h = GetDeviceCaps( hdc, VERTRES );
      for( i = 1; i <= n && lOk; i++ )
      {
         HENHMETAFILE hEmf = GetEnhMetaFile( HMG_arrayGetCPtr( pFiles, i ) );
         if( hEmf )
         {
            // the page keeps its size in millimetres, from the top-left of the printable area
            ENHMETAHEADER eh;
            RECT rc;
            GetEnhMetaFileHeader( hEmf, sizeof( eh ), &eh );
            SetRect( &rc, 0, 0,
                     MulDiv( eh.rclFrame.right - eh.rclFrame.left, w, GetDeviceCaps( hdc, HORZSIZE ) * 100 ),
                     MulDiv( eh.rclFrame.bottom - eh.rclFrame.top, h, GetDeviceCaps( hdc, VERTSIZE ) * 100 ) );
            lOk = StartPage( hdc ) > 0 && PlayEnhMetaFile( hdc, hEmf, &rc ) && EndPage( hdc ) > 0;
            DeleteEnhMetaFile( hEmf );
         }
         else
            lOk = FALSE;
      }
      if( lOk )
      {
         EndDoc( hdc );
         lOk = pdf_wait( cPrinter, ( DWORD ) nJob, cOut, 60000 );
      }
      else
         AbortDoc( hdc );
   }
   else
      lOk = FALSE;
   DeleteDC( hdc );
   hb_xfree( cOut );
   hb_retl( lOk );
}
