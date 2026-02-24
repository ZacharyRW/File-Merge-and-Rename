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
| `video_file` | Name of the video file (with extension) |
| `audio_file` | Name of the audio file (with extension) |
| `output_name` | Desired name for the merged output file (with extension) |

**Example:**
```batch
File_Renamer.bat video.f137.mp4 audio.f140.m4a "My Final Video.mkv"
```

## What It Does

1. Renames your video and audio files to short temporary names (`abc`, `def`) to avoid path length issues
2. Merges them using FFmpeg (stream copy — no re-encoding, fast and lossless)
3. Renames the output to your specified name
4. Deletes the temporary files
5. Copies the final file to `C:\Users\zacha\Desktop`

> **Note:** The desktop copy path is hardcoded. Edit line 20 of the script to change the destination, or use `%USERPROFILE%\Desktop` for portability across user accounts.

## Alternative Solutions

- **Enable long path support**: Windows 10 (1607+) supports paths beyond 260 characters via a registry setting or Group Policy
- **Use yt-dlp**: A modern YouTube-DL fork that handles path length issues more gracefully

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.
