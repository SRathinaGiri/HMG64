/*----------------------------------------------------------------------------
 HMG5 IDE - completion of Form. and Form.Control. in the built-in code editor
 (PHASE4-DESIGN.md section 6.7)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 The editor (ide_editw.c) asks IDE_ED_MEMBERS( hView, cChain ) after a dot:
   Win_Main.          the controls of Win_Main (project index, prjindex.prg) and the
                      window's properties and methods
   Win_Main.Btn_Ok.   the properties and methods of a button
   ThisWindow. / This.  the window's / a control's
 The forms and controls come from the project's files on disk and from the text
 being edited (not saved yet). The property and method names are the ones
 GetProperty / SetProperty / DoMethod of HMG5 (SOURCE\h_controlmisc.prg and its
 hooks) understand; tests/ide checks each one against that source.
---------------------------------------------------------------------------*/

#include "hmg.ch"

MEMVAR ProjectName

STATIC s_hProj  := NIL     // index of the project's files on disk
STATIC s_cProj  := ""      // what it was built from (.hbp or folder)
STATIC s_aTimes := {}      // { cFile, tTime } it was built with

#define M_PROPS    2
#define M_METHODS  3
#define M_COMMON   4

/* { cType, cProperties, cMethods, lCommon }: lCommon adds the properties and methods
   every visible control has (the "*" row) */
STATIC FUNCTION IDE_MemberTable()
   STATIC s_a := NIL
   IF s_a == NIL
      s_a := { ;
         { "WINDOW", "Title Row Col Width Height ClientAreaWidth ClientAreaHeight Enabled FocusedControl Handle Index Name " + ;
                     "NoCaption NoClose NoMaximize NoMinimize NoSize NoSysMenu HScroll VScroll IsMaximized IsMinimized " + ;
                     "NotifyIcon NotifyTooltip Cursor BackColorTransparent AlphaBlendTransparent", ;
                     "Activate Center CenterDesktop Show Hide Release Maximize Minimize Restore SetFocus Redraw Print Capture", .F. }, ;
         { "*",      "Value Enabled Visible Row Col Width Height ToolTip FontName FontSize FontBold FontItalic FontUnderline " + ;
                     "FontStrikeout FontColor BackColor Name Handle Type Index", ;
                     "SetFocus Show Hide Release Refresh Redraw", .F. }, ;
         { "BUTTON",        "Caption Picture Icon", "", .T. }, ;
         { "CHECKBOX",      "Caption", "", .T. }, ;
         { "CHECKBUTTON",   "Caption Picture", "", .T. }, ;
         { "LABEL",         "", "", .T. }, ;
         { "HYPERLINK",     "Address", "", .T. }, ;
         { "TEXTBOX",       "DisplayValue ReadOnly CaretPos GetTextLength", "", .T. }, ;
         { "EDITBOX",       "ReadOnly CaretPos GetTextLength", "", .T. }, ;
         { "RICHEDITBOX",   "ReadOnly AutoURLDetect CanPaste CanRedo CanUndo CaretPos FindText FontBackColor FontScript " + ;
                            "GetClickLinkRange GetClickLinkText GetPosChar GetSelectText GetTextLength GetTextRange Link " + ;
                            "ParaAlignment ParaIndent ParaLineSpacing ParaNumbering ParaNumberingStart ParaNumberingStyle " + ;
                            "ParaOffset ReplaceAllText ReplaceText RTFTextMode SelectRange ViewRect Zoom AddText " + ;
                            "AddTextAndSelect BackgroundColor", ;
                            "ClearUndoBuffer LoadFile Redo RTFLoadFile RTFPrint RTFSaveFile SaveFile SelClear SelCopy SelCut " + ;
                            "SelectAll SelPaste SelPasteSpecial Undo UnSelectAll", .T. }, ;
         { "LISTBOX",       "Item ItemCount", "AddItem DeleteItem DeleteAllItems", .T. }, ;
         { "COMBOBOX",      "DisplayValue Item ItemCount", "AddItem DeleteItem DeleteAllItems", .T. }, ;
         { "COMBOSEARCHBOX", "DisplayValue Item ItemCount", "AddItem DeleteItem DeleteAllItems", .T. }, ;
         { "GRID",          "Item ItemCount Cell Header HeaderImages AllowEdit AllowAppend AllowDelete InputItems DisplayItems " + ;
                            "CellEx CellNavigation CellColClicked CellColFocused CellRowClicked CellRowFocused " + ;
                            "CheckBoxEnabled CheckBoxItem CheckBoxAllItems ColumnControl ColumnCount ColumnDisplayPosition " + ;
                            "ColumnDynamicBackColor ColumnDynamicFont ColumnDynamicForeColor ColumnHeader ColumnJustify " + ;
                            "ColumnOnHeadClick ColumnValid ColumnWhen ColumnWidth EditOption GroupEnabled GroupExist " + ;
                            "GroupGetAllItemIndex GroupInfo GroupItemID HeaderDynamicBackColor HeaderDynamicFont " + ;
                            "HeaderDynamicForeColor HeaderImageIndex ImageIndex ImageList PaintDoubleBuffer BackgroundImage", ;
                            "AddItem AddItemEx DeleteItem DeleteAllItems AddColumn AddColumnEx DeleteColumn DisableUpdate " + ;
                            "EnableUpdate GroupAdd GroupDelete GroupDeleteAll GroupDeleteAllItems GroupExpand GroupCollapsed", .T. }, ;
         { "BROWSE",        "RecNo AllowEdit AllowAppend AllowDelete InputItems DisplayItems", "Delete Recall", .T. }, ;
         { "TREE",          "Item ItemCount AllValue Cargo CargoScan ChildValue FirstItemValue FullRowSelect GetDisplayLevel " + ;
                            "GetPathName GetPathValue HasButton HasLines ImageCount ImageIndex ImageList IsExpand IsTrueNode " + ;
                            "ItemText NodeFlag ParentValue RootValue SiblingValue AddImage DynamicBackColor DynamicFont " + ;
                            "DynamicForeColor LineColor TextColor", ;
                            "AddItem DeleteItem DeleteAllItems Expand Collapse Sort SetDefaultNodeFlag SetDefaultAllNodeFlag", .T. }, ;
         { "TAB",           "Caption ItemCount", "AddPage DeletePage AddControl", .T. }, ;
         { "SPINNER",       "RangeMin RangeMax", "", .T. }, ;
         { "SLIDER",        "RangeMin RangeMax", "", .T. }, ;
         { "PROGRESSBAR",   "RangeMin RangeMax", "", .T. }, ;
         { "DATEPICKER",    "", "", .T. }, ;
         { "TIMEPICKER",    "Format", "", .T. }, ;
         { "MONTHCALENDAR", "", "", .T. }, ;
         { "RADIOGROUP",    "Caption ReadOnly", "", .T. }, ;
         { "IPADDRESS",     "", "", .T. }, ;
         { "FRAME",         "Caption", "", .T. }, ;
         { "IMAGE",         "Picture HBitmap", "", .T. }, ;
         { "ANIMATEBOX",    "", "Open Play Seek Stop Close", .T. }, ;
         { "PLAYER",        "Volume Position Repeat Speed Zoom Length", "Play PlayReverse Stop Pause Resume Close Eject Open OpenDialog", .T. }, ;
         { "ACTIVEX",       "Object", "", .T. }, ;
         { "WEBVIEW",       "Url Html CanGoBack CanGoForward Ready Error ZoomFactor UserDataFolder", ;
                            "Navigate SetHtml ExecuteScript PostMessage GoBack GoForward Reload Stop", .T. }, ;
         { "TIMER",         "Value Enabled Name", "Release", .F. }, ;
         { "TOOLBUTTON",    "Caption Value Enabled ToolTip Picture", "", .F. }, ;
         { "MENUITEM",      "Checked Enabled", "", .F. } }
   ENDIF
