# Code Review — File-Merge-and-Rename

**Review date:** 2026-03-02
**Scope:** `File_Renamer.bat` (188 lines), `README.md`, `REVIEW_TASKS.md`, `CLAUDE.md`

---

## Summary Table

| Priority | Count | Task Types |
|---|---|---|
| P0 | 1 | Bug Fix (undocumented rollback correctness assumption) |
| P1 | 4 | Bug Fix (asymmetric error message, unchecked rollback renames, inconsistent ERRORLEVEL capture, missing path context in error message) |
| P2 | 6 | Documentation Update x5, Bug Fix/Doc x1 (relative-path resolution edge case) |
| P3 | 6 | Typo Fix x2, Test Improvement x1, Documentation Update x3 |
| **Total** | **17** | |

---

## P0 — Critical

### Finding 1 — Undocumented rollback correctness assumption
- **Type:** Bug Fix
- **Location:** `File_Renamer.bat`, lines 159–161 (`RENAME OUTPUT TO DESIRED NAME` failure block)
- **Description:** The output-rename failure handler attempts to restore `%TMPVID%` and `%TMPAUD%` to their original names. This rollback silently assumes that `ffmpeg -c copy` leaves its input files intact on disk. That assumption is correct today, but is completely undocumented. If a future change to the ffmpeg flags caused inputs to be consumed, the rollback would silently fail (`RENAME` on a non-existent file returns ERRORLEVEL 1, which is unguarded), leaving the user with no source files and no usable output.
- **Fix:** Add a comment at line 159: `:: ffmpeg -c copy reads but does not delete input files; %TMPVID% and %TMPAUD% still exist here.` This documents the invariant that makes the rollback safe. See also Finding 3 for guarding the rollback RENAME commands against silent failure.

---

## P1 — High

### Finding 2 — Asymmetric error messaging
- **Type:** Bug Fix
- **Location:** `File_Renamer.bat`, lines 14–16 (`if "%~3"==""` block)
- **Description:** The two branches of the argument count check have asymmetric error messaging. The too-many-args branch (lines 18–22) prints `Error: Too many arguments. Expected exactly three.` followed by usage. The too-few-args branch (lines 14–16) prints only `Usage: File_Renamer.bat ...` with no error label. A user who provides two arguments receives an unadorned usage string with no indication they made an error.
- **Fix:** Add `echo Error: Too few arguments. Expected exactly three.` as the first line inside the `if "%~3"==""` block, before the existing `echo Usage:` line.

### Finding 3 — Unchecked rollback RENAMEs
- **Type:** Bug Fix
- **Location:** `File_Renamer.bat`, line 129; lines 147–148; lines 160–161
- **Description:** All rollback `RENAME` commands are not followed by any error-level check. If a rollback rename fails (e.g., due to a file lock or name collision), the failure is silently discarded and the user is left with temp-named originals with no warning. The warn-and-continue idiom is already established in the script at lines 171–173 (the `del`/`if exist` pattern for temp-file deletion).
- **Fix:** After each rollback `RENAME`, add an existence-check warning. For example, after `RENAME "%TMPVID%" "%~nx1"` add: `if exist "%TMPVID%" echo Warning: Could not restore "%TMPVID%" to "%~nx1". File may remain temp-named.` Apply the same pattern after each of the three rollback locations.

### Finding 4 — Inconsistent ERRORLEVEL capture
- **Type:** Bug Fix
- **Location:** `File_Renamer.bat`, lines 56–60 (`FFMPEG AVAILABILITY CHECK` section)
- **Description:** The `where ffmpeg` check uses `if %ERRORLEVEL% NEQ 0` — bare percent-expansion — immediately after the command. This is the only place in the script that does not follow the established safe pattern of capturing ERRORLEVEL immediately with `SET "VAR=%ERRORLEVEL%"` before testing it. That pattern is already used for FFmpeg at line 143 (`SET "FFERR=%ERRORLEVEL%"`). If any intervening command were inserted between the `where` call and the check, it would reset ERRORLEVEL to 0 and the ffmpeg-not-found check would silently pass.
- **Fix:** Insert `SET "WHEREE=%ERRORLEVEL%"` immediately after `where ffmpeg >nul 2>nul` and change `if %ERRORLEVEL% NEQ 0` to `if %WHEREE% NEQ 0`, matching the `SET "FFERR=%ERRORLEVEL%"` pattern already used in the same script.

