@echo off
REM The Batch Package Manager - Created by Shivter and Sintrode
setlocal enabledelayedexpansion
set BPM.ver=1.3.0
for /f %%a in ('echo prompt $E^| cmd') do set "\e=%%a"
if not exist "%~dp0\packages" goto :install

set "#err=2;255;127;127"
set "#name=2;127;255;255"
set "#cmd=2;127;255;127"

if "%~1"=="" goto --help
if "%~1"=="/?" goto --help
for %%a in (
	"-$" "--help"
	"-I" "--install"
	"-S" "--search"
	"-L" "--list"
	"-U" "--update"
	"-R" "--uninstall"
	"-V" "--version"
	"-H" "--info"
) do (
	set "option=%%~a"
	if /I "%~1"=="!option:$=?!" (
		call :%*
		exit /b !errorlevel!
	)
)
exit /b -1
:get-db
for /f "tokens=1 delims==" %%a in ('set item.[ 2^>nul') do set "%%~a="

if exist "%~dp0database.txt" del "%~dp0database.txt"
cmd /c curl -# -o "%~dp0database.txt" "https://raw.githubusercontent.com/Shivter14/BPM/main/database.txt"
<nul set /p "=%\e%[K%\e%[A%\e%[K"
if not exist "%~dp0database.txt" goto db-err

