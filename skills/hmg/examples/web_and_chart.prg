/*
 * HMG5's modern controls: a WEBVIEW whose HTML calls Harbour (hmg.call) and a CHART
 * (Apache ECharts) that reacts to clicks and to new data.
 * Needs the Microsoft Edge WebView2 Runtime (part of Windows 10 and 11).
 * Build and run:  build64 web_and_chart.prg
 */
#include "hmg.ch"

FUNCTION Main()

   IF Empty( HMG_WebViewVersion() )
      MsgStop( "This program needs the Microsoft Edge WebView2 Runtime." )
      RETURN NIL
   ENDIF

   DEFINE WINDOW Win_Main AT 0, 0 WIDTH 1000 HEIGHT 560 TITLE "WEBVIEW and CHART" MAIN

      // HTML made by the program: trusted, so its JavaScript may call the bound Harbour blocks
      @ 10, 10 WEBVIEW Web_Form WIDTH 470 HEIGHT 480 HTML FormHtml() PRIVATE

      // a chart; ON CLICK gets the clicked bar from HMG_ChartClicked()
      @ 10, 500 CHART Ch_Sales WIDTH 470 HEIGHT 440 TYPE COLUMN ;
         TITLE "Sales by quarter" ;
         CATEGORIES { "Q1", "Q2", "Q3", "Q4" } ;
         SERIES { { "2026", { 120, 132, 101, 134 } } } ;
         LABELS ;
         ON CLICK ShowClick()

      @ 460, 500 LABEL Lbl_Click VALUE "Click a bar" WIDTH 470 HEIGHT 24
   END WINDOW

   // the only Harbour functions JavaScript can reach (web sites loaded later cannot)
   Win_Main.Web_Form.Bind( "addSale", {| cQuarter, nAmount | AddSale( cQuarter, nAmount ) } )

   Win_Main.Center
   Win_Main.Activate
RETURN NIL

STATIC FUNCTION AddSale( cQuarter, nAmount )
   LOCAL aSeries := Win_Main.Ch_Sales.Series, n
   n := AScan( { "Q1", "Q2", "Q3", "Q4" }, cQuarter )
   IF n == 0 .OR. ! HB_ISNUMERIC( nAmount )
      RETURN "unknown quarter"
   ENDIF
   aSeries[ 1 ][ 2 ][ n ] += nAmount
   Win_Main.Ch_Sales.Series := aSeries          // setting a chart property redraws it
RETURN "added " + hb_ntos( nAmount ) + " to " + cQuarter

STATIC PROCEDURE ShowClick()
   LOCAL h := HMG_ChartClicked()
   Win_Main.Lbl_Click.Value := "Clicked " + hb_HGetDef( h, "category", "" ) + " = " + hb_ValToStr( hb_HGetDef( h, "value", "" ) )
RETURN

STATIC FUNCTION FormHtml()
   LOCAL cHtml
#pragma __stream|cHtml := %s
<!doctype html><html><head><meta charset="utf-8">
<style>body{font:14px "Segoe UI",sans-serif;margin:16px} select,input,button{font:inherit;padding:4px 8px}</style>
</head><body>
<h3>Add a sale</h3>
<select id="q"><option>Q1</option><option>Q2</option><option>Q3</option><option>Q4</option></select>
<input id="a" type="number" value="25">
<button id="b">Add</button>
<p id="r"></p>
<script>
document.getElementById("b").onclick = async () => {
  const r = await hmg.call("addSale", document.getElementById("q").value,
                           Number(document.getElementById("a").value));
  document.getElementById("r").textContent = r;     // textContent: never parsed as HTML
};
</script></body></html>
#pragma __endtext
RETURN cHtml
