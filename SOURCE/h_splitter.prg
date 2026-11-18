/*
 * HMG5 5.2 - SPLITTER: a thin bar the mouse drags to share space between the controls on its
 * two sides (c_splitter.c draws it and follows the mouse).
 *
 *   @ row, col SPLITTER Spl_1 [ OF <form> ] [ VERTICAL | HORIZONTAL ] [ WIDTH n ] [ HEIGHT n ] ;
 *      BETWEEN { "Grid_Left" } AND { "Edit_Right", "Btn_Ok" } [ MINSIZE n ] [ ON CHANGE <action> ] [ INVISIBLE ]
 *
 * VERTICAL (the default): an upright bar dragged left and right; the controls BETWEEN keep their
 * left edge and end at the bar, the controls AND keep their right edge and start after it.
 * HORIZONTAL: a lying bar dragged up and down; BETWEEN above, AND below. MINSIZE (default 20) is
 * the least width or height left to any of them. ON CHANGE runs when a drag ends.
 * Property Position: the bar's column (VERTICAL) or row (HORIZONTAL); setting it lays out too.
 * Esc during a drag puts everything back.
 */

#include "hmg.ch"

MEMVAR _HMG_SYSDATA

#define SPL_VERTICAL   1
#define SPL_BEFORE     2
#define SPL_AFTER      3
#define SPL_MINSIZE    4
#define SPL_START      5   /* the place when the drag began */

