@echo off 
REM setlocal enabledelayedexpansion

set time_scale=daily

C:\Python27\ArcGIS10.1\python.exe ..\prog\04_point2grid_raster2Ascii_IDW.py %time_scale% tavg

pause
C:\Python27\ArcGIS10.1\python.exe ..\prog\04_point2grid_raster2Ascii_IDW.py %time_scale% tmax

C:\Python27\ArcGIS10.1\python.exe ..\prog\04_point2grid_raster2Ascii_IDW.py %time_scale% tmin

REM endlocal
pause
exit /b
REM pause
