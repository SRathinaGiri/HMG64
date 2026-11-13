/*----------------------------------------------------------------------------
 HMG5 IDE - project index: the forms and controls a project defines in code
 (and in .fmg files), where they are used, and the references that point to
 nothing (PHASE4-DESIGN.md section 6, I12).

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 Pure Harbour (no GUI): used by the IDE's "Forms and Controls" window and by
 tools\hmgindex (console report). It reads source text; it never runs it.

 What it understands:
   DEFINE WINDOW <name> ... END WINDOW            (nesting: panels, child windows)
   DEFINE <control> <name> [OF|PARENT <form>] ... END <control>
   @ <row>, <col> <control> <name> [OF|PARENT <form>] ...
   BUTTON <name> inside DEFINE TOOLBAR, ITEM ... NAME <name> in menus
   LOAD WINDOW <name> [AS <alias>]                (reads <name>.fmg)
   custom controls declared in the project's own #xcommand / #command
 References it checks:
   <form>.<control>.<property>, <form>.<property>
   GetProperty / SetProperty / DoMethod( "<form>", "<control>", ... )
   IsControlDefined / _IsControlDefined / GetControlHandle( "<control>", "<form>" )
   IsWindowDefined / _IsWindowDefined / GetFormHandle( <form> )
   ACTIVATE / RELEASE / CENTER / SHOW / HIDE / MAXIMIZE / MINIMIZE / RESTORE WINDOW <form> [, ...]
 Names built at run time (&cName, variables) are skipped, not reported.
---------------------------------------------------------------------------*/

#define TK_TYPE  1
#define TK_TEXT  2

// controls of the @ <r>,<c> <word> syntax and of DEFINE <word> ... END <word> (HMG5 INCLUDE\*.ch)
STATIC s_cControls := ",ACTIVEX,ANIMATEBOX,BROWSE,BUTTON,CHECKBOX,CHECKBUTTON,COMBOBOX,COMBOSEARCHBOX," + ;
   "DATEPICKER,EDITBOX,FRAME,GRID,HYPERLINK,IMAGE,IPADDRESS,LABEL,LISTBOX,MONTHCALENDAR,PLAYER," + ;
   "PROGRESSBAR,RADIOGROUP,RICHEDITBOX,SLIDER,SPINNER,TEXTBOX,TIMEPICKER,WEBVIEW,TAB,TREE,TIMER,TOOLBAR,"

// DEFINE <word> that is not a control with a name
STATIC s_cNotControls := ",WINDOW,MAIN,CONTEXT,NOTIFY,POPUP,PAGE,MENU,STATUSBAR,SPLITBOX,NODE,REPORT,DROPDOWN," + ;
   "LAYOUT,HEADER,DETAIL,FOOTER,SUMMARY,GROUP,GROUPHEADER,GROUPFOOTER,DATA,LINE,PICTURE,RECTANGLE,TEXT,INI," + ;
   "CONTROL,CLASS,"

// first word of a dot chain that is not a form
STATIC s_cNotForms := ",THIS,THISWINDOW,APPLICATION,SYSTEM,SELF,SUPER,AND,OR,NOT,T,F,Y,N,"

// a form has these without a DEFINE
STATIC s_cBuiltIn := ",STATUSBAR,"

FUNCTION HMGIdx_New( cRoot )
   LOCAL h := { => }
   hb_HCaseMatch( h, .F. )
   h[ "root" ]     := hb_DirSepAdd( cRoot )
   h[ "files" ]    := {}
   h[ "forms" ]    := hb_HSetCaseMatch( { => }, .F. )
   h[ "refs" ]     := {}
   h[ "problems" ] := {}
   h[ "custom" ]   := ","          // custom control words found in the project's headers
RETURN h

/* HMGIdx_Project( cHbpOrFolder ) -> hIndex
   An .hbp: its .prg files (and the .ch files they include from the project folder).
   A folder: every .prg in it. */
FUNCTION HMGIdx_Project( cTarget )
   LOCAL h, aFiles := {}, cLine, cDir, aDir, f

   IF hb_DirExists( cTarget )
      h := HMGIdx_New( cTarget )
      FOR EACH aDir IN Directory( hb_DirSepAdd( cTarget ) + "*.prg" )
         AAdd( aFiles, hb_DirSepAdd( cTarget ) + aDir[ 1 ] )
      NEXT
   ELSE
      cDir := hb_FNameDir( cTarget )
      IF Empty( cDir )
         cDir := hb_DirSepAdd( hb_cwd() )
      ENDIF
      h := HMGIdx_New( cDir )
      FOR EACH cLine IN hb_ATokens( StrTran( hb_MemoRead( cTarget ), Chr( 13 ) ), Chr( 10 ) )
         cLine := AllTrim( cLine )
         IF ! Empty( cLine ) .AND. ! Left( cLine, 1 ) $ "-#" .AND. Lower( hb_FNameExt( cLine ) ) == ".prg"
            AAdd( aFiles, iif( hb_FNameDir( cLine ) == "" .OR. ! ( ":" $ cLine ), cDir + cLine, cLine ) )
         ENDIF
      NEXT
   ENDIF

   // custom control words first (any file may use them)
   FOR EACH f IN aFiles
      HMGIdx_CustomFrom( h, f )
   NEXT
   FOR EACH f IN aFiles
      HMGIdx_File( h, f )
   NEXT
   HMGIdx_Check( h )
