/*
 * HMG5 sample: a small web browser with the WEBVIEW control (Microsoft Edge WebView2).
 *
 *  - toolbar: Back, Forward, Reload, Stop, Home, the address box, zoom, and "open in
 *    your own browser"; Back and Forward are enabled only when there is a page to go to
 *  - favourites: HMG Forum, HMG5 on GitHub, Harbour, Apache ECharts, the WebView2 docs
 *    and xBase on Wikipedia
 *  - a start page made by the program (HTML): its cards call Harbour through
 *    hmg.call(), which works only for the program's own content, never for a web site
 *  - the status bar follows ON NAVIGATE and ON TITLE; the window title is the page's
 *  - PRIVATE: nothing (cookies, history, cache) is kept on disk after the program ends
 *
 * Type an address, or words to search for. Needs the WebView2 Runtime (part of
 * Windows 10 and 11) and, for the web sites, an internet connection.
 */
#include "hmg.ch"

#define HOME_TITLE  "HMG5 Web Browser"

STATIC s_aFav := { ;
   { "HMG Forum",       "https://www.hmgforum.com/",                          "The HMG community: questions, answers, samples and news." }, ;
   { "HMG5 on GitHub",  "https://github.com/SRathinaGiri/HMG64",              "HMG5's source code, releases and issues." }, ;
   { "Harbour",         "https://harbour.github.io/",                         "The Harbour compiler that HMG programs are written in." }, ;
   { "Apache ECharts",  "https://echarts.apache.org/en/index.html",           "The chart library behind HMG5's CHART control." }, ;
   { "WebView2",        "https://learn.microsoft.com/microsoft-edge/webview2/", "Microsoft's documentation of the browser control used here." }, ;
   { "xBase",           "https://en.wikipedia.org/wiki/XBase",                "Wikipedia: the dBase family of languages, Clipper and Harbour." } }

STATIC s_lHome := .T.     // the start page is shown

FUNCTION Main()
   LOCAL i, nCol := 10

   IF Empty( HMG_WebViewVersion() )
      MsgStop( "This sample needs the Microsoft Edge WebView2 Runtime." )
      RETURN NIL
   ENDIF

   DEFINE WINDOW Win_Main AT 0, 0 WIDTH 1200 HEIGHT 820 TITLE HOME_TITLE MAIN ON SIZE Layout() ON MAXIMIZE Layout()

      // toolbar
      @ 8, 10  BUTTON Btn_Back    CAPTION "◀"  WIDTH 34 HEIGHT 28 ACTION Win_Main.Web_1.GoBack()    TOOLTIP "Back"
      @ 8, 46  BUTTON Btn_Forward CAPTION "▶"  WIDTH 34 HEIGHT 28 ACTION Win_Main.Web_1.GoForward() TOOLTIP "Forward"
      @ 8, 82  BUTTON Btn_Reload  CAPTION "⟳"  WIDTH 34 HEIGHT 28 ACTION Reload()                    TOOLTIP "Reload"
      @ 8, 118 BUTTON Btn_Stop    CAPTION "✕"  WIDTH 34 HEIGHT 28 ACTION Win_Main.Web_1.Stop()      TOOLTIP "Stop loading"
      @ 8, 154 BUTTON Btn_Home    CAPTION "⌂"  WIDTH 34 HEIGHT 28 ACTION GoHome()                   TOOLTIP "Start page"
      @ 10, 196 TEXTBOX Txt_Url WIDTH 700 HEIGHT 26 VALUE "" ON ENTER OpenUrl( Win_Main.Txt_Url.Value ) ;
         TOOLTIP "An address, or words to search for (Enter)"
      @ 8, 902 BUTTON Btn_Go      CAPTION "Go"  WIDTH 44 HEIGHT 28 ACTION OpenUrl( Win_Main.Txt_Url.Value )
      @ 8, 952 BUTTON Btn_ZoomOut CAPTION "−"   WIDTH 30 HEIGHT 28 ACTION Zoom( -0.1 ) TOOLTIP "Zoom out"
      @ 8, 984 BUTTON Btn_Zoom    CAPTION "100%" WIDTH 54 HEIGHT 28 ACTION Zoom( 0 )   TOOLTIP "Actual size"
      @ 8, 1040 BUTTON Btn_ZoomIn CAPTION "+"   WIDTH 30 HEIGHT 28 ACTION Zoom( 0.1 )  TOOLTIP "Zoom in"
      @ 8, 1076 BUTTON Btn_Open   CAPTION "↗"   WIDTH 34 HEIGHT 28 ACTION OpenOutside() TOOLTIP "Open this page in your own browser"

      // favourites
      FOR i := 1 TO Len( s_aFav )
         DefineFavourite( i, @nCol )
      NEXT

      @ 76, 0 WEBVIEW Web_1 WIDTH 1184 HEIGHT 680 HTML StartPage() PRIVATE ;
         ON NAVIGATE OnNavigate() ;
         ON TITLE OnTitle() ;
         ON ERROR Win_Main.StatusBar.Item( 1 ) := "Error: " + hb_HGetDef( HMG_WebViewData(), "error", "" )

      DEFINE STATUSBAR
         STATUSITEM "Start page"
         STATUSITEM "Zoom 100%" WIDTH 100
         STATUSITEM "Private: nothing is kept on disk" WIDTH 230
      END STATUSBAR

   END WINDOW

   // what the start page may ask Harbour for (web sites cannot call these)
   Win_Main.Web_1.Bind( "open", {| cUrl | OpenUrl( cUrl ) } )
   Win_Main.Web_1.Bind( "info", {|| { "webview" => HMG_WebViewVersion(), "hmg" => HMGVersion(), ;
                                      "harbour" => Version(), "favourites" => Len( s_aFav ) } } )

   Win_Main.Btn_Back.Enabled := .F.
   Win_Main.Btn_Forward.Enabled := .F.
   Layout()
   Win_Main.Center
   Win_Main.Activate
