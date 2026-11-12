/*----------------------------------------------------------------------------
 HMG5 IDE - built-in code editor (PHASE4-DESIGN.md 6.7, I6 b)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 The editor window: a tab for each open file, menus, find and replace, files kept in
 their own encoding and line endings. The editing itself (RichEdit, line numbers,
 colouring, auto-indent) is ide_editw.c.

 IDE_EditFile( cFile [, nLine] ) is where the IDE opens a source file: the built-in
 editor, or the program of editor.ini when Tools > Preferences says so.
---------------------------------------------------------------------------*/

#include "hmg.ch"

DECLARE WINDOW IDE_Ed
DECLARE WINDOW IDE_EdFind

MEMVAR ProgramEditor

#define D_VIEW    1
#define D_FILE    2
#define D_ENC     3
#define D_BOM     4
#define D_CRLF    5
#define D_TIME    6

#define ENC_UTF8  1
#define ENC_ANSI  2
#define ENC_UTF16 3

#define K_CTRL    0x10000
#define K_SHIFT   0x20000
#define K_ALT     0x40000

#define CMD_UNDO     1
#define CMD_REDO     2
#define CMD_CUT      3
#define CMD_COPY     4
#define CMD_PASTE    5
#define CMD_SELALL   7
#define CMD_INDENT   8
#define CMD_OUTDENT  9
#define CMD_COMMENT 10
#define CMD_CANUNDO 11

STATIC s_hHost   := 0      // ide_editw.c host window (tabs and views)
STATIC s_aDocs   := {}     // { hView, cFile, nEnc, lBOM, lCRLF, tTime }
STATIC s_cFind   := ""
STATIC s_cRepl   := ""
STATIC s_lCase   := .F.
STATIC s_lWord   := .F.
STATIC s_lBusy   := .F.    // a question is open: no disk check
STATIC s_aPending := NIL
STATIC s_cTrace  := ""     // self-test step log   // { cFile, nLine } to open once the build-error window is gone

/* where the IDE opens a source file */
PROCEDURE IDE_EditFile( cFile, nLine )
   IF Empty( cFile )
      RETURN
   ENDIF
   IF IDE_UseBuiltinEditor()
      IDE_EdOpen( cFile, nLine )
   ELSEIF HB_ISNUMERIC( nLine ) .AND. nLine > 0
      IDE_OpenAtLine( cFile, nLine, .T. )
   ELSE
      EXECUTE FILE ProgramEditor PARAMETERS cFile
   ENDIF
RETURN

/* the build-error window asks for a file at a line; opened after that window closes */
PROCEDURE IDE_EdOpenLater( cFile, nLine )
   s_aPending := { cFile, nLine }
RETURN

PROCEDURE IDE_EdOpenPending()
   LOCAL a := s_aPending
   s_aPending := NIL
   IF HB_ISARRAY( a ) .AND. ! Empty( a[ 1 ] )
      IDE_EditFile( a[ 1 ], a[ 2 ] )
   ENDIF
RETURN

/* the build-error window's "Open in editor" (and double-click): the file of the error
   at the line shown, once that modal window has closed */
PROCEDURE IDE_LogOpenInEditor()
   MEMVAR cCurrentFixedFile
   LOCAL cFile := iif( Type( "cCurrentFixedFile" ) == "C", cCurrentFixedFile, "" )
   LOCAL nLine := GetProperty( "showlog", "grid_1", "Value" )
   IF Empty( cFile ) .OR. ! hb_FileExists( cFile )
      RETURN
   ENDIF
   IDE_EdOpenLater( cFile, iif( HB_ISNUMERIC( nLine ), nLine, 0 ) )
   DoMethod( "showlog", "Release" )
RETURN

