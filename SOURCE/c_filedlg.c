/*----------------------------------------------------------------------------
 HMG5 - modern file dialogs (Phase 4 F), see PHASE4-DESIGN.md section 4.

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).

 SET FILEDIALOG MODERN makes C_GETFILE / C_PUTFILE / C_GETFOLDER (c_dialogs.c),
 and so GetFile / PutFile / GetFolder, use IFileOpenDialog / IFileSaveDialog.
 Same arguments, same return values; no MAX_PATH buffers; GetFolder gets the
 Explorer-style folder picker instead of the SHBrowseForFolder tree.

 Each entry point returns FALSE when it did not show a dialog (COM unavailable
 on this thread, or a GetFolder request the picker cannot serve: files, computers,
 printers); the caller then runs the classic dialog.
---------------------------------------------------------------------------*/

#include "SET_COMPILE_HMG_UNICODE.ch"
#include "HMG_UNICODE.h"

#define COBJMACROS
#include <windows.h>
#include <shlobj.h>
#include <shobjidl.h>

#include "hbapi.h"

#ifdef UNICODE
   #define FD_W( c )   HMG_CHAR_TO_WCHAR( c )   // UTF-8 -> UTF-16, frame-owned
   #define FD_A( w )   HMG_WCHAR_TO_CHAR( w )
#else
   #define FD_W( c )   HMG_MBtoWC( c )          // ANSI code page -> UTF-16, frame-owned
   #define FD_A( w )   HMG_WCtoMB( w )
#endif

/* local GUIDs: no dependency on libuuid in user programs */
static const CLSID s_CLSID_FileOpenDialog = { 0xDC1C5A9C, 0xE88A, 0x4DDE, { 0xA5, 0xA1, 0x60, 0xF8, 0x2A, 0x20, 0xAE, 0xF7 } };
static const CLSID s_CLSID_FileSaveDialog = { 0xC0B4E2F3, 0xBA21, 0x4773, { 0x8D, 0xBA, 0x33, 0x5E, 0xC9, 0x46, 0xEB, 0x8B } };
static const IID   s_IID_IFileOpenDialog  = { 0xD57C7288, 0xD4AD, 0x4768, { 0xBE, 0x02, 0x9D, 0x96, 0x95, 0x32, 0xD9, 0x60 } };
static const IID   s_IID_IFileSaveDialog  = { 0x84BCCD23, 0x5FDE, 0x4CDB, { 0xAE, 0xA4, 0xAF, 0x64, 0xB8, 0x3D, 0x78, 0xAB } };
static const IID   s_IID_IShellItem       = { 0x43826D1E, 0xE718, 0x42EE, { 0xBC, 0x55, 0xA1, 0xE2, 0x61, 0xC3, 0x7B, 0xFE } };

static int s_fdModern = 0;   // SET FILEDIALOG MODERN
static int s_fdLast   = 0;   // kind of the last dialog shown: 1 modern, 0 classic (for tests)

BOOL HMG_FileDlgIsModern( void )
{
   return s_fdModern;
}

void HMG_FileDlgUsed( int nKind )
{
   s_fdLast = nKind;
}

/* HMG_FILEDIALOG_MODERN( [lOn] ) -> lWasOn */
HB_FUNC( HMG_FILEDIALOG_MODERN )
{
   hb_retl( s_fdModern );
   if( HB_ISLOG( 1 ) )
      s_fdModern = hb_parl( 1 );
}

/* HMG_FILEDIALOG_LASTKIND() -> 1 modern, 0 classic */
HB_FUNC( HMG_FILEDIALOG_LASTKIND )
{
   hb_retni( s_fdLast );
}

/* 1: initialised here (caller uninitialises), 0: already STA, -1: unusable (MTA thread) */
static int fd_comInit( void )
{
   HRESULT hr = CoInitializeEx( NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE );
   if( hr == S_OK )
      return 1;
   if( hr == S_FALSE )   // already initialised as STA: balance the extra reference
   {
      CoUninitialize();
      return 0;
   }
   return -1;
}

static IShellItem * fd_itemFromPath( LPCWSTR cPath )
{
   IShellItem * pItem = NULL;
   if( cPath && *cPath )
   {
      if( FAILED( SHCreateItemFromParsingName( cPath, NULL, &s_IID_IShellItem, ( void ** ) &pItem ) ) )
         pItem = NULL;
   }
   return pItem;
}

