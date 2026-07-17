<#
.SYNOPSIS
    Pester coverage for the batch script and the PowerShell port.
#>

#Requires -Version 7.0

$implementations = @("Batch", "PowerShell")

BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:BatchScript = Join-Path $script:RepoRoot "File_Renamer.bat"
    $script:PowerShellScript = Join-Path $script:RepoRoot "File_Renamer.ps1"
    $script:CmdExe = Join-Path $env:SystemRoot "System32\cmd.exe"
    $script:PwshExe = (Get-Command pwsh -ErrorAction Stop).Source

    function New-TestWorkspace {
        $root = Join-Path $TestDrive "case_$([System.Guid]::NewGuid().ToString('N'))"
        $media = Join-Path $root "media"
        $user = Join-Path $root "user"
        $desktop = Join-Path $user "Desktop"
        $mockBin = Join-Path $root "mock-bin"
        New-Item -Path $media, $desktop, $mockBin -ItemType Directory -Force | Out-Null

        [pscustomobject]@{
            Root = $root
            Media = $media
            UserProfile = $user
            Desktop = $desktop
            MockBin = $mockBin
        }
    }

    function New-DummyFile {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Path,

            [string]$Content = "dummy"
        )

        Set-Content -LiteralPath $Path -Value $Content -NoNewline
    }

    function Install-MockFFmpeg {
        param(
            [Parameter(Mandatory = $true)]
            [string]$MockBin,

            [ValidateSet("Success", "Failure")]
            [string]$Mode = "Success",

            [int]$ExitCode = 23
        )

        $mockPath = Join-Path $MockBin "ffmpeg.bat"
        if ($Mode -eq "Success") {
            @"
@echo off
set "OUTPUT_PATH="
for %%A in (%*) do set "OUTPUT_PATH=%%~A"
echo MOCK_OUTPUT>"%OUTPUT_PATH%"
exit /b 0
"@ | Set-Content -LiteralPath $mockPath -Encoding ASCII
        }
        else {
            @"
@echo off
exit /b $ExitCode
"@ | Set-Content -LiteralPath $mockPath -Encoding ASCII
        }
    }

    function Get-WindowsSystemPath {
        $systemRoot = $env:SystemRoot
        if ([string]::IsNullOrWhiteSpace($systemRoot)) {
            $systemRoot = "C:\Windows"
        }

        return @(
            (Join-Path $systemRoot "System32")
            $systemRoot
            (Join-Path $systemRoot "System32\WindowsPowerShell\v1.0")
        ) -join [System.IO.Path]::PathSeparator
    }

    function Invoke-RenamerScript {
        param(
            [ValidateSet("Batch", "PowerShell")]
            [string]$Implementation,

            [string[]]$Arguments = @(),

            [Parameter(Mandatory = $true)]
            [string]$WorkingDirectory,

            [Parameter(Mandatory = $true)]
            [string]$UserProfile,

            [string]$PathPrefix
        )

        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.WorkingDirectory = $WorkingDirectory

        if ($Implementation -eq "Batch") {
            $process.StartInfo.FileName = $script:CmdExe
            $process.StartInfo.ArgumentList.Add("/c")
            $process.StartInfo.ArgumentList.Add($script:BatchScript)
        }
        else {
            $process.StartInfo.FileName = $script:PwshExe
            $process.StartInfo.ArgumentList.Add("-NoLogo")
            $process.StartInfo.ArgumentList.Add("-NoProfile")
            $process.StartInfo.ArgumentList.Add("-ExecutionPolicy")
            $process.StartInfo.ArgumentList.Add("Bypass")
            $process.StartInfo.ArgumentList.Add("-File")
            $process.StartInfo.ArgumentList.Add($script:PowerShellScript)
        }

        foreach ($argument in $Arguments) {
            $process.StartInfo.ArgumentList.Add($argument)
        }

        $path = Get-WindowsSystemPath
        if (-not [string]::IsNullOrWhiteSpace($PathPrefix)) {
            $path = "$PathPrefix$([System.IO.Path]::PathSeparator)$path"
        }

        $process.StartInfo.Environment["PATH"] = $path
        $process.StartInfo.Environment["USERPROFILE"] = $UserProfile
        $process.StartInfo.Environment["PATHEXT"] = ".COM;.EXE;.BAT;.CMD"

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

Describe "File merge scripts" -Skip:(-not $IsWindows) {
    Context "Argument and output-name validation" {
        It "<_> rejects too few arguments before file operations" -ForEach $implementations {
            $workspace = New-TestWorkspace
            $result = Invoke-RenamerScript -Implementation $_ -Arguments @("video.mp4", "audio.m4a") -WorkingDirectory $workspace.Media -UserProfile $workspace.UserProfile

            $result.ExitCode | Should -Be 1
            $result.StdOut | Should -Match "Usage:"
        }

        It "<_> rejects too many arguments" -ForEach $implementations {
            $workspace = New-TestWorkspace
            $result = Invoke-RenamerScript -Implementation $_ -Arguments @("video.mp4", "audio.m4a", "out.mkv", "extra") -WorkingDirectory $workspace.Media -UserProfile $workspace.UserProfile

            $result.ExitCode | Should -Be 1
            $result.StdOut | Should -Match "Too many arguments"
        }

        It "<_> rejects output names with path separators" -ForEach $implementations {
            $workspace = New-TestWorkspace
            $video = Join-Path $workspace.Media "video.mp4"
            $audio = Join-Path $workspace.Media "audio.m4a"
            New-DummyFile -Path $video
            New-DummyFile -Path $audio
            Install-MockFFmpeg -MockBin $workspace.MockBin

            $result = Invoke-RenamerScript -Implementation $_ -Arguments @("video.mp4", "audio.m4a", "nested\out.mkv") -WorkingDirectory $workspace.Media -UserProfile $workspace.UserProfile -PathPrefix $workspace.MockBin

            $result.ExitCode | Should -Be 1
            $result.StdOut | Should -Match "plain filename"
            $video | Should -Exist
            $audio | Should -Exist
        }

        It "<_> rejects non-MKV output without renaming inputs" -ForEach $implementations {
            $workspace = New-TestWorkspace
            $video = Join-Path $workspace.Media "video.mp4"
            $audio = Join-Path $workspace.Media "audio.m4a"
            New-DummyFile -Path $video
            New-DummyFile -Path $audio
            Install-MockFFmpeg -MockBin $workspace.MockBin

            $result = Invoke-RenamerScript -Implementation $_ -Arguments @("video.mp4", "audio.m4a", "output.mp4") -WorkingDirectory $workspace.Media -UserProfile $workspace.UserProfile -PathPrefix $workspace.MockBin

            $result.ExitCode | Should -Be 1
            $result.StdOut | Should -Match "\.mkv"
            $video | Should -Exist
            $audio | Should -Exist
            (Get-ChildItem -LiteralPath $workspace.Media -Filter "frm_*") | Should -BeNullOrEmpty
        }
    }

    Context "Dependency and input validation" {
        It "<_> rejects missing FFmpeg before renaming inputs" -ForEach $implementations {
            $workspace = New-TestWorkspace
            $video = Join-Path $workspace.Media "video.mp4"
            $audio = Join-Path $workspace.Media "audio.m4a"
            New-DummyFile -Path $video
            New-DummyFile -Path $audio

            $result = Invoke-RenamerScript -Implementation $_ -Arguments @("video.mp4", "audio.m4a", "output.mkv") -WorkingDirectory $workspace.Media -UserProfile $workspace.UserProfile

            $result.ExitCode | Should -Be 1
            $result.StdOut | Should -Match "FFmpeg not found"
            $video | Should -Exist
            $audio | Should -Exist
        }

        It "<_> rejects inputs from different directories" -ForEach $implementations {
            $workspace = New-TestWorkspace
            $other = Join-Path $workspace.Root "other"
            New-Item -Path $other -ItemType Directory -Force | Out-Null
            $video = Join-Path $workspace.Media "video.mp4"
            $audio = Join-Path $other "audio.m4a"
            New-DummyFile -Path $video
            New-DummyFile -Path $audio
            Install-MockFFmpeg -MockBin $workspace.MockBin

            $result = Invoke-RenamerScript -Implementation $_ -Arguments @($video, $audio, "output.mkv") -WorkingDirectory $workspace.Root -UserProfile $workspace.UserProfile -PathPrefix $workspace.MockBin

            $result.ExitCode | Should -Be 1
            $result.StdOut | Should -Match "same directory"
            $video | Should -Exist
            $audio | Should -Exist
        }

        It "<_> rejects missing audio file" -ForEach $implementations {
            $workspace = New-TestWorkspace
            $video = Join-Path $workspace.Media "video.mp4"
            New-DummyFile -Path $video
            Install-MockFFmpeg -MockBin $workspace.MockBin

            $result = Invoke-RenamerScript -Implementation $_ -Arguments @("video.mp4", "audio.m4a", "output.mkv") -WorkingDirectory $workspace.Media -UserProfile $workspace.UserProfile -PathPrefix $workspace.MockBin

            $result.ExitCode | Should -Be 1
            $result.StdOut | Should -Match "Audio file"
            $video | Should -Exist
        }
    }

    Context "Merge behavior and rollback" {
        It "<_> restores original filenames when FFmpeg fails" -ForEach $implementations {
            $workspace = New-TestWorkspace
            $video = Join-Path $workspace.Media "video.mp4"
            $audio = Join-Path $workspace.Media "audio.m4a"
            New-DummyFile -Path $video
            New-DummyFile -Path $audio
            Install-MockFFmpeg -MockBin $workspace.MockBin -Mode Failure -ExitCode 23

            $result = Invoke-RenamerScript -Implementation $_ -Arguments @("video.mp4", "audio.m4a", "output.mkv") -WorkingDirectory $workspace.Media -UserProfile $workspace.UserProfile -PathPrefix $workspace.MockBin

            $result.ExitCode | Should -Be 23
            $result.StdOut | Should -Match "FFmpeg merge failed"
            $video | Should -Exist
            $audio | Should -Exist
            (Join-Path $workspace.Media "output.mkv") | Should -Not -Exist
            (Get-ChildItem -LiteralPath $workspace.Media -Filter "frm_*") | Should -BeNullOrEmpty
        }

        It "<_> preserves merged temp output and restores inputs when final output exists" -ForEach $implementations {
            $workspace = New-TestWorkspace
            $video = Join-Path $workspace.Media "video.mp4"
            $audio = Join-Path $workspace.Media "audio.m4a"
            $output = Join-Path $workspace.Media "output.mkv"
            New-DummyFile -Path $video
            New-DummyFile -Path $audio
            New-DummyFile -Path $output -Content "existing"
            Install-MockFFmpeg -MockBin $workspace.MockBin

            $result = Invoke-RenamerScript -Implementation $_ -Arguments @("video.mp4", "audio.m4a", "output.mkv") -WorkingDirectory $workspace.Media -UserProfile $workspace.UserProfile -PathPrefix $workspace.MockBin

            $result.ExitCode | Should -Be 1
            $result.StdOut | Should -Match "Could not rename output"
            $video | Should -Exist
            $audio | Should -Exist
            (Get-Content -LiteralPath $output -Raw) | Should -Be "existing"
            (Get-ChildItem -LiteralPath $workspace.Media -Filter "frm_*_out.mkv").Count | Should -Be 1
        }

        It "<_> succeeds, removes temporary inputs, and copies output to Desktop" -ForEach $implementations {
            $workspace = New-TestWorkspace
            $video = Join-Path $workspace.Media "video.mp4"
            $audio = Join-Path $workspace.Media "audio.m4a"
            $output = Join-Path $workspace.Media "output.MKV"
            $desktopOutput = Join-Path $workspace.Desktop "output.MKV"
            New-DummyFile -Path $video
            New-DummyFile -Path $audio
            Install-MockFFmpeg -MockBin $workspace.MockBin

            $result = Invoke-RenamerScript -Implementation $_ -Arguments @("video.mp4", "audio.m4a", "output.MKV") -WorkingDirectory $workspace.Media -UserProfile $workspace.UserProfile -PathPrefix $workspace.MockBin

            $result.ExitCode | Should -Be 0
            $result.StdOut | Should -Match "Success:"
            $output | Should -Exist
            $desktopOutput | Should -Exist
            $video | Should -Not -Exist
            $audio | Should -Not -Exist
            (Get-ChildItem -LiteralPath $workspace.Media -Filter "frm_*") | Should -BeNullOrEmpty
        }
    }
}