### Finding 5 — Missing path context in output-rename error message
- **Type:** Bug Fix
- **Location:** `File_Renamer.bat`, line 162 (error message in `RENAME OUTPUT TO DESIRED NAME` failure block)
- **Description:** When the output rename fails, the error message reads: `echo Error: Could not rename output to "%~3". Merged file remains at "%TMPOUT%".` At this point, `pushd` has moved the working directory into the video file's directory, so `%TMPOUT%` expands to a bare filename with no path context. After `popd` runs on line 163, the user no longer knows which directory contains this file.
- **Fix:** Change line 162 to: `echo Error: Could not rename output to "%~3". Merged file is at "%CD%\%TMPOUT%".` The `%CD%` variable holds the absolute path of the current directory before `popd` fires, matching the pattern already used for the desktop-copy warning at line 181.

---

## P2 — Medium

### Finding 6 — Broken syntax in REVIEW_TASKS.md Task 11
- **Type:** Documentation Update
- **Location:** `REVIEW_TASKS.md`, Task 11, lines 62–64
- **Description:** Task 11 proposes `popd && exit /b 0 || exit /b 1` as the fix for the missing explicit success exit code. This syntax is borrowed from Unix shells but does not behave as expected in `cmd.exe`. The `||` clause is a separate unconditional statement — it always runs, not only on failure. The code works by accident rather than by design.
- **Fix:** Replace the proposed code block with idiomatic batch syntax:
  ```batch
  popd
  IF ERRORLEVEL 1 ( exit /b 1 ) ELSE ( exit /b 0 )
  ```

### Finding 7 — Relative-path edge case undocumented
- **Type:** Bug Fix / Documentation Update
- **Location:** `File_Renamer.bat`, lines 72–78 (`INPUT DIRECTORY MATCH CHECK` comment block); `README.md` line 27
- **Description:** The `INPUT DIRECTORY MATCH CHECK` comment states that running the check after `pushd` "prevents a false mismatch when the caller mixes an absolute video path with a relative audio name." This guarantee holds only for bare filenames with no directory component in arg2. If arg2 contains a relative path with directory components such as `..\audio.m4a`, `%~dp2` is resolved against the caller's CWD at call time (before `pushd`), not against the `pushd`'d directory.
- **Fix:** Amend the comment to add: `Note: this guarantee applies only to bare filenames (no path separators in arg2). Relative paths with .. or . in arg2 are resolved against the caller's CWD, not the pushd'd directory.` Add a matching caveat to `README.md` line 27.

### Finding 8 — Weak exit-code assertion in test table
- **Type:** Documentation Update
- **Location:** `README.md`, line 89 (FFmpeg failure row of the test scenarios table)
- **Description:** The test table specifies `"non-zero"` as the expected exit code for the FFmpeg failure scenario. The script explicitly propagates the FFmpeg exit code at line 151: `exit /b %FFERR%`. Since the failure stub exits with `1`, the expected exit code is deterministically `1`, not just "non-zero." A CI assertion against "non-zero" will pass even if the script propagates the wrong non-zero code.
- **Fix:** Change "non-zero" to "same as stub exit code (1 with the failure stub above)." Add a note: "Because the script propagates `%FFERR%` verbatim via `exit /b %FFERR%`, the test assertion should check for the exact value, not just non-zero."

### Finding 9 — Four tasks marked open but already resolved in REVIEW_TASKS.md
- **Type:** Documentation Update
- **Location:** `REVIEW_TASKS.md`, summary table, lines 159–166
- **Description:** Tasks 12, 13, 14, and 15 are marked "open" in the summary table, but all four appear to be resolved in the current state of `CLAUDE.md`. Task 12 (CLAUDE.md "How it works" list) — the 14-step list now includes all validation steps. Task 13 (enhancement suggestions contradicting code) — conflicting items removed. Task 14 (ffmpeg validation listed as enhancement) — removed. Task 15 (MKV-only framed as limitation) — reworded correctly.
- **Fix:** Mark Tasks 12, 13, 14, and 15 as "Resolved" in the summary table and move them to the "Previously Identified Tasks — Status Update" section, with commit references.

### Finding 10 — Hard-coded extensions in temp name examples
- **Type:** Documentation Update
- **Location:** `README.md`, line 44; `CLAUDE.md`, line 119
- **Description:** Step 8 in "What It Does" gives temp name examples `frm_12345_v.mp4` and `frm_12345_a.m4a`. The actual script at lines 94–95 uses `%~x1` and `%~x2` — the extensions of the input files. The examples hard-code `.mp4` and `.m4a`, which could lead users to believe the script only handles those formats.
- **Fix:** Change both examples to use a placeholder: `frm_12345_v.<ext>` and `frm_12345_a.<ext>` where `<ext>` is the original file's extension, matching the format already used for the output example (`frm_<RANDOM>_out.mkv`).

