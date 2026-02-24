:: This batch script requires three inputs.
:: The first input is the name of the video file.
:: The second input is the name of the audio file.
:: The third input is the name you want the resulting combined file to have.
:: Make sure to end the name with the type of file you want the output to be.
:: Make sure to have the exstensions at the end of the file name included.

@echo off

SET "TMPBASE=frm_%RANDOM%"
SET "TMPVID=%TMPBASE%_v%~x1"
SET "TMPAUD=%TMPBASE%_a%~x2"
SET "TMPOUT=%TMPBASE%_out.mkv"

pushd "%~dp1"
IF ERRORLEVEL 1 (
    echo Error: Could not change to directory "%~dp1".
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
del "%TMPAUD%"

copy "%~nx3" "%USERPROFILE%\Desktop"
popd
