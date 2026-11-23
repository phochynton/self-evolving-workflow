# Codex SOP — Verbatim Full-Code Bundle

## Purpose
Create `{Name}.Related-Code_Full_Dump.MD` for external planning (`libra`) or external review (`criticus`).

## Steps

### 1. Set Bundle `{Name}` and File List
1. Choose `{Name}` from the reference doc name or feature slug (e.g., `2026-11-23_auth-plan` or `criticus-r1`).
2. Prepare the input source:
   - **From a doc** (`-FromDoc`): pass a Markdown file containing backticked file paths.
   - **From a list** (`-ListFile`): write relative paths (one per line, `#` for comments) to `.scratch/<feature>/{Name}.files.txt`.
3. **Done when**: `{Name}` and `-FromDoc` or `-ListFile` are ready.

### 2. Run `dump_related_code.ps1`
1. Run:
   ```powershell
   pwsh -NoProfile -File scripts/dump_related_code.ps1 -Name "<Name>" -ListFile "<list>" -OutDir ".scratch/<feature>"
   ```
   (or pass `-FromDoc "<doc>"`).
2. Do **not** read or open the resulting `.Related-Code_Full_Dump.MD`.
3. If exit code is non-zero (`1` empty list, `2` missing files, `3` check failed), fix the list and re-run.
4. **Done when**: Script exits `0` and prints `PASS: N files dumped and verified.`

### 3. Report Output
Return only:
- The script's `File / Lines` table
- Verification status and any skipped binary files
- Clickable link to `.scratch/<feature>/{Name}.Related-Code_Full_Dump.MD`
**Done when**: Bundle link is delivered without reading its contents.
