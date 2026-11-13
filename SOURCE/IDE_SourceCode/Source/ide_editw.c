/*----------------------------------------------------------------------------
 HMG5 IDE - built-in code editor, the window part (PHASE4-DESIGN.md 6.7, I6 b)

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 Built on what Windows already has: the RichEdit control (Msftedit.dll, as HMG's
 RICHEDITBOX) and its Text Object Model. No Scintilla, nothing new to ship.

   host  (class HMGIDEEditHost, a child of an HMG form): a tab strip and one view a file
   view  (class HMGIDECodeView): the line-number gutter and a RichEdit
   lexer Harbour/HMG colouring of the visible lines (keywords from
         tools\editor\hmg5_keywords.txt, embedded at compile time)

 Events go to the Harbour function IDE_ED_EVENT( hHost, nEvent, hView, nArg ):
   1 tab changed     2 modified flag changed     3 caret moved
   4 key (nArg = virtual key + 0x10000 Ctrl + 0x20000 Shift + 0x40000 Alt); .T. = handled
   5 close asked (middle click on a tab)
---------------------------------------------------------------------------*/

#define _WIN32_IE      0x0600
#define _WIN32_WINNT   0x0A00
#define COBJMACROS

#include <windows.h>
#include <commctrl.h>
#include <richedit.h>
#include <richole.h>
#include <tom.h>
#include <wchar.h>

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"

/* ------------------------------------------------------------------ styles */

enum { ST_DEF, ST_LANG, ST_CMD, ST_CLAUSE, ST_HMGF, ST_HBF, ST_PP, ST_CONST, ST_STR, ST_COMMENT, ST_NUM, ST_COUNT };

static const COLORREF s_palLight[ ST_COUNT ] = {
   RGB(   0,   0,   0 ),   /* default             */
   RGB(   0,   0, 192 ),   /* Harbour language    */
   RGB(   0,  96, 160 ),   /* HMG commands        */
   RGB(   0, 128, 128 ),   /* HMG clauses         */
   RGB( 128,   0, 128 ),   /* HMG functions       */
   RGB(   0,  80, 160 ),   /* Harbour functions   */
   RGB( 160,  80,   0 ),   /* preprocessor        */
   RGB( 200,  80,   0 ),   /* constants           */
   RGB( 163,  21,  21 ),   /* strings             */
   RGB(   0, 128,   0 ),   /* comments            */
   RGB( 200,  80,   0 ) }; /* numbers             */

static const COLORREF s_palDark[ ST_COUNT ] = {
   RGB( 220, 220, 220 ),
   RGB(  86, 156, 214 ),
   RGB(  78, 201, 176 ),
   RGB( 156, 220, 254 ),
   RGB( 197, 134, 192 ),
   RGB( 220, 220, 170 ),
   RGB( 214, 157, 133 ),
   RGB( 181, 206, 168 ),
   RGB( 206, 145, 120 ),
   RGB( 106, 153,  85 ),
   RGB( 181, 206, 168 ) };

static const BOOL s_bold[ ST_COUNT ]   = { 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0 };
static const BOOL s_italic[ ST_COUNT ] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0 };

#define BG_LIGHT       RGB( 255, 255, 255 )
#define BG_DARK        RGB(  30,  30,  30 )
#define GUT_LIGHT      RGB( 243, 243, 243 )
#define GUT_DARK       RGB(  37,  37,  38 )
#define GUTTXT_LIGHT   RGB( 140, 140, 140 )
#define GUTTXT_DARK    RGB( 120, 120, 120 )
#define GUTCUR_LIGHT   RGB(  40,  40,  40 )
#define GUTCUR_DARK    RGB( 220, 220, 220 )

/* HMG5 dark palette (c_dark.c) for the tab strip */
#define DK_BG          RGB(  32,  32,  32 )
#define DK_TEXT        RGB( 235, 235, 235 )
#define DK_GRAY        RGB( 140, 140, 140 )
#define DK_STRIP       RGB(  24,  24,  24 )
BOOL HMG_TabApplyModern( HWND hTab, COLORREF cStrip, COLORREF cPill, COLORREF cText, COLORREF cTextSel );   /* c_tab.c */

/* IID_ITextDocument, here so that no import library is needed for it */
static const IID s_IID_ITextDocument = { 0x8CC497C0, 0xA1DF, 0x11CE, { 0x80, 0x98, 0x00, 0xAA, 0x00, 0x47, 0xBE, 0x5D } };

/* ------------------------------------------------------------------ keywords */

static const char s_kwText[] = {
#embed "../../../tools/editor/hmg5_keywords.txt"
   , 0 };

#define KW_SIZE   16384          /* power of 2, > 4 x the word count */
#define KW_LEN    40
typedef struct { char w[ KW_LEN ]; unsigned char g; } KWENTRY;
static KWENTRY * s_kw = NULL;

static unsigned kw_hash( const char * s, int n )
{
   unsigned h = 2166136261u;
   int i;
   for( i = 0; i < n; i++ )
      h = ( h ^ ( unsigned char ) s[ i ] ) * 16777619u;
   return h;
}

static void kw_add( const char * s, int n, int g )
{
   unsigned h;
   char u[ KW_LEN ];
   int i;
   if( n <= 0 || n >= KW_LEN )
      return;
   for( i = 0; i < n; i++ )
      u[ i ] = ( char ) ( ( s[ i ] >= 'a' && s[ i ] <= 'z' ) ? s[ i ] - 32 : s[ i ] );
   u[ n ] = 0;
   h = kw_hash( u, n ) & ( KW_SIZE - 1 );
   while( s_kw[ h ].g && strcmp( s_kw[ h ].w, u ) != 0 )
      h = ( h + 1 ) & ( KW_SIZE - 1 );
   if( ! s_kw[ h ].g )
   {
      memcpy( s_kw[ h ].w, u, n + 1 );
      s_kw[ h ].g = ( unsigned char ) g;
   }
}

static void kw_init( void )
{
   const char * p = s_kwText;
   if( s_kw )
      return;
   s_kw = ( KWENTRY * ) calloc( KW_SIZE, sizeof( KWENTRY ) );
   while( *p )
   {
      const char * e = p;
      while( *e && *e != '\n' )
         e++;
      if( *p >= '1' && *p <= '7' && p[ 1 ] == ' ' )
      {
         const char * w = p + 2, * we = e;
         while( we > w && ( we[ -1 ] == '\r' || we[ -1 ] == ' ' ) )
            we--;
         kw_add( w, ( int ) ( we - w ), *p - '0' );
      }
      p = *e ? e + 1 : e;
   }
}

/* group 1..7 of an ASCII word (any case), 0 if unknown */
static int kw_find( const WCHAR * s, int n )
{
   char u[ KW_LEN ];
   unsigned h;
   int i;
   if( n <= 0 || n >= KW_LEN )
      return 0;
   for( i = 0; i < n; i++ )
   {
      WCHAR c = s[ i ];
      if( c > 127 )
         return 0;
      u[ i ] = ( char ) ( ( c >= 'a' && c <= 'z' ) ? c - 32 : c );
   }
   u[ n ] = 0;
   h = kw_hash( u, n ) & ( KW_SIZE - 1 );
   while( s_kw[ h ].g )
   {
      if( strcmp( s_kw[ h ].w, u ) == 0 )
         return s_kw[ h ].g;
      h = ( h + 1 ) & ( KW_SIZE - 1 );
   }
   return 0;
}

/* ------------------------------------------------------------------ lexer */

typedef void ( * LEXEMIT )( void * ctx, LONG s, LONG e, int st );

static BOOL lx_idstart( WCHAR c ) { return ( c >= 'A' && c <= 'Z' ) || ( c >= 'a' && c <= 'z' ) || c == '_'; }
static BOOL lx_idchar( WCHAR c )  { return lx_idstart( c ) || ( c >= '0' && c <= '9' ); }
static BOOL lx_eol( WCHAR c )     { return c == '\r' || c == '\n'; }

/* Lexes t[0..n) from the start (block comments need it) and emits the tokens that
   touch [from, to) with a style other than ST_DEF. bC: a C file; C rules are also used
   between #pragma BEGINDUMP and #pragma ENDDUMP (no && or * comments, backslash escapes). */
static void lex( const WCHAR * t, LONG n, LONG from, LONG to, LEXEMIT emit, void * ctx, BOOL bC )
{
   LONG pos = 0;
   BOOL atLineStart = TRUE, inC = bC;

   if( to > n )
      to = n;
   while( pos < to )
   {
      WCHAR c = t[ pos ], d = pos + 1 < n ? t[ pos + 1 ] : 0;
      LONG s = pos;

      if( lx_eol( c ) )
      {
         pos++;
         atLineStart = TRUE;
         continue;
      }
      if( c == ' ' || c == '\t' )
      {
         pos++;
         continue;
      }
      if( atLineStart )
      {
         atLineStart = FALSE;
         if( c == '*' && d != '/' && ! inC )
         {
            while( pos < n && ! lx_eol( t[ pos ] ) )
               pos++;
            if( pos > from ) emit( ctx, s, pos, ST_COMMENT );
            continue;
         }
         if( c == '#' )
         {
            pos++;
            while( pos < n && lx_idchar( t[ pos ] ) )
               pos++;
            if( pos > from ) emit( ctx, s, pos, ST_PP );
            if( pos - s == 7 && _wcsnicmp( t + s, L"#pragma", 7 ) == 0 && ! bC )
            {
               LONG w = pos, we;
               while( w < n && ( t[ w ] == ' ' || t[ w ] == '\t' ) )
                  w++;
               we = w;
               while( we < n && lx_idchar( t[ we ] ) )
                  we++;
               if( we - w == 9 && _wcsnicmp( t + w, L"BEGINDUMP", 9 ) == 0 )
                  inC = TRUE;
               else if( we - w == 7 && _wcsnicmp( t + w, L"ENDDUMP", 7 ) == 0 )
                  inC = FALSE;
            }
            continue;
         }
         if( ! inC && ( c == 'N' || c == 'n' ) && pos + 4 <= n && _wcsnicmp( t + pos, L"NOTE", 4 ) == 0 &&
             ( pos + 4 == n || t[ pos + 4 ] == ' ' || t[ pos + 4 ] == '\t' || lx_eol( t[ pos + 4 ] ) ) )
         {
            while( pos < n && ! lx_eol( t[ pos ] ) )
               pos++;
            if( pos > from ) emit( ctx, s, pos, ST_COMMENT );
            continue;
         }
      }
      if( ( c == '/' && d == '/' ) || ( c == '&' && d == '&' && ! inC ) )
      {
         while( pos < n && ! lx_eol( t[ pos ] ) )
            pos++;
         if( pos > from ) emit( ctx, s, pos, ST_COMMENT );
         continue;
      }
      if( c == '/' && d == '*' )
      {
         pos += 2;
         while( pos < n && ! ( t[ pos ] == '*' && pos + 1 < n && t[ pos + 1 ] == '/' ) )
            pos++;
         pos = pos < n ? pos + 2 : n;
         if( pos > from ) emit( ctx, s, pos, ST_COMMENT );
         continue;
      }
      if( c == '"' || c == '\'' )
      {
         pos++;
         while( pos < n && t[ pos ] != c && ! lx_eol( t[ pos ] ) )
            pos += ( inC && t[ pos ] == '\\' && pos + 1 < n && ! lx_eol( t[ pos + 1 ] ) ) ? 2 : 1;
         if( pos < n && t[ pos ] == c )
            pos++;
         if( pos > from ) emit( ctx, s, pos, ST_STR );
         continue;
      }
      if( ( c >= '0' && c <= '9' ) || ( c == '.' && d >= '0' && d <= '9' ) )
      {
         pos++;
         while( pos < n && ( lx_idchar( t[ pos ] ) || t[ pos ] == '.' ) )
         {
            if( t[ pos ] == '.' && pos + 1 < n && ! ( t[ pos + 1 ] >= '0' && t[ pos + 1 ] <= '9' ) )
               break;   /* 1.AND. */
            pos++;
         }
         if( pos > from ) emit( ctx, s, pos, ST_NUM );
         continue;
      }
      if( c == '.' && lx_idstart( d ) )
      {
         LONG e = pos + 1;
         while( e < n && e - pos <= 4 && ( ( t[ e ] >= 'A' && t[ e ] <= 'Z' ) || ( t[ e ] >= 'a' && t[ e ] <= 'z' ) ) )
            e++;
         if( e < n && t[ e ] == '.' )
         {
            WCHAR w[ 8 ];
            int k = ( int ) ( e - pos - 1 ), i;
            for( i = 0; i < k; i++ )
               w[ i ] = ( WCHAR ) towupper( t[ pos + 1 + i ] );
            w[ k ] = 0;
            if( wcscmp( w, L"T" ) == 0 || wcscmp( w, L"F" ) == 0 || wcscmp( w, L"Y" ) == 0 || wcscmp( w, L"N" ) == 0 ||
                wcscmp( w, L"AND" ) == 0 || wcscmp( w, L"OR" ) == 0 || wcscmp( w, L"NOT" ) == 0 )
            {
               pos = e + 1;
               if( pos > from ) emit( ctx, s, pos, ST_CONST );
               continue;
            }
         }
         pos++;
         continue;
      }
      if( lx_idstart( c ) )
      {
         pos++;
         while( pos < n && lx_idchar( t[ pos ] ) )
            pos++;
         if( pos - s == 1 && ( c == 'e' || c == 'E' ) && pos < n && t[ pos ] == '"' )
         {  /* e"..." with backslash escapes */
            pos++;
            while( pos < n && t[ pos ] != '"' && ! lx_eol( t[ pos ] ) )
               pos += ( t[ pos ] == '\\' && pos + 1 < n && ! lx_eol( t[ pos + 1 ] ) ) ? 2 : 1;
            if( pos < n && t[ pos ] == '"' )
               pos++;
            if( pos > from ) emit( ctx, s, pos, ST_STR );
            continue;
         }
         if( pos > from )
         {
            int g = kw_find( t + s, ( int ) ( pos - s ) );
            if( g )
               emit( ctx, s, pos, g );   /* groups 1..7 are ST_LANG..ST_CONST */
         }
         continue;
      }
      pos++;
   }
}

/* ------------------------------------------------------------------ data */

typedef struct { const WCHAR * name; const WCHAR * hint; BOOL own; } ACITEM;   /* a completion */

typedef struct _EDHOST
{
   HWND     hHost, hTab;
   BOOL     bDark;
   WCHAR    face[ LF_FACESIZE ];
   int      nSize, nIndent, nTabWidth;
   HFONT    hFont, hTabFont;
   int      charW, tabH, lineH;
   HWND     hPop, hList;           /* the completion list (ac_ below) */
   struct _EDDOC * acDoc;          /* the file it is open for, NULL: closed */
   LONG     acStart;               /* where the word being completed starts */
   BOOL     acMember, acForced;
   ACITEM * ac;                    /* the candidates, sorted */
   int      acN, acCap;
} EDHOST;

typedef struct _EDDOC
{
   HWND             hView, hRich, hHost;
   EDHOST *         host;
   ITextDocument *  pDoc;
   WCHAR *          text;
   LONG             len, textVer, ver;
   LONG             hlFrom, hlTo, hlVer;
   int              firstLine, lineCount, caretLine, gutterW;
   BOOL             bModified, inHL, bC;
} EDDOC;

static UINT s_cp = CP_UTF8;   /* code page of Harbour strings: UTF-8 (UNICODE mode) or ANSI */

#define HL_TIMER   1

