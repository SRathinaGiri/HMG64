/*----------------------------------------------------------------------------
 HMG - Harbour Windows GUI library source code

 Copyright 2002-2017 Roberto Lopez <mail.box.hmg@gmail.com>
 http://sites.google.com/site/hmgweb/

 Head of HMG project:

      2002-2012 Roberto Lopez <mail.box.hmg@gmail.com>
      http://sites.google.com/site/hmgweb/

      2012-2017 Dr. Claudio Soto <srvet@adinet.com.uy>
      http://srvet.blogspot.com

 This program is free software; you can redistribute it and/or modify it under 
 the terms of the GNU General Public License as published by the Free Software 
 Foundation; either version 2 of the License, or (at your option) any later 
 version. 

 This program is distributed in the hope that it will be useful, but WITHOUT 
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with 
 this software; see the file COPYING. If not, write to the Free Software 
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA (or 
 visit the web site http://www.gnu.org/).

 As a special exception, you have permission for additional uses of the text 
 contained in this release of HMG.

 The exception is that, if you link the HMG library with other 
 files to produce an executable, this does not by itself cause the resulting 
 executable to be covered by the GNU General Public License.
 Your use of that executable is in no way restricted on account of linking the 
 HMG library code into it.

 Parts of this project are based upon:

	"Harbour GUI framework for Win32"
 	Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 	Copyright 2001 Antonio Linares <alinares@fivetech.com>
	www - http://www.harbour-project.org

	"Harbour Project"
	Copyright 1999-2008, http://www.harbour-project.org/

	"WHAT32"
	Copyright 2002 AJ Wos <andrwos@aust1.net> 

	"HWGUI"
  	Copyright 2001-2008 Alexander S.Kresin <alex@belacy.belgorod.su>

---------------------------------------------------------------------------*/
MEMVAR _HMG_SYSDATA
MEMVAR _HMG_SYSDATA_cButtonName
MEMVAR _HMG_SYSDATA_nControlHandle


#include "hmg.ch"
*------------------------------------------------------------------------------*
Function _DefineMainMenu ( Parent )
*------------------------------------------------------------------------------*

   if valtype(Parent) == 'U'
      Parent := _HMG_SYSDATA [ 223 ]
   Endif


   IF IsMainMenuDefined (Parent) == .T.     // ADD
      MsgHMGError("Main Menu already defined in Window: "+ Parent + ". Program Terminated" )
   ENDIF


	_HMG_SYSDATA [ 218 ] := 'MAIN'
	_HMG_SYSDATA [ 172 ] := 0
	_HMG_SYSDATA [ 173 ] := 0
	_HMG_SYSDATA [ 174 ] := 0 
	_HMG_SYSDATA [ 220 ] := ""


	_HMG_SYSDATA [ 173 ] := GetFormHandle ( Parent )
	_HMG_SYSDATA [ 220 ] := Parent
	_HMG_SYSDATA [ 172 ] := CreateMenu()

Return Nil
*------------------------------------------------------------------------------*
Function _DefineMenuPopup ( Caption , Name )
*------------------------------------------------------------------------------*
Local mVar , k

	If _HMG_SYSDATA [ 218 ] == 'MAIN'

		_HMG_SYSDATA [ 174 ]++

		_HMG_SYSDATA [ 335 ] [ _HMG_SYSDATA [ 174 ] ] := CreatePopupMenu()

		_HMG_SYSDATA [ 336 ] [ _HMG_SYSDATA [ 174 ] ] := Caption

		If _HMG_SYSDATA [ 174 ] > 1
			AppendMenuPopup ( _HMG_SYSDATA [ 335 ] [_HMG_SYSDATA [ 174 ] - 1 ] , _HMG_SYSDATA [ 335 ] [ _HMG_SYSDATA [ 174 ] ] , _HMG_SYSDATA [ 336 ] [ _HMG_SYSDATA [ 174 ] ] )
		EndIf

		if valtype (name) != 'U'

			mVar := '_' + _HMG_SYSDATA [ 220 ] + '_' + Name

			k := _GetControlFree()

			Public &mVar. := k
	
			_HMG_SYSDATA [HMG_CTL_TYPE] [k] :=  "POPUP" 
			_HMG_SYSDATA [HMG_CTL_NAME]  [k] :=  Name 
			_HMG_SYSDATA [HMG_CTL_HANDLE]  [k] :=  _HMG_SYSDATA [ 172 ]   // Main Menu Handle  // Dr. Claudio Soto (July 2013)  // 0
			_HMG_SYSDATA [HMG_CTL_PARENTHANDLE]  [k] :=  _HMG_SYSDATA [ 173 ]   // Form Parent Handle
			_HMG_SYSDATA [  HMG_CTL_ID ]  [k] :=  0 
			_HMG_SYSDATA [  HMG_CTL_PROCEDURE ] [k] :=   Nil
			_HMG_SYSDATA [  HMG_CTL_PAGEMAP ]  [k] :=   _HMG_SYSDATA [ 172 ]   // Main Menu Handle
			_HMG_SYSDATA [  HMG_CTL_VALUE ]  [k] :=  Nil 
			_HMG_SYSDATA [  HMG_CTL_INPUTMASK ]   [k] := "" 
			_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ]  [k] :=  "" 
			_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ]  [k] :=  "" 
			_HMG_SYSDATA [ HMG_CTL_CHANGE ]  [k] :=  "MAIN_MENU_POPUP"   // ADD
			_HMG_SYSDATA [ HMG_CTL_DELETED ]  [k] :=  .F. 
			_HMG_SYSDATA [ HMG_CTL_BKCOLOR ]  [k] :=  Nil 
			_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ]  [k] :=  Nil 
			_HMG_SYSDATA [ HMG_CTL_DBLCLICK ]   [k] := "" 
			_HMG_SYSDATA [ HMG_CTL_HEADCLICK ]  [k] :=  {} 
			_HMG_SYSDATA [ HMG_CTL_ROW ]  [k] :=  0 
			_HMG_SYSDATA [ HMG_CTL_COL ]  [k] :=  0 
			_HMG_SYSDATA [ HMG_CTL_WIDTH ]  [k] :=  0 
			_HMG_SYSDATA [ HMG_CTL_HEIGHT ]  [k] :=  0 
			_HMG_SYSDATA [ HMG_CTL_SPACING ]  [k] :=  _HMG_SYSDATA [ 335 ] [ _HMG_SYSDATA [ 174 ] ]   // Popup Menu Handle
			_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ]  [k] :=  -1 
			_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ]  [k] :=  -1 
			_HMG_SYSDATA [ HMG_CTL_PICTURE ]  [k] :=  "" 
			_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ]  [k] :=  0 
			_HMG_SYSDATA [ HMG_CTL_FONTNAME ]  [k] :=  '' 
			_HMG_SYSDATA [ HMG_CTL_FONTSIZE ]  [k] :=  0 
			_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ]  [k] :=  {.f.,.f.,.f.,.f.} 
			_HMG_SYSDATA [ HMG_CTL_TOOLTIP ]   [k] :=  ''  
			_HMG_SYSDATA [ HMG_CTL_RANGEMIN ]   [k] :=  0  
			_HMG_SYSDATA [ HMG_CTL_RANGEMAX ]  [k] :=   0  
			_HMG_SYSDATA [ HMG_CTL_CAPTION ]  [k] :=   Caption  
			_HMG_SYSDATA [ HMG_CTL_VISIBLE ]  [k] :=   .t. 
			_HMG_SYSDATA [ HMG_CTL_HELPID ]  [k] :=   0 
			_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ]   [k] :=  0 
			_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ]  [k] :=   0 
			_HMG_SYSDATA [ HMG_CTL_ENABLED ]  [k] :=   .T. 
			_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := 0
			_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

		EndIf

	Else

		MsgHMGError("Context/DropDown/Notify Menus Does Not Support SubMenus. Program Terminated")

	EndIf

