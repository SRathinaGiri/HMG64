/*
 * HMG5 5.2 - PLACEHOLDER: the grey hint text Windows shows in an empty TEXTBOX or COMBOBOX.
 *
 *   @ r, c TEXTBOX Txt_Search ... PLACEHOLDER "Search customers..."
 *   @ r, c COMBOBOX Cmb_City ... PLACEHOLDER "Choose a city"
 *   DEFINE TEXTBOX / DEFINE COMBOBOX ... PLACEHOLDER "..." ... END
 *   Form.Control.Placeholder := "..."   /   cHint := Form.Control.Placeholder
 *
 * A plain TEXTBOX (not a masked or date one: those are never empty) shows it until text is
 * typed, also while it has the focus; a COMBOBOX while nothing is chosen or typed.
 * c_placeholder.c: EM_SETCUEBANNER / CB_SETCUEBANNER.
 */

#include "hmg.ch"

MEMVAR _HMG_SYSDATA

/* called by the clause right after the control is defined; cText NIL: nothing to do */
FUNCTION _HMG_SetPlaceholder( cControl, cForm, cText )
   IF cText == NIL
      RETURN NIL
   ENDIF
   /* the window the control was just defined in, found as _DefineTextBox finds it */
   IF _HMG_SYSDATA[ 264 ] == .T.
      cForm := _HMG_SYSDATA[ 223 ]   // inside DEFINE WINDOW
   ENDIF
   IF _HMG_SYSDATA[ 183 ] > 0 .AND. _HMG_SYSDATA[ 240 ] == .F.
      cForm := _HMG_SYSDATA[ 332 ][ _HMG_SYSDATA[ 183 ] ]   // inside a TAB page
   ENDIF
RETURN _HMG_PlaceholderSet( cControl, cForm, cText )

FUNCTION _HMG_PlaceholderSet( cControl, cForm, cText )
   LOCAL cType := GetControlType( cControl, cForm ), hWnd := GetControlHandle( cControl, cForm )
   IF HB_ISARRAY( hWnd )
      hWnd := hWnd[ 1 ]
   ENDIF
   DO CASE
   CASE cType == "TEXT" .OR. cType == "NUMTEXT"
      RETURN HMG_SETCUEBANNER( hWnd, hb_CStr( cText ), .F. )
   CASE cType == "COMBO"
      RETURN HMG_SETCUEBANNER( hWnd, hb_CStr( cText ), .T. )
   ENDCASE
   MsgHMGError( "PLACEHOLDER: " + cControl + " Of " + cForm + " is not a TEXTBOX or a COMBOBOX (" + cType + "). Program Terminated" )
RETURN .F.

FUNCTION _HMG_PlaceholderGet( cControl, cForm )
   LOCAL cType := GetControlType( cControl, cForm ), hWnd := GetControlHandle( cControl, cForm )
   IF HB_ISARRAY( hWnd )
      hWnd := hWnd[ 1 ]
   ENDIF
   IF cType == "TEXT" .OR. cType == "NUMTEXT" .OR. cType == "COMBO"
      RETURN HMG_GETCUEBANNER( hWnd, cType == "COMBO" )
   ENDIF
RETURN ""