static BOOL ed_event( HWND hHost, int ev, HWND hView, HB_MAXINT arg )
{
   PHB_DYNS s = hb_dynsymFindName( "IDE_ED_EVENT" );
   BOOL r = FALSE;
   if( ! s || ! hHost )
      return FALSE;
   if( hb_vmRequestReenter() )
   {
      hb_vmPushDynSym( s );
      hb_vmPushNil();
      hb_vmPushNumInt( ( HB_PTRUINT ) hHost );
      hb_vmPushInteger( ev );
      hb_vmPushNumInt( ( HB_PTRUINT ) hView );
      hb_vmPushNumInt( arg );
      hb_vmFunction( 4 );
      r = hb_parl( -1 );
      hb_vmRequestRestore();
   }
   return r;
}

static EDDOC *  ed_doc( HWND hView )  { return hView && IsWindow( hView ) ? ( EDDOC * ) GetWindowLongPtrW( hView, GWLP_USERDATA ) : NULL; }
static EDHOST * ed_host( HWND hHost ) { return hHost && IsWindow( hHost ) ? ( EDHOST * ) GetWindowLongPtrW( hHost, GWLP_USERDATA ) : NULL; }

static const COLORREF * ed_pal( EDHOST * h ) { return h->bDark ? s_palDark : s_palLight; }

static int ed_dpi( HWND hWnd )
{
   typedef UINT ( WINAPI * PFN )( HWND );
   static PFN pfn = NULL;
   static BOOL tried = FALSE;
   int dpi = 0;
   if( ! tried )
   {
      tried = TRUE;
      pfn = ( PFN ) ( void * ) GetProcAddress( GetModuleHandleW( L"user32.dll" ), "GetDpiForWindow" );
   }
   if( pfn && hWnd )
      dpi = ( int ) pfn( hWnd );
   if( dpi <= 0 )
   {
      HDC hdc = GetDC( NULL );
      dpi = GetDeviceCaps( hdc, LOGPIXELSY );
      ReleaseDC( NULL, hdc );
   }
   return dpi;
}

static void ed_theme( HWND hWnd, BOOL bDark )
{
   typedef HRESULT ( WINAPI * PFN )( HWND, LPCWSTR, LPCWSTR );
   static PFN pfn = NULL;
   static BOOL tried = FALSE;
   if( ! tried )
   {
      HMODULE hUx = LoadLibraryW( L"uxtheme.dll" );
      tried = TRUE;
      if( hUx )
         pfn = ( PFN ) ( void * ) GetProcAddress( hUx, "SetWindowTheme" );
   }
   if( pfn )
      pfn( hWnd, bDark ? L"DarkMode_Explorer" : L"Explorer", NULL );
}

/* ------------------------------------------------------------------ text helpers */

static WCHAR * ed_towide( const char * s, HB_SIZE n, UINT cp, int * pLen )
{
   int m = n ? MultiByteToWideChar( cp, 0, s, ( int ) n, NULL, 0 ) : 0;
   WCHAR * w = ( WCHAR * ) hb_xgrab( ( m + 1 ) * sizeof( WCHAR ) );
   if( m )
      MultiByteToWideChar( cp, 0, s, ( int ) n, w, m );
   w[ m ] = 0;
   if( pLen )
      *pLen = m;
   return w;
}

/* a Harbour string as wide text, CRLF and LF made CR (RichEdit's paragraph mark) */
static WCHAR * ed_parw( int iParam, int * pLen )
{
   int n, i, j;
   WCHAR * w = ed_towide( hb_parcx( iParam ), hb_parclen( iParam ), s_cp, &n );
   for( i = j = 0; i < n; i++ )
   {
      if( w[ i ] == '\r' && i + 1 < n && w[ i + 1 ] == '\n' )
         continue;
      w[ j++ ] = w[ i ] == '\n' ? '\r' : w[ i ];
   }
   w[ j ] = 0;
   if( pLen )
      *pLen = j;
   return w;
}

/* returns wide text (CR line ends) as a Harbour string with CRLF */
static void ed_retw( const WCHAR * w, LONG n )
{
   LONG i, nCR = 0, k = 0;
   WCHAR * x;
   int m;
   char * b;
   for( i = 0; i < n; i++ )
      if( w[ i ] == '\r' )
         nCR++;
   x = ( WCHAR * ) hb_xgrab( ( n + nCR + 1 ) * sizeof( WCHAR ) );
   for( i = 0; i < n; i++ )
   {
      x[ k++ ] = w[ i ];
      if( w[ i ] == '\r' )
         x[ k++ ] = '\n';
   }
   m = k ? WideCharToMultiByte( s_cp, 0, x, ( int ) k, NULL, 0, NULL, NULL ) : 0;
   b = ( char * ) hb_xgrab( m + 1 );
   if( m )
      WideCharToMultiByte( s_cp, 0, x, ( int ) k, b, m, NULL, NULL );
   b[ m ] = 0;
   hb_retclen_buffer( b, m );
   hb_xfree( x );
}

/* refreshes the cached copy of the document's text */
static void ed_fetch( EDDOC * d )
{
   GETTEXTLENGTHEX gl;
   GETTEXTEX gt;
   LONG n;
   if( d->text && d->textVer == d->ver )
      return;
   gl.flags = GTL_NUMCHARS | GTL_PRECISE;
   gl.codepage = 1200;
   n = ( LONG ) SendMessageW( d->hRich, EM_GETTEXTLENGTHEX, ( WPARAM ) &gl, 0 );
   if( d->text )
      hb_xfree( d->text );
   d->text = ( WCHAR * ) hb_xgrab( ( n + 1 ) * sizeof( WCHAR ) );
   memset( &gt, 0, sizeof( gt ) );
   gt.cb = ( DWORD ) ( ( n + 1 ) * sizeof( WCHAR ) );
   gt.flags = GT_DEFAULT;
   gt.codepage = 1200;
   d->len = ( LONG ) SendMessageW( d->hRich, EM_GETTEXTEX, ( WPARAM ) &gt, ( LPARAM ) d->text );
   if( d->len < 0 || d->len > n )
      d->len = 0;
   d->text[ d->len ] = 0;
   d->textVer = d->ver;
}

static LONG ed_lineindex( EDDOC * d, LONG line ) { return ( LONG ) SendMessageW( d->hRich, EM_LINEINDEX, ( WPARAM ) line, 0 ); }
static LONG ed_linefromchar( EDDOC * d, LONG cp ) { return ( LONG ) SendMessageW( d->hRich, EM_EXLINEFROMCHAR, 0, ( LPARAM ) cp ); }
static LONG ed_linecount( EDDOC * d ) { return ( LONG ) SendMessageW( d->hRich, EM_GETLINECOUNT, 0, 0 ); }

static void ed_getsel( EDDOC * d, LONG * s, LONG * e )
{
   CHARRANGE cr;
   SendMessageW( d->hRich, EM_EXGETSEL, 0, ( LPARAM ) &cr );
   *s = cr.cpMin;
   *e = cr.cpMax;
}

static void ed_setsel( EDDOC * d, LONG s, LONG e )
{
   CHARRANGE cr;
   cr.cpMin = s;
   cr.cpMax = e;
   SendMessageW( d->hRich, EM_EXSETSEL, 0, ( LPARAM ) &cr );
}

/* ------------------------------------------------------------------ colouring */

typedef struct { EDDOC * d; const COLORREF * pal; } HLCTX;

static void ed_style( ITextDocument * pDoc, LONG s, LONG e, int st, const COLORREF * pal )
{
   ITextRange * r = NULL;
   ITextFont * f = NULL;
   if( ITextDocument_Range( pDoc, s, e, &r ) == S_OK && r )
   {
      if( ITextRange_GetFont( r, &f ) == S_OK && f )
      {
         ITextFont_SetForeColor( f, ( long ) pal[ st ] );
         ITextFont_SetBold( f, s_bold[ st ] ? tomTrue : tomFalse );
         ITextFont_SetItalic( f, s_italic[ st ] ? tomTrue : tomFalse );
         ITextFont_Release( f );
      }
      ITextRange_Release( r );
   }
}

static void hl_emit( void * ctx, LONG s, LONG e, int st )
{
   HLCTX * c = ( HLCTX * ) ctx;
   ed_style( c->d->pDoc, s, e, st, c->pal );
}

/* colours the visible lines (and one screen above and below); bForce: even if done */
static void ed_highlight( EDDOC * d, BOOL bForce )
{
   RECT rc;
   POINTL pt;
   LONG first, last, cnt, a, b, cpA, cpB, cpBottom, margin, mask, cnt0 = 0;
   BOOL bMod;
   HLCTX ctx;

   if( ! d || d->inHL || ! d->pDoc )
      return;
   first = ( LONG ) SendMessageW( d->hRich, EM_GETFIRSTVISIBLELINE, 0, 0 );
   GetClientRect( d->hRich, &rc );
   pt.x = 0;
   pt.y = rc.bottom > 0 ? rc.bottom - 1 : 0;
   cpBottom = ( LONG ) SendMessageW( d->hRich, EM_CHARFROMPOS, 0, ( LPARAM ) &pt );
   last = ed_linefromchar( d, cpBottom );
   cnt = ed_linecount( d );
   margin = last - first + 1;
   a = first - margin < 0 ? 0 : first - margin;
   b = last + margin >= cnt ? cnt - 1 : last + margin;
   cpA = ed_lineindex( d, a );
   ed_fetch( d );
   cpB = b + 1 < cnt ? ed_lineindex( d, b + 1 ) : d->len;
   if( cpB > d->len )
      cpB = d->len;
   if( ! bForce && d->hlVer == d->ver && cpA >= d->hlFrom && cpB <= d->hlTo )
      return;

   d->inHL = TRUE;
   mask = ( LONG ) SendMessageW( d->hRich, EM_GETEVENTMASK, 0, 0 );
   SendMessageW( d->hRich, EM_SETEVENTMASK, 0, 0 );
   bMod = ( BOOL ) SendMessageW( d->hRich, EM_GETMODIFY, 0, 0 );
   ITextDocument_Freeze( d->pDoc, &cnt0 );
   ITextDocument_Undo( d->pDoc, tomSuspend, NULL );

   ctx.d = d;
   ctx.pal = ed_pal( d->host );
   if( cpB > cpA )
   {
      ed_style( d->pDoc, cpA, cpB, ST_DEF, ctx.pal );
      lex( d->text, d->len, cpA, cpB, hl_emit, &ctx, d->bC );
   }

   ITextDocument_Undo( d->pDoc, tomResume, NULL );
   ITextDocument_Unfreeze( d->pDoc, &cnt0 );
   SendMessageW( d->hRich, EM_SETMODIFY, ( WPARAM ) bMod, 0 );
   SendMessageW( d->hRich, EM_SETEVENTMASK, 0, ( LPARAM ) mask );
   d->inHL = FALSE;

   if( d->hlVer == d->ver && cpA <= d->hlTo && cpB >= d->hlFrom )
   {
      if( cpA < d->hlFrom ) d->hlFrom = cpA;
      if( cpB > d->hlTo )   d->hlTo = cpB;
   }
   else
   {
      d->hlFrom = cpA;
      d->hlTo = cpB;
      d->hlVer = d->ver;
   }
}

/* ------------------------------------------------------------------ view */

static int ed_digits( LONG n ) { int k = 1; while( n >= 10 ) { n /= 10; k++; } return k; }

static void ed_layout( EDDOC * d )
{
   RECT rc;
   int digits = ed_digits( d->lineCount > 0 ? d->lineCount : 1 );
   if( digits < 3 )
      digits = 3;
   d->gutterW = d->host->charW * ( digits + 1 ) + MulDiv( 8, ed_dpi( d->hView ), 96 );
   GetClientRect( d->hView, &rc );
   MoveWindow( d->hRich, d->gutterW, 0, rc.right - d->gutterW > 0 ? rc.right - d->gutterW : 0, rc.bottom, TRUE );
   InvalidateRect( d->hView, NULL, TRUE );
}

/* after anything that may have scrolled or changed the line count */
static void ed_checkview( EDDOC * d )
{
   LONG first, cnt, s, e, line;
   RECT rc;
   BOOL scrolled;
   if( ! d || d->inHL )
      return;
   first = ( LONG ) SendMessageW( d->hRich, EM_GETFIRSTVISIBLELINE, 0, 0 );
   cnt = ed_linecount( d );
   ed_getsel( d, &s, &e );
   line = ed_linefromchar( d, e );
   if( cnt != d->lineCount )
   {
      BOOL relayout = ed_digits( cnt ) != ed_digits( d->lineCount );
      d->lineCount = cnt;
      if( relayout )
         ed_layout( d );
   }
   scrolled = first != d->firstLine;
   if( scrolled || line != d->caretLine )
   {
      d->firstLine = first;
      d->caretLine = line;
      GetClientRect( d->hView, &rc );
      rc.right = d->gutterW;
      InvalidateRect( d->hView, &rc, FALSE );
   }
   /* scrolled into lines not coloured yet: now, before they are painted;
      after typing, the timer colours (once the typing pauses) */
   if( scrolled && d->hlVer == d->ver )
      ed_highlight( d, FALSE );
}

static void ed_paintgutter( EDDOC * d, HDC hdc )
{
   RECT rc, r;
   HBRUSH hbr;
   HFONT hOld;
   LONG line, cnt, cp;
   POINTL pt;
   WCHAR buf[ 16 ];
   BOOL dark = d->host->bDark;

   GetClientRect( d->hView, &rc );
   rc.right = d->gutterW;
   hbr = CreateSolidBrush( dark ? GUT_DARK : GUT_LIGHT );
   FillRect( hdc, &rc, hbr );
   DeleteObject( hbr );
   hOld = ( HFONT ) SelectObject( hdc, d->host->hFont );
   SetBkMode( hdc, TRANSPARENT );
   cnt = ed_linecount( d );
   for( line = ( LONG ) SendMessageW( d->hRich, EM_GETFIRSTVISIBLELINE, 0, 0 ); line < cnt; line++ )
   {
      cp = ed_lineindex( d, line );
      if( cp < 0 )
         break;
      SendMessageW( d->hRich, EM_POSFROMCHAR, ( WPARAM ) &pt, ( LPARAM ) cp );
      if( pt.y > rc.bottom )
         break;
      SetTextColor( hdc, line == d->caretLine ? ( dark ? GUTCUR_DARK : GUTCUR_LIGHT ) : ( dark ? GUTTXT_DARK : GUTTXT_LIGHT ) );
      r.left = 0;
      r.right = d->gutterW - d->host->charW / 2 - MulDiv( 4, ed_dpi( d->hView ), 96 );
      r.top = pt.y;
      r.bottom = pt.y + 200;
      _snwprintf( buf, 16, L"%ld", ( long ) line + 1 );
      buf[ 15 ] = 0;
      DrawTextW( hdc, buf, -1, &r, DT_RIGHT | DT_TOP | DT_SINGLELINE | DT_NOPREFIX );
   }
   SelectObject( hdc, hOld );
}

/* plain text only: the clipboard's Unicode text, never RTF or objects */
static void ed_paste( EDDOC * d )
{
   SendMessageW( d->hRich, EM_PASTESPECIAL, CF_UNICODETEXT, 0 );
}

