/*
 * Unit test for the GraphPlus class on Apache ECharts (SOURCE\h_graphplus.prg, PHASE4-DESIGN.md 7):
 * the GraphPlus interface (SETGET, GridData, SwitchRowsToColumns, Draw/Bitmap/Save) and the
 * ECharts option of all 15 GT_ types; Draw() renders off screen, Show() into a CHART control.
 * Synthetic data. Without the WebView2 runtime only the option checks run.
 */
#include "hmg.ch"
#include "GraphPlus.ch"

STATIC s_nPass := 0, s_nFail := 0
STATIC s_nStage := 0

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "graphplus: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 700 HEIGHT 500 TITLE "graphplus" MAIN NOSHOW ON INIT Start()
      @ 10, 10 GRID Grd_1 WIDTH 300 HEIGHT 120 HEADERS { "Item", "Q1", "Q2", "Q3" } WIDTHS { 80, 60, 60, 60 } ;
         ITEMS { { "Rice", "10", "20", "30" }, { "Wheat", "5", "15", "25" } }
      @ 140, 10 CHART Ch_1 WIDTH 600 HEIGHT 320
      DEFINE TIMER Tmr_Step INTERVAL 200 ACTION Step()
      DEFINE TIMER Tmr_Timeout INTERVAL 90000 ACTION Finish( "timeout at stage " + hb_ntos( s_nStage ) )
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC FUNCTION NewGraph( nType )
   LOCAL o := GraphPlus():New()
   WITH OBJECT o
      :GraphData  := { { 14, 20, 12, 25 }, { 8, 20, 15, 5 }, { 12, -8, 10, 15 } }
      :Legends    := { "S1", "S2", "S3" }
      :Categories := { "Jan", "Feb", "Mar", "Apr" }
      :Title      := "T" + hb_ntos( nType )
      :GraphType  := nType
   ENDWITH
RETURN o

STATIC FUNCTION Opt( o )
   LOCAL h := NIL
   hb_jsonDecode( o:Option(), @h )
RETURN iif( HB_ISHASH( h ), h, { => } )

STATIC FUNCTION SType( h, n )
RETURN iif( hb_HHasKey( h, "series" ) .AND. Len( h[ "series" ] ) >= hb_defaultValue( n, 1 ), h[ "series" ][ hb_defaultValue( n, 1 ) ][ "type" ], "" )

