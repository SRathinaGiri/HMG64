/*
 * make_npp_udl.prg - writes the Notepad++ "User Defined Language" file for HMG5
 * (tools\editor\HMG5_Notepad++.xml) from HMG's own headers and sources, so the
 * highlighting knows exactly HMG5's commands, controls, clauses and functions.
 *
 * Build and run from the HMG5 folder:
 *    hbmk2 tools\editor\make_npp_udl.prg -otools\editor\make_npp_udl
 *    tools\editor\make_npp_udl.exe [<HMG folder>]
 *
 * Keyword groups (Notepad++ "Keywords1..8"):
 *    1 Harbour language     FUNCTION, LOCAL, IF, DO CASE ...
 *    2 HMG commands         DEFINE, END, ACTIVATE, LOAD, SET ... and the control/block names
 *    3 HMG clauses          ROW, COL, WIDTH, CAPTION, ON CHANGE ... (words of the command patterns)
 *    4 HMG functions        public FUNCTION/PROCEDURE names of SOURCE\*.prg (no leading "_")
 *    5 Harbour functions    harbour.hbx (runtime library)
 *    6 Preprocessor         #include, #define ...
 *    7 Constants            .T. .F. NIL
 */

#include "fileio.ch"

#define K_LANG      1
#define K_CMD       2
#define K_CLAUSE    3
#define K_HMGFUNC   4
#define K_HBFUNC    5
#define K_PP        6
#define K_CONST     7

STATIC s_aHarbour := { "FUNCTION", "PROCEDURE", "RETURN", "LOCAL", "STATIC", "PRIVATE", "PUBLIC", "MEMVAR", ;
   "FIELD", "PARAMETERS", "DECLARE", "EXTERNAL", "REQUEST", "ANNOUNCE", "INIT", "EXIT", "LOOP", ;
   "IF", "ELSE", "ELSEIF", "ENDIF", "END", "DO", "CASE", "OTHERWISE", "ENDCASE", "WHILE", "ENDDO", ;
   "FOR", "EACH", "IN", "TO", "STEP", "NEXT", "DESCEND", "SWITCH", "ENDSWITCH", "BEGIN", "SEQUENCE", ;
   "RECOVER", "USING", "ALWAYS", "WITH", "BREAK", "QUIT", "CLASS", "ENDCLASS", "METHOD", "DATA", ;
   "VAR", "INHERIT", "FROM", "AS", "THREAD", "OPTIONAL", "AND", "OR", "NOT", "SELF", "SUPER", "IIF", ;
   "ACCEPT", "INPUT", "WAIT", "USE", "INDEX", "ON", "ALIAS", "SHARED", "EXCLUSIVE", "NEW", "VIA", ;
   "SKIP", "GO", "GOTO", "TOP", "BOTTOM", "SEEK", "REPLACE", "APPEND", "BLANK", "DELETE", "RECALL", ;
   "PACK", "ZAP", "COMMIT", "UNLOCK", "CLOSE", "SELECT", "LOCATE", "CONTINUE" }

STATIC s_aFolds := { "IF", "FOR", "SWITCH", '"DO CASE"', '"DO WHILE"', '"BEGIN SEQUENCE"', "PAGE", "POPUP", "NODE" }

