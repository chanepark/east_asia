@echo off 
setlocal enabledelayedexpansion

set infile=..\2006\wrfout_d01_2006-01-01_00-00-00

For %%v in (Times XLAT XLONG) Do (
	ncdump.exe -v %%v -b c %infile% > %%v.txt
)
pause


