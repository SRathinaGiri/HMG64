/*----------------------------------------------------------------------------
 HMG5 - WebView2 control (Phase 4, PHASE4-DESIGN.md section 1)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 Plain C against the WebView2 COM interfaces (WebView2.h, Microsoft WebView2
 SDK, BSD-3-Clause, see INCLUDE/WebView2-LICENSE.txt). No C++ runtime needed.

 Model:
   - the control's HMG handle is a host child window of class "HMG_WebView";
   - the WebView2 environment and controller are created asynchronously;
   - every WebView2 callback only copies its data and posts WM_HMG_WVEVENT to
     the host; the host's window procedure calls _HMG_WEBVIEWEVENT() in PRG.
     COM callbacks never run Harbour code.
---------------------------------------------------------------------------*/

#define COBJMACROS
#define CINTERFACE

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#include <windows.h>
#include <objbase.h>
#include "hmg_webview2.h"

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbapistr.h"
#include "hbapicdp.h"
#include "hbvm.h"

#define WM_HMG_WVEVENT     ( WM_APP + 0x2A51 )
#define HMG_WV_CLASS       L"HMG_WebView"

/* The HTML property is served from memory at this private origin (WebResourceRequested),
   not with NavigateToString: NavigateToString pages report "about:blank" as their source,
   which any data: or blank page reports too, so it cannot be told apart from foreign
   content. No remote page can have this origin (".example" never resolves, and every
   request to it is answered here). Keep in sync with h_webview.prg. */
#define HMG_WV_HTMLHOST    L"https://html.hmg.example/"

/* Library files (scripts, styles) served from memory to every WebView at
   HMG_WV_HTMLHOST "lib/<name>": e.g. Apache ECharts for the CHART control
   (c_echarts.c). Registered once per program, never freed; the data is not copied. */
#define HMG_WV_LIBMAX      16
typedef struct
{
   WCHAR          name[ 64 ];
   const void *   data;
   size_t         len;
   WCHAR          mime[ 64 ];
} WVLIB;
static WVLIB s_aLib[ HMG_WV_LIBMAX ];
static int   s_nLib = 0;

/* name: "echarts.min.js"; data stays valid for the life of the program */
BOOL HMG_WebViewAddLibrary( const WCHAR * name, const void * data, size_t len, const WCHAR * mime )
{
   int i;
   for( i = 0; i < s_nLib; i++ )
      if( _wcsicmp( s_aLib[ i ].name, name ) == 0 )
         return TRUE;                          /* already there */
   if( s_nLib >= HMG_WV_LIBMAX || wcslen( name ) >= 64 || wcslen( mime ) >= 64 )
      return FALSE;
   wcscpy( s_aLib[ s_nLib ].name, name );
   wcscpy( s_aLib[ s_nLib ].mime, mime );
   s_aLib[ s_nLib ].data = data;
   s_aLib[ s_nLib ].len  = len;
   s_nLib++;
   return TRUE;
}

static const WVLIB * wv_findLib( LPCWSTR uri )
{
   static const WCHAR szLib[] = HMG_WV_HTMLHOST L"lib/";
   size_t n = HB_SIZEOFARRAY( szLib ) - 1;
   int i;
   if( _wcsnicmp( uri, szLib, n ) != 0 )
      return NULL;
   for( i = 0; i < s_nLib; i++ )
   {
      size_t k = wcslen( s_aLib[ i ].name );
      if( _wcsnicmp( uri + n, s_aLib[ i ].name, k ) == 0 && ( uri[ n + k ] == 0 || uri[ n + k ] == L'?' ) )
         return &s_aLib[ i ];
   }
   return NULL;
}

static IStream * wv_memStream( const void * data, size_t len )
{
   IStream * stm = NULL;
   HGLOBAL hg = GlobalAlloc( GMEM_MOVEABLE, len ? len : 1 );
   if( hg )
   {
      void * p = GlobalLock( hg );
      if( p )
      {
         memcpy( p, data, len );
         GlobalUnlock( hg );
      }
      if( FAILED( CreateStreamOnHGlobal( hg, TRUE, &stm ) ) )
      {
         GlobalFree( hg );
         stm = NULL;
      }
      else
      {
         ULARGE_INTEGER sz;
         sz.QuadPart = len;
         IStream_SetSize( stm, sz );
      }
   }
   return stm;
}

/* event kinds, keep in sync with h_webview.prg */
#define WVE_READY          1
#define WVE_ERROR          2
#define WVE_NAVIGATED      3
#define WVE_MESSAGE        4
#define WVE_TITLE          5
#define WVE_SCRIPTRESULT   6

/* JavaScript injected into every document: the hmg.* bridge (section 1.4) */
static const WCHAR s_szShim[] =
   L"(function(){"
   L"if(window.hmg)return;"
   L"var w=window.chrome&&window.chrome.webview;if(!w)return;"
   L"var seq=0,pend={},subs=[];"
   L"function send(o){w.postMessage(JSON.stringify(o));}"
   L"var hmg={"
   L"call:function(name){var a=Array.prototype.slice.call(arguments,1);"
   L"return new Promise(function(res,rej){var id=++seq;pend[id]={res:res,rej:rej};"
   L"send({hmg:1,id:id,fn:String(name),args:a});});},"
   L"post:function(v){send({hmg:2,data:v});},"
   L"on:function(f){if(typeof f==='function')subs.push(f);},"
   L"__settle:function(id,ok,v){var p=pend[id];if(!p)return;delete pend[id];"
   L"if(ok)p.res(v);else p.rej(new Error(String(v)));}"
   L"};"
   L"w.addEventListener('message',function(e){for(var i=0;i<subs.length;i++){try{subs[i](e.data);}catch(x){}}});"
   L"Object.defineProperty(window,'hmg',{value:Object.freeze(hmg),writable:false,configurable:false});"
   L"})();";

/* ------------------------------------------------------------------------ */
/* Per-control state                                                         */
/* ------------------------------------------------------------------------ */

