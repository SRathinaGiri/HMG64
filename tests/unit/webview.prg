/*
 * Unit test for the HMG5 WebView2 control (PHASE4-DESIGN.md section 1, SOURCE/h_webview.prg,
 * SOURCE/c_webview.c). Needs the Microsoft Edge WebView2 Runtime (part of Windows 10/11);
 * without it only the "no runtime" path is checked.
 *
 * The control is asynchronous, so the test is a chain of events:
 *   ready -> page calls Harbour (bound / unbound / failing) -> ExecuteScript result ->
 *   PostMessage echo -> foreign origin rejected -> release -> PRIVATE control ready -> done.
 * A timer fails the test after 60 s if the chain stalls.
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0
STATIC s_hGot := NIL
STATIC s_nStage := 0
STATIC s_cDir := ""
STATIC s_cText := "abc"   // Unicode text in the UNICODE build (set in Main)

#define PAGE ;
   '<!doctype html><html><head><meta charset="utf-8"><title>wv-test</title></head><body>' + ;
   '<p id="p">' + s_cText + '</p><script>' + ;
   'hmg.on(function(d){ hmg.post({echo:d}); });' + ;
   'hmg.call("add", 2, 3).then(function(r){ hmg.post({sum:r}); });' + ;
   'hmg.call("text").then(function(r){ hmg.post({text:r}); });' + ;
   'hmg.call("nope").catch(function(e){ hmg.post({nope:e.message}); });' + ;
   'hmg.call("boom").catch(function(e){ hmg.post({boom:e.message}); });' + ;
   '</script></body></html>'

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "webview: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   s_hGot := { => }
   IF HMG_SupportUnicode()
      s_cText := "€ தமிழ்"     // UTF-8 source; HMG selects the UTF8 codepage in the UNICODE build
   ENDIF

   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 600 HEIGHT 400 TITLE "webview" MAIN NOSHOW ON INIT Start()
      DEFINE TIMER Tmr_Timeout INTERVAL 60000 ACTION Finish( "timeout at stage " + hb_ntos( s_nStage ) )
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC PROCEDURE Start()
   LOCAL cVer := HMG_WebViewVersion()

   OutStd( "webview: runtime " + iif( Empty( cVer ), "(none)", cVer ) + hb_eol() )

   @ 10, 10 WEBVIEW Web_1 OF Win_1 WIDTH 560 HEIGHT 340 HTML PAGE PRIVATE ;
      ON READY OnReady() ON MESSAGE OnMessage() ON ERROR OnError() ON NAVIGATE OnNavigate()

   Check( "defined",            _IsControlDefined( "Web_1", "Win_1" ) )
   Check( "type",               GetControlType( "Web_1", "Win_1" ) == "WEBVIEW" )
   Check( "not ready at once",  GetProperty( "Win_1", "Web_1", "Ready" ) == .F. )
   Check( "dot syntax ready",   Win_1.Web_1.Ready == .F. )

   IF Empty( cVer )
      // no runtime: the control must report the error, not crash
      s_nStage := -1
      RETURN
   ENDIF

   // bindings and a script queued before the control is ready
   DoMethod( "Win_1", "Web_1", "Bind", "add",  {| a, b | a + b } )
   DoMethod( "Win_1", "Web_1", "Bind", "text", {|| s_cText } )
   DoMethod( "Win_1", "Web_1", "Bind", "boom", {|| 1 / "x" } )
   Win_1.Web_1.ExecuteScript( "40 + 2", {| x, lOk | s_hGot[ "early" ] := iif( lOk, x, "fail" ) } )
   s_nStage := 1
RETURN

STATIC PROCEDURE OnReady()
   Check( "ready event",        HB_ISHASH( HMG_WebViewData() ) .AND. HMG_WebViewData()[ "ready" ] )
   Check( "ready property",     Win_1.Web_1.Ready )
   Check( "data outside event", .T. )
RETURN

STATIC PROCEDURE OnError()
   LOCAL h := HMG_WebViewData()
   IF s_nStage == -1
      Check( "no-runtime error",  HB_ISHASH( h ) .AND. "not found" $ h[ "error" ] )
      Finish( "" )
   ELSE
      Finish( "unexpected error: " + hb_ValToExp( h ) )
   ENDIF
RETURN

STATIC PROCEDURE OnNavigate()
   LOCAL h := HMG_WebViewData()
   IF s_nStage == 1
      Check( "navigate success",  h[ "success" ] )
      s_hGot[ "navurl" ] := h[ "url" ]
   ELSEIF s_nStage == 3
      // foreign page loaded: its hmg.call must be rejected
      s_nStage := 4
   ENDIF
RETURN

STATIC PROCEDURE OnMessage()
   LOCAL h := HMG_WebViewData(), v

   v := h[ "value" ]
   IF ! HB_ISHASH( v )
      RETURN
   ENDIF

   IF s_nStage == 1
      hb_HMerge( s_hGot, v )
      s_hGot[ "trusted" ] := h[ "trusted" ]
      s_hGot[ "source" ] := h[ "source" ]
      IF hb_HHasKey( s_hGot, "sum" ) .AND. hb_HHasKey( s_hGot, "nope" ) .AND. hb_HHasKey( s_hGot, "boom" ) .AND. hb_HHasKey( s_hGot, "text" )
         Check( "bound call result",     s_hGot[ "sum" ] == 5 )
         Check( "unicode round trip",    s_hGot[ "text" ] == s_cText )
         Check( "unbound call rejected", "not bound" $ s_hGot[ "nope" ] )
         Check( "error rejects promise", "argument error" $ Lower( s_hGot[ "boom" ] ) )
         Check( "HTML content trusted",  s_hGot[ "trusted" ] )
         Check( "early script result",   hb_HGetDef( s_hGot, "early", 0 ) == 42 )
         OutStd( "webview: HTML source is '" + s_hGot[ "source" ] + "', url '" + hb_HGetDef( s_hGot, "navurl", "" ) + "'" + hb_eol() )
         s_nStage := 2
         Win_1.Web_1.PostMessage( { "k" => 1, "s" => s_cText } )
      ENDIF

   ELSEIF s_nStage == 2 .AND. hb_HHasKey( v, "echo" )
      Check( "PostMessage echo",  HB_ISHASH( v[ "echo" ] ) .AND. v[ "echo" ][ "k" ] == 1 .AND. v[ "echo" ][ "s" ] == s_cText )
      Win_1.Web_1.ExecuteScript( "document.getElementById('p').textContent", ;
         {| x | Check( "ExecuteScript string", x == s_cText ), Stage3() } )

   ELSEIF s_nStage >= 3 .AND. hb_HHasKey( v, "foreign" )
      OutStd( "webview: foreign source='" + h[ "source" ] + "' result='" + hb_CStr( v[ "foreign" ] ) + "'" + hb_eol() )
      Check( "foreign untrusted",     ! h[ "trusted" ] )
      Check( "foreign call rejected", "not allowed" $ v[ "foreign" ] )
      Stage5()
   ENDIF
RETURN

STATIC PROCEDURE Stage3()
   s_nStage := 3
   // a data: URL is not one of the control's origins
   Win_1.Web_1.URL := "data:text/html,<script>hmg.call('add',1,1).then(function(){hmg.post({foreign:'allowed'})}," + ;
                      "function(e){hmg.post({foreign:e.message})})</script>"
RETURN

STATIC PROCEDURE Stage5()
   LOCAL h := GetControlHandle( "Web_1", "Win_1" )
   s_nStage := 5
   Win_1.Web_1.Release()
   Check( "released",           ! _IsControlDefined( "Web_1", "Win_1" ) )
   Check( "host destroyed",     ! HMG_WEBVIEW_ISWEBVIEW( h ) )

   // second control: URL property, created and released before it is ready
   @ 10, 10 WEBVIEW Web_2 OF Win_1 WIDTH 100 HEIGHT 100 URL "about:blank"
   Win_1.Web_2.Release()
   Check( "release before ready", ! _IsControlDefined( "Web_2", "Win_1" ) )

   // third control: ready again after the others are gone
   @ 10, 10 WEBVIEW Web_3 OF Win_1 WIDTH 200 HEIGHT 100 HTML "<p>3</p>" ;
      ON READY Stage6() ON ERROR Finish( "Web_3 error" )
RETURN

// FOLDER: a local folder served at https://app.hmg.example/, trusted, relative files work
STATIC PROCEDURE Stage6()
   LOCAL cDir := hb_DirSepAdd( hb_DirTemp() ) + "hmg_wv_test_" + hb_ntos( hb_RandomInt( 1, 999999 ) )
   s_nStage := 6
   s_cDir := cDir
   hb_DirBuild( hb_DirSepAdd( cDir ) + "js" )
   hb_MemoWrit( hb_DirSepAdd( cDir ) + "start.html", ;
      '<!doctype html><html><head><meta charset="utf-8"><script src="js/app.js"></script></head><body></body></html>' )
   hb_MemoWrit( hb_DirSepAdd( cDir ) + "js" + hb_ps() + "app.js", ;
      'hmg.call("add", 20, 22).then(function(r){ hmg.post({folder:r, origin:location.origin}); });' )
   @ 10, 10 WEBVIEW Web_4 OF Win_1 WIDTH 200 HEIGHT 100 FOLDER cDir START "start.html" ;
      ON MESSAGE OnFolderMessage() ON ERROR Finish( "Web_4 error" )
   Win_1.Web_4.Bind( "add", {| a, b | a + b } )
RETURN

STATIC PROCEDURE OnFolderMessage()
   LOCAL h := HMG_WebViewData(), v := h[ "value" ]
   IF HB_ISHASH( v ) .AND. hb_HHasKey( v, "folder" )
      Check( "folder call result", v[ "folder" ] == 42 )
      Check( "folder trusted",     h[ "trusted" ] )
      Check( "folder origin",      v[ "origin" ] == "https://app.hmg.example" )
      Finish( "" )
   ENDIF
RETURN

STATIC PROCEDURE Finish( cWhy )
   IF ! Empty( s_cDir )
      FErase( hb_DirSepAdd( s_cDir ) + "js" + hb_ps() + "app.js" )
      FErase( hb_DirSepAdd( s_cDir ) + "start.html" )
      DirRemove( hb_DirSepAdd( s_cDir ) + "js" )
      DirRemove( s_cDir )
   ENDIF
   IF ! Empty( cWhy )
      s_nFail++
      OutStd( "webview: FAIL " + cWhy + hb_eol() )
   ENDIF
   OutStd( "webview: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "webview: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
