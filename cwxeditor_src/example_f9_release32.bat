@echo off

rem `f9_release.bat`から呼び出され、F9版(32-bit)のビルドとアーカイブを行います。

rem 作業フォルダ(実在するフォルダを指定すること)
set DEST_DIR=%USERPROFILE%\Desktop\release_work
rem ZIP圧縮に使用するアーカイバ(コマンド)
set ARCHIVER="C:\Program Files\7-Zip\7z" a -tzip

rem -----------------------------------------------------------------------

set CWX_VERSION=default
git checkout %CWX_VERSION%
dub build --compiler=ldc2 --arch=x86
if not errorlevel = 0 goto failure
copy cwxeditor.exe %DEST_DIR%\cwxeditor_fnine.exe
dub build --compiler=ldc2 --build=gui --arch=x86
if not errorlevel = 0 goto failure
copy cwxeditor.exe %DEST_DIR%\cwxeditor_fnine_win.exe
copy fnine_readme.txt %DEST_DIR%
git clone ../ %DEST_DIR%\cwxeditor
cd /D %DEST_DIR%
cd cwxeditor
git checkout %CWX_VERSION%
rmdir /S /Q .git
del .gitignore
%ARCHIVER% cwxeditor_src.zip cwxeditor_src
rmdir /S /Q cwxeditor_src
move ..\cwxeditor_fnine.exe .
move ..\cwxeditor_fnine_win.exe .
move ..\fnine_readme.txt .
cd ..
%ARCHIVER% cwxeditor_fnine_%date:/=%%1_x86.zip cwxeditor
rmdir /S /Q cwxeditor
exit /b 0

:failure
exit /b -1
