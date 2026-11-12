/*----------------------------------------------------------------------------
 HMG5 - Apache ECharts for the CHART control (Phase 4, PHASE4-DESIGN.md section 7)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 echarts.min.js (Apache ECharts 6.1.0, Apache License 2.0, see echarts/LICENSE
 and echarts/NOTICE) is compiled into this object with C23 #embed and served to
 the CHART control's page from memory at https://html.hmg.example/lib/echarts.min.js
 (c_webview.c). Only programs that define a CHART link this object (it is referenced
 from h_chart.prg only), so other programs stay small; charts work offline.
---------------------------------------------------------------------------*/

#include <windows.h>
#include "hbapi.h"

BOOL HMG_WebViewAddLibrary( const WCHAR * name, const void * data, size_t len, const WCHAR * mime );

static const unsigned char s_echarts[] = {
#embed "echarts/echarts.min.js"
};

/* HMG_ECHARTS_REGISTER() -> lOk : make echarts.min.js available to every WebView */
HB_FUNC( HMG_ECHARTS_REGISTER )
{
   hb_retl( HMG_WebViewAddLibrary( L"echarts.min.js", s_echarts, sizeof( s_echarts ), L"application/javascript; charset=utf-8" ) );
}

/* HMG_ECHARTS_VERSION() -> "6.1.0" */
HB_FUNC( HMG_ECHARTS_VERSION )
{
   hb_retc_const( "6.1.0" );
}
