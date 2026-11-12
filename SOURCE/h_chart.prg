/*----------------------------------------------------------------------------
 HMG5 - CHART control: Apache ECharts in a WEBVIEW (Phase 4, PHASE4-DESIGN.md section 7)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

   @ <row>, <col> CHART <name> [ OF <form> ] WIDTH <w> HEIGHT <h>
        [ TYPE COLUMN | BAR | LINE | AREA | POINTS | PIE | DOUGHNUT | FUNNEL ]
        [ TITLE <cTitle> ] [ CATEGORIES <aNames> ] [ SERIES <aSeries> ]
        [ LEGEND | NOLEGEND ] [ LABELS ] [ STACKED ] [ THEME <cTheme> ]
        [ COLORS <aColors> ] [ OPTION <cJson> ] [ INVISIBLE ] [ ON CLICK <action> ]

 SERIES { { "2025", { 10, 20, 30 } }, { "2026", { 12, 18, 33 } } }, or one series as a
 plain array { 10, 20, 30 }. Types follow GraphPlus: COLUMN vertical, BAR horizontal.
 PIE, DOUGHNUT and FUNNEL take the first series, named by CATEGORIES.
 OPTION: any ECharts option (JSON), applied over the generated one: every ECharts
 chart is reachable. THEME "dark" | "light"; default follows SET DARKMODE.

 Properties: ChartType, ChartTitle, Categories, Series, ChartOption (setting one redraws),
 Loaded (read only). Methods: Refresh, SaveImage( cPngFile [, nScale ] ).
 ON CLICK: HMG_ChartClicked() -> { "series", "category", "value", "index" }.
 Plus every WEBVIEW property (Row, Col, Width, Height, Visible ...).
---------------------------------------------------------------------------*/

MEMVAR _HMG_SYSDATA

#include "hmg.ch"

#define CHART_LIB_URL   "lib/echarts.min.js"

STATIC s_lLib   := .F.
STATIC s_hClick := NIL

FUNCTION _DefineChart( cName, cParent, nRow, nCol, nWidth, nHeight, cType, cTitle, aCategories, aSeries, ;
                       lLegend, lLabels, lStacked, cTheme, aColors, cOption, bClick, lInvisible )
   LOCAL hSpec, k

   IF ! s_lLib
      s_lLib := HMG_ECHARTS_REGISTER()
   ENDIF

   hSpec := { => }
   hSpec[ "type" ]       := _Chart_Type( cType )
   hSpec[ "title" ]      := hb_defaultValue( cTitle, "" )
   hSpec[ "categories" ] := iif( HB_ISARRAY( aCategories ), aCategories, {} )
   hSpec[ "series" ]     := _Chart_Series( aSeries )
   hSpec[ "legend" ]     := lLegend                        // NIL: automatic
   hSpec[ "labels" ]     := hb_defaultValue( lLabels, .F. )
   hSpec[ "stacked" ]    := hb_defaultValue( lStacked, .F. )
   hSpec[ "theme" ]      := iif( Empty( cTheme ), iif( HMG_IsDarkMode(), "dark", "light" ), Lower( AllTrim( cTheme ) ) )
   hSpec[ "colors" ]     := aColors
   hSpec[ "option" ]     := iif( HB_ISSTRING( cOption ) .AND. ! Empty( cOption ), cOption, "" )
   hSpec[ "onclick" ]    := bClick
   hSpec[ "loaded" ]     := .F.
   hSpec[ "index" ]      := 0
   hSpec[ "hook" ]       := {| cOp, i, cProp, x1, x2, xData | _Chart_Hook( cOp, i, cProp, x1, x2, @xData ) }

   k := _DefineWebView( cName, cParent, nRow, nCol, nWidth, nHeight, NIL, _Chart_Page( hSpec ), NIL, NIL, NIL, ;
                        .F., .F., NIL, NIL, {|| _Chart_Message( hSpec ) }, NIL, NIL, lInvisible )
   hSpec[ "index" ] := k
   _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [ k ] [ "chart" ] := hSpec
   RETURN NIL

/* HMG_ChartClicked() -> { "series" => c, "category" => c, "value" => x, "index" => n } in ON CLICK, else NIL */
FUNCTION HMG_ChartClicked()
   RETURN s_hClick

/* HMG_ChartSaveImage( cForm, cChart, cFile [, nScale ] ) -> lOk: the chart as a PNG file
   (nScale 2 by default: twice the screen size, for printing). Waits for the page if needed. */
FUNCTION HMG_ChartSaveImage( cForm, cChart, cFile, nScale )
   LOCAL i := GetControlIndex( cChart, cForm )
   IF i == 0 .OR. ! _Chart_Is( i )
      RETURN .F.
   ENDIF
   RETURN _Chart_SaveImage( i, cFile, nScale )

