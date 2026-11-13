# IDE form round-trip test (PHASE4-DESIGN.md section 6, step I2) and the built-in
# editor's self-test (IDE.exe /edtest, section 6.7) and the design-form grid check (/gridtest).
#
# For every form in tests\ide\corpus:
#   1. IDE.exe /roundtrip corpus\X  out\X.1   (open in the designer, generate as File > Save)
#   2. IDE.exe /roundtrip out\X.1   out\X.2   (the IDE's own output must be a fixed point)
#   3. out\X.1 must equal expected\X          (reference output of the baseline IDE)
#
#   run.ps1           run the test (exit code 0 = all passed)
#   run.ps1 -Update   write the current output as the new reference (only after reviewing
#                     the differences: the reference is what keeps forms unchanged)
param([switch]$Update, [string]$Ide = "$PSScriptRoot\..\..\IDE\IDE.exe", [int]$TimeoutSec = 40)

$ErrorActionPreference = 'Stop'
$corpus   = Join-Path $PSScriptRoot 'corpus'
$expected = Join-Path $PSScriptRoot 'expected'
$out      = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\out\ide'))
New-Item -ItemType Directory -Force $out, $expected | Out-Null
$Ide = (Resolve-Path $Ide).Path

function Invoke-RoundTrip([string]$in, [string]$dst) {
   if (Test-Path $dst) { Remove-Item $dst }
   $p = Start-Process $Ide -ArgumentList "/roundtrip `"$in`" `"$dst`"" -WorkingDirectory (Split-Path $Ide) -PassThru
   if (-not $p.WaitForExit($TimeoutSec * 1000)) { $p.Kill(); return "TIMEOUT (a dialog may be open)" }
   if (-not (Test-Path $dst)) { return "no output (exit $($p.ExitCode))" }
   $text = [IO.File]::ReadAllText($dst)
   if ($text.StartsWith('ERROR:')) { return $text.Trim() }
   return $null
}

