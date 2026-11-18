/*
 * Unit test for the IDE's project lines and Error List (HMG5 5.2, IDE ide_buildlog.prg).
 * Four small projects that fail to link are built for real with build64.bat, so the test
 * reads what this linker really says; a few logs are written here for the other cases.
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   LOCAL cDir, a, cLog, cHbp, cBuild

   ErrorBlock( {| e | OutStd( "buildlog: RUNTIME ERROR " + e:subsystem + "/" + hb_ntos( e:subCode ) + " " + ;
                              e:description + " in " + ProcName( 2 ) + "(" + hb_ntos( ProcLine( 2 ) ) + ")" + hb_eol() ), ;
                      ExitProcess( 2 ) } )

   // --- the .hbp lines -----------------------------------------------------------------------
   cHbp := "main.prg" + Chr( 13 ) + Chr( 10 ) + "-gc3" + Chr( 10 ) + "# a comment" + Chr( 13 ) + ;
           "util.prg" + Chr( 13 ) + Chr( 10 ) + "-lmylib" + Chr( 13 ) + Chr( 10 ) + "extra.c" + Chr( 13 ) + Chr( 10 ) + ;
           "Main.fmg" + Chr( 13 ) + Chr( 10 ) + Chr( 13 ) + Chr( 10 )
   Check( "lines with CR LF, LF and CR", Len( IDE_HbpLines( cHbp ) ) == 9 .AND. IDE_HbpLines( cHbp )[ 3 ] == "# a comment" )
   a := IDE_HbpOtherLines( cHbp )
   Check( "the other lines, in order (" + hb_ValToExp( a ) + ")", ;
          hb_ValToExp( a ) == hb_ValToExp( { "-gc3", "# a comment", "-lmylib", "extra.c", "Main.fmg" } ) )
   Check( "the build keeps options and files, not .fmg", ;
          IDE_HbpBuildText( cHbp ) == "main.prg" + EOL() + "-gc3" + EOL() + "# a comment" + EOL() + "util.prg" + EOL() + ;
                                      "-lmylib" + EOL() + "extra.c" + EOL() )
   Check( "an old project: only modules", IDE_HbpBuildText( "a.prg" + EOL() + "b.prg" + EOL() ) == "a.prg" + EOL() + "b.prg" + EOL() .AND. ;
          Empty( IDE_HbpOtherLines( "a.prg" + EOL() + "b.prg" + EOL() ) ) )

   // --- real link failures ---------------------------------------------------------------------
   cDir := hb_DirSepAdd( hb_DirTemp() ) + "hmg5_buildlog_" + hb_ntos( hb_RandomInt( 100000, 999999 ) ) + hb_ps()
   hb_DirBuild( cDir )
   cBuild := hb_PathNormalize( hb_DirBase() + "..\..\build64.bat" )
   IF ! hb_FileExists( cBuild )
      cBuild := hb_PathNormalize( hb_cwd() + "..\..\build64.bat" )
   ENDIF

   cLog := LinkLog( cDir, cBuild, "a", "FUNCTION Main()" + EOL() + "   NoSuchFunc()" + EOL() + "   OtherMissing( 1 )" + EOL() + "RETURN NIL" + EOL() )
   a := IDE_BuildLogItems( cLog, cDir )
   Check( "undefined function, its module (" + hb_ValToExp( a ) + ")", ;
          Has( a, "Linker: a.prg: function `NOSUCHFUNC' is called but not defined" ) .AND. Has( a, "Linker: a.prg: function `OTHERMISSING'" ) )
   Check( "no garbled or doubled lines", Len( a ) == 2 )
   Check( "the module where the Error List looks for it", ModuleOf( a[ 1 ] ) == "a.prg" .AND. FunOf( a[ 1 ] ) == "NOSUCHFUNC" )

   cLog := LinkLog( cDir, cBuild, "b", "FUNCTION Main()" + EOL() + "RETURN NIL" + EOL() + "FUNCTION GetActiveWindow()" + EOL() + "RETURN 0" + EOL() )
   a := IDE_BuildLogItems( cLog, cDir )
   Check( "defined twice: the module and the library (" + hb_ValToExp( a ) + ")", ;
          Len( a ) == 1 .AND. Has( a, "Linker: b.prg: function `GETACTIVEWINDOW' is defined twice - also in libhmg-64.a" ) )

   cLog := LinkLog( cDir, cBuild, "c", "FUNCTION Main()" + EOL() + "   CCALL()" + EOL() + "RETURN NIL" + EOL() + ;
                    "#pragma BEGINDUMP" + EOL() + '#include "hbapi.h"' + EOL() + "extern int NoSuchCFunction( int );" + EOL() + ;
                    "HB_FUNC( CCALL ) { hb_retni( NoSuchCFunction( 1 ) ); }" + EOL() + "#pragma ENDDUMP" + EOL() )
   a := IDE_BuildLogItems( cLog, cDir )
   Check( "a C function not found (" + hb_ValToExp( a ) + ")", Len( a ) == 1 .AND. Has( a, "Linker: c.prg: C function `NoSuchCFunction' not found" ) )

   cLog := LinkLog( cDir, cBuild, "d", "FUNCTION Main()" + EOL() + "RETURN NIL" + EOL(), "-lnosuchlib" )
   a := IDE_BuildLogItems( cLog, cDir )
   Check( "a library not found (was an empty list) (" + hb_ValToExp( a ) + ")", ;
          Len( a ) == 1 .AND. Has( a, "Linker: library `nosuchlib' not found (libnosuchlib.a)" ) )

   cLog := LinkLog( cDir, cBuild, "e", "FUNCTION Main()" + EOL() + "   x := ( 1 +" + EOL() + "RETURN NIL" + EOL() )
   a := IDE_BuildLogItems( cLog, cDir )
   Check( "Harbour errors as before (" + hb_ValToExp( a ) + ")", Len( a ) >= 1 .AND. Left( a[ 1 ], 15 ) == "Harbour: e.prg(" )
   hb_DirRemoveAll( cDir )

   // --- written logs -------------------------------------------------------------------------
   cLog := "x/ld.exe: C:/t/main.o:main.c:(.text+0x5): multiple definition of `HB_FUN_SUM'" + EOL() + ;
           "x/ld.exe: C:/t/util.o:util.c:(.text+0x9): first defined here" + EOL() + "collect2.exe: error: ld returned 1 exit status" + EOL()
   a := IDE_BuildLogItems( cLog, hb_DirTemp() )
   Check( "defined twice, the older two-line form (" + hb_ValToExp( a ) + ")", Len( a ) == 1 .AND. Has( a, "function `SUM' is defined twice - also in util.o" ) )

   cLog := "x/ld.exe: cannot open output file prog.exe: Permission denied" + EOL() + "collect2.exe: error: ld returned 1 exit status" + EOL()
   a := IDE_BuildLogItems( cLog )
   Check( "the program still running", Len( a ) == 1 .AND. Has( a, "Linker: cannot write prog.exe - is the program still running?" ) )

   cLog := "hbmk2: Error: Referenced, missing, but unknown function(s): FOO()," + EOL() + "       BAR()" + EOL()
   a := IDE_BuildLogItems( cLog )
   Check( "hbmk2's list alone (" + hb_ValToExp( a ) + ")", Len( a ) == 1 .AND. Has( a, "Linker: unknown function(s) FOO(), BAR()" ) )

   cLog := "C:/p/util.c:12:5: error: 'y' undeclared (first use in this function)" + EOL()
   a := IDE_BuildLogItems( cLog )
   Check( "C compiler errors (" + hb_ValToExp( a ) + ")", Len( a ) == 1 .AND. Has( a, "C compiler: util.c(12) 'y' undeclared" ) )

   cLog := "collect2.exe: error: ld returned 1 exit status" + EOL() + "hbmk2[p]: Error: Running linker. 1" + EOL()
   a := IDE_BuildLogItems( cLog )
   Check( "a link failure with nothing else said", Len( a ) == 1 .AND. Has( a, "Linker: the link step failed" ) )

   a := IDE_BuildLogItems( "Something unusual went wrong" + EOL() )
   Check( "never empty", Len( a ) == 1 .AND. Has( a, "Build: Something unusual went wrong" ) )

   OutStd( "buildlog: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ExitProcess( iif( s_nFail == 0, 0, 1 ) )
RETURN NIL

STATIC FUNCTION EOL()
RETURN Chr( 13 ) + Chr( 10 )

/* builds <cName>.prg (+ option line) in cDir with build64 /n and returns error.log */
STATIC FUNCTION LinkLog( cDir, cBuild, cName, cCode, cOption )
   LOCAL cOld := hb_cwd( cDir ), cLog
   hb_MemoWrit( cName + ".prg", '#include "hmg.ch"' + EOL() + cCode )
   hb_MemoWrit( cName + ".hbp", iif( Empty( cOption ), "", cOption + EOL() ) + cName + ".prg" + EOL() )
   FErase( "error.log" )
   hb_processRun( 'cmd /c ""' + cBuild + '" /n ' + cName + '.hbp"' )
   cLog := hb_MemoRead( "error.log" )
   hb_cwd( cOld )
RETURN cLog

STATIC FUNCTION Has( a, cPart )
RETURN AScan( a, {| x | cPart $ x } ) > 0

/* as the IDE's Error List reads a Linker line: the file between the first and last colon,
   the function between ` and ' */
STATIC FUNCTION ModuleOf( c )
RETURN AllTrim( SubStr( c, At( ":", c ) + 1, RAt( ":", c ) - At( ":", c ) - 1 ) )

STATIC FUNCTION FunOf( c )
RETURN SubStr( c, At( "`", c ) + 1, At( "'", c ) - At( "`", c ) - 1 )

STATIC PROCEDURE Check( cName, lOk )
   IF HB_ISLOGICAL( lOk ) .AND. lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "buildlog: FAIL " + cName + hb_eol() )
   ENDIF
RETURN
