/*
 * h_tooltip.prg - modern tooltip look (HMG5)
 *
 * From HMG 3.7 (2026): rounded owner-drawn tooltips with a gradient, margins, a default
 * font, and SET TOOLTIPROUND / MARGIN / FONT / BORDERCOLOR / GRADIENT / THEME.
 * HMG5: everything here is used only while SET TOOLTIPCUSTOMDRAW is ON (slot 509, default
 * .F. as in 3.6), so programs that never turn custom draw on keep the system tooltips.
 *
 * Released under the HMG licence, as the rest of HMG.
 */

#include "hmg.ch"

MEMVAR _HMG_SYSDATA

// HMG_SYS_TOOLTIPSTYLE = { nRadius, nMarginX, nMarginY, cFontName, nFontSize,
//                          aBorderColor, aBackColor, aForeColor, nGradient, nVisualStyle }
#define TTIP_RADIUS       1
#define TTIP_MARGINX      2
#define TTIP_MARGINY      3
#define TTIP_FONTNAME     4
#define TTIP_FONTSIZE     5
#define TTIP_BORDER       6
#define TTIP_BACK         7
#define TTIP_FORE         8
#define TTIP_GRADIENT     9
#define TTIP_VISUALSTYLE 10

#define TTS_USEVISUALSTYLE 0x0100
#define DEFAULT_GUI_FONT   17


FUNCTION _ToolTipRgb ( aColor, nDefault )
   IF ValType ( aColor ) == "A" .AND. HMG_LEN ( aColor ) >= 3
      RETURN RGB ( aColor [ 1 ], aColor [ 2 ], aColor [ 3 ] )
   ENDIF
RETURN nDefault


// default tooltip HFONT, created once and cached in HMG_SYS_TOOLTIPFONT
FUNCTION _ToolTipDefaultFont ()
LOCAL aGlob := _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ]

   IF _HMG_SYSDATA [ HMG_SYS_TOOLTIPFONT ] == 0
      _HMG_SYSDATA [ HMG_SYS_TOOLTIPFONT ] := HMG_CreateFontFromArrayFont ( { aGlob [ TTIP_FONTNAME ], aGlob [ TTIP_FONTSIZE ] } )
      IF _HMG_SYSDATA [ HMG_SYS_TOOLTIPFONT ] == 0
         _HMG_SYSDATA [ HMG_SYS_TOOLTIPFONT ] := GetStockObject ( DEFAULT_GUI_FONT )
      ENDIF
   ENDIF

RETURN _HMG_SYSDATA [ HMG_SYS_TOOLTIPFONT ]


// 0 = classic drawing. A TITLE or ICON keeps the classic drawing: the control lays those out
// itself and the owner-drawn gradient does not reproduce them. Balloons never get here.
STATIC FUNCTION _ToolTipGradientMode ( aData )
   IF _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ] [ TTIP_GRADIENT ] != 1
      RETURN 0
   ENDIF
   IF ValType ( aData ) == "A" .AND. HMG_LEN ( aData ) >= 6
      IF aData [ 4 ] == .T. .OR. .NOT. Empty ( aData [ 5 ] ) .OR. .NOT. Empty ( aData [ 6 ] )
         RETURN 0
      ENDIF
   ENDIF
RETURN 1


// { nBack, nFore, nBorder, nRadius, nMode }. Colours set with SET TOOLTIPBACKCOLOR /
// FORECOLOR (slots 56/57) win over the style defaults.
STATIC FUNCTION _ToolTipDrawData ( aData )
LOCAL aGlob := _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ]
LOCAL nBack := -1, nFore := -1

   IF ValType ( aData ) == "A"
      nBack := aData [ 1 ]
      nFore := aData [ 2 ]
   ENDIF
   IF nBack == -1 .AND. ValType ( _HMG_SYSDATA [ 56 ] ) == "A"
      nBack := _ToolTipRgb ( _HMG_SYSDATA [ 56 ], -1 )
   ENDIF
   IF nFore == -1 .AND. ValType ( _HMG_SYSDATA [ 57 ] ) == "A"
      nFore := _ToolTipRgb ( _HMG_SYSDATA [ 57 ], -1 )
   ENDIF
   IF nBack == -1
      nBack := _ToolTipRgb ( aGlob [ TTIP_BACK ], -1 )
   ENDIF
   IF nFore == -1
      nFore := _ToolTipRgb ( aGlob [ TTIP_FORE ], -1 )
   ENDIF

RETURN { nBack, nFore, _ToolTipRgb ( aGlob [ TTIP_BORDER ], -1 ), aGlob [ TTIP_RADIUS ], _ToolTipGradientMode ( aData ) }


// HWND of the control the tooltip belongs to (0 for SPINNER and MENU, whose handle slot is
// not a single window)
STATIC FUNCTION _ToolTipToolHandle ( i )
LOCAL h
   IF i > 0 .AND. _HMG_SYSDATA [ HMG_CTL_TYPE ] [ i ] != "MENU"
      h := _HMG_SYSDATA [ HMG_CTL_HANDLE ] [ i ]
      IF ValType ( h ) == "N"
         RETURN h
      ENDIF
   ENDIF