/* Tab / Shift+Tab / Ctrl+Q on whole lines: mode 1 indent, 2 outdent, 3 toggle // */
static void ed_blockop( EDDOC * d, int mode )
{
   LONG s, e, l1, l2, a, b, i, lineStart, nOut = 0, delta = 0, caretLine;
   WCHAR * out;
   int ind = d->host->nIndent, minWs = 0x7FFFFFFF;
   BOOL allCommented = TRUE, anyLine = FALSE, single;

   ed_getsel( d, &s, &e );
   ed_fetch( d );
   l1 = ed_linefromchar( d, s );
   l2 = ed_linefromchar( d, e );
   if( e > s && l2 > l1 && ed_lineindex( d, l2 ) == e )
      l2--;
   single = ( s == e ) || l1 == l2;
   a = ed_lineindex( d, l1 );
   b = ed_lineindex( d, l2 ) + ( LONG ) SendMessageW( d->hRich, EM_LINELENGTH, ( WPARAM ) ed_lineindex( d, l2 ), 0 );
   if( a < 0 || b < a || b > d->len )
      return;
   caretLine = ed_linefromchar( d, s );

   /* first pass: comment state and the smallest indent */
   for( i = a; i <= b; )
   {
      LONG j = i, ws;
      while( j < b && ( d->text[ j ] == ' ' || d->text[ j ] == '\t' ) )
         j++;
      ws = j - i;
      if( j < b && d->text[ j ] != '\r' )
      {
         anyLine = TRUE;
         if( ws < minWs )
            minWs = ( int ) ws;
         if( ! ( j + 1 < b && d->text[ j ] == '/' && d->text[ j + 1 ] == '/' ) )
            allCommented = FALSE;
      }
      while( i < b && d->text[ i ] != '\r' )
         i++;
      i++;
   }
   if( mode == 3 && ! anyLine )
      return;

   out = ( WCHAR * ) hb_xgrab( ( ( b - a ) * 2 + ( l2 - l1 + 1 ) * ( ind + 4 ) + 8 ) * sizeof( WCHAR ) );
   for( lineStart = a; lineStart <= b; )
   {
      LONG lineEnd = lineStart, j, k;
      LONG before = nOut;
      while( lineEnd < b && d->text[ lineEnd ] != '\r' )
         lineEnd++;
      j = lineStart;
      while( j < lineEnd && ( d->text[ j ] == ' ' || d->text[ j ] == '\t' ) )
         j++;
      if( mode == 1 )
      {
         if( j < lineEnd || single )
            for( k = 0; k < ind; k++ )
               out[ nOut++ ] = ' ';
         for( k = lineStart; k < lineEnd; k++ )
            out[ nOut++ ] = d->text[ k ];
      }
      else if( mode == 2 )
      {
         LONG skip = 0;
         if( lineStart < lineEnd && d->text[ lineStart ] == '\t' )
            skip = 1;
         else
            while( skip < ind && lineStart + skip < lineEnd && d->text[ lineStart + skip ] == ' ' )
               skip++;
         for( k = lineStart + skip; k < lineEnd; k++ )
            out[ nOut++ ] = d->text[ k ];
      }
      else
      {
         if( j >= lineEnd )
         {
            for( k = lineStart; k < lineEnd; k++ )
               out[ nOut++ ] = d->text[ k ];
         }
         else if( allCommented )
         {
            for( k = lineStart; k < j; k++ )
               out[ nOut++ ] = d->text[ k ];
            k = j + 2;
            if( k < lineEnd && d->text[ k ] == ' ' )
               k++;
            for( ; k < lineEnd; k++ )
               out[ nOut++ ] = d->text[ k ];
         }
         else
         {
            for( k = lineStart; k < lineStart + minWs; k++ )
               out[ nOut++ ] = d->text[ k ];
            out[ nOut++ ] = '/';
            out[ nOut++ ] = '/';
            out[ nOut++ ] = ' ';
            for( k = lineStart + minWs; k < lineEnd; k++ )
               out[ nOut++ ] = d->text[ k ];
         }
      }
      if( ed_linefromchar( d, lineStart ) == caretLine )
         delta = ( nOut - before ) - ( lineEnd - lineStart );
      if( lineEnd < b )
         out[ nOut++ ] = '\r';
      lineStart = lineEnd + 1;
   }
   out[ nOut ] = 0;

   if( nOut != b - a || wmemcmp( out, d->text + a, ( size_t ) nOut ) != 0 )
   {
      ed_setsel( d, a, b );
      SendMessageW( d->hRich, EM_REPLACESEL, TRUE, ( LPARAM ) out );
      if( single )
      {
         LONG c = s + delta;
         LONG ls = ed_lineindex( d, caretLine );
         if( c < ls )
            c = ls;
         ed_setsel( d, c, c );
      }
      else
         ed_setsel( d, a, a + nOut );
   }
   hb_xfree( out );
   ed_checkview( d );
}

/* Tab without a multi-line selection: spaces up to the next indent column */
static void ed_tab( EDDOC * d )
{
   LONG s, e, col;
   WCHAR sp[ 64 ];
   int n, i;
   ed_getsel( d, &s, &e );
   col = s - ed_lineindex( d, ed_linefromchar( d, s ) );
   n = d->host->nIndent - ( int ) ( col % d->host->nIndent );
   if( n < 1 || n > 63 )
      n = 1;
   for( i = 0; i < n; i++ )
      sp[ i ] = ' ';
   sp[ n ] = 0;
   SendMessageW( d->hRich, EM_REPLACESEL, TRUE, ( LPARAM ) sp );
}

/* Enter: a new line with the indent of the current one */
static void ed_enter( EDDOC * d )
{
   LONG s, e, a, n, i;
   TEXTRANGEW tr;
   WCHAR * buf, * ins;
   ed_getsel( d, &s, &e );
   a = ed_lineindex( d, ed_linefromchar( d, s ) );
   n = s - a;
   buf = ( WCHAR * ) hb_xgrab( ( n + 2 ) * sizeof( WCHAR ) );
   tr.chrg.cpMin = a;
   tr.chrg.cpMax = s;
   tr.lpstrText = buf;
   n = ( LONG ) SendMessageW( d->hRich, EM_GETTEXTRANGE, 0, ( LPARAM ) &tr );
   for( i = 0; i < n && ( buf[ i ] == ' ' || buf[ i ] == '\t' ); i++ )
      ;
   ins = ( WCHAR * ) hb_xgrab( ( i + 2 ) * sizeof( WCHAR ) );
   ins[ 0 ] = '\r';
   memcpy( ins + 1, buf, i * sizeof( WCHAR ) );
   ins[ i + 1 ] = 0;
   SendMessageW( d->hRich, EM_REPLACESEL, TRUE, ( LPARAM ) ins );
   SendMessageW( d->hRich, EM_SCROLLCARET, 0, 0 );
   hb_xfree( ins );
   hb_xfree( buf );
}

#define CMD_UNDO      1
#define CMD_REDO      2
#define CMD_CUT       3
#define CMD_COPY      4
#define CMD_PASTE     5
#define CMD_DELETE    6
#define CMD_SELALL    7
#define CMD_INDENT    8
#define CMD_OUTDENT   9
#define CMD_COMMENT  10
#define CMD_CANUNDO  11
#define CMD_CANREDO  12

static BOOL ed_command( EDDOC * d, int cmd )
{
   switch( cmd )
   {
      case CMD_UNDO:    SendMessageW( d->hRich, EM_UNDO, 0, 0 ); break;
      case CMD_REDO:    SendMessageW( d->hRich, EM_REDO, 0, 0 ); break;
      case CMD_CUT:     SendMessageW( d->hRich, WM_CUT, 0, 0 ); break;
      case CMD_COPY:    SendMessageW( d->hRich, WM_COPY, 0, 0 ); break;
      case CMD_PASTE:   ed_paste( d ); break;
      case CMD_DELETE:  SendMessageW( d->hRich, WM_CLEAR, 0, 0 ); break;
      case CMD_SELALL:  ed_setsel( d, 0, -1 ); break;
      case CMD_INDENT:  ed_blockop( d, 1 ); break;
      case CMD_OUTDENT: ed_blockop( d, 2 ); break;
      case CMD_COMMENT: ed_blockop( d, 3 ); break;
      case CMD_CANUNDO: return ( BOOL ) SendMessageW( d->hRich, EM_CANUNDO, 0, 0 );
      case CMD_CANREDO: return ( BOOL ) SendMessageW( d->hRich, EM_CANREDO, 0, 0 );
      default:          return FALSE;
   }
   ed_checkview( d );
   return TRUE;
}

static void ed_contextmenu( EDDOC * d, int x, int y )
{
   HMENU hm = CreatePopupMenu();
   LONG s, e;
   int cmd;
   ed_getsel( d, &s, &e );
   AppendMenuW( hm, MF_STRING | ( SendMessageW( d->hRich, EM_CANUNDO, 0, 0 ) ? 0 : MF_GRAYED ), CMD_UNDO, L"Undo\tCtrl+Z" );
   AppendMenuW( hm, MF_STRING | ( SendMessageW( d->hRich, EM_CANREDO, 0, 0 ) ? 0 : MF_GRAYED ), CMD_REDO, L"Redo\tCtrl+Y" );
   AppendMenuW( hm, MF_SEPARATOR, 0, NULL );
   AppendMenuW( hm, MF_STRING | ( s != e ? 0 : MF_GRAYED ), CMD_CUT, L"Cut\tCtrl+X" );
   AppendMenuW( hm, MF_STRING | ( s != e ? 0 : MF_GRAYED ), CMD_COPY, L"Copy\tCtrl+C" );
   AppendMenuW( hm, MF_STRING | ( IsClipboardFormatAvailable( CF_UNICODETEXT ) ? 0 : MF_GRAYED ), CMD_PASTE, L"Paste\tCtrl+V" );
   AppendMenuW( hm, MF_STRING | ( s != e ? 0 : MF_GRAYED ), CMD_DELETE, L"Delete" );
   AppendMenuW( hm, MF_SEPARATOR, 0, NULL );
   AppendMenuW( hm, MF_STRING, CMD_SELALL, L"Select All\tCtrl+A" );
   AppendMenuW( hm, MF_SEPARATOR, 0, NULL );
   AppendMenuW( hm, MF_STRING, CMD_COMMENT, L"Comment / Uncomment\tCtrl+Q" );
   if( x == -1 && y == -1 )
   {
      POINT p;
      GetCaretPos( &p );
      ClientToScreen( d->hRich, &p );
      x = p.x;
      y = p.y;
   }
   cmd = TrackPopupMenu( hm, TPM_RETURNCMD | TPM_RIGHTBUTTON, x, y, 0, d->hRich, NULL );
   DestroyMenu( hm );
   if( cmd )
      ed_command( d, cmd );
}

static int ed_mods( void )
{
   return ( GetKeyState( VK_CONTROL ) < 0 ? 0x10000 : 0 ) | ( GetKeyState( VK_SHIFT ) < 0 ? 0x20000 : 0 ) | ( GetKeyState( VK_MENU ) < 0 ? 0x40000 : 0 );
}

/* ------------------------------------------------------------------ completion

   A list under the word being typed: after 3 letters, the words of the file and the
   HMG5/Harbour keywords; after "Form." or "Form.Control.", what IDE_ED_MEMBERS( hView,
   cChain ) returns (ide_complete.prg: the project's controls, properties, methods).
   Ctrl+Space opens it at once. Up/Down/PgUp/PgDn choose, Enter or Tab inserts,
   Esc closes. The list never takes the focus: the keys stay with the editor. */

#define AC_MINLEN   3       /* letters before the list opens by itself */
#define AC_ROWS     10
#define AC_MAXSHOW  500

static const WCHAR ** s_acKw = NULL;   /* the keywords in their own case, sorted, no duplicates */
static int s_acKwN = 0;
static HBRUSH s_acBr[ 2 ] = { NULL, NULL };

static WCHAR ac_up( WCHAR c ) { return ( c >= 'a' && c <= 'z' ) ? ( WCHAR ) ( c - 32 ) : c; }

static int ac_cmp( const WCHAR * a, const WCHAR * b )
{
   while( *a && ac_up( *a ) == ac_up( *b ) )
   {
      a++;
      b++;
   }
   return ( int ) ac_up( *a ) - ( int ) ac_up( *b );
}

static BOOL ac_prefix( const WCHAR * w, const WCHAR * p, int n )
{
   int i;
   for( i = 0; i < n; i++ )
      if( ! w[ i ] || ac_up( w[ i ] ) != ac_up( p[ i ] ) )
         return FALSE;
   return TRUE;
}

static int ac_qcmpw( const void * a, const void * b ) { return ac_cmp( *( const WCHAR * const * ) a, *( const WCHAR * const * ) b ); }
static int ac_qcmpi( const void * a, const void * b ) { return ac_cmp( ( ( const ACITEM * ) a )->name, ( ( const ACITEM * ) b )->name ); }

static void ac_kwinit( void )
{
   const char * p = s_kwText;
   int n = 0, cap = 4096, i, k;
   WCHAR ** a;
   if( s_acKw )
      return;
   a = ( WCHAR ** ) malloc( cap * sizeof( WCHAR * ) );
   while( *p )
   {
      const char * e = p;
      while( *e && *e != '\n' )
         e++;
      if( *p >= '1' && *p <= '7' && p[ 1 ] == ' ' )
      {
         const char * w = p + 2, * we = e;
         while( we > w && ( we[ -1 ] == '\r' || we[ -1 ] == ' ' ) )
            we--;
         if( we - w >= 2 && lx_idstart( ( WCHAR ) ( unsigned char ) *w ) )
         {
            WCHAR * x = ( WCHAR * ) malloc( ( we - w + 1 ) * sizeof( WCHAR ) );
            for( i = 0; i < we - w; i++ )
               x[ i ] = ( WCHAR ) ( unsigned char ) w[ i ];
            x[ we - w ] = 0;
            if( n == cap )
               a = ( WCHAR ** ) realloc( a, ( cap *= 2 ) * sizeof( WCHAR * ) );
            a[ n++ ] = x;
         }
      }
      p = *e ? e + 1 : e;
   }
   qsort( a, n, sizeof( WCHAR * ), ac_qcmpw );
   for( i = 0, k = 0; i < n; i++ )
   {
      if( k > 0 && ac_cmp( a[ k - 1 ], a[ i ] ) == 0 )
         free( a[ i ] );
      else
         a[ k++ ] = a[ i ];
   }
   s_acKw = ( const WCHAR ** ) a;
   s_acKwN = k;
}

static void ac_clear( EDHOST * h )
{
   int i;
   for( i = 0; i < h->acN; i++ )
      if( h->ac[ i ].own )
         hb_xfree( ( void * ) h->ac[ i ].name );   /* name and hint are one block */
   if( h->ac )
      hb_xfree( h->ac );
   h->ac = NULL;
   h->acN = h->acCap = 0;
}

static void ac_add( EDHOST * h, const WCHAR * name, int nName, const WCHAR * hint, int nHint, BOOL copy )
{
   ACITEM * it;
   if( h->acN == h->acCap )
   {
      h->acCap = h->acCap ? h->acCap * 2 : 256;
      h->ac = ( ACITEM * ) hb_xrealloc( h->ac, h->acCap * sizeof( ACITEM ) );
   }
   it = &h->ac[ h->acN++ ];
   if( copy )
   {
      WCHAR * b = ( WCHAR * ) hb_xgrab( ( nName + nHint + 2 ) * sizeof( WCHAR ) );
      memcpy( b, name, nName * sizeof( WCHAR ) );
      b[ nName ] = 0;
      if( nHint > 0 )
         memcpy( b + nName + 1, hint, nHint * sizeof( WCHAR ) );
      b[ nName + 1 + nHint ] = 0;
      it->name = b;
      it->hint = nHint > 0 ? b + nName + 1 : NULL;
      it->own = TRUE;
   }
   else
   {
      it->name = name;
      it->hint = NULL;
      it->own = FALSE;
   }
}

static void ac_hide( EDHOST * h )
{
   if( ! h )
      return;
   if( h->hPop && IsWindowVisible( h->hPop ) )
      ShowWindow( h->hPop, SW_HIDE );
   if( h->hList )
      SendMessageW( h->hList, LB_RESETCONTENT, 0, 0 );
   ac_clear( h );
   h->acDoc = NULL;
}

static BOOL ac_visible( EDDOC * d )
{
   return d && d->host->acDoc == d && d->host->hPop && IsWindowVisible( d->host->hPop );
}

