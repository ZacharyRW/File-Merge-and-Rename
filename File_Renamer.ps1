<#
.SYNOPSIS
    Merges video and audio files using FFmpeg with proper error handling.

.DESCRIPTION
    This script merges separate video and audio files (typically from YouTube-DL)
    using FFmpeg. It handles Windows path length limitations by using temporary
    short filenames during the merge process.

.PARAMETER VideoFile
    Path to the video file (e.g., video.f137.mp4)

.PARAMETER AudioFile
    Path to the audio file (e.g., audio.f140.m4a)

.PARAMETER OutputFile
    Desired name for the merged output file (e.g., "My Video.mkv")

.PARAMETER OutputDirectory
    Directory where the final file should be copied. Defaults to user's Desktop.

.PARAMETER KeepTemporaryFiles
    If specified, temporary files will not be deleted (useful for debugging)

.EXAMPLE
    .\File_Renamer.ps1 -VideoFile "video.mp4" -AudioFile "audio.m4a" -OutputFile "merged.mkv"

.EXAMPLE
    .\File_Renamer.ps1 "video.mp4" "audio.m4a" "merged.mkv" -OutputDirectory "C:\Videos"

.NOTES
    Requires FFmpeg to be installed and available in PATH.
    Version: 2.0
    License: GNU GPL v3.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to the video file")]
    [ValidateNotNullOrEmpty()]
    [string]$VideoFile,

    [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Path to the audio file")]
    [ValidateNotNullOrEmpty()]
    [string]$AudioFile,

    [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Name for the output file")]
    [ValidateNotNullOrEmpty()]
    [string]$OutputFile,

    [Parameter(Mandatory = $false, HelpMessage = "Directory to copy the final file to")]
    [string]$OutputDirectory = "$env:USERPROFILE\Desktop",

    [Parameter(Mandatory = $false, HelpMessage = "Keep temporary files for debugging")]
    [switch]$KeepTemporaryFiles
)

# Script configuration
$ErrorActionPreference = "Stop"
$TempVideoName = "temp_video_$(Get-Random)"
$TempAudioName = "temp_audio_$(Get-Random)"
$TempOutputName = "temp_output_$(Get-Random).mkv"

# Function to check if FFmpeg is available
function Test-FFmpegAvailable {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $null = Get-Command ffmpeg -ErrorAction Stop
        Write-Verbose "FFmpeg found in PATH"
        return $true
    }
    catch {
        Write-Error "FFmpeg is not installed or not in PATH. Please install FFmpeg and ensure it's accessible from the command line."
        return $false
    }
}

# Function to validate file exists and is readable
function Test-FileAccessible {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$FileDescription
    )

    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "$FileDescription does not exist: $FilePath"
        return $false
    }

    try {
        $fileInfo = Get-Item -Path $FilePath -ErrorAction Stop
        if ($fileInfo.Length -eq 0) {
            Write-Warning "$FileDescription is empty (0 bytes): $FilePath"
        }
        Write-Verbose "$FileDescription validated: $FilePath ($($fileInfo.Length) bytes)"
        return $true
    }
    catch {
        Write-Error "Cannot access $FileDescription: $FilePath - $($_.Exception.Message)"
        return $false
    }
}

# Function to validate output directory exists and is writable
function Test-OutputDirectory {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    if (-not (Test-Path -Path $Directory -PathType Container)) {
        Write-Warning "Output directory does not exist: $Directory"
        try {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
            Write-Verbose "Created output directory: $Directory"
            return $true
        }
        catch {
            Write-Error "Cannot create output directory: $Directory - $($_.Exception.Message)"
            return $false
        }
    }

    # Test write permissions
    $testFile = Join-Path -Path $Directory -ChildPath ".write_test_$(Get-Random).tmp"
    try {
        New-Item -Path $testFile -ItemType File -Force | Out-Null
        Remove-Item -Path $testFile -Force
        Write-Verbose "Output directory is writable: $Directory"
        return $true
    }
    catch {
        Write-Error "Output directory is not writable: $Directory - $($_.Exception.Message)"
        return $false
    }
}

# Function to cleanup temporary files
function Remove-TemporaryFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Files
    )

    foreach ($file in $Files) {
        if (Test-Path -Path $file) {
            try {
                Remove-Item -Path $file -Force -ErrorAction Stop
                Write-Verbose "Deleted temporary file: $file"
            }
            catch {
                Write-Warning "Could not delete temporary file: $file - $($_.Exception.Message)"
            }
        }
    }
}