Return Nil
*------------------------------------------------------------------------------*
Function _EndMenuPopup()
*------------------------------------------------------------------------------*

	If _HMG_SYSDATA [ 218 ] == 'MAIN'

		_HMG_SYSDATA [ 174 ]--

		If _HMG_SYSDATA [ 174 ] == 0
			AppendMenuPopup ( _HMG_SYSDATA [ 172 ] , _HMG_SYSDATA [ 335 ] [ 1 ] , _HMG_SYSDATA [ 336 ] [ 1 ] )
		EndIf

	Else

		MsgHMGError("Context/DropDown/Notify Menus Does Not Support SubMenus. Program Terminated")

	EndIf

Return Nil
*-----------------------------------------------------------------------------------------*
Function _DefineMenuItem ( caption , action , name , Image , checked , NoTrans, ToolTip )
*-----------------------------------------------------------------------------------------*
Local mVar , k, cTypeMenu :=""
Local id
LOCAL cParentName := "", MenuItemID

	If _HMG_SYSDATA [ 218 ] == 'MAIN'

		Id := _GetId()

		AppendMenuString ( _HMG_SYSDATA [ 335 ] [_HMG_SYSDATA [ 174 ] ] , id ,  caption )   // This Not return a Handle, return lBoolean value

		if Valtype ( image ) != 'U'
			MenuItem_SetBitMaps ( _HMG_SYSDATA [ 335 ] [_HMG_SYSDATA [ 174 ]] , Id , image , "" , NoTrans )
		EndIf

		k := _GetControlFree()

		if valtype (name) != 'U'
			mVar := '_' + _HMG_SYSDATA [ 220 ] + '_' + Name
			Public &mVar. := k
		Else
			*mVar := '_MenuDummyVar'
			*Name := 'DummyMenuName'
			*Public &mVar. := 0  
			Name := ''
		EndIf

		_HMG_SYSDATA [HMG_CTL_TYPE] [k] := "MENU" 
		_HMG_SYSDATA [HMG_CTL_NAME]  [k] :=  Name 
		_HMG_SYSDATA [HMG_CTL_HANDLE]  [k] :=  _HMG_SYSDATA [ 172 ]   // Main Menu Handle   // Dr. Claudio Soto (July 2013)  Controlhandle   // This Not a Handle, this is lBoolean value
		_HMG_SYSDATA [HMG_CTL_PARENTHANDLE]  [k] :=  _HMG_SYSDATA [ 173 ]   // Form Parent Handle
		_HMG_SYSDATA [  HMG_CTL_ID ]  [k] :=  id 
		_HMG_SYSDATA [  HMG_CTL_PROCEDURE ]  [k] :=  action 
		_HMG_SYSDATA [  HMG_CTL_PAGEMAP ]  [k] :=  _HMG_SYSDATA [ 335 ] [_HMG_SYSDATA [ 174 ] ]   // Popup Menu Handle
		_HMG_SYSDATA [  HMG_CTL_VALUE ]  [k] :=  Nil                                            // _HMG_SYSDATA [ 335 ] -> _HMG_xMenuPopuphandle
		_HMG_SYSDATA [  HMG_CTL_INPUTMASK ]  [k] :=  ""                                             // _HMG_SYSDATA [ 174 ] -> counter of Popup Menu Handle 
		_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ]  [k] :=  ""
		_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ]  [k] :=  ""
		_HMG_SYSDATA [ HMG_CTL_CHANGE ]  [k] :=  "MAIN_MENU_ITEM"   // ADD 
		_HMG_SYSDATA [ HMG_CTL_DELETED ]  [k] :=  .F. 
		_HMG_SYSDATA [ HMG_CTL_BKCOLOR ]  [k] :=  Nil 
		_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ] [k] :=   Nil 
		_HMG_SYSDATA [ HMG_CTL_DBLCLICK ]   [k] := "" 
		_HMG_SYSDATA [ HMG_CTL_HEADCLICK ]  [k] :=  {} 
		_HMG_SYSDATA [ HMG_CTL_ROW ]  [k] :=  0 
		_HMG_SYSDATA [ HMG_CTL_COL ]   [k] := 0 
		_HMG_SYSDATA [ HMG_CTL_WIDTH ]  [k] :=  0 
		_HMG_SYSDATA [ HMG_CTL_HEIGHT ]  [k] :=  0 
		_HMG_SYSDATA [ HMG_CTL_SPACING ]  [k] :=  0 
		_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ]  [k] :=  -1 
		_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ]  [k] :=  -1 
		_HMG_SYSDATA [ HMG_CTL_PICTURE ]  [k] :=  "" 
		_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ]  [k] :=  0 
		_HMG_SYSDATA [ HMG_CTL_FONTNAME ]  [k] :=  '' 
		_HMG_SYSDATA [ HMG_CTL_FONTSIZE ]  [k] :=  0 
		_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ]  [k] :=  {.f.,.f.,.f.,.f.} 
		_HMG_SYSDATA [ HMG_CTL_TOOLTIP ]   [k] :=  ToolTip
		_HMG_SYSDATA [ HMG_CTL_RANGEMIN ]  [k] :=   0  
		_HMG_SYSDATA [ HMG_CTL_RANGEMAX ]   [k] :=  0  
		_HMG_SYSDATA [ HMG_CTL_CAPTION ]  [k] :=   Caption  
		_HMG_SYSDATA [ HMG_CTL_VISIBLE ]  [k] :=   .t. 
		_HMG_SYSDATA [ HMG_CTL_HELPID ]  [k] :=   0 
		_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ]  [k] :=   0 
		_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ]   [k] :=  0 
		_HMG_SYSDATA [ HMG_CTL_ENABLED ]  [k] :=   .T. 
		_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := 0
		_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }   // ToolTip MenuItem Data

		if checked == .t.
			xCheckMenuItem ( _HMG_SYSDATA [ 335 ] [_HMG_SYSDATA [ 174 ] ] , id )
		EndIf
			
	Else

		id := _GetId()

		AppendMenuString ( _HMG_SYSDATA [ 175 ] , id ,  caption )   // This Not return a Handle, return lBoolean value

		if Valtype ( image ) != 'U'
			MenuItem_SetBitMaps ( _HMG_SYSDATA [ 175 ] , Id , image , "" , NoTrans )
		EndIf

		k := _GetControlFree()

		if valtype (name) != 'U'
			mVar := '_' + _HMG_SYSDATA [ 221 ] + '_' + Name
			Public &mVar. := k
		Else
			*mVar := '_MenuDummyVar'
			*Name := 'DummyMenuName'
			*Public &mVar. := 0  
			Name := ''
		EndIf


        IF     _HMG_SYSDATA [ 218 ] == "CONTEXT"       // ADD
               cTypeMenu := "CONTEXT_MENU_ITEM"        // ADD
        ELSEIF _HMG_SYSDATA [ 218 ] == "NOTIFY"        // ADD
               cTypeMenu := "NOTIFY_MENU_ITEM"         // ADD
        ELSEIF _HMG_SYSDATA [ 218 ] == "DROPDOWN"      // ADD
               cTypeMenu := "DROPDOWN_MENU_ITEM"       // ADD
        ELSEIF _HMG_SYSDATA [ 218 ] == "CONTROL"       // ADD
               cTypeMenu := "CONTROL_MENU_ITEM"        // ADD
        ENDIF


		_HMG_SYSDATA [  HMG_CTL_TYPE ]  [k] :=   "MENU" 
		_HMG_SYSDATA [  HMG_CTL_NAME ]  [k] :=   Name 
		_HMG_SYSDATA [  HMG_CTL_HANDLE ]  [k] :=   _HMG_SYSDATA [ 175 ]   // Popup Menu Handle  // Dr. Claudio Soto (July 2013)   Controlhandle   // This Not a Handle, this is lBoolean value
		_HMG_SYSDATA [  HMG_CTL_PARENTHANDLE ]  [k] :=   _HMG_SYSDATA [ 176 ]   // _HMG_SYSDATA [ 176 ] := GetFormHandle ( Parent )   // Form Parent Handle
		_HMG_SYSDATA [  HMG_CTL_ID ]  [k] :=   id 
		_HMG_SYSDATA [  HMG_CTL_PROCEDURE ]  [k] :=   action 
		_HMG_SYSDATA [  HMG_CTL_PAGEMAP ]  [k] :=   _HMG_SYSDATA [ 175 ]   //_HMG_SYSDATA [ 175 ] := CreatePopupMenu()   // Popup Menu Handle 
		_HMG_SYSDATA [  HMG_CTL_VALUE ]  [k] :=   Nil 
		_HMG_SYSDATA [  HMG_CTL_INPUTMASK ]  [k] :=   ""
		_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ]  [k] :=   ""
		_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ]  [k] :=   _HMG_SYSDATA_cButtonName   // ADD
      _HMG_SYSDATA [ HMG_CTL_CHANGE ]  [k] :=   cTypeMenu         // ADD
		_HMG_SYSDATA [ HMG_CTL_DELETED ]  [k] :=   .F. 
		_HMG_SYSDATA [ HMG_CTL_BKCOLOR ]  [k] :=   Nil 
		_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ]  [k] :=   Nil 
		_HMG_SYSDATA [ HMG_CTL_DBLCLICK ]  [k] :=   "" 
		_HMG_SYSDATA [ HMG_CTL_HEADCLICK ]  [k] :=   {} 
		_HMG_SYSDATA [ HMG_CTL_ROW ]  [k] :=   _HMG_SYSDATA_nControlHandle // ADD
		_HMG_SYSDATA [ HMG_CTL_COL ]  [k] :=   0 
		_HMG_SYSDATA [ HMG_CTL_WIDTH ]  [k] :=   0 
		_HMG_SYSDATA [ HMG_CTL_HEIGHT ]  [k] :=   0 
		_HMG_SYSDATA [ HMG_CTL_SPACING ]  [k] :=   0 
		_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ]  [k] :=   -1 
		_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ]  [k] :=   -1 
		_HMG_SYSDATA [ HMG_CTL_PICTURE ]  [k] :=   "" 
		_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ]  [k] :=   0 
		_HMG_SYSDATA [ HMG_CTL_FONTNAME ]  [k] :=   '' 
		_HMG_SYSDATA [ HMG_CTL_FONTSIZE ]  [k] :=   0 
		_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ]  [k] :=   {.f.,.f.,.f.,.f.} 
		_HMG_SYSDATA [ HMG_CTL_TOOLTIP ]  [k] :=   ToolTip
		_HMG_SYSDATA [ HMG_CTL_RANGEMIN ]  [k] :=   0  
		_HMG_SYSDATA [ HMG_CTL_RANGEMAX ]  [k] :=   0  
		_HMG_SYSDATA [ HMG_CTL_CAPTION ]  [k] :=   Caption  
		_HMG_SYSDATA [ HMG_CTL_VISIBLE ]  [k] :=   .t. 
		_HMG_SYSDATA [ HMG_CTL_HELPID ]  [k] :=   0 
		_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ]  [k] :=   0
		_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ]  [k] :=   0
		_HMG_SYSDATA [ HMG_CTL_ENABLED ]  [k] :=   .T. 
		_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ]  [k] :=   0
		_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ]  [k] :=   { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

		if checked == .t.
			xCheckMenuItem ( _HMG_SYSDATA [ 175 ] , id )
		EndIf

	EndIf

    // by Dr. Claudio Soto, December 2014
   if valtype(tooltip) != "U"
      GetFormNameByHandle ( _HMG_SYSDATA [ HMG_CTL_PARENTHANDLE ] [ k ] , @cParentName )
      MenuItemID  := _HMG_SYSDATA [ HMG_CTL_ID ] [ k ]
      SetToolTipMenuItem ( GetFormHandle (cParentName), ToolTip, MenuItemID, GetMenuToolTipHandle (cParentName) )
   endif

Return Nil
*------------------------------------------------------------------------------*
Function _DefineSeparator ()
*------------------------------------------------------------------------------*

	If _HMG_SYSDATA [ 218 ] == 'MAIN'

		AppendMenuSeparator ( _HMG_SYSDATA [ 335 ] [_HMG_SYSDATA [ 174 ] ] )
	Else

		AppendMenuSeparator ( _HMG_SYSDATA [ 175 ] )

	EndIf

Return Nil
*------------------------------------------------------------------------------*
Function _EndMenu()
*------------------------------------------------------------------------------*
Local i

	Do Case
	Case _HMG_SYSDATA [ 218 ] == 'MAIN'

		SetMenu( _HMG_SYSDATA [ 173 ] , _HMG_SYSDATA [ 172 ] ) 

	Case _HMG_SYSDATA [ 218 ] == 'CONTEXT'

		i := GetFormIndex ( _HMG_SYSDATA [ 221 ] )
		_HMG_SYSDATA [ HMG_FRM_CONTEXTMENU  ] [i] := _HMG_SYSDATA [ 175 ]

	Case _HMG_SYSDATA [ 218 ] == 'NOTIFY'

		i := GetFormIndex ( _HMG_SYSDATA [ 221 ] )
		_HMG_SYSDATA [ HMG_FRM_NOTIFYMENU ] [i] := _HMG_SYSDATA [ 175 ]

	Case _HMG_SYSDATA [ 218 ] == 'DROPDOWN'

		_HMG_SYSDATA [ HMG_CTL_RANGEMAX ] [_HMG_SYSDATA [ 169 ]] := _HMG_SYSDATA [ 175 ]

	EndCase

Return Nil
*------------------------------------------------------------------------------*
Function _DisableMenuItem ( ItemName , FormName )
*------------------------------------------------------------------------------*
Local i , h , x

	x := GetControlIndex ( ItemName , FormName )

	h := _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [ x ]

	If _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "MENU"
		i := _HMG_SYSDATA [  HMG_CTL_ID ] [ x ]
	ElseIf _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "POPUP"
		i := _HMG_SYSDATA [ HMG_CTL_SPACING ] [ x ]
	EndIf

	xDisableMenuItem ( h , i )

Return Nil
*------------------------------------------------------------------------------*
Function _EnableMenuItem ( ItemName , FormName )
*------------------------------------------------------------------------------*
Local i , h , x

	x := GetControlIndex ( ItemName , FormName )

	h := _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [ x ]

	If _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "MENU"
		i := _HMG_SYSDATA [  HMG_CTL_ID ] [ x ]
	ElseIf _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "POPUP"
		i := _HMG_SYSDATA [ HMG_CTL_SPACING ] [ x ]
	EndIf

	xEnableMenuItem ( h , i )

Return Nil
*------------------------------------------------------------------------------*
Function _CheckMenuItem ( ItemName , FormName )
*------------------------------------------------------------------------------*
Local i , h , x

	x := GetControlIndex ( ItemName , FormName )

	h := _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [ x ]

	If _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "MENU"
		i := _HMG_SYSDATA [  HMG_CTL_ID ] [ x ]
	ElseIf _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "POPUP"
		i := _HMG_SYSDATA [ HMG_CTL_SPACING ] [ x ]
	EndIf

	xCheckMenuItem ( h , i )

Return Nil
*------------------------------------------------------------------------------*
Function _UncheckMenuItem ( ItemName , FormName )
*------------------------------------------------------------------------------*
Local i , h , x

	x := GetControlIndex ( ItemName , FormName )

	h := _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [ x ]

	If _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "MENU"
		i := _HMG_SYSDATA [  HMG_CTL_ID ] [ x ]
	ElseIf _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "POPUP"
		i := _HMG_SYSDATA [ HMG_CTL_SPACING ] [ x ]
	EndIf

	xUncheckMenuItem ( h , i )

Return Nil
*------------------------------------------------------------------------------*
Function _IsMenuItemChecked ( ItemName , FormName )
*------------------------------------------------------------------------------*
Local x,h,i,r,z

	x := GetControlIndex ( ItemName , FormName )

	h := _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [ x ]

	If _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "MENU"
		i := _HMG_SYSDATA [  HMG_CTL_ID ] [ x ]
	ElseIf _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "POPUP"
		i := _HMG_SYSDATA [ HMG_CTL_SPACING ] [ x ]
	EndIf

	r := xGetMenuCheckState ( h , i )

	If r == 1 
		z := .t.
	Else
		z := .f.
	EndIf

Return z
*------------------------------------------------------------------------------*
Function _IsMenuItemEnabled ( ItemName , FormName )
*------------------------------------------------------------------------------*
Local x,h,i,r,z

	x := GetControlIndex ( ItemName , FormName )

	h := _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [ x ]

	If _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "MENU"
		i := _HMG_SYSDATA [  HMG_CTL_ID ] [ x ]
	ElseIf _HMG_SYSDATA [HMG_CTL_TYPE] [ x ] == "POPUP"
		i := _HMG_SYSDATA [ HMG_CTL_SPACING ] [ x ]
	EndIf

	r := xGetMenuEnabledState ( h , i )

	If r == 1 
		z := .t.
	Else
		z := .f.
	EndIf

Return z


*------------------------------------------------------------------------------*
Function _DefineContextMenu ( Parent )
*------------------------------------------------------------------------------*

   IF valtype(Parent) == 'U'
      Parent := _HMG_SYSDATA [ 223 ]
   ENDIF

   PUBLIC _HMG_SYSDATA_cButtonName := ""   // ADD
   PUBLIC _HMG_SYSDATA_nControlHandle := 0 // ADD
   IF IsContextMenuDefined (Parent) == .T.     // ADD
      MsgHMGError("Context Menu already defined in Window: "+ Parent + ". Program Terminated" )
   ENDIF

   _HMG_SYSDATA [ 175 ] := 0
   _HMG_SYSDATA [ 176 ] := 0
   _HMG_SYSDATA [ 177 ] := 0 
   _HMG_SYSDATA [ 221 ] := ""

   _HMG_SYSDATA [ 218 ] := 'CONTEXT'

   _HMG_SYSDATA [ 174 ] := 0

   _HMG_SYSDATA [ 176 ] := GetFormHandle ( Parent )
   _HMG_SYSDATA [ 221 ] := Parent
   _HMG_SYSDATA [ 175 ] := CreatePopupMenu()
   
Return Nil

*------------------------------------------------------------------------------*
Function _DefineNotifyMenu ( Parent )
*------------------------------------------------------------------------------*

   IF valtype(Parent) == 'U'
      Parent := _HMG_SYSDATA [ 223 ]
   ENDIF

   PUBLIC _HMG_SYSDATA_cButtonName := ""   // ADD
   PUBLIC _HMG_SYSDATA_nControlHandle := 0 // ADD
   IF IsNotifyMenuDefined (Parent) == .T.     // ADD
      MsgHMGError("Notify Menu already defined in Window: "+ Parent + ". Program Terminated" )
   ENDIF

   _HMG_SYSDATA [ 175 ] := 0
   _HMG_SYSDATA [ 176 ] := 0
   _HMG_SYSDATA [ 177 ] := 0 
   _HMG_SYSDATA [ 221 ] := ""

   _HMG_SYSDATA [ 218 ] := 'NOTIFY'

   _HMG_SYSDATA [ 174 ] := 0

   _HMG_SYSDATA [ 176 ] := GetFormHandle ( Parent )
   _HMG_SYSDATA [ 221 ] := Parent
   _HMG_SYSDATA [ 175 ] := CreatePopupMenu()

Return Nil

*------------------------------------------------------------------------------*
Function _DefineDropDownMenu ( cButton , Parent )
*------------------------------------------------------------------------------*

   IF valtype(Parent) == 'U'
      Parent := _HMG_SYSDATA [ 223 ]
   ENDIF

   PUBLIC _HMG_SYSDATA_cButtonName := cButton   // ADD
   PUBLIC _HMG_SYSDATA_nControlHandle := 0 // ADD
   IF IsDropDownMenuDefined ( cButton, Parent ) == .T.     // ADD
      MsgHMGError("DropDown Menu of Button: " + cButton + " already defined in Window: "+ Parent + ". Program Terminated" )
   ENDIF

   _HMG_SYSDATA [ 175 ] := 0
   _HMG_SYSDATA [ 176 ] := 0
   _HMG_SYSDATA [ 177 ] := 0 
   _HMG_SYSDATA [ 221 ] := ""

   _HMG_SYSDATA [ 218 ] := 'DROPDOWN'

   _HMG_SYSDATA [ 174 ] := 0

   _HMG_SYSDATA [ 169 ] := GetControlIndex ( cButton , Parent )
   _HMG_SYSDATA [ 176 ] := GetFormHandle ( Parent )
   _HMG_SYSDATA [ 221 ] := Parent
   _HMG_SYSDATA [ 175 ] := CreatePopupMenu()

Return Nil




// Dr. Claudio Soto (March 2013)

*------------------------------------------------------------------------------*
Procedure DeleteItem_HMG_SYSDATA (k)
*------------------------------------------------------------------------------*
          _HMG_SYSDATA [ HMG_CTL_DELETED ] [k] := .T.
          _HMG_SYSDATA [  HMG_CTL_TYPE ] [k] := ""
          _HMG_SYSDATA [  HMG_CTL_NAME ] [k] := ""
          _HMG_SYSDATA [  HMG_CTL_HANDLE ] [k] := 0
          _HMG_SYSDATA [  HMG_CTL_PARENTHANDLE ] [k] := 0
          _HMG_SYSDATA [  HMG_CTL_ID ] [k] := 0
          _HMG_SYSDATA [  HMG_CTL_PROCEDURE ] [k] := ""
          _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [k] := {}
          _HMG_SYSDATA [  HMG_CTL_VALUE ] [k] := NIL
          _HMG_SYSDATA [  HMG_CTL_INPUTMASK ] [k] := ""
          _HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ] [k] := ""
          _HMG_SYSDATA [ HMG_CTL_GOTFOCUS ] [k] := ""
          _HMG_SYSDATA [ HMG_CTL_CHANGE ] [k] := ""
          _HMG_SYSDATA [ HMG_CTL_BKCOLOR ] [k] := NIL
          _HMG_SYSDATA [ HMG_CTL_FONTCOLOR ] [k] := NIL
          _HMG_SYSDATA [ HMG_CTL_DBLCLICK ] [k] := ""
          _HMG_SYSDATA [ HMG_CTL_HEADCLICK ] [k] := {}
          _HMG_SYSDATA [ HMG_CTL_ROW ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_COL ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_WIDTH ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_HEIGHT ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_SPACING ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_CONTAINERROW ] [k] := 0 
          _HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ] [k] := 0 
          _HMG_SYSDATA [ HMG_CTL_PICTURE ] [k] := ''
          _HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ] [k] := 0 
          _HMG_SYSDATA [ HMG_CTL_FONTNAME ] [k] := '' 
          _HMG_SYSDATA [ HMG_CTL_FONTSIZE ] [k] := 0  
          _HMG_SYSDATA [ HMG_CTL_TOOLTIP ] [k] := ''  
          _HMG_SYSDATA [ HMG_CTL_RANGEMIN ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_RANGEMAX ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_CAPTION ] [k] := '' 
          _HMG_SYSDATA [ HMG_CTL_VISIBLE ] [k] := .F.
          _HMG_SYSDATA [ HMG_CTL_HELPID ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_FONTHANDLE ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ] [k] := {}
          _HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_ENABLED ] [k] := .F.
          _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := 0
          _HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := NIL
