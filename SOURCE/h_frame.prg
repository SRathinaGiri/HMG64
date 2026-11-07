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
#include "hmg.ch"
*-----------------------------------------------------------------------------*
Function _DefineFrame ( ControlName, ParentForm, x, y, w, h , caption , fontname , fontsize , opaque , bold, italic, underline, strikeout , backcolor , fontcolor , transparent , nrounded )
*-----------------------------------------------------------------------------*
Local mVar , k
Local ControlHandle
Local FontHandle
Local cParentTabName := ''
Local cParentWindowName := ''


	If .Not. _IsWindowDefined (ParentForm)
		MsgHMGError("Window: "+ ParentForm + " is not defined. Program terminated")
	Endif

	If _IsControlDefined (ControlName,ParentForm)
		MsgHMGError ("Control: " + ControlName + " Of " + ParentForm + " Already defined. Program Terminated")
	endif

	mVar := '_' + ParentForm + '_' + ControlName


	ParentForm = GetFormHandle (ParentForm)

	Controlhandle := InitFrame ( ParentForm, 0, x, y, w, h , caption , '' , 0 , .F. )

	if valtype(fontname) != "U" .and. valtype(fontsize) != "U"
		FontHandle := _SetFont (ControlHandle,FontName,FontSize,bold,italic,underline,strikeout)
	Else
		FontHandle := _SetFont (ControlHandle,_HMG_SYSDATA [ 342 ],_HMG_SYSDATA [ 343 ],bold,italic,underline,strikeout)		
	endif

	// ROUNDED <n> (from HMG 3.7): opt-in. HMG5 keeps the native group box unless asked;
	// 3.7 rounds every FRAME by default. See c_rounded.c.
	if valtype(nrounded) == "N"
		_SetFrameRounded ( ControlHandle, nrounded )
	endif

	if _HMG_SYSDATA [ 183 ] > 0
		IF _HMG_SYSDATA [ 240 ] == .F.
		cParentTabName := _HMG_SYSDATA [ 225 ] 
		cParentWindowName := _HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]]
		ENDIF
	endif

	If _HMG_SYSDATA [ 265 ] = .T.
		aAdd ( _HMG_SYSDATA [ 142 ] , Controlhandle )
	EndIf

	k := _GetControlFree()

	Public &mVar. := k

	_HMG_SYSDATA [HMG_CTL_TYPE] [k] := "FRAME" 
	_HMG_SYSDATA [HMG_CTL_NAME]  [k] :=  ControlName 
	_HMG_SYSDATA [HMG_CTL_HANDLE]  [k] :=  ControlHandle 
	_HMG_SYSDATA [HMG_CTL_PARENTHANDLE]  [k] :=  ParentForm 
	_HMG_SYSDATA [  HMG_CTL_ID ]  [k] :=  0 
	_HMG_SYSDATA [  HMG_CTL_PROCEDURE ]  [k] :=  "" 
	_HMG_SYSDATA [  HMG_CTL_PAGEMAP ]  [k] :=  {} 
	_HMG_SYSDATA [  HMG_CTL_VALUE ]  [k] :=  Nil 
	_HMG_SYSDATA [  HMG_CTL_INPUTMASK ]  [k] :=  transparent 
	_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_CHANGE ]  [k] :=  ""
	_HMG_SYSDATA [ HMG_CTL_DELETED ]  [k] :=  .F. 
	_HMG_SYSDATA [ HMG_CTL_BKCOLOR ]  [k] :=  backcolor 
	_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ]  [k] :=  fontcolor 
	_HMG_SYSDATA [ HMG_CTL_DBLCLICK ]  [k] :=  _HMG_SYSDATA [ 266 ] 
	_HMG_SYSDATA [ HMG_CTL_HEADCLICK ]  [k] :=  {} 
	_HMG_SYSDATA [ HMG_CTL_ROW ]  [k] :=  y 
	_HMG_SYSDATA [ HMG_CTL_COL ]  [k] :=  x 
	_HMG_SYSDATA [ HMG_CTL_WIDTH ]  [k] :=  w 
	_HMG_SYSDATA [ HMG_CTL_HEIGHT ]   [k] := h 
	_HMG_SYSDATA [ HMG_CTL_SPACING ]   [k] := 0 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ]  [k] :=  iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]] , -1 )  
	_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ]  [k] :=  iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_PICTURE ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ]  [k] :=  0 
	_HMG_SYSDATA [ HMG_CTL_FONTNAME ]  [k] :=  fontname 
	_HMG_SYSDATA [ HMG_CTL_FONTSIZE ]  [k] :=  fontsize 
	_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ]  [k] :=  {bold,italic,underline,strikeout} 
	_HMG_SYSDATA [ HMG_CTL_TOOLTIP ]   [k] :=  ''  
	_HMG_SYSDATA [ HMG_CTL_RANGEMIN ]  [k] :=  cParentTabName
	_HMG_SYSDATA [ HMG_CTL_RANGEMAX ]  [k] :=  cParentWindowName
	_HMG_SYSDATA [ HMG_CTL_CAPTION ]  [k] :=   Caption  
	_HMG_SYSDATA [ HMG_CTL_VISIBLE ]  [k] :=   .t. 
	_HMG_SYSDATA [ HMG_CTL_HELPID ]   [k] :=  0 
	_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ]  [k] :=   FontHandle 
	_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ]  [k] :=  Opaque
	_HMG_SYSDATA [ HMG_CTL_ENABLED ]  [k] :=   .T. 
	_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := 0
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

Return Controlhandle

Function _BeginFrame( name , parent , row , col , w , h , caption , fontname , fontsize , opaque , bold, italic, underline, strikeout , backcolor , fontcolor , transparent , nrounded ) 

	if _HMG_SYSDATA [ 264 ] = .T.
		if .Not. Empty (_HMG_SYSDATA [ 224 ]) .And. ValType(FontName) == "U"
			FontName := _HMG_SYSDATA [ 224 ]
		EndIf
		if .Not. Empty (_HMG_SYSDATA [ 182 ]) .And. ValType(FontSize) == "U"
			FontSize := _HMG_SYSDATA [ 182 ]
		EndIf
	endif

	if _HMG_SYSDATA [ 183 ] > 0
		IF _HMG_SYSDATA [ 240 ] == .F.
		col 	:= col + _HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]]
		row 	:= row + _HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]] 
		Parent	:= _HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]]
		ENDIF
	EndIf

	if valtype (parent) == 'U'
		parent := _HMG_SYSDATA [ 223 ]
	EndIf

	if valtype (caption) == 'U'
		caption := ""
		fontname := "Arial"
		fontsize := 1
	EndIf

	if valtype (w) == 'U'
		w := 140
	EndIf

	if valtype (h) == 'U'
		h := 140
	EndIf

	_DefineFrame ( name , parent , col , row , w , h , caption , fontname , fontsize , opaque , bold, italic, underline, strikeout , backcolor , fontcolor , transparent , nrounded )

Return Nil