RETURN h

/* the project's own #xcommand / #command: "@ <r>, <c> WORD" and "DEFINE WORD" are controls;
   also the .ch files the source includes from the project folder */
STATIC PROCEDURE HMGIdx_CustomFrom( h, cFile )
   LOCAL cLine, cInc, aW, cU
   IF ! hb_FileExists( cFile )
      RETURN
   ENDIF
   FOR EACH cLine IN hb_ATokens( StrTran( hb_MemoRead( cFile ), Chr( 13 ) ), Chr( 10 ) )
      cLine := AllTrim( cLine )
      cU := Upper( cLine )
      IF hb_LeftEq( cU, "#INCLUDE" )
         cInc := AllTrim( StrTran( StrTran( StrTran( SubStr( cLine, 9 ), '"' ), "<" ), ">" ) )
         IF hb_FileExists( h[ "root" ] + cInc ) .AND. ! ( "," + Upper( cInc ) + "," ) $ h[ "custom" ]
            h[ "custom" ] += Upper( cInc ) + ","        // read once
            HMGIdx_CustomFrom( h, h[ "root" ] + cInc )
         ENDIF
      ELSEIF hb_LeftEq( cU, "#XCOMMAND" ) .OR. hb_LeftEq( cU, "#COMMAND" )
         aW := hb_ATokens( AllTrim( SubStr( cLine, At( " ", cLine ) + 1 ) ), " " )
         IF Len( aW ) >= 2 .AND. Upper( aW[ 1 ] ) == "DEFINE" .AND. hb_regexLike( "[A-Za-z_][A-Za-z0-9_]*", aW[ 2 ] )
            HMGIdx_AddCustom( h, aW[ 2 ] )
         ELSEIF Len( aW ) >= 1 .AND. Left( aW[ 1 ], 1 ) == "@"
            cU := hb_regexAtX( "@\s*<[^>]+>\s*,\s*<[^>]+>\s+([A-Za-z_][A-Za-z0-9_]*)", cLine )
            IF HB_ISARRAY( cU ) .AND. Len( cU ) >= 2
               HMGIdx_AddCustom( h, cU[ 2 ][ 1 ] )
            ENDIF
         ENDIF
      ENDIF
   NEXT
RETURN

STATIC PROCEDURE HMGIdx_AddCustom( h, cWord )
   cWord := Upper( cWord )
   IF ! ( "," + cWord + "," ) $ s_cNotControls .AND. ! ( "," + cWord + "," ) $ h[ "custom" ]
      h[ "custom" ] += cWord + ","
   ENDIF
RETURN

STATIC FUNCTION IsControlWord( h, cWord )
   cWord := "," + Upper( cWord ) + ","
RETURN cWord $ s_cControls .OR. cWord $ h[ "custom" ]

/* one source file (.prg, or .fmg via LOAD WINDOW: cFormName names its TEMPLATE window);
   cText: the file's text when it is not the one on disk (the IDE's editor) */
