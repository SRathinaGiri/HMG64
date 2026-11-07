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


#include <shlobj.h>
#include <windows.h>
#include <commctrl.h>
#include "hbapi.h"

#include "hbthread.h"
extern HB_CRITICAL_T _HMG_Mutex;   // global Mutex variable defined into c_Thread.c


/*----------------------------------------------------------------------------
   SET MSGBOXMODERN ON: MsgBox/MsgInfo/MsgYesNo ... shown as a TaskDialog
   (Windows 10/11 look) instead of MessageBox(). Idea and dialog layout from
   HMG 3.7 (Dr. Claudio Soto, 2026). HMG5 differences:
   - OFF by default, so existing programs look and behave as before;
   - works in the ANSI library too (TaskDialog is wide-only: text is converted);
   - comctl32 is taken from the process (no LoadLibrary search path);
   - button sets TaskDialog has no system-translated buttons for
     (Abort/Retry/Ignore, Cancel/Try Again/Continue) stay on MessageBox(),
     so their captions stay in the user's language.
   The return values are the MessageBox() ones (IDOK, IDYES ..., ID_TIMEDOUT).
---------------------------------------------------------------------------*/

#define ID_TIMEDOUT        32000
#define HMG_NO_TIMEOUT     ( ( DWORD ) 0xFFFFFFFF )
#define HMG_MB_DEFBUTTONS  0x00000F00

int WINAPI MessageBoxTimeout (HWND hWnd, LPCTSTR lpText, LPCTSTR lpCaption, UINT uType, WORD wLanguageId, DWORD dwMilliseconds);

typedef HRESULT ( WINAPI * HMG_PFTASKDIALOGINDIRECT ) ( const TASKDIALOGCONFIG *, int *, int *, BOOL * );

typedef struct {
   DWORD dwMillis;       /* HMG_NO_TIMEOUT = never */
   DWORD dwStart;
   BOOL  lTimedOut;
   BOOL  lTopMost;
} HMG_MSGDATA;

static int s_lMsgBoxModern = 0;

static HMG_PFTASKDIALOGINDIRECT HMG_TaskDialogPointer ( void )
{
   static HMG_PFTASKDIALOGINDIRECT pfn = NULL;
   static int lChecked = 0;

   _THREAD_LOCK();
   if ( ! lChecked )
   {
      /* comctl32 v6 (the manifest's) is already loaded by InitCommonControlsEx */
      HMODULE hLib = GetModuleHandle( _TEXT( "comctl32.dll" ) );
      if ( hLib == NULL )
         hLib = HMG_LoadSystemLibrary( _TEXT( "comctl32.dll" ) );
      if ( hLib != NULL )   /* comctl32 v5 has no TaskDialog: the classic path is used */
         pfn = ( HMG_PFTASKDIALOGINDIRECT ) GetProcAddress( hLib, "TaskDialogIndirect" );
      lChecked = 1;
   }
   _THREAD_UNLOCK();
   return pfn;
}

static HRESULT CALLBACK HMG_MsgDialogCallback ( HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam, LONG_PTR lpRefData )
{
   HMG_MSGDATA * pData = ( HMG_MSGDATA * ) lpRefData;
   ( void ) wParam; ( void ) lParam;

   if ( msg == TDN_DIALOG_CONSTRUCTED )
   {
      if ( pData->lTopMost )
         SetWindowPos( hDlg, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE );
      pData->dwStart = GetTickCount();
   }
   else if ( msg == TDN_TIMER && pData->dwMillis != HMG_NO_TIMEOUT &&
             GetTickCount() - pData->dwStart >= pData->dwMillis )   /* unsigned: safe across wrap */
   {
      pData->lTimedOut = TRUE;
      /* a TaskDialog ignores WM_CLOSE: "click" a button id it does not have */
      SendMessageW( hDlg, TDM_CLICK_BUTTON, ID_TIMEDOUT, 0 );
   }
   return S_OK;
}

