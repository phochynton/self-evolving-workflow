<#
.SYNOPSIS
  plan-lint: deterministic checks on plan.md. No LLM required.
.USAGE
  powershell -ExecutionPolicy Bypass -File plan-lint.ps1 <plan.md> [-Root <repo>] [-Config <psd1>] [-Slim]
  plan-lint.ps1 <plan.md> -Gate map                          MAP entry gate (strict state checks, clean working tree, fast-track verdict)
  plan-lint.ps1 <plan.md> -Gate ticket -Ticket <NN>          one ticket's uncommitted change: docs sync, scope, claims, Tier 3 tests
  plan-lint.ps1 <plan.md> -Gate post -Base <sha> [-Deliver]  delivery gate over every commit since <sha>; -Deliver sets "status: delivered" only when clean
  plan-lint.ps1 <plan.md> -Gate cite [-Attack <file>]        checks every path:line in an attack or review report exists (default: latest attack-r<N>.md)
  -Slim: deterministic rationale extraction (moves exact-title narrative sections to rationale.md), then exit 0.
  Exit code: 0 = PASS (warnings allowed), 1 = FAIL.
  Output lines: "ERROR [tag] msg" / "WARN [tag] msg" / "INFO ..." / "PASS ..." / "FAIL ...".
.CONFIG
  Project rules load from <Root>/scripts/plan-lint.config.psd1 when present (UTF-8).
  Keys (all optional): DocMap, AlwaysDocs, Gates, SectionAliases, MaxPlanChars, MaxLineChars, Tier3When,
    ProtectedPaths (regex array: steering/tooling files such as AGENTS.md or scripts/),
    TestPaths (regex array: test files; default covers tests/, *Tests.*, *.spec.*, *.test.*),
    MaxTicketFiles (default 3) and MaxTicketLines (default 150): size limit of one ticket's production change,
    TestEditLevel ('Error' default, or 'Warn'): severity of editing an existing test without a declaration.
  In -Gate post, DocMap keys are matched against changed file paths, so write them to match paths as well as symbols.
.REMEDY TAGS
  verdict-r<N>.md lists accepted remedies as "[Remedy <N>.<k>]"; plan.md must carry "(Remedy <N>.<k>)" where each is applied.
  open_accepted_items = number of accepted remedies missing from plan.md. The script computes it; the frontmatter must match.
  Remedy IDs are <round>.<k> without leading zeros (1.1, 1.10). The verdict file is named exactly verdict-r<N>.md.
.TICKET FIELDS (.scratch/<feature>/issues/<NN>-*.md, section "## MAP")
  Tier, Touches, Red test: always. Tier 3 adds Integration test and Attack case (test names that must exist in the test files).
  Tests-may-change: declares which existing tests the ticket may edit (without it, removing test lines is an ERROR).
  Size-waiver: <reason> lifts the size limit; only the human writes it.
  Claims lines: "<doc path> | <claim> | <test name or path:line>"; the third field must exist.
.REVIEW FILES (docs/specs/<feature>/review-r<N>.md)
  Every [Finding <N>.<k>] needs one row in "## Disposition": | Finding | Level | fixed/deferred/rejected | Ref |.
  fixed: Ref has a real commit SHA and "sweep: <pattern> -> <n> hits". deferred: Ref is a K-<n> id listed in docs/specs/known-open.md.
  rejected: Ref cites a real path:line or a plan clause. The last round must contain no fixed rows (a later round re-reviews the fix diff).
  First line: "Reviewer: model=<id> developer=<id> mode=internal|external".
.STATE LOG (.scratch/<feature>/state.md)
  One line per ticket: "- <NN> | <sha> | tests=<n> | read: <path:line, ...> | tests-changed: <...> | <notes>".
  Every ticket whose Red test is not n/a needs "read:" with real path:line entries (proof the Developer opened what it changed).
.COMMIT TAGS
  Code or test commits end their subject with [<NN>] (ticket) or [review-r<N>] (review fix).
#>
param(
  [Parameter(Mandatory = $true)][string]$Plan,
  [string]$Root = (Get-Location).Path,
  [string]$Config = '',
  [switch]$Slim,
  [ValidateSet('', 'map', 'post', 'ticket', 'cite')][string]$Gate = '',
  [string]$Attack = '',
  [string]$Base = '',
  [string]$Ticket = '',
  [switch]$Deliver
)

$errors = New-Object System.Collections.ArrayList
$warns  = New-Object System.Collections.ArrayList
function Err($m)  { [void]$errors.Add($m) }
function Warn($m) { [void]$warns.Add($m) }

# ---------- 0. Load config ----------
$cfg = @{}
if (-not $Config) { $Config = Join-Path $Root 'scripts\plan-lint.config.psd1' }
if (Test-Path $Config) {
  $sb = [scriptblock]::Create((Get-Content $Config -Raw -Encoding UTF8))
  $sb.CheckRestrictedLanguage([string[]]@(), [string[]]@(), $false)   # data only, no code execution
  $cfg = & $sb
}
$DocMap       = if ($cfg.DocMap)       { $cfg.DocMap }       else { @{} }
$AlwaysDocs   = if ($cfg.AlwaysDocs)   { $cfg.AlwaysDocs }   else { @() }
$Gates        = if ($cfg.Gates)        { $cfg.Gates }        else { @() }
$Aliases      = if ($cfg.SectionAliases) { $cfg.SectionAliases } else { @{} }
$MaxPlanChars = if ($cfg.MaxPlanChars) { $cfg.MaxPlanChars } else { 15000 }
$MaxLineChars = if ($cfg.MaxLineChars) { $cfg.MaxLineChars } else { 600 }
$Protected    = if ($cfg.ProtectedPaths) { @($cfg.ProtectedPaths) } else { @() }
$TestRes      = if ($cfg.TestPaths) { @($cfg.TestPaths) } else { @('(?i)(^|/)(tests?|__tests__)/', '(?i)tests?\.[a-z]+$', '(?i)\.(spec|test)\.[a-z]+$') }
$MaxTicketFiles = if ($cfg.MaxTicketFiles) { [int]$cfg.MaxTicketFiles } else { 3 }
$MaxTicketLines = if ($cfg.MaxTicketLines) { [int]$cfg.MaxTicketLines } else { 150 }
$TestEditLevel  = if ($cfg.TestEditLevel) { [string]$cfg.TestEditLevel } else { 'Error' }

if (-not [System.IO.Path]::IsPathRooted($Plan)) { $Plan = Join-Path $Root $Plan }
if (-not (Test-Path $Plan)) { Write-Host "FAIL plan not found: $Plan"; exit 1 }

$text  = Get-Content $Plan -Raw -Encoding UTF8
$lines = $text -split "`r?`n"
$dir   = Split-Path $Plan -Parent

function Run-Git([string[]]$GitArgs) {
  # Returns an array (possibly empty), or $null when git fails or is missing.
  try {
    $o = & git -c core.quotepath=off -C $Root @GitArgs 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    if ($null -eq $o) { return ,@() }
    return ,@($o)
  } catch { return $null }
}
function Match-Any([string]$s, [object[]]$res) {
  foreach ($r in $res) { if ($s -match $r) { return $true } }
  return $false
}