FUNCTION HMGIdx_File( h, cFile, cFormName, cText )
   LOCAL aLines, aL, aT, nLine, cW, cW2, aStack := {}, xCtl := NIL, cBlock := NIL, n, cName, cForm
   LOCAL cTab := "", cPage := "", nPage := 0, lToolbar := .F., lMenu := .F.

   IF ! HB_ISCHAR( cText ) .AND. ! hb_FileExists( cFile )
      AAdd( h[ "problems" ], { cFile, 0, "W", "file not found" } )
      RETURN NIL
   ENDIF
   AAdd( h[ "files" ], cFile )
   aLines := HMGIdx_Logical( iif( HB_ISCHAR( cText ), cText, hb_MemoRead( cFile ) ) )

   FOR EACH aL IN aLines
      nLine := aL[ 1 ]
      aT    := aL[ 2 ]
      IF Empty( aT ) .OR. aT[ 1 ][ TK_TEXT ] == "#"
         LOOP
      ENDIF
      cW  := Upper( TokI( aT, 1 ) )
      cW2 := Upper( TokI( aT, 2 ) )

      DO CASE
      CASE cW == "DEFINE" .AND. cW2 == "WINDOW"
         cName := TokI( aT, 3 )
         IF Upper( cName ) == "TEMPLATE" .AND. ! Empty( cFormName )
            cName := cFormName
         ENDIF
         IF ! Empty( cName )
            HMGIdx_AddForm( h, cName, cFile, nLine, HMGIdx_WindowKind( aT ), ATail( aStack ) )
         ENDIF
         AAdd( aStack, cName )               // "" for &cName: its controls are skipped
         xCtl := NIL ; cBlock := NIL ; cTab := "" ; cPage := ""

      CASE cW == "END" .AND. cW2 == "WINDOW"
         IF ! Empty( aStack )
            ASize( aStack, Len( aStack ) - 1 )
         ENDIF
         xCtl := NIL ; cBlock := NIL

      CASE cW == "LOAD" .AND. cW2 == "WINDOW"
         cName := TokI( aT, 3 )
         n := TokPos( aT, "AS" )
         cForm := iif( n > 0, TokI( aT, n + 1 ), cName )
         IF ! Empty( cName ) .AND. ! Empty( cForm ) .AND. ! hb_HHasKey( h[ "forms" ], cForm )
            HMGIdx_File( h, HMGIdx_FindFmg( h, cName ), cForm )
         ENDIF
         HMGIdx_AddRef( h, cFile, nLine, cForm, NIL, "LOAD WINDOW" )

      CASE cW == "DEFINE" .AND. cW2 == "TOOLBAR"
         lToolbar := .T.
         HMGIdx_DefineControl( h, aT, 2, cFile, nLine, aStack, @xCtl, @cBlock, cTab, cPage )

      CASE cW == "DEFINE" .AND. cW2 $ "MAIN|CONTEXT|NOTIFY|POPUP|DROPDOWN"
         lMenu := .T.

      CASE cW == "DEFINE" .AND. cW2 == "PAGE" .OR. ( cW == "PAGE" .AND. ! Empty( cTab ) )
         nPage++
         cPage := iif( Len( aT ) >= iif( cW == "PAGE", 2, 3 ) .AND. aT[ iif( cW == "PAGE", 2, 3 ) ][ TK_TYPE ] == "S", ;
                       aT[ iif( cW == "PAGE", 2, 3 ) ][ TK_TEXT ], "page " + hb_ntos( nPage ) )

      CASE cW == "DEFINE" .AND. Len( aT ) >= 3 .AND. aT[ 3 ][ TK_TYPE ] $ "IM" .AND. ;
           ! ( "," + cW2 + "," ) $ s_cNotControls .AND. ( IsControlWord( h, cW2 ) .OR. ! Empty( ATail( aStack ) ) )
         HMGIdx_DefineControl( h, aT, 2, cFile, nLine, aStack, @xCtl, @cBlock, cTab, cPage )
         IF cW2 == "TAB" .AND. xCtl != NIL
            cTab := xCtl[ 1 ] ; nPage := 0 ; cPage := ""
         ENDIF

      CASE cW == "END"
         IF cW2 == "TAB"
            cTab := "" ; cPage := ""
         ELSEIF cW2 == "TOOLBAR"
            lToolbar := .F.
         ELSEIF cW2 == "MENU" .OR. cW2 == "POPUP"
            lMenu := ( cW2 == "POPUP" )   // END POPUP: still inside the menu
         ENDIF
         IF cBlock != NIL .AND. cW2 == cBlock
            xCtl := NIL ; cBlock := NIL
         ENDIF

      CASE cW == "@" .OR. ( Len( aT ) > 0 .AND. aT[ 1 ][ TK_TEXT ] == "@" )
         n := HMGIdx_AtWord( h, aT )
         IF n > 0
            HMGIdx_DefineControl( h, aT, n, cFile, nLine, aStack, NIL, NIL, cTab, cPage )
         ENDIF

      CASE lToolbar .AND. cW == "BUTTON" .AND. Len( aT ) >= 2 .AND. aT[ 2 ][ TK_TYPE ] == "I"
         HMGIdx_AddControl( h, ATail( aStack ), aT[ 2 ][ TK_TEXT ], "TOOLBUTTON", cFile, nLine, "" )

      CASE lMenu .AND. ( cW == "ITEM" .OR. cW == "MENUITEM" ) .AND. ( n := TokPos( aT, "NAME" ) ) > 0 .AND. ;
           Len( aT ) > n .AND. aT[ n + 1 ][ TK_TYPE ] == "I"
         HMGIdx_AddControl( h, ATail( aStack ), aT[ n + 1 ][ TK_TEXT ], "MENUITEM", cFile, nLine, "" )

      CASE xCtl != NIL .AND. ( cW == "PARENT" .OR. cW == "OF" ) .AND. Len( aT ) >= 2 .AND. aT[ 2 ][ TK_TYPE ] == "I"
         // alternate syntax: PARENT <form> inside DEFINE <control> ... END <control>
         HMGIdx_MoveControl( h, xCtl, aT[ 2 ][ TK_TEXT ] )
      ENDCASE

      HMGIdx_Refs( h, aT, cFile, nLine )
   NEXT
RETURN NIL

STATIC FUNCTION HMGIdx_FindFmg( h, cName )
   LOCAL cExt
   FOR EACH cExt IN { ".fmg", ".FMG", ".Fmg" }
      IF hb_FileExists( h[ "root" ] + cName + cExt )
         RETURN h[ "root" ] + cName + cExt
      ENDIF
   NEXT
RETURN h[ "root" ] + cName + ".fmg"

STATIC FUNCTION HMGIdx_WindowKind( aT )
   LOCAL c
   FOR EACH c IN { "MAIN", "CHILD", "MODAL", "SPLITCHILD", "PANEL", "INTERNAL" }
      IF TokPos( aT, c ) > 0
         RETURN c
      ENDIF
   NEXT
RETURN "STANDARD"

