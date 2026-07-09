<#
.SYNOPSIS
    Creates small dummy fixture files for manual Pester runs.

.DESCRIPTION
    The automated suite creates isolated fixtures in Pester's TestDrive. This
    helper is kept for manual exploration and for contributors who want stable
    sample files under tests/fixtures.
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [string]$OutputDirectory = $PSScriptRoot
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "Stop"

New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null

function New-DummyFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [int]$SizeInBytes = 1024
    )

    $content = [byte[]]::new($SizeInBytes)
    [System.Random]::new().NextBytes($content)
    [System.IO.File]::WriteAllBytes($Path, $content)
}

New-DummyFile -Path (Join-Path $OutputDirectory "valid_video.mp4") -SizeInBytes 4096
New-DummyFile -Path (Join-Path $OutputDirectory "valid_audio.m4a") -SizeInBytes 2048
New-DummyFile -Path (Join-Path $OutputDirectory "video with spaces.mp4") -SizeInBytes 4096
New-DummyFile -Path (Join-Path $OutputDirectory "audio with spaces.m4a") -SizeInBytes 2048
New-DummyFile -Path (Join-Path $OutputDirectory "video(with)parens.mp4") -SizeInBytes 4096
New-DummyFile -Path (Join-Path $OutputDirectory "audio[with]brackets.m4a") -SizeInBytes 2048

Write-Host "Created test fixtures in $OutputDirectory"
