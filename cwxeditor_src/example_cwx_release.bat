@echo off

rem 使い方:
rem  1. スクリプトを自分用にコピーして`cwx_release.bat`とし、各環境変数を設定します。
rem  2. リリース時に以下のコマンドでdry runを行います(バージョン7リリースの場合)。
rem     cwx_release.bat 7.0 test
rem  3. dry runの結果が問題なければ以下のコマンドを実行します。
rem     cwx_release.bat 7.0 release

rem 作業フォルダ(実在するフォルダを指定すること)
set DEST_DIR_EDITOR=%USERPROFILE%\Desktop\release_work
rem ZIP圧縮に使用するアーカイバ(コマンド)
set ARCHIVER="C:\Program Files\7-Zip\7z" a -tzip

rem ローカルリポジトリのパス
set LOCAL_REPO_EDITOR=D:\path\to\cwxeditor
rem リモートリポジトリのURL
set MAIN_REPO_EDITOR=https://<username>@bitbucket.org/<username>/cwxeditor
rem コミットするユーザ(hg ci -u <username>)
set USER=<username>

rem テキストエディタ
set EDITOR=notepad

rem -----------------------------------------------------------------------

if "%1"=="" exit /b -1
if not "%2"=="test" (
	if not "%2"=="release" exit /b -1
)

set CWX_VERSION=default

set COMMIT_MESSAGE_EDITOR=%1
set COMMIT_MESSAGE_EDITOR=%COMMIT_MESSAGE_EDITOR:beta=β%
set COMMIT_MESSAGE_EDITOR=%COMMIT_MESSAGE_EDITOR:a=α%

pushd %DEST_DIR_EDITOR%
hg clone %LOCAL_REPO_EDITOR% cwxeditor_temp
cd cwxeditor_temp\cwxeditor_src

hg up %CWX_VERSION%
%EDITOR% ..\editor_history.txt
%EDITOR% @version.txt
hg ci -u %USER% -m "%COMMIT_MESSAGE_EDITOR%"
hg tag release_%1 -u %USER%
if not "%3"=="copy_builds" (
	if "%2"=="release" hg push %MAIN_REPO_EDITOR%
)
rdmd build clean
rdmd build release
if not errorlevel = 0 goto failure
copy cwxeditor.exe %DEST_DIR_EDITOR%
hg clone ../ %DEST_DIR_EDITOR%\cwxeditor
pushd %DEST_DIR_EDITOR%\cwxeditor
hg up %CWX_VERSION%
rmdir /S /Q .hg
del .hgignore
del .hgtags
%ARCHIVER% cwxeditor_src.zip cwxeditor_src
if "%3"=="copy_builds" (
	mkdir ..\cwxeditor_x86
	copy cwxeditor_src.zip ..\cwxeditor_x86
	copy *.txt ..\cwxeditor_x86
	copy cwxscript.html ..\cwxeditor_x86
	mkdir ..\cwxeditor_x86\x86
	copy x86\*.dll ..\cwxeditor_x86\x86
	copy ..\cwxeditor.exe ..\cwxeditor_x86
)
rmdir /S /Q cwxeditor_src
rmdir /S /Q x64
move ..\cwxeditor.exe .
cd ..
set CWX_DATE=
%ARCHIVER% cwxeditor_%1_x86.zip cwxeditor
rmdir /S /Q cwxeditor
popd

rdmd build clean
rdmd build release -m64
if not errorlevel = 0 goto failure
copy cwxeditor.exe %DEST_DIR_EDITOR%
hg clone ../ %DEST_DIR_EDITOR%\cwxeditor
pushd %DEST_DIR_EDITOR%\cwxeditor
cd ..
cd cwxeditor
hg up %CWX_VERSION%
rmdir /S /Q .hg
del .hgignore
del .hgtags
%ARCHIVER% cwxeditor_src.zip cwxeditor_src
if "%3"=="copy_builds" (
	mkdir ..\cwxeditor_x64
	copy cwxeditor_src.zip ..\cwxeditor_x64
	copy *.txt ..\cwxeditor_x64
	copy cwxscript.html ..\cwxeditor_x64
	mkdir ..\cwxeditor_x64\x64
	copy x64\*.dll ..\cwxeditor_x64\x64
	copy ..\cwxeditor.exe ..\cwxeditor_x64
)
rmdir /S /Q cwxeditor_src
rmdir /S /Q x86
move ..\cwxeditor.exe .
cd ..
set CWX_DATE=
%ARCHIVER% cwxeditor_%1_x64.zip cwxeditor
rmdir /S /Q cwxeditor

if not "%3"=="copy_builds" (
	rmdir /S /Q cwxeditor_temp
	if "%2"=="release" (
		pushd %LOCAL_REPO_EDITOR%
		hg pull upstream --update
		hg push
	)
)
exit /b 0

:failure
exit /b -1