/* TaskDialog path. Returns the button id, or -1 when the caller must use MessageBox(). */
static int HMG_MsgDialog ( HWND hWnd, LPCTSTR pcText, LPCTSTR pcCaption, UINT uType, DWORD dwMillis, HICON hUserIcon )
{
   HMG_PFTASKDIALOGINDIRECT pfn;
   TASKDIALOGCONFIG cfg;
   HMG_MSGDATA      data;
   WCHAR            szApp [ MAX_PATH ];
   const WCHAR *    pwText;
   const WCHAR *    pwCaption;
   WCHAR *          pwMain = NULL;
   const WCHAR *    p;
   int              aIds [ 3 ] = { 0, 0, 0 }, nIds, nDef, nButton = 0;
   DWORD            dwButtons, dwFlags;
   HRESULT          hr;

   if ( ! s_lMsgBoxModern || pcText == NULL || ( pfn = HMG_TaskDialogPointer() ) == NULL )
      return -1;

   switch ( uType & MB_TYPEMASK )
   {
      case MB_OK:
         dwButtons = TDCBF_OK_BUTTON;
         nIds = 1; aIds[0] = IDOK;
         break;
      case MB_OKCANCEL:
         dwButtons = TDCBF_OK_BUTTON | TDCBF_CANCEL_BUTTON;
         nIds = 2; aIds[0] = IDOK; aIds[1] = IDCANCEL;
         break;
      case MB_YESNO:
         dwButtons = TDCBF_YES_BUTTON | TDCBF_NO_BUTTON;
         nIds = 2; aIds[0] = IDYES; aIds[1] = IDNO;
         break;
      case MB_YESNOCANCEL:
         dwButtons = TDCBF_YES_BUTTON | TDCBF_NO_BUTTON | TDCBF_CANCEL_BUTTON;
         nIds = 3; aIds[0] = IDYES; aIds[1] = IDNO; aIds[2] = IDCANCEL;
         break;
      case MB_RETRYCANCEL:
         dwButtons = TDCBF_RETRY_BUTTON | TDCBF_CANCEL_BUTTON;
         nIds = 2; aIds[0] = IDRETRY; aIds[1] = IDCANCEL;
         break;
      default:
         return -1;   /* no system-translated common buttons for these */
   }

#ifdef UNICODE
   pwText    = pcText;
   pwCaption = pcCaption;
#else
   pwText    = HMG_MBtoWC( pcText );      /* frame-owned: freed when the HB_FUNC returns */
   pwCaption = HMG_MBtoWC( pcCaption );
   if ( pwText == NULL )
      return -1;
#endif

   memset( &cfg, 0, sizeof( cfg ) );
   memset( &data, 0, sizeof( data ) );
   cfg.cbSize          = sizeof( cfg );
   cfg.hwndParent      = hWnd;
   cfg.dwCommonButtons = ( TASKDIALOG_COMMON_BUTTON_FLAGS ) dwButtons;

   nDef = ( int ) ( ( uType & HMG_MB_DEFBUTTONS ) >> 8 );   /* MB_DEFBUTTON1..3 -> 0..2 */
   cfg.nDefaultButton = aIds [ ( nDef < nIds ) ? nDef : 0 ];

   /* No caption: the exe name, as MessageBox does. (The TD_WINDOWTITLE_* sentinels crash
      comctl32 on x64 - found by HMG 3.7.) */
   if ( pwCaption == NULL || *pwCaption == 0 )
   {
      DWORD   n = GetModuleFileNameW( NULL, szApp, MAX_PATH );
      WCHAR * q, * pLast = szApp;
      if ( n == 0 || n >= MAX_PATH )
         szApp [ 0 ] = 0;
      for ( q = szApp; *q; q++ )
         if ( *q == L'\\' || *q == L'/' )
            pLast = q + 1;
      cfg.pszWindowTitle = pLast;
   }
   else
      cfg.pszWindowTitle = pwCaption;

   dwFlags = TDF_ALLOW_DIALOG_CANCELLATION | TDF_POSITION_RELATIVE_TO_WINDOW;
   if ( hUserIcon != NULL )
   {
      cfg.hMainIcon = hUserIcon;
      dwFlags |= TDF_USE_HICON_MAIN;
   }
   else switch ( uType & MB_ICONMASK )
   {
      case MB_ICONHAND:        cfg.pszMainIcon = TD_ERROR_ICON;       break;
      case MB_ICONEXCLAMATION: cfg.pszMainIcon = TD_WARNING_ICON;     break;
      case MB_ICONASTERISK:    cfg.pszMainIcon = TD_INFORMATION_ICON; break;
      case MB_ICONQUESTION:    /* TaskDialog has no question icon; shared icon, never destroyed */
         cfg.hMainIcon = LoadIcon( NULL, IDI_QUESTION );
         if ( cfg.hMainIcon != NULL )
            dwFlags |= TDF_USE_HICON_MAIN;
         break;
   }

   /* first line = main instruction (bold), the rest = content */
   for ( p = pwText; *p && *p != L'\r' && *p != L'\n'; p++ )
      ;
   if ( *p )
   {
      SIZE_T nLen = ( SIZE_T ) ( p - pwText );
      pwMain = ( WCHAR * ) hb_xgrab( ( nLen + 1 ) * sizeof( WCHAR ) );
      memcpy( pwMain, pwText, nLen * sizeof( WCHAR ) );
      pwMain [ nLen ] = 0;
      while ( *p == L'\r' || *p == L'\n' )
         p++;
      cfg.pszMainInstruction = pwMain;
      cfg.pszContent         = *p ? p : NULL;
   }
   else
      cfg.pszMainInstruction = pwText;

   data.dwMillis = ( dwMillis == 0 ) ? HMG_NO_TIMEOUT : dwMillis;
   data.lTopMost = ( uType & ( MB_SYSTEMMODAL | MB_TOPMOST ) ) != 0;
   if ( data.dwMillis != HMG_NO_TIMEOUT )
      dwFlags |= TDF_CALLBACK_TIMER;

   cfg.dwFlags        = ( TASKDIALOG_FLAGS ) dwFlags;
   cfg.pfCallback     = HMG_MsgDialogCallback;
   cfg.lpCallbackData = ( LONG_PTR ) &data;

   hr = pfn( &cfg, &nButton, NULL, NULL );

   if ( pwMain != NULL )
      hb_xfree( pwMain );

   if ( FAILED( hr ) )
      return -1;
   if ( data.lTimedOut )
      return ID_TIMEDOUT;
   return ( nButton == 0 ) ? IDCANCEL : nButton;   /* closed with X / Esc */
}