typedef struct _WVCTL
{
   LONG                       ref;        /* host window + pending COM callbacks */
   HWND                       hHost;
   BOOL                       closed;
   BOOL                       devTools;
   BOOL                       inPrivate;
   ICoreWebView2Environment * env;
   ICoreWebView2Controller *  ctrl;
   ICoreWebView2 *            wv;
   EventRegistrationToken     tokMsg;
   EventRegistrationToken     tokNav;
   EventRegistrationToken     tokTitle;
   EventRegistrationToken     tokRes;
   BOOL                       hasTokens;
   char *                     html;       /* UTF-8 page served at HMG_WV_HTMLHOST */
   HB_SIZE                    htmlLen;
   unsigned                   htmlSeq;
} WVCTL;

typedef struct
{
   int     kind;
   int     num;
   WCHAR * text;
   WCHAR * extra;
} WVEVT;

static void wv_ctlAddRef( WVCTL * c ) { c->ref++; }

static void wv_ctlRelease( WVCTL * c )
{
   if( --c->ref == 0 )
   {
      if( c->html )
         hb_xfree( c->html );
      hb_xfree( c );
   }
}

static WCHAR * wv_wcsdup( LPCWSTR s )
{
   WCHAR * r;
   size_t  n;
   if( s == NULL )
      return NULL;
   n = wcslen( s ) + 1;
   r = ( WCHAR * ) hb_xgrab( n * sizeof( WCHAR ) );
   memcpy( r, s, n * sizeof( WCHAR ) );
   return r;
}

/* Post an event to the host window (copies the strings). */
static void wv_post( WVCTL * c, int kind, int num, LPCWSTR text, LPCWSTR extra )
{
   WVEVT * e;
   if( c->closed || c->hHost == NULL )
      return;
   e = ( WVEVT * ) hb_xgrab( sizeof( WVEVT ) );
   e->kind  = kind;
   e->num   = num;
   e->text  = wv_wcsdup( text );
   e->extra = wv_wcsdup( extra );
   if( ! PostMessageW( c->hHost, WM_HMG_WVEVENT, 0, ( LPARAM ) e ) )
   {
      if( e->text )  hb_xfree( e->text );
      if( e->extra ) hb_xfree( e->extra );
      hb_xfree( e );
   }
}

static void wv_postError( WVCTL * c, LPCWSTR what, HRESULT hr )
{
   WCHAR buf[ 256 ];
   _snwprintf( buf, HB_SIZEOFARRAY( buf ) - 1, L"%ls (HRESULT 0x%08lX)", what, ( unsigned long ) hr );
   buf[ HB_SIZEOFARRAY( buf ) - 1 ] = 0;
   wv_post( c, WVE_ERROR, ( int ) hr, buf, NULL );
}

static void wv_freeEvent( WVEVT * e )
{
   if( e->text )  hb_xfree( e->text );
   if( e->extra ) hb_xfree( e->extra );
   hb_xfree( e );
}

/* ------------------------------------------------------------------------ */
/* Generic COM handler object                                                */
/*                                                                           */
/* All WebView2 handler interfaces are IUnknown + one Invoke method, so one  */
/* struct serves them all; only the vtable (Invoke signature) differs.       */
/* ------------------------------------------------------------------------ */

typedef struct
{
   void *      lpVtbl;
   LONG        ref;
   const IID * iid;
   WVCTL *     ctl;
   int         id;        /* ExecuteScript callback id */
} WVHANDLER;

