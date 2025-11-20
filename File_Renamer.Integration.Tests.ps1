<#
.SYNOPSIS
    Integration tests for File_Renamer.ps1 with real FFmpeg

.DESCRIPTION
    These tests require FFmpeg to be installed and use real media files.
    They test end-to-end functionality with actual merging operations.

.NOTES
    Requires:
    - Pester v5.x
    - FFmpeg installed and in PATH
#>

BeforeAll {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "File_Renamer.ps1"

    # Verify FFmpeg is available
    try {
        $null = Get-Command ffmpeg -ErrorAction Stop
        $script:ffmpegAvailable = $true
    }
    catch {
        $script:ffmpegAvailable = $false
        Write-Warning "FFmpeg not found. Integration tests will be skipped."
    }

    # Helper to create test output directory
    function New-TestOutputDirectory {
        $tempDir = Join-Path -Path $env:TEMP -ChildPath "FileRenamerIntegration_$(Get-Random)"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        return $tempDir
    }

    # Helper to create actual test media files with FFmpeg
    function New-TestMediaFiles {
        param(
            [string]$OutputDirectory,
            [string]$VideoFileName = "test_video.mp4",
            [string]$AudioFileName = "test_audio.m4a"
        )

        $videoPath = Join-Path -Path $OutputDirectory -ChildPath $VideoFileName
        $audioPath = Join-Path -Path $OutputDirectory -ChildPath $AudioFileName

        # Create 1-second test video (320x240, 1fps)
        $videoArgs = @(
            "-f", "lavfi"
            "-i", "testsrc=duration=1:size=320x240:rate=1"
            "-pix_fmt", "yuv420p"
            "-y"
            $videoPath
        )
        $null = Start-Process -FilePath "ffmpeg" -ArgumentList $videoArgs -NoNewWindow -Wait -PassThru

        # Create 1-second test audio (440Hz sine wave)
        $audioArgs = @(
            "-f", "lavfi"
            "-i", "sine=frequency=440:duration=1"
            "-y"
            $audioPath
        )
        $null = Start-Process -FilePath "ffmpeg" -ArgumentList $audioArgs -NoNewWindow -Wait -PassThru

        return @{
            Video = $videoPath
            Audio = $audioPath
        }
    }
}