/* ---- page ----------------------------------------------------------------------- */

STATIC FUNCTION _Chart_Page( hSpec )
   LOCAL cBg := iif( hSpec[ "theme" ] == "dark", "#202020", "#ffffff" )
   LOCAL c := ""
   c += '<!DOCTYPE html><html><head><meta charset="utf-8">'
   c += '<style>html,body,#c{margin:0;padding:0;width:100%;height:100%;overflow:hidden;background:' + cBg + '}</style>'
   c += '<script src="' + CHART_LIB_URL + '"></script></head><body><div id="c"></div><script>'
   c += '(function(){'
   c += 'var el=document.getElementById("c");'
   c += 'var chart=echarts.init(el,' + iif( hSpec[ "theme" ] == "dark", '"dark"', 'null' ) + ');'
   c += 'window.hmgChart={chart:chart,'
   c +=   'set:function(o,x){chart.setOption(o,true);if(x){chart.setOption(x);}return true;},'
   c +=   'png:function(s){return chart.getDataURL({type:"png",pixelRatio:s||2,backgroundColor:"' + cBg + '"});},'
   c +=   'emit:function(d){hmg.post({chart:"click",data:d});}};'
   c += 'chart.on("click",function(p){window.hmgChart.emit({series:p.seriesName||"",category:p.name||"",'
   c +=   'value:(p.value===undefined?null:p.value),index:(p.dataIndex===undefined?-1:p.dataIndex)});});'
   c += 'window.addEventListener("resize",function(){chart.resize();});'
   c += 'hmg.post({chart:"ready"});'
   c += '})();</script></body></html>'
   RETURN c

/* ---- option ---------------------------------------------------------------------- */

STATIC FUNCTION _Chart_Type( cType )
   LOCAL c := Lower( AllTrim( hb_defaultValue( cType, "column" ) ) )
   SWITCH c
   CASE "columns" ; RETURN "column"
   CASE "bars"    ; RETURN "bar"
   CASE "point"
   CASE "scatter" ; RETURN "points"
   CASE "donut"   ; RETURN "doughnut"
   ENDSWITCH
   RETURN iif( ! Empty( c ) .AND. ( "," + c + "," ) $ ",column,bar,line,area,points,pie,doughnut,funnel,", c, "column" )

/* { { cName, aValues }, ... } ; a plain array of numbers is one unnamed series */
STATIC FUNCTION _Chart_Series( aSeries )
   LOCAL a := {}, x
   IF ! HB_ISARRAY( aSeries ) .OR. Empty( aSeries )
      RETURN a
   ENDIF
   IF ! HB_ISARRAY( aSeries[ 1 ] )
      RETURN { { "", aSeries } }
   ENDIF
   FOR EACH x IN aSeries
      IF HB_ISARRAY( x ) .AND. Len( x ) >= 2 .AND. HB_ISARRAY( x[ 2 ] )
         AAdd( a, { hb_CStr( x[ 1 ] ), x[ 2 ] } )
      ENDIF
   NEXT
   RETURN a

STATIC FUNCTION _Chart_Color( x )
   IF HB_ISARRAY( x ) .AND. Len( x ) >= 3
      RETURN "#" + hb_NumToHex( x[ 1 ], 2 ) + hb_NumToHex( x[ 2 ], 2 ) + hb_NumToHex( x[ 3 ], 2 )
   ENDIF
   RETURN hb_CStr( x )

