
CWXEditor ビルドガイド
----------------------

ビルドツール:
 : dmd 2.097.0 または LDC 1.25.1
 : Digital Mars rcc
 : Microsoft Windows Resource Compiler (RC)
ライブラリ:
 : DWT at GitHub, dxml at GitHub

後はGitのクライアントがあると楽です。

 * D言語のコンパイラであるdmdのインストールについては、[D言語友の会](http://dusers.dip.jp/modules/wiki/?Tools%2FDMD)の記事が参考になります。
 * [Gitのインストールについても日本語記事があります](https://git-scm.com/book/ja/v1/%E4%BD%BF%E3%81%84%E5%A7%8B%E3%82%81%E3%82%8B-Git%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB)。


Windowsの場合
-------------

### リソースコンパイラの入手方法

dmdの32ビット版でビルドする時のリソースコンパイルに使うDigital Mars rccは以下のサイトから入手できます。

http://www.digitalmars.com//download/freecompiler.html

ここからBasic Utilitiesを入手して、パスを通しましょう(「パスを通す」などのキーワードで検索する事で、具体的な情報が見つかります)。

64ビット版、またはLDCでのビルドで使用するMicrosoft Windows Resource Compilerは、Build Tools for Visual Studio 2019等に入っているものが使用できます。

https://visualstudio.microsoft.com/ja/downloads/


### dubを使用してビルドする

ビルドツールが揃っている場合は、`cwxeditor_src`フォルダでD言語標準のビルドツールであるdubを実行する事で簡単にビルド・実行できます。

    dub

ビルドだけなら:

    dub build

コンソール無し版は:

    dub --build=gui

リリース版は:

    dub --build=release


### ビルドスクリプトを使う

dubは標準で64ビット版をビルドします。32ビット版をビルドしたい場合は以下のようにします。

    dub --arch=x86

ところが、dmd 2.093.1では謎のエラーが発生してビルドに失敗してしまいます(LDCなら問題ありません。ただし64ビット版と32ビット版の両方をビルドするならmultilib版を使いましょう)。

cwxeditorでは歴史的に独自のビルドスクリプトを使用してきましたが、そのスクリプトは今でも使用でき、こちらはdmdによる32ビット版ビルドも問題無く行う事が可能です。ただし、外部ライブラリをセットアップする必要があるため多少手間がかかります。

まず、DWTをGitHubから取ってきてビルドします。

    git clone https://github.com/d-widget-toolkit/dwt.git
    cd dwt
    dub --build=release :base --arch=x86
    dub --build=release --arch=x86

64ビット版のライブラリを作成する場合は次のようにします。

    dub --build=release :base --arch=x86_64
    dub --build=release --arch=x86_64

次に、DWTと同様にdxmlを取ってきてビルドします。

    git clone https://github.com/jmdavis/dxml.git
    cd dwt
    dub --build=release --arch=x86

64ビット版のライブラリを作成する場合は次のようにします。

    dub --build=release --arch=x86_64

後は、`dmd2/windows/bin/sc.ini`を編集してライブラリのインポートフォルダやリソースフォルダを探しに行くようにしておきましょう。

たとえば:

    [Environment]

    DFLAGS="-I%@P%\..\..\src\phobos" "-I%@P%\..\..\src\druntime\import" "-I%@P%\..\..\import" "-I%@P%\..\..\..\lib\dwt32\base\src" "-I%@P%\..\..\..\lib\dwt64\org.eclipse.swt\Eclipse SWT\common" "-I%@P%\..\..\..\lib\dwt64\org.eclipse.swt\Eclipse SWT Custom Widgets\common" "-I%@P%\..\..\..\lib\dwt32\org.eclipse.swt.win32.win32.x86\src" "-J%@P%\..\..\..\lib\dwt32\base\res" "-J%@P%\..\..\..\lib\dwt32\org.eclipse.swt.win32.win32.x86\res" "-I%@P%\..\..\..\lib\dxml32\source"
      :
    [Environment32]
    LIB=%LIB%;"%@P%\..\..\..\lib\dwt32";"%@P%\..\..\..\lib\dwt32\org.eclipse.swt.win32.win32.x86\lib";"%@P%\..\..\..\lib\dxml32"
      :
    [Environment64]
      :
    LIB=%LIB%;"%@P%\..\..\..\lib\dwt64";"%@P%\..\..\..\lib\dwt64\org.eclipse.swt.win32.win32.x86\lib";"%@P%\..\..\..\lib\dxml64"

これでようやく準備完了です。

ビルドスクリプト`build.d`でビルドを実行します。rdmdはD言語のソースファイルをその場で実行するコマンドです。

    rdmd build

リリースビルドなら:

    rdmd build release

クリーンするなら:

    rdmd build clean

デバグビルドでコンソールを出さないなら:

    rdmd build gui

64ビット版もビルドできます。`-m64`をつけて:

    rdmd build -m64


linuxの場合
-----------

linuxでのビルドは最新のバージョンでは試されていない事が多いです。

また、ビルドできたとしても全体が正常に動作する事はほとんどありません(数箇所修正すれば動くはずではあります)。


### 事前に必要なパッケージ

apt等で手に入れておきましょう。


 * libcairo2-dev
 * libglib2.0-dev
 * libgnomeui-dev
 * libgtk2.0-dev
 * libpango1.0-dev
 * libxcomposite-dev
 * libxcursor-dev
 * libxdamage-dev
 * libxfixes-dev
 * libxi-dev
 * libxinerama-dev
 * libxrandr-dev
 * libxtst-dev


### dubを使用してビルドする

linux側のリンカにはWindows側のOPTLINKのような問題はありません。dubを使ってビルドしてください。

    dub

コンソール無し版は:

    dub --build=gui

リリース版は:

    dub --build=release