static HRESULT STDMETHODCALLTYPE h_QueryInterface( void * This, REFIID riid, void ** ppv )
{
   WVHANDLER * h = ( WVHANDLER * ) This;
   if( ppv == NULL )
      return E_POINTER;
   if( IsEqualIID( riid, &IID_IUnknown ) || IsEqualIID( riid, h->iid ) )
   {
      *ppv = This;
      InterlockedIncrement( &h->ref );
      return S_OK;
   }
   *ppv = NULL;
   return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE h_AddRef( void * This )
{
   return ( ULONG ) InterlockedIncrement( &( ( WVHANDLER * ) This )->ref );
}

static ULONG STDMETHODCALLTYPE h_Release( void * This )
{
   WVHANDLER * h = ( WVHANDLER * ) This;
   LONG        r = InterlockedDecrement( &h->ref );
   if( r == 0 )
   {
      if( h->ctl )
         wv_ctlRelease( h->ctl );
      hb_xfree( h );
   }
   return ( ULONG ) r;
}

static WVHANDLER * wv_newHandler( void * vtbl, const IID * iid, WVCTL * c, int id )
{
   WVHANDLER * h = ( WVHANDLER * ) hb_xgrab( sizeof( WVHANDLER ) );
   h->lpVtbl = vtbl;
   h->ref    = 1;
   h->iid    = iid;
   h->ctl    = c;
   h->id     = id;
   wv_ctlAddRef( c );
   return h;
}

/* forward */
static void wv_onControllerReady( WVCTL * c, ICoreWebView2Controller * ctrl );

/* --- Environment created ------------------------------------------------ */

static HRESULT STDMETHODCALLTYPE envDone_Invoke( ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler * This,
                                                 HRESULT hr, ICoreWebView2Environment * env );
static ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandlerVtbl s_envDoneVtbl = {
   ( void * ) h_QueryInterface, ( void * ) h_AddRef, ( void * ) h_Release, envDone_Invoke };

static HRESULT STDMETHODCALLTYPE ctrlDone_Invoke( ICoreWebView2CreateCoreWebView2ControllerCompletedHandler * This,
                                                  HRESULT hr, ICoreWebView2Controller * ctrl );
static ICoreWebView2CreateCoreWebView2ControllerCompletedHandlerVtbl s_ctrlDoneVtbl = {
   ( void * ) h_QueryInterface, ( void * ) h_AddRef, ( void * ) h_Release, ctrlDone_Invoke };

static HRESULT STDMETHODCALLTYPE envDone_Invoke( ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler * This,
                                                 HRESULT hr, ICoreWebView2Environment * env )
{
   WVCTL * c = ( ( WVHANDLER * ) This )->ctl;

   if( c->closed )
      return S_OK;
   if( FAILED( hr ) || env == NULL )
   {
      wv_postError( c, L"WebView2 environment could not be created", hr );
      return S_OK;
   }
   c->env = env;
   ICoreWebView2Environment_AddRef( env );

   {
      WVHANDLER * h = wv_newHandler( &s_ctrlDoneVtbl, &IID_ICoreWebView2CreateCoreWebView2ControllerCompletedHandler, c, 0 );
      HRESULT     hr2;

      if( c->inPrivate )
      {
         ICoreWebView2Environment10 *   env10 = NULL;
         ICoreWebView2ControllerOptions * opt  = NULL;

         hr2 = ICoreWebView2Environment_QueryInterface( env, &IID_ICoreWebView2Environment10, ( void ** ) &env10 );
         if( SUCCEEDED( hr2 ) && env10 )
         {
            hr2 = ICoreWebView2Environment10_CreateCoreWebView2ControllerOptions( env10, &opt );
            if( SUCCEEDED( hr2 ) && opt )
            {
               ICoreWebView2ControllerOptions_put_IsInPrivateModeEnabled( opt, TRUE );
               hr2 = ICoreWebView2Environment10_CreateCoreWebView2ControllerWithOptions( env10, c->hHost, opt,
                        ( ICoreWebView2CreateCoreWebView2ControllerCompletedHandler * ) h );
               ICoreWebView2ControllerOptions_Release( opt );
            }
            ICoreWebView2Environment10_Release( env10 );
         }
         if( FAILED( hr2 ) )
            wv_postError( c, L"PRIVATE needs a newer WebView2 runtime (101 or later)", hr2 );
      }
      else
      {
         hr2 = ICoreWebView2Environment_CreateCoreWebView2Controller( env, c->hHost,
                  ( ICoreWebView2CreateCoreWebView2ControllerCompletedHandler * ) h );
         if( FAILED( hr2 ) )
            wv_postError( c, L"WebView2 controller could not be created", hr2 );
      }
      h_Release( h );
   }
   return S_OK;
}

static HRESULT STDMETHODCALLTYPE ctrlDone_Invoke( ICoreWebView2CreateCoreWebView2ControllerCompletedHandler * This,
                                                  HRESULT hr, ICoreWebView2Controller * ctrl )
{
   WVCTL * c = ( ( WVHANDLER * ) This )->ctl;

   if( c->closed )
   {
      if( ctrl )
         ICoreWebView2Controller_Close( ctrl );
      return S_OK;
   }
   if( FAILED( hr ) || ctrl == NULL )
   {
      wv_postError( c, L"WebView2 controller could not be created", hr );
      return S_OK;
   }
   wv_onControllerReady( c, ctrl );
   return S_OK;
}

/* --- Web message from the page ----------------------------------------- */

static HRESULT STDMETHODCALLTYPE msg_Invoke( ICoreWebView2WebMessageReceivedEventHandler * This,
                                             ICoreWebView2 * sender, ICoreWebView2WebMessageReceivedEventArgs * args )
{
   WVCTL * c      = ( ( WVHANDLER * ) This )->ctl;
   LPWSTR  source = NULL;
   LPWSTR  text   = NULL;
   int     isStr  = 1;

   HB_SYMBOL_UNUSED( sender );
   if( c->closed || args == NULL )
      return S_OK;

   ICoreWebView2WebMessageReceivedEventArgs_get_Source( args, &source );
   if( FAILED( ICoreWebView2WebMessageReceivedEventArgs_TryGetWebMessageAsString( args, &text ) ) || text == NULL )
   {
      /* not a string: pass the JSON form */
      isStr = 0;
      ICoreWebView2WebMessageReceivedEventArgs_get_WebMessageAsJson( args, &text );
   }
   wv_post( c, WVE_MESSAGE, isStr, text ? text : L"", source ? source : L"" );
   if( text )   CoTaskMemFree( text );
   if( source ) CoTaskMemFree( source );
   return S_OK;
}
static ICoreWebView2WebMessageReceivedEventHandlerVtbl s_msgVtbl = {
   ( void * ) h_QueryInterface, ( void * ) h_AddRef, ( void * ) h_Release, msg_Invoke };

/* --- Navigation completed ---------------------------------------------- */

static HRESULT STDMETHODCALLTYPE nav_Invoke( ICoreWebView2NavigationCompletedEventHandler * This,
                                             ICoreWebView2 * sender, ICoreWebView2NavigationCompletedEventArgs * args )
{
   WVCTL * c   = ( ( WVHANDLER * ) This )->ctl;
   BOOL    ok  = FALSE;
   LPWSTR  uri = NULL;
   COREWEBVIEW2_WEB_ERROR_STATUS st = COREWEBVIEW2_WEB_ERROR_STATUS_UNKNOWN;

   if( c->closed )
      return S_OK;
   if( args )
   {
      ICoreWebView2NavigationCompletedEventArgs_get_IsSuccess( args, &ok );
      ICoreWebView2NavigationCompletedEventArgs_get_WebErrorStatus( args, &st );
   }
   if( sender )
      ICoreWebView2_get_Source( sender, &uri );
   wv_post( c, WVE_NAVIGATED, ok ? 0 : ( int ) st + 1, uri ? uri : L"", NULL );
   if( uri )
      CoTaskMemFree( uri );
   return S_OK;
}
static ICoreWebView2NavigationCompletedEventHandlerVtbl s_navVtbl = {
   ( void * ) h_QueryInterface, ( void * ) h_AddRef, ( void * ) h_Release, nav_Invoke };

/* --- Document title changed -------------------------------------------- */

static HRESULT STDMETHODCALLTYPE title_Invoke( ICoreWebView2DocumentTitleChangedEventHandler * This,
                                               ICoreWebView2 * sender, IUnknown * args )
{
   WVCTL * c     = ( ( WVHANDLER * ) This )->ctl;
   LPWSTR  title = NULL;

   HB_SYMBOL_UNUSED( args );
   if( c->closed || sender == NULL )
      return S_OK;
   ICoreWebView2_get_DocumentTitle( sender, &title );
   wv_post( c, WVE_TITLE, 0, title ? title : L"", NULL );
   if( title )
      CoTaskMemFree( title );
   return S_OK;
}
static ICoreWebView2DocumentTitleChangedEventHandlerVtbl s_titleVtbl = {
   ( void * ) h_QueryInterface, ( void * ) h_AddRef, ( void * ) h_Release, title_Invoke };

/* --- Requests to HMG_WV_HTMLHOST: serve the HTML property from memory -- */

static HRESULT STDMETHODCALLTYPE res_Invoke( ICoreWebView2WebResourceRequestedEventHandler * This,
                                             ICoreWebView2 * sender, ICoreWebView2WebResourceRequestedEventArgs * args )
{
   static const WCHAR szPage[] = HMG_WV_HTMLHOST L"page";
   WVCTL *                            c    = ( ( WVHANDLER * ) This )->ctl;
   ICoreWebView2WebResourceRequest *  req  = NULL;
   ICoreWebView2WebResourceResponse * resp = NULL;
   IStream *                          stm  = NULL;
   LPWSTR                             uri  = NULL;
   const WVLIB *                      lib;

   HB_SYMBOL_UNUSED( sender );
   if( c->closed || args == NULL || c->env == NULL )
      return S_OK;

   if( SUCCEEDED( ICoreWebView2WebResourceRequestedEventArgs_get_Request( args, &req ) ) && req )
   {
      ICoreWebView2WebResourceRequest_get_Uri( req, &uri );
      ICoreWebView2WebResourceRequest_Release( req );
   }

   if( uri && ( lib = wv_findLib( uri ) ) != NULL )
   {
      WCHAR hdr[ 160 ];
      stm = wv_memStream( lib->data, lib->len );
      _snwprintf( hdr, HB_SIZEOFARRAY( hdr ), L"Content-Type: %ls\r\nCache-Control: max-age=86400", lib->mime );
      hdr[ HB_SIZEOFARRAY( hdr ) - 1 ] = 0;
      if( stm )
         ICoreWebView2Environment_CreateWebResourceResponse( c->env, stm, 200, L"OK", hdr, &resp );
      else
         ICoreWebView2Environment_CreateWebResourceResponse( c->env, NULL, 404, L"Not Found", L"", &resp );
      if( resp )
      {
         ICoreWebView2WebResourceRequestedEventArgs_put_Response( args, resp );
         ICoreWebView2WebResourceResponse_Release( resp );
      }
      if( stm )
         IStream_Release( stm );
      CoTaskMemFree( uri );
      return S_OK;
   }

   if( uri && c->html && _wcsnicmp( uri, szPage, HB_SIZEOFARRAY( szPage ) - 1 ) == 0 )
   {
      HGLOBAL hg = GlobalAlloc( GMEM_MOVEABLE, c->htmlLen ? c->htmlLen : 1 );
      if( hg )
      {
         void * p = GlobalLock( hg );
         if( p )
         {
            memcpy( p, c->html, c->htmlLen );
            GlobalUnlock( hg );
         }
         if( FAILED( CreateStreamOnHGlobal( hg, TRUE, &stm ) ) )
         {
            GlobalFree( hg );
            stm = NULL;
         }
         else
         {
            ULARGE_INTEGER sz;
            sz.QuadPart = c->htmlLen;
            IStream_SetSize( stm, sz );
         }
      }
   }
   if( stm )
      ICoreWebView2Environment_CreateWebResourceResponse( c->env, stm, 200, L"OK",
         L"Content-Type: text/html; charset=utf-8\r\nCache-Control: no-store", &resp );
   else
      ICoreWebView2Environment_CreateWebResourceResponse( c->env, NULL, 404, L"Not Found", L"", &resp );
   if( resp )
   {
      ICoreWebView2WebResourceRequestedEventArgs_put_Response( args, resp );
      ICoreWebView2WebResourceResponse_Release( resp );
   }
   if( stm )
      IStream_Release( stm );
   if( uri )
      CoTaskMemFree( uri );
   return S_OK;
}
static ICoreWebView2WebResourceRequestedEventHandlerVtbl s_resVtbl = {
   ( void * ) h_QueryInterface, ( void * ) h_AddRef, ( void * ) h_Release, res_Invoke };

/* --- ExecuteScript result ---------------------------------------------- */

static HRESULT STDMETHODCALLTYPE exec_Invoke( ICoreWebView2ExecuteScriptCompletedHandler * This,
                                              HRESULT hr, LPCWSTR json )
{
   WVHANDLER * h = ( WVHANDLER * ) This;
   if( h->ctl->closed || h->id == 0 )
      return S_OK;
   if( FAILED( hr ) )
      wv_post( h->ctl, WVE_SCRIPTRESULT, h->id, L"", L"error" );
   else
      wv_post( h->ctl, WVE_SCRIPTRESULT, h->id, json ? json : L"null", NULL );
   return S_OK;
}
static ICoreWebView2ExecuteScriptCompletedHandlerVtbl s_execVtbl = {
   ( void * ) h_QueryInterface, ( void * ) h_AddRef, ( void * ) h_Release, exec_Invoke };

/* ------------------------------------------------------------------------ */
/* Controller ready: settings, bridge script, events, bounds                 */
/* ------------------------------------------------------------------------ */

static void wv_updateBounds( WVCTL * c )
{
   RECT rc;
   if( c->ctrl == NULL )
      return;
   GetClientRect( c->hHost, &rc );
   ICoreWebView2Controller_put_Bounds( c->ctrl, rc );
}

static void wv_onControllerReady( WVCTL * c, ICoreWebView2Controller * ctrl )
{
   ICoreWebView2Settings * set = NULL;
   WVHANDLER *             h;
   HRESULT                 hr;

   c->ctrl = ctrl;
   ICoreWebView2Controller_AddRef( ctrl );

   hr = ICoreWebView2Controller_get_CoreWebView2( ctrl, &c->wv );
   if( FAILED( hr ) || c->wv == NULL )
   {
      c->wv = NULL;
      wv_postError( c, L"WebView2 core could not be obtained", hr );
      return;
   }

   if( SUCCEEDED( ICoreWebView2_get_Settings( c->wv, &set ) ) && set )
   {
      ICoreWebView2Settings_put_IsScriptEnabled( set, TRUE );
      ICoreWebView2Settings_put_IsWebMessageEnabled( set, TRUE );
      ICoreWebView2Settings_put_AreHostObjectsAllowed( set, FALSE );     /* bridge is hmg.call only */
      ICoreWebView2Settings_put_AreDevToolsEnabled( set, c->devTools );
      ICoreWebView2Settings_put_AreDefaultContextMenusEnabled( set, c->devTools );
      ICoreWebView2Settings_put_IsStatusBarEnabled( set, FALSE );
      ICoreWebView2Settings_Release( set );
   }

   ICoreWebView2_AddScriptToExecuteOnDocumentCreated( c->wv, s_szShim, NULL );

   h = wv_newHandler( &s_msgVtbl, &IID_ICoreWebView2WebMessageReceivedEventHandler, c, 0 );
   ICoreWebView2_add_WebMessageReceived( c->wv, ( ICoreWebView2WebMessageReceivedEventHandler * ) h, &c->tokMsg );
   h_Release( h );

   h = wv_newHandler( &s_navVtbl, &IID_ICoreWebView2NavigationCompletedEventHandler, c, 0 );
   ICoreWebView2_add_NavigationCompleted( c->wv, ( ICoreWebView2NavigationCompletedEventHandler * ) h, &c->tokNav );
   h_Release( h );

   h = wv_newHandler( &s_titleVtbl, &IID_ICoreWebView2DocumentTitleChangedEventHandler, c, 0 );
   ICoreWebView2_add_DocumentTitleChanged( c->wv, ( ICoreWebView2DocumentTitleChangedEventHandler * ) h, &c->tokTitle );
   h_Release( h );

   ICoreWebView2_AddWebResourceRequestedFilter( c->wv, HMG_WV_HTMLHOST L"*", COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL );
   h = wv_newHandler( &s_resVtbl, &IID_ICoreWebView2WebResourceRequestedEventHandler, c, 0 );
   ICoreWebView2_add_WebResourceRequested( c->wv, ( ICoreWebView2WebResourceRequestedEventHandler * ) h, &c->tokRes );
   h_Release( h );

   c->hasTokens = TRUE;

   wv_updateBounds( c );
   ICoreWebView2Controller_put_IsVisible( ctrl, IsWindowVisible( c->hHost ) );

   wv_post( c, WVE_READY, 0, NULL, NULL );
}

/* Close the browser and drop every COM reference. Safe to call twice. */
static void wv_close( WVCTL * c )
{
   MSG msg;

   if( c->closed )
      return;
   c->closed = TRUE;

   if( c->wv )
   {
      if( c->hasTokens )
      {
         ICoreWebView2_remove_WebMessageReceived( c->wv, c->tokMsg );
         ICoreWebView2_remove_NavigationCompleted( c->wv, c->tokNav );
         ICoreWebView2_remove_DocumentTitleChanged( c->wv, c->tokTitle );
         ICoreWebView2_remove_WebResourceRequested( c->wv, c->tokRes );
      }
      ICoreWebView2_Release( c->wv );
      c->wv = NULL;
   }
   if( c->ctrl )
   {
      ICoreWebView2Controller_Close( c->ctrl );
      ICoreWebView2Controller_Release( c->ctrl );
      c->ctrl = NULL;
   }
   if( c->env )
   {
      ICoreWebView2Environment_Release( c->env );
      c->env = NULL;
   }

   /* events already posted to this host are never delivered now: free them */
   while( PeekMessageW( &msg, c->hHost, WM_HMG_WVEVENT, WM_HMG_WVEVENT, PM_REMOVE ) )
      wv_freeEvent( ( WVEVT * ) msg.lParam );
}

/* ------------------------------------------------------------------------ */
/* Runtime loader (section 1.2)                                              */
/* ------------------------------------------------------------------------ */

typedef HRESULT ( STDMETHODCALLTYPE * PFN_CREATEENV )( PCWSTR, PCWSTR, ICoreWebView2EnvironmentOptions *,
                                                       ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler * );
typedef HRESULT ( STDMETHODCALLTYPE * PFN_CREATEENVINTERNAL )( BOOL, int, PCWSTR, IUnknown *,
                                                               ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler * );
typedef HRESULT ( STDMETHODCALLTYPE * PFN_GETVERSION )( PCWSTR, LPWSTR * );

static const WCHAR s_szRuntimeGuid[] = L"{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}";

static int                   s_loaderState = 0;   /* 0 = not tried, 1 = loaded, -1 = not found */
static PFN_CREATEENV         s_pCreateEnv  = NULL;
static PFN_CREATEENVINTERNAL s_pCreateInt  = NULL;
static PFN_GETVERSION        s_pGetVersion = NULL;
static WCHAR                 s_szVersion[ 64 ];

static BOOL wv_regString( HKEY root, LPCWSTR subKey, LPCWSTR value, WCHAR * out, DWORD cch )
{
   HKEY  hKey;
   DWORD type, cb = ( cch - 1 ) * sizeof( WCHAR );
   BOOL  ok = FALSE;

   if( RegOpenKeyExW( root, subKey, 0, KEY_READ | KEY_WOW64_32KEY, &hKey ) != ERROR_SUCCESS )
      return FALSE;
   if( RegQueryValueExW( hKey, value, NULL, &type, ( LPBYTE ) out, &cb ) == ERROR_SUCCESS && type == REG_SZ && cb > 0 )
   {
      out[ cb / sizeof( WCHAR ) ] = 0;
      ok = out[ 0 ] != 0;
   }
   RegCloseKey( hKey );
   return ok;
}

/* Folder of the installed Evergreen runtime version, e.g.
   C:\Program Files (x86)\Microsoft\EdgeWebView\Application\157.0.4341.46 */
static BOOL wv_runtimeFolder( WCHAR * out, DWORD cch )
{
   static const HKEY roots[ 2 ] = { HKEY_LOCAL_MACHINE, HKEY_CURRENT_USER };
   WCHAR key[ 160 ];
   int   i;

   for( i = 0; i < 2; i++ )
   {
      _snwprintf( key, HB_SIZEOFARRAY( key ), L"SOFTWARE\\Microsoft\\EdgeUpdate\\ClientState\\%ls", s_szRuntimeGuid );
      if( wv_regString( roots[ i ], key, L"EBWebView", out, cch ) )
         return TRUE;
   }
   for( i = 0; i < 2; i++ )
   {
      WCHAR loc[ MAX_PATH ], pv[ 64 ];
      _snwprintf( key, HB_SIZEOFARRAY( key ), L"SOFTWARE\\Microsoft\\EdgeUpdate\\Clients\\%ls", s_szRuntimeGuid );
      if( wv_regString( roots[ i ], key, L"location", loc, HB_SIZEOFARRAY( loc ) ) &&
          wv_regString( roots[ i ], key, L"pv", pv, HB_SIZEOFARRAY( pv ) ) )
      {
         _snwprintf( out, cch, L"%ls\\%ls", loc, pv );
         out[ cch - 1 ] = 0;
         return TRUE;
      }
   }
   return FALSE;
}

static BOOL wv_loadRuntime( void )
{
   if( s_loaderState != 0 )
      return s_loaderState > 0;
   s_loaderState = -1;
   s_szVersion[ 0 ] = 0;

   /* 1. WebView2Loader.dll shipped next to the exe (documented path) */
   {
      HMODULE hLoader = LoadLibraryExW( L"WebView2Loader.dll", NULL, LOAD_LIBRARY_SEARCH_APPLICATION_DIR );
      if( hLoader )
      {
         s_pCreateEnv  = ( PFN_CREATEENV ) ( void * ) GetProcAddress( hLoader, "CreateCoreWebView2EnvironmentWithOptions" );
         s_pGetVersion = ( PFN_GETVERSION ) ( void * ) GetProcAddress( hLoader, "GetAvailableCoreWebView2BrowserVersionString" );
         if( s_pCreateEnv )
         {
            LPWSTR v = NULL;
            if( s_pGetVersion && SUCCEEDED( s_pGetVersion( NULL, &v ) ) && v )
            {
               lstrcpynW( s_szVersion, v, HB_SIZEOFARRAY( s_szVersion ) );
               CoTaskMemFree( v );
            }
            if( s_szVersion[ 0 ] )
            {
               s_loaderState = 1;
               return TRUE;
            }
         }
         s_pCreateEnv = NULL;
         s_pGetVersion = NULL;
         FreeLibrary( hLoader );
      }
   }

   /* 2. built-in loader: the installed runtime's EmbeddedBrowserWebView.dll */
   {
      WCHAR   folder[ MAX_PATH ], dll[ MAX_PATH + 64 ];
      HMODULE hDll;
      LPCWSTR p;

      if( ! wv_runtimeFolder( folder, HB_SIZEOFARRAY( folder ) ) )
         return FALSE;
      _snwprintf( dll, HB_SIZEOFARRAY( dll ), L"%ls\\EBWebView\\x64\\EmbeddedBrowserWebView.dll", folder );
      dll[ HB_SIZEOFARRAY( dll ) - 1 ] = 0;
      hDll = LoadLibraryExW( dll, NULL, LOAD_WITH_ALTERED_SEARCH_PATH );
      if( hDll == NULL )
         return FALSE;
      s_pCreateInt = ( PFN_CREATEENVINTERNAL ) ( void * ) GetProcAddress( hDll, "CreateWebViewEnvironmentWithOptionsInternal" );
      if( s_pCreateInt == NULL )
      {
         FreeLibrary( hDll );
         return FALSE;
      }
      p = wcsrchr( folder, L'\\' );
      lstrcpynW( s_szVersion, p ? p + 1 : folder, HB_SIZEOFARRAY( s_szVersion ) );
      s_loaderState = 1;
      return TRUE;
   }
}

/* ------------------------------------------------------------------------ */
/* Host window                                                               */
/* ------------------------------------------------------------------------ */

static PHB_DYNS s_pEventSym = NULL;

static void wv_dispatch( HWND hWnd, WVEVT * e )
{
   if( s_pEventSym == NULL )
      s_pEventSym = hb_dynsymFindName( "_HMG_WEBVIEWEVENT" );
   if( s_pEventSym && hb_vmRequestReenter() )
   {
      hb_vmPushDynSym( s_pEventSym );
      hb_vmPushNil();
      hb_vmPushNumInt( ( HB_MAXINT ) ( HB_PTRUINT ) hWnd );
      hb_vmPushInteger( e->kind );
      {
         PHB_ITEM p = hb_itemPutStrU16( NULL, HB_CDP_ENDIAN_NATIVE, e->text ? e->text : L"" );
         hb_vmPush( p );
         hb_itemPutStrU16( p, HB_CDP_ENDIAN_NATIVE, e->extra ? e->extra : L"" );
         hb_vmPush( p );
         hb_itemRelease( p );
      }
      hb_vmPushInteger( e->num );
      hb_vmDo( 5 );
      hb_vmRequestRestore();
   }
}

static LRESULT CALLBACK wv_HostProc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   WVCTL * c = ( WVCTL * ) GetWindowLongPtrW( hWnd, GWLP_USERDATA );

   switch( msg )
   {
      case WM_HMG_WVEVENT:
      {
         WVEVT * e = ( WVEVT * ) lParam;
         if( c && ! c->closed )
            wv_dispatch( hWnd, e );
         wv_freeEvent( e );
         return 0;
      }
      case WM_SIZE:
         if( c )
            wv_updateBounds( c );
         break;
      case WM_SHOWWINDOW:
         if( c && c->ctrl )
            ICoreWebView2Controller_put_IsVisible( c->ctrl, ( BOOL ) wParam );
         break;
      case WM_SETFOCUS:
         if( c && c->ctrl )
            ICoreWebView2Controller_MoveFocus( c->ctrl, COREWEBVIEW2_MOVE_FOCUS_REASON_PROGRAMMATIC );
         return 0;
      case WM_ERASEBKGND:
         if( c && c->ctrl )
            return 1;
         break;
      case WM_DESTROY:
         if( c )
            wv_close( c );
         break;
      case WM_NCDESTROY:
         if( c )
         {
            SetWindowLongPtrW( hWnd, GWLP_USERDATA, 0 );
            c->hHost = NULL;
            wv_ctlRelease( c );
         }
         break;
   }
   return DefWindowProcW( hWnd, msg, wParam, lParam );
}

