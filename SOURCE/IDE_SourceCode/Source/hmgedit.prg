/*----------------------------------------------------------------------------
 HMG5 Code Editor (HMGEdit.exe) - the IDE's built-in code editor as a program of its own

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 The same editor as View > Code Editor in the IDE (ide_editor.prg, ide_editw.c,
 completion from ide_complete.prg and prjindex.prg), without the IDE:

    HMGEdit [ [/L<line>] file ... ]

 Opens each file in a tab (a file that does not exist yet is created on the first
 Save); /L<n> goes to line n of the next file. Build > Save All, Build and Run (F5)
 builds the current file's project - the .hbp in its folder that lists it - or the
 .prg itself with build64 /n, opens the first error at its line, or runs the program.
 Settings: hmgedit.ini next to HMGEdit.exe ("edfont=", "edsize=", "edindent=" as in
 the IDE's ide.ini, and "external=<program>" for File > Open in External Editor).
---------------------------------------------------------------------------*/

#include "hmg.ch"

DECLARE WINDOW IDE_Ed

MEMVAR ProgramEditor
MEMVAR ProjectName

STATIC s_aEdFont   := { "Consolas", 10, 3 }   // font, size in points, indent
STATIC s_lStarted  := .F.                     // the editor window has been opened

FUNCTION Main( ... )
   LOCAL aArgs := hb_AParams()

   PUBLIC ProgramEditor := "notepad.exe"      // File > Open in External Editor
   PUBLIC ProjectName   := ""                 // the .hbp completion indexes (ide_complete.prg)

   SET CENTURY ON
   SET DATE ANSI

   HMGEdit_LoadSettings()

   // test modes (tests/ide/run.ps1): /edtest <out.txt> is the IDE's editor self-test;
   // /buildtest <file> <out.txt> builds like F5 and writes the result instead of showing it
   IF Len( aArgs ) >= 2 .AND. Upper( aArgs[ 1 ] ) == "/EDTEST"
      DEFINE WINDOW Win_HMGEdit AT 0, 0 WIDTH 200 HEIGHT 100 TITLE "HMG Code Editor" MAIN NOSHOW
         DEFINE TIMER Tmr_Test INTERVAL 300 ACTION ( Win_HMGEdit.Tmr_Test.Enabled := .F., IDE_EdSelfTest( aArgs[ 2 ] ) )
      END WINDOW
      Win_HMGEdit.Activate
      RETURN NIL
   ENDIF
   IF Len( aArgs ) >= 3 .AND. Upper( aArgs[ 1 ] ) == "/BUILDTEST"
      DEFINE WINDOW Win_HMGEdit AT 0, 0 WIDTH 200 HEIGHT 100 TITLE "HMG Code Editor" MAIN NOSHOW
         DEFINE TIMER Tmr_Test INTERVAL 300 ACTION ( Win_HMGEdit.Tmr_Test.Enabled := .F., HMGEdit_BuildTest( aArgs[ 2 ], aArgs[ 3 ] ) )
      END WINDOW
      Win_HMGEdit.Activate
      RETURN NIL
   ENDIF

   // the editor window is not a MAIN window (the IDE owns one): a hidden main window
   // carries the message loop and ends the program when the editor is closed
   DEFINE WINDOW Win_HMGEdit AT 0, 0 WIDTH 200 HEIGHT 100 TITLE "HMG Code Editor" MAIN NOSHOW ;
      ON INIT HMGEdit_Start( aArgs )
      DEFINE TIMER Tmr_Closed INTERVAL 250 ACTION HMGEdit_CheckClosed()
   END WINDOW
   Win_HMGEdit.Activate
RETURN NIL

STATIC PROCEDURE HMGEdit_BuildTest( cFile, cOut )
   LOCAL a
   IDE_EdShow()
   IDE_EdOpen( cFile )
   a := HMGEdit_Build()
   hb_MemoWrit( cOut, "buildtest: " + a[ 1 ] + " " + hb_ValToExp( a[ 2 ] ) + Chr( 13 ) + Chr( 10 ) )
   ExitProcess( 0 )
