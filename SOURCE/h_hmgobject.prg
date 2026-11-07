/*
 * HMG5 control and form objects (PHASE3-DESIGN.md, step S3)
 *
 * Copyright 2026 HMG5 contributors.
 * Licence: as HMG (GNU GPL v2 or later, with the HMG linking exception; see the
 * HMG licence text).
 *
 *    oCtl  := HMG_GetControl( "Form_1", "Text_1" )   // NIL if no such control
 *    oForm := HMG_GetForm( "Form_1" )                // NIL if no such window
 *
 *    ? oCtl:Value               ->  GetProperty( "Form_1", "Text_1", "Value" )
 *    oCtl:Value := "abc"        ->  SetProperty( "Form_1", "Text_1", "Value", "abc" )
 *    ? oCtl:Item( 3 )           ->  GetProperty( "Form_1", "Grid_1", "Item", 3 )
 *    oCtl:Set( "Item", 3, a )   ->  SetProperty( "Form_1", "Grid_1", "Item", 3, a )
 *    oCtl:SetFocus()            ->  DoMethod( "Form_1", "Text_1", "SetFocus" )
 *    oCtl:Do( "AddItem", x )    ->  DoMethod( "Form_1", "Combo_1", "AddItem", x )
 *
 * The objects are thin: they hold the form and control names plus the identity of
 * the control they were created for, never a copy of its data. Every property and
 * method goes through GetProperty / SetProperty / DoMethod with the same number of
 * arguments as the command syntax, so behaviour is exactly that of
 * Form_1.Text_1.Value. Programs that do not use these objects are unaffected.
 *
 * Why identity matters: HMG reuses the slot of a released control for the next one.
 * An object whose control was released must not silently act on whatever control
 * now sits in that slot, so every call first checks the slot still holds the same
 * control (not deleted, same name, same parent window, same handle) and raises a
 * clear runtime error otherwise.
 */

#include "hmg.ch"
#include "hbclass.ch"
#include "error.ch"

MEMVAR _HMG_SYSDATA

#define HMG_OBJ_SUBCODE   5501   // runtime error subcode for these classes

*------------------------------------------------------------------------------*
FUNCTION HMG_GetControl( cForm, cControl )
*------------------------------------------------------------------------------*
LOCAL i
   IF ! HB_ISSTRING( cForm ) .OR. ! HB_ISSTRING( cControl ) .OR. ! _IsControlDefined( cControl, cForm )
      RETURN NIL
   ENDIF
   i := GetControlIndex( cControl, cForm )
RETURN HMG_Control():New( GetFormName( cForm ), _HMG_SYSDATA[ HMG_CTL_NAME ][ i ], i )

*------------------------------------------------------------------------------*
FUNCTION HMG_GetForm( cForm )
*------------------------------------------------------------------------------*
   IF ! HB_ISSTRING( cForm ) .OR. ! _IsWindowDefined( cForm )
      RETURN NIL
   ENDIF
RETURN HMG_Form():New( GetFormName( cForm ), GetFormIndex( cForm ) )

*------------------------------------------------------------------------------*
CREATE CLASS HMG_Control
*------------------------------------------------------------------------------*
   PROTECTED:
      VAR cForm
      VAR cCtl
      VAR nIdx
      VAR xHandle
      VAR nParent

   EXPORTED:
      METHOD New( cForm, cCtl, nIdx )

      METHOD IsValid()
      METHOD Name()          INLINE ::cCtl
      METHOD FormName()      INLINE ::cForm
      METHOD Form()          INLINE HMG_GetForm( ::cForm )
      METHOD Index()         INLINE ( ::Check( "Index" ), ::nIdx )
      METHOD Type()          INLINE ( ::Check( "Type" ), _HMG_SYSDATA[ HMG_CTL_TYPE ][ ::nIdx ] )
      METHOD Handle()        INLINE ( ::Check( "Handle" ), _HMG_SYSDATA[ HMG_CTL_HANDLE ][ ::nIdx ] )
      METHOD ParentHandle()  INLINE ( ::Check( "ParentHandle" ), ::nParent )

      METHOD Get( cProperty, ... )
      METHOD Set( cProperty, ... )
      METHOD Do( cMethod, ... )

      METHOD SetFocus()      INLINE ::Do( "SetFocus" )
      METHOD Show()          INLINE ::Do( "Show" )
      METHOD Hide()          INLINE ::Do( "Hide" )
      METHOD Refresh()       INLINE ::Do( "Refresh" )
      METHOD Release()       INLINE ::Do( "Release" )

      ERROR HANDLER OnError( ... )

   PROTECTED:
      METHOD Check( cOperation )
