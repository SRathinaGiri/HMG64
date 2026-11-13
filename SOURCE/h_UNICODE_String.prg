/*----------------------------------------------------------------------------
 HMG Source File --> h_UNICODE_STRING.prg  

 Copyright 2012-2017 by Dr. Claudio Soto (from Uruguay). 

 mail: <srvet@adinet.com.uy>
 blog: http://srvet.blogspot.com

 Permission to use, copy, modify, distribute and sell this software
 and its documentation for any purpose is hereby granted without fee,
 provided that the above copyright notice appear in all copies and
 that both that copyright notice and this permission notice appear
 in supporting documentation.
 It is provided "as is" without express or implied warranty.

 ----------------------------------------------------------------------------*/

#include "hmg.ch"
 
/*

UNICODE/ANSI                 ANSI Only
------------                 ---------
HMG_LEN()               <=>   LEN()
HMG_LOWER()             <=>   LOWER()
HMG_UPPER()             <=>   UPPER()
HMG_PADC()              <=>   PADC()
HMG_PADL()              <=>   PADL()
HMG_PADR()              <=>   PADR()
HMG_ISALPHA()           <=>   ISALPHA()
HMG_ISDIGIT()           <=>   ISDIGIT()
HMG_ISLOWER()           <=>   ISLOWER()
HMG_ISUPPER()           <=>   ISUPPER()
HMG_ISALPHANUMERIC()    <=>   RETURN (ISALPHA(c) .OR. ISDIGIT(c)) 

HB_USUBSTR()            <=>   SUBSTR()
HB_ULEFT()              <=>   LEFT()
HB_URIGHT()             <=>   RIGHT()
HB_UAT()                <=>   AT()
HB_UTF8RAT()            <=>   RAT()
HB_UTF8STUFF()          <=>   STUFF()

*/

 
#include "SET_COMPILE_HMG_UNICODE.ch"


#ifdef COMPILE_HMG_UNICODE


   FUNCTION HMG_LEN (x)
      IF ValType(x) == "C"   // HB_ISSTRING(x) .OR. HB_ISCHAR(x) .OR. HB_ISMEMO(x)
         RETURN HB_ULEN (x)
      ELSE
         RETURN LEN (x)
      ENDIF
   RETURN NIL


   FUNCTION HMG_PADC (xValue, nLen, cFillChar)
   LOCAL cText, nSize, cPadText := ""
      IF nLen > 0
         IF HB_ISNIL(cFillChar)
            cFillChar := " "
         ENDIF
         IF .NOT. HB_WILDMATCHI ("",cFillChar)
             cFillChar := HB_USUBSTR (cFillChar,1,1)
             cText := HB_VALTOSTR (xValue)
             IF HB_ULEN (cText) >= nLen
                cPadText := HB_USUBSTR (cText,1,nLen)
             ELSE
                nSize := nLen - HB_ULEN (cText)
                cPadText := REPLICATE (cFillChar, (nSize/2)) + cText + REPLICATE (cFillChar, ((nSize+1)/2))             
                cPadText := HB_USUBSTR (cPadText,1,nLen)
             ENDIF
         ENDIF
      ENDIF
   RETURN cPadText


   FUNCTION HMG_PADL (xValue, nLen, cFillChar)
   LOCAL cText, nSize, cPadText := ""
      IF nLen > 0
         IF HB_ISNIL(cFillChar)
            cFillChar := " "
         ENDIF
         IF .NOT. HB_WILDMATCHI ("",cFillChar)
             cFillChar := HB_USUBSTR (cFillChar,1,1)
             cText := HB_VALTOSTR (xValue)
             IF HB_ULEN (cText) >= nLen
                cPadText := HB_USUBSTR (cText,1,nLen)
             ELSE
                nSize := nLen - HB_ULEN (cText)
                cPadText := REPLICATE (cFillChar, nSize) + cText
             ENDIF
         ENDIF
      ENDIF
   RETURN cPadText


   FUNCTION HMG_PADR (xValue, nLen, cFillChar)
   LOCAL cText, nSize, cPadText := ""
      IF nLen > 0
         IF HB_ISNIL(cFillChar)
            cFillChar := " "
         ENDIF
         IF .NOT. HB_WILDMATCHI ("",cFillChar)
             cFillChar := HB_USUBSTR (cFillChar,1,1)
             cText := HB_VALTOSTR (xValue)
             IF HB_ULEN (cText) >= nLen
                cPadText := HB_USUBSTR (cText,1,nLen)
             ELSE
                nSize := nLen - HB_ULEN (cText)
                cPadText := cText + REPLICATE (cFillChar, nSize)
             ENDIF
         ENDIF
      ENDIF
   RETURN cPadText

