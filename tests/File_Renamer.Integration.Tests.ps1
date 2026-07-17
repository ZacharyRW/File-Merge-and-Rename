<#
.SYNOPSIS
    Opt-in Pester integration tests that use real FFmpeg.

.DESCRIPTION
    These tests are skipped unless RUN_REAL_FFMPEG_TESTS=1 is set. The default
    CI job uses the mock-FFmpeg unit suite in tests/File_Renamer.Tests.ps1.
#>

#Requires -Version 7.0

BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:PowerShellScript = Join-Path $script:RepoRoot "File_Renamer.ps1"

    function Invoke-PowerShellRenamer {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$Arguments,

            [Parameter(Mandatory = $true)]
            [string]$WorkingDirectory,

            [Parameter(Mandatory = $true)]
            [string]$UserProfile
        )

        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.FileName = "pwsh"
        $process.StartInfo.WorkingDirectory = $WorkingDirectory
        $process.StartInfo.Environment["USERPROFILE"] = $UserProfile
        $process.StartInfo.ArgumentList.Add("-NoLogo")
        $process.StartInfo.ArgumentList.Add("-NoProfile")
        $process.StartInfo.ArgumentList.Add("-ExecutionPolicy")
        $process.StartInfo.ArgumentList.Add("Bypass")
        $process.StartInfo.ArgumentList.Add("-File")
        $process.StartInfo.ArgumentList.Add($script:PowerShellScript)
        foreach ($argument in $Arguments) {
            $process.StartInfo.ArgumentList.Add($argument)
        }

        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        [pscustomobject]@{
            ExitCode = $process.ExitCode
            StdOut = $stdout
            StdErr = $stderr
        }
    }
}

Describe "File_Renamer.ps1 real FFmpeg integration" -Tag "Integration" -Skip:($env:RUN_REAL_FFMPEG_TESTS -ne "1") {
    It "merges generated one-second video and audio fixtures" {
        Get-Command ffmpeg -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $root = Join-Path $TestDrive "real_ffmpeg"
        $media = Join-Path $root "media"
        $user = Join-Path $root "user"
        $desktop = Join-Path $user "Desktop"
        New-Item -Path $media, $desktop -ItemType Directory -Force | Out-Null

        $video = Join-Path $media "video.mp4"
        $audio = Join-Path $media "audio.m4a"
        $output = Join-Path $media "merged.mkv"

        & ffmpeg -hide_banner -loglevel error -f lavfi -i "testsrc=duration=1:size=160x90:rate=1" -pix_fmt yuv420p $video
        $LASTEXITCODE | Should -Be 0

        & ffmpeg -hide_banner -loglevel error -f lavfi -i "sine=frequency=1000:duration=1" $audio
        $LASTEXITCODE | Should -Be 0

        $result = Invoke-PowerShellRenamer -Arguments @("video.mp4", "audio.m4a", "merged.mkv") -WorkingDirectory $media -UserProfile $user

        $result.ExitCode | Should -Be 0
        $output | Should -Exist
        (Join-Path $desktop "merged.mkv") | Should -Exist
    }
}