static void ac_accept( EDHOST * h )
{
   EDDOC * d = h->acDoc;
   LRESULT i;
   LONG s, e;
   const WCHAR * w;
   if( ! d )
      return;
   i = SendMessageW( h->hList, LB_GETCURSEL, 0, 0 );
   if( i == LB_ERR )
   {
      ac_hide( h );
      return;
   }
   i = SendMessageW( h->hList, LB_GETITEMDATA, ( WPARAM ) i, 0 );
   if( i < 0 || i >= h->acN )
   {
      ac_hide( h );
      return;
   }
   w = h->ac[ i ].name;
   ed_getsel( d, &s, &e );
   ed_setsel( d, h->acStart, e );
   SendMessageW( d->hRich, EM_REPLACESEL, TRUE, ( LPARAM ) w );
   ac_hide( h );
   ed_checkview( d );
}

static LRESULT CALLBACK ac_listproc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam, UINT_PTR uId, DWORD_PTR ref )
{
   EDHOST * h = ( EDHOST * ) ref;
   ( void ) uId;
   switch( msg )
   {
      case WM_MOUSEACTIVATE:
         return MA_NOACTIVATE;
      case WM_LBUTTONDOWN:
      {
         LRESULT r = SendMessageW( hWnd, LB_ITEMFROMPOINT, 0, lParam );
         if( HIWORD( r ) == 0 )
            SendMessageW( hWnd, LB_SETCURSEL, LOWORD( r ), 0 );
         return 0;   /* no focus for the list */
      }
      case WM_LBUTTONDBLCLK:
         ac_accept( h );
         return 0;
      case WM_NCDESTROY:
         RemoveWindowSubclass( hWnd, ac_listproc, 1 );
         break;
   }
   return DefSubclassProc( hWnd, msg, wParam, lParam );
}

static LRESULT CALLBACK ac_popproc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   EDHOST * h = ( EDHOST * ) GetWindowLongPtrW( hWnd, GWLP_USERDATA );
   switch( msg )
   {
      case WM_MOUSEACTIVATE:
         return MA_NOACTIVATE;
      case WM_CTLCOLORLISTBOX:
         if( h )
            return ( LRESULT ) s_acBr[ h->bDark ? 1 : 0 ];
         break;
      case WM_DRAWITEM:
      {
         DRAWITEMSTRUCT * di = ( DRAWITEMSTRUCT * ) lParam;
         LRESULT k;
         RECT rc;
         BOOL sel, dark;
         int pad;
         if( ! h || di->itemID == ( UINT ) -1 )
            return TRUE;
         k = ( LRESULT ) di->itemData;
         if( k < 0 || k >= h->acN )
            return TRUE;
         dark = h->bDark;
         sel = ( di->itemState & ODS_SELECTED ) != 0;
         pad = MulDiv( 6, ed_dpi( hWnd ), 96 );
         SetDCBrushColor( di->hDC, sel ? ( dark ? RGB( 4, 57, 94 ) : RGB( 204, 232, 255 ) ) : ( dark ? RGB( 37, 37, 38 ) : RGB( 255, 255, 255 ) ) );
         FillRect( di->hDC, &di->rcItem, ( HBRUSH ) GetStockObject( DC_BRUSH ) );
         SetBkMode( di->hDC, TRANSPARENT );
         SelectObject( di->hDC, h->hFont );
         rc = di->rcItem;
         rc.left += pad;
         rc.right -= pad;
         SetTextColor( di->hDC, dark ? RGB( 220, 220, 220 ) : RGB( 0, 0, 0 ) );
         DrawTextW( di->hDC, h->ac[ k ].name, -1, &rc, DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX );
         if( h->ac[ k ].hint )
         {
            SetTextColor( di->hDC, dark ? RGB( 140, 140, 140 ) : RGB( 120, 120, 120 ) );
            DrawTextW( di->hDC, h->ac[ k ].hint, -1, &rc, DT_RIGHT | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX );
         }
         return TRUE;
      }
   }
   return DefWindowProcW( hWnd, msg, wParam, lParam );
}

static void ac_create( EDHOST * h )
{
   static BOOL reg = FALSE;
   HWND hOwner = GetAncestor( h->hHost, GA_ROOT );
   if( h->hPop && IsWindow( h->hPop ) )
      return;
   if( ! reg )
   {
      WNDCLASSW wc;
      memset( &wc, 0, sizeof( wc ) );
      wc.hInstance = GetModuleHandleW( NULL );
      wc.hCursor = LoadCursor( NULL, IDC_ARROW );
      wc.lpfnWndProc = ac_popproc;
      wc.lpszClassName = L"HMGIDEComplete";
      wc.style = CS_DROPSHADOW;
      RegisterClassW( &wc );
      s_acBr[ 0 ] = CreateSolidBrush( RGB( 255, 255, 255 ) );
      s_acBr[ 1 ] = CreateSolidBrush( RGB( 37, 37, 38 ) );
      reg = TRUE;
   }
   h->hPop = CreateWindowExW( WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE, L"HMGIDEComplete", L"", WS_POPUP | WS_CLIPCHILDREN,
                              0, 0, 100, 100, hOwner, NULL, GetModuleHandleW( NULL ), NULL );
   SetWindowLongPtrW( h->hPop, GWLP_USERDATA, ( LONG_PTR ) h );
   h->hList = CreateWindowExW( 0, L"LISTBOX", L"", WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_BORDER | LBS_NOTIFY |
                               LBS_OWNERDRAWFIXED | LBS_HASSTRINGS | LBS_NOINTEGRALHEIGHT,
                               0, 0, 100, 100, h->hPop, NULL, GetModuleHandleW( NULL ), NULL );
   SendMessageW( h->hList, WM_SETFONT, ( WPARAM ) h->hFont, FALSE );
   SendMessageW( h->hList, LB_SETITEMHEIGHT, 0, h->lineH + MulDiv( 3, ed_dpi( h->hHost ), 96 ) );
   SetWindowSubclass( h->hList, ac_listproc, 1, ( DWORD_PTR ) h );
   ed_theme( h->hList, h->bDark );
}

/* the list for the text typed since acStart; hidden when nothing (more) matches */
static void ac_filter( EDHOST * h )
{
   EDDOC * d = h->acDoc;
   LONG s, e, n, i;
   WCHAR pre[ 80 ];
   TEXTRANGEW tr;
   int shown = 0, itemH, rows, w, hgt, maxN = 0, maxH = 0, pad, sb;
   BOOL exact = FALSE;
   HDC hdc;
   HFONT hOld;
   POINTL pt;
   POINT p;
   MONITORINFO mi;
   SIZE sz;

   if( ! d )
      return;
   ed_getsel( d, &s, &e );
   n = s - h->acStart;
   if( s != e || n < 0 || n >= 79 || ( ! h->acMember && ! h->acForced && n == 0 ) )
   {
      ac_hide( h );
      return;
   }
   tr.chrg.cpMin = h->acStart;
   tr.chrg.cpMax = s;
   tr.lpstrText = pre;
   pre[ 0 ] = 0;
   if( n > 0 )
      SendMessageW( d->hRich, EM_GETTEXTRANGE, 0, ( LPARAM ) &tr );
   pre[ n ] = 0;
   for( i = 0; i < n; i++ )
      if( ! lx_idchar( pre[ i ] ) )
      {
         ac_hide( h );
         return;
      }

   ac_create( h );
   SendMessageW( h->hList, WM_SETREDRAW, FALSE, 0 );
   SendMessageW( h->hList, LB_RESETCONTENT, 0, 0 );
   hdc = GetDC( h->hList );
   hOld = ( HFONT ) SelectObject( hdc, h->hFont );
   for( i = 0; i < h->acN && shown < AC_MAXSHOW; i++ )
   {
      if( ac_prefix( h->ac[ i ].name, pre, ( int ) n ) )
      {
         LRESULT k = SendMessageW( h->hList, LB_ADDSTRING, 0, ( LPARAM ) h->ac[ i ].name );
         SendMessageW( h->hList, LB_SETITEMDATA, ( WPARAM ) k, ( LPARAM ) i );
         GetTextExtentPoint32W( hdc, h->ac[ i ].name, lstrlenW( h->ac[ i ].name ), &sz );
         if( sz.cx > maxN )
            maxN = sz.cx;
         if( h->ac[ i ].hint )
         {
            GetTextExtentPoint32W( hdc, h->ac[ i ].hint, lstrlenW( h->ac[ i ].hint ), &sz );
            if( sz.cx > maxH )
               maxH = sz.cx;
         }
         shown++;
         if( lstrlenW( h->ac[ i ].name ) == n )
            exact = TRUE;
      }
   }
   SelectObject( hdc, hOld );
   ReleaseDC( h->hList, hdc );
   SendMessageW( h->hList, WM_SETREDRAW, TRUE, 0 );
   if( shown == 1 && exact && ! h->acForced )
      shown = 0;   /* only the word itself: nothing to complete */
   if( shown <= 0 )
   {
      ac_hide( h );
      h->acDoc = NULL;
      return;
   }
   SendMessageW( h->hList, LB_SETCURSEL, 0, 0 );

   pad = MulDiv( 6, ed_dpi( h->hHost ), 96 );
   itemH = ( int ) SendMessageW( h->hList, LB_GETITEMHEIGHT, 0, 0 );
   rows = shown < AC_ROWS ? shown : AC_ROWS;
   sb = shown > rows ? GetSystemMetrics( SM_CXVSCROLL ) : 0;
   w = maxN + ( maxH ? maxH + 4 * pad : 0 ) + 2 * pad + sb + 4;
   if( w < MulDiv( 140, ed_dpi( h->hHost ), 96 ) )
      w = MulDiv( 140, ed_dpi( h->hHost ), 96 );
   if( w > MulDiv( 600, ed_dpi( h->hHost ), 96 ) )
      w = MulDiv( 600, ed_dpi( h->hHost ), 96 );
   hgt = rows * itemH + 2 * GetSystemMetrics( SM_CYBORDER );

   SendMessageW( d->hRich, EM_POSFROMCHAR, ( WPARAM ) &pt, h->acStart );
   p.x = pt.x - pad;
   p.y = pt.y;
   ClientToScreen( d->hRich, &p );
   mi.cbSize = sizeof( mi );
   GetMonitorInfoW( MonitorFromPoint( p, MONITOR_DEFAULTTONEAREST ), &mi );
   if( p.y + h->lineH + hgt > mi.rcWork.bottom )
      p.y -= hgt;
   else
      p.y += h->lineH;
   if( p.x + w > mi.rcWork.right )
      p.x = mi.rcWork.right - w;
   if( p.x < mi.rcWork.left )
      p.x = mi.rcWork.left;
   SetWindowPos( h->hPop, HWND_TOP, p.x, p.y, w, hgt, SWP_NOACTIVATE | SWP_SHOWWINDOW );
   MoveWindow( h->hList, 0, 0, w, hgt, TRUE );
}

static void ac_move( EDHOST * h, int nStep )
{
   LRESULT n = SendMessageW( h->hList, LB_GETCOUNT, 0, 0 ), i = SendMessageW( h->hList, LB_GETCURSEL, 0, 0 );
   if( n <= 0 )
      return;
   i += nStep;
   if( i < 0 )
      i = nStep < -1 ? 0 : n - 1;
   else if( i >= n )
      i = nStep > 1 ? n - 1 : 0;
   SendMessageW( h->hList, LB_SETCURSEL, ( WPARAM ) i, 0 );
}

typedef struct { LONG pos; int st; } ACSTYLE;
static void ac_styleemit( void * ctx, LONG s, LONG e, int st )
{
   ACSTYLE * c = ( ACSTYLE * ) ctx;
   if( s <= c->pos && c->pos < e )
      c->st = st;
}

/* IDE_ED_MEMBERS( hView, cChain ) -> { "name" | "name" + Chr( 9 ) + "hint", ... } */
static void ac_members( EDDOC * d, const WCHAR * chain, int nChain )
{
   PHB_DYNS s = hb_dynsymFindName( "IDE_ED_MEMBERS" );
   int m;
   char * b;
   if( ! s || ! hb_vmRequestReenter() )
      return;
   m = WideCharToMultiByte( s_cp, 0, chain, nChain, NULL, 0, NULL, NULL );
   b = ( char * ) hb_xgrab( m + 1 );
   WideCharToMultiByte( s_cp, 0, chain, nChain, b, m, NULL, NULL );
   b[ m ] = 0;
   hb_vmPushDynSym( s );
   hb_vmPushNil();
   hb_vmPushNumInt( ( HB_PTRUINT ) d->hView );
   hb_vmPushString( b, m );
   hb_xfree( b );
   hb_vmFunction( 2 );
   {
      PHB_ITEM a = hb_param( -1, HB_IT_ARRAY );
      HB_SIZE i, n = a ? hb_arrayLen( a ) : 0;
      for( i = 1; i <= n; i++ )
      {
         const char * c = hb_arrayGetCPtr( a, i );
         int nc = ( int ) hb_arrayGetCLen( a, i ), k;
         WCHAR * w;
         int nw;
         if( nc == 0 )
            continue;
         w = ed_towide( c, nc, s_cp, &nw );
         for( k = 0; k < nw && w[ k ] != '\t'; k++ )
            ;
         ac_add( d->host, w, k, w + k + 1, k < nw ? nw - k - 1 : 0, TRUE );
         hb_xfree( w );
      }
   }
   hb_vmRequestRestore();
}

/* the words of the file (3 letters or more, not the one at nSkip) and the keywords */
static void ac_words( EDDOC * d, LONG nSkip )
{
   EDHOST * h = d->host;
   unsigned cap = 1024, mask, k;
   const WCHAR ** set;
   LONG p = 0;
   int i;

   while( cap < ( unsigned ) d->len / 2 && cap < ( 1u << 22 ) )
      cap <<= 1;
   mask = cap - 1;
   set = ( const WCHAR ** ) hb_xgrabz( cap * sizeof( WCHAR * ) );
   while( p < d->len )
   {
      if( lx_idstart( d->text[ p ] ) && ( p == 0 || ! lx_idchar( d->text[ p - 1 ] ) ) )
      {
         LONG q = p;
         while( q < d->len && lx_idchar( d->text[ q ] ) )
            q++;
         if( q - p >= AC_MINLEN && q - p < 64 && p != nSkip && ( unsigned ) h->acN < cap / 2 )
         {
            unsigned hh = 2166136261u;
            LONG j;
            for( j = p; j < q; j++ )
               hh = ( hh ^ ac_up( d->text[ j ] ) ) * 16777619u;
            k = hh & mask;
            while( set[ k ] )
            {
               if( lstrlenW( set[ k ] ) == q - p && ac_prefix( set[ k ], d->text + p, ( int ) ( q - p ) ) )
                  break;
               k = ( k + 1 ) & mask;
            }
            if( ! set[ k ] )
            {
               ac_add( h, d->text + p, ( int ) ( q - p ), NULL, 0, TRUE );
               set[ k ] = h->ac[ h->acN - 1 ].name;
            }
         }
         p = q;
      }
      else
         p++;
   }
   ac_kwinit();
   for( i = 0; i < s_acKwN; i++ )
   {
      const WCHAR * w = s_acKw[ i ];
      int n = lstrlenW( w );
      unsigned hh = 2166136261u;
      int j;
      BOOL found = FALSE;
      for( j = 0; j < n; j++ )
         hh = ( hh ^ ac_up( w[ j ] ) ) * 16777619u;
      k = hh & mask;
      while( set[ k ] )
      {
         if( lstrlenW( set[ k ] ) == n && ac_prefix( set[ k ], w, n ) )
         {
            found = TRUE;   /* the file's own spelling wins */
            break;
         }
         k = ( k + 1 ) & mask;
      }
      if( ! found )
         ac_add( h, w, n, NULL, 0, FALSE );
   }
   hb_xfree( ( void * ) set );
   qsort( h->ac, h->acN, sizeof( ACITEM ), ac_qcmpi );
}

/* opens the list at the caret: bForced (Ctrl+Space) also with fewer letters; after a dot,
   the members of the chain before it. -> TRUE if it is shown */