RETURN

STATIC PROCEDURE HMGEdit_Start( aArgs )
   LOCAL cArg, nLine := 0, lFirst := .T.

   IDE_EdShow()
   IDE_Ed.Center

   FOR EACH cArg IN aArgs
      IF Upper( Left( cArg, 2 ) ) $ "/L|-L" .AND. Val( SubStr( cArg, 3 ) ) > 0
         nLine := Int( Val( SubStr( cArg, 3 ) ) )
         LOOP
      ENDIF
      IF lFirst
         ProjectName := HMGEdit_FindProject( HMGEdit_FullPath( cArg ) )
         lFirst := .F.
      ENDIF
      IDE_EdOpen( cArg, nLine )
      nLine := 0
   NEXT
   s_lStarted := .T.
RETURN

/* the editor closed: end the program (not before it was opened: the timer can fire
   while the main window is being activated) */
STATIC PROCEDURE HMGEdit_CheckClosed()
   IF s_lStarted .AND. ! IsWindowDefined( IDE_Ed )
      Win_HMGEdit.Tmr_Closed.Enabled := .F.
      Win_HMGEdit.Release
   ENDIF
RETURN

/* ------------------------------------------------------------ settings */

STATIC FUNCTION HMGEdit_Ini()
RETURN hb_DirBase() + "hmgedit.ini"

STATIC PROCEDURE HMGEdit_LoadSettings()
   LOCAL cLine, cKey, cVal, n
   FOR EACH cLine IN hb_ATokens( StrTran( hb_MemoRead( HMGEdit_Ini() ), Chr( 13 ) ), Chr( 10 ) )
      IF ( n := At( "=", cLine ) ) == 0
         LOOP
      ENDIF
      cKey := Lower( AllTrim( Left( cLine, n - 1 ) ) )
      cVal := AllTrim( SubStr( cLine, n + 1 ) )
      DO CASE
      CASE cKey == "edfont" .AND. ! Empty( cVal )
         s_aEdFont[ 1 ] := cVal
      CASE cKey == "edsize" .AND. Val( cVal ) >= 6 .AND. Val( cVal ) <= 48
         s_aEdFont[ 2 ] := Int( Val( cVal ) )
      CASE cKey == "edindent" .AND. Val( cVal ) >= 1 .AND. Val( cVal ) <= 16
         s_aEdFont[ 3 ] := Int( Val( cVal ) )
      CASE cKey == "external" .AND. ! Empty( cVal )
         ProgramEditor := cVal
      ENDCASE
   NEXT
RETURN

STATIC PROCEDURE HMGEdit_SaveSettings()
   hb_MemoWrit( HMGEdit_Ini(), ;
      "edfont=" + s_aEdFont[ 1 ] + Chr( 13 ) + Chr( 10 ) + ;
      "edsize=" + hb_ntos( s_aEdFont[ 2 ] ) + Chr( 13 ) + Chr( 10 ) + ;
      "edindent=" + hb_ntos( s_aEdFont[ 3 ] ) + Chr( 13 ) + Chr( 10 ) + ;
      "external=" + ProgramEditor + Chr( 13 ) + Chr( 10 ) )
RETURN

/* ------------------------------------------------- what ide_editor.prg asks the IDE */

/* always the built-in editor here */
FUNCTION IDE_UseBuiltinEditor()
RETURN .T.

/* the editor's { cFont, nSize, nIndent }; with aSet, sets and saves them first */
FUNCTION IDE_EdFontSettings( aSet )
   IF HB_ISARRAY( aSet ) .AND. ( aSet[ 1 ] != s_aEdFont[ 1 ] .OR. aSet[ 2 ] != s_aEdFont[ 2 ] .OR. aSet[ 3 ] != s_aEdFont[ 3 ] )
      s_aEdFont := AClone( aSet )
      HMGEdit_SaveSettings()
   ENDIF
RETURN AClone( s_aEdFont )

