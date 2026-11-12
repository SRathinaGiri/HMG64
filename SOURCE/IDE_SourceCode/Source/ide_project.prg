/*----------------------------------------------------------------------------
 HMG5 IDE - project builder mode and recent projects (PHASE4-DESIGN.md section 6, I8)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 Many members write their forms in code and use the IDE only to keep projects and
 build them. View > Form Designer switches the designer windows off: no control
 palette, no Object Inspector, new projects get their main window in code instead
 of a .fmg; a "Forms and Controls" button takes the palette's place. Opening a
 .fmg still works: the designer windows come back while that form is open.
 File > Code Only New Project: <name>.prg is the only (main) module, the main window written
 in code, no .fmg (New Project itself is unchanged).
 Settings: ide.ini ("designer=0|1", "editor=builtin|external"); recent projects: recent.ini
 (one path a line).
---------------------------------------------------------------------------*/

#include "hmg.ch"

DECLARE WINDOW Form_Main

#define RECENT_MAX  8

MEMVAR StartUpFolder
MEMVAR lDesignerOn
MEMVAR aRecentProjects
MEMVAR ProjectName
MEMVAR cParameters
MEMVAR nParameterCount

STATIC s_lBuiltinEditor := .T.   // the IDE's own code editor (ide_editor.prg) instead of editor.ini's program

PROCEDURE IDE_LoadIdeSettings()
   LOCAL cLine
   FOR EACH cLine IN hb_ATokens( StrTran( hb_MemoRead( StartUpFolder + "ide.ini" ), Chr( 13 ) ), Chr( 10 ) )
      IF Lower( AllTrim( cLine ) ) == "designer=0"
         lDesignerOn := .F.
      ELSEIF Lower( AllTrim( cLine ) ) == "editor=external"
         s_lBuiltinEditor := .F.
      ENDIF
   NEXT
   aRecentProjects := {}
   FOR EACH cLine IN hb_ATokens( StrTran( hb_MemoRead( StartUpFolder + "recent.ini" ), Chr( 13 ) ), Chr( 10 ) )
      cLine := AllTrim( cLine )
      IF ! Empty( cLine ) .AND. Len( aRecentProjects ) < RECENT_MAX
         AAdd( aRecentProjects, cLine )
      ENDIF
   NEXT
RETURN

STATIC PROCEDURE IDE_SaveIdeSettings()
   LOCAL c := "", x
   hb_MemoWrit( StartUpFolder + "ide.ini", "designer=" + iif( lDesignerOn, "1", "0" ) + hb_eol() + ;
                                            "editor=" + iif( s_lBuiltinEditor, "builtin", "external" ) + hb_eol() )
   FOR EACH x IN aRecentProjects
      c += x + hb_eol()
   NEXT
   hb_MemoWrit( StartUpFolder + "recent.ini", c )
RETURN

/* Tools > Preferences > Use the built-in editor */
FUNCTION IDE_UseBuiltinEditor( lSet )
   IF HB_ISLOGICAL( lSet ) .AND. lSet != s_lBuiltinEditor
      s_lBuiltinEditor := lSet
      IDE_SaveIdeSettings()
   ENDIF
RETURN s_lBuiltinEditor

/* View > Form Designer */
PROCEDURE IDE_ToggleDesigner()
   lDesignerOn := ! lDesignerOn
   IDE_SaveIdeSettings()
   Form_Main.mnuDesigner.Checked := lDesignerOn
   IDE_ApplyDesignerMode( lDesignerOn )
RETURN

/* the designer windows: control palette, builders, user components, Object Inspector */
PROCEDURE IDE_ApplyDesignerMode( lShow )
   LOCAL i, c
   IF ! _IsWindowDefined( "Form_Main" )
      RETURN
   ENDIF
   FOR i := 1 TO 36
      c := "Control_" + StrZero( i, 2 )
      IF _IsControlDefined( c, "Form_Main" )
         SetProperty( "Form_Main", c, "Visible", lShow )
      ENDIF
   NEXT
   FOR EACH c IN { "DeleteControl", "TabOrder", "label_User", "User", "FRAME_1", "NewForm" }
      IF _IsControlDefined( c, "Form_Main" )
         SetProperty( "Form_Main", c, "Visible", lShow )
      ENDIF
   NEXT
   IF _IsControlDefined( "Btn_FormsControls", "Form_Main" )
      SetProperty( "Form_Main", "Btn_FormsControls", "Visible", ! lShow )
   ENDIF
   IF _IsWindowDefined( "Properties" )
      DoMethod( "Properties", iif( lShow, "Show", "Hide" ) )
   ENDIF
