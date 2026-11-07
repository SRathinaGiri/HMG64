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
#include "common.ch"
*-----------------------------------------------------------------------------*
Function _DefineEditbox ( ControlName, ParentForm, x, y, w, h, value, ;
                          fontname, fontsize, tooltip, MaxLength, gotfocus, ;
                          change, lostfocus, readonly, break, HelpId, ;
                          invisible, notabstop , bold, italic, underline, strikeout , field , backcolor , fontcolor , novscroll , nohscroll , DISABLEDBACKCOLOR , DISABLEDFORECOLOR , nRounded  )
*-----------------------------------------------------------------------------*
Local i  , cParentForm , mVar , ContainerHandle := 0 , k
Local ControlHandle
Local FontHandle
Local WorkArea
Local cParentTabName

   DEFAULT w         TO 120
   DEFAULT h         TO 240
   DEFAULT value     TO ""
   DEFAULT change    TO ""
   DEFAULT lostfocus TO ""
   DEFAULT gotfocus  TO ""
   DEFAULT MaxLength TO 0  //64000
   DEFAULT invisible TO FALSE
   DEFAULT notabstop TO FALSE

	If ValType ( Field ) != 'U'
		if  HB_UAT ( '>', Field ) == 0 
			MsgHMGError ("Control: " + ControlName + " Of " + ParentForm + " : You must specify a fully qualified field name. Program Terminated" )
		Else
			WorkArea := HB_ULEFT ( Field , HB_UAT ( '>', Field ) - 2 )
			If Select (WorkArea) != 0
				Value := &(Field)
			EndIf
		EndIf
	EndIf

	if _HMG_SYSDATA [ 264 ] = .T.
		ParentForm := _HMG_SYSDATA [ 223 ]
		if .Not. Empty (_HMG_SYSDATA [ 224 ]) .And. ValType(FontName) == "U"
			FontName := _HMG_SYSDATA [ 224 ]
		EndIf
		if .Not. Empty (_HMG_SYSDATA [ 182 ]) .And. ValType(FontSize) == "U"
			FontSize := _HMG_SYSDATA [ 182 ]
		EndIf
	endif
	if _HMG_SYSDATA [ 183 ] > 0
		IF _HMG_SYSDATA [ 240 ] == .F.
		x 	:= x + _HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]]
		y 	:= y + _HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]]
		ParentForm := _HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]]
		cParentTabName := _HMG_SYSDATA [ 225 ] 
		ENDIF
	EndIf

	If .Not. _IsWindowDefined (ParentForm)
		MsgHMGError("Window: "+ ParentForm + " is not defined. Program terminated" )
	Endif

	If _IsControlDefined (ControlName,ParentForm)
		MsgHMGError ("Control: " + ControlName + " Of " + ParentForm + " Already defined. Program Terminated" )
	endif

	mVar := '_' + ParentForm + '_' + ControlName

	cParentForm := ParentForm

	ParentForm = GetFormHandle (ParentForm)

	if valtype(x) == "U" .or. valtype(y) == "U"

		If _HMG_SYSDATA [ 216 ] == 'TOOLBAR'
			Break := .T.
		EndIf

		_HMG_SYSDATA [ 216 ]	:= 'EDIT'

		i := GetFormIndex ( cParentForm )

		if i > 0

			ControlHandle := InitEditBox ( ParentForm , 0, x, y, w, h, '', 0 , MaxLength , readonly, invisible, notabstop , novscroll , nohscroll )
			if valtype(fontname) != "U" .and. valtype(fontsize) != "U"
				FontHandle := _SetFont (ControlHandle,FontName,FontSize,bold,italic,underline,strikeout)
			Else
				FontHandle := _SetFont (ControlHandle,_HMG_SYSDATA [ 342 ],_HMG_SYSDATA [ 343 ],bold,italic,underline,strikeout)
			endif

			AddSplitBoxItem ( Controlhandle , _HMG_SYSDATA [ HMG_FRM_REBARHANDLE ] [i] , w , break , , , , _HMG_SYSDATA [ 258 ] )
			Containerhandle := _HMG_SYSDATA [ HMG_FRM_REBARHANDLE ] [i]

			If Valtype (Value) == 'C' ;
				.or.;
				Valtype (Value) == 'M'

				If .Not. Empty (Value)
					SetWindowText ( ControlHandle , value )
				EndIf

			EndIf

		EndIf

	Else

		ControlHandle := InitEditBox ( ParentForm, 0, x, y, w, h, '', 0 , MaxLength , readonly, invisible, notabstop , novscroll , nohscroll )
		if valtype(fontname) != "U" .and. valtype(fontsize) != "U"
			FontHandle := _SetFont (ControlHandle,FontName,FontSize,bold,italic,underline,strikeout)
		Else
			FontHandle := _SetFont (ControlHandle,_HMG_SYSDATA [ 342 ],_HMG_SYSDATA [ 343 ],bold,italic,underline,strikeout)
		endif

		If Valtype (Value) == 'C' ;
			.or.;
			Valtype (Value) == 'M'

			If .Not. Empty (Value)
				SetWindowText ( ControlHandle , value )
			EndIf

		EndIf

	endif

	If _HMG_SYSDATA [ 265 ] = .T.
		aAdd ( _HMG_SYSDATA [ 142 ] , Controlhandle )
	EndIf

	if valtype(tooltip) != "U"
		SetToolTip ( ControlHandle , tooltip , GetFormToolTipHandle (cParentForm) )
	endif

	k := _GetControlFree()

	_HMG_VarSet ( mVar , k )

	_HMG_SYSDATA [HMG_CTL_TYPE] [k] := "EDIT" 
	_HMG_SYSDATA [HMG_CTL_NAME]  [k] :=  ControlName 
	_HMG_SYSDATA [HMG_CTL_HANDLE]  [k] :=  ControlHandle 
	_HMG_SYSDATA [HMG_CTL_PARENTHANDLE]  [k] :=  ParentForm 
	_HMG_SYSDATA [  HMG_CTL_ID ]  [k] :=  0 
	_HMG_SYSDATA [  HMG_CTL_PROCEDURE ]  [k] :=  "" 
	_HMG_SYSDATA [  HMG_CTL_PAGEMAP ]  [k] :=  Field 
	_HMG_SYSDATA [  HMG_CTL_VALUE ]  [k] :=  Nil 
	_HMG_SYSDATA [  HMG_CTL_INPUTMASK ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ]  [k] :=  lostfocus 
	_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ] [k] :=   gotfocus 
	_HMG_SYSDATA [ HMG_CTL_CHANGE ]  [k] :=  change 
	_HMG_SYSDATA [ HMG_CTL_DELETED ]  [k] :=  .F. 
	_HMG_SYSDATA [ HMG_CTL_BKCOLOR ]  [k] :=  backcolor 
	_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ]  [k] :=  fontcolor 
	_HMG_SYSDATA [ HMG_CTL_DBLCLICK ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_HEADCLICK ]  [k] :=  {} 
	_HMG_SYSDATA [ HMG_CTL_ROW ]  [k] :=  y 
	_HMG_SYSDATA [ HMG_CTL_COL ]   [k] := x 
	_HMG_SYSDATA [ HMG_CTL_WIDTH ]   [k] := w 
	_HMG_SYSDATA [ HMG_CTL_HEIGHT ]   [k] := h 
	_HMG_SYSDATA [ HMG_CTL_SPACING ]   [k] := 0 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ]  [k] :=  iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ]  [k] :=  iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_PICTURE ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ]  [k] :=  ContainerHandle 
	_HMG_SYSDATA [ HMG_CTL_FONTNAME ]  [k] :=  fontname 
	_HMG_SYSDATA [ HMG_CTL_FONTSIZE ]  [k] :=  fontsize 
	_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ]  [k] :=  {bold,italic,underline,strikeout} 
	_HMG_SYSDATA [ HMG_CTL_TOOLTIP ]   [k] :=  tooltip  
	_HMG_SYSDATA [ HMG_CTL_RANGEMIN ]  [k] :=   cParentTabName
	_HMG_SYSDATA [ HMG_CTL_RANGEMAX ]  [k] :=   0  
	_HMG_SYSDATA [ HMG_CTL_CAPTION ]  [k] :=   ''  
	_HMG_SYSDATA [ HMG_CTL_VISIBLE ]  [k] :=   if(invisible,FALSE,TRUE) 
	_HMG_SYSDATA [ HMG_CTL_HELPID ]   [k] :=  HelpId 
	_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ]  [k] :=   FontHandle 
	_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ]  [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_ENABLED ]  [k] :=   .T. 
	_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := 0
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] [  9 ] := DISABLEDBACKCOLOR
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] [ 10 ] := DISABLEDFORECOLOR
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] [ 11 ] := readonly

	// ROUNDED <n> (from HMG 3.7): opt-in rounded border, see c_rounded.c
	if valtype( nRounded ) == "N"
		_SetTextBoxRounded ( ControlHandle , nRounded )
	endif
		
	if valtype ( Field ) != 'U'
		aAdd ( _HMG_SYSDATA [ HMG_FRM_BROWSELIST ]	[ GetFormIndex ( cParentForm ) ] , k )
	EndIf

Return Nil

Procedure _DataEditBoxRefresh (i)
Local Field

	Field		:= _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [i]
	_SetValue ( '' , '' , &Field , i ) 

Return

Procedure _DataEditBoxSave ( ControlName , ParentForm)
Local Field , i 

	i := GetControlIndex ( ControlName , ParentForm)	

	Field := _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [i]

	REPLACE &Field WITH _GetValue ( Controlname , ParentForm ) 

Return

