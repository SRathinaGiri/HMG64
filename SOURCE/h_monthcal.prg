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

/* HMG5: ported from HMG 3.5 - WIDTH/HEIGHT, FONTCOLOR, OUTERFONTCOLOR, BACKCOLOR, BORDERCOLOR,
   TITLEFONTCOLOR, TITLEBACKCOLOR, RANGEMIN, RANGEMAX, VIEW and ON GETBOLDDAYS. Their data is kept
   in the control's own MISCDATA1 slot (a hash), not in general slots: HMG5's layout is frozen
   and the MonthCalendar already keeps its tab page name in the RANGEMIN slot. */
#define MCM_FIRST               0x1000
#define MCM_SETCOLOR            (MCM_FIRST+10)
#define MCM_GETCOLOR            (MCM_FIRST+11)
#define MCM_GETCURRENTVIEW      (MCM_FIRST+22)
#define MCM_SETCURRENTVIEW      (MCM_FIRST+32)
*-----------------------------------------------------------------------------*
Function _DefineMonthCal ( ControlName, ParentForm, x, y, w, h, value, ;
                           fontname, fontsize, tooltip, notoday, notodaycircle, ;
                           weeknumbers, change, HelpId, invisible, notabstop, ;
                           bold, italic, underline, strikeout, ;
                           fontcolor, outerfontcolor, backcolor, ;
                           bordercolor, titlefontcolor, titlebackcolor, ;
                           rangemin, rangemax, view, getbolddays )
