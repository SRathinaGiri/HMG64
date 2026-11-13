/*
 * HMG5 sample: GraphPlus on Apache ECharts.
 * The 15 GraphPlus types drawn as bitmaps with :Draw() / :Bitmap() (as GraphPlus programs
 * always did, now anti-aliased and DPI-sharp), and the clicked one shown interactive with
 * :Show() in a CHART control (tooltips; hover the bars and slices).
 * Needs the WebView2 runtime (part of Windows 10/11); works offline.
 */
#include "hmg.ch"
#include "GraphPlus.ch"

STATIC s_aGraphs := {}

FUNCTION Main()
   LOCAL i, nRow, nCol, cName

   DEFINE WINDOW Win_Main AT 0, 0 WIDTH 1300 HEIGHT 900 TITLE "HMG5 GraphPlus (Apache ECharts)" MAIN ON INIT DrawAll()
      FOR i := 1 TO 15
         nRow := 10 + Int( ( i - 1 ) / 5 ) * 170
         nCol := 10 + ( ( i - 1 ) % 5 ) * 256
         cName := "Img_" + hb_ntos( i )
         @ nRow, nCol IMAGE &cName PICTURE "" WIDTH 250 HEIGHT 160 STRETCH ;
            ON CLICK ShowLive( Val( SubStr( This.Name, 5 ) ) )
      NEXT
      @ 525, 10 LABEL Lbl_Hint VALUE "Click a chart above to see it live:" WIDTH 400 HEIGHT 20
      @ 548, 10 CHART Ch_Live WIDTH 1270 HEIGHT 300
   END WINDOW

   Win_Main.Center
   Win_Main.Activate
RETURN NIL

STATIC PROCEDURE DrawAll()
   LOCAL i, o
   s_aGraphs := MakeGraphs()
   FOR i := 1 TO Len( s_aGraphs )
      o := s_aGraphs[ i ]
      o:Width  := 500
      o:Height := 320
      o:Draw()
      SetProperty( "Win_Main", "Img_" + hb_ntos( i ), "HBITMAP", o:Bitmap( 250, 160 ) )   // a resized copy, as GraphPlus thumbnails
   NEXT
   ShowLive( 1 )
RETURN

STATIC PROCEDURE ShowLive( n )
   s_aGraphs[ n ]:Show( "Win_Main", "Ch_Live" )
RETURN

STATIC FUNCTION MakeGraphs()
   LOCAL a := {}, o, i, aX := {}, aY := {}
   LOCAL aMonths := { "Jan", "Feb", "Mar", "Apr", "May" }
   LOCAL aSeries := { { 14280, 20420, 12870, 25347, 7640 }, { 8350, 20315, 15870, 5347, 12340 }, { 12345, 8945, 10560, 15600, 17610 } }
   LOCAL aCost := { { "Material", "Core", "Graphite", 400 }, { "Material", "Core", "Clay", 200 }, { "Material", "Core", "Wood", 250 }, ;
                    { "Material", "Packing", "Board", 100 }, { "Material", "Packing", "Box", 25 }, ;
                    { "Labour", "Skilled", "Foreman", 150 }, { "Labour", "Skilled", "Operator", 170 }, { "Labour", "Unskilled", "Cleaner", 50 }, ;
                    { "Overheads", "Direct", "Power", 150 }, { "Overheads", "Indirect", "Salary", 150 } }

   FOR i := 1 TO 15
      o := GraphPlus():New()
      o:GraphData  := aSeries
      o:Legends    := { "Serie 1", "Serie 2", "Serie 3" }
      o:Categories := aMonths
      o:ShowLegends := .T.
      o:TitleFont  := { "Arial", 11, .T., .F., .F., .F. }
      o:GraphType  := i
      AAdd( a, o )
   NEXT
   a[ GT_COLUMNS ]:Title := "Columns"
   a[ GT_LINE ]:Title := "Line"
   a[ GT_POINTS ]:Title := "Points"
   WITH OBJECT a[ GT_PIE ]
      :Title := "Pie"
      :GraphData := { 1387, 1340, 339, 269, 224 }
      :Legends := { "China", "India", "USA", "Indonesia", "Brazil" }
   ENDWITH
   WITH OBJECT a[ GT_BAR ]
      :Title := "Bar"
      :GraphData := { 1387, 1340, 339, 269, 224 }
      :Categories := { "China", "India", "USA", "Indonesia", "Brazil" }
      :Legends := { "Population (M)" }
      :ShowLabels := .T.
   ENDWITH
   WITH OBJECT a[ GT_FUNNEL ]
      :Title := "Funnel"
      :GraphData := { 8000, 6000, 4500, 2000, 900 }
      :Categories := { "Awareness", "Interest", "Consideration", "Intent", "Purchase" }
      :ShowLegends := .F.
   ENDWITH
   a[ GT_STACKEDCOLUMN ]:Title := "Stacked column"
   a[ GT_STACKEDBAR ]:Title := "Stacked bar"
   WITH OBJECT a[ GT_AREA ]
      :Title := "Area"
      :GraphData := { { 800, 1000, 1100, 1040, 980 }, { 650, 780, 1300, 840, 700 }, { 150, 220, -200, 200, 280 } }
      :Legends := { "Sales", "Cost", "Profit" }
   ENDWITH
   FOR i := -10 TO 10
      AAdd( aX, i )
      AAdd( aY, i * i )
   NEXT
   WITH OBJECT a[ GT_SCATTERXY ]
      :Title := "Scatter XY: y = x^2"
      :GraphData := { aX, aY }
      :Legends := { "y = x^2" }
      :ScatterLine := .T.
   ENDWITH
   WITH OBJECT a[ GT_DOUGHNUT ]
      :Title := "Doughnut"
      :GraphData := { { 1000, 2000, 3000 }, { 2000, 1000, 2000 }, { 3000, 2000, 1000 } }
      :Legends := { "Product 1", "Product 2", "Product 3" }
      :Categories := { "India", "Sri Lanka", "Japan" }
      :BarGapRatio := 0.3
   ENDWITH
   WITH OBJECT a[ GT_SUNBURST ]
      :Title := "Sunburst: pencil cost"
      :GraphData := aCost
   ENDWITH
   WITH OBJECT a[ GT_WATERFALL ]
      :Title := "Waterfall"
      :GraphData := { 15000, -10000, 15000, -12000, -6000, 7000, 9000 }
      :TotalItems := { 1, 7 }
      :Categories := { "Opening", "Jan", "Feb", "Mar", "Apr", "May", "Closing" }
      :Legends := { "Credit", "Debit", "Balance" }
      :GraphColors := { { 112, 173, 71 }, { 237, 125, 49 }, { 68, 115, 197 } }
      :GraphData := { 15000, -10000, 15000, -12000, -6000, 7000, 9000 }
   ENDWITH
   WITH OBJECT a[ GT_TREEMAP ]
      :Title := "Treemap: pencil cost"
      :GraphData := aCost
   ENDWITH
   WITH OBJECT a[ GT_BUBBLE ]
      :Title := "Bubbles"
      :GraphData := { { 1, 5, 20 }, { 2, 6, 45 }, { 3, 9, 10 }, { 0, 9, 30 }, { 4, 2, 15 } }
      :Legends := { "A", "B", "C", "D", "E" }
      :XTitle := "x"
      :YTitle := "y"
   ENDWITH
RETURN a
