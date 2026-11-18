/*
 * HMG5 5.2 - TOGGLE: an on/off switch (c_toggle.c draws it).
 *
 *   @ row, col TOGGLE Tgl_1 [ OF <form> ] [ CAPTION <c> ] [ VALUE <l> ] [ WIDTH n ] [ HEIGHT n ] ;
 *      [ FONT <f> ] [ SIZE <n> ] [ BOLD ] [ ITALIC ] [ UNDERLINE ] [ STRIKEOUT ] [ TOOLTIP <t> ] ;
 *      [ BACKCOLOR <a> ] [ FONTCOLOR <a> ] [ ON GOTFOCUS <x> ] [ ON CHANGE <x> ] [ ON LOSTFOCUS <x> ] ;
 *      [ HELPID <n> ] [ INVISIBLE ] [ NOTABSTOP ]
 *   DEFINE TOGGLE Tgl_1 ... END TOGGLE (the same clauses as DEFINE CHECKBOX)
 *
 * Value is logical. A click or Space flips it and runs ON CHANGE; Value := does not.
 * Caption, Enabled, Visible, the font and colour properties work as on a CHECKBOX.
 * The parameters are those of _DefineCheckBox, so DEFINE TOGGLE shares its clauses; FIELD,
 * TRANSPARENT and ON ENTER are accepted there and not used.
 */

#include "hmg.ch"

MEMVAR _HMG_SYSDATA