*-----------------------------------------------------------------------------*
Local cParentForm , mVar , k
Local aControlHandle
Local cParentTabName
Local aColors, a, lColors := .F.

   DEFAULT w         TO 0
   DEFAULT h         TO 0
   DEFAULT value     TO date()
   DEFAULT change    TO ""
   DEFAULT bold      TO FALSE
   DEFAULT italic    TO FALSE
   DEFAULT underline TO FALSE
   DEFAULT strikeout TO FALSE

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
		MsgHMGError("Window: "+ ParentForm + " is not defined. Program terminated")
	Endif

	If _IsControlDefined (ControlName,ParentForm)
		MsgHMGError ("Control: " + ControlName + " Of " + ParentForm + " Already defined. Program terminated")
	endif

	mVar := '_' + ParentForm + '_' + ControlName

	cParentForm := ParentForm

	ParentForm = GetFormHandle (ParentForm)

	if valtype(fontname) != "U" .and. valtype(fontsize) != "U"
		aControlHandle := InitMonthCal ( ParentForm, 0, x, y, w, h , fontname , fontsize , notoday , notodaycircle , weeknumbers, invisible, notabstop, bold, italic, underline, strikeout, HB_ISBLOCK( getbolddays ) )
	Else
		aControlHandle := InitMonthCal ( ParentForm, 0, x, y, w, h , _HMG_SYSDATA [ 342 ] , _HMG_SYSDATA [ 343 ] , notoday , notodaycircle , weeknumbers, invisible, notabstop, bold, italic, underline, strikeout, HB_ISBLOCK( getbolddays ) )
	endif

	// colours: the themed calendar ignores them, so a calendar given a colour is drawn classic
	aColors := { { fontcolor, MCSC_TEXT }, { outerfontcolor, MCSC_TRAILINGTEXT }, { backcolor, MCSC_MONTHBK }, ;
	             { bordercolor, MCSC_BACKGROUND }, { titlefontcolor, MCSC_TITLETEXT }, { titlebackcolor, MCSC_TITLEBK } }
	FOR EACH a IN aColors
		IF _HMG_MonthCalRGB( a[1] )
			IF ! lColors .AND. IsAppThemed()
				SetWindowTheme( aControlHandle[1], "", "" )
			ENDIF
			lColors := .T.
			SendMessage( aControlHandle[1], MCM_SETCOLOR, a[2], RGB( a[1][1], a[1][2], a[1][3] ) )
		ENDIF
	NEXT

	if w != 0 .and. h != 0
		SetWindowPos( aControlHandle[1], 0, x, y, w, h, SWP_NOZORDER )
	endif

	If _HMG_SYSDATA [ 265 ] = .T.
		aAdd ( _HMG_SYSDATA [ 142 ] , aControlhandle[1] )
	EndIf

	IF HB_ISDATE( rangemin ) .OR. HB_ISDATE( rangemax )
		SetMonthCalRange( aControlHandle[1], rangemin, rangemax )
	ENDIF
	IF HB_ISNUMERIC( view ) .AND. view >= MCMV_MONTH .AND. view <= MCMV_CENTURY
		SendMessage( aControlHandle[1], MCM_SETCURRENTVIEW, 0, view )
	ENDIF

	SetMonthCal( aControlHandle[1] ,year(value), month(value), day(value) )

	if valtype(tooltip) != "U"
		SetToolTip ( aControlHandle[1] , tooltip , GetFormToolTipHandle (cParentForm) )
	endif

	w := GetWindowWidth ( aControlHandle[1] )
	h := GetWindowHeight ( aControlHandle[1] )

	k := _GetControlFree()

	_HMG_VarSet ( mVar , k )

	_HMG_SYSDATA [HMG_CTL_TYPE] [k] := "MONTHCAL" 
	_HMG_SYSDATA [HMG_CTL_NAME]  [k] :=  ControlName 
	_HMG_SYSDATA [HMG_CTL_HANDLE]  [k] :=  aControlHandle[1] 
	_HMG_SYSDATA [HMG_CTL_PARENTHANDLE] [k] :=   ParentForm 
	_HMG_SYSDATA [  HMG_CTL_ID ]  [k] :=  0 
	_HMG_SYSDATA [  HMG_CTL_PROCEDURE ]  [k] :=  "" 
	_HMG_SYSDATA [  HMG_CTL_PAGEMAP ]  [k] :=  {} 
	_HMG_SYSDATA [  HMG_CTL_VALUE ]  [k] :=  Nil 
	_HMG_SYSDATA [  HMG_CTL_INPUTMASK ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_GOTFOCUS ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_CHANGE ]  [k] :=  change 
	_HMG_SYSDATA [ HMG_CTL_DELETED ]  [k] :=  .F. 
	_HMG_SYSDATA [ HMG_CTL_BKCOLOR ]  [k] :=  Nil 
	_HMG_SYSDATA [ HMG_CTL_FONTCOLOR ]  [k] :=  Nil 
	_HMG_SYSDATA [ HMG_CTL_DBLCLICK ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_HEADCLICK ]  [k] :=  {} 
	_HMG_SYSDATA [ HMG_CTL_ROW ]  [k] :=  y 
	_HMG_SYSDATA [ HMG_CTL_COL ]   [k] := x 
	_HMG_SYSDATA [ HMG_CTL_WIDTH ]   [k] := w 
	_HMG_SYSDATA [ HMG_CTL_HEIGHT ]   [k] := h 
	_HMG_SYSDATA [ HMG_CTL_SPACING ]   [k] := 0 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERROW ]   [k] := iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 333 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ]  [k] :=  iif ( _HMG_SYSDATA [ 183 ] > 0 ,_HMG_SYSDATA [ 334 ] [_HMG_SYSDATA [ 183 ]] , -1 ) 
	_HMG_SYSDATA [ HMG_CTL_PICTURE ]  [k] :=  "" 
	_HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ]  [k] :=  0 
	_HMG_SYSDATA [ HMG_CTL_FONTNAME ]  [k] :=  fontname 
	_HMG_SYSDATA [ HMG_CTL_FONTSIZE ]  [k] :=  fontsize 
	_HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ]  [k] :=  {bold,italic,underline,strikeout} 
	_HMG_SYSDATA [ HMG_CTL_TOOLTIP ]   [k] :=  tooltip  
	_HMG_SYSDATA [ HMG_CTL_RANGEMIN ]  [k] :=   cParentTabName
	_HMG_SYSDATA [ HMG_CTL_RANGEMAX ]  [k] :=   0  
	_HMG_SYSDATA [ HMG_CTL_CAPTION ]   [k] :=  ''  
	_HMG_SYSDATA [ HMG_CTL_VISIBLE ]  [k] :=   if(invisible,FALSE,TRUE) 
	_HMG_SYSDATA [ HMG_CTL_HELPID ]  [k] :=   HelpId 
	_HMG_SYSDATA [ HMG_CTL_FONTHANDLE ]  [k] :=   aControlHandle[2] 
	_HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ]  [k] :=   0 
	_HMG_SYSDATA [ HMG_CTL_ENABLED ]  [k] :=   .T. 
	_HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [k] := { "rangemin" => iif( HB_ISDATE( rangemin ), rangemin, CToD( "" ) ), ;
	                                            "rangemax" => iif( HB_ISDATE( rangemax ), rangemax, CToD( "" ) ), ;
	                                            "getbolddays" => iif( HB_ISBLOCK( getbolddays ), getbolddays, NIL ) }
	_HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [k] := { NIL , NIL , NIL , NIL , NIL , NIL , NIL , NIL }

Return Nil

STATIC FUNCTION _HMG_MonthCalRGB( a )
RETURN HB_ISARRAY( a ) .AND. Len( a ) >= 3 .AND. HB_ISNUMERIC( a[1] ) .AND. HB_ISNUMERIC( a[2] ) .AND. HB_ISNUMERIC( a[3] )

/* the MonthCalendar's own data (MISCDATA1), {=>} if the control is not a MonthCalendar */
FUNCTION _HMG_MonthCalData( i )
   IF i > 0 .AND. _HMG_SYSDATA [ HMG_CTL_TYPE ] [i] == "MONTHCAL" .AND. HB_ISHASH( _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [i] )
      RETURN _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [i]
   ENDIF
RETURN { "rangemin" => CToD( "" ), "rangemax" => CToD( "" ), "getbolddays" => NIL }

