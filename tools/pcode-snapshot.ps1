<#
.SYNOPSIS
  Proves that a source refactor does not change the compiled library (PHASE3-DESIGN.md, S1).

.DESCRIPTION
  snapshot: compiles every .prg under SOURCE\ and hfcl\Source\ to C with harbour.exe
            (fixed flags, no hbmk2) into <OutDir>, one .c per source file.
  compare : compares two snapshot folders byte for byte and lists every difference.

  Named #defines disappear in the preprocessor, so renaming _HMG_SYSDATA[ 3 ] to
  _HMG_SYSDATA[ HMG_CTL_HANDLE ] must give identical C. Line numbers are part of the
  generated code, so the rename must not add or remove lines.

.EXAMPLE
  powershell -File tools\pcode-snapshot.ps1 snapshot D:\tmp\before
  ... edit ...
  powershell -File tools\pcode-snapshot.ps1 snapshot D:\tmp\after
  powershell -File tools\pcode-snapshot.ps1 compare  D:\tmp\before D:\tmp\after
#>
param(
   [Parameter(Mandatory)][ValidateSet('snapshot', 'compare')] [string] $Action,
   [Parameter(Mandatory)] [string] $Dir1,
   [string] $Dir2 = ''
)
$ErrorActionPreference = 'Stop'
$Hmg = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

if ($Action -eq 'snapshot') {
   $hb = Join-Path $Hmg 'harbour64\bin\harbour.exe'
   if (-not (Test-Path $hb)) { Write-Host "ERROR: $hb not found (run tools\setup-toolchain.ps1)"; exit 1 }
   New-Item -ItemType Directory -Force $Dir1 | Out-Null
   $files = @(Get-ChildItem -Recurse -File (Join-Path $Hmg 'SOURCE'), (Join-Path $Hmg 'hfcl\Source') |
              Where-Object { $_.Extension -ieq '.prg' })
   $fail = 0
   foreach ($f in $files) {
      $rel = $f.FullName.Substring($Hmg.Length + 1)
      $out = Join-Path $Dir1 (($rel -replace '[\\/]', '__') -replace '\.prg$', '.c')
      # Same switches as hmg64.hbp except warnings (irrelevant to the generated code).
      $o = cmd /c "`"$hb`" -n1 -q -D__HBIDE__ -w0 -gc0 `"-i$Hmg\harbour64\include`" `"-i$Hmg\INCLUDE`" `"-i$Hmg\hfcl\Include`" `"-o$out`" `"$($f.FullName)`" 2>&1"
      if ($LASTEXITCODE -ne 0) { $fail++; Set-Content -Path "$out.err" -Value $o }
   }
   Write-Host "snapshot: $($files.Count) files -> $Dir1 (compile failures: $fail, kept as *.err)"
   exit 0
}

# compare
if (-not $Dir2) { Write-Host 'ERROR: compare needs two folders'; exit 2 }
$a = Get-ChildItem -File $Dir1 | Sort-Object Name
$b = Get-ChildItem -File $Dir2 | Sort-Object Name
$diff = 0
$names = @($a.Name) + @($b.Name) | Sort-Object -Unique
foreach ($n in $names) {
   $p1 = Join-Path $Dir1 $n; $p2 = Join-Path $Dir2 $n
   if (-not (Test-Path $p1) -or -not (Test-Path $p2)) { Write-Host "ONLY IN ONE: $n"; $diff++; continue }
   # The generated C embeds the source path only via the file name, which is the same in both.
   if ((Get-FileHash $p1).Hash -ne (Get-FileHash $p2).Hash) { Write-Host "DIFFERS: $n"; $diff++ }
}
if ($diff -eq 0) { Write-Host "IDENTICAL: $($names.Count) files" ; exit 0 }
Write-Host "$diff file(s) differ"
exit 1