static BOOL wv_registerClass( void )
{
   static BOOL s_done = FALSE;
   WNDCLASSEXW wc;

   if( s_done )
      return TRUE;
   memset( &wc, 0, sizeof( wc ) );
   wc.cbSize        = sizeof( wc );
   wc.lpfnWndProc   = wv_HostProc;
   wc.hInstance     = GetModuleHandleW( NULL );
   wc.hCursor       = LoadCursor( NULL, IDC_ARROW );
   wc.hbrBackground = ( HBRUSH ) ( COLOR_WINDOW + 1 );
   wc.lpszClassName = HMG_WV_CLASS;
   if( ! RegisterClassExW( &wc ) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS )
      return FALSE;
   s_done = TRUE;
   return TRUE;
}

static WVCTL * wv_fromParam( int n )
{
   HWND    h = ( HWND ) ( HB_PTRUINT ) hb_parnll( n );
   WCHAR   cls[ 32 ];
   if( h == NULL || ! IsWindow( h ) )
      return NULL;
   if( GetClassNameW( h, cls, HB_SIZEOFARRAY( cls ) ) == 0 || lstrcmpW( cls, HMG_WV_CLASS ) != 0 )
      return NULL;
   return ( WVCTL * ) GetWindowLongPtrW( h, GWLP_USERDATA );
}

