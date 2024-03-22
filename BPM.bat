@echo off
REM The Batch Package Manager - Created by Shivter and Sintrode
setlocal enabledelayedexpansion
chcp 65001 > nul 2>&1
for /f %%a in ('echo prompt $E^| cmd') do set "\e=%%a"
if "%~1"=="" goto --help
if "%~1"=="/?" goto --help
for %%a in (
	"-$ --help" "-G --get" "-S --search" "-L --list" "-U --update" "-D --uninstall"
) do for /f "tokens=1,2" %%b in (%%a) do (
	set "option=%%~b"
	if "%~1"=="!option:$=?!" call :%%~c %1 %2
	if "%~1"=="%%~c" call :%*
)
exit /b
:--get

exit /b
:--search

exit /b
:--list

exit /b
:--update

exit /b
:--uninstall

exit /b
:--help
for %%a in (
	"BMP.bat|%\e%[38;2;0;255;0m  The Universal Batch Package Manager."
	" |%\e%[38;2;0;255;0m  Created by: %\e%[38;2;255;255;0mShivter, Sintrode"
	"%\e%[38;2;255;255;0m"
	"== Parameters =="
	"    -$|--help| |Displays the help prompt. (In case you forgot lol)"
	"    -G|--get|<identifier>|Install a package by its identifier."
	"    -S|--search|<keywords>|Searches for packages by keywords."
	"    -L|--list|[<keywords>]|Lists installed packages."
	"    -U|--update|[<identifier>]|Updates a package. If no ID is specified, updates all."
	"    -D|--uninstall|<identifier>|Uninstalls a package."
) do (
	for /f "tokens=1-4 delims=|" %%w in ("%%~a") do (
		set "option=%%~w"
		echo(%\e%[38;2;0;255;255m!option:$=?!%\e%[9G%\e%[38;2;0;255;0m%%~x%\e%[C%\e%[38;2;255;255;0m%%~y%\e%[35G%\e%[38;2;255;255;255m%%~z
	)
)
exit /b
