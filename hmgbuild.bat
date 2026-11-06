@echo off
rem ============================================================================
rem  hmgbuild.bat - single, non-interactive build entry point for HMG 64-bit
rem
rem    hmgbuild check            verify the toolchain is present and pinned
rem    hmgbuild lib [ansi]       build all HMG libraries into LIB-64 (default UNICODE;
rem                              "ansi" = ANSI-only library, as BuildLib64.bat /ansi)
rem    hmgbuild app <prg|hbp>    build an application (no run), via build64.bat
rem    hmgbuild test             run the smoke + regression tests in tests\
rem    hmgbuild all              check + lib + test (UNICODE)
rem    hmgbuild matrix           lib ansi + test, then lib unicode + test; ends UNICODE
rem
rem  The library mode is chosen when LIB-64 is built: INCLUDE\SET_COMPILE_HMG_UNICODE.ch
rem  is overwritten from _ANSI.ch or _UNICODE.ch and hmglib64.txt records the mode
rem  (same mechanism as BuildLib64.bat). After "lib ansi" both files show as modified
rem  in git; "lib" (UNICODE) restores them.
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

rem ---- Toolchain pins (as at 06-11-2026; keep in sync with TOOLCHAIN.md and
rem      tools\setup-toolchain.ps1) ---------------------------------------------
set "PIN_HB_REV=r2610242111"
set "PIN_GCC=16.2.0"
rem ----------------------------------------------------------------------------

if /I "%~1"=="check" goto CHECK
if /I "%~1"=="lib"   goto LIB
if /I "%~1"=="app"   goto APP
if /I "%~1"=="test"  goto TEST
if /I "%~1"=="all"   goto ALL
if /I "%~1"=="matrix" goto MATRIX
echo Usage: hmgbuild check ^| lib [ansi] ^| app ^<file.prg^|file.hbp^> ^| test ^| all ^| matrix
exit /b 2

rem ----------------------------------------------------------------------------
:ALL
call :DO_CHECK || exit /b 1
call :DO_LIB UNICODE || exit /b 1
call "%HMGPATH%\tests\run.bat"
exit /b %ERRORLEVEL%

:MATRIX
rem UNICODE runs last so the tree ends in its tracked (UNICODE) state.
call :DO_CHECK || exit /b 1
set "MRC=0"
echo ===== ANSI =====
call :DO_LIB ANSI || exit /b 1
call "%HMGPATH%\tests\run.bat" || set "MRC=1"
echo ===== UNICODE =====
call :DO_LIB UNICODE || exit /b 1
call "%HMGPATH%\tests\run.bat" || set "MRC=1"
if "%MRC%"=="0" ( echo MATRIX: both modes green ) else ( echo MATRIX: FAILED - see output above )
exit /b %MRC%

:CHECK
call :DO_CHECK
exit /b %ERRORLEVEL%

:LIB
call :DO_CHECK || exit /b 1
set "MODE=UNICODE"
if /I "%~2"=="ansi" set "MODE=ANSI"
if not "%~2"=="" if /I not "%~2"=="ansi" if /I not "%~2"=="unicode" ( echo ERROR: unknown library mode "%~2" - use ansi or unicode & exit /b 2 )
call :DO_LIB %MODE%
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
echo %HBVER% | findstr /c:"%PIN_HB_REV%" >nul || echo WARNING: Harbour build differs from the pinned %PIN_HB_REV% - see TOOLCHAIN.md
if not "%GCCVER%"=="%PIN_GCC%" echo WARNING: GCC %GCCVER% differs from the pinned %PIN_GCC% - see TOOLCHAIN.md
exit /b 0

:NO_TOOLCHAIN
echo ERROR: toolchain not found under "%HMGPATH%".
echo        The mingw64\ and harbour64\ folders are not stored in git.
echo        Run:  powershell -ExecutionPolicy Bypass -File tools\setup-toolchain.ps1
echo        (see TOOLCHAIN.md)
exit /b 1

rem ----------------------------------------------------------------------------
:DO_LIB
rem %1 = ANSI or UNICODE.
rem Same steps as BuildLib64.bat /ansi|/unicode + BuildAllLib64.bat, but stops on
rem the first failure and returns hbmk2's exit code.
if not exist "%HMGPATH%\INCLUDE\_%~1.ch" ( echo ERROR: INCLUDE\_%~1.ch not found & exit /b 1 )
if not exist "%HMGPATH%\LIB-64" md "%HMGPATH%\LIB-64"
echo Library mode: %~1
copy /y "%HMGPATH%\INCLUDE\_%~1.ch" "%HMGPATH%\INCLUDE\SET_COMPILE_HMG_UNICODE.ch" >nul || exit /b 1
rem Byte-identical to what BuildLib64.bat writes (the IDE reads this file).
echo.%~1 > "%HMGPATH%\hmglib64.txt"

pushd "%HMGPATH%"
echo Building hmg-64 ...
hbmk2 hmg64.hbp -q > "%HMGPATH%\build.log" 2>&1
if errorlevel 1 ( type "%HMGPATH%\build.log" & echo FAILED: hmg-64 & popd & exit /b 1 )
popd

for %%L in (crypt edit editex graph hbvpdf ini report) do (
   call :BUILD_SUBLIB "%HMGPATH%\SOURCE\%%L" %%L-64.hbp "-i%HMGPATH%\INCLUDE" || exit /b 1
)
call :BUILD_SUBLIB "%HMGPATH%\hfcl\Source" hfcl-64.hbp "-i%HMGPATH%\INCLUDE" "-i%HMGPATH%\hfcl\Include" || exit /b 1
rem HMGSQL bridges (libhmgsqlite-64 etc.). HMG 3.6 shipped them prebuilt in LIB-64 via
rem SOURCE\HMGSQL\buildlib64.bat; user projects link them from their own .hbc.
for %%L in (sqlitebridge mysqlbridge pgsqlbridge) do (
   call :BUILD_SUBLIB "%HMGPATH%\SOURCE\HMGSQL" %%L-64.hbp "-i%HMGPATH%\INCLUDE" || exit /b 1
)
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