STATIC FUNCTION _Chart_Option( hSpec )
   LOCAL o := { => }, cType := hSpec[ "type" ], lRound := cType $ "pie,doughnut,funnel"
   LOCAL aS := {}, s, hS, aData, i, lLegend, aCat := hSpec[ "categories" ], lHoriz := ( cType == "bar" )

   o[ "backgroundColor" ] := "transparent"
   o[ "animation" ] := .T.
   IF ! Empty( hSpec[ "title" ] )
      o[ "title" ] := { "text" => hSpec[ "title" ], "left" => "center" }
   ENDIF
   o[ "tooltip" ] := { "trigger" => iif( lRound, "item", "axis" ) }
   lLegend := iif( HB_ISLOGICAL( hSpec[ "legend" ] ), hSpec[ "legend" ], ( lRound .OR. Len( hSpec[ "series" ] ) > 1 ) )
   IF lLegend
      o[ "legend" ] := { "bottom" => 0 }
   ENDIF
   IF HB_ISARRAY( hSpec[ "colors" ] ) .AND. ! Empty( hSpec[ "colors" ] )
      o[ "color" ] := {}
      AEval( hSpec[ "colors" ], {| x | AAdd( o[ "color" ], _Chart_Color( x ) ) } )
   ENDIF

   IF lRound
      aData := {}
      IF ! Empty( hSpec[ "series" ] )
         FOR i := 1 TO Len( hSpec[ "series" ][ 1 ][ 2 ] )
            AAdd( aData, { "name" => iif( i <= Len( aCat ), hb_CStr( aCat[ i ] ), hb_ntos( i ) ), "value" => hSpec[ "series" ][ 1 ][ 2 ][ i ] } )
         NEXT
      ENDIF
      hS := { "type" => iif( cType == "funnel", "funnel", "pie" ), "data" => aData, ;
              "name" => iif( Empty( hSpec[ "series" ] ), "", hSpec[ "series" ][ 1 ][ 1 ] ), ;
              "label" => { "show" => .T., "formatter" => iif( hSpec[ "labels" ], "{b}" + Chr( 10 ) + "{d}%", "{b}" ) } }
      DO CASE
      CASE cType == "pie"
         hS[ "radius" ] := "56%"
      CASE cType == "doughnut"
         hS[ "radius" ] := { "34%", "56%" }
      CASE cType == "funnel"
         hS[ "label" ][ "formatter" ] := iif( hSpec[ "labels" ], "{b}: {c}", "{b}" )
         hS[ "top" ] := iif( Empty( hSpec[ "title" ] ), 20, 50 )
         hS[ "bottom" ] := iif( lLegend, 40, 20 )
      ENDCASE
      IF cType != "funnel"
         hS[ "center" ] := { "50%", iif( Empty( hSpec[ "title" ] ), "48%", "54%" ) }
      ENDIF
      AAdd( aS, hS )
   ELSE
      o[ "grid" ] := { "containLabel" => .T., "left" => 16, "right" => 24, ;
                       "top" => iif( Empty( hSpec[ "title" ] ), 24, 56 ), "bottom" => iif( lLegend, 40, 16 ) }
      IF lHoriz
         o[ "yAxis" ] := { "type" => "category", "data" => aCat }
         o[ "xAxis" ] := { "type" => "value" }
      ELSE
         o[ "xAxis" ] := { "type" => "category", "data" => aCat, "boundaryGap" => ( cType $ "column,points" ) }
         o[ "yAxis" ] := { "type" => "value" }
      ENDIF
      FOR EACH s IN hSpec[ "series" ]
         hS := { "name" => s[ 1 ], "data" => s[ 2 ] }
         SWITCH cType
         CASE "column"
         CASE "bar"    ; hS[ "type" ] := "bar"     ; EXIT
         CASE "line"   ; hS[ "type" ] := "line"    ; EXIT
         CASE "area"   ; hS[ "type" ] := "line"    ; hS[ "areaStyle" ] := { => } ; EXIT
         CASE "points" ; hS[ "type" ] := "scatter" ; hS[ "symbolSize" ] := 10 ; EXIT
         ENDSWITCH
         IF hSpec[ "stacked" ]
            hS[ "stack" ] := "total"
         ENDIF
         IF hSpec[ "labels" ]
            hS[ "label" ] := { "show" => .T., "position" => iif( hSpec[ "stacked" ], "inside", iif( lHoriz, "right", "top" ) ) }
         ENDIF
         AAdd( aS, hS )
      NEXT
   ENDIF
   o[ "series" ] := aS
   RETURN o

/* hmgChart.set( option, extra ) */
STATIC FUNCTION _Chart_Script( hSpec )
   LOCAL cJson := hb_jsonEncode( _Chart_Option( hSpec ) )
   RETURN "hmgChart.set(" + cJson + "," + iif( Empty( hSpec[ "option" ] ), "null", hSpec[ "option" ] ) + ")"

STATIC PROCEDURE _Chart_Push( hSpec )
   LOCAL i := hSpec[ "index" ]
   IF hSpec[ "loaded" ] .AND. i > 0 .AND. ! _HMG_SYSDATA [ HMG_CTL_DELETED ] [ i ]
      HMG_WEBVIEW_EXECSCRIPT( _HMG_SYSDATA [ HMG_CTL_HANDLE ] [ i ], _Chart_Script( hSpec ), 0 )
   ENDIF
   RETURN

/* ---- events ---------------------------------------------------------------------- */

