@echo off

SET HMGPATH=%~dp0%
SET HMGPATH1=%HMGPATH:~0,-15%

SET PATH=%HMGPATH1%\harbour64\bin;%HMGPATH1%\mingw64\bin;%PATH%

rem hbmk2 sqlitebridge-64.hbp -i%hmgpath1%\include
hbmk2 mysqlbridge-64.hbp -i%hmgpath1%\include
hbmk2 sqlitebridge-64.hbp -i%hmgpath1%\include
hbmk2 pgsqlbridge-64.hbp -i%hmgpath1%\include
rem hbmk2 pgsqlbridge-64.hbp -i%hmgpath1%\include
pause