/*
   HB_FUNC (HMG_LOWER)
   HB_FUNC (HMG_UPPER)
   HB_FUNC (HMG_ISALPHA)
   HB_FUNC (HMG_ISDIGIT)
   HB_FUNC (HMG_ISLOWER)
   HB_FUNC (HMG_ISUPPER)
   HB_FUNC (HMG_ISALPHANUMERIC)
*/

   /* HMG5 (from HMG 3.5): characters above U+FFFF and CESU-8
      HMG_CHR( nCode [, lCesu8 ] ) -> the character (UTF-8; with lCesu8 a code above U+FFFF is
                                      written as a surrogate pair, as CESU-8)
      HMG_ASC( cStr )              -> the code of the first character (surrogate pairs joined)
      HMG_CESU8( cStr )            -> cStr with every character above U+FFFF as a surrogate pair:
                                      what Windows controls (UTF-16) show correctly
      HMG_UNCESU8( cStr )          -> back to plain UTF-8 */
   FUNCTION HMG_CHR( nCode, lCesu8 )
      IF ! HB_ISNUMERIC( nCode ) .OR. nCode < 0
         RETURN ""
      ENDIF
      IF nCode < 0x10000
         RETURN hb_UTF8Chr( nCode )
      ENDIF
      IF Empty( lCesu8 )
         RETURN Chr( 0xF0 + Int( nCode / 0x40000 ) ) + Chr( 0x80 + Int( nCode / 0x1000 ) % 0x40 ) + ;
                Chr( 0x80 + Int( nCode / 0x40 ) % 0x40 ) + Chr( 0x80 + nCode % 0x40 )
      ENDIF
      nCode -= 0x10000
   RETURN hb_UTF8Chr( 0xD800 + Int( nCode / 0x400 ) ) + hb_UTF8Chr( 0xDC00 + nCode % 0x400 )

   FUNCTION HMG_ASC( cStr )
      LOCAL nCode := 0, nCode2 := 0, nNext
      IF HB_ISSTRING( cStr ) .AND. ! Empty( cStr )
         nNext := _HMG_U8Next( cStr, 1, @nCode )
         IF nCode >= 0xD800 .AND. nCode <= 0xDBFF .AND. nNext <= Len( cStr )
            _HMG_U8Next( cStr, nNext, @nCode2 )
            IF nCode2 >= 0xDC00 .AND. nCode2 <= 0xDFFF
               nCode := 0x10000 + ( nCode - 0xD800 ) * 0x400 + ( nCode2 - 0xDC00 )
            ENDIF
         ENDIF
      ENDIF
   RETURN nCode

   FUNCTION HMG_CESU8( cStr )
      LOCAL cOut := "", n := 1, nNext, nCode := 0
      IF ! HB_ISSTRING( cStr )
         RETURN cStr
      ENDIF
      DO WHILE n <= Len( cStr )
         nNext := _HMG_U8Next( cStr, n, @nCode )
         cOut += iif( nCode >= 0x10000, HMG_CHR( nCode, .T. ), SubStr( cStr, n, nNext - n ) )
         n := nNext
      ENDDO
   RETURN cOut

   FUNCTION HMG_UNCESU8( cStr )
      LOCAL cOut := "", n := 1, nNext, nNext2, nCode := 0, nCode2 := 0
      IF ! HB_ISSTRING( cStr )
         RETURN cStr
      ENDIF
      DO WHILE n <= Len( cStr )
         nNext := _HMG_U8Next( cStr, n, @nCode )
         IF nCode >= 0xD800 .AND. nCode <= 0xDBFF .AND. nNext <= Len( cStr )
            nNext2 := _HMG_U8Next( cStr, nNext, @nCode2 )
            IF nCode2 >= 0xDC00 .AND. nCode2 <= 0xDFFF
               cOut += HMG_CHR( 0x10000 + ( nCode - 0xD800 ) * 0x400 + ( nCode2 - 0xDC00 ), .F. )
               n := nNext2
               LOOP
            ENDIF
         ENDIF
         cOut += SubStr( cStr, n, nNext - n )
         n := nNext
      ENDDO
   RETURN cOut

   /* the code of the UTF-8 character at byte n (surrogates accepted) -> the byte after it */
   STATIC FUNCTION _HMG_U8Next( cStr, n, nCode )
      LOCAL b := Asc( SubStr( cStr, n, 1 ) ), nLen, i, c
      DO CASE
      CASE b >= 0xF0 ; nLen := 4 ; nCode := b % 0x08
      CASE b >= 0xE0 ; nLen := 3 ; nCode := b % 0x10
      CASE b >= 0xC0 ; nLen := 2 ; nCode := b % 0x20
      OTHERWISE      ; nCode := b ; RETURN n + 1
      ENDCASE
      FOR i := 1 TO nLen - 1
         c := Asc( SubStr( cStr, n + i, 1 ) )
         IF n + i > Len( cStr ) .OR. c < 0x80 .OR. c >= 0xC0
            nCode := b                          // a broken sequence: the byte itself
            RETURN n + 1
         ENDIF
         nCode := nCode * 0x40 + ( c % 0x40 )
      NEXT
   RETURN n + nLen