/* n: position of the control word (DEFINE <word> <name>, @ r, c <word> <name>) */
STATIC PROCEDURE HMGIdx_DefineControl( h, aT, n, cFile, nLine, aStack, xCtl, cBlock, cTab, cPage )
   LOCAL cType := Upper( aT[ n ][ TK_TEXT ] ), cName, cForm, k
   IF Len( aT ) < n + 1 .OR. aT[ n + 1 ][ TK_TYPE ] != "I"
      xCtl := NIL
      RETURN                                   // &cName or no name
   ENDIF
   cName := aT[ n + 1 ][ TK_TEXT ]
   cForm := ATail( aStack )
   IF ( k := TokPos( aT, "OF", n + 2 ) ) > 0 .OR. ( k := TokPos( aT, "PARENT", n + 2 ) ) > 0
      cForm := iif( Len( aT ) > k .AND. aT[ k + 1 ][ TK_TYPE ] == "I", aT[ k + 1 ][ TK_TEXT ], "" )
   ENDIF
   IF Empty( cForm )
      xCtl := NIL
      RETURN                                   // outside a window, or a run-time parent
   ENDIF
   xCtl := HMGIdx_AddControl( h, cForm, cName, cType, cFile, nLine, ;
                              iif( Empty( cTab ), "", cTab + iif( Empty( cPage ), "", " / " + cPage ) ) )
   cBlock := cType
RETURN

FUNCTION HMGIdx_AddForm( h, cName, cFile, nLine, cKind, cParent )
   LOCAL hF
   IF hb_HHasKey( h[ "forms" ], cName )
      hF := h[ "forms" ][ cName ]
      IF ! Empty( hF[ "file" ] )
         // a second DEFINE WINDOW of the same name: an alternative layout (only one exists at a
         // time), e.g. "login" and "change password". Its controls join the form; a note, not a problem.
         IF cFile != NIL
            hF[ "defno" ]++
            AAdd( hF[ "also" ], hb_FNameNameExt( cFile ) + ":" + hb_ntos( nLine ) )
         ENDIF
         RETURN hF
      ENDIF
   ELSE
      hF := { => }
      hb_HCaseMatch( hF, .F. )
      hF[ "controls" ] := hb_HSetCaseMatch( { => }, .F. )
      hF[ "also" ]  := {}
      hF[ "defno" ] := 1
      h[ "forms" ][ cName ] := hF
   ENDIF
   hF[ "name" ]   := cName
   hF[ "file" ]   := cFile
   hF[ "line" ]   := nLine
   hF[ "kind" ]   := cKind
   hF[ "parent" ] := hb_defaultValue( cParent, "" )
RETURN hF

/* -> { cName, cForm } of the new control */
FUNCTION HMGIdx_AddControl( h, cForm, cName, cType, cFile, nLine, cWhere )
   LOCAL hF, hC
   IF Empty( cForm ) .OR. Empty( cName )
      RETURN NIL
   ENDIF
   IF ! hb_HHasKey( h[ "forms" ], cForm )      // OF <form> defined later or elsewhere
      hF := HMGIdx_AddForm( h, cForm, "", 0, "", "" )
   ELSE
      hF := h[ "forms" ][ cForm ]
   ENDIF
   IF hb_HHasKey( hF[ "controls" ], cName )
      hC := hF[ "controls" ][ cName ]
      IF hC[ "defno" ] == hF[ "defno" ]       // twice in the same DEFINE WINDOW: HMG stops with an error
         AAdd( h[ "problems" ], { cFile, nLine, "E", cForm + "." + cName + " is defined twice in the same window (also " + ;
                                  hb_FNameNameExt( hC[ "file" ] ) + ":" + hb_ntos( hC[ "line" ] ) + ")" } )
      ENDIF
      RETURN { cName, cForm }
   ENDIF
   hC := { "name" => cName, "type" => cType, "file" => cFile, "line" => nLine, "where" => cWhere, "uses" => 0, "defno" => hF[ "defno" ] }
   hF[ "controls" ][ cName ] := hC
RETURN { cName, cForm }

STATIC PROCEDURE HMGIdx_MoveControl( h, xCtl, cNewForm )
   LOCAL hC
   IF hb_HHasKey( h[ "forms" ], xCtl[ 2 ] ) .AND. hb_HHasKey( h[ "forms" ][ xCtl[ 2 ] ][ "controls" ], xCtl[ 1 ] ) .AND. ;
      ! ( Upper( xCtl[ 2 ] ) == Upper( cNewForm ) )
      hC := h[ "forms" ][ xCtl[ 2 ] ][ "controls" ][ xCtl[ 1 ] ]
      hb_HDel( h[ "forms" ][ xCtl[ 2 ] ][ "controls" ], xCtl[ 1 ] )
      HMGIdx_AddControl( h, cNewForm, hC[ "name" ], hC[ "type" ], hC[ "file" ], hC[ "line" ], hC[ "where" ] )
      xCtl[ 2 ] := cNewForm
   ENDIF
RETURN

/* "@ <row>, <col> WORD name": position of WORD when it is a control word, else 0.
   Row and col are expressions; WORD is the first known control word at bracket depth 0
   after the first top-level comma that follows an operand (not an operator). */
