@echo off 
setlocal enabledelayedexpansion
echo %cd%

FOR %%V IN (RAINNC, RAINSH) DO (
	title  "<%%V>"
	perl ../prog/02_pointData_extraction_prcp_basedon_1hour_data-refactor.pl %%V
)
endlocal
pause