RETURN

/* around a design form's message loop: in project mode the designer windows are shown
   while a form (.fmg) is open, and hidden again when it is closed */
PROCEDURE IDE_DesignerForForm( lOpen )
   IF ! lDesignerOn
      IDE_ApplyDesignerMode( lOpen )
   ENDIF
RETURN

/* main.prg of a new project in project mode: the main window written in code */
FUNCTION IDE_HandCodedMain( cProject )
   LOCAL cName := hb_FNameName( hb_defaultValue( cProject, "" ) ), c
   c := '#include <hmg.ch>' + hb_eol() + hb_eol()
   c += 'FUNCTION Main()' + hb_eol() + hb_eol()
   c += '   DEFINE WINDOW Win_Main ;' + hb_eol()
   c += '      AT 0, 0 WIDTH 640 HEIGHT 480 ;' + hb_eol()
   c += '      TITLE "' + iif( Empty( cName ), "Main", cName ) + '" ;' + hb_eol()
   c += '      MAIN' + hb_eol() + hb_eol()
   c += '      DEFINE BUTTON Btn_Close' + hb_eol()
   c += '         ROW     400' + hb_eol()
   c += '         COL     510' + hb_eol()
   c += '         WIDTH   100' + hb_eol()
   c += '         HEIGHT  28' + hb_eol()
   c += '         CAPTION "Close"' + hb_eol()
   c += '         ACTION  ThisWindow.Release' + hb_eol()
   c += '      END BUTTON' + hb_eol() + hb_eol()
   c += '   END WINDOW' + hb_eol() + hb_eol()
   c += '   Win_Main.Center' + hb_eol()
   c += '   Win_Main.Activate' + hb_eol() + hb_eol()
   c += 'RETURN NIL' + hb_eol()
RETURN c

/* File > Recent Projects: most recent first, full paths, at most RECENT_MAX */
PROCEDURE IDE_AddRecent( cFile )
   LOCAL n
   IF Empty( cFile )
      RETURN
   ENDIF
   cFile := AllTrim( cFile )
   IF ! ( SubStr( cFile, 2, 1 ) == ":" .OR. Left( cFile, 2 ) == "\\" )
      cFile := hb_DirSepAdd( hb_cwd() ) + cFile
   ENDIF
   IF ! Lower( hb_FNameExt( cFile ) ) == ".hbp"
      cFile += ".hbp"
   ENDIF
   IF ( n := AScan( aRecentProjects, {| x | Lower( x ) == Lower( cFile ) } ) ) > 0
      hb_ADel( aRecentProjects, n, .T. )
   ENDIF
   hb_AIns( aRecentProjects, 1, cFile, .T. )
   IF Len( aRecentProjects ) > RECENT_MAX
      ASize( aRecentProjects, RECENT_MAX )
   ENDIF
   IDE_SaveIdeSettings()
   IF IsMainMenuDefined( "Form_Main" )
      Proc_DEFINE_MAIN_MENU()     // the menu is rebuilt to show the new list
   ENDIF
RETURN

/* called inside DEFINE MAIN MENU (File popup) */
PROCEDURE IDE_DefineRecentMenu()
   LOCAL i
   POPUP 'Recent Projects'
      IF Empty( aRecentProjects )
         ITEM '(none)' ACTION Nil
      ENDIF
      FOR i := 1 TO Len( aRecentProjects )
         _DefineMenuItem( "&" + hb_ntos( i ) + "  " + aRecentProjects[ i ], IDE_RecentBlock( i ), "mnuRecent" + hb_ntos( i ) )
      NEXT
   END POPUP
RETURN

STATIC FUNCTION IDE_RecentBlock( n )
RETURN {|| IDE_OpenRecent( n ) }

STATIC PROCEDURE IDE_OpenRecent( n )
   LOCAL cFile
   IF n < 1 .OR. n > Len( aRecentProjects )
      RETURN
   ENDIF
   cFile := aRecentProjects[ n ]
   IF ! hb_FileExists( cFile )
      MsgStop( cFile + hb_eol() + "was not found; it is removed from the list.", "HMG IDE" )
      hb_ADel( aRecentProjects, n, .T. )
      IDE_SaveIdeSettings()
      Proc_DEFINE_MAIN_MENU()
      RETURN
   ENDIF
   // the same way as a project named on the command line
   IF Len( cParameters ) == 0
      AAdd( cParameters, cFile )
   ELSE
      cParameters[ 1 ] := cFile
   ENDIF
   nParameterCount := 1
   OpenProject()
RETURN
