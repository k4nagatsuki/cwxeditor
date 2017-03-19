
CWXEditor ビルドガイド
----------------------

ビルドツール:
 : dmd 2.073.2
 : Digital Mars rcc
ライブラリ:
 : DWT at GitHub

後はGitのクライアントがあると楽です。

 * D言語のコンパイラであるdmdのインストールについては、[D言語友の会](http://dusers.dip.jp/modules/wiki/?Tools%2FDMD)の記事が参考になります。
 * [Gitのインストールについても日本語記事があります](https://git-scm.com/book/ja/v1/%E4%BD%BF%E3%81%84%E5%A7%8B%E3%82%81%E3%82%8B-Git%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB)。


Windowsの場合
-------------

DWTをGitHubから取ってきます。

submoduleがあるので、submodule initとupdateをしておきましょう。各submoduleが最新のcommitになっていない事が結構あるので、強制的にpullもしておきます。

    git clone https://github.com/d-widget-toolkit/dwt.git
    cd dwt
    git submodule update --init
    git submodule foreach git pull origin master

準備ができたらビルドします。

    rdmd build base swt

64ビット版のライブラリを作成する場合は次のようにします。

    rdmd build base swt -m64

(ただし64ビットのビルド環境を整える事は簡単ではありません。[英文の参考文書もあります](https://wiki.dlang.org/Installing_DMD_on_64-bit_Windows_7_(COFF-compatible))が、英語が読めたとしても難しいので、無理に64ビットビルドを行おうとしない方がいいかもしれません)

後は、`dmd2/windows/bin/sc.ini`を弄くってDWTのインポートフォルダやらリソースフォルダやらを探しに行くようにしておきましょう。

    [Environment]

    DFLAGS="-I%@P%\..\..\src\phobos" "-I%@P%\..\..\src\druntime\import" "-I%@P%\..\..\import" "-I%@P%\..\..\dwt\imp" "-J%@P%\..\..\dwt\res"
      :
    [Environment32]
    LIB="%@P%\..\lib";"%@P%\..\..\dwt\lib"
      :
    [Environment64]
      :
    LIB=%LIB%;"%@P%\..\..\dwt\lib"

最後にリソースコンパイル用のrccを入手します(32ビット版のみ)。

Digital MarsのサイトからBasic Utilitiesを入手して、パスを通しましょう(「パスを通す」などのキーワードで検索する事で、具体的な情報が見つかります)。

http://www.digitalmars.com//download/freecompiler.html

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

後はどうかDWTが死なないことを私と一緒に祈ってください。


### 番外: マージツールについて

2017年3月現在、CWXEditorのバージョン管理には[Mercurial](https://www.mercurial-scm.org/)を使用していますが、MercurialのGUIクライアントTortoiseHgに付属しているマージツール(kdiff3)には、日本語ファイルをマージした時に内容が壊れてしまうバグが存在しています。

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

DWTをGitHubから取ってきます。

submoduleがあるので、submodule initとupdateをしておきましょう。各submoduleが最新のcommitになっていない事が結構あるので、強制的にpullもしておきます。

    git clone https://github.com/d-widget-toolkit/dwt.git
    cd dwt
    git submodule update --init
    git submodule foreach git pull origin master

準備ができたらビルドします。

    rdmd build base swt

ビルドが完了すると、以下のライブラリファイルがlibディレクトリに生成されるはずです。

 * dwt-base.a
 * org.eclipse.swt.gtk.linux.x86.a

`dwt/lib`にある状態では何をどうしてもリンクできなかったので、`cwxeditor_src/`に放り込んでしまってください。

名前が"lib"から始まっていないのが悪いのですが、そのままリンクする方法があるんでしょうか。自分は完膚無きまでにタコなので、分かっている人は教えてくださると助かります。

後は"/etc/dmd.conf"のDFLAGSを弄くってDWTのインポートフォルダやらリソースやらを探しに行くようにしておきましょう。

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

後はどうかDWTが死なないことを私と一緒に祈ってください。
