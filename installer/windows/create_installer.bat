REM this script must set QTDIR32 and QTDIR64 paths to the root of corresponding Qt builds. Example:
REM set QTDIR32=k:\Qt\5\5.4\msvc2013_opengl\
REM set QTDIR64=k:\Qt\5\5.4\msvc2013_64_opengl\

call set_qt_paths.bat
if not defined WIN_SDK set WIN_SDK=10.0.18362.0

SETLOCAL

RMDIR /S /Q binaries\

if exist "%programfiles(x86)%\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    call "%programfiles(x86)%\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" x86 %WIN_SDK%
) else (
    call "%programfiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x86 %WIN_SDK%
)

REM X86
pushd ..\..\
del .qmake.stash
%QTDIR32%\bin\qmake.exe -tp vc -r
popd

msbuild ../../file-commander.sln /t:Build /p:Configuration=Release;PlatformToolset=v141;Platform="Win32"
if not %errorlevel% == 0 goto build_fail

xcopy /R /Y ..\..\bin\release\x86\FileCommander.exe binaries\32\
xcopy /R /Y ..\..\bin\release\x86\plugin_*.dll binaries\32\
xcopy /R /Y "3rdparty binaries"\32\* binaries\32\

SETLOCAL
SET PATH=%QTDIR32%\bin\
%QTDIR32%\bin\windeployqt.exe --dir binaries\32\Qt --force --no-translations --release --no-compiler-runtime --no-angle binaries\32\FileCommander.exe
FOR %%p IN (binaries\32\plugin_*.dll) DO %QTDIR32%\bin\windeployqt.exe --dir binaries\32\Qt --release --no-compiler-runtime --no-angle --no-translations %%p
ENDLOCAL

xcopy /R /Y %SystemRoot%\SysWOW64\msvcp140.dll binaries\32\msvcr\
xcopy /R /Y %SystemRoot%\SysWOW64\msvcp140_1.dll binaries\32\msvcr\
xcopy /R /Y %SystemRoot%\SysWOW64\vcruntime140.dll binaries\32\msvcr\
xcopy /R /Y %SystemRoot%\SysWOW64\vcruntime140_1.dll binaries\32\msvcr\

echo "%programfiles(x86)%\Windows Kits\10\Redist\%WIN_SDK%\ucrt\DLLs\x86\*.dll"
xcopy /R /Y "%programfiles(x86)%\Windows Kits\10\Redist\%WIN_SDK%\ucrt\DLLs\x86\*.dll" binaries\32\msvcr\
if %ERRORLEVEL% GEQ 1 goto windows_sdk_not_found

del binaries\32\Qt\opengl*.*

ENDLOCAL

SETLOCAL

if exist "%programfiles(x86)%\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    call "%programfiles(x86)%\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 %WIN_SDK%
) else (
    call "%programfiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 %WIN_SDK%
)

REM X64
pushd ..\..\
del .qmake.stash
%QTDIR64%\bin\qmake.exe -tp vc -r
popd

msbuild ../../file-commander.sln /t:Build /p:Configuration=Release;Platform="x64";PlatformToolset=v141
if not %errorlevel% == 0 goto build_fail

xcopy /R /Y ..\..\bin\release\x64\FileCommander.exe binaries\64\
xcopy /R /Y ..\..\bin\release\x64\plugin_*.dll binaries\64\
xcopy /R /Y "3rdparty binaries"\64\* binaries\64\

SETLOCAL
SET PATH=%QTDIR64%\bin\
%QTDIR64%\bin\windeployqt.exe --dir binaries\64\Qt --force --release --no-compiler-runtime --no-angle --no-translations binaries\64\FileCommander.exe
FOR %%p IN (binaries\64\plugin_*.dll) DO %QTDIR64%\bin\windeployqt.exe --dir binaries\64\Qt --release --no-compiler-runtime --no-angle --no-translations %%p
ENDLOCAL

xcopy /R /Y %SystemRoot%\System32\msvcp140.dll binaries\64\msvcr\
xcopy /R /Y %SystemRoot%\System32\msvcp140_1.dll binaries\64\msvcr\
xcopy /R /Y %SystemRoot%\System32\vcruntime140.dll binaries\64\msvcr\
xcopy /R /Y %SystemRoot%\System32\vcruntime140_1.dll binaries\64\msvcr\

echo "%programfiles(x86)%\Windows Kits\10\Redist\%WIN_SDK%\ucrt\DLLs\x64\*.dll"
xcopy /R /Y "%programfiles(x86)%\Windows Kits\10\Redist\%WIN_SDK%\ucrt\DLLs\x64\*.dll" binaries\64\msvcr\
if %ERRORLEVEL% GEQ 1 goto windows_sdk_not_found

del binaries\64\Qt\opengl*.*

"c:\Program Files (x86)\Inno Setup 6\iscc" setup.iss

ENDLOCAL
exit /b 0

:build_fail
ENDLOCAL
echo Build failed
pause
exit /b 1

:windows_sdk_not_found
ENDLOCAL
echo Windows SDK not found (required for CRT DLLs)
pause
exit /b 1