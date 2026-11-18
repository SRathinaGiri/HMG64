/*
 * HMG5 5.2 - HTTP and HTTPS without OpenSSL (c_http.c, on Windows' WinHTTP).
 *
 *   a := HMG_HttpGet( cUrl [, aHeaders] [, nTimeoutMs] )
 *   a := HMG_HttpPost( cUrl, cBody [, cContentType] [, aHeaders] [, nTimeoutMs] )
 *   a := HMG_HttpRequest( cMethod, cUrl [, cBody] [, aHeaders] [, nTimeoutMs] [, cContentType] )
 *
 *   a[ 1 ] status (200 ...; 0 when no answer came), a[ 2 ] body, a[ 3 ] error text ("" when
 *   fine), a[ 4 ] response headers. The call waits for the answer.
 */

#include "hmg.ch"

FUNCTION HMG_HttpGet( cUrl, aHeaders, nTimeoutMs )
RETURN HMG_HTTPREQUEST( "GET", cUrl, NIL, aHeaders, nTimeoutMs )

/* cContentType by default from the body: JSON ({ or [), XML (<), otherwise a form */
FUNCTION HMG_HttpPost( cUrl, cBody, cContentType, aHeaders, nTimeoutMs )
   LOCAL c
   IF ! HB_ISSTRING( cBody )
      cBody := ""
   ENDIF
   IF ! HB_ISSTRING( cContentType ) .OR. Empty( cContentType )
      c := Left( LTrim( StrTran( StrTran( cBody, Chr( 13 ), "" ), Chr( 10 ), "" ) ), 1 )
      DO CASE
      CASE c == "{" .OR. c == "["
         cContentType := "application/json; charset=utf-8"
      CASE c == "<"
         cContentType := "text/xml; charset=utf-8"
      OTHERWISE
         cContentType := "application/x-www-form-urlencoded"
      ENDCASE
   ENDIF
RETURN HMG_HTTPREQUEST( "POST", cUrl, cBody, aHeaders, nTimeoutMs, cContentType )