Return


*------------------------------------------------------------------------------*
Function IsMainMenuDefined ( cParentForm )
*------------------------------------------------------------------------------*
LOCAL hWnd, Ret
    hWnd := GetFormHandle (cParentForm)
    Ret  := ExistMainMenu (hWnd)
Return Ret


*------------------------------------------------------------------------------*
Function IsContextMenuDefined ( cParentForm )
*------------------------------------------------------------------------------*
LOCAL hWnd, k
    hWnd := GetFormHandle ( cParentForm )
    FOR k = 1 TO HMG_LEN (_HMG_SYSDATA [HMG_CTL_TYPE])
       IF (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "MENU") .OR. (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "POPUP")
          IF ((_HMG_SYSDATA [HMG_CTL_CHANGE] [k] == "CONTEXT_MENU_ITEM") .AND. (_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] == hWnd))
               Return .T.
          ENDIF
       ENDIF
    NEXT
Return .F.


*------------------------------------------------------------------------------*
Function IsNotifyMenuDefined ( cParentForm )
*------------------------------------------------------------------------------*
LOCAL hWnd, k
    hWnd := GetFormHandle ( cParentForm )
    FOR k = 1 TO HMG_LEN (_HMG_SYSDATA [HMG_CTL_TYPE])
       IF (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "MENU") .OR. (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "POPUP")
          IF ((_HMG_SYSDATA [HMG_CTL_CHANGE] [k] == "NOTIFY_MENU_ITEM") .AND. (_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] == hWnd))
               Return .T.
          ENDIF
       ENDIF
    NEXT
