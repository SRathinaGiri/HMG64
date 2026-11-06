/*
 * Unit tests for the AES-256-GCM crypt API (AUDIT.md H1): c_crypt_cng.c + h_crypt_aes.prg.
 * All data is synthetic. Exit code = number of failed checks.
 */

#include "error.ch"

REQUEST HB_CODEPAGE_UTF8

#define OVERHEAD  53

STATIC s_nFail := 0, s_nPass := 0

PROCEDURE Main()
   LOCAL cPlain, cBlob, cBlob2, cBig, cAll := "", i, nPos, cLeg, cDir, cIn, cEnc, cOut
   LOCAL nT := hb_MilliSeconds()

   hb_cdpSelect( "UTF8" )

   FOR i := 0 TO 255
      cAll += hb_BChar( i )
   NEXT

   // --- known-answer vector, produced independently with Python 'cryptography' + hashlib
   //     (PBKDF2-HMAC-SHA256 600000 it, salt 00..0F, nonce A0..AB, AAD = 37-byte header)
   Check( "KAT decrypt", HMG_AESDecrypt( hb_HexToStr( ;
      "484d474301000927c0000102030405060708090a0b0c0d0e0fa0a1a2a3a4a5a6a7a8a9aaab6ec9769ca4fa" + ;
      "536627918f4b42f46324b0309285757369d3abc0d0a86b73c5fb12a21c77c65324108660b2937120e3d94a" + ;
      "1c435813bab60f7f904719034703687495fcaa6e383f5153a45d4e5151" ), "Test₹Pässword" ) == ;
      "SYNTHETIC PAN ZZZZZ9999Z | IFSC TEST0000001 | ₹ 12,34,567.89" )

   // --- round trip -----------------------------------------------------------
   cPlain := "SYNTHETIC PAN ZZZZZ9999Z, A/c 000000000000, ₹ 1,00,000.00"
   cBlob  := HMG_AESEncrypt( cPlain, "correct horse" )
   Check( "round trip text",   HMG_AESDecrypt( cBlob, "correct horse" ) == cPlain )
   Check( "blob size",         hb_BLen( cBlob ) == hb_BLen( cPlain ) + OVERHEAD )
   Check( "blob header",       hb_BLeft( cBlob, 5 ) == "HMGC" + hb_BChar( 1 ) .AND. HMG_AESIsBlob( cBlob ) )
   Check( "iterations stored", Bin2U( cBlob, 6 ) == HMG_AESIterations() .AND. HMG_AESIterations() >= 600000 )
   Check( "no plaintext leak", ! "ZZZZZ9999Z" $ cBlob )
   cBlob2 := HMG_AESEncrypt( cPlain, "correct horse" )
   Check( "random salt+nonce", ! hb_BSubStr( cBlob, 10, 28 ) == hb_BSubStr( cBlob2, 10, 28 ) .AND. ! cBlob == cBlob2 )
   Check( "round trip binary", HMG_AESDecrypt( HMG_AESEncrypt( cAll, "k" ), "k" ) == cAll )
   Check( "unicode password",  HMG_AESDecrypt( HMG_AESEncrypt( cPlain, "கடவுச்சொல்₹" ), "கடவுச்சொல்₹" ) == cPlain )

   // --- wrong password -> NIL, never garbage ---------------------------------
   Check( "wrong password",    HMG_AESDecrypt( cBlob, "correct horsE" ) == NIL )
   Check( "password prefix",   HMG_AESDecrypt( cBlob, "correct hors" ) == NIL )

   // --- single-bit tamper anywhere -> NIL --------------------------------------
   //     magic, version, iterations, salt, nonce, ciphertext first/last, tag first/last
   FOR EACH nPos IN { 1, 5, 9, 10, 25, 26, 37, 38, 37 + hb_BLen( cPlain ), 38 + hb_BLen( cPlain ), hb_BLen( cBlob ) }
      Check( "bit flip @" + hb_ntos( nPos ), HMG_AESDecrypt( FlipBit( cBlob, nPos ), "correct horse" ) == NIL )
   NEXT
   Check( "truncated",         HMG_AESDecrypt( hb_BLeft( cBlob, hb_BLen( cBlob ) - 1 ), "correct horse" ) == NIL )
   Check( "extended",          HMG_AESDecrypt( cBlob + "x", "correct horse" ) == NIL )
   Check( "not a blob",        HMG_AESDecrypt( "hello", "x" ) == NIL .AND. ! HMG_AESIsBlob( "hello" ) .AND. ! HMG_AESIsBlob( 1 ) )

   // --- empty and 1 MB ---------------------------------------------------------
   cBlob := HMG_AESEncrypt( "", "p" )
   Check( "empty size",        hb_BLen( cBlob ) == OVERHEAD )
   Check( "empty round trip",  HMG_AESDecrypt( cBlob, "p" ) == "" )
   Check( "empty wrong pw",    HMG_AESDecrypt( cBlob, "q" ) == NIL )
   Check( "empty tampered",    HMG_AESDecrypt( FlipBit( cBlob, OVERHEAD ), "p" ) == NIL )
   cBig  := Replicate( cAll, 4096 )                       // 1 MB, every byte value
   cBlob := HMG_AESEncrypt( cBig, "big" )
   Check( "1 MB round trip",   hb_BLen( cBig ) == 1048576 .AND. HMG_AESDecrypt( cBlob, "big" ) == cBig )
   Check( "1 MB tampered",     HMG_AESDecrypt( FlipBit( cBlob, 500000 ), "big" ) == NIL )

   // --- bad arguments raise HMGCRYPT run-time errors ---------------------------
   Check( "RTE data numeric",  IsRTE( {|| HMG_AESEncrypt( 123, "p" ) } ) )
   Check( "RTE password NIL",  IsRTE( {|| HMG_AESEncrypt( "x" ) } ) )
   Check( "RTE password ''",   IsRTE( {|| HMG_AESEncrypt( "x", "" ) } ) )
   Check( "RTE blob NIL",      IsRTE( {|| HMG_AESDecrypt( NIL, "p" ) } ) )
   Check( "RTE dec pw date",   IsRTE( {|| HMG_AESDecrypt( "x", Date() ) } ) )
   Check( "RTE file same",     IsRTE( {|| HMG_AESEncryptFile( "a.txt", "A.TXT ", "p" ) } ) )
   Check( "RTE file missing",  IsRTE( {|| HMG_AESEncryptFile( "no_such_file.bin", "out.bin", "p" ) } ) )

   // --- legacy XOR string -> AES -------------------------------------------------
   cLeg := _ENCRYPT( cPlain, "oldpass" )
   Check( "legacy is XOR",     _DECRYPT( cLeg, "oldpass" ) == cPlain )
   Check( "migrate string",    HMG_AESDecrypt( HMG_AESMigrateString( cLeg, "oldpass", "NewPass#1" ), "NewPass#1" ) == cPlain )
   Check( "migrate no oldpw",  HMG_AESDecrypt( HMG_AESMigrateString( _ENCRYPT( cPlain ), NIL, "n" ), "n" ) == cPlain )

   // --- files ------------------------------------------------------------------
   cDir := hb_DirTemp() + "hmg_aes_test_" + hb_ntos( hb_MilliSeconds() ) + hb_ps()
   hb_DirCreate( cDir )
   cIn := cDir + "plain.bin" ; cEnc := cDir + "plain.hmgc" ; cOut := cDir + "plain.out"

   hb_MemoWrit( cIn, cBig + hb_BChar( 26 ) )             // trailing Ctrl-Z must survive
   Check( "file encrypt",      HMG_AESEncryptFile( cIn, cEnc, "fp" ) .AND. HMG_AESIsBlob( hb_MemoRead( cEnc ) ) )
   Check( "file wrong pw",     ! HMG_AESDecryptFile( cEnc, cOut, "FP" ) .AND. ! hb_FileExists( cOut ) )
   Check( "file round trip",   HMG_AESDecryptFile( cEnc, cOut, "fp" ) .AND. hb_MemoRead( cOut ) == cBig + hb_BChar( 26 ) )
   FErase( cOut )
   hb_MemoWrit( cEnc, FlipBit( hb_MemoRead( cEnc ), 1000 ) )
   Check( "file tampered",     ! HMG_AESDecryptFile( cEnc, cOut, "fp" ) .AND. ! hb_FileExists( cOut ) )

   // legacy FI_CODE file -> AES. ASCII content: FI_CODE's HB_USUBSTR on its last block
   // is character-based, so only ASCII files round-trip through FI_CODE/FI_DECODE exactly.
   cPlain := Replicate( "SYNTHETIC LEDGER 2025-26;ZZZZZ9999Z;12345.67" + Chr( 13 ) + Chr( 10 ), 30 ) // 1380 bytes
   hb_MemoWrit( cIn, cPlain )
   FErase( cEnc ) ; FErase( cOut )
   FI_CODE( cIn, "legacy", cEnc )
   Check( "legacy file made",  hb_BLeft( hb_MemoRead( cEnc ), 30 ) == "ENCRYPTED FILE (C) ODESSA 2002" )
   Check( "migrate file badpw", ! HMG_AESMigrateFile( cEnc, "legacY", cOut, "new" ) .AND. ! hb_FileExists( cOut ) )
   Check( "migrate file",      HMG_AESMigrateFile( cEnc, "legacy", cOut, "new" ) .AND. ;
                               HMG_AESDecrypt( hb_MemoRead( cOut ), "new" ) == cPlain )
   Check( "migrate not legacy", IsRTE( {|| HMG_AESMigrateFile( cIn, "legacy", cDir + "x.out", "new" ) } ) )

   AEval( Directory( cDir + "*.*" ), {| a | FErase( cDir + a[ 1 ] ) } )
   DirRemove( cDir )

   OutStd( "crypt_aes: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + ;
           " (" + hb_ntos( Int( ( hb_MilliSeconds() - nT ) / 1000 ) ) + " s)" + hb_eol() )
   ErrorLevel( s_nFail )
