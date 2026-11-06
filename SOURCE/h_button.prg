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


#define BUTTON_IMAGELIST_ALIGN_LEFT   0
#define BUTTON_IMAGELIST_ALIGN_RIGHT  1
#define BUTTON_IMAGELIST_ALIGN_TOP    2
#define BUTTON_IMAGELIST_ALIGN_BOTTOM 3
#define BUTTON_IMAGELIST_ALIGN_CENTER 4



*-----------------------------------------------------------------------------*
Function _DefineButton ( ControlName, ParentForm, x, y, Caption, ;
                         ProcedureName, w, h, fontname, fontsize, tooltip, ;
                         gotfocus, lostfocus, flat, NoTabStop, HelpId, ;
                         invisible , bold, italic, underline, strikeout , multiline )
*-----------------------------------------------------------------------------*
Local cParentForm , mVar , ControlHandle , FontHandle , k , cParentTabName

   DEFAULT w         TO 100
   DEFAULT h         TO 28
   DEFAULT lostfocus TO ""
   DEFAULT gotfocus  TO ""
   DEFAULT invisible TO FALSE

	if _HMG_SYSDATA [ 264 ] = TRUE
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
	Endif

	mVar := '_' + ParentForm + '_' + ControlName

	cParentForm := ParentForm

	ParentForm = GetFormHandle (ParentForm)

	ControlHandle := InitButton ( ParentForm, Caption, 0, x, y ,w ,h,'',0 , flat , NoTabStop, invisible , multiline )

	if valtype(fontname) != "U" .and. valtype(fontsize) != "U"
		FontHandle := _SetFont (ControlHandle,FontName,FontSize,bold,italic,underline,strikeout)
	Else
		FontHandle := _SetFont (ControlHandle,_HMG_SYSDATA [ 342 ],_HMG_SYSDATA [ 343 ],bold,italic,underline,strikeout)
	Endif

	If _HMG_SYSDATA [ 265 ] = TRUE
		aAdd ( _HMG_SYSDATA [ 142 ] , Controlhandle )
	EndIf

	if valtype(tooltip) != "U"
		SetToolTip ( ControlHandle , tooltip , GetFormToolTipHandle (cParentForm) )
	endif

	k := _GetControlFree()

	Public &mVar. := k

	_HMG_SYSDATA [HMG_CTL_TYPE] [k] := "BUTTON" 
	_HMG_SYSDATA [HMG_CTL_NAME] [k] := ControlName 
	_HMG_SYSDATA [HMG_CTL_HANDLE] [k] := ControlHandle 
	_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] := ParentForm 
	_HMG_SYSDATA [  HMG_CTL_ID ] [k] := 0 
	_HMG_SYSDATA [  HMG_CTL_PROCEDURE ] [k] := ProcedureName 
	_HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [k] := {} 
	_HMG_SYSDATA [  HMG_CTL_VALUE ] [k] := Nil 
	_HMG_SYSDATA [  HMG_CTL_INPUTMASK ] [k] := "" 
	_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ] [k] := lostfocus 
	_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ] [k] := gotfocus 
	_HMG_SYSDATA [ HMG_CTL_CHANGE ] [k] := "" 
	_HMG_SYSDATA [ HMG_CTL_DELETED ] [k] := FALSE 
	_HMG_SYSDATA [ HMG_CTL_BKCOLOR ] [k] := Nil 
	_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ] [k] := Nil 
	_HMG_SYSDATA [ HMG_CTL_DBLCLICK ] [k] := "" 
	_HMG_SYSDATA [ HMG_CTL_HEADCLICK ] [k] := {} 
	_HMG_SYSDATA [ HMG_CTL_ROW ] [k] := y 
	_HMG_SYSDATA [ HMG_CTL_COL ] [k] := x 
	_HMG_SYSDATA [ HMG_CTL_WIDTH ] [k] := w 
	_HMG_SYSDATA [ HMG_CTL_HEIGHT ] [k] := h 
	_HMG_SYSDATA [ HMG_CTL_SPACING ] [k] := 'T'
	_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ] [k] := iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ] [k] := iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_PICTURE ] [k] := "" 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ] [k] := 0 
	_HMG_SYSDATA [ HMG_CTL_FONTNAME ] [k] := fontname 
	_HMG_SYSDATA [ HMG_CTL_FONTSIZE ] [k] := fontsize 
	_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ] [k] := {bold,italic,underline,strikeout} 
	_HMG_SYSDATA [ HMG_CTL_TOOLTIP ] [k] := tooltip  
	_HMG_SYSDATA [ HMG_CTL_RANGEMIN ] [k] := cParentTabName  
	_HMG_SYSDATA [ HMG_CTL_RANGEMAX ] [k] := 0  
	_HMG_SYSDATA [ HMG_CTL_CAPTION ] [k] := Caption  
	_HMG_SYSDATA [ HMG_CTL_VISIBLE ] [k] := if(invisible,FALSE,TRUE) 
	_HMG_SYSDATA [ HMG_CTL_HELPID ] [k] := HelpId 
	_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ] [k] := FontHandle 
	_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ] [k] := 0 
	_HMG_SYSDATA [ HMG_CTL_ENABLED ] [k] := .T. 
	_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := 0
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