/* the core, or NULL if the control is not ready */
static ICoreWebView2 * wv_core( int n )
{
   WVCTL * c = wv_fromParam( n );
   return ( c && ! c->closed ) ? c->wv : NULL;
}

/* ------------------------------------------------------------------------ */
/* Harbour API (called from h_webview.prg only)                              */
/* ------------------------------------------------------------------------ */

/* HMG_WebViewVersion() -> cVersion | "" when no runtime is installed */
HB_FUNC( HMG_WEBVIEWVERSION )
{
   if( wv_loadRuntime() )
      hb_retstr_u16( HB_CDP_ENDIAN_NATIVE, s_szVersion );
   else
      hb_retc_null();
}

/* HMG_WEBVIEW_CREATE( hParent, nCol, nRow, nWidth, nHeight, cUserDataFolder, lPrivate, lDevTools, lVisible )
   -> hHost (the control handle), 0 on failure. Creation continues asynchronously:
   READY or ERROR is reported through _HMG_WEBVIEWEVENT(). */
HB_FUNC( HMG_WEBVIEW_CREATE )
{
   HWND     hParent = ( HWND ) ( HB_PTRUINT ) hb_parnll( 1 );
   void *   hUser;
   LPCWSTR  szUser;
   WVCTL *  c;
   HWND     hHost;
   HRESULT  hr;
   DWORD    style = WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS | WS_TABSTOP;

   if( hParent == NULL || ! IsWindow( hParent ) || ! wv_registerClass() )
   {
      hb_retnll( 0 );
      return;
   }
   if( hb_parldef( 9, HB_TRUE ) )
      style |= WS_VISIBLE;

   hHost = CreateWindowExW( 0, HMG_WV_CLASS, L"", style,
                            hb_parni( 2 ), hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ),
                            hParent, NULL, GetModuleHandleW( NULL ), NULL );
   if( hHost == NULL )
   {
      hb_retnll( 0 );
      return;
   }

   c = ( WVCTL * ) hb_xgrabz( sizeof( WVCTL ) );
   c->ref       = 1;                       /* owned by the host window */
   c->hHost     = hHost;
   c->inPrivate = hb_parl( 7 );
   c->devTools  = hb_parl( 8 );
   SetWindowLongPtrW( hHost, GWLP_USERDATA, ( LONG_PTR ) c );

   hb_retnll( ( HB_LONGLONG ) ( HB_PTRUINT ) hHost );

   hr = CoInitializeEx( NULL, COINIT_APARTMENTTHREADED );
   if( hr == RPC_E_CHANGED_MODE )
   {
      wv_postError( c, L"WebView2 needs a single-threaded COM apartment on the GUI thread", hr );
      return;
   }

   if( ! wv_loadRuntime() )
   {
      wv_post( c, WVE_ERROR, 0, L"WebView2 runtime not found. Install the Microsoft Edge WebView2 Runtime.", NULL );
      return;
   }

   szUser = hb_parstr_u16( 6, HB_CDP_ENDIAN_NATIVE, &hUser, NULL );
   if( szUser && szUser[ 0 ] == 0 )
      szUser = NULL;
   {
      WVHANDLER * h = wv_newHandler( &s_envDoneVtbl, &IID_ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler, c, 0 );
      if( s_pCreateEnv )
         hr = s_pCreateEnv( NULL, szUser, NULL, ( ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler * ) h );
      else
         hr = s_pCreateInt( TRUE, 0, szUser, NULL, ( ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler * ) h );
      h_Release( h );
   }
   hb_strfree( hUser );
   if( FAILED( hr ) )
      wv_postError( c, L"WebView2 environment could not be created", hr );
}

