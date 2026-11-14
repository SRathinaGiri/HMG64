/*
 * The smallest complete HMG program: one MAIN window, a label, a text box and a button.
 * Build and run:  build64 hello.prg
 */
#include "hmg.ch"

FUNCTION Main()

   DEFINE WINDOW Win_Main AT 0, 0 WIDTH 420 HEIGHT 200 ;
      TITLE "Hello HMG5" MAIN

      @ 24, 20 LABEL Lbl_Name VALUE "Your name:" WIDTH 90 HEIGHT 24
      @ 20, 110 TEXTBOX Txt_Name WIDTH 270 HEIGHT 26 VALUE "" ;
         ON ENTER SayHello()
      @ 70, 110 BUTTON Btn_Hello CAPTION "Say hello" WIDTH 120 HEIGHT 30 ;
         ACTION SayHello()
      @ 70, 240 BUTTON Btn_Close CAPTION "Close" WIDTH 120 HEIGHT 30 ;
         ACTION Win_Main.Release

   END WINDOW

   Win_Main.Center
   Win_Main.Activate      // runs the program until the MAIN window closes
RETURN NIL

STATIC PROCEDURE SayHello()
   LOCAL cName := AllTrim( Win_Main.Txt_Name.Value )
   IF Empty( cName )
      MsgStop( "Please type your name first.", "Hello" )
      Win_Main.Txt_Name.SetFocus
      RETURN
   ENDIF
   MsgInfo( "Hello, " + cName + "!", "Hello" )
RETURN
