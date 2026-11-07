/*
 * Unit test for Phase 3 S5: SET HMG LEGACY VARS OFF. The whole program runs with the
 * internal index store; no _<Form> / _<Form>_<Control> PUBLIC variable may appear,
 * and every lookup, define, release and re-define must work as with the default ON.
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "legacyvars: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " " + e:operation + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   Check( "default is ON",          HMG_LegacyVars() == .T. )
   SET HMG LEGACY VARS OFF
   Check( "switched OFF",           HMG_LegacyVars() == .F. )

   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 500 HEIGHT 400 TITLE "legacyvars" MAIN NOSHOW ON INIT RunChecks()
      @ 10, 10 TEXTBOX Text_1 VALUE "abc" WIDTH 120
      @ 40, 10 LABEL Lbl_1 VALUE "hello" WIDTH 80
      @ 70, 10 RADIOGROUP Radio_1 OPTIONS { "a", "b" } VALUE 1 WIDTH 60
      DEFINE MAIN MENU
         POPUP "File"
            MENUITEM "Exit" NAME mnuExit ACTION NIL
         END POPUP
      END MENU
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC FUNCTION RunChecks()
   LOCAL i, lErr, oErr

   // no PUBLICs created
   Check( "no form PUBLIC",         Type( "_Win_1" ) == "U" )
   Check( "no control PUBLIC",      Type( "_Win_1_Text_1" ) == "U" )
   Check( "no menu PUBLIC",         Type( "_Win_1_mnuExit" ) == "U" )

   // lookups
   Check( "window defined",         _IsWindowDefined( "Win_1" ) .AND. _IsWindowDefined( "WIN_1" ) )
   Check( "window not defined",     ! _IsWindowDefined( "Nope" ) )
   Check( "control defined",        _IsControlDefined( "Text_1", "Win_1" ) .AND. _IsControlDefined( "text_1", "win_1" ) )
   Check( "control not defined",    ! _IsControlDefined( "Nope", "Win_1" ) )
   i := GetControlIndex( "Text_1", "Win_1" )
   Check( "control index",          i > 0 .AND. _HMG_SYSDATA[ HMG_CTL_NAME ][ i ] == "Text_1" )
   Check( "form index",             GetFormIndex( "Win_1" ) > 0 .AND. GetFormHandle( "Win_1" ) != 0 )
   Check( "control handle",         GetControlHandle( "Text_1", "Win_1" ) == _HMG_SYSDATA[ HMG_CTL_HANDLE ][ i ] )
   Check( "menu item defined",      _IsControlDefined( "mnuExit", "Win_1" ) )

   // properties
   Check( "get value",              Win_1.Text_1.Value == "abc" )
   Win_1.Text_1.Value := "xyz"
   Check( "set value",              GetProperty( "Win_1", "Text_1", "Value" ) == "xyz" )
   Check( "label value",            Win_1.Lbl_1.Value == "hello" )
   Win_1.Radio_1.Value := 2
   Check( "radio value",            Win_1.Radio_1.Value == 2 )
   Check( "object API",             HMG_GetControl( "Win_1", "Text_1" ):Value == "xyz" )

   // release, re-define with the same name, runtime-defined controls
   Win_1.Lbl_1.Release
   Check( "released not defined",   ! _IsControlDefined( "Lbl_1", "Win_1" ) )
   @ 40, 10 LABEL Lbl_1 OF Win_1 VALUE "again" WIDTH 80
   Check( "re-defined",             _IsControlDefined( "Lbl_1", "Win_1" ) .AND. Win_1.Lbl_1.Value == "again" )

   // second form: define, activate, release
   DEFINE WINDOW Win_2 AT 0, 0 WIDTH 200 HEIGHT 100 TITLE "two" CHILD NOSHOW
      @ 10, 10 TEXTBOX T2 VALUE "two" WIDTH 80
   END WINDOW
   Check( "second form defined",    _IsWindowDefined( "Win_2" ) .AND. Win_2.T2.Value == "two" )
   Check( "second form no PUBLIC",  Type( "_Win_2" ) == "U" .AND. Type( "_Win_2_T2" ) == "U" )
   _ActivateWindow ( { "Win_2" }, .F. )   // no second message loop
   Win_2.Release
   DoEvents()
   Check( "second form released",   ! _IsWindowDefined( "Win_2" ) )

   // unknown name raises the same error as the missing PUBLIC did
   lErr := .F.
   BEGIN SEQUENCE WITH {| e | Break( e ) }
      GetControlIndex( "Nope", "Win_1" )
   RECOVER USING oErr
      lErr := HB_ISOBJECT( oErr ) .AND. oErr:subCode == 1003 .AND. oErr:subSystem == "BASE"
   END SEQUENCE
   Check( "unknown raises 1003",    lErr )

   OutStd( "legacyvars: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "legacyvars: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
