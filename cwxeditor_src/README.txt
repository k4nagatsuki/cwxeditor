
[[[ CWXEditor ビルドガイド ]]]

ビルドツール:
	・dmd 2.066
	・Digital Mars rcc
ライブラリ:
	・DWT at GitHub

　後はgitのクライアントがあると楽です。


[ Windowsの場合 ]

　DWTをGitHubから取ってきます。
　submoduleがあるので、submodule initとupdateをしておきましょう。
　各submoduleが最新のcommitになっていない事が結構あるので、強制的に
pullもしておきます。
---
git clone https://github.com/d-widget-toolkit/dwt.git
cd dwt
git submodule update --init
git submodule foreach git pull origin master
---
　準備ができたらビルドします。
---
rdmd build base swt
---

　後は、dmd2/windows/bin/sc.iniを弄くってDWTのインポートフォルダやら
リソースフォルダやらを探しに行くようにしておきましょう。
　DWTが今の所32bit版しかないので、cwxeditorも32bitでビルドする必要が
あります。
---
[Environment]

DFLAGS="-I%@P%\..\..\src\phobos" "-I%@P%\..\..\src\druntime\import" "-I%@P%\..\..\import" "-I%@P%\..\..\dwt\imp" "-J%@P%\..\..\dwt\res"
  :

[Environment32]
LIB="%@P%\..\lib";"%@P%\..\..\dwt\lib"
  :

---

　最後にリソースコンパイル用のrccを入手します。
　Digital MarsのサイトからBasic Utilitiesを入手して、パスを通しましょう。
　http://www.digitalmars.com//download/freecompiler.html

　これでようやく準備完了です。
　cwxeditor本体のビルドはビルドスクリプトbuild.dで行います。
　rdmd等で実行してください。
---
rdmd build
---
　リリースビルドなら:
---
rdmd build release
---
　クリーンするなら:
---
rdmd build clean
---
　デバグビルドでコンソールを出さないなら:
---
rdmd build gui
---

　後はどうかDWTが死なないことを私と一緒に祈ってください。


[ linuxの場合 ]

　linuxでのビルドは最新のバージョンでは試されていない事が多いです。
また、ビルドできたとしても全体が正常に動作する事はほとんどありませ
ん(数箇所修正すれば動くはずではあります)。
　手順はWindows側と概ね同じです。


/ 事前に必要なパッケージ /

　apt-get等で手に入れておきましょう。

・libgtk2.0-dev
・libxtst-dev
・libgnomeui-dev


/ DライブラリとCWXEditorのビルド /

　DWTをGitHubから取ってきます。
　submoduleがあるので、submodule initとupdateをしておきましょう。
　各submoduleが最新のcommitになっていない事が結構あるので、強制的に
pullもしておきます。
---
git clone https://github.com/d-widget-toolkit/dwt.git
cd dwt
git submodule update --init
git submodule foreach git pull origin master
---
　準備ができたらビルドします。
---
rdmd build base swt
---
　ビルドが完了すると、以下のライブラリファイルがlibディレクトリに生成され
るはずです。
　 dwt-base.a
　 org.eclipse.swt.gtk.linux.x86.a
　dwt/libにある状態では何をどうしてもリンクできなかったので、cwxeditor_src/
に放り込んでしまってください。
　名前が"lib"から始まっていないのが悪いのですが、そのままリンクする方法が
あるんでしょうか。自分は完膚無きまでにタコなので、分かっている人は教えて
くださると助かります。

　後は"/etc/dmd.conf"のDFLAGSを弄くってDWTのインポートフォルダやらリソー
スやらを探しに行くようにしておきましょう。

　これでようやく準備完了です。
　cwxeditor本体のビルドはビルドスクリプトbuild.dで行います。
　rdmd等で実行してください。
---
rdmd build
---
　リリースビルドなら:
---
rdmd build release
---
　クリーンするなら:
---
rdmd build clean
---
　デバグビルドでコンソールを出さないなら:
---
rdmd build gui
---

　後はどうかDWTが死なないことを私と一緒に祈ってください。
