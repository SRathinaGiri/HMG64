/*----------------------------------------------------------------------------
 HMG - Harbour Windows GUI library source code

 h_crypt_aes.prg - file and migration helpers for the AES-256-GCM API in
 c_crypt_cng.c (replacement for the XOR crypt module, AUDIT.md finding H1).

   HMG_AESEncrypt( cData, cPassword )              -> cBlob            (C)
   HMG_AESDecrypt( cBlob, cPassword )              -> cData | NIL      (C)
   HMG_AESIsBlob( xValue )                         -> lLooksLikeBlob   (C)

   HMG_AESEncryptFile( cInFile, cOutFile, cPassword )          -> .T.
   HMG_AESDecryptFile( cInFile, cOutFile, cPassword )          -> lOk
       .F. = wrong password or the file was altered/damaged; cOutFile is
       then NOT created. Bad arguments and I/O failures raise a run-time
       error (subsystem HMGCRYPT) instead, so .F. has exactly one meaning.

   HMG_AESMigrateString( cLegacy, cOldPass, cNewPass )         -> cBlob
       cLegacy = output of the deprecated _ENCRYPT( cData, cOldPass ).
       XOR has no integrity check: a wrong cOldPass silently yields garbage,
       which is then encrypted. Verify the migrated value before discarding
       the legacy copy.

   HMG_AESMigrateFile( cLegacyFile, cOldPass, cOutFile, cNewPass ) -> lOk
       cLegacyFile = output of the deprecated FI_CODE(). .F. = cOldPass does
       not match the password check stored in the legacy file. The plaintext
       is never written to disk. cLegacyFile is left untouched.

 Files are processed in memory (GCM is single-shot here), so very large files
 need RAM of about twice their size.
 ----------------------------------------------------------------------------*/

#include "error.ch"

#define HMG_AES_SUBSYSTEM   "HMGCRYPT"

// FI_CODE() layout - see SOURCE/Crypt/h_crypt.prg
#define LEGACY_FI_HEADER    "ENCRYPTED FILE (C) ODESSA 2002"
#define LEGACY_FI_PASSLEN   10
#define LEGACY_FI_CHUNK     512
#define LEGACY_FI_DEFPASS   "<PRIMARY>"


FUNCTION HMG_AESEncryptFile( cInFile, cOutFile, cPassword )

   LOCAL cData

   AESCheckFiles( cInFile, cOutFile, "HMG_AESENCRYPTFILE" )
   cData := AESReadFile( cInFile, "HMG_AESENCRYPTFILE" )
   AESWriteFile( cOutFile, HMG_AESEncrypt( cData, cPassword ), "HMG_AESENCRYPTFILE" )

RETURN .T.


FUNCTION HMG_AESDecryptFile( cInFile, cOutFile, cPassword )

   LOCAL cData

   AESCheckFiles( cInFile, cOutFile, "HMG_AESDECRYPTFILE" )
   cData := HMG_AESDecrypt( AESReadFile( cInFile, "HMG_AESDECRYPTFILE" ), cPassword )
   IF cData == NIL
      RETURN .F.
   ENDIF
   AESWriteFile( cOutFile, cData, "HMG_AESDECRYPTFILE" )

RETURN .T.


FUNCTION HMG_AESMigrateString( cLegacy, cOldPass, cNewPass )

   IF ! HB_ISSTRING( cLegacy )
      AESArgError( "HMG_AESMIGRATESTRING", "Legacy data must be a character string" )
   ENDIF
   IF cOldPass != NIL .AND. ! HB_ISSTRING( cOldPass )
      AESArgError( "HMG_AESMIGRATESTRING", "Old password must be a character string or NIL" )
   ENDIF

   // _ENCRYPT() skips the password XOR when the password is empty; CHARXOR with "" is a no-op
RETURN HMG_AESEncrypt( _DECRYPT( cLegacy, iif( Empty( cOldPass ), "", cOldPass ) ), cNewPass )


