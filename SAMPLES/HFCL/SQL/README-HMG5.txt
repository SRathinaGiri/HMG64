SQL samples in HMG5
===================

Build out of the box:

   HMGSQLite\          SQLite through HMG's own bridge (libs hmgsqlite-64, hbsqlit3, sqlite3)
   SQLITE\             SQLite with Harbour's hbsqlit3

Need a database client library that HMG5 does not bundle:

   MySQL\MYSQL_1 .. MYSQL_3   Harbour's MySQL classes (TMySQLServer: contrib hbmysql)
   RDD_SQL\mysql              Harbour's SQL RDD with the MySQL driver (contrib sddmy)
   POSTGRESQL_1\              Harbour's PostgreSQL classes (contrib hbpgsql)

   These link against the MySQL or PostgreSQL client (libmysql.dll / libmariadb.dll,
   libpq.dll) and Harbour's contrib libraries built for them. To build these samples:

   1. Install the 64-bit client library of your database server (MySQL Connector/C or
      MariaDB Connector/C; PostgreSQL's libpq) and note its include and lib folders.
   2. Build the matching Harbour contrib (hbmysql, sddmy or hbpgsql) against it with
      HMG5's harbour64 and mingw64 (see TOOLCHAIN.md), and copy the .a files into
      harbour64\lib\win\mingw64.
   3. Add the library names to the sample's .hbp (for example: -lhbmysql -lmysqlclient)
      and put the client DLL next to the program.

   HMG 3.5 shipped 32-bit MySQL libraries; HMG5 is 64-bit only, so those cannot be used.