static BOOL ac_open( EDDOC * d, BOOL bForced )
{
   EDHOST * h = d->host;
   LONG s, e, start, p;
   ACSTYLE cs;

   ac_hide( h );
   ed_getsel( d, &s, &e );
   if( s != e )
      return FALSE;
   d->textVer = -1;
   ed_fetch( d );
   if( s > d->len )
      return FALSE;
   start = s;
   while( start > 0 && lx_idchar( d->text[ start - 1 ] ) )
      start--;
   if( start < s && d->text[ start ] >= '0' && d->text[ start ] <= '9' )
      return FALSE;
   if( start > 0 )
   {
      cs.pos = start - 1;
      cs.st = ST_DEF;
      lex( d->text, d->len, start - 1, start, ac_styleemit, &cs, d->bC );
      if( cs.st == ST_STR || cs.st == ST_COMMENT )
         return FALSE;
   }

   if( start > 0 && d->text[ start - 1 ] == '.' )
   {
      /* Form. / Form.Control. : the chain of names before the dot, each one a name */
      LONG cEnd = start - 1, cBeg = cEnd;
      for( ;; )
      {
         p = cBeg;
         while( p > 0 && lx_idchar( d->text[ p - 1 ] ) )
            p--;
         if( p == cBeg || ! lx_idstart( d->text[ p ] ) )
            return FALSE;
         cBeg = p;
         if( p > 0 && d->text[ p - 1 ] == '.' )
            cBeg = p - 1;
         else
            break;
      }
      if( cBeg > 0 && ( d->text[ cBeg - 1 ] == ':' || d->text[ cBeg - 1 ] == '>' ) )
         return FALSE;   /* oObj:x.y, p->x */
      if( ! bForced && start != s )
         return FALSE;   /* only right after the dot, or with Ctrl+Space */
      h->acDoc = d;      /* for ac_add's owner; the list itself comes below */
      ac_members( d, d->text + cBeg, ( int ) ( cEnd - cBeg ) );
      if( h->acN == 0 )
      {
         h->acDoc = NULL;
         return FALSE;
      }
      h->acMember = TRUE;   /* in IDE_ED_MEMBERS' order: the controls, then properties and methods */
   }
   else
   {
      if( ! bForced && s - start < AC_MINLEN )
         return FALSE;
      ac_words( d, start );
      h->acMember = FALSE;
   }
   h->acDoc = d;
   h->acStart = start;
   h->acForced = bForced;
   ac_filter( h );
   return ac_visible( d );
}

/* test hook: IDEED_TYPE sends keys with these modifiers instead of the keyboard's */
static int s_fakeMods = -1;
static BOOL s_acEat = FALSE;   /* the WM_CHAR of a key the completion list used */
static int ed_curmods( void ) { return s_fakeMods >= 0 ? s_fakeMods : ed_mods(); }

static LRESULT CALLBACK ed_richproc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam, UINT_PTR uId, DWORD_PTR ref )
{
   EDDOC * d = ( EDDOC * ) ref;
   LRESULT r;
   ( void ) uId;

   switch( msg )
   {
      case WM_GETDLGCODE:
         return DLGC_WANTALLKEYS | DLGC_WANTARROWS | DLGC_WANTCHARS | DLGC_WANTTAB;

      case WM_KEYDOWN:
      {
         int mods = ed_curmods();
         BOOL ctrl = ( mods & 0x10000 ) != 0, shift = ( mods & 0x20000 ) != 0;
         if( ac_visible( d ) )
         {
            switch( wParam )
            {
               case VK_UP:     ac_move( d->host, -1 ); return 0;
               case VK_DOWN:   ac_move( d->host, 1 ); return 0;
               case VK_PRIOR:  ac_move( d->host, -( AC_ROWS - 1 ) ); return 0;
               case VK_NEXT:   ac_move( d->host, AC_ROWS - 1 ); return 0;
               case VK_ESCAPE: ac_hide( d->host ); return 0;
               case VK_RETURN: case VK_TAB:
                  if( ! ctrl && ! shift )
                  {
                     ac_accept( d->host );
                     s_acEat = TRUE;   /* its WM_CHAR */
                     return 0;
                  }
                  ac_hide( d->host );
                  break;
               case VK_LEFT: case VK_RIGHT: case VK_HOME: case VK_END: case VK_DELETE:
                  ac_hide( d->host );
                  break;
            }
         }
         if( wParam == VK_SPACE && ctrl && ! shift && ! ( mods & 0x40000 ) )
         {
            ac_open( d, TRUE );   /* Ctrl+Space */
            s_acEat = TRUE;
            return 0;
         }
         if( wParam == VK_TAB && ! ctrl )
         {
            LONG s, e;
            ed_getsel( d, &s, &e );
            if( shift )
               ed_blockop( d, 2 );
            else if( s != e && ed_linefromchar( d, s ) != ed_linefromchar( d, e ) )
               ed_blockop( d, 1 );
            else
               ed_tab( d );
            ed_checkview( d );
            return 0;
         }
         if( wParam == VK_RETURN && ! ctrl && ! ( mods & 0x40000 ) )
         {
            ed_enter( d );
            ed_checkview( d );
            return 0;
         }
         if( ( wParam == 'V' && ctrl ) || ( wParam == VK_INSERT && shift && ! ctrl ) )
         {
            ed_paste( d );
            ed_checkview( d );
            return 0;
         }
         if( ctrl )
         {
            switch( wParam )
            {
               case 'C': case 'X': case 'Z': case 'Y': case 'A':
               case VK_HOME: case VK_END: case VK_LEFT: case VK_RIGHT: case VK_UP: case VK_DOWN:
               case VK_BACK: case VK_DELETE: case VK_INSERT: case VK_PRIOR: case VK_NEXT:
               case VK_CONTROL: case VK_SHIFT: case VK_MENU:
                  if( ! ( wParam == 'Z' && shift ) )
                     break;   /* RichEdit's own: copy, cut, undo, redo, select all, moving */
                  ed_event( d->hHost, 4, d->hView, ( HB_MAXINT ) ( wParam | mods ) );   /* Ctrl+Shift+Z */
                  return 0;
               default:
                  ed_event( d->hHost, 4, d->hView, ( HB_MAXINT ) ( wParam | mods ) );
                  return 0;   /* RichEdit's own formatting keys (Ctrl+E, Ctrl+L, Ctrl+1 ...) never run */
            }
         }
         else if( ( wParam >= VK_F1 && wParam <= VK_F24 ) || wParam == VK_ESCAPE )
         {
            if( ed_event( d->hHost, 4, d->hView, ( HB_MAXINT ) ( wParam | mods ) ) || wParam == VK_ESCAPE )
               return 0;
         }
         break;
      }

      case WM_SYSKEYDOWN:
         if( wParam >= VK_F1 && wParam <= VK_F24 )
         {
            if( ed_event( d->hHost, 4, d->hView, ( HB_MAXINT ) ( wParam | ed_curmods() ) ) )
               return 0;
         }
         break;

      case WM_CHAR:
         if( s_acEat )
         {
            s_acEat = FALSE;
            if( wParam == ' ' || wParam == '\t' || wParam == '\r' )
               return 0;
         }
         if( wParam == '\t' || wParam == '\r' || wParam == '\n' || wParam == 0x1B || wParam == 0x7F )
            return 0;
         if( wParam < 32 && wParam != 8 )
            return 0;
         if( wParam == 8 && ( ed_curmods() & 0x10000 ) )
            return 0;   /* Ctrl+H */
         break;

      case WM_KILLFOCUS:
      case WM_LBUTTONDOWN: case WM_RBUTTONDOWN: case WM_MBUTTONDOWN:
         if( d->host->acDoc == d )
            ac_hide( d->host );
         break;

      case WM_MOUSEWHEEL:
         if( ac_visible( d ) )
         {
            SendMessageW( d->host->hList, WM_MOUSEWHEEL, wParam, lParam );   /* scrolls the list */
            return 0;
         }
         if( GET_KEYSTATE_WPARAM( wParam ) & MK_CONTROL )
            return 0;   /* no zoom: the gutter would not match */
         break;

      case WM_PASTE:
         ed_paste( d );
         return 0;

      case WM_CONTEXTMENU:
         ed_contextmenu( d, ( short ) LOWORD( lParam ), ( short ) HIWORD( lParam ) );
         return 0;

      case WM_NCDESTROY:
         RemoveWindowSubclass( hWnd, ed_richproc, 1 );
         break;
   }

   r = DefSubclassProc( hWnd, msg, wParam, lParam );

   /* a character went in: the completion list follows it */
   if( msg == WM_CHAR && IsWindow( hWnd ) )
   {
      if( wParam < 128 && lx_idchar( ( WCHAR ) wParam ) )
      {
         if( ac_visible( d ) )
            ac_filter( d->host );
         else
            ac_open( d, FALSE );
      }
      else if( wParam == 8 )
      {
         if( ac_visible( d ) )
            ac_filter( d->host );
      }
      else
      {
         if( d->host->acDoc == d )
            ac_hide( d->host );
         if( wParam == '.' )
            ac_open( d, FALSE );
      }
   }

   /* what the user does that can scroll, move the caret or change the text (the EM_
      messages this file sends are below WM_USER too: never from here) */
   switch( msg )
   {
      case WM_KEYDOWN: case WM_KEYUP: case WM_CHAR: case WM_SYSKEYDOWN:
      case WM_VSCROLL: case WM_HSCROLL: case WM_MOUSEWHEEL: case WM_MOUSEHWHEEL:
      case WM_LBUTTONDOWN: case WM_LBUTTONUP: case WM_LBUTTONDBLCLK: case WM_SIZE:
      case WM_CUT: case WM_CLEAR: case WM_UNDO:
         ed_checkview( d );
         break;
      case WM_MOUSEMOVE:
      case WM_TIMER:   /* RichEdit scrolls from a timer while a selection is dragged */
         if( GetKeyState( VK_LBUTTON ) < 0 )
            ed_checkview( d );
         break;
   }
   return r;
}

static LRESULT CALLBACK ed_viewproc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   EDDOC * d = ( EDDOC * ) GetWindowLongPtrW( hWnd, GWLP_USERDATA );

   switch( msg )
   {
      case WM_SIZE:
         if( d )
            ed_layout( d );
         return 0;

      case WM_ERASEBKGND:
         return 1;

      case WM_PAINT:
      {
         PAINTSTRUCT ps;
         HDC hdc = BeginPaint( hWnd, &ps );
         if( d )
            ed_paintgutter( d, hdc );
         EndPaint( hWnd, &ps );
         return 0;
      }

      case WM_SETFOCUS:
         if( d )
            SetFocus( d->hRich );
         return 0;

      case WM_COMMAND:
         if( d && ( HWND ) lParam == d->hRich && HIWORD( wParam ) == EN_CHANGE )
         {
            BOOL bMod = ( BOOL ) SendMessageW( d->hRich, EM_GETMODIFY, 0, 0 );
            d->ver++;
            SetTimer( hWnd, HL_TIMER, 30, NULL );
            if( bMod != d->bModified )
            {
               d->bModified = bMod;
               ed_event( d->hHost, 2, d->hView, bMod );
            }
            ed_checkview( d );
            return 0;
         }
         break;

      case WM_NOTIFY:
         if( d && ( ( NMHDR * ) lParam )->hwndFrom == d->hRich && ( ( NMHDR * ) lParam )->code == EN_SELCHANGE )
         {
            ed_checkview( d );
            ed_event( d->hHost, 3, d->hView, 0 );
            return 0;
         }
         break;

      case WM_TIMER:
         if( wParam == HL_TIMER && d )
         {
            KillTimer( hWnd, HL_TIMER );
            ed_highlight( d, FALSE );
            return 0;
         }
         break;

      case WM_NCDESTROY:
         if( d )
         {
            if( d->host && d->host->acDoc == d )
               ac_hide( d->host );
            if( d->pDoc )
               ITextDocument_Release( d->pDoc );
            if( d->text )
               hb_xfree( d->text );
            hb_xfree( d );
            SetWindowLongPtrW( hWnd, GWLP_USERDATA, 0 );
         }
         break;
   }
   return DefWindowProcW( hWnd, msg, wParam, lParam );
}

/* editor font, colours and tab stops on the whole document (no undo step) */
static void ed_applyformat( EDDOC * d )
{
   CHARFORMAT2W cf;
   PARAFORMAT2 pf;
   EDHOST * h = d->host;
   LONG s, e, cnt0 = 0;
   int i, tw;
   BOOL bMod = ( BOOL ) SendMessageW( d->hRich, EM_GETMODIFY, 0, 0 );
   LONG mask = ( LONG ) SendMessageW( d->hRich, EM_GETEVENTMASK, 0, 0 );

   d->inHL = TRUE;
   SendMessageW( d->hRich, EM_SETEVENTMASK, 0, 0 );
   if( d->pDoc )
   {
      ITextDocument_Freeze( d->pDoc, &cnt0 );
      ITextDocument_Undo( d->pDoc, tomSuspend, NULL );
   }
   memset( &cf, 0, sizeof( cf ) );
   cf.cbSize = sizeof( cf );
   cf.dwMask = CFM_FACE | CFM_SIZE | CFM_COLOR | CFM_BOLD | CFM_ITALIC | CFM_UNDERLINE | CFM_STRIKEOUT | CFM_BACKCOLOR | CFM_CHARSET;
   cf.dwEffects = CFE_AUTOBACKCOLOR;
   cf.yHeight = h->nSize * 20;
   cf.crTextColor = ed_pal( h )[ ST_DEF ];
   cf.bCharSet = DEFAULT_CHARSET;
   lstrcpynW( cf.szFaceName, h->face, LF_FACESIZE );
   SendMessageW( d->hRich, EM_SETCHARFORMAT, SCF_DEFAULT, ( LPARAM ) &cf );
   SendMessageW( d->hRich, EM_SETCHARFORMAT, SCF_ALL, ( LPARAM ) &cf );
   SendMessageW( d->hRich, EM_SETBKGNDCOLOR, 0, ( LPARAM ) ( h->bDark ? BG_DARK : BG_LIGHT ) );

   memset( &pf, 0, sizeof( pf ) );
   pf.cbSize = sizeof( pf );
   pf.dwMask = PFM_TABSTOPS;
   tw = MulDiv( h->charW * h->nTabWidth, 1440, ed_dpi( d->hView ) );
   pf.cTabCount = MAX_TAB_STOPS;
   for( i = 0; i < MAX_TAB_STOPS; i++ )
      pf.rgxTabs[ i ] = tw * ( i + 1 );
   ed_getsel( d, &s, &e );
   ed_setsel( d, 0, -1 );
   SendMessageW( d->hRich, EM_SETPARAFORMAT, 0, ( LPARAM ) &pf );
   ed_setsel( d, s, e );

   if( d->pDoc )
   {
      ITextDocument_Undo( d->pDoc, tomResume, NULL );
      ITextDocument_Unfreeze( d->pDoc, &cnt0 );
   }
   SendMessageW( d->hRich, EM_SETMODIFY, ( WPARAM ) bMod, 0 );
   SendMessageW( d->hRich, EM_SETEVENTMASK, 0, ( LPARAM ) mask );
   d->inHL = FALSE;
   ed_theme( d->hRich, h->bDark );
   d->hlVer = -1;
}

/* ------------------------------------------------------------------ host */

static int ed_tabcount( EDHOST * h ) { return ( int ) SendMessageW( h->hTab, TCM_GETITEMCOUNT, 0, 0 ); }

static HWND ed_tabview( EDHOST * h, int i )
{
   TCITEMW ti;
   ti.mask = TCIF_PARAM;
   ti.lParam = 0;
   if( i < 0 || ! SendMessageW( h->hTab, TCM_GETITEMW, ( WPARAM ) i, ( LPARAM ) &ti ) )
      return NULL;
   return ( HWND ) ti.lParam;
}

