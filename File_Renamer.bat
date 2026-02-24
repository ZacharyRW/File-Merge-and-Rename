:: This batch script merges a video and audio file using FFmpeg.
:: The first input (%1) is the path to the video file (with extension).
:: The second input (%2) is the path to the audio file (with extension).
:: The third input (%3) is the desired output filename — plain name only, no path.
:: Output MUST use the .mkv extension — the merge always produces a Matroska (MKV) container.
:: Include file extensions for all three arguments (e.g. video.mp4, audio.m4a, output.mkv).

@echo off

:: ── ARGUMENT VALIDATION ──────────────────────────────────────────────────────
:: Require exactly three arguments: video file, audio file, output name.
:: %~3 expands arg3 with enclosing quotes stripped; empty string means < 3 args.
:: %~4 must be empty; a non-empty %~4 means more than three arguments were given.
if "%~3"=="" (
    echo Usage: File_Renamer.bat video_file audio_file output_name
    exit /b 1
)
if not "%~4"=="" (
    echo Error: Too many arguments. Expected exactly three.
    echo Usage: File_Renamer.bat video_file audio_file output_name
    exit /b 1
)

:: Reject path separators and drive letters in the output name.
:: arg3 must be a plain filename; the output is always written to the input directory.
:: Each check strips one character class via string substitution; if the result
:: differs from the original, that character was present in the argument.
:: Note: %~d3 is NOT used for the drive-letter check because cmd.exe resolves
:: relative names against the current drive, making %~d3 non-empty even for a
:: plain filename like "output.mkv" — which would incorrectly reject valid calls.
set "_OUT3=%~3"
if not "%_OUT3:\=%"=="%_OUT3%" (
    echo Error: Output name must be a plain filename ^(no backslashes^). Example: "My Video.mkv"
    exit /b 1
)
if not "%_OUT3:/=%"=="%_OUT3%" (
    echo Error: Output name must be a plain filename ^(no forward slashes^). Example: "My Video.mkv"
    exit /b 1
)
:: Colons are invalid in Windows filenames and only appear in drive specifiers
:: such as "C:file.mkv" or "C:\path\file.mkv" (the latter is also caught above).
if not "%_OUT3::=%"=="%_OUT3%" (
    echo Error: Output name must be a plain filename ^(no drive letter^). Example: "My Video.mkv"
    exit /b 1
)

:: ── FFMPEG AVAILABILITY CHECK ────────────────────────────────────────────────
:: Verify FFmpeg is on PATH before any file operations.  A missing binary would
:: otherwise fail only after the input files have already been renamed.
where ffmpeg >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: FFmpeg not found. Please install FFmpeg and add it to your PATH.
    exit /b 1
)

:: ── CHANGE TO INPUT DIRECTORY ────────────────────────────────────────────────
:: All file operations run in the video file's own directory to keep paths short.
:: pushd / popd track the original directory so it is restored on every exit path.
:: %~dp1 expands to the drive + path component of arg1 (e.g. C:\Users\user\Videos\).
pushd "%~dp1"
IF ERRORLEVEL 1 (
    echo Error: Could not change to directory "%~dp1".
    exit /b 1
)

:: ── INPUT DIRECTORY MATCH CHECK ──────────────────────────────────────────────
:: Both input files must reside in the same directory.  This check runs after
:: pushd so that relative-path arguments are resolved against the video file's
:: directory: a bare audio filename (e.g. "audio.m4a") then produces the same
:: %~dp2 as %~dp1, preventing a false mismatch when the caller mixes an absolute
:: video path with a relative audio name.  An audio argument that is an absolute
:: path to a genuinely different directory is still caught correctly.
if /i not "%~dp1"=="%~dp2" (
    echo Error: Both input files must be in the same directory.
    echo   Video directory: "%~dp1"
    echo   Audio directory: "%~dp2"
    popd
    exit /b 1
)

:: ── TEMPORARY FILE NAME GENERATION ──────────────────────────────────────────
:: Short randomised names keep all paths well under the 260-char MAX_PATH limit.
:: %RANDOM% yields a pseudo-random integer in the range 0–32767.
:: All three candidate names are checked for pre-existing files before use;
:: if any collision is found the entire set is regenerated to avoid clobbering.
:GENERATE_TMPNAMES
SET "TMPBASE=frm_%RANDOM%"
SET "TMPVID=%TMPBASE%_v%~x1"
SET "TMPAUD=%TMPBASE%_a%~x2"
SET "TMPOUT=%TMPBASE%_out.mkv"
if exist "%TMPVID%" goto GENERATE_TMPNAMES
if exist "%TMPAUD%" goto GENERATE_TMPNAMES
if exist "%TMPOUT%" goto GENERATE_TMPNAMES