$pass = 0; $fail = 0; $t0 = Get-Date
foreach ($f in Get-ChildItem $corpus -File | Sort-Object Name) {
   $o1 = Join-Path $out ($f.Name + '.1')
   $o2 = Join-Path $out ($f.Name + '.2')
   $ref = Join-Path $expected $f.Name
   $err = Invoke-RoundTrip $f.FullName $o1
   if (-not $err) { $err = Invoke-RoundTrip $o1 $o2 }
   if (-not $err) {
      $b1 = [IO.File]::ReadAllBytes($o1); $b2 = [IO.File]::ReadAllBytes($o2)
      if ([Convert]::ToBase64String($b1) -ne [Convert]::ToBase64String($b2)) { $err = "second round trip differs (not a fixed point): fc $o1 $o2" }
   }
   if (-not $err) {
      if ($Update) { Copy-Item $o1 $ref -Force }
      elseif (-not (Test-Path $ref)) { $err = "no reference in expected\ (run with -Update after review)" }
      elseif ([Convert]::ToBase64String([IO.File]::ReadAllBytes($ref)) -ne [Convert]::ToBase64String($b1)) { $err = "differs from the reference: fc `"$ref`" `"$o1`"" }
   }
   if ($err) { $fail++; Write-Output "ide-roundtrip: FAIL $($f.Name): $err" } else { $pass++ }
}
# AddControl defaults: one control of every palette type on an empty form (IDE.exe /addall)
$oa = Join-Path $out 'addall.fmg'
$refa = Join-Path $expected 'addall.fmg'
if (Test-Path $oa) { Remove-Item $oa }
$p = Start-Process $Ide -ArgumentList "/addall `"$PSScriptRoot\addall_base.fmg`" `"$oa`"" -WorkingDirectory (Split-Path $Ide) -PassThru
$err = $null
if (-not $p.WaitForExit($TimeoutSec * 1000)) { $p.Kill(); $err = "TIMEOUT (a dialog may be open)" }
elseif (-not (Test-Path $oa)) { $err = "no output" }
elseif ([IO.File]::ReadAllText($oa).StartsWith('ERROR:')) { $err = [IO.File]::ReadAllText($oa).Trim() }
elseif ($Update) { Copy-Item $oa $refa -Force }
elseif (-not (Test-Path $refa)) { $err = "no reference in expected\ (run with -Update after review)" }
elseif ([Convert]::ToBase64String([IO.File]::ReadAllBytes($refa)) -ne [Convert]::ToBase64String([IO.File]::ReadAllBytes($oa))) { $err = "differs from the reference: fc `"$refa`" `"$oa`"" }
if ($err) { $fail++; Write-Output "ide-roundtrip: FAIL addall: $err" } else { $pass++ }

# built-in code editor (PHASE4-DESIGN.md 6.7): IDE.exe /edtest writes one PASS/FAIL line a check
$oe = Join-Path $out 'edtest.txt'
if (Test-Path $oe) { Remove-Item $oe }
$p = Start-Process $Ide -ArgumentList "/edtest `"$oe`"" -WorkingDirectory (Split-Path $Ide) -PassThru
$err = $null
if (-not $p.WaitForExit($TimeoutSec * 1000)) { $p.Kill(); $err = "TIMEOUT (a dialog may be open)" }
elseif (-not (Test-Path $oe)) { $err = "no output" }
else {
   $lines = Get-Content $oe
   $bad = @($lines | Where-Object { $_ -like 'FAIL*' })
   if ($bad.Count -gt 0 -or -not ($lines | Where-Object { $_ -like 'edtest: PASS=*' })) { $err = ($bad -join '; ') }
}
if ($err) { $fail++; Write-Output "ide-roundtrip: FAIL edtest: $err" } else { $pass++ }

# design-form grid after closing and reopening a form: IDE.exe /gridtest <in.fmg> <out.txt>
$og = Join-Path $out 'gridtest.txt'
if (Test-Path $og) { Remove-Item $og }
$p = Start-Process $Ide -ArgumentList "/gridtest `"$PSScriptRoot\addall_base.fmg`" `"$og`"" -WorkingDirectory (Split-Path $Ide) -PassThru
$err = $null
if (-not $p.WaitForExit($TimeoutSec * 1000)) { $p.Kill(); $err = "TIMEOUT (a dialog may be open)" }
elseif (-not (Test-Path $og)) { $err = "no output" }
else {
   $lines = @(Get-Content $og)
   $bad = @($lines | Where-Object { $_ -notlike 'PASS*' })
   if ($bad.Count -gt 0 -or $lines.Count -ne 2) { $err = ($lines -join '; ') }
}
if ($err) { $fail++; Write-Output "ide-roundtrip: FAIL gridtest: $err" } else { $pass++ }

# New Project, both kinds: IDE.exe /newproject <dir\sample.hbp> code|form
#   code: sample.prg is the only module (the main window in code), no .fmg
#   form: Main.Prg loads Main.Fmg
foreach ($kind in 'code', 'form') {
   $dn = Join-Path $out "newproject_$kind"
   if (Test-Path $dn) { Remove-Item $dn -Recurse -Force }
   New-Item -ItemType Directory $dn | Out-Null
   $p = Start-Process $Ide -ArgumentList "/newproject `"$dn\sample.hbp`" $kind" -WorkingDirectory (Split-Path $Ide) -PassThru
   $err = $null
   if (-not $p.WaitForExit($TimeoutSec * 1000)) { $p.Kill(); $err = "TIMEOUT (a dialog may be open)" }
   elseif (-not (Test-Path "$dn\sample.hbp")) { $err = "no sample.hbp" }
   else {
      $mods  = @(Get-Content "$dn\sample.hbp" | Where-Object { $_ -match '\.prg$' })
      $fmgs  = @(Get-ChildItem $dn -Filter *.fmg)
      $files = (Get-ChildItem $dn | ForEach-Object Name) -join ' '
      if ($kind -eq 'code') {
         if ($mods.Count -ne 1 -or $mods[0] -ne 'sample.prg' -or $fmgs.Count -ne 0) { $err = "files: $files; modules: $($mods -join ' ')" }
         elseif ((Get-Content "$dn\sample.prg" -Raw) -notmatch 'DEFINE WINDOW Win_Main') { $err = "sample.prg has no main window in code" }
      } else {
         if ($mods.Count -ne 1 -or $mods[0] -ne 'Main.Prg' -or $fmgs.Count -ne 1) { $err = "files: $files; modules: $($mods -join ' ')" }
         elseif ((Get-Content "$dn\Main.Prg" -Raw) -notmatch 'Load Window Main') { $err = "Main.Prg does not load Main.fmg" }
      }
   }
   if ($err) { $fail++; Write-Output "ide-roundtrip: FAIL newproject $kind`: $err" } else { $pass++ }
}

$secs = [int]((Get-Date) - $t0).TotalSeconds
Write-Output ("ide-roundtrip: PASS={0} FAIL={1} ({2} s){3}" -f $pass, $fail, $secs, $(if ($Update) { ' - references updated' } else { '' }))
exit $(if ($fail -eq 0) { 0 } else { 1 })
