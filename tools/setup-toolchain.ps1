<#
.SYNOPSIS
  Sets up the pinned HMG64 toolchain: GCC (WinLibs, UCRT) + Harbour built from source.

.DESCRIPTION
  1. Downloads the pinned WinLibs GCC zip from GitHub and verifies its SHA-256.
  2. Extracts it to <ToolchainDir>\gcc\mingw64.
  3. Clones harbour/core and checks out the pinned commit.
  4. Builds and installs Harbour with that GCC into <ToolchainDir>\harbour64,
     then runs Harbour's own regression test (hbtest).
  5. Links <HmgDir>\mingw64 and <HmgDir>\harbour64 to them as directory junctions.
  Steps that are already done are skipped. Re-running is safe.

  Pins live in the constants block below. Change them only together with TOOLCHAIN.md
  and the pins in hmgbuild.bat.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\setup-toolchain.ps1
#>
[CmdletBinding()]
param(
   # Where the toolchain is downloaded and built (outside the repo).
   # Default: a "hmg-toolchain" folder next to the HMG tree.
   [string] $ToolchainDir = '',
   # HMG tree that gets the mingw64\ and harbour64\ junctions. Default: this script's repo.
   [string] $HmgDir       = '',
   # Use an already-downloaded GCC zip instead of downloading (it is still hash-checked).
   [string] $ZipPath      = '',
   # Harbour git source (a URL or a local clone).
   [string] $HarbourRepo  = 'https://github.com/harbour/core.git',
   # Rebuild Harbour even if a matching build is already installed.
   [switch] $Rebuild
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # Invoke-WebRequest is very slow with a progress bar on PS 5.1

# ---- PINS (as at 06-11-2026; keep in sync with TOOLCHAIN.md and hmgbuild.bat) ----------
$GccZipName   = 'winlibs-x86_64-posix-seh-gcc-16.2.0-mingw-w64ucrt-14.0.0-r3.zip'
$GccZipUrl    = 'https://github.com/brechtsanders/winlibs_mingw/releases/download/16.2.0posix-23.1.3-14.0.0-ucrt-r3/' + $GccZipName
$GccZipSha256 = '3c69305081e4a647144339a936244fcf7d3d9e558319e1ad7be2cd2886d4b6a1'
$GccVersion   = '16.2.0'
$HbCommit     = '694428e1c12f726675b19324d62167fa77d68185'   # harbour/core, 2026-10-24
$HbRevision   = 'r2610242111'                                # as reported by harbour -build
# Same extra C flags as the Harbour shipped with HMG 3.6, so behaviour stays comparable.
$HbUserCflags = '-DHB_GUI -DHB_NO_TRACE -DHB_MEMO_SAFELOCK'
# ------------------------------------------------------------------------------------------

function Step ($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Fail ($msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

# Defaults are resolved here, not in param(): Windows PowerShell 5.1 leaves $PSScriptRoot
# empty inside param() default values.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $HmgDir)       { $HmgDir = Split-Path -Parent $ScriptDir }
if (-not $ToolchainDir) { $ToolchainDir = Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($HmgDir))) 'hmg-toolchain' }

$ToolchainDir = [IO.Path]::GetFullPath($ToolchainDir)
$HmgDir       = [IO.Path]::GetFullPath($HmgDir)
$DlDir        = Join-Path $ToolchainDir 'dl'
$GccRoot      = Join-Path $ToolchainDir 'gcc'
$GccBin       = Join-Path $GccRoot 'mingw64\bin'
$HbSrc        = Join-Path $ToolchainDir 'harbour-src'
$HbPrefix     = Join-Path $ToolchainDir 'harbour64'

if (-not (Test-Path (Join-Path $HmgDir 'hmgbuild.bat'))) { Fail "HmgDir '$HmgDir' is not an HMG64 tree (hmgbuild.bat not found)." }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail 'git is not on PATH. Install Git for Windows and re-run.' }
New-Item -ItemType Directory -Force $ToolchainDir, $DlDir | Out-Null

# ---- 1. GCC zip: download (or use -ZipPath) and verify ------------------------------------
if ($ZipPath) { $Zip = [IO.Path]::GetFullPath($ZipPath) } else { $Zip = Join-Path $DlDir $GccZipName }
if (-not (Test-Path $Zip)) {
   Step "Downloading $GccZipName (~263 MB)"
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
   Invoke-WebRequest -Uri $GccZipUrl -OutFile $Zip -UseBasicParsing
}
Step 'Verifying GCC zip SHA-256'
$hash = (Get-FileHash -Algorithm SHA256 $Zip).Hash.ToLowerInvariant()
if ($hash -ne $GccZipSha256) { Fail "SHA-256 mismatch for $Zip`n  expected $GccZipSha256`n  got      $hash`nDelete the file and re-run." }