#else

   FUNCTION HMG_LEN(x); RETURN LEN (x)
   FUNCTION HMG_LOWER(c); RETURN LOWER (c)
   FUNCTION HMG_UPPER(c); RETURN UPPER (c)

   FUNCTION HMG_PADC(x,n,c); RETURN PADC(x,n,c)
   FUNCTION HMG_PADL(x,n,c); RETURN PADL(x,n,c)
   FUNCTION HMG_PADR(x,n,c); RETURN PADR(x,n,c)

   FUNCTION HMG_ISALPHA(c); RETURN ISALPHA(c)
   FUNCTION HMG_ISDIGIT(c); RETURN ISDIGIT(c)
   FUNCTION HMG_ISLOWER(c); RETURN ISLOWER(c)
   FUNCTION HMG_ISUPPER(c); RETURN ISUPPER(c)
   FUNCTION HMG_ISALPHANUMERIC(c); RETURN (ISALPHA(c) .OR. ISDIGIT(c))
   FUNCTION HMG_CHR(n); RETURN CHR(n)
   FUNCTION HMG_ASC(c); RETURN ASC(c)
   FUNCTION HMG_CESU8(c); RETURN c
   FUNCTION HMG_UNCESU8(c); RETURN c

#endif



// #define UTF8_BOM  ( HB_BCHAR (0xEF) + HB_BCHAR (0xBB) + HB_BCHAR (0xBF) )


FUNCTION HMG_IsUTF8WithBOM ( cString )
RETURN (HB_BLEFT (cString, HB_BLEN (UTF8_BOM)) == UTF8_BOM)


FUNCTION HMG_UTF8RemoveBOM ( cString )
   IF HMG_IsUTF8WithBOM (cString) == .T.
      cString := HB_BSUBSTR (cString, HB_BLEN ( UTF8_BOM ) + 1)
   ENDIF
RETURN cString


FUNCTION HMG_UTF8InsertBOM ( cString )
   IF HMG_IsUTF8WithBOM (cString) == .F.
      cString := UTF8_BOM + cString
   ENDIF
RETURN cString



FUNCTION HMG_IsUTF8 ( cString )
RETURN HB_StrIsUTF8 ( cString )


/*
FUNCTION HMG_IsUTF8 ( cString )   // code from Harbour Project, now is implemented as HB_StrIsUTF8()
LOCAL lASCII := .T.
LOCAL nOctets := 0
LOCAL nChar
LOCAL tmp

   FOR EACH tmp IN cString

      nChar := HB_BCODE( tmp )

      IF HB_bitAND ( nChar, 0x80 ) != 0
         lASCII := .F.
      ENDIF

      IF nOctets != 0

         IF HB_bitAND ( nChar, 0xC0 ) != 0x80
            RETURN .F.
         ENDIF

         --nOctets

      ELSEIF HB_bitAND ( nChar, 0x80 ) != 0

         DO WHILE HB_bitAND ( nChar, 0x80 ) != 0
            nChar := HB_bitAND ( HB_bitSHIFT ( nChar, 1 ), 0xFF )
            ++nOctets
         ENDDO

         --nOctets

         IF nOctets == 0
            RETURN .F.
         ENDIF
      ENDIF

   NEXT

RETURN !( nOctets > 0 .OR. lASCII )
*/