# HMG5 additions (not in HMG 3.x)

Check the target first: these need HMG5 (`HMGVersion()` returns "HMG 5.0 ..." or "HMG 5.1 ..."; drag and drop needs 5.1). Everything else in
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

## Drag and drop - LISTBOX and GRID (HMG5 5.1)

```
@ <row>, <col> LISTBOX | GRID <name> ...
      [ DRAGSOURCE ]      items can be dragged out of the control
      [ DROPTARGET ]      items can be dropped on it
      [ DRAGREMOVE ]      dropped away from every drop target, they are removed (implies DRAGSOURCE)
      [ ON DROP <action> ]  runs instead of the default move / copy / remove
```

- DEFINE syntax: `DRAGSOURCE .T.`, `DROPTARGET .T.`, `DRAGREMOVE .T.`, `ON DROP <action>` (or
  `ONDROP`). The IDE Form Designer has them as properties DragSource, DropTarget, DragRemove and
  the event OnDrop.
- Without ON DROP the selected items **move** (all of a MULTISELECT selection); **Ctrl** at the
  drop copies; **Esc** or the right button cancels. A line shows where they land; dropping inside
  the same control reorders it. A SORT list box sorts what it receives. List box text <-> grid
  row: the text goes to (comes from) the first column; rows are padded/cut to the target's columns.
- **Inside ON DROP** (the target's; for a DRAGREMOVE drop away, the source's): `This.DragForm`,
  `This.DragControl` (where the items came from), `This.DragItems` (their rows, ascending),
  `This.DragData` (list box texts or grid row arrays), `This.DropRow` (row of the first dropped
  item; 0 for a SORT list box), `This.DropCopy`, `This.DropOutside`. Call `HMG_DragDefault()` to
  do the default afterwards (e.g. after asking the user); not calling it leaves both controls as
  they were.