RETURN

STATIC FUNCTION FlipBit( c, nPos )
RETURN hb_BLeft( c, nPos - 1 ) + hb_BChar( hb_bitXor( hb_BCode( hb_BSubStr( c, nPos, 1 ) ), 1 ) ) + hb_BSubStr( c, nPos + 1 )

STATIC FUNCTION Bin2U( c, nPos )   // big-endian uint32 at byte nPos
RETURN ( ( hb_BCode( hb_BSubStr( c, nPos, 1 ) ) * 256 + hb_BCode( hb_BSubStr( c, nPos + 1, 1 ) ) ) * 256 + ;
         hb_BCode( hb_BSubStr( c, nPos + 2, 1 ) ) ) * 256 + hb_BCode( hb_BSubStr( c, nPos + 3, 1 ) )

STATIC FUNCTION IsRTE( bCode )
   LOCAL lRTE := .F., oErr
   BEGIN SEQUENCE WITH {| e | Break( e ) }
      Eval( bCode )
   RECOVER USING oErr
      lRTE := HB_ISOBJECT( oErr ) .AND. oErr:subSystem == "HMGCRYPT"
   END SEQUENCE
RETURN lRTE

STATIC PROCEDURE Check( cName, lOk )
   IF lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "FAIL " + cName + hb_eol() )
   ENDIF
RETURN
