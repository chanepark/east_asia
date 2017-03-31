@echo off 
setlocal enabledelayedexpansion

set var=RAINSH
REM set core=4
REM SET /a "count=0"

REM use perl code instead of batch folder creation
REM if not exist "..\point_extraction" mkdir ..\point_extraction
REM if not exist "..\point_extraction\tmin" mkdir ..\point_extraction\tmin
REM if not exist "..\point_extraction\tmax" mkdir ..\point_extraction\tmax
REM if not exist "..\point_extraction\tavg" mkdir ..\point_extraction\tavg

REM del filelist_!var!.txt

REM echo Dummy > filelist_!var!.txt
For /R %%j in ("..\data_ncfType\validation_d01_*_!var!.txt") DO (
	echo %%~nj 
	perl ..\prog\03_prcp_basedon_1hour_data.pl %%j 1 !var!
)
endlocal
REM pause
exit /b
pause


