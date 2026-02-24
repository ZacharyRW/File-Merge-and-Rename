# File-Merge-and-Rename

A Windows batch script utility to merge and rename video/audio files downloaded by YouTube-DL that failed to merge due to Windows PATH length limitations.

## Problem

YouTube-DL sometimes downloads video and audio as separate files and merges them automatically. When file paths exceed Windows' 260-character MAX_PATH limit (common with long video titles or deep directory structures), the automatic merge fails. This script provides a manual workaround.

## Requirements

- **Windows** (batch script, Windows-only)
- **FFmpeg** installed and available in system PATH

## Usage

Navigate to the directory containing your separate video and audio files, then run:

```batch
File_Renamer.bat <video_file> <audio_file> <output_name>
```

**Arguments:**

| Argument | Description |
|---|---|
| `video_file` | Name of the input video file (with extension) |
| `audio_file` | Name of the input audio file (with extension) |
| `output_name` | Desired name for the merged output file — **must use a `.mkv` extension**. The script produces an intermediate `ghi.mkv` and renames it to this value; using a non-`.mkv` extension (e.g. `.mp4`) will produce a file with MKV internals but an incorrect extension. |

**Example:**
```batch
File_Renamer.bat video.f137.mp4 audio.f140.m4a "My Final Video.mkv"
```

## What It Does

1. Changes into the directory containing your video file
2. Renames your video and audio files to short randomized temporary names (e.g. `frm_12345_v.mp4`, `frm_12345_a.m4a`) to avoid path length issues
3. Merges them using FFmpeg (stream copy — no re-encoding, fast and lossless)
4. Renames the merged output to your specified name
5. Deletes the temporary files
6. Copies the final file to `%USERPROFILE%\Desktop` (your current user's desktop)

If any step fails, the script rolls back the file renames and exits with an error message, leaving your original files intact.

## Alternative Solutions

- **Enable long path support**: Windows 10 (1607+) supports paths beyond 260 characters via a registry setting or Group Policy
- **Use yt-dlp**: A modern YouTube-DL fork that handles path length issues more gracefully

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.
