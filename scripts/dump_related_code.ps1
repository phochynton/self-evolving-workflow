param(
    [Parameter(Mandatory)][string]$Name,
    [string]$FromDoc,
    [string]$ListFile,
    [string]$OutDir
)
$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
if (-not $OutDir) { $OutDir = $root }
$safeName = ($Name -replace '[\\/:*?"<>|]', '_').Trim()
$out = Join-Path $OutDir "$safeName.Related-Code_Full_Dump.MD"

if (-not $FromDoc -and -not $ListFile) { Write-Host 'ERROR: Specify at least -FromDoc or -ListFile'; exit 1 }

$utf8NoBom  = New-Object System.Text.UTF8Encoding($false)
$strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
$bt = [string][char]96
$extPattern = 'cs|cshtml|razor|js|ts|tsx|jsx|css|scss|json|ps1|psm1|csproj|sln|props|targets|xml|config|md|sql|py|html|yml|yaml|txt|sh|bat|go|rs|java|kt|rb|php'
$langMap = @{ '.cs'='csharp'; '.cshtml'='html'; '.razor'='html'; '.js'='javascript'; '.ts'='typescript'; '.tsx'='tsx'; '.jsx'='jsx'
              '.css'='css'; '.scss'='scss'; '.json'='json'; '.ps1'='powershell'; '.psm1'='powershell'; '.csproj'='xml'; '.xml'='xml'
              '.md'='markdown'; '.sql'='sql'; '.py'='python'; '.html'='html'; '.yml'='yaml'; '.yaml'='yaml'; '.sh'='bash'
              '.go'='go'; '.rs'='rust'; '.java'='java'; '.kt'='kotlin'; '.rb'='ruby'; '.php'='php' }

function Read-Source([string]$p) {
    $bytes = [System.IO.File]::ReadAllBytes($p)
    if ($bytes -contains 0) { return $null }
    try   { return $strictUtf8.GetString($bytes).TrimStart([char]0xFEFF) }
    catch { return [System.Text.Encoding]::Default.GetString($bytes) }
}

$paths = New-Object System.Collections.Generic.List[string]
if ($ListFile) {
    if (-not (Test-Path $ListFile)) { Write-Host "ERROR: ListFile not found: $ListFile"; exit 1 }
    Get-Content $ListFile -Encoding UTF8 | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { $paths.Add($_) }
}
if ($FromDoc) {
    if (-not (Test-Path $FromDoc)) { Write-Host "ERROR: FromDoc not found: $FromDoc"; exit 1 }
    $docText = Read-Source (Resolve-Path $FromDoc).Path
    $rx = '`([^`\r\n*?|<>]+?\.(?:' + $extPattern + '))`'
    foreach ($m in [regex]::Matches($docText, $rx, 'IgnoreCase')) { $paths.Add($m.Groups[1].Value.Trim()) }
}

$selfNames = @()
if ($FromDoc) { $selfNames += [IO.Path]::GetFileName($FromDoc) }
$selfNames += [IO.Path]::GetFileName($out)
$tracked = $null
try { $tracked = @(git ls-files 2>$null) } catch { $tracked = @() }

$files = @()
$missing = @()
foreach ($p in ($paths | ForEach-Object { ($_ -replace '\\', '/').TrimStart('.', '/') } | Select-Object -Unique)) {
    if ($selfNames -contains [IO.Path]::GetFileName($p)) { continue }
    $full = Join-Path $root $p
    if (Test-Path -LiteralPath $full -PathType Leaf) { $files += $p; continue }
    $hit = @($tracked | Where-Object { $_ -eq $p -or $_.EndsWith("/$p") })
    if ($hit.Count -eq 1) { $files += $hit[0]; continue }
    $missing += $p
}
$files = @($files | Select-Object -Unique)
if (-not $files -and -not $missing) { Write-Host 'ERROR: File list is empty'; exit 1 }

$listOut = Join-Path $OutDir "$safeName.Related-Code_Files.txt"
[System.IO.File]::WriteAllText($listOut, (($files + ($missing | ForEach-Object { "# MISSING: $_" })) -join "`n"), $utf8NoBom)

$hash = ''
try { $hash = (git rev-parse HEAD 2>$null | Out-String).Trim() } catch { }

$report = @(); $skipped = @()
$writer = New-Object System.IO.StreamWriter($out, $false, $utf8NoBom)
try {
    $writer.WriteLine("# $Name - Related Code Full Dump")
    $writer.WriteLine('')
    if ($hash) { $writer.WriteLine("**Base Commit Hash**: $bt$hash$bt"); $writer.WriteLine('') }
    $writer.WriteLine('> [!IMPORTANT]')
    $writer.WriteLine('> Generated automatically by dump_related_code.ps1 (verbatim full source, no truncation).')
    $writer.WriteLine('')
    foreach ($rel in $files) {
        $full = Join-Path $root $rel
        $content = Read-Source $full
        if ($null -eq $content) { $skipped += $rel; $writer.WriteLine("<!-- Binary file skipped: $rel -->"); continue }
        $maxRun = 0
        foreach ($m in [regex]::Matches($content, '`+')) { if ($m.Length -gt $maxRun) { $maxRun = $m.Length } }
        $fence = $bt * ([Math]::Max(4, $maxRun + 1))
        $ext  = [IO.Path]::GetExtension($rel).ToLower()
        $lang = if ($langMap.ContainsKey($ext)) { $langMap[$ext] } else { '' }
        $writer.WriteLine("## File: $bt$rel$bt")
        $writer.WriteLine('')
        $writer.WriteLine($fence + $lang)
        $writer.WriteLine('// ==========================================')
        $writer.WriteLine("// FILE: $rel")
        $writer.WriteLine('// ==========================================')
        $writer.WriteLine($content)
        $writer.WriteLine($fence)
        $writer.WriteLine('')
        $report += [pscustomobject]@{ File = $rel; Lines = ($content -split "`r?`n").Count; Content = $content }
    }
    foreach ($rel in $missing) { $writer.WriteLine("<!-- Missing file: $rel -->") }
} finally { $writer.Dispose() }

$all  = [System.IO.File]::ReadAllText($out, $utf8NoBom)
$fail = @($report | Where-Object { -not $all.Contains($_.Content) } | ForEach-Object { $_.File })

$report | Select-Object File, Lines | Format-Table -AutoSize
if ($hash) { Write-Host "Commit: $hash" }
Write-Host "Output: $(([Uri]$out).AbsoluteUri)"
Write-Host "FileList: $(([Uri]$listOut).AbsoluteUri)"
if ($skipped.Count -gt 0) { Write-Host "WARN: Skipped binary files: $($skipped -join ', ')" }
if ($missing.Count -gt 0) { Write-Host "ERROR: Missing files: $($missing -join ', ')"; exit 2 }
if ($fail.Count -gt 0)    { Write-Host "ERROR: Verbatim check failed: $($fail -join ', ')"; exit 3 }
Write-Host "PASS: $($report.Count) files dumped and verified."
