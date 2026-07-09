# File-Merge-and-Rename

A Windows batch script utility to merge and rename video/audio files downloaded by YouTube-DL that failed to merge due to Windows PATH length limitations.

## Problem

YouTube-DL sometimes downloads video and audio as separate files and merges them automatically. When file paths exceed Windows' 260-character MAX_PATH limit (common with long video titles or deep directory structures), the automatic merge fails. This script provides a manual workaround.

## Requirements

- **Windows** (batch script, Windows-only)
- **FFmpeg** installed and available in system PATH
- **PowerShell 7+** if using the PowerShell port or running the Pester test suite

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
| `output_name` | Desired name for the merged output file — **must use a `.mkv` extension** (plain filename, no path). The script rejects non-`.mkv` extensions before any file operations. The merge always produces a Matroska (MKV) container. |

**Example:**
```batch
File_Renamer.bat video.f137.mp4 audio.f140.m4a "My Final Video.mkv"
```

PowerShell alternative:

```powershell
.\File_Renamer.ps1 video.f137.mp4 audio.f140.m4a "My Final Video.mkv"
```

The PowerShell port intentionally follows the batch script's current behavior: exactly three positional arguments, a plain `.mkv` output filename, same-directory inputs, short temporary renames, rollback on merge failures, and a warning-only Desktop copy.

## What It Does

1. Validates that exactly three arguments are provided (prints usage and exits if fewer or more)
2. Rejects path separators and drive letters in the output name — it must be a plain filename
3. Requires the output name to use the `.mkv` extension
4. Checks that FFmpeg is installed and available in your PATH
5. Changes into the directory containing your video file
6. Verifies both input files are in the same directory
7. Verifies both input files exist in that directory
8. Renames your video and audio files to short randomized temporary names (e.g. `frm_12345_v.mp4`, `frm_12345_a.m4a`) to avoid path length issues
9. Merges them using FFmpeg into a temporary file named `frm_<RANDOM>_out.mkv` (stream copy — no re-encoding, fast and lossless)
10. Renames `frm_<RANDOM>_out.mkv` to your specified output name
11. Deletes the temporary files
12. Copies the final file to `%USERPROFILE%\Desktop` (your current user's desktop)

If any rename or FFmpeg step fails, the script rolls back all file renames and exits with an error message, leaving your original files intact. The desktop copy (step 12) is a convenience-only step: if it fails the script prints a warning but does **not** roll back — the merged file is already safely present in the input directory.

## Testing and CI

> **Prerequisites:** The default automated suite requires a **Windows environment** and PowerShell 7+. It uses a mocked `ffmpeg.bat` binary placed earlier on `PATH` than any real binary. The scripts cannot be meaningfully tested on Linux or macOS without a Windows compatibility layer.

Run the default Pester suite from the repository root:

```powershell
pwsh -NoProfile -Command "Invoke-Pester -Path .\File_Renamer.Tests.ps1 -Output Detailed"
```

GitHub Actions runs the same suite on `windows-latest` via `.github/workflows/test.yml` with Pester 5.x.

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

### Covered Test Scenarios

| Scenario | Setup | Expected exit code |
|---|---|---|
| Valid inputs, FFmpeg succeeds | All args valid, both files present, success stub | `0` |
| Missing argument(s) | Fewer than 3 args | `1` |
| FFmpeg not in PATH | No `ffmpeg` on PATH | `1` |
| Input video file not found | Non-existent first file | `1` |
| Input audio file not found | Non-existent second file | `1` |
| FFmpeg failure | Failure stub | non-zero |
| Output name contains path separator | e.g. `C:\out\file.mkv` as arg3 | `1` |
| Non-`.mkv` output extension | e.g. `output.mp4` as arg3 | `1` |
| Output rename conflict | Pre-existing final output file | `1` with input rollback |
| Desktop copy succeeds | Mock merge with writable Desktop | `0` |

### Extension Mismatch

The script requires the output name to use the `.mkv` extension. Passing a non-`.mkv` output name (e.g. `output.mp4`) exits with code `1` before any file operations occur. To test this:

```batch
File_Renamer.bat video.mp4 audio.m4a output.mp4
:: Expected: exit code 1, error message, no files renamed or created
```

## Alternative Solutions

- **Enable long path support**: Windows 10 (1607+) supports paths beyond 260 characters via a registry setting or Group Policy
- **Use yt-dlp**: A modern YouTube-DL fork that handles path length issues more gracefully

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.
