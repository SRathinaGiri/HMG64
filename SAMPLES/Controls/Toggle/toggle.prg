/*
 * HMG5 sample: TOGGLE (5.2)
 *
 *  - Click a switch or press Space on it: it flips and ON CHANGE runs.
 *  - "Airplane mode" turns the other two off and disables them (Value :=, Enabled :=).
 *  - Run "toggle dark" to see it with SET DARKMODE ON.
 */

#include "hmg.ch"

FUNCTION Main( cMode )

   IF hb_defaultValue( cMode, "" ) == "dark"
      SET DARKMODE ON
   ENDIF

   DEFINE WINDOW Win_1 ;
      AT 0, 0 WIDTH 420 HEIGHT 300 ;
      TITLE "HMG5 - Toggle" ;
      MAIN

      @ 20, 20 TOGGLE Tgl_Wifi CAPTION "Wi-Fi" VALUE .T. WIDTH 200 ON CHANGE ShowState()
      @ 60, 20 TOGGLE Tgl_Bluetooth CAPTION "Bluetooth" WIDTH 200 ON CHANGE ShowState()
      @ 100, 20 TOGGLE Tgl_Airplane CAPTION "Airplane mode" WIDTH 200 ON CHANGE Airplane()

      DEFINE TOGGLE Tgl_Fixed
         ROW 140
         COL 20
         WIDTH 250
         CAPTION "Location (set by policy)"
         VALUE .T.
      END TOGGLE

      @ 200, 20 LABEL Lbl_State WIDTH 380 HEIGHT 24
   END WINDOW

   Win_1.Tgl_Fixed.Enabled := .F.
   ShowState()
   CENTER WINDOW Win_1
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC PROCEDURE Airplane()
   LOCAL lOn := Win_1.Tgl_Airplane.Value
   IF lOn
      Win_1.Tgl_Wifi.Value := .F.
      Win_1.Tgl_Bluetooth.Value := .F.
   ENDIF
   Win_1.Tgl_Wifi.Enabled := ! lOn
   Win_1.Tgl_Bluetooth.Enabled := ! lOn
   ShowState()
RETURN

STATIC PROCEDURE ShowState()
   Win_1.Lbl_State.Value := "Wi-Fi " + iif( Win_1.Tgl_Wifi.Value, "on", "off" ) + ;
                            ", Bluetooth " + iif( Win_1.Tgl_Bluetooth.Value, "on", "off" ) + ;
                            ", airplane mode " + iif( Win_1.Tgl_Airplane.Value, "on", "off" )
RETURN
