
CWXEditor ビルドガイド
----------------------

ビルドツール:
 : dmd 2.079.0
 : Digital Mars rcc
ライブラリ:
 : DWT at GitHub

後はGitのクライアントがあると楽です。

 * D言語のコンパイラであるdmdのインストールについては、[D言語友の会](http://dusers.dip.jp/modules/wiki/?Tools%2FDMD)の記事が参考になります。
 * [Gitのインストールについても日本語記事があります](https://git-scm.com/book/ja/v1/%E4%BD%BF%E3%81%84%E5%A7%8B%E3%82%81%E3%82%8B-Git%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB)。


Windowsの場合
-------------

DWTをGitHubから取ってきます。

今はDWTも[dub](https://code.dlang.org/)で使えますが、CWXEditorの規模になると工夫無しではリンカがエラーを吐いてしまうので自前でライブラリを用意する必要があります。

以下のようにしてDWTをビルドします。

    git clone https://github.com/d-widget-toolkit/dwt.git
    cd dwt
    dub --build=release :base
    dub --build=release

64ビット版のライブラリを作成する場合は次のようにします。

    dub --build=release :base --arch=x86_64
    dub --build=release --arch=x86_64

後は、`dmd2/windows/bin/sc.ini`を弄くってDWTのインポートフォルダやらリソースフォルダやらを探しに行くようにしておきましょう。

たとえば:

    [Environment]

    DFLAGS="-I%@P%\..\..\src\phobos" "-I%@P%\..\..\src\druntime\import" "-I%@P%\..\..\import" "-I%@P%\..\..\..\lib\dwt32\base\src" "-I%@P%\..\..\..\lib\dwt32\org.eclipse.swt.win32.win32.x86\src" "-J%@P%\..\..\..\lib\dwt32\base\res" "-J%@P%\..\..\..\lib\dwt32\org.eclipse.swt.win32.win32.x86\res"
      :
    [Environment32]
    LIB=%LIB%;"%@P%\..\..\..\lib\dwt32";"%@P%\..\..\..\lib\dwt32\org.eclipse.swt.win32.win32.x86\lib"
      :
    [Environment64]
      :
    LIB=%LIB%;"%@P%\..\..\..\lib\dwt64";"%@P%\..\..\..\lib\dwt64\org.eclipse.swt.win32.win32.x86\lib"

最後にリソースコンパイル用のrccを入手します(32ビット版のみ)。

Digital MarsのサイトからBasic Utilitiesを入手して、パスを通しましょう(「パスを通す」などのキーワードで検索する事で、具体的な情報が見つかります)。

http://www.digitalmars.com//download/freecompiler.html

---

Dの処理系のバグにより音声ループ処理で問題が発生するため、その部分だけC言語のモジュールになっており、場合によってはcwxeditor本体より先にそちらをビルドする必要があります。

32-bit版はrccと同じ場所で入手できるDigital Mars C/C++ Compiler(dmc)、64-bit版はVisual Studio 2015が必要です。

以下のようにしてビルドします。

    rem 使用するVisual C++のコンパイラを64-bit版に切り替える
    "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64
    rem 64-bit版をビルド
    cl /c cwx\editor\gui\bassloop.c /Ox /Fobassloop64.obj
    rem 32-bit版をビルド
    dmc -obassloop32 -c -o .\cwx\editor\gui\bassloop.c

---

これでようやく準備完了です。

cwxeditor本体のビルドはビルドスクリプトbuild.dで行います。

rdmd等で実行してください。

    rdmd build

リリースビルドなら:

    rdmd build release

クリーンするなら:

    rdmd build clean

デバグビルドでコンソールを出さないなら:

    rdmd build gui

64ビット版なら`-m64`をつけます:

    rdmd build -m64


### 番外: マージツールについて

2018年2月現在、CWXEditorのバージョン管理には[Mercurial](https://www.mercurial-scm.org/)を使用していますが、MercurialのGUIクライアントTortoiseHgに付属しているマージツール(kdiff3)には、日本語ファイルをマージした時に内容が壊れてしまうバグが存在しています。

Windowsにおける有名なマージツールに[WinMerge](http://www.geocities.co.jp/SiliconValley-SanJose/8165/winmerge.html)があるので、そちらに差し替える事をお勧めします。

WinMergeをインストールしたら、TortoiseHg Workbenchを起動し、`ファイル(F) > 設定(S)`の「ユーザー設定のエクステンション」を選択し、`extdiff`にチェックを入れ、左上の「ファイルを開く」を押し、以下のように記入して保存してください。

    [extensions]
    extdiff = 

    [extdiff]
    cmd.wmdiff = <WinMergeのフルパス>/WinMergeU.exe
    opts.wmdiff = /r /e /x /ub

    [merge-tools]
    winmerge.args = /e /ub /dl other /dr local $other $local $output
    winmerge.regkey = Software\Thingamahoochie\WinMerge
    winmerge.regname = Executable
    winmerge.fixeol = True
    winmerge.checkchanged = True
    winmerge.gui = True


linuxの場合
-----------

linuxでのビルドは最新のバージョンでは試されていない事が多いです。

また、ビルドできたとしても全体が正常に動作する事はほとんどありませ
ん(数箇所修正すれば動くはずではあります)。

手順はWindows側と概ね同じです。

### 事前に必要なパッケージ

apt-get等で手に入れておきましょう。

 * libgnomeui-dev
 * libxtst-dev


### DライブラリとCWXEditorのビルド

DWTのビルドが完了すると、以下のライブラリファイルがlibディレクトリに生成されるはずです。

 * libdwt_base.a
 * libdwt.a

後は"/etc/dmd.conf"のDFLAGSを弄くってDWTのインポートフォルダやらリソースやらを探しに行くようにしておきましょう。
