# File-Merge-and-Rename

A Windows batch script utility to merge and rename video/audio files downloaded by YouTube-DL that failed to merge due to Windows PATH length limitations.

## Problem

YouTube-DL sometimes downloads video and audio as separate files and merges them automatically. When file paths exceed Windows' 260-character MAX_PATH limit (common with long video titles or deep directory structures), the automatic merge fails. This script provides a manual workaround.

## Requirements

- **Windows** (batch script, Windows-only)
- **FFmpeg** installed and available in system PATH

## Usage

Both the video and audio files must be in the same directory. Navigate to that directory, then run:

```batch
File_Renamer.bat <video_file> <audio_file> <output_name>
```

**Arguments:**

| Argument | Description |
|---|---|
| `video_file` | Name of the input video file (with extension) |
| `audio_file` | Name of the input audio file (with extension) — **must be in the same directory as `video_file`**. The script changes into the video file's directory and looks for the audio file there by name only; passing a file from a different folder will fail. |
| `output_name` | Desired name for the merged output file — **must use a `.mkv` extension**. The script produces an intermediate file named `frm_<RANDOM>_out.mkv` (e.g. `frm_12345_out.mkv`) and renames it to this value; using a non-`.mkv` extension (e.g. `.mp4`) will produce a file with MKV internals but an incorrect extension. |

**Example:**
```batch
File_Renamer.bat video.f137.mp4 audio.f140.m4a "My Final Video.mkv"
```

## What It Does

1. Validates that all three arguments are provided (prints usage and exits if not)
2. Checks that FFmpeg is installed and available in your PATH
3. Changes into the directory containing your video file
4. Verifies both input files exist in that directory
5. Renames your video and audio files to short randomized temporary names (e.g. `frm_12345_v.mp4`, `frm_12345_a.m4a`) to avoid path length issues
6. Merges them using FFmpeg into a temporary file named `frm_<RANDOM>_out.mkv` (stream copy — no re-encoding, fast and lossless)
7. Renames `frm_<RANDOM>_out.mkv` to your specified output name
8. Deletes the temporary files
9. Copies the final file to `%USERPROFILE%\Desktop` (your current user's desktop)

If any rename or FFmpeg step fails, the script rolls back all file renames and exits with an error message, leaving your original files intact. The desktop copy (step 9) is a convenience-only step: if it fails the script prints a warning but does **not** roll back — the merged file is already safely present in the input directory.

## Testing and CI

> **Prerequisites:** All tests require a **Windows environment** (Command Prompt, PowerShell, or a GitHub Actions `windows-latest` runner) plus either a real FFmpeg installation or a **mocked `ffmpeg` binary** placed earlier on `PATH` than any real binary. The script cannot be meaningfully tested on Linux or macOS without a Windows compatibility layer.

There are currently no automated tests in the repository. See `REVIEW_TASKS.md` (Tasks 9 and 10) for the full proposed CI plan. The sections below provide enough detail to implement a basic Windows CI job.

### Mocking FFmpeg

Place a `ffmpeg.bat` stub in a temporary directory and prepend that directory to `PATH` before running each test case.

**Success stub** — creates the expected output file and exits `0`, simulating a successful merge:

```batch
@echo off
:: Capture the last argument (the output filename) and write a placeholder.
set "OUTFILE="
for %%A in (%*) do set "OUTFILE=%%~A"
echo MOCK_OUTPUT > "%OUTFILE%"
exit /b 0
```

**Failure stub** — exits non-zero without creating any output, simulating an FFmpeg error:

```batch
@echo off
exit /b 1
```

### Test Scenarios

| Scenario | Setup | Expected exit code |
|---|---|---|
| Valid inputs, FFmpeg succeeds | All args valid, both files present, success stub | `0` |
| Missing argument(s) | Fewer than 3 args | `1` |
| FFmpeg not in PATH | No `ffmpeg` on PATH | `1` |
| Input video file not found | Non-existent first file | `1` |
| Input audio file not found | Non-existent second file | `1` |
| FFmpeg failure | Failure stub | non-zero |
| Output name contains path separator | e.g. `C:\out\file.mkv` as arg3 | `1` |
| Desktop copy fails | Read-only Desktop or missing folder | `0` (warning printed) |

### Extension Mismatch

Pass a non-`.mkv` output name (e.g. `output.mp4`) to test extension handling:

- **Current behavior**: The script renames the intermediate `frm_*_out.mkv` to `output.mp4`. The file's internal container remains MKV; only the extension label is wrong.
- **If extension validation is added**: The script should reject non-`.mkv` extensions with exit code `1` before any file operations occur.

## Alternative Solutions

- **Enable long path support**: Windows 10 (1607+) supports paths beyond 260 characters via a registry setting or Group Policy
- **Use yt-dlp**: A modern YouTube-DL fork that handles path length issues more gracefully

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.