RETURN 0


// { hWndToolParent, nToolId } a MENU item tooltip was registered with (form, MenuItemID),
// needed to read its text; other tools are resolved in C
STATIC FUNCTION _ToolTipToolReg ( i )
   IF i > 0 .AND. _HMG_SYSDATA [ HMG_CTL_TYPE ] [ i ] == "MENU"
      RETURN { _HMG_SYSDATA [ HMG_CTL_PARENTHANDLE ] [ i ], _HMG_SYSDATA [ HMG_CTL_ID ] [ i ] }
   ENDIF
RETURN { NIL, NIL }


STATIC FUNCTION _ToolTipFontHandle ( i, k )
LOCAL hFont := 0

   IF i > 0 .AND. ValType ( _HMG_SYSDATA [ 41 ] [ i ] [ 3 ] ) == "A"
      hFont := _HMG_SYSDATA [ 41 ] [ i ] [ 3 ] [ 3 ]
   ENDIF
   IF ( ValType ( hFont ) != "N" .OR. hFont == 0 ) .AND. k > 0
      hFont := _HMG_SYSDATA [ HMG_FRM_TOOLTIPDATA ] [ k ] [ 3 ]
   ENDIF
   IF ValType ( hFont ) != "N" .OR. hFont == 0
      hFont := _ToolTipDefaultFont ()
   ENDIF

RETURN hFont


// .T. when the tooltip about to show is a balloon
FUNCTION _ToolTipIsBalloon ( i, k )
LOCAL aData

   IF i > 0
      aData := _HMG_SYSDATA [ 41 ] [ i ] [ 3 ]
      IF ValType ( aData ) == "A" .AND. ValType ( aData [ 4 ] ) == "L"
         RETURN aData [ 4 ]
      ENDIF
   ENDIF
   IF k > 0
      aData := _HMG_SYSDATA [ HMG_FRM_TOOLTIPDATA ] [ k ]
      IF ValType ( aData ) == "A"
         IF ValType ( aData [ 4 ] ) == "L"
            RETURN aData [ 4 ]
         ENDIF
         RETURN aData [ 7 ] == .T.
      ENDIF
   ENDIF

RETURN .F.


// NM_CUSTOMDRAW of a tooltip, custom draw ON. A balloon is left to comctl32: its shape
// (with the stem) exists only in its own drawing.
FUNCTION _ToolTipCustomDraw ( lParam, i, k )
LOCAL aData, aSt, aReg

   IF _ToolTipIsBalloon ( i, k )
      RETURN 0   // CDRF_DODEFAULT
   ENDIF
   IF ValType ( _HMG_SYSDATA [ 41 ] [ i ] [ 3 ] ) == "A"
      aData := _HMG_SYSDATA [ 41 ] [ i ] [ 3 ]
   ELSE
      aData := _HMG_SYSDATA [ HMG_FRM_TOOLTIPDATA ] [ k ]
   ENDIF
   aSt  := _ToolTipDrawData ( aData )
   aReg := _ToolTipToolReg ( i )

RETURN TOOLTIP_CUSTOMDRAW ( lParam, aSt [ 1 ], aSt [ 2 ], aSt [ 3 ], aSt [ 4 ], aSt [ 5 ], ;
                            _ToolTipToolHandle ( i ), _ToolTipFontHandle ( i, k ), aReg [ 1 ], aReg [ 2 ] )


// margins (and theme) of a new tooltip window. Only with custom draw ON: otherwise the
// tooltip is left exactly as the system made it.
PROCEDURE _ApplyToolTipStyle ( hWndToolTip )
LOCAL aGlob := _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ]

   IF _HMG_SYSDATA [ 509 ] != .T. .OR. ValType ( hWndToolTip ) != "N" .OR. hWndToolTip == 0
      RETURN
   ENDIF
   // a themed tooltip ignores TTM_SETMARGIN; balloons keep the theme (comctl32 draws them)
   ToolTip_SetUiTheme ( hWndToolTip, HMG_IsWindowStyle ( hWndToolTip, TTS_BALLOON ) == .F. )
   ToolTip_SetMargin ( hWndToolTip, aGlob [ TTIP_MARGINX ], aGlob [ TTIP_MARGINY ] )
   IF aGlob [ TTIP_VISUALSTYLE ] == 1
      HMG_ChangeWindowStyle ( hWndToolTip, TTS_USEVISUALSTYLE, NIL, .F., .F. )
   ENDIF

RETURN


// shape of the tooltip about to show: native balloon, or HMG's rounded box. The region is
// set here (TTN_SHOW) because the window is 0x0 until it is shown.
PROCEDURE _ToolTipBalloonStyle ( hWndToolTip, lBalloon )
LOCAL aGlob := _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ]
LOCAL lIsBalloon := HMG_IsWindowStyle ( hWndToolTip, TTS_BALLOON )

   IF lBalloon == .T.
      HMG_ChangeWindowStyle ( hWndToolTip, TTS_BALLOON, TTS_USEVISUALSTYLE, .F., .NOT. lIsBalloon )
   ELSE
      HMG_ChangeWindowStyle ( hWndToolTip, IIF ( aGlob [ TTIP_VISUALSTYLE ] == 1, TTS_USEVISUALSTYLE, 0 ), ;
                              TTS_BALLOON, .F., lIsBalloon )
      ToolTip_ApplyStyle ( hWndToolTip, aGlob [ TTIP_RADIUS ] )
   ENDIF

