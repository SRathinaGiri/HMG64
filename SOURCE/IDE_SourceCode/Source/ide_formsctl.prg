/*----------------------------------------------------------------------------
 HMG5 IDE - "Forms and Controls" window (PHASE4-DESIGN.md section 6, I12)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 Every form and control of the project - defined in code (DEFINE / @ syntax) or in
 .fmg files - with where it is defined and how often it is used, and the references
 that point to nothing (a misspelt control name). For members who write their forms
 by hand: the names are one search away, and typos show before the program runs.
 The index is prjindex.prg; this file is only the window.
---------------------------------------------------------------------------*/

#include "hmg.ch"

DECLARE WINDOW IDE_FC

MEMVAR ProjectName
MEMVAR ProgramEditor

STATIC s_hIdx   := NIL      // the index
STATIC s_cHbp   := ""       // project it was built from
STATIC s_aRows  := {}       // controls shown in the grid: { cForm, cControl, hControl }
STATIC s_aProbs := {}       // problems shown in the grid

/* View > Forms and Controls (F6) */
PROCEDURE IDE_FormsAndControls( cHbp )
   IF Empty( cHbp )
      cHbp := iif( Empty( ProjectName ), "", ProjectName )
   ENDIF

   IF Empty( cHbp )
      cHbp := GetFile( { { "HMG projects", "*.hbp" } }, "Forms and controls of a project" )
      IF Empty( cHbp )
         RETURN
      ENDIF
   ENDIF

   IF IsWindowDefined( IDE_FC )
      IDE_FC_Load( cHbp )
      IDE_FC.Restore
      IDE_FC.SetFocus
      RETURN
   ENDIF

   DEFINE WINDOW IDE_FC AT 120, 160 WIDTH 900 HEIGHT 620 ;
      TITLE "Forms and Controls" ;
      ON SIZE IDE_FC_Layout() ;
      ON RELEASE ( s_hIdx := NIL )

      @ 12, 10 LABEL Lbl_Find VALUE "Find:" WIDTH 40 HEIGHT 20
      @ 8, 50 TEXTBOX Txt_Find WIDTH 260 HEIGHT 24 ;
         TOOLTIP "Part of a form or control name (or type)" ;
         ON CHANGE IDE_FC_Fill()
      @ 8, 320 BUTTON Btn_Refresh CAPTION "Refresh" WIDTH 90 HEIGHT 26 ACTION IDE_FC_Load( s_cHbp )
      @ 8, 415 BUTTON Btn_Project CAPTION "Project..." WIDTH 90 HEIGHT 26 ACTION IDE_FC_Choose()
      @ 12, 515 LABEL Lbl_Summary VALUE "" WIDTH 370 HEIGHT 20

      @ 40, 10 LISTBOX Lst_Forms WIDTH 200 HEIGHT 380 ON CHANGE IDE_FC_Fill() ;
         TOOLTIP "Forms of the project"

      @ 40, 215 GRID Grd_Controls WIDTH 670 HEIGHT 380 ;
         HEADERS { "Control", "Type", "Form", "Defined at", "Uses", "Tab / page" } ;
         WIDTHS { 150, 100, 110, 150, 50, 100 } ;
         ON DBLCLICK IDE_FC_OpenControl() ;
         TOOLTIP "Double-click: open in the editor at that line"

      @ 426, 215 BUTTON Btn_Copy CAPTION "Copy Form.Control" WIDTH 140 HEIGHT 26 ACTION IDE_FC_Copy( .T. )
      @ 426, 360 BUTTON Btn_CopyName CAPTION "Copy name" WIDTH 100 HEIGHT 26 ACTION IDE_FC_Copy( .F. )
      @ 426, 465 BUTTON Btn_Open CAPTION "Open in editor" WIDTH 120 HEIGHT 26 ACTION IDE_FC_OpenControl()

      @ 458, 10 LABEL Lbl_Problems VALUE "Problems" WIDTH 400 HEIGHT 20 FONT "Arial" SIZE 9 BOLD
      @ 478, 10 GRID Grd_Problems WIDTH 875 HEIGHT 100 ;
         HEADERS { "Where", "", "Problem" } WIDTHS { 160, 60, 640 } ;
         ON DBLCLICK IDE_FC_OpenProblem() ;
         TOOLTIP "Double-click: open in the editor at that line"
   END WINDOW

   IDE_FC_Load( cHbp )
   ACTIVATE WINDOW IDE_FC