/* RangeMin / RangeMax of a MonthCalendar: an empty date is no limit */
FUNCTION _SetMonthCalendarRange( i, dMin, dMax )
   LOCAL h := _HMG_MonthCalData( i )
   h[ "rangemin" ] := iif( HB_ISDATE( dMin ), dMin, CToD( "" ) )
   h[ "rangemax" ] := iif( HB_ISDATE( dMax ), dMax, CToD( "" ) )
   SetMonthCalRange( _HMG_SYSDATA [ HMG_CTL_HANDLE ] [i], h[ "rangemin" ], h[ "rangemax" ] )
RETURN NIL

FUNCTION GetMonthCalendarVisibleMin( cControlName, cParentName )
   LOCAL dMin, dMax
   GetMonthCalVisible( GetControlHandle( cControlName, cParentName ), @dMin, @dMax )
RETURN dMin

FUNCTION GetMonthCalendarVisibleMax( cControlName, cParentName )
   LOCAL dMin, dMax
   GetMonthCalVisible( GetControlHandle( cControlName, cParentName ), @dMin, @dMax )
RETURN dMax

FUNCTION GetMonthCalendarView( cControlName, cParentName )
RETURN SendMessage( GetControlHandle( cControlName, cParentName ), MCM_GETCURRENTVIEW, 0, 0 )

FUNCTION SetMonthCalendarView( cControlName, cParentName, nView )
RETURN SendMessage( GetControlHandle( cControlName, cParentName ), MCM_SETCURRENTVIEW, 0, nView ) != 0

/* MCN_GETDAYSTATE (h_windows.prg): ON GETBOLDDAYS { | dStart, dEnd | aDates } gives the days to show in bold */
PROCEDURE SetMonthCalendarBoldDays( i, lParam )
   LOCAL bBold := _HMG_MonthCalData( i )[ "getbolddays" ], dStart, dEnd, nMonths, adBold
   IF HB_ISBLOCK( bBold )
      GetMonthCalVisible( GetHwndFrom( lParam ), @dStart, @dEnd )
      InitBoldDays( lParam, @dStart, @nMonths )
      adBold := Eval( bBold, dStart, dEnd )
      SetBoldDays( lParam, BoldDaysNumericArray( dStart, dEnd, nMonths, adBold ) )
   ENDIF
RETURN

/* the dates of adBold as one bit mask a month, nMonths months from dStart's month */
FUNCTION BoldDaysNumericArray( dStart, dEnd, nMonths, adBold )
   LOCAL nStartMonths := Year( dStart ) * 12 + Month( dStart ) - 1
   LOCAL anBold := AFill( Array( nMonths ), 0 )
   LOCAL dBold, nMonth
   IF HB_ISARRAY( adBold )
      FOR EACH dBold IN adBold
         IF HB_ISDATE( dBold ) .AND. dBold >= dStart .AND. dBold <= dEnd
            nMonth := Year( dBold ) * 12 + Month( dBold ) - 1 - nStartMonths + 1
            IF nMonth >= 1 .AND. nMonth <= nMonths
               anBold[ nMonth ] := hb_bitSet( anBold[ nMonth ], Day( dBold ) - 1 )
            ENDIF
         ENDIF
      NEXT
   ENDIF
RETURN anBold


// by Dr. Claudio Soto (April 2013)
// HMG5: a MONTHCALENDAR uses MCM_GETCOLOR; any other control (a DATEPICKER's drop-down calendar) as before
FUNCTION GetMonthCalendarColor (cControlName, cParentName, nIndexColor)
LOCAL RGBcolorRef, hWnd := GetControlHandle (cControlName, cParentName)
IF GetControlType (cControlName, cParentName) == "MONTHCAL"
   RGBcolorRef := SendMessage( hWnd, MCM_GETCOLOR, nIndexColor, 0 )
ELSE
   RGBcolorRef := DATETIME_GETMONTHCALCOLOR (hWnd, nIndexColor)
ENDIF
RETURN { GETRED (RGBcolorRef), GETGREEN (RGBcolorRef), GETBLUE (RGBcolorRef) } 


// by Dr. Claudio Soto (April 2013)
// HMG5: a MONTHCALENDAR uses MCM_SETCOLOR (drawn classic: the themed calendar ignores colours);
// any other control (a DATEPICKER's drop-down calendar) as before
FUNCTION SetMonthCalendarColor (cControlName, cParentName, nIndexColor, aRGBcolor)
LOCAL RGBcolorRef, hWnd := GetControlHandle (cControlName, cParentName)
IF GetControlType (cControlName, cParentName) == "MONTHCAL"
   IF IsAppThemed()
      SetWindowTheme( hWnd, "", "" )
   ENDIF
   RGBcolorRef := SendMessage( hWnd, MCM_SETCOLOR, nIndexColor, RGB (aRGBcolor[1], aRGBcolor[2], aRGBcolor[3]) )
ELSE
   RGBcolorRef := DATETIME_SETMONTHCALCOLOR (hWnd, nIndexColor, RGB (aRGBcolor[1], aRGBcolor[2], aRGBcolor[3]))
ENDIF
RETURN { GETRED (RGBcolorRef), GETGREEN (RGBcolorRef), GETBLUE (RGBcolorRef) } 




