*-----------------------------------------------------------------------------*
PROCEDURE SaveString ( cFileName , cString, lUTF8 )
*-----------------------------------------------------------------------------*
 Local nOutfile := NIL
   lUTF8 := NIL
   
   HB_MEMOWRIT (cFileName, cString)

/*
	nOutfile := FCREATE( cFileName , FC_NORMAL)
   
   IF ValType(lUTF8) == "L" .AND. lUTF8 == .T.
      #define UTF8_BOM  ( HB_BCHAR (0xEF) + HB_BCHAR (0xBB) + HB_BCHAR (0xBF) )
      FWRITE(nOutfile, BOM_UTF8 , HB_BLEN (BOM_UTF8))
   ENDIF
   
//	FWRITE(nOutfile , cString , HMG_LEN ( cString ) )
 FWRITE(nOutfile , cString , HB_BLEN ( cString ) )

        FCLOSE(nOutfile)
*/
RETURN