FUNCTION Main( cHmg )
   LOCAL aK := { => }, cFile, cText, aWords, cW, nPos, aDefine := { => }, aEnd := { => }
   LOCAL aFoldOpen := {}, cOut, n, aLists := Array( 7 )

   hb_HCaseMatch( aK, .F. )
   cHmg := hb_DirSepAdd( iif( Empty( cHmg ), hb_cwd(), cHmg ) )
   IF ! hb_DirExists( cHmg + "INCLUDE" )
      OutErr( "make_npp_udl: no INCLUDE folder under " + cHmg + hb_eol() )
      ErrorLevel( 1 )
      RETURN NIL
   ENDIF

   AEval( s_aHarbour, {| c | aK[ c ] := K_LANG } )
   AEval( { ".T.", ".F.", ".AND.", ".OR.", ".NOT.", "NIL" }, {| c | aK[ c ] := K_CONST } )
   AEval( { "#include", "#define", "#undef", "#ifdef", "#ifndef", "#if", "#else", "#elif", "#endif", ;
            "#command", "#xcommand", "#translate", "#xtranslate", "#pragma", "#stdout", "#error" }, {| c | aK[ c ] := K_PP } )

   // 1. commands, controls and clauses from the HMG headers
   FOR EACH cFile IN Directory( cHmg + "INCLUDE" + hb_ps() + "*.ch" )
      FOR EACH cText IN Patterns( hb_MemoRead( cHmg + "INCLUDE" + hb_ps() + cFile[ 1 ] ) )
         aWords := Words( cText[ 2 ] )
         IF ! cText[ 1 ]   // #translate / #xtranslate
            IF Len( aWords ) == 1 .AND. ! Left( aWords[ 1 ], 1 ) == "(" .AND. ! "<" $ cText[ 2 ]
               // one-word alias: COLOR_Red => {...} is a constant, IsGridDeleteAllItems => ... a function
               IF ! hb_HHasKey( aK, aWords[ 1 ] )
                  aK[ aWords[ 1 ] ] := iif( Left( cText[ 3 ], 1 ) $ "{0123456789-." + Chr( 34 ) + Chr( 39 ), K_CONST, K_HMGFUNC )
               ENDIF
               LOOP
            ENDIF
            FOR EACH cW IN aWords   // dot syntax and the like: properties, methods
               IF Left( cW, 1 ) == "("
                  cW := SubStr( cW, 2 )
               ENDIF
               IF ! hb_HHasKey( aK, cW )
                  aK[ cW ] := K_CLAUSE
               ENDIF
            NEXT
            LOOP
         ENDIF
         IF Len( aWords ) == 1 .AND. "<" $ cText[ 2 ] .AND. ! Left( aWords[ 1 ], 1 ) == "("
            // "ROW <r>", "ONCHANGE <f>": a property line of the DEFINE ... END syntax
            IF ! hb_HHasKey( aK, aWords[ 1 ] )
               aK[ aWords[ 1 ] ] := K_CLAUSE
            ENDIF
            LOOP
         ENDIF
         FOR EACH cW IN aWords
            IF Left( cW, 1 ) == "("          // name( : a function-like translate
               cW := SubStr( cW, 2 )
               IF ! hb_HHasKey( aK, cW )
                  aK[ cW ] := K_HMGFUNC
               ENDIF
               LOOP
            ENDIF
            IF cW:__enumIndex() == 1 .OR. ( cW:__enumIndex() == 2 .AND. Upper( aWords[ 1 ] ) $ "DEFINE END" )
               IF ! hb_HHasKey( aK, cW ) .OR. aK[ cW ] == K_CLAUSE
                  aK[ cW ] := K_CMD
               ENDIF
            ELSEIF ! hb_HHasKey( aK, cW )
               aK[ cW ] := K_CLAUSE
            ENDIF
         NEXT
         IF Len( aWords ) >= 2 .AND. Upper( aWords[ 1 ] ) == "DEFINE"
            aDefine[ Upper( aWords[ 2 ] ) ] := NIL
         ELSEIF Len( aWords ) >= 2 .AND. Upper( aWords[ 1 ] ) == "END"
            aEnd[ Upper( aWords[ 2 ] ) ] := NIL
         ENDIF
         IF Len( aWords ) >= 1 .AND. Left( aWords[ 1 ], 1 ) == "@"
            // "@ <r>, <c> BUTTON ..." : the control name is the first word
         ENDIF
      NEXT
   NEXT

   // blocks that fold: DEFINE x ... END x
   FOR EACH cW IN hb_HKeys( aDefine )
      IF hb_HHasKey( aEnd, cW )
         AAdd( aFoldOpen, '"DEFINE ' + cW + '"' )
      ENDIF
   NEXT
   AEval( s_aFolds, {| c | AAdd( aFoldOpen, c ) } )
   ASort( aFoldOpen )

   // 2. public HMG functions
   FOR EACH cFile IN Directory( cHmg + "SOURCE" + hb_ps() + "*.prg" )
      FOR EACH cText IN hb_ATokens( StrTran( hb_MemoRead( cHmg + "SOURCE" + hb_ps() + cFile[ 1 ] ), Chr( 13 ) ), Chr( 10 ) )
         cText := AllTrim( cText )
         IF ( nPos := FuncName( cText ) ) != NIL .AND. ! Left( nPos, 1 ) == "_"
            IF ! hb_HHasKey( aK, nPos ) .OR. aK[ nPos ] == K_CLAUSE
               aK[ nPos ] := K_HMGFUNC
            ENDIF
         ENDIF
      NEXT
   NEXT

   // 3. Harbour runtime functions
   FOR EACH cText IN hb_ATokens( StrTran( hb_MemoRead( cHmg + "harbour64" + hb_ps() + "include" + hb_ps() + "harbour.hbx" ), Chr( 13 ) ), Chr( 10 ) )
      IF Left( cText, 8 ) == "DYNAMIC " .AND. ! "<" $ cText
         cW := AllTrim( SubStr( cText, 9 ) )
         IF ! Left( cW, 2 ) == "__" .AND. ! hb_HHasKey( aK, cW )
            aK[ cW ] := K_HBFUNC
         ENDIF
      ENDIF
   NEXT

   FOR n := 1 TO 7
      aLists[ n ] := {}
   NEXT
   FOR EACH cW IN hb_HKeys( aK )
      AAdd( aLists[ aK[ cW ] ], cW )
   NEXT
   AEval( aLists, {| a | ASort( a,,, {| x, y | Upper( x ) < Upper( y ) } ) } )

   cOut := Udl( aLists, aFoldOpen )
   hb_MemoWrit( cHmg + "tools" + hb_ps() + "editor" + hb_ps() + "HMG5_Notepad++.xml", cOut )
   OutStd( "make_npp_udl: " + hb_ntos( Len( hb_HKeys( aK ) ) ) + " words (" + ;
           "language " + hb_ntos( Len( aLists[ K_LANG ] ) ) + ", commands " + hb_ntos( Len( aLists[ K_CMD ] ) ) + ;
           ", clauses " + hb_ntos( Len( aLists[ K_CLAUSE ] ) ) + ", HMG functions " + hb_ntos( Len( aLists[ K_HMGFUNC ] ) ) + ;
           ", Harbour functions " + hb_ntos( Len( aLists[ K_HBFUNC ] ) ) + "), " + hb_ntos( Len( aFoldOpen ) ) + " fold openers" + hb_eol() )
