HMG 5.0 - xBase Development System for Windows, 64-bit
============================================================

HMG 5 continues the HMG 3 line (HMG 3.6). Your HMG 3 programs should compile
unchanged: same commands, same build64.bat, same IDE. HMG4 (Qt) is not continued.

Everything you need is in this one folder. Nothing else to install:

   IDE\IDE.exe      the HMG IDE (forms designer + project manager)
   build64.bat      build a program:   build64 myprog.prg   or   build64 myprog.hbp
   mingw64\         C compiler (MinGW-w64 GCC 16.2.0, UCRT) - used by build64, you never call it
   harbour64\       Harbour 3.2.1dev (r2610242111)
   SAMPLES\         examples
   doc\             HMG reference


Compile your old program
------------------------
Open a Command Prompt in your program's folder and type:

   C:\HMG5\build64 myprog.prg          (builds and runs)
   C:\HMG5\build64 /n myprog.hbp       (builds, does not run)

If the build fails, the messages are in error.log in your program's folder.
Or open your .hbp project in IDE\IDE.exe and press Build.


UNICODE or ANSI
---------------
The libraries in LIB-64 are built in UNICODE mode (the default since HMG 3.2).
If your programs need the ANSI-only library, rebuild it once (about 2 minutes):

   C:\HMG5\hmgbuild lib ansi           (ANSI-only)
   C:\HMG5\hmgbuild lib                (back to UNICODE)


What changed compared with HMG 3.6
----------------------------------
 - Newer compilers: GCC 16.2.0 (was 13.1.0), Harbour 3.2.1dev (was 3.2.0dev 2023).
 - Fixed a memory leak in every string passed to Windows (long-running programs grew
   without limit), several buffer overflows (file dialogs, fonts, tray tips, tree
   items), crashes on NIL arguments in HMG_ISALPHA() etc., and DLLs being loaded
   from the program's folder before System32.
 - The XOR "crypt" functions are marked deprecated: they are not encryption.
 - Programs need Windows 10 or later (they use the Universal C Runtime that is part
   of Windows). Windows 7/8 are no longer supported.
 - New controls: WEBVIEW (Microsoft Edge WebView2: HTML/JavaScript screens) and CHART
   (Apache ECharts); GraphPlus charts drawn by ECharts.
 - Opt-in, off unless your program asks: SET DPIAWARE PERMONITOR (sharp on every
   monitor), SET DARKMODE ON|AUTO, SET FILEDIALOG MODERN, SET PDFENGINE WINDOWS.
 - Faster GetProperty/SetProperty/DoMethod and event handling; an optional object API
   (HMG_GetControl / HMG_GetForm) and SET HMG LEGACY VARS OFF.
 - The IDE: built-in code editor (colouring, completion of keywords, forms, controls
   and properties, font and indent settings), View > Forms and Controls (every form
   and control of a project, misspelt names found before the build), a project
   builder mode for code-only programs (File > Code Only New Project), English texts.
 - New samples in SAMPLES\Controls: ChartGallery (every Apache ECharts chart type, one
   tab each) and WebBrowser (a small browser with the HMG Forum among its favourites).
 - Full list: changelog.txt.


Licence
-------
HMG: GNU GPL v2 or later with a linking exception - programs you build with HMG are
yours and are not covered by the GPL (see license.txt). Harbour: GPL with exception
(harbour64\LICENSE.txt). MinGW-w64 / GCC: GPL with the GCC Runtime Library Exception.

Project: https://github.com/SRathinaGiri/HMG64
