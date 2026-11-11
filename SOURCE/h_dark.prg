/*----------------------------------------------------------------------------
 HMG5 - dark mode, PRG side (Phase 4 K). C side and what it covers: c_dark.c.

 Copyright 2026 HMG5 contributors

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version. As a special exception, linking the HMG library with other files to
 produce an executable does not by itself cause the executable to be covered
 by the GNU General Public License (see license.txt).
---------------------------------------------------------------------------*/

#include "hmg.ch"

/* HMG_SetDarkMode( xMode ) -> lActive
   SET DARKMODE ON / OFF / AUTO. .T. or "ON": dark; "AUTO": dark when Windows' app
   mode is dark (Settings > Personalisation > Colours); .F. or "OFF": light.
   Must run before the first DEFINE WINDOW (form classes and control themes are set
   when windows are created); later calls only return the current state. */
FUNCTION HMG_SetDarkMode( xMode )
   LOCAL lWant

   IF HB_ISSTRING( xMode )
      xMode := Upper( AllTrim( xMode ) )
      lWant := iif( xMode == "AUTO", HMG_DARK_SYSTEMISDARK(), xMode == "ON" )
   ELSEIF HB_ISLOGICAL( xMode )
      lWant := xMode
   ELSE
      RETURN HMG_DARK_ISON()
   ENDIF
   IF ! lWant .OR. HMG_DARK_ISON() .OR. _HMG_AnyFormDefined()
      RETURN HMG_DARK_ISON()
   ENDIF
RETURN HMG_DARK_ENABLE()

/* HMG_IsDarkMode() -> lOn */
FUNCTION HMG_IsDarkMode()
RETURN HMG_DARK_ISON()