FUNCTION _DefineSplitter( ControlName, ParentForm, x, y, w, h, lVertical, aBefore, aAfter, nMinSize, bChange, lInvisible )
   LOCAL mVar, k, hWnd, cParentForm

   hb_default( @lVertical, .T. )
   hb_default( @nMinSize, 20 )
   hb_default( @lInvisible, .F. )
   IF HB_ISSTRING( aBefore )
      aBefore := { aBefore }
   ENDIF
   IF HB_ISSTRING( aAfter )
      aAfter := { aAfter }
   ENDIF
   hb_default( @aBefore, {} )
   hb_default( @aAfter, {} )
   hb_default( @w, iif( lVertical, 6, 100 ) )
   hb_default( @h, iif( lVertical, 100, 6 ) )

   IF _HMG_SYSDATA[ 264 ] == .T.
      ParentForm := _HMG_SYSDATA[ 223 ]
   ENDIF
   IF _HMG_SYSDATA[ 183 ] > 0
      MsgHMGError( "SPLITTER: inside a TAB page is not supported. Program Terminated" )
   ENDIF
   IF ! _IsWindowDefined( ParentForm )
      MsgHMGError( "Window: " + hb_CStr( ParentForm ) + " is not defined. Program terminated" )
   ENDIF
   IF _IsControlDefined( ControlName, ParentForm )
      MsgHMGError( "Control: " + ControlName + " Of " + ParentForm + " Already defined. Program Terminated" )
   ENDIF

   cParentForm := ParentForm
   mVar := "_" + ParentForm + "_" + ControlName
   hWnd := INITSPLITTER( GetFormHandle( ParentForm ), x, y, w, h, lVertical, lInvisible )

   k := _GetControlFree()
   _HMG_VarSet( mVar, k )

   _HMG_SYSDATA[ HMG_CTL_TYPE ][ k ]            := "SPLITTER"
   _HMG_SYSDATA[ HMG_CTL_NAME ][ k ]            := ControlName
   _HMG_SYSDATA[ HMG_CTL_HANDLE ][ k ]          := hWnd
   _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ k ]    := GetFormHandle( cParentForm )
   _HMG_SYSDATA[ HMG_CTL_ID ][ k ]              := 0
   _HMG_SYSDATA[ HMG_CTL_PROCEDURE ][ k ]       := ""
   _HMG_SYSDATA[ HMG_CTL_PAGEMAP ][ k ]         := { lVertical, aBefore, aAfter, nMinSize, NIL }
   _HMG_SYSDATA[ HMG_CTL_VALUE ][ k ]           := NIL
   _HMG_SYSDATA[ HMG_CTL_INPUTMASK ][ k ]       := ""
   _HMG_SYSDATA[ HMG_CTL_LOSTFOCUS ][ k ]       := ""
   _HMG_SYSDATA[ HMG_CTL_GOTFOCUS ][ k ]        := ""
   _HMG_SYSDATA[ HMG_CTL_CHANGE ][ k ]          := bChange
   _HMG_SYSDATA[ HMG_CTL_DELETED ][ k ]         := .F.
   _HMG_SYSDATA[ HMG_CTL_BKCOLOR ][ k ]         := NIL
   _HMG_SYSDATA[ HMG_CTL_FONTCOLOR ][ k ]       := NIL
   _HMG_SYSDATA[ HMG_CTL_DBLCLICK ][ k ]        := ""
   _HMG_SYSDATA[ HMG_CTL_HEADCLICK ][ k ]       := {}
   _HMG_SYSDATA[ HMG_CTL_ROW ][ k ]             := y
   _HMG_SYSDATA[ HMG_CTL_COL ][ k ]             := x
   _HMG_SYSDATA[ HMG_CTL_WIDTH ][ k ]           := w
   _HMG_SYSDATA[ HMG_CTL_HEIGHT ][ k ]          := h
   _HMG_SYSDATA[ HMG_CTL_SPACING ][ k ]         := 0
   _HMG_SYSDATA[ HMG_CTL_CONTAINERROW ][ k ]    := -1
   _HMG_SYSDATA[ HMG_CTL_CONTAINERCOL ][ k ]    := -1
   _HMG_SYSDATA[ HMG_CTL_PICTURE ][ k ]         := ""
   _HMG_SYSDATA[ HMG_CTL_CONTAINERHANDLE ][ k ] := 0
   _HMG_SYSDATA[ HMG_CTL_FONTNAME ][ k ]        := ""
   _HMG_SYSDATA[ HMG_CTL_FONTSIZE ][ k ]        := 0
   _HMG_SYSDATA[ HMG_CTL_FONTATTRIBUTES ][ k ]  := { .F., .F., .F., .F. }
   _HMG_SYSDATA[ HMG_CTL_TOOLTIP ][ k ]         := ""
   _HMG_SYSDATA[ HMG_CTL_RANGEMIN ][ k ]        := ""
   _HMG_SYSDATA[ HMG_CTL_RANGEMAX ][ k ]        := ""
   _HMG_SYSDATA[ HMG_CTL_CAPTION ][ k ]         := ""
   _HMG_SYSDATA[ HMG_CTL_VISIBLE ][ k ]         := ! lInvisible
   _HMG_SYSDATA[ HMG_CTL_HELPID ][ k ]          := 0
   _HMG_SYSDATA[ HMG_CTL_FONTHANDLE ][ k ]      := 0
   _HMG_SYSDATA[ HMG_CTL_BRUSHHANDLE ][ k ]     := 0
   _HMG_SYSDATA[ HMG_CTL_ENABLED ][ k ]         := .T.
   _HMG_SYSDATA[ HMG_CTL_MISCDATA1 ][ k ]       := 0
   _HMG_SYSDATA[ HMG_CTL_MISCDATA2 ][ k ]       := { NIL, NIL, NIL, NIL, NIL, NIL, NIL, NIL }
RETURN hWnd

/* the form name of control k */
STATIC FUNCTION FormOf( k )
   LOCAL i := AScan( _HMG_SYSDATA[ HMG_FRM_HANDLE ], _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ k ] )
RETURN iif( i > 0, _HMG_SYSDATA[ HMG_FRM_NAME ][ i ], "" )

/* { nStart, nEnd } of a control along the splitter's axis (col and right edge, or row and bottom) */
STATIC FUNCTION Span( cForm, cCtl, lVertical )
   LOCAL n := GetProperty( cForm, cCtl, iif( lVertical, "Col", "Row" ) )
RETURN { n, n + GetProperty( cForm, cCtl, iif( lVertical, "Width", "Height" ) ) }

