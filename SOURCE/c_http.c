/*
 * HMG5 5.2 - HTTP and HTTPS without OpenSSL, on Windows' own WinHTTP: TLS with the
 * system's certificates, the user's proxy settings, redirects and gzip/deflate.
 *
 * HMG_HTTPREQUEST( cMethod, cUrl [, cBody] [, aHeaders] [, nTimeoutMs] [, cContentType] )
 *    -> { nStatus, cBody, cError, cHeaders }
 *
 *  nStatus   the HTTP status (200, 404 ...), 0 when no answer came (cError says why)
 *  cBody     the response bytes as received (UTF-8 stays UTF-8); a UTF-16 response (a
 *            FF FE byte order mark or charset=utf-16) is converted to the program's
 *            strings, as HMG converts any Windows text
 *  cError    "" or "WinHTTP <code>: <Windows' message>"
 *  cHeaders  the response headers, one per line (CR LF)
 *
 * aHeaders: "Name: value" strings or { cName, cValue } pairs. The call waits for the
 * answer (nTimeoutMs, default 30000, for each step: resolve, connect, send, receive).
 * HMG_HttpGet() / HMG_HttpPost() (h_http.prg) are the short forms.
 */

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <winhttp.h>
#include "hbapi.h"
#include "hbapiitm.h"

#ifndef WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY
   #define WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY   4
#endif
#ifndef WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT
   #define WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT 7
#endif
#ifndef WINHTTP_OPTION_DECOMPRESSION
   #define WINHTTP_OPTION_DECOMPRESSION          118
#endif
#ifndef WINHTTP_DECOMPRESSION_FLAG_ALL
   #define WINHTTP_DECOMPRESSION_FLAG_ALL        3
#endif

static WCHAR * http_wide( const char * s )   /* Harbour string -> UTF-16, hb_xfree() it */
{
   return ( WCHAR * ) hb_osStrU16Encode( s ? s : "" );
}

static void http_seterror( PHB_ITEM pResult, DWORD dwErr, const char * szWhere )
{
   WCHAR  w[ 512 ];
   char   szHead[ 96 ];
   char * szMsg = NULL;
   DWORD  n = FormatMessageW( FORMAT_MESSAGE_FROM_HMODULE | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                              GetModuleHandleW( L"winhttp.dll" ), dwErr, 0, w, 511, NULL );
   while( n > 0 && ( w[ n - 1 ] == L'\r' || w[ n - 1 ] == L'\n' || w[ n - 1 ] == L' ' || w[ n - 1 ] == L'.' ) )
      n--;
   w[ n ] = 0;
   hb_snprintf( szHead, sizeof( szHead ), "WinHTTP %lu (%s): ", ( unsigned long ) dwErr, szWhere );
   if( n > 0 )
      szMsg = hb_osStrU16Decode( ( const HB_WCHAR * ) w );
   {
      HB_SIZE nHead = strlen( szHead ), nMsg = szMsg ? strlen( szMsg ) : 0;
      char *  p = ( char * ) hb_xgrab( nHead + nMsg + 1 );
      memcpy( p, szHead, nHead );
      if( nMsg )
         memcpy( p + nHead, szMsg, nMsg );
      p[ nHead + nMsg ] = 0;
      hb_arraySetCLPtr( pResult, 3, p, nHead + nMsg );
   }
   if( szMsg )
      hb_xfree( szMsg );
}