Return Nil


*-----------------------------------------------------------------------------*
Function _DefineImageButton ( ControlName, ParentForm, x, y, Caption, ;
                              ProcedureName, w, h, image, tooltip, gotfocus, ;
                              lostfocus, flat, notrans, HelpId, invisible, ;
                              notabstop )
*-----------------------------------------------------------------------------*
Local cParentForm , mVar , ControlHandle , k
Local nhImage 
Local aRet
Local cParentTabName

	DEFAULT invisible TO FALSE
	DEFAULT notabstop TO FALSE

	if _HMG_SYSDATA [ 264 ] = TRUE
		ParentForm := _HMG_SYSDATA [ 223 ]
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
		MsgHMGError ("Control: " + ControlName + " Of " + ParentForm + " Already defined. Program terminated" )
	endif

	mVar := '_' + ParentForm + '_' + ControlName

	cParentForm := ParentForm

	ParentForm = GetFormHandle (ParentForm)

   if ( IsAppThemed() )
      aRet := InitImageButton ( ParentForm, Caption, 0, x, y, w, h, image , flat , notrans, invisible, notabstop , .T. )
   else
      aRet := InitImageButton ( ParentForm, Caption, 0, x, y, w, h, image , flat , notrans, invisible, notabstop , .F. )
   endif

	ControlHandle := aRet [1]
	nhImage := aRet [2]

	If _HMG_SYSDATA [ 265 ] = TRUE
		aAdd ( _HMG_SYSDATA [ 142 ] , Controlhandle )
	EndIf

	if valtype(tooltip) != "U"
		SetToolTip ( ControlHandle , tooltip , GetFormToolTipHandle (cParentForm) )
	endif

	k := _GetControlFree()

	Public &mVar. := k

	_HMG_SYSDATA [HMG_CTL_TYPE] [k] := "BUTTON" 
	_HMG_SYSDATA [HMG_CTL_NAME] [k] :=   ControlName 
	_HMG_SYSDATA [HMG_CTL_HANDLE] [k] :=   ControlHandle 
	_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] :=   ParentForm 
	_HMG_SYSDATA [  HMG_CTL_ID ] [k] :=   0 
	_HMG_SYSDATA [  HMG_CTL_PROCEDURE ] [k] :=   ProcedureName 
	_HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [k] :=   {} 
	_HMG_SYSDATA [  HMG_CTL_VALUE ] [k] :=   Nil 
	_HMG_SYSDATA [  HMG_CTL_INPUTMASK ] [k] :=   "" 
	_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ] [k] :=   lostfocus 
	_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ] [k] :=   gotfocus 
	_HMG_SYSDATA [ HMG_CTL_CHANGE ] [k] :=   "" 
	_HMG_SYSDATA [ HMG_CTL_DELETED ] [k] :=   FALSE 
	_HMG_SYSDATA [ HMG_CTL_BKCOLOR ] [k] :=   NIL
	_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ] [k] :=   Nil 
	_HMG_SYSDATA [ HMG_CTL_DBLCLICK ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_HEADCLICK ] [k] :=   {} 
	_HMG_SYSDATA [ HMG_CTL_ROW ] [k] :=   y 
	_HMG_SYSDATA [ HMG_CTL_COL ] [k] :=   x 
	_HMG_SYSDATA [ HMG_CTL_WIDTH ] [k] :=   w 
	_HMG_SYSDATA [ HMG_CTL_HEIGHT ] [k] :=   h 
	_HMG_SYSDATA [ HMG_CTL_SPACING ] [k] :=   'I'
	_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ] [k] :=   iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ] [k] :=   iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_PICTURE ] [k] :=   image 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ] [k] :=   BUTTON_IMAGELIST_ALIGN_CENTER
	_HMG_SYSDATA [ HMG_CTL_FONTNAME ] [k] :=   '' 
	_HMG_SYSDATA [ HMG_CTL_FONTSIZE ] [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ] [k] :=   {.f.,.f.,.f.,.f.} 
	_HMG_SYSDATA [ HMG_CTL_TOOLTIP ] [k] :=    tooltip  
	_HMG_SYSDATA [ HMG_CTL_RANGEMIN ] [k] :=  cParentTabName  
	_HMG_SYSDATA [ HMG_CTL_RANGEMAX ] [k] :=  notrans // ADD  
	_HMG_SYSDATA [ HMG_CTL_CAPTION ] [k] :=    Caption  
	_HMG_SYSDATA [ HMG_CTL_VISIBLE ] [k] :=    if(invisible,FALSE,TRUE) 
	_HMG_SYSDATA [ HMG_CTL_HELPID ] [k] :=    HelpId 
	_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ] [k] :=    0 
	_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ] [k] := nhImage
	_HMG_SYSDATA [ HMG_CTL_ENABLED ] [k] :=    .T. 
	_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := 0
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