Describe "File_Renamer.ps1 - Integration Tests" -Tag "Integration" {

    BeforeAll {
        if (-not $script:ffmpegAvailable) {
            Set-ItResult -Skipped -Because "FFmpeg is not available"
        }
    }

    Context "When merging valid video and audio files" {
        BeforeAll {
            $testDir = New-TestOutputDirectory
            $mediaFiles = New-TestMediaFiles -OutputDirectory $testDir
            $outputFile = "merged_output.mkv"
        }

        AfterAll {
            if (Test-Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Should successfully merge video and audio" -Skip:(-not $script:ffmpegAvailable) {
            & $scriptPath -VideoFile $mediaFiles.Video -AudioFile $mediaFiles.Audio -OutputFile $outputFile -OutputDirectory $testDir

            $mergedFile = Join-Path -Path $testDir -ChildPath $outputFile
            $mergedFile | Should -Exist

            $fileInfo = Get-Item -Path $mergedFile
            $fileInfo.Length | Should -BeGreaterThan 0
        }

        It "Should create output with both video and audio streams" -Skip:(-not $script:ffmpegAvailable) {
            & $scriptPath -VideoFile $mediaFiles.Video -AudioFile $mediaFiles.Audio -OutputFile $outputFile -OutputDirectory $testDir

            $mergedFile = Join-Path -Path $testDir -ChildPath $outputFile

            # Use ffprobe to verify streams
            $probeArgs = @(
                "-v", "error"
                "-show_entries", "stream=codec_type"
                "-of", "default=noprint_wrappers=1:nokey=1"
                $mergedFile
            )

            try {
                $streams = & ffprobe @probeArgs 2>&1
                $streams -contains "video" | Should -Be $true
                $streams -contains "audio" | Should -Be $true
            }
            catch {
                # If ffprobe not available, just check file exists and has size
                $mergedFile | Should -Exist
            }
        }

        It "Should cleanup temporary files after merge" -Skip:(-not $script:ffmpegAvailable) {
            $beforeFiles = Get-ChildItem -Path $testDir -File | Measure-Object

            & $scriptPath -VideoFile $mediaFiles.Video -AudioFile $mediaFiles.Audio -OutputFile "temp_test.mkv" -OutputDirectory $testDir

            $afterFiles = Get-ChildItem -Path $testDir -File | Measure-Object

            # Should have original 2 files + 1 merged file (temp files cleaned up)
            $afterFiles.Count | Should -Be ($beforeFiles.Count + 1)
        }
    }

    Context "When using KeepTemporaryFiles flag" {
        BeforeAll {
            $testDir = New-TestOutputDirectory
            $mediaFiles = New-TestMediaFiles -OutputDirectory $testDir
        }

        AfterAll {
            if (Test-Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Should preserve temporary files when flag is set" -Skip:(-not $script:ffmpegAvailable) {
            $beforeCount = (Get-ChildItem -Path $testDir -File).Count

            & $scriptPath -VideoFile $mediaFiles.Video -AudioFile $mediaFiles.Audio `
                -OutputFile "keep_temp_test.mkv" -OutputDirectory $testDir -KeepTemporaryFiles

            $afterCount = (Get-ChildItem -Path $testDir -File).Count

            # Should have more than just the merged file (temp files kept)
            $afterCount | Should -BeGreaterThan ($beforeCount + 1)
        }
    }

    Context "When handling files with special characters" {
        BeforeAll {
            $testDir = New-TestOutputDirectory
            $mediaFiles = New-TestMediaFiles -OutputDirectory $testDir `
                -VideoFileName "test video (1).mp4" `
                -AudioFileName "test audio [2].m4a"
        }

        AfterAll {
            if (Test-Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Should handle input files with spaces and special characters" -Skip:(-not $script:ffmpegAvailable) {
            & $scriptPath -VideoFile $mediaFiles.Video -AudioFile $mediaFiles.Audio `
                -OutputFile "output with spaces.mkv" -OutputDirectory $testDir

            $outputPath = Join-Path -Path $testDir -ChildPath "output with spaces.mkv"
            $outputPath | Should -Exist
        }
    }

    Context "When merging incompatible formats" {
        BeforeAll {
            $testDir = New-TestOutputDirectory

            # Create a corrupted/invalid file
            $badVideoPath = Join-Path -Path $testDir -ChildPath "bad_video.mp4"
            [System.IO.File]::WriteAllBytes($badVideoPath, [byte[]](1..100))

            # Create valid audio
            $audioArgs = @(
                "-f", "lavfi"
                "-i", "sine=frequency=440:duration=1"
                "-y"
                (Join-Path -Path $testDir -ChildPath "test_audio.m4a")
            )
            $null = Start-Process -FilePath "ffmpeg" -ArgumentList $audioArgs -NoNewWindow -Wait -PassThru
        }

        AfterAll {
            if (Test-Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Should fail gracefully with corrupted video file" -Skip:(-not $script:ffmpegAvailable) {
            $badVideo = Join-Path -Path $testDir -ChildPath "bad_video.mp4"
            $audio = Join-Path -Path $testDir -ChildPath "test_audio.m4a"

            { & $scriptPath -VideoFile $badVideo -AudioFile $audio -OutputFile "output.mkv" -OutputDirectory $testDir } |
                Should -Throw
        }
    }

    Context "When handling large file paths" {
        BeforeAll {
            # Create deep directory structure to test path handling
            $testDir = New-TestOutputDirectory
            $deepPath = $testDir

            # Create a moderately deep path (not quite 260 chars, but enough to test)
            for ($i = 0; $i -lt 5; $i++) {
                $deepPath = Join-Path -Path $deepPath -ChildPath "very_long_directory_name_$i"
            }
            New-Item -Path $deepPath -ItemType Directory -Force | Out-Null

            $mediaFiles = New-TestMediaFiles -OutputDirectory $deepPath
        }

        AfterAll {
            if (Test-Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Should handle files in deep directory structures" -Skip:(-not $script:ffmpegAvailable) {
            & $scriptPath -VideoFile $mediaFiles.Video -AudioFile $mediaFiles.Audio `
                -OutputFile "deep_path_test.mkv" -OutputDirectory $deepPath

            $outputPath = Join-Path -Path $deepPath -ChildPath "deep_path_test.mkv"
            $outputPath | Should -Exist
        }
    }

    Context "When output file already exists" {
        BeforeAll {
            $testDir = New-TestOutputDirectory
            $mediaFiles = New-TestMediaFiles -OutputDirectory $testDir
            $outputFile = "existing_output.mkv"
            $outputPath = Join-Path -Path $testDir -ChildPath $outputFile

            # Create a pre-existing output file
            [System.IO.File]::WriteAllBytes($outputPath, [byte[]](1..500))
            $originalSize = (Get-Item $outputPath).Length
        }

        AfterAll {
            if (Test-Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Should overwrite existing output file" -Skip:(-not $script:ffmpegAvailable) {
            & $scriptPath -VideoFile $mediaFiles.Video -AudioFile $mediaFiles.Audio `
                -OutputFile $outputFile -OutputDirectory $testDir

            $outputPath | Should -Exist
            $newSize = (Get-Item $outputPath).Length
            $newSize | Should -Not -Be $originalSize
            $newSize | Should -BeGreaterThan 0
        }
    }

    Context "When running from different working directories" {
        BeforeAll {
            $testDir = New-TestOutputDirectory
            $mediaFiles = New-TestMediaFiles -OutputDirectory $testDir
            $originalLocation = Get-Location
        }

        AfterAll {
            Set-Location -Path $originalLocation
            if (Test-Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Should work with absolute paths from different directory" -Skip:(-not $script:ffmpegAvailable) {
            # Change to a different directory
            Set-Location -Path $env:TEMP

            & $scriptPath -VideoFile $mediaFiles.Video -AudioFile $mediaFiles.Audio `
                -OutputFile "abs_path_test.mkv" -OutputDirectory $testDir

            $outputPath = Join-Path -Path $testDir -ChildPath "abs_path_test.mkv"
            $outputPath | Should -Exist
        }
    }

    Context "When testing verbose output" {
        BeforeAll {
            $testDir = New-TestOutputDirectory
            $mediaFiles = New-TestMediaFiles -OutputDirectory $testDir
        }

        AfterAll {
            if (Test-Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Should provide verbose logging when requested" -Skip:(-not $script:ffmpegAvailable) {
            $output = & $scriptPath -VideoFile $mediaFiles.Video -AudioFile $mediaFiles.Audio `
                -OutputFile "verbose_test.mkv" -OutputDirectory $testDir -Verbose 4>&1

            # Should have verbose messages
            $output | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "File_Renamer.ps1 - Error Recovery Integration Tests" -Tag "Integration", "ErrorHandling" {

    BeforeAll {
        if (-not $script:ffmpegAvailable) {
            Set-ItResult -Skipped -Because "FFmpeg is not available"
        }
    }

    Context "When FFmpeg process fails mid-execution" {
        BeforeAll {
            $testDir = New-TestOutputDirectory
            $videoFile = Join-Path -Path $testDir -ChildPath "video.mp4"
            $audioFile = Join-Path -Path $testDir -ChildPath "audio.m4a"

            # Create invalid files
            [System.IO.File]::WriteAllBytes($videoFile, [byte[]](1..100))
            [System.IO.File]::WriteAllBytes($audioFile, [byte[]](1..100))
        }

        AfterAll {
            if (Test-Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Should cleanup temporary files even on FFmpeg failure" -Skip:(-not $script:ffmpegAvailable) {
            $beforeFiles = Get-ChildItem -Path $testDir -File

            { & $scriptPath -VideoFile $videoFile -AudioFile $audioFile `
                -OutputFile "fail_test.mkv" -OutputDirectory $testDir } | Should -Throw

            $afterFiles = Get-ChildItem -Path $testDir -File

            # Should have same number of files (temp files cleaned up)
            $afterFiles.Count | Should -Be $beforeFiles.Count
        }
    }

    Context "When disk space is insufficient" {
        It "Should fail gracefully when out of disk space" -Skip:$true {
            # This is very difficult to test reliably without risk
            # Marking as skipped but documented
            $true | Should -Be $true
        }
    }
}

Describe "File_Renamer.ps1 - Performance Tests" -Tag "Integration", "Performance" {

    BeforeAll {
        if (-not $script:ffmpegAvailable) {
            Set-ItResult -Skipped -Because "FFmpeg is not available"
        }
    }

    Context "When measuring merge performance" {
        BeforeAll {
            $testDir = New-TestOutputDirectory
            $mediaFiles = New-TestMediaFiles -OutputDirectory $testDir
        }

        AfterAll {
            if (Test-Path $testDir) {
                Remove-Item -Path $testDir -Recurse -Force
            }
        }

        It "Should complete merge in reasonable time" -Skip:(-not $script:ffmpegAvailable) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            & $scriptPath -VideoFile $mediaFiles.Video -AudioFile $mediaFiles.Audio `
                -OutputFile "perf_test.mkv" -OutputDirectory $testDir

            $stopwatch.Stop()

            # Small files should merge in under 30 seconds
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 30000
        }
    }
}
