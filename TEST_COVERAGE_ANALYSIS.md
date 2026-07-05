# Test Coverage Analysis

> **Analysis date:** 2026-07-05
> **Scope:** `File_Renamer.bat` — all execution paths

---

## Current State

The repository has **no automated tests**. Every execution path in `File_Renamer.bat` is validated only by manual runs. This is already tracked as Tasks 9 and 10 in `REVIEW_TASKS.md`; this document expands on those tasks with a complete path-by-path breakdown and recommended test harness approach.

---

## Untested Code Paths

### 1. Argument Validation (lines 14–51)

| Scenario | Expected Exit Code |
|---|---|
| Zero arguments | `1` |
| One argument | `1` |
| Two arguments | `1` |
| Four or more arguments | `1` |
| arg3 contains a backslash | `1` |
| arg3 contains a forward slash | `1` |
| arg3 contains a colon (drive letter) | `1` |
| arg3 uses `.mp4`, `.avi`, or other non-`.mkv` extension | `1` |
| arg3 uses `.MKV` (uppercase — case-insensitive check should pass) | proceed |

### 2. FFmpeg Availability (lines 56–60)

| Scenario | Expected Exit Code |
|---|---|
| `ffmpeg` not on PATH | `1` |
| `ffmpeg` present on PATH | proceed |

### 3. Directory Resolution (lines 66–85)

| Scenario | Expected Exit Code |
|---|---|
| Video path directory does not exist (`pushd` fails) | `1` |
| Video and audio files are in different directories | `1` |
| Audio path is a relative (bare) filename in the same directory | proceed |
| Audio path is an absolute path to a different directory | `1` |

### 4. Input File Existence (lines 104–113)

| Scenario | Expected Exit Code |
|---|---|
| Video file does not exist in the resolved directory | `1` |
| Audio file does not exist in the resolved directory | `1` |
| Both files exist | proceed |

### 5. Rename Operations (lines 119–133)

| Scenario | Expected Exit Code |
|---|---|
| First rename (video → temp name) fails | `1` |
| Second rename (audio → temp name) fails; first rename rolled back | `1` |

### 6. FFmpeg Merge (lines 142–152)

| Scenario | Notes |
|---|---|
| FFmpeg exits `0` (success) | Happy path — no test exists |
| FFmpeg exits non-zero — partial output deleted, original filenames restored | Rollback correctness untested |
| FFmpeg exit code propagated as script exit code | Exit code forwarding untested |

### 7. Output Rename (lines 157–165)

| Scenario | Expected Exit Code |
|---|---|
| Rename of `TMPOUT` to desired name succeeds | proceed |
| Rename fails — input files restored from temp names, script exits | `1` |
| A file with the desired output name already exists in the directory | `1` |

### 8. Cleanup and Desktop Copy (lines 170–184)

| Scenario | Expected Behavior |
|---|---|
| Temp file deletion succeeds | Silent — no output |
| Temp file deletion fails | Warning printed; script does not abort |
| Desktop copy succeeds | "Success" message printed |
| Desktop copy fails | Warning printed; script does not abort |

### 9. Success Path Exit Code (line 187)

The script exits via bare `popd` with no explicit `exit /b 0`. The final exit code is whatever `popd` returns rather than a deterministic zero. No test validates the exit code on the full success path. (See also Task 11 in `REVIEW_TASKS.md`.)

---

## Highest-Risk Untested Areas

These gaps carry direct data-loss risk if a regression is introduced:

1. **FFmpeg failure rollback (lines 143–152):** If the rollback logic is broken, users permanently lose their original filenames — they are left with temp-named files and no merged output.
2. **Second rename failure rollback (lines 127–133):** If the first rename is not restored, the user's video file is left under a temporary name.
3. **Output rename failure rollback (lines 158–165):** Input files may be left with temp names if the rollback is skipped.

These three scenarios should be the first tests written.

---

## Recommended Test Harness

The script requires a Windows environment. A **PowerShell test harness with a mock `ffmpeg.bat` stub** placed earlier on `PATH` is the most practical approach, as already noted in Task 9 of `REVIEW_TASKS.md`.

### Mock FFmpeg Stub

```batch
:: ffmpeg_success.bat — simulates successful merge by creating the output file
@echo off
:: Parse the output filename from the argument list (last non-flag argument)
:: For test simplicity, accept a fixed known output name via environment variable
copy NUL "%MOCK_OUTPUT%" >nul
exit /b 0
```

```batch
:: ffmpeg_fail.bat — simulates a failed merge
@echo off
exit /b 1
```

### Proposed Test Cases (Priority Order)

1. **Argument count validation** — pure logic, no files needed; easiest to automate
2. **Path-separator and extension rejection** — pure logic; covers lines 24–51
3. **Missing FFmpeg** — manipulate PATH to exclude any `ffmpeg` binary
4. **Missing input files** — create a temp directory without the expected files
5. **FFmpeg failure + rollback** — use failing mock; assert original filenames are restored
6. **Output rename conflict** — pre-create a file at the desired output name
7. **Different-directory rejection** — pass absolute paths from two different temp directories
8. **`.MKV` uppercase acceptance** — verify the `/i` flag on the extension check
9. **Full success path** — mock ffmpeg creates the output file; assert exit code is `0` and desktop copy occurs

### GitHub Actions Integration

A `windows-latest` runner can execute the test harness without additional setup:

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        shell: pwsh
        run: .\tests\Run-Tests.ps1
```

---

## Relationship to Existing Open Tasks

| Task # | Summary | This Document |
|---|---|---|
| 9 | Add automated CI tests | Expanded with full path inventory and harness design |
| 10 | Extension validation test case | Covered under Argument Validation scenario 8 above |
| 11 | Missing `exit /b 0` on success path | Covered under "Success Path Exit Code" section above |
