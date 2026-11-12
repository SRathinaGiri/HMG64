/*
 * HMG5 sample: the CHART control (Apache ECharts in a WEBVIEW).
 * Six charts on one form: the types, stacked columns, labels, colours, a raw ECharts
 * option, ON CLICK and changing the data at run time. Needs the WebView2 runtime
 * (part of Windows 10/11); works offline.
 */
#include "hmg.ch"

FUNCTION Main()
   LOCAL aMonths := { "Jan", "Feb", "Mar", "Apr", "May", "Jun" }

   DEFINE WINDOW Win_Main AT 0, 0 WIDTH 1220 HEIGHT 760 TITLE "HMG5 charts (Apache ECharts)" MAIN

      @ 10, 10 CHART Ch_Sales WIDTH 590 HEIGHT 330 TYPE COLUMN ;
         TITLE "Receipts by month" ;
         CATEGORIES aMonths ;
         SERIES { { "2025", { 120, 132, 101, 134, 90, 230 } }, { "2026", { 220, 182, 191, 234, 290, 330 } } } ;
         STACKED LABELS ;
         ON CLICK ShowClick()

      @ 10, 610 CHART Ch_Trend WIDTH 590 HEIGHT 330 TYPE AREA ;
         TITLE "Members" ;
         CATEGORIES aMonths ;
         SERIES { { "Active", { 820, 932, 901, 934, 1290, 1330 } }, { "New", { 120, 132, 101, 134, 290, 230 } } } ;
         COLORS { { 68, 115, 197 }, { 237, 125, 49 } } ;
         ON CLICK ShowClick()

      @ 350, 10 CHART Ch_Share WIDTH 390 HEIGHT 300 TYPE DOUGHNUT ;
         TITLE "Share" ;
         CATEGORIES { "Life", "Annual", "Donor", "Student" } ;
         SERIES { 335, 310, 234, 135 } ;
         LABELS ;
         ON CLICK ShowClick()

      @ 350, 410 CHART Ch_Bar WIDTH 390 HEIGHT 300 TYPE BAR ;
         TITLE "Top streets" ;
         CATEGORIES { "North St", "Temple St", "Market Rd", "Lake View" } ;
         SERIES { { "Members", { 182, 234, 290, 104 } } } ;
         LABELS ;
         ON CLICK ShowClick()

      // any ECharts option goes through OPTION: here a gauge, which has no TYPE of its own
      @ 350, 810 CHART Ch_Gauge WIDTH 390 HEIGHT 300 ;
         TITLE "Dues collected" ;
         OPTION '{"series":[{"type":"gauge","progress":{"show":true},"detail":{"formatter":"{value}%"},"data":[{"value":72,"name":"2026"}]}],"xAxis":{"show":false},"yAxis":{"show":false}}'

      @ 670, 10 BUTTON Btn_Change CAPTION "Change data" WIDTH 140 HEIGHT 30 ACTION ChangeData()
      @ 670, 160 BUTTON Btn_Save CAPTION "Save as PNG" WIDTH 140 HEIGHT 30 ACTION SaveChart()
      @ 676, 320 LABEL Lbl_Click VALUE "Click a bar, a slice or a point" WIDTH 800 HEIGHT 24

   END WINDOW

   Win_Main.Center
   Win_Main.Activate
RETURN NIL

STATIC PROCEDURE ShowClick()
   LOCAL h := HMG_ChartClicked()
   Win_Main.Lbl_Click.Value := "Clicked: " + hb_HGetDef( h, "series", "" ) + " / " + hb_HGetDef( h, "category", "" ) + ;
                               " = " + hb_ValToStr( hb_HGetDef( h, "value", "" ) )
RETURN

STATIC PROCEDURE ChangeData()
   LOCAL aNew := {}, i
   FOR i := 1 TO 6
      AAdd( aNew, hb_RandomInt( 50, 350 ) )
   NEXT
   Win_Main.Ch_Sales.Series := { { "2025", aNew }, { "2026", { 220, 182, 191, 234, 290, 330 } } }
   Win_Main.Ch_Trend.ChartType := iif( Win_Main.Ch_Trend.ChartType == "area", "line", "area" )
RETURN

STATIC PROCEDURE SaveChart()
   LOCAL cFile := PutFile( { { "PNG image", "*.png" } }, "Save chart", , .T., "receipts.png" )
   IF ! Empty( cFile )
      IF HMG_ChartSaveImage( "Win_Main", "Ch_Sales", cFile )
         MsgInfo( "Saved: " + cFile )
      ENDIF
   ENDIF
RETURN
