/*
 * Unit test for the CHART control (Apache ECharts in a WEBVIEW; SOURCE\h_chart.prg,
 * SOURCE\c_echarts.c, PHASE4-DESIGN.md section 7). Needs the WebView2 runtime; without it
 * the test only checks that the control is defined and reports itself as skipped.
 *
 * Stages (each waits for the page): loaded -> option drawn (read back from ECharts) ->
 * Series / ChartType changed with dot syntax -> raw OPTION -> PNG saved -> click event -> done.
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0
STATIC s_nStage := 0
STATIC s_xGot := NIL
STATIC s_lGot := .F.
STATIC s_hClick := NIL

#define READ_OPTION  'JSON.stringify((function(o){return {type:o.series[0].type,n:o.series.length,' + ;
                     'title:(o.title&&o.title[0]?o.title[0].text:""),cats:(o.xAxis&&o.xAxis[0]?o.xAxis[0].data:[]),' + ;
                     'names:(o.series[0].data||[]).map(function(d){return d&&d.name?d.name:""}),' + ;
                     'stack:o.series[0].stack||"",ver:echarts.version};})(hmgChart.chart.getOption()))'

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "chart: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 640 HEIGHT 460 TITLE "chart" MAIN NOSHOW ON INIT Start()
      DEFINE TIMER Tmr_Step INTERVAL 200 ACTION Step()
      DEFINE TIMER Tmr_Timeout INTERVAL 60000 ACTION Finish( "timeout at stage " + hb_ntos( s_nStage ) )
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC PROCEDURE Start()
   @ 10, 10 CHART Chart_1 OF Win_1 WIDTH 600 HEIGHT 400 TYPE COLUMN ;
      TITLE "Sales" ;
      CATEGORIES { "Jan", "Feb", "Mar" } ;
      SERIES { { "2025", { 10, 20, 30 } }, { "2026", { 12, 18, 33 } } } ;
      STACKED ;
      ON CLICK OnClick()

   Check( "defined",          _IsControlDefined( "Chart_1", "Win_1" ) )
   Check( "is a webview",     GetControlType( "Chart_1", "Win_1" ) == "WEBVIEW" )
   Check( "type property",    Win_1.Chart_1.ChartType == "column" )
   Check( "series property",  Len( Win_1.Chart_1.Series ) == 2 .AND. Win_1.Chart_1.Series[ 2 ][ 1 ] == "2026" )
   Check( "title property",   Win_1.Chart_1.ChartTitle == "Sales" )
   Check( "not loaded yet",   Win_1.Chart_1.Loaded == .F. )

   IF Empty( HMG_WebViewVersion() )
      OutStd( "chart: SKIPPED - no WebView2 runtime" + hb_eol() )
      Finish( "" )
   ENDIF
   s_nStage := 1
RETURN

/* the asynchronous part, one stage at a time */
STATIC PROCEDURE Step()
   LOCAL h, cFile, cPng
   SWITCH s_nStage
   CASE 1   // page loaded and drawn
      IF Win_1.Chart_1.Loaded
         Ask( READ_OPTION )
         s_nStage := 2
      ENDIF
      EXIT
   CASE 2
      IF s_lGot
         h := Decode()
         Check( "ECharts served from memory", hb_HGetDef( h, "ver", "" ) == HMG_ECHARTS_VERSION() )
         Check( "drawn as bar series", hb_HGetDef( h, "type", "" ) == "bar" .AND. hb_HGetDef( h, "n", 0 ) == 2 )
         Check( "title drawn",         hb_HGetDef( h, "title", "" ) == "Sales" )
         Check( "categories drawn",    ValToPrg( hb_HGetDef( h, "cats", {} ) ) == ValToPrg( { "Jan", "Feb", "Mar" } ) )
         Check( "stacked",             hb_HGetDef( h, "stack", "" ) == "total" )
         // change data and type with dot syntax: redrawn from Harbour
         Win_1.Chart_1.Series := { { "Share", { 50, 30, 20 } } }
         Win_1.Chart_1.ChartType := "pie"
         Ask( READ_OPTION )
         s_nStage := 3
      ENDIF
      EXIT
   CASE 3
      IF s_lGot
         h := Decode()
         Check( "pie after change",    hb_HGetDef( h, "type", "" ) == "pie" .AND. hb_HGetDef( h, "n", 0 ) == 1 )
         Check( "pie names = categories", ValToPrg( hb_HGetDef( h, "names", {} ) ) == ValToPrg( { "Jan", "Feb", "Mar" } ) )
         // any ECharts option, over the generated one
         Win_1.Chart_1.ChartOption := '{"title":{"text":"Raw option"}}'
         Ask( READ_OPTION )
         s_nStage := 4
      ENDIF
      EXIT
   CASE 4
      IF s_lGot
         h := Decode()
         Check( "raw option applied", hb_HGetDef( h, "title", "" ) == "Raw option" )
         cFile := hb_DirSepAdd( hb_DirTemp() ) + "hmg_chart_" + hb_ntos( hb_RandomInt( 100000, 999999 ) ) + ".png"
         Check( "SaveImage",          HMG_ChartSaveImage( "Win_1", "Chart_1", cFile, 1 ) )
         cPng := hb_MemoRead( cFile )
         Check( "PNG file",           hb_LeftEq( cPng, hb_BChar( 137 ) + "PNG" ) .AND. Len( cPng ) > 2000 )
         FErase( cFile )
         // a click on the chart, as the page reports it
         Win_1.Chart_1.ExecuteScript( 'hmgChart.emit({series:"Share",category:"Feb",value:30,index:1})' )
         s_nStage := 5
      ENDIF
      EXIT
   CASE 5
      IF s_hClick != NIL
         Check( "ON CLICK data",      hb_HGetDef( s_hClick, "category", "" ) == "Feb" .AND. hb_HGetDef( s_hClick, "value", 0 ) == 30 .AND. ;
                                      hb_HGetDef( s_hClick, "index", -1 ) == 1 .AND. hb_HGetDef( s_hClick, "series", "" ) == "Share" )
         Check( "outside ON CLICK",   HMG_ChartClicked() == NIL )
         Finish( "" )
      ENDIF
      EXIT
   ENDSWITCH
RETURN

STATIC PROCEDURE OnClick()
   s_hClick := HMG_ChartClicked()
RETURN

STATIC PROCEDURE Ask( cJs )
   s_lGot := .F.
   s_xGot := NIL
   Win_1.Chart_1.ExecuteScript( cJs, {| x, lOk | s_xGot := iif( lOk, x, NIL ), s_lGot := .T. } )
RETURN

/* the script returns JSON.stringify(...): a string holding JSON */
STATIC FUNCTION Decode()
   LOCAL h := NIL
   IF HB_ISSTRING( s_xGot )
      hb_jsonDecode( s_xGot, @h )
   ENDIF
RETURN iif( HB_ISHASH( h ), h, { => } )

STATIC PROCEDURE Finish( cWhy )
   IF ! Empty( cWhy )
      s_nFail++
      OutStd( "chart: FAIL " + cWhy + hb_eol() )
   ENDIF
   OutStd( "chart: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "chart: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