RETURN

STATIC PROCEDURE IDE_FC_Choose()
   LOCAL cHbp := GetFile( { { "HMG projects", "*.hbp" } }, "Forms and controls of a project" )
   IF ! Empty( cHbp )
      IDE_FC_Load( cHbp )
   ENDIF
RETURN

STATIC PROCEDURE IDE_FC_Load( cHbp )
   LOCAL aForms, cF, nCtl := 0, nErr := 0, aP
   s_cHbp := cHbp
   s_hIdx := HMGIdx_Project( cHbp )

   aForms := hb_HKeys( s_hIdx[ "forms" ] )
   ASort( aForms,,, {| x, y | Upper( x ) < Upper( y ) } )
   IDE_FC.Lst_Forms.DeleteAllItems
   IDE_FC.Lst_Forms.AddItem( "(all forms)" )
   FOR EACH cF IN aForms
      nCtl += Len( s_hIdx[ "forms" ][ cF ][ "controls" ] )
      IDE_FC.Lst_Forms.AddItem( s_hIdx[ "forms" ][ cF ][ "name" ] + "  (" + hb_ntos( Len( s_hIdx[ "forms" ][ cF ][ "controls" ] ) ) + ")" )
   NEXT
   IDE_FC.Lst_Forms.Value := 1
   AEval( s_hIdx[ "problems" ], {| a | iif( a[ 3 ] == "E", nErr++, NIL ) } )

   IDE_FC.Title := "Forms and Controls - " + hb_FNameNameExt( cHbp )
   IDE_FC.Lbl_Summary.Value := hb_ntos( Len( s_hIdx[ "files" ] ) ) + " files, " + hb_ntos( Len( aForms ) ) + " forms, " + ;
                               hb_ntos( nCtl ) + " controls, " + hb_ntos( Len( s_hIdx[ "refs" ] ) ) + " references"

   s_aProbs := s_hIdx[ "problems" ]
   IDE_FC.Grd_Problems.DeleteAllItems
   FOR EACH aP IN s_aProbs
      IDE_FC.Grd_Problems.AddItem( { hb_FNameNameExt( aP[ 1 ] ) + ":" + hb_ntos( aP[ 2 ] ), iif( aP[ 3 ] == "E", "error", "warning" ), aP[ 4 ] } )
   NEXT
   IDE_FC.Lbl_Problems.Value := iif( Empty( s_aProbs ), "Problems: none", ;
                                "Problems: " + hb_ntos( Len( s_aProbs ) ) + iif( nErr > 0, " (" + hb_ntos( nErr ) + " errors)", "" ) )
   IDE_FC_Fill()
RETURN

/* the controls of the selected form (or of all), filtered by the Find text */
STATIC PROCEDURE IDE_FC_Fill()
   LOCAL cFind := Upper( AllTrim( IDE_FC.Txt_Find.Value ) ), nSel := IDE_FC.Lst_Forms.Value
   LOCAL aForms, cF, hF, aC, cC, hC

   IF s_hIdx == NIL
      RETURN
   ENDIF
   aForms := hb_HKeys( s_hIdx[ "forms" ] )
   ASort( aForms,,, {| x, y | Upper( x ) < Upper( y ) } )
   IF nSel > 1 .AND. nSel - 1 <= Len( aForms )
      aForms := { aForms[ nSel - 1 ] }
   ENDIF

   s_aRows := {}
   FOR EACH cF IN aForms
      hF := s_hIdx[ "forms" ][ cF ]
      aC := hb_HKeys( hF[ "controls" ] )
      ASort( aC,,, {| x, y | iif( hF[ "controls" ][ x ][ "file" ] == hF[ "controls" ][ y ][ "file" ], ;
                                  hF[ "controls" ][ x ][ "line" ] < hF[ "controls" ][ y ][ "line" ], ;
                                  hF[ "controls" ][ x ][ "file" ] < hF[ "controls" ][ y ][ "file" ] ) } )
      FOR EACH cC IN aC
         hC := hF[ "controls" ][ cC ]
         IF Empty( cFind ) .OR. cFind $ Upper( hC[ "name" ] ) .OR. cFind $ Upper( hF[ "name" ] ) .OR. cFind $ Upper( hC[ "type" ] )
            AAdd( s_aRows, { hF[ "name" ], hC[ "name" ], hC } )
         ENDIF
      NEXT
   NEXT

   IDE_FC.Grd_Controls.DisableUpdate
   IDE_FC.Grd_Controls.DeleteAllItems
   FOR EACH cF IN s_aRows
      hC := cF[ 3 ]
      IDE_FC.Grd_Controls.AddItem( { hC[ "name" ], Lower( hC[ "type" ] ), cF[ 1 ], ;
                                     hb_FNameNameExt( hC[ "file" ] ) + ":" + hb_ntos( hC[ "line" ] ), ;
                                     iif( hC[ "uses" ] == 0, "-", hb_ntos( hC[ "uses" ] ) ), hC[ "where" ] } )
   NEXT
   IDE_FC.Grd_Controls.EnableUpdate
   IF Len( s_aRows ) > 0
      IDE_FC.Grd_Controls.Value := 1
   ENDIF
