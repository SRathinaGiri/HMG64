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
//#include "hfcl.ch"
#include "common.ch"

*-----------------------------------------------------------------------------*
Function _DefineImage ( ControlName, ParentForm, x, y, FileName, w, h, ProcedureName, HelpId, invisible, stretch, transparent, aBKColor, adjustimage, aTranspColor, cToolTip )
*-----------------------------------------------------------------------------*
Local cParentForm , mVar , k, lActionTooltip
Local ControlHandle, BackgroundColor, TransparentColor

	if _HMG_SYSDATA [ 264 ] = .T.
		ParentForm := _HMG_SYSDATA [ 223 ]
	endif
	if _HMG_SYSDATA [ 183 ] > 0
		IF _HMG_SYSDATA [ 240 ] == .F.
		x 	:= x + _HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]]
		y 	:= y + _HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]]
		ParentForm := _HMG_SYSDATA [ 332 ] [_HMG_SYSDATA [ 183 ]]
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

   
   IF ValType(w) == "U" .OR. w == 0
      w := -1 
   ENDIF

   IF ValType(h) == "U" .OR. h == 0
      h := -1 
   ENDIF

   IF ValType (aBKColor) <> "A"
      BackgroundColor := -1
   ELSE
      BackgroundColor := RGB (aBKColor[1], aBKColor[2], aBKColor[3])
   ENDIF

   IF ValType (aTranspColor) <> "A"
      TransparentColor := -1
   ELSE
      TransparentColor := RGB (aTranspColor[1], aTranspColor[2], aTranspColor[3])
   ENDIF

   IF ValType (ProcedureName) <> "U" .OR. ValType (cToolTip) <> "U"
      lActionTooltip := .T.
   ELSE
      lActionTooltip := .F.
   ENDIF

	if valtype(ProcedureName) == "U"
		ProcedureName := ""
	endif

   ControlHandle := InitImage ( ParentForm, x, y, invisible, lActionTooltip )
  
	If _HMG_SYSDATA [ 265 ] = .T.
		aAdd ( _HMG_SYSDATA [ 142 ] , ControlHandle )
	EndIf


   if ValType( cToolTip ) != "U"
      SetToolTip ( ControlHandle , cToolTip , GetFormToolTipHandle (cParentForm) )
   endif

	k := _GetControlFree()

	_HMG_VarSet ( mVar , k )

	_HMG_SYSDATA [  HMG_CTL_TYPE ]  [k] :=   "IMAGE" 
	_HMG_SYSDATA [  HMG_CTL_NAME ]  [k] :=   ControlName 
	_HMG_SYSDATA [  HMG_CTL_HANDLE ]  [k] :=   ControlHandle 
	_HMG_SYSDATA [  HMG_CTL_PARENTHANDLE ]  [k] :=   ParentForm 
	_HMG_SYSDATA [  HMG_CTL_ID ]  [k] :=   0 
	_HMG_SYSDATA [  HMG_CTL_PROCEDURE ]  [k] :=   ProcedureName 
	_HMG_SYSDATA [  HMG_CTL_PAGEMAP ]  [k] :=   {} 
	_HMG_SYSDATA [  HMG_CTL_VALUE ]  [k] :=   if ( stretch == .t. , 1 , 0 ) 
	_HMG_SYSDATA [  HMG_CTL_INPUTMASK ]  [k] :=   "" 
	_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ]  [k] :=   "" 
	_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ]  [k] :=   "" 
	_HMG_SYSDATA [ HMG_CTL_CHANGE ]  [k] :=   "" 
	_HMG_SYSDATA [ HMG_CTL_DELETED ]  [k] :=   .F.   // Is Deleted 
	_HMG_SYSDATA [ HMG_CTL_BKCOLOR ]  [k] :=   Nil 
	_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ]  [k] :=   Nil 
	_HMG_SYSDATA [ HMG_CTL_DBLCLICK ]  [k] :=   "" 
	_HMG_SYSDATA [ HMG_CTL_HEADCLICK ]  [k] :=   {} 
	_HMG_SYSDATA [ HMG_CTL_ROW ]  [k] :=   y 
	_HMG_SYSDATA [ HMG_CTL_COL ]  [k] :=   x 
	_HMG_SYSDATA [ HMG_CTL_WIDTH ]  [k] :=   w 
	_HMG_SYSDATA [ HMG_CTL_HEIGHT ]  [k] :=   h 
	_HMG_SYSDATA [ HMG_CTL_SPACING ]  [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ]  [k] :=   if ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ]  [k] :=   if ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_PICTURE ]  [k] :=   FileName 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ]  [k] :=   BackgroundColor 
	_HMG_SYSDATA [ HMG_CTL_FONTNAME ]  [k] :=   '' 
	_HMG_SYSDATA [ HMG_CTL_FONTSIZE ]  [k] :=   TransparentColor
	_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ]  [k] :=   {.f.,.f.,.f.,.f.} 
	_HMG_SYSDATA [ HMG_CTL_TOOLTIP ]  [k] :=   cToolTip
	_HMG_SYSDATA [ HMG_CTL_RANGEMIN ]  [k] :=   w   // original Width
	_HMG_SYSDATA [ HMG_CTL_RANGEMAX ]  [k] :=   h   // original Height
	_HMG_SYSDATA [ HMG_CTL_CAPTION ]  [k] :=   ''  
	_HMG_SYSDATA [ HMG_CTL_VISIBLE ]  [k] :=   if( invisible, .f., .t.) 
	_HMG_SYSDATA [ HMG_CTL_HELPID ]  [k] :=   HelpId 
	_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ]  [k] :=   if ( adjustimage == .t. , 1 , 0)
	_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ]  [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_ENABLED ]  [k] :=   .T. 
	_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ]  [k] :=   if ( transparent == .t. , 1 , 0 )
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ]  [k] :=   { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

   // Dr. Claudio Soto (May 2013)
   _HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ]  [k] :=   C_SetPicture    ( ControlHandle , FileName , w , h , if ( stretch == .t. , 1 , 0 ) , if ( transparent == .t. , 1 , 0 ), BackgroundColor, if ( adjustimage == .t. , 1 , 0), TransparentColor)
   _HMG_SYSDATA [ HMG_CTL_WIDTH ]  [k] :=   GetWindowWidth  ( ControlHandle )
   _HMG_SYSDATA [ HMG_CTL_HEIGHT ]  [k] :=   GetWindowHeight ( ControlHandle )

