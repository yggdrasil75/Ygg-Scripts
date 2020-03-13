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
	if "%%K" NEQ "MagickPath" (
		>>ygg.new echo %%K=%%L)
	)
	else (
		>>ygg.new echo %%K=%PATH%
	)
)
del Ygg.ini
ren ygg.new Ygg.ini
