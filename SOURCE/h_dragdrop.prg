/*
 * HMG5 - drag and drop between LISTBOX and GRID controls (5.1)
 *
 *   DEFINE LISTBOX / GRID ...  DRAGSOURCE      items can be dragged out of the control
 *                              DROPTARGET      items can be dropped on the control
 *                              DRAGREMOVE      dropping them away from every drop target
 *                                              removes them (implies DRAGSOURCE)
 *                              ON DROP <act>   runs instead of the default move/copy/remove
 *
 * The mouse part is in c_dragdrop.c; it calls _HMG_DragDrop() when items are dropped.
 * Without ON DROP the items move (copy with Ctrl). Inside ON DROP:
 *   This.DragForm, This.DragControl   where the items came from
 *   This.DragItems                    their rows there (array, ascending)
 *   This.DragData                     their values: texts (LISTBOX) or row arrays (GRID)
 *   This.DropRow                      where they land: row of the first one (0: sorted list)
 *   This.DropCopy                     .T. when Ctrl was held
 *   This.DropOutside                  .T. when dropped away (DRAGREMOVE source; the event is
 *                                     then the source's)
 *   HMG_DragDefault()                 does what HMG would have done without ON DROP
 */

#include "hmg.ch"

MEMVAR _HMG_SYSDATA

#define DD_SOURCE   1
#define DD_TARGET   2
#define DD_REMOVE   3
#define DD_ONDROP   4

// the drop being handled
#define DI_SRC      1   // source control index
#define DI_TGT      2   // target control index (0: outside)
#define DI_ITEMS    3
#define DI_DATA     4
#define DI_ROW      5
#define DI_COPY     6
#define DI_OUTSIDE  7

STATIC s_hDrag := NIL   // control handle -> { lSource, lTarget, lRemove, bOnDrop }
STATIC s_aInfo := NIL

/* DEFINE LISTBOX / GRID ... END: the drag clauses (alternate syntax) */
FUNCTION _HMG_DragClauses()
   LOCAL h := _HMG_SYSDATA[ HMG_SYS_ALTCLAUSES ]
   IF ! HB_ISHASH( h )
      RETURN NIL
   ENDIF
   RETURN { hb_HGetDef( h, "DRAGSOURCE", .F. ), hb_HGetDef( h, "DROPTARGET", .F. ), ;
            hb_HGetDef( h, "DRAGREMOVE", .F. ), hb_HGetDef( h, "ONDROP", NIL ) }

/* any drag clause given? (DRAGITEMS, the old reorder inside one list box, is then left off) */
FUNCTION _HMG_DragWanted( aDD )
   RETURN HB_ISARRAY( aDD ) .AND. Len( aDD ) >= 4 .AND. ;
          ( hb_defaultValue( aDD[ DD_SOURCE ], .F. ) .OR. hb_defaultValue( aDD[ DD_TARGET ], .F. ) .OR. ;
            hb_defaultValue( aDD[ DD_REMOVE ], .F. ) )

/* the end of _DefineListBox / _DefineGrid */
PROCEDURE _HMG_DragSetup( k, aDD )
   LOCAL lSource, lTarget, lRemove, bOnDrop, cType, hWnd

   IF ! _HMG_DragWanted( aDD )
      RETURN
   ENDIF
   lSource := hb_defaultValue( aDD[ DD_SOURCE ], .F. )
   lTarget := hb_defaultValue( aDD[ DD_TARGET ], .F. )
   lRemove := hb_defaultValue( aDD[ DD_REMOVE ], .F. )
   bOnDrop := iif( HB_ISBLOCK( aDD[ DD_ONDROP ] ), aDD[ DD_ONDROP ], NIL )
   lSource := lSource .OR. lRemove

   cType := _HMG_SYSDATA[ HMG_CTL_TYPE ][ k ]
   hWnd  := _HMG_SYSDATA[ HMG_CTL_HANDLE ][ k ]
   IF _HMG_DragIsVirtual( k ) .AND. bOnDrop == NIL
      // HMG cannot add or delete the rows of a VIRTUAL grid: only ON DROP can
      lTarget := .F.
      lRemove := .F.
   ENDIF

   IF s_hDrag == NIL
      s_hDrag := { => }
   ENDIF
   s_hDrag[ hWnd ] := { lSource, lTarget, lRemove, bOnDrop }
   HMG_DRAGREGISTER( hWnd, iif( cType == "LIST" .OR. cType == "MULTILIST", 1, 2 ), lSource, lTarget, lRemove )
   RETURN

