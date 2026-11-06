/*
 * Regression test: the HMGSQL SQLite bridge (libhmgsqlite-64) is built into LIB-64
 * and works with the bundled SQLite. HMG 3.6 shipped this library prebuilt; HMG5's
 * first bundle missed it, so projects using CONNECT2DB()/SQL() failed to link.
 * Synthetic data only.
 */
#include "hmg.ch"

STATIC s_nPass := 0, s_nFail := 0

FUNCTION Main()
   LOCAL db, a

   db := connect2db( ":memory:", .T. )
   Check( "connect2db", ! Empty( db ) )

   Check( "create",  miscsql( db, "CREATE TABLE t (id INTEGER, name TEXT, d DATE, ok BOOL)" ) )
   Check( "insert",  miscsql( db, "INSERT INTO t VALUES (1, " + C2SQL( "O'Brien & Co" ) + ", " + C2SQL( 0d20260401 ) + ", 1)" ) )
   Check( "insert2", miscsql( db, "INSERT INTO t VALUES (2, " + C2SQL( "Test Two" ) + ", " + C2SQL( 0d20270331 ) + ", 0)" ) )

   a := sql( db, "SELECT id, name, d, ok FROM t ORDER BY id" )
   Check( "rows",          ValType( a ) == "A" .AND. Len( a ) == 2 )
   IF ValType( a ) == "A" .AND. Len( a ) == 2
      Check( "integer -> N", a[ 1, 1 ] == 1 )
      Check( "quote escape", a[ 1, 2 ] == "O'Brien & Co" )
      Check( "date -> D",    a[ 1, 3 ] == 0d20260401 )
      Check( "bool -> L",    a[ 1, 4 ] == .T. .AND. a[ 2, 4 ] == .F. )
   ENDIF
   Check( "sqlite version", ! Empty( sqlite3_libversion() ) )

   OutStd( "hmgsqlite: SQLite " + sqlite3_libversion() + hb_eol() )
   OutStd( "hmgsqlite: PASS=" + hb_ntos( s_nPass ) + " FAIL=" + hb_ntos( s_nFail ) + hb_eol() )
   ErrorLevel( iif( s_nFail == 0, 0, 1 ) )
   RETURN NIL

STATIC PROCEDURE Check( cName, lOk )
   IF lOk
      s_nPass++
   ELSE
      s_nFail++
      OutStd( "FAIL " + cName + hb_eol() )
   ENDIF
   RETURN