RETURN NIL

/* { lCommand, pattern, replacement }: the left-hand side of every #command / #xcommand (.T.) and #translate / #xtranslate (.F.) */
STATIC FUNCTION Patterns( cSrc )
   LOCAL aOut := {}, aLines, cLine, cCur := NIL, nArrow, lCmd := .F.
   aLines := hb_ATokens( StrTran( cSrc, Chr( 13 ) ), Chr( 10 ) )
   FOR EACH cLine IN aLines
      IF cCur == NIL
         IF ! hb_LeftEqI( LTrim( cLine ), "#xcommand" ) .AND. ! hb_LeftEqI( LTrim( cLine ), "#command" ) .AND. ;
            ! hb_LeftEqI( LTrim( cLine ), "#xtranslate" ) .AND. ! hb_LeftEqI( LTrim( cLine ), "#translate" )
            LOOP
         ENDIF
         lCmd := hb_LeftEqI( LTrim( cLine ), "#xcommand" ) .OR. hb_LeftEqI( LTrim( cLine ), "#command" )
         cCur := SubStr( LTrim( cLine ), At( " ", LTrim( cLine ) ) + 1 )
      ELSE
         cCur += " " + cLine
      ENDIF
      IF ( nArrow := At( "=>", cCur ) ) > 0
         AAdd( aOut, { lCmd, Left( cCur, nArrow - 1 ), LTrim( SubStr( cCur, nArrow + 2 ) ) } )
         cCur := NIL
      ELSEIF Right( RTrim( cCur ), 1 ) == ";"
         cCur := Left( RTrim( cCur ), Len( RTrim( cCur ) ) - 1 )
      ELSE
         cCur := NIL   // no "=>": not a pattern we understand
      ENDIF
   NEXT
RETURN aOut

/* literal words of a pattern: match markers removed, restricted-marker words kept,
   "name(" returned as "(name" (a function-like translate) */