- A VIRTUAL grid (rows are the program's) is a drop target only with ON DROP; as a source its
  items are copied, never deleted, and `This.DragData` holds NIL for each row - use `This.DragItems`.
- Works between controls of different windows of the same program; not with other programs or
  Explorer files. TREE is not supported. `SAMPLES\Controls\DragDrop` shows it all.

## Fast VIRTUAL grid from an array - ROWSOURCE (HMG5 5.2)

```harbour
@ 10, 10 GRID Grid_1 OF Win_1 WIDTH 600 HEIGHT 300 ;
   HEADERS { "Name", "Qty", "Date" } WIDTHS { 250, 100, 120 } ;
   ROWSOURCE aRows                     // aRows := { { "Apple", 10, Date() }, ... }

AAdd( aRows, { "Pear", 3, Date() } )
Win_1.Grid_1.Refresh                   // the grid shows the array's rows and values again
Win_1.Grid_1.RowSource := aOtherRows   // another array; NIL unbinds
```

- The grid is VIRTUAL and keeps a reference to the array (no copy): cells are read in C,
  no Harbour code per cell, so large arrays (100,000 rows) scroll as fast as Windows draws.
- Values are shown as with ON QUERYDATA: character RTrim, number Str(), date DToC(),
  logical .T./.F., others empty; a short row shows empty cells; a row that is not an array
  is column 1; with IMAGE, column 1 is the image index.
- Assigning a new array to the program's variable does not rebind the grid: use RowSource.
- With EDIT / ALLOWEDIT and COLUMNCONTROLS the grid is editable with no code: the editor gets
  the typed value from the array and the edit is written back into `aRows[ row, col ]`
  (a short row grows). COLUMNWHEN / COLUMNVALID see the same values. (A VIRTUAL grid with
  ON QUERYDATA still keeps no edit by itself.)
- `ROWSOURCE "alias"` (a table) is unchanged. Use ON QUERYDATA when cells are computed.

## HTTP and HTTPS - HMG_HttpGet / HMG_HttpPost (HMG5 5.2)

```harbour
a := HMG_HttpGet( "https://api.example.com/rates?x=1" [, aHeaders] [, nTimeoutMs] )
a := HMG_HttpPost( cUrl, hb_jsonEncode( hData ) [, cContentType] [, aHeaders] [, nTimeoutMs] )
a := HMG_HttpRequest( "PUT", cUrl [, cBody] [, aHeaders] [, nTimeoutMs] [, cContentType] )
IF a[ 1 ] == 200            // a[1] status, 0 = no answer; a[2] body; a[3] error text; a[4] headers
   hb_jsonDecode( a[ 2 ], @hResult )
ELSE
   MsgStop( iif( a[ 1 ] == 0, a[ 3 ], "HTTP " + hb_ntos( a[ 1 ] ) + ": " + a[ 2 ] ) )
ENDIF
```

- Windows' WinHTTP: TLS with the system's certificates, the user's proxy, redirects, gzip. No
  OpenSSL, no hbssl/hbtip SSL, no DLLs; nothing to link (hmg64.hbc adds winhttp).
- aHeaders: `"Name: value"` strings or `{ "Name", "value" }` pairs. HMG_HttpPost guesses the
  Content-Type from the body: `{`/`[` JSON, `<` XML, otherwise a form; pass cContentType to choose.
- Bodies are bytes: UTF-8 stays UTF-8; a UTF-16 answer (BOM or charset=utf-16) is converted.
- An HTTP error (404, 500) is a status with its body, not an error; a[3] is set only when no
  answer came (no network, refused, TLS, timeout), never a runtime error.
- The call waits (default 30 s; WinHTTP retries a timed-out request once). For long calls in a
  window, show the user that work is going on.
- Replaces `CreateObject( "Msxml2.XMLHTTP.6.0" )` / ServerXMLHTTP calls one for one.

## Long jobs without freezing - HMG_Busy (HMG5 5.2)

```harbour
aRows := HMG_Busy( "Loading", {| oBusy | LoadAll( oBusy ) } )   // returns what the job returns

FUNCTION LoadAll( oBusy )
   LOCAL n, aRows := {}
   FOR n := 1 TO 12
      IF ! oBusy:Step( n - 1, 12, "Month " + hb_ntos( n ) )   // .F. after Cancel / Esc / X
         RETURN NIL
      ENDIF
      ... one month of work ...
   NEXT
RETURN aRows
```

- A small modal window (text, progress bar, Cancel) runs the job in the program's own thread;
  the other windows are disabled meanwhile. `oBusy:Step( nDone, nTotal [, cText] )`,
  `oBusy:Text( cText )` repaint and handle messages at most every 50 ms, so Windows never shows
  "Not Responding" and tight loops stay fast. No nTotal: a moving (marquee) bar.
- `oBusy:Cancelled` is .T. after Cancel, Esc or the window's X; the job decides when to stop.
  `HMG_Busy( cTitle, bJob, .F. )` shows no Cancel button.
- WAIT WINDOW ... NOWAIT only shows a message: it neither handles messages nor offers Cancel,
  so a long job behind it still freezes the window. Use HMG_Busy for anything over a second.

## Grid export to CSV and Excel (HMG5 5.2)

```harbour
Win_1.Grid_1.ExportCSV( "C:\out\sales.csv" [, lHeaders] [, cSeparator] )
Win_1.Grid_1.ExportXLSX( "C:\out\sales.xlsx" [, cSheet] [, lHeaders] )
lOk := HMG_GridExportCSV( "Win_1", "Grid_1", cFile [, lHeaders] [, cSeparator] )   // .T./.F.
lOk := HMG_GridExportXLSX( "Win_1", "Grid_1", cFile [, cSheet] [, lHeaders] )
```

- Any GRID: items, VIRTUAL with ON QUERYDATA or ROWSOURCE array, or a table. The grid's own
  (typed) values are exported, text without trailing spaces as the grid shows it.
- CSV: UTF-8 with BOM (Excel reads every language), quoted as Excel expects, numbers with a
  point, dates YYYY-MM-DD, logicals TRUE/FALSE.
- XLSX is written by HMG itself (no Excel, no extra library): numbers stay numbers, dates are
  real dates (shown in the user's date format), header row bold and frozen, grid column widths.
- The methods return nothing; use the functions to know whether the file was written.

## Files dropped from Explorer - ON DROPFILES (HMG5 5.2)

```harbour
DEFINE WINDOW Win_1 ...
   ON DROPFILES ACTION OpenFiles( This.DroppedFiles )        // the window (OF left out inside DEFINE WINDOW)
   @ 10, 10 TEXTBOX Txt_File WIDTH 300
   ON DROPFILES CONTROL Txt_File ACTION Win_1.Txt_File.Value := This.DroppedFiles[ 1 ]
END WINDOW
ON DROPFILES OF Win_2 CONTROL Grid_1 ACTION ImportFiles( This.DroppedFiles )   // any time after
RELEASE DROPFILES OF Win_1 [ CONTROL Txt_File ]
HMG_DropFiles( cForm, cControl | NIL, bAction | NIL )   // the same as a function
```

- `This.DroppedFiles`: the full paths, an array. Any window or control; a drop on a control
  without its own ON DROPFILES goes to its window's. Works when the program runs elevated too.
- Not the same as drag and drop between LISTBOX/GRID controls (DRAGSOURCE / DROPTARGET).

## Hint text in empty boxes - PLACEHOLDER (HMG5 5.2)

```harbour
@ 10, 10 TEXTBOX Txt_Search WIDTH 250 PLACEHOLDER "Search customers..."
@ 40, 10 COMBOBOX Cmb_City WIDTH 250 ITEMS aCities PLACEHOLDER "Choose a city"
Win_1.Txt_Search.Placeholder := "Search by GSTIN"      // or read it
```

- Windows' own grey hint: a plain TEXTBOX (also NUMERIC) shows it until something is typed,
  even with the focus; a COMBOBOX while nothing is chosen. Also in DEFINE TEXTBOX /
  DEFINE COMBOBOX (`PLACEHOLDER "..."`). Masked and date TEXTBOXes are never empty: no hint.

## Two panes resized with the mouse - SPLITTER (HMG5 5.2)

```harbour
@ 10, 10 GRID Grid_Files WIDTH 290 HEIGHT 440 ...
@ 10, 300 SPLITTER Spl_Side HEIGHT 440 ;                    // VERTICAL is the default
   BETWEEN { "Grid_Files" } AND { "Edt_Notes", "Edt_Log" } MINSIZE 120 ;
   ON CHANGE ShowPlaces()
@ 10, 306 EDITBOX Edt_Notes WIDTH 504 HEIGHT 214
@ 224, 306 SPLITTER Spl_Notes WIDTH 504 HORIZONTAL BETWEEN { "Edt_Notes" } AND { "Edt_Log" }
@ 230, 306 EDITBOX Edt_Log WIDTH 504 HEIGHT 220
Win_1.Spl_Side.Position := 300                              // or read it (column; row if HORIZONTAL)
```

- The bar is 6 thick by default (WIDTH for VERTICAL, HEIGHT for HORIZONTAL). Dragging it: the
  controls in BETWEEN's first array end at the bar, those in the second start right after it
  and keep their right (bottom) edge. Define them touching the bar.
- MINSIZE (default 20): the smallest width (height) left on either side; Position := is kept
  within it too. ON CHANGE runs once when a drag ends (not after Esc, not for Position :=).
- Esc while dragging puts everything back. Not inside a TAB page (an error says so).

## On/off switch - TOGGLE (HMG5 5.2)

```harbour
@ 20, 20 TOGGLE Tgl_Wifi CAPTION "Wi-Fi" VALUE .T. WIDTH 200 ON CHANGE ShowState()
DEFINE TOGGLE Tgl_Fixed            // DEFINE form: the same clauses as DEFINE CHECKBOX
   ROW 60
   COL 20
   CAPTION "Location"
END TOGGLE
lOn := Win_1.Tgl_Wifi.Value        // logical; Win_1.Tgl_Wifi.Value := .F. (no ON CHANGE)
```

- A switch drawn by HMG: accent colour when on, an outline when off, grey when disabled; follows
  SET DARKMODE and DPI. A click or Space flips it and runs ON CHANGE (This.Value is the new value).
- Clauses as CHECKBOX: CAPTION (optional), WIDTH (default 120), HEIGHT (28), FONT, SIZE, BOLD...,
  TOOLTIP, BACKCOLOR (default: the form's), FONTCOLOR, ON GOTFOCUS, ON LOSTFOCUS, HELPID,
  INVISIBLE, NOTABSTOP. No FIELD. Works on TAB pages.

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
