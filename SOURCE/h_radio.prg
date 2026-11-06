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

#define BM_GETCHECK     240   // ok
#define BST_UNCHECKED   0     // ok
#define BST_CHECKED     1     // ok
#define BM_SETCHECK     241   // ok

#include "hmg.ch"
#include "common.ch"
*-----------------------------------------------------------------------------*
Function _DefineRadioGroup ( ControlName, ParentForm, x, y, aOptions, Value, ;
                             fontname, fontsize, tooltip, change, width, ;
                             spacing, HelpId, invisible, notabstop , bold, italic, underline, strikeout , backcolor , fontcolor , transparent , aReadOnly , horizontal )
*-----------------------------------------------------------------------------*
Local i , cParentForm , mVar , BackRow , k
Local aHandles 	[ 0 ]
Local ControlHandle
Local FontHandle
Local cParentTabName := ''
Local cParentWindowName := ''
Local Z
Local BackCol

		// mSGiNFO ('Creating Radio ' + if ( horizontal ,'.T.' , '.F.' )  )


		DEFAULT Width     TO 120
		DEFAULT change    TO ""
		DEFAULT invisible TO FALSE
		DEFAULT notabstop TO FALSE

		if horizontal 
			Default Spacing To 125
		else
			Default Spacing To 25
		endif


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
		cParentWindowName := ParentForm
		ENDIF
	EndIf

	If .Not. _IsWindowDefined (ParentForm)
		MsgHMGError("Window: "+ ParentForm + " is not defined. Program terminated")
	Endif

	If _IsControlDefined (ControlName,ParentForm)
		MsgHMGError ("Control: " + ControlName + " Of " + ParentForm + " Already defined. Program Terminated")
	endif

	mVar := '_' + ParentForm + '_' + ControlName

	cParentForm := ParentForm

	ParentForm = GetFormHandle (ParentForm)

	BackRow := y
	BackCol := x

	if horizontal 

		ControlHandle := InitRadioGroup ( ParentForm, aOptions[1], 0, x, y , '' , 0 , Spacing, invisible, notabstop )

	else

		ControlHandle := InitRadioGroup ( ParentForm, aOptions[1], 0, x, y , '' , 0 , width, invisible, notabstop )

	endif

	if valtype(fontname) != "U" .and. valtype(fontsize) != "U"
		FontHandle := _SetFont (ControlHandle,FontName,FontSize,bold,italic,underline,strikeout)
	Else
		FontHandle := _SetFont (ControlHandle,_HMG_SYSDATA [ 342 ],_HMG_SYSDATA [ 343 ],bold,italic,underline,strikeout)
	endif

	if valtype(tooltip) != "U"
		SetToolTip ( ControlHandle , tooltip , GetFormToolTipHandle (cParentForm) )
	endif

	aAdd ( aHandles , ControlHandle )

	for i = 2 to HMG_LEN (aOptions)

		if horizontal 
			x = x + Spacing
		else
			y = y + Spacing
		endif

		if horizontal 

			ControlHandle := InitRadioButton ( ParentForm, aOptions[i], 0, x, y , '' , 0 , Spacing, invisible )

		else

			ControlHandle := InitRadioButton ( ParentForm, aOptions[i], 0, x, y , '' , 0 , width, invisible )

		endif

		if valtype(fontname) != "U" .and. valtype(fontsize) != "U"
			FontHandle := _SetFont (ControlHandle,FontName,FontSize,bold,italic,underline,strikeout)
		Else
			FontHandle := _SetFont (ControlHandle,_HMG_SYSDATA [ 342 ],_HMG_SYSDATA [ 343 ],bold,italic,underline,strikeout)
		endif

		if valtype(tooltip) != "U"
			SetToolTip ( ControlHandle , tooltip , GetFormToolTipHandle (cParentForm) )
		endif

		aAdd ( aHandles , ControlHandle )

	next i

	If _HMG_SYSDATA [ 265 ] = .T.
		aAdd ( _HMG_SYSDATA [ 142 ] , aHandles )
	EndIf

	k := _GetControlFree()

	Public &mVar. := k

	_HMG_SYSDATA [HMG_CTL_TYPE] [k] := "RADIOGROUP" 
	_HMG_SYSDATA [HMG_CTL_NAME]  [k] :=  ControlName 
	_HMG_SYSDATA [HMG_CTL_HANDLE]  [k] :=  aHandles 
	_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] :=   ParentForm 
	_HMG_SYSDATA [  HMG_CTL_ID ]  [k] :=  aReadOnly
	_HMG_SYSDATA [  HMG_CTL_PROCEDURE ]  [k] :=  "" 
	_HMG_SYSDATA [  HMG_CTL_PAGEMAP ]  [k] :=  {} 
	_HMG_SYSDATA [  HMG_CTL_VALUE ]  [k] :=  horizontal // (Nil)
	_HMG_SYSDATA [  HMG_CTL_INPUTMASK ]  [k] :=  transparent 
	_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_CHANGE ]  [k] :=  change 
	_HMG_SYSDATA [ HMG_CTL_DELETED ]  [k] :=  .F. 
	_HMG_SYSDATA [ HMG_CTL_BKCOLOR ]  [k] :=   backcolor 
	_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ]  [k] :=  fontcolor 
	_HMG_SYSDATA [ HMG_CTL_DBLCLICK ]  [k] :=  _HMG_SYSDATA [ 266 ] 
	_HMG_SYSDATA [ HMG_CTL_HEADCLICK ]  [k] :=  {} 
	_HMG_SYSDATA [ HMG_CTL_ROW ]  [k] :=  BackRow 
	_HMG_SYSDATA [ HMG_CTL_COL ]  [k] :=  BackCol
	_HMG_SYSDATA [ HMG_CTL_WIDTH ]  [k] :=  if ( horizontal , Spacing * HMG_LEN (aOptions) , Width )
	_HMG_SYSDATA [ HMG_CTL_HEIGHT ]  [k] :=  if ( horizontal , 28 , Spacing * HMG_LEN (aOptions) )
	_HMG_SYSDATA [ HMG_CTL_SPACING ]  [k] :=  Spacing 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ]  [k] :=  iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ]  [k] :=  iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_PICTURE ]  [k] :=  .Not. NoTabStop
	_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ]  [k] :=  0 
	_HMG_SYSDATA [ HMG_CTL_FONTNAME ]  [k] :=  fontname 
	_HMG_SYSDATA [ HMG_CTL_FONTSIZE ]  [k] :=  fontsize 
	_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ]  [k] :=  {bold,italic,underline,strikeout} 
	_HMG_SYSDATA [ HMG_CTL_TOOLTIP ]  [k] :=   tooltip  
	_HMG_SYSDATA [ HMG_CTL_RANGEMIN ]  [k] :=  cParentTabName
	_HMG_SYSDATA [ HMG_CTL_RANGEMAX ]  [k] :=  cParentWindowName
	_HMG_SYSDATA [ HMG_CTL_CAPTION ]  [k] :=   aOptions  
	_HMG_SYSDATA [ HMG_CTL_VISIBLE ]  [k] :=   if(invisible,FALSE,TRUE) 
	_HMG_SYSDATA [ HMG_CTL_HELPID ]  [k] :=   HelpId 
	_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ]  [k] :=   FontHandle 
	_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ]  [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_ENABLED ]  [k] :=   .T. 
	_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := 0
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

	if valtype (Value) <> 'U'
		SendMessage( aHandles [value] , BM_SETCHECK  , BST_CHECKED , 0 )
		if notabstop .and. IsTabStop(aHandles [value])
			SetTabStop(aHandles [value],.f.)
		endif
	EndIf

	IF VALTYPE ( aReadOnly ) = 'A'

		IF HMG_LEN ( aReadOnly ) == HMG_LEN ( aOptions )

			FOR Z := 1 TO HMG_LEN ( aReadOnly )

				IF VALTYPE ( aReadOnly [Z] ) == 'L'

					IF aReadOnly [Z] == .T.
					
			                        DisableWindow ( aHandles [Z] )

					ELSE

			                        EnableWindow ( aHandles [Z] )
						

					ENDIF

				ENDIF

			NEXT Z

		ENDIF

	ENDIF