STATIC FUNCTION HMGIdx_AtWord( h, aT )
   LOCAL i, nDepth := 0, lComma := .F., c, cPrev
   FOR i := 2 TO Len( aT )
      c := aT[ i ][ TK_TEXT ]
      IF aT[ i ][ TK_TYPE ] == "P"
         IF c $ "([{"
            nDepth++
         ELSEIF c $ ")]}"
            nDepth--
         ELSEIF c == "," .AND. nDepth == 0
            IF lComma
               RETURN 0
            ENDIF
            lComma := .T.
         ENDIF
      ELSEIF lComma .AND. nDepth == 0 .AND. aT[ i ][ TK_TYPE ] == "I" .AND. i > 3
         cPrev := aT[ i - 1 ]
         IF ( cPrev[ TK_TYPE ] $ "INS" .OR. cPrev[ TK_TEXT ] $ ")]}" ) .AND. ! ( cPrev[ TK_TEXT ] == "," )
            RETURN iif( IsControlWord( h, c ), i, 0 )
         ENDIF
      ENDIF
   NEXT
RETURN 0

/* references in one logical line */
STATIC PROCEDURE HMGIdx_Refs( h, aT, cFile, nLine )
   LOCAL i, n := Len( aT ), cU, aArgs, cW
   FOR i := 1 TO n
      IF aT[ i ][ TK_TYPE ] != "I"
         LOOP
      ENDIF
      cU := Upper( aT[ i ][ TK_TEXT ] )
      // dot syntax: a.b[.c]  (tokens must touch: "x .and. y" is not a chain)
      IF i + 2 <= n .AND. aT[ i + 1 ][ TK_TEXT ] == "." .AND. aT[ i + 1 ][ 4 ] .AND. aT[ i + 2 ][ TK_TYPE ] == "I" .AND. ;
         ( i == 1 .OR. ! ( aT[ i - 1 ][ TK_TEXT ] == "." .AND. aT[ i - 1 ][ 4 ] ) ) .AND. ;
         ! ( "," + cU + "," ) $ s_cNotForms .AND. ! ( "," + Upper( aT[ i + 2 ][ TK_TEXT ] ) + "," ) $ s_cNotForms
         IF i + 4 <= n .AND. aT[ i + 3 ][ TK_TEXT ] == "." .AND. aT[ i + 3 ][ 4 ] .AND. aT[ i + 4 ][ TK_TYPE ] == "I"
            HMGIdx_AddRef( h, cFile, nLine, aT[ i ][ TK_TEXT ], aT[ i + 2 ][ TK_TEXT ], "dot" )
         ELSE
            HMGIdx_AddRef( h, cFile, nLine, aT[ i ][ TK_TEXT ], NIL, "dot" )
         ENDIF
         LOOP
      ENDIF
      IF i < n .AND. aT[ i + 1 ][ TK_TEXT ] == "("
         DO CASE
         CASE cU == "GETPROPERTY" .OR. cU == "SETPROPERTY" .OR. cU == "DOMETHOD"
            aArgs := CallArgs( aT, i + 1 )
            IF Len( aArgs ) >= 1 .AND. aArgs[ 1 ] != NIL
               HMGIdx_AddRef( h, cFile, nLine, aArgs[ 1 ], iif( Len( aArgs ) >= iif( cU == "DOMETHOD", 3, iif( cU == "SETPROPERTY", 4, 3 ) ), aArgs[ 2 ], NIL ), cU )
            ENDIF
         CASE cU == "ISCONTROLDEFINED" .OR. cU == "_ISCONTROLDEFINED" .OR. cU == "GETCONTROLHANDLE"
            aArgs := CallArgs( aT, i + 1, cU == "ISCONTROLDEFINED" )
            IF Len( aArgs ) >= 2 .AND. aArgs[ 2 ] != NIL .AND. aArgs[ 1 ] != NIL
               HMGIdx_AddRef( h, cFile, nLine, aArgs[ 2 ], aArgs[ 1 ], cU )
            ENDIF
         CASE cU == "ISWINDOWDEFINED" .OR. cU == "_ISWINDOWDEFINED" .OR. cU == "GETFORMHANDLE"
            aArgs := CallArgs( aT, i + 1, cU == "ISWINDOWDEFINED" )
            IF Len( aArgs ) >= 1 .AND. aArgs[ 1 ] != NIL
               HMGIdx_AddRef( h, cFile, nLine, aArgs[ 1 ], NIL, cU )
            ENDIF
         ENDCASE
      ELSEIF i == 1 .AND. cU $ "ACTIVATE|RELEASE|CENTER|SHOW|HIDE|MAXIMIZE|MINIMIZE|RESTORE" .AND. ;
             n >= 3 .AND. Upper( aT[ 2 ][ TK_TEXT ] ) == "WINDOW"
         FOR EACH cW IN WindowList( aT, 3 )
            HMGIdx_AddRef( h, cFile, nLine, cW, NIL, cU + " WINDOW" )
         NEXT
      ENDIF
   NEXT
RETURN

