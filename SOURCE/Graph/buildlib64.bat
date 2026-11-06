@echo off

SET HMGPATH=%~dp0%
SET HMGPATH1=%HMGPATH:~0,-14%

SET PATH=%HMGPATH1%\harbour64\bin;%HMGPATH1%\mingw64\bin;%PATH%

hbmk2 graph-64.hbp -i%hmgpath1%\include
pause