Return .F.


*------------------------------------------------------------------------------*
Function IsDropDownMenuDefined ( cButton, cParentForm )
*------------------------------------------------------------------------------*
LOCAL hWnd, k
    hWnd := GetFormHandle ( cParentForm )
    FOR k = 1 TO HMG_LEN (_HMG_SYSDATA [HMG_CTL_TYPE])
       IF (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "MENU") .OR. (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "POPUP")
          IF ((_HMG_SYSDATA [HMG_CTL_CHANGE] [k] == "DROPDOWN_MENU_ITEM") .AND. (_HMG_SYSDATA [HMG_CTL_GOTFOCUS] [k] == cButton) .AND. (_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] == hWnd))
               Return .T.
          ENDIF
       ENDIF
    NEXT
Return .F.


*------------------------------------------------------------------------------*
Function ReleaseMainMenu ( cParentForm )
*------------------------------------------------------------------------------*
LOCAL hWnd, k, Ret := 0

    IF VALTYPE (cParentForm) == 'U'
       cParentForm := ThisWindow.Name
    ENDIF

    IF IsMainMenuDefined (cParentForm) == .F.
       MsgHMGError("Main Menu not defined in Window: "+ cParentForm + ". Program Terminated" )
    ENDIF

    hWnd := GetFormHandle ( cParentForm )    
    DeleteMainMenu (hWnd)
    
    FOR k = 1 TO HMG_LEN (_HMG_SYSDATA [HMG_CTL_TYPE])
        IF (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "MENU") .OR. (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "POPUP")
          IF ((_HMG_SYSDATA [HMG_CTL_CHANGE] [k] == "MAIN_MENU_ITEM" .OR. _HMG_SYSDATA [HMG_CTL_CHANGE] [k] == "MAIN_MENU_POPUP") .AND. (_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] == hWnd))
               DeleteItem_HMG_SYSDATA (k)
               Ret ++
          ENDIF
        ENDIF
    NEXT
