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

rem commit時のユーザ名
set USER=username
rem commit時のEメールアドレス
set EMAIL=username@example.com

rem テキストエディタ
set EDITOR=notepad

rem -----------------------------------------------------------------------

if "%1"=="" exit /b -1
if not "%2"=="test" (
	if not "%2"=="release" exit /b -1
)

set CWX_VERSION=master

set COMMIT_MESSAGE_EDITOR=%1
set COMMIT_MESSAGE_EDITOR=%COMMIT_MESSAGE_EDITOR:beta=β%
set COMMIT_MESSAGE_EDITOR=%COMMIT_MESSAGE_EDITOR:a=α%

pushd %DEST_DIR_EDITOR%
git clone %LOCAL_REPO_EDITOR% cwxeditor_temp
cd cwxeditor_temp\cwxeditor_src
git config --local user.name "%USER%"
git config --local user.email "%EMAIL%"

git checkout %CWX_VERSION%
%EDITOR% ..\editor_history.txt
git add ..\editor_history.txt
%EDITOR% @version.txt
git add @version.txt
git commit -m "%COMMIT_MESSAGE_EDITOR%"
git tag release_%1
if not "%3"=="copy_builds" (
	if "%2"=="release" (
		git pull %MAIN_REPO_EDITOR% master
		git push %MAIN_REPO_EDITOR% master
		git push %MAIN_REPO_EDITOR% --tags
	)
)
dub clean
dub build --compiler=ldc2 --build=release --arch=x86
if not errorlevel = 0 goto failure
copy cwxeditor.exe %DEST_DIR_EDITOR%
git clone ../ %DEST_DIR_EDITOR%\cwxeditor
pushd %DEST_DIR_EDITOR%\cwxeditor
git config --local user.name "%USER%"
git config --local user.email "%EMAIL%"
git checkout %CWX_VERSION%
rmdir /S /Q .git
del .gitignore
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

dub clean
dub build --compiler=ldc2 --build=release --arch=x86_64
if not errorlevel = 0 goto failure
copy cwxeditor.exe %DEST_DIR_EDITOR%
git clone ../ %DEST_DIR_EDITOR%\cwxeditor
pushd %DEST_DIR_EDITOR%\cwxeditor
git config --local user.name "%USER%"
git config --local user.email "%EMAIL%"
cd ..
cd cwxeditor
git checkout %CWX_VERSION%
rmdir /S /Q .git
del .gitignore
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
		git pull upstream master
		git pull upstream --tags
		git push origin master
		git push origin --tags
	)
)
exit /b 0

:failure
exit /b -1
