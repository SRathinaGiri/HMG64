/*
 * Regression test for Phase 3 S2 (PHASE3-DESIGN.md): GetProperty / SetProperty /
 * DoMethod now evaluate the GridEx/Tree/RichEditBox hook guard once and call only the
 * matching hook; the name accessors evaluate their macro once. Results must not change:
 * each hook still answers for its own control type, plain controls bypass all three,
 * and window properties are unaffected. Also prints the per-call cost (information only,
 * not asserted: timings vary by machine).
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   // A runtime error must fail the test, not open HMG's modal "Program Error" box.
   ErrorBlock( {| e | OutStd( "props: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   DEFINE WINDOW Win_1 AT 0, 0 WIDTH 500 HEIGHT 400 TITLE "props" MAIN NOSHOW ON INIT RunChecks()
      @ 10, 10 LABEL Lbl_1 VALUE "hello" WIDTH 80 HEIGHT 20
      @ 40, 10 TEXTBOX Text_1 VALUE "abc" WIDTH 120
      @ 70, 10 GRID Grid_1 WIDTH 200 HEIGHT 100 HEADERS { "A", "B" } WIDTHS { 80, 80 } ;
         ITEMS { { "1", "2" }, { "3", "4" } }
      DEFINE TREE Tree_1 AT 180, 10 WIDTH 150 HEIGHT 100
         NODE "Root"
            TREEITEM "Item 1"
            TREEITEM "Item 2"
         END NODE
      END TREE
      @ 290, 10 RICHEDITBOX Rich_1 WIDTH 200 HEIGHT 60 VALUE "rich"
   END WINDOW
   ACTIVATE WINDOW Win_1
RETURN NIL

STATIC FUNCTION RunChecks()
   LOCAL n, t, x

   // plain controls: no hook applies
   Check( "label value",        GetProperty( "Win_1", "Lbl_1", "Value" ) == "hello" )
   SetProperty( "Win_1", "Text_1", "Value", "xyz" )
   Check( "textbox set/get",    GetProperty( "Win_1", "Text_1", "Value" ) == "xyz" )
   Check( "label row",          GetProperty( "Win_1", "Lbl_1", "Row" ) == 10 )
   Check( "label width",        GetProperty( "Win_1", "Lbl_1", "Width" ) == 80 )
   Check( "type via getprop",   GetProperty( "Win_1", "Grid_1", "Type" ) == "GRID" )

   // GridEx hook (GRID): getter with an index argument, setter, and a non-hook method
   Check( "grid columncount",   GetProperty( "Win_1", "Grid_1", "ColumnCount" ) == 2 )
   SetProperty( "Win_1", "Grid_1", "ColumnHeader", 1, "Amt" )
   Check( "grid columnheader",  GetProperty( "Win_1", "Grid_1", "ColumnHeader", 1 ) == "Amt" )
   Check( "grid itemcount",     GetProperty( "Win_1", "Grid_1", "ItemCount" ) == 2 )
   DoMethod( "Win_1", "Grid_1", "DeleteAllItems" )
   Check( "grid deleteall",     GetProperty( "Win_1", "Grid_1", "ItemCount" ) == 0 )

   // Tree hook
   x := GetProperty( "Win_1", "Tree_1", "AllValue" )
   Check( "tree allvalue",      HB_ISARRAY( x ) .AND. Len( x ) == 3 )

   // RichEditBox hook. Before the c_richeditbox.c class-name fix the ANSI library never
   // created the control (handle 0), so these failed there.
   Check( "richedit created",   GetControlHandle( "Rich_1", "Win_1" ) != 0 )
   x := GetProperty( "Win_1", "Rich_1", "FontName" )
   Check( "richedit fontname",  HB_ISSTRING( x ) .AND. ! Empty( x ) )
   Check( "richedit value",     GetProperty( "Win_1", "Rich_1", "Value" ) == "rich" )
   SetProperty( "Win_1", "Rich_1", "Value", "changed" )
   Check( "richedit set value", GetProperty( "Win_1", "Rich_1", "Value" ) == "changed" )
   // whole-text range: the buffer used to be one TCHAR short (stack overflow by one)
   Check( "richedit textrange", RichEditBox_GetTextRange( GetControlHandle( "Rich_1", "Win_1" ), { 0, -1 } ) == "changed" )
   Check( "richedit textlength", RichEditBox_GetTextLength( GetControlHandle( "Rich_1", "Win_1" ) ) == 7 )
   Check( "richedit partrange",  RichEditBox_GetTextRange( GetControlHandle( "Rich_1", "Win_1" ), { 1, 4 } ) == "han" )
   RichEditBox_SetSelRange( GetControlHandle( "Rich_1", "Win_1" ), { 0, 2 } )
   RichEditBox_ReplaceSel( GetControlHandle( "Rich_1", "Win_1" ), "ex" )
   Check( "richedit replacesel", GetProperty( "Win_1", "Rich_1", "Value" ) == "exanged" )
   RichEditBox_SetSelRange( GetControlHandle( "Rich_1", "Win_1" ), { 0, 0 } )
   RichEditBox_FindText( GetControlHandle( "Rich_1", "Win_1" ), "ang", .T., .F., .F., .T. )
   x := RichEditBox_GetSelRange( GetControlHandle( "Rich_1", "Win_1" ) )
   Check( "richedit findtext",   x[ 1 ] == 2 .AND. x[ 2 ] == 5 )

   // window properties (2 and 3 arguments: the hooks' guard must reject them)
   Check( "window title",       GetProperty( "Win_1", "Title" ) == "props" )
   SetProperty( "Win_1", "Title", "props2" )
   Check( "window title set",   GetProperty( "Win_1", "Title" ) == "props2" )

   // name accessors (single macro evaluation)
   Check( "isdefined yes",      _IsControlDefined( "Lbl_1", "Win_1" ) )
   Check( "isdefined quoted",   _IsControlDefined( "'Lbl_1'", "Win_1" ) )
   Check( "isdefined no",       ! _IsControlDefined( "Nope", "Win_1" ) )
   Check( "isdefined no form",  ! _IsControlDefined( "Lbl_1", "NoForm" ) )
   Check( "controltype",        GetControlType( "Tree_1", "Win_1" ) == "TREE" )
   Check( "controlhandle",      GetControlHandle( "Lbl_1", "Win_1" ) != 0 )
   Check( "controlname",        GetControlName( "Lbl_1", "Win_1" ) == "Lbl_1" )
   Check( "formhandle",         GetFormHandle( "Win_1" ) != 0 )
   Check( "windowdefined",      _IsWindowDefined( "Win_1" ) .AND. ! _IsWindowDefined( "NoForm" ) )
   Check( "windowtype",         GetWindowType( "Win_1" ) == "A" )

   // information only
   t := hb_MilliSeconds()
   FOR n := 1 TO 20000
      x := GetProperty( "Win_1", "Lbl_1", "Value" )
   NEXT
   OutStd( "props: GetProperty(label,Value) " + hb_ntos( Int( ( hb_MilliSeconds() - t ) * 1000 / 20 ) ) + " ns/call" + hb_eol() )

   OutStd( "props: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   // Not QUIT / __Quit(): HMG's exit path ends in ReleaseAllWindows() -> ExitProcess(0),
   // which would turn a failure into exit code 0.
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC PROCEDURE Check( cName, lOk )
   IF lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "props: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
