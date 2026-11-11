/* HMG5 Phase 4 helpers: per-monitor DPI (SOURCE/c_dpi.c) and dark mode (SOURCE/c_dark.c).
   Include after <windows.h>. */
#ifndef HMG_DPI_H
#define HMG_DPI_H
UINT HMG_DpiForFont      ( HWND h );
BOOL HMG_DpiIsOn         ( void );
BOOL HMG_DpiWndProc      ( HWND hWnd, UINT nMsg, WPARAM wParam, LPARAM lParam, LRESULT * pResult );
void HMG_DpiScaleRect    ( HWND h, int * x, int * y, int * w, int * hgt, BOOL bMove, BOOL bSize );
int  HMG_DpiScaleSize    ( HWND h, int v );
int  HMG_DpiUnscaleSize  ( HWND h, int v );
int  HMG_DpiUnscaleClient( HWND h, int v );
int  HMG_DpiSystemMetric ( int nIndex );
BOOL HMG_IsHmgForm      ( HWND h );

BOOL     HMG_DarkIsOn      ( void );
COLORREF HMG_SysColor      ( int nIndex );
HBRUSH   HMG_DarkFormBrush ( void );
void     HMG_DarkPrepareDC ( UINT nMsg, HDC hDC );
HBRUSH   HMG_DarkCtlBrush  ( UINT nMsg );
#endif
