:: This batch script requires three inputs.
:: The first input is the name of the video file.
:: The second input is the name of the audio file.
:: The third input is the name you want the resulting combined file to have.
:: Make sure to end the name with the type of file you want the output to be.
:: Make sure to have the extensions at the end of the file name included.

@echo off

:: Validate arguments
if "%~3"=="" (
    echo Usage: File_Renamer.bat video_file audio_file output_name
    exit /b 1
)

:: Check ffmpeg is available
where ffmpeg >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: FFmpeg not found. Please install FFmpeg and add it to your PATH.
    exit /b 1
)

SET "TMPBASE=frm_%RANDOM%"
SET "TMPVID=%TMPBASE%_v%~x1"
SET "TMPAUD=%TMPBASE%_a%~x2"
SET "TMPOUT=%TMPBASE%_out.mkv"

pushd "%~dp1"
IF ERRORLEVEL 1 (
    echo Error: Could not change to directory "%~dp1".
    exit /b 1
)

:: Check input files exist
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

RENAME "%~nx1" "%TMPVID%"
IF ERRORLEVEL 1 (
    echo Error: Could not rename "%~1".
    popd
    exit /b 1
)

RENAME "%~nx2" "%TMPAUD%"
IF ERRORLEVEL 1 (
    RENAME "%TMPVID%" "%~nx1"
    echo Error: Could not rename "%~2".
    popd
    exit /b 1
)

ffmpeg -y -loglevel "repeat+info" -i "%TMPVID%" -i "%TMPAUD%" -c copy -map "0:v:0" -map "1:a:0" "%TMPOUT%"
SET "FFERR=%ERRORLEVEL%"
IF %FFERR% NEQ 0 (
    if exist "%TMPOUT%" del "%TMPOUT%"
    RENAME "%TMPVID%" "%~nx1"
    RENAME "%TMPAUD%" "%~nx2"
    echo Error: FFmpeg merge failed.
    popd
    exit /b %FFERR%
)

RENAME "%TMPOUT%" "%~nx3"
IF ERRORLEVEL 1 (
    RENAME "%TMPVID%" "%~nx1"
    RENAME "%TMPAUD%" "%~nx2"
    echo Error: Could not rename output to "%~3". Merged file remains at "%TMPOUT%".
    popd
    exit /b 1
)

del "%TMPVID%"
if exist "%TMPVID%" echo Warning: Could not delete temporary file "%TMPVID%".
del "%TMPAUD%"
if exist "%TMPAUD%" echo Warning: Could not delete temporary file "%TMPAUD%".

copy "%~nx3" "%USERPROFILE%\Desktop"
IF ERRORLEVEL 1 (
    echo Warning: Could not copy "%~nx3" to Desktop. The merged file remains in "%CD%".
) ELSE (
    echo Success: "%~nx3" merged and copied to Desktop.
)

popd