/* called by c_dragdrop.c when items are dropped */
FUNCTION _HMG_DragDrop( hSrc, aItems, hTgt, nRow, lCopy, lOutside )
   LOCAL iS, iT := 0, k, aEntry, aSave

   iS := GetControlIndexByHandle( hSrc )
   IF ! lOutside
      iT := GetControlIndexByHandle( hTgt )
   ENDIF
   IF iS == 0 .OR. ( ! lOutside .AND. iT == 0 ) .OR. s_hDrag == NIL
      RETURN NIL
   ENDIF
   k      := iif( lOutside, iS, iT )
   aEntry := hb_HGetDef( s_hDrag, _HMG_SYSDATA[ HMG_CTL_HANDLE ][ k ], NIL )

   aSave   := s_aInfo
   s_aInfo := { iS, iT, aItems, _HMG_DragData( iS, aItems ), nRow, lCopy, lOutside }
   IF aEntry != NIL .AND. HB_ISBLOCK( aEntry[ DD_ONDROP ] )
      _DoControlEventProcedure( aEntry[ DD_ONDROP ], k )
   ELSE
      HMG_DragDefault()
   ENDIF
   s_aInfo := aSave
   RETURN NIL

/* This.DragForm, This.DragControl, This.DragItems, This.DragData, This.DropRow,
   This.DropCopy, This.DropOutside (NIL outside ON DROP) */
FUNCTION HMG_DragInfo( cWhat )
   IF s_aInfo == NIL
      RETURN NIL
   ENDIF
   SWITCH Upper( cWhat )
   CASE "DRAGFORM"     ; RETURN _HMG_DragFormName( s_aInfo[ DI_SRC ] )
   CASE "DRAGCONTROL"  ; RETURN _HMG_SYSDATA[ HMG_CTL_NAME ][ s_aInfo[ DI_SRC ] ]
   CASE "DRAGITEMS"    ; RETURN AClone( s_aInfo[ DI_ITEMS ] )
   CASE "DRAGDATA"     ; RETURN AClone( s_aInfo[ DI_DATA ] )
   CASE "DROPROW"      ; RETURN s_aInfo[ DI_ROW ]
   CASE "DROPCOPY"     ; RETURN s_aInfo[ DI_COPY ]
   CASE "DROPOUTSIDE"  ; RETURN s_aInfo[ DI_OUTSIDE ]
   ENDSWITCH
   RETURN NIL

/* the default action of a drop: move (copy with Ctrl) the items, or remove them when
   dropped outside. Inside ON DROP it can be called to do just that. -> lDone */
