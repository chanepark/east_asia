@echo off 
setlocal enabledelayedexpansion


FOR %%V IN (RAINC,RAINNC,RAINSH) DO (
	start "<%%V>" perl 01_ncdump_1hourData.pl %%V
)
endlocal
REM pause
exit /b
REM pause


