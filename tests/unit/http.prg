/*
 * Unit test for HMG_HttpGet / HMG_HttpPost / HMG_HttpRequest (HMG5 5.2, c_http.c, WinHTTP).
 * No internet: the test starts its own small HTTP server on 127.0.0.1 (a C thread below)
 * and checks methods, headers, bodies, status codes, a redirect, a UTF-16 answer, a
 * timeout (approximate: WinHTTP retries once) and the error texts. HMG_TEST_INTERNET=1 also fetches https://example.com.
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   LOCAL nPort, cBase, a, cRaw, cUtf8 := "héllo ₹ नमस्ते"

   ErrorBlock( {| e | OutStd( "http: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   nPort := TESTSERVER_START()
   Check( "test server started", nPort > 0 )
   cBase := "http://127.0.0.1:" + hb_ntos( nPort )

   // GET, a UTF-8 body, the response headers
   a := HMG_HttpGet( cBase + "/hello" )
   Check( "GET status 200", a[ 1 ] == 200 )
   Check( "GET body (UTF-8 kept)", a[ 2 ] == cUtf8 )
   Check( "GET no error", a[ 3 ] == "" )
   Check( "response headers", "X-Server: hmgtest" $ a[ 4 ] )

   // the request as the server saw it: method, path, query, headers, body
   a := HMG_HttpGet( cBase + "/echo?q=1&w=a%20b", { "X-Test: abc", { "X-Pair", "pair value" } } )
   cRaw := a[ 2 ]
   Check( "GET request line", hb_LeftEq( cRaw, "GET /echo?q=1&w=a%20b HTTP/1.1" ) )
   Check( "header string", "X-Test: abc" $ cRaw )
   Check( "header pair", "X-Pair: pair value" $ cRaw )

   a := HMG_HttpPost( cBase + "/echo", '{ "name": "' + cUtf8 + '" }' )
   cRaw := a[ 2 ]
   Check( "POST request line", hb_LeftEq( cRaw, "POST /echo HTTP/1.1" ) )
   Check( "POST JSON content type guessed", "Content-Type: application/json; charset=utf-8" $ cRaw )
   Check( "POST body bytes unchanged", EndsWith( cRaw, '{ "name": "' + cUtf8 + '" }' ) )

   a := HMG_HttpPost( cBase + "/echo", "<a>1</a>" )
   Check( "POST XML content type guessed", "Content-Type: text/xml; charset=utf-8" $ a[ 2 ] )
   a := HMG_HttpPost( cBase + "/echo", "a=1&b=2" )
   Check( "POST form content type guessed", "Content-Type: application/x-www-form-urlencoded" $ a[ 2 ] )
   a := HMG_HttpPost( cBase + "/echo", "plain", "text/plain" )
   Check( "POST explicit content type", "Content-Type: text/plain" $ a[ 2 ] )

   a := HMG_HttpRequest( "PUT", cBase + "/echo", "put body", { "Authorization: Bearer xyz" } )
   Check( "PUT method, body and header", hb_LeftEq( a[ 2 ], "PUT /echo HTTP/1.1" ) .AND. ;
          "Authorization: Bearer xyz" $ a[ 2 ] .AND. EndsWith( a[ 2 ], "put body" ) )
   a := HMG_HttpRequest( "DELETE", cBase + "/echo" )
   Check( "DELETE", hb_LeftEq( a[ 2 ], "DELETE /echo HTTP/1.1" ) )

   // status codes, a redirect, a UTF-16 answer
   a := HMG_HttpGet( cBase + "/status/404" )
   Check( "404 is a status, not an error", a[ 1 ] == 404 .AND. a[ 2 ] == "nope" .AND. a[ 3 ] == "" )
   a := HMG_HttpGet( cBase + "/redirect" )
   Check( "redirect followed", a[ 1 ] == 200 .AND. a[ 2 ] == cUtf8 )
   a := HMG_HttpGet( cBase + "/utf16" )
   // UNICODE mode: UTF-8; ANSI mode: the Windows code page, where ₹ has no place and becomes "?"
   Check( "UTF-16 answer converted (as Tally sends): " + a[ 2 ], a[ 1 ] == 200 .AND. ;
          iif( HMG_SupportUnicode(), a[ 2 ] == "Tally ₹ data", hb_LeftEq( a[ 2 ], "Tally " ) .AND. EndsWith( a[ 2 ], " data" ) .AND. Len( a[ 2 ] ) == 12 ) )

   // errors: no answer gives status 0 and Windows' reason
   a := HMG_HttpGet( "http://127.0.0.1:1/" )
   Check( "closed port: WinHTTP 12029", a[ 1 ] == 0 .AND. "WinHTTP 12029" $ a[ 3 ] )
   a := HMG_HttpGet( "not a url" )
   Check( "bad URL: an error", a[ 1 ] == 0 .AND. "WinHTTP" $ a[ 3 ] )
   a := HMG_HttpGet( "https://127.0.0.1:" + hb_ntos( nPort ) + "/hello" , , 3000 )
   Check( "HTTPS to a plain server: a TLS error", a[ 1 ] == 0 .AND. "WinHTTP" $ a[ 3 ] )
   a := HMG_HttpGet( "" )
   Check( "empty URL", a[ 1 ] == 0 .AND. ! Empty( a[ 3 ] ) )

   // a timeout, last (the test server answers one request at a time): WinHTTP tries a timed-out
   // request once more, so a 2 s limit ends after about 4 s, still well before the server's 10 s
   cRaw := hb_MilliSeconds()
   a := HMG_HttpGet( cBase + "/slow10", , 2000 )
   cRaw := hb_MilliSeconds() - cRaw
   Check( "timeout: status 0 and WinHTTP 12002 (" + hb_ntos( cRaw ) + " ms)", a[ 1 ] == 0 .AND. "WinHTTP 12002" $ a[ 3 ] .AND. cRaw < 8000 )
   IF GetEnv( "HMG_TEST_INTERNET" ) == "1"
      a := HMG_HttpGet( "https://example.com/" )
      Check( "internet: https://example.com", a[ 1 ] == 200 .AND. "Example Domain" $ a[ 2 ] )
   ENDIF

   TESTSERVER_STOP()
   OutStd( "http: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC FUNCTION EndsWith( c, cEnd )
RETURN Len( c ) >= Len( cEnd ) .AND. Right( c, Len( cEnd ) ) == cEnd

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "http: FAIL " + cName + hb_eol() )
   ENDIF
RETURN

#pragma BEGINDUMP
#include <winsock2.h>
#include <windows.h>
#include <string.h>
#include <stdio.h>
#include "hbapi.h"

static SOCKET s_listen = INVALID_SOCKET;

static void srv_send( SOCKET c, const char * szStatus, const char * szType, const char * pBody, int nBody, const char * szExtra )
{
   char head[ 512 ];
   int  n = snprintf( head, sizeof( head ),
                      "HTTP/1.1 %s\r\nX-Server: hmgtest\r\nContent-Type: %s\r\nContent-Length: %d\r\n%sConnection: close\r\n\r\n",
                      szStatus, szType, nBody, szExtra ? szExtra : "" );
   send( c, head, n, 0 );
   if( nBody > 0 )
      send( c, pBody, nBody, 0 );
}

static void srv_handle( SOCKET c )
{
   static char buf[ 65536 ];
   int    n = 0, r, nHead = -1, nLen = 0;
   char   szMethod[ 16 ] = "", szPath[ 512 ] = "";
   char * p;

   while( n < ( int ) sizeof( buf ) - 1 )   /* the head, then Content-Length bytes */
   {
      r = recv( c, buf + n, ( int ) sizeof( buf ) - 1 - n, 0 );
      if( r <= 0 )
         break;
      n += r;
      buf[ n ] = 0;
      if( nHead < 0 && ( p = strstr( buf, "\r\n\r\n" ) ) != NULL )
      {
         char * q = buf;
         nHead = ( int ) ( p - buf ) + 4;
         for( ; q < p; q++ )
            if( _strnicmp( q, "\ncontent-length:", 16 ) == 0 )
               nLen = atoi( q + 16 );
      }
      if( nHead >= 0 && n >= nHead + nLen )
         break;
   }
   if( nHead < 0 )
      return;
   sscanf( buf, "%15s %511s", szMethod, szPath );

   if( strcmp( szPath, "/hello" ) == 0 )
   {
      const char * s = "h\xC3\xA9llo \xE2\x82\xB9 \xE0\xA4\xA8\xE0\xA4\xAE\xE0\xA4\xB8\xE0\xA5\x8D\xE0\xA4\xA4\xE0\xA5\x87";
      srv_send( c, "200 OK", "text/plain; charset=utf-8", s, ( int ) strlen( s ), NULL );
   }
   else if( strncmp( szPath, "/echo", 5 ) == 0 )
      srv_send( c, "200 OK", "application/octet-stream", buf, n, NULL );
   else if( strcmp( szPath, "/status/404" ) == 0 )
      srv_send( c, "404 Not Found", "text/plain", "nope", 4, NULL );
   else if( strcmp( szPath, "/redirect" ) == 0 )
      srv_send( c, "302 Found", "text/plain", "", 0, "Location: /hello\r\n" );
   else if( strcmp( szPath, "/utf16" ) == 0 )
   {
      static const unsigned char s[] = { 0xFF, 0xFE, 'T', 0, 'a', 0, 'l', 0, 'l', 0, 'y', 0, ' ', 0, 0xB9, 0x20,
                                         ' ', 0, 'd', 0, 'a', 0, 't', 0, 'a', 0 };
      srv_send( c, "200 OK", "text/xml", ( const char * ) s, ( int ) sizeof( s ), NULL );
   }
   else if( strcmp( szPath, "/slow10" ) == 0 )
   {
      Sleep( 10000 );
      srv_send( c, "200 OK", "text/plain", "late", 4, NULL );
   }
   else
      srv_send( c, "404 Not Found", "text/plain", "", 0, NULL );
}

