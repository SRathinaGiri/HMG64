/* HMG5 per-monitor DPI (Phase 4 D): helpers in SOURCE/c_dpi.c. Include after <windows.h>. */
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
#endif