/* HMG_WEBVIEW_ISREADY( hHost ) -> lReady */
HB_FUNC( HMG_WEBVIEW_ISREADY )
{
   hb_retl( wv_core( 1 ) != NULL );
}

/* HMG_WEBVIEW_NAVIGATE( hHost, cUrl ) -> lSent */
HB_FUNC( HMG_WEBVIEW_NAVIGATE )
{
   ICoreWebView2 * wv = wv_core( 1 );
   void *          hStr;
   LPCWSTR         s;
   HRESULT         hr = E_FAIL;

   if( wv && HB_ISCHAR( 2 ) )
   {
      s  = hb_parstr_u16( 2, HB_CDP_ENDIAN_NATIVE, &hStr, NULL );
      hr = ICoreWebView2_Navigate( wv, s );
      hb_strfree( hStr );
   }
   hb_retl( SUCCEEDED( hr ) );
}

/* HMG_WEBVIEW_SETHTML( hHost, cHtml ) -> lSent
   The page is kept (as UTF-8) and served from memory at HMG_WV_HTMLHOST; no size limit. */
HB_FUNC( HMG_WEBVIEW_SETHTML )
{
   WVCTL *         c  = wv_fromParam( 1 );
   ICoreWebView2 * wv = wv_core( 1 );
   HRESULT         hr = E_FAIL;

   if( wv && HB_ISCHAR( 2 ) )
   {
      void *       hStr;
      HB_SIZE      nLen = 0;
      const char * s    = hb_parstr_utf8( 2, &hStr, &nLen );
      WCHAR        url[ 64 ];

      if( c->html )
         hb_xfree( c->html );
      c->html = ( char * ) hb_xgrab( nLen + 1 );
      memcpy( c->html, s ? s : "", nLen );
      c->html[ nLen ] = 0;
      c->htmlLen = nLen;
      hb_strfree( hStr );

      /* a new URL per page, so WebView2 never shows a cached copy of an earlier page */
      _snwprintf( url, HB_SIZEOFARRAY( url ), HMG_WV_HTMLHOST L"page%u.html", ++c->htmlSeq );
      url[ HB_SIZEOFARRAY( url ) - 1 ] = 0;
      hr = ICoreWebView2_Navigate( wv, url );
   }
   hb_retl( SUCCEEDED( hr ) );
}

