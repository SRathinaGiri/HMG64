/*
 * c_scan.c - fast lookups over the _HMG_SYSDATA control arrays (HMG5, Phase 3 S4)
 *
 * Events() used to find a control whose handle is an array (RADIOGROUP options,
 * SPINNER edit+updown) with a PRG loop over every control. Measured on a form with
 * 312 controls: 105-190 us per message, and 360-470 us at 1,012 controls, paid on every
 * repaint of each radio option (WM_CTLCOLORSTATIC) and on every WM_COMMAND/WM_CTLCOLOREDIT
 * from a child window that is not itself a control. The same walk in C costs ~1 us.
 * The callers keep their original checks (type, parent), so behaviour is unchanged.
 *
 * Released under the HMG licence, as the rest of HMG.
 */

#include "hbapi.h"
#include "hbapiitm.h"


// Same result as the PRG "==" for two numbers (handles are stored as numbers).
static HB_BOOL hmg_NumEqual( PHB_ITEM pA, PHB_ITEM pB )
{
   if( HB_IS_NUMINT( pA ) && HB_IS_NUMINT( pB ) )
      return hb_itemGetNInt( pA ) == hb_itemGetNInt( pB );
   return hb_itemGetND( pA ) == hb_itemGetND( pB );
}


//        HMG_ScanSubArray( aOuter, nValue, [ nStart ], [ @nInner ], [ nPos ] ) --> nOuter
//  Next index >= nStart (default 1) whose element is an array holding nValue, or 0.
//  nPos > 0: compare only element nPos of each sub-array; otherwise any element.
//  nInner receives the position inside the sub-array. Non-numeric elements never
//  match (the PRG loops only ever compared numeric handles).
HB_FUNC( HMG_SCANSUBARRAY )
{
   PHB_ITEM pOuter = hb_param( 1, HB_IT_ARRAY );
   PHB_ITEM pValue = hb_param( 2, HB_IT_NUMERIC );
   HB_SIZE  nStart = HB_ISNUM( 3 ) && hb_parns( 3 ) > 0 ? ( HB_SIZE ) hb_parns( 3 ) : 1;
   HB_SIZE  nPos   = HB_ISNUM( 5 ) && hb_parns( 5 ) > 0 ? ( HB_SIZE ) hb_parns( 5 ) : 0;
   HB_SIZE  nLen, i, x, nSub;

   if( pOuter && pValue )
   {
      nLen = hb_arrayLen( pOuter );
      for( i = nStart; i <= nLen; i++ )
      {
         PHB_ITEM pSub = hb_arrayGetItemPtr( pOuter, i );

         if( pSub == NULL || ! HB_IS_ARRAY( pSub ) )
            continue;

         nSub = hb_arrayLen( pSub );
         for( x = ( nPos ? nPos : 1 ); x <= ( nPos ? HB_MIN( nPos, nSub ) : nSub ); x++ )
         {
            PHB_ITEM pItem = hb_arrayGetItemPtr( pSub, x );

            if( pItem && HB_IS_NUMERIC( pItem ) && hmg_NumEqual( pItem, pValue ) )
            {
               hb_storns( ( HB_ISIZ ) x, 4 );
               hb_retns( ( HB_ISIZ ) i );
               return;
            }
         }
      }
   }

   hb_storns( 0, 4 );
   hb_retns( 0 );
}