/* hmg.post() from the chart page: "ready" (draw now) and "click" (ON CLICK) */
STATIC PROCEDURE _Chart_Message( hSpec )
   LOCAL hEv := HMG_WebViewData(), xVal
   IF ! HB_ISHASH( hEv ) .OR. ! hb_HGetDef( hEv, "trusted", .F. )
      RETURN
   ENDIF
   xVal := hb_HGetDef( hEv, "value", NIL )
   IF ! HB_ISHASH( xVal )
      RETURN
   ENDIF
   SWITCH hb_HGetDef( xVal, "chart", "" )
   CASE "ready"
      hSpec[ "loaded" ] := .T.
      _Chart_Push( hSpec )
      EXIT
   CASE "click"
      IF HB_ISBLOCK( hSpec[ "onclick" ] )
         s_hClick := hb_HGetDef( xVal, "data", NIL )
         BEGIN SEQUENCE
            Eval( hSpec[ "onclick" ] )
         ALWAYS
            s_hClick := NIL
         END SEQUENCE
      ENDIF
      EXIT
   ENDSWITCH
   RETURN

/* ---- properties and methods (called through the WEBVIEW hooks) -------------------- */

STATIC FUNCTION _Chart_Is( i )
   LOCAL h := _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [ i ]
   RETURN _HMG_SYSDATA [ HMG_CTL_TYPE ] [ i ] == "WEBVIEW" .AND. HB_ISHASH( h ) .AND. hb_HHasKey( h, "chart" )

STATIC FUNCTION _Chart_Hook( cOp, i, cName, x1, x2, xData )
   LOCAL hSpec := _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [ i ] [ "chart" ]
   DO CASE
   CASE cOp == "GET"
      SWITCH cName
      CASE "CHARTTYPE"   ; xData := hSpec[ "type" ]       ; RETURN .T.
      CASE "CHARTTITLE"  ; xData := hSpec[ "title" ]      ; RETURN .T.
      CASE "CATEGORIES"  ; xData := hSpec[ "categories" ] ; RETURN .T.
      CASE "SERIES"      ; xData := hSpec[ "series" ]     ; RETURN .T.
      CASE "CHARTOPTION" ; xData := hSpec[ "option" ]     ; RETURN .T.
      CASE "LOADED"      ; xData := hSpec[ "loaded" ]     ; RETURN .T.
      ENDSWITCH
   CASE cOp == "SET"
      SWITCH cName
      CASE "CHARTTYPE"   ; hSpec[ "type" ] := _Chart_Type( x1 )                       ; EXIT
      CASE "CHARTTITLE"  ; hSpec[ "title" ] := hb_defaultValue( x1, "" )              ; EXIT
      CASE "CATEGORIES"  ; hSpec[ "categories" ] := iif( HB_ISARRAY( x1 ), x1, {} )   ; EXIT
      CASE "SERIES"      ; hSpec[ "series" ] := _Chart_Series( x1 )                   ; EXIT
      CASE "CHARTOPTION" ; hSpec[ "option" ] := iif( HB_ISSTRING( x1 ), x1, "" )      ; EXIT
      OTHERWISE
         RETURN .F.
      ENDSWITCH
      _Chart_Push( hSpec )
      RETURN .T.
   CASE cOp == "DO"
      SWITCH cName
      CASE "REFRESH"
         _Chart_Push( hSpec )
         RETURN .T.
      CASE "SAVEIMAGE"
         _Chart_SaveImage( i, x1, x2 )
         RETURN .T.
      ENDSWITCH
   ENDCASE
   RETURN .F.

STATIC FUNCTION _Chart_SaveImage( i, cFile, nScale )
   LOCAL hState := _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [ i ], hSpec := hState[ "chart" ]
   LOCAL nStart := hb_MilliSeconds(), lDone := .F., cData := NIL, nId, nPos

   IF ! HB_ISSTRING( cFile ) .OR. Empty( cFile )
      RETURN .F.
   ENDIF
   DO WHILE ! hSpec[ "loaded" ] .AND. hb_MilliSeconds() - nStart < 15000   // page not drawn yet
      DO EVENTS
      hb_idleSleep( 0.02 )
   ENDDO
   IF ! hSpec[ "loaded" ]
      RETURN .F.
   ENDIF
   nId := ++hState[ "seq" ]
   hState[ "scripts" ][ nId ] := {| x, lOk | cData := iif( lOk, x, NIL ), lDone := .T. }
   HMG_WEBVIEW_EXECSCRIPT( _HMG_SYSDATA [ HMG_CTL_HANDLE ] [ i ], "hmgChart.png(" + hb_ntos( hb_defaultValue( nScale, 2 ) ) + ")", nId )
   DO WHILE ! lDone .AND. hb_MilliSeconds() - nStart < 15000
      DO EVENTS
      hb_idleSleep( 0.02 )
   ENDDO
   IF HB_ISSTRING( cData ) .AND. ( nPos := At( "base64,", cData ) ) > 0
      RETURN hb_MemoWrit( cFile, hb_base64Decode( SubStr( cData, nPos + 7 ) ) )
   ENDIF
   RETURN .F.