Return Ret


*------------------------------------------------------------------------------*
Function ReleaseContextMenu ( cParentForm )
*------------------------------------------------------------------------------*
LOCAL hWnd, hMenu, k, Ret := 0

    IF VALTYPE (cParentForm) == 'U'
       cParentForm := ThisWindow.Name
    ENDIF

    IF IsContextMenuDefined (cParentForm) == .F.
       MsgHMGError("Context Menu not defined in Window: "+ cParentForm + ". Program Terminated" )
    ENDIF

    hWnd := GetFormHandle ( cParentForm )    
    
    FOR k = 1 TO HMG_LEN (_HMG_SYSDATA [HMG_CTL_TYPE])
        IF (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "MENU") .OR. (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "POPUP")
          IF ((_HMG_SYSDATA [HMG_CTL_CHANGE] [k] == "CONTEXT_MENU_ITEM") .AND. (_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] == hWnd))
               hMenu := _HMG_SYSDATA [HMG_CTL_PAGEMAP] [k]
               DestroyMenu (hMenu)
               DeleteItem_HMG_SYSDATA (k)
               Ret ++
          ENDIF
        ENDIF
    NEXT
Return Ret


*------------------------------------------------------------------------------*
Function ReleaseNotifyMenu ( cParentForm )
*------------------------------------------------------------------------------*
LOCAL hWnd, hMenu, k, Ret := 0

    IF VALTYPE (cParentForm) == 'U'
       cParentForm := ThisWindow.Name
    ENDIF

    IF IsNotifyMenuDefined (cParentForm) == .F.
       MsgHMGError("Notify Menu not defined in Window: "+ cParentForm + ". Program Terminated" )
    ENDIF

    hWnd := GetFormHandle ( cParentForm )    
    
    FOR k = 1 TO HMG_LEN (_HMG_SYSDATA [HMG_CTL_TYPE])
        IF (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "MENU") .OR. (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "POPUP")
          IF ((_HMG_SYSDATA [HMG_CTL_CHANGE] [k] == "NOTIFY_MENU_ITEM") .AND. (_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] == hWnd))
               hMenu := _HMG_SYSDATA [HMG_CTL_PAGEMAP] [k]
               DestroyMenu (hMenu)
               DeleteItem_HMG_SYSDATA (k)
               Ret ++
          ENDIF
        ENDIF
    NEXT
