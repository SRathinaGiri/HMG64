# HMG5 additions (not in HMG 3.x)

Check the target first: these need HMG5 (`HMGVersion()` returns "HMG 5.0 ..."). Everything else in
this skill works on HMG 3.x too.

## WEBVIEW - Microsoft Edge (WebView2) inside a window

```
@ <row>, <col> WEBVIEW <name> [ OF <parent> ] WIDTH <w> HEIGHT <h>
      [ URL <cUrl> | HTML <cHtml> | FOLDER <cFolder> [ START <cFile> ] ]
      [ USERDATA <cFolder> ] [ PRIVATE ] [ DEVTOOLS ] [ INVISIBLE ]
      [ ON READY <action> ] [ ON NAVIGATE <action> ] [ ON MESSAGE <action> ]
      [ ON TITLE <action> ] [ ON ERROR <action> ]
```

- **Properties:** `URL` (get; set = navigate), `HTML` (set), `Title` (get - use
  `GetProperty( f, c, "Title" )`, there is no `Form.Web.Title` rule), `Ready`, `Error`, `CanGoBack`,
  `CanGoForward`, `ZoomFactor` (get/set, 1 = 100 %), `UserDataFolder`, plus Row/Col/Width/Height/Visible.
- **Methods:** `Navigate( cUrl )`, `SetHtml( cHtml )`, `Reload`, `Stop`, `GoBack`, `GoForward`,
  `ExecuteScript( cJs [, {| xValue, lOk | ... } ] )`, `Bind( cName, bBlock )`, `Unbind( cName )`,
  `PostMessage( xValue )`, `AllowOrigin( cOrigin )`, `SetFocus`, `Release`.
- **Event data:** inside an ON ... action, `HMG_WebViewData()` returns a hash: NAVIGATE
  `{ "url", "success", "status" }`, MESSAGE `{ "value", "source", "trusted" }`, TITLE `{ "title" }`,
  ERROR `{ "error", "code" }`.
- **Calling Harbour from JavaScript:** `Win.Web.Bind( "name", {| a, b | ... } )` in Harbour, then
  `await hmg.call( "name", a, b )` in the page; arrays/hashes/numbers/strings/logicals convert both
  ways; a Harbour runtime error rejects the promise with its text. Only bound names are reachable,
  and only from the program's own content (HTML / FOLDER / allowed origins) - a web site the user
  navigates to cannot call Harbour.
- **Harbour to JavaScript:** `Win.Web.PostMessage( hData )`; the page listens with `hmg.on( d => ... )`;
  the page sends with `hmg.post( obj )` (ON MESSAGE).
- `PRIVATE` keeps nothing (cookies, cache) on disk. Check the runtime: `HMG_WebViewVersion()` ("" = missing).
- In HTML from the program, put data in the page with `textContent`, not `innerHTML`.

## CHART - Apache ECharts 6 charts

```
@ <row>, <col> CHART <name> [ OF <parent> ] WIDTH <w> HEIGHT <h>
      [ TYPE COLUMN | BAR | LINE | AREA | POINTS | PIE | DOUGHNUT | FUNNEL | CUSTOM ]
      [ CHARTTYPE <cType> ]            ( the type as an expression )
      [ TITLE <cTitle> ] [ CATEGORIES <aNames> ] [ SERIES <aSeries> ]
      [ LEGEND | NOLEGEND ] [ LABELS ] [ STACKED ] [ THEME "light" | "dark" ]
      [ COLORS <aColors> ] [ OPTION <cEChartsJson> ] [ INVISIBLE ]
      [ ON CLICK <action> ]            ( HMG_ChartClicked() in the action )
```

- `SERIES { { "2025", { 10, 20, 30 } }, { "2026", { 12, 18, 33 } } }`, or one series as a plain array.
  COLUMN is vertical, BAR horizontal. PIE, DOUGHNUT, FUNNEL use the first series, named by CATEGORIES.
- **Properties:** `ChartType`, `ChartTitle`, `Categories`, `Series`, `ChartOption` (setting one
  redraws), `Loaded` (read only). **Methods:** `Refresh`, `SaveImage( cPng [, nScale ] )`; also
  `HMG_ChartSaveImage( cForm, cChart, cFile [, nScale ] )`.