:: ── INPUT FILE EXISTENCE CHECKS ──────────────────────────────────────────────
:: %~nx1 / %~nx2 are the name + extension components of the input arguments;
:: these are the bare filenames as they appear inside the now-current directory.
if not exist "%~nx1" (
    echo Error: Video file "%~nx1" not found in "%~dp1".
    popd
    exit /b 1
)
if not exist "%~nx2" (
    echo Error: Audio file "%~nx2" not found in "%~dp1".
    popd
    exit /b 1
)

:: ── RENAME INPUTS TO TEMPORARY NAMES ────────────────────────────────────────
:: Short names avoid MAX_PATH problems during the FFmpeg merge step.
:: On failure, any already-renamed file is restored before exiting so the
:: caller is never left with temp-named originals.
RENAME "%~nx1" "%TMPVID%"
IF ERRORLEVEL 1 (
    echo Error: Could not rename "%~1".
    popd
    exit /b 1
)

RENAME "%~nx2" "%TMPAUD%"
IF ERRORLEVEL 1 (
    :: Restore the first rename before aborting.
    RENAME "%TMPVID%" "%~nx1"
    echo Error: Could not rename "%~2".
    popd
    exit /b 1
)

:: ── FFMPEG MERGE ─────────────────────────────────────────────────────────────
:: -y              Overwrite output without prompting.
:: -loglevel       Show repeated messages and info-level output for diagnostics.
:: -c copy         Stream-copy (no re-encoding) — fast and lossless.
:: -map "0:v:0"    Take the first video stream from the first input file.
:: -map "1:a:0"    Take the first audio stream from the second input file.
:: The output container is always Matroska (MKV) regardless of arg3's extension.
ffmpeg -y -loglevel "repeat+info" -i "%TMPVID%" -i "%TMPAUD%" -c copy -map "0:v:0" -map "1:a:0" "%TMPOUT%"
SET "FFERR=%ERRORLEVEL%"
IF %FFERR% NEQ 0 (
    :: Merge failed — delete any partial output and restore original filenames.
    if exist "%TMPOUT%" del "%TMPOUT%"
    RENAME "%TMPVID%" "%~nx1"
    RENAME "%TMPAUD%" "%~nx2"
    echo Error: FFmpeg merge failed.
    popd
    exit /b %FFERR%
)

:: ── OUTPUT EXTENSION VALIDATION ──────────────────────────────────────────────
:: The merge always produces a Matroska container (.mkv); any other extension
:: would give a mismatched container header.  Catch this before the rename so
:: the user receives a clear diagnostic.  On failure both input files are
:: restored to their original names and the temp output is deleted, leaving the
:: input directory exactly as it was before the script ran.
if /i not "%~x3"==".mkv" (
    RENAME "%TMPVID%" "%~nx1"
    RENAME "%TMPAUD%" "%~nx2"
    if exist "%TMPOUT%" del "%TMPOUT%"
    echo Error: Output filename must use the .mkv extension. Received: "%~nx3"
    popd
    exit /b 1
)

:: ── RENAME OUTPUT TO DESIRED NAME ────────────────────────────────────────────
:: %~nx3 is the name + extension of arg3; path components were already rejected
:: above so this is guaranteed to be a plain filename at this point.
RENAME "%TMPOUT%" "%~nx3"
IF ERRORLEVEL 1 (
    :: Restore input filenames so the user is not left with temp-named originals.
    RENAME "%TMPVID%" "%~nx1"
    RENAME "%TMPAUD%" "%~nx2"
    echo Error: Could not rename output to "%~3". Merged file remains at "%TMPOUT%".
    popd
    exit /b 1
)

:: ── CLEAN UP TEMPORARY INPUT FILES ──────────────────────────────────────────
:: Warn (but do not abort) if a temp file cannot be removed; any leftover
:: frm_* files can be identified and deleted manually.
del "%TMPVID%"
if exist "%TMPVID%" echo Warning: Could not delete temporary file "%TMPVID%".
del "%TMPAUD%"
if exist "%TMPAUD%" echo Warning: Could not delete temporary file "%TMPAUD%".

:: ── COPY RESULT TO DESKTOP ───────────────────────────────────────────────────
:: Convenience step only — failure here does NOT trigger rollback.
:: The merge is already complete; the file safely exists in the input directory.
:: %USERPROFILE%\Desktop resolves to the current user's desktop on any Windows.
copy "%~nx3" "%USERPROFILE%\Desktop"
IF ERRORLEVEL 1 (
    echo Warning: Could not copy "%~nx3" to Desktop. The merged file remains in "%CD%".
) ELSE (
    echo Success: "%~nx3" merged and copied to Desktop.
)

:: Restore the original working directory.
popd
