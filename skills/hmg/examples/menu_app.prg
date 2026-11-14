/*
 * An application shell: main menu, context menu, status bar with a clock, a TIMER, a
 * modal dialog that returns a value, a CHILD window opened once, and keyboard shortcuts.
 * Build and run:  build64 menu_app.prg
 */
#include "hmg.ch"

// Win_Notes is used (Win_Notes.Restore) above its DEFINE WINDOW: dot syntax needs this
DECLARE WINDOW Win_Notes

STATIC s_cUser := ""          // what the modal login dialog returns

FUNCTION Main()

   DEFINE WINDOW Win_Main AT 0, 0 WIDTH 800 HEIGHT 560 TITLE "My Application" MAIN ;
      ON INIT Win_Main.StatusBar.Item( 1 ) := "Welcome"

      DEFINE MAIN MENU
         DEFINE POPUP "&File"
            MENUITEM "&Login..." + Chr( 9 ) + "Ctrl+L" ACTION Login()
            MENUITEM "&Notes"                        ACTION OpenNotes()
            SEPARATOR
            MENUITEM "E&xit"                         ACTION Win_Main.Release
         END POPUP
         DEFINE POPUP "&View"
            MENUITEM "&Clock in status bar" ACTION ToggleClock() NAME mnuClock CHECKED
         END POPUP
         DEFINE POPUP "&Help"
            MENUITEM "&About" ACTION MsgInfo( "My Application 1.0" + CRLF + HMGVersion(), "About" )
         END POPUP
      END MENU

      DEFINE CONTEXT MENU
         MENUITEM "Say hello" ACTION MsgInfo( "Hello from the context menu" )
      END MENU

      @ 20, 20 LABEL Lbl_Info VALUE "Right-click the window for the context menu." WIDTH 500 HEIGHT 24

      DEFINE TIMER Tmr_Clock INTERVAL 1000 ACTION Win_Main.StatusBar.Item( 2 ) := Time()

      DEFINE STATUSBAR
         STATUSITEM "" WIDTH 500
         STATUSITEM Time() WIDTH 100
      END STATUSBAR

      ON KEY CONTROL+L ACTION Login()
   END WINDOW

   Win_Main.Center
   Win_Main.Activate
RETURN NIL

/* a MODAL window blocks the others until it is released; its result comes back in a STATIC */
STATIC PROCEDURE Login()
   s_cUser := ""
   DEFINE WINDOW Win_Login AT 0, 0 WIDTH 340 HEIGHT 190 TITLE "Login" MODAL NOSIZE
      @ 24, 20 LABEL Lbl_U VALUE "User" WIDTH 80
      @ 20, 110 TEXTBOX Txt_User WIDTH 190
      @ 58, 20 LABEL Lbl_P VALUE "Password" WIDTH 80
      @ 54, 110 TEXTBOX Txt_Pass WIDTH 190 PASSWORD
      @ 100, 110 BUTTON Btn_Ok CAPTION "OK" WIDTH 90 ACTION CheckLogin()
      @ 100, 210 BUTTON Btn_Cancel CAPTION "Cancel" WIDTH 90 ACTION Win_Login.Release
      ON KEY ESCAPE ACTION Win_Login.Release
      ON KEY RETURN ACTION CheckLogin()
   END WINDOW
   Win_Login.Center
   Win_Login.Activate                     // returns when the dialog is released
   IF ! Empty( s_cUser )
      Win_Main.StatusBar.Item( 1 ) := "Logged in as " + s_cUser
   ENDIF
RETURN

STATIC PROCEDURE CheckLogin()
   IF Empty( Win_Login.Txt_User.Value ) .OR. Empty( Win_Login.Txt_Pass.Value )
      MsgExclamation( "User and password, please.", "Login" )
      RETURN
   ENDIF
   s_cUser := AllTrim( Win_Login.Txt_User.Value )   // a real program checks the password here
   Win_Login.Release
RETURN

/* a CHILD window: opened once, brought to the front if it is already open */
STATIC PROCEDURE OpenNotes()
   IF IsWindowDefined( Win_Notes )
      Win_Notes.Restore
      Win_Notes.SetFocus
      RETURN
   ENDIF
   DEFINE WINDOW Win_Notes AT 100, 100 WIDTH 420 HEIGHT 300 TITLE "Notes" CHILD
      @ 10, 10 EDITBOX Edt_Notes WIDTH 385 HEIGHT 240 VALUE ""
   END WINDOW
   Win_Notes.Activate
RETURN

STATIC PROCEDURE ToggleClock()
   Win_Main.mnuClock.Checked := ! Win_Main.mnuClock.Checked
   Win_Main.Tmr_Clock.Enabled := Win_Main.mnuClock.Checked
   IF ! Win_Main.mnuClock.Checked
      Win_Main.StatusBar.Item( 2 ) := ""
   ENDIF
RETURN
