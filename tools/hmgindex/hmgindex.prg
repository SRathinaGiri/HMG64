/*
 * hmgindex - lists the forms and controls an HMG project defines in code and .fmg files,
 * and the references that point to nothing (a misspelt control name, a form that does
 * not exist). Same index as the IDE's "Forms and Controls" window (SOURCE\IDE_SourceCode\Source\prjindex.prg).
 *
 *    hmgindex <project.hbp | folder> [/problems]
 *
 * Exit code: 0 no errors, 1 errors found (misspelt controls), 2 usage.
 */

PROCEDURE Main( cTarget, cOpt )
   LOCAL h, aP, nErr := 0

   IF Empty( cTarget )
      OutStd( "usage: hmgindex <project.hbp | folder> [/problems]" + hb_eol() )
      ErrorLevel( 2 )
      RETURN
   ENDIF
   h := HMGIdx_Project( cTarget )
   OutStd( HMGIdx_Report( h, ! ( Lower( hb_defaultValue( cOpt, "" ) ) == "/problems" ) ) )
   FOR EACH aP IN h[ "problems" ]
      IF aP[ 3 ] == "E"
         nErr++
      ENDIF
   NEXT
   ErrorLevel( iif( nErr > 0, 1, 0 ) )
RETURN