/* ACTIVATE WINDOW a, b, c: the names (stops at a non-name: ALL, NOWAIT ...) */
STATIC FUNCTION WindowList( aT, nFrom )
   LOCAL a := {}, i
   FOR i := nFrom TO Len( aT ) STEP 2
      IF aT[ i ][ TK_TYPE ] != "I" .OR. Upper( aT[ i ][ TK_TEXT ] ) $ "ALL|NOWAIT|MAIN"
         EXIT
      ENDIF
      AAdd( a, aT[ i ][ TK_TEXT ] )
      IF i + 1 > Len( aT ) .OR. ! aT[ i + 1 ][ TK_TEXT ] == ","
         EXIT
      ENDIF
   NEXT
RETURN a

/* arguments of a call starting at "(" (position n): string literal -> its text,
   bare name (lBare: macros like IsWindowDefined( Form_1 )) -> the name, else NIL */
STATIC FUNCTION CallArgs( aT, n, lBare )
   LOCAL a := {}, i, nDepth := 0, aCur := {}
   hb_default( @lBare, .F. )
   FOR i := n + 1 TO Len( aT )
      IF aT[ i ][ TK_TYPE ] == "P" .AND. aT[ i ][ TK_TEXT ] $ "([{"
         nDepth++
      ELSEIF aT[ i ][ TK_TYPE ] == "P" .AND. aT[ i ][ TK_TEXT ] $ ")]}"
         IF nDepth == 0
            AAdd( a, ArgValue( aCur, lBare ) )
            EXIT
         ENDIF
         nDepth--
      ELSEIF aT[ i ][ TK_TEXT ] == "," .AND. nDepth == 0
         AAdd( a, ArgValue( aCur, lBare ) )
         aCur := {}
         LOOP
      ENDIF
      AAdd( aCur, aT[ i ] )
   NEXT
RETURN a

STATIC FUNCTION ArgValue( aCur, lBare )
   IF Len( aCur ) == 1 .AND. aCur[ 1 ][ TK_TYPE ] == "S"
      RETURN aCur[ 1 ][ TK_TEXT ]
   ENDIF
   IF lBare .AND. Len( aCur ) == 1 .AND. aCur[ 1 ][ TK_TYPE ] == "I"
      RETURN aCur[ 1 ][ TK_TEXT ]
   ENDIF
RETURN NIL

STATIC PROCEDURE HMGIdx_AddRef( h, cFile, nLine, cForm, cCtl, cHow )
   IF ! Empty( cForm ) .AND. hb_regexLike( "[A-Za-z_][A-Za-z0-9_]*", cForm ) .AND. ;
      ( cCtl == NIL .OR. hb_regexLike( "[A-Za-z_][A-Za-z0-9_]*", cCtl ) )
      AAdd( h[ "refs" ], { cFile, nLine, cForm, cCtl, cHow } )
   ENDIF
RETURN

/* problems: references to forms the project does not define, to controls a form does not have */
FUNCTION HMGIdx_Check( h )
   LOCAL aR, hF, aUnknownForm := hb_HSetCaseMatch( { => }, .F. )
   FOR EACH aR IN h[ "refs" ]
      IF ! hb_HHasKey( h[ "forms" ], aR[ 3 ] )
         IF ! hb_HHasKey( aUnknownForm, aR[ 3 ] )       // once per name
            aUnknownForm[ aR[ 3 ] ] := NIL
            AAdd( h[ "problems" ], { aR[ 1 ], aR[ 2 ], "W", "form " + aR[ 3 ] + " is not defined in the project" + ;
                                     iif( aR[ 4 ] == NIL, "", " (" + aR[ 3 ] + "." + aR[ 4 ] + ")" ) } )
         ENDIF
         LOOP
      ENDIF
      hF := h[ "forms" ][ aR[ 3 ] ]
      IF aR[ 4 ] != NIL
         IF hb_HHasKey( hF[ "controls" ], aR[ 4 ] )
            hF[ "controls" ][ aR[ 4 ] ][ "uses" ]++
         ELSEIF ! ( "," + Upper( aR[ 4 ] ) + "," ) $ s_cBuiltIn .AND. ! Empty( hF[ "file" ] )
            AAdd( h[ "problems" ], { aR[ 1 ], aR[ 2 ], "E", aR[ 3 ] + "." + aR[ 4 ] + ": form " + hF[ "name" ] + ;
                                     " has no control " + aR[ 4 ] + Hint( hF, aR[ 4 ] ) } )
         ENDIF
      ENDIF
   NEXT
   ASort( h[ "problems" ],,, {| x, y | iif( x[ 1 ] == y[ 1 ], x[ 2 ] < y[ 2 ], x[ 1 ] < y[ 1 ] ) } )
RETURN h

/* "; did you mean <name>?" for a near miss (one edit away, or same letters) */
STATIC FUNCTION Hint( hF, cName )
   LOCAL c, cBest := "", nBest := 3, n
   FOR EACH c IN hb_HKeys( hF[ "controls" ] )
      n := Distance( Upper( c ), Upper( cName ) )
      IF n < nBest
         nBest := n
         cBest := hF[ "controls" ][ c ][ "name" ]
      ENDIF
   NEXT
RETURN iif( Empty( cBest ), "", "; did you mean " + cBest + "?" )

