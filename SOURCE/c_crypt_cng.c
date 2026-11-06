/*----------------------------------------------------------------------------
 HMG - Harbour Windows GUI library source code

 c_crypt_cng.c - authenticated encryption for HMG (replaces the XOR "crypt"
 module, AUDIT.md finding H1) using Windows CNG (bcrypt.dll). No third-party
 code: CNG ships with Windows Vista and later.

   AES-256-GCM, key = PBKDF2-HMAC-SHA256( password(UTF-8), salt, iterations )

 Blob format, version 1 (all integers big-endian):

   offset  size  field
   0       4     magic       "HMGC"
   4       1     version     0x01
   5       4     iterations  PBKDF2 iteration count used for THIS blob
   9       16    salt        random per blob (BCryptGenRandom)
   25      12    nonce       random per blob (BCryptGenRandom)
   37      n     ciphertext  same length as the plaintext
   37+n    16    tag         GCM authentication tag

 The 37-byte header is passed to GCM as additional authenticated data, so
 changing any header byte (version, iterations, salt, nonce) fails the tag
 check just like changing the ciphertext does.

 Harbour API (implemented here):
   HMG_AESENCRYPT( cData, cPassword )  -> cBlob
   HMG_AESDECRYPT( cBlob, cPassword )  -> cData, or NIL when the password is
                                          wrong or the blob was altered/damaged
   HMG_AESISBLOB( xValue )             -> .T. if xValue looks like a v1 blob
                                          (format check only, no password)
 File and migration helpers are in h_crypt_aes.prg.

 cData is binary (any bytes, may contain Chr(0)); cPassword is text and is
 converted to UTF-8 before key derivation so the same password gives the same
 key whatever the application's codepage (HB_CDP) is.
 ----------------------------------------------------------------------------*/

#ifndef _WIN32_WINNT
   #define _WIN32_WINNT 0x0600   // CNG needs Vista+
#endif

#include <windows.h>
#include <bcrypt.h>

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapierr.h"
#include "hbapistr.h"

#ifndef NT_SUCCESS
   #define NT_SUCCESS( s )   ( ( ( NTSTATUS ) ( s ) ) >= 0 )
#endif


/*****************************************************************************************
*   CONSTANTS - change here only
******************************************************************************************/

// PBKDF2-HMAC-SHA256 iterations for NEW blobs. 600,000 = OWASP Password Storage Cheat
// Sheet recommendation for PBKDF2-HMAC-SHA256 (as at 2023-2026). Raising it later is
// safe: every blob records its own count, so old blobs still decrypt.
#define HMG_AES_PBKDF2_ITERATIONS      600000UL

// Accepted range when DECRYPTING. The upper bound stops a forged header from making
// decryption spin for hours; the lower bound refuses blobs no HMG build ever wrote.
#define HMG_AES_PBKDF2_MIN_ITERATIONS  100000UL
#define HMG_AES_PBKDF2_MAX_ITERATIONS  10000000UL

#define HMG_AES_MAGIC        "HMGC"
#define HMG_AES_MAGIC_LEN    4
#define HMG_AES_VERSION      0x01
#define HMG_AES_SALT_LEN     16
#define HMG_AES_NONCE_LEN    12   // 96-bit nonce: the GCM-recommended size (NIST SP 800-38D 8.2)
#define HMG_AES_TAG_LEN      16   // full 128-bit tag
#define HMG_AES_KEY_LEN      32   // AES-256

#define HMG_AES_OFS_VERSION  ( HMG_AES_MAGIC_LEN )
#define HMG_AES_OFS_ITER     ( HMG_AES_OFS_VERSION + 1 )
#define HMG_AES_OFS_SALT     ( HMG_AES_OFS_ITER + 4 )
#define HMG_AES_OFS_NONCE    ( HMG_AES_OFS_SALT + HMG_AES_SALT_LEN )
#define HMG_AES_HEADER_LEN   ( HMG_AES_OFS_NONCE + HMG_AES_NONCE_LEN )   // 37
#define HMG_AES_OVERHEAD     ( HMG_AES_HEADER_LEN + HMG_AES_TAG_LEN )    // 53

// CNG takes ULONG lengths; keep well clear of 4 GB.
#define HMG_AES_MAX_DATA     ( 0x7FFFFFFFUL - HMG_AES_OVERHEAD )

#define HMG_AES_SUBSYSTEM    "HMGCRYPT"


/*****************************************************************************************
*   ERRORS
******************************************************************************************/

