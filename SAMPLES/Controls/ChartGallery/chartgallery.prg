/*
 * HMG5 sample: a gallery of every Apache ECharts chart type with the CHART control.
 *
 * One tab per chart type, each with an example of its own. The simple types use
 * the CHART clauses (TYPE LINE, AREA, COLUMN, BAR, PIE, DOUGHNUT, FUNNEL). For the
 * others, TYPE CUSTOM takes the whole ECharts option through OPTION: this sample
 * builds it as a Harbour hash and turns it into JSON with hb_jsonEncode(). The geo
 * map and the custom series need JavaScript (a map shape, a drawing function), so
 * they are given to the chart with ExecuteScript once it has loaded.
 *
 * Click any bar, slice, point or node: the status bar shows what was clicked.
 * Needs the Microsoft Edge WebView2 Runtime (part of Windows 10 and 11). Works
 * offline: ECharts is inside the HMG library.
 *
 * ECharts option reference: https://echarts.apache.org/en/option.html
 */
#include "hmg.ch"

#define CH_ROW   40
#define CH_COL   10
#define CH_W     1206
#define CH_H     640
#define TXT_ROW  688

STATIC s_nSeed := 20261113
STATIC s_lMapDone := .F., s_lCustomDone := .F.

FUNCTION Main()
   LOCAL aMonths := { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
   LOCAL aDays   := { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" }

   IF Empty( HMG_WebViewVersion() )
      MsgStop( "This sample needs the Microsoft Edge WebView2 Runtime." )
      RETURN NIL
   ENDIF

   DEFINE WINDOW Win_Main AT 0, 0 WIDTH 1250 HEIGHT 790 TITLE "HMG5 Chart Gallery - every Apache ECharts chart type" ;
      MAIN NOMAXIMIZE NOSIZE

      DEFINE TAB Tab_Charts AT 6, 6 WIDTH 1230 HEIGHT 726

         PAGE "Line"
            @ CH_ROW, CH_COL CHART Ch_Line WIDTH 598 HEIGHT CH_H TYPE LINE ;
               TITLE "Average temperature (°C)" CATEGORIES aMonths ;
               SERIES { { "Chennai", { 25, 26, 28, 31, 33, 32, 31, 30, 30, 28, 26, 25 } }, ;
                        { "Delhi",   { 14, 17, 23, 29, 33, 34, 31, 30, 29, 26, 20, 15 } }, ;
                        { "Shimla",  {  5,  7, 11, 15, 18, 19, 18, 17, 16, 13, 10,  7 } } } ;
               ON CLICK ShowClick()
            @ CH_ROW, CH_COL + 608 CHART Ch_Area WIDTH 598 HEIGHT CH_H TYPE AREA STACKED ;
               TITLE "Visitors by channel" CATEGORIES aDays ;
               SERIES { { "Search",  { 820, 932, 901, 934, 1290, 1330, 1320 } }, ;
                        { "Direct",  { 320, 332, 301, 334,  390,  330,  320 } }, ;
                        { "Email",   { 120, 132, 101, 134,   90,  230,  210 } }, ;
                        { "Social",  { 220, 182, 191, 234,  290,  330,  310 } } } ;
               ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Line WIDTH CH_W HEIGHT 40 ;
               VALUE "line series. Left: TYPE LINE. Right: TYPE AREA STACKED (a line series with areaStyle and a stack)."
         END PAGE

         PAGE "Bar"
            @ CH_ROW, CH_COL CHART Ch_Column WIDTH 598 HEIGHT CH_H TYPE COLUMN STACKED LABELS ;
               TITLE "Sales by zone (₹ lakh)" CATEGORIES { "Q1", "Q2", "Q3", "Q4" } ;
               SERIES { { "South", { 120, 132, 151, 174 } }, { "West", { 90, 110, 98, 130 } }, ;
                        { "North", { 70, 82, 95, 110 } }, { "East", { 40, 52, 61, 70 } } } ;
               ON CLICK ShowClick()
            @ CH_ROW, CH_COL + 608 CHART Ch_Bar WIDTH 598 HEIGHT CH_H TYPE BAR LABELS ;
               TITLE "Top products (units)" ;
               CATEGORIES { "Notebook", "Pen set", "Calculator", "Stapler", "Diary", "Marker", "File box", "Ruler" } ;
               SERIES { { "Units", { 1820, 1534, 1290, 1104, 980, 890, 760, 640 } } } ;
               COLORS { { 91, 143, 249 } } ;
               ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Bar WIDTH CH_W HEIGHT 40 ;
               VALUE "bar series. Left: TYPE COLUMN STACKED LABELS. Right: TYPE BAR (horizontal) with COLORS."
         END PAGE

         PAGE "Pie"
            @ CH_ROW, CH_COL CHART Ch_Pie WIDTH 398 HEIGHT CH_H TYPE PIE LABELS ;
               TITLE "Market share" CATEGORIES { "HMG", "Harbour", "xHarbour", "Clipper", "Others" } ;
               SERIES { 42, 26, 14, 10, 8 } ON CLICK ShowClick()
            @ CH_ROW, CH_COL + 404 CHART Ch_Doughnut WIDTH 398 HEIGHT CH_H TYPE DOUGHNUT LABELS ;
               TITLE "Monthly expenses" CATEGORIES { "Rent", "Food", "Travel", "School", "Health", "Savings" } ;
               SERIES { 18000, 12000, 5000, 7000, 3000, 15000 } ON CLICK ShowClick()
            @ CH_ROW, CH_COL + 808 CHART Ch_Rose WIDTH 398 HEIGHT CH_H TYPE CUSTOM ;
               OPTION OptRose() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Pie WIDTH CH_W HEIGHT 40 ;
               VALUE "pie series. TYPE PIE, TYPE DOUGHNUT and, with TYPE CUSTOM + OPTION, a Nightingale rose (roseType)."
         END PAGE

         PAGE "Scatter"
            @ CH_ROW, CH_COL CHART Ch_Scatter WIDTH 598 HEIGHT CH_H TYPE CUSTOM OPTION OptScatter() ON CLICK ShowClick()
            @ CH_ROW, CH_COL + 608 CHART Ch_Bubble WIDTH 598 HEIGHT CH_H TYPE CUSTOM OPTION OptBubble() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Scatter WIDTH CH_W HEIGHT 40 ;
               VALUE "scatter and effectScatter series on two value axes. Right: the bubble size is a third value (symbolSize)."
         END PAGE

         PAGE "Radar"
            @ CH_ROW, CH_COL CHART Ch_Radar WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptRadar() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Radar WIDTH CH_W HEIGHT 40 ;
               VALUE "radar series: three branches scored on six measures (radar.indicator gives each axis its name and maximum)."
         END PAGE

         PAGE "Candlestick"
            @ CH_ROW, CH_COL CHART Ch_Candle WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptCandle() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Candle WIDTH CH_W HEIGHT 40 ;
               VALUE "candlestick series (open, close, low, high) with 5- and 20-day moving averages and a dataZoom slider. Drag the slider."
         END PAGE

         PAGE "Boxplot"
            @ CH_ROW, CH_COL CHART Ch_Box WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptBoxplot() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Box WIDTH CH_W HEIGHT 40 ;
               VALUE "boxplot series (minimum, lower quartile, median, upper quartile, maximum) and the outliers as a scatter series."
         END PAGE

         PAGE "Heatmap"
            @ CH_ROW, CH_COL CHART Ch_Heat WIDTH 520 HEIGHT CH_H TYPE CUSTOM OPTION OptHeatmap() ON CLICK ShowClick()
            @ CH_ROW, CH_COL + 530 CHART Ch_Calendar WIDTH 676 HEIGHT CH_H TYPE CUSTOM OPTION OptCalendar() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Heat WIDTH CH_W HEIGHT 40 ;
               VALUE "heatmap series with a visualMap. Left: on a weekday x hour grid. Right: on a calendar (one cell a day of 2026)."
         END PAGE

         PAGE "Tree"
            @ CH_ROW, CH_COL CHART Ch_Tree WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptTree() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Tree WIDTH CH_W HEIGHT 40 ;
               VALUE "tree series, top to bottom: an organisation chart. Click a node to fold or unfold it."
         END PAGE

         PAGE "Treemap"
            @ CH_ROW, CH_COL CHART Ch_Treemap WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptTreemap() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Treemap WIDTH CH_W HEIGHT 40 ;
               VALUE "treemap series: a year's household spending; each area is proportional to its amount. Click a block to zoom in."
         END PAGE

         PAGE "Sunburst"
            @ CH_ROW, CH_COL CHART Ch_Sunburst WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptSunburst() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Sunburst WIDTH CH_W HEIGHT 40 ;
               VALUE "sunburst series: sales by zone, state and city in rings. Click a ring to make it the centre."
         END PAGE

         PAGE "Graph"
            @ CH_ROW, CH_COL CHART Ch_Graph WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptGraph() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Graph WIDTH CH_W HEIGHT 40 ;
               VALUE "graph series with a force layout: what an HMG5 program is made of. Drag the nodes; the wheel zooms."
         END PAGE

         PAGE "Sankey"
            @ CH_ROW, CH_COL CHART Ch_Sankey WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptSankey() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Sankey WIDTH CH_W HEIGHT 40 ;
               VALUE "sankey series: where a family's monthly income goes. The width of each band is the amount."
         END PAGE

         PAGE "Chord"
            @ CH_ROW, CH_COL CHART Ch_Chord WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptChord() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Chord WIDTH CH_W HEIGHT 40 ;
               VALUE "chord series (new in ECharts 6): goods sent between five branches. Each ribbon joins two branches."
         END PAGE

         PAGE "Funnel"
            @ CH_ROW, CH_COL CHART Ch_Funnel WIDTH CH_W HEIGHT CH_H TYPE FUNNEL LABELS ;
               TITLE "Sales pipeline" ;
               CATEGORIES { "Enquiries", "Demos", "Quotations", "Negotiation", "Orders" } ;
               SERIES { 1200, 640, 380, 190, 120 } ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Funnel WIDTH CH_W HEIGHT 40 ;
               VALUE "funnel series: TYPE FUNNEL LABELS."
         END PAGE

         PAGE "Gauge"
            @ CH_ROW, CH_COL CHART Ch_Gauge WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptGauge() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Gauge WIDTH CH_W HEIGHT 40 ;
               VALUE "gauge series: three gauges in one chart, each with its own centre, range and style."
         END PAGE

         PAGE "Pictorial"
            @ CH_ROW, CH_COL CHART Ch_Pictorial WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptPictorial() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Pictorial WIDTH CH_W HEIGHT 40 ;
               VALUE "pictorialBar series: bars drawn with repeated symbols (symbolRepeat) instead of rectangles."
         END PAGE

         PAGE "ThemeRiver"
            @ CH_ROW, CH_COL CHART Ch_River WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptThemeRiver() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_River WIDTH CH_W HEIGHT 40 ;
               VALUE "themeRiver series on a time axis: forum posts a week by topic; each stream's width is that topic's share."
         END PAGE

         PAGE "Parallel"
            @ CH_ROW, CH_COL CHART Ch_Parallel WIDTH CH_W HEIGHT CH_H TYPE CUSTOM OPTION OptParallel() ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Parallel WIDTH CH_W HEIGHT 40 ;
               VALUE "parallel series: six laptops compared on five measures, one line each. Drag along an axis to filter."
         END PAGE

         PAGE "Map, Lines"
            @ CH_ROW, CH_COL CHART Ch_Map WIDTH CH_W HEIGHT CH_H TYPE CUSTOM ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Map WIDTH CH_W HEIGHT 40 ;
               VALUE "map, lines and effectScatter on a geo component. The map shape (GeoJSON) is registered with echarts.registerMap() through ExecuteScript."
         END PAGE

         PAGE "Custom"
            @ CH_ROW, CH_COL CHART Ch_Custom WIDTH CH_W HEIGHT CH_H TYPE CUSTOM ON CLICK ShowClick()
            @ TXT_ROW, CH_COL LABEL Lbl_Custom WIDTH CH_W HEIGHT 40 ;
               VALUE "custom series: a project plan drawn by a JavaScript renderItem function, given with ExecuteScript."
         END PAGE

      END TAB

      DEFINE STATUSBAR
         STATUSITEM "Click a chart element to see its data here"
         STATUSITEM "ECharts 6 - WebView2 " + HMG_WebViewVersion() WIDTH 260
      END STATUSBAR

      // the map and the custom chart get their JavaScript once their page has loaded
      DEFINE TIMER Tmr_Script INTERVAL 250 ACTION LateScripts()

   END WINDOW

   Win_Main.Center
   Win_Main.Activate
RETURN NIL

/* ---- clicks ------------------------------------------------------------------------ */

STATIC PROCEDURE ShowClick()
   LOCAL h := HMG_ChartClicked(), x
   IF HB_ISHASH( h )
      x := hb_HGetDef( h, "value", "" )
      Win_Main.StatusBar.Item( 1 ) := "Clicked: " + ;
         iif( Empty( hb_HGetDef( h, "series", "" ) ), "", hb_HGetDef( h, "series", "" ) + " / " ) + ;
         hb_HGetDef( h, "category", "" ) + " = " + iif( HB_ISARRAY( x ) .OR. HB_ISHASH( x ), hb_jsonEncode( x ), hb_ValToStr( x ) )
   ENDIF
RETURN

/* ---- the map and the custom series: JavaScript, once the page is up ----------------- */

STATIC PROCEDURE LateScripts()
   IF ! s_lMapDone .AND. Win_Main.Ch_Map.Loaded
      s_lMapDone := .T.
      Win_Main.Ch_Map.ExecuteScript( MapScript() )
   ENDIF
   IF ! s_lCustomDone .AND. Win_Main.Ch_Custom.Loaded
      s_lCustomDone := .T.
      Win_Main.Ch_Custom.ExecuteScript( GanttScript() )
   ENDIF
   IF s_lMapDone .AND. s_lCustomDone
      Win_Main.Tmr_Script.Enabled := .F.
   ENDIF
RETURN

/* ---- options (ECharts JSON built from Harbour hashes) ------------------------------ */

STATIC FUNCTION J( h )
RETURN hb_jsonEncode( h )

STATIC FUNCTION Ttl( cText, cSub )
   LOCAL h := { "text" => cText, "left" => "center" }
   IF ! Empty( cSub )
      h[ "subtext" ] := cSub
   ENDIF
RETURN h

STATIC FUNCTION OptRose()
RETURN J( { "title" => Ttl( "Visitors by city", "roseType: area" ), ;
            "tooltip" => { "trigger" => "item" }, ;
            "legend" => { "bottom" => 0 }, ;
            "series" => { { "type" => "pie", "roseType" => "area", "radius" => { "12%", "62%" }, "center" => { "50%", "52%" }, ;
                            "itemStyle" => { "borderRadius" => 6 }, ;
                            "data" => { { "name" => "Chennai",   "value" => 40 }, { "name" => "Mumbai", "value" => 38 }, ;
                                        { "name" => "Bengaluru", "value" => 32 }, { "name" => "Delhi",  "value" => 30 }, ;
                                        { "name" => "Kolkata",   "value" => 28 }, { "name" => "Pune",   "value" => 26 }, ;
                                        { "name" => "Madurai",   "value" => 22 }, { "name" => "Kochi",  "value" => 18 } } } } } )

STATIC FUNCTION OptScatter()
   LOCAL aBoys := {}, aGirls := {}, i
   FOR i := 1 TO 60
      AAdd( aBoys,  { Round( 150 + Rnd() * 35, 1 ), Round( 42 + Rnd() * 35, 1 ) } )
      AAdd( aGirls, { Round( 145 + Rnd() * 30, 1 ), Round( 38 + Rnd() * 28, 1 ) } )
   NEXT
RETURN J( { "title" => Ttl( "Height and weight of 120 students" ), ;
            "tooltip" => { "trigger" => "item" }, "legend" => { "bottom" => 0 }, ;
            "grid" => { "left" => 50, "right" => 30, "top" => 60, "bottom" => 50 }, ;
            "xAxis" => { "type" => "value", "name" => "cm", "scale" => .T. }, ;
            "yAxis" => { "type" => "value", "name" => "kg", "scale" => .T. }, ;
            "series" => { { "name" => "Boys", "type" => "scatter", "symbolSize" => 9, "data" => aBoys }, ;
                          { "name" => "Girls", "type" => "scatter", "symbolSize" => 9, "data" => aGirls } } } )

STATIC FUNCTION OptBubble()
   // city: literacy %, income (₹ '000 a year), population (lakh)
   LOCAL aCity := { { "Chennai", 90, 310, 110 }, { "Coimbatore", 89, 260, 21 }, { "Madurai", 87, 190, 15 }, ;
                    { "Bengaluru", 89, 360, 130 }, { "Mysuru", 86, 210, 11 }, { "Kochi", 97, 280, 7 }, ;
                    { "Hyderabad", 83, 300, 100 }, { "Pune", 91, 320, 70 }, { "Nagpur", 92, 220, 29 } }
   LOCAL aData := {}, a
   FOR EACH a IN aCity
      AAdd( aData, { "name" => a[ 1 ], "value" => { a[ 2 ], a[ 3 ], a[ 4 ] }, "symbolSize" => Max( 12, Sqrt( a[ 4 ] ) * 5 ) } )
   NEXT
RETURN J( { "title" => Ttl( "Cities: literacy, income and population" ), ;
            "tooltip" => { "trigger" => "item" }, ;
            "grid" => { "left" => 60, "right" => 40, "top" => 60, "bottom" => 50 }, ;
            "xAxis" => { "type" => "value", "name" => "literacy %", "min" => 80, "max" => 100 }, ;
            "yAxis" => { "type" => "value", "name" => "income ₹'000", "scale" => .T. }, ;
            "series" => { { "type" => "effectScatter", "data" => aData, "rippleEffect" => { "scale" => 2.2 }, ;
                            "label" => { "show" => .T., "formatter" => "{b}", "position" => "top" } } } } )

STATIC FUNCTION OptRadar()
RETURN J( { "title" => Ttl( "Branch scorecard" ), "tooltip" => { "trigger" => "item" }, "legend" => { "bottom" => 0 }, ;
            "radar" => { "radius" => "65%", "center" => { "50%", "52%" }, ;
                         "indicator" => { { "name" => "Sales", "max" => 100 }, { "name" => "Collections", "max" => 100 }, ;
                                          { "name" => "Service", "max" => 100 }, { "name" => "Stock turns", "max" => 100 }, ;
                                          { "name" => "Staff", "max" => 100 }, { "name" => "Growth", "max" => 100 } } }, ;
            "series" => { { "type" => "radar", "areaStyle" => { "opacity" => 0.15 }, ;
                            "data" => { { "name" => "Chennai",   "value" => { 92, 78, 85, 70, 88, 76 } }, ;
                                        { "name" => "Madurai",   "value" => { 74, 90, 72, 82, 65, 91 } }, ;
                                        { "name" => "Coimbatore", "value" => { 81, 70, 93, 64, 79, 68 } } } } } } )

STATIC FUNCTION OptCandle()
   LOCAL aDates := {}, aOhlc := {}, aClose := {}, d := SToD( "20260803" ), n := 0, nPrev := 1250, nOpen, nClose, nLow, nHigh
   DO WHILE n < 80
      IF DoW( d ) != 1 .AND. DoW( d ) != 7
         nOpen  := Round( nPrev + ( Rnd() - 0.5 ) * 20, 1 )
         nClose := Round( nOpen + ( Rnd() - 0.47 ) * 45, 1 )
         nLow   := Round( Min( nOpen, nClose ) - Rnd() * 18, 1 )
         nHigh  := Round( Max( nOpen, nClose ) + Rnd() * 18, 1 )
         AAdd( aDates, IsoDate( d ) )
         AAdd( aOhlc, { nOpen, nClose, nLow, nHigh } )      // ECharts order: open, close, lowest, highest
         AAdd( aClose, nClose )
         nPrev := nClose
         n++
      ENDIF
      d++
   ENDDO
RETURN J( { "title" => Ttl( "Mahamai Textiles Ltd (sample data, ₹)" ), ;
            "tooltip" => { "trigger" => "axis", "axisPointer" => { "type" => "cross" } }, ;
            "legend" => { "top" => 30 }, ;
            "grid" => { "left" => 60, "right" => 40, "top" => 70, "bottom" => 90 }, ;
            "xAxis" => { "type" => "category", "data" => aDates, "boundaryGap" => .T. }, ;
            "yAxis" => { "type" => "value", "scale" => .T. }, ;
            "dataZoom" => { { "type" => "inside", "start" => 40, "end" => 100 }, { "type" => "slider", "start" => 40, "end" => 100, "bottom" => 30 } }, ;
            "series" => { { "name" => "Price", "type" => "candlestick", "data" => aOhlc, ;
                            "itemStyle" => { "color" => "#16a34a", "color0" => "#dc2626", "borderColor" => "#16a34a", "borderColor0" => "#dc2626" } }, ;
                          { "name" => "MA 5", "type" => "line", "data" => MovingAvg( aClose, 5 ), "smooth" => .T., "showSymbol" => .F. }, ;
                          { "name" => "MA 20", "type" => "line", "data" => MovingAvg( aClose, 20 ), "smooth" => .T., "showSymbol" => .F. } } } )

STATIC FUNCTION OptBoxplot()
RETURN J( { "title" => Ttl( "Delivery time by courier (hours)" ), "tooltip" => { "trigger" => "item" }, ;
            "grid" => { "left" => 60, "right" => 40, "top" => 60, "bottom" => 40 }, ;
            "xAxis" => { "type" => "category", "data" => { "SpeedPost", "BlueDart", "DTDC", "Delhivery", "Ecom" } }, ;
            "yAxis" => { "type" => "value", "name" => "hours" }, ;
            "series" => { { "name" => "Delivery", "type" => "boxplot", ;
                            "data" => { { 20, 34, 46, 60, 84 }, { 12, 22, 28, 36, 52 }, { 18, 30, 40, 52, 76 }, ;
                                        { 14, 24, 32, 42, 60 }, { 22, 36, 50, 64, 90 } } }, ;
                          { "name" => "Outliers", "type" => "scatter", ;
                            "data" => { { 0, 110 }, { 1, 70 }, { 1, 74 }, { 2, 98 }, { 4, 120 }, { 4, 8 } } } } } )

STATIC FUNCTION OptHeatmap()
   LOCAL aDays := { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" }, aHours := {}, aData := {}, d, h, v
   FOR h := 9 TO 21
      AAdd( aHours, hb_ntos( h ) + ":00" )
   NEXT
   FOR d := 0 TO 6
      FOR h := 0 TO 12
         v := Int( 10 + Rnd() * 40 + iif( h >= 8 .AND. h <= 11, 40, 0 ) + iif( d >= 5, 30, 0 ) )
         AAdd( aData, { h, d, v } )
      NEXT
   NEXT
RETURN J( { "title" => Ttl( "Shop footfall" ), "tooltip" => { "position" => "top" }, ;
            "grid" => { "left" => 60, "right" => 20, "top" => 60, "bottom" => 90 }, ;
            "xAxis" => { "type" => "category", "data" => aHours, "splitArea" => { "show" => .T. } }, ;
            "yAxis" => { "type" => "category", "data" => aDays, "splitArea" => { "show" => .T. } }, ;
            "visualMap" => { "min" => 0, "max" => 130, "calculable" => .T., "orient" => "horizontal", "left" => "center", "bottom" => 10 }, ;
            "series" => { { "name" => "Visitors", "type" => "heatmap", "data" => aData, "label" => { "show" => .T. } } } } )

STATIC FUNCTION OptCalendar()
   LOCAL aData := {}, d := SToD( "20260101" ), v
   DO WHILE Year( d ) == 2026
      v := Int( 20 + Rnd() * 60 + iif( DoW( d ) == 1 .OR. DoW( d ) == 7, 40, 0 ) + iif( Month( d ) >= 10, 30, 0 ) )
      AAdd( aData, { IsoDate( d ), v } )
      d++
   ENDDO
RETURN J( { "title" => Ttl( "Orders a day, 2026" ), "tooltip" => { "position" => "top" }, ;
            "visualMap" => { "min" => 0, "max" => 160, "type" => "piecewise", "orient" => "horizontal", "left" => "center", "bottom" => 20, ;
                             "inRange" => { "color" => { "#e0f2fe", "#38bdf8", "#0284c7", "#0c4a6e" } } }, ;
            "calendar" => { "range" => "2026", "top" => 110, "left" => 40, "right" => 20, "cellSize" => { "auto", 34 }, ;
                            "yearLabel" => { "show" => .F. } }, ;
            "series" => { { "type" => "heatmap", "coordinateSystem" => "calendar", "data" => aData } } } )

STATIC FUNCTION OptTree()
   LOCAL hRoot := { "name" => "Managing Director", "children" => { ;
      { "name" => "Sales", "children" => { { "name" => "South" }, { "name" => "North" }, { "name" => "Exports" } } }, ;
      { "name" => "Accounts", "children" => { { "name" => "Payables" }, { "name" => "Receivables" }, { "name" => "Tax" } } }, ;
      { "name" => "IT", "children" => { { "name" => "HMG5 apps" }, { "name" => "Network" } } }, ;
      { "name" => "Operations", "children" => { { "name" => "Purchase" }, { "name" => "Stores" }, { "name" => "Dispatch" } } }, ;
      { "name" => "HR" } } }
RETURN J( { "title" => Ttl( "Organisation" ), "tooltip" => { "trigger" => "item" }, ;
            "series" => { { "type" => "tree", "data" => { hRoot }, "orient" => "TB", ;
                            "top" => 70, "bottom" => 70, "left" => 40, "right" => 40, ;
                            "symbolSize" => 12, "initialTreeDepth" => 3, "expandAndCollapse" => .T., ;
                            "label" => { "position" => "top", "fontSize" => 13 }, ;
                            "leaves" => { "label" => { "position" => "bottom", "rotate" => 0 } } } } } )

STATIC FUNCTION Spend()
RETURN { { "name" => "Home", "children" => { { "name" => "Rent", "value" => 216000 }, { "name" => "Electricity", "value" => 30000 }, ;
                                           { "name" => "Internet", "value" => 9600 }, { "name" => "Repairs", "value" => 14000 } } }, ;
         { "name" => "Food", "children" => { { "name" => "Groceries", "value" => 96000 }, { "name" => "Vegetables", "value" => 36000 }, ;
                                           { "name" => "Eating out", "value" => 24000 } } }, ;
         { "name" => "Children", "children" => { { "name" => "School fees", "value" => 120000 }, { "name" => "Books", "value" => 12000 }, ;
                                               { "name" => "Classes", "value" => 30000 } } }, ;
         { "name" => "Travel", "children" => { { "name" => "Fuel", "value" => 42000 }, { "name" => "Train", "value" => 15000 }, ;
                                             { "name" => "Holiday", "value" => 60000 } } }, ;
         { "name" => "Health", "children" => { { "name" => "Insurance", "value" => 25000 }, { "name" => "Medicines", "value" => 11000 } } }, ;
         { "name" => "Savings", "value" => 180000 } }

STATIC FUNCTION OptTreemap()
RETURN J( { "title" => Ttl( "Household spending in a year (₹)" ), "tooltip" => { "trigger" => "item" }, ;
            "series" => { { "type" => "treemap", "name" => "All", "data" => Spend(), "top" => 60, "bottom" => 40, ;
                            "leafDepth" => 2, "roam" => .F., "label" => { "show" => .T., "formatter" => "{b}" }, ;
                            "upperLabel" => { "show" => .T., "height" => 24 }, ;
                            "levels" => { { "itemStyle" => { "borderWidth" => 0, "gapWidth" => 4 } }, ;
                                          { "itemStyle" => { "gapWidth" => 2, "borderColorSaturation" => 0.6 } } } } } } )

STATIC FUNCTION OptSunburst()
   LOCAL aData := { ;
      { "name" => "South", "children" => { ;
         { "name" => "Tamil Nadu", "children" => { { "name" => "Chennai", "value" => 48 }, { "name" => "Coimbatore", "value" => 22 }, { "name" => "Madurai", "value" => 16 } } }, ;
         { "name" => "Karnataka", "children" => { { "name" => "Bengaluru", "value" => 41 }, { "name" => "Mysuru", "value" => 9 } } }, ;
         { "name" => "Kerala", "children" => { { "name" => "Kochi", "value" => 14 }, { "name" => "Thrissur", "value" => 7 } } } } }, ;
      { "name" => "West", "children" => { ;
         { "name" => "Maharashtra", "children" => { { "name" => "Mumbai", "value" => 39 }, { "name" => "Pune", "value" => 21 } } }, ;
         { "name" => "Gujarat", "children" => { { "name" => "Ahmedabad", "value" => 18 }, { "name" => "Surat", "value" => 12 } } } } }, ;
      { "name" => "North", "children" => { ;
         { "name" => "Delhi", "children" => { { "name" => "New Delhi", "value" => 30 } } }, ;
         { "name" => "Punjab", "children" => { { "name" => "Ludhiana", "value" => 10 }, { "name" => "Amritsar", "value" => 6 } } } } } }
RETURN J( { "title" => Ttl( "Sales by zone, state and city (₹ lakh)" ), "tooltip" => { "trigger" => "item" }, ;
            "series" => { { "type" => "sunburst", "data" => aData, "radius" => { "12%", "90%" }, "center" => { "50%", "55%" }, ;
                            "sort" => "desc", "emphasis" => { "focus" => "ancestor" }, ;
                            "levels" => { { => }, { "r0" => "12%", "r" => "38%", "label" => { "rotate" => "tangential" } }, ;
                                          { "r0" => "38%", "r" => "66%", "label" => { "align" => "right" } }, ;
                                          { "r0" => "66%", "r" => "70%", "label" => { "position" => "outside", "padding" => 3 } } } } } } )

STATIC FUNCTION OptGraph()
   LOCAL aCat := { { "name" => "Your program" }, { "name" => "HMG5" }, { "name" => "Harbour" }, { "name" => "Windows" } }
   LOCAL aNodes := { ;
      Node( "myapp.exe", 0, 60 ), Node( "Forms", 0, 34 ), Node( "Reports", 0, 30 ), Node( "Data", 0, 30 ), ;
      Node( "HMG library", 1, 52 ), Node( "HFCL", 1, 30 ), Node( "WEBVIEW", 1, 32 ), Node( "CHART", 1, 32 ), Node( "IDE", 1, 36 ), ;
      Node( "Harbour VM", 2, 46 ), Node( "RDD (DBF)", 2, 30 ), Node( "hbsqlit3", 2, 26 ), Node( "hbhpdf", 2, 26 ), ;
      Node( "Win32 API", 3, 44 ), Node( "WebView2", 3, 34 ), Node( "GDI+", 3, 28 ) }
   LOCAL aLinks := { ;
      Lnk( "myapp.exe", "Forms" ), Lnk( "myapp.exe", "Reports" ), Lnk( "myapp.exe", "Data" ), Lnk( "Forms", "HMG library" ), ;
      Lnk( "Reports", "HMG library" ), Lnk( "Reports", "hbhpdf" ), Lnk( "Data", "RDD (DBF)" ), Lnk( "Data", "hbsqlit3" ), ;
      Lnk( "HMG library", "HFCL" ), Lnk( "HMG library", "WEBVIEW" ), Lnk( "WEBVIEW", "CHART" ), Lnk( "HMG library", "Harbour VM" ), ;
      Lnk( "HMG library", "Win32 API" ), Lnk( "WEBVIEW", "WebView2" ), Lnk( "HMG library", "GDI+" ), Lnk( "IDE", "HMG library" ), ;
      Lnk( "RDD (DBF)", "Harbour VM" ), Lnk( "hbsqlit3", "Harbour VM" ), Lnk( "hbhpdf", "Harbour VM" ), Lnk( "IDE", "myapp.exe" ) }
RETURN J( { "title" => Ttl( "What an HMG5 program is made of" ), "tooltip" => { => }, "legend" => { "bottom" => 0 }, ;
            "series" => { { "type" => "graph", "layout" => "force", "roam" => .T., "draggable" => .T., ;
                            "categories" => aCat, "data" => aNodes, "links" => aLinks, ;
                            "force" => { "repulsion" => 420, "edgeLength" => { 70, 150 } }, ;
                            "label" => { "show" => .T., "position" => "right" }, ;
                            "lineStyle" => { "color" => "source", "curveness" => 0.15, "opacity" => 0.7 }, ;
                            "emphasis" => { "focus" => "adjacency" } } } } )

STATIC FUNCTION Node( cName, nCat, nSize )
RETURN { "name" => cName, "category" => nCat, "symbolSize" => nSize }

STATIC FUNCTION Lnk( cFrom, cTo )
RETURN { "source" => cFrom, "target" => cTo }

STATIC FUNCTION OptSankey()
   LOCAL aNodes := {}, c
   FOR EACH c IN { "Salary", "Rent received", "Interest", "Household", "Rent", "Food", "Travel", "School", "Health", ;
                   "Savings", "Fixed deposit", "Mutual funds", "Gold" }
      AAdd( aNodes, { "name" => c } )
   NEXT
RETURN J( { "title" => Ttl( "Monthly income and where it goes (₹)" ), "tooltip" => { "trigger" => "item" }, ;
            "series" => { { "type" => "sankey", "top" => 60, "bottom" => 30, "left" => 30, "right" => 120, ;
                            "emphasis" => { "focus" => "adjacency" }, "nodeGap" => 14, ;
                            "lineStyle" => { "color" => "gradient", "curveness" => 0.5 }, ;
                            "data" => aNodes, ;
                            "links" => { Flow( "Salary", "Household", 70000 ), Flow( "Rent received", "Household", 15000 ), ;
                                         Flow( "Interest", "Household", 5000 ), ;
                                         Flow( "Household", "Rent", 18000 ), Flow( "Household", "Food", 14000 ), ;
                                         Flow( "Household", "Travel", 6000 ), Flow( "Household", "School", 10000 ), ;
                                         Flow( "Household", "Health", 4000 ), Flow( "Household", "Savings", 38000 ), ;
                                         Flow( "Savings", "Fixed deposit", 15000 ), Flow( "Savings", "Mutual funds", 18000 ), ;
                                         Flow( "Savings", "Gold", 5000 ) } } } } )

STATIC FUNCTION Flow( cFrom, cTo, nValue )
RETURN { "source" => cFrom, "target" => cTo, "value" => nValue }

STATIC FUNCTION OptChord()
   LOCAL aNames := { "Chennai", "Madurai", "Coimbatore", "Bengaluru", "Kochi" }, aNodes := {}, c
   FOR EACH c IN aNames
      AAdd( aNodes, { "name" => c } )
   NEXT
RETURN J( { "title" => Ttl( "Stock transfers between branches (cartons a month)" ), "tooltip" => { "trigger" => "item" }, ;
            "legend" => { "bottom" => 0 }, ;
            "series" => { { "type" => "chord", "radius" => { "62%", "68%" }, "center" => { "50%", "53%" }, ;
                            "clockwise" => .F., "label" => { "show" => .T. }, ;
                            "lineStyle" => { "color" => "target", "opacity" => 0.6 }, ;
                            "emphasis" => { "focus" => "adjacency" }, ;
                            "data" => aNodes, ;
                            "links" => { Flow( "Chennai", "Madurai", 40 ), Flow( "Chennai", "Coimbatore", 30 ), ;
                                         Flow( "Chennai", "Bengaluru", 25 ), Flow( "Chennai", "Kochi", 15 ), ;
                                         Flow( "Madurai", "Coimbatore", 12 ), Flow( "Bengaluru", "Coimbatore", 18 ), ;
                                         Flow( "Bengaluru", "Kochi", 10 ), Flow( "Kochi", "Madurai", 8 ), ;
                                         Flow( "Coimbatore", "Kochi", 14 ) } } } } )

STATIC FUNCTION OptGauge()
RETURN J( { "title" => Ttl( "Today at the factory" ), ;
            "series" => { ;
               { "type" => "gauge", "center" => { "18%", "56%" }, "radius" => "58%", "min" => 0, "max" => 120, ;
                 "progress" => { "show" => .T., "width" => 14 }, "axisLine" => { "lineStyle" => { "width" => 14 } }, ;
                 "detail" => { "formatter" => "{value} m/min", "fontSize" => 18, "offsetCenter" => { 0, "70%" } }, ;
                 "title" => { "offsetCenter" => { 0, "95%" } }, ;
                 "data" => { { "name" => "Loom speed", "value" => 86 } } }, ;
               { "type" => "gauge", "center" => { "50%", "56%" }, "radius" => "58%", "startAngle" => 90, "endAngle" => -270, ;
                 "pointer" => { "show" => .F. }, "progress" => { "show" => .T., "roundCap" => .T., "width" => 18 }, ;
                 "axisLine" => { "lineStyle" => { "width" => 18 } }, "splitLine" => { "show" => .F. }, ;
                 "axisTick" => { "show" => .F. }, "axisLabel" => { "show" => .F. }, ;
                 "detail" => { "formatter" => "{value}%", "fontSize" => 30, "offsetCenter" => { 0, 0 } }, ;
                 "title" => { "offsetCenter" => { 0, "30%" } }, ;
                 "data" => { { "name" => "Order done", "value" => 72 } } }, ;
               { "type" => "gauge", "center" => { "82%", "56%" }, "radius" => "58%", "min" => 0, "max" => 60, ;
                 "axisLine" => { "lineStyle" => { "width" => 14, "color" => { { 0.6, "#22c55e" }, { 0.8, "#f59e0b" }, { 1, "#ef4444" } } } }, ;
                 "pointer" => { "itemStyle" => { "color" => "auto" } }, ;
                 "detail" => { "formatter" => "{value} °C", "fontSize" => 18, "offsetCenter" => { 0, "70%" } }, ;
                 "title" => { "offsetCenter" => { 0, "95%" } }, ;
                 "data" => { { "name" => "Boiler", "value" => 41 } } } } } )

STATIC FUNCTION OptPictorial()
   LOCAL aCat := { "Mangoes", "Bananas", "Coconuts", "Jackfruit", "Guavas" }
RETURN J( { "title" => Ttl( "Fruit sold this week (crates)" ), "tooltip" => { "trigger" => "axis" }, ;
            "grid" => { "left" => 110, "right" => 70, "top" => 60, "bottom" => 30 }, ;
            "xAxis" => { "type" => "value", "max" => 60, "splitLine" => { "show" => .F. } }, ;
            "yAxis" => { "type" => "category", "data" => aCat, "inverse" => .T., "axisTick" => { "show" => .F. } }, ;
            "series" => { { "type" => "pictorialBar", "name" => "Crates", "symbol" => "roundRect", "symbolRepeat" => .T., ;
                            "symbolSize" => { 16, 26 }, "symbolMargin" => 3, "symbolClip" => .T., ;
                            "label" => { "show" => .T., "position" => "right", "formatter" => "{c}" }, ;
                            "data" => { { "value" => 52, "itemStyle" => { "color" => "#f59e0b" } }, ;
                                        { "value" => 44, "itemStyle" => { "color" => "#eab308" } }, ;
                                        { "value" => 31, "itemStyle" => { "color" => "#84cc16" } }, ;
                                        { "value" => 18, "itemStyle" => { "color" => "#16a34a" } }, ;
                                        { "value" => 26, "itemStyle" => { "color" => "#ec4899" } } } } } } )

STATIC FUNCTION OptThemeRiver()
   LOCAL aTopics := { "Forms", "Grid", "Printing", "Database", "WebView" }, aData := {}, d := SToD( "20260601" ), i, c, nBase
   FOR i := 1 TO 24
      FOR EACH c IN aTopics
         nBase := { 30, 25, 18, 22, 4 }[ c:__enumIndex() ]
         IF c == "WebView"
            nBase += i * 1.6                       // a new topic growing
         ENDIF
         AAdd( aData, { StrTran( IsoDate( d ), "-", "/" ), Int( nBase + Rnd() * 12 ), c } )
      NEXT
      d += 7
   NEXT
RETURN J( { "title" => Ttl( "Forum posts a week by topic" ), ;
            "tooltip" => { "trigger" => "axis", "axisPointer" => { "type" => "line" } }, ;
            "legend" => { "bottom" => 0, "data" => aTopics }, ;
            "singleAxis" => { "type" => "time", "top" => 60, "bottom" => 60, "left" => 40, "right" => 40 }, ;
            "series" => { { "type" => "themeRiver", "data" => aData, "label" => { "show" => .T. }, ;
                            "emphasis" => { "itemStyle" => { "shadowBlur" => 12 } } } } } )

STATIC FUNCTION OptParallel()
RETURN J( { "title" => Ttl( "Laptops compared" ), "tooltip" => { "trigger" => "item" }, "legend" => { "bottom" => 0 }, ;
            "parallel" => { "left" => 70, "right" => 110, "top" => 80, "bottom" => 60 }, ;
            "parallelAxis" => { { "dim" => 0, "name" => "Price (₹'000)" }, { "dim" => 1, "name" => "Weight (kg)", "inverse" => .T. }, ;
                                { "dim" => 2, "name" => "Battery (h)" }, { "dim" => 3, "name" => "RAM (GB)" }, ;
                                { "dim" => 4, "name" => "Rating", "min" => 3, "max" => 5 } }, ;
            "series" => { Lap( "Alpha 14",  { 58, 1.4, 10, 16, 4.3 } ), Lap( "Bravo 15", { 72, 1.8, 8, 16, 4.1 } ), ;
                          Lap( "Carbon X",  { 120, 1.1, 14, 32, 4.7 } ), Lap( "Delta 13", { 45, 1.3, 9, 8, 3.9 } ), ;
                          Lap( "Echo Pro",  { 95, 2.1, 6, 32, 4.4 } ), Lap( "Fox Air", { 66, 1.2, 12, 16, 4.5 } ) } } )

STATIC FUNCTION Lap( cName, aVal )
RETURN { "name" => cName, "type" => "parallel", "lineStyle" => { "width" => 3 }, "data" => { aVal } }

/* ---- map: a made-up district with seven zones, as GeoJSON; lines between branches ---- */

STATIC FUNCTION MapScript()
   LOCAL aZones := { ;
      { "North Hills",  { { 0, 6 }, { 4, 6 }, { 4, 9 }, { 0, 9 } }, 42 }, ;
      { "Lake Side",    { { 4, 6 }, { 9, 6 }, { 9, 9 }, { 4, 9 } }, 65 }, ;
      { "Old Town",     { { 0, 3 }, { 3, 3 }, { 3, 6 }, { 0, 6 } }, 88 }, ;
      { "Market",       { { 3, 3 }, { 6, 3 }, { 6, 6 }, { 3, 6 } }, 120 }, ;
      { "Railway",      { { 6, 3 }, { 9, 3 }, { 9, 6 }, { 6, 6 } }, 74 }, ;
      { "Port",         { { 0, 0 }, { 5, 0 }, { 5, 3 }, { 0, 3 } }, 96 }, ;
      { "Industrial",   { { 5, 0 }, { 9, 0 }, { 9, 3 }, { 5, 3 } }, 51 } }
   LOCAL aFeat := {}, aMapData := {}, a, aRing, hGeo, hOpt
   // the branches sit away from the zone centres, where the zone names are
   LOCAL aBranch := { { "Head office", { 4.5, 3.7 } }, { "Depot", { 8.1, 0.8 } }, { "Harbour shop", { 0.9, 0.8 } }, ;
                      { "Hill shop", { 0.9, 8.3 } }, { "Lake shop", { 7.6, 8.3 } } }
   LOCAL aLines := {}, aPoints := {}, i
   FOR EACH a IN aZones
      aRing := AClone( a[ 2 ] )
      AAdd( aRing, a[ 2 ][ 1 ] )                // a closed ring
      AAdd( aFeat, { "type" => "Feature", "properties" => { "name" => a[ 1 ] }, ;
                     "geometry" => { "type" => "Polygon", "coordinates" => { aRing } } } )
      AAdd( aMapData, { "name" => a[ 1 ], "value" => a[ 3 ] } )
   NEXT
   hGeo := { "type" => "FeatureCollection", "features" => aFeat }
   FOR i := 2 TO Len( aBranch )
      AAdd( aLines, { "coords" => { aBranch[ 1 ][ 2 ], aBranch[ i ][ 2 ] } } )
   NEXT
   FOR EACH a IN aBranch
      AAdd( aPoints, { "name" => a[ 1 ], "value" => { a[ 2 ][ 1 ], a[ 2 ][ 2 ], 1 } } )
   NEXT
   hOpt := { "title" => Ttl( "Sales by zone and deliveries from the head office" ), ;
             "tooltip" => { "trigger" => "item" }, ;
             "visualMap" => { "min" => 40, "max" => 120, "left" => 20, "bottom" => 20, "text" => { "high", "low" }, "calculable" => .T., ;
                              "seriesIndex" => 0, "inRange" => { "color" => { "#e0f2fe", "#38bdf8", "#1d4ed8" } } }, ;
             "geo" => { "map" => "hmgdistrict", "roam" => .T., "top" => 70, "bottom" => 30, ;
                        "label" => { "show" => .T., "color" => "#0f172a", "textBorderColor" => "#ffffff", "textBorderWidth" => 3 }, ;
                        "itemStyle" => { "borderColor" => "#ffffff", "borderWidth" => 2 } }, ;
             "series" => { { "name" => "Sales", "type" => "map", "geoIndex" => 0, "data" => aMapData }, ;
                           { "name" => "Deliveries", "type" => "lines", "coordinateSystem" => "geo", "data" => aLines, ;
                             "effect" => { "show" => .T., "period" => 4, "symbol" => "arrow", "symbolSize" => 9, "trailLength" => 0.1 }, ;
                             "lineStyle" => { "color" => "#f97316", "width" => 2, "curveness" => 0.25 } }, ;
                           { "name" => "Branches", "type" => "effectScatter", "coordinateSystem" => "geo", "data" => aPoints, ;
                             "symbolSize" => 12, "itemStyle" => { "color" => "#f97316" }, ;
                             "label" => { "show" => .T., "formatter" => "{b}", "position" => "right", "fontWeight" => "bold" } } } }
RETURN "echarts.registerMap('hmgdistrict'," + J( hGeo ) + ");hmgChart.set(" + J( hOpt ) + ",null);"

/* ---- custom series: a project plan; renderItem is JavaScript ------------------------ */

STATIC FUNCTION GanttScript()
   LOCAL aTasks := { { "Requirements", 0, 6 }, { "Form design", 4, 12 }, { "Database", 6, 16 }, { "Reports", 12, 22 }, ;
                     { "WebView screens", 14, 24 }, { "Charts", 18, 26 }, { "Testing", 22, 32 }, { "Training", 30, 35 }, ;
                     { "Go live", 35, 36 } }
   LOCAL aNames := {}, aData := {}, a, cJs
   FOR EACH a IN aTasks
      AAdd( aNames, a[ 1 ] )
      AAdd( aData, { "name" => a[ 1 ], "value" => { a:__enumIndex() - 1, a[ 2 ], a[ 3 ], a[ 3 ] - a[ 2 ] } } )
   NEXT
#pragma __stream|cJs := %s
var tasks = TASKS, names = NAMES;
var colors = ['#6366f1','#0ea5e9','#14b8a6','#22c55e','#eab308','#f97316','#ef4444','#a855f7','#111827'];
hmgChart.chart.setOption({
  backgroundColor: 'transparent',
  title: { text: 'Project plan (days)', left: 'center' },
  tooltip: { formatter: function (p) { return p.name + ': day ' + p.value[1] + ' to ' + p.value[2] + ' (' + p.value[3] + ' days)'; } },
  grid: { left: 140, right: 40, top: 60, bottom: 40 },
  xAxis: { type: 'value', min: 0, max: 36, name: 'day' },
  yAxis: { type: 'category', data: names, inverse: true },
  series: [{
    type: 'custom',
    encode: { x: [1, 2], y: 0 },
    data: tasks,
    renderItem: function (params, api) {
      var row = api.value(0), start = api.coord([api.value(1), row]), end = api.coord([api.value(2), row]);
      var h = api.size([0, 1])[1] * 0.56;
      var rect = echarts.graphic.clipRectByRect(
        { x: start[0], y: start[1] - h / 2, width: Math.max(end[0] - start[0], 6), height: h },
        { x: params.coordSys.x, y: params.coordSys.y, width: params.coordSys.width, height: params.coordSys.height });
      return rect && { type: 'rect', shape: rect, style: { fill: colors[row % colors.length], opacity: 0.9 },
                       textContent: { style: { text: api.value(3) + 'd', fill: '#fff', fontSize: 11 } },
                       textConfig: { position: 'inside' } };
    }
  }]
}, true);
#pragma __endtext
RETURN StrTran( StrTran( cJs, "TASKS", J( aData ) ), "NAMES", J( aNames ) )

/* ---- helpers ----------------------------------------------------------------------- */

STATIC FUNCTION MovingAvg( aVal, n )
   LOCAL aRes := {}, i, j, nSum
   FOR i := 1 TO Len( aVal )
      IF i < n
         AAdd( aRes, "-" )                   // ECharts: no value yet
      ELSE
         nSum := 0
         FOR j := i - n + 1 TO i
            nSum += aVal[ j ]
         NEXT
         AAdd( aRes, Round( nSum / n, 2 ) )
      ENDIF
   NEXT
RETURN aRes

STATIC FUNCTION IsoDate( d )
   LOCAL c := DToS( d )
RETURN Left( c, 4 ) + "-" + SubStr( c, 5, 2 ) + "-" + Right( c, 2 )

/* the same "random" data every run */
STATIC FUNCTION Rnd()
   s_nSeed := ( s_nSeed * 16807 ) % 2147483647          // Park-Miller: exact in a double
RETURN s_nSeed / 2147483647