STATIC FUNCTION Distance( a, b )   // Levenshtein, small strings
   LOCAL d := {}, i, j, nA := Len( a ), nB := Len( b )
   IF Abs( nA - nB ) > 2
      RETURN 99
   ENDIF
   FOR i := 0 TO nA
      AAdd( d, Array( nB + 1 ) )
      d[ i + 1 ][ 1 ] := i
   NEXT
   FOR j := 0 TO nB
      d[ 1 ][ j + 1 ] := j
   NEXT
   FOR i := 1 TO nA
      FOR j := 1 TO nB
         d[ i + 1 ][ j + 1 ] := Min( Min( d[ i ][ j + 1 ] + 1, d[ i + 1 ][ j ] + 1 ), ;
                                     d[ i ][ j ] + iif( SubStr( a, i, 1 ) == SubStr( b, j, 1 ), 0, 1 ) )
      NEXT
   NEXT
RETURN d[ nA + 1 ][ nB + 1 ]

/* ---- source text -> logical lines of tokens ---------------------------------
   { nLine, aTokens }; a token is { cType, cText, nCol, lTouchesNext }:
   I identifier, S string (text without quotes), N number, P punctuation, M macro (&name).
   Comments (line, block, * lines, NOTE) removed; ";" at the end joins lines. */
FUNCTION HMGIdx_Logical( cSrc )
   LOCAL aOut := {}, aPhys, cLine, nPhys := 0, aCur := NIL, nStart := 0, lBlock := .F., cTrim
   IF hb_LeftEq( cSrc, hb_BChar( 0xEF ) + hb_BChar( 0xBB ) + hb_BChar( 0xBF ) )   // UTF-8 byte-order mark
      cSrc := hb_BSubStr( cSrc, 4 )
   ENDIF
   aPhys := hb_ATokens( StrTran( cSrc, Chr( 13 ) ), Chr( 10 ) )
   FOR EACH cLine IN aPhys
      nPhys++
      cTrim := LTrim( cLine )
      IF ! lBlock .AND. aCur == NIL .AND. ( Left( cTrim, 1 ) == "*" .OR. hb_LeftEqI( cTrim, "NOTE " ) )
         LOOP
      ENDIF
      cLine := StripComments( cLine, @lBlock )
      IF aCur == NIL
         aCur := {}
         nStart := nPhys
      ENDIF
      Tokenize( cLine, aCur )
      IF Len( aCur ) > 0 .AND. ATail( aCur )[ TK_TEXT ] == ";" .AND. ATail( aCur )[ TK_TYPE ] == "P"
         ASize( aCur, Len( aCur ) - 1 )       // continued on the next line
         LOOP
      ENDIF
      IF Len( aCur ) > 0
         AAdd( aOut, { nStart, aCur } )
      ENDIF
      aCur := NIL
   NEXT
   IF aCur != NIL .AND. Len( aCur ) > 0
      AAdd( aOut, { nStart, aCur } )
   ENDIF
RETURN aOut

/* removes line and block comments (outside strings); lBlock carries an open block comment across lines */
STATIC FUNCTION StripComments( cLine, lBlock )
   LOCAL cOut := "", i := 1, n := Len( cLine ), c, cQ := ""
   DO WHILE i <= n
      c := SubStr( cLine, i, 1 )
      IF lBlock
         IF SubStr( cLine, i, 2 ) == "*/"
            lBlock := .F.
            i += 2
            cOut += " "
            LOOP
         ENDIF
         i++
         LOOP
      ENDIF
      IF ! Empty( cQ )
         cOut += c
         IF c == cQ
            cQ := ""
         ENDIF
      ELSEIF c == '"' .OR. c == "'"
         cQ := c
         cOut += c
      ELSEIF SubStr( cLine, i, 2 ) == "//" .OR. SubStr( cLine, i, 2 ) == "&&"
         EXIT
      ELSEIF SubStr( cLine, i, 2 ) == "/*"
         lBlock := .T.
         i += 2
         LOOP
      ELSE
         cOut += c
      ENDIF
      i++
   ENDDO
RETURN cOut