Return Ret


*------------------------------------------------------------------------------*
Function ReleaseDropDownMenu ( cButton, cParentForm )
*------------------------------------------------------------------------------*
LOCAL hWnd, hMenu, k, Ret := 0

    IF VALTYPE (cParentForm) == 'U'
       cParentForm := ThisWindow.Name
    ENDIF

    IF IsDropDownMenuDefined ( cButton, cParentForm) == .F.
       MsgHMGError("DropDown Menu of Button: " + cButton + " not defined in Window: "+ cParentForm + ". Program Terminated" )
    ENDIF

    hWnd := GetFormHandle ( cParentForm )    
    
    FOR k = 1 TO HMG_LEN (_HMG_SYSDATA [HMG_CTL_TYPE])
        IF (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "MENU") .OR. (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "POPUP")
          IF ((_HMG_SYSDATA [HMG_CTL_CHANGE] [k] == "DROPDOWN_MENU_ITEM") .AND. (_HMG_SYSDATA [HMG_CTL_GOTFOCUS] [k] == cButton) .AND. (_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] == hWnd))
               hMenu := _HMG_SYSDATA [HMG_CTL_PAGEMAP] [k]
               DestroyMenu (hMenu)
               DeleteItem_HMG_SYSDATA (k)
               Ret ++
          ENDIF
        ENDIF
    NEXT
