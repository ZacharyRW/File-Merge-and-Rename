:: This batch script requires three inputs.
:: The first input is the name of the video file.
:: The second input is the name of the audio file.
:: The third input is the name you want the resulting combined file to have.
:: Make sure to end the name with the type of file you want the output to be.
:: Make sure to have the exstensions at the end of the file name included.

@echo off

SET "TMPBASE=frm_%RANDOM%"
SET "TMPVID=%TMPBASE%_v"
SET "TMPAUD=%TMPBASE%_a"
SET "TMPOUT=%TMPBASE%_out.mkv"

RENAME "%~1" "%TMPVID%"
IF ERRORLEVEL 1 (
    echo Error: Could not rename "%~1".
    exit /b 1
)

RENAME "%~2" "%TMPAUD%"
IF ERRORLEVEL 1 (
    RENAME "%TMPVID%" "%~1"
    echo Error: Could not rename "%~2".
    exit /b 1
)

ffmpeg -y -loglevel "repeat+info" -i "%TMPVID%" -i "%TMPAUD%" -c copy -map "0:v:0" -map "1:a:0" "%TMPOUT%"
SET "FFERR=%ERRORLEVEL%"
IF %FFERR% NEQ 0 (
    RENAME "%TMPVID%" "%~1"
    RENAME "%TMPAUD%" "%~2"
    echo Error: FFmpeg merge failed.
    exit /b %FFERR%
)

RENAME "%TMPOUT%" "%~3"
del "%TMPVID%"
del "%TMPAUD%"

xcopy /s "%~3" "%USERPROFILE%\Desktop"
