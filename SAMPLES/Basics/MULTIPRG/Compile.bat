@ECHO OFF
cd lib1
echo Building LIBTEST1
call buildlib.bat
PAUSE
echo.
cd..
cd lib2
echo Building LIBTEST2
call buildlib.bat
PAUSE
echo.
cd..
echo Building MultiPrg Demo
IF "%NoRun%"=="" CALL ..\..\..\build64.bat multiprg.hbp multiprg.hbc
IF NOT "%NoRun%"=="" CALL ..\..\..\build64.bat /n multiprg.hbp multiprg.hbc