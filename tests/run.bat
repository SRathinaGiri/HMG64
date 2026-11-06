@echo off
rem ============================================================================
rem  tests\run.bat - HMG smoke + regression tests (called by: hmgbuild test)
rem
rem  smoke-<sample> : every SAMPLES\Basics\*\*.hbp must compile and link
rem  leak           : tests\leak\leakprobe - AUDIT.md finding C1
rem  unit-<name>    : tests\unit\<name>.hbp, console build, exit code 0 = pass
rem
rem  Tests listed in tests\known-fail.txt are reported as XFAIL and do not fail
rem  the run; if one starts passing it is reported as XPASS.
rem  Exit code: number of unexpected results (0 = green).
rem ============================================================================
setlocal EnableExtensions EnableDelayedExpansion

set "TESTS=%~dp0"
for %%I in ("%TESTS%..") do set "HMGPATH=%%~fI"
set "PATH=%HMGPATH%\harbour64\bin;%HMGPATH%\mingw64\bin;%PATH%"
set "OUT=%TESTS%out"
if not exist "%OUT%" md "%OUT%"
set /a PASS=0, FAIL=0, XFAIL=0, XPASS=0

rem --- smoke: build every sample project, never run it (GUI) ------------------
for /d %%D in ("%HMGPATH%\SAMPLES\Basics\*") do (
   for %%P in ("%%D\*.hbp") do (
      pushd "%%D"
      if exist error.log del error.log
      call "%HMGPATH%\build64.bat" /n "%%~nxP" >nul 2>&1
      set "R=0"
      if exist error.log ( set "R=1" & copy /y error.log "%OUT%\smoke-%%~nxD.log" >nul )
      if not exist "%%~nP.exe" set "R=1"
      popd
      call :RESULT smoke-%%~nxD !R!
   )
)

rem --- leak: console build of the probe, then run it --------------------------
pushd "%TESTS%leak"
if exist error.log del error.log
if exist leakprobe.exe del leakprobe.exe
call "%HMGPATH%\build64.bat" /n /c leakprobe.hbp >nul 2>&1
set "R=1"
set "B=1"
if exist leakprobe.exe set "B=0"
call :RESULT leakprobe-build !B!
if exist leakprobe.exe (
   .\leakprobe.exe >"%OUT%\leak.log" 2>&1
   if not errorlevel 1 set "R=0"
   type "%OUT%\leak.log"
) else (
   if exist error.log copy /y error.log "%OUT%\leak-build.log" >nul
   echo leakprobe did not build - see tests\out\leak-build.log
)
popd
call :RESULT leak !R!

rem --- unit: every tests\unit\*.hbp is built as a console app and run ---------
rem     exit code 0 = pass; the program prints its own per-check details
for %%P in ("%TESTS%unit\*.hbp") do (
   pushd "%TESTS%unit"
   if exist error.log del error.log
   if exist "%%~nP.exe" del "%%~nP.exe"
   call "%HMGPATH%\build64.bat" /n /c "%%~nxP" >nul 2>&1
   set "R=1"
   if exist "%%~nP.exe" (
      ".\%%~nP.exe" >"%OUT%\unit-%%~nP.log" 2>&1
      if not errorlevel 1 set "R=0"
      type "%OUT%\unit-%%~nP.log"
   ) else (
      if exist error.log copy /y error.log "%OUT%\unit-%%~nP-build.log" >nul
      echo %%~nP did not build - see tests\out\unit-%%~nP-build.log
   )
   popd
   call :RESULT unit-%%~nP !R!
)

echo.
echo PASS=%PASS%  FAIL=%FAIL%  XFAIL=%XFAIL%  XPASS=%XPASS%
set /a BAD=FAIL+XPASS
exit /b %BAD%

rem ----------------------------------------------------------------------------
:RESULT
rem %1 = test name, %2 = 0 pass / 1 fail
set "KNOWN=0"
findstr /x /c:"%~1" "%TESTS%known-fail.txt" >nul 2>&1 && set "KNOWN=1"
if "%~2"=="0" (
   if "%KNOWN%"=="1" ( echo XPASS %~1  ^(remove it from known-fail.txt^) & set /a XPASS+=1 ) else ( echo PASS  %~1 & set /a PASS+=1 )
) else (
   if "%KNOWN%"=="1" ( echo XFAIL %~1 & set /a XFAIL+=1 ) else ( echo FAIL  %~1 & set /a FAIL+=1 )
)
exit /b 0