/* HMG_WEBVIEW_MAPFOLDER( hHost, cHostName, cFolder ) -> lOk */
HB_FUNC( HMG_WEBVIEW_MAPFOLDER )
{
   ICoreWebView2 *   wv = wv_core( 1 );
   ICoreWebView2_3 * wv3 = NULL;
   HRESULT           hr = E_FAIL;

   if( wv && HB_ISCHAR( 2 ) && HB_ISCHAR( 3 ) &&
       SUCCEEDED( ICoreWebView2_QueryInterface( wv, &IID_ICoreWebView2_3, ( void ** ) &wv3 ) ) && wv3 )
   {
      void *  h1, * h2;
      LPCWSTR host   = hb_parstr_u16( 2, HB_CDP_ENDIAN_NATIVE, &h1, NULL );
      LPCWSTR folder = hb_parstr_u16( 3, HB_CDP_ENDIAN_NATIVE, &h2, NULL );
      hr = ICoreWebView2_3_SetVirtualHostNameToFolderMapping( wv3, host, folder,
              COREWEBVIEW2_HOST_RESOURCE_ACCESS_KIND_DENY_CORS );
      hb_strfree( h1 );
      hb_strfree( h2 );
      ICoreWebView2_3_Release( wv3 );
   }
   hb_retl( SUCCEEDED( hr ) );
}

