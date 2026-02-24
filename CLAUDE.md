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
   - `%1`: Video file name (with extension)
   - `%2`: Audio file name (with extension)
   - `%3`: Desired output file name (with extension)
2. Renames input files to temporary names (`abc`, `def`) to avoid path length issues
3. Uses ffmpeg to merge video and audio streams
4. Renames output file to user-specified name
5. Deletes temporary files
6. Copies final file to `%USERPROFILE%\Desktop`

**Key lines explained**:
- Line 10-11: Rename inputs to short temporary names
- Line 13: FFmpeg merge command with specific stream mapping
- Line 15: Rename output to desired name
- Line 17-18: Cleanup temporary files
- Line 20: Copy to desktop (hardcoded path)

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
  - Command format: `ffmpeg -i input1 -i input2 -c copy -map "0:v:0" -map "1:a:0" output`

### Platform Requirements
- **Operating System**: Windows (batch file is Windows-specific)
- **File System**: NTFS or compatible (supports file operations)

## Development Workflow

### Git Branch Information
- **Development Branch**: `claude/update-docs-ms5gg`
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
- Temporary files: Short names (`abc`, `def`, `ghi.mkv`)
- Final files: User-specified names with extensions

### Security Considerations

#### Output Path
- **Line 20**: Desktop path uses `%USERPROFILE%\Desktop`, which resolves to the current user's desktop on any Windows system
- **Note**: To change the destination, edit line 20 of `File_Renamer.bat`
- **Enhancement**: Consider accepting an optional 4th argument for a custom output directory

#### Input Validation
- **Current State**: No input validation on arguments
- **Risks**:
  - Missing arguments cause undefined behavior
  - Special characters in filenames may break commands
  - No check for file existence before operations
- **Recommendations**:
  - Add argument count validation
  - Check if input files exist
  - Validate file extensions
  - Escape special characters

#### Command Injection
- **Risk**: Batch scripts are vulnerable to command injection via filenames
- **Impact**: Malicious filenames could execute arbitrary commands
- **Mitigation**: Always quote variables: `"%1"` instead of `%1`

#### File Cleanup
- **Line 17-18**: Deletes temporary files after merge
- **Good**: Prevents file buildup
- **Risk**: If ffmpeg fails, temporary files remain
- **Recommendation**: Add error checking before cleanup

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
- Validating ffmpeg installation before running
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
ffmpeg -y -loglevel "repeat+info" -i "abc" -i "def" -c copy -map "0:v:0" -map "1:a:0" "ghi.mkv"
```

**Flags explained**:
- `-y`: Overwrite output file without prompting
- `-loglevel "repeat+info"`: Set logging verbosity
- `-i "abc"`: First input (video file)
- `-i "def"`: Second input (audio file)
- `-c copy`: Copy streams without re-encoding (fast)
- `-map "0:v:0"`: Map first video stream from first input
- `-map "1:a:0"`: Map first audio stream from second input
- `"ghi.mkv"`: Output file (Matroska container)

**Why this approach**:
- Stream copy (`-c copy`) avoids re-encoding (preserves quality, very fast)
- Explicit stream mapping ensures correct video/audio pairing
- MKV container supports wide variety of codecs

## Potential Issues and Solutions

### Issue: Script fails on other users' systems
**Cause**: Hardcoded desktop path (line 20)
**Solution**: Use `%USERPROFILE%\Desktop` or accept output directory as parameter

### Issue: Files with spaces in names
**Cause**: Unquoted variables
**Solution**: Quote all variable references: `RENAME "%1" abc`

### Issue: Missing FFmpeg
**Cause**: FFmpeg not in PATH
**Solution**: Add check at script start:
```batch
where ffmpeg >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo FFmpeg not found. Please install FFmpeg and add to PATH.
    exit /b 1
)
```

### Issue: Wrong number of arguments
**Cause**: No parameter validation
**Solution**: Add validation at script start:
```batch
if "%~3"=="" (
    echo Usage: File_Renamer.bat video_file audio_file output_name
    exit /b 1
)
```

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
1. **No error handling**: Script continues even if operations fail
2. **Hardcoded paths**: Desktop location specific to one user
3. **No input validation**: Assumes correct usage
4. **No logging**: Difficult to debug failures
5. **Platform-locked**: Windows-only solution

### Recommended Enhancements (Priority Order)
1. Add input validation and error messages
2. Make output directory configurable
3. Quote all variable references for safety
4. Add FFmpeg existence check
5. Provide usage help when arguments missing
6. Create PowerShell alternative for better error handling
7. Add option to keep/delete temporary files
8. Support different output formats beyond MKV

## Version Control Notes

### Current State
Repository contains:
- **File_Renamer.bat**: Main Windows batch utility script for merging video/audio files
- **README.md**: User-facing documentation with problem statement, requirements, usage examples, and alternatives
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
1. Using very short temporary names (3 characters)
2. Operating in the current directory (shorter path)
3. Manually triggering the merge operation

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

**Last Updated**: 2026-02-24
**For**: AI assistants working with File-Merge-and-Rename repository
**Maintained By**: Claude AI sessions working on this codebase
