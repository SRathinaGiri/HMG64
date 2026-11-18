/*
 * HMG5 sample: SPLITTER (5.2)
 *
 *  - Drag the upright bar left and right: the list narrows or widens, the notes follow.
 *  - Drag the lying bar up and down between the two notes.
 *  - Esc while dragging puts everything back; the status bar shows where the bars are.
 *  - "Reset" sets both with the Position property.
 */

#include "hmg.ch"

FUNCTION Main()

   DEFINE WINDOW Win_1 ;
      AT 0, 0 WIDTH 840 HEIGHT 560 ;
      TITLE "HMG5 - Splitter" ;
      MAIN

      @ 10, 10 GRID Grid_Files WIDTH 290 HEIGHT 440 ;
         HEADERS { "Customer", "City" } WIDTHS { 150, 120 } ;
         ITEMS { { "Arun Traders", "Chennai" }, { "Bharat Steel", "Mumbai" }, { "Chola Foods", "Madurai" }, ;
                 { "Deccan Paper", "Hyderabad" }, { "Eastern Tea", "Kolkata" } }

      @ 10, 300 SPLITTER Spl_Side HEIGHT 440 ;
         BETWEEN { "Grid_Files" } AND { "Edt_Notes", "Edt_Log" } MINSIZE 120 ;
         ON CHANGE ShowPlaces()

      @ 10, 306 EDITBOX Edt_Notes WIDTH 504 HEIGHT 214 VALUE "Notes: drag the bars."

      @ 224, 306 SPLITTER Spl_Notes WIDTH 504 HORIZONTAL ;
         BETWEEN { "Edt_Notes" } AND { "Edt_Log" } MINSIZE 60 ;
         ON CHANGE ShowPlaces()

      @ 230, 306 EDITBOX Edt_Log WIDTH 504 HEIGHT 220 VALUE "Log"

      @ 460, 10 BUTTON Btn_Reset CAPTION "Reset" WIDTH 100 HEIGHT 28 ;
         ACTION ( Win_1.Spl_Side.Position := 300, Win_1.Spl_Notes.Position := 224, ShowPlaces() )

      DEFINE STATUSBAR
         STATUSITEM ""
      END STATUSBAR
   END WINDOW

   ShowPlaces()
   CENTER WINDOW Win_1
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC PROCEDURE ShowPlaces()
   Win_1.StatusBar.Item( 1 ) := "Upright bar at column " + hb_ntos( Win_1.Spl_Side.Position ) + ;
                                ", lying bar at row " + hb_ntos( Win_1.Spl_Notes.Position )
RETURN