ENDCLASS

METHOD New( cForm, cCtl, nIdx ) CLASS HMG_Control
   ::cForm   := cForm
   ::cCtl    := cCtl
   ::nIdx    := nIdx
   ::xHandle := _HMG_SYSDATA[ HMG_CTL_HANDLE ][ nIdx ]
   ::nParent := _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ nIdx ]
RETURN Self

// .T. while the slot still holds the control this object was made for. Runs before every
// call, so cheapest and most selective checks first; types are compared before `==`
// (mixed types raise an error), and `==` on an array handle (radio group, spinner)
// compares the array reference. The name is compared exactly: the slot keeps the very
// string it was created with, and ::cCtl was taken from it.
METHOD IsValid() CLASS HMG_Control
   LOCAL i := ::nIdx, x
   IF i > Len( _HMG_SYSDATA[ HMG_CTL_DELETED ] ) .OR. _HMG_SYSDATA[ HMG_CTL_DELETED ][ i ] != .F.
      RETURN .F.
   ENDIF
   x := _HMG_SYSDATA[ HMG_CTL_HANDLE ][ i ]
   IF ValType( x ) != ValType( ::xHandle ) .OR. ! ( x == ::xHandle )
      RETURN .F.
   ENDIF
   x := _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ i ]
   IF ValType( x ) != ValType( ::nParent ) .OR. ! ( x == ::nParent )
      RETURN .F.
   ENDIF
   x := _HMG_SYSDATA[ HMG_CTL_NAME ][ i ]
RETURN HB_ISSTRING( x ) .AND. x == ::cCtl

METHOD Check( cOperation ) CLASS HMG_Control
   IF ! ::IsValid()
      _HMG_ObjError( cOperation, "Control " + ::cForm + "." + ::cCtl + " no longer exists (it was released)" )
   ENDIF
RETURN NIL

METHOD Get( cProperty, ... ) CLASS HMG_Control
   ::Check( cProperty )
RETURN GetProperty( ::cForm, ::cCtl, cProperty, ... )

METHOD Set( cProperty, ... ) CLASS HMG_Control
   ::Check( cProperty )
   SetProperty( ::cForm, ::cCtl, cProperty, ... )
RETURN Self

METHOD Do( cMethod, ... ) CLASS HMG_Control
   ::Check( cMethod )
   DoMethod( ::cForm, ::cCtl, cMethod, ... )
RETURN Self

// Any other message is a property: oCtl:Value, oCtl:Value := x, oCtl:Item( n ).
METHOD OnError( ... ) CLASS HMG_Control
   LOCAL cMsg := __GetMessage()
   IF Left( cMsg, 1 ) == "_"
      ::Check( SubStr( cMsg, 2 ) )
      hb_ExecFromArray( @SetProperty(), _HMG_ObjArgs( { ::cForm, ::cCtl, SubStr( cMsg, 2 ) }, hb_AParams() ) )
      RETURN hb_PValue( 1 )
   ENDIF
   ::Check( cMsg )
RETURN hb_ExecFromArray( @GetProperty(), _HMG_ObjArgs( { ::cForm, ::cCtl, cMsg }, hb_AParams() ) )

*------------------------------------------------------------------------------*
CREATE CLASS HMG_Form
*------------------------------------------------------------------------------*
   PROTECTED:
      VAR cForm
      VAR nIdx
      VAR nHandle

   EXPORTED:
      METHOD New( cForm, nIdx )

      METHOD IsValid()
      METHOD Name()          INLINE ::cForm
      METHOD Index()         INLINE ( ::Check( "Index" ), ::nIdx )
      METHOD Handle()        INLINE ( ::Check( "Handle" ), ::nHandle )
      METHOD Type()          INLINE ( ::Check( "Type" ), _HMG_SYSDATA[ HMG_FRM_TYPE ][ ::nIdx ] )

      METHOD Control( cControl )
      METHOD Controls()

      METHOD Get( cProperty, ... )
      METHOD Set( cProperty, ... )
      METHOD Do( cMethod, ... )

      METHOD Show()          INLINE ::Do( "Show" )
      METHOD Hide()          INLINE ::Do( "Hide" )
      METHOD SetFocus()      INLINE ::Do( "SetFocus" )
      METHOD Release()       INLINE ::Do( "Release" )

      ERROR HANDLER OnError( ... )

   PROTECTED:
      METHOD Check( cOperation )
ENDCLASS