static int ed_tabindex( EDHOST * h, HWND hView )
{
   int i, n = ed_tabcount( h );
   for( i = 0; i < n; i++ )
      if( ed_tabview( h, i ) == hView )
         return i;
   return -1;
}

static void ed_hostlayout( EDHOST * h )
{
   RECT rc, ra;
   int i, n = ed_tabcount( h ), cur;
   GetClientRect( h->hHost, &rc );
   ra = rc;
   ra.bottom = 400;
   SendMessageW( h->hTab, TCM_ADJUSTRECT, FALSE, ( LPARAM ) &ra );
   h->tabH = ra.top > 8 ? ra.top - 2 : MulDiv( 26, ed_dpi( h->hHost ), 96 );
   MoveWindow( h->hTab, 0, 0, rc.right, h->tabH, TRUE );
   cur = ( int ) SendMessageW( h->hTab, TCM_GETCURSEL, 0, 0 );
   for( i = 0; i < n; i++ )
   {
      HWND hv = ed_tabview( h, i );
      MoveWindow( hv, 0, h->tabH, rc.right, rc.bottom - h->tabH > 0 ? rc.bottom - h->tabH : 0, TRUE );
      ShowWindow( hv, i == cur ? SW_SHOW : SW_HIDE );
   }
}

static void ed_showcurrent( EDHOST * h, BOOL bFocus )
{
   int i, n = ed_tabcount( h ), cur = ( int ) SendMessageW( h->hTab, TCM_GETCURSEL, 0, 0 );
   ac_hide( h );
   for( i = 0; i < n; i++ )
      if( i != cur )
         ShowWindow( ed_tabview( h, i ), SW_HIDE );
   if( cur >= 0 )
   {
      HWND hv = ed_tabview( h, cur );
      ShowWindow( hv, SW_SHOW );
      if( bFocus )
         SetFocus( hv );
      ed_checkview( ed_doc( hv ) );
   }
}

static LRESULT CALLBACK ed_tabproc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam, UINT_PTR uId, DWORD_PTR ref )
{
   EDHOST * h = ( EDHOST * ) ref;
   ( void ) uId;
   if( msg == WM_MBUTTONUP )
   {
      TCHITTESTINFO hti;
      int i;
      hti.pt.x = ( short ) LOWORD( lParam );
      hti.pt.y = ( short ) HIWORD( lParam );
      i = ( int ) SendMessageW( hWnd, TCM_HITTEST, 0, ( LPARAM ) &hti );
      if( i >= 0 )
         ed_event( h->hHost, 5, ed_tabview( h, i ), 0 );
      return 0;
   }
   if( msg == WM_NCDESTROY )
      RemoveWindowSubclass( hWnd, ed_tabproc, 1 );
   return DefSubclassProc( hWnd, msg, wParam, lParam );
}

static LRESULT CALLBACK ed_hostproc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   EDHOST * h = ( EDHOST * ) GetWindowLongPtrW( hWnd, GWLP_USERDATA );

   switch( msg )
   {
      case WM_SIZE:
         if( h )
            ed_hostlayout( h );
         return 0;

      case WM_ERASEBKGND:
         if( h )
         {
            RECT rc;
            HBRUSH hbr = CreateSolidBrush( h->bDark ? BG_DARK : GetSysColor( COLOR_BTNFACE ) );
            GetClientRect( hWnd, &rc );
            FillRect( ( HDC ) wParam, &rc, hbr );
            DeleteObject( hbr );
            return 1;
         }
         break;

      case WM_SETFOCUS:
         if( h )
         {
            int cur = ( int ) SendMessageW( h->hTab, TCM_GETCURSEL, 0, 0 );
            if( cur >= 0 )
               SetFocus( ed_tabview( h, cur ) );
         }
         return 0;

      case WM_NOTIFY:
         if( h && ( ( NMHDR * ) lParam )->hwndFrom == h->hTab && ( ( NMHDR * ) lParam )->code == TCN_SELCHANGE )
         {
            int cur = ( int ) SendMessageW( h->hTab, TCM_GETCURSEL, 0, 0 );
            ed_showcurrent( h, TRUE );
            ed_event( hWnd, 1, ed_tabview( h, cur ), 0 );
            return 0;
         }
         break;

      case WM_NCDESTROY:
         if( h )
         {
            ac_hide( h );
            if( h->hPop && IsWindow( h->hPop ) )
               DestroyWindow( h->hPop );
            if( h->hFont )
               DeleteObject( h->hFont );
            if( h->hTabFont )
               DeleteObject( h->hTabFont );
            hb_xfree( h );
            SetWindowLongPtrW( hWnd, GWLP_USERDATA, 0 );
         }
         break;
   }
   return DefWindowProcW( hWnd, msg, wParam, lParam );
}

static void ed_register( void )
{
   static BOOL done = FALSE;
   WNDCLASSW wc;
   if( done )
      return;
   done = TRUE;
   LoadLibraryW( L"Msftedit.dll" );
   memset( &wc, 0, sizeof( wc ) );
   wc.hInstance = GetModuleHandleW( NULL );
   wc.hCursor = LoadCursor( NULL, IDC_ARROW );
   wc.lpfnWndProc = ed_hostproc;
   wc.lpszClassName = L"HMGIDEEditHost";
   RegisterClassW( &wc );
   wc.lpfnWndProc = ed_viewproc;
   wc.lpszClassName = L"HMGIDECodeView";
   RegisterClassW( &wc );
}

static void ed_hostfonts( EDHOST * h )
{
   NONCLIENTMETRICSW ncm;
   HDC hdc;
   HFONT hOld;
   SIZE sz;
   int dpi = ed_dpi( h->hHost );

   if( h->hFont )
      DeleteObject( h->hFont );
   h->hFont = CreateFontW( -MulDiv( h->nSize, dpi, 72 ), 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                           CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, FIXED_PITCH | FF_MODERN, h->face );
   hdc = GetDC( h->hHost );
   hOld = ( HFONT ) SelectObject( hdc, h->hFont );
   GetTextExtentPoint32W( hdc, L"0000000000", 10, &sz );
   h->lineH = sz.cy > 0 ? sz.cy : 16;
   SelectObject( hdc, hOld );
   ReleaseDC( h->hHost, hdc );
   h->charW = sz.cx / 10 > 0 ? sz.cx / 10 : 8;

   if( h->hTabFont )
      DeleteObject( h->hTabFont );
   memset( &ncm, 0, sizeof( ncm ) );
   ncm.cbSize = sizeof( ncm );
   SystemParametersInfoW( SPI_GETNONCLIENTMETRICS, sizeof( ncm ), &ncm, 0 );
   ncm.lfMessageFont.lfHeight = -MulDiv( 9, dpi, 72 );
   h->hTabFont = CreateFontIndirectW( &ncm.lfMessageFont );
   SendMessageW( h->hTab, WM_SETFONT, ( WPARAM ) h->hTabFont, TRUE );
}

/* ------------------------------------------------------------------ Harbour API */

#define PARHWND( n )   ( ( HWND ) ( HB_PTRUINT ) hb_parnint( n ) )

/* IDEED_CREATE( hParent, nRow, nCol, nWidth, nHeight, lDark, cFont, nSize, nIndent, nTabWidth, lUnicode ) -> hHost */
HB_FUNC( IDEED_CREATE )
{
   EDHOST * h;
   HWND hHost;
   int n;
   WCHAR * w;

   kw_init();
   ed_register();
   s_cp = hb_parldef( 11, 1 ) ? CP_UTF8 : CP_ACP;
   hHost = CreateWindowExW( WS_EX_CONTROLPARENT, L"HMGIDEEditHost", L"", WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN | WS_TABSTOP,
                            hb_parni( 3 ), hb_parni( 2 ), hb_parni( 4 ), hb_parni( 5 ), PARHWND( 1 ), NULL, GetModuleHandleW( NULL ), NULL );
   if( ! hHost )
   {
      hb_retnint( 0 );
      return;
   }
   h = ( EDHOST * ) hb_xgrabz( sizeof( EDHOST ) );
   h->hHost = hHost;
   h->bDark = hb_parl( 6 );
   w = ed_towide( HB_ISCHAR( 7 ) && hb_parclen( 7 ) ? hb_parc( 7 ) : "Consolas", HB_ISCHAR( 7 ) && hb_parclen( 7 ) ? hb_parclen( 7 ) : 8, s_cp, &n );
   lstrcpynW( h->face, w, LF_FACESIZE );
   hb_xfree( w );
   h->nSize = hb_parnidef( 8, 10 );
   h->nIndent = hb_parnidef( 9, 3 );
   h->nTabWidth = hb_parnidef( 10, 4 );
   if( h->nIndent < 1 || h->nIndent > 16 ) h->nIndent = 3;
   if( h->nTabWidth < 1 || h->nTabWidth > 16 ) h->nTabWidth = 4;
   SetWindowLongPtrW( hHost, GWLP_USERDATA, ( LONG_PTR ) h );

   h->hTab = CreateWindowExW( 0, WC_TABCONTROLW, L"", WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | TCS_FOCUSNEVER | TCS_TOOLTIPS,
                              0, 0, 100, 26, hHost, NULL, GetModuleHandleW( NULL ), NULL );
   SetWindowSubclass( h->hTab, ed_tabproc, 1, ( DWORD_PTR ) h );
   ed_hostfonts( h );
   if( h->bDark )
      HMG_TabApplyModern( h->hTab, DK_STRIP, DK_BG, DK_GRAY, DK_TEXT );
   ed_hostlayout( h );
   hb_retnint( ( HB_PTRUINT ) hHost );
}

/* IDEED_MOVE( hHost, nRow, nCol, nWidth, nHeight ) */
HB_FUNC( IDEED_MOVE )
{
   EDHOST * h = ed_host( PARHWND( 1 ) );
   if( h )
      MoveWindow( h->hHost, hb_parni( 3 ), hb_parni( 2 ), hb_parni( 4 ), hb_parni( 5 ), TRUE );
}

/* IDEED_ADDDOC( hHost, cCaption ) -> hView (selected) */
HB_FUNC( IDEED_ADDDOC )
{
   EDHOST * h = ed_host( PARHWND( 1 ) );
   EDDOC * d;
   TCITEMW ti;
   IRichEditOle * pOle = NULL;
   WCHAR * w;
   int i;

   if( ! h )
   {
      hb_retnint( 0 );
      return;
   }
   d = ( EDDOC * ) hb_xgrabz( sizeof( EDDOC ) );
   d->host = h;
   d->hHost = h->hHost;
   d->hlVer = -1;
   d->textVer = -1;
   d->hView = CreateWindowExW( 0, L"HMGIDECodeView", L"", WS_CHILD | WS_CLIPCHILDREN, 0, 0, 10, 10, h->hHost, NULL, GetModuleHandleW( NULL ), NULL );
   d->hRich = CreateWindowExW( 0, L"RICHEDIT50W", L"",
                               WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_HSCROLL | WS_TABSTOP | ES_MULTILINE | ES_AUTOVSCROLL |
                               ES_AUTOHSCROLL | ES_NOHIDESEL | ES_WANTRETURN | ES_NOOLEDRAGDROP,
                               0, 0, 10, 10, d->hView, NULL, GetModuleHandleW( NULL ), NULL );
   SetWindowLongPtrW( d->hView, GWLP_USERDATA, ( LONG_PTR ) d );
   SendMessageW( d->hRich, EM_SETTEXTMODE, TM_RICHTEXT | TM_MULTILEVELUNDO | TM_MULTICODEPAGE, 0 );
   SendMessageW( d->hRich, EM_SETUNDOLIMIT, 1000, 0 );
   SendMessageW( d->hRich, EM_EXLIMITTEXT, 0, 0x7FFFFFFE );
   SendMessageW( d->hRich, EM_SETTARGETDEVICE, 0, 1 );   /* no word wrap */
   SendMessageW( d->hRich, EM_AUTOURLDETECT, FALSE, 0 );
   SendMessageW( d->hRich, EM_SETOPTIONS, ECOOP_AND, ( LPARAM ) ~( ECO_AUTOWORDSELECTION ) );
   SendMessageW( d->hRich, EM_SETMARGINS, EC_LEFTMARGIN, MAKELONG( MulDiv( 4, ed_dpi( d->hView ), 96 ), 0 ) );
   SendMessageW( d->hRich, EM_GETOLEINTERFACE, 0, ( LPARAM ) &pOle );
   if( pOle )
   {
      pOle->lpVtbl->QueryInterface( pOle, &s_IID_ITextDocument, ( void ** ) &d->pDoc );
      pOle->lpVtbl->Release( pOle );
   }
   ed_applyformat( d );
   SetWindowSubclass( d->hRich, ed_richproc, 1, ( DWORD_PTR ) d );
   SendMessageW( d->hRich, EM_SETEVENTMASK, 0, ENM_CHANGE | ENM_SELCHANGE | ENM_SCROLL );
   d->lineCount = 1;
   d->caretLine = -1;

   w = ed_parw( 2, NULL );
   memset( &ti, 0, sizeof( ti ) );
   ti.mask = TCIF_TEXT | TCIF_PARAM;
   ti.pszText = w;
   ti.lParam = ( LPARAM ) d->hView;
   i = ( int ) SendMessageW( h->hTab, TCM_INSERTITEMW, ( WPARAM ) ed_tabcount( h ), ( LPARAM ) &ti );
   hb_xfree( w );
   SendMessageW( h->hTab, TCM_SETCURSEL, ( WPARAM ) i, 0 );
   ed_hostlayout( h );
   ed_showcurrent( h, FALSE );
   hb_retnint( ( HB_PTRUINT ) d->hView );
}

/* IDEED_CLOSEDOC( hView ) : the tab next to it becomes the current one */
HB_FUNC( IDEED_CLOSEDOC )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   if( d )
   {
      EDHOST * h = d->host;
      int i = ed_tabindex( h, d->hView ), n;
      HWND hv = d->hView;
      if( i >= 0 )
         SendMessageW( h->hTab, TCM_DELETEITEM, ( WPARAM ) i, 0 );
      DestroyWindow( hv );
      n = ed_tabcount( h );
      if( n > 0 )
      {
         SendMessageW( h->hTab, TCM_SETCURSEL, ( WPARAM ) ( i < n ? i : n - 1 ), 0 );
         ed_showcurrent( h, TRUE );
      }
      InvalidateRect( h->hHost, NULL, TRUE );
   }
}

/* IDEED_SELECT( hView ) */
HB_FUNC( IDEED_SELECT )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   if( d )
   {
      int i = ed_tabindex( d->host, d->hView );
      if( i >= 0 )
      {
         SendMessageW( d->host->hTab, TCM_SETCURSEL, ( WPARAM ) i, 0 );
         ed_showcurrent( d->host, TRUE );
      }
   }
}

/* IDEED_CURRENT( hHost ) -> hView or 0 */
HB_FUNC( IDEED_CURRENT )
{
   EDHOST * h = ed_host( PARHWND( 1 ) );
   hb_retnint( h ? ( HB_PTRUINT ) ed_tabview( h, ( int ) SendMessageW( h->hTab, TCM_GETCURSEL, 0, 0 ) ) : 0 );
}

/* IDEED_DOCS( hHost ) -> { hView, ... } in tab order */
HB_FUNC( IDEED_DOCS )
{
   EDHOST * h = ed_host( PARHWND( 1 ) );
   int i, n = h ? ed_tabcount( h ) : 0;
   PHB_ITEM a = hb_itemArrayNew( n );
   for( i = 0; i < n; i++ )
      hb_arraySetNInt( a, i + 1, ( HB_PTRUINT ) ed_tabview( h, i ) );
   hb_itemReturnRelease( a );
}