/* one request header line, "Name: value", as UTF-16 (hb_xfree() it); NULL to skip */
static WCHAR * http_header( PHB_ITEM pItem )
{
   if( HB_IS_STRING( pItem ) && hb_itemGetCLen( pItem ) > 0 )
      return http_wide( hb_itemGetCPtr( pItem ) );
   if( HB_IS_ARRAY( pItem ) && hb_arrayLen( pItem ) >= 2 )
   {
      const char * szName  = hb_arrayGetCPtr( pItem, 1 );
      const char * szValue = hb_arrayGetCPtr( pItem, 2 );
      HB_SIZE      nName = strlen( szName ), nValue = strlen( szValue );
      char *       p;
      WCHAR *      w;
      if( nName == 0 )
         return NULL;
      p = ( char * ) hb_xgrab( nName + nValue + 3 );
      memcpy( p, szName, nName );
      memcpy( p + nName, ": ", 2 );
      memcpy( p + nName + 2, szValue, nValue );
      p[ nName + nValue + 2 ] = 0;
      w = http_wide( p );
      hb_xfree( p );
      return w;
   }
   return NULL;
}

static HB_BOOL http_isutf16( const char * pData, HB_SIZE nData, const WCHAR * wHeaders )
{
   if( nData >= 2 && ( unsigned char ) pData[ 0 ] == 0xFF && ( unsigned char ) pData[ 1 ] == 0xFE )
      return HB_TRUE;
   if( wHeaders )
   {
      const WCHAR * p = wHeaders;
      for( ; *p; p++ )   /* "charset=utf-16" anywhere in Content-Type */
      {
         if( _wcsnicmp( p, L"charset=utf-16", 14 ) == 0 )
            return HB_TRUE;
      }
   }
   return HB_FALSE;
}

