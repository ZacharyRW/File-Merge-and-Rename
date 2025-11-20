# File-Merge-and-Rename

A utility to merge and rename video/audio files created by YouTube-DL that failed to merge due to Windows PATH length limitations (260 character limit).

## Overview

When YouTube-DL downloads videos with very long filenames or from deep directory structures, the file paths can exceed Windows' 260-character limit. This prevents FFmpeg from merging the separate video and audio files. This utility solves the problem by:

1. Creating temporary files with short names
2. Merging them using FFmpeg
3. Renaming the output to your desired filename
4. Cleaning up temporary files

## Versions Available

### PowerShell Version (Recommended) - `File_Renamer.ps1`

**Modern, robust script with comprehensive error handling and testing.**

**Features**:
- ✓ Full parameter validation
- ✓ FFmpeg availability checking
- ✓ Comprehensive error handling
- ✓ Configurable output directory
- ✓ Automatic cleanup
- ✓ Cross-platform support (PowerShell Core)
- ✓ Built-in help documentation
- ✓ 90%+ test coverage

**Usage**:
```powershell
# Basic usage
.\File_Renamer.ps1 -VideoFile "video.f137.mp4" -AudioFile "audio.f140.m4a" -OutputFile "My Video.mkv"

# Custom output directory
.\File_Renamer.ps1 "video.mp4" "audio.m4a" "output.mkv" -OutputDirectory "C:\Videos"

# Keep temporary files for debugging
.\File_Renamer.ps1 "video.mp4" "audio.m4a" "output.mkv" -KeepTemporaryFiles

# Get help
Get-Help .\File_Renamer.ps1 -Detailed
```

### Batch Script Version (Legacy) - `File_Renamer.bat`

**Original Windows batch script - simple but minimal error handling.**

**Usage**:
```batch
File_Renamer.bat video.f137.mp4 audio.f140.m4a "My Video.mkv"
```

**Note**: This version has hardcoded paths and no error handling. The PowerShell version is recommended for all new usage.

## Requirements

- **FFmpeg**: Must be installed and available in PATH
  - Download: https://ffmpeg.org/download.html
- **PowerShell**: 5.1+ (Windows) or PowerShell Core 7+ (cross-platform)
  - Download: https://github.com/PowerShell/PowerShell

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/ZacharyRW/File-Merge-and-Rename.git
   cd File-Merge-and-Rename
   ```

2. Ensure FFmpeg is installed:
   ```powershell
   ffmpeg -version
   ```

3. Run the script (PowerShell version):
   ```powershell
   .\File_Renamer.ps1 -VideoFile <video> -AudioFile <audio> -OutputFile <output>
   ```

## Testing

The PowerShell version includes a comprehensive test suite with 50+ tests.

**Run tests**:
```powershell
# Install Pester (if not already installed)
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run tests
Invoke-Pester -Path ./File_Renamer.Tests.ps1

# Run with coverage
Invoke-Pester -Path ./File_Renamer.Tests.ps1 -CodeCoverage ./File_Renamer.ps1
```

See [tests/README.md](tests/README.md) for detailed testing documentation.

## Documentation

- **CLAUDE.md**: Comprehensive guide for AI assistants working on this project
- **TEST_COVERAGE.md**: Detailed test coverage analysis and improvement plan
- **tests/README.md**: Testing infrastructure and procedures

## Common Issues

### FFmpeg Not Found
```
Error: FFmpeg is not installed or not in PATH
```
**Solution**: Install FFmpeg and ensure it's in your system PATH.

### Files Not Found
```
Error: Video file does not exist: video.mp4
```
**Solution**: Ensure you're running the script from the directory containing the files, or provide full paths.

### Permission Denied
```
Error: Output directory is not writable
```
**Solution**: Check directory permissions or specify a different output directory.

## How It Works

1. **Validation**: Checks that FFmpeg is available and input files exist
2. **Temporary Copies**: Creates temporary copies with short names to avoid path length issues
3. **Merge**: Uses FFmpeg to merge video and audio streams without re-encoding
4. **Finalize**: Moves merged file to output location with desired name
5. **Cleanup**: Removes temporary files

**FFmpeg Command Used**:
```bash
ffmpeg -y -loglevel error -i video -i audio -c copy -map "0:v:0" -map "1:a:0" output.mkv
```

- `-c copy`: Stream copy (no re-encoding) for fast, lossless merge
- `-map "0:v:0"`: Use video stream from first input
- `-map "1:a:0"`: Use audio stream from second input

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add/update tests as needed
5. Ensure all tests pass
6. Submit a pull request

## License

GNU General Public License v3.0

See [LICENSE](LICENSE) for full text.

## Acknowledgments

- Created to solve YouTube-DL path length issues on Windows
- Uses FFmpeg for media processing
- Inspired by the need for robust file handling in media workflows