STATIC PROCEDURE Start()
   LOCAL o, h, a, i
   LOCAL aRows := { { "Material", "Core", "Graphite", 400 }, { "Material", "Core", "Clay", 200 }, ;
                    { "Material", "Packing", "Board", 100 }, { "Labour", "Skilled", "Foreman", 150 } }

   // the GraphPlus interface
   o := NewGraph( GT_COLUMNS )
   Check( "SETGET get",        o:Title == "T1" .AND. o:GraphType == GT_COLUMNS .AND. Len( o:Legends ) == 3 )
   o:GraphData := { 1, 2, 3 }
   Check( "1D data -> one row", Len( o:GraphData ) == 1 .AND. Len( o:GraphData[ 1 ] ) == 3 )
   o := NewGraph( GT_COLUMNS )
   o:SwitchRowsToColumns()
   Check( "SwitchRowsToColumns", Len( o:aData ) == 4 .AND. Len( o:aData[ 1 ] ) == 3 .AND. o:aData[ 2 ][ 3 ] == -8 .AND. ;
                                 o:Legends[ 1 ] == "Jan" .AND. o:Categories[ 3 ] == "S3" )
   o := GraphPlus():New()
   o:GridData( "Win_1", "Grd_1" )
   Check( "GridData",          Len( o:aData ) == 2 .AND. o:aData[ 2 ][ 3 ] == 25 .AND. o:Legends[ 2 ] == "Wheat" .AND. ;
                               Len( o:Categories ) == 3 .AND. o:Categories[ 1 ] == "Q1" )

   // the ECharts option of every type
   h := Opt( NewGraph( GT_COLUMNS ) )
   Check( "columns",           SType( h ) == "bar" .AND. Len( h[ "series" ] ) == 3 .AND. h[ "xAxis" ][ "type" ] == "category" .AND. h[ "title" ][ "text" ] == "T1" )
   h := Opt( NewGraph( GT_BAR ) )
   Check( "bar (horizontal)",  SType( h ) == "bar" .AND. h[ "yAxis" ][ "type" ] == "category" .AND. h[ "xAxis" ][ "type" ] == "value" )
   Check( "line",              SType( Opt( NewGraph( GT_LINE ) ) ) == "line" )
   Check( "points",            SType( Opt( NewGraph( GT_POINTS ) ) ) == "scatter" )
   h := Opt( NewGraph( GT_AREA ) )
   Check( "area",              SType( h ) == "line" .AND. hb_HHasKey( h[ "series" ][ 1 ], "areaStyle" ) )
   h := Opt( NewGraph( GT_STACKEDCOLUMN ) )
   Check( "stacked column",    SType( h ) == "bar" .AND. h[ "series" ][ 2 ][ "stack" ] == "total" .AND. h[ "xAxis" ][ "type" ] == "category" )
   h := Opt( NewGraph( GT_STACKEDBAR ) )
   Check( "stacked bar",       h[ "series" ][ 3 ][ "stack" ] == "total" .AND. h[ "yAxis" ][ "type" ] == "category" )
   o := NewGraph( GT_PIE )
   o:GraphData := { 50, 30, 20 }
   o:Legends := { "A", "B", "C" }
   h := Opt( o )
   Check( "pie named by legends", SType( h ) == "pie" .AND. h[ "series" ][ 1 ][ "data" ][ 2 ][ "name" ] == "B" .AND. h[ "series" ][ 1 ][ "data" ][ 2 ][ "value" ] == 30 )
   o := NewGraph( GT_FUNNEL )
   o:GraphData := { 80, 60, 40 }
   o:Categories := { "Seen", "Tried", "Bought" }
   h := Opt( o )
   Check( "funnel",            SType( h ) == "funnel" .AND. h[ "series" ][ 1 ][ "data" ][ 3 ][ "name" ] == "Bought" )
   h := Opt( NewGraph( GT_DOUGHNUT ) )
   Check( "doughnut: ring per category", Len( h[ "series" ] ) == 4 .AND. SType( h, 4 ) == "pie" .AND. ;
                                         h[ "series" ][ 2 ][ "name" ] == "Feb" .AND. Len( h[ "series" ][ 2 ][ "data" ] ) == 3 )
   o := NewGraph( GT_SCATTERXY )
   a := { {}, {} }
   FOR i := -5 TO 5
      AAdd( a[ 1 ], i )
      AAdd( a[ 2 ], i * i )
   NEXT
   o:GraphData := a
   o:ScatterLine := .T.
   h := Opt( o )
   Check( "scatter XY",        SType( h ) == "line" .AND. h[ "xAxis" ][ "type" ] == "value" .AND. Len( h[ "series" ][ 1 ][ "data" ] ) == 11 .AND. ;
                               h[ "series" ][ 1 ][ "data" ][ 1 ][ 2 ] == 25 )
   o := NewGraph( GT_SUNBURST )
   o:GraphData := aRows
   h := Opt( o )
   Check( "sunburst tree",     SType( h ) == "sunburst" .AND. Len( h[ "series" ][ 1 ][ "data" ] ) == 2 .AND. ;
                               h[ "series" ][ 1 ][ "data" ][ 1 ][ "name" ] == "Material" .AND. Len( h[ "series" ][ 1 ][ "data" ][ 1 ][ "children" ] ) == 2 .AND. ;
                               h[ "series" ][ 1 ][ "data" ][ 1 ][ "children" ][ 1 ][ "children" ][ 2 ][ "value" ] == 200 )
   o:GraphType := GT_TREEMAP
   Check( "treemap",           SType( Opt( o ) ) == "treemap" )
   o := NewGraph( GT_WATERFALL )
   o:GraphData := { 100, -30, 50, -20, 100 }
   o:TotalItems := { 1, 5 }
   o:Categories := { "Open", "A", "B", "C", "Close" }
   h := Opt( o )
   Check( "waterfall boxes",   SType( h ) == "candlestick" .AND. ;
                               ValToPrg( h[ "series" ][ 1 ][ "data" ][ 2 ][ "value" ] ) == ValToPrg( { 100, 70, 70, 100 } ) .AND. ;
                               ValToPrg( h[ "series" ][ 1 ][ "data" ][ 5 ][ "value" ] ) == ValToPrg( { 0, 100, 0, 100 } ) )
   o := NewGraph( GT_BUBBLE )
   o:GraphData := { { 1, 5, 20 }, { 2, 6, 45 }, { 3, 9, 10 } }
   o:Legends := { "P1", "P2", "P3" }
   h := Opt( o )
   Check( "bubbles",           Len( h[ "series" ] ) == 3 .AND. SType( h, 2 ) == "scatter" .AND. h[ "series" ][ 2 ][ "name" ] == "P2" .AND. ;
                               h[ "series" ][ 2 ][ "symbolSize" ] > h[ "series" ][ 3 ][ "symbolSize" ] )
   o := NewGraph( GT_COLUMNS )
   o:ShowLegends := .T.
   o:LegendPos := LEGEND_ON_RIGHT
   o:ColorTheme := THEME_3
   h := Opt( o )
   Check( "legend right, theme", h[ "legend" ][ "orient" ] == "vertical" .AND. Lower( h[ "color" ][ 1 ] ) == "#ed7d31" )
   o:GraphColors := { { 255, 0, 0 }, { 0, 255, 0 }, { 0, 0, 255 } }
   Check( "GraphColors",       Lower( Opt( o )[ "color" ][ 3 ] ) == "#0000ff" )

   IF Empty( HMG_WebViewVersion() )
      OutStd( "graphplus: rendering SKIPPED - no WebView2 runtime" + hb_eol() )
      Finish( "" )
   ENDIF
   s_nStage := 1
