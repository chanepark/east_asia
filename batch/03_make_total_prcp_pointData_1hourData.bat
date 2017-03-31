@echo off 
setlocal enabledelayedexpansion

set var=RAINC

For /d /r %%j in ("..\point_extraction\hourly\!var!\*") DO (
	REM echo %%~j
	perl ..\prog\03_MakeTotal_prcp_wRAINC_RAINNC_RAINSH.pl %%j !var! RAINNC RAINSH SSP2
)

For /d /r %%j in ("..\point_extraction\daily\!var!\*") DO (
	REM echo %%~j
	perl ..\prog\03_MakeTotal_prcp_wRAINC_RAINNC_RAINSH.pl %%j !var! RAINNC RAINSH SSP2
)

endlocal
REM pause
exit /b
pause