static void fd_setFolder( IFileDialog * pDlg, LPCWSTR cPath )
{
   IShellItem * pItem = fd_itemFromPath( cPath );
   if( pItem )
   {
      IFileDialog_SetFolder( pDlg, pItem );
      IShellItem_Release( pItem );
   }
}

/* "name\0spec\0name\0spec\0\0" (as GetFile/PutFile build it) -> SetFileTypes + SetFileTypeIndex */
static void fd_setFilter( IFileDialog * pDlg, int iParam, int iIndexParam )
{
   const char * p    = hb_parc( iParam );
   HB_SIZE      nLen = hb_parclen( iParam ), nPos = 0;
   COMDLG_FILTERSPEC * aSpec;
   UINT nSpec = 0, nMax = 0;

   if( p == NULL || nLen == 0 )
      return;
   while( nPos < nLen && p[ nPos ] )   // count pairs
   {
      nPos += strlen( p + nPos ) + 1;
      if( nPos < nLen && p[ nPos ] )
      {
         nPos += strlen( p + nPos ) + 1;
         nMax++;
      }
   }
   if( nMax == 0 )
      return;
   aSpec = ( COMDLG_FILTERSPEC * ) hb_xgrab( nMax * sizeof( COMDLG_FILTERSPEC ) );
   nPos  = 0;
   while( nSpec < nMax )
   {
      aSpec[ nSpec ].pszName = FD_W( p + nPos );
      nPos += strlen( p + nPos ) + 1;
      aSpec[ nSpec ].pszSpec = FD_W( p + nPos );
      nPos += strlen( p + nPos ) + 1;
      nSpec++;
   }
   IFileDialog_SetFileTypes( pDlg, nSpec, aSpec );
   IFileDialog_SetFileTypeIndex( pDlg, ( hb_parni( iIndexParam ) > 0 && ( UINT ) hb_parni( iIndexParam ) <= nSpec ) ? ( UINT ) hb_parni( iIndexParam ) : 1 );
   hb_xfree( aSpec );
}

static void fd_setTitle( IFileDialog * pDlg, int iParam )
{
   if( HB_ISCHAR( iParam ) && hb_parclen( iParam ) > 0 )
      IFileDialog_SetTitle( pDlg, FD_W( hb_parc( iParam ) ) );
}

/* path of a shell item, CoTaskMemAlloc'ed (NULL when it has none) */
static LPWSTR fd_itemPath( IShellItem * pItem )
{
   LPWSTR cPath = NULL;
   if( FAILED( IShellItem_GetDisplayName( pItem, SIGDN_FILESYSPATH, &cPath ) ) )
      cPath = NULL;
   return cPath;
}

/* the classic dialogs change the current directory to the chosen file's folder
   unless asked not to; the modern ones never do (FOS_NOCHANGEDIR), so it is done here */
static void fd_changeDirTo( LPCWSTR cFile )
{
   size_t n = wcslen( cFile );
   LPWSTR cDir;
   while( n > 0 && cFile[ n - 1 ] != L'\\' && cFile[ n - 1 ] != L'/' )
      n--;
   if( n == 0 )
      return;
   if( n > 1 && cFile[ n - 2 ] != L':' )   // keep the backslash of "C:\"
      n--;
   cDir = ( LPWSTR ) hb_xgrab( ( n + 1 ) * sizeof( WCHAR ) );
   memcpy( cDir, cFile, n * sizeof( WCHAR ) );
   cDir[ n ] = 0;
   SetCurrentDirectoryW( cDir );
   hb_xfree( cDir );
}

static HWND fd_owner( void )
{
   return GetActiveWindow();
}