/* One entry for every message box: TaskDialog when SET MSGBOXMODERN is ON, else MessageBox(). */
static int HMG_MsgShow ( HWND hWnd, LPCTSTR pcText, LPCTSTR pcCaption, UINT uType, DWORD dwMillis )
{
   int nRet = HMG_MsgDialog( hWnd, pcText, pcCaption, uType, dwMillis, NULL );

   if ( nRet >= 0 )
      return nRet;
   if ( dwMillis == HMG_NO_TIMEOUT )
      return MessageBox( hWnd, pcText, pcCaption, uType );
   return MessageBoxTimeout( hWnd, pcText, pcCaption, uType, MAKELANGID( LANG_NEUTRAL, SUBLANG_NEUTRAL ), dwMillis );
}

//       HMG_SetMsgBoxModern( [ lOn ] ) --> lPrevious
HB_FUNC( HMG_SETMSGBOXMODERN )
{
   hb_retl( s_lMsgBoxModern != 0 );
   if ( HB_ISLOG( 1 ) )
      s_lMsgBoxModern = hb_parl( 1 ) ? 1 : 0;
}

HB_FUNC( C_MSGBOX )
{
   HMG_MsgShow( GetActiveWindow(), HMG_parc( 1 ), HMG_parc( 2 ), MB_OK | MB_SYSTEMMODAL, HMG_NO_TIMEOUT );
}

HB_FUNC( C_MSGINFO )
{
   HMG_MsgShow( GetActiveWindow(), HMG_parc( 1 ), HMG_parc( 2 ), MB_OK | MB_ICONINFORMATION | MB_SYSTEMMODAL, HMG_NO_TIMEOUT );
}

HB_FUNC( C_MSGSTOP )
{
   HMG_MsgShow( GetActiveWindow(), HMG_parc( 1 ), HMG_parc( 2 ), MB_OK | MB_ICONSTOP | MB_SYSTEMMODAL, HMG_NO_TIMEOUT );
}

HB_FUNC( C_MSGEXCLAMATION )
{
   HMG_MsgShow( GetActiveWindow(), HMG_parc( 1 ), HMG_parc( 2 ), MB_ICONEXCLAMATION | MB_OK | MB_SYSTEMMODAL, HMG_NO_TIMEOUT );
}

HB_FUNC( C_MSGRETRYCANCEL )
{
   hb_retni( HMG_MsgShow( GetActiveWindow(), HMG_parc( 1 ), HMG_parc( 2 ), MB_RETRYCANCEL | MB_ICONQUESTION | MB_SYSTEMMODAL, HMG_NO_TIMEOUT ) );
}

HB_FUNC( C_MSGOKCANCEL )
{
   hb_retni( HMG_MsgShow( GetActiveWindow(), HMG_parc( 1 ), HMG_parc( 2 ), MB_OKCANCEL | MB_ICONQUESTION | MB_SYSTEMMODAL, HMG_NO_TIMEOUT ) );
}

HB_FUNC( C_MSGYESNO )
{
   hb_retni( HMG_MsgShow( GetActiveWindow(), HMG_parc( 1 ), HMG_parc( 2 ), MB_YESNO | MB_ICONQUESTION | MB_SYSTEMMODAL, HMG_NO_TIMEOUT ) );
}

