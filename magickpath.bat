@ECHO off

IF "%PATH%" == "Magick.exe" GOTO NOPATH
:YESPATH
PATH=%PATH%
@ECHO %PATH%
GOTO END
:NOPATH
@ECHO false
PATH=C:\DOS;
GOTO END
:END
echo. > ygg.new
for /F "delims=\= tokens=1,2" %%K in (Ygg.ini) do (
	if "%%K" NEQ "MagickPath" GOTO P1
)

:P2
	>>ygg.new echo %%K=%PATH%
	GOTO SECONDEND
:P1
	>>ygg.new echo %%K=%%L
:SECONDEND
del Ygg.ini
ren ygg.new Ygg.ini
