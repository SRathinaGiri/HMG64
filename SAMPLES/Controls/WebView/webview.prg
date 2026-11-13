/*
 * HMG5 WebView2 demo (Phase 4).
 *
 * Tab 1: an HTML screen built by the program. Its buttons call Harbour through
 *        hmg.call(); Harbour pushes data to the page with PostMessage.
 * Tab 2: a small browser (URL box, Back, Forward, Reload). Pages from the web
 *        are displayed, but they cannot call Harbour (not the app's own content).
 *
 * Needs the Microsoft Edge WebView2 Runtime (part of Windows 10 and 11).
 */
#include "hmg.ch"

STATIC s_aInvoices := { ;
   { "INV-101", "Arun Traders",      12500.00 }, ;
   { "INV-102", "Meena Textiles",     8420.50 }, ;
   { "INV-103", "Sri Ganesh Stores", 23100.00 } }

FUNCTION Main()

   IF Empty( HMG_WebViewVersion() )
      MsgStop( "This demo needs the Microsoft Edge WebView2 Runtime." )
      RETURN NIL
   ENDIF

   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 900 HEIGHT 640 TITLE "HMG5 WebView2 demo" MAIN ON SIZE Resize()

      DEFINE TAB Tab_1 AT 5, 5 WIDTH 880 HEIGHT 590

         PAGE "HTML screen"
            @ 30, 10 WEBVIEW Web_App WIDTH 855 HEIGHT 545 HTML AppPage() PRIVATE ;
               ON READY Win_1.StatusBar.Item( 1 ) := "WebView2 " + HMG_WebViewVersion() + " ready" ;
               ON MESSAGE OnAppMessage()
         END PAGE

         PAGE "Browser"
            @ 32, 10 TEXTBOX Txt_Url WIDTH 600 VALUE "https://harbour.github.io/" ON ENTER Go()
            @ 30, 620 BUTTON Btn_Go     CAPTION "Go"      WIDTH 50 ACTION Go()
            @ 30, 675 BUTTON Btn_Back   CAPTION "<"       WIDTH 40 ACTION Win_1.Web_Browse.GoBack()
            @ 30, 720 BUTTON Btn_Fwd    CAPTION ">"       WIDTH 40 ACTION Win_1.Web_Browse.GoForward()
            @ 30, 765 BUTTON Btn_Reload CAPTION "Reload"  WIDTH 70 ACTION Win_1.Web_Browse.Reload()
            @ 65, 10 WEBVIEW Web_Browse WIDTH 855 HEIGHT 510 URL "about:blank" ;
               ON NAVIGATE Win_1.StatusBar.Item( 1 ) := HMG_WebViewData()[ "url" ] + ;
                                 iif( HMG_WebViewData()[ "success" ], "", " (failed)" ) ;
               ON TITLE Win_1.Title := "HMG5 WebView2 demo - " + HMG_WebViewData()[ "title" ]
         END PAGE

      END TAB

      DEFINE STATUSBAR
         STATUSITEM "Starting WebView2..."
      END STATUSBAR

   END WINDOW

   // Harbour functions the page may call. Nothing else is reachable from JavaScript.
   Win_1.Web_App.Bind( "invoices", {|| s_aInvoices } )
   Win_1.Web_App.Bind( "addInvoice", {| cParty, nAmount | AddInvoice( cParty, nAmount ) } )
   Win_1.Web_App.Bind( "confirm", {| cText | MsgYesNo( cText, "HMG" ) } )

   CENTER WINDOW Win_1
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC FUNCTION AddInvoice( cParty, nAmount )
   LOCAL cNo
   IF ! HB_ISSTRING( cParty ) .OR. Empty( cParty ) .OR. ! HB_ISNUMERIC( nAmount ) .OR. nAmount <= 0
      // a runtime error here rejects the page's promise with this text
      Eval( ErrorBlock(), ErrorNew( "DEMO", 0, 1, "addInvoice", "party and a positive amount are required" ) )
   ENDIF
   cNo := "INV-" + hb_ntos( 100 + Len( s_aInvoices ) + 1 )
   AAdd( s_aInvoices, { cNo, AllTrim( cParty ), nAmount } )
   // tell the page (and any other listener) that the list changed
   Win_1.Web_App.PostMessage( { "event" => "changed", "count" => Len( s_aInvoices ) } )
