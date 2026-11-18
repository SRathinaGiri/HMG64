/*
 * HMG5 IDE 5.2 - the project file's other lines and the build log's Error List.
 *
 * Pure functions (no windows), so tests\unit\buildlog checks them directly.
 *
 * The IDE lists only the .prg modules of a project. Until 5.2 it wrote the .hbp back from
 * that list (SaveProject) and again with only the .prg lines before each build, so option
 * lines such as -gc3, -l<lib>, -i<path>, comments and other files were lost. Now:
 *   IDE_HbpOtherLines( cText )   the lines that are not .prg modules, as read (kept by
 *                                OpenProject, written back after the modules by SaveProject)
 *   IDE_HbpBuildText( cText )    what the build gets: every line but the IDE's own .fmg / .rpt
 *   IDE_HbpLines( cText )        the lines, whatever the line ending (CR LF, LF or CR)
 *
 * IDE_BuildLogItems( cLog [, cDir] ) -> the Error List lines for a failed build:
 *   Harbour: <file>(<line>) ...           compiler errors, as before
 *   C compiler: <file>(<line>) ...        gcc errors (#pragma BEGINDUMP, .c files)
 *   Linker: <module.prg>: ... `NAME' ...  linker errors in words: a function called but not
 *                                         defined, defined twice, a C function or a library
 *                                         not found, the .exe still running
 *   Resource compiler ...                 windres, as before
 *   HMG-IDE Builder: ...                  as before
 * The module of a linker line sits between the first two colons and the function between
 * ` and ', where the Error List looks for them to show the module at that function.
 * Until 5.2 a failed link showed nothing for a missing library and mangled the others.
 */

#define CRLF  Chr( 13 ) + Chr( 10 )

STATIC s_aKeep := {}

/* the open project's other lines (OpenProject sets them, SaveProject writes them) */
PROCEDURE IDE_HbpKeepSet( aLines )
   s_aKeep := iif( HB_ISARRAY( aLines ), aLines, {} )
RETURN

FUNCTION IDE_HbpKeepGet()
RETURN s_aKeep

/* 5.2: a project, form, report or module file with any line ending (CR LF, LF or CR) as CR LF,
   since the IDE splits files with MlCount() / MemoLine(), which break only at CR LF; what the
   IDE writes back is CR LF. Until 5.2 an LF-only file lost its lines. */
FUNCTION IDE_ToCRLF( cText )
   cText := StrTran( hb_defaultValue( cText, "" ), Chr( 13 ) + Chr( 10 ), Chr( 10 ) )
RETURN StrTran( StrTran( cText, Chr( 13 ), Chr( 10 ) ), Chr( 10 ), Chr( 13 ) + Chr( 10 ) )

FUNCTION IDE_MemoReadCRLF( cFile )
RETURN IDE_ToCRLF( hb_MemoRead( cFile ) )

FUNCTION IDE_HbpLines( cText )
   LOCAL aOut := {}, cLine
   cText := StrTran( StrTran( hb_defaultValue( cText, "" ), Chr( 13 ) + Chr( 10 ), Chr( 10 ) ), Chr( 13 ), Chr( 10 ) )
   FOR EACH cLine IN hb_ATokens( cText, Chr( 10 ) )
      AAdd( aOut, AllTrim( cLine ) )
   NEXT
RETURN aOut

STATIC FUNCTION IsExt( cLine, cExt )
RETURN Lower( Right( cLine, Len( cExt ) ) ) == cExt

FUNCTION IDE_HbpOtherLines( cText )
   LOCAL aOut := {}, cLine
   FOR EACH cLine IN IDE_HbpLines( cText )
      IF ! Empty( cLine ) .AND. ! IsExt( cLine, ".prg" )
         AAdd( aOut, cLine )
      ENDIF
   NEXT
RETURN aOut

FUNCTION IDE_HbpBuildText( cText )
   LOCAL cOut := "", cLine
   FOR EACH cLine IN IDE_HbpLines( cText )
      IF ! Empty( cLine ) .AND. ! IsExt( cLine, ".fmg" ) .AND. ! IsExt( cLine, ".rpt" )
         cOut += cLine + CRLF
      ENDIF
   NEXT
RETURN cOut

/* ------------------------------------------------------------------------------------------ */

/* between the first cOpen and the next cClose after it */
STATIC FUNCTION Between( c, cOpen, cClose )
   LOCAL n := At( cOpen, c ), m
   IF n == 0
      RETURN ""
   ENDIF
   m := hb_At( cClose, c, n + Len( cOpen ) )
RETURN iif( m == 0, "", SubStr( c, n + Len( cOpen ), m - n - Len( cOpen ) ) )

/* where a linker message points: "...\x.o:x.c:(.text+0x10)" or "...\libhmg-64.a(c_windows.o):..."
   -> { cShown, lModule }: the module x.prg when it is in cDir, else the object or library */