/* File > Open in External Editor (the same arguments as the IDE gives) */
PROCEDURE IDE_OpenAtLine( cFile, nLine, lExternal )
   LOCAL cEd := Lower( hb_FNameName( ProgramEditor ) ), cArgs
   IF ! hb_defaultValue( lExternal, .F. )
      IDE_EdOpen( cFile, nLine )
      RETURN
   ENDIF
   nLine := hb_defaultValue( nLine, 1 )
   DO CASE
   CASE "notepad++" $ cEd
      cArgs := "-n" + hb_ntos( nLine ) + ' "' + cFile + '"'
   CASE cEd == "notepad2" .OR. cEd == "notepad3"
      cArgs := "/g " + hb_ntos( nLine ) + ' "' + cFile + '"'
   CASE cEd == "code"
      cArgs := '--goto "' + cFile + ":" + hb_ntos( nLine ) + '"'
   OTHERWISE
      cArgs := '"' + cFile + '"'
   ENDCASE
   EXECUTE FILE ProgramEditor PARAMETERS cArgs
RETURN

/* Build > Save All, Build and Run (F5): ide_editor.prg has saved every file */
PROCEDURE RunApplication()
   LOCAL a := HMGEdit_Build()
   SWITCH a[ 1 ]
   CASE "OK"
      ShellExecute( 0, "open", a[ 2 ], , hb_FNameDir( a[ 2 ] ), 1 )
      EXIT
   CASE "ERRORS"
      MsgStop( a[ 2 ][ 1 ], "Build failed - " + a[ 2 ][ 2 ] )
      IF ! Empty( a[ 2 ][ 3 ] )
         IDE_EdOpen( a[ 2 ][ 3 ][ 1 ], a[ 2 ][ 3 ][ 2 ] )
      ENDIF
      EXIT
   OTHERWISE
      MsgStop( a[ 2 ], "HMG Code Editor" )
   ENDSWITCH
RETURN

/* builds the current file's project: { "OK", cExe } | { "ERRORS", { cText, cTarget, { cFile, nLine } | NIL } }
   | { "STOP", cWhy } */
STATIC FUNCTION HMGEdit_Build()
   LOCAL cFile := IDE_EdCurrentFile(), cTarget, cDir, cBuild, cLog, cExe, cOld

   IF Empty( cFile )
      RETURN { "STOP", "Open the program's .prg (or .hbp) first." }
   ENDIF
   cTarget := HMGEdit_FindProject( cFile )
   IF Empty( cTarget )
      IF ! Lower( hb_FNameExt( cFile ) ) == ".prg"
         RETURN { "STOP", "Build and Run works on a .prg or .hbp file." + hb_eol() + cFile }
      ENDIF
      cTarget := cFile
   ENDIF
   ProjectName := iif( Lower( hb_FNameExt( cTarget ) ) == ".hbp", cTarget, "" )

   IF Empty( cBuild := HMGEdit_Build64() )
      RETURN { "STOP", "build64.bat was not found. Put HMGEdit.exe in HMG's IDE folder or set HMGPATH." }
   ENDIF

   cDir := hb_FNameDir( cTarget )
   cExe := cDir + hb_FNameName( cTarget ) + ".exe"
   FErase( cDir + "error.log" )

   cOld := hb_cwd( cDir )                     // build64 builds in the current folder
   WaitWindow( "Building " + hb_FNameNameExt( cTarget ) + " ...", .T. )
   EXECUTE FILE '"' + cBuild + '" /n "' + hb_FNameNameExt( cTarget ) + '"' WAIT HIDE
   WaitWindow()
   hb_cwd( cOld )

   IF hb_FileExists( cDir + "error.log" )
      cLog := hb_MemoRead( cDir + "error.log" )
      RETURN { "ERRORS", { HMGEdit_ErrorText( cLog ), hb_FNameNameExt( cTarget ), HMGEdit_FirstError( cLog, cDir ) } }
   ENDIF
   IF ! hb_FileExists( cExe )
      RETURN { "STOP", "The build ended without " + hb_FNameNameExt( cExe ) + "." }
   ENDIF
