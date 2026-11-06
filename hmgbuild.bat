@echo off
rem ============================================================================
rem  hmgbuild.bat - single, non-interactive build entry point for HMG 64-bit
rem
rem    hmgbuild check            verify the toolchain is present and pinned
rem    hmgbuild lib              build all HMG libraries into LIB-64 (UNICODE)
rem    hmgbuild app <prg|hbp>    build an application (no run), via build64.bat
rem    hmgbuild test             run the smoke + regression tests in tests\
rem    hmgbuild all              check + lib + test
rem
rem  Exit code: 0 = success, non-zero = failure (usable from CI).
rem  The legacy scripts (build64.bat, BuildLib64.bat, BuildAllLib64.bat) are kept
rem  unchanged because the IDE and the samples call them.
rem ============================================================================
setlocal EnableExtensions

set "HMGPATH=%~dp0"
if "%HMGPATH:~-1%"=="\" set "HMGPATH=%HMGPATH:~0,-1%"
set "PATH=%HMGPATH%\harbour64\bin;%HMGPATH%\mingw64\bin;%PATH%"
set "HB_COMPILER=mingw64"

if /I "%~1"=="check" goto CHECK
if /I "%~1"=="lib"   goto LIB
if /I "%~1"=="app"   goto APP
if /I "%~1"=="test"  goto TEST
if /I "%~1"=="all"   goto ALL
echo Usage: hmgbuild check ^| lib ^| app ^<file.prg^|file.hbp^> ^| test ^| all
exit /b 2

rem ----------------------------------------------------------------------------
:ALL
call :DO_CHECK || exit /b 1
call :DO_LIB   || exit /b 1
call "%HMGPATH%\tests\run.bat"
exit /b %ERRORLEVEL%

:CHECK
call :DO_CHECK
exit /b %ERRORLEVEL%

:LIB
call :DO_CHECK || exit /b 1
call :DO_LIB
exit /b %ERRORLEVEL%

:TEST
call :DO_CHECK || exit /b 1
call "%HMGPATH%\tests\run.bat"
exit /b %ERRORLEVEL%

:APP
if "%~2"=="" ( echo ERROR: hmgbuild app needs a .prg or .hbp file & exit /b 2 )
if not exist "%~2" ( echo ERROR: file not found: %~2 & exit /b 2 )
call :DO_CHECK || exit /b 1
pushd "%~dp2"
if exist error.log del error.log
call "%HMGPATH%\build64.bat" /n "%~nx2"
set "RC=0"
if exist error.log ( type error.log & set "RC=1" )
if not exist "%~n2.exe" set "RC=1"
if "%RC%"=="0" ( echo OK: %~dpn2.exe ) else ( echo FAILED: %~2 )
popd
exit /b %RC%

rem ----------------------------------------------------------------------------
:DO_CHECK
rem Fails with an actionable message if the bundled toolchain is missing.
rem Pinned versions are documented in TOOLCHAIN.md.
if not exist "%HMGPATH%\harbour64\bin\hbmk2.exe" goto NO_TOOLCHAIN
if not exist "%HMGPATH%\mingw64\bin\gcc.exe"     goto NO_TOOLCHAIN
for /f "delims=" %%v in ('harbour -build 2^>^&1 ^| findstr /b /c:"Version:"') do set "HBVER=%%v"
for /f "delims=" %%v in ('gcc -dumpfullversion') do set "GCCVER=%%v"
echo %HBVER%
echo GCC     %GCCVER%
echo %HBVER% | findstr /c:"r2304211101" >nul || echo WARNING: Harbour build differs from the pinned r2304211101 - see TOOLCHAIN.md
if not "%GCCVER%"=="13.1.0" echo WARNING: GCC %GCCVER% differs from the pinned 13.1.0 - see TOOLCHAIN.md
exit /b 0

:NO_TOOLCHAIN
echo ERROR: toolchain not found under "%HMGPATH%".
echo        The mingw64\ and harbour64\ folders are not stored in git.
echo        Copy them in from an HMG 3.6 64-bit install - see TOOLCHAIN.md.
exit /b 1

rem ----------------------------------------------------------------------------
:DO_LIB
rem Same steps as BuildLib64.bat /unicode + BuildAllLib64.bat, but stops on
rem the first failure and returns hbmk2's exit code.
if not exist "%HMGPATH%\LIB-64" md "%HMGPATH%\LIB-64"
copy /y "%HMGPATH%\INCLUDE\_UNICODE.ch" "%HMGPATH%\INCLUDE\SET_COMPILE_HMG_UNICODE.ch" >nul || exit /b 1

pushd "%HMGPATH%"
echo Building hmg-64 ...
hbmk2 hmg64.hbp -q > "%HMGPATH%\build.log" 2>&1
if errorlevel 1 ( type "%HMGPATH%\build.log" & echo FAILED: hmg-64 & popd & exit /b 1 )
popd

for %%L in (crypt edit editex graph hbvpdf ini report) do (
   call :BUILD_SUBLIB "%HMGPATH%\SOURCE\%%L" %%L-64.hbp "-i%HMGPATH%\INCLUDE" || exit /b 1
)
call :BUILD_SUBLIB "%HMGPATH%\hfcl\Source" hfcl-64.hbp "-i%HMGPATH%\INCLUDE" "-i%HMGPATH%\hfcl\Include" || exit /b 1
echo All libraries built into LIB-64.
exit /b 0

:BUILD_SUBLIB
rem %1 = folder, %2 = .hbp, %3.. = extra hbmk2 options
echo Building %~n2 ...
pushd "%~1"
hbmk2 %2 %~3 %~4 -q > "%HMGPATH%\build.log" 2>&1
if errorlevel 1 ( type "%HMGPATH%\build.log" & echo FAILED: %~n2 & popd & exit /b 1 )
popd
exit /b 0
