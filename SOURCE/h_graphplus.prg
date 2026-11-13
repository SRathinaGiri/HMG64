/*----------------------------------------------------------------------------
 HMG5 - GraphPlus class on Apache ECharts (Phase 4, PHASE4-DESIGN.md section 7)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 The programming interface of S. Rathinagiri's GraphPlus library for HMG (2021-2026):
 the same class name, DATA, SETGET methods and constants (INCLUDE\GraphPlus.ch), so
 programs written for it run unchanged. Written for HMG5 from that interface; the
 drawing is new: every chart is an Apache ECharts option.

   oG := GraphPlus():New()
   WITH OBJECT oG
      :GraphData  := { { 10, 20, 30 }, { 12, 18, 33 } }   // one row per series (Legends)
      :Legends    := { "2025", "2026" }
      :Categories := { "Jan", "Feb", "Mar" }
      :GraphType  := GT_COLUMNS
      :Title      := "Sales"
      :Draw()                                          // as before: a bitmap ...
   ENDWITH
   Form_1.Image_1.hBitmap := oG:Bitmap()               // ... for an IMAGE control
   oG:Show( "Form_1", "Chart_1" )                      // new: interactive, in a CHART control
   cJson := oG:Option()                                // new: the ECharts option (JSON)

 Draw() renders off screen (HMG_ChartRenderPng, h_chart.prg) and needs a window to exist.
 Types: all 15 GT_ constants. Data shapes as in GraphPlus: SCATTERXY { aX, aY1 [, aY2 ...] };
 SUNBURST / TREEMAP rows { cLevel1, cLevel2, ..., nValue }; WATERFALL one row of changes with
 TotalItems (positions drawn from zero); BUBBLE rows { x, y, size } named by Legends;
 PIE one row named by Legends; DOUGHNUT one ring per category, slices = series.
---------------------------------------------------------------------------*/

#include "hmg.ch"
#include "hbclass.ch"
#include "GraphPlus.ch"

CREATE CLASS GraphPlus

   // the GraphPlus data (same names: programs may use them directly)
   DATA aData          INIT {}
   DATA aLegends       INIT {}
   DATA aCategories    INIT {}
   DATA nGraphType     INIT GT_DEFAULT
   DATA cTitle         INIT ''
   DATA cXTitle        INIT ''
   DATA cYTitle        INIT ''
   DATA lXRotate       INIT .F.
   DATA nHeight        INIT 600
   DATA nWidth         INIT 600
   DATA lShowLegends   INIT .F.
   DATA lDataLabels    INIT .F.
   DATA lHGrid         INIT .T.
   DATA lVGrid         INIT .T.
   DATA lShowValues    INIT .T.
   DATA lShowCategories INIT .T.
   DATA nLegendPos     INIT LEGEND_ON_BOTTOM
   DATA lOutBorder     INIT .T.
   DATA aColors        INIT {}
   DATA aTitleFont     INIT { 'Arial', 12, .T., .F., .F., .F. }
   DATA aLegendFont    INIT { 'Arial', 8, .F., .F., .F., .F. }
   DATA aBackColor     INIT CLR_WHITE
   DATA aTitleColor    INIT { 0, 0, 255 }
   DATA aTextColor     INIT { 0, 0, 0 }
   DATA aGridLineColor INIT { 200, 200, 200 }
   DATA nColorTheme    INIT 1
   DATA nVDivision     INIT 5
   DATA nHDivision     INIT 5
   DATA cPicture       INIT ''
   DATA cPictureX      INIT ''
   DATA cPictureY      INIT ''
   DATA nBarGapRatio   INIT 0.2
   DATA nGapWidthRatio INIT 1
   DATA nImageHeight   INIT 600
   DATA nImageWidth    INIT 600
   DATA lScatterLine   INIT .F.
   DATA aTotalItems    INIT {}
   DATA lLighter       INIT .T.
   DATA hBitMap        INIT NIL
   DATA aColorThemes   INIT { { CLR_HAVELOCK_BLUE, CLR_WESTSIDE, CLR_LIGHT_GREY, CLR_ORANGE_YELLOW, CLR_PICTON_BLUE, CLR_APPLE }, ;
                              { CLR_HAVELOCK_BLUE, CLR_LIGHT_GREY, CLR_PICTON_BLUE, CLR_DARKER_BLUE, CLR_DARK_GREY, CLR_ENDEAVOUR }, ;
                              { CLR_WESTSIDE, CLR_ORANGE_YELLOW, CLR_APPLE, CLR_SADDLE_BROWN, CLR_LIGHT_BROWN, CLR_DELL }, ;
                              { CLR_APPLE, CLR_PICTON_BLUE, CLR_ORANGE_YELLOW, CLR_DELL, CLR_ENDEAVOUR, CLR_LIGHT_BROWN }, ;
                              { CLR_HAVELOCK_BLUE }, ;
                              { CLR_WESTSIDE } }
   DATA lAnimation     INIT .T.        // HMG5: Show() animates, Draw() does not

   METHOD New
   METHOD Draw
   METHOD Bitmap
   METHOD Save
   METHOD Show
   METHOD Option
   METHOD InitColors
   METHOD SwitchRowsToColumns
   METHOD GridData

   METHOD GraphData        SETGET
   METHOD Legends          SETGET
   METHOD Categories       SETGET
   METHOD GraphColors      SETGET
   METHOD GraphType        SETGET
   METHOD Title            SETGET
   METHOD XTitle           SETGET
   METHOD YTitle           SETGET
   METHOD Height           SETGET
   METHOD Width            SETGET
   METHOD ShowLegends      SETGET
   METHOD ShowLabels       SETGET
   METHOD ShowCategories   SETGET
   METHOD ShowHGrid        SETGET
   METHOD ShowVGrid        SETGET
   METHOD ShowValues       SETGET
   METHOD LegendPos        SETGET
   METHOD ColorTheme       SETGET
   METHOD BackColor        SETGET
   METHOD BarGapRatio      SETGET
   METHOD BarGapWidthRatio SETGET
   METHOD TitleFont        SETGET
   METHOD LegendFont       SETGET
   METHOD Picture          SETGET
   METHOD PictureX         SETGET
   METHOD PictureY         SETGET
   METHOD ScatterLine      SETGET
   METHOD VDivisions       SETGET
   METHOD HDivisions       SETGET
   METHOD TotalItems       SETGET

