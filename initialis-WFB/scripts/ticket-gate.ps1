<#
.SYNOPSIS
  ticket-gate: runs a test command and records evidence that a ticket went red, then green.
.USAGE
  ticket-gate.ps1 -Mode baseline -Feature <slug> -Cmd "<full offline test command>" [-BuildCmd "<build command>"]
  ticket-gate.ps1 -Mode red   -Ticket 01 -Feature <slug> -Cmd "<test command narrowed to the ticket's new tests>"
  ticket-gate.ps1 -Mode green -Ticket 01 -Feature <slug> -Cmd "<full offline test command>" -Plan <plan.md> -Lint <plan-lint.ps1> [-BuildCmd "<build command>"] [-Static "<check>", "<check>"]
  ticket-gate.ps1 -Mode green -Ticket final -Feature <slug> -Cmd "<full offline test command>" [-BuildCmd ...] [-Static ...]
  ticket-gate.ps1 -Mode green -Ticket review-r1 -Feature <slug> -Cmd "<full offline test command>" [-BuildCmd ...] [-Static ...]
  Exit code: 0 = PASS, 1 = FAIL. Evidence: <Root>/.scratch/<feature>/evidence/<Ticket>-<Mode>.log (baseline: baseline.log)
  baseline  records which tests already fail and how many build warnings exist, before any ticket starts.
  red       PASS = the command exits non-zero, not for a build or environment error, AND the ticket's Red test is among the failing tests.
  green     PASS = the suite passes (failures that already existed at baseline are tolerated with a WARN), the build warning count did not
            grow, every -Static command exits 0 and, for numbered tickets with -Plan and -Lint, plan-lint -Gate ticket passes
            (docs sync, scope, claims, Tier 3 tests, ticket size, encoding, edited tests). Run it before committing.
  attempts  every FAIL is counted per ticket. The 2nd failure prints ESCALATE (re-dispatch the Developer one reasoning step higher);
            the 3rd prints STOP and further runs refuse until the human passes -ResetAttempts. A green PASS clears the count.
  -Cmd, -BuildCmd and -Static run as PowerShell script blocks, so quotes behave as in an interactive shell.
  -Cmd must contain a test-runner word (test, pytest, jest, vitest, rspec); a build alone is not a test.
#>
param(
  [Parameter(Mandatory = $true)][ValidateSet('baseline', 'red', 'green')][string]$Mode,
  [string]$Ticket = '',
  [Parameter(Mandatory = $true)][string]$Feature,
  [Parameter(Mandatory = $true)][string]$Cmd,
  [string]$Root = (Get-Location).Path,
  [string]$Plan = '',
  [string]$Lint = '',
  [string]$BuildCmd = '',
  [string[]]$Static = @(),
  [int]$MaxAttempts = 3,
  [switch]$ResetAttempts
)

if ($Mode -eq 'baseline') { $Ticket = 'baseline' }
elseif (-not $Ticket) { Write-Host "FAIL [gate] -Ticket <NN> is required with -Mode $Mode"; exit 1 }

if ($Cmd -notmatch '(?i)\b(test|pytest|jest|vitest|rspec)\b') {
  Write-Host "FAIL [gate] -Cmd is not a test command (a build is not a test): $Cmd"; exit 1
}

