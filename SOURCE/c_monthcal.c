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



/* 
  The adaptation of the source code of this file to support UNICODE character set and WIN64 architecture was made 
  by Dr. Claudio Soto, November 2012 and June 2014 respectively. 
  mail: <srvet@adinet.com.uy>
  blog: http://srvet.blogspot.com
*/
#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"




//#define _WIN32_IE      0x0500
//#define HB_OS_WIN_32_USED
//#define _WIN32_WINNT   0x0400


#include <shlobj.h>
#include <windows.h>
#include <commctrl.h>
#include "hbapi.h"
#include "hbvm.h"
#include "hbstack.h"
#include "hbapiitm.h"
#include "hbdate.h"   // HMG5: hb_dateEncode / hb_dateDecode
#include "winreg.h"
#include "tchar.h"

HFONT PrepareFont (TCHAR *, int, int, int, int, int );

HB_FUNC ( INITMONTHCAL )
{
	HWND hwnd;
	HWND hmonthcal;
	RECT rc;
	INITCOMMONCONTROLSEX icex;
	int Style;
	HFONT hfont ;
	int bold = FW_NORMAL;
	int italic = 0;
	int underline = 0;
	int strikeout = 0;

	icex.dwSize = sizeof(icex);
	icex.dwICC  = ICC_DATE_CLASSES;
	InitCommonControlsEx(&icex);

	hwnd = (HWND) HMG_parnl (1);

	Style = WS_BORDER | WS_CHILD ;

	if ( hb_parl(9) )
	{
		Style = Style | MCS_NOTODAY ;
	}

	if ( hb_parl(10) )
	{
		Style = Style | MCS_NOTODAYCIRCLE ;
	}

	if ( hb_parl(11) )
	{
		Style = Style | MCS_WEEKNUMBERS ;
	}

	if ( !hb_parl(12) )
	{
		Style = Style | WS_VISIBLE ;
	}

	if ( !hb_parl(13) )
	{
		Style = Style | WS_TABSTOP ;
	}

	if ( hb_parl(18) )   // HMG5 (from HMG 3.5): ON GETBOLDDAYS
	{
		Style = Style | MCS_DAYSTATE ;
	}

	hmonthcal = CreateWindowEx( 0L , MONTHCAL_CLASS /*_TEXT("SysMonthCal32")*/,
                     _TEXT(""),
                     Style,
                     0,0,0,0,
                     hwnd,
                     (HMENU) HMG_parnl (2),
                     GetModuleHandle(NULL),
                     NULL ) ;

	if ( hb_parl (14) )
	{
		bold = FW_BOLD;
	}

	if ( hb_parl (15) )
	{
		italic = 1;
	}

	if ( hb_parl (16) )
	{
		underline = 1;
	}

	if ( hb_parl (17) )
	{
		strikeout = 1;
	}

  	hfont = PrepareFont ( (TCHAR*)HMG_parc(7), (LPARAM) hb_parni(8), bold , italic, underline, strikeout ) ;

	SendMessage(hmonthcal,(UINT)WM_SETFONT,(WPARAM) hfont , (LPARAM) 1 ) ;   // add (LPARAM)

	MonthCal_GetMinReqRect(hmonthcal, &rc);

	SetWindowPos(hmonthcal, NULL, hb_parni(3) , hb_parni(4) ,
                rc.right, rc.bottom,
                SWP_NOZORDER);

	hb_reta (2);
	HMG_storvnl ((LONG_PTR) hmonthcal, -1, 1 );
	HMG_storvnl ((LONG_PTR) hfont    , -1, 2 );

}

HB_FUNC ( SETMONTHCAL )
{
	HWND hwnd;
	SYSTEMTIME sysTime;
	int y;
	int m;
	int d;

	hwnd = (HWND) HMG_parnl (1);

	y = hb_parni(2);
	m = hb_parni(3);
	d = hb_parni(4);

	sysTime.wYear = y;
	sysTime.wMonth = m;
	sysTime.wDay = d;
	sysTime.wDayOfWeek = 0;

	sysTime.wHour = 0;
	sysTime.wMinute = 0;
	sysTime.wSecond = 0;
	sysTime.wMilliseconds = 0;

	MonthCal_SetCurSel(hwnd, &sysTime);
}

HB_FUNC ( GETMONTHCALYEAR )
{
	HWND hwnd;
	SYSTEMTIME st;
	hwnd = (HWND) HMG_parnl (1);

	SendMessage(hwnd, MCM_GETCURSEL, 0, (LPARAM) &st);
	hb_retni(st.wYear);
}

HB_FUNC ( GETMONTHCALMONTH )
{
	HWND hwnd;
	SYSTEMTIME st;
	hwnd = (HWND) HMG_parnl (1);

	SendMessage(hwnd, MCM_GETCURSEL, 0, (LPARAM) &st);
	hb_retni(st.wMonth);
}

HB_FUNC ( GETMONTHCALDAY )
{
	HWND hwnd;
	SYSTEMTIME st;
	hwnd = (HWND) HMG_parnl (1);

	SendMessage(hwnd, MCM_GETCURSEL, 0, (LPARAM) &st);
	hb_retni(st.wDay);
}


