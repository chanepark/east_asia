@echo off 
setlocal enabledelayedexpansion

set var=RAINC
set core=4
SET /a "count=0"


del filelist_!var!.txt

echo Dummy > filelist_!var!.txt

For /R %%j in ("..\data\*_!var!.txt") DO (
	echo %%~nj >> filelist_!var!.txt
)

cd ..
set file_check=test
For /R %%j in ("wrfout_d01_*-01-01_00-00-00") DO (
	
	set file_check=%%~nj_!var!

	SET /a "count_c=0"
	For /f %%a in (ncdump_file\filelist_!var!.txt) DO (
	
		if !file_check!==%%a (
			set /a "count_c+=1"
		)
	)
	
	if "!count_c!"=="1" (
		echo There is file already. It will be passed.
	) else if "!count_c!"=="0" (
		set /a "count+=1"
		set /a b=!COUNT! %% !core!
		echo %%~nj
		set Input_file=%%~j
		set Output_file=..\data\%%~nj_!var!.txt
	
		if "!b!"=="0" (
			start /wait "<!var!  %%~nj>" ncdump_file\01call_execute_ncdump.bat
			TIMEOUT /T 5

		) ELSE if not "!b!"=="0" (
			start "<!var!  %%~nj>" ncdump_file\01call_execute_ncdump.bat
			TIMEOUT /T 5

		)
	
	)
)
endlocal
REM pause
exit /b
pause