RETURN

STATIC PROCEDURE Step()
   LOCAL o, cFile, cPng, hBmp, hS
   SWITCH s_nStage
   CASE 1   // Draw: an off-screen bitmap of exactly Width x Height, as GraphPlus made it
      Win_1.Tmr_Step.Enabled := .F.
      o := NewGraph( GT_STACKEDCOLUMN )
      o:Width := 640
      o:Height := 360
      o:ShowLegends := .T.
      o:ShowLabels := .T.
      o:Draw()
      Check( "Draw -> bitmap",     ! Empty( o:Bitmap() ) )
      Check( "bitmap size",        ! Empty( o:Bitmap() ) .AND. BT_BitmapWidth( o:Bitmap() ) == 640 .AND. BT_BitmapHeight( o:Bitmap() ) == 360 )
      hBmp := o:Bitmap( 320, 180 )
      Check( "Bitmap( w, h )",     ! Empty( hBmp ) .AND. BT_BitmapWidth( hBmp ) == 320 )
      cFile := hb_DirSepAdd( hb_DirTemp() ) + "hmg_gp_test_" + hb_ntos( hb_RandomInt( 100000, 999999 ) ) + ".png"
      o:Save( cFile )
      cPng := hb_MemoRead( cFile )
      Check( "Save PNG",           hb_LeftEq( cPng, hb_BChar( 137 ) + "PNG" ) )
      FErase( cFile )
      o := NewGraph( GT_SUNBURST )
      o:GraphData := { { "A", "x", 10 }, { "A", "y", 20 }, { "B", "z", 15 } }
      o:Width := 400
      o:Height := 400
      o:Draw()
      Check( "Draw sunburst",      ! Empty( o:Bitmap() ) .AND. BT_BitmapHeight( o:Bitmap() ) == 400 )
      // interactive: the same chart in a CHART control
      o := NewGraph( GT_WATERFALL )
      o:GraphData := { 100, -30, 50, -20, 100 }
      o:TotalItems := { 1, 5 }
      o:Show( "Win_1", "Ch_1" )
      Check( "Show sets CUSTOM",   Win_1.Ch_1.ChartType == "custom" .AND. '"candlestick"' $ Win_1.Ch_1.ChartOption )
      s_nStage := 2
      Win_1.Tmr_Step.Enabled := .T.
      EXIT
   CASE 2   // the CHART page drew it
      IF Win_1.Ch_1.Loaded
         Win_1.Ch_1.ExecuteScript( "hmgChart.chart.getOption().series[0].type", ;
            {| x, lOk | hS := x, Check( "Show drawn", lOk .AND. hS == "candlestick" ), Finish( "" ) } )
         s_nStage := 3
      ENDIF
      EXIT
   ENDSWITCH
RETURN

STATIC PROCEDURE Finish( cWhy )
   IF ! Empty( cWhy )
      s_nFail++
      OutStd( "graphplus: FAIL " + cWhy + hb_eol() )
   ENDIF
   OutStd( "graphplus: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "graphplus: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
