/*----------------------------------------------------------------------------
 HMG5 - per-monitor DPI, PRG side (Phase 4 D). C side and the rules: c_dpi.c.

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).
---------------------------------------------------------------------------*/

MEMVAR _HMG_SYSDATA

#include "hmg.ch"

/* HMG_SetPerMonitorDpi( lOn ) -> lActive
   SET DPIAWARE PERMONITOR / SET DPIAWARE SYSTEM. Must run before the first
   DEFINE WINDOW; switching on later, or off once on, is refused (returns the
   current state). On Windows older than 10 (1703) the call returns .F. */
FUNCTION HMG_SetPerMonitorDpi( lOn )
   IF ! HB_ISLOGICAL( lOn ) .OR. lOn == HMG_DPI_ISON()
      RETURN HMG_DPI_ISON()
   ENDIF
   IF ! lOn .OR. _HMG_DpiAnyForm()
      RETURN HMG_DPI_ISON()
   ENDIF
RETURN HMG_DPI_ENABLE()

/* HMG_GetFormDpi( cForm ) -> nDpi of the monitor the form is on (96 when the mode is off) */
FUNCTION HMG_GetFormDpi( cForm )
   IF ! _IsWindowDefined( cForm )
      RETURN 96
   ENDIF
RETURN HMG_DPI_FORMDPI( GetFormHandle( cForm ) )

STATIC FUNCTION _HMG_DpiAnyForm()
   LOCAL i
   FOR i := 1 TO Len( _HMG_SYSDATA [ HMG_FRM_HANDLE ] )
      IF ! _HMG_SYSDATA [ HMG_FRM_DELETED ] [ i ] .AND. ! Empty( _HMG_SYSDATA [ HMG_FRM_HANDLE ] [ i ] )
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

/* Called from c_dpi.c after a form moved to a monitor with another DPI (WM_DPICHANGED; the
   form already has its new size). Every control and panel of the form is placed again from
   its stored design values, and its font is created again for the new DPI. */
FUNCTION _HMG_DPIRESCALE( hWnd, nOldDpi )
   LOCAL nForm, cForm, k, cName, hFont, xHandle, aSize, nDpi, x, h, nSize, nPanelOld, nCol, nRow

   nForm := AScan( _HMG_SYSDATA [ HMG_FRM_HANDLE ], hWnd )
   IF nForm == 0 .OR. _HMG_SYSDATA [ HMG_FRM_DELETED ] [ nForm ]
      RETURN NIL
   ENDIF
   cForm := _HMG_SYSDATA [ HMG_FRM_NAME ] [ nForm ]
   nDpi  := HMG_DPI_FORMDPI( hWnd )

   FOR k := 1 TO Len( _HMG_SYSDATA [ HMG_CTL_HANDLE ] )
      IF _HMG_SYSDATA [ HMG_CTL_DELETED ] [ k ] .OR. ! ( _HMG_SYSDATA [ HMG_CTL_PARENTHANDLE ] [ k ] == hWnd ) ;
         .OR. Empty( _HMG_SYSDATA [ HMG_CTL_TYPE ] [ k ] )
         LOOP
      ENDIF
      cName   := _HMG_SYSDATA [ HMG_CTL_NAME ] [ k ]
      xHandle := _HMG_SYSDATA [ HMG_CTL_HANDLE ] [ k ]

      // position and size: MoveWindow (c_dpi.c) turns the design values into pixels for nDpi
      IF HB_ISNUMERIC( _HMG_SYSDATA [ HMG_CTL_WIDTH ] [ k ] ) .AND. _HMG_SYSDATA [ HMG_CTL_WIDTH ] [ k ] > 0
         BEGIN SEQUENCE WITH {| e | Break( e ) }
            _SetControlSizePos( cName, cForm, _GetControlRow( cName, cForm ), _GetControlCol( cName, cForm ), ;
                                _GetControlWidth( cName, cForm ), _GetControlHeight( cName, cForm ) )
         END SEQUENCE
      ENDIF

      // list-view columns keep their design widths
      IF _HMG_SYSDATA [ HMG_CTL_TYPE ] [ k ] $ "GRID MULTIGRID BROWSE" .AND. HB_ISNUMERIC( xHandle )
         HMG_DPI_RESCALECOLUMNS( xHandle, nOldDpi, nDpi )
      ENDIF

      // font: the control's current font (whatever set it: FONT clause, SET FONT default,
      // a theme) created again for the new DPI; exact size when the control stores one
      nSize := NIL
      IF HB_ISSTRING( _HMG_SYSDATA [ HMG_CTL_FONTNAME ] [ k ] ) .AND. ! Empty( _HMG_SYSDATA [ HMG_CTL_FONTNAME ] [ k ] ) ;
         .AND. HB_ISNUMERIC( _HMG_SYSDATA [ HMG_CTL_FONTSIZE ] [ k ] ) .AND. _HMG_SYSDATA [ HMG_CTL_FONTSIZE ] [ k ] > 0
         nSize := _HMG_SYSDATA [ HMG_CTL_FONTSIZE ] [ k ]
      ENDIF
      hFont := 0
      FOR EACH h IN iif( HB_ISARRAY( xHandle ), xHandle, { xHandle } )
         IF HB_ISNUMERIC( h ) .AND. h != 0
            IF hFont == 0
               hFont := HMG_DPI_REFONT( h, nOldDpi, nDpi, nSize )
            ELSE
               SetWindowFont( h, hFont, .T. )
            ENDIF
         ENDIF
      NEXT
      IF hFont != 0
         IF HB_ISNUMERIC( _HMG_SYSDATA [ HMG_CTL_FONTHANDLE ] [ k ] ) .AND. _HMG_SYSDATA [ HMG_CTL_FONTHANDLE ] [ k ] != 0
            DeleteObject( _HMG_SYSDATA [ HMG_CTL_FONTHANDLE ] [ k ] )
         ENDIF
         _HMG_SYSDATA [ HMG_CTL_FONTHANDLE ] [ k ] := hFont
      ENDIF
   NEXT

   // panels on this form: same DPI, placed again, then their own controls
   FOR x := 1 TO Len( _HMG_SYSDATA [ HMG_FRM_HANDLE ] )
      IF ! _HMG_SYSDATA [ HMG_FRM_DELETED ] [ x ] .AND. _HMG_SYSDATA [ HMG_FRM_TYPE ] [ x ] == "P" ;
         .AND. _HMG_SYSDATA [ HMG_FRM_PARENTHANDLE ] [ x ] == hWnd
         // design rectangle from the panel's real pixels at the old DPI (its parent already has the new one)
         h     := _HMG_SYSDATA [ HMG_FRM_HANDLE ] [ x ]
         aSize := HMG_DPI_RAWRECT( h )
         nCol  := aSize [ 1 ]
         nRow  := aSize [ 2 ]
         ScreenToClient( hWnd, @nCol, @nRow )
         nPanelOld := HMG_DPI_FORMDPI( h )
         HMG_DPI_FORMDPI( h, nDpi )
         MoveWindow( h, Round( nCol * 96 / nOldDpi, 0 ), Round( nRow * 96 / nOldDpi, 0 ), ;
                     Round( ( aSize [ 3 ] - aSize [ 1 ] ) * 96 / nOldDpi, 0 ), Round( ( aSize [ 4 ] - aSize [ 2 ] ) * 96 / nOldDpi, 0 ), .T. )
         _HMG_DPIRESCALE( h, nPanelOld )
      ENDIF
   NEXT

   RedrawWindow( hWnd )
RETURN NIL
