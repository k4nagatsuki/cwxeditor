
[[[ CWXEditor ビルドガイド ]]]

ビルドツール:
	・dmd 2.055
	・rake
	・Digital Mars rcc
ライブラリ:
	・DWT2 rev.125

　後はSubversionとMercurialのクライアントがあると楽です。


[ Windowsの場合 ]

　DWT2をMercurialのリポジトリから取ってきます。
---
hg clone -r 125 http://hg.dsource.org/projects/dwt2
---
　DWT2はビルドにrakeを使います。こいつはRuby言語のスクリプトなのですが、
RubyInstaller for Windowsを使うとRuby本体諸共入手できるようです。
　http://rubyinstaller.org/
　Rubyのbinフォルダにパスを通して、DWT2をビルド。baseとswtだけでOKです。
---
rake base swt
---

　後は、dmd2/windows/bin/sc.iniを弄くってDWT2のインポートフォルダやら
リソースフォルダやらを探しに行くようにしておきましょう。
---
LIB="%@P%\..\lib";\dm\lib;"%@P%\..\..\dwt2\lib"
DFLAGS="-I%@P%\..\..\src\phobos" "-I%@P%\..\..\src\druntime\import" "-I%@P%\..\..\import" "-I%@P%\..\..\dwt2\imp" "-J%@P%\..\..\dwt2\res"
LINKCMD=%@P%\link.exe
---
　最後にリソースコンパイル用のrccを入手します。
　Digital MarsのサイトからBasic Utilitiesを入手して、パスを通しましょう。
　http://www.digitalmars.com//download/freecompiler.html

　これでようやく準備完了です。
　cwxeditor本体のビルドはDigital Marsのmakeで行います。
　Makefileはwin32.makです。
---
make -f win32.mak
---
　リリースビルドなら:
---
make -f win32.mak release
---

　後はどうかDWTが死なないことを私と一緒に祈ってください。


[ linuxの場合 ]

　linuxでのビルドは今の所試していません。手順はWindows側と概ね同じです。


/ 事前に必要なパッケージ /

　apt-get等で手に入れておきましょう。

・rake
・libgtk2.0-dev
・libxtst-dev
・libgnomeui-dev


/ DライブラリとCWXEditorのビルド /

　DWT2をMercurialのリポジトリから取ってきます。
---
hg clone -r 125 http://hg.dsource.org/projects/dwt2
---
　さらに、org.eclipse.swt.browserがあると余計な依存関係が発生するので、
消すか、どこかへ移動してしまう必要があります。
---
mv org.eclipse.swt.gtk.linux.x86/src/org/eclipse/swt/browser .
---

　DWT2はビルドにrakeを使います。
　rakeで"base"と"swt"をビルドし、ライブラリを作りましょう。
　 dwt-base.a
　 org.eclipse.swt.gtk.linux.x86.a
　dwt2/libにある状態では何をどうしてもリンクできなかったので、cwxeditor_src/
に放り込んでしまってください。
　名前が"lib"から始まっていないのが悪いのですが、そのままリンクする方法が
あるんでしょうか。自分は完膚無きまでにタコなので、分かっている人は教えて
くださると助かります。

　後はTangoの"bin/sc.ini"のDFLAGSを弄くってDWT2のインポートフォルダやら
リソースフォルダやらを探しに行くようにしておきましょう。

　ここまで準備をすれば、後はmakeするだけ。
　Makefileはlinux.makです。
---
make -f linux.mak
---
　リリースビルドなら:
---
make -f linux.mak release
---

　後はどうかDWTが死なないことを私と一緒に祈ってください。


[ dwt2_trace.patch について ]

　Javaと違ってDは例外のスタックトレースを出してくれないため、とりあえずの
対策として、全てのSWTExceptionとSWTErrorがファイル名と行番号を含むように
したパッチです。以下のようにして適用できます。

---
cd dwt2
hg import dwt2_trace.patch
---

　これが無いとデバグにどれほど苦労する事やら……あっても苦労するけど。