/* C_GETFILE( cFilter, cTitle, cIniFolder, lMultiSelect, lNoChangeDir, nFilterIndex ) */
BOOL HMG_ModernGetFile( void )
{
   int com = fd_comInit();
   IFileOpenDialog * pOpen = NULL;
   IFileDialog * pDlg;
   FILEOPENDIALOGOPTIONS nOpt = 0;
   HRESULT hr;

   if( com < 0 )
      return FALSE;
   if( FAILED( CoCreateInstance( &s_CLSID_FileOpenDialog, NULL, CLSCTX_INPROC_SERVER, &s_IID_IFileOpenDialog, ( void ** ) &pOpen ) ) )
   {
      if( com )
         CoUninitialize();
      return FALSE;
   }
   s_fdLast = 1;
   pDlg = ( IFileDialog * ) pOpen;

   IFileDialog_GetOptions( pDlg, &nOpt );
   nOpt |= FOS_FILEMUSTEXIST | FOS_PATHMUSTEXIST | FOS_FORCEFILESYSTEM | FOS_NOCHANGEDIR;
   if( hb_parl( 4 ) )
      nOpt |= FOS_ALLOWMULTISELECT;
   IFileDialog_SetOptions( pDlg, nOpt );
   fd_setTitle( pDlg, 2 );
   fd_setFilter( pDlg, 1, 6 );
   if( HB_ISCHAR( 3 ) )
      fd_setFolder( pDlg, FD_W( hb_parc( 3 ) ) );

   hr = IFileDialog_Show( pDlg, fd_owner() );
   hb_retc( "" );
   if( SUCCEEDED( hr ) )
   {
      IShellItemArray * pItems = NULL;
      if( SUCCEEDED( IFileOpenDialog_GetResults( pOpen, &pItems ) ) )
      {
         DWORD nCount = 0, i;
         IShellItemArray_GetCount( pItems, &nCount );
         if( nCount > 1 )
            hb_reta( nCount );
         for( i = 0; i < nCount; i++ )
         {
            IShellItem * pItem = NULL;
            if( SUCCEEDED( IShellItemArray_GetItemAt( pItems, i, &pItem ) ) )
            {
               LPWSTR cPath = fd_itemPath( pItem );
               if( cPath )
               {
                  if( nCount > 1 )
                     hb_storvc( FD_A( cPath ), -1, ( HB_SIZE ) i + 1 );
                  else
                     hb_retc( FD_A( cPath ) );
                  if( i == 0 && ! hb_parl( 5 ) )
                     fd_changeDirTo( cPath );
                  CoTaskMemFree( cPath );
               }
               IShellItem_Release( pItem );
            }
         }
         IShellItemArray_Release( pItems );
      }
   }
   IFileOpenDialog_Release( pOpen );
   if( com )
      CoUninitialize();
   return TRUE;
}

/* C_PUTFILE( cFilter, cTitle, cIniFolder, lNoChangeDir, cDefaultFileName, @cExtFile, @nFilterIndex ) */
BOOL HMG_ModernPutFile( void )
{
   int com = fd_comInit();
   IFileSaveDialog * pSave = NULL;
   IFileDialog * pDlg;
   FILEOPENDIALOGOPTIONS nOpt = 0;
   HRESULT hr;

   if( com < 0 )
      return FALSE;
   if( FAILED( CoCreateInstance( &s_CLSID_FileSaveDialog, NULL, CLSCTX_INPROC_SERVER, &s_IID_IFileSaveDialog, ( void ** ) &pSave ) ) )
   {
      if( com )
         CoUninitialize();
      return FALSE;
   }
   s_fdLast = 1;
   pDlg = ( IFileDialog * ) pSave;

   IFileDialog_GetOptions( pDlg, &nOpt );
   nOpt |= FOS_OVERWRITEPROMPT | FOS_PATHMUSTEXIST | FOS_FORCEFILESYSTEM | FOS_NOCHANGEDIR;
   IFileDialog_SetOptions( pDlg, nOpt );
   fd_setTitle( pDlg, 2 );
   fd_setFilter( pDlg, 1, 7 );
   if( HB_ISCHAR( 3 ) )
      fd_setFolder( pDlg, FD_W( hb_parc( 3 ) ) );
   if( HB_ISCHAR( 6 ) && hb_parclen( 6 ) > 0 )
   {
      LPCWSTR cExt = FD_W( hb_parc( 6 ) );
      while( *cExt == L'.' )
         cExt++;
      if( *cExt )
         IFileDialog_SetDefaultExtension( pDlg, cExt );
   }
   if( HB_ISCHAR( 5 ) && hb_parclen( 5 ) > 0 )
   {
      // a default name with a folder ("C:\data\a.txt", as the classic dialog accepts) opens that folder
      LPWSTR cName = FD_W( hb_parc( 5 ) );
      LPWSTR cSlash = wcsrchr( cName, L'\\' );
      if( cSlash )
      {
         size_t n = ( size_t ) ( cSlash - cName );
         LPWSTR cDir = ( LPWSTR ) hb_xgrab( ( n + 2 ) * sizeof( WCHAR ) );
         memcpy( cDir, cName, n * sizeof( WCHAR ) );
         cDir[ n ] = 0;
         if( n == 2 && cName[ 1 ] == L':' )
         {
            cDir[ 2 ] = L'\\';
            cDir[ 3 ] = 0;
         }
         fd_setFolder( pDlg, cDir );
         hb_xfree( cDir );
         cName = cSlash + 1;
      }
      IFileDialog_SetFileName( pDlg, cName );
   }

   hr = IFileDialog_Show( pDlg, fd_owner() );
   hb_retc( "" );
   if( SUCCEEDED( hr ) )
   {
      IShellItem * pItem = NULL;
      if( SUCCEEDED( IFileDialog_GetResult( pDlg, &pItem ) ) )
      {
         LPWSTR cPath = fd_itemPath( pItem );
         if( cPath )
         {
            hb_retc( FD_A( cPath ) );
            if( HB_ISBYREF( 6 ) )
            {
               LPWSTR cDot = wcsrchr( cPath, L'.' ), cSep = wcsrchr( cPath, L'\\' );
               hb_storc( ( cDot && ( ! cSep || cDot > cSep ) ) ? FD_A( cDot + 1 ) : "", 6 );
            }
            if( ! hb_parl( 4 ) )
               fd_changeDirTo( cPath );
            CoTaskMemFree( cPath );
         }
         IShellItem_Release( pItem );
      }
      if( HB_ISBYREF( 7 ) )
      {
         UINT nIndex = 0;
         if( SUCCEEDED( IFileDialog_GetFileTypeIndex( pDlg, &nIndex ) ) )
            hb_storni( ( int ) nIndex, 7 );
      }
   }
   IFileSaveDialog_Release( pSave );
   if( com )
      CoUninitialize();
   return TRUE;
}