/* View > Code Editor */
PROCEDURE IDE_EdShow()
   IF IsWindowDefined( IDE_Ed )
      IDE_Ed.Restore
      IDE_EdPlace()
      IDE_Ed.SetFocus
      RETURN
   ENDIF

   DEFINE WINDOW IDE_Ed AT 60, 120 WIDTH 1040 HEIGHT 720 ;
      TITLE "HMG Code Editor" ;
      ON SIZE IDEED_FIT( s_hHost ) ;
      ON MAXIMIZE IDEED_FIT( s_hHost ) ;
      ON GOTFOCUS IDE_EdCheckDisk() ;
      ON INTERACTIVECLOSE IDE_EdCanClose() ;
      ON RELEASE IDE_EdReleased()

      DEFINE MAIN MENU
         DEFINE POPUP "&File"
            MENUITEM "&Open..." + Chr( 9 ) + "Ctrl+O"          ACTION IDE_EdOpenDialog()
            MENUITEM "&Save" + Chr( 9 ) + "Ctrl+S"             ACTION IDE_EdSave( IDE_EdCur() )
            MENUITEM "Save &As..."                             ACTION IDE_EdSaveAs( IDE_EdCur() )
            MENUITEM "Save A&ll" + Chr( 9 ) + "Ctrl+Shift+S"   ACTION IDE_EdSaveAll()
            MENUITEM "&Reload from Disk"                       ACTION IDE_EdReload( IDE_EdCur(), .T. )
            SEPARATOR
            MENUITEM "Open in E&xternal Editor"                ACTION IDE_EdExternal( IDE_EdCur() )
            SEPARATOR
            MENUITEM "&Close Tab" + Chr( 9 ) + "Ctrl+W"        ACTION IDE_EdCloseDoc( IDE_EdCurView() )
            MENUITEM "Close &Editor"                           ACTION iif( IDE_EdCanClose(), DoMethod( "IDE_Ed", "Release" ), NIL )
         END POPUP
         DEFINE POPUP "&Edit"
            MENUITEM "&Undo" + Chr( 9 ) + "Ctrl+Z"             ACTION IDE_EdCmd( CMD_UNDO )
            MENUITEM "&Redo" + Chr( 9 ) + "Ctrl+Y"             ACTION IDE_EdCmd( CMD_REDO )
            SEPARATOR
            MENUITEM "Cu&t" + Chr( 9 ) + "Ctrl+X"              ACTION IDE_EdCmd( CMD_CUT )
            MENUITEM "&Copy" + Chr( 9 ) + "Ctrl+C"             ACTION IDE_EdCmd( CMD_COPY )
            MENUITEM "&Paste" + Chr( 9 ) + "Ctrl+V"            ACTION IDE_EdCmd( CMD_PASTE )
            MENUITEM "Select &All" + Chr( 9 ) + "Ctrl+A"       ACTION IDE_EdCmd( CMD_SELALL )
            SEPARATOR
            MENUITEM "&Indent Lines" + Chr( 9 ) + "Tab"        ACTION IDE_EdCmd( CMD_INDENT )
            MENUITEM "&Outdent Lines" + Chr( 9 ) + "Shift+Tab" ACTION IDE_EdCmd( CMD_OUTDENT )
            MENUITEM "Co&mment / Uncomment" + Chr( 9 ) + "Ctrl+Q" ACTION IDE_EdCmd( CMD_COMMENT )
         END POPUP
         DEFINE POPUP "&Search"
            MENUITEM "&Find..." + Chr( 9 ) + "Ctrl+F"          ACTION IDE_EdFindWindow( .F. )
            MENUITEM "&Replace..." + Chr( 9 ) + "Ctrl+H"       ACTION IDE_EdFindWindow( .T. )
            MENUITEM "Find &Next" + Chr( 9 ) + "F3"            ACTION IDE_EdFindNext( .F. )
            MENUITEM "Find &Previous" + Chr( 9 ) + "Shift+F3"  ACTION IDE_EdFindNext( .T. )
            SEPARATOR
            MENUITEM "&Go to Line..." + Chr( 9 ) + "Ctrl+G"    ACTION IDE_EdGoto()
         END POPUP
         DEFINE POPUP "&Build"
            MENUITEM "Save All, &Build and Run" + Chr( 9 ) + "F5" ACTION IDE_EdBuildRun()
         END POPUP
      END MENU

      DEFINE STATUSBAR
         STATUSITEM "" WIDTH 560
         STATUSITEM "" WIDTH 170
         STATUSITEM "" WIDTH 100
         STATUSITEM "" WIDTH 70
      END STATUSBAR
   END WINDOW

   s_hHost := IDEED_CREATE( GetFormHandle( "IDE_Ed" ), 0, 0, 800, 600, HMG_IsDarkMode(), "Consolas", 10, 3, 4, HMG_SupportUnicode() )
   IDE_EdPlace()
   IDEED_FIT( s_hHost )
   _ActivateWindow( { "IDE_Ed" }, .F. )
   IDE_EdPlace()          // again, now that the window has a visible frame (exact borders)
   IDEED_FIT( s_hHost )   // the status bar's height is known once the window is shown
RETURN

/* below the IDE's menu and toolbars, right of the Project Browser, to the bottom of the work area */
STATIC PROCEDURE IDE_EdPlace()
   IF IsWindowDefined( Form_Main ) .AND. IsWindowVisible( GetFormHandle( "Form_Main" ) )
      IDEED_PLACE( GetFormHandle( "IDE_Ed" ), GetFormHandle( "Form_Main" ), ;
                   iif( IsWindowDefined( Project ), GetFormHandle( "Project" ), 0 ) )
      IDEED_FIT( s_hHost )
   ENDIF
RETURN

/* opens a file (or selects its tab) and goes to nLine */
PROCEDURE IDE_EdOpen( cFile, nLine )
   LOCAL n, hView
   IDE_EdShow()
   cFile := IDE_EdFullPath( cFile )
   n := AScan( s_aDocs, {| a | Lower( a[ D_FILE ] ) == Lower( cFile ) } )
   IF n > 0
      hView := s_aDocs[ n ][ D_VIEW ]
      IDEED_SELECT( hView )
   ELSEIF Empty( hView := IDE_EdLoad( cFile ) )
      RETURN
   ENDIF
   IF HB_ISNUMERIC( nLine ) .AND. nLine > 0
      IDEED_GOTO( hView, nLine )
   ENDIF
   IDE_EdStatus()
   IDE_Ed.SetFocus
   IDEED_FOCUS( hView )
RETURN