$evDir = Join-Path $Root ".scratch\$Feature\evidence"
New-Item -ItemType Directory -Force -Path $evDir | Out-Null
$logName = if ($Mode -eq 'baseline') { 'baseline.log' } else { "$Ticket-$Mode.log" }
$log = Join-Path $evDir $logName
$attFile = Join-Path $evDir "$Ticket-attempts.txt"
$baseFail = Join-Path $evDir 'baseline-failures.txt'
$baseWarn = Join-Path $evDir 'baseline-warnings.txt'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Run-Block([string]$Block) {
  Push-Location $Root
  try {
    $global:LASTEXITCODE = 0
    $o = @(& ([scriptblock]::Create($Block)) 2>&1 | ForEach-Object { "$_" })
    $c = $LASTEXITCODE
    if ($null -eq $c) { $c = 0 }
  } finally { Pop-Location }
  return [pscustomobject]@{ Out = $o; Code = $c }
}
function Get-FailedNames([string[]]$Lines) {
  $set = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach ($l in $Lines) {
    if ($l -match '^\s*(?:Failed|FAILED|FAIL|\[FAIL\])\s+(\S+)') { [void]$set.Add($Matches[1]) }
    elseif ($l -match '^\s*\[xUnit\.net[^\]]*\]\s+(\S+)\s+\[FAIL\]') { [void]$set.Add($Matches[1]) }
  }
  return ,$set
}
function Get-Ident([string]$v) {
  $v = $v.Trim().Trim([char]96)
  if (-not $v -or $v -match '(?i)^n/a') { return '' }
  $tok = ($v -split '\s+')[0]
  $ids = [regex]::Matches($tok, '[A-Za-z_][A-Za-z0-9_]*')
  if ($ids.Count -eq 0) { return '' }
  return $ids[$ids.Count - 1].Value
}
function Get-TicketName([string]$tt, [string]$field) {
  if ($tt -match ('(?mi)^\s*' + [regex]::Escape($field) + '\s*:\s*(.+?)\s*$')) { return (Get-Ident $Matches[1]) }
  return ''
}
function Test-Failing([string]$name, $set, [string]$joined) {
  if (-not $name) { return $true }
  if ($set.Count -gt 0) { foreach ($f in $set) { if ($f -match [regex]::Escape($name)) { return $true } }; return $false }
  return ($joined -match [regex]::Escape($name))   # runner output we cannot parse: fall back to a text match
}
function Get-WarningCount([string[]]$Lines) {
  $n = $null
  foreach ($l in $Lines) { if ($l -match '(\d+)\s+Warning\(s\)') { $n = [int]$Matches[1] } }
  return $n
}
function Count-Attempts { if (Test-Path $attFile) { return @(Get-Content $attFile).Count } else { return 0 } }
function Fail-Run([string]$msg) {
  Write-Host $msg
  $n = (Count-Attempts) + 1
  Add-Content -Path $attFile -Value "$(Get-Date -Format s) $Mode"
  if ($n -ge $MaxAttempts) { Write-Host "STOP [attempts] $n failed gate runs on ticket $Ticket. Do not retry. Report the log paths and what you tried to the main agent; only the human may continue (-ResetAttempts)." }
  elseif ($n -eq ($MaxAttempts - 1)) { Write-Host "ESCALATE [attempts] $n failed gate runs on ticket $Ticket. Stop and return; the main agent re-dispatches a fresh Developer one reasoning step higher, with these log paths." }
  exit 1
}

if ($ResetAttempts) { Remove-Item -LiteralPath $attFile -ErrorAction SilentlyContinue; Write-Host "INFO attempts reset for ticket $Ticket" }
if ($Mode -ne 'baseline' -and (Count-Attempts) -ge $MaxAttempts) {
  Write-Host "STOP [attempts] ticket $Ticket already failed $(Count-Attempts) gate runs; report to the main agent. Only the human may continue (-ResetAttempts)."; exit 1
}

# ---------- run the command ----------
$r = Run-Block $Cmd
$out = @($r.Out); $code = $r.Code
$sha = ''; try { $sha = (& git -C $Root rev-parse --short HEAD 2>$null) } catch {}
$header = @("# ticket-gate $Mode ticket=$Ticket feature=$Feature head=$sha", "# cmd: $Cmd", "# exit: $code", "# time: $(Get-Date -Format s)", '')
[System.IO.File]::WriteAllLines($log, [string[]]($header + $out), $utf8)
$joined = $out -join "`n"
$failed = Get-FailedNames $out
foreach ($l in @($out | Select-Object -Last 6)) { Write-Host "  $l" }

# ---------- baseline ----------
if ($Mode -eq 'baseline') {
  [System.IO.File]::WriteAllLines($baseFail, [string[]]@($failed), $utf8)
  if ($BuildCmd) {
    $b = Run-Block $BuildCmd
    $w = Get-WarningCount $b.Out
    if ($null -ne $w) { [System.IO.File]::WriteAllText($baseWarn, "$w", $utf8); Write-Host "INFO baseline build warnings=$w" }
    else { Write-Host "WARN [baseline] -BuildCmd printed no 'N Warning(s)' line; the warning count will not be compared" }
  }
  if ($code -ne 0) { Write-Host "WARN [baseline] the suite exits $code before any change; $($failed.Count) failing test(s) recorded and tolerated until fixed" }
  Write-Host "PASS baseline failing=$($failed.Count) exit=$code log=$log"; exit 0
}

