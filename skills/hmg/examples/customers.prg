/*
 * A data-entry form over a DBF table: a GRID list, an edit area (TEXTBOX, DATEPICKER,
 * COMBOBOX, CHECKBOX, numeric TEXTBOX) and New / Save / Delete. The table is created on
 * first run. Shows: USE/APPEND/REPLACE, filling a GRID from a table, Value of each control,
 * ON CHANGE, validation, and the IsControlDefined guard.
 * Build and run:  build64 customers.prg
 */
#include "hmg.ch"

#define DBF_NAME  "customers"

FUNCTION Main()

   SET DATE BRITISH
   SET CENTURY ON
   SET DELETED ON
   OpenTable()

   DEFINE WINDOW Win_Cust AT 0, 0 WIDTH 820 HEIGHT 520 TITLE "Customers" MAIN ;
      ON RELEASE dbCloseAll()

      @ 10, 10 GRID Grd_List WIDTH 420 HEIGHT 440 ;
         HEADERS { "Name", "City", "Since" } WIDTHS { 190, 120, 90 } ;
         ON CHANGE ShowCurrent()

      @ 14, 450 LABEL Lbl_1 VALUE "Name"   WIDTH 90
      @ 10, 550 TEXTBOX Txt_Name WIDTH 240 MAXLENGTH 40
      @ 48, 450 LABEL Lbl_2 VALUE "City"   WIDTH 90
      @ 44, 550 COMBOBOX Cmb_City WIDTH 240 ITEMS { "Chennai", "Madurai", "Coimbatore", "Bengaluru" } VALUE 1
      @ 82, 450 LABEL Lbl_3 VALUE "Since"  WIDTH 90
      @ 78, 550 DATEPICKER Dtp_Since WIDTH 140 VALUE Date()
      @ 116, 450 LABEL Lbl_4 VALUE "Credit limit" WIDTH 90
      @ 112, 550 TEXTBOX Txt_Limit WIDTH 140 VALUE 0 NUMERIC INPUTMASK "9,999,999.99" RIGHTALIGN
      @ 146, 550 CHECKBOX Chk_Active CAPTION "Active" WIDTH 120 VALUE .T.

      @ 200, 550 BUTTON Btn_New    CAPTION "New"    WIDTH 110 HEIGHT 30 ACTION NewRecord()
      @ 200, 670 BUTTON Btn_Save   CAPTION "Save"   WIDTH 110 HEIGHT 30 ACTION SaveRecord()
      @ 240, 550 BUTTON Btn_Delete CAPTION "Delete" WIDTH 110 HEIGHT 30 ACTION DeleteRecord()

      DEFINE STATUSBAR
         STATUSITEM "Ready"
         STATUSITEM "" WIDTH 120
      END STATUSBAR
   END WINDOW

   LoadGrid()
   Win_Cust.Center
   Win_Cust.Activate
RETURN NIL

STATIC PROCEDURE OpenTable()
   IF ! hb_FileExists( DBF_NAME + ".dbf" )
      dbCreate( DBF_NAME, { { "NAME",   "C", 40, 0 }, { "CITY", "C", 20, 0 }, { "SINCE", "D", 8, 0 }, ;
                            { "CLIMIT", "N", 12, 2 }, { "ACTIVE", "L", 1, 0 } } )
   ENDIF
   USE ( DBF_NAME ) NEW SHARED ALIAS CUST
RETURN

/* the GRID shows one row per record; the record number of each row is kept in a parallel array */
STATIC FUNCTION RecList( aNew )
   STATIC s_aRec := {}
   IF HB_ISARRAY( aNew )
      s_aRec := aNew
   ENDIF
RETURN s_aRec