RETURN NIL

/* a button on the favourites bar (a procedure: each button's action keeps its own URL) */
STATIC PROCEDURE DefineFavourite( i, nCol )
   LOCAL cName := "Btn_Fav" + hb_ntos( i ), nW := 22 + Len( s_aFav[ i ][ 1 ] ) * 7
   LOCAL cUrl := s_aFav[ i ][ 2 ]
   @ 42, nCol BUTTON &cName OF Win_Main CAPTION s_aFav[ i ][ 1 ] WIDTH nW HEIGHT 28 ;
      ACTION OpenUrl( cUrl ) TOOLTIP cUrl
   nCol += nW + 6
RETURN

/* ---- navigation --------------------------------------------------------------------- */

/* an address (https:// is added when missing) or, with spaces or no dot, a web search */
STATIC PROCEDURE OpenUrl( cText )
   LOCAL cUrl := AllTrim( hb_defaultValue( cText, "" ) )
   IF Empty( cUrl )
      RETURN
   ENDIF
   IF ! "://" $ cUrl .AND. ! Lower( cUrl ) = "about:"
      IF " " $ cUrl .OR. ! "." $ cUrl
         cUrl := "https://duckduckgo.com/?q=" + UrlEncode( cUrl )
      ELSE
         cUrl := "https://" + cUrl
      ENDIF
   ENDIF
   s_lHome := .F.
   Win_Main.Txt_Url.Value := cUrl
   Win_Main.StatusBar.Item( 1 ) := "Loading " + cUrl + " ..."
   Win_Main.Web_1.URL := cUrl
RETURN

STATIC PROCEDURE GoHome()
   s_lHome := .T.
   Win_Main.Txt_Url.Value := ""
   Win_Main.Web_1.HTML := StartPage()
   Win_Main.StatusBar.Item( 1 ) := "Start page"
RETURN

STATIC PROCEDURE Reload()
   IF s_lHome
      GoHome()
   ELSE
      Win_Main.StatusBar.Item( 1 ) := "Reloading ..."
      Win_Main.Web_1.Reload()
   ENDIF
RETURN

STATIC PROCEDURE OnNavigate()
   LOCAL h := HMG_WebViewData(), cUrl := hb_HGetDef( h, "url", "" )
   IF Left( cUrl, 4 ) == "http" .AND. ! "hmg.example" $ cUrl
      s_lHome := .F.
      Win_Main.Txt_Url.Value := cUrl
   ENDIF
   IF hb_HGetDef( h, "success", .F. )
      Win_Main.StatusBar.Item( 1 ) := iif( s_lHome, "Start page", cUrl )
   ELSE
      Win_Main.StatusBar.Item( 1 ) := "Could not open " + cUrl + " (status " + hb_ntos( hb_HGetDef( h, "status", 0 ) ) + ")"
   ENDIF
   Win_Main.Btn_Back.Enabled := Win_Main.Web_1.CanGoBack
   Win_Main.Btn_Forward.Enabled := Win_Main.Web_1.CanGoForward
RETURN

STATIC PROCEDURE OnTitle()
   LOCAL cTitle := hb_HGetDef( HMG_WebViewData(), "title", "" )
   Win_Main.Title := iif( Empty( cTitle ) .OR. s_lHome, HOME_TITLE, cTitle + " - " + HOME_TITLE )
RETURN

STATIC PROCEDURE Zoom( nStep )
   LOCAL nZoom := iif( nStep == 0, 1, Win_Main.Web_1.ZoomFactor + nStep )
   nZoom := Max( 0.25, Min( 5, Round( nZoom, 2 ) ) )
   Win_Main.Web_1.ZoomFactor := nZoom
   Win_Main.Btn_Zoom.Caption := hb_ntos( Round( nZoom * 100, 0 ) ) + "%"
   Win_Main.StatusBar.Item( 2 ) := "Zoom " + Win_Main.Btn_Zoom.Caption
RETURN

STATIC PROCEDURE OpenOutside()
   IF ! s_lHome .AND. Left( Win_Main.Web_1.URL, 4 ) == "http"
      ShellExecute( 0, "open", Win_Main.Web_1.URL, NIL, NIL, 1 )
   ENDIF
