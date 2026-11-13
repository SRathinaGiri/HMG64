/*
 * Unit test for the project index (SOURCE\IDE_SourceCode\Source\prjindex.prg, PHASE4-DESIGN.md 6, I12):
 * forms and controls found in code and .fmg files, references checked, problems reported.
 * Synthetic sources only, written to a temporary folder.
 */

#define CRLF  Chr( 13 ) + Chr( 10 )

STATIC s_nPass := 0, s_nFail := 0

PROCEDURE Main()
   LOCAL cDir := hb_DirSepAdd( hb_DirTemp() ) + "hmgidx" + hb_ntos( hb_RandomInt( 100000, 999999 ) ) + hb_ps()
   LOCAL h, hF, cP, aP

   ErrorBlock( {| e | OutStd( "projindex: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ErrorLevel( 2 ), __Quit() } )
   hb_DirCreate( cDir )

   hb_MemoWrit( cDir + "app.hbp", "-w3" + CRLF + "main.prg" + CRLF + "custom.prg" + CRLF + "other.prg" + CRLF )

   hb_MemoWrit( cDir + "mine.ch", ;
      '#xcommand @ <r>, <c> SEARCHBOX <name> [ OF <p> ] => MySearch( <"name">, <"p"> )' + CRLF + ;
      '#xcommand DEFINE SEARCHBOX <name> => MySearchStart( <"name"> )' + CRLF )

   hb_MemoWrit( cDir + "main.prg", hb_BChar( 0xEF ) + hb_BChar( 0xBB ) + hb_BChar( 0xBF ) + ;   // UTF-8 BOM
      '#include "hmg.ch"' + CRLF + ;
      '#include "mine.ch"' + CRLF + ;
      '* a comment line: DEFINE WINDOW NotAForm' + CRLF + ;
      'FUNCTION Main()' + CRLF + ;
      '   DEFINE WINDOW Win_Main AT 0, 0 WIDTH 600 HEIGHT 400 MAIN' + CRLF + ;
      '      DEFINE MAIN MENU' + CRLF + ;
      '         DEFINE POPUP "File"' + CRLF + ;
      '            MENUITEM "Open" ACTION Nil NAME mnuOpen' + CRLF + ;
      '         END POPUP' + CRLF + ;
      '      END MENU' + CRLF + ;
      '      DEFINE TOOLBAR Tb_1 BUTTONSIZE 20, 20' + CRLF + ;
      '         BUTTON TbNew CAPTION "New" ACTION Nil' + CRLF + ;
      '      END TOOLBAR' + CRLF + ;
      '      DEFINE TEXTBOX Txt_Name' + CRLF + ;
      '         ROW 10' + CRLF + ;
      '         COL 10' + CRLF + ;
      '      END TEXTBOX' + CRLF + ;
      '      @ 40, 10 BUTTON Btn_Save CAPTION "Save" ;' + CRLF + ;
      '         ACTION SaveIt()' + CRLF + ;
      '      @ nRow + ( 2 * 3 ), Col(1, 2) LABEL Lbl_Calc VALUE "x"   // expressions as row/col' + CRLF + ;
      '      @ 70, 10 SEARCHBOX Srch_1' + CRLF + ;
      '      DEFINE TAB Tab_1 AT 100, 10 WIDTH 300 HEIGHT 200' + CRLF + ;
      '         PAGE "General"' + CRLF + ;
      '            @ 30, 10 CHECKBOX Chk_Active CAPTION "Active"' + CRLF + ;
      '         END PAGE' + CRLF + ;
      '      END TAB' + CRLF + ;
      '      DEFINE STATUSBAR' + CRLF + ;
      '         STATUSITEM "Ready"' + CRLF + ;
      '      END STATUSBAR' + CRLF + ;
      '   END WINDOW' + CRLF + ;
      '   LOAD WINDOW Dlg_Fmg' + CRLF + ;
      '   ACTIVATE WINDOW Win_Main, Dlg_Fmg' + CRLF + ;
      'RETURN NIL' + CRLF + ;
      'FUNCTION SaveIt()' + CRLF + ;
      '   LOCAL lOk := a.and.b     // logical operators are not dot syntax' + CRLF + ;
      '   Win_Main.Txt_Name.Value := "x"' + CRLF + ;
      '   Win_Main.Txt_Nmae.Value := "y"     // typo: one letter swapped' + CRLF + ;
      '   Win_Main.Title := "t"' + CRLF + ;
      '   Win_Main.StatusBar.Item( 1 ) := "Saved"' + CRLF + ;
      '   This.Value := 1' + CRLF + ;
      '   x := "Win_Main.Ghost.Value"     // inside a string: not a reference' + CRLF + ;
      '   /* Win_Main.Ghost2.Value := 1  (block comment) */' + CRLF + ;
      '   SetProperty( "Win_Main", "Chk_Active", "Value", .T. )' + CRLF + ;
      '   SetProperty( "Win_Main", "Width", 300 )' + CRLF + ;
      '   DoMethod( "Win_Main", "Btn_Svae", "SetFocus" )' + CRLF + ;
      '   GetProperty( cForm, "Anything", "Value" )   // run-time form name: skipped' + CRLF + ;
      '   IF IsControlDefined( Btn_Save, Win_Main )' + CRLF + ;
      '      Dlg_Fmg.Ok.Enabled := .F.' + CRLF + ;
      '      Win_Main.mnuOpen.Enabled := .F.' + CRLF + ;
      '      Win_Main.TbNew.Enabled := .F.' + CRLF + ;
      '   ENDIF' + CRLF + ;
      '   RELEASE WINDOW Win_Gone' + CRLF + ;
      'RETURN NIL' + CRLF )

   hb_MemoWrit( cDir + "custom.prg", ;
      'PROCEDURE Login( lChange )' + CRLF + ;
      '   IF lChange' + CRLF + ;
      '      DEFINE WINDOW Win_Pass AT 0, 0 WIDTH 200 HEIGHT 100 MODAL' + CRLF + ;
      '         DEFINE TEXTBOX Pwd' + CRLF + ;
      '         END TEXTBOX' + CRLF + ;
      '      END WINDOW' + CRLF + ;
      '   ELSE' + CRLF + ;
      '      DEFINE WINDOW Win_Pass AT 0, 0 WIDTH 200 HEIGHT 100 MODAL   // alternative layout' + CRLF + ;
      '         DEFINE TEXTBOX Pwd' + CRLF + ;
      '         END TEXTBOX' + CRLF + ;
      '         DEFINE BUTTON Dup' + CRLF + ;
      '         END BUTTON' + CRLF + ;
      '         DEFINE BUTTON Dup' + CRLF + ;
      '         END BUTTON' + CRLF + ;
      '      END WINDOW' + CRLF + ;
      '   ENDIF' + CRLF + ;
      '   DEFINE WINDOW &cDynamic AT 0, 0 WIDTH 10 HEIGHT 10' + CRLF + ;
      '      DEFINE LABEL InDynamic' + CRLF + ;
      '      END LABEL' + CRLF + ;
      '   END WINDOW' + CRLF + ;
      '   @ 10, 10 GRID Grd_Late OF Win_Pass WIDTH 100 HEIGHT 100' + CRLF + ;
      '   @ 10, 120 CHART Ch_Late OF Win_Pass WIDTH 100 HEIGHT 100 TYPE PIE' + CRLF + ;
      '   @ Row, Col HPDFPRINT "not a control" FONT "Arial"' + CRLF + ;
      'RETURN' + CRLF )

   hb_MemoWrit( cDir + "other.prg", ;
      'PROCEDURE Other()' + CRLF + ;
      '   Win_Pass.Pwd.Value := ""' + CRLF + ;
      '   Win_Pass.Grd_Late.Refresh' + CRLF + ;
      'RETURN' + CRLF )

   hb_MemoWrit( cDir + "Dlg_Fmg.fmg", ;
      '* HMG-IDE Form Designer Generated Code' + CRLF + ;
      'DEFINE WINDOW TEMPLATE AT 0 , 0 WIDTH 300 HEIGHT 200 TITLE "Dialog" MODAL' + CRLF + ;
      '    DEFINE BUTTON Ok' + CRLF + ;
      '        ROW 10' + CRLF + ;
      '    END BUTTON' + CRLF + ;
      'END WINDOW' + CRLF )

   h := HMGIdx_Project( cDir + "app.hbp" )
   cP := HMGIdx_Report( h )

   Check( "files",                Len( h[ "files" ] ) == 4 )            // 3 .prg + the .fmg
   Check( "forms",                hb_HHasKey( h[ "forms" ], "win_main" ) .AND. hb_HHasKey( h[ "forms" ], "Win_Pass" ) .AND. hb_HHasKey( h[ "forms" ], "Dlg_Fmg" ) )
   Check( "no comment form",      ! hb_HHasKey( h[ "forms" ], "NotAForm" ) )
   Check( "BOM file read",        hb_HHasKey( h[ "forms" ], "Win_Main" ) .AND. h[ "forms" ][ "Win_Main" ][ "line" ] == 5 )
   hF := h[ "forms" ][ "Win_Main" ]
   Check( "main kind",            hF[ "kind" ] == "MAIN" )
   Check( "alternate syntax",     Ctl( hF, "Txt_Name" ) == "TEXTBOX" )
   Check( "@ syntax, continued",  Ctl( hF, "Btn_Save" ) == "BUTTON" )
   Check( "@ with expressions",   Ctl( hF, "Lbl_Calc" ) == "LABEL" )
   Check( "custom control (.ch)", Ctl( hF, "Srch_1" ) == "SEARCHBOX" )
   Check( "tab",                  Ctl( hF, "Tab_1" ) == "TAB" )
   Check( "control on tab page",  Ctl( hF, "Chk_Active" ) == "CHECKBOX" .AND. hF[ "controls" ][ "Chk_Active" ][ "where" ] == "Tab_1 / General" )
   Check( "toolbar + button",     Ctl( hF, "Tb_1" ) == "TOOLBAR" .AND. Ctl( hF, "TbNew" ) == "TOOLBUTTON" )
   Check( "menu item NAME",       Ctl( hF, "mnuOpen" ) == "MENUITEM" )
   Check( "no statusbar control", Len( hF[ "controls" ] ) == 9 )
   Check( "uses counted",         hF[ "controls" ][ "Txt_Name" ][ "uses" ] == 1 .AND. hF[ "controls" ][ "Chk_Active" ][ "uses" ] == 1 .AND. ;
                                  hF[ "controls" ][ "Btn_Save" ][ "uses" ] == 1 )
   Check( ".fmg via LOAD WINDOW", Ctl( h[ "forms" ][ "Dlg_Fmg" ], "Ok" ) == "BUTTON" )
   hF := h[ "forms" ][ "Win_Pass" ]
   Check( "alternative layout",   Len( hF[ "also" ] ) == 1 .AND. Ctl( hF, "Pwd" ) == "TEXTBOX" )
   Check( "OF another form",      Ctl( hF, "Grd_Late" ) == "GRID" .AND. hF[ "controls" ][ "Grd_Late" ][ "uses" ] == 1 )
   Check( "CHART control",        Ctl( hF, "Ch_Late" ) == "CHART" )
   Check( "dynamic window skipped", ! hb_HHasKey( h[ "forms" ], "InDynamic" ) .AND. Ctl( hF, "InDynamic" ) == "" )

   // problems: exactly these
   Check( "typo found",           Problem( h, "Win_Main.Txt_Nmae", "E" ) .AND. Problem( h, "did you mean Txt_Name?", "E" ) )
   Check( "typo in DoMethod",     Problem( h, "Win_Main.Btn_Svae", "E" ) .AND. Problem( h, "did you mean Btn_Save?", "E" ) )
   Check( "unknown form",         Problem( h, "form Win_Gone is not defined", "W" ) )
   Check( "duplicate in window",  Problem( h, "Win_Pass.Dup is defined twice in the same window", "E" ) )
   Check( "no false problems",    Len( h[ "problems" ] ) == 4 )
   IF Len( h[ "problems" ] ) != 4
      FOR EACH aP IN h[ "problems" ]
         OutStd( "   " + hb_FNameNameExt( aP[ 1 ] ) + ":" + hb_ntos( aP[ 2 ] ) + " " + aP[ 3 ] + " " + aP[ 4 ] + hb_eol() )
      NEXT
   ENDIF
   Check( "report",               "Files 4, forms 3, controls 14" $ cP .AND. "Problems" $ cP )   // controls: 9 + 4 + 1

   AEval( Directory( cDir + "*.*" ), {| a | FErase( cDir + a[ 1 ] ) } )
   DirRemove( cDir )

   OutStd( "projindex: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ErrorLevel( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC FUNCTION Ctl( hF, cName )
RETURN iif( hb_HHasKey( hF[ "controls" ], cName ), hF[ "controls" ][ cName ][ "type" ], "" )

STATIC FUNCTION Problem( h, cText, cSev )
   LOCAL aP
   FOR EACH aP IN h[ "problems" ]
      IF cText $ aP[ 4 ] .AND. aP[ 3 ] == cSev
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "projindex: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