STATIC PROCEDURE LoadGrid()
   LOCAL aRec := {}
   Win_Cust.Grd_List.DisableUpdate
   Win_Cust.Grd_List.DeleteAllItems
   CUST->( dbGoTop() )
   DO WHILE ! CUST->( Eof() )
      Win_Cust.Grd_List.AddItem( { AllTrim( CUST->NAME ), AllTrim( CUST->CITY ), DToC( CUST->SINCE ) } )
      AAdd( aRec, CUST->( RecNo() ) )
      CUST->( dbSkip() )
   ENDDO
   Win_Cust.Grd_List.EnableUpdate
   RecList( aRec )
   Win_Cust.StatusBar.Item( 2 ) := hb_ntos( Len( aRec ) ) + " customers"
   IF Len( aRec ) > 0
      Win_Cust.Grd_List.Value := 1
   ENDIF
RETURN

/* ON CHANGE of the GRID: it can also fire while the window is still being defined, so check
   that the last control the procedure uses exists (HMG idiom: the last defined control) */
STATIC PROCEDURE ShowCurrent()
   LOCAL n
   IF ! IsControlDefined( Chk_Active, Win_Cust )
      RETURN
   ENDIF
   n := Win_Cust.Grd_List.Value
   IF n < 1 .OR. n > Len( RecList() )
      RETURN
   ENDIF
   CUST->( dbGoto( RecList()[ n ] ) )
   Win_Cust.Txt_Name.Value   := AllTrim( CUST->NAME )
   Win_Cust.Cmb_City.Value   := Max( 1, AScan( { "Chennai", "Madurai", "Coimbatore", "Bengaluru" }, AllTrim( CUST->CITY ) ) )
   Win_Cust.Dtp_Since.Value  := CUST->SINCE
   Win_Cust.Txt_Limit.Value  := CUST->CLIMIT
   Win_Cust.Chk_Active.Value := CUST->ACTIVE
RETURN

STATIC PROCEDURE NewRecord()
   Win_Cust.Grd_List.Value   := 0
   Win_Cust.Txt_Name.Value   := ""
   Win_Cust.Cmb_City.Value   := 1
   Win_Cust.Dtp_Since.Value  := Date()
   Win_Cust.Txt_Limit.Value  := 0
   Win_Cust.Chk_Active.Value := .T.
   Win_Cust.Txt_Name.SetFocus
RETURN

STATIC PROCEDURE SaveRecord()
   LOCAL n := Win_Cust.Grd_List.Value
   IF Empty( Win_Cust.Txt_Name.Value )
      MsgStop( "The name is required.", "Customers" )
      Win_Cust.Txt_Name.SetFocus
      RETURN
   ENDIF
   IF n > 0
      CUST->( dbGoto( RecList()[ n ] ) )
      IF ! CUST->( RLock() )
         MsgStop( "Someone else is editing this customer.", "Customers" )
         RETURN
      ENDIF
   ELSE
      CUST->( dbAppend() )          // a new record is locked by the append
   ENDIF
   CUST->NAME   := Win_Cust.Txt_Name.Value
   CUST->CITY   := Win_Cust.Cmb_City.DisplayValue
   CUST->SINCE  := Win_Cust.Dtp_Since.Value
   CUST->CLIMIT := Win_Cust.Txt_Limit.Value
   CUST->ACTIVE := Win_Cust.Chk_Active.Value
   CUST->( dbCommit() )
   CUST->( dbUnlock() )
   LoadGrid()
   Win_Cust.StatusBar.Item( 1 ) := "Saved"
RETURN

STATIC PROCEDURE DeleteRecord()
   LOCAL n := Win_Cust.Grd_List.Value
   IF n < 1
      RETURN
   ENDIF
   IF MsgYesNo( "Delete " + Win_Cust.Grd_List.Cell( n, 1 ) + "?", "Customers" )
      CUST->( dbGoto( RecList()[ n ] ) )
      IF CUST->( RLock() )
         CUST->( dbDelete() )
         CUST->( dbUnlock() )
      ENDIF
      LoadGrid()
   ENDIF
RETURN