HB_FUNC( C_MSGYESNO_ID )
{
   hb_retni( HMG_MsgShow( GetActiveWindow(), HMG_parc( 1 ), HMG_parc( 2 ), MB_YESNO | MB_ICONQUESTION | MB_SYSTEMMODAL | MB_DEFBUTTON2, HMG_NO_TIMEOUT ) );
}



// by Dr. Claudio Soto (October 2013)


int WINAPI MessageBoxTimeout (HWND hWnd, LPCTSTR lpText, LPCTSTR lpCaption, UINT uType, WORD wLanguageId, DWORD dwMilliseconds) 
{
   typedef BOOL (WINAPI *PMessageBoxTimeout)(HWND,LPCTSTR,LPCTSTR,UINT,WORD,DWORD);
_THREAD_LOCK();
   static PMessageBoxTimeout pMessageBoxTimeout = NULL;
   if (pMessageBoxTimeout == NULL) 
   {
      HMODULE hLib = HMG_LoadSystemLibrary (_TEXT("User32.dll"));
      #ifdef UNICODE
         pMessageBoxTimeout = (PMessageBoxTimeout)GetProcAddress(hLib, "MessageBoxTimeoutW");
      #else
         pMessageBoxTimeout = (PMessageBoxTimeout)GetProcAddress(hLib, "MessageBoxTimeoutA");
      #endif
   }
_THREAD_UNLOCK();
   if(pMessageBoxTimeout == NULL)
      return FALSE;
   return pMessageBoxTimeout(hWnd, lpText, lpCaption, uType, wLanguageId, dwMilliseconds);
}


//       HMG_MessageBoxTimeout (cText, cCaption, nTypeIconButton, nMilliseconds) ---> Return nRetValue
HB_FUNC (HMG_MESSAGEBOXTIMEOUT)
{
   HWND  hWnd           = GetActiveWindow();
   TCHAR *lpText        = (TCHAR *) HMG_parc (1);
   TCHAR *lpCaption     = (TCHAR *) HMG_parc (2);
   UINT  uType          = HB_ISNIL(3) ? MB_OK : (UINT) hb_parnl (3);
   WORD  wLanguageId    = MAKELANGID (LANG_NEUTRAL, SUBLANG_NEUTRAL);
   DWORD dwMilliseconds = HB_ISNIL(4) ? (DWORD)0xFFFFFFFF  : (DWORD) hb_parnl (4);
   int iRet = HMG_MsgDialog (hWnd, lpText, lpCaption, uType, dwMilliseconds, NULL);
   if (iRet < 0)
      iRet = MessageBoxTimeout (hWnd, lpText, lpCaption, uType, wLanguageId, dwMilliseconds);
   hb_retni ((int) iRet);
}


//       MessageBoxIndirect ( [hWnd], cText, [cCaption], [nStyle], [cResourceIcon] )
HB_FUNC( MESSAGEBOXINDIRECT )
{
   MSGBOXPARAMS mbp;

   mbp.cbSize             = sizeof (MSGBOXPARAMS);
   mbp.hwndOwner          = HB_ISNIL (1) ? GetActiveWindow() : (HWND) HMG_parnl (1);
   mbp.hInstance          = GetModuleHandle (NULL);
   mbp.lpszText           = HMG_parc (2);
   mbp.lpszCaption        = HB_ISCHAR (3) ? HMG_parc (3) : _TEXT("");
   mbp.dwStyle            = (DWORD) (hb_parni (4) | (HB_ISCHAR (5) ? MB_USERICON : 0));
   mbp.lpszIcon           = HMG_parc (5);
   mbp.dwContextHelpId    = 0;
   mbp.lpfnMsgBoxCallback = NULL;
   mbp.dwLanguageId       = MAKELANGID (LANG_NEUTRAL, SUBLANG_NEUTRAL);

   {
      HICON hIcon = NULL;
      int   nRet;
      if ( HB_ISCHAR (5) )   /* shared resource icon: not destroyed */
         hIcon = (HICON) LoadImage (mbp.hInstance, mbp.lpszIcon, IMAGE_ICON, GetSystemMetrics (SM_CXICON), GetSystemMetrics (SM_CYICON), LR_SHARED);
      nRet = HMG_MsgDialog (mbp.hwndOwner, mbp.lpszText, mbp.lpszCaption, (UINT) mbp.dwStyle, HMG_NO_TIMEOUT, hIcon);
      hb_retni (nRet >= 0 ? nRet : (INT) MessageBoxIndirect (&mbp));
   }
}