// Raises a Harbour run-time error WITHOUT the call arguments: the default error handler
// would otherwise write the password and the plaintext into error.log.
static void hmg_aesError( HB_ERRCODE errGenCode, HB_ERRCODE errSubCode, const char * szDescription, NTSTATUS osCode )
{
   PHB_ITEM pError = hb_errRT_New( ES_ERROR, HMG_AES_SUBSYSTEM, errGenCode, errSubCode,
                                   szDescription, HB_ERR_FUNCNAME, ( HB_ERRCODE ) osCode, EF_NONE );
   hb_errLaunch( pError );
   hb_errRelease( pError );
}

static void hmg_aesArgError( const char * szDescription )
{
   hmg_aesError( EG_ARG, 1001, szDescription, 0 );
}

static void hmg_aesCngError( const char * szDescription, NTSTATUS status )
{
   hmg_aesError( EG_UNSUPPORTED, 1002, szDescription, status );
}


/*****************************************************************************************
*   CNG HELPERS
******************************************************************************************/

static void hmg_aesPutBE32( unsigned char * p, ULONG n )
{
   p[ 0 ] = ( unsigned char ) ( n >> 24 );
   p[ 1 ] = ( unsigned char ) ( n >> 16 );
   p[ 2 ] = ( unsigned char ) ( n >> 8 );
   p[ 3 ] = ( unsigned char ) ( n );
}

static ULONG hmg_aesGetBE32( const unsigned char * p )
{
   return ( ( ULONG ) p[ 0 ] << 24 ) | ( ( ULONG ) p[ 1 ] << 16 ) | ( ( ULONG ) p[ 2 ] << 8 ) | ( ULONG ) p[ 3 ];
}

// PBKDF2-HMAC-SHA256 -> 32-byte key. Returns the CNG status.
static NTSTATUS hmg_aesDeriveKey( const char * pPass, HB_SIZE nPassLen, const unsigned char * pSalt,
                                  ULONG nIter, unsigned char * pKey )
{
   BCRYPT_ALG_HANDLE hPrf = NULL;
   NTSTATUS status = BCryptOpenAlgorithmProvider( &hPrf, BCRYPT_SHA256_ALGORITHM, NULL, BCRYPT_ALG_HANDLE_HMAC_FLAG );

   if( NT_SUCCESS( status ) )
   {
      status = BCryptDeriveKeyPBKDF2( hPrf, ( PUCHAR ) pPass, ( ULONG ) nPassLen,
                                      ( PUCHAR ) pSalt, HMG_AES_SALT_LEN, ( ULONGLONG ) nIter,
                                      pKey, HMG_AES_KEY_LEN, 0 );
      BCryptCloseAlgorithmProvider( hPrf, 0 );
   }
   return status;
}

// Opens AES in GCM mode and imports the key. Caller destroys hKey and closes hAlg.
static NTSTATUS hmg_aesOpenKey( const unsigned char * pKey, BCRYPT_ALG_HANDLE * phAlg, BCRYPT_KEY_HANDLE * phKey )
{
   NTSTATUS status;

   *phAlg = NULL;
   *phKey = NULL;

   status = BCryptOpenAlgorithmProvider( phAlg, BCRYPT_AES_ALGORITHM, NULL, 0 );
   if( NT_SUCCESS( status ) )
      status = BCryptSetProperty( *phAlg, BCRYPT_CHAINING_MODE, ( PUCHAR ) BCRYPT_CHAIN_MODE_GCM,
                                  sizeof( BCRYPT_CHAIN_MODE_GCM ), 0 );
   if( NT_SUCCESS( status ) )
      status = BCryptGenerateSymmetricKey( *phAlg, phKey, NULL, 0, ( PUCHAR ) pKey, HMG_AES_KEY_LEN, 0 );

   if( ! NT_SUCCESS( status ) && *phAlg )
   {
      BCryptCloseAlgorithmProvider( *phAlg, 0 );
      *phAlg = NULL;
   }
   return status;
}

static void hmg_aesCloseKey( BCRYPT_ALG_HANDLE hAlg, BCRYPT_KEY_HANDLE hKey )
{
   if( hKey )
      BCryptDestroyKey( hKey );
   if( hAlg )
      BCryptCloseAlgorithmProvider( hAlg, 0 );
}

// Fetches the password parameter as UTF-8. Raises an RTE and returns NULL if it is not a
// non-empty string. Release with hb_strfree( *phPass ).
static const char * hmg_aesParPassword( int iParam, void ** phPass, HB_SIZE * pnLen )
{
   const char * pPass;

   if( ! HB_ISCHAR( iParam ) )
   {
      hmg_aesArgError( "Password must be a character string" );
      return NULL;
   }
   pPass = hb_parstr_utf8( iParam, phPass, pnLen );
   if( pPass == NULL || *pnLen == 0 )
   {
      hb_strfree( *phPass );
      hmg_aesArgError( "Password must not be empty" );
      return NULL;
   }
   if( *pnLen > 0xFFFF )
   {
      hb_strfree( *phPass );
      hmg_aesArgError( "Password is too long (max 65535 bytes)" );
      return NULL;
   }
   return pPass;
}


