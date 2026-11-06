/*
 * Regression test for AUDIT.md finding C1: HMG_parc()/HMG_retc() in
 * INCLUDE/HMG_UNICODE.h leak the converted string on every call.
 *
 * Calls string wrappers N times with a 50 KB argument and measures the growth
 * of process private bytes. Exit code 0 = no leak, 1 = leak detected.
 * Expected to FAIL until Phase 1 fixes the macro layer (listed in tests\known-fail.txt).
 */

#define N_CALLS        2000
#define ARG_LEN        50000
#define LIMIT_MB       10      // ~2000 * 50 KB * 2 bytes = ~190 MB when leaking

PROCEDURE Main()
   LOCAL cArg := Replicate( "a", ARG_LEN )
   LOCAL aCases := { ;
      { "HMG_ISALPHA", {|| HMG_ISALPHA( cArg ) } }, ;
      { "HMG_UPPER",   {|| HMG_UPPER( cArg ) } }, ;
      { "HMG_LOWER",   {|| HMG_LOWER( cArg ) } } }
   LOCAL aCase, i, nBefore, nMB, lLeak := .F.

   FOR EACH aCase IN aCases
      Eval( aCase[ 2 ] )                 // warm-up: first-call allocations are not leaks
      nBefore := PrivBytes()
      FOR i := 1 TO N_CALLS
         Eval( aCase[ 2 ] )
      NEXT
      nMB := ( PrivBytes() - nBefore ) / 1048576
      OutStd( PadR( aCase[ 1 ], 14 ) + "+" + Str( nMB, 8, 1 ) + " MB" + ;
              iif( nMB > LIMIT_MB, "  LEAK", "  ok" ) + hb_eol() )
      lLeak := lLeak .OR. nMB > LIMIT_MB
   NEXT

   ErrorLevel( iif( lLeak, 1, 0 ) )
RETURN

#pragma BEGINDUMP
#include <windows.h>
#include <psapi.h>
#include "hbapi.h"

HB_FUNC( PRIVBYTES )
{
   PROCESS_MEMORY_COUNTERS_EX pmc;
   GetProcessMemoryInfo( GetCurrentProcess(), ( PROCESS_MEMORY_COUNTERS * ) &pmc, sizeof( pmc ) );
   hb_retnint( ( HB_MAXINT ) pmc.PrivateUsage );
}
#pragma ENDDUMP