STATIC FUNCTION Words( cPat )
   LOCAL aOut := {}, i := 1, nLen := Len( cPat ), c, nEnd, cMark, cW, nColon
   DO WHILE i <= nLen
      c := SubStr( cPat, i, 1 )
      IF c == "<"
         nEnd := hb_At( ">", cPat, i )
         IF nEnd == 0
            EXIT
         ENDIF
         cMark := SubStr( cPat, i + 1, nEnd - i - 1 )
         IF ( nColon := At( ":", cMark ) ) > 0     // <x: WORD1, WORD2>
            FOR EACH cW IN hb_ATokens( SubStr( cMark, nColon + 1 ), "," )
               cW := AllTrim( cW )
               IF IsWord( cW )
                  AAdd( aOut, cW )
               ENDIF
            NEXT
         ENDIF
         i := nEnd + 1
      ELSEIF IsAlpha( c ) .OR. c == "_"
         nEnd := i
         DO WHILE nEnd <= nLen .AND. ( IsAlpha( SubStr( cPat, nEnd, 1 ) ) .OR. IsDigit( SubStr( cPat, nEnd, 1 ) ) .OR. SubStr( cPat, nEnd, 1 ) == "_" )
            nEnd++
         ENDDO
         cW := SubStr( cPat, i, nEnd - i )
         IF Left( cW, 1 ) == "_" .OR. Len( cW ) < 2
            // internal names (_HMG_SYSDATA ...) and single letters are not keywords
         ELSEIF SubStr( cPat, nEnd, 1 ) == "("
            AAdd( aOut, "(" + cW )
         ELSE
            AAdd( aOut, cW )
         ENDIF
         i := nEnd
      ELSEIF c == "@" .AND. Len( aOut ) == 0
         AAdd( aOut, "@" )
         i++
      ELSE
         i++
      ENDIF
   ENDDO
   IF Len( aOut ) > 0 .AND. aOut[ 1 ] == "@"
      hb_ADel( aOut, 1, .T. )
      IF Len( aOut ) > 0 .AND. Left( aOut[ 1 ], 1 ) != "("
         aOut[ 1 ] := Upper( aOut[ 1 ] )   // @ r, c BUTTON ...: the control name leads
      ENDIF
   ENDIF
RETURN aOut

STATIC FUNCTION IsWord( c )
RETURN Len( c ) >= 2 .AND. ( IsAlpha( Left( c, 1 ) ) ) .AND. hb_regexLike( "[A-Za-z_][A-Za-z0-9_]*", c )

/* "FUNCTION Name(" / "PROCEDURE Name" (not STATIC) -> "Name" */
STATIC FUNCTION FuncName( cLine )
   LOCAL cU := Upper( cLine ), cRest, n
   IF hb_LeftEq( cU, "FUNCTION " ) .OR. hb_LeftEq( cU, "PROCEDURE " )
      cRest := LTrim( SubStr( cLine, At( " ", cLine ) + 1 ) )
      n := 1
      DO WHILE n <= Len( cRest ) .AND. ( IsAlpha( SubStr( cRest, n, 1 ) ) .OR. IsDigit( SubStr( cRest, n, 1 ) ) .OR. SubStr( cRest, n, 1 ) == "_" )
         n++
      ENDDO
      IF n > 2
         RETURN Left( cRest, n - 1 )
      ENDIF
   ENDIF
RETURN NIL

STATIC FUNCTION Xml( c )
RETURN StrTran( StrTran( StrTran( StrTran( c, "&", "&amp;" ), "<", "&lt;" ), ">", "&gt;" ), '"', "&quot;" )

STATIC FUNCTION Join( a )
   LOCAL c := "", x
   FOR EACH x IN a
      c += iif( x:__enumIsFirst(), "", " " ) + x
   NEXT
RETURN Xml( c )