### Finding 11 — "Adding error messages" listed as pending enhancement
- **Type:** Documentation Update
- **Location:** `CLAUDE.md`, line 182 (the "Enhancing Functionality" bullet list)
- **Description:** `CLAUDE.md` lists "Adding error messages for common failures" as a pending enhancement. The script already has detailed error messages for all failure paths. `CLAUDE.md`'s own "Input Validation — Current State" section exhaustively enumerates the error handling already in place, directly contradicting this enhancement suggestion.
- **Fix:** Remove "Adding error messages for common failures" from the enhancement list, or replace it with a specific remaining gap (e.g., "Adding a verbose/debug mode that prints the full ffmpeg command before executing it").

---

## P3 — Low

### Finding 12 — Spelling: "randomised" vs. American English
- **Type:** Typo Fix
- **Location:** `File_Renamer.bat`, line 88
- **Description:** Line 88 uses British spelling "randomised" while the rest of the repository uses American English (line 89 of the same comment block uses "pseudo-random").
- **Fix:** Change "randomised" to "randomized."

### Finding 13 — Misleading inline comment on validation location
- **Type:** Typo Fix / Documentation Update
- **Location:** `File_Renamer.bat`, line 141 (inline comment above the ffmpeg command)
- **Description:** The comment reads: "The output container is Matroska (MKV); the script requires arg3 to use the .mkv extension and will fail otherwise." The phrase "will fail otherwise" implies the failure happens at the ffmpeg step, but the actual guard is at lines 48–51 in the ARGUMENT VALIDATION section, before any file operations. This could lead a maintainer to believe removing the earlier guard is safe.
- **Fix:** Replace with: "The output container is Matroska (MKV); arg3's .mkv extension was already validated before any file operations."

### Finding 14 — Missing rollback-failure test cases
- **Type:** Test Improvement
- **Location:** `README.md`, test scenarios table (lines 83–92); `REVIEW_TASKS.md`, Task 9
- **Description:** The test scenarios table has no cases for the rename-failure rollback paths: (a) first rename succeeds and second rename fails (lines 126–133); (b) output rename fails after successful merge (lines 157–165). These are the most data-loss-sensitive paths in the script.
- **Fix:** Add two rows to the test scenarios table:
  1. "Audio rename fails (video already renamed)" — Create a read-only audio file with `attrib +R audio.m4a` before running. Expected: exit `1`; video file restored to original name, no temp files orphaned.
  2. "Output rename fails after successful merge" — Pre-create a file named `<output_name>` in the directory before running (causes RENAME collision). Expected: exit `1`; merged file remains as `frm_XXXXX_out.mkv`; message includes full path to temp file.

### Finding 15 — Stale "Last Updated" date in CLAUDE.md
- **Type:** Documentation Update
- **Location:** `CLAUDE.md`, line 321
- **Description:** `**Last Updated**: 2026-02-24` is stale; the file has been modified in commits after that date.
- **Fix:** Update to `**Last Updated**: 2026-03-02`, or remove the field and rely on `git log` for history.

### Finding 16 — Missing cross-reference in REVIEW_TASKS.md Task 16
- **Type:** Documentation Update
- **Location:** `REVIEW_TASKS.md`, Task 16, lines 120–129
- **Description:** Task 16 proposes using `setlocal enabledelayedexpansion` to harden the directory-match check, but does not cross-reference `CLAUDE.md` lines 137–144, which contains a detailed analysis of this exact recommendation including the `!` stripping hazard. A developer reading Task 16 in isolation receives a partial picture.
- **Fix:** Add a cross-reference line to Task 16: "See also `CLAUDE.md`, 'Security Considerations > Input Validation' for the full delayed-expansion tradeoff analysis, including the `!` stripping hazard."

### Finding 17 — Stale review date in REVIEW_TASKS.md
- **Type:** Documentation Update
- **Location:** `REVIEW_TASKS.md`, line 3
- **Description:** `> **Review date:** 2026-02-24` is stale; the file was updated in commits `cedba99` and `1b7fadf` after that date.
- **Fix:** Update to `> **Review date:** 2026-03-02`, or reframe as "Original review date" and add a separate "Last updated" line.

---

## Recommended First Actions

1. **Finding 1 + Finding 3 (P0/P1)** — Add the rollback invariant comment and existence-check warnings on all three rollback RENAME commands. Together these close the highest data-loss-risk gap and take under ten minutes.
2. **Finding 6 (P2)** — Fix the broken `popd &&` syntax in `REVIEW_TASKS.md` Task 11 before any developer implements it (~1 min).
3. **Finding 9 (P2)** — Mark Tasks 12–15 as resolved in `REVIEW_TASKS.md` to reduce noise in the open-tasks list (~5 min).
