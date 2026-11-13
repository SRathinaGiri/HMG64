/*
 * hmg_sysdata.ch - names for the _HMG_SYSDATA slots (HMG5, PHASE3-DESIGN.md step S1)
 *
 * _HMG_SYSDATA is HMG's internal state: one PUBLIC array of 522 slots. Its layout is
 * FROZEN for HMG5 (append-only): user and contrib code may read _HMG_SYSDATA[ n ] by number, and
 * the commands in INCLUDE\*.ch expand to slot numbers inside compiled programs.
 * These names are aliases for the same numbers - _HMG_SYSDATA[ HMG_CTL_HANDLE ] and
 * _HMG_SYSDATA[ 3 ] are the same slot - so either spelling keeps working.
 *
 * Names follow the MiniGUI arrays the slots came from (_HMG_aControlType ...).
 * Several slots are reused per control type; the comment lists the other uses.
 * The library is rewritten to these names mechanically and checked with
 * tools\pcode-snapshot.ps1: the generated C must stay byte-identical.
 */

#ifndef _HMG_SYSDATA_CH_
#define _HMG_SYSDATA_CH_

/* ---- Per-control columns: _HMG_SYSDATA[ HMG_CTL_xxx ][ nControlIndex ] ------------ */
#define HMG_CTL_TYPE              1    // "BUTTON", "TEXT", "GRID", ...
#define HMG_CTL_NAME              2    // control name
#define HMG_CTL_HANDLE            3    // HWND (or array of HWNDs: radio group, spinner)
#define HMG_CTL_PARENTHANDLE      4    // HWND of the parent form
#define HMG_CTL_ID                5    // control ID; also: browse vertical scrollbar, toolbutton ID
#define HMG_CTL_PROCEDURE         6    // ACTION / ON CLICK block (label: URL action)
#define HMG_CTL_PAGEMAP           7    // tab page map; also: textbox FIELD, tree item handles, hotkey modifier
#define HMG_CTL_VALUE             8    // current value / item; also: hotkey key code
#define HMG_CTL_INPUTMASK         9    // input mask; also: label TRANSPARENT, misc per type
#define HMG_CTL_LOSTFOCUS        10    // ON LOSTFOCUS
#define HMG_CTL_GOTFOCUS         11    // ON GOTFOCUS
#define HMG_CTL_CHANGE           12    // ON CHANGE; also: menu item kind ("MAIN_MENU_ITEM", ...)
#define HMG_CTL_DELETED          13    // .T. = free slot (released control)
#define HMG_CTL_BKCOLOR          14    // BACKCOLOR {r,g,b}
#define HMG_CTL_FONTCOLOR        15    // FONTCOLOR {r,g,b}
#define HMG_CTL_DBLCLICK         16    // ON DBLCLICK / ON ENTER
#define HMG_CTL_HEADCLICK        17    // grid ON HEADCLICK blocks; also: browse FIELDS
#define HMG_CTL_ROW              18    // ROW
#define HMG_CTL_COL              19    // COL
#define HMG_CTL_WIDTH            20    // WIDTH
#define HMG_CTL_HEIGHT           21    // HEIGHT
#define HMG_CTL_SPACING          22    // spacing; also: label AUTOSIZE, button picture position, browse area
#define HMG_CTL_CONTAINERROW     23    // row offset inside a frame/tab container (-1 = none)
#define HMG_CTL_CONTAINERCOL     24    // col offset inside a frame/tab container (-1 = none)
#define HMG_CTL_PICTURE          25    // picture / bitmap name(s); also: NOTABSTOP flag
#define HMG_CTL_CONTAINERHANDLE  26    // container HWND (tab, toolbar, splitbox)
#define HMG_CTL_FONTNAME         27    // FONT name
#define HMG_CTL_FONTSIZE         28    // SIZE
#define HMG_CTL_FONTATTRIBUTES   29    // {bold, italic, underline, strikeout}
#define HMG_CTL_TOOLTIP          30    // TOOLTIP
#define HMG_CTL_RANGEMIN         31    // range min; also: parent TAB name, grid/browse fields, combo parent
#define HMG_CTL_RANGEMAX         32    // range max; also: parent window name, grid CELLNAVIGATION, cargo array
#define HMG_CTL_CAPTION          33    // CAPTION; also: grid/browse headers
#define HMG_CTL_VISIBLE          34    // .T. = visible
#define HMG_CTL_HELPID           35    // HELPID
#define HMG_CTL_FONTHANDLE       36    // HFONT
#define HMG_CTL_BRUSHHANDLE      37    // HBRUSH / HBITMAP to free; also: grid column justify
#define HMG_CTL_ENABLED          38    // .T. = enabled
#define HMG_CTL_MISCDATA1        39    // per type: grid selected-cell row, image transparency, ...
#define HMG_CTL_MISCDATA2        40    // per type: property array (grid: [40][i][n] columns, edit controls ...)

