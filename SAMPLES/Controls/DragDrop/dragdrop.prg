/*
 * HMG5 sample: drag and drop between LISTBOX and GRID controls (5.1)
 *
 *  - Drag fruit from "Available" to "Basket" and back; reorder inside either list.
 *  - Hold Ctrl when you drop to copy instead of move.
 *  - Drag rows between the two grids; a list box item dropped on a grid becomes a row.
 *  - Drag a basket item away from every list (onto the empty form) to remove it.
 *  - The "Orders" grid has ON DROP: it asks before taking the rows, then lets HMG
 *    do the usual move with HMG_DragDefault().
 */

#include "hmg.ch"

FUNCTION Main()

   DEFINE WINDOW Win_1 ;
      AT 0, 0 ;
      WIDTH 760 HEIGHT 520 ;
      TITLE "HMG5 - Drag and drop" ;
      MAIN

      @ 10, 20 LABEL Lbl_1 VALUE "Available" WIDTH 200
      @ 32, 20 LISTBOX List_Avail WIDTH 200 HEIGHT 190 ;
         ITEMS { "Apple", "Banana", "Cherry", "Grape", "Mango", "Orange", "Pear", "Plum" } ;
         MULTISELECT DRAGSOURCE DROPTARGET

      @ 10, 250 LABEL Lbl_2 VALUE "Basket (drag away to remove)" WIDTH 220
      @ 32, 250 LISTBOX List_Basket WIDTH 200 HEIGHT 190 ;
         MULTISELECT DROPTARGET DRAGREMOVE

      @ 10, 480 LABEL Lbl_3 VALUE "Sorted" WIDTH 200
      @ 32, 480 LISTBOX List_Sorted WIDTH 240 HEIGHT 190 SORT DROPTARGET DRAGSOURCE

      @ 240, 20 LABEL Lbl_4 VALUE "Stock" WIDTH 300
      @ 262, 20 GRID Grid_Stock WIDTH 340 HEIGHT 170 ;
         HEADERS { "Item", "Qty" } WIDTHS { 200, 100 } ;
         ITEMS { { "Paper", "10" }, { "Pens", "25" }, { "Ink", "4" }, { "Stapler", "2" } } ;
         MULTISELECT DRAGSOURCE DROPTARGET

      @ 240, 380 LABEL Lbl_5 VALUE "Orders (asks first)" WIDTH 300
      @ 262, 380 GRID Grid_Orders WIDTH 340 HEIGHT 170 ;
         HEADERS { "Item", "Qty" } WIDTHS { 200, 100 } ;
         MULTISELECT DRAGSOURCE DROPTARGET ;
         ON DROP OnOrdersDrop()

      @ 445, 20 LABEL Lbl_Status VALUE "Drag items with the mouse. Ctrl copies, Esc cancels." WIDTH 700

   END WINDOW

   CENTER WINDOW Win_1
   ACTIVATE WINDOW Win_1

RETURN NIL

/* runs instead of the usual move when rows are dropped on Grid_Orders */
STATIC FUNCTION OnOrdersDrop()
   LOCAL n := Len( This.DragItems )

   IF This.DragControl == "Grid_Orders"   // reordering inside the grid: just do it
      HMG_DragDefault()
      RETURN NIL
   ENDIF
   IF MsgYesNo( iif( This.DropCopy, "Copy ", "Move " ) + hb_ntos( n ) + iif( n == 1, " item", " items" ) + ;
                " from " + This.DragControl + " to Orders, at row " + hb_ntos( This.DropRow ) + "?", "Orders" )
      HMG_DragDefault()
      Win_1.Lbl_Status.Value := hb_ntos( n ) + " item(s) added to Orders."
   ELSE
      Win_1.Lbl_Status.Value := "Nothing changed."
   ENDIF
RETURN NIL