- **ON CLICK:** `HMG_ChartClicked()` -> `{ "series", "category", "value", "index" }`.
- **Any ECharts chart:** `TYPE CUSTOM OPTION cJson` - the JSON is the whole ECharts option
  (https://echarts.apache.org/en/option.html). Build it as a Harbour hash and convert with
  `hb_jsonEncode( h )`: `{ "series" => { { "type" => "gauge", "data" => { { "value" => 72 } } } } }`.
  With other types, OPTION is merged over the generated chart.
- JavaScript functions (formatters, `renderItem`, `echarts.registerMap` for geo maps) cannot be
  JSON: once `Win.Ch.Loaded` is .T., run `Win.Ch.ExecuteScript( "hmgChart.chart.setOption(...)" )`.
- Offline: ECharts is inside the library. `SAMPLES\Controls\ChartGallery` shows every chart type.
- **GraphPlus** (`#include "GraphPlus.ch"`) - the older graph class, drawn by ECharts in HMG5:
  `:Draw()`, `:Bitmap()`, `:Save()`, and `:Show( cForm, cChart )` for an interactive chart.

## Opt-in settings (off unless the program asks)

```harbour
SET DARKMODE ON | OFF | AUTO        // dark title bars, forms and controls; AUTO follows Windows
SET DPIAWARE PERMONITOR | SYSTEM    // sharp and correctly sized on every monitor (sizes stay 96-DPI units)
SET FILEDIALOG MODERN | CLASSIC     // GetFile/PutFile/GetFolder use the Vista+ dialogs
SET PDFENGINE WINDOWS | HARU        // SELECT PRINTER PDF through the Windows PDF printer
SET HMG LEGACY VARS ON | OFF        // OFF: no PUBLIC variable per form/control
```

Put them at the start of `Main()`, before the first window. `HMG_IsDarkMode()` tells the current
state. From HMG 3.7, also opt-in: `ROUNDED <n>` on TextBox/EditBox/RichEditBox/Frame,
`SET MSGBOXMODERN`, `SET TOOLTIPCUSTOMDRAW`, `SET TOOLTIPROUND/MARGIN/FONT/BORDERCOLOR/...`.

## Object API (optional)

```harbour
oCtl := HMG_GetControl( "Win_Main", "Txt_Name" )
? oCtl:Value              // GetProperty( "Win_Main", "Txt_Name", "Value" )
oCtl:Value := "x"         // SetProperty( ... )
oCtl:SetFocus()           // DoMethod( ... )
oCtl:Get( "Item", 3 ) ; oCtl:Set( "Item", 3, a ) ; oCtl:Do( "AddItem", x )
oWin := HMG_GetForm( "Win_Main" )
```

The objects hold only names; every call is checked against the control still being the same one (a
released control's object raises a clear runtime error instead of acting on a reused slot).

## Brought back from HMG 3.5

- MONTHCALENDAR: `WIDTH`, `HEIGHT`, `FONTCOLOR`, `OUTERFONTCOLOR`, `BACKCOLOR`, `BORDERCOLOR`,
  `TITLEFONTCOLOR`, `TITLEBACKCOLOR`, `RANGEMIN`/`RANGEMAX` (dates), `VIEW MCMV_MONTH|YEAR|DECADE|CENTURY`,
  `ON GETBOLDDAYS {| dStart, dEnd | aDates }`; properties OuterFontColor, BorderColor, TitleFontColor,
  TitleBackColor, View, VisibleMin, VisibleMax (+ FontColor, BackColor, RangeMin, RangeMax).
- GRID `RowsPerPage` (rows that fit in the visible area).
- HPDF: `@ ... HPDFPRINT cText TO r, c ... WRAP | FONTSIZEFIT | HEIGHTFIT GETBOTTOM @nBottom`,
  `BOLD IF lCond`..., `HPDFPRINT SKEW | SCALE | RENDER | CIRCLED TEXT`, `SET HPDFDOC FONT NAME/SIZE TO`.
- `HMG_CHR( n [, lCesu8 ] )`, `HMG_ASC( c )`, `HMG_CESU8( c )`, `HMG_UNCESU8( c )`.
