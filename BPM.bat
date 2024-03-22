@echo off
REM The Batch Package Manager - Created by Shivter and Sintrode
setlocal enabledelayedexpansion
chcp 65001 > nul 2>&1
for /f %%a in ('echo prompt $E^| cmd') do set "\e=%%a"

if not exist "%~dp0\packages" md "%~dp0\packages"

if "%~1"=="" goto --help
if "%~1"=="/?" goto --help
for %%a in (
	"-$ --help" "-I --install" "-S --search" "-L --list" "-U --update" "-D --uninstall" "-V --version"
) do for /f "tokens=1,2" %%b in (%%a) do (
	set "option=%%~b"
	if /I "%~1"=="!option:$=?!" (
		call :%%~c %2 %3 %4 %5 %6 %7 %8 %9 && REM This looks stupid
		exit /b !errorlevel!
	) else if /I "%~1"=="%%~c" (
		call :%*
		exit /b !errorlevel!
	)
)
exit /b -1
:parse-db
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
		set item.[!item!].downloads=!item.[%%~x].downloads! "!token!"
		set "item.[!item!].download.[!token!]=%%~b"
	)
	if "!token!"=="[Downloads]" set mode=Downloads
	if "!mode!"=="Item" (
		set "item.[!item!].%%~a=%%~b"
	)
	if "!token:~0,1!"==":" (
		set mode=Item
		set "item=!token:~1!"
		set item.[!item!]=Hello this is defined qwq
		set all_items=!all_items! "!token:~1!"
	)
)
exit /b
:get-db
if exist "%~dp0database.txt" del "%~dp0database.txt"
<nul set /p "=%\e%[38;2;255;255;255m"
call curl -# -o "%~dp0database.txt" "https://raw.githubusercontent.com/Shivter14/BPM/main/database.txt"
<nul set /p "=%\e%[A%\e%[0m%\e%[J"
if exist "%~dp0database.txt" exit /b
:db-err
echo(Something went wrong. Check your internet connection.
exit /b 1
:--install
call :get-db
call :parse-db
set return=0
for %%a in (%*) do for /f "tokens=1,2 delims=:" %%i in ("%%~a") do if defined item.[%%~i] (
	if not exist "%~dp0BPM-temp" (
		md "%~dp0BPM-temp"
	) else (
		echo(%\e%[38;2;255;255;255mIt seems like other packages are installing,
		echo(or the installation was cancelled unexpectedly.
		echo(Are you sure you want to continue installing?
		choice
		if "!errorlevel!" neq "1" exit /b
		del /Q "%~dp0BPM-temp"
		if not exist "%~dp0BPM-temp" md "%~dp0BPM-temp" && REM Just in case if somebody decided to make a file with the name "BPM-temp"
	)
	set link=
	set "packageid=%%~i"
	if "%%~j"=="" (
		set "link=!item.[%%~i].defaultDownload!"
	) else (
		if defined item.[%%~i].download.[%%~j] (
			set "link=!item.[%%~i].download.[%%~j]!"
		) else (
			echo(%\e%[38;2;255;127;127mThe package version "%%~j" for "%%~i" was not found.%\e%[E%\e%[38;2;255;255;127mIf you're looking for a specific version of a package, try using '%\e%[38;2;0;255;255mBPM --info ^<package name^>%\e%[38;2;255;255;127m'.%\e%[38;2;255;255;255m
			set return=1
		)
	)
	
	for /f "tokens=1,2 delims=;" %%x in ("!link!") do (REM The link format is actually "<link>;<package type>". This seperates it.
		set "link=%%~x"
		set "packagetype=%%~y"
	)
	if defined packagetype (
		if /I "!packagetype!"=="zip" (
			call curl -# -o "%~dp0BPM-temp\package.zip" "!link!"
			if not exist "%~dp0packages\!packageid!" md "%~dp0packages\!packageid!"
			set "returndir=%cd%"
			cd "%~dp0packages\!packageid!\"
			tar -xf "%~dp0BPM-temp\package.zip"
			if exist "install.bat" call install.bat "!packageid!"
			cd "!returndir!"
		) else if /I "!packagetype!"=="bat" (
			call curl -# -o "%~dp0BPM-temp\package.bat" "!link!"
		) else if /I "!packagetype!"=="cmd" (
			call curl -# -o "%~dp0BPM-temp\package.cmd" "!link!"
		) else REM   \/
	) else REM Todo: Add handeling for invalid package types
) else (
	echo(%\e%[38;2;255;127;127mThe package "%%~a" was not found.%\e%[E%\e%[38;2;255;255;127mMake sure you didn't use quotes. The IDs are also case sensitive.%\e%[EIf you're looking for something, try using '%\e%[38;2;0;255;255mBPM --search%\e%[38;2;255;255;127m'.%\e%[38;2;255;255;255m
	set return=1
)
if exist "%~dp0BPM-temp" rd /s /q "%~dp0BPM-temp"
exit /b %return%
:--search
call :get-db
call :parse-db
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
	if "%~1" neq "" (
		set newcache=!cache!
		for %%a in (%*) do set newcache=!newcache:%%~a=!
		if "!newcache!" neq "!cache!" echo(!cache!
	) else echo(!cache!
)
exit /b
:--list

exit /b
:--update

exit /b
:--uninstall

exit /b
:--version

exit /b
:--help
for %%a in (
	"BMP.bat|%\e%[38;2;0;255;0m  The Universal Batch Package Manager."
	" |%\e%[38;2;0;255;0m  Created by: %\e%[38;2;255;255;0mShivter, Sintrode"
	"%\e%[38;2;255;255;0m"
	"Usage:|%\e%[38;2;0;255;255mBPM.bat|%\e%[38;2;0;255;0m<options> %\e%[38;2;255;255;0m<parameters>"
	"== Options =="
	"    -$|--help| |Displays the help prompt."
	"    -V|--version|[<identifier>]|Displays the installed version of a specified package."
	"      |         |              |If no ID is specified, displays all (Including BPM)."
	"    -I|--install|<identifier>|Install a package by its identifier."
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
