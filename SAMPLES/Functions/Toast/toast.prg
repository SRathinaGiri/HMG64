/*
 * HMG5 sample: HMG_Toast (5.2)
 *
 *  - Each button shows a toast at the bottom right; several stack, the newest at the bottom.
 *  - A toast never takes the focus: keep typing in the box while they come and go.
 *  - Click a toast to close it; while the mouse is on it, it stays.
 */

#include "hmg.ch"

FUNCTION Main()

   DEFINE WINDOW Win_1 ;
      AT 0, 0 WIDTH 440 HEIGHT 260 ;
      TITLE "HMG5 - Toast" ;
      MAIN

      @ 20, 20 TEXTBOX Txt_Note WIDTH 390 PLACEHOLDER "Type here: the toasts leave the focus alone"

      @ 70, 20 BUTTON Btn_Info CAPTION "Information" WIDTH 120 HEIGHT 30 ;
         ACTION HMG_Toast( "12 invoices were exported to Tally.", "Export done", 4, 1 )
      @ 70, 155 BUTTON Btn_Warn CAPTION "Warning" WIDTH 120 HEIGHT 30 ;
         ACTION HMG_Toast( "The GST portal is slow today; the upload may take a while.", "Slow connection", 6, 2 )
      @ 70, 290 BUTTON Btn_Error CAPTION "Error" WIDTH 120 HEIGHT 30 ;
         ACTION HMG_Toast( "The file is open in another program.", "Could not save", 0, 3 )

      @ 115, 20 BUTTON Btn_Plain CAPTION "Plain text" WIDTH 120 HEIGHT 30 ;
         ACTION HMG_Toast( "Saved at " + Time() )
      @ 115, 155 BUTTON Btn_Clear CAPTION "Close all" WIDTH 120 HEIGHT 30 ;
         ACTION HMG_ToastCloseAll()

      @ 170, 20 LABEL Lbl_Help WIDTH 390 HEIGHT 40 ;
         VALUE "nSeconds 0 (the error) stays until it is clicked."
   END WINDOW

   CENTER WINDOW Win_1
   ACTIVATE WINDOW Win_1
RETURN NIL