Return Nil

Procedure _SetRadioGroupReadOnly ( ControlName , ParentForm , aReadOnly )

Local Z , I , aHandles , aOptions , lError

	lError := .F.

	I := GetControlIndex ( ControlName , ParentForm )

	aHandles := _HMG_SYSDATA [HMG_CTL_HANDLE] [I]

	aOptions := _HMG_SYSDATA [ HMG_CTL_CAPTION ] [I]

	IF VALTYPE ( aReadOnly ) = 'A'

		IF HMG_LEN ( aReadOnly ) == HMG_LEN ( aOptions )

			FOR Z := 1 TO HMG_LEN ( aReadOnly )

				IF VALTYPE ( aReadOnly [Z] ) == 'L'

					IF aReadOnly [Z] == .T.
					
			                        DisableWindow ( aHandles [Z] )

					ELSE

			                        EnableWindow ( aHandles [Z] )
						

					ENDIF

				ELSE

					lError := .T.
					EXIT

				ENDIF

			NEXT Z

		ELSE

			lError := .T.

		ENDIF

	ELSE

		lError := .T.

	ENDIF

	If .Not. lError

		_HMG_SYSDATA [ HMG_CTL_ID ] [I] := aReadOnly

	EndIf

Return

Function _GetRadioGroupReadOnly ( ControlName , ParentForm )

Local RetVal , I

	I := GetControlIndex ( ControlName , ParentForm )

	RetVal := _HMG_SYSDATA [ HMG_CTL_ID ] [I]

Return RetVal