# Main script execution
try {
    Write-Host "=== File Merge and Rename Tool ===" -ForegroundColor Cyan
    Write-Host "Video: $VideoFile" -ForegroundColor Gray
    Write-Host "Audio: $AudioFile" -ForegroundColor Gray
    Write-Host "Output: $OutputFile" -ForegroundColor Gray
    Write-Host ""

    # Step 1: Validate FFmpeg availability
    Write-Host "[1/6] Checking FFmpeg..." -ForegroundColor Yellow
    if (-not (Test-FFmpegAvailable)) {
        exit 1
    }
    Write-Host "      FFmpeg is available" -ForegroundColor Green

    # Step 2: Validate input files
    Write-Host "[2/6] Validating input files..." -ForegroundColor Yellow
    $videoPath = Resolve-Path -Path $VideoFile -ErrorAction Stop
    $audioPath = Resolve-Path -Path $AudioFile -ErrorAction Stop

    if (-not (Test-FileAccessible -FilePath $videoPath -FileDescription "Video file")) {
        exit 1
    }
    if (-not (Test-FileAccessible -FilePath $audioPath -FileDescription "Audio file")) {
        exit 1
    }
    Write-Host "      Input files validated" -ForegroundColor Green

    # Step 3: Validate output directory
    Write-Host "[3/6] Validating output directory..." -ForegroundColor Yellow
    if (-not (Test-OutputDirectory -Directory $OutputDirectory)) {
        exit 1
    }
    Write-Host "      Output directory ready: $OutputDirectory" -ForegroundColor Green

    # Step 4: Rename files to temporary names
    Write-Host "[4/6] Creating temporary files..." -ForegroundColor Yellow
    $workingDir = Get-Location
    $tempVideo = Join-Path -Path $workingDir -ChildPath $TempVideoName
    $tempAudio = Join-Path -Path $workingDir -ChildPath $TempAudioName
    $tempOutput = Join-Path -Path $workingDir -ChildPath $TempOutputName

    Copy-Item -Path $videoPath -Destination $tempVideo -Force
    Copy-Item -Path $audioPath -Destination $tempAudio -Force
    Write-Verbose "Created temporary copies: $tempVideo, $tempAudio"
    Write-Host "      Temporary files created" -ForegroundColor Green

    # Step 5: Merge files with FFmpeg
    Write-Host "[5/6] Merging files with FFmpeg..." -ForegroundColor Yellow
    $ffmpegArgs = @(
        "-y"
        "-loglevel", "error"
        "-i", $tempVideo
        "-i", $tempAudio
        "-c", "copy"
        "-map", "0:v:0"
        "-map", "1:a:0"
        $tempOutput
    )

    $ffmpegProcess = Start-Process -FilePath "ffmpeg" -ArgumentList $ffmpegArgs -NoNewWindow -Wait -PassThru

    if ($ffmpegProcess.ExitCode -ne 0) {
        throw "FFmpeg merge failed with exit code $($ffmpegProcess.ExitCode)"
    }

    if (-not (Test-Path -Path $tempOutput)) {
        throw "FFmpeg completed but output file was not created"
    }

    $outputInfo = Get-Item -Path $tempOutput
    if ($outputInfo.Length -eq 0) {
        throw "FFmpeg created an empty output file"
    }

    Write-Host "      Merge completed ($($outputInfo.Length) bytes)" -ForegroundColor Green

    # Step 6: Rename and copy to destination
    Write-Host "[6/6] Finalizing output..." -ForegroundColor Yellow
    $finalPath = Join-Path -Path $OutputDirectory -ChildPath $OutputFile

    Move-Item -Path $tempOutput -Destination $finalPath -Force
    Write-Host "      Output saved: $finalPath" -ForegroundColor Green

    # Cleanup
    if (-not $KeepTemporaryFiles) {
        Write-Verbose "Cleaning up temporary files..."
        Remove-TemporaryFiles -Files @($tempVideo, $tempAudio)
    }
    else {
        Write-Warning "Temporary files kept: $tempVideo, $tempAudio"
    }

    Write-Host ""
    Write-Host "=== SUCCESS ===" -ForegroundColor Green
    Write-Host "Merged file created: $finalPath" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host ""
    Write-Host "=== ERROR ===" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack Trace:" -ForegroundColor Gray
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray

    # Cleanup on error
    if (-not $KeepTemporaryFiles) {
        Write-Verbose "Cleaning up after error..."
        Remove-TemporaryFiles -Files @($tempVideo, $tempAudio, $tempOutput)
    }

    exit 1
}
