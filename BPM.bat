@echo off
REM The Batch Package Manager - Created by Shivter and Sintrode
REM Todo: --update, --uninstall, --version
setlocal enabledelayedexpansion
set BPM.ver=Beta 1.0.0
chcp 65001 > nul 2>&1
for /f %%a in ('echo prompt $E^| cmd') do set "\e=%%a"

if not exist "%~dp0\packages" md "%~dp0\packages"

if "%~1"=="" goto --help
if "%~1"=="/?" goto --help
for %%a in (
	"-$ --help" "-I --install" "-S --search" "-L --list" "-U --update" "-D --uninstall" "-V --version" "-H --info"
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
:get-db
for /f "tokens=1 delims==" %%a in ('set item.[ 2^>nul') do set "%%~a="
if exist "%~dp0database.txt" del "%~dp0database.txt"
<nul set /p "=%\e%[38;2;255;255;255m"
cmd /c curl -# -o "%~dp0database.txt" "https://raw.githubusercontent.com/Shivter14/BPM/main/database.txt"
<nul set /p "=%\e%[A%\e%[0m%\e%[J"
if not exist "%~dp0database.txt" goto db-err
set line=0
set mode=#
set items=
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
		set "item.[!item!]=!item!"
		set items=!items! "!token:~1!"
	)
)
exit /b
:db-err
echo(Something went wrong. Check your internet connection.
exit /b 1
:get-installed
if not exist "%~dp0BPM-LocalPackages.txt" (
	echo(# BPM Installed Packages>"%~dp0BPM-LocalPackages.txt"
)
set installed=
for /f "tokens=1-3 eol=# delims=;" %%a in ('type "%~dp0BPM-LocalPackages.txt"') do (
	set installed=!installed! "%%~a"
	set "installed.[%%~a]=%%~c"
	set "installed.[%%~a].type=%%~b"
)
exit /b
:update
for %%a in (%installed%) do (
	set "installed.[%%~a]="
	set "installed.[%%~a].type="
)
call :get-installed
set "update.package=%~1"
set "update.newversion=%~2"
set "update.packagetype=%~3"
set "update.link=%~4"
if "!installed.[%update.package%].type!" neq "!packagetype!" (
	echo(%\e%[38;2;255;127;127mFailed to update "%update.package%":
	echo(    Package types aren't equal: "!installed.[%update.package%].type!", "!packagetype!"
	echo(Packages with unequal types cannot be upgraded.%\e%[38;2;255;255;255m
	exit /b 1
)
if /I "!update.packagetype!"=="zip" (
	setlocal
	cd "%~dp0BPM-temp"
	cmd /c curl -# -o package.zip "!update.link!" || exit /b 1
	cmd /c tar -xf package.zip || exit /b 1
	del package.zip
	if exist "update.bat" (
		call update.bat "!update.package!" "%~dp0packages\!update.package!" || exit /b !errorlevel!
	) else (
		xcopy "%~dp0BPM-temp" "%~dp0packages\!update.package!" /Y /Q > nul || exit /b !errorlevel!
	)
	echo(# BPM Installed Packages>"%~dp0BPM-LocalPackages.txt"
	for %%a in (!installed!) do if "%%~a" neq "!update.package!" (
		echo(%%~a;!installed.[%%~a].type!;!installed.[%%~a]!>> "%~dp0BPM-LocalPackages.txt"
	)
	echo(!update.package!;zip;!update.newversion!>> "%~dp0BPM-LocalPackages.txt"
	endlocal
) else if /I "!update.packagetype!"=="bat" (
	cmd /c curl -# -o "%~dp0BPM-temp\package.bat" "!update.link!" || exit /b !errorlevel!
	if not exist "%~dp0BPM-temp\package.bat" (
		echo(%\e%[38;2;255;127;127mFailed to update "!update.package!":
		echo(    Something went very wrong while downloading.%\e%[38;2;255;255;255m
		exit /b 1
	)
	if exist "%~dp0packages\!update.package!.bat" del "%~dp0packages\!update.package!.bat" > nul 2>&1
	move "%~dp0BPM-temp\package.bat" "%~dp0packages\!update.package!.bat" > nul 2>&1
) else if /I "!update.packagetype!"=="cmd" (
	cmd /c curl -# -o "%~dp0BPM-temp\package.cmd" "!update.link!" || exit /b !errorlevel!
	if not exist "%~dp0BPM-temp\package.cmd" (
		echo(%\e%[38;2;255;127;127mFailed to update "!update.package!":
		echo(    Something went very wrong while downloading.%\e%[38;2;255;255;255m
		exit /b 1
	)
	if exist "%~dp0packages\!update.package!.cmd" del "%~dp0packages\!update.package!.cmd" > nul 2>&1
	move "%~dp0BPM-temp\package.cmd" "%~dp0packages\!update.package!.cmd" > nul 2>&1
) else (
	echo(%\e%[38;2;255;127;127mFailed to update "!update.package!":
	echo(    Invalid package type: !update.packagetype!
	echo(This is likely an error in the database. Create a bugfix request at:
	echo(%\e%[38;2;63;63;255m  https://github.com/Shivter14/BPM
	<nul set /p=%\e%[38;2;255;255;255m
	exit /b 1
)
echo(%\e%[38;2;255;255;127mPackage "!update.package!" has been updated successfully.%\e%[38;2;255;255;255m
exit /b
:--install
call :get-db
call :get-installed
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
set return=0
for %%a in (%*) do for /f "tokens=1,2 delims=:" %%i in ("%%~a") do if defined installed.[%%~i] (
	set packagever=
	set return=
	if "%%~j"=="" (
		set "packagever=!item.[%%~i].latestVer!"
		for /f "tokens=1,2 delims=;" %%x in ("!item.[%%~i].defaultDownload!") do (REM The link format is actually "<link>;<package type>". This seperates it.
			set "link=%%~x"
			set "packagetype=%%~y"
		)
	) else (
		if defined item.[%%~i].download.[%%~j] (
			set "packagever=%%~j"
		) else (
			echo(%\e%[38;2;255;127;127mThe package version "%%~j" for "%%~i" was not found.
			echo(%\e%[38;2;255;255;127mIf you're looking for a specific version of a package, try using '%\e%[38;2;0;255;255mBPM --info ^<package name^>%\e%[38;2;255;255;127m'.%\e%[38;2;255;255;255m
			set return=1
		)
	)
	if /I "!installed.[%%~i]!"=="!packagever!" (
		echo(%\e%[38;2;255;255;127mPackage "%%~i" version !packagever! is already installed.%\e%[38;2;255;255;255m
	) else if defined packagever if not defined return (
		echo(%\e%[38;2;255;255;127mPackage "%%~i" version !installed.[%%~i]! is currently installed.
		echo(Are you sure you want to install version !packagever! of that package^?%\e%[38;2;255;255;255m
		choice
		if "!errorlevel!"=="1" call :update "%%~i" "!packagever!" "!packagetype!" "!link!" || set return=1
	)
) else if defined item.[%%~i] (
	set link=
	set "packageid=%%~i"
	set packagever=
	if "%%~j"=="" (
		set "link=!item.[%%~i].defaultDownload!"
		set "packagever=!item.[%%~i].latestVer!"
	) else (
		if defined item.[%%~i].download.[%%~j] (
			set "link=!item.[%%~i].download.[%%~j]!"
			set "packagever=%%~j"
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
			cmd /c curl -# -o "%~dp0BPM-temp\package.zip" "!link!"
			if not exist "%~dp0packages\!packageid!" md "%~dp0packages\!packageid!"
			set "returndir=%cd%"
			cd "%~dp0packages\!packageid!\"
			tar -xf "%~dp0BPM-temp\package.zip"
			if exist "install.bat" call install.bat "!packageid!"
			if ERRORLEVEL 1 (
				echo(Something went wrong while installing package "!packageid!" version !packagever!.
				echo(Errorlevel: !errorlevel!
			) else (
				echo(!packageid!;zip;!packagever!>> "%~dp0BPM-LocalPackages.txt"
				cd "!returndir!"
				echo(%\e%[38;2;255;255;127mPackage "!packageid!" was installed successfully.%\e%[38;2;255;255;255m
			)
		) else if /I "!packagetype!"=="bat" (
			cmd /c curl -# -o "%~dp0packages\!packageid!.bat" "!link!"
			if not exist "%~dp0packages\!packageid!.bat" cmd /c exit /b 1
			if ERRORLEVEL 1 (
				echo(%\e%[38;2;255;127;127mSomething went wrong while installing package "!packageid!" version !packagever!.
				echo(Errorlevel: !errorlevel!%\e%[38;2;255;255;255m
			) else (
				echo(!packageid!;zip;!packagever!>> "%~dp0BPM-LocalPackages.txt"
				cd "!returndir!"
				echo(%\e%[38;2;255;255;127Package "!packageid!" was installed successfully.%\e%[38;2;255;255;255m
			)
		) else if /I "!packagetype!"=="cmd" (
			cmd /c curl -# -o "%~dp0packages\!packageid!.cmd" "!link!"
			if not exist "%~dp0packages\!packageid!.bat" cmd /c exit /b 1
			if ERRORLEVEL 1 (
				echo(%\e%[38;2;255;127;127mSomething went wrong while installing package "!packageid!" version !packagever!.
				echo(Errorlevel: !errorlevel!%\e%[38;2;255;255;255m
			) else (
				echo(!packageid!;zip;!packagever!>> "%~dp0BPM-LocalPackages.txt"
				cd "!returndir!"
				echo(%\e%[38;2;255;255;127Package "!packageid!" was installed successfully.%\e%[38;2;255;255;255m
			)
		) else REM   \/
	) else REM Todo: Add handeling for invalid package types
) else (
	echo(%\e%[38;2;255;127;127mThe package "%%~a" was not found.
	echo(%\e%[38;2;255;255;127mMake sure you didn't use quotes. The IDs are also case sensitive.
	echo(If you're looking for something, try using '%\e%[38;2;0;255;255mBPM --search%\e%[38;2;255;255;127m'.%\e%[38;2;255;255;255m
	set return=1
)
:x
if exist "%~dp0BPM-temp" rd /s /q "%~dp0BPM-temp"
exit /b %return%
:--search
call :get-db
set mode.W=80
for /f "tokens=2" %%a in ('mode con ^| find "Columns:"') do set /a "mode.W=%%~a"
set /a mode
set tab_one=0
set tab_two=0
for %%a in (!items!) do (
	set "cache=%%~a"
	set "newcache=%%~a"
	if "%~1" neq "" (
		for %%b in (%*) do set "newcache=!newcache:%%~b=!"
	) else set newcache=
	if "!cache!" neq "!newcache!" (

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
))
set "tab_header=────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
set /a "tab_one+=4", "tab_two+=tab_one+3", "tab_len=!mode.W!-tab_two-5", "tab_HW=!mode.W!-2"
echo(%\e%[48;2;63;63;63m%\e%[0K%\e%[38;2;0;0;0m┌!tab_header:~0,%tab_HW%!┐%\e%[!tab_one!G┬%\e%[!tab_two!G┬
for %%a in (!items!) do (
	set "info=!item.[%%~a].Info:~0,%tab_len%!"
	for /f "tokens=1 delims=×" %%b in ("!info:\n=×!") do set "info=%%~b"
	if "!item.[%%~a].Info:~%tab_len%,1!" neq "" (set append=...%\e%[38;2;0;0;0m│
	) else set append=%\e%[!mode.W!G%\e%[38;2;0;0;0m│
	set cache=%\e%[48;2;63;63;63m%\e%[0K%\e%[38;2;0;0;0m│ %\e%[38;2;0;255;255m%%~a%\e%[!tab_one!G%\e%[38;2;0;0;0m│ %\e%[38;2;0;255;0m!item.[%%~a].Name!%\e%[!tab_two!G%\e%[38;2;0;0;0m│ %\e%[38;2;255;255;0m!item.[%%~a].Info:~0,%tab_len%!%\e%[38;2;255;255;255m!append!
	if "%~1" neq "" (
		set newcache=!cache!
		for %%a in (%*) do set newcache=!newcache:%%~a=!
		if "!newcache!" neq "!cache!" echo(!cache!%\e%[0m
	) else echo(!cache!%\e%[0m
)
echo(%\e%[48;2;63;63;63m%\e%[0K%\e%[38;2;0;0;0m└!tab_header:~0,%tab_HW%!┘%\e%[!tab_one!G┴%\e%[!tab_two!G┴%\e%[38;2;255;255;255m%\e%[48;2;0;0;0m
exit /b
:--list
call :get-installed
echo(%\e%[38;2;0;255;255mInstalled Packages:%\e%[38;2;255;255;0m
set tab=7
for %%a in (%installed%) do (
	set "string=x%%~a"
	set "stringlen=0"
	for /l %%b in (9,-1,0) do (set /a "stringlen|=1<<%%b"
		for %%c in (!stringlen!) do if "!string:~%%c,1!" equ "" set /a "stringlen&=~1<<%%b"
	)
	if !stringlen! gtr !tab! set tab=!stringlen!
)
set /a tab+=6
echo(    Version%\e%[!tab!G│ Package name%\e%[38;2;255;255;127m
for %%a in (%installed%) do (
	echo(    !installed.[%%~a]!%\e%[!tab!G│ %%~a
)
echo(%\e%[38;2;0;255;255mIf you want to get more information about a specified package,
echo(use `%\e%[38;2;0;255;0mBPM --info %\e%[38;2;255;255;0m^<Package name^>%\e%[38;2;0;255;255m`%\e%[38;2;255;255;255m
exit /b
:--info
call :get-db
call :get-installed
if "%~1"=="" exit /b 1
if defined item.[%~1] (
	echo(%\e%[38;2;0;255;255m'!item.[%~1]!' - %\e%[38;2;127;255;255m!item.[%~1].Name!
	for %%a in ("!item.[%~1].info:\n=" "!") do echo(%\e%[38;2;255;255;255m%%~a
	echo(
	echo(%\e%[38;2;0;255;255mLatest version: %\e%[38;2;127;255;255m!item.[%~1].LatestVer!
	echo(%\e%[38;2;0;255;255mAvaliable versions:%\e%[38;2;127;255;255m
	for %%a in (!item.[%~1].downloads!) do echo(    %%~a
	echo(%\e%[38;2;255;255;255m
) else if defined installed.[%~1] (
	echo(%\e%[38;2;255;255;127mPackage "%~1" is installed, but it's not in the database.
	echo(%\e%[38;2;255;127;127mThis means It was removed by the BPM administrators.
	echo(%\e%[38;2;255;255;127mYou should uninstall this package using `%\e%[38;2;0;255;0mBPM --uninstall %1%\e%[38;2;255;255;127m`%\e%[38;2;255;255;255m
) else (
	echo(%\e%[38;2;255;255;127mPackage "%~1" was not found.%\e%[38;2;255;255;255m
	exit /b 1
)
exit /b 0
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
	"    -L|--list| |Lists installed packages."
	"    -H|--info|<identifier>|Shows info about the specified package."
	"    -U|--update|[<identifier>]|Updates a package. If no ID is specified, updates all."
	"    -D|--uninstall|<identifier>|Uninstalls a package."
) do (
	for /f "tokens=1-4 delims=|" %%w in ("%%~a") do (
		set "option=%%~w"
		echo(%\e%[38;2;0;255;255m!option:$=?!%\e%[9G%\e%[38;2;0;255;0m%%~x%\e%[C%\e%[38;2;255;255;0m%%~y%\e%[35G%\e%[38;2;255;255;255m%%~z
	)
)
exit /b
