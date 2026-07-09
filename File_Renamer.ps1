<#
.SYNOPSIS
    Merges a video file and an audio file with FFmpeg.

.DESCRIPTION
    PowerShell port of File_Renamer.bat. The contract intentionally mirrors the
    batch script: exactly three positional arguments, input files in the same
    directory, a plain .mkv output filename, short temporary renames to avoid
    Windows MAX_PATH issues, rollback on merge failures, and a warning-only
    copy to the current user's Desktop.

.EXAMPLE
    .\File_Renamer.ps1 video.f137.mp4 audio.f140.m4a "My Final Video.mkv"

.NOTES
    Requires FFmpeg to be installed and available on PATH.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

function Write-Usage {
    Write-Host "Usage: File_Renamer.ps1 video_file audio_file output_name"
}

function Exit-WithLocationRestore {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Code,

        [Parameter(Mandatory = $true)]
        [bool]$LocationWasPushed
    )

    if ($LocationWasPushed) {
        Pop-Location
    }

    exit $Code
}

function Get-FullPathFromCurrentLocation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetFullPath($Path, (Get-Location).ProviderPath)
}

function Test-SameDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FirstDirectory,

        [Parameter(Mandatory = $true)]
        [string]$SecondDirectory
    )

    $firstFull = [System.IO.Path]::GetFullPath($FirstDirectory).TrimEnd('\', '/')
    $secondFull = [System.IO.Path]::GetFullPath($SecondDirectory).TrimEnd('\', '/')
    return [string]::Equals($firstFull, $secondFull, [System.StringComparison]::OrdinalIgnoreCase)
}

function New-TemporaryNames {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VideoExtension,

        [Parameter(Mandatory = $true)]
        [string]$AudioExtension,

        [int]$MaximumAttempts = 100
    )

    for ($attempt = 1; $attempt -le $MaximumAttempts; $attempt++) {
        $base = "frm_$(Get-Random -Minimum 0 -Maximum 32768)"
        $candidate = [pscustomobject]@{
            Video = "${base}_v${VideoExtension}"
            Audio = "${base}_a${AudioExtension}"
            Output = "${base}_out.mkv"
        }

        if (
            -not (Test-Path -LiteralPath $candidate.Video) -and
            -not (Test-Path -LiteralPath $candidate.Audio) -and
            -not (Test-Path -LiteralPath $candidate.Output)
        ) {
            return $candidate
        }
    }

    throw "Could not generate unique temporary filenames after $MaximumAttempts attempts."
}

function Remove-FileIfPresent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        try {
            Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
        }
        catch {
            return
        }
    }
}

if ($Arguments.Count -lt 3) {
    Write-Usage
    exit 1
}

if ($Arguments.Count -gt 3) {
    Write-Host "Error: Too many arguments. Expected exactly three."
    Write-Usage
    exit 1
}

$VideoFile = $Arguments[0]
$AudioFile = $Arguments[1]
$OutputFile = $Arguments[2]

if ([string]::IsNullOrWhiteSpace($VideoFile) -or [string]::IsNullOrWhiteSpace($AudioFile) -or [string]::IsNullOrWhiteSpace($OutputFile)) {
    Write-Usage
    exit 1
}

