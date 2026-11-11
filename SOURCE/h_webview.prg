/*----------------------------------------------------------------------------
 HMG5 - WebView2 control, PRG side (Phase 4, PHASE4-DESIGN.md section 1)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 Control data lives in _HMG_SYSDATA [HMG_CTL_MISCDATA1] [i] as a hash (see
 _WV_NewState). C side: c_webview.c.
---------------------------------------------------------------------------*/

MEMVAR _HMG_SYSDATA

#include "hmg.ch"

/* event kinds, keep in sync with c_webview.c */
#define WVE_READY          1
#define WVE_ERROR          2
#define WVE_NAVIGATED      3
#define WVE_MESSAGE        4
#define WVE_TITLE          5
#define WVE_SCRIPTRESULT   6

/* the virtual host a FOLDER is mapped to; ".example" never resolves on the internet */
#define WV_APP_HOST        "app.hmg.example"
#define WV_APP_ORIGIN      "https://app.hmg.example"
#define WV_HTML_ORIGIN     "https://html.hmg.example"   // the HTML property is served here (c_webview.c)

STATIC s_aEventData := {}     // stack: data of the WebView event being processed

*-----------------------------------------------------------------------------*
FUNCTION _DefineWebView( cName, cParent, nRow, nCol, nWidth, nHeight, ;
                         cUrl, cHtml, cFolder, cStart, cUserData, lPrivate, lDevTools, ;
                         bReady, bNavigate, bMessage, bTitle, bError, lInvisible )
