/*
 * HMG5 5.2 - long jobs without freezing the program: HMG_Busy()
 *
 *   xResult := HMG_Busy( cTitle, {| oBusy | MyJob( oBusy ) } [, lCancelButton] )
 *
 * A small modal window (a text line, a progress bar, Cancel) runs the job in the program's
 * own thread. The job reports with oBusy:Step( nDone, nTotal [, cText] ) or oBusy:Text( cText );
 * both repaint the window and let Windows handle its messages at most every 50 ms (so a
 * tight loop stays fast and Windows never marks the program "Not Responding"), and return
 * .F. once the user pressed Cancel, Esc or the window's X (oBusy:Cancelled tells the same).
 * Without nTotal the bar moves (marquee). HMG_Busy() returns what the job returns. The other
 * windows are disabled meanwhile, so clicks are not queued for later.
 */

#include "hmg.ch"
#include "hbclass.ch"

MEMVAR _HMG_SYSDATA

#define BUSY_PUMP_MS   50

STATIC s_nBusy := 0

FUNCTION HMG_Busy( cTitle, bJob, lCancelButton )
   LOCAL oBusy := HMG_BusyJob():New()
RETURN oBusy:Run( cTitle, bJob, lCancelButton )

CREATE CLASS HMG_BusyJob

   VAR cForm        INIT ""
   VAR lCancelled   INIT .F.
   VAR xResult      INIT NIL
   VAR nLastPump    INIT 0
   VAR nPercent     INIT -1
   VAR lMarquee     INIT .F.
   VAR cText        INIT ""
   VAR nSteps       INIT 0
   VAR nPumps       INIT 0
   VAR lDone        INIT .F.   // the job returned: the window may close

   METHOD New()
   METHOD Run( cTitle, bJob, lCancelButton )
   METHOD Step( nDone, nTotal, cText )
   METHOD Text( cText )
   METHOD Pump( lForce )
   METHOD Cancel()
   ACCESS Cancelled  INLINE ::lCancelled

ENDCLASS

METHOD New() CLASS HMG_BusyJob
RETURN Self

METHOD Run( cTitle, bJob, lCancelButton ) CLASS HMG_BusyJob
   LOCAL oSelf := Self, cForm, nHeight

   hb_default( @cTitle, "Please wait" )
   hb_default( @lCancelButton, .T. )
   IF ! HB_ISBLOCK( bJob )
      MsgHMGError( "HMG_Busy: a codeblock job is expected. Program Terminated" )
   ENDIF

   s_nBusy++
   cForm   := "_HMG_Busy_" + hb_ntos( s_nBusy )
   ::cForm := cForm
   nHeight := iif( lCancelButton, 150, 115 ) + GetTitleHeight() + GetBorderHeight()

   DEFINE WINDOW &cForm AT 0, 0 WIDTH 440 HEIGHT nHeight TITLE cTitle MODAL NOSIZE ;
      ON INIT _HMG_BusyDo( oSelf, bJob ) ;
      ON INTERACTIVECLOSE ( iif( oSelf:lDone, NIL, oSelf:Cancel() ), oSelf:lDone )   /* X: cancel; Release (also SC_CLOSE) once done */

      ON KEY ESCAPE ACTION oSelf:Cancel()

      @ 15, 15 LABEL Lbl_Text VALUE "" WIDTH 400 HEIGHT 22
      @ 45, 15 PROGRESSBAR Prg_Done RANGE 0, 100 WIDTH 400 HEIGHT 20
      IF lCancelButton
         @ 80, 315 BUTTON Btn_Cancel CAPTION "Cancel" WIDTH 100 HEIGHT 28 ACTION oSelf:Cancel()
      ENDIF
   END WINDOW

   DoMethod( cForm, "Center" )
   _ActivateWindow( { cForm } )
   s_nBusy--
RETURN ::xResult

/* nDone of nTotal done (nTotal NIL or 0: unknown, the bar moves); .F. once cancelled */
METHOD Step( nDone, nTotal, cText ) CLASS HMG_BusyJob
   LOCAL nPercent
   ::nSteps++
   IF HB_ISNUMERIC( nTotal ) .AND. nTotal > 0
      nPercent := Int( Max( 0, Min( hb_defaultValue( nDone, 0 ), nTotal ) ) * 100 / nTotal )
      IF ::lMarquee .AND. _IsWindowDefined( ::cForm )
         SETPROGRESSBARMARQUEE( GetControlHandle( "Prg_Done", ::cForm ), .F., 0 )
         ::lMarquee := .F.
      ENDIF
      IF nPercent != ::nPercent .AND. _IsWindowDefined( ::cForm )
         SetProperty( ::cForm, "Prg_Done", "Value", nPercent )
         ::nPercent := nPercent
      ENDIF
   ELSEIF ! ::lMarquee .AND. _IsWindowDefined( ::cForm )
      SETPROGRESSBARMARQUEE( GetControlHandle( "Prg_Done", ::cForm ), .T., 30 )
      ::lMarquee := .T.
   ENDIF
   IF HB_ISSTRING( cText )
      ::Text( cText )
   ELSE
      ::Pump()
   ENDIF
RETURN ! ::lCancelled

/* the text line; .F. once cancelled */
METHOD Text( cText ) CLASS HMG_BusyJob
   IF HB_ISSTRING( cText ) .AND. ! cText == ::cText .AND. _IsWindowDefined( ::cForm )
      SetProperty( ::cForm, "Lbl_Text", "Value", cText )
      ::cText := cText
   ENDIF
   ::Pump()
RETURN ! ::lCancelled

/* lets Windows handle the messages (paint, Cancel, Esc), at most every BUSY_PUMP_MS */
METHOD Pump( lForce ) CLASS HMG_BusyJob
   LOCAL nNow := hb_MilliSeconds()
   IF hb_defaultValue( lForce, .F. ) .OR. nNow - ::nLastPump >= BUSY_PUMP_MS
      ::nLastPump := nNow
      ::nPumps++
      DO EVENTS
   ENDIF
RETURN ! ::lCancelled

METHOD Cancel() CLASS HMG_BusyJob
   ::lCancelled := .T.
   IF _IsWindowDefined( ::cForm )
      SetProperty( ::cForm, "Lbl_Text", "Value", "Cancelling..." )
      ::cText := "Cancelling..."
   ENDIF
RETURN NIL

/* ON INIT of the busy window: the window is shown; run the job, then close the window
   (its quit message ends the window's own message loop as soon as it starts) */
PROCEDURE _HMG_BusyDo( oBusy, bJob )
   oBusy:Pump( .T. )
   oBusy:xResult := Eval( bJob, oBusy )
   oBusy:lDone   := .T.
   IF _IsWindowDefined( oBusy:cForm )
      DoMethod( oBusy:cForm, "Release" )
   ENDIF
RETURN