Return Nil


*-----------------------------------------------------------------------------*
Function _DefineMixedButton ( ControlName, ParentForm, x, y, Caption, ;
			ProcedureName, w, h, fontname, fontsize, tooltip, ;
			gotfocus, lostfocus, flat, NoTabStop, HelpId, ;
			invisible , bold, italic, underline, strikeout , ;
			picture , alignment , multiline, notrans )
*-----------------------------------------------------------------------------*
Local cParentForm , mVar , ControlHandle , FontHandle , k , cParentTabName
Local aRet
Local aWinver := WindowsVersion()

	if	aWinver [1] = 'Windows 95' ;
		.Or. ;
		aWinver [1] = 'Windows 98' ;
		.Or. ;
		aWinver [1] = 'Windows Me' ;
		.Or. ;
		aWinver [1] = 'Windows NT' ;
		.Or. ;
		aWinver [1] = 'Windows 2000' ;
		.Or. ;
		aWinver [1] = 'Windows Server 2003 family'

		_DefineButton ( ControlName, ParentForm, x, y, Caption, ;
                         ProcedureName, w, h, fontname, fontsize, tooltip, ;
                         gotfocus, lostfocus, flat, NoTabStop, HelpId, ;
                         invisible , bold, italic, underline, strikeout , multiline )
		Return Nil

	endif

