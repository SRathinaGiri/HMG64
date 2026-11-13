/*----------------------------------------------------------------------------
 HMG5 - CHART control (Apache ECharts in a WEBVIEW). See SOURCE\h_chart.prg.

 @ <row>, <col> CHART <name> [ OF <parent> ] WIDTH <w> HEIGHT <h>
       [ TYPE COLUMN | BAR | LINE | AREA | POINTS | PIE | DOUGHNUT | FUNNEL ]
       [ CHARTTYPE <cType> ]                   ( the type as an expression )
       [ TITLE <cTitle> ] [ CATEGORIES <aNames> ] [ SERIES <aSeries> ]
       [ LEGEND | NOLEGEND ] [ LABELS ] [ STACKED ] [ THEME <cTheme> ]
       [ COLORS <aColors> ] [ OPTION <cEChartsJson> ] [ INVISIBLE ]
       [ ON CLICK <action> ]                   ( HMG_ChartClicked() in the action )
---------------------------------------------------------------------------*/
#xcommand @ <row>, <col> CHART <name> ;
      [ <dummy1: OF, PARENT> <parent> ] ;
      WIDTH <w> ;
      HEIGHT <h> ;
      [ TYPE <type: COLUMN, BAR, LINE, AREA, POINTS, PIE, DOUGHNUT, FUNNEL, CUSTOM> ] ;
      [ CHARTTYPE <ctype> ] ;
      [ TITLE <title> ] ;
      [ CATEGORIES <cats> ] ;
      [ SERIES <series> ] ;
      [ <legend: LEGEND> ] ;
      [ <nolegend: NOLEGEND> ] ;
      [ <labels: LABELS> ] ;
      [ <stacked: STACKED> ] ;
      [ THEME <theme> ] ;
      [ COLORS <colors> ] ;
      [ OPTION <option> ] ;
      [ <invisible: INVISIBLE> ] ;
      [ ON CLICK <click> ] ;
   => ;
   _DefineChart( <"name">, <"parent">, <row>, <col>, <w>, <h>, ;
                 hb_defaultValue( <ctype>, <"type"> ), <title>, <cats>, <series>, ;
                 iif( <.legend.>, .T., iif( <.nolegend.>, .F., NIL ) ), <.labels.>, <.stacked.>, ;
                 <theme>, <colors>, <option>, <{click}>, <.invisible.> )