RETURN s_a

/* IDE_MemberNames( cType ) -> { { cName, cHint }, ... } of a window ("WINDOW") or a control type */
FUNCTION IDE_MemberNames( cType )
   LOCAL aT := IDE_MemberTable(), n, aRes := {}, lCommon
   cType := Upper( cType )
   n := AScan( aT, {| a | a[ 1 ] == cType } )
   lCommon := n == 0 .OR. aT[ n ][ M_COMMON ]      // an unknown (custom) control: the common ones
   IF n > 0
      AddNames( aRes, aT[ n ][ M_PROPS ], "property" )
      AddNames( aRes, aT[ n ][ M_METHODS ], "method" )
   ENDIF
   IF lCommon
      n := AScan( aT, {| a | a[ 1 ] == "*" } )
      AddNames( aRes, aT[ n ][ M_PROPS ], "property" )
      AddNames( aRes, aT[ n ][ M_METHODS ], "method" )
   ENDIF
   ASort( aRes,,, {| x, y | Upper( x[ 1 ] ) < Upper( y[ 1 ] ) } )
RETURN aRes

STATIC PROCEDURE AddNames( aRes, cList, cHint )
   LOCAL c
   FOR EACH c IN hb_ATokens( cList, " " )
      IF ! Empty( c ) .AND. AScan( aRes, {| a | Upper( a[ 1 ] ) == Upper( c ) } ) == 0
         AAdd( aRes, { c, cHint } )
      ENDIF
   NEXT
RETURN

/* every name of the table (tests: each must be known to h_controlmisc.prg) */
FUNCTION IDE_MemberAllNames()
   LOCAL a, aRes := {}
   FOR EACH a IN IDE_MemberTable()
      AddNames( aRes, a[ M_PROPS ] + " " + a[ M_METHODS ], "" )
   NEXT
RETURN aRes