STATIC PROCEDURE Tokenize( cLine, aT )
   LOCAL i := 1, n := Len( cLine ), c, j, cQ
   DO WHILE i <= n
      c := SubStr( cLine, i, 1 )
      DO CASE
      CASE c == " " .OR. c == Chr( 9 )
         IF Len( aT ) > 0
            ATail( aT )[ 4 ] := .F.
         ENDIF
         i++
         LOOP
      CASE IsAlpha( c ) .OR. c == "_"
         j := i
         DO WHILE j <= n .AND. ( IsAlpha( SubStr( cLine, j, 1 ) ) .OR. IsDigit( SubStr( cLine, j, 1 ) ) .OR. SubStr( cLine, j, 1 ) == "_" )
            j++
         ENDDO
         AAdd( aT, { "I", SubStr( cLine, i, j - i ), i, .T. } )
         i := j
         LOOP
      CASE IsDigit( c )
         j := i
         DO WHILE j <= n .AND. ( IsDigit( SubStr( cLine, j, 1 ) ) .OR. ( SubStr( cLine, j, 1 ) == "." .AND. IsDigit( SubStr( cLine, j + 1, 1 ) ) ) )
            j++
         ENDDO
         AAdd( aT, { "N", SubStr( cLine, i, j - i ), i, .T. } )
         i := j
         LOOP
      CASE c == '"' .OR. c == "'"
         cQ := c
         j := hb_At( cQ, cLine, i + 1 )
         IF j == 0
            j := n + 1
         ENDIF
         AAdd( aT, { "S", SubStr( cLine, i + 1, j - i - 1 ), i, .T. } )
         i := j + 1
         LOOP
      CASE c == "&" .AND. i < n .AND. ( IsAlpha( SubStr( cLine, i + 1, 1 ) ) .OR. SubStr( cLine, i + 1, 1 ) $ "_(" )
         j := i + 1
         DO WHILE j <= n .AND. ( IsAlpha( SubStr( cLine, j, 1 ) ) .OR. IsDigit( SubStr( cLine, j, 1 ) ) .OR. SubStr( cLine, j, 1 ) $ "_." )
            j++
         ENDDO
         AAdd( aT, { "M", SubStr( cLine, i, j - i ), i, .T. } )
         i := j
         LOOP
      CASE c == "#" .AND. Len( aT ) == 0
         AAdd( aT, { "P", "#", i, .T. } )
         i := n + 1                           // preprocessor line: nothing else needed
         LOOP
      OTHERWISE
         AAdd( aT, { "P", c, i, .T. } )
      ENDCASE
      i++
   ENDDO
   IF Len( aT ) > 0
      ATail( aT )[ 4 ] := .F.                 // end of a physical line: does not touch the next
   ENDIF
RETURN

STATIC FUNCTION TokI( aT, n )
RETURN iif( Len( aT ) >= n .AND. aT[ n ][ TK_TYPE ] == "I", aT[ n ][ TK_TEXT ], "" )

STATIC FUNCTION TokPos( aT, cWord, nFrom )
   LOCAL i
   FOR i := hb_defaultValue( nFrom, 1 ) TO Len( aT )
      IF aT[ i ][ TK_TYPE ] == "I" .AND. Upper( aT[ i ][ TK_TEXT ] ) == cWord
         RETURN i
      ENDIF
   NEXT
RETURN 0

/* ---- report (tools\hmgindex, and the IDE's text view) ------------------------ */
FUNCTION HMGIdx_Report( h, lAll )
   LOCAL c := "", aF, hF, aC, hC, nCtl := 0, aP
   hb_default( @lAll, .T. )
   aF := hb_HKeys( h[ "forms" ] )
   ASort( aF,,, {| x, y | Upper( x ) < Upper( y ) } )
   AEval( aF, {| k | nCtl += Len( h[ "forms" ][ k ][ "controls" ] ) } )
   c += "Files " + hb_ntos( Len( h[ "files" ] ) ) + ", forms " + hb_ntos( Len( aF ) ) + ", controls " + hb_ntos( nCtl ) + ;
        ", references " + hb_ntos( Len( h[ "refs" ] ) ) + ", problems " + hb_ntos( Len( h[ "problems" ] ) ) + hb_eol()
   IF lAll
      FOR EACH aF IN aF
         hF := h[ "forms" ][ aF ]
         c += hb_eol() + hF[ "name" ] + "  (" + iif( Empty( hF[ "kind" ] ), "?", hF[ "kind" ] ) + ")  " + ;
              iif( Empty( hF[ "file" ] ), "not defined in the project", hb_FNameNameExt( hF[ "file" ] ) + ":" + hb_ntos( hF[ "line" ] ) ) + ;
              iif( Empty( hF[ "also" ] ), "", "  (also defined at " + JoinList( hF[ "also" ] ) + ")" ) + hb_eol()
         aC := hb_HKeys( hF[ "controls" ] )
         ASort( aC,,, {| x, y | hF[ "controls" ][ x ][ "line" ] < hF[ "controls" ][ y ][ "line" ] } )
         FOR EACH hC IN aC
            hC := hF[ "controls" ][ hC ]
            c += "   " + PadR( hC[ "name" ], 24 ) + PadR( hC[ "type" ], 15 ) + PadR( hb_FNameNameExt( hC[ "file" ] ) + ":" + hb_ntos( hC[ "line" ] ), 26 ) + ;
                 iif( hC[ "uses" ] == 0, "not used  ", "used " + PadR( hb_ntos( hC[ "uses" ] ), 5 ) ) + hC[ "where" ] + hb_eol()
         NEXT
      NEXT
   ENDIF
   IF ! Empty( h[ "problems" ] )
      c += hb_eol() + "Problems" + hb_eol()
      FOR EACH aP IN h[ "problems" ]
         c += "   " + hb_FNameNameExt( aP[ 1 ] ) + ":" + hb_ntos( aP[ 2 ] ) + "  " + iif( aP[ 3 ] == "E", "error  ", "warning" ) + "  " + aP[ 4 ] + hb_eol()
      NEXT
   ENDIF
RETURN c

STATIC FUNCTION JoinList( a )
   LOCAL c := "", x
   FOR EACH x IN a
      c += iif( x:__enumIsFirst(), "", ", " ) + x
   NEXT
RETURN c
