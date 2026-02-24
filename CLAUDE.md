# CLAUDE.md - AI Assistant Guide for File-Merge-and-Rename

## Project Overview

**Repository**: File-Merge-and-Rename
**Purpose**: A Windows batch script utility to merge and rename video/audio files created by YouTube-DL that failed to merge due to Windows PATH length limitations.
**License**: GNU General Public License v3.0
**Platform**: Windows (batch script)
**Primary Language**: Windows Batch (.bat)

### Problem Statement
YouTube-DL sometimes downloads video and audio as separate files. When the file paths exceed Windows' maximum path length (260 characters), the automatic merge process fails. This utility provides a manual workaround by:
1. Renaming files to short temporary names
2. Merging them using ffmpeg
3. Renaming the output to the desired final name
4. Cleaning up temporary files

## Repository Structure

```
File-Merge-and-Rename/
├── File_Renamer.bat    # Main batch script for merging files
├── README.md           # Basic project description
├── REVIEW_TASKS.md     # Code review findings and open tasks
├── LICENSE             # GNU GPL v3.0 license text
└── CLAUDE.md           # This file - AI assistant guide
```

### File Descriptions

#### File_Renamer.bat
**Location**: `File_Renamer.bat` (repository root)
**Type**: Windows Batch Script
**Purpose**: Merges video and audio files using ffmpeg

**How it works**:
1. Accepts 3 command-line arguments:
   - `%1`: Video file path (with extension)
   - `%2`: Audio file path (with extension)
   - `%3`: Desired output file name (plain filename, must use `.mkv` extension)
2. Validates that exactly three arguments are provided; prints usage and exits if fewer or more
3. Rejects path separators (backslash, forward slash) and drive letters (colon) in arg3 — output name must be a plain filename
4. Requires arg3 to use the `.mkv` extension; exits with error if not
5. Checks that FFmpeg is installed and available in PATH; exits with a descriptive error if not
6. Changes into the directory of the video file using `pushd`
7. Verifies both input files reside in the same directory; exits if not
8. Generates randomized temporary names using `%RANDOM%` with collision checking to avoid path length issues (e.g. `frm_12345_v.mp4`)
9. Checks that both input files exist in the video file's directory
10. Renames input files to temporary names; rolls back and exits on failure
11. Uses ffmpeg to merge video and audio streams; rolls back renames and exits on failure
12. Renames output file to user-specified name; rolls back on failure
13. Deletes temporary input files (with warnings if deletion fails)
14. Copies final file to `%USERPROFILE%\Desktop` (with warning on failure) and restores directory with `popd`

**Key sections explained** (referenced by script section-banner comments; line numbers are as of commit `445f858`):
- `ARGUMENT VALIDATION` (lines 14–22): Exits with usage message if fewer than 3 args; rejects more than 3 args
- Path-separator / drive-letter rejection (lines 24–45): Rejects backslashes, forward slashes, and colons in arg3
- `.mkv` extension enforcement (lines 48–51): Requires arg3 to use `.mkv` extension
- `FFMPEG AVAILABILITY CHECK` (lines 56–60): Verifies `ffmpeg` is on `PATH` via `where` before any file operations
- `CHANGE TO INPUT DIRECTORY` (lines 66–70): `pushd` to the video file's directory
- `INPUT DIRECTORY MATCH CHECK` (lines 79–85): Verifies both inputs share the same directory
- `TEMPORARY FILE NAME GENERATION` / `:GENERATE_TMPNAMES` (lines 92–99): Randomized temp names with collision retry
- `INPUT FILE EXISTENCE CHECKS` (lines 104–113): Confirms both input files exist in the target directory
- `RENAME INPUTS TO TEMPORARY NAMES` (lines 119–133): Renames inputs with rollback on failure
- `FFMPEG MERGE` (line 142): FFmpeg merge command with stream-copy and explicit stream mapping
- FFmpeg error handling (lines 143–152): Restores original filenames, deletes partial output
- `RENAME OUTPUT TO DESIRED NAME` (line 157): Renames merged file; rollback on failure (lines 158–165)
- `CLEAN UP TEMPORARY INPUT FILES` (lines 170–173): Deletes temp inputs with existence-check warnings
- `COPY RESULT TO DESKTOP` (lines 179–184): Copies to `%USERPROFILE%\Desktop` with error handling
- `popd` (line 187): Restores original working directory