/* nPos kept inside the limits the controls and MINSIZE allow */
STATIC FUNCTION Clamp( k, nPos )
   LOCAL a := _HMG_SYSDATA[ HMG_CTL_PAGEMAP ][ k ], cForm := FormOf( k ), c, s
   LOCAL lV := a[ SPL_VERTICAL ], nThick := iif( lV, _HMG_SYSDATA[ HMG_CTL_WIDTH ][ k ], _HMG_SYSDATA[ HMG_CTL_HEIGHT ][ k ] )
   LOCAL nMin := 0, nMax := iif( lV, GetProperty( cForm, "ClientAreaWidth" ), GetProperty( cForm, "ClientAreaHeight" ) ) - nThick
   FOR EACH c IN a[ SPL_BEFORE ]
      IF _IsControlDefined( c, cForm )
         nMin := Max( nMin, Span( cForm, c, lV )[ 1 ] + a[ SPL_MINSIZE ] )
      ENDIF
   NEXT
   FOR EACH c IN a[ SPL_AFTER ]
      IF _IsControlDefined( c, cForm )
         s := Span( cForm, c, lV )
         nMax := Min( nMax, s[ 2 ] - a[ SPL_MINSIZE ] - nThick )
      ENDIF
   NEXT
   IF nMax < nMin
      nMax := nMin
   ENDIF
RETURN Max( nMin, Min( nPos, nMax ) )

/* moves the bar to nPos and the controls on both sides with it */
STATIC PROCEDURE LayOut( k, nPos )
   LOCAL a := _HMG_SYSDATA[ HMG_CTL_PAGEMAP ][ k ], cForm := FormOf( k ), c, s
   LOCAL lV := a[ SPL_VERTICAL ], cName := _HMG_SYSDATA[ HMG_CTL_NAME ][ k ]
   LOCAL nThick := iif( lV, _HMG_SYSDATA[ HMG_CTL_WIDTH ][ k ], _HMG_SYSDATA[ HMG_CTL_HEIGHT ][ k ] )

   FOR EACH c IN a[ SPL_BEFORE ]
      IF _IsControlDefined( c, cForm )
         s := Span( cForm, c, lV )
         SetProperty( cForm, c, iif( lV, "Width", "Height" ), Max( 0, nPos - s[ 1 ] ) )
      ENDIF
   NEXT
   FOR EACH c IN a[ SPL_AFTER ]
      IF _IsControlDefined( c, cForm )
         s := Span( cForm, c, lV )   // its far edge stays
         SetProperty( cForm, c, iif( lV, "Col", "Row" ), nPos + nThick )
         SetProperty( cForm, c, iif( lV, "Width", "Height" ), Max( 0, s[ 2 ] - ( nPos + nThick ) ) )
      ENDIF
   NEXT
   SetProperty( cForm, cName, iif( lV, "Col", "Row" ), nPos )
RETURN

/* from c_splitter.c: 1 drag starts, 2 moves, 3 ends, 4 cancelled (Esc) */
FUNCTION _HMG_SplitterEvent( hWnd, nEvent, nPos )
   LOCAL k := AScan( _HMG_SYSDATA[ HMG_CTL_HANDLE ], hWnd ), a
   IF k == 0 .OR. _HMG_SYSDATA[ HMG_CTL_DELETED ][ k ]
      RETURN NIL
   ENDIF
   a := _HMG_SYSDATA[ HMG_CTL_PAGEMAP ][ k ]
   SWITCH nEvent
   CASE 1
      a[ SPL_START ] := nPos
      EXIT
   CASE 2
   CASE 4
      LayOut( k, iif( nEvent == 4, nPos, Clamp( k, nPos ) ) )
      EXIT
   CASE 3
      IF a[ SPL_START ] != NIL .AND. nPos != a[ SPL_START ]
         _DoControlEventProcedure( _HMG_SYSDATA[ HMG_CTL_CHANGE ][ k ], k )
      ENDIF
      a[ SPL_START ] := NIL
      EXIT
   ENDSWITCH
RETURN NIL

/* Form.Spl.Position := n (SetProperty): the bar and the controls, within the limits */
FUNCTION _HMG_SplitterSetPos( cControl, cForm, nPos )
   LOCAL k := GetControlIndex( cControl, cForm )
   IF k > 0 .AND. HB_ISNUMERIC( nPos )
      LayOut( k, Clamp( k, nPos ) )
   ENDIF
RETURN NIL

FUNCTION _HMG_SplitterGetPos( cControl, cForm )
   LOCAL k := GetControlIndex( cControl, cForm )
RETURN iif( k > 0, GetProperty( cForm, cControl, iif( _HMG_SYSDATA[ HMG_CTL_PAGEMAP ][ k ][ SPL_VERTICAL ], "Col", "Row" ) ), 0 )
