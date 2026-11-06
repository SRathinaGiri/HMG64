@echo off

SET HMGPATH=%~dp0%
SET HMGPATH1=%HMGPATH:~0,-12%

SET PATH=c:\harbour64\bin;c:\mingw64\bin;%PATH%

hbmk2 ini-64.hbp -i%hmgpath1%\include
pause