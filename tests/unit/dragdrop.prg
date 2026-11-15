/*
 * Unit test for drag and drop between LISTBOX and GRID controls (5.1, h_dragdrop.prg,
 * c_dragdrop.c). No real mouse: each drag posts WM_MOUSEMOVE / WM_LBUTTONUP (MK_CONTROL
 * for a copy, a WM_KEYDOWN Esc to cancel) to the source control, then HMG_DRAGBEGIN runs
 * the same loop a press-and-move starts. The window is TOPMOST while it runs, because the
 * drop target is found with WindowFromPoint.
 */
#include "hmg.ch"

#define WM_KEYDOWN     0x0100
#define WM_MOUSEMOVE   0x0200
#define WM_LBUTTONUP   0x0202
#define MK_LBUTTON     1
#define MK_CONTROL     8

STATIC s_nPass := 0, s_nFail := 0
STATIC s_aGridB := NIL, s_aListC := NIL, s_nRemoveEvents := 0

FUNCTION Main()
   ErrorBlock( {| e | OutStd( "dragdrop: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 40, 40 WIDTH 920 HEIGHT 560 TITLE "dragdrop test" MAIN TOPMOST ON INIT RunChecks()
      @ 10, 10 LISTBOX List_A WIDTH 150 HEIGHT 160 ITEMS { "a1", "a2", "a3", "a4", "a5" } MULTISELECT DRAGSOURCE DROPTARGET
      @ 10, 180 LISTBOX List_B WIDTH 150 HEIGHT 160 ITEMS { "b1", "b2", "b3" } DRAGSOURCE DROPTARGET
      @ 10, 350 LISTBOX List_S WIDTH 120 HEIGHT 160 ITEMS { "m", "z" } SORT DROPTARGET
      @ 10, 500 GRID Grid_V WIDTH 200 HEIGHT 160 HEADERS { "V" } WIDTHS { 150 } VIRTUAL ITEMCOUNT 3 ;
         ON QUERYDATA ( This.QueryData := "v" + hb_ntos( This.QueryRowIndex ) ) DROPTARGET
      @ 200, 10 GRID Grid_A WIDTH 300 HEIGHT 150 HEADERS { "Name", "N" } WIDTHS { 140, 100 } ;
         ITEMS { { "g1", "1" }, { "g2", "2" }, { "g3", "3" } } MULTISELECT DRAGSOURCE DROPTARGET
      @ 200, 330 GRID Grid_B WIDTH 300 HEIGHT 150 HEADERS { "X", "Y", "Z" } WIDTHS { 90, 90, 90 } ;
         DROPTARGET ON DROP OnGridB()
      @ 380, 700 LISTBOX List_R WIDTH 150 HEIGHT 100 ITEMS { "r1", "r2" } DRAGREMOVE ON DROP s_nRemoveEvents++
      @ 380, 520 LISTBOX List_N WIDTH 150 HEIGHT 100 ITEMS { "n1", "n2" } DRAGSOURCE

      // alternate syntax
      DEFINE LISTBOX List_C
         ROW 380
         COL 10
         WIDTH 150
         HEIGHT 100
         ITEMS { "c1", "c2" }
         DRAGSOURCE .T.
         DROPTARGET .T.
         ON DROP OnListC()
      END LISTBOX
      DEFINE LISTBOX List_P   // no drag clauses: the next control must not inherit List_C's
         ROW 380
         COL 180
         WIDTH 150
         HEIGHT 100
         ITEMS { "p1" }
      END LISTBOX
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC FUNCTION RunChecks()
   LOCAL a

   // 1. list -> list, two items, into the middle; the target selects them
   Drag( "List_A", { 2, 3 }, "List_B", 2 )
   Check( "move list->list target", Same( Items( "List_B" ), { "b1", "a2", "a3", "b2", "b3" } ) )
   Check( "move list->list source", Same( Items( "List_A" ), { "a1", "a4", "a5" } ) )
   Check( "moved items selected",   GetProperty( "Win_1", "List_B", "Value" ) == 2 )

   // 2. Ctrl copies, to the end
   Drag( "List_B", 1, "List_A", 99, .T. )
   Check( "copy target", Same( Items( "List_A" ), { "a1", "a4", "a5", "b1" } ) )
   Check( "copy source", Len( Items( "List_B" ) ) == 5 )

   // 3. reorder inside one list: a1 before b1
   Drag( "List_A", { 1 }, "List_A", 4 )
   Check( "reorder", Same( Items( "List_A" ), { "a4", "a5", "a1", "b1" } ) )
   Drag( "List_A", { 3 }, "List_A", 1 )
   Check( "reorder up", Same( Items( "List_A" ), { "a1", "a4", "a5", "b1" } ) )

   // 4. a SORT list box sorts what it receives
   Drag( "List_A", { 3 }, "List_S", 1 )
   Check( "sorted target", Same( Items( "List_S" ), { "a5", "m", "z" } ) )
   Check( "sorted source", Same( Items( "List_A" ), { "a1", "a4", "b1" } ) )
   Check( "sorted insert row 0", HMG_DRAGINSERTAT( GetControlHandle( "List_S", "Win_1" ), 0, 0 ) == 0 )

   // 5. list -> grid: the text goes to the first column
   Drag( "List_B", 5, "Grid_A", 1 )
   Check( "list->grid row", Same( GetProperty( "Win_1", "Grid_A", "Item", 1 ), { "b3", "" } ) )
   Check( "list->grid count", GetProperty( "Win_1", "Grid_A", "ItemCount" ) == 4 )

   // 6. grid -> grid with ON DROP: This values, then HMG_DragDefault()
   Drag( "Grid_A", { 2, 3 }, "Grid_B", 1 )
   a := s_aGridB
   Check( "on drop ran",        HB_ISARRAY( a ) )
   IF HB_ISARRAY( a )
      Check( "This.DragForm",    a[ 1 ] == "Win_1" )
      Check( "This.DragControl", a[ 2 ] == "Grid_A" )
      Check( "This.DragItems",   Same( a[ 3 ], { 2, 3 } ) )
      Check( "This.DragData",    Same( a[ 4 ], { { "g1", "1" }, { "g2", "2" } } ) )
      Check( "This.DropRow",     a[ 5 ] == 1 )
      Check( "This.DropCopy",    a[ 6 ] == .F. )
      Check( "This.DropOutside", a[ 7 ] == .F. )
      Check( "This.Name",        a[ 8 ] == "Grid_B" )
   ENDIF
   Check( "grid->grid rows padded", Same( GetProperty( "Win_1", "Grid_B", "Item", 1 ), { "g1", "1", "" } ) .AND. ;
                                    Same( GetProperty( "Win_1", "Grid_B", "Item", 2 ), { "g2", "2", "" } ) )
   Check( "grid->grid source",  GetProperty( "Win_1", "Grid_A", "ItemCount" ) == 2 .AND. ;
                                Same( GetProperty( "Win_1", "Grid_A", "Item", 2 ), { "g3", "3" } ) )
   Check( "This outside ON DROP", HMG_DragInfo( "DROPROW" ) == NIL )

   // 7. grid -> list: the first column
   Drag( "Grid_A", { 2 }, "List_B", 1 )
   Check( "grid->list", Items( "List_B" )[ 1 ] == "g3" .AND. GetProperty( "Win_1", "Grid_A", "ItemCount" ) == 1 )

   // 8. DRAGREMOVE: dropped away from every target, the source's ON DROP runs ...
   Drag( "List_R", 1, NIL )
   Check( "remove runs ON DROP", s_nRemoveEvents == 1 .AND. Len( Items( "List_R" ) ) == 2 )

   // ... and a source without DRAGREMOVE keeps its items
   Drag( "List_N", 1, NIL )
   Check( "no remove without DRAGREMOVE", Same( Items( "List_N" ), { "n1", "n2" } ) )

   // 9. a VIRTUAL grid without ON DROP is not a drop target
   Drag( "List_N", 1, "Grid_V", 1 )
   Check( "virtual grid refused", Same( Items( "List_N" ), { "n1", "n2" } ) .AND. ;
                                  HMG_DRAGINSERTAT( GetControlHandle( "Grid_V", "Win_1" ), 0, 0 ) == -1 )
   // a source that is not a target: dropped on itself, nothing happens
   Drag( "List_N", 1, "List_N", 2 )
   Check( "no drop on a non-target", Same( Items( "List_N" ), { "n1", "n2" } ) )

   // 10. Esc cancels
   Drag( "List_N", 2, "List_B", 1, .F., .T. )
   Check( "esc cancels", Same( Items( "List_N" ), { "n1", "n2" } ) .AND. Items( "List_B" )[ 1 ] == "g3" )

   // 11. alternate syntax: the clauses reach the control, ON DROP replaces the default
   Drag( "List_N", 1, "List_C", 2 )
   Check( "alt syntax ON DROP", HB_ISARRAY( s_aListC ) .AND. s_aListC[ 1 ] == "List_N" .AND. s_aListC[ 2 ] == 2 .AND. ;
                                Same( s_aListC[ 3 ], { "n1" } ) )
   Check( "ON DROP without default", Same( Items( "List_C" ), { "c1", "c2" } ) .AND. Same( Items( "List_N" ), { "n1", "n2" } ) )
   Check( "alt syntax reset", HMG_DRAGINSERTAT( GetControlHandle( "List_P", "Win_1" ), 0, 0 ) == -1 )

   // 12. the real start: a press on a list box item, a move past the drag distance (DragDetect)
   PressDrag( "List_B", 1, "List_A", 1 )
   Check( "press-and-move starts the drag", Items( "List_A" )[ 1 ] == "g3" )

   // 13. a press on an item of a multiple selection drags them all (the selection is kept)
   SetProperty( "Win_1", "List_A", "Value", { 1, 2 } )
   PressDrag( "List_A", 1, "List_B", 1, .F. )
   Check( "press keeps the selection", Same( Items( "List_B" ), { "g3", "a1", "b1", "a2", "a3", "b2" } ) .AND. ;
                                       Same( Items( "List_A" ), { "a4", "b1" } ) )
   // ... and a press and release without a move is an ordinary click
   SetProperty( "Win_1", "List_B", "Value", 2 )
   PressDrag( "List_B", 3, NIL, 0 )
   Check( "click without move", GetProperty( "Win_1", "List_B", "Value" ) == 3 .AND. Len( Items( "List_B" ) ) == 6 )

   // 14. a grid starts its own drag (LVN_BEGINDRAG from the list view)
   SetProperty( "Win_1", "Grid_A", "Value", { 1 } )
   PressDrag( "Grid_A", 1, "List_B", 99 )
   Check( "grid press-and-move", ATail( Items( "List_B" ) ) == "b3" .AND. GetProperty( "Win_1", "Grid_A", "ItemCount" ) == 0 )

   Check( "not dragging", ! HMG_DRAGISACTIVE() )

   OutStd( "dragdrop: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC FUNCTION OnGridB()
   s_aGridB := { This.DragForm, This.DragControl, This.DragItems, This.DragData, This.DropRow, ;
                 This.DropCopy, This.DropOutside, This.Name }
   HMG_DragDefault()
RETURN NIL

STATIC FUNCTION OnListC()
   s_aListC := { This.DragControl, This.DropRow, This.DragData }
RETURN NIL

/* select xSel in cSrc, then drop at row nRow of cTgt (NIL: on the form, away from every control) */
STATIC PROCEDURE Drag( cSrc, xSel, cTgt, nRow, lCopy, lEsc )
   LOCAL hSrc := GetControlHandle( cSrc, "Win_1" ), a, w

   SetProperty( "Win_1", cSrc, "Value", xSel )
   IF cTgt == NIL
      // the form at row 505, col 400 has no control (source client = form client - border)
      a := { 400 - GetProperty( "Win_1", cSrc, "Col" ) - 2, 505 - GetProperty( "Win_1", cSrc, "Row" ) - 2 }
   ELSE
      a := _HMG_DRAGROWPOINT( GetControlHandle( cTgt, "Win_1" ), nRow, hSrc )
   ENDIF
   w := iif( hb_defaultValue( lCopy, .F. ), MK_CONTROL, 0 )
   _HMG_DRAGPOST( hSrc, WM_MOUSEMOVE, w + MK_LBUTTON, a[ 1 ], a[ 2 ] )
   IF hb_defaultValue( lEsc, .F. )
      _HMG_DRAGPOST( hSrc, WM_KEYDOWN, 27, 0, 0 )
   ENDIF
   _HMG_DRAGPOST( hSrc, WM_LBUTTONUP, w, a[ 1 ], a[ 2 ] )
   HMG_DRAGBEGIN( hSrc )
   DO EVENTS
RETURN

/* the press goes through the list box's own WM_LBUTTONDOWN, as a click would */
/* cTgt NIL: press and release on the item, no move */
STATIC PROCEDURE PressDrag( cSrc, nItem, cTgt, nRow )
   LOCAL hSrc := GetControlHandle( cSrc, "Win_1" ), p := _HMG_DRAGROWPOINT( hSrc, nItem, hSrc ), a
   _HMG_DRAGPOST( hSrc, 0x0201, MK_LBUTTON, p[ 1 ], p[ 2 ] )             // WM_LBUTTONDOWN
   IF cTgt == NIL
      _HMG_DRAGPOST( hSrc, WM_LBUTTONUP, 0, p[ 1 ], p[ 2 ] )
   ELSE
      a := _HMG_DRAGROWPOINT( GetControlHandle( cTgt, "Win_1" ), nRow, hSrc )
      _HMG_DRAGPOST( hSrc, WM_MOUSEMOVE, MK_LBUTTON, p[ 1 ] + 30, p[ 2 ] )   // past the drag distance
      _HMG_DRAGPOST( hSrc, WM_MOUSEMOVE, MK_LBUTTON, a[ 1 ], a[ 2 ] )
      _HMG_DRAGPOST( hSrc, WM_LBUTTONUP, 0, a[ 1 ], a[ 2 ] )
   ENDIF
   DO EVENTS
RETURN

STATIC FUNCTION Items( cCtl )
   LOCAL a := {}, i
   FOR i := 1 TO GetProperty( "Win_1", cCtl, "ItemCount" )
      AAdd( a, GetProperty( "Win_1", cCtl, "Item", i ) )
   NEXT
RETURN a

STATIC FUNCTION Same( a, b )
RETURN hb_ValToExp( a ) == hb_ValToExp( b )

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "dragdrop: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