FUNCTION HMG_DragDefault()
   LOCAL iS, iT, aItems, aData, nRow, lCopy, lSrcVirtual, nCount, x, aNew := {}, nShift, i

   IF s_aInfo == NIL
      RETURN .F.
   ENDIF
   iS          := s_aInfo[ DI_SRC ]
   iT          := s_aInfo[ DI_TGT ]
   aItems      := s_aInfo[ DI_ITEMS ]
   nRow        := s_aInfo[ DI_ROW ]
   lCopy       := s_aInfo[ DI_COPY ]
   lSrcVirtual := _HMG_DragIsVirtual( iS )

   IF s_aInfo[ DI_OUTSIDE ]
      IF lSrcVirtual
         RETURN .F.
      ENDIF
      _HMG_DragDelete( iS, aItems )
      RETURN .T.
   ENDIF
   IF iT == 0 .OR. _HMG_DragIsVirtual( iT )
      RETURN .F.
   ENDIF

   aData := _HMG_DragConvert( s_aInfo[ DI_DATA ], iS, iT )

   IF iS == iT .AND. ! lCopy
      // reorder inside one control
      IF nRow > 0
         nShift := 0
         FOR EACH x IN aItems
            IF x < nRow
               nShift++
            ENDIF
         NEXT
         nRow -= nShift
      ENDIF
      _HMG_DragDelete( iS, aItems )
   ENDIF

   nCount := _HMG_DragCount( iT )
   IF nRow > nCount + 1
      nRow := 0
   ENDIF
   FOR i := 1 TO Len( aData )
      AAdd( aNew, _HMG_DragInsert( iT, aData[ i ], iif( nRow > 0, nRow + i - 1, 0 ) ) )
   NEXT

   IF iS != iT .AND. ! lCopy .AND. ! lSrcVirtual
      _HMG_DragDelete( iS, aItems )
   ENDIF
   _HMG_DragSelect( iT, aNew )
   RETURN .T.

/* ------------------------------------------------------------------------ */

STATIC FUNCTION _HMG_DragIsList( i )
   RETURN _HMG_SYSDATA[ HMG_CTL_TYPE ][ i ] == "LIST" .OR. _HMG_SYSDATA[ HMG_CTL_TYPE ][ i ] == "MULTILIST"

FUNCTION _HMG_DragIsVirtual( i )
   LOCAL a
   IF _HMG_DragIsList( i )
      RETURN .F.
   ENDIF
   a := _HMG_SYSDATA[ HMG_CTL_MISCDATA2 ][ i ]
   RETURN HB_ISARRAY( a ) .AND. Len( a ) >= 9 .AND. hb_defaultValue( a[ 9 ], .F. ) == .T.

STATIC FUNCTION _HMG_DragFormName( i )
   LOCAL nForm := GetFormIndexByHandle( _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ i ] )
   RETURN iif( nForm > 0, GetFormNameByIndex( nForm ), "" )

STATIC FUNCTION _HMG_DragCount( i )
   IF _HMG_DragIsList( i )
      RETURN ListBoxGetItemCount( _HMG_SYSDATA[ HMG_CTL_HANDLE ][ i ] )
   ENDIF
   RETURN ListView_GetItemCount( _HMG_SYSDATA[ HMG_CTL_HANDLE ][ i ] )

/* number of columns of a grid */
STATIC FUNCTION _HMG_DragColumns( i )
   RETURN Len( _HMG_SYSDATA[ HMG_CTL_PAGEMAP ][ i ] )

/* a grid with images: column 1 holds the image index */
STATIC FUNCTION _HMG_DragHasImages( i )
   LOCAL a := _HMG_SYSDATA[ HMG_CTL_BKCOLOR ][ i ]
   RETURN HB_ISARRAY( a ) .AND. Len( a ) > 0

STATIC FUNCTION _HMG_DragData( i, aItems )
   LOCAL aData := {}, n, cForm := _HMG_DragFormName( i ), cName := _HMG_SYSDATA[ HMG_CTL_NAME ][ i ]
   FOR EACH n IN aItems
      IF _HMG_DragIsList( i )
         AAdd( aData, ListBoxGetString( _HMG_SYSDATA[ HMG_CTL_HANDLE ][ i ], n ) )
      ELSEIF _HMG_DragIsVirtual( i ) .OR. Empty( cForm )
         AAdd( aData, NIL )   // a VIRTUAL grid's rows are the program's: This.DragItems
      ELSE
         AAdd( aData, _GetItem( cName, cForm, n ) )
      ENDIF
   NEXT
   RETURN aData

