<#
.SYNOPSIS
    Creates test fixture files for File_Renamer tests

.DESCRIPTION
    This script generates dummy video and audio files for testing purposes.
    These are not real media files, just binary data of appropriate sizes.

.NOTES
    For real integration testing, you may want to use actual small media files.
    You can create valid test files with FFmpeg:
        ffmpeg -f lavfi -i testsrc=duration=1:size=320x240:rate=1 -pix_fmt yuv420p test_video.mp4
        ffmpeg -f lavfi -i sine=frequency=1000:duration=1 test_audio.m4a
#>

$fixturesPath = $PSScriptRoot

Write-Host "Creating test fixtures in: $fixturesPath" -ForegroundColor Cyan

# Function to create dummy file with random content
function New-DummyFile {
    param(
        [string]$Path,
        [int]$SizeInKB
    )

    $sizeInBytes = $SizeInKB * 1024
    $content = [byte[]]::new($sizeInBytes)
    (New-Object Random).NextBytes($content)
    [System.IO.File]::WriteAllBytes($Path, $content)

    $fileInfo = Get-Item -Path $Path
    Write-Host "  Created: $($fileInfo.Name) ($($fileInfo.Length) bytes)" -ForegroundColor Green
}

# Create standard test files
Write-Host "`nCreating standard test files..." -ForegroundColor Yellow
New-DummyFile -Path (Join-Path $fixturesPath "valid_video.mp4") -SizeInKB 100
New-DummyFile -Path (Join-Path $fixturesPath "valid_audio.m4a") -SizeInKB 50

# Create edge case files
Write-Host "`nCreating edge case test files..." -ForegroundColor Yellow
New-DummyFile -Path (Join-Path $fixturesPath "empty_video.mp4") -SizeInKB 0
New-DummyFile -Path (Join-Path $fixturesPath "empty_audio.m4a") -SizeInKB 0
New-DummyFile -Path (Join-Path $fixturesPath "tiny_video.mp4") -SizeInKB 1
New-DummyFile -Path (Join-Path $fixturesPath "tiny_audio.m4a") -SizeInKB 1

# Create files with special characters in names
Write-Host "`nCreating files with special characters..." -ForegroundColor Yellow
New-DummyFile -Path (Join-Path $fixturesPath "video with spaces.mp4") -SizeInKB 75
New-DummyFile -Path (Join-Path $fixturesPath "audio with spaces.m4a") -SizeInKB 40
New-DummyFile -Path (Join-Path $fixturesPath "video(with)parens.mp4") -SizeInKB 75
New-DummyFile -Path (Join-Path $fixturesPath "audio[with]brackets.m4a") -SizeInKB 40

# Create large file (for performance testing)
Write-Host "`nCreating large test file..." -ForegroundColor Yellow
New-DummyFile -Path (Join-Path $fixturesPath "large_video.mp4") -SizeInKB 10240  # 10 MB

Write-Host "`nTest fixtures created successfully!" -ForegroundColor Green
Write-Host "`nNote: These are dummy files, not real media. For full integration testing," -ForegroundColor Gray
Write-Host "consider creating actual media files using FFmpeg (see script comments)." -ForegroundColor Gray