Return Ret





//***************************************************************************************
// Control Context Menu 
//***************************************************************************************

// Dr. Claudio Soto (May 2013)


*------------------------------------------------------------------------------*
Function _DefineControlContextMenu ( cControl, cParentForm )
*------------------------------------------------------------------------------*

   IF valtype(cParentForm) == 'U'
      cParentForm := _HMG_SYSDATA [ 223 ]
   ENDIF

   PUBLIC _HMG_SYSDATA_cButtonName := ""   // ADD
   PUBLIC _HMG_SYSDATA_nControlHandle := 0 // ADD
   IF IsControlContextMenuDefined ( cControl, cParentForm ) == .T.
      MsgHMGError("Context Menu of Control: " + cControl + " already defined in Window: "+ cParentForm + ". Program Terminated" )
   ENDIF

   _HMG_SYSDATA [ 175 ] := 0
   _HMG_SYSDATA [ 176 ] := 0
   _HMG_SYSDATA [ 177 ] := 0 
   _HMG_SYSDATA [ 221 ] := ""

   _HMG_SYSDATA [ 218 ] := 'CONTROL'

   _HMG_SYSDATA [ 174 ] := 0

   _HMG_SYSDATA_nControlHandle := GetControlHandle ( cControl, cParentForm  )
   _HMG_SYSDATA [ 176 ] := GetFormHandle ( cParentForm  )
   _HMG_SYSDATA [ 221 ] := cParentForm
   _HMG_SYSDATA [ 175 ] := CreatePopupMenu()