/* ---- Per-form columns: _HMG_SYSDATA[ HMG_FRM_xxx ][ nFormIndex ] ------------------- */
#define HMG_FRM_DELETED          65    // .T. = free slot (released form)
#define HMG_FRM_NAME             66    // form name
#define HMG_FRM_HANDLE           67    // HWND
#define HMG_FRM_ACTIVE           68    // .T. = activated
#define HMG_FRM_TYPE             69    // "A" main, "C" child, "M" modal, "P" panel, "S" splitchild, "X" ...
#define HMG_FRM_PARENTHANDLE     70    // parent HWND (panels)
#define HMG_FRM_RELEASE          71    // ON RELEASE
#define HMG_FRM_INIT             72    // ON INIT
#define HMG_FRM_TOOLTIPHANDLE    73    // tooltip window HWND
#define HMG_FRM_CONTEXTMENU      74    // context menu HMENU
#define HMG_FRM_MOUSEDRAG        75    // ON MOUSEDRAG
#define HMG_FRM_SIZE             76    // ON SIZE
#define HMG_FRM_CLICK            77    // ON MOUSECLICK
#define HMG_FRM_MOUSEMOVE        78    // ON MOUSEMOVE
#define HMG_FRM_BKCOLOR          79    // BACKCOLOR {r,g,b}
#define HMG_FRM_PAINT            80    // ON PAINT
#define HMG_FRM_NOSHOW           81    // NOSHOW
#define HMG_FRM_NOTIFYICON       82    // NOTIFYICON name
#define HMG_FRM_NOTIFYTOOLTIP    83    // NOTIFYTOOLTIP
#define HMG_FRM_NOTIFYCLICK      84    // ON NOTIFYCLICK
#define HMG_FRM_GOTFOCUS         85    // ON GOTFOCUS
#define HMG_FRM_LOSTFOCUS        86    // ON LOSTFOCUS
#define HMG_FRM_REBARHANDLE      87    // splitbox (rebar) HWND
#define HMG_FRM_NOTIFYMENU       88    // notify-icon menu HMENU
#define HMG_FRM_BROWSELIST       89    // browses on this form (refresh list)
#define HMG_FRM_SPLITCHILDLIST   90    // split-child form indexes
#define HMG_FRM_VIRTUALHEIGHT    91    // VIRTUAL HEIGHT
#define HMG_FRM_VIRTUALWIDTH     92    // VIRTUAL WIDTH
#define HMG_FRM_FOCUSED          93    // focus flag
#define HMG_FRM_SCROLLUP         94    // ON SCROLLUP
#define HMG_FRM_SCROLLDOWN       95    // ON SCROLLDOWN
#define HMG_FRM_SCROLLLEFT       96    // ON SCROLLLEFT
#define HMG_FRM_SCROLLRIGHT      97    // ON SCROLLRIGHT
#define HMG_FRM_HSCROLLBOX       98    // ON HSCROLLBOX
#define HMG_FRM_VSCROLLBOX       99    // ON VSCROLLBOX
#define HMG_FRM_BRUSHHANDLE     100    // background HBRUSH
#define HMG_FRM_FOCUSEDCONTROL  101    // HWND that had the focus
#define HMG_FRM_GRAPHTASKS      102    // DRAW ... graph task blocks
#define HMG_FRM_MAXIMIZE        103    // ON MAXIMIZE
#define HMG_FRM_MINIMIZE        104    // ON MINIMIZE
#define HMG_FRM_AUTORELEASE     105    // .T. = release on close (not NOAUTORELEASE)
#define HMG_FRM_INTERACTIVECLOSE 106   // ON INTERACTIVECLOSE
#define HMG_FRM_ACTIVATEID      107    // activation id (_HMG_ACTIVATE_<n>)
#define HMG_FRM_RESERVED108     108    // reserved (always NIL)
#define HMG_FRM_POSITION        504    // {x, y, w, h} for virtual-size scrolling
#define HMG_FRM_MENUTOOLTIP     511    // menu tooltip HWND
#define HMG_FRM_TOOLTIPDATA     512    // tooltip settings array

/* ---- Global settings added after 3.6 (same numbers as HMG 3.7, so .ch files and
        programs stay interchangeable between 3.7 and HMG5) -------------------------- */
#define HMG_SYS_TOOLTIPSTYLE    519    // { nRadius, nMarginX, nMarginY, cFontName, nFontSize, aBorder, aBack, aFore, nGradient, nVisualStyle }
#define HMG_SYS_TOOLTIPFONT     520    // cached HFONT of the tooltip default font (0 = not created)
#define HMG_SYS_ROUNDED         521    // ROUNDED <n> clause of the control being defined (NIL = native look)

/* ---- Added by HMG5 (append-only) --------------------------------------------------- */
#define HMG_SYS_ALTCLAUSES      522    // hash: clauses of DEFINE <control> ... END <control> that have no slot of
                                       // their own (DEFINE MONTHCALENDAR: OUTERFONTCOLOR, BORDERCOLOR, TITLEFONTCOLOR,
                                       // TITLEBACKCOLOR, ON GETBOLDDAYS); emptied by each DEFINE that uses it

#endif