*-----------------------------------------------------------------------------*
   LOCAL mVar, k, hParent, hHost, hState

   hb_default( @lPrivate, .F. )
   hb_default( @lDevTools, .F. )
   hb_default( @lInvisible, .F. )

   IF _HMG_SYSDATA [ 264 ] == .T.          // inside DEFINE WINDOW
      cParent := _HMG_SYSDATA [ 223 ]
   ENDIF
   IF _HMG_SYSDATA [ 183 ] > 0            // inside a TAB page
      nCol    := nCol + _HMG_SYSDATA [ 334 ] [ _HMG_SYSDATA [ 183 ] ]
      nRow    := nRow + _HMG_SYSDATA [ 333 ] [ _HMG_SYSDATA [ 183 ] ]
      cParent := _HMG_SYSDATA [ 332 ] [ _HMG_SYSDATA [ 183 ] ]
   ENDIF

   IF ! _IsWindowDefined( cParent )
      MsgHMGError( "Window: " + cParent + " is not defined. Program terminated" )
   ENDIF
   IF _IsControlDefined( cName, cParent )
      MsgHMGError( "Control: " + cName + " Of " + cParent + " Already defined. Program Terminated" )
   ENDIF
   IF HB_ISSTRING( cFolder ) .AND. ! Empty( cFolder ) .AND. ! hb_DirExists( cFolder )
      MsgHMGError( "Control: " + cName + " Of " + cParent + " FOLDER does not exist: " + cFolder + ". Program Terminated" )
   ENDIF

   IF ! HB_ISSTRING( cUserData ) .OR. Empty( cUserData )
      cUserData := _WV_DefaultUserData()
   ENDIF

   hParent := GetFormHandle( cParent )
   hHost   := HMG_WEBVIEW_CREATE( hParent, nCol, nRow, nWidth, nHeight, cUserData, lPrivate, lDevTools, ! lInvisible )
   IF Empty( hHost )
      MsgHMGError( "Control: " + cName + " Of " + cParent + " could not be created. Program Terminated" )
   ENDIF

   IF _HMG_SYSDATA [ 265 ] == .T.         // TAB page map
      AAdd( _HMG_SYSDATA [ 142 ], hHost )
   ENDIF

   hState := _WV_NewState( bReady, bNavigate, bMessage, bTitle, bError, cUserData, lPrivate )

   /* first content, applied when the control is ready */
   IF HB_ISSTRING( cFolder ) .AND. ! Empty( cFolder )
      hb_default( @cStart, "index.html" )
      _WV_Queue( hState, { "map", WV_APP_HOST, hb_PathNormalize( hb_DirSepAdd( cFolder ) ) } )
      _WV_Queue( hState, { "nav", WV_APP_ORIGIN + "/" + StrTran( cStart, "\", "/" ) } )
   ELSEIF HB_ISSTRING( cHtml )
      _WV_Queue( hState, { "html", cHtml } )
   ELSEIF HB_ISSTRING( cUrl ) .AND. ! Empty( cUrl )
      _WV_Queue( hState, { "nav", cUrl } )
   ENDIF

   mVar := "_" + cParent + "_" + cName
   k := _GetControlFree()
   _HMG_VarSet( mVar, k )

   _HMG_SYSDATA [ HMG_CTL_TYPE ] [ k ]           := "WEBVIEW"
   _HMG_SYSDATA [ HMG_CTL_NAME ] [ k ]           := cName
   _HMG_SYSDATA [ HMG_CTL_HANDLE ] [ k ]         := hHost
   _HMG_SYSDATA [ HMG_CTL_PARENTHANDLE ] [ k ]   := hParent
   _HMG_SYSDATA [ HMG_CTL_ID ] [ k ]             := 0
   _HMG_SYSDATA [ HMG_CTL_PROCEDURE ] [ k ]      := ""
   _HMG_SYSDATA [ HMG_CTL_PAGEMAP ] [ k ]        := {}
   _HMG_SYSDATA [ HMG_CTL_VALUE ] [ k ]          := NIL
   _HMG_SYSDATA [ HMG_CTL_INPUTMASK ] [ k ]      := ""
   _HMG_SYSDATA [ HMG_CTL_LOSTFOCUS ] [ k ]      := NIL
   _HMG_SYSDATA [ HMG_CTL_GOTFOCUS ] [ k ]       := NIL
   _HMG_SYSDATA [ HMG_CTL_CHANGE ] [ k ]         := ""
   _HMG_SYSDATA [ HMG_CTL_DELETED ] [ k ]        := .F.
   _HMG_SYSDATA [ HMG_CTL_BKCOLOR ] [ k ]        := NIL
   _HMG_SYSDATA [ HMG_CTL_FONTCOLOR ] [ k ]      := NIL
   _HMG_SYSDATA [ HMG_CTL_DBLCLICK ] [ k ]       := ""
   _HMG_SYSDATA [ HMG_CTL_HEADCLICK ] [ k ]      := {}
   _HMG_SYSDATA [ HMG_CTL_ROW ] [ k ]            := nRow
   _HMG_SYSDATA [ HMG_CTL_COL ] [ k ]            := nCol
   _HMG_SYSDATA [ HMG_CTL_WIDTH ] [ k ]          := nWidth
   _HMG_SYSDATA [ HMG_CTL_HEIGHT ] [ k ]         := nHeight
   _HMG_SYSDATA [ HMG_CTL_SPACING ] [ k ]        := 0
   _HMG_SYSDATA [ HMG_CTL_CONTAINERROW ] [ k ]   := iif( _HMG_SYSDATA [ 183 ] > 0, _HMG_SYSDATA [ 333 ] [ _HMG_SYSDATA [ 183 ] ], -1 )
   _HMG_SYSDATA [ HMG_CTL_CONTAINERCOL ] [ k ]   := iif( _HMG_SYSDATA [ 183 ] > 0, _HMG_SYSDATA [ 334 ] [ _HMG_SYSDATA [ 183 ] ], -1 )
   _HMG_SYSDATA [ HMG_CTL_PICTURE ] [ k ]        := ""
   _HMG_SYSDATA [ HMG_CTL_CONTAINERHANDLE ] [ k ] := 0
   _HMG_SYSDATA [ HMG_CTL_FONTNAME ] [ k ]       := ""
   _HMG_SYSDATA [ HMG_CTL_FONTSIZE ] [ k ]       := 0
   _HMG_SYSDATA [ HMG_CTL_FONTATTRIBUTES ] [ k ] := { .F., .F., .F., .F. }
   _HMG_SYSDATA [ HMG_CTL_TOOLTIP ] [ k ]        := ""
   _HMG_SYSDATA [ HMG_CTL_RANGEMIN ] [ k ]       := 0
   _HMG_SYSDATA [ HMG_CTL_RANGEMAX ] [ k ]       := 0
   _HMG_SYSDATA [ HMG_CTL_CAPTION ] [ k ]        := ""
   _HMG_SYSDATA [ HMG_CTL_VISIBLE ] [ k ]        := ! lInvisible
   _HMG_SYSDATA [ HMG_CTL_HELPID ] [ k ]         := 0
   _HMG_SYSDATA [ HMG_CTL_FONTHANDLE ] [ k ]     := 0
   _HMG_SYSDATA [ HMG_CTL_BRUSHHANDLE ] [ k ]    := 0
   _HMG_SYSDATA [ HMG_CTL_ENABLED ] [ k ]        := .T.
   _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [ k ]      := hState
   _HMG_SYSDATA [ HMG_CTL_MISCDATA2 ] [ k ]      := { NIL, NIL, NIL, NIL, NIL, NIL, NIL, NIL }

   RETURN NIL

STATIC FUNCTION _WV_DefaultUserData()
   LOCAL cBase := GetEnv( "LOCALAPPDATA" )
   IF Empty( cBase )
      cBase := GetEnv( "TEMP" )
   ENDIF
   RETURN hb_DirSepAdd( cBase ) + hb_FNameName( hb_ProgName() ) + hb_ps() + "WebView2"

STATIC FUNCTION _WV_NewState( bReady, bNavigate, bMessage, bTitle, bError, cUserData, lPrivate )
   LOCAL h := { => }, hBinds := { => }
   hb_HCaseMatch( hBinds, .T. )
   h[ "ready" ]     := .F.
   h[ "error" ]     := ""
   h[ "url" ]       := ""
   h[ "title" ]     := ""
   h[ "queue" ]     := {}
   h[ "binds" ]     := hBinds
   h[ "origins" ]   := { WV_HTML_ORIGIN, WV_APP_ORIGIN }   // never "about:blank": data: pages report it too
   h[ "scripts" ]   := { => }       // ExecuteScript callbacks by id
   h[ "seq" ]       := 0
   h[ "userdata" ]  := cUserData
   h[ "private" ]   := lPrivate
   h[ "onready" ]   := bReady
   h[ "onnavigate" ] := bNavigate
   h[ "onmessage" ] := bMessage
   h[ "ontitle" ]   := bTitle
   h[ "onerror" ]   := bError
   RETURN h

STATIC PROCEDURE _WV_Queue( hState, aOp )
   AAdd( hState[ "queue" ], aOp )
   RETURN

/* run an operation now if ready, else queue it */
STATIC FUNCTION _WV_Do( i, aOp )
   LOCAL hState := _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [ i ]
   IF hState[ "ready" ]
      RETURN _WV_Run( _HMG_SYSDATA [ HMG_CTL_HANDLE ] [ i ], aOp )
   ENDIF
   _WV_Queue( hState, aOp )
   RETURN .T.

STATIC FUNCTION _WV_Run( h, aOp )
   SWITCH aOp[ 1 ]
   CASE "nav"  ; RETURN HMG_WEBVIEW_NAVIGATE( h, aOp[ 2 ] )
   CASE "html" ; RETURN HMG_WEBVIEW_SETHTML( h, aOp[ 2 ] )
   CASE "map"  ; RETURN HMG_WEBVIEW_MAPFOLDER( h, aOp[ 2 ], aOp[ 3 ] )
   CASE "js"   ; RETURN HMG_WEBVIEW_EXECSCRIPT( h, aOp[ 2 ], aOp[ 3 ] )
   CASE "post" ; RETURN HMG_WEBVIEW_POSTJSON( h, aOp[ 2 ] )
   CASE "cmd"  ; RETURN HMG_WEBVIEW_COMMAND( h, aOp[ 2 ] )
   ENDSWITCH
   RETURN .F.

/* index of the WEBVIEW control that owns host window h, or 0 */
STATIC FUNCTION _WV_Index( h )
   LOCAL i := AScan( _HMG_SYSDATA [ HMG_CTL_HANDLE ], h )
   IF i > 0 .AND. _HMG_SYSDATA [ HMG_CTL_TYPE ] [ i ] == "WEBVIEW" .AND. ! _HMG_SYSDATA [ HMG_CTL_DELETED ] [ i ]
      RETURN i
   ENDIF
   RETURN 0

STATIC FUNCTION _WV_Fire( i, cEvent, xData )
   LOCAL bBlock := _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [ i ] [ cEvent ]
   LOCAL lDone
   IF ! HB_ISBLOCK( bBlock )
      RETURN .F.
   ENDIF
   AAdd( s_aEventData, xData )
   lDone := _DoControlEventProcedure( bBlock, i )
   ASize( s_aEventData, Len( s_aEventData ) - 1 )
   RETURN lDone

/* HMG_WebViewData() -> data of the WebView event being processed (hash), NIL outside one */
FUNCTION HMG_WebViewData()
   IF Empty( s_aEventData )
      RETURN NIL
   ENDIF
   RETURN ATail( s_aEventData )

/* is cSource (a page URL) one of the control's trusted origins? */
STATIC FUNCTION _WV_Trusted( hState, cSource )
   LOCAL cOrigin
   FOR EACH cOrigin IN hState[ "origins" ]
      IF cSource == cOrigin .OR. hb_LeftEqI( cSource, cOrigin + "/" )
         RETURN .T.
      ENDIF
   NEXT
   RETURN .F.

/* resolve or reject the page's hmg.call() promise */
STATIC PROCEDURE _WV_Settle( h, nId, lOk, xValue )
   LOCAL cJson
   IF lOk
      cJson := hb_jsonEncode( xValue )
      IF Empty( cJson )
         cJson := "null"
      ENDIF
   ELSE
      cJson := hb_jsonEncode( hb_CStr( xValue ) )
   ENDIF
   HMG_WEBVIEW_EXECSCRIPT( h, "hmg.__settle(" + hb_ntos( nId ) + "," + iif( lOk, "true", "false" ) + "," + cJson + ")", 0 )
   RETURN

/* page -> Harbour call through hmg.call( name, ... ) */
STATIC PROCEDURE _WV_Call( i, h, hState, hMsg, cSource )
   LOCAL nId := hb_HGetDef( hMsg, "id", 0 )
   LOCAL cFn := hb_HGetDef( hMsg, "fn", "" )
   LOCAL aArgs := hb_HGetDef( hMsg, "args", {} )
   LOCAL bBlock, xResult, oErr, lOk := .T.

   HB_SYMBOL_UNUSED( i )
   IF ! HB_ISNUMERIC( nId ) .OR. nId <= 0
      RETURN
   ENDIF
   IF ! _WV_Trusted( hState, cSource )
      _WV_Settle( h, nId, .F., "hmg.call is not allowed from " + cSource )
      RETURN
   ENDIF
   IF ! HB_ISSTRING( cFn ) .OR. ! hb_HHasKey( hState[ "binds" ], cFn )
      _WV_Settle( h, nId, .F., "hmg.call: '" + hb_CStr( cFn ) + "' is not bound" )
      RETURN
   ENDIF
   IF ! HB_ISARRAY( aArgs )
      aArgs := {}
   ENDIF
   bBlock := hState[ "binds" ][ cFn ]

   BEGIN SEQUENCE WITH {| e | Break( e ) }
      xResult := hb_ExecFromArray( bBlock, aArgs )
   RECOVER USING oErr
      lOk := .F.
      xResult := iif( HB_ISOBJECT( oErr ), oErr:Description + iif( Empty( oErr:Operation ), "", ": " + oErr:Operation ), "error" )
   END SEQUENCE

   /* the control may have been released by the bound block */
   IF HMG_WEBVIEW_ISWEBVIEW( h )
      _WV_Settle( h, nId, lOk, xResult )
   ENDIF
   RETURN

/* called from c_webview.c (host window procedure) for every WebView event */
FUNCTION _HMG_WEBVIEWEVENT( h, nKind, cText, cExtra, nNum )
   LOCAL i := _WV_Index( h )
   LOCAL hState, aOp, xMsg, bCb, xVal, lTrusted

   IF i == 0
      RETURN NIL
   ENDIF
   hState := _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [ i ]

   SWITCH nKind
   CASE WVE_READY
      hState[ "ready" ] := .T.
      FOR EACH aOp IN hState[ "queue" ]
         _WV_Run( h, aOp )
      NEXT
      hState[ "queue" ] := {}
      _WV_Fire( i, "onready", { "ready" => .T. } )
      EXIT

   CASE WVE_ERROR
      hState[ "error" ] := cText
      hState[ "queue" ] := {}
      _WV_Fire( i, "onerror", { "error" => cText, "code" => nNum } )
      EXIT

   CASE WVE_NAVIGATED
      hState[ "url" ] := cText
      _WV_Fire( i, "onnavigate", { "url" => cText, "success" => ( nNum == 0 ), "status" => Max( nNum - 1, 0 ) } )
      EXIT

   CASE WVE_TITLE
      hState[ "title" ] := cText
      _WV_Fire( i, "ontitle", { "title" => cText } )
      EXIT

   CASE WVE_MESSAGE
      lTrusted := _WV_Trusted( hState, cExtra )
      xMsg := NIL
      IF nNum == 1 .AND. hb_LeftEq( cText, "{" )
         hb_jsonDecode( cText, @xMsg )
      ENDIF
      IF HB_ISHASH( xMsg ) .AND. hb_HHasKey( xMsg, "hmg" )
         SWITCH hb_HGetDef( xMsg, "hmg", 0 )
         CASE 1
            _WV_Call( i, h, hState, xMsg, cExtra )
            EXIT
         CASE 2
            _WV_Fire( i, "onmessage", { "value" => hb_HGetDef( xMsg, "data", NIL ), "source" => cExtra, "trusted" => lTrusted } )
            EXIT
         ENDSWITCH
      ELSE
         /* raw window.chrome.webview.postMessage(): the string, or the decoded JSON value */
         IF nNum == 1
            xVal := cText
         ELSE
            hb_jsonDecode( cText, @xVal )
         ENDIF
         _WV_Fire( i, "onmessage", { "value" => xVal, "source" => cExtra, "trusted" => lTrusted } )
      ENDIF
      EXIT

   CASE WVE_SCRIPTRESULT
      IF hb_HHasKey( hState[ "scripts" ], nNum )
         bCb := hState[ "scripts" ][ nNum ]
         hb_HDel( hState[ "scripts" ], nNum )
         xVal := NIL
         IF ! ( cExtra == "error" )
            hb_jsonDecode( cText, @xVal )
         ENDIF
         Eval( bCb, xVal, ! ( cExtra == "error" ) )
      ENDIF
      EXIT
   ENDSWITCH

   RETURN NIL

*-----------------------------------------------------------------------------*
* GetProperty / SetProperty / DoMethod hooks (called from h_controlmisc.prg)
*-----------------------------------------------------------------------------*

FUNCTION _WebView_GetProperty( xData, cForm, cControl, cProp )
   LOCAL i, h, hState

   i      := GetControlIndex( cControl, cForm )
   h      := _HMG_SYSDATA [ HMG_CTL_HANDLE ] [ i ]
   hState := _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [ i ]

   SWITCH Upper( AllTrim( cProp ) )
   CASE "URL"
      xData := iif( hState[ "ready" ], HMG_WEBVIEW_GETSTR( h, 1 ), hState[ "url" ] )
      EXIT
   CASE "TITLE"
      xData := iif( hState[ "ready" ], HMG_WEBVIEW_GETSTR( h, 2 ), hState[ "title" ] )
      EXIT
   CASE "READY"
      xData := hState[ "ready" ]
      EXIT
   CASE "ERROR"
      xData := hState[ "error" ]
      EXIT
   CASE "CANGOBACK"
      xData := HMG_WEBVIEW_CANGO( h, .F. )
      EXIT
   CASE "CANGOFORWARD"
      xData := HMG_WEBVIEW_CANGO( h, .T. )
      EXIT
   CASE "ZOOMFACTOR"
      xData := HMG_WEBVIEW_ZOOM( h )
      EXIT
   CASE "USERDATAFOLDER"
      xData := hState[ "userdata" ]
      EXIT
   OTHERWISE
      RETURN .F.
   ENDSWITCH
   RETURN .T.

FUNCTION _WebView_SetProperty( cForm, cControl, cProp, xValue )
   LOCAL i := GetControlIndex( cControl, cForm )

   SWITCH Upper( AllTrim( cProp ) )
   CASE "URL"
      IF HB_ISSTRING( xValue )
         _WV_Do( i, { "nav", xValue } )
      ENDIF
      EXIT
   CASE "HTML"
      IF HB_ISSTRING( xValue )
         _WV_Do( i, { "html", xValue } )
      ENDIF
      EXIT
   CASE "ZOOMFACTOR"
      IF HB_ISNUMERIC( xValue )
         HMG_WEBVIEW_ZOOM( _HMG_SYSDATA [ HMG_CTL_HANDLE ] [ i ], xValue )
      ENDIF
      EXIT
   OTHERWISE
      RETURN .F.
   ENDSWITCH
   RETURN .T.

FUNCTION _WebView_DoMethod( cForm, cControl, cMethod, xArg1, xArg2 )
   LOCAL i := GetControlIndex( cControl, cForm )
   LOCAL hState := _HMG_SYSDATA [ HMG_CTL_MISCDATA1 ] [ i ]
   LOCAL nId

   SWITCH Upper( AllTrim( cMethod ) )
   CASE "NAVIGATE"
      IF HB_ISSTRING( xArg1 )
         _WV_Do( i, { "nav", xArg1 } )
      ENDIF
      EXIT
   CASE "SETHTML"
      IF HB_ISSTRING( xArg1 )
         _WV_Do( i, { "html", xArg1 } )
      ENDIF
      EXIT
   CASE "RELOAD"    ; _WV_Do( i, { "cmd", 1 } ) ; EXIT
   CASE "STOP"      ; _WV_Do( i, { "cmd", 2 } ) ; EXIT
   CASE "GOBACK"    ; _WV_Do( i, { "cmd", 3 } ) ; EXIT
   CASE "GOFORWARD" ; _WV_Do( i, { "cmd", 4 } ) ; EXIT
   CASE "EXECUTESCRIPT"
      IF HB_ISSTRING( xArg1 )
         nId := 0
         IF HB_ISBLOCK( xArg2 )
            nId := ++hState[ "seq" ]
            hState[ "scripts" ][ nId ] := xArg2
         ENDIF
         _WV_Do( i, { "js", xArg1, nId } )
      ENDIF
      EXIT
   CASE "BIND"
      IF HB_ISSTRING( xArg1 ) .AND. ! Empty( xArg1 ) .AND. HB_ISBLOCK( xArg2 )
         hState[ "binds" ][ xArg1 ] := xArg2
      ENDIF
      EXIT
   CASE "UNBIND"
      IF HB_ISSTRING( xArg1 ) .AND. hb_HHasKey( hState[ "binds" ], xArg1 )
         hb_HDel( hState[ "binds" ], xArg1 )
      ENDIF
      EXIT
   CASE "POSTMESSAGE"
      _WV_Do( i, { "post", hb_jsonEncode( xArg1 ) } )
      EXIT
   CASE "ALLOWORIGIN"
      IF HB_ISSTRING( xArg1 ) .AND. ! Empty( xArg1 )
         xArg1 := AllTrim( xArg1 )
         IF Right( xArg1, 1 ) == "/"
            xArg1 := Left( xArg1, Len( xArg1 ) - 1 )
         ENDIF
         IF AScan( hState[ "origins" ], {| c | hb_LeftEqI( c, xArg1 ) .AND. Len( c ) == Len( xArg1 ) } ) == 0
            AAdd( hState[ "origins" ], xArg1 )
         ENDIF
      ENDIF
      EXIT
   OTHERWISE
      RETURN .F.
   ENDSWITCH
   RETURN .T.