/* IDEED_SETCAPTION( hView, cCaption ) */
HB_FUNC( IDEED_SETCAPTION )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   if( d )
   {
      int i = ed_tabindex( d->host, d->hView );
      if( i >= 0 )
      {
         TCITEMW ti;
         WCHAR * w = ed_parw( 2, NULL );
         ti.mask = TCIF_TEXT;
         ti.pszText = w;
         SendMessageW( d->host->hTab, TCM_SETITEMW, ( WPARAM ) i, ( LPARAM ) &ti );
         hb_xfree( w );
         ed_hostlayout( d->host );
      }
   }
}

/* IDEED_SETBYTES( hView, cFileBytes, nDefaultEnc ) -> { nEnc, lBOM, lCRLF } or NIL (binary file)
   nEnc: 1 UTF-8, 2 ANSI, 3 UTF-16 LE. nDefaultEnc: for a file of plain ASCII. */
HB_FUNC( IDEED_SETBYTES )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   const char * b = hb_parcx( 2 );
   HB_SIZE n = hb_parclen( 2 ), i;
   int nEnc, m = 0, j, k;
   BOOL bBom = FALSE, bAscii = TRUE, bCRLF;
   LONG nCRLF = 0, nLF = 0;
   WCHAR * w;
   ITextRange * r = NULL;
   PHB_ITEM a;

   if( ! d )
      return;
   if( n >= 2 && ( unsigned char ) b[ 0 ] == 0xFF && ( unsigned char ) b[ 1 ] == 0xFE )
   {
      nEnc = 3;
      bBom = TRUE;
      m = ( int ) ( ( n - 2 ) / 2 );
      w = ( WCHAR * ) hb_xgrab( ( m + 1 ) * sizeof( WCHAR ) );
      memcpy( w, b + 2, m * sizeof( WCHAR ) );
      w[ m ] = 0;
   }
   else
   {
      for( i = 0; i < n; i++ )
      {
         if( b[ i ] == 0 )
            return;   /* binary */
         if( ( unsigned char ) b[ i ] >= 0x80 )
            bAscii = FALSE;
      }
      if( n >= 3 && ( unsigned char ) b[ 0 ] == 0xEF && ( unsigned char ) b[ 1 ] == 0xBB && ( unsigned char ) b[ 2 ] == 0xBF )
      {
         nEnc = 1;
         bBom = TRUE;
         b += 3;
         n -= 3;
      }
      else if( bAscii )
         nEnc = hb_parnidef( 3, 1 ) == 2 ? 2 : 1;
      else if( MultiByteToWideChar( CP_UTF8, MB_ERR_INVALID_CHARS, b, ( int ) n, NULL, 0 ) > 0 )
         nEnc = 1;
      else
         nEnc = 2;
      w = ed_towide( b, n, nEnc == 1 ? CP_UTF8 : CP_ACP, &m );
   }
   for( j = 0; j < m; j++ )
   {
      if( w[ j ] == 0 )
      {
         hb_xfree( w );
         return;
      }
      if( w[ j ] == '\r' && j + 1 < m && w[ j + 1 ] == '\n' )
         nCRLF++;
      else if( w[ j ] == '\n' )
         nLF++;
   }
   bCRLF = ! ( nLF > 0 && nCRLF == 0 );
   for( j = k = 0; j < m; j++ )
   {
      if( w[ j ] == '\r' && j + 1 < m && w[ j + 1 ] == '\n' )
         continue;
      w[ k++ ] = w[ j ] == '\n' ? '\r' : w[ j ];
   }
   w[ k ] = 0;

   d->inHL = TRUE;
   SendMessageW( d->hRich, EM_SETEVENTMASK, 0, 0 );
   if( d->pDoc && ITextDocument_Range( d->pDoc, 0, tomForward, &r ) == S_OK && r )
   {
      BSTR bs = SysAllocStringLen( w, ( UINT ) k );
      r->lpVtbl->SetText( r, bs );   /* always plain text, even if it starts with {\rtf */
      SysFreeString( bs );
      ITextRange_Release( r );
   }
   d->inHL = FALSE;
   hb_xfree( w );
   ed_applyformat( d );
   SendMessageW( d->hRich, EM_EMPTYUNDOBUFFER, 0, 0 );
   SendMessageW( d->hRich, EM_SETMODIFY, FALSE, 0 );
   d->bModified = FALSE;
   d->ver++;
   ed_setsel( d, 0, 0 );
   SendMessageW( d->hRich, EM_SCROLLCARET, 0, 0 );
   SendMessageW( d->hRich, EM_SETEVENTMASK, 0, ENM_CHANGE | ENM_SELCHANGE | ENM_SCROLL );
   d->lineCount = -1;
   ed_checkview( d );
   ed_highlight( d, TRUE );

   a = hb_itemArrayNew( 3 );
   hb_arraySetNI( a, 1, nEnc );
   hb_arraySetL( a, 2, bBom );
   hb_arraySetL( a, 3, bCRLF );
   hb_itemReturnRelease( a );
}

/* IDEED_GETBYTES( hView, nEnc, lBOM, lCRLF, @lLossy ) -> cFileBytes */
HB_FUNC( IDEED_GETBYTES )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   int nEnc = hb_parnidef( 2, 1 );
   BOOL bBom = hb_parl( 3 ), bCRLF = hb_parldef( 4, 1 ), bLossy = FALSE;
   LONG i, nCR = 0, k = 0;
   WCHAR * x;
   char * out;
   HB_SIZE nOut = 0;

   if( ! d )
   {
      hb_retc_null();
      return;
   }
   ed_fetch( d );
   for( i = 0; i < d->len; i++ )
      if( d->text[ i ] == '\r' )
         nCR++;
   x = ( WCHAR * ) hb_xgrab( ( d->len + nCR + 1 ) * sizeof( WCHAR ) );
   for( i = 0; i < d->len; i++ )
   {
      if( d->text[ i ] == '\r' )
      {
         if( bCRLF )
            x[ k++ ] = '\r';
         x[ k++ ] = '\n';
      }
      else
         x[ k++ ] = d->text[ i ];
   }
   if( nEnc == 3 )
   {
      out = ( char * ) hb_xgrab( k * 2 + 3 );
      if( bBom )
      {
         out[ nOut++ ] = ( char ) 0xFF;
         out[ nOut++ ] = ( char ) 0xFE;
      }
      memcpy( out + nOut, x, k * 2 );
      nOut += k * 2;
   }
   else
   {
      UINT cp = nEnc == 2 ? CP_ACP : CP_UTF8;
      BOOL bUsed = FALSE;
      int m = k ? WideCharToMultiByte( cp, 0, x, ( int ) k, NULL, 0, NULL, NULL ) : 0;
      out = ( char * ) hb_xgrab( m + 4 );
      if( nEnc == 1 && bBom )
      {
         out[ nOut++ ] = ( char ) 0xEF;
         out[ nOut++ ] = ( char ) 0xBB;
         out[ nOut++ ] = ( char ) 0xBF;
      }
      if( m )
         WideCharToMultiByte( cp, 0, x, ( int ) k, out + nOut, m, NULL, cp == CP_ACP ? &bUsed : NULL );
      nOut += m;
      bLossy = bUsed;
   }
   hb_xfree( x );
   hb_storl( bLossy, 5 );
   hb_retclen_buffer( out, nOut );
}

/* IDEED_GETTEXT( hView ) -> text with CRLF */
HB_FUNC( IDEED_GETTEXT )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   if( ! d )
   {
      hb_retc_null();
      return;
   }
   ed_fetch( d );
   ed_retw( d->text, d->len );
}

/* IDEED_SELTEXT( hView ) -> selected text with CRLF */
HB_FUNC( IDEED_SELTEXT )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   LONG s, e;
   if( ! d )
   {
      hb_retc_null();
      return;
   }
   ed_getsel( d, &s, &e );
   ed_fetch( d );
   if( s < 0 ) s = 0;
   if( e > d->len ) e = d->len;
   ed_retw( d->text + s, e > s ? e - s : 0 );
}

/* IDEED_MODIFIED( hView [, lSet] ) -> lModified */
HB_FUNC( IDEED_MODIFIED )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   if( ! d )
   {
      hb_retl( FALSE );
      return;
   }
   if( HB_ISLOG( 2 ) )
   {
      SendMessageW( d->hRich, EM_SETMODIFY, ( WPARAM ) hb_parl( 2 ), 0 );
      d->bModified = hb_parl( 2 );
   }
   hb_retl( ( BOOL ) SendMessageW( d->hRich, EM_GETMODIFY, 0, 0 ) );
}

/* puts line nLine (0-based) about a third down the window */
static void ed_showline( EDDOC * d, LONG line )
{
   RECT rc;
   LONG first = ( LONG ) SendMessageW( d->hRich, EM_GETFIRSTVISIBLELINE, 0, 0 ), vis, cpTop, cpBottom, last;
   POINTL pt;
   GetClientRect( d->hRich, &rc );
   pt.x = 0;
   pt.y = rc.bottom - 1;
   cpBottom = ( LONG ) SendMessageW( d->hRich, EM_CHARFROMPOS, 0, ( LPARAM ) &pt );
   last = ed_linefromchar( d, cpBottom );
   ( void ) cpTop;
   vis = last - first + 1;
   if( line >= first + 1 && line <= last - 3 )
      return;   /* already well inside the window */
   SendMessageW( d->hRich, EM_LINESCROLL, 0, ( LPARAM ) ( ( line - vis / 3 < 0 ? 0 : line - vis / 3 ) - first ) );
}

/* IDEED_GOTO( hView, nLine [, nCol] ) : 1-based */
HB_FUNC( IDEED_GOTO )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   LONG line, cnt, cp, len;
   if( ! d )
      return;
   cnt = ed_linecount( d );
   line = ( LONG ) hb_parnl( 2 ) - 1;
   if( line < 0 ) line = 0;
   if( line >= cnt ) line = cnt - 1;
   cp = ed_lineindex( d, line );
   len = ( LONG ) SendMessageW( d->hRich, EM_LINELENGTH, ( WPARAM ) cp, 0 );
   if( hb_parnl( 3 ) > 1 )
      cp += ( hb_parnl( 3 ) - 1 < len ? hb_parnl( 3 ) - 1 : len );
   ed_setsel( d, cp, cp );
   ed_showline( d, line );
   ed_checkview( d );
}

/* IDEED_CARET( hView ) -> { nLine, nCol, nLines, nSelLength, nCp } (1-based line and column) */
HB_FUNC( IDEED_CARET )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   LONG s, e, line;
   PHB_ITEM a = hb_itemArrayNew( 5 );
   if( d )
   {
      ed_getsel( d, &s, &e );
      line = ed_linefromchar( d, e );
      hb_arraySetNL( a, 1, line + 1 );
      hb_arraySetNL( a, 2, e - ed_lineindex( d, line ) + 1 );
      hb_arraySetNL( a, 3, ed_linecount( d ) );
      hb_arraySetNL( a, 4, e - s );
      hb_arraySetNL( a, 5, e );
   }
   hb_itemReturnRelease( a );
}

static BOOL ed_findtext( EDDOC * d, const WCHAR * what, BOOL bCase, BOOL bWord, BOOL bBack, BOOL bWrap )
{
   FINDTEXTEXW ft;
   LONG s, e, r, len;
   WPARAM fl = ( bCase ? FR_MATCHCASE : 0 ) | ( bWord ? FR_WHOLEWORD : 0 ) | ( bBack ? 0 : FR_DOWN );
   int pass;
   if( ! *what )
      return FALSE;
   ed_getsel( d, &s, &e );
   ed_fetch( d );
   len = d->len;
   for( pass = 0; pass < ( bWrap ? 2 : 1 ); pass++ )
   {
      ft.lpstrText = what;
      if( bBack )
      {
         ft.chrg.cpMin = pass ? len : s;
         ft.chrg.cpMax = 0;
      }
      else
      {
         ft.chrg.cpMin = pass ? 0 : e;
         ft.chrg.cpMax = -1;
      }
      r = ( LONG ) SendMessageW( d->hRich, EM_FINDTEXTEXW, fl, ( LPARAM ) &ft );
      if( r >= 0 )
      {
         ed_setsel( d, ft.chrgText.cpMin, ft.chrgText.cpMax );
         ed_showline( d, ed_linefromchar( d, ft.chrgText.cpMin ) );
         SendMessageW( d->hRich, EM_SCROLLCARET, 0, 0 );
         ed_checkview( d );
         return TRUE;
      }
   }
   return FALSE;
}

/* IDEED_FIND( hView, cWhat, lMatchCase, lWholeWord, lBackwards, lWrap ) -> lFound (selected) */
HB_FUNC( IDEED_FIND )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   WCHAR * w;
   if( ! d )
   {
      hb_retl( FALSE );
      return;
   }
   w = ed_parw( 2, NULL );
   hb_retl( ed_findtext( d, w, hb_parl( 3 ), hb_parl( 4 ), hb_parl( 5 ), hb_parldef( 6, 1 ) ) );
   hb_xfree( w );
}

static BOOL ed_isword( WCHAR c ) { return iswalnum( c ) || c == '_'; }

static BOOL ed_matchat( const WCHAR * t, LONG n, LONG i, const WCHAR * what, int wl, BOOL bCase, BOOL bWord )
{
   if( i + wl > n )
      return FALSE;
   if( CompareStringOrdinal( t + i, wl, what, wl, ! bCase ) != CSTR_EQUAL )
      return FALSE;
   if( bWord && ( ( i > 0 && ed_isword( t[ i - 1 ] ) ) || ( i + wl < n && ed_isword( t[ i + wl ] ) ) ) )
      return FALSE;
   return TRUE;
}

/* IDEED_REPLACE( hView, cWhat, cWith, lMatchCase, lWholeWord ) -> lFoundNext
   replaces the selection if it is a match, then selects the next match */
HB_FUNC( IDEED_REPLACE )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   WCHAR * what, * with;
   int wl;
   LONG s, e;
   if( ! d )
   {
      hb_retl( FALSE );
      return;
   }
   what = ed_parw( 2, &wl );
   with = ed_parw( 3, NULL );
   ed_getsel( d, &s, &e );
   ed_fetch( d );
   if( wl && e - s == wl && ed_matchat( d->text, d->len, s, what, wl, hb_parl( 4 ), hb_parl( 5 ) ) )
      SendMessageW( d->hRich, EM_REPLACESEL, TRUE, ( LPARAM ) with );
   hb_retl( ed_findtext( d, what, hb_parl( 4 ), hb_parl( 5 ), FALSE, TRUE ) );
   hb_xfree( what );
   hb_xfree( with );
}

/* IDEED_REPLACEALL( hView, cWhat, cWith, lMatchCase, lWholeWord ) -> nCount (one undo step) */
HB_FUNC( IDEED_REPLACEALL )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   WCHAR * what, * with, * out;
   int wl, nl;
   LONG i, nOut = 0, cnt = 0, cap, s, e, first, newFirst;
   BOOL bCase = hb_parl( 4 ), bWord = hb_parl( 5 );
   if( ! d )
   {
      hb_retnl( 0 );
      return;
   }
   what = ed_parw( 2, &wl );
   with = ed_parw( 3, &nl );
   ed_fetch( d );
   if( wl )
   {
      cap = d->len + 16;
      out = ( WCHAR * ) hb_xgrab( cap * sizeof( WCHAR ) );
      for( i = 0; i < d->len; )
      {
         if( nOut + nl + 2 >= cap )
         {
            cap = cap * 2 + nl;
            out = ( WCHAR * ) hb_xrealloc( out, cap * sizeof( WCHAR ) );
         }
         if( ed_matchat( d->text, d->len, i, what, wl, bCase, bWord ) )
         {
            memcpy( out + nOut, with, nl * sizeof( WCHAR ) );
            nOut += nl;
            i += wl;
            cnt++;
         }
         else
            out[ nOut++ ] = d->text[ i++ ];
      }
      out[ nOut ] = 0;
      if( cnt )
      {
         ed_getsel( d, &s, &e );
         first = ( LONG ) SendMessageW( d->hRich, EM_GETFIRSTVISIBLELINE, 0, 0 );
         SendMessageW( d->hRich, WM_SETREDRAW, FALSE, 0 );
         ed_setsel( d, 0, d->len );
         SendMessageW( d->hRich, EM_REPLACESEL, TRUE, ( LPARAM ) out );
         ed_setsel( d, s < nOut ? s : nOut, s < nOut ? s : nOut );
         newFirst = ( LONG ) SendMessageW( d->hRich, EM_GETFIRSTVISIBLELINE, 0, 0 );
         SendMessageW( d->hRich, EM_LINESCROLL, 0, ( LPARAM ) ( first - newFirst ) );
         SendMessageW( d->hRich, WM_SETREDRAW, TRUE, 0 );
         InvalidateRect( d->hRich, NULL, TRUE );
         ed_checkview( d );
         ed_highlight( d, TRUE );
      }
      hb_xfree( out );
   }
   hb_xfree( what );
   hb_xfree( with );
   hb_retnl( cnt );
}

