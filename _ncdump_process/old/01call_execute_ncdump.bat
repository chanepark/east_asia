@echo off 

call ncdump_file\ncdump.exe -v %var% -b c %Input_file% > %Output_file%

exit