# ---- 2. Extract GCC ------------------------------------------------------------------------
if (-not (Test-Path (Join-Path $GccBin 'gcc.exe'))) {
   Step "Extracting GCC to $GccRoot"
   New-Item -ItemType Directory -Force $GccRoot | Out-Null
   & "$env:SystemRoot\System32\tar.exe" -xf $Zip -C $GccRoot   # Windows tar reads zip; Git Bash tar does not
   if ($LASTEXITCODE -ne 0) { Fail 'Extracting the GCC zip failed.' }
}
$gccVer = (& (Join-Path $GccBin 'gcc.exe') -dumpfullversion).Trim()
if ($gccVer -ne $GccVersion) { Fail "Found GCC $gccVer in $GccBin, expected $GccVersion. Delete '$GccRoot' and re-run." }

# ---- 3. Harbour source at the pinned commit ------------------------------------------------
if (-not (Test-Path (Join-Path $HbSrc '.git'))) {
   Step "Cloning Harbour from $HarbourRepo"
   cmd /c "git -c core.autocrlf=false clone -q `"$HarbourRepo`" `"$HbSrc`" 2>&1"
   if ($LASTEXITCODE -ne 0) { Fail 'git clone of Harbour failed.' }
}
# Native tools that write to stderr run through cmd /c: under Windows PowerShell 5.1 with
# ErrorActionPreference=Stop, stderr redirected by PowerShell becomes a terminating error.
cmd /c "git -C `"$HbSrc`" -c core.autocrlf=false checkout -q $HbCommit 2>nul"
if ($LASTEXITCODE -ne 0) {
   cmd /c "git -C `"$HbSrc`" fetch -q origin 2>&1"
   cmd /c "git -C `"$HbSrc`" -c core.autocrlf=false checkout -q $HbCommit 2>&1"
   if ($LASTEXITCODE -ne 0) { Fail "Harbour commit $HbCommit not found in $HbSrc." }
}

# ---- 4. Build + install Harbour, then hbtest ----------------------------------------------
$hbExe = Join-Path $HbPrefix 'bin\harbour.exe'
$haveHb = $false
if ((Test-Path $hbExe) -and -not $Rebuild) {
   $haveHb = [bool]((cmd /c "`"$hbExe`" -build 2>&1" | Out-String) -match [regex]::Escape($HbRevision))
}
$env:PATH = "$GccBin;$env:PATH"
if (-not $haveHb) {
   Step "Building Harbour $HbRevision with GCC $GccVersion (takes several minutes)"
   $env:HB_COMPILER       = 'mingw64'
   $env:HB_PLATFORM       = 'win'
   $env:HB_INSTALL_PREFIX = $HbPrefix
   $env:HB_USER_CFLAGS    = $HbUserCflags
   $log = Join-Path $ToolchainDir 'harbour-build.log'
   Push-Location $HbSrc
   try {
      # Absolute path: with NoDefaultCurrentDirectoryInExePath set, cmd does not search the current folder.
      cmd /c "`"$(Join-Path $HbSrc 'win-make.exe')`" -j$([Environment]::ProcessorCount) install > `"$log`" 2>&1"
      $rc = $LASTEXITCODE
   } finally { Pop-Location }
   if ($rc -ne 0) { Fail "Harbour build failed (exit $rc). See $log" }
}
Step 'Running Harbour regression test (hbtest)'
$hbtestOut = cmd /c "`"$(Join-Path $HbPrefix 'bin\hbtest.exe')`" 2>&1" | Out-String
if ($hbtestOut -notmatch 'Test calls failed:\s+0\b') { Write-Host $hbtestOut; Fail 'hbtest reported failures.' }

# ---- 5. Junctions into the HMG tree --------------------------------------------------------
foreach ($pair in @(@('mingw64', (Join-Path $GccRoot 'mingw64')), @('harbour64', $HbPrefix))) {
   $link = Join-Path $HmgDir $pair[0]
   $target = $pair[1]
   if (Test-Path $link) {
      $item = Get-Item $link -Force
      if ($item.LinkType -eq 'Junction') {
         if ($item.Target -contains $target -or "$($item.Target)" -eq $target) { continue }
         cmd /c rmdir "$link" | Out-Null         # removes the junction only, never the target
      } else {
         Fail "'$link' is a real folder (probably the old HMG 3.6 toolchain). Rename it (e.g. to $($pair[0]).old) and re-run - this script never deletes it."
      }
   }
   Step "Linking $link -> $target"
   cmd /c mklink /J "$link" "$target" | Out-Null
   if ($LASTEXITCODE -ne 0) { Fail "Could not create junction $link." }
}

Step 'Checking with hmgbuild'
& cmd /c "`"$(Join-Path $HmgDir 'hmgbuild.bat')`" check"
if ($LASTEXITCODE -ne 0) { Fail 'hmgbuild check failed.' }
Write-Host "Toolchain ready. Next: hmgbuild all   (or: hmgbuild matrix  for ANSI + UNICODE)" -ForegroundColor Green