RETURN cNo

STATIC PROCEDURE OnAppMessage()
   LOCAL h := HMG_WebViewData()
   IF HB_ISHASH( h[ "value" ] ) .AND. hb_HGetDef( h[ "value" ], "event", "" ) == "status"
      Win_1.StatusBar.Item( 1 ) := hb_HGetDef( h[ "value" ], "text", "" )
   ENDIF
RETURN

STATIC PROCEDURE Go()
   Win_1.Web_Browse.URL := AllTrim( Win_1.Txt_Url.Value )
RETURN

STATIC PROCEDURE Resize()
   LOCAL nW := Win_1.Width, nH := Win_1.Height
   IF nW < 400 .OR. nH < 300
      RETURN
   ENDIF
   Win_1.Tab_1.Width  := nW - 20
   Win_1.Tab_1.Height := nH - 50 - 25
   Win_1.Web_App.Width     := nW - 45
   Win_1.Web_App.Height    := nH - 95 - 25
   Win_1.Web_Browse.Width  := nW - 45
   Win_1.Web_Browse.Height := nH - 130 - 25
RETURN

STATIC FUNCTION AppPage()
   LOCAL cHtml
#pragma __stream|cHtml := %s
<!doctype html>
<html><head><meta charset="utf-8"><title>Invoices</title>
<style>
 body { font: 14px "Segoe UI", sans-serif; margin: 16px; color: #222; }
 table { border-collapse: collapse; min-width: 480px; }
 th, td { padding: 6px 10px; border-bottom: 1px solid #ddd; text-align: left; }
 td.amt, th.amt { text-align: right; font-variant-numeric: tabular-nums; }
 .bar { margin: 12px 0; display: flex; gap: 8px; }
 input { padding: 4px 6px; } button { padding: 4px 12px; }
 #msg { color: #a00; min-height: 1.2em; }
</style></head>
<body>
 <h2>Invoices (data from Harbour)</h2>
 <table><thead><tr><th>No.</th><th>Party</th><th class="amt">Amount (₹)</th></tr></thead>
  <tbody id="rows"></tbody>
  <tfoot><tr><th></th><th>Total</th><th class="amt" id="total"></th></tr></tfoot></table>
 <div class="bar">
  <input id="party" placeholder="Party">
  <input id="amount" placeholder="Amount" type="number" step="0.01">
  <button id="add">Add</button>
 </div>
 <div id="msg"></div>
<script>
 const fmt = new Intl.NumberFormat("en-IN", { minimumFractionDigits: 2 });
 async function load() {
   const list = await hmg.call("invoices");        // Harbour array -> JS array
   const rows = document.getElementById("rows");
   rows.textContent = "";
   let total = 0;
   for (const [no, party, amt] of list) {
     const tr = rows.insertRow();
     tr.insertCell().textContent = no;
     tr.insertCell().textContent = party;           // textContent: data is never parsed as HTML
     const c = tr.insertCell(); c.className = "amt"; c.textContent = fmt.format(amt);
     total += amt;
   }
   document.getElementById("total").textContent = fmt.format(total);
   hmg.post({ event: "status", text: list.length + " invoices" });
 }
 document.getElementById("add").onclick = async () => {
   const party = document.getElementById("party").value;
   const amount = parseFloat(document.getElementById("amount").value);
   const msg = document.getElementById("msg");
   msg.textContent = "";
   if (!(await hmg.call("confirm", "Add an invoice for " + party + "?"))) return;
   try {
     const no = await hmg.call("addInvoice", party, amount);
     msg.textContent = "Added " + no;
   } catch (e) {
     msg.textContent = e.message;                   // Harbour error text
   }
 };
 hmg.on(d => { if (d && d.event === "changed") load(); });   // pushed by Harbour
 load();
</script>
</body></html>
#pragma __endtext
RETURN cHtml