STATIC FUNCTION Udl( aL, aFoldOpen )
   LOCAL c := "", n
   LOCAL aStyle := { ;
      { "DEFAULT",           "000000", "0" }, { "COMMENTS",       "008000", "2" }, { "LINE COMMENTS", "008000", "2" }, ;
      { "NUMBERS",           "FF8000", "0" }, { "KEYWORDS1",      "0000FF", "1" }, { "KEYWORDS2",     "8000FF", "1" }, ;
      { "KEYWORDS3",         "0080C0", "0" }, { "KEYWORDS4",      "A0522D", "0" }, { "KEYWORDS5",     "000080", "0" }, ;
      { "KEYWORDS6",         "804000", "1" }, { "KEYWORDS7",      "FF0080", "1" }, { "KEYWORDS8",     "000000", "0" }, ;
      { "OPERATORS",         "000080", "1" }, { "FOLDER IN CODE1", "0000FF", "1" }, { "FOLDER IN CODE2", "000000", "0" }, ;
      { "FOLDER IN COMMENT", "008000", "0" }, { "DELIMITERS1",    "808080", "0" }, { "DELIMITERS2",   "808080", "0" }, ;
      { "DELIMITERS3",       "000000", "0" }, { "DELIMITERS4",    "000000", "0" }, { "DELIMITERS5",   "000000", "0" }, ;
      { "DELIMITERS6",       "000000", "0" }, { "DELIMITERS7",    "000000", "0" }, { "DELIMITERS8",   "000000", "0" } }

   c += '<?xml version="1.0" encoding="UTF-8" ?>' + hb_eol()
   c += '<!-- HMG5 syntax for Notepad++ (Language > User Defined Language > Import...).' + hb_eol()
   c += '     Generated by tools\editor\make_npp_udl.prg from HMG5 INCLUDE\*.ch and SOURCE\*.prg: do not edit by hand. -->' + hb_eol()
   c += '<NotepadPlus>' + hb_eol()
   c += '    <UserLang name="HMG5" ext="prg ch fmg" udlVersion="2.1">' + hb_eol()
   c += '        <Settings>' + hb_eol()
   c += '            <Global caseIgnored="yes" allowFoldOfComments="no" foldCompact="no" forcePureLC="0" decimalSeparator="0" />' + hb_eol()
   c += '            <Prefix Keywords1="no" Keywords2="no" Keywords3="no" Keywords4="no" Keywords5="no" Keywords6="yes" Keywords7="no" Keywords8="no" />' + hb_eol()
   c += '        </Settings>' + hb_eol()
   c += '        <KeywordLists>' + hb_eol()
   c += '            <Keywords name="Comments">00// 00&amp;&amp; 01 02 03/* 04*/</Keywords>' + hb_eol()
   AEval( { "Numbers, prefix1", "Numbers, prefix2", "Numbers, extras1", "Numbers, extras2", "Numbers, suffix1", ;
            "Numbers, suffix2", "Numbers, range" }, {| x | c += '            <Keywords name="' + x + '"></Keywords>' + hb_eol() } )
   c += '            <Keywords name="Operators1">( ) [ ] { } , ; : = + - / * % ^ ! # @ $ &amp; &lt; &gt; |</Keywords>' + hb_eol()
   c += '            <Keywords name="Operators2"></Keywords>' + hb_eol()
   c += '            <Keywords name="Folders in code1, open">' + Join( aFoldOpen ) + '</Keywords>' + hb_eol()
   c += '            <Keywords name="Folders in code1, middle">ELSE ELSEIF CASE OTHERWISE RECOVER ALWAYS</Keywords>' + hb_eol()
   c += '            <Keywords name="Folders in code1, close">END ENDIF NEXT ENDCASE ENDDO ENDSWITCH</Keywords>' + hb_eol()
   AEval( { "Folders in code2, open", "Folders in code2, middle", "Folders in code2, close", ;
            "Folders in comment, open", "Folders in comment, middle", "Folders in comment, close" }, ;
          {| x | c += '            <Keywords name="' + x + '"></Keywords>' + hb_eol() } )
   FOR n := 1 TO 8
      c += '            <Keywords name="Keywords' + hb_ntos( n ) + '">' + iif( n <= 7, Join( aL[ n ] ), "" ) + '</Keywords>' + hb_eol()
   NEXT
   c += '            <Keywords name="Delimiters">00&quot; 01 02&quot; 03&apos; 04 05&apos; 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23</Keywords>' + hb_eol()
   c += '        </KeywordLists>' + hb_eol()
   c += '        <Styles>' + hb_eol()
   FOR n := 1 TO Len( aStyle )
      c += '            <WordsStyle name="' + aStyle[ n ][ 1 ] + '" fgColor="' + aStyle[ n ][ 2 ] + '" bgColor="FFFFFF" fontName="" fontStyle="' + ;
           aStyle[ n ][ 3 ] + '" nesting="0" />' + hb_eol()
   NEXT
   c += '        </Styles>' + hb_eol()
   c += '    </UserLang>' + hb_eol()
   c += '</NotepadPlus>' + hb_eol()
RETURN c