set line=0
set mode=#
set items=
for /f "tokens=1* delims=;" %%a in ('type "%~dp0\database.txt"') do (
	set "token=%%~a"
	set /a line+=1
	if "!mode!"=="#" (
		if "!token!" neq "# BPM Database" goto db-err	%= Makes sure that this is a BPM database file =%
		set mode=
	)
	if "!token!"=="[\Downloads]" set mode=
	
	if "!mode!"=="Downloads" for %%x in ("!item!") do (
		set item.[!item!].downloads=!item.[%%~x].downloads! "!token!"
		set "item.[!item!].download.[!token!]=%%~b"
	)
	if "!token!"=="[Downloads]" set mode=Downloads
	
	if "!mode!"=="Item" (
		set "item.[!item!].%%~a=%%~b"	%= Item properties =%
	)
	if "!token:~0,1!"==":" (
		set mode=Item
		set "item=!token:~1!"
		set "item.[!item!]=!item!"
		set items=!items! "!token:~1!"
	)
)
exit /b 0
:db-err
echo=Something went wrong. Check your internet connection.
exit /b 1
:get-installed
if not exist "%~dp0BPM-LocalPackages.txt" (
	echo=# BPM Installed Packages>"%~dp0BPM-LocalPackages.txt"
)
set installed=
set installedAmount=0
for /f "tokens=1-3 eol=# delims=;" %%a in ('type "%~dp0BPM-LocalPackages.txt"') do (
	set /a "installedAmount+=1"
	set installed=!installed! "%%~a"
	set "installed.[%%~a]=%%~c"
	set "installed.[%%~a].type=%%~b"
)
exit /b 0
:update
for %%a in (!installed!) do (
	set "installed.[%%~a]="
	set "installed.[%%~a].type="
)
call :get-installed || exit /b !errorlevel!
set "update.package=%~1"
set "update.newversion=%~2"
set "update.packagetype=%~3"
set "update.link=%~4"
set "update.packageFilename=%~5"
set "update.packageHash=%~6"
if "!installed.[%update.package%].type!" neq "!packagetype!" (
	echo=%\e%[38;!#err!mFailed to upgrade%\e%[38;!#name!m !update.package! %\e%[38;!#err!mto version !update.newversion!:
	echo=    Package types aren't equal: "!installed.[%update.package%].type!", "!packagetype!"
	echo=Packages with unequal types cannot be upgraded.
	echo=Try selecting a different version to update to.%\e%[38;2;255;255;255m
	exit /b 1
)
if /I "!update.packagetype!"=="zip" (
	setlocal
	pushd "%~dp0BPM-temp"
	cmd /c curl -fkLO "!update.link:¤=?!"
	if not exist "!update.packageFilename!" cmd /c exit 1
	if errorlevel 1 (
		echo=%\e%[38;!#err!mFailed to upgrade%\e%[38;!#name!m !update.package! %\e%[38;!#err!mto version !update.newversion!:
		echo=    Download failed.%\e%[38;2;255;255;255m
		exit /b 1
	)
	for /f "usebackq" %%1 in ("!update.packageFilename!") do if "%%~z1"=="0" (
		echo=%\e%[38;!#err!mFailed to upgrade "!update.package!" to version "!update.newversion!":
		echo=    The ZIP file seems to be 0 bytes in size.%\e%[38;2;255;255;255m
		exit /b 1
	)
	set temp.hash=
	for /f "skip=1" %%a in ('certutil -hashfile "!update.packageFilename!" SHA256') do (
		if "%%~a" neq "CertUtil:" set "temp.hash=%%~a"
	)
	if "!temp.hash!" neq "!update.packageHash!" (
		echo=%\e%[38;!#err!mFailed to upgrade%\e%[38;!#name!m !update.package! %\e%[38;!#err!mto version !update.newversion!:
		echo=    Failed to vertify package: Invalid hash.
		echo=    The owner may have changed the package without updating the database.%\e%[38;2;255;255;255m
		echo=    Expected hash: !update.packageHash!
		echo=    Recieved hash: !temp.hash!
		exit /b 1
	)
	set temp.hash=
	cmd /c tar -xf "!update.packageFilename!" || (
		echo=%\e%[38;!#err!mFailed to upgrade%\e%[38;!#name!m !update.package! %\e%[38;!#err!mto version !update.newversion!:
		echo=    Failed to extract the package.%\e%[38;2;255;255;255m
		exit /b 1
	)
	del "!packageFilename!" > nul
	if exist "update.bat" (
		cmd /c update.bat "!update.package!" "%~dp0packages\!update.package!"
		if errorlevel 1 exit /b !errorlevel!
	) else (
		xcopy "!cd!" "%~dp0packages\!update.package!" /Q /S /Y || exit /b !errorlevel!
	)
	echo=# BPM Installed Packages>"%~dp0BPM-LocalPackages.txt"
	for %%a in (!installed!) do if "%%~a" neq "!update.package!" (
		>>"%~dp0BPM-LocalPackages.txt" echo=%%~a;!installed.[%%~a].type!;!installed.[%%~a]!
	)
	>>"%~dp0BPM-LocalPackages.txt" echo=!update.package!;zip;!update.newversion!
	popd
	endlocal
) else if /I "!update.packagetype!"=="bat" (
	cmd /c curl -# -o "%~dp0BPM-temp\package.bat" "!update.link:¤=?!" || exit /b !errorlevel!
	if not exist "%~dp0BPM-temp\package.bat" (
		echo=%\e%[38;!#err!mFailed to upgrade%\e%[38;!#name!m !update.package! %\e%[38;!#err!mto version !update.newversion!:
		echo=    Download failed.%\e%[38;2;255;255;255m
		exit /b 1
	)

	set temp.hash=
	for /f "skip=1" %%a in ('certutil -hashfile "%~dp0BPM-temp\package.bat" SHA256') do (
		if "%%~a" neq "CertUtil:" set "temp.hash=%%~a"
	)
	if "!temp.hash!" neq "!update.packageHash!" (
		echo=%\e%[38;!#err!mFailed to upgrade%\e%[38;!#name!m !update.package! %\e%[38;!#err!mto version !update.newversion!:
		echo=    Failed to vertify package: Invalid hash.
		echo=    The owner may have changed the package without updating the database.%\e%[38;2;255;255;255m
		echo=    Expected hash: !update.packageHash!
		echo=    Recieved hash: !temp.hash!
		exit /b 1
	)
	set temp.hash=

	if exist "%~dp0packages\!update.package!.bat" del "%~dp0packages\!update.package!.bat" > nul 2>&1
	move "%~dp0BPM-temp\package.bat" "%~dp0packages\!update.package!.bat" > nul 2>&1
	echo=# BPM Installed Packages>"%~dp0BPM-LocalPackages.txt"
	for %%a in (!installed!) do if "%%~a" neq "!update.package!" (
		>>"%~dp0BPM-LocalPackages.txt" echo=%%~a;!installed.[%%~a].type!;!installed.[%%~a]!
	)
	>>"%~dp0BPM-LocalPackages.txt" echo=!update.package!;bat;!update.newversion!
) else if /I "!update.packagetype!"=="cmd" (
	cmd /c curl -# -o "%~dp0BPM-temp\package.cmd" "!update.link:¤=?!" || exit /b !errorlevel!
	if not exist "%~dp0BPM-temp\package.cmd" (
		echo=%\e%[38;!#err!mFailed to upgrade%\e%[38;!#name!m !update.package! %\e%[38;!#err!mto version !update.newversion!:
		echo=    Something went very wrong while downloading.%\e%[38;2;255;255;255m
		exit /b 1
	)
	
	set temp.hash=
	for /f "skip=1" %%a in ('certutil -hashfile "%~dp0BPM-temp\package.cmd" SHA256') do (
		if "%%~a" neq "CertUtil:" set "temp.hash=%%~a"
	)
	if "!temp.hash!" neq "!update.packageHash!" (
		echo=%\e%[38;!#err!mFailed to upgrade%\e%[38;!#name!m !update.package! %\e%[38;!#err!mto version !update.newversion!:
		echo=    Failed to vertify package: Invalid hash.
		echo=    The owner may have changed the package without updating the database.%\e%[38;2;255;255;255m
		echo=    Expected hash: !update.packageHash!
		echo=    Recieved hash: !temp.hash!
		exit /b 1
	)
	set temp.hash=
	
	if exist "%~dp0packages\!update.package!.cmd" del "%~dp0packages\!update.package!.cmd" > nul 2>&1
	move "%~dp0BPM-temp\package.cmd" "%~dp0packages\!update.package!.cmd" > nul 2>&1
	echo=# BPM Installed Packages>"%~dp0BPM-LocalPackages.txt"
	for %%a in (!installed!) do if "%%~a" neq "!update.package!" (
		>>"%~dp0BPM-LocalPackages.txt" echo=%%~a;!installed.[%%~a].type!;!installed.[%%~a]!
	)
	>>"%~dp0BPM-LocalPackages.txt" echo=!update.package!;cmd;!update.newversion!
) else (
	echo=%\e%[38;!#err!mFailed to upgrade%\e%[38;!#name!m !update.package! %\e%[38;!#err!m:
	echo=    Invalid package type: !update.packagetype!
	echo=This is likely an error in the database. Create a bugfix request at:
	echo=%\e%[38;2;63;63;255m  https://github.com/Shivter14/BPM
	<nul set /p=%\e%[38;2;255;255;255m
	exit /b 1
)
echo=%\e%[38;2;255;255;127mPackage%\e%[38;!#name!m !update.package! %\e%[38;2;255;255;127mhas been updated successfully.%\e%[38;2;255;255;255m
exit /b
:-I
:--install
<nul set /p "=%\e%[38;2;255;255;255m"
call :get-db || exit /b !errorlevel!
call :get-installed || exit /b !errorlevel!
if not exist "%~dp0BPM-temp" (
	md "%~dp0BPM-temp"
) else (
	echo=%\e%[38;2;255;255;255mIt seems like other packages are installing,
	echo=or the installation was cancelled unexpectedly.
	echo=Are you sure you want to continue installing?
	choice
	if "!errorlevel!" neq "1" exit /b
	del /Q "%~dp0BPM-temp"
	if not exist "%~dp0BPM-temp" md "%~dp0BPM-temp" && REM Just in case if somebody decided to make a file with the name "BPM-temp"
)
set return=
for %%a in (%*) do for /f "tokens=1* delims=:" %%i in ("%%~a") do if defined installed.[%%~i] (
	set packagever=
	set return=
	if "%%~j"=="" (
		set "packagever=!item.[%%~i].latestVer!"
		for /f "tokens=1-4 delims=;" %%w in ("!item.[%%~i].defaultDownload!") do (REM The link format is actually "<link>;<package type>". This seperates it.
			set "link=%%~w"
			set "packagetype=%%~x"
			set "packageFilename=%%~y"
			set "packageHash=%%~z"
		)
	) else (
		if defined item.[%%~i].download.[%%~j] (
			set "packagever=%%~j"
			for /f "tokens=1-4 delims=;" %%s in ("!item.[%%~i].download.[%%~j]!") do (
				set "link=%%~s"
				set "packagetype=%%~t"
				set "packageFilename=%%~u"
				set "packageHash=%%~v"
			)
		) else (
			echo=%\e%[38;!#err!mPackage %\e%[38;!#name!m%%i %\e%[38;!#err!mversion %\e%[38;!#name!m%%j %\e%[38;!#err!mwas not found.
			if not defined return echo=%\e%[38;2;255;255;127mIf you're looking for a specific version of a package, try using '%\e%[38;2;0;255;255mBPM --info ^<package name^>%\e%[38;2;255;255;127m'.%\e%[38;2;255;255;255m
			set return=1
		)
	)
	if /I "!installed.[%%~i]!"=="!packagever!" (
		echo=%\e%[38;!#err!mPackage%\e%[38;!#name!m %%i %\e%[38;!#err!mversion %\e%[38;!#name!m!packagever!%\e%[38;!#err!m is already installed.%\e%[38;2;255;255;255m
	) else if defined packagever if not defined return (
		echo=%\e%[38;2;255;255;127mPackage%\e%[38;!#name!m %%i %\e%[38;2;255;255;127mversion %\e%[38;!#name!m!installed.[%%~i]!%\e%[38;2;255;255;127m is currently installed.
		echo=Are you sure you want to install version%\e%[38;!#name!m !packagever!%\e%[38;2;255;255;127m of that package^?%\e%[38;2;255;255;255m
		choice
		if "!errorlevel!"=="1" call :update "%%~i" "!packagever!" "!packagetype!" "!link!" "!packageFilename!" "!packageHash!" || set return=1
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
			echo=%\e%[38;!#err!mPackage %\e%[38;!#name!m%%i %\e%[38;!#err!mversion %\e%[38;!#name!m%%j %\e%[38;!#err!mwas not found.
			if not defined return echo=%\e%[38;2;255;255;127mIf you're looking for a specific version of a package, try using '%\e%[38;2;0;255;255mBPM --info ^<package name^>%\e%[38;2;255;255;127m'.%\e%[38;2;255;255;255m
			set return=1
		)
	)
	
	for /f "tokens=1-4 delims=;" %%w in ("!link!") do (REM The link format is actually "<link>;<package type>;<file name>;<hash>". This seperates it.
		set "link=%%~w"
		set "packagetype=%%~x"
		set "packageFilename=%%~y"
		set "packageHash=%%~z"
	)
	if defined packagetype (
		if /I "!packagetype!"=="zip" (
			pushd "%~dp0BPM-temp"
			cmd /c curl -fkLO "!link:¤=?!" || (
				echo=%\e%[38;!#err!mFailed to install "!packagid!":
				echo=    Download failed.%\e%[38;2;255;255;255m
			)
			if not errorlevel 1 (
				set temp.hash=
				for /f "skip=1" %%a in ('certutil -hashfile "!packageFilename!" SHA256') do (
					if "%%~a" neq "CertUtil:" set "temp.hash=%%~a"
				)
				if "!temp.hash!" neq "!packageHash!" (
					echo=%\e%[38;!#err!mFailed to install%\e%[38;!#name!m !packageId! %\e%[38;!#err!mversion !packagever!:
					echo=    Failed to vertify package: Invalid hash.
					echo=    The owner may have changed the package without updating the database.%\e%[38;2;255;255;255m
					echo=    Expected hash: !packageHash!
					echo=    Recieved hash: !temp.hash!
					cmd /c exit 1
				) else (
					if not exist "%~dp0packages\!packageid!" md "%~dp0packages\!packageid!"
					cd "%~dp0packages\!packageid!\"
					cmd /c tar -xf "%~dp0BPM-temp\!packageFilename!" || (
						echo=%\e%[38;!#err!mFailed to install%\e%[38;!#name!m !packageId! %\e%[38;!#err!mversion !packagever!:
						echo=    Failed to extract the package.%\e%[38;2;255;255;255m
					)
					if exist "install.bat" cmd /c install.bat "!packageid!"
				)
			)
			if errorlevel 1 (
				echo=Something went wrong while installing package "!packageid!" version !packagever!.
				echo=Errorlevel: !errorlevel!
			) else (
				>>"%~dp0BPM-LocalPackages.txt" echo=!packageid!;zip;!packagever!
				echo=%\e%[38;2;255;255;127mPackage%\e%[38;!#name!m !packageid! %\e%[38;2;255;255;127mwas installed successfully.%\e%[38;2;255;255;255m
			)
			popd
		) else if /I "!packagetype!"=="bat" (
			cmd /c curl -o "%~dp0packages\!packageid!.bat" "!link:¤=?!"
			if not exist "%~dp0packages\!packageid!.bat" cmd /c exit /b 1
			if errorlevel 1 (
				echo=%\e%[38;!#err!mFailed to install%\e%[38;!#name!m !packageId! %\e%[38;!#err!mversion !packagever!:
				echo=    Download failed.
				echo=    Errorlevel: !errorlevel!%\e%[38;2;255;255;255m
			) else (
				set temp.hash=
				for /f "skip=1" %%a in ('certutil -hashfile "%~dp0packages\!packageid!.bat" SHA256') do (
					if "%%~a" neq "CertUtil:" set "temp.hash=%%~a"
				)
				if "!temp.hash!" neq "!packageHash!" (
					echo=%\e%[38;!#err!mFailed to install%\e%[38;!#name!m !packageId! %\e%[38;!#err!mversion !packagever!:
					echo=    Failed to vertify package: Invalid hash.
					echo=    The owner may have changed the package without updating the database.%\e%[38;2;255;255;255m
					echo=    Expected hash: !packageHash!
					echo=    Recieved hash: !temp.hash!
				) else (
					>>"%~dp0BPM-LocalPackages.txt" echo=!packageid!;bat;!packagever!
					echo=%\e%[38;2;255;255;127mPackage%\e%[38;!#name!m !packageid! %\e%[38;2;255;255;127mwas installed successfully.%\e%[38;2;255;255;255m
				)
			)
		) else if /I "!packagetype!"=="cmd" (
			cmd /c curl -o "%~dp0packages\!packageid!.cmd" "!link:¤=?!"
			if not exist "%~dp0packages\!packageid!.bat" cmd /c exit /b 1
			if errorlevel 1 (
				echo=%\e%[38;!#err!mSomething went wrong while installing package "!packageid!" version !packagever!.
				echo=Errorlevel: !errorlevel!%\e%[38;2;255;255;255m
			) else (
				set temp.hash=
				for /f "skip=1" %%a in ('certutil -hashfile "%~dp0packages\!packageid!.bat" SHA256') do (
					if "%%~a" neq "CertUtil:" set "temp.hash=%%~a"
				)
				if "!temp.hash!" neq "!packageHash!" (
					echo=%\e%[38;!#err!mFailed to install%\e%[38;!#name!m !packageId! %\e%[38;!#err!mversion !packagever!:
					echo=    Failed to vertify package: Invalid hash.
					echo=    The owner may have changed the package without updating the database.%\e%[38;2;255;255;255m
					echo=    Expected hash: !packageHash!
					echo=    Recieved hash: !temp.hash!
				) else (
					>>"%~dp0BPM-LocalPackages.txt" echo=!packageid!;cmd;!packagever!
					echo=%\e%[38;2;255;255;127mPackage%\e%[38;!#name!m !packageid! %\e%[38;2;255;255;127mwas installed successfully.%\e%[38;2;255;255;255m
				)
			)
		) else (
			echo=%\e%[38;!#err!mFatal error: Package %\e%[38;!#name!m !packageid! %\e%[38;!#err!mhas an invalid package type:%\e%[38;!#name!m
			echo=	!packagetype!
			echo=%\e%[38;!#err!mThe BPM database might be corrupted, or you're using an outdated version.%\e%[38;2;255;255;255m
			exit /b 1
		)
	) else (
		echo=%\e%[38;!#err!mFatal error: Package %\e%[38;!#name!m !packageid! %\e%[38;!#err!mdoesn't have a package type somehow.
		echo=The BPM database might be corrupted, or you're using an outdated version.%\e%[38;2;255;255;255m
		exit /b 1
	)
) else (
	echo=%\e%[38;!#err!mPackage%\e%[38;!#name!m %%i%\e%[38;!#err!m was not found.%\e%[38;2;255;255;255m
	if not defined return (
		echo=%\e%[38;2;255;255;127mMake sure you didn't use quotes. The IDs are also case sensitive.
		echo=If you're looking for something, try using '%\e%[38;2;0;255;255mBPM --search%\e%[38;2;255;255;127m'.%\e%[38;2;255;255;255m
	)
	set return=1
)
:x
if exist "%~dp0BPM-temp" rd /s /q "%~dp0BPM-temp"
exit /b !return!

:-S
:--search
call :get-db || exit /b 1
set mode.W=80
for /f "tokens=2" %%a in ('mode con ^| find "Columns:"') do set /a "mode.W=%%~a"
set /a mode
set tab_one=0
set tab_two=0
chcp 65001 > nul 2>&1
for %%a in (!items!) do (
	set "cache=%%~a;!item.[%%~a]!;!item.[%%~a].Info!"
	set "newcache=!cache!"
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
	)
)
if "!tab_one!"=="0" (
	echo No items with the specified keywords were found.
	exit /b 1
)
set "tab_header=────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
set /a "tab_one+=4", "tab_two+=tab_one+3", "tab_len=!mode.W!-tab_two-5", "tab_HW=!mode.W!-2"
echo=%\e%[48;2;63;63;63m%\e%[0K%\e%[38;2;0;0;0m┌!tab_header:~0,%tab_HW%!┐%\e%[!tab_one!G┬%\e%[!tab_two!G┬
for %%a in (!items!) do (
	set "info=!item.[%%~a].Info:~0,%tab_len%!"
	for /f "tokens=1 delims=×" %%b in ("!info:\n=×!") do set "info=%%~b"
	if "!item.[%%~a].Info:~%tab_len%,1!" neq "" (
		set "append=...%\e%[38;2;0;0;0m%\e%[!mode.W!G│"
	) else set "append=%\e%[!mode.W!G%\e%[38;2;0;0;0m│"
	set "cache=%\e%[48;2;63;63;63m%\e%[0K%\e%[38;2;0;0;0m│ %\e%[38;2;0;255;255m%%~a%\e%[!tab_one!G%\e%[38;2;0;0;0m│ %\e%[38;2;0;255;0m!item.[%%~a].Name!%\e%[!tab_two!G%\e%[38;2;0;0;0m│ %\e%[38;2;255;255;0m!info!%\e%[38;2;255;255;255m!append!"
	if "%~1" neq "" (
		set "comp1=%%~a;!item.[%%~a]!;!item.[%%~a].Info!"
		set "comp2=!comp1!
		for %%b in (%*) do set "comp2=!comp2:%%~b=!"
		if "!comp1!" neq "!comp2!" echo=!cache!%\e%[0m
	) else echo=!cache!%\e%[0m
)
echo=%\e%[48;2;63;63;63m%\e%[0K%\e%[38;2;0;0;0m└!tab_header:~0,%tab_HW%!┘%\e%[!tab_one!G┴%\e%[!tab_two!G┴%\e%[38;2;255;255;255m%\e%[48;2;0;0;0m
exit /b

:-L
:--list
call :get-installed
if "%~1"=="--raw" (
	for %%a in (!installed!) do (
		echo=%%~a:!installed.[%%~a]!
	)
	exit /b
)
chcp 65001>nul 2>&1
echo=%\e%[38;2;0;255;255mInstalled Packages:%\e%[38;2;255;255;0m
set tab=7
for %%a in (!installed!) do (
	set "string=x!installed.[%%~a]!"
	set "stringlen=0"
	for /l %%b in (9,-1,0) do (
		set /a "stringlen|=1<<%%b"
		for %%c in (!stringlen!) do if "!string:~%%c,1!" equ "" set /a "stringlen&=~1<<%%b"
	)
	if !stringlen! gtr !tab! set tab=!stringlen!
)
set /a tab+=6
echo=    Version%\e%[!tab!G│ Package name%\e%[38;2;255;255;127m
for %%a in (!installed!) do (
	echo=    !installed.[%%~a]!%\e%[!tab!G│ %%~a
)
echo=%\e%[38;2;0;255;255mIf you want to get more information about a specified package,
echo=use `%\e%[38;2;0;255;0mBPM --info %\e%[38;2;255;255;0m^<Package name^>%\e%[38;2;0;255;255m`%\e%[38;2;255;255;255m
exit /b

:-I
:--info
chcp 65001 > nul
<nul set /p "=%\e%[38;2;255;255;255m"
call :get-db || exit /b !errorlevel!
call :get-installed || exit /b !errorlevel!
if "%~1"=="" exit /b 1
if "!item.[%~1]!" neq "" (
	echo=%\e%[38;2;0;255;255m'!item.[%~1]!' - %\e%[38;!#name!m!item.[%~1].Name!
	for %%a in ("!item.[%~1].info:\n=" "!") do echo=%\e%[38;2;255;255;255m%%~a
	echo=
	if "!installed.[%~1]!"=="" set "installed.[%~1]=!item.[%~1].latestVer!"
	if "!installed.[%~1]!" neq "!item.[%~1].latestVer!" (
		echo=%\e%[38;2;0;255;255mInstalled version: %\e%[38;!#name!m!installed.[%~1]!
		echo=%\e%[38;2;255;255;127m  Updated version: %\e%[38;2;255;127;255m!item.[%~1].LatestVer!
		echo=%\e%[38;2;0;255;255m  Use '%\e%[38;!#cmd!mbpm --update %1%\e%[38;2;0;255;255m' to update.
		echo=
	) else echo=%\e%[38;2;0;255;255mLatest version: %\e%[38;!#name!m!item.[%~1].LatestVer!
	
	echo=%\e%[38;2;0;255;255mAvaliable versions:
	for %%a in (!item.[%~1].downloads!) do for /f "tokens=1,2 delims=;" %%b in ("!item.[%~1].download.[%%~a]!") do (
		set "temp.dl=%%~b"
		set "temp.name=   %\e%[38;!#name!m%%~a"
		if "%~2" neq "--full-link" (
			set "temp.dl=!temp.dl:https://=!"
			for /f "tokens=2-6 delims=/" %%2 in ("!temp.dl!") do (
				if "%%~4/%%~5"=="releases/download" (
					set "temp.dl=%\e%[4m↓%\e%[24m %\e%[38;2;0;192;255mgithub.com/%%~2/%%~3/releases/%%~6"
				)
			)
			set "temp.dl=!temp.dl:raw.githubusercontent.com/=₪ %\e%[38;2;127;255;127m!"
			set "temp.dl=!temp.dl:codeload.github.com/=► %\e%[38;2;192;255;127m!"
			if "!temp.dl!" neq "!temp.dl:objects.githubusercontent.com/=!" set "temp.dl=<GitHub object>"
		)
		if "!installed.[%~1]!" == "%%~a" set "temp.name=%\e%[38;2;127;127;127m-> !temp.name:~3!"
		echo=%\e%[38;2;127;127;127m !temp.name!	%\e%[38;2;127;127;255m!temp.dl!
	)
	echo=%\e%[38;2;255;255;255m
) else if "!installed.[%~1]!" neq "" (
	echo=%\e%[38;2;255;255;127mPackage "%~1" is installed, but it's not in the database.
	echo=%\e%[38;!#err!mThis means It was removed by the BPM administrators.
	echo=%\e%[38;2;255;255;127mYou should uninstall this package using `%\e%[38;2;0;255;0mBPM --uninstall %1%\e%[38;2;255;255;127m`%\e%[38;2;255;255;255m
) else (
	echo=%\e%[38;!#err!mPackage%\e%[38;!#name!m %1 %\e%[38;!#err!mwas not found.%\e%[38;2;255;255;255m
	exit /b 1
)
exit /b 0

:-U
:--update
where choice > nul 2>&1 || (
	echo=%\e%[38;!#err!mFatal error: '%\e%[38;!#cmd!mchoice%\e%[38;!#err!m' command was not found.
	exit /b 1
)
call :get-db || exit /b !errorlevel!
call :get-installed || exit /b !errorlevel!
if not exist "%~dp0BPM-temp" (
	md "%~dp0BPM-temp"
) else (
	echo=%\e%[38;2;255;255;255mIt seems like other packages are installing,
	echo=or an installation was cancelled unexpectedly.
	echo=Are you sure you want to continue installing^?
	choice
	if "!errorlevel!" neq "1" exit /b
	del /Q "%~dp0BPM-temp">nul	%= rem   Just in case if a file with the name "BPM-temp" exists =%
	if not exist "%~dp0BPM-temp" md "%~dp0BPM-temp"
)
set return=0
set update_packages=%*
if not defined update_packages (
	for %%a in (!installed!) do if "!installed.[%%~a]!" neq "!item.[%%~a].latestVer!" set update_packages=!update_packages! %%a
	if not defined update_packages echo=%\e%[38;2;255;255;127mThere are no packages to update.%\e%[38;2;255;255;255m
)
for %%a in (!update_packages!) do for /f "tokens=1* delims=:" %%i in ("%%~a") do if "!installed.[%%~i]!" neq "" (
	set packagever=
	set return=
	if "%%~j"=="" (
		set "packagever=!item.[%%~i].latestVer!"
		for /f "tokens=1-4 delims=;" %%w in ("!item.[%%~i].defaultDownload!") do (%= rem   The link format is actually "<link>;<package type>;<file name>;<hash>". This seperates it.=%
			set "link=%%~w"
			set "packagetype=%%~x"
			set "packageFilename=%%~y"
			set "packageHash=%%~z"
		)
	) else (
		if "!item.[%%~i].download.[%%~j]!" neq "" (
			set "packagever=%%~j"
			for /f "tokens=1-4 delims=;" %%s in ("!item.[%%~i].download.[%%~j]!") do (
				set "link=%%~s"
				set "packagetype=%%~t"
				set "packageFilename=%%~u"
				set "packageHash=%%~v"
			)
		) else (
			echo=%\e%[38;!#err!mThe package version "%%~j" for "%%~i" was not found.
			echo=%\e%[38;2;255;255;127mIf you're looking for a specific version of a package, try using '%\e%[38;!#cmd!mBPM --info ^<package name^>%\e%[38;2;255;255;127m'.%\e%[38;2;255;255;255m
			set return=1
		)
	)
	if /I "!installed.[%%~i]!"=="!packagever!" (
		echo=%\e%[38;2;255;255;127mPackage%\e%[38;!#name!m %%i %\e%[38;2;255;255;127mversion !packagever! is already installed.%\e%[38;2;255;255;255m
	) else if defined packagever if not defined return (
		echo=%\e%[38;2;255;255;127mPackage%\e%[38;!#name!m %%i %\e%[38;2;255;255;127mversion !installed.[%%~i]! is currently installed.
		echo=Do you want to update this package to version !packagever!^?%\e%[38;2;255;255;255m
		choice
		if "!errorlevel!"=="1" call :update "%%~i" "!packagever!" "!packagetype!" "!link!" "!packageFilename!" "!packageHash!" || set return=1
	)
) else (
	echo=%\e%[38;!#err!mPackage "%%~i" is not installed.%\e%[38;2;255;255;255m
)
if exist "%~dp0BPM-temp" rd /s /q "%~dp0BPM-temp"
exit /b

:-R
:--uninstall
call :get-installed || exit /b !errorlevel!
set return=0
set force=False
if /I "%~1"=="BPM" goto uninstall-BPM
if /I "%~2"=="BPM" goto uninstall-BPM
for %%a in (%*) do if "%%~a"=="-F" (
	set force=True
) else if "%%~a"=="--no-script" (
	set force=True
) else for /f "tokens=1,2 delims=:" %%i in ("%%~a") do if defined installed.[%%~i] (
	set "packagever=%%~j"
	if not defined packagever (
		set "packagever=!installed.[%%~i]!"
	)
	if "!installed.[%%~i]!" neq "!packagever!" (
		echo=%\e%[38;!#err!mPackage %\e%[38;!#name!m%%~i%\e%[38;!#err!m version %\e%[38;!#name!m!installed.[%%~i]!%\e%[38;!#err!m is installed, but version %\e%[38;!#name!m%%~j%\e%[38;!#err!m is not.%\e%[0m
		set /a return+=1
	) else (
		if /I "!installed.[%%~i].type!"=="zip" (
			if "!force!" neq "True" if exist "%~dp0packages\%%~i\uninstall.bat" (
				pushd "%~dp0packages\%%~i"
				call uninstall.bat
				popd
			)
			if not errorlevel 1 rd /s /q "%~dp0packages\%%~i\"
		) else if /I "!installed.[%%~i].type!"=="bat" (
			del "%~dp0packages\%%~i.bat" || (
				echo=%\e%[38;!#err!mPackage %\e%[38;!#name!m%%~i%\e%[38;!#err!m was not found.%\e%[0m
				set /a return+=1
			)
		) else if /I "!installed.[%%~i].type!"=="cmd" (
			del "%~dp0packages\%%~i.cmd" || (
				echo=%\e%[38;!#err!mPackage %\e%[38;!#name!m%%~i%\e%[38;!#err!m was not found.%\e%[0m
				set /a return+=1
			)
		) else (
			echo=%\e%[38;!#err!mPackage %\e%[38;!#name!m%%~i%\e%[38;!#err!m has an invalid package type: %\e%[38;!#name!m!installed.[%%~i].type!
			echo=%\e%[38;!#err!mThis may have been caused by downgrading BPM.%\e%[0m
			cmd /c exit /b 1
			set /a return+=1
		)
		if not errorlevel 1 (
			echo=# BPM Installed Packages>"%~dp0BPM-LocalPackages.txt"
			for %%a in (!installed!) do if "%%~a" neq "%%~i" (
				>>"%~dp0BPM-LocalPackages.txt" echo=%%~a;!installed.[%%~a].type!;!installed.[%%~a]!
			)
			echo=%\e%[38;!#err!mPackage %\e%[38;!#name!m%%~i%\e%[38;!#err!m was uninstalled successfully.%\e%[0m
		)
	)
) else (
	echo=%\e%[38;!#err!mPackage %\e%[38;!#name!m%%~i%\e%[38;!#err!m is not installed.%\e%[0m
	set /a return+=1
)
exit /b !return!

:-V
:--version
call :get-installed || exit /b !errorlevel!
set list=%*
set return=0
if not defined list (
	pushd "%~dp0"
	echo=%\e%[38;2;255;255;127mBPM version %\e%[38;!$name!m!bpm.ver!
	echo=%\e%[0mLocal directory: !cd!
	popd
	exit /b
)
for %%a in (!list!) do (
	if "!installed.[%%~a]!"=="" (
		echo=[Error]:	Package "%%~a" is not installed.
		set /a return+=1
	) else (
		echo=%%~a:	!installed.[%%~a]!
	)
)
exit /b !return!
:-?
:--help
for %%a in (
	"BMP.bat|%\e%[38;2;0;255;0m  The Universal Batch Package Manager."
	" |%\e%[38;2;0;255;0m  Created by: %\e%[38;2;255;255;0mShivter, Sintrode"
	"%\e%[38;2;255;255;0m"
	"Usage:|%\e%[38;2;0;255;255mBPM.bat|%\e%[38;2;0;255;0m<options> %\e%[38;2;255;255;0m<parameters>"
	"== Options =="
	"    -$|--help| |Displays the help prompt."
	"    -V|--version|[<ID>]|Displays the installed version for specified packages."
	"      |         |              |If no ID is specified, displays all (Including BPM)."
	"    -I|--install|<ID>[:<version>]|Install a package by its identifier."
	"    -S|--search|<keywords>|Searches for packages by keywords."
	"    -L|--list|[--raw]|Lists installed packages."
	"    -H|--info|<ID> [--full-link]|Shows info about the specified package."
	"    -U|--update|[<ID>]|Updates specified packages."
	"      |        |              |If no ID is specified, updates all installed."
	"    -R|--uninstall|[-F] <identifier>|Uninstalls a package."
) do (
	for /f "tokens=1-4 delims=|" %%w in ("%%~a") do (
		set "option=%%~w"
		echo=%\e%[38;2;0;255;255m!option:$=?!%\e%[9G%\e%[38;2;0;255;0m%%~x%\e%[C%\e%[38;2;255;255;0m%%~y%\e%[44G%\e%[38;2;255;255;255m%%~z
	)
)
<nul set /p "=%\e%[0m"
exit /b
:install
where choice > nul 2>&1 || (
	echo=%\e%[38;!#err!mFatal error: '%\e%[38;!#cmd!mchoice%\e%[38;!#err!m' command was not found.
	exit /b 1
)
echo=
echo=  Welcome to the BPM installation wizard.
echo=  ^(Warning: This script should be run manually from the command line^)
echo=
choice /M ":: Do you want to continue"
if errorlevel 2 (
	echo=Aborted.
	exit /b 0
)
<nul set /p "=%\e%[?1049h"
:install.start
echo=%\e%[38;2;255;255;128;48;5;16m%\e%[2J%\e%[2;3HSelect a location for BPM and it's packages:%\e%[38;5;15m%\e%[B

echo=  [1] %%LocalAppData%%\BPM %\e%[2m(Recommended)%\e%[22m
echo=  [2] %%UserProfile%%\BPM
echo=  [3] %\e%[3mCustom...%\e%[23m
<nul set /p "=%\e%[B::"
choice /c 123
if errorlevel 3 (
	set /p "installDir=%\e%[10;3H%\e%[38;2;255;255;128mEnter the full path (the folder will be created automatically, but not it's parent.):%\e%[38;5;15m%\e%[11;1H::> "
) else if errorlevel 2 (
	if not exist "!userProfile!" (
		echo=%\e%[0m%\e%[?1049lSomething went very wrong. User profile directory was not found.
		exit /b 1
	)
	set "installDir=!userProfile!\BPM"
) else if errorlevel 1 (
	if not exist "!LocalAppData!" (
		echo=%\e%[0m%\e%[?1049lSomething went very wrong. Local App Data directory was not found.
		exit /b 1
	)
	set "installDir=!LocalAppData!\BPM"
) else (
	echo=%\e%[0m%\e%[?1049lSomething went wrong. Aborted.
	exit /b -1
)
<nul set /p "=%\e%[38;2;255;255;128m%\e%[2J%\e%[2;3HConfirm installation^?%\e%[38;5;15m%\e%[4;3HInstallation directory:%\e%[5;5H!installDir!%\e%[7;1H::"
choice
echo=%\e%[0m%\e%[?1049lInstalling BPM
if errorlevel 2 (
	echo=Aborted
	exit /b 0
)
echo=:: Creating directory
md "!installDir!" || (
	echo=Something went wrong: Failed to create directory.
	exit /b 2
)
md "!installDir!\packages"
echo=:: Copying BPM script
copy "%~f0" "!installDir!\BPM.bat" || (
	echo=Something went wrong: Failed to copy BPM.
	exit /b 3
)
echo=:: Updating PATH variable to include BPM
reg ADD HKEY_CURRENT_USER\Environment /v Path /t REG_EXPAND_SZ /d "!Path!;!installDir!;!installDir!\packages" /f
echo=
echo=To finish the installation, log out of your user profile and log back in.
<nul set /p "=Press any key to exit. . ."
pause > nul
exit /b
:uninstall-BPM
call :get-installed
echo=%\e%[38;!#err!mAre you sure you want to uninstall BPM and all packages you have installed?%\e%[38;5;7m
choice
if errorlevel 2 exit /b 0

if "!installedAmount!"=="0" goto uninstall-BPM.skipWarning
echo=%\e%[38;!#err!mAre you really sure? This is the last warning.
echo=You have !installedAmount! package^(s^) installed.%\e%[38;5;7m
for %%a in (3 2 1) do (
	<nul set /p "=%\e%[1G[Wait %%a seconds]"
	>nul timeout 1 /nobreak
)
<nul set /p "=%\e%[1G%\e%[K"
choice
if errorlevel 2 exit /b 0
:uninstall-BPM.skipWarning
pushd "%~dp0"
echo=%\e%[38;5;15m:: Uninstalling all packages%\e%[0m
set forceUninstall=
if "%~1"=="-F" set forceUninstall=-F
if "%~1"=="--no-script" set forceUninstall=--no-script
call :--uninstall !forceUninstall! !installed!
if errorlevel 1 if not defined forceUninstall (
	echo=%\e%[38;!#err!mOne or more packages failed to uninstall properly. The uninstallation was stopped.%\e%[0m
	echo=If you want to forcefully remove the package^(s^), run '%\e%[38;2;255;255;127mBPM --uninstall BPM -F%\e%[0m'
	exit /b 1
)

echo=%\e%[38;5;15m:: Removing BPM from PATH%\e%[0m
set "path=!path:;%cd%;%cd%\packages=!"
reg ADD HKEY_CURRENT_USER\Environment /v Path /t REG_EXPAND_SZ /d "!Path!" /f
cd "%~dp0.."
echo=%\e%[38;5;15m:: Removing all BPM files%\e%[0m
(
	rd /s /q "%~dp0"
	echo=%\e%[0mUninstallation completed. Don't mind the error below.
	exit /b 0
)
