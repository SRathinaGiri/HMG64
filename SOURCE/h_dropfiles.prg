/*
 * HMG5 5.2 - files dropped from Explorer (c_dropfiles.c, WM_DROPFILES, no OLE).
 *
 *   ON DROPFILES [ OF <form> ] [ CONTROL <control> ] ACTION <action>
 *   RELEASE DROPFILES [ OF <form> ] [ CONTROL <control> ]
 *   This.DroppedFiles   -> the dropped paths (an array), inside the action
 *
 * Inside DEFINE WINDOW the form is the one being defined (as ON KEY does). A drop on a
 * control without its own ON DROPFILES goes to its window's, if the window has one.
 * HMG_DropFiles( cForm, cControl | NIL, bAction | NIL ) is the function form.
 */

#include "hmg.ch"

MEMVAR _HMG_SYSDATA

STATIC s_hDrop  := NIL   // handle -> { cForm, cControl | NIL, bAction }
STATIC s_aFiles := {}

FUNCTION HMG_DropFiles( cForm, cControl, bAction )
   LOCAL hWnd

   IF _HMG_SYSDATA[ 264 ] == .T. .AND. Empty( cForm )
      cForm := _HMG_SYSDATA[ 223 ]   // inside DEFINE WINDOW
   ENDIF
   IF ! HB_ISSTRING( cForm ) .OR. Empty( cForm )
      MsgHMGError( "ON DROPFILES: Window Not Specified. Program Terminated" )
   ENDIF
   IF ! _IsWindowDefined( cForm )
      MsgHMGError( "ON DROPFILES: Window " + cForm + " is not defined. Program Terminated" )
   ENDIF
   IF HB_ISSTRING( cControl ) .AND. ! Empty( cControl )
      IF ! _IsControlDefined( cControl, cForm )
         MsgHMGError( "ON DROPFILES: Control " + cControl + " Of " + cForm + " is not defined. Program Terminated" )
      ENDIF
      hWnd := GetControlHandle( cControl, cForm )
      IF HB_ISARRAY( hWnd )   // controls made of several windows: the first one
         hWnd := hWnd[ 1 ]
      ENDIF
   ELSE
      cControl := NIL
      hWnd     := GetFormHandle( cForm )
   ENDIF

   IF s_hDrop == NIL
      s_hDrop := { => }
   ENDIF
   IF HB_ISBLOCK( bAction )
      s_hDrop[ hWnd ] := { cForm, cControl, bAction }
      HMG_DROPFILESREGISTER( hWnd, .T. )
   ELSE
      HMG_DROPFILESREGISTER( hWnd, .F. )
      IF hb_HHasKey( s_hDrop, hWnd )
         hb_HDel( s_hDrop, hWnd )
      ENDIF
   ENDIF
RETURN NIL

/* the dropped paths, inside an ON DROPFILES action (This.DroppedFiles) */
FUNCTION _HMG_DroppedFiles()
RETURN AClone( s_aFiles )

/* from c_dropfiles.c: files were dropped on hWnd */
FUNCTION _HMG_DropFilesEvent( hWnd, aFiles )
   LOCAL aEntry, aSave, k

   IF s_hDrop == NIL .OR. ! hb_HHasKey( s_hDrop, hWnd )
      RETURN NIL
   ENDIF
   aEntry := s_hDrop[ hWnd ]
   IF ! _IsWindowDefined( aEntry[ 1 ] )
      RETURN NIL
   ENDIF
   aSave    := s_aFiles
   s_aFiles := aFiles
   IF aEntry[ 2 ] != NIL
      IF ( k := GetControlIndex( aEntry[ 2 ], aEntry[ 1 ] ) ) > 0
         _DoControlEventProcedure( aEntry[ 3 ], k )
      ENDIF
   ELSE
      _DoWindowEventProcedure( aEntry[ 3 ], GetFormIndex( aEntry[ 1 ] ), "WINDOW_DROPFILES" )
   ENDIF
   s_aFiles := aSave
RETURN NIL