/* the editor's question after a dot (ide_editw.c ac_members) */
FUNCTION IDE_ED_MEMBERS( hView, cChain )
   LOCAL aParts := hb_ATokens( cChain, "." ), aRes := {}, aIdx, hF, hC, cC, a, cFirst

   cFirst := Upper( aParts[ 1 ] )
   IF Len( aParts ) == 1
      IF cFirst == "THISWINDOW"
         RETURN Pairs( IDE_MemberNames( "WINDOW" ) )
      ELSEIF cFirst == "THIS"
         RETURN Pairs( IDE_MemberNames( "*" ) )
      ENDIF
   ENDIF
   IF Len( aParts ) > 2
      RETURN {}
   ENDIF

   aIdx := IDE_CompleteIndexes( hView )
   IF Len( aParts ) == 1
      hF := FindForm( aIdx, aParts[ 1 ] )
      IF hF == NIL
         RETURN {}
      ENDIF
      FOR EACH a IN aIdx
         IF hb_HHasKey( a[ "forms" ], aParts[ 1 ] )
            FOR EACH cC IN hb_HKeys( a[ "forms" ][ aParts[ 1 ] ][ "controls" ] )
               hC := a[ "forms" ][ aParts[ 1 ] ][ "controls" ][ cC ]
               IF AScan( aRes, {| x | Upper( x[ 1 ] ) == Upper( hC[ "name" ] ) } ) == 0
                  AAdd( aRes, { hC[ "name" ], Lower( hC[ "type" ] ) } )
               ENDIF
            NEXT
         ENDIF
      NEXT
      ASort( aRes,,, {| x, y | Upper( x[ 1 ] ) < Upper( y[ 1 ] ) } )   // the controls first
      FOR EACH a IN IDE_MemberNames( "WINDOW" )
         IF AScan( aRes, {| x | Upper( x[ 1 ] ) == Upper( a[ 1 ] ) } ) == 0   // a control named like a property wins
            AAdd( aRes, a )
         ENDIF
      NEXT
      RETURN Pairs( aRes )
   ENDIF

   // Form.Control.  (ThisWindow.Control.: the control in any form)
   FOR EACH a IN aIdx
      FOR EACH hF IN a[ "forms" ]
         IF ( cFirst == "THISWINDOW" .OR. Upper( hF[ "name" ] ) == cFirst ) .AND. hb_HHasKey( hF[ "controls" ], aParts[ 2 ] )
            RETURN Pairs( IDE_MemberNames( hF[ "controls" ][ aParts[ 2 ] ][ "type" ] ) )
         ENDIF
      NEXT
   NEXT
RETURN {}

STATIC FUNCTION FindForm( aIdx, cName )
   LOCAL a
   FOR EACH a IN aIdx
      IF hb_HHasKey( a[ "forms" ], cName )
         RETURN a[ "forms" ][ cName ]
      ENDIF
   NEXT
RETURN NIL

STATIC FUNCTION Pairs( a )
   LOCAL aRes := Array( Len( a ) ), i
   FOR i := 1 TO Len( a )
      aRes[ i ] := a[ i ][ 1 ] + iif( Empty( a[ i ][ 2 ] ), "", Chr( 9 ) + a[ i ][ 2 ] )
   NEXT
RETURN aRes

/* { hIndexOfTheTextBeingEdited, hIndexOfTheProject }: the project's files on disk (built
   again when one of them changed), and the editor's text of this file */
STATIC FUNCTION IDE_CompleteIndexes( hView )
   LOCAL cFile := IDE_EdViewFile( hView ), cTarget, hBuf, lStale, a, t, aF

   cTarget := iif( Empty( ProjectName ), "", ProjectName )
   IF Empty( cTarget ) .OR. ! hb_FileExists( cTarget )
      cTarget := iif( Empty( cFile ), "", hb_FNameDir( cFile ) )
   ENDIF

   lStale := s_hProj == NIL .OR. ! ( s_cProj == cTarget )
   IF ! lStale
      FOR EACH a IN s_aTimes
         IF ! hb_FGetDateTime( a[ 1 ], @t ) .OR. ! ( t == a[ 2 ] )
            lStale := .T.
            EXIT
         ENDIF
      NEXT
   ENDIF
   IF lStale .AND. ! Empty( cTarget )
      s_hProj := HMGIdx_Project( cTarget )
      s_cProj := cTarget
      s_aTimes := {}
      aF := AClone( s_hProj[ "files" ] )
      IF hb_FileExists( cTarget )
         AAdd( aF, cTarget )   // the .hbp: a module added or removed
      ENDIF
      FOR EACH a IN aF
         IF hb_FGetDateTime( a, @t )
            AAdd( s_aTimes, { a, t } )
         ENDIF
      NEXT
   ENDIF

   hBuf := HMGIdx_New( iif( Empty( cFile ), hb_cwd(), hb_FNameDir( cFile ) ) )
   IF s_hProj != NIL
      hBuf[ "custom" ] := s_hProj[ "custom" ]
   ENDIF
   HMGIdx_File( hBuf, iif( Empty( cFile ), "untitled.prg", cFile ), NIL, IDEED_GETTEXT( hView ) )
RETURN iif( s_hProj == NIL, { hBuf }, { hBuf, s_hProj } )