// Dr. Claudio Soto (April 2013)
HB_FUNC ( DATETIME_GETMONTHCALCOLOR )
{
   HWND     hWnd         = (HWND) HMG_parnl (1);
   INT      nColorIndex  = (INT)  hb_parnl (2);
   COLORREF colorRGB;
   colorRGB = (COLORREF) DateTime_GetMonthCalColor (hWnd, nColorIndex);
   hb_retnl ((LONG) colorRGB);
}


// Dr. Claudio Soto (April 2013)
HB_FUNC ( DATETIME_SETMONTHCALCOLOR )
{
   HWND     hWnd         = (HWND)     HMG_parnl (1);
   INT      nColorIndex  = (INT)      hb_parnl (2);
   COLORREF colorRGB     = (COLORREF) hb_parnl (3);
   colorRGB = (COLORREF) DateTime_SetMonthCalColor (hWnd, nColorIndex, colorRGB);
   hb_retnl ((LONG) colorRGB);
}


// Dr. Claudio Soto (April 2013)
HB_FUNC ( DATETIME_GETMONTHCALFONT )
{
   HWND hWnd = (HWND) HMG_parnl (1);
   HFONT hFont;
   hFont = (HFONT) DateTime_GetMonthCalFont (hWnd);
   HMG_retnl ((LONG_PTR) hFont);
}


// Dr. Claudio Soto (April 2013)
HB_FUNC ( DATETIME_SETMONTHCALFONT )
{
   HWND  hWnd    = (HWND)  HMG_parnl (1);
   HFONT hFont   = (HFONT) HMG_parnl (2);
   BOOL  lRedraw = (BOOL)  hb_parl  (3);
   DateTime_SetMonthCalFont (hWnd, hFont, lRedraw);
}


/* ---- HMG5: ported from HMG 3.5 (RANGEMIN/RANGEMAX, VISIBLEMIN/VISIBLEMAX, ON GETBOLDDAYS) ---- */

static void hmg_mc_date( SYSTEMTIME * st, long lJulian )
{
   int y, m, d;
   hb_dateDecode( lJulian, &y, &m, &d );
   memset( st, 0, sizeof( SYSTEMTIME ) );
   st->wYear  = ( WORD ) y;
   st->wMonth = ( WORD ) m;
   st->wDay   = ( WORD ) d;
}

/* SETMONTHCALRANGE( hWnd, dMin, dMax ): an empty date (or NIL) is no limit on that side */
HB_FUNC ( SETMONTHCALRANGE )
{
   HWND hWnd = (HWND) HMG_parnl (1);
   SYSTEMTIME st[ 2 ];
   DWORD dwFlags = 0;
   long lMin = HB_ISDATE( 2 ) ? hb_pardl( 2 ) : 0;
   long lMax = HB_ISDATE( 3 ) ? hb_pardl( 3 ) : 0;
   memset( st, 0, sizeof( st ) );
   if( lMin )
   {
      hmg_mc_date( &st[ 0 ], lMin );
      dwFlags |= GDTR_MIN;
   }
   if( lMax )
   {
      hmg_mc_date( &st[ 1 ], lMax );
      dwFlags |= GDTR_MAX;
   }
   hb_retl( MonthCal_SetRange( hWnd, dwFlags, st ) != 0 );
}

/* GETMONTHCALVISIBLE( hWnd, @dStart, @dEnd ): the first and last day shown, partly shown months included */
HB_FUNC ( GETMONTHCALVISIBLE )
{
   HWND hWnd = (HWND) HMG_parnl (1);
   SYSTEMTIME st[ 2 ];
   memset( st, 0, sizeof( st ) );
   SendMessage( hWnd, MCM_GETMONTHRANGE, GMR_DAYSTATE, (LPARAM) st );
   hb_stordl( hb_dateEncode( st[ 0 ].wYear, st[ 0 ].wMonth, st[ 0 ].wDay ), 2 );
   hb_stordl( hb_dateEncode( st[ 1 ].wYear, st[ 1 ].wMonth, st[ 1 ].wDay ), 3 );
}

/* INITBOLDDAYS( lParam, @dStart, @nMonths ): MCN_GETDAYSTATE asks for nMonths months from dStart */
HB_FUNC ( INITBOLDDAYS )
{
   NMDAYSTATE * pDayState = (NMDAYSTATE *) HMG_parnl (1);
   hb_stordl( hb_dateEncode( pDayState->stStart.wYear, pDayState->stStart.wMonth, pDayState->stStart.wDay ), 2 );
   hb_storni( pDayState->cDayState, 3 );
}

/* SETBOLDDAYS( lParam, anMonths ): one bit a day (bit 0 = day 1) for each month asked for.
   The buffer must outlive the notification (the control reads it after the handler returns):
   static, not on the stack as in HMG 3.5. */
HB_FUNC ( SETBOLDDAYS )
{
   static MONTHDAYSTATE s_aState[ 14 ];
   NMDAYSTATE * pDayState = (NMDAYSTATE *) HMG_parnl (1);
   PHB_ITEM pMonths = hb_param( 2, HB_IT_ARRAY );
   int i, n = pDayState->cDayState;
   if( n > 14 )
      n = 14;
   memset( s_aState, 0, sizeof( s_aState ) );
   for( i = 0; i < n; i++ )
      s_aState[ i ] = pMonths ? (MONTHDAYSTATE) hb_arrayGetNL( pMonths, i + 1 ) : 0;
   pDayState->prgDayState = s_aState;
}