/* HMG_WEBVIEW_EXECSCRIPT( hHost, cJs, nCallbackId ) -> lSent
   nCallbackId > 0: the result comes back as a SCRIPTRESULT event */
HB_FUNC( HMG_WEBVIEW_EXECSCRIPT )
{
   WVCTL *         c  = wv_fromParam( 1 );
   ICoreWebView2 * wv = wv_core( 1 );
   HRESULT         hr = E_FAIL;

   if( wv && HB_ISCHAR( 2 ) )
   {
      void *      hStr;
      LPCWSTR     s = hb_parstr_u16( 2, HB_CDP_ENDIAN_NATIVE, &hStr, NULL );
      WVHANDLER * h = wv_newHandler( &s_execVtbl, &IID_ICoreWebView2ExecuteScriptCompletedHandler, c, hb_parni( 3 ) );
      hr = ICoreWebView2_ExecuteScript( wv, s, ( ICoreWebView2ExecuteScriptCompletedHandler * ) h );
      h_Release( h );
      hb_strfree( hStr );
   }
   hb_retl( SUCCEEDED( hr ) );
}

/* HMG_WEBVIEW_POSTJSON( hHost, cJson ) -> lSent */
HB_FUNC( HMG_WEBVIEW_POSTJSON )
{
   ICoreWebView2 * wv = wv_core( 1 );
   HRESULT         hr = E_FAIL;

   if( wv && HB_ISCHAR( 2 ) )
   {
      void *  hStr;
      LPCWSTR s = hb_parstr_u16( 2, HB_CDP_ENDIAN_NATIVE, &hStr, NULL );
      hr = ICoreWebView2_PostWebMessageAsJson( wv, s );
      hb_strfree( hStr );
   }
   hb_retl( SUCCEEDED( hr ) );
}

/* HMG_WEBVIEW_GETSTR( hHost, nWhat ) -> cValue   1 = URL, 2 = title */
HB_FUNC( HMG_WEBVIEW_GETSTR )
{
   ICoreWebView2 * wv = wv_core( 1 );
   LPWSTR          s  = NULL;

   if( wv )
   {
      if( hb_parni( 2 ) == 1 )
         ICoreWebView2_get_Source( wv, &s );
      else
         ICoreWebView2_get_DocumentTitle( wv, &s );
   }
   if( s )
   {
      hb_retstr_u16( HB_CDP_ENDIAN_NATIVE, s );
      CoTaskMemFree( s );
   }
   else
      hb_retc_null();
}

/* HMG_WEBVIEW_COMMAND( hHost, nCmd ) -> lOk   1 Reload, 2 Stop, 3 GoBack, 4 GoForward */
HB_FUNC( HMG_WEBVIEW_COMMAND )
{
   ICoreWebView2 * wv = wv_core( 1 );
   HRESULT         hr = E_FAIL;

   if( wv )
   {
      switch( hb_parni( 2 ) )
      {
         case 1: hr = ICoreWebView2_Reload( wv );    break;
         case 2: hr = ICoreWebView2_Stop( wv );      break;
         case 3: hr = ICoreWebView2_GoBack( wv );    break;
         case 4: hr = ICoreWebView2_GoForward( wv ); break;
      }
   }
   hb_retl( SUCCEEDED( hr ) );
}

/* HMG_WEBVIEW_CANGO( hHost, lForward ) -> lCan */
HB_FUNC( HMG_WEBVIEW_CANGO )
{
   ICoreWebView2 * wv  = wv_core( 1 );
   BOOL            can = FALSE;

   if( wv )
   {
      if( hb_parl( 2 ) )
         ICoreWebView2_get_CanGoForward( wv, &can );
      else
         ICoreWebView2_get_CanGoBack( wv, &can );
   }
   hb_retl( can );
}

/* HMG_WEBVIEW_ZOOM( hHost [, nFactor ] ) -> nFactor (0 when not ready) */
HB_FUNC( HMG_WEBVIEW_ZOOM )
{
   WVCTL * c = wv_fromParam( 1 );
   double  z = 0;

   if( c && ! c->closed && c->ctrl )
   {
      if( HB_ISNUM( 2 ) && hb_parnd( 2 ) > 0 )
         ICoreWebView2Controller_put_ZoomFactor( c->ctrl, hb_parnd( 2 ) );
      ICoreWebView2Controller_get_ZoomFactor( c->ctrl, &z );
   }
   hb_retnd( z );
}

/* HMG_WEBVIEW_ISWEBVIEW( hWnd ) -> lIsHost */
HB_FUNC( HMG_WEBVIEW_ISWEBVIEW )
{
   hb_retl( wv_fromParam( 1 ) != NULL );
}