RETURN

STATIC PROCEDURE IDE_FC_Copy( lWithForm )
   LOCAL n := IDE_FC.Grd_Controls.Value
   IF n > 0 .AND. n <= Len( s_aRows )
      System.Clipboard := iif( lWithForm, s_aRows[ n ][ 1 ] + "." + s_aRows[ n ][ 2 ], s_aRows[ n ][ 2 ] )
   ENDIF
RETURN

STATIC PROCEDURE IDE_FC_OpenControl()
   LOCAL n := IDE_FC.Grd_Controls.Value
   IF n > 0 .AND. n <= Len( s_aRows )
      IDE_OpenAtLine( s_aRows[ n ][ 3 ][ "file" ], s_aRows[ n ][ 3 ][ "line" ] )
   ENDIF
RETURN

STATIC PROCEDURE IDE_FC_OpenProblem()
   LOCAL n := IDE_FC.Grd_Problems.Value
   IF n > 0 .AND. n <= Len( s_aProbs )
      IDE_OpenAtLine( s_aProbs[ n ][ 1 ], s_aProbs[ n ][ 2 ] )
   ENDIF
RETURN

/* a file at a line: the built-in editor (ide_editor.prg), or with lExternal or when
   Tools > Preferences says so the program editor: Notepad++ (-n), Notepad2/3 and
   Scintilla-based editors (/g), VS Code (--goto file:line); other editors open the file */
PROCEDURE IDE_OpenAtLine( cFile, nLine, lExternal )
   LOCAL cEd := Lower( hb_FNameName( ProgramEditor ) ), cArgs
   IF ! hb_defaultValue( lExternal, .F. ) .AND. IDE_UseBuiltinEditor()
      IDE_EdOpen( cFile, nLine )
      RETURN
   ENDIF
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

STATIC PROCEDURE IDE_FC_Layout()
   // client size, not window size: the controls are placed inside the client area
   LOCAL nW := GetClientAreaWidth( GetFormHandle( "IDE_FC" ) ) - 20, nH := GetClientAreaHeight( GetFormHandle( "IDE_FC" ) )
   IF nW < 600 .OR. nH < 420 .OR. ! IsControlDefined( Grd_Problems, IDE_FC )
      RETURN
   ENDIF
   SetProperty( "IDE_FC", "Lst_Forms",    "Height", nH - 200 )
   SetProperty( "IDE_FC", "Grd_Controls", "Width",  nW - 205 )
   SetProperty( "IDE_FC", "Grd_Controls", "Height", nH - 200 )
   SetProperty( "IDE_FC", "Btn_Copy",     "Row",    nH - 154 )
   SetProperty( "IDE_FC", "Btn_CopyName", "Row",    nH - 154 )
   SetProperty( "IDE_FC", "Btn_Open",     "Row",    nH - 154 )
   SetProperty( "IDE_FC", "Lbl_Problems", "Row",    nH - 122 )
   SetProperty( "IDE_FC", "Grd_Problems", "Row",    nH - 102 )
   SetProperty( "IDE_FC", "Grd_Problems", "Width",  nW )
RETURN