STATIC FUNCTION Place( cLoc, cDir )
   LOCAL n, cObj, cLib
   cLoc := StrTran( cLoc, "/", "\" )
   IF ( n := At( ".a(", Lower( cLoc ) ) ) > 0
      cLib := hb_FNameNameExt( Left( cLoc, n + 1 ) )
      cObj := Between( SubStr( cLoc, n + 1 ), "(", ")" )
      RETURN { cLib + iif( Empty( cObj ), "", " (" + cObj + ")" ), .F. }
   ENDIF
   IF ( n := At( ".o:", Lower( cLoc ) ) ) > 0
      cObj := hb_FNameName( Left( cLoc, n + 1 ) )
      IF hb_FileExists( hb_DirSepAdd( cDir ) + cObj + ".prg" )
         RETURN { cObj + ".prg", .T. }
      ENDIF
      RETURN { cObj + ".o", .F. }
   ENDIF
RETURN { "", .F. }

STATIC FUNCTION FunName( cSym )
   IF Left( cSym, 7 ) == "HB_FUN_"
      RETURN { SubStr( cSym, 8 ), .T. }
   ENDIF
   IF Left( cSym, 6 ) == "__imp_"
      cSym := SubStr( cSym, 7 )
   ENDIF
RETURN { cSym, .F. }

STATIC PROCEDURE Add( aOut, cItem )
   IF AScan( aOut, {| x | x == cItem } ) == 0
      AAdd( aOut, cItem )
   ENDIF
RETURN

FUNCTION IDE_BuildLogItems( cLog, cDir )
   LOCAL aOut := {}, aLines, i, cLine, cLow, n, r, cSym, aFun, aP, aQ, cLoc, cMsg
   LOCAL lLinkFailed := .F., lUndefHb := .F., cUnknown := "", nLeftPar, nRightPar, nLineNo

   hb_default( @cDir, hb_cwd() )
   aLines := IDE_HbpLines( cLog )

   FOR i := 1 TO Len( aLines )
      cLine := aLines[ i ]
      cLow := Lower( cLine )
      IF Empty( cLine )
         LOOP
      ENDIF

      IF "can't delete previous" $ cLow
         Add( aOut, "HMG-IDE Builder: " + cLine )
         LOOP
      ENDIF

      // the linker's own lines
      n := At( "ld.exe: ", cLow )
      IF n == 0 .AND. Left( cLow, 4 ) == "ld: "
         n := 1
      ENDIF
      IF n > 0
         r := SubStr( cLine, n + iif( SubStr( cLow, n, 3 ) == "ld:", 4, 8 ) )
         lLinkFailed := .T.
         DO CASE
         CASE "undefined reference to `" $ r
            cSym := Between( r, "`", "'" )
            aFun := FunName( cSym )
            aP   := Place( Left( r, At( ": undefined reference", r ) - 1 ), cDir )
            IF aFun[ 2 ]
               lUndefHb := .T.
               cMsg := "function `" + aFun[ 1 ] + "' is called but not defined anywhere"
            ELSE
               cMsg := "C function `" + aFun[ 1 ] + "' not found - a library missing?"
            ENDIF
            IF aP[ 2 ]
               Add( aOut, "Linker: " + aP[ 1 ] + ": " + cMsg )
            ELSE
               Add( aOut, "Linker: " + cMsg + iif( Empty( aP[ 1 ] ), "", " (called in " + aP[ 1 ] + ")" ) )
            ENDIF
         CASE "multiple definition of `" $ r
            cSym := Between( r, "`", "'" )
            aFun := FunName( cSym )
            aP   := Place( Left( r, At( ": multiple definition", r ) - 1 ), cDir )
            cLoc := ""
            IF ";" $ r .AND. "first defined here" $ r
               cLoc := AllTrim( SubStr( r, At( ";", r ) + 1 ) )
            ELSEIF i < Len( aLines ) .AND. "first defined here" $ aLines[ i + 1 ]
               cLoc := aLines[ i + 1 ]
               IF ( n := At( "ld.exe: ", Lower( cLoc ) ) ) > 0
                  cLoc := SubStr( cLoc, n + 8 )
               ENDIF
               i++
            ENDIF
            aQ := Place( cLoc, cDir )
            IF ! aP[ 2 ] .AND. aQ[ 2 ]      // the program's module first
               n := aP ; aP := aQ ; aQ := n
            ENDIF
            cMsg := iif( aFun[ 2 ], "function `", "C symbol `" ) + aFun[ 1 ] + "' is defined twice" + ;
                    iif( Empty( aQ[ 1 ] ), "", " - also in " + aQ[ 1 ] )
            IF aP[ 2 ]
               Add( aOut, "Linker: " + aP[ 1 ] + ": " + cMsg )
            ELSE
               Add( aOut, "Linker: " + cMsg + iif( Empty( aP[ 1 ] ), "", " (in " + aP[ 1 ] + ")" ) )
            ENDIF
         CASE "cannot find -l" $ r
            cSym := SubStr( r, At( "cannot find -l", r ) + 14 )
            IF ( n := At( ":", cSym ) ) > 0
               cSym := Left( cSym, n - 1 )
            ENDIF
            cSym := AllTrim( StrTran( cSym, '"', "" ) )
            Add( aOut, "Linker: library `" + cSym + "' not found (lib" + cSym + ".a) - check the project's libraries" )
         CASE "cannot open output file" $ r
            cSym := AllTrim( Between( r + ":", "cannot open output file", ":" ) )
            Add( aOut, "Linker: cannot write " + hb_FNameNameExt( StrTran( cSym, "/", "\" ) ) + " - is the program still running?" )
         CASE ".rsrc merge failure" $ r .OR. "have you installed the static version" $ r .OR. "first defined here" $ r
            // follows the real error; nothing to add
         OTHERWISE
            Add( aOut, "Linker: " + StrTran( r, ":", " -" ) )
         ENDCASE
         LOOP
      ENDIF

      IF "collect2" $ cLow .OR. "running linker" $ cLow
         lLinkFailed := .T.
         LOOP
      ENDIF

      // hbmk2's own list of unknown functions (a line and its continuation lines)
      IF "referenced, missing, but unknown function(s):" $ cLow
         cUnknown := AllTrim( SubStr( cLine, At( "function(s):", cLow ) + 12 ) )
         DO WHILE i < Len( aLines ) .AND. Right( cUnknown, 1 ) == "," .AND. ! Empty( aLines[ i + 1 ] )
            i++
            cUnknown += " " + aLines[ i ]
         ENDDO
         LOOP
      ENDIF

      // the command line hbmk2 shows after a link failure
      IF Left( cLow, 8 ) == "gcc.exe " .OR. Left( cLow, 4 ) == "gcc "
         LOOP
      ENDIF

      // Harbour
      IF ".prg(" $ cLow .OR. ".fmg(" $ cLow .OR. ".ch(" $ cLow
         Add( aOut, "Harbour: " + cLine )
         LOOP
      ENDIF

      // the resource compiler, as the IDE showed it before 5.2 (lines of _temp.rc after its 42)
      IF "windres" $ cLow
         cLine := StrTran( StrTran( cLine, "windres:", "" ), "_temp.rc:", "line:" )
         nLeftPar := At( ":", cLine )
         nRightPar := RAt( ":", cLine )
         nLineNo := Val( SubStr( cLine, nLeftPar + 1, nRightPar - nLeftPar - 1 ) ) - 42
         Add( aOut, "Resource compiler " + AllTrim( Left( cLine, nLeftPar ) + hb_ntos( nLineNo ) + SubStr( cLine, nRightPar ) ) )
         LOOP
      ENDIF

      // gcc: "<file>:<line>:<col>: error: <text>"
      IF ( n := At( ": error: ", cLow ) ) > 0 .OR. ( n := At( ": fatal error: ", cLow ) ) > 0
         cLoc := Left( cLine, n - 1 )
         cMsg := AllTrim( SubStr( cLine, At( "error: ", SubStr( cLow, n ) ) + n - 1 + 7 ) )
         aP := hb_ATokens( cLoc, ":" )
         IF Len( aP ) >= 3 .AND. Val( ATail( aP ) ) > 0 .AND. Val( aP[ Len( aP ) - 1 ] ) > 0
            cLoc := hb_FNameNameExt( StrTran( Left( cLoc, Len( cLoc ) - Len( ATail( aP ) ) - Len( aP[ Len( aP ) - 1 ] ) - 2 ), "/", "\" ) ) + ;
                    "(" + aP[ Len( aP ) - 1 ] + ")"
         ELSEIF Len( aP ) >= 2 .AND. Val( ATail( aP ) ) > 0
            cLoc := hb_FNameNameExt( StrTran( Left( cLoc, Len( cLoc ) - Len( ATail( aP ) ) - 1 ), "/", "\" ) ) + "(" + ATail( aP ) + ")"
         ENDIF
         Add( aOut, "C compiler: " + cLoc + " " + cMsg )
         LOOP
      ENDIF
   NEXT

   // hbmk2's list says nothing more than the linker's lines; alone (other linkers) it is shown
   IF ! Empty( cUnknown ) .AND. ! lUndefHb
      Add( aOut, "Linker: unknown function(s) " + cUnknown + " - defined nowhere" )
   ENDIF

   IF lLinkFailed .AND. AScan( aOut, {| x | Left( x, 7 ) == "Linker:" } ) == 0
      Add( aOut, "Linker: the link step failed - the Build Log shows the linker's words" )
   ENDIF

   // never an empty list for a failed build: the lines that say "error", else the first lines
   IF Empty( aOut ) .AND. ! Empty( cLog )
      FOR EACH cLine IN aLines
         IF "error" $ Lower( cLine ) .AND. Len( aOut ) < 15
            Add( aOut, "Build: " + cLine )
         ENDIF
      NEXT
      IF Empty( aOut )
         FOR EACH cLine IN aLines
            IF ! Empty( cLine ) .AND. Len( aOut ) < 3 .AND. ! ( "harbour " $ Lower( cLine ) .OR. "copyright" $ Lower( cLine ) )
               Add( aOut, "Build: " + cLine )
            ENDIF
         NEXT
      ENDIF
   ENDIF
RETURN aOut