Return Nil



*------------------------------------------------------------------------------*
Function IsControlContextMenuDefined ( cControl, cParentForm )
*------------------------------------------------------------------------------*
LOCAL hWnd, nControlHandle, k
    hWnd := GetFormHandle ( cParentForm )
    nControlHandle := GetControlHandle ( cControl, cParentForm )
    FOR k = 1 TO HMG_LEN (_HMG_SYSDATA [HMG_CTL_TYPE])
       IF (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "MENU") .OR. (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "POPUP")
          IF ((_HMG_SYSDATA [HMG_CTL_CHANGE] [k] == "CONTROL_MENU_ITEM") .AND. _TestControlHandle_ContextMenu (_HMG_SYSDATA [HMG_CTL_ROW] [k], nControlHandle) .AND. (_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] == hWnd))
               Return .T.
          ENDIF
       ENDIF
    NEXT
Return .F.



*------------------------------------------------------------------------------*
Function ReleaseControlContextMenu ( cControl, cParentForm )
*------------------------------------------------------------------------------*
LOCAL hWnd, hMenu, nControlHandle, k, Ret := 0

    IF VALTYPE (cParentForm) == 'U'
       cParentForm := ThisWindow.Name
    ENDIF

   IF IsControlContextMenuDefined ( cControl, cParentForm ) == .F.
      MsgHMGError("Context Menu of Control: " + cControl + " not defined in Window: "+ cParentForm + ". Program Terminated" )
   ENDIF

    hWnd := GetFormHandle ( cParentForm )    
    nControlHandle := GetControlHandle ( cControl, cParentForm )
    
    FOR k = 1 TO HMG_LEN (_HMG_SYSDATA [HMG_CTL_TYPE])
        IF (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "MENU") .OR. (_HMG_SYSDATA [HMG_CTL_TYPE] [k] == "POPUP")
          IF ((_HMG_SYSDATA [HMG_CTL_CHANGE] [k] == "CONTROL_MENU_ITEM") .AND. _TestControlHandle_ContextMenu (_HMG_SYSDATA [HMG_CTL_ROW] [k], nControlHandle) .AND. (_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] == hWnd))
               hMenu := _HMG_SYSDATA [HMG_CTL_PAGEMAP] [k]
               DestroyMenu (hMenu)
               DeleteItem_HMG_SYSDATA (k)
               Ret ++
          ENDIF
        ENDIF
    NEXT
Return Ret



*------------------------------------------------------------------------------*
Function _TestControlHandle_ContextMenu  ( Handle , ControlHandle )
*------------------------------------------------------------------------------*
LOCAL i, k

   IF ValType (Handle) == "N" .AND. ValType (ControlHandle) == "N" 
      Return (Handle == ControlHandle)
   ENDIF
   
   
   IF ValType (Handle) == "A" .AND. ValType (ControlHandle) == "N"
      FOR i = 1 TO HMG_LEN (Handle)
          IF Handle [i] == ControlHandle
             Return .T.
          ENDIF
      NEXT
      Return .F.
   ENDIF
   
   
   IF ValType (Handle) == "N" .AND. ValType (ControlHandle) == "A"
      FOR i = 1 TO HMG_LEN (ControlHandle)
          IF Handle == ControlHandle [i]
             Return .T.
          ENDIF
      NEXT
      Return .F.
   ENDIF
   
   
   IF ValType (Handle) == "A" .AND. ValType (ControlHandle) == "A"
      FOR i = 1 TO HMG_LEN (Handle)
         FOR k = 1 TO HMG_LEN (ControlHandle)
             IF Handle [i] == ControlHandle [k]
                Return .T.
             ENDIF
         NEXT
      NEXT
      Return .F.
   ENDIF
   
Return .F.


