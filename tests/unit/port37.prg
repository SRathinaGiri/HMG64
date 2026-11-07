/*
 * Unit test for the HMG 3.7 features ported into HMG5: ROUNDED (text/edit/rich/frame),
 * SET MSGBOXMODERN, the tooltip style setters, SET MENUHOVER and TabSetModern.
 * The window is shown and painted once, so the owner-draw / ring painting code runs.
 * Defaults must stay as in 3.6: nothing visual changes unless a program opts in.
 */
#include "hmg.ch"

#define TCS_OWNERDRAWFIXED  0x2000
#define HOVER_TIMERID       65521

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   // HMG's QUIT ends in ExitProcess(0); exit through ExitProcess(n) so failures count.
   ErrorBlock( {| e | OutStd( "port37: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   // defaults, before anything is created
   Check( "custom draw default off",  _HMG_SYSDATA[ 509 ] == .F. )
   Check( "ROUNDED slot default NIL", _HMG_SYSDATA[ 521 ] == NIL )
   Check( "msgbox modern default off", SetMsgBoxModern() == .F. )

   DEFINE WINDOW Win_1 AT 60, 60 WIDTH 560 HEIGHT 420 TITLE "port37" MAIN ON INIT RunChecks()
      DEFINE MAIN MENU
         POPUP "File"
            MENUITEM "Exit" ACTION Win_1.Release
         END POPUP
         POPUP "Help"
            MENUITEM "About" ACTION NIL
         END POPUP
      END MENU
      @ 10, 10 TEXTBOX Text_R VALUE "rounded" WIDTH 140 ROUNDED 8 TOOLTIP "a tooltip"
      @ 40, 10 TEXTBOX Text_P VALUE "plain" WIDTH 140
      @ 70, 10 EDITBOX Edit_R VALUE "edit" WIDTH 140 HEIGHT 60 ROUNDED 6
      @ 140, 10 RICHEDITBOX Rich_R VALUE "rich" WIDTH 140 HEIGHT 60 ROUNDED 5
      @ 210, 10 FRAME Frame_R CAPTION "Frame" WIDTH 160 HEIGHT 80 ROUNDED 10
      @ 300, 10 FRAME Frame_P CAPTION "Plain" WIDTH 160 HEIGHT 50
      DEFINE TAB Tab_1 AT 10, 200 WIDTH 320 HEIGHT 200
         PAGE "First"
            @ 40, 20 LABEL Lbl_1 VALUE "page one" WIDTH 100
         END PAGE
         PAGE "Second"
            @ 40, 20 LABEL Lbl_2 VALUE "page two" WIDTH 100
         END PAGE
      END TAB
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC FUNCTION RunChecks()
   LOCAL hTab, hForm, hText, t0, x

   // ROUNDED clause and the slot reset after each control
   Check( "slot reset after define", _HMG_SYSDATA[ 521 ] == NIL )
   Check( "text rounded get",     GetProperty( "Win_1", "Text_R", "Rounded" ) == 8 )
   Check( "text plain get 0",     GetProperty( "Win_1", "Text_P", "Rounded" ) == 0 )
   SetProperty( "Win_1", "Text_P", "Rounded", 5 )
   Check( "text set",             GetProperty( "Win_1", "Text_P", "Rounded" ) == 5 )
   Win_1.Text_P.Rounded := 0
   Check( "text set 0 removes",   Win_1.Text_P.Rounded == 0 )
   Check( "edit rounded",         GetProperty( "Win_1", "Edit_R", "Rounded" ) == 6 )
   Check( "rich rounded",         GetProperty( "Win_1", "Rich_R", "Rounded" ) == 5 )
   Check( "frame rounded",        GetProperty( "Win_1", "Frame_R", "Rounded" ) == 10 )
   Check( "frame plain 0",        GetProperty( "Win_1", "Frame_P", "Rounded" ) == 0 )
   Win_1.Frame_P.Rounded := 6
   Check( "frame set",            Win_1.Frame_P.Rounded == 6 )
   SetProperty( "Win_1", "Text_P", "Rounded", 99 )
   Check( "text clamp 0..20",     GetProperty( "Win_1", "Text_P", "Rounded" ) == 20 )
   Check( "value unaffected",     Win_1.Text_R.Value == "rounded" )

   // SET MSGBOXMODERN
   SET MSGBOXMODERN ON
   Check( "msgbox modern on",     SetMsgBoxModern() == .T. )
   Check( "returns previous",     SetMsgBoxModern( .F. ) == .T. .AND. SetMsgBoxModern() == .F. )

   // tooltip style setters (stored always, applied only with custom draw ON)
   SET TOOLTIPROUND 4
   Check( "tooltip round",        _HMG_SYSDATA[ 519 ][ 1 ] == 4 )
   SET TOOLTIPMARGIN 6, 3
   Check( "tooltip margins",      _HMG_SYSDATA[ 519 ][ 2 ] == 6 .AND. _HMG_SYSDATA[ 519 ][ 3 ] == 3 )
   SET TOOLTIPFONT "Tahoma", 10
   Check( "tooltip font",         _HMG_SYSDATA[ 519 ][ 4 ] == "Tahoma" .AND. _HMG_SYSDATA[ 519 ][ 5 ] == 10 )
   SET TOOLTIPCUSTOMDRAW ON
   Check( "custom draw on",       _HMG_SYSDATA[ 509 ] == .T. )
   SET TOOLTIPGRADIENT ON
   SET TOOLTIPTHEME OFF
   SET TOOLTIPCUSTOMDRAW OFF
   Check( "custom draw off",      _HMG_SYSDATA[ 509 ] == .F. )

   // SET MENUHOVER
   hForm := GetFormHandle( "Win_1" )
   SET MENUHOVER OF Win_1 ON
   Check( "hover registered",     ClearMenuBarHover( hForm ) == .T. )
   Check( "hover cleared",        ClearMenuBarHover( hForm ) == .F. )
   Check( "hover set fn",         SetMenuBarHover( "Win_1", .T. ) == .T. )
   Check( "hover unknown form",   SetMenuBarHover( "NoSuchForm", .T. ) == .F. )
   Check( "timer: other id",      HandleMenuBarHoverTimer( 1 ) == .F. )
   Check( "timer: hover id",      HandleMenuBarHoverTimer( HOVER_TIMERID ) == .T. )
   Check( "hit index off bar",    MenubarHitIndex( hForm, MakeLParam( 1, 1 ) ) == -1 )
   SET MENUHOVER OF Win_1 OFF
   Check( "hover off",            ClearMenuBarHover( hForm ) == .F. )
   t0 := MenubarElapsedMs( 0 )
   hb_idleSleep( 0.05 )
   x := MenubarElapsedMs( t0 )
   Check( "elapsed ms",           x >= 40 .AND. x < 2000 )

   // TabSetModern
   hTab  := GetControlHandle( "Tab_1", "Win_1" )
   hText := GetControlHandle( "Text_P", "Win_1" )
   Check( "tab not modern",       IsTabModern( hTab ) == .F. )
   Check( "tab set modern",       TabSetModern( hTab, 0, 120, 215, 255, 255, 255, 255, 255, 255, 0, 0, 0, 90 ) == .T. )
   Check( "tab is modern",        IsTabModern( hTab ) == .T. )
   Check( "tab ownerdraw style",  hb_bitAnd( GetWindowLongPtr( hTab, -16 ), TCS_OWNERDRAWFIXED ) != 0 )
   Check( "tab set again",        TabSetModern( hTab ) == .T. )
   Check( "not a tab",            TabSetModern( hText ) == .F. )
   DoEvents()
   Win_1.Tab_1.Value := 2
   DoEvents()
   Check( "tab page switch",      Win_1.Tab_1.Value == 2 )
   Check( "tab clear",            TabClearModern( hTab ) == .T. .AND. IsTabModern( hTab ) == .F. )
   Check( "tab style restored",   hb_bitAnd( GetWindowLongPtr( hTab, -16 ), TCS_OWNERDRAWFIXED ) == 0 )
   Check( "tab clear twice",      TabClearModern( hTab ) == .F. )
   TabSetModern( hTab )           // left on: freed by WM_NCDESTROY when the form closes

   // paint everything once more with all features on
   SET TOOLTIPCUSTOMDRAW ON
   RedrawWindow( hForm )
   DoEvents()

   OutStd( "port37: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   Win_1.Release
   DoEvents()
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC FUNCTION MakeLParam( nX, nY )
RETURN hb_bitOr( hb_bitShift( nY, 16 ), nX )

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "port37: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
