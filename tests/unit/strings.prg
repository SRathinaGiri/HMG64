/*
 * Unit tests for the HMG string layer (AUDIT.md C1, C3).
 * Checks the frame-owned conversions return CORRECT results (not just leak-free),
 * that non-string arguments no longer crash, and that conversions are thread-safe.
 * Exit code = number of failed checks.
 */

REQUEST HB_CODEPAGE_UTF8

STATIC s_nFail := 0, s_nPass := 0, s_lUni := .T.

PROCEDURE Main()
   LOCAL aThreads := {}, i, aResults

   // The library is built either UNICODE (default) or ANSI-only (hmgbuild lib ansi).
   // ASCII and no-crash checks run in both; UTF-8 checks only in the Unicode build.
   s_lUni := HMG_SupportUnicode()
   OutStd( "strings: library mode = " + iif( s_lUni, "UNICODE", "ANSI" ) + hb_eol() )
   IF s_lUni
      hb_cdpSelect( "UTF8" )
   ENDIF

   // --- C1: values survive the frame-owned conversion round trip -------------
   Check( "upper ascii",      HMG_UPPER( "abc xyz" ) == "ABC XYZ" )
   Check( "lower ascii",      HMG_LOWER( "ABC XYZ" ) == "abc xyz" )
   Check( "upper empty",      HMG_UPPER( "" ) == "" )
   Check( "upper 1 MB",       HMG_UPPER( Replicate( "a", 1048576 ) ) == Replicate( "A", 1048576 ) )
   IF s_lUni
      Check( "upper unicode",    HMG_UPPER( "ñandú àéî ß" ) == "ÑANDÚ ÀÉÎ ß" )
      Check( "lower unicode",    HMG_LOWER( "ÑANDÚ ÀÉÎ" ) == "ñandú àéî" )
      Check( "upper tamil kept", HMG_UPPER( "தமிழ்" ) == "தமிழ்" )
      Check( "unicode value",    hb_ValToExp( HMG_GETUNICODEVALUE( "A₹" ) ) == "{65, 8377}" )
   ENDIF

   // --- C3: non-string / missing arguments return a value instead of crashing -
   Check( "isalpha()",        HMG_ISALPHA() == .F. )
   Check( "isalpha(123)",     HMG_ISALPHA( 123 ) == .F. )
   Check( "isdigit(NIL)",     HMG_ISDIGIT( NIL ) == .F. )
   Check( "islower({})",      HMG_ISLOWER( {} ) == .F. )
   Check( "isupper(date)",    HMG_ISUPPER( Date() ) == .F. )
   Check( "isalnum(.T.)",     HMG_ISALPHANUMERIC( .T. ) == .F. )
   Check( "unicodevalue(NIL)", Len( HMG_GETUNICODEVALUE( NIL ) ) == 0 )
   Check( "isalpha still ok", HMG_ISALPHA( "a" ) .AND. ! HMG_ISALPHA( "5" ) .AND. HMG_ISDIGIT( "5" ) )
   IF s_lUni
      Check( "isalpha accented", HMG_ISALPHA( "é" ) )
   ENDIF

   // --- C1: per-thread HVM stacks own their conversions -----------------------
   FOR i := 1 TO 4
      AAdd( aThreads, hb_threadStart( @Worker(), i ) )
   NEXT
   aResults := {}
   FOR i := 1 TO 4
      AAdd( aResults, NIL )
      hb_threadJoin( aThreads[ i ], @aResults[ i ] )
   NEXT
   Check( "4 threads x 5000", AScan( aResults, {| l | l != .T. } ) == 0 )

   OutStd( "strings: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ErrorLevel( s_nFail )
RETURN

STATIC FUNCTION Worker( nId )
   LOCAL i
   LOCAL cIn  := Replicate( iif( s_lUni, "ñ", "n" ) + hb_ntos( nId ), 500 )
   LOCAL cOut := Replicate( iif( s_lUni, "Ñ", "N" ) + hb_ntos( nId ), 500 )
   FOR i := 1 TO 5000
      IF ! HMG_UPPER( cIn ) == cOut
         RETURN .F.
      ENDIF
   NEXT
RETURN .T.

STATIC PROCEDURE Check( cName, lOk )
   IF lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "  FAIL " + cName + hb_eol() )
   ENDIF
RETURN