/* C_GETFOLDER( cTitle, nBIF_Flags, nCSIDL, cInvalidDataMsg, cInitPath ) */
BOOL HMG_ModernGetFolder( void )
{
   int com;
   IFileOpenDialog * pOpen = NULL;
   IFileDialog * pDlg;
   FILEOPENDIALOGOPTIONS nOpt = 0;
   HRESULT hr;

   // the folder picker shows folders only
   if( ( ( DWORD ) hb_parnl( 2 ) ) & ( BIF_BROWSEINCLUDEFILES | BIF_BROWSEFORCOMPUTER | BIF_BROWSEFORPRINTER ) )
      return FALSE;
   com = fd_comInit();
   if( com < 0 )
      return FALSE;
   if( FAILED( CoCreateInstance( &s_CLSID_FileOpenDialog, NULL, CLSCTX_INPROC_SERVER, &s_IID_IFileOpenDialog, ( void ** ) &pOpen ) ) )
   {
      if( com )
         CoUninitialize();
      return FALSE;
   }
   s_fdLast = 1;
   pDlg = ( IFileDialog * ) pOpen;

   IFileDialog_GetOptions( pDlg, &nOpt );
   nOpt |= FOS_PICKFOLDERS | FOS_PATHMUSTEXIST | FOS_FORCEFILESYSTEM | FOS_NOCHANGEDIR;
   IFileDialog_SetOptions( pDlg, nOpt );
   fd_setTitle( pDlg, 1 );
   if( HB_ISCHAR( 5 ) && hb_parclen( 5 ) > 0 )
      fd_setFolder( pDlg, FD_W( hb_parc( 5 ) ) );
   else if( HB_ISNUM( 3 ) )   // the picker has no root: start in the special folder instead
   {
      LPITEMIDLIST pidl = NULL;
      if( SUCCEEDED( SHGetSpecialFolderLocation( NULL, hb_parni( 3 ), &pidl ) ) && pidl )
      {
         IShellItem * pItem = NULL;
         if( SUCCEEDED( SHCreateItemFromIDList( pidl, &s_IID_IShellItem, ( void ** ) &pItem ) ) )
         {
            IFileDialog_SetFolder( pDlg, pItem );
            IShellItem_Release( pItem );
         }
         CoTaskMemFree( pidl );
      }
   }

   hr = IFileDialog_Show( pDlg, fd_owner() );
   hb_retc( "" );
   if( SUCCEEDED( hr ) )
   {
      IShellItem * pItem = NULL;
      if( SUCCEEDED( IFileDialog_GetResult( pDlg, &pItem ) ) )
      {
         LPWSTR cPath = fd_itemPath( pItem );
         if( cPath )
         {
            hb_retc( FD_A( cPath ) );
            CoTaskMemFree( cPath );
         }
         IShellItem_Release( pItem );
      }
   }
   IFileOpenDialog_Release( pOpen );
   if( com )
      CoUninitialize();
   return TRUE;
}
