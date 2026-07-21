# Repository Guide

This is the canonical project guidance for every coding agent. Read it before changing the repository. For machine-local capabilities, also read `~/.codex/DEVICE.md` when applicable.

## Project and sources of truth

- Media File Merge Renamer is a local recovery utility for separate video and audio files whose normal FFmpeg merge failed because of Windows path-length constraints.
- The current implementation is `File_Renamer.bat` (Windows compatibility) and `File_Renamer.ps1` (PowerShell 7). The code and current tests outrank summaries and historical Git records.
- `README.md` is the user-facing contract. `ANALYSIS.md` records verified audit findings; `ROADMAP.md` is the only active planning document.
- The repository has no separate historical review tracker. Do not recreate `AUDIT.md`, `CODE_REVIEW.md`, `REVIEW_TASKS.md`, or `TEST_COVERAGE_ANALYSIS.md`; Git history retains their provenance.

## Behavioral contract

- Preserve the three positional arguments: video file, audio file, and a plain `.mkv` output name.
- Both inputs must resolve to the same directory. The merge uses FFmpeg stream copy and explicit video/audio maps.
- Short temporary names are intentional: they are the path-length workaround. Failure paths must preserve or clearly report the state of original inputs and temporary output.
- The Desktop copy is convenience-only; a failure there must not undo a completed merge.
- Keep batch and PowerShell behavior aligned. Prefer PowerShell for any new behavior that cannot be made safe and testable in cmd.exe.

## Tests and validation

- All automated tests live under `tests/`.
- The default suite is Windows-only and requires PowerShell 7+: `pwsh -NoProfile -Command "Invoke-Pester -Path .\tests\File_Renamer.Tests.ps1 -Output Detailed"`.
- The real-FFmpeg integration suite is opt-in: set `RUN_REAL_FFMPEG_TESTS=1`, then run `tests/File_Renamer.Integration.Tests.ps1` with Pester.
- GitHub Actions runs the default mock-FFmpeg suite on `windows-latest`. Do not claim local Windows test results from a non-Windows host.
- Update test paths, README instructions, and the workflow together whenever test layout changes.

## Change discipline

- Inspect branch and working tree first. Preserve uncommitted user work and do not rewrite history or force-push.
- Use focused branches and commits. Treat pushes, PRs, merges, releases, and GitHub settings as separate authority boundaries.
- Do not delete inputs outside the current invocation’s temporary files. Avoid automatic cleanup of arbitrary historical `frm_*` files.
- Keep documentation concise and current. Add durable work only after verification; keep speculative ideas in `ROADMAP.md`'s exploratory/deferred sections.
