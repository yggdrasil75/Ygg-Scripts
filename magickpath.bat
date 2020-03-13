@ECHO OFF
echo/> ygg.new 
set %MagickPath% where Magick
echo/> ygg.new
for /F "delims=\= tokens=1,2" %%k in (Ygg.ini) do (
	if "%%K" == "MagickPath" (
		>>ygg.new echo %%K=%%L)
	)
	else (
		>>ygg.new echo %%K=%Path%
	)
del Ygg.ini
ren ygg.new Ygg.ini