METHOD New( cForm, nIdx ) CLASS HMG_Form
   ::cForm   := cForm
   ::nIdx    := nIdx
   ::nHandle := _HMG_SYSDATA[ HMG_FRM_HANDLE ][ nIdx ]
RETURN Self

METHOD IsValid() CLASS HMG_Form
   LOCAL i := ::nIdx
   IF i > Len( _HMG_SYSDATA[ HMG_FRM_DELETED ] ) .OR. _HMG_SYSDATA[ HMG_FRM_DELETED ][ i ] != .F.
      RETURN .F.
   ENDIF
   IF ! HB_ISSTRING( _HMG_SYSDATA[ HMG_FRM_NAME ][ i ] ) .OR. ! ( _HMG_SYSDATA[ HMG_FRM_NAME ][ i ] == ::cForm )   // exact: ::cForm came from the slot
      RETURN .F.
   ENDIF
RETURN HB_ISNUMERIC( _HMG_SYSDATA[ HMG_FRM_HANDLE ][ i ] ) .AND. _HMG_SYSDATA[ HMG_FRM_HANDLE ][ i ] == ::nHandle

METHOD Check( cOperation ) CLASS HMG_Form
   IF ! ::IsValid()
      _HMG_ObjError( cOperation, "Window " + ::cForm + " no longer exists (it was released)" )
   ENDIF
RETURN NIL

METHOD Control( cControl ) CLASS HMG_Form
   ::Check( "Control" )
RETURN HMG_GetControl( ::cForm, cControl )

// Live controls whose parent is this window, in slot order (a control defined after a
// release may take the released one's slot, so this is not always definition order).
METHOD Controls() CLASS HMG_Form
   LOCAL aCtl := {}, i
   ::Check( "Controls" )
   FOR i := 1 TO Len( _HMG_SYSDATA[ HMG_CTL_NAME ] )
      IF _HMG_SYSDATA[ HMG_CTL_DELETED ][ i ] == .F. .AND. ;
         HB_ISNUMERIC( _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ i ] ) .AND. ;
         _HMG_SYSDATA[ HMG_CTL_PARENTHANDLE ][ i ] == ::nHandle .AND. ;
         HB_ISSTRING( _HMG_SYSDATA[ HMG_CTL_NAME ][ i ] ) .AND. ! Empty( _HMG_SYSDATA[ HMG_CTL_NAME ][ i ] )
         AAdd( aCtl, HMG_Control():New( ::cForm, _HMG_SYSDATA[ HMG_CTL_NAME ][ i ], i ) )
      ENDIF
   NEXT
RETURN aCtl

METHOD Get( cProperty, ... ) CLASS HMG_Form
   ::Check( cProperty )
RETURN GetProperty( ::cForm, cProperty, ... )

METHOD Set( cProperty, ... ) CLASS HMG_Form
   ::Check( cProperty )
   SetProperty( ::cForm, cProperty, ... )
RETURN Self

METHOD Do( cMethod, ... ) CLASS HMG_Form
   ::Check( cMethod )
   DoMethod( ::cForm, cMethod, ... )
RETURN Self

METHOD OnError( ... ) CLASS HMG_Form
   LOCAL cMsg := __GetMessage()
   IF Left( cMsg, 1 ) == "_"
      ::Check( SubStr( cMsg, 2 ) )
      hb_ExecFromArray( @SetProperty(), _HMG_ObjArgs( { ::cForm, SubStr( cMsg, 2 ) }, hb_AParams() ) )
      RETURN hb_PValue( 1 )
   ENDIF
   ::Check( cMsg )
RETURN hb_ExecFromArray( @GetProperty(), _HMG_ObjArgs( { ::cForm, cMsg }, hb_AParams() ) )

*------------------------------------------------------------------------------*
STATIC FUNCTION _HMG_ObjError( cOperation, cDescription )
*------------------------------------------------------------------------------*
LOCAL oErr := ErrorNew()
   oErr:severity    := ES_ERROR
   oErr:genCode     := EG_ARG
   oErr:subSystem   := "HMG"
   oErr:subCode     := HMG_OBJ_SUBCODE
   oErr:operation   := cOperation
   oErr:description := cDescription
   oErr:canDefault  := .F.
   oErr:canRetry    := .F.
RETURN Eval( ErrorBlock(), oErr )

*------------------------------------------------------------------------------*
STATIC FUNCTION _HMG_ObjArgs( aHead, aTail )
*------------------------------------------------------------------------------*
   AEval( aTail, {| x | AAdd( aHead, x ) } )
RETURN aHead
