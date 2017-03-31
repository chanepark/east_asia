@echo off 
setlocal enabledelayedexpansion

set time_scale=daily

FOR %%T IN (O3, PM10, PM25) DO (
	start "<%%T>" C:\Python27\ArcGIS10.1\python.exe ..\prog\04_point2grid_raster2Ascii.py !time_scale! %%T
)
endlocal
REM pause
exit /b
REM pause
