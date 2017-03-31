@echo off 
setlocal enabledelayedexpansion

set var=prcp

FOR %%T IN (daily) DO (
	start "<%%T>" C:\Python27\ArcGIS10.1\python.exe ..\prog\04_point2grid_raster2Ascii_IDW.py %%T !var!
)
endlocal
REM pause
exit /b
REM pause