/* list box texts <-> grid rows */
STATIC FUNCTION _HMG_DragConvert( aData, iS, iT )
   LOCAL aOut := {}, x, nCols, aRow, nFirst

   IF _HMG_DragIsList( iT )
      FOR EACH x IN aData
         IF HB_ISARRAY( x )
            nFirst := iif( _HMG_DragHasImages( iS ) .AND. Len( x ) > 1, 2, 1 )
            x := iif( Len( x ) >= nFirst, x[ nFirst ], "" )
         ENDIF
         AAdd( aOut, iif( HB_ISSTRING( x ), x, iif( x == NIL, "", hb_ValToStr( x ) ) ) )
      NEXT
      RETURN aOut
   ENDIF

   nCols := _HMG_DragColumns( iT )
   FOR EACH x IN aData
      IF HB_ISARRAY( x )
         aRow := AClone( x )
         IF Len( aRow ) > nCols
            ASize( aRow, nCols )
         ENDIF
         DO WHILE Len( aRow ) < nCols
            AAdd( aRow, "" )
         ENDDO
      ELSE
         aRow := Array( nCols )
         AFill( aRow, "" )
         IF _HMG_DragHasImages( iT ) .AND. nCols > 1
            aRow[ 1 ] := 0
            aRow[ 2 ] := iif( HB_ISSTRING( x ), x, "" )
         ELSEIF nCols > 0
            aRow[ 1 ] := iif( HB_ISSTRING( x ), x, "" )
         ENDIF
      ENDIF
      AAdd( aOut, aRow )
   NEXT
   RETURN aOut

/* inserts one item; nRow 0 = at the end (or sorted). -> its row (0 if not known) */
STATIC FUNCTION _HMG_DragInsert( i, x, nRow )
   LOCAL h := _HMG_SYSDATA[ HMG_CTL_HANDLE ][ i ], nCount := _HMG_DragCount( i )

   IF _HMG_DragIsList( i )
      IF HMG_DRAGISSORTED( h )
         ListBoxAddString( h, x )
         RETURN 0
      ELSEIF nRow == 0
         ListBoxAddString( h, x )
         RETURN nCount + 1
      ENDIF
      ListBoxInsertString( h, x, nRow )
      RETURN nRow
   ENDIF
   IF nRow == 0
      nRow := nCount + 1
   ENDIF
   _AddGridRow( _HMG_SYSDATA[ HMG_CTL_NAME ][ i ], _HMG_DragFormName( i ), x, nRow )
   RETURN nRow

STATIC PROCEDURE _HMG_DragDelete( i, aItems )
   LOCAL a := ASort( AClone( aItems ),,, {| x, y | x > y } ), n
   FOR EACH n IN a
      _DeleteItem( _HMG_SYSDATA[ HMG_CTL_NAME ][ i ], _HMG_DragFormName( i ), n )
   NEXT
   RETURN

STATIC PROCEDURE _HMG_DragSelect( i, aNew )
   LOCAL h := _HMG_SYSDATA[ HMG_CTL_HANDLE ][ i ], a := {}, n
   FOR EACH n IN aNew
      IF n > 0
         AAdd( a, n )
      ENDIF
   NEXT
   IF Empty( a )
      RETURN
   ENDIF
   DO CASE
   CASE _HMG_SYSDATA[ HMG_CTL_TYPE ][ i ] == "MULTILIST"
      LISTBOXSETMULTISEL( h, a )
   CASE _HMG_SYSDATA[ HMG_CTL_TYPE ][ i ] == "LIST"
      ListBoxSetCurSel( h, a[ 1 ] )
   CASE _HMG_SYSDATA[ HMG_CTL_TYPE ][ i ] == "MULTIGRID"
      ListViewSetMultiSel( h, a )
   OTHERWISE
      ListView_SetCursel( h, a[ 1 ] )
   ENDCASE
   RETURN