/*****************************************************************************************
*   HARBOUR FUNCTIONS
******************************************************************************************/

// HMG_AESENCRYPT( cData, cPassword ) -> cBlob
HB_FUNC( HMG_AESENCRYPT )
{
   const char *  pData;
   HB_SIZE       nData;
   const char *  pPass;
   HB_SIZE       nPass;
   void *        hPass = NULL;
   unsigned char key[ HMG_AES_KEY_LEN ];
   unsigned char * pOut;
   BCRYPT_ALG_HANDLE hAlg;
   BCRYPT_KEY_HANDLE hKey;
   BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO info;
   ULONG    cbResult = 0;
   NTSTATUS status;

   if( ! HB_ISCHAR( 1 ) )
   {
      hmg_aesArgError( "Data to encrypt must be a character string" );
      return;
   }
   pData = hb_parc( 1 );
   nData = hb_parclen( 1 );
   if( nData > HMG_AES_MAX_DATA )
   {
      hmg_aesArgError( "Data is too large to encrypt in one call (max 2 GB)" );
      return;
   }
   if( ( pPass = hmg_aesParPassword( 2, &hPass, &nPass ) ) == NULL )
      return;

   pOut = ( unsigned char * ) hb_xgrab( nData + HMG_AES_OVERHEAD + 1 );

   memcpy( pOut, HMG_AES_MAGIC, HMG_AES_MAGIC_LEN );
   pOut[ HMG_AES_OFS_VERSION ] = HMG_AES_VERSION;
   hmg_aesPutBE32( pOut + HMG_AES_OFS_ITER, HMG_AES_PBKDF2_ITERATIONS );

   // salt + nonce in one call; both must be unique per blob, never reused
   status = BCryptGenRandom( NULL, pOut + HMG_AES_OFS_SALT, HMG_AES_SALT_LEN + HMG_AES_NONCE_LEN,
                             BCRYPT_USE_SYSTEM_PREFERRED_RNG );
   if( ! NT_SUCCESS( status ) )
   {
      hb_strfree( hPass );
      hb_xfree( pOut );
      hmg_aesCngError( "Windows random number generator failed", status );
      return;
   }

   status = hmg_aesDeriveKey( pPass, nPass, pOut + HMG_AES_OFS_SALT, HMG_AES_PBKDF2_ITERATIONS, key );
   hb_strfree( hPass );
   if( ! NT_SUCCESS( status ) )
   {
      SecureZeroMemory( key, sizeof( key ) );
      hb_xfree( pOut );
      hmg_aesCngError( "PBKDF2 key derivation failed (Windows CNG)", status );
      return;
   }

   status = hmg_aesOpenKey( key, &hAlg, &hKey );
   SecureZeroMemory( key, sizeof( key ) );
   if( ! NT_SUCCESS( status ) )
   {
      hb_xfree( pOut );
      hmg_aesCngError( "AES-256-GCM is not available (Windows CNG)", status );
      return;
   }

   BCRYPT_INIT_AUTH_MODE_INFO( info );
   info.pbNonce    = pOut + HMG_AES_OFS_NONCE;
   info.cbNonce    = HMG_AES_NONCE_LEN;
   info.pbAuthData = pOut;                       // header is AAD
   info.cbAuthData = HMG_AES_HEADER_LEN;
   info.pbTag      = pOut + HMG_AES_HEADER_LEN + nData;
   info.cbTag      = HMG_AES_TAG_LEN;

   // CNG rejects a NULL input pointer even for 0 bytes; hb_parc() is never NULL here.
   status = BCryptEncrypt( hKey, ( PUCHAR ) pData, ( ULONG ) nData, &info, NULL, 0,
                           pOut + HMG_AES_HEADER_LEN, ( ULONG ) nData, &cbResult, 0 );
   hmg_aesCloseKey( hAlg, hKey );

   if( ! NT_SUCCESS( status ) || cbResult != ( ULONG ) nData )
   {
      SecureZeroMemory( pOut, nData + HMG_AES_OVERHEAD );
      hb_xfree( pOut );
      hmg_aesCngError( "AES-256-GCM encryption failed (Windows CNG)", status );
      return;
   }

   pOut[ nData + HMG_AES_OVERHEAD ] = '\0';
   hb_retclen_buffer( ( char * ) pOut, nData + HMG_AES_OVERHEAD );
}

