@echo off 
setlocal enabledelayedexpansion

set var=T2
set outFolder=datanew
set inFolder=new_data_set_0214


For /d /R %%j in ("..\!inFolder!\wrfout_d01_*-01-01_00-00-00") DO (
	echo %%j

	
	if "!count_c!"=="1" (
		echo There is file already. It will be passed.
	) else if "!count_c!"=="0" (
		set /a "count+=1"
		set /a b=!COUNT! %% !core!
		echo %%~nj
		set Input_file=%%~j
		set Output_file=..\!outFolder!\%%~nj_!var!.txt
	
		if "!b!"=="0" (
			start /wait "<!var!  %%~nj>" 01call_execute_ncdump.bat
			TIMEOUT /T 3

		) ELSE if not "!b!"=="0" (
			start "<!var!  %%~nj>" 01call_execute_ncdump.bat
			TIMEOUT /T 3

		)
	
	)
)
endlocal
REM pause
exit /b
pause
REM _ncdump_process\

