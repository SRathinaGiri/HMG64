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
#include 'hmg.ch'
*------------------------------------------------------------------------------*
Procedure _DefineHotKey ( cParentForm , nMod , nKey , bAction )
*------------------------------------------------------------------------------*
Local nParentForm , nId , i , nControlCount , k , z 

	If _HMG_SYSDATA [ 264 ] = .T.
		cParentForm := _HMG_SYSDATA [ 223 ]
	EndIf

	If ValType ( cParentForm ) == 'U'
		MsgHMGError ("ON KEY: Parent Window Not Specified. Program Terminated")
	EndIf

	// Check if the window/form is defined.
	if ( .not. _IsWindowDefined( cParentForm ) )
		MsgHMGError( "Window: " + cParentForm + " is not defined. Program terminated." )
	Endif

	nParentForm := GetFormHandle ( cParentForm )
	nControlCount := HMG_LEN ( _HMG_SYSDATA [HMG_CTL_HANDLE] )
	z := GetFormIndex (cParentForm)

	For i := 1 To nControlCount
		If _HMG_SYSDATA [HMG_CTL_TYPE] [i] == 'HOTKEY' .and. _HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [i] == nParentForm .and. _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [i] == nMod .and. _HMG_SYSDATA [  HMG_CTL_VALUE ] [i] == nKey
			_EraseControl(i,z)
			Exit
		EndIf
	Next i

	nId := _GetId()

	InitHotKey ( nParentForm , nMod , nKey , nId )

	k := _GetControlFree()

	
	_HMG_SYSDATA [HMG_CTL_TYPE] [k] :=  "HOTKEY" 
	_HMG_SYSDATA [HMG_CTL_NAME]  [k] :=   '' 
	_HMG_SYSDATA [HMG_CTL_HANDLE]  [k] :=   0 
	_HMG_SYSDATA [HMG_CTL_PARENTHANDLE]  [k] :=   nParentForm 
	_HMG_SYSDATA [  HMG_CTL_ID ]  [k] :=   nId 
	_HMG_SYSDATA [  HMG_CTL_PROCEDURE ]  [k] :=   bAction 
	_HMG_SYSDATA [  HMG_CTL_PAGEMAP ]  [k] :=   nMod  
	_HMG_SYSDATA [  HMG_CTL_VALUE ]  [k] :=   nKey 
	_HMG_SYSDATA [  HMG_CTL_INPUTMASK ]  [k] :=   "" 
	_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ]  [k] :=   "" 
	_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ]   [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_CHANGE ]  [k] :=   "" 
	_HMG_SYSDATA [ HMG_CTL_DELETED ]  [k] :=   .F. 
	_HMG_SYSDATA [ HMG_CTL_BKCOLOR ]  [k] :=   Nil 
	_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ]  [k] :=   Nil 
	_HMG_SYSDATA [ HMG_CTL_DBLCLICK ]   [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_HEADCLICK ]  [k] :=   {} 
	_HMG_SYSDATA [ HMG_CTL_ROW ]  [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_COL ]   [k] :=  0 
	_HMG_SYSDATA [ HMG_CTL_WIDTH ]  [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_HEIGHT ]  [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_SPACING ]   [k] :=  0 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ]  [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ]   [k] :=  0 
	_HMG_SYSDATA [ HMG_CTL_PICTURE ]   [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ]   [k] :=  0 
	_HMG_SYSDATA [ HMG_CTL_FONTNAME ]   [k] :=  '' 
	_HMG_SYSDATA [ HMG_CTL_FONTSIZE ]  [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ]  [k] :=   {.f.,.f.,.f.,.f.} 
	_HMG_SYSDATA [ HMG_CTL_TOOLTIP ]   [k] :=   ''  
	_HMG_SYSDATA [ HMG_CTL_RANGEMIN ]   [k] :=   0  
	_HMG_SYSDATA [ HMG_CTL_RANGEMAX ]   [k] :=   0  
	_HMG_SYSDATA [ HMG_CTL_CAPTION ]   [k] :=   '' 
	_HMG_SYSDATA [ HMG_CTL_VISIBLE ]   [k] :=   .t. 
	_HMG_SYSDATA [ HMG_CTL_HELPID ]  [k] :=    0 
	_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ]  [k] :=    0 
	_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ]  [k] :=    0 
	_HMG_SYSDATA [ HMG_CTL_ENABLED ]  [k] :=    .T. 
	_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := 0
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

Return
*------------------------------------------------------------------------------*
Procedure _ReleaseHotKey ( cParentForm, nMod , nKey )
*------------------------------------------------------------------------------*
Local i , nParentFormHandle , nControlCount , z 

	nParentFormHandle := GetFormhandle ( cParentForm )
	nControlCount := HMG_LEN ( _HMG_SYSDATA [HMG_CTL_HANDLE] )
	z := GetFormIndex (cParentForm)

	For i := 1 To nControlCount
		If _HMG_SYSDATA [HMG_CTL_TYPE] [i] == 'HOTKEY' .and. _HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [i] == nParentFormHandle .and. _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [i] == nMod .and. _HMG_SYSDATA [  HMG_CTL_VALUE ] [i] == nKey
			_EraseControl(i,z)
			Exit
		EndIf
	Next i

Return

*------------------------------------------------------------------------------*
Function _GetHotKey ( cParentForm, nMod , nKey )
*------------------------------------------------------------------------------*
Local i , nParentFormHandle , nControlCount , bRetVal := Nil

	nParentFormHandle := GetFormhandle ( cParentForm )
	nControlCount := HMG_LEN ( _HMG_SYSDATA [HMG_CTL_HANDLE] )

	For i := 1 To nControlCount
		If _HMG_SYSDATA [HMG_CTL_TYPE] [i] == 'HOTKEY' .and. _HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [i] == nParentFormHandle .and. _HMG_SYSDATA [  HMG_CTL_PAGEMAP ] [i] == nMod .and. _HMG_SYSDATA [  HMG_CTL_VALUE ] [i] == nKey
			bRetVal := _HMG_SYSDATA [  HMG_CTL_PROCEDURE ] [i]
			Exit
		EndIf
	Next i

Return ( bRetVal )


*------------------------------------------------------------------------------*
Function _PushKey (nKey)
*------------------------------------------------------------------------------*
   Keybd_Event ( nKey, .F. )
   Keybd_Event ( nKey, .T. )
Return Nil


//*******************************************
//* by Dr. Claudio Soto, April 2016
//*******************************************

//       HMG_PressKey( nVK1, nVK2, ... ) --> return array { nVK1, nVK2, ... }
FUNCTION HMG_PressKey( ... )
LOCAL i, aVK := {}

   FOR i := 1 TO PCount()
      IF ValType( PValue( i ) ) == "N"
         AADD( aVK, PValue( i ) )
      ELSE
         MsgHMGError ("HMG_PressKey: invalid parameter")
      ENDIF
      Keybd_Event( aVK[ i ], .F. )   // KeyDown
   NEXT

   FOR i := HMG_LEN( aVK ) TO 1 STEP -1
      Keybd_Event( aVK[ i ], .T. )   // KeyUp
   NEXT

RETURN aVK