// Format check shared by HMG_AESDECRYPT and HMG_AESISBLOB.
static HB_BOOL hmg_aesIsBlob( const unsigned char * p, HB_SIZE n )
{
   ULONG nIter;

   if( n < HMG_AES_OVERHEAD || n - HMG_AES_OVERHEAD > HMG_AES_MAX_DATA )
      return HB_FALSE;
   if( memcmp( p, HMG_AES_MAGIC, HMG_AES_MAGIC_LEN ) != 0 || p[ HMG_AES_OFS_VERSION ] != HMG_AES_VERSION )
      return HB_FALSE;
   nIter = hmg_aesGetBE32( p + HMG_AES_OFS_ITER );
   return nIter >= HMG_AES_PBKDF2_MIN_ITERATIONS && nIter <= HMG_AES_PBKDF2_MAX_ITERATIONS;
}

// HMG_AESDECRYPT( cBlob, cPassword ) -> cData | NIL
HB_FUNC( HMG_AESDECRYPT )
{
   const unsigned char * pBlob;
   HB_SIZE       nBlob, nData;
   const char *  pPass;
   HB_SIZE       nPass;
   void *        hPass = NULL;
   unsigned char key[ HMG_AES_KEY_LEN ];
   unsigned char * pOut;
   BCRYPT_ALG_HANDLE hAlg;
   BCRYPT_KEY_HANDLE hKey;
   BCRYPT_AUTHENTICATED_CIPHER_MODE_INFO info;
   ULONG    cbResult = 0;
   NTSTATUS status;

   if( ! HB_ISCHAR( 1 ) )
   {
      hmg_aesArgError( "Encrypted data must be a character string" );
      return;
   }
   pBlob = ( const unsigned char * ) hb_parc( 1 );
   nBlob = hb_parclen( 1 );
   if( ( pPass = hmg_aesParPassword( 2, &hPass, &nPass ) ) == NULL )
      return;

   // Not an HMG v1 blob (truncated, other format, forged header): same answer as a
   // wrong password - NIL - so callers have exactly one failure case to handle.
   if( ! hmg_aesIsBlob( pBlob, nBlob ) )
   {
      hb_strfree( hPass );
      hb_ret();
      return;
   }
   nData = nBlob - HMG_AES_OVERHEAD;

   status = hmg_aesDeriveKey( pPass, nPass, pBlob + HMG_AES_OFS_SALT, hmg_aesGetBE32( pBlob + HMG_AES_OFS_ITER ), key );
   hb_strfree( hPass );
   if( ! NT_SUCCESS( status ) )
   {
      SecureZeroMemory( key, sizeof( key ) );
      hmg_aesCngError( "PBKDF2 key derivation failed (Windows CNG)", status );
      return;
   }

   status = hmg_aesOpenKey( key, &hAlg, &hKey );
   SecureZeroMemory( key, sizeof( key ) );
   if( ! NT_SUCCESS( status ) )
   {
      hmg_aesCngError( "AES-256-GCM is not available (Windows CNG)", status );
      return;
   }

   pOut = ( unsigned char * ) hb_xgrab( nData + 1 );

   BCRYPT_INIT_AUTH_MODE_INFO( info );
   info.pbNonce    = ( PUCHAR ) pBlob + HMG_AES_OFS_NONCE;
   info.cbNonce    = HMG_AES_NONCE_LEN;
   info.pbAuthData = ( PUCHAR ) pBlob;
   info.cbAuthData = HMG_AES_HEADER_LEN;
   info.pbTag      = ( PUCHAR ) pBlob + HMG_AES_HEADER_LEN + nData;
   info.cbTag      = HMG_AES_TAG_LEN;

   status = BCryptDecrypt( hKey, ( PUCHAR ) pBlob + HMG_AES_HEADER_LEN, ( ULONG ) nData, &info, NULL, 0,
                           pOut, ( ULONG ) nData, &cbResult, 0 );
   hmg_aesCloseKey( hAlg, hKey );

   if( ! NT_SUCCESS( status ) || cbResult != ( ULONG ) nData )
   {
      // STATUS_AUTH_TAG_MISMATCH (0xC000A002) = wrong password or altered data. CNG
      // does not return unauthenticated plaintext, but wipe the buffer regardless.
      SecureZeroMemory( pOut, nData + 1 );
      hb_xfree( pOut );
      hb_ret();
      return;
   }

   pOut[ nData ] = '\0';
   hb_retclen_buffer( ( char * ) pOut, nData );
}

// HMG_AESISBLOB( xValue ) -> lLooksLikeBlob  (no password, no authenticity guarantee)
HB_FUNC( HMG_AESISBLOB )
{
   hb_retl( HB_ISCHAR( 1 ) && hmg_aesIsBlob( ( const unsigned char * ) hb_parc( 1 ), hb_parclen( 1 ) ) );
}

// HMG_AESITERATIONS() -> nIterations used for new blobs (for documentation / tests)
HB_FUNC( HMG_AESITERATIONS )
{
   hb_retnl( ( long ) HMG_AES_PBKDF2_ITERATIONS );
}
