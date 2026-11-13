/*
 * Harbour 3.2.1dev (r2610242111)
 * MinGW GNU C 16.2 (64-bit)
 * Generated C source from "code2.prg"
 */

#include "hbvmpub.h"
#include "hbinit.h"


HB_FUNC( MAIN );


HB_INIT_SYMBOLS_BEGIN( hb_vm_SymbolInit_CODE2 )
{ "MAIN", {HB_FS_PUBLIC | HB_FS_LOCAL}, {HB_FUNCNAME( MAIN )}, NULL }
HB_INIT_SYMBOLS_EX_END( hb_vm_SymbolInit_CODE2, "code2.prg", 0x0, 0x0003 )

#if defined( HB_PRAGMA_STARTUP )
   #pragma startup hb_vm_SymbolInit_CODE2
#elif defined( HB_DATASEG_STARTUP )
   #define HB_DATASEG_BODY    HB_DATASEG_FUNC( hb_vm_SymbolInit_CODE2 )
   #include "hbiniseg.h"
#endif

HB_FUNC( MAIN )
{
	static const HB_BYTE pcode[] =
	{
		36,3,0,7
	};

	hb_vmExecute( pcode, symbols );
}

