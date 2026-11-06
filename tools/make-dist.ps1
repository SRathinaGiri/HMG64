<#
.SYNOPSIS
  Assembles the HMG5 out-of-the-box folder: HMG + a trimmed GCC + Harbour, ready to use.

.DESCRIPTION
  Copies this HMG tree, the GCC it is linked to (mingw64\) and Harbour (harbour64\) into
  one self-contained folder (default: HMG5 next to the HMG tree). Only what is needed to
  compile and link HMG programs is copied from GCC: no gdb, Python, Fortran, Objective-C,
  CMake, Doxygen, Cppcheck or the WinLibs package tools. All GCC DLLs are kept, so no
  compiler dependency can go missing.

  Then it verifies the result in place: toolchain check, every SAMPLES\Basics project,
  the leak test and the unit tests (hmgbuild test).

  The folder is the input for dist\HMG5.iss (the Setup.exe).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\make-dist.ps1 -Dest D:\HMG5
#>
[CmdletBinding()]
param(
   [string] $Dest   = '',
   [string] $HmgDir = '',
   # Skip the in-place build test of the new folder.
   [switch] $NoVerify
)

$ErrorActionPreference = 'Stop'

function Step ($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Fail ($msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

# Resolved after param(): Windows PowerShell 5.1 leaves $PSScriptRoot empty in param() defaults.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $HmgDir) { $HmgDir = Split-Path -Parent $ScriptDir }
$HmgDir = [IO.Path]::GetFullPath($HmgDir)
if (-not $Dest) { $Dest = Join-Path (Split-Path -Parent $HmgDir) 'HMG5' }
$Dest = [IO.Path]::GetFullPath($Dest)

# ---- Preconditions ------------------------------------------------------------------------
foreach ($p in 'hmgbuild.bat', 'build64.bat', 'mingw64\bin\gcc.exe', 'harbour64\bin\hbmk2.exe', 'LIB-64\libhmg-64.a') {
   if (-not (Test-Path (Join-Path $HmgDir $p))) { Fail "$p not found in $HmgDir. Run tools\setup-toolchain.ps1 and 'hmgbuild lib' first." }
}
$mode = (Get-Content (Join-Path $HmgDir 'hmglib64.txt') -Raw).Trim()
Write-Host "Library mode in LIB-64: $mode"
if (($Dest + '\').StartsWith($HmgDir.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
   Fail "Dest '$Dest' is inside the HMG tree '$HmgDir'. Choose a folder outside it, e.g. D:\HMG5."
}
if ((Test-Path $Dest) -and (Get-ChildItem -Force $Dest | Select-Object -First 1)) {
   Fail "'$Dest' already exists and is not empty. Rename or remove it, then re-run (this script never deletes it)."
}
# Real folders behind the junctions.
$GccSrc = (Get-Item (Join-Path $HmgDir 'mingw64')).FullName
$HbSrc  = (Get-Item (Join-Path $HmgDir 'harbour64')).FullName
foreach ($j in 'mingw64', 'harbour64') {
   $it = Get-Item (Join-Path $HmgDir $j) -Force
   if ($it.LinkType -eq 'Junction') { if ($j -eq 'mingw64') { $GccSrc = "$($it.Target)" } else { $HbSrc = "$($it.Target)" } }
}

function Copy-Tree ($from, $to, [string[]] $extra) {
   # robocopy: exit codes below 8 mean success. /XJ: never follow junctions.
   $rcArgs = @($from, $to, '/E', '/XJ', '/NFL', '/NDL', '/NJH', '/NJS', '/NP', '/R:1', '/W:1') + $extra
   & robocopy @rcArgs | Out-Null
   if ($LASTEXITCODE -ge 8) { Fail "Copying $from failed (robocopy exit $LASTEXITCODE)." }
}

# ---- 1. HMG itself ------------------------------------------------------------------------
Step "Copying HMG to $Dest"
Copy-Tree $HmgDir $Dest @(
   '/XD', '.git', 'mingw64', 'harbour64', 'tools', 'dist', '.hbmk',
   '/XF', '.gitattributes', '.gitignore', 'AUDIT.md', 'unins000.dat', 'unins000.exe', 'build.log', 'error.log', '*.o')
Copy-Item (Join-Path $HmgDir 'dist\HMG5-README.txt') (Join-Path $Dest 'README-HMG5.txt')

# ---- 2. GCC, trimmed ----------------------------------------------------------------------
Step "Copying GCC (trimmed) from $GccSrc"
$g = Join-Path $Dest 'mingw64'
# Everything except bin\ and share\ (docs, locale, gdb/CMake data), minus other languages and Python.
Copy-Tree $GccSrc $g @(
   '/XD', (Join-Path $GccSrc 'bin'), (Join-Path $GccSrc 'share'), 'python3.9', 'finclude',
   '/XF', 'f951.exe', 'cc1obj.exe', 'cc1objplus.exe', 'libpython3.9*', 'libgfortran*', 'libcaf_*.a', 'libyasm.a', '*-gdb.py')
# bin\: the compiler drivers and binutils hbmk2 uses, plus every DLL.
$keepExe = 'gcc','g++','c++','cpp','as','ld','ld.bfd','ar','ranlib','nm','strip','objcopy','objdump',
           'windres','windmc','dlltool','gcc-ar','gcc-nm','gcc-ranlib','mingw32-make','addr2line','c++filt',
           'size','strings','gendef','gcov',
           'x86_64-w64-mingw32-gcc','x86_64-w64-mingw32-gcc-16.2.0','x86_64-w64-mingw32-g++','x86_64-w64-mingw32-c++',
           'x86_64-w64-mingw32-gcc-ar','x86_64-w64-mingw32-gcc-nm','x86_64-w64-mingw32-gcc-ranlib' | ForEach-Object { "$_.exe" }
Copy-Tree (Join-Path $GccSrc 'bin') (Join-Path $g 'bin') (@('*.dll') + $keepExe)
foreach ($e in 'gcc.exe','as.exe','ld.exe','windres.exe') {
   if (-not (Test-Path (Join-Path $g "bin\$e"))) { Fail "Trimmed GCC lacks bin\$e." }
}
Copy-Item (Join-Path $GccSrc 'version_info.txt') $g -ErrorAction SilentlyContinue

# ---- 3. Harbour ---------------------------------------------------------------------------
Step "Copying Harbour from $HbSrc"
Copy-Tree $HbSrc (Join-Path $Dest 'harbour64') @('/XF', 'ChangeLog.txt')

$mb = [math]::Round(((Get-ChildItem -Recurse -File $Dest | Measure-Object Length -Sum).Sum / 1MB), 0)
Write-Host "HMG5 folder: $Dest ($mb MB)"

# ---- 4. Verify in place -------------------------------------------------------------------
if (-not $NoVerify) {
   Step 'Verifying: hmgbuild test inside the new folder'
   # Absolute path: with NoDefaultCurrentDirectoryInExePath set, cmd does not search the current folder.
   cmd /c "`"$(Join-Path $Dest 'hmgbuild.bat')`" test"
   if ($LASTEXITCODE -ne 0) { Fail 'The new HMG5 folder failed its tests (see above).' }
}
Write-Host "HMG5 ready: $Dest   Next: build Setup.exe with dist\HMG5.iss (Inno Setup 6)" -ForegroundColor Green
