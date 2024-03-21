@echo off
REM The Batch Package Manager - Created by Shivter and Sintrode
setlocal enabledelayedexpansion
chcp 65001 > nul 2>&1
for /f %%a in ('echo prompt $E^| cmd') do set "\e=%%a"
if _%1==_ goto help
for %%a in ("/?" "-?" "--help") do if "%~1"==%%a goto help

exit /b
:help
for %%a in (
	"BMP.bat|%\e%[38;2;0;255;0m  The Universal Batch Package Manager."
	" |%\e%[38;2;0;255;0m  Created by: %\e%[38;2;255;255;0mShivter, Sintrode"
	"%\e%[38;2;255;255;0m"
	"== Parameters =="
	"    -$|--help| |Displays the help prompt (In case you forgot lol)"
	"    -G|--get|<identifier>|Install a package by it's identifier"
) do (
	for /f "tokens=1-4 delims=|" %%w in ("%%~a") do (
		set "option=%%~w"
		echo(%\e%[38;2;0;255;255m!option:$=?!%\e%[9G%\e%[38;2;0;255;0m%%~x%\e%[C%\e%[38;2;255;255;0m%%~y%\e%[32G%\e%[38;2;255;255;255m%%~z
	)
)
exit /b