#### README.md
**Location**: `README.md` (repository root)
**Purpose**: Full usage guide covering the problem statement, requirements (Windows + FFmpeg), command-line usage with argument descriptions and examples, step-by-step explanation of script behavior, and alternative solutions

#### LICENSE
**Location**: `LICENSE` (repository root)
**Purpose**: Full text of GNU General Public License v3.0

## Dependencies

### Required Software
- **FFmpeg**: Command-line multimedia framework
  - Must be installed and accessible in system PATH
  - Used for merging video and audio streams
  - Command format: `ffmpeg -y -loglevel "repeat+info" -i input1 -i input2 -c copy -map "0:v:0" -map "1:a:0" output` (see "FFmpeg Command Breakdown" section for flag details)

### Platform Requirements
- **Operating System**: Windows (batch file is Windows-specific)
- **File System**: NTFS or compatible (supports file operations)

## Development Workflow

### Git Branch Information
- **Development Branch**: Varies per session (uses `claude/*` branch naming convention)
- **Main Branch**: `master`

### Making Changes
1. Develop on the specified claude/* branch
2. Test changes on Windows system with ffmpeg installed
3. Commit with descriptive messages
4. Push using: `git push -u origin <branch-name>`

### Testing Considerations
- Batch scripts require Windows environment
- Cannot be tested on Linux/macOS without compatibility layer
- When suggesting changes, note they need Windows validation
- Consider providing PowerShell alternatives for cross-version compatibility

## Key Conventions

### Code Style
- Batch script uses Windows batch syntax
- `@echo off` suppresses command echoing for cleaner output
- Uses positional parameters (`%1`, `%2`, `%3`)
- Comments use `::` prefix

### Naming Conventions
- Temporary files: Randomized names using `%RANDOM%` (e.g. `frm_12345_v.mp4`, `frm_12345_a.m4a`, `frm_12345_out.mkv`)
- Final files: User-specified names with extensions

### Security Considerations

> Line numbers below are as of commit `445f858`. Prefer searching for the
> section-banner comments (e.g. `:: ── COPY RESULT TO DESKTOP`) which are
> stable across refactors.

#### Output Path
- **`COPY RESULT TO DESKTOP` section (line 179)**: Desktop path uses `%USERPROFILE%\Desktop`, which resolves to the current user's desktop on any Windows system
- **Note**: To change the destination, edit the `copy` command in the `COPY RESULT TO DESKTOP` section of `File_Renamer.bat`
- **Enhancement**: Consider accepting a configurable output directory via an environment variable (a 4th positional argument would conflict with the too-many-args guard at lines 18–22)

#### Input Validation
- **Current State**: The script validates argument count (`ARGUMENT VALIDATION`, lines 14–22), rejects path separators and non-`.mkv` extensions in arg3 (lines 24–51), checks FFmpeg availability (`FFMPEG AVAILABILITY CHECK`, lines 56–60), verifies both inputs share the same directory (`INPUT DIRECTORY MATCH CHECK`, lines 79–85), and confirms input file existence (`INPUT FILE EXISTENCE CHECKS`, lines 104–113). Rename and FFmpeg operations have per-step error handling with rollback.
- **Remaining Risks**:
  - Special characters in filenames (e.g. `&`, `%`, `!`, `)`) may break commands
- **Recommendations**:
  - Escape special characters where possible. **Caution with delayed expansion:** `setlocal enabledelayedexpansion` allows `!var!` syntax, which protects against poison characters like `&` and `)` inside variables — but it also silently strips every literal `!` from filenames (e.g. `Great Video!.mkv` becomes `Great Video.mkv`). The safe pattern is to keep delayed expansion **disabled** by default (use `%var%` to preserve `!` in values) and only toggle it on around the specific comparison or block that needs it, then immediately disable it afterward:
    ```batch
    :: Safe pattern: enable delayed expansion only for the critical operation
    setlocal enabledelayedexpansion
    if /i not "!_DIR1!"=="!_DIR2!" ( ... )
    endlocal
    ```

#### Command Injection
- **Risk**: Batch scripts are vulnerable to command injection via filenames
- **Impact**: Malicious filenames could execute arbitrary commands
- **Mitigation**: Always quote variables: `"%1"` instead of `%1`

#### File Cleanup
- **`CLEAN UP TEMPORARY INPUT FILES` section (lines 170–173)**: Deletes temporary input files after merge, with warnings if deletion fails
- **Good**: Prevents file buildup; warns user about any orphaned temp files
- **FFmpeg failure**: If ffmpeg fails, the error handler (`FFMPEG MERGE` section, lines 143–152) restores original filenames and deletes partial output — no orphaned temp files remain
- **Recommendation**: Temp file warnings are now in place; consider adding a cleanup mode for finding leftover `frm_*` files

## Common Tasks

### For AI Assistants Working on This Repository

#### Improving the Script
When modifying `File_Renamer.bat`:
1. Read the current file first
2. Test logic mentally for Windows batch syntax
3. Add input validation if missing
4. Quote all variable references for safety
5. Consider error handling (batch scripts don't have try-catch)
6. Note that testing requires Windows environment

#### Adding Cross-Platform Support
If asked to make cross-platform:
1. Consider PowerShell script (works on Windows/Linux/macOS)
2. Or create shell script (.sh) alternative for Unix systems
3. Both would use same ffmpeg commands
4. Document platform-specific versions clearly

#### Enhancing Functionality
Common enhancement requests might include:
- Making output directory configurable
- Adding progress feedback during merge
- Supporting batch processing of multiple files
- Adding error messages for common failures
- Supporting drag-and-drop operation

#### Documentation Updates
When updating documentation:
- Keep README.md simple and user-focused
- Keep CLAUDE.md (this file) technical and comprehensive
- Update both if functionality changes
- Include examples for new features

## FFmpeg Command Breakdown

```batch
ffmpeg -y -loglevel "repeat+info" -i "%TMPVID%" -i "%TMPAUD%" -c copy -map "0:v:0" -map "1:a:0" "%TMPOUT%"
```

**Flags explained**:
- `-y`: Overwrite output file without prompting
- `-loglevel "repeat+info"`: Set logging verbosity
- `-i "%TMPVID%"`: First input (randomized temp video file)
- `-i "%TMPAUD%"`: Second input (randomized temp audio file)
- `-c copy`: Copy streams without re-encoding (fast)
- `-map "0:v:0"`: Map first video stream from first input
- `-map "1:a:0"`: Map first audio stream from second input
- `"%TMPOUT%"`: Output file (Matroska container, e.g. `frm_12345_out.mkv`)

**Why this approach**:
- Stream copy (`-c copy`) avoids re-encoding (preserves quality, very fast)
- Explicit stream mapping ensures correct video/audio pairing
- MKV container supports wide variety of codecs

## Potential Issues and Solutions

### Issue: Script fails on other users' systems
**Status**: Already resolved — the `COPY RESULT TO DESKTOP` section uses `%USERPROFILE%\Desktop`, which resolves dynamically per user
**Enhancement**: Consider a configurable output directory via environment variable (a 4th positional argument would conflict with the too-many-args guard)

### Issue: Files with spaces in names
**Cause**: Unquoted variables
**Solution**: Quote all variable references: `RENAME "%1" abc`

### Issue: Missing FFmpeg
**Status**: Resolved — the `FFMPEG AVAILABILITY CHECK` section verifies FFmpeg is on `PATH` via `where` before any file operations

### Issue: Wrong number of arguments
**Status**: Resolved — the `ARGUMENT VALIDATION` section validates that exactly three arguments are provided before proceeding

## Best Practices for AI Assistants

### When Analyzing This Code
1. Recognize it's a utility script, not production software
2. Consider the specific use case (YouTube-DL path length workaround)
3. Understand Windows batch limitations
4. Note security implications of running batch scripts

### When Suggesting Improvements
1. Maintain backward compatibility with 3-argument interface
2. Keep it simple - this is a single-purpose utility
3. Test suggestions against Windows batch syntax rules
4. Consider adding PowerShell version for modern Windows
5. Validate all paths and filenames
6. Add error handling incrementally

### When Asked About Usage
Provide clear examples:
```batch
File_Renamer.bat video.f137.mp4 audio.f140.m4a "My Final Video.mkv"
```

### What NOT to Do
- Don't suggest complex error handling (batch is limited)
- Don't recommend features requiring external dependencies
- Don't assume UNIX tools are available
- Don't ignore the Windows-specific context

## Technical Debt and Improvement Opportunities

### Current Limitations
1. **Fixed output directory**: Desktop destination is not configurable via arguments
2. **MKV-only output**: The script enforces `.mkv` as the output container — this is an intentional design choice since the merge always produces a Matroska container
3. **No logging**: Difficult to debug failures beyond printed error messages
4. **Platform-locked**: Windows-only solution
5. **No special character escaping**: Filenames with `&`, `%`, `!`, etc. may break commands

### Recommended Enhancements (Priority Order)
1. Make output directory configurable (via environment variable — a 4th positional argument would conflict with the too-many-args guard at `ARGUMENT VALIDATION` lines 18–22)
2. Create PowerShell alternative for better error handling and cross-platform support
3. Add option to keep/delete temporary files
4. Escape special characters in filenames
5. Add logging to a file for debugging

## Version Control Notes

### Current State
Repository contains:
- **File_Renamer.bat**: Main Windows batch utility script for merging video/audio files
- **README.md**: User-facing documentation with problem statement, requirements, usage examples, and alternatives
- **REVIEW_TASKS.md**: Code review findings — resolved tasks, open bug/doc/test tasks
- **CLAUDE.md**: Technical guide for AI assistants working with this repository
- **LICENSE**: GNU General Public License v3.0

All core functionality and documentation complete and user-ready.

### When Committing Changes
- Use descriptive commit messages
- Follow pattern: "Add [feature]", "Fix [issue]", "Update [component]"
- Commit related changes together
- Don't commit without explicit user request

### When Creating Pull Requests
- Summarize all changes in PR description
- Note any breaking changes
- Include testing instructions
- Mention Windows requirement explicitly

## Additional Context

### Why This Tool Exists
Windows has a maximum path length of 260 characters (MAX_PATH). When YouTube-DL downloads videos with long titles or is run from deep directory structures, the combined path can exceed this limit. FFmpeg can't access files with paths exceeding this limit, causing merge operations to fail. This script works around the issue by:
1. Using short randomized temporary names instead of the original long filenames
2. Operating directly in the video file's directory (shorter path)
3. Manually triggering the merge operation with full error handling and rollback

### User Workflow
1. User downloads video with YouTube-DL
2. Download creates separate video and audio files (merge failed)
3. User navigates to file location in Command Prompt
4. User runs: `File_Renamer.bat video_file audio_file desired_output_name`
5. Script merges files and copies to desktop
6. User finds merged video on desktop

### Future Considerations
- Windows 10 (1607+) supports long paths when enabled in registry
- Modern YouTube-DL alternatives (yt-dlp) handle this better
- Consider documenting enabling long path support as alternative solution
- PowerShell 7+ is cross-platform and might be better long-term solution

---

**Last Updated**: 2026-02-24 (docs sync with current script)
**For**: AI assistants working with File-Merge-and-Rename repository
**Maintained By**: Claude AI sessions working on this codebase