# ---------- ticket fields ----------
$tt = ''
$tf = @(Get-ChildItem (Join-Path $Root ".scratch\$Feature\issues") -Filter "$Ticket-*.md" -ErrorAction SilentlyContinue)
if ($tf.Count -eq 1) { $tt = Get-Content $tf[0].FullName -Raw -Encoding UTF8 }

# ---------- red ----------
if ($Mode -eq 'red') {
  if ($code -eq 0) { Fail-Run "FAIL [red] tests passed; a red test must fail first. Write or fix the test, then rerun." }
  if ($joined -match '(?i)\berror (CS|MSB|TS|FS)\d+|SyntaxError|ModuleNotFoundError|ImportError') {
    Fail-Run "FAIL [red] the run failed to build or import; make the test compile so it fails on behavior. See $log"
  }
  if ($joined -match '(?i)Could not find file|FileNotFoundException|provider is not registered|Unable to (open|connect)') {
    Fail-Run "FAIL [red] the run failed for an environment reason (data file or provider), not on behavior. Fix the test setup, then rerun. See $log"
  }
  $rt = Get-TicketName $tt 'Red test'
  if ($rt -and -not (Test-Failing $rt $failed $joined)) {
    $first = (@($failed) | Select-Object -First 5) -join ', '
    Fail-Run "FAIL [red] the ticket's Red test '$rt' is not among the failing tests (failing: $first). Make that test fail on the missing behavior."
  }
  foreach ($f in @('Integration test', 'Attack case')) {
    $nm = Get-TicketName $tt $f
    if ($nm -and -not (Test-Failing $nm $failed $joined)) { Write-Host "WARN [red] $f '$nm' did not fail; write it so it fails until the behavior exists" }
  }
  Write-Host "PASS red ticket=$Ticket exit=$code log=$log"; exit 0
}

# ---------- green ----------
$ok = ($code -eq 0)
if (-not $ok) {
  $base = @(); if (Test-Path $baseFail) { $base = @(Get-Content $baseFail) }
  $newFail = @(@($failed) | Where-Object { $base -notcontains $_ })
  if ($failed.Count -gt 0 -and $newFail.Count -eq 0) {
    $ok = $true; Write-Host "WARN [baseline] suite exits $code, but all $($failed.Count) failing test(s) already failed at baseline"
  } else {
    $shown = if ($newFail.Count -gt 0) { ($newFail | Select-Object -First 5) -join ', ' } else { 'unparsed' }
    Fail-Run "FAIL [green] tests exit $code; new failures: $shown; see $log"
  }
}
if ($BuildCmd) {
  $b = Run-Block $BuildCmd
  $w = Get-WarningCount $b.Out
  if ($b.Code -ne 0) { Fail-Run "FAIL [static] build exits $($b.Code)" }
  if ($null -ne $w -and (Test-Path $baseWarn)) {
    $bw = [int](Get-Content $baseWarn -Raw)
    if ($w -gt $bw) { Fail-Run "FAIL [static] build warnings grew from $bw to $w; fix the new warnings" }
  }
}
foreach ($sc in $Static) {
  $s = Run-Block $sc
  if ($s.Code -ne 0) {
    foreach ($l in @($s.Out | Select-Object -Last 6)) { Write-Host "  [static] $l" }
    Fail-Run "FAIL [static] '$sc' exits $($s.Code)"
  }
}
if ($Ticket -match '^\d+$') {
  if ($Plan -and $Lint) {
    $lo = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $Lint $Plan -Root $Root -Gate ticket -Ticket $Ticket 2>&1 | ForEach-Object { "$_" })
    $lc = $LASTEXITCODE
    foreach ($l in $lo) { Write-Host "  [lint] $l" }
    if ($lc -ne 0) { Fail-Run "FAIL [lint] ticket checks failed; fix docs, claims, scope, size, encoding or edited tests, then rerun" }
  } else {
    Write-Host "WARN [gate] no -Plan/-Lint given; ticket docs, scope, claim, size and encoding checks were skipped"
  }
}
Remove-Item -LiteralPath $attFile -ErrorAction SilentlyContinue
Write-Host "PASS $Mode ticket=$Ticket exit=$code log=$log"; exit 0
