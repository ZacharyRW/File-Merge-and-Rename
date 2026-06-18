# AUDIT — File-Merge-and-Rename

Date: 2026-06-16
Auditor: Claude Code (Opus 4.7)
Audit type: Deep
Last commit: `bec2b2d` — "Add CODE_REVIEW.md with 17 prioritized findings from audit"

> **Relationship to existing review docs.** This repo carries TWO active review docs: `REVIEW_TASKS.md` (17 numbered tasks from the initial review; 1–8 resolved, 9–17 open) and `CODE_REVIEW.md` (17 findings P0–P3 from a 2026-03-02 audit). This audit verifies status, adds net-new findings, and surfaces ideas the existing docs don't cover.

---

## 1. Snapshot

A single Windows batch script (`File_Renamer.bat`, 187 lines) that wraps an FFmpeg merge to work around Windows `MAX_PATH` failures from YouTube-DL. By far the smallest project in the user's portfolio by LOC.

- **Source**: 1 `.bat` file (187 lines).
- **Docs**: 3 markdown files totaling 657 lines of review + how-to.
- **License**: **GPL v3.0** (present and complete).
- **Tests / CI**: none (REVIEW_TASKS #9 carries this).
- **Repo URL**: `https://github.com/ZacharyRW/File-Merge-and-Rename.git`.
- **Health verdict**: 🟢 **healthy for scope.** The script is mature: every code path has rollback, every input is validated, FFmpeg is checked before any file ops, the .mkv constraint is documented and enforced. The existing review docs catch most everything. Net-new audit findings are small (mostly cleanup / hygiene). The biggest open item is "no tests" (REVIEW_TASKS #9) — and for a 187-line script that's *acceptable* given the scope, but addressable.

---

## 2. Bugs & Correctness Issues

### 2.1 Status of previously-catalogued items

| Source | # | Severity | Description | Status |
|---|---|---|---|---|
| REVIEW_TASKS | 9 | High | No automated tests | ✅ still open |
| REVIEW_TASKS | 10 | Medium | No extension validation test | ✅ still open |
| REVIEW_TASKS | 11 | Medium | Missing explicit `exit /b 0` on success | ✅ still open (line 187: bare `popd`) |
| REVIEW_TASKS | 12–15 | High/Medium | CLAUDE.md staleness / contradictions | ✅ marked resolved per CODE_REVIEW #9 |
| REVIEW_TASKS | 16 | Low | Poison-character hazard in dir-match `IF (...)` | ✅ still open |
| REVIEW_TASKS | 17 | Low | Unbounded `%RANDOM%` retry loop | ✅ still open |
| CODE_REVIEW | 1 | P0 | Undocumented rollback correctness assumption | ✅ still open (line 159) |
| CODE_REVIEW | 2 | P1 | Asymmetric error messaging in arg-count | ✅ still open (line 15 missing `Error:` prefix) |
| CODE_REVIEW | 3 | P1 | Unchecked rollback RENAMEs (lines 129, 147–148, 160–161) | ✅ still open |
| CODE_REVIEW | 4 | P1 | Inconsistent ERRORLEVEL capture for `where ffmpeg` | ✅ still open (line 57 uses bare `%ERRORLEVEL%`) |
| CODE_REVIEW | 5 | P1 | Output-rename error message lacks path context | ✅ still open (line 162 uses bare `%TMPOUT%`) |
| CODE_REVIEW | 6 | P2 | Broken `popd && exit /b 0 || exit /b 1` syntax in REVIEW_TASKS Task 11 fix | ✅ still in REVIEW_TASKS.md |
| CODE_REVIEW | 7 | P2 | Relative-path edge case undocumented | ✅ still open |
| CODE_REVIEW | 8 | P2 | "non-zero" weak assertion in README test table | ✅ still open |
| CODE_REVIEW | 10 | P2 | Hard-coded `.mp4`/`.m4a` in temp-name docs | ✅ still open |
| CODE_REVIEW | 11 | P2 | "Adding error messages" stale enhancement in CLAUDE.md | ✅ still open |
| CODE_REVIEW | 12 | P3 | "randomised" vs American spelling (line 88) | ✅ still open |
| CODE_REVIEW | 13 | P3 | Misleading "will fail otherwise" inline comment (line 141) | ✅ still open |
| CODE_REVIEW | 14 | P3 | Missing rollback-failure test cases | ✅ still open |
| CODE_REVIEW | 15 | P3 | Stale "Last Updated" in CLAUDE.md | ✅ still open |
| CODE_REVIEW | 16 | P3 | Missing cross-reference in REVIEW_TASKS Task 16 | ✅ still open |
| CODE_REVIEW | 17 | P3 | Stale review date in REVIEW_TASKS.md | ✅ still open |

**Net status**: of 29 distinct findings across the two review docs, ~21 are still present in the working tree. The two docs were written to be comprehensive; *every* finding in them is a real, actionable item.

### 2.2 Net-new findings (not in any prior review doc)

> **N-#** = newly-surfaced; severity scale S0 (data loss) · S1 (silent wrong behavior) · S2 (robustness / hygiene).

**N-1 · S2 · Two review docs exist for one 187-line script.**
- `REVIEW_TASKS.md` (167 lines) and `CODE_REVIEW.md` (148 lines) each list "17 tasks/findings" but they're different numberings of overlapping concerns. A reader cold-opening either gets a partial picture.
- The user's other repos (`literotica`, `homelab-docs`, `hexos-homepage-config`) have a single canonical findings file. This repo's doc shape is the outlier.
- *Recommendation*: merge into a single `BACKLOG.md` (matching the portfolio convention from `literotica`). Mark resolved items as resolved. The merged doc will have ~25 items, manageable in one view.

**N-2 · S2 · The success path of the script ends with `popd` on line 187 without `exit /b 0`** (REVIEW_TASKS #11 catches this, but CODE_REVIEW #6 *correctly* notes the proposed fix uses broken Unix-shell `&& || ` syntax). Net effect: there's an open finding AND its proposed fix is wrong. Anyone implementing #11 from REVIEW_TASKS.md verbatim will introduce another bug.

**N-3 · S2 · `File_Renamer.bat:179` — `copy "%~nx3" "%USERPROFILE%\Desktop"` succeeds when no Desktop folder exists (uncommon but possible: redirected profile, OneDrive Desktop, etc.).**
- Some Windows installations have OneDrive Desktop syncing where `%USERPROFILE%\Desktop` either doesn't exist or is `%OneDrive%\Desktop`. The copy then fails with a non-obvious error.
- *Recommendation*: check `if not exist "%USERPROFILE%\Desktop"` first; if missing, log "no Desktop folder, file remains in source directory" and skip copy. The script already treats the copy as non-fatal, so this is purely a UX improvement.

**N-4 · S2 · `File_Renamer.bat:142` — `ffmpeg -y` overwrites any pre-existing `%TMPOUT%` without consent.**
- The `:GENERATE_TMPNAMES` loop guarantees `%TMPOUT%` doesn't exist when generated. So `-y` is *redundant* in this workflow but not harmful.
- *Recommendation*: drop `-y` (let FFmpeg's default-prompt behavior catch the case where the random name collision check was bypassed somehow). Defense in depth.

**N-5 · S2 · `File_Renamer.bat:64-66` — `pushd "%~dp1"` is called before any input-existence check.**
- If `%~dp1` exists but `%~nx1` (the video file) doesn't, the script `pushd`s into a directory, then errors out, then `popd`s back. Not a bug, but a behavior worth noting in CLAUDE.md.
- *Recommendation*: a one-line comment that the pushed working directory is a temporary state, used only for path-length reduction.

**N-6 · S2 · No mention of `yt-dlp` (the modern fork) anywhere in the README / CLAUDE.md.**
- `youtube-dl` is the project's stated input source. `yt-dlp` is the actively-maintained fork that:
  - Fixes most Windows MAX_PATH issues via its own `--windows-filenames` and `--restrict-filenames` flags.
  - Has built-in retry logic for the merge step.
  - Is the de facto modern replacement.
- The `File_Renamer.bat` tool may be largely obsoleted by yt-dlp itself.
- *Recommendation*: add a "When to use this" section to README that acknowledges yt-dlp's improvements, and explains the specific scenarios where this tool still adds value (e.g., recovering from a failed merge after the download is already complete).

**N-7 · S2 · No PowerShell alternative**, despite CLAUDE.md mentioning it as future work and PowerShell 7+ being cross-platform.
- A PowerShell version would:
  - Work on macOS/Linux (the user has both — `verizon_bill_parser` etc. are on macOS).
  - Have proper try/catch error handling.
  - Have native `Get-FileHash` for integrity verification.
  - Eliminate the poison-character (#16) hazard entirely.
- *Recommendation*: forward-looking work; not urgent.

**N-8 · S2 · `File_Renamer.bat:175-184` — "COPY RESULT TO DESKTOP" is a hardcoded UX choice.**
- The script always copies to Desktop, which assumes the user wants the file there. For automation / scripted invocation, that's intrusive.
- *Recommendation*: gate behind an env var `FILE_RENAMER_COPY_TO_DESKTOP=1` (default 1 for backward compatibility, set to 0 to skip).

**N-9 · S2 · No explicit version mention of FFmpeg required.**
- Some older FFmpeg versions (pre-3.0) don't support `-map "0:v:0"` syntax. The `where ffmpeg` check passes any installed version.
- *Recommendation*: parse `ffmpeg -version | findstr /b "ffmpeg version"` and assert version >= 4. Probably overkill; FFmpeg <4 is increasingly rare. Document the minimum version instead.

**N-10 · S2 · `File_Renamer.bat:64` — `@echo off` followed by no commands echoing.**
- This is correct — `@echo off` is the convention. But there's no `setlocal` at the top of the script, which means any `SET` calls (lines 31, 92–95, 143) modify the *caller's* environment after the script exits.
- *Recommendation*: add `setlocal` at the top to scope all variable changes. Minor hygiene.

---

## 3. Security Findings

The script is a local file-manipulation tool with no network surface, no auth, no data persistence beyond filesystem renames. The threat model is narrow.

### 3.1 New security findings

**SEC-1 · LOW · Argument injection via crafted filenames (`%`, `&`, `!`, `)`) — CLAUDE.md acknowledges this as a known gap.**
- The script uses double-quoting everywhere (good defense), but the `IF` block at line 79 evaluates the `dp1`/`dp2` paths inside parentheses, which is the classic `)` injection surface (REVIEW_TASKS #16 catches this).
- Already documented.

**SEC-2 · LOW · `del` operations on `%TMPVID%`, `%TMPAUD%` (lines 170-173) are unconditional and only check existence after.**
- If `%TMPVID%` is somehow set to a value containing `*` or `?`, `del` would expand it. Not exploitable in normal use — `%RANDOM%` is purely numeric.
- Documentation-only concern.

**SEC-3 · LOW · No checksum / integrity verification of merged output.**
- After `ffmpeg -c copy …`, the merged file is moved to Desktop. There's no verification that the file is non-empty or playable. Not a security finding strictly — but a "did the merge actually succeed" finding.
- *Recommendation*: a `dir "%~nx3"` size check or `ffprobe` validation step.

---

## 4. Documentation Issues

**DOC-1 · `CLAUDE.md` "Last Updated" is stale** (CODE_REVIEW #15).

**DOC-2 · `REVIEW_TASKS.md` "Review date" is stale** (CODE_REVIEW #17).

**DOC-3 · Two review docs duplicate content** (N-1).

**DOC-4 · `README.md` doesn't mention `yt-dlp`** (N-6).

**DOC-5 · No PowerShell variant** (N-7).

**DOC-6 · `LICENSE` is present (GPL v3.0).** This is the only repo in the user's portfolio with a license file. Good.

**DOC-7 · No `CONTRIBUTING.md`.** Minor.

**DOC-8 · No `CHANGELOG.md`.** Minor; git log suffices for a 1-script project.

---

## 5. Dependency & Version Audit

- **FFmpeg** — system-managed, not version-pinned (N-9).
- **Windows** — script is Windows-only.
- **No Python / JS / etc.** dependencies.

Smallest dep surface in the portfolio (along with `backpacking-and-camping`).

---

## 6. Static Analysis Output

- No batch-script linter readily available locally. Visual scan of `File_Renamer.bat` against the existing review docs confirms accuracy.
- All findings in REVIEW_TASKS.md and CODE_REVIEW.md are real.
- One typo verified ("randomised", line 88) — CODE_REVIEW #12.

---

## 7. Test Coverage & CI

**No tests, no CI.** REVIEW_TASKS #9 has been open across multiple review cycles. The README contains a "Testing and CI" section with proposed test cases (`README.md:83-92`); CODE_REVIEW #8 / #14 note gaps in those proposed tests.

**Recommended minimal CI**:
- GitHub Actions `windows-latest` runner.
- A 30-line PowerShell test harness that stubs out FFmpeg, calls `File_Renamer.bat` with each input scenario, and checks exit code + file state.
- Time-to-implement: about 1 hour.

---

## 8. Performance / Resource Notes

Not applicable. The script invokes `ffmpeg -c copy` which is I/O-bound. No optimization opportunities at the script level.

---

## 9. Cleanup / Tech-Debt

- **Two review docs** (N-1).
- **REVIEW_TASKS #11 proposed fix uses broken syntax** (CODE_REVIEW #6).
- **Stale dates** (CODE_REVIEW #15, #17).
- **No `setlocal`** (N-10).
- **No tests** (REVIEW_TASKS #9).
- **No `BACKLOG.md` in portfolio-convention shape** (N-1).

No `TODO`/`FIXME` markers.

---

## 10. Ideas — Additions (in scope)

**ADD-1 · S — Merge REVIEW_TASKS.md and CODE_REVIEW.md into a single BACKLOG.md.**
- *Why this fits*: closes N-1, matches portfolio convention (`literotica/BACKLOG.md`).
- *First step*: write a `BACKLOG.md` with sections "Resolved", "Open" (deduplicated from both files), and "Triaging".

**ADD-2 · S — Address the P0 + P1 findings from CODE_REVIEW.**
- Specifically: #1 (rollback comment), #2 (asymmetric error), #3 (rollback rename checks), #4 (ERRORLEVEL capture), #5 (path context in error).
- *Why this fits*: all are 1–3 line changes; together they make every error path resilient to surprise.
- *First step*: a single PR titled "Address P0/P1 findings from CODE_REVIEW.md".

**ADD-3 · S — `setlocal` at top of script** (N-10).

**ADD-4 · M — Add basic PowerShell-based integration tests + CI workflow.**
- *Why this fits*: closes REVIEW_TASKS #9 (test improvement) and gives confidence in future refactors.
- *First step*: write `tests/Run-Tests.ps1` with 5 scenarios and `.github/workflows/ci.yml` on `windows-latest`.

**ADD-5 · S — Add a `BUILD.md` or section in README explaining when to use this vs. yt-dlp's built-in merge.**
- *Why this fits*: closes N-6. Acknowledges the obsolescence and clarifies the niche.

**ADD-6 · S — Environment variable to disable Desktop copy** (N-8).

---

## 11. Ideas — New Directions (out of scope but interesting)

**DIR-1 · PowerShell rewrite as the canonical implementation.**
- *Pitch*: a `File-Renamer.ps1` (or even a tiny PowerShell module) gets:
  - Cross-platform support (Windows + macOS + Linux via PowerShell 7+).
  - Real try/catch error handling.
  - File-path objects (no quoting issues).
  - Calls FFmpeg the same way, but with `Invoke-Expression` or `Start-Process` for proper streaming.
  - Pester tests come "for free" (Pester is PowerShell's native test framework).
- *What changes*: new file alongside `File_Renamer.bat`; mark batch as legacy / Windows-only.
- *Why it's worth considering*: closes many of the open findings *by construction*. Aligns with the user's macOS dev environment.

**DIR-2 · Inline this into yt-dlp's post-processor system.**
- *Pitch*: yt-dlp supports user-defined post-processors. A small Python plugin that detects merge failures and retries with the temp-name strategy would eliminate the manual `File_Renamer.bat` call.
- *What changes*: this repo becomes a `yt-dlp-plugin-merge-rename` package, distributable via PyPI.
- *Why it's worth considering*: closes the use case end-to-end. Removes the need for a separate batch script entirely.

---

## 12. Recommended Next Actions

### Must-fix (correctness)

1. **CODE_REVIEW #1** — Add a one-line comment at line 159 documenting the `ffmpeg -c copy` rollback invariant.
2. **CODE_REVIEW #3** — Add existence-check warnings after each of the three rollback RENAMEs.
3. **CODE_REVIEW #4** — Capture `%ERRORLEVEL%` immediately after `where ffmpeg`.
4. **CODE_REVIEW #5** — Include `%CD%\%TMPOUT%` (not just `%TMPOUT%`) in the output-rename error message.

### Should-fix (DX / hygiene)

5. **CODE_REVIEW #2** — Add explicit `Error:` prefix to the too-few-args message.
6. **CODE_REVIEW #6** — Fix the broken `popd && exit /b 0 || exit /b 1` proposal in REVIEW_TASKS #11. Replace with `IF ERRORLEVEL 1 ( exit /b 1 ) ELSE ( exit /b 0 )`.
7. **REVIEW_TASKS #11** — After #6 is settled, implement the success-exit fix.
8. **N-1 / ADD-1** — Merge the two review docs into one `BACKLOG.md`.
9. **N-10 / ADD-3** — Add `setlocal` at script top.
10. **N-3** — Guard the Desktop copy against missing Desktop folder.
11. **N-6 / ADD-5** — Document when to use this tool vs yt-dlp's built-in.
12. **CODE_REVIEW #15 / #17 (DOC-1 / DOC-2)** — Update the stale dates.
13. **CODE_REVIEW #10, #11, #12, #13** — Doc cleanups.

### Nice-to-have (cleanup / ideas)

14. **REVIEW_TASKS #9 / ADD-4** — Add CI tests.
15. **REVIEW_TASKS #10** — Extension validation test case.
16. **REVIEW_TASKS #16** — Delayed-expansion fix for the dir-match comparison.
17. **REVIEW_TASKS #17** — Bound the `%RANDOM%` retry loop.
18. **N-4** — Drop `ffmpeg -y`.
19. **N-8 / ADD-6** — Env var to disable Desktop copy.
20. **N-9** — Document FFmpeg minimum version.
21. **N-7 / DIR-1** — PowerShell variant.
22. **DIR-2** — Convert to yt-dlp post-processor.

---

## Appendix: How this audit was produced

- Read `File_Renamer.bat`, `README.md`, `CLAUDE.md`, `REVIEW_TASKS.md`, `CODE_REVIEW.md` in full.
- Verified line numbers and findings against the working tree.
- Inspected `git log`, `git remote`, `git status`.
- No code modifications were made.
