/*
 * Regression test: HMG's PDF commands (SELECT HPDFDOC / HPDFPRINT) work against the
 * bundled libHaru. Phase 2b replaced HMG's stale 2.2.1 headers with the 2.3.0 ones
 * that match the linked library; this proves a document is still produced.
 * Synthetic data only.
 */
#include "hmg.ch"
#include "hmg_hpdf.ch"

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   LOCAL cFile := hb_DirTemp() + "hmg_hpdf_test_" + hb_ntos( hb_RandomInt( 100000, 999999 ) ) + ".pdf"
   LOCAL lOk := .F., cPdf

   // A runtime error must fail the test, not open HMG's modal "Program Error" box
   // (which would block the unattended test run).
   ErrorBlock( {| e | OutStd( "hpdf: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ErrorLevel( 2 ), __Quit() } )

   SELECT HPDFDOC cFile TO lOk PAPERSIZE HPDF_PAPER_A4
   Check( "select", lOk )
   SET HPDFDOC COMPRESS NONE
   START HPDFDOC
      START HPDFPAGE
         @ 20, 20 HPDFPRINT "SYNTHETIC INVOICE 2026-27" FONT "Helvetica" SIZE 14 BOLD
         @ 30, 20 HPDFPRINT "Line two, right aligned" SIZE 10 RIGHT
         @ 40, 20 HPDFPRINT LINE TO 40, 180
         @ 50, 20 HPDFPRINT RECTANGLE TO 80, 180
      END HPDFPAGE
      START HPDFPAGE
         @ 20, 20 HPDFPRINT "Page 2" SIZE 12
      END HPDFPAGE
   END HPDFDOC

   Check( "file written", hb_FileExists( cFile ) )
   cPdf := hb_MemoRead( cFile )
   Check( "pdf header",   Left( cPdf, 5 ) == "%PDF-" )
   Check( "pdf trailer",  "%%EOF" $ Right( cPdf, 32 ) )
   Check( "two pages",    "/Count 2" $ cPdf )
   Check( "text present", "SYNTHETIC INVOICE" $ cPdf )
   FErase( cFile )

   OutStd( "hpdf: " + hb_ntos( Len( cPdf ) ) + " bytes, PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ErrorLevel( iif( s_nFail == 0, 0, 1 ) )
   RETURN NIL

STATIC PROCEDURE Check( cName, lOk )
   IF lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "FAIL " + cName + hb_eol() )
   ENDIF
   RETURN