RETURN { "OK", cExe }

/* ------------------------------------------------------------ helpers */

STATIC FUNCTION HMGEdit_FullPath( cFile )
   cFile := StrTran( AllTrim( cFile ), "/", "\" )
   IF ! ( ":" $ cFile .OR. hb_LeftEq( cFile, "\\" ) )
      cFile := hb_PathJoin( hb_cwd(), cFile )
   ENDIF
RETURN hb_PathNormalize( cFile )

/* the .hbp a file belongs to: the file itself, or a .hbp in its folder that lists it */
STATIC FUNCTION HMGEdit_FindProject( cFile )
   LOCAL cDir := hb_FNameDir( cFile ), cName := Lower( hb_FNameNameExt( cFile ) ), aHbp, cLine

   IF Lower( hb_FNameExt( cFile ) ) == ".hbp"
      RETURN cFile
   ENDIF
   FOR EACH aHbp IN Directory( cDir + "*.hbp" )            // aHbp[ 1 ]: the file name
      FOR EACH cLine IN hb_ATokens( StrTran( hb_MemoRead( cDir + aHbp[ 1 ] ), Chr( 13 ) ), Chr( 10 ) )
         cLine := Lower( AllTrim( StrTran( cLine, "/", "\" ) ) )
         IF cLine == cName .OR. Right( cLine, Len( cName ) + 1 ) == "\" + cName
            RETURN cDir + aHbp[ 1 ]
         ENDIF
      NEXT
   NEXT
RETURN ""

/* build64.bat: in HMGEdit.exe's folder or one above it (installed in HMG's IDE\),
   else in %HMGPATH% or C:\HMG5 */
STATIC FUNCTION HMGEdit_Build64()
   LOCAL cDir := hb_DirBase(), c, i
   FOR i := 1 TO 4
      IF hb_FileExists( cDir + "build64.bat" )
         RETURN cDir + "build64.bat"
      ENDIF
      cDir := hb_PathNormalize( cDir + "..\" )
   NEXT
   IF ! Empty( GetEnv( "HMGPATH" ) ) .AND. hb_FileExists( c := hb_DirSepAdd( GetEnv( "HMGPATH" ) ) + "build64.bat" )
      RETURN c
   ENDIF
RETURN iif( hb_FileExists( "C:\HMG5\build64.bat" ), "C:\HMG5\build64.bat", "" )

/* { cFile, nLine } of the first "file.prg(123) Error ..." line, or NIL */
STATIC FUNCTION HMGEdit_FirstError( cLog, cDir )
   LOCAL cLine, n, m, cFile
   FOR EACH cLine IN hb_ATokens( StrTran( cLog, Chr( 13 ) ), Chr( 10 ) )
      cLine := AllTrim( cLine )
      IF ( n := At( "(", cLine ) ) > 1 .AND. ( m := At( ")", cLine ) ) > n + 1 .AND. ;
         "ERROR" $ Upper( SubStr( cLine, m ) ) .AND. Val( SubStr( cLine, n + 1 ) ) > 0
         cFile := StrTran( Left( cLine, n - 1 ), "/", "\" )
         IF ! ( ":" $ cFile )
            cFile := cDir + cFile
         ENDIF
         IF hb_FileExists( cFile )
            RETURN { cFile, Int( Val( SubStr( cLine, n + 1 ) ) ) }
         ENDIF
      ENDIF
   NEXT
RETURN NIL

/* the log's error lines (at most 15), or its start */
STATIC FUNCTION HMGEdit_ErrorText( cLog )
   LOCAL cText := "", nCount := 0, cLine
   FOR EACH cLine IN hb_ATokens( StrTran( cLog, Chr( 13 ) ), Chr( 10 ) )
      IF "ERROR" $ Upper( cLine ) .AND. nCount < 15
         cText += iif( nCount == 0, "", hb_eol() ) + AllTrim( cLine )
         nCount++
      ENDIF
   NEXT
RETURN iif( nCount == 0, Left( cLog, 1500 ), cText )