static DWORD WINAPI srv_thread( LPVOID p )
{
   ( void ) p;
   for( ;; )
   {
      SOCKET c = accept( s_listen, NULL, NULL );
      if( c == INVALID_SOCKET )
         break;
      srv_handle( c );
      shutdown( c, SD_SEND );
      closesocket( c );
   }
   return 0;
}

/* TESTSERVER_START() -> nPort (0 on failure): an HTTP server on 127.0.0.1, any free port */
HB_FUNC( TESTSERVER_START )
{
   WSADATA            w;
   struct sockaddr_in a;
   int                len = sizeof( a );

   WSAStartup( MAKEWORD( 2, 2 ), &w );
   s_listen = socket( AF_INET, SOCK_STREAM, IPPROTO_TCP );
   memset( &a, 0, sizeof( a ) );
   a.sin_family      = AF_INET;
   a.sin_addr.s_addr = htonl( INADDR_LOOPBACK );
   a.sin_port        = 0;
   if( s_listen == INVALID_SOCKET || bind( s_listen, ( struct sockaddr * ) &a, sizeof( a ) ) != 0 ||
       listen( s_listen, 16 ) != 0 || getsockname( s_listen, ( struct sockaddr * ) &a, &len ) != 0 )
   {
      hb_retni( 0 );
      return;
   }
   CloseHandle( CreateThread( NULL, 0, srv_thread, NULL, 0, NULL ) );
   hb_retni( ntohs( a.sin_port ) );
}

HB_FUNC( TESTSERVER_STOP )
{
   if( s_listen != INVALID_SOCKET )
      closesocket( s_listen );
   s_listen = INVALID_SOCKET;
}
#pragma ENDDUMP