# ---------- shared helpers: ticket, claim and change checks ----------
$script:ticketTexts = @{}
$script:testBlob = $null
function Get-Field([string]$tt, [string]$name) {
  if ($tt -match ('(?mi)^\s*' + [regex]::Escape($name) + '\s*:\s*(.+?)\s*$')) { return $Matches[1].Trim() }
  return ''
}
function Get-TestBlob {
  if ($null -ne $script:testBlob) { return $script:testBlob }
  $sb = New-Object System.Text.StringBuilder
  $ls = Run-Git @('ls-files', '--cached', '--others', '--exclude-standard')
  if ($ls) {
    foreach ($f in $ls) {
      if (Match-Any $f $TestRes) {
        $p = Join-Path $Root ($f -replace '/', '\')
        if (Test-Path -LiteralPath $p) { [void]$sb.AppendLine((Get-Content -LiteralPath $p -Raw -Encoding UTF8)) }
      }
    }
  }
  $script:testBlob = $sb.ToString()
  return $script:testBlob
}
function Test-NameExists([string]$ref) {
  $tok = ($ref.Trim().Trim([char]96) -split '\s+')[0]
  $ids = [regex]::Matches($tok, '[A-Za-z_][A-Za-z0-9_]*')
  if ($ids.Count -eq 0) { return $false }
  $name = $ids[$ids.Count - 1].Value
  return ((Get-TestBlob) -match ('\b' + [regex]::Escape($name) + '\b'))
}
function Split-Touches([string]$s) {
  return @($s -split '[,;]' | ForEach-Object { ($_.Trim().Trim([char]96) -replace '\\', '/') } | Where-Object { $_ })
}
function Check-Ticket([string]$tt, [string]$nn) {
  $tier = Get-Field $tt 'Tier'
  if ($tier -notmatch '^[123]$') { Err "[ticket] ticket $nn needs 'Tier: 1|2|3' in its ## MAP section" }
  if (-not (Get-Field $tt 'Touches')) { Err "[ticket] ticket $nn needs 'Touches: <path prefixes>' (the files this ticket may change)" }
  if (-not (Get-Field $tt 'Red test')) { Err "[ticket] ticket $nn needs 'Red test: <name>' or 'Red test: n/a - <reason>'" }
  if ($tier -eq '3') {
    foreach ($f in @('Integration test', 'Attack case')) {
      $v = Get-Field $tt $f
      if (-not $v) { Err "[ticket] Tier 3 ticket $nn needs '$($f): <test name>'" }
      elseif ($v -match '(?i)^n/a') {
        if ($f -eq 'Integration test' -or $v -notmatch '(?i)^n/a\s*-\s*\S') {
          Err "[ticket] Tier 3 ticket $($nn): '$f' needs a real test name (only Attack case may be 'n/a - <reason>')"
        }
      }
      elseif (-not (Test-NameExists $v)) { Err "[ticket] ticket $($nn): $f '$v' was not found in the test files" }
    }
  }
  foreach ($m in [regex]::Matches($tt, '(?mi)^\s*Claims?\s*:\s*(.+?)\s*$')) {
    $parts = @($m.Groups[1].Value -split '\|' | ForEach-Object { $_.Trim() })
    if ($parts.Count -lt 3 -or -not $parts[2]) {
      Err "[claims] ticket $($nn): a claim line needs '<doc path> | <claim> | <test name or path:line>': $($m.Groups[1].Value)"
      continue
    }
    $ref = $parts[2].Trim([char]96)
    if ($ref -match '^([^\s:]+):(\d+)') {
      $cp = Join-Path $Root ($Matches[1] -replace '/', '\'); $ln = [int]$Matches[2]
      if (-not (Test-Path -LiteralPath $cp)) { Err "[claims] ticket $($nn): $ref names a file that does not exist" }
      elseif (@(Get-Content -LiteralPath $cp -Encoding UTF8).Count -lt $ln) { Err "[claims] ticket $($nn): $ref is past the end of the file" }
    }
    elseif (-not (Test-NameExists $ref)) { Err "[claims] ticket $($nn): '$ref' is neither an existing path:line nor a test name found in the test files" }
  }
}
function Check-Files([string[]]$files, [string]$label, [string]$ticketText, [string]$nn, [string]$kind) {
  $specRe = '^docs/specs/(' + [regex]::Escape($fm['feature']) + '/|known-open\.md$)'
  $code = @(); $prot = @(); $tests = @()
  foreach ($f in $files) {
    if ($f -match $specRe) { continue }
    if (Match-Any $f $Protected) { $prot += $f; continue }
    if ($f -match '^docs/' -or $f -match '\.md$') { continue }
    if (Match-Any $f $TestRes) { $tests += $f; continue }
    $code += $f
  }
  $joined = ($files -join "`n")
  if ($code.Count -gt 0) {
    foreach ($a in $AlwaysDocs) {
      if ($joined -notmatch [regex]::Escape($a)) { Err "[docs-sync] $label changes code but not $a (docs ship in the same commit as the code)" }
    }
    foreach ($pat in $DocMap.Keys) {
      if (@($code | Where-Object { $_ -match $pat }).Count -gt 0 -and $joined -notmatch [regex]::Escape($DocMap[$pat])) {
        Err "[docs-sync] $label changes files matching /$pat/ but not $($DocMap[$pat])"
      }
    }
  }
  foreach ($f in $prot) {
    if ($text -notmatch [regex]::Escape((Split-Path $f -Leaf))) { Err "[scope] $label changes $f, which plan.md never names" }
  }
  foreach ($f in $code) {
    if ($text -notmatch [regex]::Escape((Split-Path $f -Leaf))) { Warn "[scope] $label changes $f, which plan.md never names" }
  }
  if ($prot.Count -gt 0 -and $code.Count -gt 0) { Warn "[commit-mix] $label mixes steering/tooling files with code; split them" }
  $touch = @(); $who = ''
  if ($kind -eq 'ticket' -and $ticketText) { $touch = @(Split-Touches (Get-Field $ticketText 'Touches')); $who = "ticket $nn" }
  elseif ($kind -eq 'review') {
    foreach ($k in $script:ticketTexts.Keys) { $touch += @(Split-Touches (Get-Field $script:ticketTexts[$k] 'Touches')) }
    $who = 'any ticket'
  }
  if ($touch.Count -gt 0) {
    foreach ($f in $code) {
      $ok = $false
      foreach ($p in $touch) {
        if (($p -match '[*?]' -and $f -like $p) -or $f.StartsWith($p, [StringComparison]::OrdinalIgnoreCase)) { $ok = $true; break }
      }
      if (-not $ok) { Err "[scope] $label changes $f, outside the Touches of $who" }
    }
  }
  return [pscustomobject]@{ Work = (($code.Count + $tests.Count) -gt 0) }
}

# ---------- v4.3 helpers: path:line proof, ticket size, encoding, test edits ----------
$script:RefRe = '(?<![\w/\\.])([\w./\\-]+\.(?:cs|cshtml|csproj|json|ps1|psd1|md|yaml|yml|ts|tsx|js|py|razor|css|html)):(\d+)(?:-(\d+))?'
function Test-PathLine([string]$path, [int]$line) {
  # Returns '' when path:line exists, else the reason.
  $cp = Join-Path $Root ($path -replace '/', '\')
  if (-not (Test-Path -LiteralPath $cp)) { return "$path does not exist" }
  if (@(Get-Content -LiteralPath $cp -Encoding UTF8).Count -lt $line) { return "${path}:$line is past the end of the file" }
  return ''
}
function Split-Files([string[]]$files) {
  $specRe = '^docs/specs/(' + [regex]::Escape($fm['feature']) + '/|known-open\.md$)'
  $code = @(); $tests = @()
  foreach ($f in $files) {
    if ($f -match $specRe) { continue }
    if (Match-Any $f $Protected) { continue }
    if ($f -match '^docs/' -or $f -match '\.md$') { continue }
    if (Match-Any $f $TestRes) { $tests += $f; continue }
    $code += $f
  }
  return [pscustomobject]@{ Code = $code; Tests = $tests }
}
function Get-Numstat([string]$f) {
  # Returns @{Added; Deleted; Tracked} for one uncommitted file against HEAD.
  $num = Run-Git @('diff', 'HEAD', '--numstat', '--no-renames', '--', $f)
  foreach ($l in @($num)) { if ($l -match '^(\d+)\s+(\d+)\s+') { return @{ Added = [int]$Matches[1]; Deleted = [int]$Matches[2]; Tracked = $true } } }
  $p = Join-Path $Root ($f -replace '/', '\')
  $n = 0; if (Test-Path -LiteralPath $p) { $n = @(Get-Content -LiteralPath $p -Encoding UTF8).Count }
  return @{ Added = $n; Deleted = 0; Tracked = $false }
}
function Check-Size([string[]]$files, [string]$tt, [string]$nn) {
  if ($tt -match '(?mi)^\s*Size-waiver\s*:\s*\S') { Write-Host "INFO [size] ticket $nn carries a Size-waiver; the size limit is skipped"; return }
  $sp = Split-Files $files
  $lines = 0
  foreach ($f in @($sp.Code)) { $ns = Get-Numstat $f; $lines += $ns.Added + $ns.Deleted }
  Write-Host "INFO ticket-size files=$(@($sp.Code).Count)/$MaxTicketFiles lines=$lines/$MaxTicketLines"
  if (@($sp.Code).Count -gt $MaxTicketFiles) { Err "[size] ticket $nn changes $(@($sp.Code).Count) production files (limit $MaxTicketFiles); split it into smaller tickets (expand-contract for refactors)" }
  if ($lines -gt $MaxTicketLines) { Err "[size] ticket $nn changes $lines production lines (limit $MaxTicketLines); split it into smaller tickets" }
}
function Get-HeadBytes([string]$rel) {
  try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'git'
    $psi.Arguments = ('-C "{0}" show "HEAD:{1}"' -f $Root, $rel)
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.UseShellExecute = $false
    $pr = [System.Diagnostics.Process]::Start($psi)
    $ms = New-Object System.IO.MemoryStream
    $pr.StandardOutput.BaseStream.CopyTo($ms)
    [void]$pr.StandardError.ReadToEnd()
    $pr.WaitForExit()
    if ($pr.ExitCode -ne 0) { return $null }
    return ,$ms.ToArray()
  } catch { return $null }
}
function Get-ByteStats([byte[]]$b) {
  $crlf = 0; $lf = 0; $fffd = 0
  for ($i = 0; $i -lt $b.Length; $i++) {
    if ($b[$i] -eq 10) { if ($i -gt 0 -and $b[$i - 1] -eq 13) { $crlf++ } else { $lf++ } }
    elseif ($b[$i] -eq 0xEF -and $i + 2 -lt $b.Length -and $b[$i + 1] -eq 0xBF -and $b[$i + 2] -eq 0xBD) { $fffd++ }
  }
  $bom = ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
  return @{ Crlf = $crlf; Lf = $lf; Fffd = $fffd; Bom = $bom }
}
function Check-Encoding([string[]]$files) {
  foreach ($f in $files) {
    if ($f -notmatch '(?i)\.(cs|cshtml|razor|csproj|json|ps1|psd1|md|yaml|yml|js|ts|tsx|py|css|html|xml|config|txt)$') { continue }
    $p = Join-Path $Root ($f -replace '/', '\')
    if (-not (Test-Path -LiteralPath $p)) { continue }
    $now = Get-ByteStats ([System.IO.File]::ReadAllBytes($p))
    $hb = Get-HeadBytes $f
    if ($null -eq $hb) {
      if ($now.Fffd -gt 0) { Err "[encoding] $f contains $($now.Fffd) U+FFFD replacement character(s): damaged text" }
      continue
    }
    $was = Get-ByteStats $hb
    if ($now.Fffd -gt $was.Fffd) { Err "[encoding] $f gained U+FFFD replacement character(s): text was damaged by an edit or a re-encode" }
    if ($now.Bom -ne $was.Bom) { Err "[encoding] $f BOM changed (HEAD: $($was.Bom), now: $($now.Bom)); keep each file's encoding exactly as it is" }
    if (($was.Crlf + $was.Lf) -gt 0) {
      $wasMinor = [Math]::Min($was.Crlf, $was.Lf); $nowMinor = [Math]::Min($now.Crlf, $now.Lf)
      $wasDom = if ($was.Crlf -ge $was.Lf) { 'CRLF' } else { 'LF' }
      $nowDom = if ($now.Crlf -ge $now.Lf) { 'CRLF' } else { 'LF' }
      if ($wasDom -ne $nowDom -and ($now.Crlf + $now.Lf) -gt 0) { Err "[encoding] $f line endings flipped from $wasDom to $nowDom" }
      elseif ($wasMinor -eq 0 -and $nowMinor -gt 0) { Err "[encoding] $f now mixes CRLF and LF line endings (HEAD used only $wasDom)" }
    }
  }
}
function Test-TestMayChange([string]$tt) { return ($tt -match '(?mi)^\s*Tests-may-change\s*:\s*\S') }
function Check-TestEdits([string[]]$files, [string]$tt, [string]$nn) {
  if (Test-TestMayChange $tt) { return }
  $sp = Split-Files $files
  foreach ($f in @($sp.Tests)) {
    $ns = Get-Numstat $f
    if ($ns.Tracked -and $ns.Deleted -gt 0) {
      $m = "[tests] ticket $nn edits existing test code in $f ($($ns.Deleted) line(s) removed); declare 'Tests-may-change: <what and why>' in the ticket's ## MAP before editing existing tests"
      if ($TestEditLevel -eq 'Warn') { Warn $m } else { Err $m }
    }
  }
}
function Check-RefsIn([string]$textBlock, [string]$label) {
  # Every path:line token in the text must exist. Returns the number of tokens checked.
  $n = 0
  foreach ($m in [regex]::Matches($textBlock, $script:RefRe)) {
    $n++
    $why = Test-PathLine $m.Groups[1].Value ([int]$m.Groups[2].Value)
    if ($why) { Err "[cite] $($label): $why" }
  }
  return $n
}

# ---------- Gate cite: path:line proof for attack and review reports ----------
if ($Gate -eq 'cite') {
  $af = $Attack
  if (-not $af) {
    $best = 0
    foreach ($f in @(Get-ChildItem $dir -Filter '*criticus-r*.md' -ErrorAction SilentlyContinue) + @(Get-ChildItem $dir -Filter '*attack-r*.md' -ErrorAction SilentlyContinue)) {
      if ($f.Name -match '^(?:[A-Za-z0-9_-]+-)?(?:criticus|attack)-r(\d+)\.md$' -and [int]$Matches[1] -gt $best) { $best = [int]$Matches[1]; $af = $f.FullName }
    }
  }
  if (-not $af) { Write-Host "FAIL [cite] no <id>-criticus-r<N>.md or attack-r<N>.md found; pass -Attack <file>"; exit 1 }
  if (-not [System.IO.Path]::IsPathRooted($af)) { $af = Join-Path $Root $af }
  if (-not (Test-Path -LiteralPath $af)) { Write-Host "FAIL [cite] file not found: $af"; exit 1 }
  $checked = 0; $head = '(before the first heading)'
  foreach ($ln in (Get-Content -LiteralPath $af -Encoding UTF8)) {
    if ($ln -match '^\s*#+\s+(.+)$') { $head = $Matches[1].Trim(); if ($head.Length -gt 70) { $head = $head.Substring(0, 70) } }
    $checked += Check-RefsIn $ln $head
  }
  foreach ($e in $errors) { Write-Host "ERROR $e" }
  Write-Host "INFO cite checked=$checked"
  if ($errors.Count -eq 0) { Write-Host "PASS cite errors=0"; exit 0 }
  Write-Host "FAIL cite errors=$($errors.Count)"; exit 1
}

if ($Slim) {
  # Only moves narrative sections whose heading is EXACTLY one of these. Contract sections
  # (Problem Statement / Requirement / impact analysis ...) are never touched.
  # Non-ASCII titles are written as \u escapes so the script stays encoding-safe on Windows PowerShell 5.1.
  $titles = 'Background|Alternatives|Design Philosophy|Philosophy|\u80CC\u666F|\u66FF\u4EE3\u65B9\u6848|\u8A2D\u8A08\u54F2\u5B78'
  $noteRe = '^> \[!NOTE\] Background and design rationale preserved'
  $out = New-Object System.Collections.ArrayList
  $moved = New-Object System.Collections.ArrayList
  $i = 0
  while ($i -lt $lines.Count) {
    if ($lines[$i] -match "^(#{2,3})\s+(\d+[\.\)]?\s*)?($titles)\s*$") {
      $level = $Matches[1].Length
      $j = $i + 1
      while ($j -lt $lines.Count -and $lines[$j] -notmatch "^#{1,$level}\s") { $j++ }
      # idempotency: skip sections that are empty or already reduced to the NOTE pointer
      $body = @(); for ($k = $i + 1; $k -lt $j; $k++) { if ($lines[$k].Trim()) { $body += $lines[$k] } }
      if ($body.Count -eq 0 -or ($body.Count -eq 1 -and $body[0] -match $noteRe)) {
        for ($k = $i; $k -lt $j; $k++) { [void]$out.Add($lines[$k]) }
        $i = $j; continue
      }
      for ($k = $i; $k -lt $j; $k++) { [void]$moved.Add($lines[$k]) }
      [void]$out.Add($lines[$i])
      [void]$out.Add('> [!NOTE] Background and design rationale preserved in [rationale.md](rationale.md).')
      [void]$out.Add('')
      $i = $j
    } else { [void]$out.Add($lines[$i]); $i++ }
  }
  if ($moved.Count -gt 0) {
    $ratPath = Join-Path $dir 'rationale.md'
    $prev = if (Test-Path $ratPath) { Get-Content $ratPath -Raw -Encoding UTF8 } else { '' }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ratPath, $prev + ($moved -join "`r`n") + "`r`n", $utf8)
    [System.IO.File]::WriteAllText($Plan, ($out -join "`r`n"), $utf8)
    Write-Host "INFO slimmed: moved $($moved.Count) line(s) to rationale.md"
  } else { Write-Host "INFO slim: nothing to move" }
  exit 0
}

function Get-Section([string]$pattern) {
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^(#{2,3})\s.*($pattern)") {
      $level = $Matches[1].Length
      $buf = New-Object System.Collections.ArrayList
      for ($j = $i + 1; $j -lt $lines.Count; $j++) {
        if ($lines[$j] -match "^#{1,$level}\s") { break }
        [void]$buf.Add($lines[$j])
      }
      return ($buf -join "`n")
    }
  }
  return $null
}

if ($Deliver -and $Gate -ne 'post') { Err "[gate] -Deliver requires -Gate post" }

# ---------- 1. Frontmatter ----------
$fm = @{}
if ($text -match '(?s)^\s*---\s*\r?\n(.*?)\r?\n---') {
  $head = $Matches[1]
  foreach ($k in 'status', 'feature', 'round', 'verdict', 'open_accepted_items', 'ar_waiver') {
    if ($head -match "(?m)^\s*$k\s*:\s*(.+?)\s*$") { $fm[$k] = $Matches[1] }
  }
} else { Err "[frontmatter] YAML header missing" }
foreach ($k in 'status', 'feature', 'round', 'open_accepted_items') {
  if (-not $fm.ContainsKey($k)) { Err "[frontmatter] field missing: $k" }
}
if ($fm.ContainsKey('status') -and $fm['status'] -notmatch '^(draft|ar-done|approved|delivered)$') {
  Err "[frontmatter] invalid status: $($fm['status']). Legal: draft | ar-done (set by /ar-judge) | approved (set by the human) | delivered (set by this script only)"
}

# ---------- 2. Required sections ----------
$req = [ordered]@{
  'requirement' = 'Requirement'
  'symbols'    = 'Blast Radius|Modified Symbols'
  'out-of-scope' = 'Out of Scope'
  'test-seams' = 'Test Seams'
  'regression' = 'Regression'
  'docs-sync'  = 'Docs Sync'
}
foreach ($k in @($req.Keys)) { if ($Aliases[$k]) { $req[$k] = $req[$k] + '|' + $Aliases[$k] } }
foreach ($k in $req.Keys) {
  if ($null -eq (Get-Section $req[$k])) { Err "[section] missing: $k (heading must match /$($req[$k])/)" }
}

$chkFiles = 0; $chkDocs = 0
# ---------- 3. Symbol existence ----------
$symText = Get-Section $req['symbols']
if ($symText) {
  foreach ($ln in ($symText -split "`n")) {
    if ($ln -cmatch 'NEW|MOVE|\[(new|add|create)\]' -or ($Aliases['new-marker'] -and $ln -match $Aliases['new-marker'])) { continue }
    foreach ($m in [regex]::Matches($ln, '`([^`]+)`')) {   # every backticked token on the line
      $segs  = $m.Groups[1].Value -split '>'
      $first = ($segs[0] -split '&')[0].Trim()
      if ($first -notmatch '^[^\s:]+\.(cs|cshtml|json|ps1|md|yaml|yml|csproj|ts|tsx|js|py)$' -or $first -notmatch '[/\\]') { continue }
      $full = Join-Path $Root ($first -replace '/', '\')
      if (-not (Test-Path $full)) { Err "[symbol] file not found: $first"; continue }
      $chkFiles++
      if ($segs.Count -lt 2) { continue }
      $content = Get-Content $full -Raw -Encoding UTF8
      $d = Split-Path $full -Parent
      foreach ($extra in ($segs[0] -split '&' | Select-Object -Skip 1)) {
        $p = Join-Path $d $extra.Trim()
        if (Test-Path $p) { $content += "`n" + (Get-Content $p -Raw -Encoding UTF8) }
      }
      $cls = @([regex]::Matches($segs[1], '[A-Z][a-z][A-Za-z0-9_]{2,}') | ForEach-Object { $_.Value })
      if ($cls.Count -gt 0 -and -not ($cls | Where-Object { $content -match "\b$_\b" })) {
        Warn "[symbol] type not found in ${first}: $($cls -join ', ')"
      }
      if ($segs.Count -ge 3) {
        foreach ($mm in [regex]::Matches($segs[2], '[A-Z][a-z][A-Za-z0-9_]{2,}')) {
          if ($content -notmatch "\b$($mm.Value)\b") { Warn "[symbol] member not found in ${first}: $($mm.Value)" }
        }
      }
    }
  }
}

# ---------- 4. Docs sync map (triggered by symbols section) ----------
$scope = if ($symText) { $symText } else { $text }
$T3 = if ($cfg.Tier3When) { $cfg.Tier3When } else { '' }
if ($T3 -and $scope -match $T3) { Write-Host "INFO tier-floor=3 matched=$($Matches[0])" } else { Write-Host "INFO tier-floor=1" }
$docs = Get-Section $req['docs-sync']
if ($docs) { $docs = $docs -replace '\\', '/' }
if ($docs) {
  foreach ($m in [regex]::Matches($docs, 'docs/[^\s`''"|<>*?(),;:\uFF08\uFF09\uFF0C\u3002\u3001\uFF1B\uFF1A]+')) {
    # trim trailing punctuation (ASCII + fullwidth, written as \u escapes for PS 5.1 encoding safety)
    $p = $m.Value -replace '[\uFF0C\u3002\u3001\uFF1B\uFF1A\uFF09),.;]+$', ''
    $chkDocs++
    if (-not (Test-Path -LiteralPath (Join-Path $Root ($p -replace '/', '\')))) { Err "[docs-path] not found: $p (must be a real file or folder, not a prefix)" }
  }
  foreach ($pat in $DocMap.Keys) {
    if ($scope -match $pat -and $docs -notmatch [regex]::Escape($DocMap[$pat])) {
      Err "[docs-sync] symbols match /$pat/ but docs-sync lacks $($DocMap[$pat])"
    }
  }
  foreach ($a in $AlwaysDocs) {
    if ($docs -notmatch [regex]::Escape($a)) { Err "[docs-sync] always-required entry missing: $a" }
  }
}

# ---------- 5. Gate tests ----------
foreach ($g in $Gates) {
  if ($scope -match $g.When -and $text -notmatch [regex]::Escape($g.Require)) {
    $msg = "[gate] symbols match /$($g.When)/ but plan never names $($g.Require)"
    if ($g.Level -eq 'Warn') { Warn $msg } else { Err $msg }
  }
}

# ---------- 6. State machine ----------
$maxN = 0; $verdictFile = ''
foreach ($v in @(Get-ChildItem $dir -Filter '*censo-r*.md' -ErrorAction SilentlyContinue) + @(Get-ChildItem $dir -Filter '*verdict-r*.md' -ErrorAction SilentlyContinue)) {
  if ($v.Name -match '^(?:[A-Za-z0-9_-]+-)?(?:censo|verdict)-r(\d+)\.md$' -and [int]$Matches[1] -gt $maxN) { $maxN = [int]$Matches[1]; $verdictFile = $v.FullName }
}
foreach ($f in @(Get-ChildItem $dir -Filter '*.md' -ErrorAction SilentlyContinue)) {
  if ($f.Name -match '(?i)(judge|verdict|censo)' -and $f.Name -notmatch '^(?:[A-Za-z0-9_-]+-)?(?:censo|verdict)-r\d+\.md$') {
    Err "[state] unexpected file name $($f.Name); the verdict file is named <id>-censo-r<N>.md (or verdict-r<N>.md)"
  }
}
$verdictText = ''
if ($maxN -ge 1 -and $verdictFile) { $verdictText = Get-Content $verdictFile -Raw -Encoding UTF8 }
if ($fm['round'] -match '^\d+$' -and $maxN -ne [int]$fm['round']) {
  Err "[state] round=$($fm['round']) but latest verdict is r$maxN"
}
if ($fm['status'] -eq 'delivered' -and $fm['open_accepted_items'] -match '^\d+$' -and [int]$fm['open_accepted_items'] -ne 0) {
  Err "[state] status=delivered but open_accepted_items=$($fm['open_accepted_items'])"
}
if ($fm['status'] -match '^(ar-done|approved|delivered)$' -and $maxN -eq 0) {
  Warn "[state] status=$($fm['status']) but no <id>-censo-r*.md"
}
# verdict: must be the path of a real verdict file (never a word such as "accepted")
if ($fm.ContainsKey('verdict') -and $fm['verdict'] -notmatch '^(null|~)?$') {
  $vp = $fm['verdict'].Trim().Trim('"').Trim("'")
  if (-not (Test-Path -LiteralPath (Join-Path $Root ($vp -replace '/', '\')))) { Err "[state] verdict path not found: $vp (must be the <id>-censo-r<N>.md file)" }
}
# open_accepted_items is computed, not declared: accepted remedies without a (Remedy N.k) tag in plan.md
$remIds = @()
if ($verdictText) {
  foreach ($m in [regex]::Matches($verdictText, '\[Remedy\s+([^\]]*)\]')) {
    if ($m.Groups[1].Value.Trim() -notmatch '^[1-9]\d*\.[1-9]\d*$') {
      Err "[remedy-id] malformed '[Remedy $($m.Groups[1].Value)]' in r$maxN; use [Remedy <round>.<k>] without leading zeros (1.1, 1.10)"
    }
  }
  $remIds = @([regex]::Matches($verdictText, '\[Remedy\s+(\d+\.\d+)\]') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
}
$missing = @($remIds | Where-Object { $text -notmatch ('Remedy\s+' + [regex]::Escape($_) + '(?!\d)') })
if ($remIds.Count -gt 0) {
  Write-Host "INFO open_accepted_items computed=$($missing.Count) accepted=$($remIds.Count)"
  if ($fm['open_accepted_items'] -match '^\d+$' -and [int]$fm['open_accepted_items'] -ne $missing.Count) {
    Err "[state] open_accepted_items=$($fm['open_accepted_items']) but computed $($missing.Count); remedies missing a (Remedy N.k) tag in plan.md: $($missing -join ', ')"
  }
}
# Round 2: an accepted Blocker needs a follow-up round (or a human-written ar_waiver)
if ($verdictText) {
  $hasNext = (@(Get-ChildItem $dir -Filter "*criticus-r$($maxN + 1).md" -ErrorAction SilentlyContinue) + @(Get-ChildItem $dir -Filter "*attack-r$($maxN + 1).md" -ErrorAction SilentlyContinue)).Count -gt 0
  if ($verdictText -match 'Blocker\*{0,2}\s*[:\uFF1A]\s*([1-9]\d*)' -and -not $hasNext) {
    $msg = "[state] censo-r$maxN accepted $($Matches[1]) Blocker(s); no round $($maxN + 1)"
    $strict = ($fm['status'] -match '^(approved|delivered)$') -or ($Gate -ne '')
    if ($strict -and -not $fm['ar_waiver']) {
      Err "$msg (run the follow-up review, or have the human set frontmatter ar_waiver: <reason>)"
    } else { Warn $msg }
  }
}
# judge independence and calibration
$judgeCtx = ''; $judgeVia = ''
if ($verdictText) {
  if ($verdictText -match '(?m)^\s*Judge\s*:\s*model=(\S+)\s+context=(fresh|inherited)(?:\s+via=(internal|external))?') { $judgeCtx = $Matches[2]; $judgeVia = $Matches[3] }
  else { Warn "[judge] verdict-r$maxN lacks a 'Judge: model=<id> context=fresh|inherited via=internal|external' line" }
  if ($judgeCtx -and -not $judgeVia) { Warn "[judge] verdict-r$maxN does not say via=internal|external; an internal judge shares the attackers' model and is held to the stricter calibration rule" }
  $recv = $null; $dism = $null
  if ($verdictText -match 'Received Findings\*{0,2}\s*[:\uFF1A]\s*(\d+)') { $recv = [int]$Matches[1] }
  if ($verdictText -match 'Dismissed Findings\*{0,2}\s*[:\uFF1A]\s*(\d+)') { $dism = [int]$Matches[1] }
  $hasWeak = ($verdictText -match '(?m)^\s*[-*]?\s*Weakest-3\s*:\s*\S')
  if ($null -ne $recv -and $null -ne $dism -and $dism -eq 0) {
    if ($judgeVia -eq 'external') {
      if ($recv -ge 10 -and -not $hasWeak) { Warn "[calibration] verdict-r$maxN accepted all $recv findings (0 dismissed); re-check the weakest ones against the Anti-Over-Engineering filter and add a 'Weakest-3:' line" }
    }
    elseif ($recv -ge 6 -and -not $hasWeak) {
      Err "[calibration] verdict-r$maxN (internal judge, same model as the attackers) accepted all $recv findings; re-check the three weakest against the Anti-Over-Engineering filter and add 'Weakest-3: <ID>, <ID>, <ID> - why they still stand' to section 1"
    }
  }
  # every cited path:line must exist; a Type (a) dismissal must cite one
  $sec3 = $false; $curId = ''; $curA = $false
  foreach ($vl in ($verdictText -split "`r?`n")) {
    if ($vl -match '^#{2,4}\s*3[\.\)]?\s') { $sec3 = $true; continue }
    if ($vl -match '^#{2,4}\s*4[\.\)]?\s') { $sec3 = $false }
    if ($vl -match '(?i)(Verified Evidence|Dismissal Evidence)\s*:') {
      $n = 0
      foreach ($m in [regex]::Matches($vl, $script:RefRe)) {
        $n++
        $why = Test-PathLine $m.Groups[1].Value ([int]$m.Groups[2].Value)
        if ($why) { Err "[verdict-cite] verdict-r$($maxN): $why" }
      }
      if ($sec3 -and $curA -and $n -eq 0) { Err "[verdict-cite] verdict-r$($maxN): dismissal $curId is Type (a) (factual error or guard exists) but cites no path:line" }
    }
    if ($sec3) {
      if ($vl -match '^\s*\d+\.\s+\*{0,2}\[([A-Z]-\d+)\]') { $curId = $Matches[1]; $curA = $false }
      if ($vl -match '(?i)Dismissal Type\s*:\s*\(?a\)?') { $curA = $true }
    }
  }
}

# ---------- 7. Size ----------
if ($text.Length -gt $MaxPlanChars) { Warn "[size] $($text.Length) chars > $MaxPlanChars; move rationale out" }
$long = @($lines | Where-Object { $_.Length -gt $MaxLineChars }).Count
if ($long -gt 0) { Warn "[size] $long line(s) > $MaxLineChars chars; one symbol per line" }

# ---------- 8. Gate map (MAP entry) ----------
if ($Gate -eq 'map') {
  if ($fm['status'] -notmatch '^(ar-done|approved)$') { Err "[gate] status=$($fm['status']); MAP needs ar-done or approved" }
  if ($fm['status'] -eq 'ar-done' -and $fm['open_accepted_items'] -ne '0') { Err "[gate] ar-done needs open_accepted_items=0 (now $($fm['open_accepted_items']))" }
  if ($judgeCtx -eq 'inherited' -and -not $fm['ar_waiver']) {
    Err "[judge] verdict-r$maxN was ruled in an inherited context; rerun /ar-judge in a fresh window, or have the human set ar_waiver: <reason>"
  }
  $dirty = Run-Git @('status', '--porcelain', '--untracked-files=all')
  if ($null -eq $dirty) { Write-Host "INFO git unavailable; working-tree check skipped" }
  else {
    $dirty = @($dirty | Where-Object { $_ -notmatch '^.{2}\s+"?\.scratch/' })
    if ($dirty.Count -gt 0) {
      Err "[gate] working tree is not clean ($($dirty.Count) path(s); first: $((@($dirty | Select-Object -First 5)) -join '; ')); commit or stash everything, the spec folder included, before MAP"
    }
  }
}

# ---------- 8b. Gate ticket (one ticket's uncommitted change) ----------
if ($Gate -eq 'ticket') {
  $feature = $fm['feature']
  if ($fm['status'] -notmatch '^(ar-done|approved)$') { Err "[gate] status=$($fm['status']); tickets need ar-done or approved" }
  if (-not $Ticket) { Err "[gate] -Ticket <NN> is required with -Gate ticket" }
  else {
    $tf = @(Get-ChildItem (Join-Path $Root ".scratch\$feature\issues") -Filter "$Ticket-*.md" -ErrorAction SilentlyContinue)
    if ($tf.Count -ne 1) { Err "[ticket] expected exactly one .scratch/$feature/issues/$Ticket-*.md, found $($tf.Count)" }
    else {
      $tt = Get-Content $tf[0].FullName -Raw -Encoding UTF8
      Check-Ticket $tt $Ticket
      $st = Run-Git @('status', '--porcelain', '--untracked-files=all')
      if ($null -eq $st) { Err "[gate] cannot read git status" }
      else {
        $changed = @()
        foreach ($l in $st) {
          if ($l.Length -lt 4) { continue }
          $p = $l.Substring(3)
          if ($p -match ' -> ') { $p = ($p -split ' -> ')[-1] }
          $p = $p.Trim().Trim('"')
          if ($p -notmatch '^\.scratch/') { $changed += $p }
        }
        if ($changed.Count -eq 0) { Err "[ticket] no uncommitted changes to check for ticket $Ticket" }
        else {
          [void](Check-Files $changed 'working tree' $tt $Ticket 'ticket')
          Check-Size $changed $tt $Ticket
          Check-Encoding $changed
          Check-TestEdits $changed $tt $Ticket
        }
      }
    }
  }
}

# ---------- 9. Gate post (delivery) ----------
if ($Gate -eq 'post') {
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
  $feature = $fm['feature']
  if (-not $Base) { Err "[gate] -Base <sha> is required with -Gate post (use HEAD_AT_MAP_START)" }
  if ($fm['status'] -notmatch '^(ar-done|approved|delivered)$') { Err "[gate] status=$($fm['status']) is not deliverable" }

  # 9a. every ticket is well formed and carries red and green evidence
  $scratch = Join-Path $Root ".scratch\$feature"
  $ev = Join-Path $scratch 'evidence'
  $tickets = @(Get-ChildItem (Join-Path $scratch 'issues') -Filter '*.md' -ErrorAction SilentlyContinue)
  if ($tickets.Count -eq 0) { Err "[evidence] no tickets found under .scratch/$feature/issues" }
  foreach ($t in $tickets) {
    $nn = ($t.Name -split '-')[0]
    $tt = Get-Content $t.FullName -Raw -Encoding UTF8
    $script:ticketTexts[$nn] = $tt
    Check-Ticket $tt $nn
    if (-not (Test-Path (Join-Path $ev "$nn-green.log"))) { Err "[evidence] ticket $nn has no green log" }
    if (-not (Test-Path (Join-Path $ev "$nn-red.log")) -and $tt -notmatch '(?mi)^\s*Red test:\s*n/a\s*-\s*\S') {
      Err "[evidence] ticket $nn has no red log (or 'Red test: n/a - <reason>' in the ticket)"
    }
  }

  # 9a-2. state log: one line per ticket with proof of reading (path:line must exist)
  $statePath0 = Join-Path $scratch 'state.md'
  $stateText0 = ''
  if (Test-Path $statePath0) { $stateText0 = Get-Content $statePath0 -Raw -Encoding UTF8 }
  foreach ($nn in @($script:ticketTexts.Keys | Sort-Object)) {
    $m = [regex]::Match($stateText0, ('(?m)^\s*[-*]?\s*' + [regex]::Escape($nn) + '\s*\|(.*)$'))
    if (-not $m.Success) { Err "[state-log] state.md has no line for ticket $nn (format: '- $nn | <sha> | tests=<n> | read: <path:line, ...> | tests-changed: <...> | <notes>')"; continue }
    if ($script:ticketTexts[$nn] -match '(?mi)^\s*Red test:\s*n/a\s*-\s*\S') { continue }
    $rd = [regex]::Match($m.Groups[1].Value, '(?i)read\s*:\s*([^|]+)')
    if (-not $rd.Success -or -not [regex]::IsMatch($rd.Groups[1].Value, $script:RefRe)) { Err "[read] ticket $nn has no 'read: <path:line, ...>' on its state.md line (list what the Developer opened before editing)"; continue }
    foreach ($rm in [regex]::Matches($rd.Groups[1].Value, $script:RefRe)) {
      $why = Test-PathLine $rm.Groups[1].Value ([int]$rm.Groups[2].Value)
      if ($why) { Err "[read] ticket $($nn): read proof $why" }
    }
  }

  # 9b. review rounds: every finding has a disposition; the last round applied no fixes
  $rvFiles = @(@(Get-ChildItem $dir -Filter '*custos-r*.md' -ErrorAction SilentlyContinue) + @(Get-ChildItem $dir -Filter 'review-r*.md' -ErrorAction SilentlyContinue) |
    Where-Object { $_.Name -match '^(?:[A-Za-z0-9_-]+-)?(?:custos|review)-r(\d+)\.md$' } | Sort-Object { [int]([regex]::Match($_.Name, '-r(\d+)\.md$').Groups[1].Value) })
  if ($rvFiles.Count -eq 0) { Err "[review] no <id>-custos-r<N>.md or review-r<N>.md in docs/specs/$feature" }
  $known = ''
  $kp = Join-Path $Root 'docs\specs\known-open.md'
  if (Test-Path $kp) { $known = Get-Content $kp -Raw -Encoding UTF8 }
  $lastName = ''; $lastFixed = 0
  foreach ($rf in $rvFiles) {
    $rt = Get-Content $rf.FullName -Raw -Encoding UTF8
    $lastName = $rf.Name; $lastFixed = 0
    if ($rt -notmatch '(?m)^#+\s*Standards' -or $rt -notmatch '(?m)^#+\s*Spec') { Err "[review] $($rf.Name) needs both a Standards and a Spec section" }
    $dm = [regex]::Match($rt, '(?m)^#+\s*Disposition')
    if (-not $dm.Success) { Err "[review] $($rf.Name) has no '## Disposition' section"; continue }
    if ($rt -match '(?m)^\s*Reviewer\s*:\s*model=(\S+)\s+developer=(\S+)\s+mode=(internal|external)') {
      $hasT3 = @($script:ticketTexts.Values | Where-Object { (Get-Field $_ 'Tier') -eq '3' }).Count -gt 0
      if ($Matches[3] -eq 'internal' -and $hasT3) { Warn "[review] $($rf.Name): a Tier 3 ticket was reviewed internally by the same model that wrote it; review Tier 3 externally (Argon) with the review prompt" }
    } else { Warn "[review] $($rf.Name) lacks a 'Reviewer: model=<id> developer=<id> mode=internal|external' line" }
    $body = $rt.Substring(0, $dm.Index); $disp = $rt.Substring($dm.Index)
    $ids = @([regex]::Matches($body, '\[Finding\s+(\d+\.\d+)\]') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $rows = @{}
    foreach ($ln in ($disp -split "`r?`n")) {
      if ($ln -match '^\s*\|\s*\[?Finding\s+(\d+\.\d+)\]?\s*\|\s*([A-Za-z]+)\s*\|\s*(fixed|deferred|rejected)\s*\|\s*(.+?)\s*\|?\s*$') {
        $rows[$Matches[1]] = @{ Level = $Matches[2]; Action = $Matches[3]; Ref = $Matches[4] }
      }
    }
    $noRow = @($ids | Where-Object { -not $rows.ContainsKey($_) })
    if ($noRow.Count -gt 0) { Err "[review] $($rf.Name): findings without a disposition row: $($noRow -join ', ')" }
    $extra = @($rows.Keys | Where-Object { $ids -notcontains $_ })
    if ($extra.Count -gt 0) { Err "[review] $($rf.Name): disposition rows for unknown findings: $($extra -join ', ')" }
    foreach ($k in $rows.Keys) {
      $r = $rows[$k]
      if ($r.Level -notmatch '^(Hard|Smell|Missing|Scope|Blemish)$') { Err "[review] $($rf.Name) [Finding $k]: Level must be Hard, Smell, Missing, Scope or Blemish" }
      if ($r.Action -eq 'deferred') {
        if ($r.Level -match '^(Hard|Missing|Scope)$') { Err "[review] $($rf.Name) [Finding $k]: a $($r.Level) finding must be fixed or rejected, never deferred" }
        if ($r.Ref -notmatch '(K-\d+)') { Err "[review] $($rf.Name) [Finding $k]: deferred needs a K-<n> id from docs/specs/known-open.md" }
        elseif ($known -notmatch [regex]::Escape($Matches[1]) + '(?!\d)') { Err "[review] $($rf.Name) [Finding $k]: $($Matches[1]) is not listed in docs/specs/known-open.md" }
      }
      elseif ($r.Action -eq 'fixed') {
        $lastFixed++
        if ($r.Ref -notmatch '\b([0-9a-f]{7,40})\b') { Err "[review] $($rf.Name) [Finding $k]: fixed needs the fix commit SHA" }
        else {
          $ct = Run-Git @('cat-file', '-t', $Matches[1])
          if ($null -eq $ct -or $ct.Count -eq 0 -or $ct[0] -ne 'commit') { Err "[review] $($rf.Name) [Finding $k]: $($Matches[1]) is not a commit in this repo" }
        }
        if ($r.Ref -notmatch '(?i)sweep:\s*\S') { Err "[review] $($rf.Name) [Finding $k]: fixed needs 'sweep: <pattern> -> <n> hits' (same pattern searched across the change)" }
      }
      elseif ($r.Ref.Length -lt 12) { Err "[review] $($rf.Name) [Finding $k]: rejected needs a reason (cite path:line or a plan clause)" }
      else {
        $hasRef = [regex]::IsMatch($r.Ref, $script:RefRe)
        if (-not $hasRef -and $r.Ref -notmatch '(?i)plan|\u00A7|Remedy') { Err "[review] $($rf.Name) [Finding $k]: rejected must cite a real path:line or a plan clause, not only an opinion" }
        foreach ($m in [regex]::Matches($r.Ref, $script:RefRe)) {
          $why = Test-PathLine $m.Groups[1].Value ([int]$m.Groups[2].Value)
          if ($why) { Err "[review] $($rf.Name) [Finding $k]: rejected cites $why" }
        }
      }
    }
  }
  if ($lastName -and $lastFixed -gt 0) { Err "[review] $lastName applied $lastFixed fix(es) and no later round re-reviewed the fix diff; run the next review round" }

  # 9c. per-commit: ticket tag, docs sync, scope, edited tests
  if ($Base) {
    $commits = Run-Git @('rev-list', '--reverse', "$Base..HEAD")
    if ($null -eq $commits) { Err "[gate] cannot read git history for $Base..HEAD" }
    else {
      $statePath = Join-Path $scratch 'state.md'
      $stateText = ''
      if (Test-Path $statePath) { $stateText = Get-Content $statePath -Raw -Encoding UTF8 }
      foreach ($c in $commits) {
        $short = $c.Substring(0, [Math]::Min(7, $c.Length))
        $subject = (Run-Git @('log', '-1', '--format=%s', $c)) -join ' '
        $files = Run-Git @('show', '--name-only', '--no-renames', '--pretty=format:', $c)
        $files = @($files | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.Trim() })
        $kind = ''; $nn = ''; $ttext = ''
        if ($subject -match '\[(\d+)\]\s*$') {
          $kind = 'ticket'; $nn = $Matches[1]
          if ($script:ticketTexts.ContainsKey($nn)) { $ttext = $script:ticketTexts[$nn] }
          else { Err "[commit] commit $short names ticket [$nn], which does not exist" }
        }
        elseif ($subject -match '\[review-r\d+\]\s*$') { $kind = 'review' }
        $res = Check-Files $files "commit $short" $ttext $nn $kind
        if ($res.Work -and -not $kind) { Err "[commit] commit $short has no [<NN>] ticket tag or [review-r<N>] tag at the end of its subject" }
        $num = Run-Git @('show', '--numstat', '--no-renames', '--pretty=format:', $c)
        foreach ($l in @($num)) {
          if ($l -match '^(\d+)\s+(\d+)\s+(.+)$' -and [int]$Matches[2] -gt 0 -and (Match-Any $Matches[3] $TestRes)) {
            if ($stateText -notmatch ('(?mi)' + [regex]::Escape($short) + '.*tests-changed') -and -not ($ttext -and (Test-TestMayChange $ttext))) {
              $tm = "[tests] commit $short edits existing test code in $($Matches[3]) ($($Matches[2]) line(s) removed); declare 'Tests-may-change:' in the ticket, and record 'tests-changed: <what and why>' on its line in state.md"
              if ($TestEditLevel -eq 'Warn') { Warn $tm } else { Err $tm }
            }
          }
        }
      }
    }
  }

  # 9d. retro inputs
  if (-not (Test-Path (Join-Path $dir 'metrics.json'))) { Warn "[metrics] docs/specs/$feature/metrics.json is missing (run measure-tokens.ps1 -Output)" }
  if (-not (Test-Path (Join-Path $dir 'retro-input.md'))) { Warn "[retro] docs/specs/$feature/retro-input.md is missing (MAP Stage 4 writes it for /retro)" }
}

# ---------- Output ----------
if ($Gate -eq 'map') {
  if ($errors.Count -eq 0) { Write-Host "INFO fast-track=eligible status=$($fm['status'])" } else { Write-Host "INFO fast-track=blocked" }
}
foreach ($e in $errors) { Write-Host "ERROR $e" }
foreach ($w in $warns)  { Write-Host "WARN $w" }
Write-Host "INFO checked file-paths=$chkFiles docs-paths=$chkDocs"
if ($errors.Count -eq 0) {
  if ($Deliver -and $Gate -eq 'post') {
    $rx = New-Object System.Text.RegularExpressions.Regex('(?m)^(\s*status\s*:\s*)[^\r\n]+')
    $new = $rx.Replace($text, '${1}delivered', 1)
    [System.IO.File]::WriteAllText($Plan, $new, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "INFO status set to delivered"
  }
  Write-Host "PASS errors=0 warns=$($warns.Count)"; exit 0
}
Write-Host "FAIL errors=$($errors.Count) warns=$($warns.Count)"; exit 1
