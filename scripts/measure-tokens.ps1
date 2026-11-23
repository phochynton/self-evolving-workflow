<#
.SYNOPSIS
  Measures token use from transcript.jsonl (PLANNER_RESPONSE turns): totals, cache metrics,
  cold-cache turns, compaction events and a per-segment breakdown. Reports facts only, no savings claims.
.PARAMETER TranscriptPath  Main transcript. Default: newest transcript.jsonl under -BaseDir.
.PARAMETER SubagentPaths   Subagent transcripts; each is its own source and is added to the totals.
.PARAMETER Segment         "name=startStep-endStep" (main transcript only). Repeatable, e.g. 'ticket01=176-213'.
.PARAMETER Output          Write the metrics as JSON to this path (commit it as the next feature's baseline).
.PARAMETER ColdMinInput    A turn is "cold" when CacheRead=0, the previous turn had CacheRead>0 and Input >= this.
.PARAMETER TestPattern     Regex counted against each turn's tool calls (test runs).
.PARAMETER BuildPattern    Regex counted against each turn's tool calls (builds; a build is not a test).
Definitions
  HitRate    = CacheRead / (CacheRead + Input)  [%]
  Multiplier = CacheRead / Input                [x]  (not a hit rate)
  AvgContext = (Input + CacheRead) / Turns
  WarmInput  = Input of turns that are not cold or post-compaction (the real per-turn fresh input)
  ColdInput  = Input paid in full because the cache missed or the context was compacted
#>
[CmdletBinding()]
param(
  [string]$TranscriptPath,
  [string[]]$SubagentPaths = @(),
  [string[]]$Segment = @(),
  [string]$Output,
  [string]$BaseDir = (Join-Path $HOME '.gemini/antigravity/brain'),
  [long]$ColdMinInput = 20000,
  [string]$TestPattern = '(?i)(dotnet test|pytest|npm (run )?test|go test|cargo test)',
  [string]$BuildPattern = '(?i)dotnet build'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Prop($obj, [string]$name, $default) {
  if ($null -ne $obj -and $obj.PSObject.Properties[$name]) { return $obj.PSObject.Properties[$name].Value }
  return $default
}

function Read-Source([string]$Path, [string]$Label) {
  $turns = New-Object System.Collections.ArrayList
  $compactions = New-Object System.Collections.ArrayList
  $prevCache = 0L; $prevTime = $null; $afterCompaction = $false
  foreach ($line in [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)) {
    if ($line -match 'Resuming from a compaction') {
      try { [void]$compactions.Add([int](Get-Prop (ConvertFrom-Json $line) 'step_index' 0)) } catch { }
      $afterCompaction = $true
      continue
    }
    if ($line -notmatch '"type":"PLANNER_RESPONSE"') { continue }
    try { $j = ConvertFrom-Json $line } catch { continue }
    $inp   = [long](Get-Prop $j 'input_tokens' 0)
    $cache = [long](Get-Prop $j 'cache_read_tokens' 0)
    $outT  = [long](Get-Prop $j 'output_tokens' 0)
    $step  = [int](Get-Prop $j 'step_index' 0)
    $time  = $null; try { $time = [datetime](Get-Prop $j 'created_at' $null) } catch { }
    $calls = Get-Prop $j 'tool_calls' $null
    $names = ''; $callText = ''
    if ($calls) {
      $names = (@($calls | ForEach-Object { Get-Prop $_ 'name' '' }) -join ', ')
      $callText = ($calls | ConvertTo-Json -Depth 6 -Compress)
    }
    $kind = 'warm'
    if ($cache -eq 0 -and $afterCompaction) { $kind = 'compaction' }
    elseif ($cache -eq 0 -and $prevCache -gt 0 -and $inp -ge $ColdMinInput) { $kind = 'cold' }
    $gap = $null; if ($time -and $prevTime) { $gap = [int]($time - $prevTime).TotalSeconds }
    [void]$turns.Add([pscustomobject]@{
      Source = $Label; Step = $step; Input = $inp; CacheRead = $cache; Output = $outT; Kind = $kind; GapSec = $gap
      Tools = $names
      IsTest = [bool]($callText -match $TestPattern)
      IsBuild = [bool]($callText -match $BuildPattern)
      IsSubagent = [bool]($names -match 'invoke_subagent')
    })
    $prevCache = $cache; $prevTime = $time; $afterCompaction = $false
  }
  return [pscustomobject]@{ Label = $Label; Path = $Path; Turns = $turns; Compactions = $compactions }
}

function Summarize($turns, [string]$Name) {
  $t = @($turns)
  $n = $t.Count
  $in = 0L; $ca = 0L; $out = 0L; $coldIn = 0L; $coldN = 0
  foreach ($x in $t) {
    $in += $x.Input; $ca += $x.CacheRead; $out += $x.Output
    if ($x.Kind -ne 'warm') { $coldIn += $x.Input; $coldN++ }
  }
  $warmN = $n - $coldN
  [pscustomobject]@{
    Name = $Name; Turns = $n; Input = $in; CacheRead = $ca; Output = $out
    HitRatePct = $(if (($ca + $in) -gt 0) { [math]::Round(100.0 * $ca / ($ca + $in), 2) } else { 0 })
    Multiplier = $(if ($in -gt 0) { [math]::Round($ca / [double]$in, 2) } else { 0 })
    AvgContext = $(if ($n -gt 0) { [math]::Round(($in + $ca) / [double]$n, 0) } else { 0 })
    ColdTurns = $coldN; ColdInput = $coldIn; WarmInput = ($in - $coldIn)
    WarmInputPerTurn = $(if ($warmN -gt 0) { [math]::Round(($in - $coldIn) / [double]$warmN, 0) } else { 0 })
    TestRuns = @($t | Where-Object { $_.IsTest }).Count
    BuildRuns = @($t | Where-Object { $_.IsBuild }).Count
    SubagentCalls = @($t | Where-Object { $_.IsSubagent }).Count
  }
}

if (-not $TranscriptPath) {
  $c = @(Get-ChildItem -Path $BaseDir -Filter 'transcript.jsonl' -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
  if ($c.Count -eq 0) { Write-Error "No transcript.jsonl found in $BaseDir" }
  $TranscriptPath = $c[0].FullName
}
if (-not (Test-Path $TranscriptPath)) { Write-Error "Transcript file not found: $TranscriptPath" }

$sources = New-Object System.Collections.ArrayList
Write-Host "Analyzing transcript: $TranscriptPath" -ForegroundColor Cyan
[void]$sources.Add((Read-Source $TranscriptPath 'main'))
$k = 0
foreach ($p in $SubagentPaths) { $k++; [void]$sources.Add((Read-Source $p ("subagent" + $k))) }

$all = New-Object System.Collections.ArrayList
foreach ($s in $sources) { foreach ($x in $s.Turns) { [void]$all.Add($x) } }
if ($all.Count -eq 0) { Write-Host "No PLANNER_RESPONSE turns found in log." -ForegroundColor Yellow; exit 0 }

$total = Summarize $all 'total'
$perSource = @($sources | ForEach-Object { Summarize $_.Turns $_.Label })
$perSegment = @()
foreach ($seg in $Segment) {
  if ($seg -match '^(.+?)=(\d+)-(\d+)$') {
    $a = [int]$Matches[2]; $b = [int]$Matches[3]; $nm = $Matches[1]
    $perSegment += Summarize @($sources[0].Turns | Where-Object { $_.Step -ge $a -and $_.Step -le $b }) $nm
  } else { Write-Host "Ignoring segment '$seg' (use name=start-end)" -ForegroundColor Yellow }
}
$coldList = @($all | Where-Object { $_.Kind -ne 'warm' })

Write-Host "`n=== Totals (all sources) ===" -ForegroundColor Green
$total | Format-List Turns, Input, CacheRead, Output, HitRatePct, Multiplier, AvgContext, ColdTurns, ColdInput, WarmInput, WarmInputPerTurn, TestRuns, BuildRuns, SubagentCalls
Write-Host "=== Per source ===" -ForegroundColor Green
$perSource | Format-Table Name, Turns, Input, CacheRead, Output, HitRatePct, AvgContext, ColdInput -AutoSize
if ($perSegment.Count -gt 0) {
  Write-Host "=== Per segment (main transcript) ===" -ForegroundColor Green
  $perSegment | Format-Table Name, Turns, Input, WarmInput, ColdInput, AvgContext, Output, TestRuns, BuildRuns, SubagentCalls -AutoSize
}
Write-Host "=== Cold or post-compaction turns (Input paid in full) ===" -ForegroundColor Yellow
if ($coldList.Count -gt 0) { $coldList | Format-Table Source, Step, Kind, Input, GapSec -AutoSize } else { Write-Host "none" }
Write-Host "=== Compaction events (step index) ===" -ForegroundColor Yellow
foreach ($s in $sources) { if ($s.Compactions.Count -gt 0) { Write-Host ("{0}: {1}" -f $s.Label, ($s.Compactions -join ', ')) } }
Write-Host "=== Top 5 turns by Input ===" -ForegroundColor Cyan
$all | Sort-Object Input -Descending | Select-Object -First 5 | Format-Table Source, Step, Kind, Input, CacheRead, Output, Tools -AutoSize

if ($Output) {
  $obj = [ordered]@{
    transcript = $TranscriptPath
    total = $total; sources = $perSource; segments = $perSegment; coldTurns = $coldList
    compactions = @($sources | ForEach-Object { [ordered]@{ source = $_.Label; steps = @($_.Compactions) } })
  }
  [System.IO.File]::WriteAllText($Output, ($obj | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "Metrics written: $Output" -ForegroundColor Green
}