FUNCTION HMG_AESMigrateFile( cLegacyFile, cOldPass, cOutFile, cNewPass )

   LOCAL cFile, cPayload, cPlain := "", nPos

   AESCheckFiles( cLegacyFile, cOutFile, "HMG_AESMIGRATEFILE" )
   IF cOldPass != NIL .AND. ! HB_ISSTRING( cOldPass )
      AESArgError( "HMG_AESMIGRATEFILE", "Old password must be a character string or NIL" )
   ENDIF

   // same password normalisation as FI_CODE()/FI_DECODE(), so existing files match
   IF cOldPass == NIL
      cOldPass := LEGACY_FI_DEFPASS
   ENDIF
   IF HMG_LEN( cOldPass ) > LEGACY_FI_PASSLEN
      cOldPass := HB_USUBSTR( cOldPass, 1, LEGACY_FI_PASSLEN )
   ELSE
      cOldPass := HMG_PADR( cOldPass, LEGACY_FI_PASSLEN )
   ENDIF

   cFile := AESReadFile( cLegacyFile, "HMG_AESMIGRATEFILE" )
   IF ! hb_BLeft( cFile, hb_BLen( LEGACY_FI_HEADER ) ) == LEGACY_FI_HEADER
      AESArgError( "HMG_AESMIGRATEFILE", "Not a file encrypted with the legacy FI_CODE(): " + cLegacyFile )
   ENDIF
   IF ! hb_BSubStr( cFile, hb_BLen( LEGACY_FI_HEADER ) + 1, LEGACY_FI_PASSLEN ) == _ENCRYPT( cOldPass )
      RETURN .F.
   ENDIF

   // FI_CODE() restarts the XOR key at every 512-byte block, so decrypt block by block.
   // Byte functions (hb_B*) on purpose: with a UTF-8 codepage SubStr()/Len() count characters.
   cPayload := hb_BSubStr( cFile, hb_BLen( LEGACY_FI_HEADER ) + LEGACY_FI_PASSLEN + 1 )
   FOR nPos := 1 TO hb_BLen( cPayload ) STEP LEGACY_FI_CHUNK
      cPlain += _DECRYPT( hb_BSubStr( cPayload, nPos, LEGACY_FI_CHUNK ), cOldPass )
   NEXT

   AESWriteFile( cOutFile, HMG_AESEncrypt( cPlain, cNewPass ), "HMG_AESMIGRATEFILE" )

RETURN .T.


/*****************************************************************************************
*   INTERNAL
******************************************************************************************/

STATIC PROCEDURE AESCheckFiles( cInFile, cOutFile, cOperation )

   IF ! HB_ISSTRING( cInFile ) .OR. Empty( cInFile )
      AESArgError( cOperation, "Input file name must be a non-empty character string" )
   ENDIF
   IF ! HB_ISSTRING( cOutFile ) .OR. Empty( cOutFile )
      AESArgError( cOperation, "Output file name must be a non-empty character string" )
   ENDIF
   IF Upper( AllTrim( cInFile ) ) == Upper( AllTrim( cOutFile ) )
      AESArgError( cOperation, "Input and output file must be different: " + cInFile )
   ENDIF

RETURN


STATIC FUNCTION AESReadFile( cFile, cOperation )

   IF ! hb_FileExists( cFile )
      AESError( EG_OPEN, 1003, cOperation, "File not found: " + cFile )
   ENDIF

// hb_MemoRead (unlike MemoRead) returns the bytes unchanged, including a trailing Chr(26)
RETURN hb_MemoRead( cFile )


STATIC PROCEDURE AESWriteFile( cFile, cData, cOperation )

   // hb_MemoWrit (unlike MemoWrit) does not append Chr(26)
   IF ! hb_MemoWrit( cFile, cData )
      FErase( cFile )
      AESError( EG_WRITE, 1004, cOperation, "Cannot write file: " + cFile )
   ENDIF

RETURN


STATIC PROCEDURE AESArgError( cOperation, cDescription )

   AESError( EG_ARG, 1001, cOperation, cDescription )

RETURN


// Arguments are deliberately NOT attached: error.log must never contain passwords or data.
STATIC PROCEDURE AESError( nGenCode, nSubCode, cOperation, cDescription )

   LOCAL oError := ErrorNew()

   oError:severity    := ES_ERROR
   oError:genCode     := nGenCode
   oError:subSystem   := HMG_AES_SUBSYSTEM
   oError:subCode     := nSubCode
   oError:operation   := cOperation
   oError:description := cDescription
   oError:canDefault  := .F.
   oError:canRetry    := .F.
   Eval( ErrorBlock(), oError )
   // a handler that returns instead of BREAKing must not let processing continue
   BREAK( oError )
