@echo off

rem F9版リリースを少し楽にするためのスクリプトです。引数はありません。
rem 以下のスクリプトとフォルダが揃っている必要があります。
rem  * f9_release32.bat
rem  * f9_release64.bat
rem  * private (フォルダ)

setlocal enabledelayedexpansion

copy private\dailybuild.log private\dailybuild_backup.log

set dailybuild_datetime=0
set dailybuild_sub=0

for /f "delims=" %%l in (private\dailybuild.log) do (
    if !dailybuild_datetime! == 0 (
        set dailybuild_datetime=%%l
    ) else (
        set dailybuild_sub=%%l
    )
)

if %date:/=% == !dailybuild_datetime! (
    if !dailybuild_sub! == a (
        set dailybuild_sub=b
    ) else if !dailybuild_sub! == b (
        set dailybuild_sub=c
    ) else if !dailybuild_sub! == c (
        set dailybuild_sub=d
    ) else if !dailybuild_sub! == d (
        set dailybuild_sub=e
    ) else if !dailybuild_sub! == e (
        set dailybuild_sub=f
    ) else if !dailybuild_sub! == f (
        set dailybuild_sub=g
    ) else if !dailybuild_sub! == g (
        set dailybuild_sub=h
    ) else if !dailybuild_sub! == h (
        set dailybuild_sub=i
    ) else if !dailybuild_sub! == i (
        set dailybuild_sub=j
    ) else if !dailybuild_sub! == j (
        set dailybuild_sub=k
    ) else if !dailybuild_sub! == k (
        set dailybuild_sub=l
    ) else if !dailybuild_sub! == l (
        set dailybuild_sub=m
    ) else if !dailybuild_sub! == m (
        set dailybuild_sub=n
    ) else if !dailybuild_sub! == n (
        set dailybuild_sub=o
    ) else if !dailybuild_sub! == o (
        set dailybuild_sub=p
    ) else if !dailybuild_sub! == p (
        set dailybuild_sub=q
    ) else if !dailybuild_sub! == q (
        set dailybuild_sub=r
    ) else if !dailybuild_sub! == r (
        set dailybuild_sub=s
    ) else if !dailybuild_sub! == s (
        set dailybuild_sub=t
    ) else if !dailybuild_sub! == t (
        set dailybuild_sub=u
    ) else if !dailybuild_sub! == u (
        set dailybuild_sub=v
    ) else if !dailybuild_sub! == v (
        set dailybuild_sub=w
    ) else if !dailybuild_sub! == w (
        set dailybuild_sub=x
    ) else if !dailybuild_sub! == x (
        set dailybuild_sub=y
    ) else if !dailybuild_sub! == y (
        set dailybuild_sub=z
    )
) else (
    set dailybuild_sub=a
)

if not !dailybuild_sub! == a (
    set BUILD_N=!dailybuild_sub!
)

@echo on

dub upgrade

call f9_release64.bat %BUILD_N%
if not errorlevel = 0 goto failure
pushd %~dp0
call f9_release32.bat %BUILD_N%
if not errorlevel = 0 goto failure
pushd %~dp0

echo %date:/=%> private\dailybuild.log
echo !dailybuild_sub!>> private\dailybuild.log

:failure

endlocal
