# Test Suite

The repository has a Windows Pester suite in this directory that exercises both implementations:

- `File_Renamer.bat`
- `File_Renamer.ps1`

The default tests use an isolated `ffmpeg.bat` mock in a temporary directory. Each test
prepends that directory to `PATH`, so the batch script's `where ffmpeg` check and the
PowerShell port's `Get-Command ffmpeg` check both resolve the same stub.

## Run Locally

Run the default suite from the repository root on Windows:

```powershell
pwsh -NoProfile -Command "Invoke-Pester -Path .\tests\File_Renamer.Tests.ps1 -Output Detailed"
```

The real-FFmpeg integration test is opt-in:

```powershell
$env:RUN_REAL_FFMPEG_TESTS = "1"
pwsh -NoProfile -Command "Invoke-Pester -Path .\tests\File_Renamer.Integration.Tests.ps1 -Tag Integration -Output Detailed"
```

## Fixtures

The automated tests create their own files in Pester `TestDrive`. For manual runs, create
sample fixture files with:

```powershell
pwsh -NoProfile -File .\tests\fixtures\Create-TestFixtures.ps1
```
