
[[[ CWXEditor ビルドガイド ]]]

ビルドツール:
	・dmd 1.056
	・bud 3.04
ライブラリ:
	・Tango 0.99.9
	・tangobos (based on Phobos 1.024)
	・DWT2 rev.111

　後はSubversionとMercurialのクライアントがあると楽です。


[ Windowsの場合 ]

　まずTango(dmdのバンドル版がいい感じです)を手に入れてパスを通して使えるように
しておきましょう。
　http://downloads.dsource.org/projects/tango/0.99.9/tango-0.99.9-bin-win32-dmd.1.056.zip
　追加的なライブラリも忘れずにダウンロードしてlibフォルダに放り込んでおきます。
　http://www.dsource.org/projects/tango/attachment/wiki/TopicInstallTangoDmd/dmd-win32-lib.zip

　次にtangobosのtrunkからrev.63を手に入れておきます。
---
svn co http://svn.dsource.org/projects/tangobos/trunk@63
---
　このままだとzlibが干渉してコンパイルできないとか色々超常現象が起こるので
パッチを当てます。"tangobos-rev.63_cwx.patch"がそれです。Z_NULLとかの名前を
微妙に変えただけですがこれで問題は起きなくなるはず。TortoiseSVNを使うと
簡単にパッチ当てができるみたいです。

　次にDWT2をMercurialのリポジトリから取ってきます。
---
hg clone -r 111 http://hg.dsource.org/projects/dwt2
---
　例によってバグがあるのでパッチを当てます。svnと違ってhgには自力でパッチを
当てる機能がついてるみたいです。ナイスだね。
---
cd dwt2
hg patch dwt2-rev.111_cwx.patch
---
　こんな感じで。

　後はTangoの"bin/sc.ini"を弄くってtangobosやDWT2のインポートフォルダやら
リソースフォルダやらを探しに行くようにしておきましょう。
---
DFLAGS="-I%@P%\..\tangobos" "-I%@P%\..\import" "-I%@P%\..\import\tango\core\vendor" -version=Tango -defaultlib=tango.lib -debuglib=tango.lib -L+tango.lib "-I%@P%\..\dwt2\base\src" "-I%@P%\..\dwt2\org.eclipse.swt.win32.win32.x86\src" "-J%@P%\..\dwt2\res"
---
　長ッ！

　最後にビルドに使うbudを手に入れて、bud_win_3.04.exeをbud.exeとリネーム
するなりして……
　http://www.dsource.org/projects/build/

　とりあえずこれで準備は完了。Digital Marsのrccとかも使うのですが、
無くてもアイコンが無くなるとかそんな程度の問題しか起きないから無問題。

　cwxeditor_srcフォルダでbuildと打ってみてください。releaseバージョンなら
build_releaseです。後はbudが一晩でやってくれました。
　最後にリンカが"org.eclipse.swt.win32.win32.x86"が見つからないとか文句を
言ってきますが、実は何の問題も無いようです。気になる人はディレクトリ名とSWT.d
内の該当箇所を'.'を含まない別の名前に変えましょう。

　後はどうかDWTが死なないことを私と一緒に祈ってください。


/ なぜtangobosやDWT2を事前にビルドしないのか /

　実はビルド済みのtangobosやDWT2をリンクしてビルドするレスポンスファイルを書い
てみたのですが(win32_d.rspがそれです)、ビルド成功して起動してみると正体不明の
アクセス違反は発生するわメモリアロケーションエラーが出るわ意味不明な現象が続々。
　あまつさえレスポンスファイル内の*.dファイルの位置を入替えると出るエラーが
変わるという地雷原状態。
　諦めました。
　D頑張れ。


[ linuxの場合 ]

　ビルドはできますが非常に不安定です。


/ 事前に必要なパッケージ /

　apt-get等で手に入れておきましょう。

・rake
・libgtk2.0-dev
・libxtst-dev
・libgnomeui-dev


/ DライブラリとCWXEditorのビルド /

　まずはTango(dmdのバンドル版がいい感じです)を手に入れてパスを通して使えるように
しておきましょう。
　http://downloads.dsource.org/projects/tango/0.99.9/tango-0.99.9-bin-linux-with-dmd.1.056.tar.gz

　次にtangobosのtrunkからrev.63を手に入れておきます。
---
svn co http://svn.dsource.org/projects/tangobos/trunk@63
---
　このままだとzlibが干渉してコンパイルできないとか色々超常現象が起こるので
パッチを当てます。"tangobos-rev.63_cwx.patch"がそれです。Z_NULLとかの名前を
微妙に変えただけですがこれで問題は起きなくなるはず。

　次にDWT2をMercurialのリポジトリから取ってきます。
---
hg clone -r 111 http://hg.dsource.org/projects/dwt2
---
　例によってバグがあるのでパッチを当てます。svnと違ってhgには自力でパッチを
当てる機能がついてるみたいです。ナイスだね。
---
cd dwt2
hg patch dwt2-rev.111_cwx.patch
---
　こんな感じで。
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

　後はTangoの"bin/sc.ini"を弄くってtangobosやDWT2のインポートフォルダやら
リソースフォルダやらを探しに行くようにしておきましょう。
---
DFLAGS=-I%@P%/../tangobos -I%@P%/../import -I%@P%/../include -I%@P%/../import/tango/core/vendor -L-L%@P%/../lib -version=Tango -defaultlib=tango-dmd -debuglib=tango-dmd -J%@P%/../dwt2/res -I%@P%/../dwt2/imp -L-L%@P%/../tangobos
---

　ここまで準備をすれば、後はレスポンスファイルを指定してdmdを実行するだけ。
---
dmd @linux_d.rsp
---
　成功すると思います。多分すると思う。するんじゃないかな。

　後はどうかDWTが死なないことを私と一緒に祈ってください。

