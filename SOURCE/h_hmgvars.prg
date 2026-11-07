/*
 * h_hmgvars.prg - where HMG keeps "form name -> index" and "form + control -> index"
 * (HMG5, Phase 3 S5)
 *
 * HMG 3 stores these as macro-named PUBLIC variables: _<Form> and _<Form>_<Control>
 * hold the slot index. Every lookup in the library goes through the four functions
 * below, so the store can be switched:
 *
 *    SET HMG LEGACY VARS ON    (default)  PUBLIC variables, exactly as HMG 3.x
 *    SET HMG LEGACY VARS OFF              a private hash; no PUBLIC per form/control
 *
 * Why OFF: a program with many forms and controls creates thousands of PUBLICs, and a
 * program PUBLIC or PRIVATE whose name happens to be _<Form>_<Control> collides with
 * HMG's. Not the default, because user code may read the variables directly
 * (Type( "_Form1_Text1" ), _Form1 ...), which only works with ON.
 * Speed is the same either way (memvar lookup 0.7 us vs hash 1.05 us, PHASE3-DESIGN 4.2).
 *
 * Released under the HMG licence, as the rest of HMG.
 */

#include "hmg.ch"
#include "error.ch"

MEMVAR _HMG_SYSDATA

STATIC s_lLegacy := .T.
STATIC s_hIndex  := NIL


*------------------------------------------------------------------------------*
FUNCTION HMG_LegacyVars ( lOn )
*------------------------------------------------------------------------------*
// Returns the current setting; changes it when lOn is logical. Only before the first
// DEFINE WINDOW: switching later would split the entries between the two stores.
LOCAL lOld := s_lLegacy

   IF HB_ISLOGICAL ( lOn ) .AND. lOn != s_lLegacy
      IF HMG_LEN ( _HMG_SYSDATA [ HMG_FRM_NAME ] ) > 0
         MsgHMGError ( "SET HMG LEGACY VARS must come before the first DEFINE WINDOW. Program terminated" )
      ENDIF
      s_lLegacy := lOn
   ENDIF

RETURN lOld


STATIC FUNCTION HashStore ()
   IF s_hIndex == NIL
      s_hIndex := { => }
      hb_HCaseMatch ( s_hIndex, .F. )   // memvar names are case-insensitive
   ENDIF
RETURN s_hIndex


*------------------------------------------------------------------------------*
FUNCTION _HMG_VarSet ( cVar, nIndex )
*------------------------------------------------------------------------------*
// Was: Public &mVar. := nIndex
   IF s_lLegacy
      PUBLIC &cVar.
      &cVar. := nIndex
   ELSE
      HashStore () [ cVar ] := nIndex
   ENDIF
RETURN nIndex


*------------------------------------------------------------------------------*
FUNCTION _HMG_VarGet ( cVar )
*------------------------------------------------------------------------------*
// Was: &mVar  (an unknown name raises the same error as the missing variable did)
LOCAL oErr

   IF s_lLegacy
      RETURN &cVar
   ENDIF

   IF hb_HHasKey ( HashStore (), cVar )
      RETURN s_hIndex [ cVar ]
   ENDIF

   oErr := ErrorNew ()
   oErr:severity    := ES_ERROR
   oErr:genCode     := EG_NOVAR
   oErr:subSystem   := "BASE"
   oErr:subCode     := 1003
   oErr:description := "Variable does not exist"
   oErr:operation   := Upper ( cVar )
   oErr:canDefault  := .T.

RETURN Eval ( ErrorBlock (), oErr )


*------------------------------------------------------------------------------*
FUNCTION _HMG_VarType ( cVar )
*------------------------------------------------------------------------------*
// Was: Type ( mVar )
   IF s_lLegacy
      RETURN Type ( cVar )
   ENDIF
RETURN IIF ( hb_HHasKey ( HashStore (), cVar ), ValType ( s_hIndex [ cVar ] ), "U" )


*------------------------------------------------------------------------------*
FUNCTION _HMG_VarPut ( cVar, nIndex )
*------------------------------------------------------------------------------*
// Was: __MVPUT ( mVar , nIndex )  (callers check _HMG_VarType first)
   IF s_lLegacy
      __mvPut ( cVar, nIndex )
   ELSE
      HashStore () [ cVar ] := nIndex
   ENDIF
RETURN nIndex