FUNCTION _DefineToggle( ControlName, ParentForm, x, y, Caption, Value, ;
                        fontname, fontsize, tooltip, changeprocedure, w, h, ;
                        lostfocus, gotfocus, HelpId, invisible, notabstop, bold, italic, underline, strikeout, ;
                        field, backcolor, fontcolor, transparent, OnEnter )
   LOCAL cParentForm, mVar, k, ControlHandle, FontHandle
   LOCAL cParentTabName := "", cParentWindowName := ""

   HB_SYMBOL_UNUSED( field )
   HB_SYMBOL_UNUSED( transparent )
   HB_SYMBOL_UNUSED( OnEnter )

   hb_default( @Caption, "" )
   hb_default( @Value, .F. )
   hb_default( @w, 120 )
   hb_default( @h, 28 )
   // blocks: hb_default() would replace them (another type than "")
   IF lostfocus == NIL
      lostfocus := ""
   ENDIF
   IF gotfocus == NIL
      gotfocus := ""
   ENDIF
   IF changeprocedure == NIL
      changeprocedure := ""
   ENDIF
   hb_default( @invisible, .F. )
   hb_default( @notabstop, .F. )

   IF _HMG_SYSDATA[ 264 ] == .T.
      ParentForm := _HMG_SYSDATA[ 223 ]
      IF ! Empty( _HMG_SYSDATA[ 224 ] ) .AND. fontname == NIL
         fontname := _HMG_SYSDATA[ 224 ]
      ENDIF
      IF ! Empty( _HMG_SYSDATA[ 182 ] ) .AND. fontsize == NIL
         fontsize := _HMG_SYSDATA[ 182 ]
      ENDIF
   ENDIF
   IF _HMG_SYSDATA[ 183 ] > 0
      IF _HMG_SYSDATA[ 240 ] == .F.
         x := x + _HMG_SYSDATA[ 334 ][ _HMG_SYSDATA[ 183 ] ]
         y := y + _HMG_SYSDATA[ 333 ][ _HMG_SYSDATA[ 183 ] ]
         ParentForm := _HMG_SYSDATA[ 332 ][ _HMG_SYSDATA[ 183 ] ]
         cParentTabName := _HMG_SYSDATA[ 225 ]
         cParentWindowName := ParentForm
      ENDIF
   ENDIF
   IF ! _IsWindowDefined( ParentForm )
      MsgHMGError( "Window: " + hb_CStr( ParentForm ) + " is not defined. Program terminated" )
   ENDIF
   IF _IsControlDefined( ControlName, ParentForm )
      MsgHMGError( "Control: " + ControlName + " Of " + ParentForm + " Already defined. Program Terminated" )
   ENDIF

   mVar := "_" + ParentForm + "_" + ControlName
   cParentForm := ParentForm
   ControlHandle := INITTOGGLE( GetFormHandle( cParentForm ), Caption, x, y, w, h, Value, invisible, notabstop )

   IF fontname != NIL .AND. fontsize != NIL
      FontHandle := _SetFont( ControlHandle, fontname, fontsize, bold, italic, underline, strikeout )
   ELSE
      FontHandle := _SetFont( ControlHandle, _HMG_SYSDATA[ 342 ], _HMG_SYSDATA[ 343 ], bold, italic, underline, strikeout )
   ENDIF
   IF _HMG_SYSDATA[ 265 ] == .T.
      AAdd( _HMG_SYSDATA[ 142 ], ControlHandle )
   ENDIF
   IF tooltip != NIL
      SetToolTip( ControlHandle, tooltip, GetFormToolTipHandle( cParentForm ) )
   ENDIF

   k := _GetControlFree()
   _HMG_VarSet( mVar, k )

   _HMG_SYSDATA[ HMG_CTL_TYPE ][ k ]            := "TOGGLE"
   _HMG_SYSDATA[ HMG_CTL_NAME ][ k ]            := ControlName
   _HMG_SYSDATA[ HMG_CTL_HANDLE ][ k ]          := ControlHandle
   _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ k ]    := GetFormHandle( cParentForm )
   _HMG_SYSDATA[ HMG_CTL_ID ][ k ]              := 0
   _HMG_SYSDATA[ HMG_CTL_PROCEDURE ][ k ]       := ""
   _HMG_SYSDATA[ HMG_CTL_PAGEMAP ][ k ]         := NIL
   _HMG_SYSDATA[ HMG_CTL_VALUE ][ k ]           := NIL
   _HMG_SYSDATA[ HMG_CTL_INPUTMASK ][ k ]       := ""
   _HMG_SYSDATA[ HMG_CTL_LOSTFOCUS ][ k ]       := lostfocus
   _HMG_SYSDATA[ HMG_CTL_GOTFOCUS ][ k ]        := gotfocus
   _HMG_SYSDATA[ HMG_CTL_CHANGE ][ k ]          := changeprocedure
   _HMG_SYSDATA[ HMG_CTL_DELETED ][ k ]         := .F.
   _HMG_SYSDATA[ HMG_CTL_BKCOLOR ][ k ]         := backcolor
   _HMG_SYSDATA[ HMG_CTL_FONTCOLOR ][ k ]       := fontcolor
   _HMG_SYSDATA[ HMG_CTL_DBLCLICK ][ k ]        := ""
   _HMG_SYSDATA[ HMG_CTL_HEADCLICK ][ k ]       := {}
   _HMG_SYSDATA[ HMG_CTL_ROW ][ k ]             := y
   _HMG_SYSDATA[ HMG_CTL_COL ][ k ]             := x
   _HMG_SYSDATA[ HMG_CTL_WIDTH ][ k ]           := w
   _HMG_SYSDATA[ HMG_CTL_HEIGHT ][ k ]          := h
   _HMG_SYSDATA[ HMG_CTL_SPACING ][ k ]         := 0
   _HMG_SYSDATA[ HMG_CTL_CONTAINERROW ][ k ]    := iif( _HMG_SYSDATA[ 183 ] > 0, _HMG_SYSDATA[ 333 ][ _HMG_SYSDATA[ 183 ] ], -1 )
   _HMG_SYSDATA[ HMG_CTL_CONTAINERCOL ][ k ]    := iif( _HMG_SYSDATA[ 183 ] > 0, _HMG_SYSDATA[ 334 ][ _HMG_SYSDATA[ 183 ] ], -1 )
   _HMG_SYSDATA[ HMG_CTL_PICTURE ][ k ]         := ""
   _HMG_SYSDATA[ HMG_CTL_CONTAINERHANDLE ][ k ] := 0
   _HMG_SYSDATA[ HMG_CTL_FONTNAME ][ k ]        := fontname
   _HMG_SYSDATA[ HMG_CTL_FONTSIZE ][ k ]        := fontsize
   _HMG_SYSDATA[ HMG_CTL_FONTATTRIBUTES ][ k ]  := { bold, italic, underline, strikeout }
   _HMG_SYSDATA[ HMG_CTL_TOOLTIP ][ k ]         := tooltip
   _HMG_SYSDATA[ HMG_CTL_RANGEMIN ][ k ]        := cParentTabName
   _HMG_SYSDATA[ HMG_CTL_RANGEMAX ][ k ]        := cParentWindowName
   _HMG_SYSDATA[ HMG_CTL_CAPTION ][ k ]         := Caption
   _HMG_SYSDATA[ HMG_CTL_VISIBLE ][ k ]         := ! invisible
   _HMG_SYSDATA[ HMG_CTL_HELPID ][ k ]          := HelpId
   _HMG_SYSDATA[ HMG_CTL_FONTHANDLE ][ k ]      := FontHandle
   _HMG_SYSDATA[ HMG_CTL_BRUSHHANDLE ][ k ]     := 0
   _HMG_SYSDATA[ HMG_CTL_ENABLED ][ k ]         := .T.
   _HMG_SYSDATA[ HMG_CTL_MISCDATA1 ][ k ]       := 0
   _HMG_SYSDATA[ HMG_CTL_MISCDATA2 ][ k ]       := { NIL, NIL, NIL, NIL, NIL, NIL, NIL, NIL }