DEFAULT w         TO 100
DEFAULT h         TO 28
DEFAULT lostfocus TO ""
DEFAULT gotfocus  TO ""
DEFAULT invisible TO FALSE


	if valtype (alignment) = 'U'
		alignment := BUTTON_IMAGELIST_ALIGN_TOP
	elseif valtype (alignment) = 'C'
		if	ALLTRIM(HMG_UPPER(alignment)) == 'LEFT'
			alignment := BUTTON_IMAGELIST_ALIGN_LEFT
		elseif	ALLTRIM(HMG_UPPER(alignment)) == 'RIGHT'
			alignment := BUTTON_IMAGELIST_ALIGN_RIGHT
		elseif	ALLTRIM(HMG_UPPER(alignment)) == 'TOP'
			alignment := BUTTON_IMAGELIST_ALIGN_TOP
		elseif	ALLTRIM(HMG_UPPER(alignment)) == 'BOTTOM'
			alignment := BUTTON_IMAGELIST_ALIGN_BOTTOM
		else
			alignment := BUTTON_IMAGELIST_ALIGN_TOP
		endif
	else
		alignment := BUTTON_IMAGELIST_ALIGN_TOP
	endif

	if _HMG_SYSDATA [ 264 ] = TRUE
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
	Endif

	mVar := '_' + ParentForm + '_' + ControlName

	cParentForm := ParentForm

	ParentForm = GetFormHandle (ParentForm)

	aRet := InitMixedButton ( ParentForm, Caption, 0, x, y, w, h, '', 0, flat, NoTabStop, invisible, picture, alignment, multiline, notrans )

	ControlHandle := aRet [1]

	if valtype(fontname) != "U" .and. valtype(fontsize) != "U"
		FontHandle := _SetFont (ControlHandle,FontName,FontSize,bold,italic,underline,strikeout)
	Else
		FontHandle := _SetFont (ControlHandle,_HMG_SYSDATA [ 342 ],_HMG_SYSDATA [ 343 ],bold,italic,underline,strikeout)
	Endif

	If _HMG_SYSDATA [ 265 ] = TRUE
		aAdd ( _HMG_SYSDATA [ 142 ] , Controlhandle )
	EndIf

	if valtype(tooltip) != "U"
		SetToolTip ( ControlHandle , tooltip , GetFormToolTipHandle (cParentForm) )
	endif

	k := _GetControlFree()

	Public &mVar. := k

	_HMG_SYSDATA [HMG_CTL_TYPE] [k] := "BUTTON" 
	_HMG_SYSDATA [HMG_CTL_NAME] [k] := ControlName 
	_HMG_SYSDATA [HMG_CTL_HANDLE] [k] := ControlHandle 
	_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] := ParentForm 
	_HMG_SYSDATA [  HMG_CTL_ID ] [k] := 0 
	_HMG_SYSDATA [  HMG_CTL_PROCEDURE ] [k] := ProcedureName 
	_HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [k] := {} 
	_HMG_SYSDATA [  HMG_CTL_VALUE ] [k] := Nil 
	_HMG_SYSDATA [  HMG_CTL_INPUTMASK ] [k] := "" 
	_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ] [k] := lostfocus 
	_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ] [k] := gotfocus 
	_HMG_SYSDATA [ HMG_CTL_CHANGE ] [k] := "" 
	_HMG_SYSDATA [ HMG_CTL_DELETED ] [k] := FALSE 
	_HMG_SYSDATA [ HMG_CTL_BKCOLOR ] [k] := NIL
	_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ] [k] := Nil 
	_HMG_SYSDATA [ HMG_CTL_DBLCLICK ] [k] := "" 
	_HMG_SYSDATA [ HMG_CTL_HEADCLICK ] [k] := {} 
	_HMG_SYSDATA [ HMG_CTL_ROW ] [k] := y 
	_HMG_SYSDATA [ HMG_CTL_COL ] [k] := x 
	_HMG_SYSDATA [ HMG_CTL_WIDTH ] [k] := w 
	_HMG_SYSDATA [ HMG_CTL_HEIGHT ] [k] := h 
	_HMG_SYSDATA [ HMG_CTL_SPACING ] [k] := 'M'
	_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ] [k] := iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ] [k] := iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_PICTURE ] [k] := picture
	_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ] [k] := alignment
	_HMG_SYSDATA [ HMG_CTL_FONTNAME ] [k] := fontname 
	_HMG_SYSDATA [ HMG_CTL_FONTSIZE ] [k] := fontsize 
	_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ] [k] := {bold,italic,underline,strikeout} 
	_HMG_SYSDATA [ HMG_CTL_TOOLTIP ] [k] := tooltip  
	_HMG_SYSDATA [ HMG_CTL_RANGEMIN ] [k] := cParentTabName  
	_HMG_SYSDATA [ HMG_CTL_RANGEMAX ] [k] := notrans // ADD  
	_HMG_SYSDATA [ HMG_CTL_CAPTION ] [k] := Caption  
	_HMG_SYSDATA [ HMG_CTL_VISIBLE ] [k] := if(invisible,FALSE,TRUE) 
	_HMG_SYSDATA [ HMG_CTL_HELPID ] [k] := HelpId 
	_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ] [k] := FontHandle 
	_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ] [k] := aRet [2]
	_HMG_SYSDATA [ HMG_CTL_ENABLED ] [k] := .T. 
	_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := 0
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

Return Nil