HB_FUNC( HMG_HTTPREQUEST )
{
   PHB_ITEM        pResult  = hb_itemArrayNew( 4 );
   const char *    szMethod = hb_parclen( 1 ) > 0 ? hb_parc( 1 ) : "GET";
   const char *    szUrl    = hb_parc( 2 );
   const char *    pBody    = hb_parc( 3 );
   HB_SIZE         nBody    = hb_parclen( 3 );
   PHB_ITEM        pHeaders = hb_param( 4, HB_IT_ARRAY );
   int             nTimeout = HB_ISNUM( 5 ) && hb_parni( 5 ) > 0 ? hb_parni( 5 ) : 30000;
   const char *    szCType  = hb_parc( 6 );
   WCHAR *         wUrl = NULL, * wMethod = NULL, * wHost = NULL, * wPath = NULL, * wRaw = NULL;
   HINTERNET       hSession = NULL, hConnect = NULL, hRequest = NULL;
   URL_COMPONENTS  uc;
   DWORD           dwStatus = 0, dwSize = sizeof( dwStatus ), dwErr = 0;
   char *          pData = NULL;
   HB_SIZE         nData = 0, nAlloc = 0;
   const char *    szWhere = "";

   hb_arraySetNI( pResult, 1, 0 );
   hb_arraySetC( pResult, 2, "" );
   hb_arraySetC( pResult, 3, "" );
   hb_arraySetC( pResult, 4, "" );

   if( szUrl == NULL || *szUrl == 0 )
   {
      hb_arraySetC( pResult, 3, "WinHTTP: no URL" );
      hb_itemReturnRelease( pResult );
      return;
   }

   wUrl = http_wide( szUrl );
   memset( &uc, 0, sizeof( uc ) );
   uc.dwStructSize      = sizeof( uc );
   uc.dwHostNameLength  = ( DWORD ) -1;
   uc.dwUrlPathLength   = ( DWORD ) -1;
   uc.dwExtraInfoLength = ( DWORD ) -1;
   uc.dwSchemeLength    = ( DWORD ) -1;
   if( ! WinHttpCrackUrl( wUrl, 0, 0, &uc ) )
   {
      dwErr = GetLastError();
      szWhere = "URL";
      goto done;
   }
   wHost = ( WCHAR * ) hb_xgrab( ( uc.dwHostNameLength + 1 ) * sizeof( WCHAR ) );
   memcpy( wHost, uc.lpszHostName, uc.dwHostNameLength * sizeof( WCHAR ) );
   wHost[ uc.dwHostNameLength ] = 0;
   wPath = ( WCHAR * ) hb_xgrab( ( uc.dwUrlPathLength + uc.dwExtraInfoLength + 2 ) * sizeof( WCHAR ) );
   if( uc.dwUrlPathLength > 0 )
      memcpy( wPath, uc.lpszUrlPath, uc.dwUrlPathLength * sizeof( WCHAR ) );
   else
      wPath[ 0 ] = L'/';
   {
      DWORD n = uc.dwUrlPathLength > 0 ? uc.dwUrlPathLength : 1;
      if( uc.dwExtraInfoLength > 0 )
         memcpy( wPath + n, uc.lpszExtraInfo, uc.dwExtraInfoLength * sizeof( WCHAR ) );
      wPath[ n + uc.dwExtraInfoLength ] = 0;
   }

   hSession = WinHttpOpen( L"HMG5 (WinHTTP)", WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY,
                           WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0 );
   if( hSession == NULL )   /* before Windows 8.1 */
      hSession = WinHttpOpen( L"HMG5 (WinHTTP)", WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
                              WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0 );
   if( hSession == NULL )
   {
      dwErr = GetLastError();
      szWhere = "open";
      goto done;
   }
   WinHttpSetTimeouts( hSession, nTimeout, nTimeout, nTimeout, nTimeout );
   {  /* waiting for the answer is a timeout of its own (90 s by default) */
      DWORD dwWait = ( DWORD ) nTimeout;
      WinHttpSetOption( hSession, WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT, &dwWait, sizeof( dwWait ) );
   }
   {
      DWORD dwDec = WINHTTP_DECOMPRESSION_FLAG_ALL;
      WinHttpSetOption( hSession, WINHTTP_OPTION_DECOMPRESSION, &dwDec, sizeof( dwDec ) );   /* Windows 8.1+ */
   }

   hConnect = WinHttpConnect( hSession, wHost, uc.nPort, 0 );
   if( hConnect == NULL )
   {
      dwErr = GetLastError();
      szWhere = "connect";
      goto done;
   }
   wMethod  = http_wide( szMethod );
   hRequest = WinHttpOpenRequest( hConnect, wMethod, wPath, NULL, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES,
                                  uc.nScheme == INTERNET_SCHEME_HTTPS ? WINHTTP_FLAG_SECURE : 0 );
   if( hRequest == NULL )
   {
      dwErr = GetLastError();
      szWhere = "request";
      goto done;
   }
   WinHttpSetTimeouts( hRequest, nTimeout, nTimeout, nTimeout, nTimeout );   /* the request's own copy */
   {
      DWORD dwWait = ( DWORD ) nTimeout;
      WinHttpSetOption( hRequest, WINHTTP_OPTION_RECEIVE_RESPONSE_TIMEOUT, &dwWait, sizeof( dwWait ) );
   }

   if( szCType && *szCType )
   {
      char *  p = ( char * ) hb_xgrab( strlen( szCType ) + 16 );
      WCHAR * w;
      strcpy( p, "Content-Type: " );
      strcat( p, szCType );
      w = http_wide( p );
      WinHttpAddRequestHeaders( hRequest, w, ( DWORD ) -1, WINHTTP_ADDREQ_FLAG_ADD | WINHTTP_ADDREQ_FLAG_REPLACE );
      hb_xfree( w );
      hb_xfree( p );
   }
   if( pHeaders )
   {
      HB_SIZE i;
      for( i = 1; i <= hb_arrayLen( pHeaders ); i++ )
      {
         WCHAR * w = http_header( hb_arrayGetItemPtr( pHeaders, i ) );
         if( w )
         {
            WinHttpAddRequestHeaders( hRequest, w, ( DWORD ) -1, WINHTTP_ADDREQ_FLAG_ADD | WINHTTP_ADDREQ_FLAG_REPLACE );
            hb_xfree( w );
         }
      }
   }

   if( ! WinHttpSendRequest( hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, 0,
                             nBody ? ( LPVOID ) pBody : WINHTTP_NO_REQUEST_DATA,
                             ( DWORD ) nBody, ( DWORD ) nBody, 0 ) )
   {
      dwErr = GetLastError();
      szWhere = "send";
      goto done;
   }
   if( ! WinHttpReceiveResponse( hRequest, NULL ) )
   {
      dwErr = GetLastError();
      szWhere = "receive";
      goto done;
   }

   WinHttpQueryHeaders( hRequest, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                        WINHTTP_HEADER_NAME_BY_INDEX, &dwStatus, &dwSize, WINHTTP_NO_HEADER_INDEX );
   {
      DWORD dwLen = 0;
      WinHttpQueryHeaders( hRequest, WINHTTP_QUERY_RAW_HEADERS_CRLF, WINHTTP_HEADER_NAME_BY_INDEX,
                           WINHTTP_NO_OUTPUT_BUFFER, &dwLen, WINHTTP_NO_HEADER_INDEX );
      if( dwLen > 0 )
      {
         wRaw = ( WCHAR * ) hb_xgrabz( dwLen + sizeof( WCHAR ) );
         if( WinHttpQueryHeaders( hRequest, WINHTTP_QUERY_RAW_HEADERS_CRLF, WINHTTP_HEADER_NAME_BY_INDEX,
                                  wRaw, &dwLen, WINHTTP_NO_HEADER_INDEX ) )
         {
            char * p = hb_osStrU16Decode( ( const HB_WCHAR * ) wRaw );
            if( p )
               hb_arraySetCLPtr( pResult, 4, p, strlen( p ) );
         }
      }
   }

   for( ;; )
   {
      DWORD dwAvail = 0, dwRead = 0;
      if( ! WinHttpQueryDataAvailable( hRequest, &dwAvail ) )
      {
         dwErr = GetLastError();
         szWhere = "read";
         break;
      }
      if( dwAvail == 0 )
         break;
      if( nData + dwAvail + 2 > nAlloc )
      {
         nAlloc = ( nData + dwAvail + 2 ) * 2;
         pData = ( char * ) ( pData ? hb_xrealloc( pData, nAlloc ) : hb_xgrab( nAlloc ) );
      }
      if( ! WinHttpReadData( hRequest, pData + nData, dwAvail, &dwRead ) )
      {
         dwErr = GetLastError();
         szWhere = "read";
         break;
      }
      nData += dwRead;
      if( dwRead == 0 )
         break;
   }

   hb_arraySetNI( pResult, 1, ( int ) dwStatus );
   if( pData && nData > 0 )
   {
      if( http_isutf16( pData, nData, wRaw ) )
      {
         HB_SIZE  nSkip = ( ( unsigned char ) pData[ 0 ] == 0xFF && ( unsigned char ) pData[ 1 ] == 0xFE ) ? 2 : 0;
         HB_SIZE  nW = ( nData - nSkip ) / 2;
         WCHAR *  w = ( WCHAR * ) hb_xgrab( ( nW + 1 ) * sizeof( WCHAR ) );
         char *   p;
         memcpy( w, pData + nSkip, nW * sizeof( WCHAR ) );
         w[ nW ] = 0;
         p = hb_osStrU16Decode( ( const HB_WCHAR * ) w );
         hb_xfree( w );
         if( p )
            hb_arraySetCLPtr( pResult, 2, p, strlen( p ) );
      }
      else
         hb_arraySetCL( pResult, 2, pData, nData );
   }

done:
   if( dwErr )
      http_seterror( pResult, dwErr, szWhere );
   if( pData )
      hb_xfree( pData );
   if( wRaw )
      hb_xfree( wRaw );
   if( hRequest )
      WinHttpCloseHandle( hRequest );
   if( hConnect )
      WinHttpCloseHandle( hConnect );
   if( hSession )
      WinHttpCloseHandle( hSession );
   if( wMethod )
      hb_xfree( wMethod );
   if( wPath )
      hb_xfree( wPath );
   if( wHost )
      hb_xfree( wHost );
   if( wUrl )
      hb_xfree( wUrl );
   hb_itemReturnRelease( pResult );
}