ENDCLASS

METHOD New() CLASS GraphPlus
   RETURN Self

/* ---- properties (SETGET: :Title := x / :Title()) --------------------------------- */

METHOD GraphData( aData ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::aData
   ENDIF
   IF HB_ISARRAY( aData ) .AND. Len( aData ) > 0 .AND. ! HB_ISARRAY( aData[ 1 ] )
      ::aData := { aData }            // one row
   ELSE
      ::aData := aData
   ENDIF
   RETURN Self

METHOD Legends( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::aLegends
   ENDIF
   ::aLegends := x
   RETURN Self

METHOD Categories( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::aCategories
   ENDIF
   ::aCategories := x
   RETURN Self

METHOD GraphColors( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::aColors
   ENDIF
   ::aColors := x
   RETURN Self

METHOD Title( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::cTitle
   ENDIF
   ::cTitle := x
   RETURN Self

METHOD XTitle( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::cXTitle
   ENDIF
   ::cXTitle := x
   RETURN Self

METHOD YTitle( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::cYTitle
   ENDIF
   ::cYTitle := x
   RETURN Self

METHOD Height( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::nImageHeight
   ENDIF
   ::nImageHeight := x
   RETURN Self

METHOD Width( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::nImageWidth
   ENDIF
   ::nImageWidth := x
   RETURN Self

METHOD ShowLegends( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::lShowLegends
   ENDIF
   ::lShowLegends := x
   RETURN Self

METHOD ShowLabels( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::lDataLabels
   ENDIF
   ::lDataLabels := x
   RETURN Self

METHOD ShowCategories( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::lShowCategories
   ENDIF
   ::lShowCategories := x
   RETURN Self

METHOD ShowHGrid( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::lHGrid
   ENDIF
   ::lHGrid := x
   RETURN Self

METHOD ShowVGrid( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::lVGrid
   ENDIF
   ::lVGrid := x
   RETURN Self

METHOD ShowValues( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::lShowValues
   ENDIF
   ::lShowValues := x
   RETURN Self

METHOD LegendPos( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::nLegendPos
   ENDIF
   ::nLegendPos := x
   RETURN Self

METHOD BackColor( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::aBackColor
   ENDIF
   ::aBackColor := x
   RETURN Self

METHOD BarGapRatio( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::nBarGapRatio
   ENDIF
   ::nBarGapRatio := x
   RETURN Self

METHOD BarGapWidthRatio( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::nGapWidthRatio
   ENDIF
   ::nGapWidthRatio := x
   RETURN Self

METHOD TitleFont( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::aTitleFont
   ENDIF
   ::aTitleFont := x
   RETURN Self

METHOD LegendFont( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::aLegendFont
   ENDIF
   ::aLegendFont := x
   RETURN Self

METHOD Picture( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::cPicture
   ENDIF
   ::cPicture := x
   RETURN Self

METHOD PictureX( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::cPictureX
   ENDIF
   ::cPictureX := x
   RETURN Self

METHOD PictureY( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::cPictureY
   ENDIF
   ::cPictureY := x
   RETURN Self

METHOD ScatterLine( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::lScatterLine
   ENDIF
   ::lScatterLine := x
   RETURN Self

METHOD VDivisions( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::nVDivision
   ENDIF
   ::nVDivision := x
   RETURN Self

METHOD HDivisions( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::nHDivision
   ENDIF
   ::nHDivision := x
   RETURN Self

METHOD TotalItems( x ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::aTotalItems
   ENDIF
   ::aTotalItems := x
   RETURN Self

METHOD GraphType( nType ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::nGraphType
   ENDIF
   ::nGraphType := nType
   RETURN Self

METHOD ColorTheme( nTheme ) CLASS GraphPlus
   IF PCount() == 0
      RETURN ::nColorTheme
   ENDIF
   ::nColorTheme := nTheme
   ::aColors := {}                    // colours come from the theme again
   RETURN Self

/* ---- data helpers ---------------------------------------------------------------- */

/* rows of a grid: column 1 names the series (Legends), the headers of columns 2.. are the Categories */
METHOD GridData( cForm, cGrid ) CLASS GraphPlus
   LOCAL nRows, nCols, i, j, aItem, aRow
   IF PCount() == 0
      RETURN ::aData
   ENDIF
   ::aData := {}
   ::aLegends := {}
   ::aCategories := {}
   nCols := GetProperty( cForm, cGrid, "COLUMNCOUNT" )
   nRows := GetProperty( cForm, cGrid, "ITEMCOUNT" )
   FOR i := 2 TO nCols
      AAdd( ::aCategories, GetProperty( cForm, cGrid, "COLUMNHEADER", i ) )
   NEXT
   FOR i := 1 TO nRows
      aItem := GetProperty( cForm, cGrid, "ITEM", i )
      aRow := {}
      FOR j := 1 TO nCols
         IF j == 1
            AAdd( ::aLegends, aItem[ j ] )
         ELSE
            AAdd( aRow, Val( AllTrim( hb_CStr( aItem[ j ] ) ) ) )
         ENDIF
      NEXT
      AAdd( ::aData, aRow )
   NEXT
   RETURN Self

/* series <-> categories: the data transposed, Legends and Categories swapped, X/Y titles swapped */
METHOD SwitchRowsToColumns() CLASS GraphPlus
   LOCAL aNew := {}, i, j, aRow, x
   IF Empty( ::aData ) .OR. ! HB_ISARRAY( ::aData[ 1 ] )
      RETURN NIL
   ENDIF
   FOR j := 1 TO Len( ::aData[ 1 ] )
      aRow := {}
      FOR i := 1 TO Len( ::aData )
         AAdd( aRow, iif( j <= Len( ::aData[ i ] ), ::aData[ i ][ j ], 0 ) )
      NEXT
      AAdd( aNew, aRow )
   NEXT
   ::aData := aNew
   x := ::aCategories ; ::aCategories := ::aLegends ; ::aLegends := x
   x := ::cXTitle ; ::cXTitle := ::cYTitle ; ::cYTitle := x
   RETURN NIL

/* ::aColors: the given colours, else the theme's, extended with lighter (or darker) shades */
METHOD InitColors( nNeeded ) CLASS GraphPlus
   LOCAL aTheme, i, nRound, nStep
   hb_default( @nNeeded, Max( Len( ::aLegends ), Len( ::aData ) ) )
   IF Len( ::aColors ) >= nNeeded .AND. nNeeded > 0
      RETURN NIL
   ENDIF
   aTheme := ::aColorThemes[ Max( 1, Min( ::nColorTheme, Len( ::aColorThemes ) ) ) ]
   ::aColors := {}
   FOR i := 1 TO Max( nNeeded, 1 )
      nRound := Int( ( i - 1 ) / Len( aTheme ) )          // 0 for the theme's own colours
      nStep  := Min( 0.8, nRound * 0.25 )
      AAdd( ::aColors, GP_Shade( aTheme[ ( ( i - 1 ) % Len( aTheme ) ) + 1 ], iif( ::lLighter, nStep, -nStep ) ) )
   NEXT
   RETURN NIL

/* ---- output ---------------------------------------------------------------------- */

/* the chart as a bitmap of Width x Height pixels (as GraphPlus did); NIL when it cannot be drawn */
METHOD Draw() CLASS GraphPlus
   LOCAL cPng, cFile
   IF Empty( ::aData )
      MsgStop( 'No Graph data!' )
      RETURN NIL
   ENDIF
   ::lAnimation := .F.
   cPng := HMG_ChartRenderPng( ::Option(), ::nImageWidth, ::nImageHeight, GP_Rgb( ::aBackColor ) )
   ::lAnimation := .T.
   IF Empty( cPng )
      RETURN NIL
   ENDIF
   cFile := hb_DirSepAdd( hb_DirTemp() ) + "hmg_gp_" + hb_ntos( hb_RandomInt( 1000000, 9999999 ) ) + ".png"
   IF hb_MemoWrit( cFile, cPng )
      ::hBitmap := BT_BitmapLoadFile( cFile )
      FErase( cFile )
   ENDIF
   RETURN NIL

METHOD Bitmap( nWidth, nHeight ) CLASS GraphPlus
   IF PCount() == 0 .OR. Empty( ::hBitmap )
      RETURN ::hBitmap
   ENDIF
   RETURN BT_BitmapCopyAndResize( ::hBitmap, nWidth, nHeight )

METHOD Save( cFileName ) CLASS GraphPlus
   IF PCount() == 0
      cFileName := GetFile()
   ENDIF
   cFileName := AllTrim( hb_defaultValue( cFileName, "" ) )
   IF Len( cFileName ) > 0 .AND. ! Empty( ::hBitmap )
      IF File( cFileName ) .AND. ! MsgYesNo( 'File already Exists! Do you want to overwrite?' )
         RETURN NIL
      ENDIF
      BT_BitmapSaveFile( ::hBitmap, cFileName, BT_FILEFORMAT_PNG )
   ENDIF
   RETURN NIL

/* HMG5: the same chart, interactive, in a CHART control (tooltips, zoom, ON CLICK) */
METHOD Show( cForm, cChart ) CLASS GraphPlus
   SetProperty( cForm, cChart, "ChartType", "custom" )
   SetProperty( cForm, cChart, "ChartOption", ::Option() )
   RETURN Self

/* HMG5: the ECharts option of this chart (JSON) */
METHOD Option() CLASS GraphPlus
   LOCAL o := { => }, nType := ::nGraphType, aData := ::aData, aLeg, aCat, aS := {}, aRow
   LOCAL i, j, hS, lRot, nSeries, nPoints, cText := GP_Contrast( ::aBackColor ), lRound, nLegFont, nTitleFont
   LOCAL lTotal, nStart, nEnd, nBal, aBox, aLab, nZMax, nSize, nRings, nHole, nWidthRing

   IF ! HB_ISARRAY( aData ) .OR. Empty( aData )
      aData := { {} }
   ELSEIF ! HB_ISARRAY( aData[ 1 ] )
      aData := { aData }
   ENDIF
   nSeries := Len( aData )
   nPoints := Len( aData[ 1 ] )
   lRound  := nType == GT_PIE .OR. nType == GT_DOUGHNUT .OR. nType == GT_FUNNEL .OR. ;
              nType == GT_SUNBURST .OR. nType == GT_TREEMAP
   lRot    := nType == GT_BAR .OR. nType == GT_STACKEDBAR

   // names: given, else "Legend n" / "Category n" as GraphPlus did
   aLeg := AClone( ::aLegends )
   aCat := AClone( ::aCategories )
   IF nType == GT_WATERFALL .AND. Empty( aLeg )
      aLeg := { "Increase", "Decrease", "Total" }
   ENDIF
   FOR i := Len( aLeg ) + 1 TO iif( nType == GT_PIE, nPoints, nSeries )
      AAdd( aLeg, "Legend " + hb_ntos( i ) )
   NEXT
   FOR i := Len( aCat ) + 1 TO nPoints
      AAdd( aCat, "Category " + hb_ntos( i ) )
   NEXT

   ::InitColors( Max( Max( Len( aLeg ), nSeries ), iif( lRound .OR. nType == GT_BUBBLE, nPoints, 0 ) ) )
   nLegFont   := GP_Px( ::aLegendFont, 8 )
   nTitleFont := GP_Px( ::aTitleFont, 12 )

   o[ "animation" ] := ::lAnimation
   IF ! ::lAnimation                  // off-screen render: no fade-ins half way through
      o[ "animationDuration" ] := 0
      o[ "animationDurationUpdate" ] := 0
      o[ "stateAnimation" ] := { "duration" => 0 }
   ENDIF
   o[ "backgroundColor" ] := GP_Rgb( ::aBackColor )
   o[ "color" ] := {}
   AEval( ::aColors, {| c | AAdd( o[ "color" ], GP_Rgb( c ) ) } )
   o[ "textStyle" ] := { "fontFamily" => GP_Font( ::aLegendFont ), "fontSize" => nLegFont, "color" => cText }
   IF ! Empty( ::cTitle )
      o[ "title" ] := { "text" => ::cTitle, "left" => "center", "top" => 6, ;
                        "textStyle" => { "fontFamily" => GP_Font( ::aTitleFont ), "fontSize" => nTitleFont, ;
                                         "fontWeight" => iif( GP_Bold( ::aTitleFont ), "bold", "normal" ), "color" => GP_Rgb( ::aTitleColor ) } }
   ENDIF
   o[ "tooltip" ] := { "trigger" => iif( lRound .OR. nType == GT_SCATTERXY .OR. nType == GT_BUBBLE, "item", "axis" ) }
   IF ::lShowLegends .AND. nType != GT_SUNBURST .AND. nType != GT_TREEMAP
      IF ::nLegendPos == LEGEND_ON_RIGHT
         o[ "legend" ] := { "orient" => "vertical", "right" => 8, "top" => "middle", "textStyle" => { "color" => cText } }
      ELSE
         o[ "legend" ] := { "bottom" => 4, "textStyle" => { "color" => cText } }
      ENDIF
   ENDIF
   o[ "grid" ] := { "containLabel" => .T., "left" => 16, ;
                    "right" => iif( ::lShowLegends .AND. ::nLegendPos == LEGEND_ON_RIGHT, 150, 24 ), ;
                    "top" => iif( Empty( ::cTitle ), 24, nTitleFont + 30 ), ;
                    "bottom" => iif( ::lShowLegends .AND. ::nLegendPos != LEGEND_ON_RIGHT, 36, 16 ) + iif( Empty( ::cXTitle ), 0, 22 ) }

   DO CASE
   CASE nType == GT_PIE .OR. nType == GT_FUNNEL
      aRow := {}
      FOR i := 1 TO nPoints
         AAdd( aRow, GP_Item( iif( nType == GT_PIE, aLeg[ i ], aCat[ i ] ), aData[ 1 ][ i ], Self ) )
      NEXT
      hS := { "type" => iif( nType == GT_PIE, "pie", "funnel" ), "data" => aRow, ;
              "label" => { "show" => .T., "color" => cText, "formatter" => iif( ::lDataLabels, "{b}" + Chr( 10 ) + "{d}%", "{b}" ) } }
      IF nType == GT_PIE
         hS[ "radius" ] := "58%"
         hS[ "center" ] := { "50%", iif( Empty( ::cTitle ), "50%", "54%" ) }
      ELSE
         hS[ "top" ] := iif( Empty( ::cTitle ), 20, nTitleFont + 30 )
         hS[ "bottom" ] := iif( ::lShowLegends, 40, 16 )
         hS[ "label" ][ "formatter" ] := iif( ::lDataLabels, "{b}: {c}", "{b}" )
         hS[ "label" ][ "position" ] := "inside"
         hS[ "label" ][ "color" ] := "#ffffff"
      ENDIF
      AAdd( aS, hS )

   CASE nType == GT_DOUGHNUT          // one ring per category, slices = series
      nRings := nPoints
      nHole := Max( 8, Min( 60, Int( ::nBarGapRatio * 70 ) ) )
      nWidthRing := ( 70 - nHole ) / Max( nRings, 1 )
      FOR j := 1 TO nRings
         aRow := {}
         FOR i := 1 TO nSeries
            AAdd( aRow, GP_Item( aLeg[ i ], aData[ i ][ j ], Self ) )
         NEXT
         AAdd( aS, { "type" => "pie", "name" => aCat[ j ], "data" => aRow, ;
                     "radius" => { hb_ntos( Round( nHole + ( j - 1 ) * nWidthRing, 1 ) ) + "%", hb_ntos( Round( nHole + j * nWidthRing - 0.5, 1 ) ) + "%" }, ;
                     "center" => { "50%", iif( Empty( ::cTitle ), "50%", "54%" ) }, ;
                     "label" => { "show" => ::lDataLabels .AND. j == nRings, "color" => cText, "formatter" => "{b}" + Chr( 10 ) + "{d}%" } } )
      NEXT

   CASE nType == GT_SUNBURST .OR. nType == GT_TREEMAP
      hS := { "type" => iif( nType == GT_SUNBURST, "sunburst", "treemap" ), "data" => GP_Tree( ::aData ) }
      IF nType == GT_SUNBURST
         hS[ "radius" ] := { "8%", "88%" }
         hS[ "center" ] := { "50%", iif( Empty( ::cTitle ), "50%", "54%" ) }
         hS[ "label" ] := { "rotate" => "radial", "show" => .T. }
         hS[ "itemStyle" ] := { "borderWidth" => 1, "borderColor" => GP_Rgb( ::aBackColor ) }
      ELSE
         hS[ "top" ] := iif( Empty( ::cTitle ), 10, nTitleFont + 24 )
         hS[ "breadcrumb" ] := { "show" => .F. }
         hS[ "roam" ] := .F.
         hS[ "nodeClick" ] := .F.
         hS[ "upperLabel" ] := { "show" => .T., "height" => 18 }
         hS[ "label" ] := { "show" => .T., "formatter" => iif( ::lDataLabels, "{b}" + Chr( 10 ) + "{c}", "{b}" ) }
         hS[ "levels" ] := { { "itemStyle" => { "borderWidth" => 0, "gapWidth" => 3 } }, ;
                             { "itemStyle" => { "gapWidth" => 2 } }, ;
                             { "colorSaturation" => { 0.35, 0.6 }, "itemStyle" => { "gapWidth" => 1 } } }
      ENDIF
      AAdd( aS, hS )

   CASE nType == GT_SCATTERXY         // { aX, aY1 [, aY2 ...] }
      o[ "xAxis" ] := GP_ValueAxis( Self, ::cXTitle, ::lVGrid, ::nHDivision )
      o[ "yAxis" ] := GP_ValueAxis( Self, ::cYTitle, ::lHGrid, ::nVDivision )
      FOR j := 2 TO Max( nSeries, 2 )
         aRow := {}
         IF nSeries >= j
            FOR i := 1 TO Min( Len( aData[ 1 ] ), Len( aData[ j ] ) )
               AAdd( aRow, { aData[ 1 ][ i ], aData[ j ][ i ] } )
            NEXT
         ENDIF
         AAdd( aS, { "type" => iif( ::lScatterLine, "line", "scatter" ), "name" => iif( j - 1 <= Len( aLeg ), aLeg[ j - 1 ], "y" ), ;
                     "data" => aRow, "symbolSize" => 7, "showSymbol" => .T., "label" => { "show" => ::lDataLabels, "position" => "top" } } )
      NEXT

   CASE nType == GT_BUBBLE            // rows { x, y, size }, one series per point (named by Legends)
      o[ "xAxis" ] := GP_ValueAxis( Self, ::cXTitle, ::lVGrid, ::nHDivision )
      o[ "yAxis" ] := GP_ValueAxis( Self, ::cYTitle, ::lHGrid, ::nVDivision )
      nZMax := 0
      AEval( ::aData, {| r | nZMax := Max( nZMax, iif( HB_ISARRAY( r ) .AND. Len( r ) >= 3, Abs( r[ 3 ] ), 0 ) ) } )
      FOR i := 1 TO Len( ::aData )
         IF HB_ISARRAY( ::aData[ i ] ) .AND. Len( ::aData[ i ] ) >= 3
            nSize := Max( 8, Int( Min( ::nImageWidth, ::nImageHeight ) * 0.16 * Sqrt( Abs( ::aData[ i ][ 3 ] ) / Max( nZMax, 1 ) ) ) )
            AAdd( aS, { "type" => "scatter", "name" => iif( i <= Len( ::aLegends ), ::aLegends[ i ], "Legend " + hb_ntos( i ) ), ;
                        "data" => { ::aData[ i ] }, "symbolSize" => nSize, "itemStyle" => { "opacity" => 0.8 }, ;
                        "label" => { "show" => ::lDataLabels, "formatter" => hb_ntos( ::aData[ i ][ 3 ] ) } } )
         ENDIF
      NEXT

   CASE nType == GT_WATERFALL         // floating bars: candlestick { start, end, low, high }
      o[ "xAxis" ] := GP_CategoryAxis( Self, aCat, .F. )
      o[ "yAxis" ] := GP_ValueAxis( Self, ::cYTitle, ::lHGrid, ::nVDivision )
      aBox := {}
      aLab := {}
      nBal := 0
      FOR i := 1 TO nPoints
         lTotal := AScan( ::aTotalItems, i ) > 0
         IF lTotal
            nStart := 0
            nEnd   := aData[ 1 ][ i ]
            nBal   := aData[ 1 ][ i ]
         ELSE
            nStart := nBal
            nEnd   := nBal + aData[ 1 ][ i ]
            nBal   := nEnd
         ENDIF
         j := iif( lTotal, 3, iif( aData[ 1 ][ i ] >= 0, 1, 2 ) )
         AAdd( aBox, { "value" => { nStart, nEnd, Min( nStart, nEnd ), Max( nStart, nEnd ) }, ;
                       "itemStyle" => { "color" => GP_Rgb( ::aColors[ j ] ), "color0" => GP_Rgb( ::aColors[ j ] ), ;
                                        "borderColor" => GP_Rgb( ::aColors[ j ] ), "borderColor0" => GP_Rgb( ::aColors[ j ] ) } } )
         AAdd( aLab, { "value" => { i - 1, Max( nStart, nEnd ) }, "label" => { "formatter" => GP_Text( aData[ 1 ][ i ], ::cPicture ) } } )
      NEXT
      AAdd( aS, { "type" => "candlestick", "name" => "", "data" => aBox, "barWidth" => hb_ntos( Int( 100 / ( 1 + Max( ::nBarGapRatio, 0 ) ) ) ) + "%" } )
      IF ::lDataLabels
         AAdd( aS, { "type" => "scatter", "name" => "", "symbolSize" => 0, "data" => aLab, "silent" => .T., ;
                     "label" => { "show" => .T., "position" => "top", "color" => cText } } )
      ENDIF
      FOR i := 1 TO 3                    // legend entries: increase, decrease, total
         AAdd( aS, { "type" => "bar", "name" => aLeg[ Min( i, Len( aLeg ) ) ], "data" => {}, "itemStyle" => { "color" => GP_Rgb( ::aColors[ i ] ) } } )
      NEXT
      o[ "tooltip" ] := { "trigger" => "item" }

   OTHERWISE                          // columns, bars, lines, points, area, stacked
      IF lRot
         o[ "yAxis" ] := GP_CategoryAxis( Self, aCat, .T. )
         o[ "xAxis" ] := GP_ValueAxis( Self, ::cXTitle, ::lVGrid, ::nVDivision )
         o[ "yAxis" ][ "name" ] := ::cYTitle
      ELSE
         o[ "xAxis" ] := GP_CategoryAxis( Self, aCat, .F. )
         o[ "yAxis" ] := GP_ValueAxis( Self, ::cYTitle, ::lHGrid, ::nVDivision )
         o[ "xAxis" ][ "boundaryGap" ] := ! ( nType == GT_LINE .OR. nType == GT_AREA )
      ENDIF
      FOR i := 1 TO nSeries
         aRow := {}
         FOR j := 1 TO Len( aData[ i ] )
            AAdd( aRow, GP_Item( NIL, aData[ i ][ j ], Self ) )
         NEXT
         hS := { "name" => aLeg[ i ], "data" => aRow }
         DO CASE
         CASE nType == GT_LINE
            hS[ "type" ] := "line"
            hS[ "lineStyle" ] := { "width" => 2 }
         CASE nType == GT_POINTS
            hS[ "type" ] := "scatter"
            hS[ "symbolSize" ] := 10
         CASE nType == GT_AREA
            hS[ "type" ] := "line"
            hS[ "areaStyle" ] := { "opacity" => 0.55 }
         OTHERWISE
            hS[ "type" ] := "bar"
            IF nType == GT_STACKEDCOLUMN .OR. nType == GT_STACKEDBAR
               hS[ "stack" ] := "total"
            ENDIF
            IF ::nBarGapRatio > 0
               hS[ "barCategoryGap" ] := hb_ntos( Int( 100 * ::nBarGapRatio / ( ::nBarGapRatio + iif( "stack" $ hS, 1, nSeries ) ) ) ) + "%"
            ENDIF
         ENDCASE
         IF ::lDataLabels
            hS[ "label" ] := { "show" => .T., "color" => cText, ;
                               "position" => iif( "stack" $ hS, "inside", iif( lRot, "right", "top" ) ) }
         ENDIF
         AAdd( aS, hS )
      NEXT
   ENDCASE

   o[ "series" ] := aS
   RETURN hb_jsonEncode( o )

/* ---- helpers --------------------------------------------------------------------- */

STATIC FUNCTION GP_CategoryAxis( oG, aCat, lVertical )
   LOCAL h := { "type" => "category", "data" => aCat, ;
                "axisLabel" => { "show" => oG:lShowCategories, "rotate" => iif( oG:lXRotate .AND. ! lVertical, 45, 0 ) }, ;
                "splitLine" => { "show" => iif( lVertical, oG:lHGrid, oG:lVGrid ), "lineStyle" => { "color" => GP_Rgb( oG:aGridLineColor ) } } }
   IF ! lVertical .AND. ! Empty( oG:cXTitle )
      h[ "name" ] := oG:cXTitle
      h[ "nameLocation" ] := "middle"
      h[ "nameGap" ] := 28
   ENDIF
   RETURN h

STATIC FUNCTION GP_ValueAxis( oG, cName, lGrid, nSplit )
   LOCAL h := { "type" => "value", "scale" => .F., "splitNumber" => Max( 2, hb_defaultValue( nSplit, 5 ) ), ;
                "axisLabel" => { "show" => oG:lShowValues }, ;
                "splitLine" => { "show" => lGrid, "lineStyle" => { "color" => GP_Rgb( oG:aGridLineColor ) } } }
   IF ! Empty( cName )
      h[ "name" ] := cName
      h[ "nameLocation" ] := "middle"
      h[ "nameGap" ] := 40
   ENDIF
   RETURN h

/* a data point; with Picture, its label shows the value through Transform() */
STATIC FUNCTION GP_Item( cName, nValue, oG )
   LOCAL h
   IF cName == NIL .AND. ( Empty( oG:cPicture ) .OR. ! oG:lDataLabels )
      RETURN nValue
   ENDIF
   h := { "value" => nValue }
   IF cName != NIL
      h[ "name" ] := hb_CStr( cName )
   ENDIF
   IF ! Empty( oG:cPicture ) .AND. oG:lDataLabels .AND. cName == NIL
      h[ "label" ] := { "formatter" => GP_Text( nValue, oG:cPicture ) }
   ENDIF
   RETURN h

STATIC FUNCTION GP_Text( nValue, cPicture )
   IF Empty( cPicture )
      RETURN hb_ntos( nValue )
   ENDIF
   RETURN AllTrim( Transform( nValue, cPicture ) )

/* rows { level1, level2, ..., value } -> { { name, children: { ... } } ... } */
STATIC FUNCTION GP_Tree( aRows )
   LOCAL aRoot := {}, r, aLevel, k, n, cName, nPos
   FOR EACH r IN aRows
      IF ! HB_ISARRAY( r ) .OR. Len( r ) < 2
         LOOP
      ENDIF
      aLevel := aRoot
      n := Len( r ) - 1
      FOR k := 1 TO n
         cName := hb_CStr( r[ k ] )
         nPos := AScan( aLevel, {| h | h[ "name" ] == cName } )
         IF nPos == 0
            AAdd( aLevel, { "name" => cName } )
            nPos := Len( aLevel )
         ENDIF
         IF k == n
            aLevel[ nPos ][ "value" ] := hb_HGetDef( aLevel[ nPos ], "value", 0 ) + r[ Len( r ) ]
         ELSE
            IF ! hb_HHasKey( aLevel[ nPos ], "children" )
               aLevel[ nPos ][ "children" ] := {}
            ENDIF
            aLevel := aLevel[ nPos ][ "children" ]
         ENDIF
      NEXT
   NEXT
   RETURN aRoot

STATIC FUNCTION GP_Rgb( a )
   IF HB_ISARRAY( a ) .AND. Len( a ) >= 3
      RETURN "#" + hb_NumToHex( Max( 0, Min( 255, Int( a[ 1 ] ) ) ), 2 ) + hb_NumToHex( Max( 0, Min( 255, Int( a[ 2 ] ) ) ), 2 ) + ;
             hb_NumToHex( Max( 0, Min( 255, Int( a[ 3 ] ) ) ), 2 )
   ENDIF
   RETURN "#000000"

/* black or white, whichever reads on the background */
STATIC FUNCTION GP_Contrast( a )
   IF HB_ISARRAY( a ) .AND. Len( a ) >= 3 .AND. ( a[ 1 ] * 299 + a[ 2 ] * 587 + a[ 3 ] * 114 ) / 1000 < 128
      RETURN "#ffffff"
   ENDIF
   RETURN "#333333"

/* a lighter (n > 0) or darker (n < 0) shade, n in 0..1 */
STATIC FUNCTION GP_Shade( a, n )
   LOCAL i, b := AClone( a )
   FOR i := 1 TO 3
      b[ i ] := Int( iif( n >= 0, b[ i ] + ( 255 - b[ i ] ) * n, b[ i ] * ( 1 + n ) ) )
   NEXT
   RETURN b

/* GraphPlus fonts: { cName, nPoints, lBold, lItalic, lUnderline, lStrikeOut } */
STATIC FUNCTION GP_Font( a )
   RETURN iif( HB_ISARRAY( a ) .AND. Len( a ) >= 1 .AND. HB_ISSTRING( a[ 1 ] ), a[ 1 ], "Arial" )

STATIC FUNCTION GP_Px( a, nDefault )
   RETURN Round( iif( HB_ISARRAY( a ) .AND. Len( a ) >= 2 .AND. HB_ISNUMERIC( a[ 2 ] ), a[ 2 ], nDefault ) * 96 / 72, 0 )

STATIC FUNCTION GP_Bold( a )
   RETURN HB_ISARRAY( a ) .AND. Len( a ) >= 3 .AND. HB_ISLOGICAL( a[ 3 ] ) .AND. a[ 3 ]