RETURN ControlHandle

/* from c_toggle.c: 1 changed by the user, 2 got the focus, 3 lost it */
FUNCTION _HMG_ToggleEvent( hWnd, nEvent )
   LOCAL k := AScan( _HMG_SYSDATA[ HMG_CTL_HANDLE ], hWnd )
   IF k > 0 .AND. ! _HMG_SYSDATA[ HMG_CTL_DELETED ][ k ]
      SWITCH nEvent
      CASE 1
         _DoControlEventProcedure( _HMG_SYSDATA[ HMG_CTL_CHANGE ][ k ], k )
         EXIT
      CASE 2
         _DoControlEventProcedure( _HMG_SYSDATA[ HMG_CTL_GOTFOCUS ][ k ], k )
         EXIT
      CASE 3
         _DoControlEventProcedure( _HMG_SYSDATA[ HMG_CTL_LOSTFOCUS ][ k ], k )
         EXIT
      ENDSWITCH
   ENDIF
RETURN NIL

/* from c_toggle.c when painting: { nBack, nFore } as COLORREF, -1 for the default */
FUNCTION _HMG_ToggleColors( hWnd )
   LOCAL k := AScan( _HMG_SYSDATA[ HMG_CTL_HANDLE ], hWnd ), i, aBack, aFore
   IF k == 0
      RETURN { -1, -1 }
   ENDIF
   aBack := _HMG_SYSDATA[ HMG_CTL_BKCOLOR ][ k ]
   aFore := _HMG_SYSDATA[ HMG_CTL_FONTCOLOR ][ k ]
   IF ! IsRGB( aBack )
      i := AScan( _HMG_SYSDATA[ HMG_FRM_HANDLE ], _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ k ] )
      aBack := iif( i > 0, _HMG_SYSDATA[ HMG_FRM_BKCOLOR ][ i ], NIL )
   ENDIF
RETURN { iif( IsRGB( aBack ), RGB( aBack[ 1 ], aBack[ 2 ], aBack[ 3 ] ), -1 ), ;
         iif( IsRGB( aFore ), RGB( aFore[ 1 ], aFore[ 2 ], aFore[ 3 ] ), -1 ) }

STATIC FUNCTION IsRGB( a )
RETURN HB_ISARRAY( a ) .AND. Len( a ) >= 3 .AND. HB_ISNUMERIC( a[ 1 ] ) .AND. a[ 1 ] >= 0 .AND. ;
       HB_ISNUMERIC( a[ 2 ] ) .AND. HB_ISNUMERIC( a[ 3 ] )
