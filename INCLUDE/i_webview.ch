/*----------------------------------------------------------------------------
 HMG5 - WebView2 control (Phase 4). See PHASE4-DESIGN.md section 1.

 @ <row>, <col> WEBVIEW <name> [ OF <parent> ] WIDTH <w> HEIGHT <h>
       [ URL <cUrl> | HTML <cHtml> | FOLDER <cFolder> [ START <cFile> ] ]
       [ USERDATA <cFolder> ] [ PRIVATE ] [ DEVTOOLS ] [ INVISIBLE ]
       [ ON READY <bAction> ] [ ON NAVIGATE <bAction> ] [ ON MESSAGE <bAction> ]
       [ ON TITLE <bAction> ] [ ON ERROR <bAction> ]

 Event data: HMG_WebViewData() returns a hash, e.g. ON MESSAGE:
 { "value" => xValue, "source" => cPageUrl, "trusted" => lAppContent }
---------------------------------------------------------------------------*/

#xcommand @ <row>, <col> WEBVIEW <name> ;
      [ <dummy1: OF, PARENT> <parent> ] ;
      WIDTH <w> ;
      HEIGHT <h> ;
      [ URL <url> ] ;
      [ HTML <html> ] ;
      [ FOLDER <folder> ] ;
      [ START <start> ] ;
      [ USERDATA <userdata> ] ;
      [ <private: PRIVATE> ] ;
      [ <devtools: DEVTOOLS> ] ;
      [ <invisible: INVISIBLE> ] ;
      [ ON READY <ready> ] ;
      [ ON NAVIGATE <navigate> ] ;
      [ ON MESSAGE <message> ] ;
      [ ON TITLE <title> ] ;
      [ ON ERROR <error> ] ;
   => ;
   _DefineWebView( <"name">, <"parent">, <row>, <col>, <w>, <h>, ;
                   <url>, <html>, <folder>, <start>, <userdata>, <.private.>, <.devtools.>, ;
                   <{ready}>, <{navigate}>, <{message}>, <{title}>, <{error}>, <.invisible.> )
