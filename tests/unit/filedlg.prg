/*
 * Unit test for the modern file dialogs (PHASE4-DESIGN.md section 4, SOURCE/c_filedlg.c).
 * GetFile / PutFile / GetFolder are modal: a helper thread (C, below) finds the dialog this
 * process opened, types the answer into its file-name box and presses OK or Cancel.
 * The same answers are given to the classic dialogs, so both return the same values.
 */
#include "hmg.ch"

#define BIF_BROWSEINCLUDEFILES  0x4000

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   LOCAL cDir, cHome := hb_cwd(), x, cExt, nIdx, cSub

   ErrorBlock( {| e | OutStd( "filedlg: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   cDir := hb_DirSepAdd( hb_DirTemp() ) + "hmgfd" + hb_ntos( hb_RandomInt( 100000, 999999 ) )
   hb_DirCreate( cDir )
   cSub := cDir + "\sub"
   hb_DirCreate( cSub )
   hb_MemoWrit( cDir + "\a.txt", "a" )
   hb_MemoWrit( cDir + "\b.txt", "b" )
   hb_MemoWrit( cDir + "\c.log", "c" )

   Check( "classic by default", ! HMG_IsModernFileDialog() )

   // classic, as the reference
   TEST_ANSWER( "a.txt", 1 )
   x := GetFile( { { "Text", "*.txt" } }, "fdtest", cDir, , .T. )
   Check( "classic getfile", x == cDir + "\a.txt" )
   Check( "classic kind",    HMG_FILEDIALOG_LASTKIND() == 0 )

   SET FILEDIALOG MODERN
   Check( "modern on", HMG_IsModernFileDialog() )

   // single file, title, current directory left alone
   TEST_ANSWER( "a.txt", 1 )
   x := GetFile( { { "Text", "*.txt" }, { "All", "*.*" } }, "fdtest open", cDir, , .T. )
   Check( "getfile",            x == cDir + "\a.txt" )
   Check( "getfile kind",       HMG_FILEDIALOG_LASTKIND() == 1 )
   Check( "getfile title",      TEST_LASTTITLE() == "fdtest open" )
   Check( "nochangedir",        hb_cwd() == cHome )

   // without NOCHANGEDIR the current directory moves to the file's folder (as classic)
   TEST_ANSWER( "c.log", 1 )
   x := GetFile( { { "Log", "*.log" } }, "fdtest", cDir )
   Check( "getfile log",        x == cDir + "\c.log" )
   Check( "changedir",          hb_DirSepDel( hb_cwd() ) == cDir )
   hb_cwd( cHome )

   // multiselect
   TEST_ANSWER( '"a.txt" "b.txt"', 1 )
   x := GetFile( { { "Text", "*.txt" } }, "fdtest", cDir, .T., .T. )
   Check( "multi count",        HB_ISARRAY( x ) .AND. Len( x ) == 2 )
   Check( "multi names",        HB_ISARRAY( x ) .AND. Len( x ) == 2 .AND. ;
                                AScan( x, cDir + "\a.txt" ) > 0 .AND. AScan( x, cDir + "\b.txt" ) > 0 )
   TEST_ANSWER( "b.txt", 1 )
   x := GetFile( { { "Text", "*.txt" } }, "fdtest", cDir, .T., .T. )
   Check( "multi one",          HB_ISARRAY( x ) .AND. Len( x ) == 1 .AND. x[ 1 ] == cDir + "\b.txt" )

   // cancel
   TEST_ANSWER( "", 2 )
   x := GetFile( { { "Text", "*.txt" } }, "fdtest", cDir, , .T. )
   Check( "getfile cancel",     HB_ISCHAR( x ) .AND. x == "" )
   Check( "dialog seen",        TEST_SEEN() )

   // save: default extension, extension and filter index returned by reference
   cExt := "txt"
   nIdx := 1
   TEST_ANSWER( "new", 1 )
   x := PutFile( { { "Text", "*.txt" }, { "All", "*.*" } }, "fdtest save", cDir, .T., "", @cExt, @nIdx )
Check( "putfile",            x == cDir + "\new.txt" )
   Check( "putfile kind",       HMG_FILEDIALOG_LASTKIND() == 1 )
   Check( "putfile ext",        cExt == "txt" )
   Check( "putfile index",      nIdx == 1 )
   Check( "putfile title",      TEST_LASTTITLE() == "fdtest save" )

   // default name with a folder: accepted as typed
   TEST_ANSWER( NIL, 1 )
   x := PutFile( { { "All", "*.*" } }, "fdtest", , .T., cDir + "\d.dat" )
   Check( "putfile default",    x == cDir + "\d.dat" )

   TEST_ANSWER( "", 2 )
   x := PutFile( { { "All", "*.*" } }, "fdtest", cDir, .T. )
   Check( "putfile cancel",     x == "" )

   // folder picker
   TEST_ANSWER( NIL, 1 )   // Select Folder on the starting folder
   x := GetFolder( "fdtest folder", cSub )
   Check( "getfolder",          x == cSub )
   Check( "getfolder kind",     HMG_FILEDIALOG_LASTKIND() == 1 )

   TEST_ANSWER( "", 2 )
   x := GetFolder( "fdtest folder", cDir )
   Check( "getfolder cancel",   x == "" )

   // a request the picker cannot serve falls back to the classic tree
   TEST_ANSWER( "", 2 )
   x := GetFolder( "fdtest", cDir, , , , , BIF_BROWSEINCLUDEFILES )
   Check( "fallback kind",      HMG_FILEDIALOG_LASTKIND() == 0 .AND. x == "" )

   SET FILEDIALOG CLASSIC
   Check( "classic again",      ! HMG_IsModernFileDialog() )
   TEST_ANSWER( "b.txt", 1 )
   x := GetFile( { { "Text", "*.txt" } }, "fdtest", cDir, , .T. )
   Check( "classic again file", x == cDir + "\b.txt" .AND. HMG_FILEDIALOG_LASTKIND() == 0 )

   AEval( { "a.txt", "b.txt", "c.log", "new.txt", "d.dat" }, {| f | FErase( cDir + "\" + f ) } )
   DirRemove( cSub )
   DirRemove( cDir )

   OutStd( "filedlg: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "filedlg: FAIL " + cName + hb_eol() )
   ENDIF
RETURN

#pragma BEGINDUMP

#include <windows.h>
#include "hbapi.h"

static WCHAR s_cText[ 1024 ];
static int   s_lSetText;
static int   s_nAction;          /* 1 OK, 2 Cancel */
static volatile LONG s_lSeen;
static char  s_cTitle[ 256 ];

typedef struct { DWORD pid; HWND hDlg; } FINDDLG;

static BOOL CALLBACK td_findTop( HWND h, LPARAM l )
{
   FINDDLG * f = ( FINDDLG * ) l;
   DWORD pid = 0;
   WCHAR cls[ 32 ];
   GetWindowThreadProcessId( h, &pid );
   if( pid == f->pid && IsWindowVisible( h ) && GetClassNameW( h, cls, 32 ) && lstrcmpW( cls, L"#32770" ) == 0 )
   {
      f->hDlg = h;
      return FALSE;
   }
   return TRUE;
}

typedef struct { int id; HWND h; } FINDCTL;

static BOOL CALLBACK td_findCtl( HWND h, LPARAM l )
{
   FINDCTL * f = ( FINDCTL * ) l;
   if( GetDlgCtrlID( h ) == f->id )
   {
      f->h = h;
      return FALSE;
   }
   return TRUE;
}

static HWND td_ctl( HWND hDlg, int id )
{
   FINDCTL f;
   f.id = id;
   f.h  = NULL;
   EnumChildWindows( hDlg, td_findCtl, ( LPARAM ) &f );
   return f.h;
}

static DWORD WINAPI td_thread( LPVOID p )
{
   FINDDLG f;
   int i;
   ( void ) p;
   f.pid  = GetCurrentProcessId();
   f.hDlg = NULL;
   for( i = 0; i < 200 && ! f.hDlg; i++ )
   {
      Sleep( 50 );
      EnumWindows( td_findTop, ( LPARAM ) &f );
   }
   if( ! f.hDlg )
      return 0;
   Sleep( 400 );   /* let the dialog finish initialising */
   InterlockedExchange( &s_lSeen, 1 );
   GetWindowTextA( f.hDlg, s_cTitle, sizeof( s_cTitle ) );
   if( s_nAction == 1 )
   {
      if( s_lSetText )
      {
         /* the file-name box has the focus when the dialog opens */
         GUITHREADINFO gti;
         HWND hEdit = NULL;
         WCHAR cls[ 32 ];
         gti.cbSize = sizeof( gti );
         if( GetGUIThreadInfo( GetWindowThreadProcessId( f.hDlg, NULL ), &gti ) && gti.hwndFocus
             && GetClassNameW( gti.hwndFocus, cls, 32 ) && lstrcmpiW( cls, L"Edit" ) == 0 )
            hEdit = gti.hwndFocus;
         if( ! hEdit )
         {
            HWND hName = td_ctl( f.hDlg, 1148 );
            hEdit = hName ? FindWindowExW( hName, NULL, L"Edit", NULL ) : NULL;
            if( ! hEdit )
               hEdit = hName;
         }
         SetWindowTextW( hEdit, s_cText );
         Sleep( 100 );
      }
      PostMessageW( f.hDlg, WM_COMMAND, MAKEWPARAM( IDOK, BN_CLICKED ), ( LPARAM ) td_ctl( f.hDlg, IDOK ) );
      for( i = 0; i < 60 && IsWindow( f.hDlg ); i++ )   /* not accepted: cancel, never hang */
         Sleep( 50 );
      if( IsWindow( f.hDlg ) )
         PostMessageW( f.hDlg, WM_COMMAND, MAKEWPARAM( IDCANCEL, BN_CLICKED ), ( LPARAM ) td_ctl( f.hDlg, IDCANCEL ) );
   }
   else
      PostMessageW( f.hDlg, WM_COMMAND, MAKEWPARAM( IDCANCEL, BN_CLICKED ), ( LPARAM ) td_ctl( f.hDlg, IDCANCEL ) );
   return 0;
}

/* TEST_ANSWER( cText | NIL, nAction ): answer the next dialog this process opens */
HB_FUNC( TEST_ANSWER )
{
   HANDLE h;
   s_lSetText = HB_ISCHAR( 1 );
   s_cText[ 0 ] = 0;
   if( s_lSetText )
      MultiByteToWideChar( CP_UTF8, 0, hb_parc( 1 ), -1, s_cText, 1024 );
   s_nAction = hb_parni( 2 );
   s_cTitle[ 0 ] = 0;
   InterlockedExchange( &s_lSeen, 0 );
   h = CreateThread( NULL, 0, td_thread, NULL, 0, NULL );
   if( h )
      CloseHandle( h );
}

HB_FUNC( TEST_SEEN )
{
   hb_retl( s_lSeen != 0 );
}

HB_FUNC( TEST_LASTTITLE )
{
   hb_retc( s_cTitle );
}

#pragma ENDDUMP