RETURN


// MENU tooltip: only the TTS_BALLOON bit moves, as in 3.6. A frame change or a region
// while the menu is open would close the menu.
PROCEDURE _ToolTipMenuBalloonStyle ( hWndToolTip, lBalloon )
   IF lBalloon == .T.
      HMG_ChangeWindowStyle ( hWndToolTip, TTS_BALLOON, NIL, .F., .F. )
   ELSE
      HMG_ChangeWindowStyle ( hWndToolTip, NIL, TTS_BALLOON, .F., .F. )
   ENDIF
RETURN


// re-apply the style to the tooltips already created (form and menu tooltips). No region
// here: a tooltip that is not showing is 0x0, and an empty region would hide it for good.
PROCEDURE _RefreshToolTipStyle ()
LOCAL j, n, hWndToolTip

   FOR EACH n IN { HMG_FRM_TOOLTIPHANDLE, HMG_FRM_MENUTOOLTIP }
      IF ValType ( _HMG_SYSDATA [ n ] ) == "A"
         FOR j := 1 TO HMG_LEN ( _HMG_SYSDATA [ n ] )
            hWndToolTip := _HMG_SYSDATA [ n ] [ j ]
            IF ValType ( hWndToolTip ) == "N" .AND. hWndToolTip != 0
               _ApplyToolTipStyle ( hWndToolTip )
            ENDIF
         NEXT
      ENDIF
   NEXT

RETURN


// SET TOOLTIPCUSTOMDRAW OFF: give the existing tooltips their native theme and shape back
PROCEDURE _ResetToolTipStyle ()
LOCAL j, n, hWndToolTip

   FOR EACH n IN { HMG_FRM_TOOLTIPHANDLE, HMG_FRM_MENUTOOLTIP }
      IF ValType ( _HMG_SYSDATA [ n ] ) == "A"
         FOR j := 1 TO HMG_LEN ( _HMG_SYSDATA [ n ] )
            hWndToolTip := _HMG_SYSDATA [ n ] [ j ]
            IF ValType ( hWndToolTip ) == "N" .AND. hWndToolTip != 0
               ToolTip_SetUiTheme ( hWndToolTip, .F. )
               ToolTip_ApplyStyle ( hWndToolTip, 0 )
            ENDIF
         NEXT
      ENDIF
   NEXT

RETURN


PROCEDURE SetToolTipRound ( nRadius )
   IF ValType ( nRadius ) == "N"
      _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ] [ TTIP_RADIUS ] := nRadius
      _RefreshToolTipStyle ()
   ENDIF
RETURN


PROCEDURE SetToolTipMargins ( nMarginX, nMarginY )
   IF ValType ( nMarginX ) == "N" .AND. ValType ( nMarginY ) == "N"
      _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ] [ TTIP_MARGINX ] := nMarginX
      _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ] [ TTIP_MARGINY ] := nMarginY
      _RefreshToolTipStyle ()
   ENDIF
RETURN


PROCEDURE SetToolTipFont ( cFontName, nFontSize )
   IF HB_ISCHAR ( cFontName ) .AND. .NOT. Empty ( cFontName ) .AND. ValType ( nFontSize ) == "N" .AND. nFontSize > 0
      _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ] [ TTIP_FONTNAME ] := cFontName
      _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ] [ TTIP_FONTSIZE ] := nFontSize
      IF _HMG_SYSDATA [ HMG_SYS_TOOLTIPFONT ] != 0 .AND. _HMG_SYSDATA [ HMG_SYS_TOOLTIPFONT ] != GetStockObject ( DEFAULT_GUI_FONT )
         DeleteObject ( _HMG_SYSDATA [ HMG_SYS_TOOLTIPFONT ] )
      ENDIF
      _HMG_SYSDATA [ HMG_SYS_TOOLTIPFONT ] := 0       // re-created for the next tooltip shown
   ENDIF
RETURN


PROCEDURE SetToolTipBorderColor ( aBorderColor )
   IF ValType ( aBorderColor ) == "A"
      _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ] [ TTIP_BORDER ] := aBorderColor
   ENDIF
RETURN


PROCEDURE SetToolTipGradient ( lOn )
   IF HB_ISLOGICAL ( lOn )
      _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ] [ TTIP_GRADIENT ] := IIF ( lOn, 1, 0 )
   ENDIF
RETURN


PROCEDURE SetToolTipVisualStyle ( lOn )
   IF HB_ISLOGICAL ( lOn )
      _HMG_SYSDATA [ HMG_SYS_TOOLTIPSTYLE ] [ TTIP_VISUALSTYLE ] := IIF ( lOn, 1, 0 )
      _RefreshToolTipStyle ()
   ENDIF
RETURN