STATIC FUNCTION IDE_EdFullPath( cFile )
   cFile := StrTran( AllTrim( cFile ), "/", "\" )
   IF ! ( ":" $ cFile .OR. hb_LeftEq( cFile, "\\" ) )
      cFile := hb_PathJoin( hb_cwd(), cFile )
   ENDIF
RETURN hb_PathNormalize( cFile )

STATIC FUNCTION IDE_EdDefaultEnc()
RETURN iif( HMG_SupportUnicode(), ENC_UTF8, ENC_ANSI )

STATIC FUNCTION IDE_EdLoad( cFile )
   LOCAL cBytes := "", aInfo, hView, tTime := NIL
   IF hb_FileExists( cFile )
      IF hb_FSize( cFile ) > 64 * 1024 * 1024
         MsgStop( cFile + CRLF + "is too large for the editor.", "HMG Code Editor" )
         RETURN 0
      ENDIF
      cBytes := hb_MemoRead( cFile )
      IF Chr( 0 ) $ cBytes .AND. ! hb_LeftEq( cBytes, Chr( 255 ) + Chr( 254 ) )
         MsgStop( cFile + CRLF + "is not a text file.", "HMG Code Editor" )
         RETURN 0
      ENDIF
      hb_FGetDateTime( cFile, @tTime )
   ENDIF
   hView := IDEED_ADDDOC( s_hHost, hb_FNameNameExt( cFile ) )
   IDEED_SETLANG( hView, Lower( hb_FNameExt( cFile ) ) $ "|.c|.h|.cpp|.hpp|.cc|" )
   aInfo := IDEED_SETBYTES( hView, cBytes, IDE_EdDefaultEnc() )
   IF ! HB_ISARRAY( aInfo )
      IDEED_CLOSEDOC( hView )
      MsgStop( cFile + CRLF + "is not a text file.", "HMG Code Editor" )
      RETURN 0
   ENDIF
   AAdd( s_aDocs, { hView, cFile, aInfo[ 1 ], aInfo[ 2 ], aInfo[ 3 ], tTime } )
RETURN hView

STATIC FUNCTION IDE_EdDocIndex( hView )
RETURN AScan( s_aDocs, {| a | a[ D_VIEW ] == hView } )

STATIC FUNCTION IDE_EdCurView()
RETURN iif( Empty( s_hHost ), 0, IDEED_CURRENT( s_hHost ) )

STATIC FUNCTION IDE_EdCur()
RETURN IDE_EdDocIndex( IDE_EdCurView() )

STATIC PROCEDURE IDE_EdCaption( n )
   IF n > 0
      IDEED_SETCAPTION( s_aDocs[ n ][ D_VIEW ], hb_FNameNameExt( s_aDocs[ n ][ D_FILE ] ) + ;
                        iif( IDEED_MODIFIED( s_aDocs[ n ][ D_VIEW ] ), " *", "" ) )
   ENDIF
RETURN

STATIC PROCEDURE IDE_EdStatus()
   LOCAL n := IDE_EdCur(), a
   IF ! IsWindowDefined( IDE_Ed )
      RETURN
   ENDIF
   IF n == 0
      IDE_Ed.Title := "HMG Code Editor"
      IDE_Ed.StatusBar.Item( 1 ) := ""
      IDE_Ed.StatusBar.Item( 2 ) := ""
      IDE_Ed.StatusBar.Item( 3 ) := ""
      IDE_Ed.StatusBar.Item( 4 ) := ""
      RETURN
   ENDIF
   a := IDEED_CARET( s_aDocs[ n ][ D_VIEW ] )
   IDE_Ed.Title := "HMG Code Editor - " + hb_FNameNameExt( s_aDocs[ n ][ D_FILE ] )
   IDE_Ed.StatusBar.Item( 1 ) := s_aDocs[ n ][ D_FILE ]
   IDE_Ed.StatusBar.Item( 2 ) := "Ln " + hb_ntos( a[ 1 ] ) + ", Col " + hb_ntos( a[ 2 ] ) + ;
                                 iif( a[ 4 ] != 0, "  (" + hb_ntos( Abs( a[ 4 ] ) ) + " sel)", "" )
   IDE_Ed.StatusBar.Item( 3 ) := { "UTF-8", "ANSI", "UTF-16 LE" }[ s_aDocs[ n ][ D_ENC ] ] + ;
                                 iif( s_aDocs[ n ][ D_BOM ] .AND. s_aDocs[ n ][ D_ENC ] == ENC_UTF8, " BOM", "" )
   IDE_Ed.StatusBar.Item( 4 ) := iif( s_aDocs[ n ][ D_CRLF ], "CRLF", "LF" )
RETURN

/* events from ide_editw.c */
FUNCTION IDE_ED_EVENT( hHost, nEvent, hView, nArg )
   LOCAL n
   IF hHost != s_hHost .OR. Empty( s_hHost )
      RETURN .F.
   ENDIF
   SWITCH nEvent
   CASE 1                       // tab changed
   CASE 3                       // caret moved
      IDE_EdStatus()
      EXIT
   CASE 2                       // modified flag changed
      IDE_EdCaption( IDE_EdDocIndex( hView ) )
      EXIT
   CASE 4                       // a key the IDE handles
      RETURN IDE_EdKey( nArg )
   CASE 5                       // middle click on a tab
      IF ( n := IDE_EdDocIndex( hView ) ) > 0
         IDE_EdCloseDoc( hView )
      ENDIF
      EXIT
   ENDSWITCH
RETURN .F.

STATIC FUNCTION IDE_EdKey( nArg )
   LOCAL nKey := hb_bitAnd( nArg, 0xFFFF )
   LOCAL lCtrl := hb_bitAnd( nArg, K_CTRL ) != 0, lShift := hb_bitAnd( nArg, K_SHIFT ) != 0
   IF lCtrl
      SWITCH nKey
      CASE Asc( "S" )
         iif( lShift, IDE_EdSaveAll(), IDE_EdSave( IDE_EdCur() ) )
         RETURN .T.
      CASE Asc( "O" )
         IDE_EdOpenDialog()
         RETURN .T.
      CASE Asc( "W" )
      CASE VK_F4
         IDE_EdCloseDoc( IDE_EdCurView() )
         RETURN .T.
      CASE Asc( "F" )
         IDE_EdFindWindow( .F. )
         RETURN .T.
      CASE Asc( "H" )
         IDE_EdFindWindow( .T. )
         RETURN .T.
      CASE Asc( "G" )
         IDE_EdGoto()
         RETURN .T.
      CASE Asc( "Q" )
         IDE_EdCmd( CMD_COMMENT )
         RETURN .T.
      CASE Asc( "Z" )         // Ctrl+Shift+Z
         IDE_EdCmd( CMD_REDO )
         RETURN .T.
      CASE VK_TAB
         IDE_EdNextTab( iif( lShift, -1, 1 ) )
         RETURN .T.
      ENDSWITCH
      RETURN .F.
   ENDIF
   SWITCH nKey
   CASE VK_F3
      IDE_EdFindNext( lShift )
      RETURN .T.
   CASE VK_F5
      IDE_EdBuildRun()
      RETURN .T.
   CASE VK_ESCAPE
      IF IsWindowDefined( IDE_EdFind )
         IDE_EdFind.Release
      ENDIF
      RETURN .T.
   ENDSWITCH
RETURN .F.

STATIC PROCEDURE IDE_EdNextTab( nStep )
   LOCAL a := IDEED_DOCS( s_hHost ), n
   IF Len( a ) > 1
      n := AScan( a, IDEED_CURRENT( s_hHost ) ) + nStep
      n := iif( n < 1, Len( a ), iif( n > Len( a ), 1, n ) )
      IDEED_SELECT( a[ n ] )
      IDE_EdStatus()
   ENDIF
RETURN

STATIC PROCEDURE IDE_EdCmd( nCmd )
   LOCAL hView := IDE_EdCurView()
   IF ! Empty( hView )
      IDEED_COMMAND( hView, nCmd )
      IDEED_FOCUS( hView )
   ENDIF
RETURN

/* ------------------------------------------------------------------ files */

STATIC PROCEDURE IDE_EdOpenDialog()
   LOCAL n := IDE_EdCur(), cFile
   cFile := GetFile( { { "Harbour and HMG files", "*.prg;*.ch;*.fmg;*.rc;*.hbp;*.hbc" }, { "All files", "*.*" } }, ;
                     "Open", iif( n > 0, hb_FNameDir( s_aDocs[ n ][ D_FILE ] ), hb_cwd() ), .F., .T. )
   IF ! Empty( cFile )
      IDE_EdOpen( cFile )
   ENDIF
RETURN

/* saves doc n; .F. if it could not be saved (or the user cancelled) */
STATIC FUNCTION IDE_EdSave( n )
   LOCAL d, cBytes, lLossy := .F., tTime := NIL, nAns
   IF n == 0
      RETURN .T.
   ENDIF
   d := s_aDocs[ n ]
   cBytes := IDEED_GETBYTES( d[ D_VIEW ], d[ D_ENC ], d[ D_BOM ], d[ D_CRLF ], @lLossy )
   IF lLossy
      s_lBusy := .T.
      nAns := IDEED_ASK( GetFormHandle( "IDE_Ed" ), hb_FNameNameExt( d[ D_FILE ] ) + " has characters that the ANSI code page " + ;
                         "cannot hold." + CRLF + CRLF + "Save it as UTF-8 instead?" + CRLF + ;
                         "(No: save as ANSI, those characters become '?')", "HMG Code Editor" )
      s_lBusy := .F.
      IF nAns == -1
         RETURN .F.
      ELSEIF nAns == 1
         d[ D_ENC ] := ENC_UTF8
         cBytes := IDEED_GETBYTES( d[ D_VIEW ], d[ D_ENC ], d[ D_BOM ], d[ D_CRLF ] )
      ENDIF
   ENDIF
   IF ! hb_MemoWrit( d[ D_FILE ], cBytes )
      MsgStop( "Could not save" + CRLF + d[ D_FILE ], "HMG Code Editor" )
      RETURN .F.
   ENDIF
   hb_FGetDateTime( d[ D_FILE ], @tTime )
   d[ D_TIME ] := tTime
   IDEED_MODIFIED( d[ D_VIEW ], .F. )
   IDE_EdCaption( n )
   IDE_EdStatus()
RETURN .T.

STATIC FUNCTION IDE_EdSaveAs( n )
   LOCAL cFile
   IF n == 0
      RETURN .F.
   ENDIF
   cFile := Putfile( { { "Harbour source (*.prg)", "*.prg" }, { "Header (*.ch)", "*.ch" }, { "All files (*.*)", "*.*" } }, ;
                     "Save As", hb_FNameDir( s_aDocs[ n ][ D_FILE ] ), .T., hb_FNameNameExt( s_aDocs[ n ][ D_FILE ] ) )
   IF Empty( cFile )
      RETURN .F.
   ENDIF
   s_aDocs[ n ][ D_FILE ] := IDE_EdFullPath( cFile )
RETURN IDE_EdSave( n )

/* saves every changed file; the IDE calls it before a build */
FUNCTION IDE_EdSaveAll()
   LOCAL n, lOk := .T.
   FOR n := 1 TO Len( s_aDocs )
      IF IDEED_MODIFIED( s_aDocs[ n ][ D_VIEW ] )
         lOk := IDE_EdSave( n ) .AND. lOk
      ENDIF
   NEXT
RETURN lOk

STATIC PROCEDURE IDE_EdReload( n, lAsk )
   LOCAL d, cBytes, aInfo, aCaret, tTime := NIL
   IF n == 0 .OR. ! hb_FileExists( s_aDocs[ n ][ D_FILE ] )
      RETURN
   ENDIF
   d := s_aDocs[ n ]
   IF lAsk .AND. IDEED_MODIFIED( d[ D_VIEW ] )
      s_lBusy := .T.
      lAsk := MsgYesNo( "Reload " + hb_FNameNameExt( d[ D_FILE ] ) + " from disk and lose your changes?", "HMG Code Editor" )
      s_lBusy := .F.
      IF ! lAsk
         RETURN
      ENDIF
   ENDIF
   aCaret := IDEED_CARET( d[ D_VIEW ] )
   cBytes := hb_MemoRead( d[ D_FILE ] )
   aInfo := IDEED_SETBYTES( d[ D_VIEW ], cBytes, IDE_EdDefaultEnc() )
   IF HB_ISARRAY( aInfo )
      d[ D_ENC ] := aInfo[ 1 ]
      d[ D_BOM ] := aInfo[ 2 ]
      d[ D_CRLF ] := aInfo[ 3 ]
   ENDIF
   hb_FGetDateTime( d[ D_FILE ], @tTime )
   d[ D_TIME ] := tTime
   IDEED_GOTO( d[ D_VIEW ], aCaret[ 1 ], aCaret[ 2 ] )
   IDE_EdCaption( n )
   IDE_EdStatus()
RETURN

/* the editor got the focus: files changed by another program */
STATIC PROCEDURE IDE_EdCheckDisk()
   LOCAL n, tTime, d
   IF s_lBusy
      RETURN
   ENDIF
   s_lBusy := .T.
   FOR n := 1 TO Len( s_aDocs )
      d := s_aDocs[ n ]
      tTime := NIL
      IF d[ D_TIME ] != NIL .AND. hb_FGetDateTime( d[ D_FILE ], @tTime ) .AND. tTime != d[ D_TIME ]
         d[ D_TIME ] := tTime
         IF ! IDEED_MODIFIED( d[ D_VIEW ] )
            IDE_EdReload( n, .F. )
         ELSEIF MsgYesNo( hb_FNameNameExt( d[ D_FILE ] ) + " was changed by another program." + CRLF + ;
                          "Reload it and lose your changes?", "HMG Code Editor" )
            IDE_EdReload( n, .F. )
         ENDIF
      ENDIF
   NEXT
   s_lBusy := .F.
RETURN

/* asks about unsaved changes; .F. = keep the file open */
STATIC FUNCTION IDE_EdAskSave( n )
   LOCAL nAns
   IF n == 0 .OR. ! IDEED_MODIFIED( s_aDocs[ n ][ D_VIEW ] )
      RETURN .T.
   ENDIF
   IDEED_SELECT( s_aDocs[ n ][ D_VIEW ] )
   s_lBusy := .T.
   nAns := IDEED_ASK( GetFormHandle( "IDE_Ed" ), "Save the changes to " + hb_FNameNameExt( s_aDocs[ n ][ D_FILE ] ) + "?", "HMG Code Editor" )
   s_lBusy := .F.
   IF nAns == -1
      RETURN .F.
   ENDIF
RETURN nAns == 0 .OR. IDE_EdSave( n )

STATIC PROCEDURE IDE_EdCloseDoc( hView )
   LOCAL n := IDE_EdDocIndex( hView )
   IF n > 0 .AND. IDE_EdAskSave( n )
      IDEED_CLOSEDOC( hView )
      hb_ADel( s_aDocs, n, .T. )
      IDE_EdStatus()
   ENDIF
RETURN

STATIC FUNCTION IDE_EdCanClose()
   LOCAL n
   FOR n := 1 TO Len( s_aDocs )
      IF ! IDE_EdAskSave( n )
         RETURN .F.
      ENDIF
   NEXT
RETURN .T.

STATIC PROCEDURE IDE_EdReleased()
   s_hHost := 0
   s_aDocs := {}
   IF IsWindowDefined( IDE_EdFind )
      IDE_EdFind.Release
   ENDIF
RETURN

STATIC PROCEDURE IDE_EdExternal( n )
   IF n > 0 .AND. IDE_EdAskSave( n )
      IDE_OpenAtLine( s_aDocs[ n ][ D_FILE ], IDEED_CARET( s_aDocs[ n ][ D_VIEW ] )[ 1 ], .T. )
   ENDIF
RETURN

/* Build > Save All, Build and Run (F5) */
STATIC PROCEDURE IDE_EdBuildRun()
   IF IDE_EdSaveAll()
      RunApplication()
   ENDIF
RETURN

/* ------------------------------------------------------------------ search */

STATIC PROCEDURE IDE_EdGoto()
   LOCAL hView := IDE_EdCurView(), a, c
   IF Empty( hView )
      RETURN
   ENDIF
   a := IDEED_CARET( hView )
   s_lBusy := .T.
   c := InputBox( "Line number (1 - " + hb_ntos( a[ 3 ] ) + "):", "Go to Line", hb_ntos( a[ 1 ] ) )
   s_lBusy := .F.
   IF Val( c ) > 0
      IDEED_GOTO( hView, Val( c ) )
   ENDIF
   IDEED_FOCUS( hView )
RETURN

STATIC PROCEDURE IDE_EdFindWindow( lReplace )
   LOCAL hView := IDE_EdCurView(), cSel
   IF Empty( hView )
      RETURN
   ENDIF
   cSel := IDEED_SELTEXT( hView )
   IF ! Empty( cSel ) .AND. ! Chr( 13 ) $ cSel .AND. Len( cSel ) < 200
      s_cFind := cSel
   ENDIF
   IF IsWindowDefined( IDE_EdFind )
      IDE_EdFind.Txt_What.Value := s_cFind
      IDE_EdFind.Title := iif( lReplace, "Replace", "Find" )
      IDE_EdFind.SetFocus
      IDE_EdFind.Txt_What.SetFocus
      RETURN
   ENDIF

   DEFINE WINDOW IDE_EdFind AT IDE_Ed.Row + 90, IDE_Ed.Col + IDE_Ed.Width - 520 WIDTH 500 HEIGHT 205 ;
      TITLE iif( lReplace, "Replace", "Find" ) NOMINIMIZE NOMAXIMIZE NOSIZE ;
      ON RELEASE IDE_EdFindSave()

      ON KEY ESCAPE ACTION IDE_EdFind.Release
      ON KEY F3 ACTION IDE_EdFindNext( .F. )

      @ 14, 10 LABEL Lbl_What VALUE "Find what:" WIDTH 90 HEIGHT 20
      @ 10, 100 TEXTBOX Txt_What VALUE s_cFind WIDTH 250 HEIGHT 24 ON ENTER IDE_EdFindNext( .F. )
      @ 44, 10 LABEL Lbl_With VALUE "Replace with:" WIDTH 90 HEIGHT 20
      @ 40, 100 TEXTBOX Txt_With VALUE s_cRepl WIDTH 250 HEIGHT 24 ON ENTER IDE_EdReplace()
      @ 72, 100 CHECKBOX Chk_Case CAPTION "Match case" WIDTH 120 HEIGHT 22 VALUE s_lCase
      @ 72, 225 CHECKBOX Chk_Word CAPTION "Whole word" WIDTH 120 HEIGHT 22 VALUE s_lWord
      @ 110, 10 LABEL Lbl_Msg VALUE "" WIDTH 340 HEIGHT 40

      @ 8, 365 BUTTON Btn_Next CAPTION "Find Next" WIDTH 115 HEIGHT 26 ACTION IDE_EdFindNext( .F. )
      @ 38, 365 BUTTON Btn_Prev CAPTION "Find Previous" WIDTH 115 HEIGHT 26 ACTION IDE_EdFindNext( .T. )
      @ 68, 365 BUTTON Btn_Repl CAPTION "Replace" WIDTH 115 HEIGHT 26 ACTION IDE_EdReplace()
      @ 98, 365 BUTTON Btn_All CAPTION "Replace All" WIDTH 115 HEIGHT 26 ACTION IDE_EdReplaceAll()
      @ 128, 365 BUTTON Btn_Close CAPTION "Close" WIDTH 115 HEIGHT 26 ACTION IDE_EdFind.Release
   END WINDOW
   _ActivateWindow( { "IDE_EdFind" }, .F. )
   IDE_EdFind.Txt_What.SetFocus
RETURN

/* the find window's fields into the statics */
STATIC PROCEDURE IDE_EdFindSave()
   IF IsWindowDefined( IDE_EdFind )
      s_cFind := IDE_EdFind.Txt_What.Value
      s_cRepl := IDE_EdFind.Txt_With.Value
      s_lCase := IDE_EdFind.Chk_Case.Value
      s_lWord := IDE_EdFind.Chk_Word.Value
   ENDIF
RETURN

STATIC PROCEDURE IDE_EdFindMsg( c )
   IF IsWindowDefined( IDE_EdFind )
      IDE_EdFind.Lbl_Msg.Value := c
   ELSEIF IsWindowDefined( IDE_Ed )
      IDE_Ed.StatusBar.Item( 1 ) := c
   ENDIF
RETURN

STATIC PROCEDURE IDE_EdFindNext( lBack )
   LOCAL hView := IDE_EdCurView()
   IDE_EdFindSave()
   IF Empty( hView ) .OR. Empty( s_cFind )
      IF Empty( s_cFind ) .AND. ! IsWindowDefined( IDE_EdFind )
         IDE_EdFindWindow( .F. )
      ENDIF
      RETURN
   ENDIF
   IF IDEED_FIND( hView, s_cFind, s_lCase, s_lWord, lBack, .T. )
      IDE_EdFindMsg( "" )
   ELSE
      IDE_EdFindMsg( "Not found: " + s_cFind )
   ENDIF
RETURN

STATIC PROCEDURE IDE_EdReplace()
   LOCAL hView := IDE_EdCurView()
   IDE_EdFindSave()
   IF ! Empty( hView ) .AND. ! Empty( s_cFind )
      IDE_EdFindMsg( iif( IDEED_REPLACE( hView, s_cFind, s_cRepl, s_lCase, s_lWord ), "", "No more: " + s_cFind ) )
   ENDIF
RETURN

STATIC PROCEDURE IDE_EdReplaceAll()
   LOCAL hView := IDE_EdCurView(), n
   IDE_EdFindSave()
   IF ! Empty( hView ) .AND. ! Empty( s_cFind )
      n := IDEED_REPLACEALL( hView, s_cFind, s_cRepl, s_lCase, s_lWord )
      IDE_EdFindMsg( hb_ntos( n ) + " replaced (one Undo puts them back)" )
   ENDIF
RETURN

/* ------------------------------------------------------------------ self-test */

/* IDE.exe /edtest <out.txt> (tests/ide/run.ps1): the editor's file round trips, colours,
   undo, indent and search, written as "PASS name" / "FAIL name: why" lines */
PROCEDURE IDE_EdSelfTest( cOut )
   LOCAL aRes := {}, cDir, hView, c, cR, a, n, oErr, cText
   LOCAL aFiles := { ;
      { "utf8.prg",   "x := " + Chr( 34 ) + Chr( 195 ) + Chr( 169 ) + Chr( 34 ) + Chr( 13 ) + Chr( 10 ) + "y" + Chr( 13 ) + Chr( 10 ), ENC_UTF8, .F., .T. }, ;
      { "utf8bom.prg", Chr( 239 ) + Chr( 187 ) + Chr( 191 ) + "a" + Chr( 10 ) + "b", ENC_UTF8, .T., .F. }, ;
      { "ansi.prg",   "x := '" + Chr( 233 ) + "'" + Chr( 13 ) + Chr( 10 ), ENC_ANSI, .F., .T. }, ;
      { "utf16.prg",  Chr( 255 ) + Chr( 254 ) + "a" + Chr( 0 ) + Chr( 13 ) + Chr( 0 ) + Chr( 10 ) + Chr( 0 ) + "b" + Chr( 0 ), ENC_UTF16, .T., .T. }, ;
      { "ascii.prg",  "? 1" + Chr( 13 ) + Chr( 10 ) + Chr( 13 ) + Chr( 10 ), IDE_EdDefaultEnc(), .F., .T. }, ;
      { "rtf.prg",    "{\rtf1 not rich}" + Chr( 13 ) + Chr( 10 ), ENC_UTF8, .F., .T. } }

   BEGIN SEQUENCE WITH {| e | Break( e ) }
      cDir := hb_FNameDir( IDE_EdFullPath( cOut ) ) + "edtest" + hb_ps()
      hb_DirCreate( cDir )
      s_cTrace := cOut + ".log"
      hb_MemoWrit( s_cTrace, "" )
      TL( "show" )
      IDE_EdShow()
      TL( "shown" )

      // 1. files come back byte for byte, in their encoding and line endings
      FOR EACH a IN aFiles
         hb_MemoWrit( cDir + a[ 1 ], a[ 2 ] )
         TL( "open " + a[ 1 ] )
         IDE_EdOpen( cDir + a[ 1 ] )
         TL( "opened" )
         n := IDE_EdCur()
         c := IDEED_GETBYTES( s_aDocs[ n ][ D_VIEW ], s_aDocs[ n ][ D_ENC ], s_aDocs[ n ][ D_BOM ], s_aDocs[ n ][ D_CRLF ] )
         T( aRes, "load " + a[ 1 ], s_aDocs[ n ][ D_ENC ] == a[ 3 ] .AND. s_aDocs[ n ][ D_BOM ] == a[ 4 ] .AND. s_aDocs[ n ][ D_CRLF ] == a[ 5 ], ;
            "enc " + hb_ntos( s_aDocs[ n ][ D_ENC ] ) + " bom " + hb_ValToStr( s_aDocs[ n ][ D_BOM ] ) + " crlf " + hb_ValToStr( s_aDocs[ n ][ D_CRLF ] ) )
         T( aRes, "bytes " + a[ 1 ], c == a[ 2 ], hb_StrToHex( c ) + " <> " + hb_StrToHex( a[ 2 ] ) )
         T( aRes, "unmodified " + a[ 1 ], ! IDEED_MODIFIED( s_aDocs[ n ][ D_VIEW ] ) .AND. ! IDEED_COMMAND( s_aDocs[ n ][ D_VIEW ], CMD_CANUNDO ), "modified or undo after load" )
         IDEED_MODIFIED( s_aDocs[ n ][ D_VIEW ], .T. )
         IDE_EdSave( n )
         T( aRes, "save " + a[ 1 ], hb_MemoRead( cDir + a[ 1 ] ) == a[ 2 ], hb_StrToHex( hb_MemoRead( cDir + a[ 1 ] ) ) )
      NEXT
      T( aRes, "rtf stays text", hb_LeftEq( IDEED_GETTEXT( IDE_EdCurView() ), "{\rtf1 not rich}" ), IDEED_GETTEXT( IDE_EdCurView() ) )

      // 2. colours
      cText := "FUNCTION Main()" + CRLF + ;
               "   LOCAL x := " + Chr( 34 ) + "str" + Chr( 34 ) + " // note" + CRLF + ;
               "   /* block" + CRLF + ;
               "still */ DEFINE WINDOW Win_1" + CRLF + ;
               "#include " + Chr( 34 ) + "hmg.ch" + Chr( 34 ) + CRLF + ;
               "* old comment" + CRLF + ;
               "x := .T. + 12" + CRLF + ;
               "MsgInfo( AllTrim( x ) )" + CRLF + ;
               "#pragma BEGINDUMP" + CRLF + ;
               "int a = b && c;" + CRLF + ;
               "#pragma ENDDUMP" + CRLF + ;
               "? 1 && harbour comment" + CRLF
      hView := TestDoc( cDir + "colors.prg", cText )
      cR := StrTran( cText, CRLF, Chr( 13 ) )
      TC( aRes, hView, cR, "FUNCTION", 0, 1, .T., .F. )
      TC( aRes, hView, cR, "Win_1", 0, 0, .F., .F. )
      TC( aRes, hView, cR, Chr( 34 ) + "str", 0, 8, .F., .F. )
      TC( aRes, hView, cR, "// note", 0, 9, .F., .T. )
      TC( aRes, hView, cR, "still", 0, 9, .F., .T. )
      TC( aRes, hView, cR, "DEFINE", 0, 2, .T., .F. )
      TC( aRes, hView, cR, "#include", 0, 6, .F., .F. )
      TC( aRes, hView, cR, Chr( 34 ) + "hmg.ch", 0, 8, .F., .F. )
      TC( aRes, hView, cR, "* old", 0, 9, .F., .T. )
      TC( aRes, hView, cR, ".T.", 0, 7, .F., .F. )
      TC( aRes, hView, cR, "12", 0, 10, .F., .F. )
      TC( aRes, hView, cR, "MsgInfo", 0, 4, .F., .F. )
      TC( aRes, hView, cR, "AllTrim", 0, 5, .F., .F. )
      TC( aRes, hView, cR, "&& c;", 0, 0, .F., .F. )
      TC( aRes, hView, cR, "&& harbour", 0, 9, .F., .T. )
      T( aRes, "colouring adds no undo", ! IDEED_COMMAND( hView, CMD_CANUNDO ) .AND. ! IDEED_MODIFIED( hView ), "undo or modified after colouring" )

      // 3. typing and undo
      n := Len( cR )
      IDEED_SETSEL( hView, n, n )
      IDEED_TYPE( hView, "Z" )
      T( aRes, "type", IDEED_GETTEXT( hView ) == cText + "Z" .AND. IDEED_MODIFIED( hView ), IDEED_GETTEXT( hView ) )
      IDEED_HIGHLIGHT( hView )
      IDEED_COMMAND( hView, CMD_UNDO )
      T( aRes, "undo is one step", IDEED_GETTEXT( hView ) == cText .AND. ! IDEED_COMMAND( hView, CMD_CANUNDO ), IDEED_GETTEXT( hView ) )

      // 4. Enter keeps the indent, Tab goes to the next indent column
      hView := TestDoc( cDir + "indent.prg", "   IF x" )
      IDEED_SETSEL( hView, 7, 7 )
      IDEED_TYPE( hView, Chr( 13 ) + "y" )
      T( aRes, "auto-indent", IDEED_GETTEXT( hView ) == "   IF x" + CRLF + "   y", IDEED_GETTEXT( hView ) )
      hView := TestDoc( cDir + "tab.prg", "ab" )
      IDEED_SETSEL( hView, 2, 2 )
      IDEED_TYPE( hView, Chr( 9 ) + "c" )
      T( aRes, "tab", IDEED_GETTEXT( hView ) == "ab c", IDEED_GETTEXT( hView ) )
      IDEED_TYPE( hView, Chr( 9 ), K_SHIFT )
      T( aRes, "shift+tab", IDEED_GETTEXT( hView ) == "ab c", IDEED_GETTEXT( hView ) )

      // 5. whole lines: indent, outdent, comment
      cText := "a" + CRLF + "" + CRLF + "   b" + CRLF + "c"
      hView := TestDoc( cDir + "block.prg", cText )
      IDEED_SETSEL( hView, 0, -1 )
      IDEED_COMMAND( hView, CMD_INDENT )
      T( aRes, "indent lines", IDEED_GETTEXT( hView ) == "   a" + CRLF + "" + CRLF + "      b" + CRLF + "   c", IDEED_GETTEXT( hView ) )
      IDEED_COMMAND( hView, CMD_OUTDENT )
      T( aRes, "outdent lines", IDEED_GETTEXT( hView ) == cText, IDEED_GETTEXT( hView ) )
      IDEED_COMMAND( hView, CMD_COMMENT )
      T( aRes, "comment lines", IDEED_GETTEXT( hView ) == "// a" + CRLF + "" + CRLF + "//    b" + CRLF + "// c", IDEED_GETTEXT( hView ) )
      IDEED_COMMAND( hView, CMD_COMMENT )
      T( aRes, "uncomment lines", IDEED_GETTEXT( hView ) == cText, IDEED_GETTEXT( hView ) )
      IDEED_COMMAND( hView, CMD_UNDO )
      T( aRes, "block undo", IDEED_GETTEXT( hView ) == "// a" + CRLF + "" + CRLF + "//    b" + CRLF + "// c", IDEED_GETTEXT( hView ) )

      // 6. find, replace, replace all, go to line
      cText := "alpha beta Alpha gamma alpha_x alpha"
      hView := TestDoc( cDir + "find.prg", cText )
      IDEED_SETSEL( hView, 0, 0 )
      T( aRes, "find", IDEED_FIND( hView, "alpha", .T., .F., .F., .T. ) .AND. IDEED_CARET( hView )[ 5 ] == 5, hb_ntos( IDEED_CARET( hView )[ 5 ] ) )
      T( aRes, "find next (case)", IDEED_FIND( hView, "alpha", .T., .F., .F., .T. ) .AND. IDEED_CARET( hView )[ 5 ] == 28, hb_ntos( IDEED_CARET( hView )[ 5 ] ) )
      T( aRes, "find whole word", IDEED_FIND( hView, "alpha", .T., .T., .F., .T. ) .AND. IDEED_CARET( hView )[ 5 ] == 36, hb_ntos( IDEED_CARET( hView )[ 5 ] ) )
      T( aRes, "find previous", IDEED_FIND( hView, "beta", .F., .F., .T., .T. ) .AND. IDEED_SELTEXT( hView ) == "beta", IDEED_SELTEXT( hView ) )
      T( aRes, "not found", ! IDEED_FIND( hView, "delta", .F., .F., .F., .T. ), "found delta" )
      IDEED_SETSEL( hView, 0, 0 )
      IDEED_FIND( hView, "beta", .F., .F., .F., .T. )
      IDEED_REPLACE( hView, "beta", "B", .F., .F. )
      T( aRes, "replace", IDEED_GETTEXT( hView ) == "alpha B Alpha gamma alpha_x alpha", IDEED_GETTEXT( hView ) )
      n := IDEED_REPLACEALL( hView, "alpha", "x", .F., .T. )
      T( aRes, "replace all", n == 3 .AND. IDEED_GETTEXT( hView ) == "x B x gamma alpha_x x", hb_ntos( n ) + " " + IDEED_GETTEXT( hView ) )
      IDEED_COMMAND( hView, CMD_UNDO )
      T( aRes, "replace all is one undo", IDEED_GETTEXT( hView ) == "alpha B Alpha gamma alpha_x alpha", IDEED_GETTEXT( hView ) )
      c := ""
      FOR n := 1 TO 300
         c += "line " + hb_ntos( n ) + CRLF
      NEXT
      hView := TestDoc( cDir + "goto.prg", c )
      IDEED_GOTO( hView, 250, 3 )
      a := IDEED_CARET( hView )
      T( aRes, "go to line", a[ 1 ] == 250 .AND. a[ 2 ] == 3 .AND. a[ 3 ] >= 300, hb_ValToExp( a ) )

      // 7. external choice still works through IDE_EditFile (not run: it starts a program)
      T( aRes, "setting", HB_ISLOGICAL( IDE_UseBuiltinEditor() ), "no setting" )
   RECOVER USING oErr
      AAdd( aRes, "FAIL runtime error: " + iif( HB_ISOBJECT( oErr ), oErr:Description + " " + hb_ValToStr( oErr:Operation ) + " " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")", hb_ValToStr( oErr ) ) )
   END SEQUENCE

   n := 0
   AEval( aRes, {| x | iif( hb_LeftEq( x, "PASS" ), n++, NIL ) } )
   c := ""
   AEval( aRes, {| x | c += x + CRLF } )
   c += "edtest: PASS=" + hb_ntos( n ) + " FAIL=" + hb_ntos( Len( aRes ) - n ) + CRLF
   hb_MemoWrit( cOut, c )
   ExitProcess( 0 )
RETURN

STATIC FUNCTION TestDoc( cFile, cText )
   hb_MemoWrit( cFile, cText )
   IDE_EdOpen( cFile )
   IDEED_HIGHLIGHT( IDE_EdCurView() )
RETURN IDE_EdCurView()

STATIC PROCEDURE TL( c )
   IF ! Empty( s_cTrace )
      hb_MemoWrit( s_cTrace, hb_MemoRead( s_cTrace ) + c + Chr( 13 ) + Chr( 10 ) )
   ENDIF
RETURN

STATIC PROCEDURE T( aRes, cName, lOk, cWhy )
   TL( iif( lOk, "PASS ", "FAIL " ) + cName )
   AAdd( aRes, iif( lOk, "PASS " + cName, "FAIL " + cName + ": " + hb_ValToStr( cWhy ) ) )
RETURN

/* the colour (and bold, italic) of the first character of cWhat */
STATIC PROCEDURE TC( aRes, hView, cR, cWhat, nFrom, nStyle, lBold, lItalic )
   LOCAL nCp := hb_At( cWhat, cR, nFrom + 1 ) - 1, a
   a := IDEED_COLORAT( hView, nCp )
   T( aRes, "colour " + cWhat, a[ 1 ] == IDEED_STYLECOLOR( s_hHost, nStyle ) .AND. a[ 2 ] == lBold .AND. a[ 3 ] == lItalic, ;
      "colour " + hb_NumToHex( a[ 1 ] ) + " want " + hb_NumToHex( IDEED_STYLECOLOR( s_hHost, nStyle ) ) + " bold " + hb_ValToStr( a[ 2 ] ) + " italic " + hb_ValToStr( a[ 3 ] ) )
RETURN