/* IDEED_COMMAND( hView, nCmd ) -> lDone : 1 undo 2 redo 3 cut 4 copy 5 paste 6 delete 7 select all
   8 indent 9 outdent 10 comment/uncomment 11 can undo? 12 can redo? */
HB_FUNC( IDEED_COMMAND )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   hb_retl( d ? ed_command( d, hb_parni( 2 ) ) : FALSE );
}

/* IDEED_FOCUS( hView | hHost ) */
HB_FUNC( IDEED_FOCUS )
{
   HWND hWnd = PARHWND( 1 );
   if( hWnd && IsWindow( hWnd ) )
      SetFocus( hWnd );
}

/* IDEED_HIGHLIGHT( hView ) : colours the visible lines now (tests) */
HB_FUNC( IDEED_HIGHLIGHT )
{
   ed_highlight( ed_doc( PARHWND( 1 ) ), TRUE );
}

/* IDEED_COLORAT( hView, nCp ) -> { nColor, lBold, lItalic } of the character at nCp (0-based) */
HB_FUNC( IDEED_COLORAT )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   PHB_ITEM a = hb_itemArrayNew( 3 );
   ITextRange * r = NULL;
   ITextFont * f = NULL;
   long c = 0, bold = 0, ital = 0;
   if( d && d->pDoc && ITextDocument_Range( d->pDoc, hb_parnl( 2 ), hb_parnl( 2 ) + 1, &r ) == S_OK && r )
   {
      if( ITextRange_GetFont( r, &f ) == S_OK && f )
      {
         f->lpVtbl->GetForeColor( f, &c );
         f->lpVtbl->GetBold( f, &bold );
         f->lpVtbl->GetItalic( f, &ital );
         ITextFont_Release( f );
      }
      ITextRange_Release( r );
   }
   hb_arraySetNL( a, 1, c );
   hb_arraySetL( a, 2, bold == tomTrue );
   hb_arraySetL( a, 3, ital == tomTrue );
   hb_itemReturnRelease( a );
}

/* IDEED_STYLECOLOR( hHost, nStyle ) -> nColor of the palette in use (tests) */
HB_FUNC( IDEED_STYLECOLOR )
{
   EDHOST * h = ed_host( PARHWND( 1 ) );
   int st = hb_parni( 2 );
   hb_retnl( h && st >= 0 && st < ST_COUNT ? ( long ) ed_pal( h )[ st ] : -1 );
}

/* IDEED_TYPE( hView, cKeys [, nMods] ) : sends the characters as typing would (tests);
   Chr(13) is Enter, Chr(9) Tab; nMods as in event 4 (0x20000 = Shift) */
HB_FUNC( IDEED_TYPE )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   int n, i;
   WCHAR * w;
   if( ! d )
      return;
   w = ed_towide( hb_parcx( 2 ), hb_parclen( 2 ), s_cp, &n );
   s_fakeMods = hb_parni( 3 );
   for( i = 0; i < n; i++ )
   {
      if( w[ i ] == '\r' || w[ i ] == '\t' )
      {
         SendMessageW( d->hRich, WM_KEYDOWN, w[ i ] == '\r' ? VK_RETURN : VK_TAB, 0 );
         SendMessageW( d->hRich, WM_CHAR, w[ i ], 0 );
      }
      else if( w[ i ] != '\n' )
         SendMessageW( d->hRich, WM_CHAR, w[ i ], 0 );
   }
   s_fakeMods = -1;
   hb_xfree( w );
}

/* IDEED_SETSEL( hView, nStart, nEnd ) : 0-based (tests) */
HB_FUNC( IDEED_SETSEL )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   if( d )
   {
      ed_setsel( d, hb_parnl( 2 ), hb_parnl( 3 ) );
      ed_checkview( d );
   }
}

/* the visible frame of a window (Windows 10/11 add invisible resize borders to GetWindowRect) */
typedef HRESULT ( WINAPI * ED_PFN_DWMGETATTR )( HWND, DWORD, PVOID, DWORD );

static void ed_frame( HWND hWnd, RECT * rc )
{
   static HMODULE hDwm = NULL;
   if( hDwm == NULL )
      hDwm = LoadLibraryExW( L"dwmapi.dll", NULL, 0x00000800 /* LOAD_LIBRARY_SEARCH_SYSTEM32 */ );
   ED_PFN_DWMGETATTR pGet = hDwm ? ( ED_PFN_DWMGETATTR ) ( void * ) GetProcAddress( hDwm, "DwmGetWindowAttribute" ) : NULL;

   GetWindowRect( hWnd, rc );
   if( pGet )
   {
      RECT r;
      if( SUCCEEDED( pGet( hWnd, 9 /* DWMWA_EXTENDED_FRAME_BOUNDS */, &r, sizeof( r ) ) ) && r.right > r.left )
         *rc = r;
   }
}

/* IDEED_PLACE( hWnd, hMain, hLeft ) : puts the editor window in the free space of the IDE:
   below the main window (menu and toolbars), right of hLeft (the Project Browser; 0: none),
   down to the bottom of the work area of the monitor the main window is on. Physical pixels, so
   it is right at any DPI. Returns .T. when it moved the window. */
typedef HANDLE ( WINAPI * ED_PFN_SETTHREADDPICTX )( HANDLE );

static HB_BOOL ed_place( HWND hWnd, HWND hMain, HWND hLeft );

HB_FUNC( IDEED_PLACE )
{
   /* physical pixels whatever the IDE's DPI awareness: a DPI-unaware IDE is scaled by Windows, and
      the visible frame (DWM) is reported in physical pixels; Windows 10 1607+ */
   ED_PFN_SETTHREADDPICTX pSet = ( ED_PFN_SETTHREADDPICTX ) ( void * ) GetProcAddress( GetModuleHandleW( L"user32.dll" ), "SetThreadDpiAwarenessContext" );
   HANDLE hOld = pSet ? pSet( ( HANDLE ) -4 /* DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 */ ) : NULL;
   HB_BOOL lOk = ed_place( PARHWND( 1 ), PARHWND( 2 ), PARHWND( 3 ) );
   if( hOld )
      pSet( hOld );
   hb_retl( lOk );
}

static HB_BOOL ed_place( HWND hWnd, HWND hMain, HWND hLeft )
{
   MONITORINFO mi;
   RECT rMain, rLeft, rWin, rVis, rc;

   if( ! IsWindow( hWnd ) || ! IsWindow( hMain ) )
   {
      return HB_FALSE;
   }
   mi.cbSize = sizeof( mi );
   GetMonitorInfoW( MonitorFromWindow( hMain, MONITOR_DEFAULTTONEAREST ), &mi );
   ed_frame( hMain, &rMain );

   rc        = mi.rcWork;
   rc.top    = rMain.bottom;
   if( hLeft && IsWindow( hLeft ) && IsWindowVisible( hLeft ) )
   {
      ed_frame( hLeft, &rLeft );
      if( rLeft.right > rc.left && rLeft.right < rc.right - 300 )
         rc.left = rLeft.right;
   }
   if( rc.bottom - rc.top < 200 || rc.right - rc.left < 300 )   /* no room: leave it where it is */
   {
      return HB_FALSE;
   }

   /* the editor's own invisible borders: GetWindowRect minus its visible frame */
   GetWindowRect( hWnd, &rWin );
   ed_frame( hWnd, &rVis );
   if( ! IsWindowVisible( hWnd ) )   /* DWM has frame bounds only for a shown window: called again after showing */
      rVis = rWin;
   rc.left   -= rVis.left - rWin.left;
   rc.top    -= rVis.top - rWin.top;
   rc.right  += rWin.right - rVis.right;
   rc.bottom += rWin.bottom - rVis.bottom;

   if( IsZoomed( hWnd ) )
      ShowWindow( hWnd, SW_RESTORE );
   SetWindowPos( hWnd, NULL, rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top, SWP_NOZORDER | SWP_NOACTIVATE );
   return HB_TRUE;
}

/* IDEED_FIT( hHost ) : fills the parent's client area above its status bar */
HB_FUNC( IDEED_FIT )
{
   EDHOST * h = ed_host( PARHWND( 1 ) );
   if( h )
   {
      HWND hParent = GetParent( h->hHost ), hc;
      RECT rc;
      int bottom;
      GetClientRect( hParent, &rc );
      bottom = rc.bottom;
      for( hc = GetWindow( hParent, GW_CHILD ); hc; hc = GetWindow( hc, GW_HWNDNEXT ) )
      {
         WCHAR cls[ 64 ];
         if( ( GetWindowLongW( hc, GWL_STYLE ) & WS_VISIBLE ) && GetClassNameW( hc, cls, 64 ) && lstrcmpiW( cls, STATUSCLASSNAMEW ) == 0 )
         {
            RECT rs;
            GetWindowRect( hc, &rs );
            bottom -= rs.bottom - rs.top;
         }
      }
      MoveWindow( h->hHost, 0, 0, rc.right, bottom > 0 ? bottom : 0, TRUE );
   }
}

/* IDEED_ASK( hParent, cText, cTitle ) -> 1 Yes, 0 No, -1 Cancel */
HB_FUNC( IDEED_ASK )
{
   WCHAR * t = ed_towide( hb_parcx( 2 ), hb_parclen( 2 ), s_cp, NULL );
   WCHAR * c = ed_towide( hb_parcx( 3 ), hb_parclen( 3 ), s_cp, NULL );
   int r = MessageBoxW( PARHWND( 1 ), t, c, MB_YESNOCANCEL | MB_ICONQUESTION );
   hb_xfree( t );
   hb_xfree( c );
   hb_retni( r == IDYES ? 1 : ( r == IDNO ? 0 : -1 ) );
}

/* IDEED_SETLANG( hView, lC ) : .T. for a C file (.c, .h): C comment and string rules */
HB_FUNC( IDEED_SETLANG )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   if( d && d->bC != hb_parl( 2 ) )
   {
      d->bC = hb_parl( 2 );
      d->hlVer = -1;
      ed_highlight( d, TRUE );
   }
}

/* IDEED_SETFONT( hHost, cFont, nSize, nIndent ) : the font, its size in points and the indent
   (spaces a Tab inserts) of every open file and of the files opened later */
HB_FUNC( IDEED_SETFONT )
{
   EDHOST * h = ed_host( PARHWND( 1 ) );
   int i, n;
   if( ! h )
      return;
   if( HB_ISCHAR( 2 ) && hb_parclen( 2 ) )
   {
      WCHAR * w = ed_towide( hb_parc( 2 ), hb_parclen( 2 ), s_cp, NULL );
      lstrcpynW( h->face, w, LF_FACESIZE );
      hb_xfree( w );
   }
   if( hb_parni( 3 ) >= 6 && hb_parni( 3 ) <= 48 )
      h->nSize = hb_parni( 3 );
   if( hb_parni( 4 ) >= 1 && hb_parni( 4 ) <= 16 )
      h->nIndent = hb_parni( 4 );
   ac_hide( h );
   if( h->hPop && IsWindow( h->hPop ) )
      DestroyWindow( h->hPop );   /* made again with the new font */
   h->hPop = h->hList = NULL;
   ed_hostfonts( h );
   n = ed_tabcount( h );
   for( i = 0; i < n; i++ )
   {
      EDDOC * d = ed_doc( ed_tabview( h, i ) );
      if( d )
      {
         ed_applyformat( d );
         ed_layout( d );
         ed_highlight( d, TRUE );
      }
   }
   ed_hostlayout( h );
}

static int CALLBACK ed_fontproc( const LOGFONTW * lf, const TEXTMETRICW * tm, DWORD type, LPARAM lp )
{
   PHB_ITEM a = ( PHB_ITEM ) lp;
   HB_SIZE i, n = hb_arrayLen( a );
   char b[ LF_FACESIZE * 4 ];
   int m;
   ( void ) tm;
   ( void ) type;
   if( ( lf->lfPitchAndFamily & 3 ) != FIXED_PITCH || lf->lfFaceName[ 0 ] == '@' )
      return 1;
   m = WideCharToMultiByte( s_cp, 0, lf->lfFaceName, -1, b, ( int ) sizeof( b ), NULL, NULL );
   if( m <= 1 )
      return 1;
   for( i = 1; i <= n; i++ )
      if( strcmp( hb_arrayGetCPtr( a, i ), b ) == 0 )
         return 1;
   {
      PHB_ITEM it = hb_itemPutC( NULL, b );
      hb_arrayAddForward( a, it );
      hb_itemRelease( it );
   }
   return 1;
}

/* IDEED_FIXEDFONTS() -> { cFace, ... } the installed fixed-pitch (monospaced) fonts */
HB_FUNC( IDEED_FIXEDFONTS )
{
   PHB_ITEM a = hb_itemArrayNew( 0 );
   LOGFONTW lf;
   HDC hdc = GetDC( NULL );
   memset( &lf, 0, sizeof( lf ) );
   lf.lfCharSet = DEFAULT_CHARSET;
   EnumFontFamiliesExW( hdc, &lf, ( FONTENUMPROCW ) ed_fontproc, ( LPARAM ) a, 0 );
   ReleaseDC( NULL, hdc );
   hb_itemReturnRelease( a );
}

/* IDEED_COMPLETE( hView [, nAction] ) -> { cItem, ... } shown by the completion list (empty:
   closed); nAction 1 opens it as Ctrl+Space does, 2 inserts the selected item, 3 closes it,
   4 selects the next item (tests) */
HB_FUNC( IDEED_COMPLETE )
{
   EDDOC * d = ed_doc( PARHWND( 1 ) );
   PHB_ITEM a = hb_itemArrayNew( 0 );
   if( d )
   {
      switch( hb_parni( 2 ) )
      {
         case 1: ac_open( d, TRUE ); break;
         case 2: if( ac_visible( d ) ) ac_accept( d->host ); break;
         case 3: ac_hide( d->host ); break;
         case 4: if( ac_visible( d ) ) ac_move( d->host, 1 ); break;
      }
      if( ac_visible( d ) )
      {
         LRESULT i, n = SendMessageW( d->host->hList, LB_GETCOUNT, 0, 0 );
         for( i = 0; i < n; i++ )
         {
            LRESULT k = SendMessageW( d->host->hList, LB_GETITEMDATA, ( WPARAM ) i, 0 );
            if( k >= 0 && k < d->host->acN )
            {
               const WCHAR * w = d->host->ac[ k ].name;
               int m = WideCharToMultiByte( s_cp, 0, w, -1, NULL, 0, NULL, NULL );
               char * b = ( char * ) hb_xgrab( m + 1 );
               PHB_ITEM it;
               WideCharToMultiByte( s_cp, 0, w, -1, b, m, NULL, NULL );
               it = hb_itemPutC( NULL, b );
               hb_arrayAddForward( a, it );
               hb_itemRelease( it );
               hb_xfree( b );
            }
         }
      }
   }
   hb_itemReturnRelease( a );
}