Return Nil




// by Dr. Claudio Soto (August 2013)

// HMG_GetImageInfo ( [ cFileName | hBitmap ], @nWidth, @nHeight, @aBackColor, [ nRowColor ], [ nColColor ] ) --> Return lBoolean

*-------------------------------------------------------------------------------------------*
FUNCTION HMG_GetImageInfo ( xFile, nWidth, nHeight, aBackColor, nRowColor, nColColor )
*-------------------------------------------------------------------------------------------*
LOCAL hBitmap, cFileName, hDC, BTstruct
   
   DEFAULT nRowColor TO 0
   DEFAULT nColColor TO 0
   
   IF HB_ISNUMERIC (xFile)
      hBitmap := xFile
   ELSE
      cFileName := xFile
      hBitmap  := BT_BitmapLoadFile (cFileName)
   ENDIF
   
   IF hBitmap == 0
      RETURN .F.
   ENDIF
   
   nWidth   := BT_BitmapWidth  (hBitmap)  
   nHeight  := BT_BitmapHeight (hBitmap)
   
   hDC := BT_CreateDC (hBitmap, BT_HDC_BITMAP, @BTstruct)     
       aBackColor := BT_DrawGetPixel (hDC, nRowColor, nColColor)
   BT_DeleteDC (BTstruct)
   
   BT_BitmapRelease (hBitmap)
RETURN .T.
