/*
 * Unit test for the HMG5 control/form objects (PHASE3-DESIGN.md S3, SOURCE/h_hmgobject.prg).
 * Every object call must give the same result as the command syntax it maps to, a
 * released control must raise an error (never act on the control that reuses its slot),
 * and programs that do not use the objects are unaffected (covered by tests/unit/props).
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   // HMG's QUIT ends in ExitProcess(0); exit through ExitProcess(n) so failures count.
   ErrorBlock( {| e | OutStd( "ctlapi: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 500 HEIGHT 400 TITLE "ctlapi" MAIN NOSHOW ON INIT RunChecks()
      @ 10, 10 LABEL Lbl_1 VALUE "hello" WIDTH 80 HEIGHT 20
      @ 40, 10 TEXTBOX Text_1 VALUE "abc" WIDTH 120
      @ 70, 10 GRID Grid_1 WIDTH 200 HEIGHT 100 HEADERS { "A", "B" } WIDTHS { 80, 80 } ;
         ITEMS { { "1", "2" }, { "3", "4" } }
      @ 180, 10 COMBOBOX Combo_1 ITEMS { "x", "y" } VALUE 1 WIDTH 100
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC FUNCTION RunChecks()
   LOCAL oT, oL, oG, oC, oF, oOld, aCtl, x, lErr, nIdx

   // lookup
   oT := HMG_GetControl( "Win_1", "Text_1" )
   Check( "get control",          HB_ISOBJECT( oT ) )
   Check( "case-insensitive",     HB_ISOBJECT( HMG_GetControl( "WIN_1", "text_1" ) ) )
   Check( "stored name case",     HMG_GetControl( "WIN_1", "text_1" ):Name() == "Text_1" )
   Check( "unknown control NIL",  HMG_GetControl( "Win_1", "Nope" ) == NIL )
   Check( "unknown form NIL",     HMG_GetControl( "NoForm", "Text_1" ) == NIL )
   Check( "bad args NIL",         HMG_GetControl( 1, NIL ) == NIL .AND. HMG_GetForm( NIL ) == NIL )

   // identity accessors = the slot / existing functions
   Check( "name/form",            oT:Name() == "Text_1" .AND. oT:FormName() == "Win_1" )
   Check( "type",                 oT:Type() == GetControlType( "Text_1", "Win_1" ) )
   Check( "handle",               oT:Handle() == GetControlHandle( "Text_1", "Win_1" ) )
   Check( "index",                oT:Index() == GetControlIndex( "Text_1", "Win_1" ) )
   Check( "parent handle",        oT:ParentHandle() == GetFormHandle( "Win_1" ) )

   // properties through the error handler = GetProperty / SetProperty
   Check( "value get",            oT:Value == GetProperty( "Win_1", "Text_1", "Value" ) )
   oT:Value := "xyz"
   Check( "value set",            GetProperty( "Win_1", "Text_1", "Value" ) == "xyz" )
   x := ( oT:Width := 150 )
   Check( "assign returns value", x == 150 )
   Check( "width set",            GetProperty( "Win_1", "Text_1", "Width" ) == 150 )
   oL := HMG_GetControl( "Win_1", "Lbl_1" )
   Check( "label value",          oL:Value == "hello" )
   Check( "Get()",                oL:Get( "Row" ) == 10 )
   oL:Set( "Value", "bye" )
   Check( "Set()",                Win_1.Lbl_1.Value == "bye" )

   // properties with an index argument (GridEx hook path)
   oG := HMG_GetControl( "Win_1", "Grid_1" )
   Check( "grid item(n)",         HB_ISARRAY( oG:Item( 2 ) ) .AND. oG:Item( 2 )[ 1 ] == "3" )
   oG:Set( "ColumnHeader", 1, "Amt" )
   Check( "grid set w/ index",    GetProperty( "Win_1", "Grid_1", "ColumnHeader", 1 ) == "Amt" )
   Check( "grid get w/ index",    oG:ColumnHeader( 1 ) == "Amt" )
   Check( "grid itemcount",       oG:ItemCount == 2 )

   // methods = DoMethod
   oC := HMG_GetControl( "Win_1", "Combo_1" )
   oC:Do( "AddItem", "z" )
   Check( "Do() with args",       GetProperty( "Win_1", "Combo_1", "ItemCount" ) == 3 )
   oG:Do( "DeleteAllItems" )
   Check( "Do() no args",         oG:ItemCount == 0 )
   oL:Hide()
   Check( "Hide()",               GetProperty( "Win_1", "Lbl_1", "Visible" ) == .F. )
   oL:Show()
   Check( "Show()",               GetProperty( "Win_1", "Lbl_1", "Visible" ) == .T. )

   // form object
   oF := HMG_GetForm( "win_1" )
   Check( "get form",             HB_ISOBJECT( oF ) .AND. oF:Name() == "Win_1" )
   Check( "form handle",          oF:Handle() == GetFormHandle( "Win_1" ) )
   Check( "form type",            oF:Type() == "A" )
   Check( "form title",           oF:Title == "ctlapi" )
   oF:Title := "ctlapi2"
   Check( "form title set",       GetProperty( "Win_1", "Title" ) == "ctlapi2" )
   oF:Set( "Title", "ctlapi3" )
   Check( "form Set()",           Win_1.Title == "ctlapi3" )
   Check( "form Get()",           oF:Get( "Title" ) == "ctlapi3" )
   aCtl := oF:Controls()
   Check( "Controls() count",     Len( aCtl ) == 4 )
   Check( "Controls() order",     aCtl[ 1 ]:Name() == "Lbl_1" .AND. aCtl[ 4 ]:Name() == "Combo_1" )
   Check( "form Control()",       oF:Control( "Lbl_1" ):Value == "bye" )
   Check( "control Form()",       oT:Form():Name() == "Win_1" )

   // a released control: IsValid() goes .F., use raises an error,
   // and a new control reusing the slot is not touched through the old object
   oOld := HMG_GetControl( "Win_1", "Lbl_1" )
   nIdx := oOld:Index()
   oOld:Release()
   Check( "released invalid",     ! oOld:IsValid() )
   Check( "released lookup NIL",  HMG_GetControl( "Win_1", "Lbl_1" ) == NIL )
   @ 300, 300 LABEL Lbl_New OF Win_1 VALUE "new" WIDTH 50 HEIGHT 20
   Check( "slot reused",          GetControlIndex( "Lbl_New", "Win_1" ) == nIdx )
   Check( "old still invalid",    ! oOld:IsValid() )
   lErr := .F.
   BEGIN SEQUENCE WITH {| e | Break( e ) }
      oOld:Value := "WRONG"
   RECOVER USING x
      lErr := HB_ISOBJECT( x ) .AND. x:subCode == 5501 .AND. "released" $ x:description
   END SEQUENCE
   Check( "released use errors",  lErr )
   Check( "new control untouched", GetProperty( "Win_1", "Lbl_New", "Value" ) == "new" )
   lErr := .F.
   BEGIN SEQUENCE WITH {| e | Break( e ) }
      x := oOld:Handle()
   RECOVER
      lErr := .T.
   END SEQUENCE
   Check( "released accessor errors", lErr )
   aCtl := oF:Controls()
   Check( "Controls() after release", Len( aCtl ) == 4 .AND. ;
          AScan( aCtl, {| o | o:Name() == "Lbl_New" } ) > 0 .AND. AScan( aCtl, {| o | o:Name() == "Lbl_1" } ) == 0 )

   // information only: cost of the object layer on top of GetProperty
   TimeIt( "GetProperty(text,Value)", {|| GetProperty( "Win_1", "Text_1", "Value" ) } )
   TimeIt( "oCtl:Value",              {|| oT:Value } )
   TimeIt( "oCtl:Get('Value')",       {|| oT:Get( "Value" ) } )
   TimeIt( "oCtl:IsValid()",          {|| oT:IsValid() } )

   OutStd( "ctlapi: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC PROCEDURE TimeIt( cWhat, bCode )
   LOCAL n, t := hb_MilliSeconds()
   FOR n := 1 TO 20000
      Eval( bCode )
   NEXT
   OutStd( "ctlapi: " + PadR( cWhat, 26 ) + Str( ( hb_MilliSeconds() - t ) * 1000 / 20, 8, 0 ) + " ns/call" + hb_eol() )
RETURN

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "ctlapi: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