RETURN

STATIC PROCEDURE Layout()
   LOCAL nW := Win_Main.Width, nH := Win_Main.Height
   IF nW < 640 .OR. nH < 400
      RETURN
   ENDIF
   Win_Main.Web_1.Width  := nW - 16
   Win_Main.Web_1.Height := nH - 76 - 64
   Win_Main.Txt_Url.Width := nW - 196 - 290
   Win_Main.Btn_Go.Col      := nW - 288
   Win_Main.Btn_ZoomOut.Col := nW - 238
   Win_Main.Btn_Zoom.Col    := nW - 206
   Win_Main.Btn_ZoomIn.Col  := nW - 150
   Win_Main.Btn_Open.Col    := nW - 114
RETURN

STATIC FUNCTION UrlEncode( c )
   LOCAL cOut := "", i, ch
   FOR i := 1 TO Len( c )
      ch := SubStr( c, i, 1 )
      IF IsAlpha( ch ) .OR. IsDigit( ch ) .OR. ch $ "-_.~"
         cOut += ch
      ELSEIF ch == " "
         cOut += "+"
      ELSE
         cOut += "%" + hb_NumToHex( Asc( ch ), 2 )
      ENDIF
   NEXT
RETURN cOut

/* ---- the start page ------------------------------------------------------------------ */

STATIC FUNCTION StartPage()
   LOCAL cHtml, cCards := "", a, cLogo
   // the HMG5 logo from the HMG folder, when it is there (SAMPLES\Controls\WebBrowser -> logo)
   cLogo := hb_MemoRead( hb_DirBase() + "..\..\..\logo\hmg5-ide-mark.svg" )
   IF Empty( cLogo )
      cLogo := hb_MemoRead( hb_DirBase() + "..\..\..\logo\hmg5-mark.svg" )
   ENDIF
   FOR EACH a IN s_aFav
      cCards += '<button class="card" data-url="' + a[ 2 ] + '"><b>' + a[ 1 ] + '</b><span>' + a[ 3 ] + ;
                '</span><i>' + a[ 2 ] + '</i></button>'
   NEXT
#pragma __stream|cHtml := %s
<!doctype html>
<html><head><meta charset="utf-8"><title>Start</title>
<style>
 :root { --ink:#0e1a3a; --sub:#5b6785; --line:#dbe3f3; --bg:#f6f8fd; }
 body { margin:0; font:15px "Segoe UI", system-ui, sans-serif; color:var(--ink); background:var(--bg); }
 header { display:flex; align-items:center; gap:18px; padding:28px 36px 8px; }
 header svg { width:72px; height:72px; }
 h1 { margin:0; font-size:30px; }
 h1 span { background:linear-gradient(90deg,#14d8a5,#1e9bff,#5a4dff); -webkit-background-clip:text; color:transparent; }
 p.sub { margin:4px 0 0; color:var(--sub); }
 form { padding:14px 36px; }
 form input { width:min(640px,90%); padding:11px 16px; font-size:16px; border:1px solid var(--line); border-radius:24px; outline:none; }
 form input:focus { border-color:#1e9bff; box-shadow:0 0 0 3px #1e9bff33; }
 .grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(300px,1fr)); gap:16px; padding:8px 36px 24px; }
 .card { text-align:left; display:flex; flex-direction:column; gap:6px; padding:18px 20px; border:1px solid var(--line);
         border-radius:14px; background:#fff; cursor:pointer; font:inherit; color:inherit; transition:.15s; }
 .card:hover { transform:translateY(-2px); box-shadow:0 8px 22px #0e1a3a18; border-color:#1e9bff; }
 .card b { font-size:17px; } .card span { color:var(--sub); } .card i { font-style:normal; font-size:12px; color:#1e9bff; }
 footer { padding:0 36px 28px; color:var(--sub); font-size:13px; }
</style></head>
<body>
 <header>LOGO<div><h1>HMG5 <span>Web Browser</span></h1>
   <p class="sub">A WEBVIEW control in an HMG window. This page is HTML made by the program.</p></div></header>
 <form id="f"><input id="q" placeholder="Type an address or search the web" autofocus></form>
 <div class="grid">CARDS</div>
 <footer id="info"></footer>
<script>
 // the cards and the box ask Harbour to open the page: hmg.call() reaches the bound "open" block
 document.querySelectorAll(".card").forEach(c => c.onclick = () => hmg.call("open", c.dataset.url));
 document.getElementById("f").onsubmit = e => { e.preventDefault(); hmg.call("open", document.getElementById("q").value); };
 hmg.call("info").then(i => {
   document.getElementById("info").textContent =
     i.hmg + "  ·  " + i.harbour + "  ·  WebView2 " + i.webview + "  ·  web sites cannot call Harbour; this page can.";
 });
</script>
</body></html>
#pragma __endtext
RETURN StrTran( StrTran( cHtml, "CARDS", cCards ), "LOGO", cLogo )
