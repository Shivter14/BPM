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
	if "%~1"=="!option:$=?!" call :%%~c %2 %3
	if "%~1"=="%%~c" call :%*
)
exit /b
:scan-db
set line=0
set mode=#
set all_items=
for /f "tokens=1* delims=;" %%a in ('type "%~dp0\database.txt"') do (
	set "token=%%~a"
	set /a line+=1
	if "!mode!"=="#" (
		if "!token!" neq "# BPM Database" goto db-err
		set mode=
	)
	if "!token!"=="[\Downloads]" set mode=
	if "!mode!"=="Downloads" for %%x in ("!item!") do (
		set item.[!item!].downloads=!item.[%%~x].downloads! "!token!=%%~b"
	)
	if "!token!"=="[Downloads]" set mode=Downloads
	if "!mode!"=="Item" (
		set "item.[!item!].%%~a=%%~b"
	) else (
		if "!token:~0,1!"==":" (
			set mode=Item
			set "item=!token:~1!"
			set all_items=!all_items! "!token:~1!"
		)
	)
)
exit /b
:get-db
if exist "%~dp0\database.txt" del "%~dp0\database.txt"
<nul set /p "=%\e%[38;2;255;255;255m"
call curl -# -o "%~dp0\database.txt" "https://raw.githubusercontent.com/Shivter14/BPM/main/database.txt"
<nul set /p "=%\e%[A%\e%[0m%\e%[J"
if exist "%~dp0\database.txt" exit /b
:db-err
echo(Something went wrong. Check your internet connection.
exit /b 1
:--get

exit /b
:--search
call :get-db
call :scan-db
set mode.W=80
for /f "tokens=2" %%a in ('mode con ^| find "Columns:"') do set /a "mode.W=%%~a"
set /a mode
set tab_one=0
set tab_two=0
for %%a in (%all_items%) do (
	set "string=x%%~a"
	set "stringlen=0"
	for /l %%b in (9,-1,0) do (set /a "stringlen|=1<<%%b"
		for %%c in (!stringlen!) do if "!string:~%%c,1!" equ "" set /a "stringlen&=~1<<%%b"
	)
	if !stringlen! gtr !tab_one! set tab_one=!stringlen!
	
	set "string=x!item.[%%~a].Name!"
	set "stringlen=0"
	for /l %%b in (9,-1,0) do (set /a "stringlen|=1<<%%b"
		for %%c in (!stringlen!) do if "!string:~%%c,1!" equ "" set /a "stringlen&=~1<<%%b"
	)
	if !stringlen! gtr !tab_two! set tab_two=!stringlen!
)
set /a tab_one+=3
set /a tab_two+=%tab_one%+2
set /a tab_len=!mode.W!-!tab_two!-3
for %%a in (%all_items%) do (
	if "!item.[%%~a].Info:~%tab_len%,1!" neq "" (set append=...
	) else set append=
	set cache=%\e%[38;2;0;255;255m%%~a%\e%[38;2;0;255;0m%\e%[!tab_one!G!item.[%%~a].Name!%\e%[38;2;255;255;0m%\e%[!tab_two!G!item.[%%~a].Info:~0,%tab_len%!%\e%[38;2;255;255;255m!append!
	set newcache=!cache!
	for %%a in (%*) do set newcache=!newcache:%%~a=!
	if "!newcache!" neq "!cache!" echo(!cache!
)
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