if ($OutputFile.Contains('\')) {
    Write-Host 'Error: Output name must be a plain filename (no backslashes). Example: "My Video.mkv"'
    exit 1
}

if ($OutputFile.Contains('/')) {
    Write-Host 'Error: Output name must be a plain filename (no forward slashes). Example: "My Video.mkv"'
    exit 1
}

if ($OutputFile.Contains(':')) {
    Write-Host 'Error: Output name must be a plain filename (no drive letter). Example: "My Video.mkv"'
    exit 1
}

if (-not [string]::Equals([System.IO.Path]::GetExtension($OutputFile), ".mkv", [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "Error: Output filename must use the .mkv extension. Received: `"$([System.IO.Path]::GetFileName($OutputFile))`""
    exit 1
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "Error: FFmpeg not found. Please install FFmpeg and add it to your PATH."
    exit 1
}

$locationWasPushed = $false
$renamedVideo = $false
$renamedAudio = $false
$temporaryNames = $null
$videoName = $null
$audioName = $null

try {
    $videoFullPath = Get-FullPathFromCurrentLocation -Path $VideoFile
    $videoDirectory = [System.IO.Path]::GetDirectoryName($videoFullPath)

    if ([string]::IsNullOrEmpty($videoDirectory) -or -not (Test-Path -LiteralPath $videoDirectory -PathType Container)) {
        Write-Host "Error: Could not change to directory `"$videoDirectory`"."
        exit 1
    }

    Push-Location -LiteralPath $videoDirectory
    $locationWasPushed = $true

    $audioFullPath = Get-FullPathFromCurrentLocation -Path $AudioFile
    $audioDirectory = [System.IO.Path]::GetDirectoryName($audioFullPath)

    if (-not (Test-SameDirectory -FirstDirectory $videoDirectory -SecondDirectory $audioDirectory)) {
        Write-Host "Error: Both input files must be in the same directory."
        Write-Host "  Video directory: `"$videoDirectory`""
        Write-Host "  Audio directory: `"$audioDirectory`""
        Exit-WithLocationRestore -Code 1 -LocationWasPushed $locationWasPushed
    }

    $videoName = [System.IO.Path]::GetFileName($VideoFile)
    $audioName = [System.IO.Path]::GetFileName($AudioFile)
    $outputName = [System.IO.Path]::GetFileName($OutputFile)

    $temporaryNames = New-TemporaryNames `
        -VideoExtension ([System.IO.Path]::GetExtension($videoName)) `
        -AudioExtension ([System.IO.Path]::GetExtension($audioName))

    if (-not (Test-Path -LiteralPath $videoName -PathType Leaf)) {
        Write-Host "Error: Video file `"$videoName`" not found in `"$videoDirectory`"."
        Exit-WithLocationRestore -Code 1 -LocationWasPushed $locationWasPushed
    }

    if (-not (Test-Path -LiteralPath $audioName -PathType Leaf)) {
        Write-Host "Error: Audio file `"$audioName`" not found in `"$videoDirectory`"."
        Exit-WithLocationRestore -Code 1 -LocationWasPushed $locationWasPushed
    }

    try {
        Move-Item -LiteralPath $videoName -Destination $temporaryNames.Video -ErrorAction Stop
        $renamedVideo = $true
    }
    catch {
        Write-Host "Error: Could not rename `"$VideoFile`"."
        Exit-WithLocationRestore -Code 1 -LocationWasPushed $locationWasPushed
    }

    try {
        Move-Item -LiteralPath $audioName -Destination $temporaryNames.Audio -ErrorAction Stop
        $renamedAudio = $true
    }
    catch {
        if ($renamedVideo -and (Test-Path -LiteralPath $temporaryNames.Video)) {
            Move-Item -LiteralPath $temporaryNames.Video -Destination $videoName -ErrorAction SilentlyContinue
        }
        Write-Host "Error: Could not rename `"$AudioFile`"."
        Exit-WithLocationRestore -Code 1 -LocationWasPushed $locationWasPushed
    }

    $ffmpegArguments = @(
        "-y"
        "-loglevel", "repeat+info"
        "-i", $temporaryNames.Video
        "-i", $temporaryNames.Audio
        "-c", "copy"
        "-map", "0:v:0"
        "-map", "1:a:0"
        $temporaryNames.Output
    )

    & ffmpeg @ffmpegArguments
    $ffmpegExitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }

    if ($ffmpegExitCode -ne 0) {
        Remove-FileIfPresent -Path $temporaryNames.Output
        if (Test-Path -LiteralPath $temporaryNames.Video) {
            Move-Item -LiteralPath $temporaryNames.Video -Destination $videoName -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $temporaryNames.Audio) {
            Move-Item -LiteralPath $temporaryNames.Audio -Destination $audioName -ErrorAction SilentlyContinue
        }
        Write-Host "Error: FFmpeg merge failed."
        Exit-WithLocationRestore -Code $ffmpegExitCode -LocationWasPushed $locationWasPushed
    }

    try {
        Move-Item -LiteralPath $temporaryNames.Output -Destination $outputName -ErrorAction Stop
    }
    catch {
        if (Test-Path -LiteralPath $temporaryNames.Video) {
            Move-Item -LiteralPath $temporaryNames.Video -Destination $videoName -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $temporaryNames.Audio) {
            Move-Item -LiteralPath $temporaryNames.Audio -Destination $audioName -ErrorAction SilentlyContinue
        }
        Write-Host "Error: Could not rename output to `"$OutputFile`". Merged file remains at `"$($temporaryNames.Output)`"."
        Exit-WithLocationRestore -Code 1 -LocationWasPushed $locationWasPushed
    }

    Remove-FileIfPresent -Path $temporaryNames.Video
    if (Test-Path -LiteralPath $temporaryNames.Video) {
        Write-Host "Warning: Could not delete temporary file `"$($temporaryNames.Video)`"."
    }

    Remove-FileIfPresent -Path $temporaryNames.Audio
    if (Test-Path -LiteralPath $temporaryNames.Audio) {
        Write-Host "Warning: Could not delete temporary file `"$($temporaryNames.Audio)`"."
    }

    $desktopDirectory = if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        "Desktop"
    }
    else {
        Join-Path -Path $env:USERPROFILE -ChildPath "Desktop"
    }
    try {
        Copy-Item -LiteralPath $outputName -Destination $desktopDirectory -ErrorAction Stop
        Write-Host "Success: `"$outputName`" merged and copied to Desktop."
    }
    catch {
        Write-Host "Warning: Could not copy `"$outputName`" to Desktop. The merged file remains in `"$(Get-Location)`"."
    }

    Exit-WithLocationRestore -Code 0 -LocationWasPushed $locationWasPushed
}
catch {
    if ($renamedVideo -and $null -ne $temporaryNames -and $null -ne $videoName -and (Test-Path -LiteralPath $temporaryNames.Video) -and -not (Test-Path -LiteralPath $videoName)) {
        Move-Item -LiteralPath $temporaryNames.Video -Destination $videoName -ErrorAction SilentlyContinue
    }
    if ($renamedAudio -and $null -ne $temporaryNames -and $null -ne $audioName -and (Test-Path -LiteralPath $temporaryNames.Audio) -and -not (Test-Path -LiteralPath $audioName)) {
        Move-Item -LiteralPath $temporaryNames.Audio -Destination $audioName -ErrorAction SilentlyContinue
    }

    Write-Host "Error: $($_.Exception.Message)"
    Exit-WithLocationRestore -Code 1 -LocationWasPushed $locationWasPushed
}
