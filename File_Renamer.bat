:: This batch script requires three inputs.
:: The first input is the name of the video file.
:: The second input is the name of the audio file.
:: The third input is the name you want the resulting combined file to have.
:: Make sure to end the name with the type of file you want the output to be.
:: Make sure to have the exstensions at the end of the file name included.

@echo off

RENAME %1 abc
RENAME %2 def

ffmpeg -y -loglevel "repeat+info" -i "abc" -i "def" -c copy -map "0:v:0" -map "1:a:0" "ghi.mkv"

RENAME ghi.mkv %3

del abc
del def

xcopy /s %3 C:\Users\zacha\Desktop