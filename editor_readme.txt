
[[[ CWXEditor ]]]

[ 目次 ]

  1. これは何？
  2. インストール
  3. アンインストール
  4. 使い方
  5. 制限事項
  6. 困ったときは
  7. 起動オプション
  8. 基本設定ファイル "cwxeditor.config"
  9. CardWirth本体の探し方のルール
 10. CardWirthEditorと併用する際の注意点
 11. *.wex について
 12. CWXPathについて
 13. 外部リソースの読込み
 14. 多言語化について

---------------------------------------------------------------------------
[ 1. これは何？ ]

　XML形式のCardWirthデータを作成するエディタのDによる実装です。
　クラシックなCardWirthシナリオのエディタとしてもご利用いただけます。

---------------------------------------------------------------------------
[ 2. インストール ]

　アーカイブを展開した場所でそのまま使用できますが、最初に [ツール] >
[エディタ設定] で CardWirthPy.exeの場所 を指定しておく事をお勧めします。
ここを設定しないとCardWirthPy付属のスキンが使用できず、カードの背景が
真っ白になったりします。

---------------------------------------------------------------------------
[ 3. アンインストール ]

　CWXEditorのフォルダを丸ごと消してください。

　通常、CWXEditorは、設定ファイルをユーザ固有のアプリケーションデータ
フォルダに生成します。通常、次のパスでアクセスできます。
　 %APPDATA%\cwxeditor
　ゴミが残るようで気になる方は、このフォルダも削除してください。

---------------------------------------------------------------------------
[ 4. 使い方 ]

　詳細な使い方はまだ書かれていません。
　大枠では従来のCardWirthEditorと同じです。

---------------------------------------------------------------------------
[ 5. 制限事項 ]

　今のところ、シナリオのタグやラベルは設定できません。
　JPYのアニメーションは表示できません。
　JPTXは不完全にしか表示できません。
　Windowsでは一部フォントのアンチエイリアスを正しくかけられず、その結果と
してフォントのサイズが若干小さく見える事があります。
　Windows以外の環境では、フォントのサイズを正しく設定できない事の方が多く
なります。

---------------------------------------------------------------------------
[ 6. 困ったときは ]

　技術的限界により、現在のCWXEditorはいくつか修正困難な問題を抱えています。
　次のような状態に陥った場合、参考にして対処してみてください。

# BGMが鳴らなくなる場合がある

　VirtualMIDISynthというソフトウェアと併用すると音周りに問題が発生する事が
あるようです。その場合は、VirtualMIDISynthによるドライバ設定をシステム標準
に戻すと回復します。
　VirtualMIDISynthとは無関係に問題が発生する場合、開発者に連絡してください。

# シナリオの保存後にハングアップしたように見える(保存自体は成功している)

　USB 1.0で繋げた数世代前の外付けHDDなど、ファイルへのアクセスに長い時間が
かかる環境で発生する事があります。
　シナリオ内のファイル一覧の更新に非常に時間がかかっているだけなので、数分
待てば回復する可能性があります。
　設定ダイアログで「ファイル・フォルダの変更を自動的に追跡する」のチェック
を外すか、ファイル一覧を閉じて非表示にする事で回避できるかもしれません。

# シナリオをクラシックからXML形式に変換したとき、素材の参照が正しくなくなる

　作成されたXML形式のシナリオのフォルダに、「Material」フォルダが生成されて
いるかどうか確認してください。
　生成されていない場合、圧縮ファイルの一時展開先に対してのファイルやフォル
ダの書き込みが上手くいっていない可能性があります。
　一時展開先を変更するなどの対策により、解決する事があります。
　例えば一時展開先を"temp"にするとcwxeditorフォルダの直下にtempフォルダが
生成され、そこが展開先になります。cwxeditor以下にフォルダを生成できる状況
であれば、それで問題が解決する可能性があります。

# 長大なコンテントツリーを作成すると動作がおかしくなる

　ライブラリのバグによるものと思われます。
　よほど長大でなければ発生しないので、適度に新しいツリーを作成して折り返す
ようにすれば問題ありません。

---------------------------------------------------------------------------
[ 7. 起動オプション ]

　クリックだの何だので普通に起動しますが、何気なくコマンドラインオプション
を付けられるようになってます。

使い方: cwxeditor [-help | -putlangfile <PATH> | -conf <PATH>
                   | -create <NAME> [<SKIN>] | -createclassic <NAME> [<PATH>]
                   | -selectfile <PATH> | -noload] <SCENARIO> [<CWXPath ...>]
オプション:
  -help         起動オプションの説明を表示して終了します。
  -putlangfile <PATH> デフォルトの言語設定ファイル<PAHT>を出力して終了します。
  -conf <PATH>  指定されたパスの基本設定ファイルを使用します。
  -create        <NAME> [<SKIN>]  起動後にシナリオを新規作成します。
  -createclassic <NAME> [<PATH>]  起動後、<PATH>で指定されたフォルダに
                                  クラシックなシナリオを新規作成します。
  -selectfile  <PATH> 指定されたファイルをファイルビューで選択します。
  -noload       起動後、前回終了時の編集状態を復元しません。
  <SCENARIO>    起動と同時に指定されたシナリオを開きます。
                (*.wsn/Summary.xml/Summary.wsm/[フォルダ])
OpenID:
  -a <ID>       シナリオを開いた後、<ID>で指定したIDのエリアを開きます。
  -b <ID>       シナリオを開いた後、<ID>で指定したIDのバトルを開きます。
  -p <ID>       シナリオを開いた後、<ID>で指定したIDのパッケージを開きます。
CWXPath:
  <CWXPath>     シナリオを開いた後、<CWXPath>で指定したリソースを開きます。
                詳しくは後述。

---------------------------------------------------------------------------
[ 8. 基本設定ファイル "cwxeditor.config" ]

　以下のようなテキストを"cwxeditor.config"という名前でCWXEditorのフォルダに
保存する事により、設定ファイルをどこから読み込むか指定できます。
---
<?xml version="1.0"?>
<initialize>
    <location>standard</location>
    <file>cwxeditor.xml</file>
</initialize>
---
　"<location>standard</location>"となっている部分を"<location>local</location>"
に書き換える事によって、ver.1.0と同じように、CWXEditor本体と同じフォルダに
設定ファイルを置く事ができるようになります。
　なお、ver.1.0との互換性を保つため、CWXEditor本体のフォルダにcwxeditor.xml
が見つかった場合、デフォルトでlocalを指定したのと同じように動作します。
　copyを指定した場合、ユーザ毎の設定ファイルが見つからなかった場合に限り、
CWXEditor本体のフォルダにあるcwxeditor.xmlをユーザ毎のフォルダにコピーします。
　nothingを指定した場合、設定ファイルの読込・保存を行いません。一時展開先、
及びバックアップ先は、%APPDATA%\cwxeditor_no_settingsに生成され、CWXEditor
終了時に削除されます。

---------------------------------------------------------------------------
[ 9. CardWirth本体の探し方のルール ]

　CWXEditorは、CardWirthPyとセットで使用される事を前提に設計されています。
しかしながら、CardWirthPyのリソース(画像やBGM等々)のみを使用していたのでは、
クラシックなシナリオを編集する際に不都合が生じます。
　例えば、学園バリアントは、CardWirthPyのClassicスキンと比較すると、一部の
効果音が欠けています。学園バリアント向けシナリオを編集中にClassicスキンに
含まれている効果音一覧を見せられても、どれを使用していいのか分かりません。
　そこでCWXEditorでは、クラシックなシナリオを開いたとき、以下のようなルール
でクラシックなCardWirthエンジンを検索し、そのエンジンのリソースを使用する
ようになっています。

 1. シナリオの一つ上のフォルダにDataフォルダがあるか確認し、あるようであれば
    その中に"Table\MapOfWirth.BMP"が存在しているかを確認します。
 2. Dataフォルダが無いようであれば、"D_[A-Z]1"もしくは"[A-Z]_dt"というフォル
    ダを代わりに探して同様に"Table\MapOfWirth.BMP"の存在を確認します。
 3. "MapOfWirth.BMP"が見つかったら、Data等のフォルダと同じところにCardWirth
    エンジンがあるかどうかを確認します。以下のような名前がCardWirthエンジン
    と看做されます。
     - CardWirth.exe
     - *Wirth.exe
     - CardWirth_*.exe
 4. Dataフォルダもしくはエンジンが見つからなかった場合、フォルダ階層の一つ
    上に移動して1.からの手順を繰り返します。
 5. フォルダ階層の最上位まで来ても見つからなかった場合は、CardWirthPyの
    Classicスキンを使用します。
 6. CardWirthPyの本体の場所も指定されていなかった場合、スキン無しでの編集
    モードになります。この場合、カードの台紙等は一切表示されず、標準の素材
    も選択できません。

---------------------------------------------------------------------------
[ 10. CardWirthEditorと併用する際の注意点 ]

　CWXEditorで保存したシナリオをCardWirthEditorで編集し、保存した場合、拡
張データの不整合が発生する事があります。
　二つのエディタを使い分けて編集する場合、 [ 11. *.wex について ] を参照
し、拡張データを保存しないよう設定する事をお勧めします。

# コメント
　イベントコンテントの位置が変化した場合、コメントのつく場所が移動してし
まったり、コメントが消えてしまったりする可能性があります。
　データとしては無害です。

# 格納イメージのファイルパス
　CardWirthEditorでカードを削除して同じIDで別のカードを作り直したりした場
合、CWXEditorで再読込すると、現在存在するカードの画像が削除したカードの画
像になってしまう等の現象が発生する可能性があります。

# 参照カード
　CardWirthEditorでキャストの持ち札を削除して同じIDで別の持ち札を作り直し
たりした場合、CWXEditorで再読込すると、元のカードに戻ってしまう等の現象が
発生する可能性があります。

---------------------------------------------------------------------------
[ 11. *.wex について ]

　クラシックなシナリオを保存した時、以下のファイルが作成される事があります。

・Comment.wex
・ImageRef.wex
・CardRef.wex
・Template.wex

　これらはクラシックなCardWirthEditorでは作成されない、CWXEditor特有の拡張
情報ファイルです。次のようなデータが保存されています。

・Comment.wex  ... イベントコンテントにつけたコメント。
・ImageRef.wex ... カードに格納された画像のファイルパス。
・CardRef.wex  ... キャストの所有カード等の参照先ID。
・Template.wex ... シナリオに付属するイベントテンプレート。

　これらを生成したくない場合は、以下のようにしてください。

# Comment.wex
　コメントが存在しなければ、このファイルは生成されません。すでに存在してい
た場合は、保存時に削除されます。
　ワイルドカード'*'などの検索によってすべてのコメントを探し出し、それらを
削除するか、Comment.wexを手動で削除した後、シナリオを再読込するなどして、
すべてのコメントを消す事ができます。

# ImageRef.wex
　設定の「クラシックなシナリオで格納イメージのファイルパスを保存する」の
チェックを外してシナリオを保存すると、ImageRef.wexは生成されません。すで
に存在していた場合は、削除されます。

# CardRef.wex
　キャストの所有カードや効果によって召喚されるカードを参照式で設定してい
なければ生成されません。設定の「キャストの所有カードや召喚対象のカードを
参照で設定する」のチェックを外してください。
　すでに参照式になっているカードを格納に戻したい場合、CardRef.wexを削除し
てシナリオを再読込してください。

# Template.wex
　シナリオのテンプレートが存在しなければ保存されません。
　イベントツリービューのコンテントボックスのイベントテンプレートメニュー
から、シナリオのテンプレートの編集を行う事ができます。そこですべてのテン
プレートを削除すれば、ファイルもシナリオの保存時に削除されます。

# 内部構造  ※ この項の内容は技術者向けです。
　wexファイルの内容は、ごく普通のXMLです。
　Template.wex以外は、拡張情報の配置箇所をCWXPathで持つという構造が共通し
ています。従って、*.wexを更新せずにイベントコンテントツリーなどの構造を変
更すると、ずれた場所に拡張情報が配置されてしまいます。
　Comment.wexは以下のような構造になっています:
---
<!DOCTYPE comments[
	<!ELEMENT comments (comment*)>
	<!ATTLIST comments dataVersion CDATA #FIXED "1">
	<!ELEMENT comment (#PCDATA)><!-- コメント本文 -->
	<!ATTLIST comment path CDATA #REQUIRED><!-- CWXPath(コンテント) -->
]>
---
　実際のデータは以下のようになります。dataVersionは現在"1"固定です:
---
<?xml version="1.0"?>
<comments dataVersion="1">
  <comment path="area:id:1/event:0/:0/:0/:0/:0">コメント一行目
二行目</comment>
</comments>
---
　ImageRef.wexの構造は以下のようになっています:
---
<!DOCTYPE imageRefs[
	<!ELEMENT imageRefs (imageRef*)>
	<!ATTLIST imageRefs dataVersion CDATA #FIXED "1">
	<!ELEMENT imageRef (#PCDATA)><!-- シナリオからの相対ファイルパス -->
	<!ATTLIST imageRef path CDATA #REQUIRED><!-- CWXPath(貼り紙かカード) -->
]>
---
　実際のデータは:
---
<?xml version="1.0"?>
<imageRefs dataVersion="1">
	<imageRef path="">harigami.bmp</imageRef>
	<imageRef path="castcard:id:1">cast1.bmp</imageRef>
	<imageRef path="castcard:id:2">cast2.bmp</imageRef>
</imageRefs>
---
　通常のCardWirth参照イメージと同様、相対ファイルパスはTableフォルダ内の
画像を指している場合があります。
　CardRef.wexは以下の通りです。召喚獣召喚効果のための"ネスト可能数"が存在
しています:
---
<!DOCTYPE cardRefs[
	<!ELEMENT cardRefs (maxNest*,cardRef*)>
	<!ATTLIST cardRefs dataVersion CDATA #FIXED "1">
	<!ELEMENT maxNest (#PCDATA)><!-- ネスト可能数 -->
	<!ATTLIST maxNest path CDATA #REQUIRED><!-- CWXPath(効果) -->
	<!ELEMENT cardRef (#PCDATA)><!-- カードID -->
	<!ATTLIST cardRef path CDATA #REQUIRED><!-- CWXPath(キャストか効果) -->
]>
---
　実際のデータは:
---
<?xml version="1.0"?>
<cardRefs dataVersion="1">
	<maxNest path="beastcard:id:1/motion:2">3</maxNest>
	<maxNest path="skillcard:id:1/motion:3">7</maxNest>
	<cardRef path="beastcard:id:1/motion:2/beastcard:id:1">1</cardRef>
	<cardRef path="castcard:id:1/skillcard:id:1">1</cardRef>
	<cardRef path="skillcard:id:1/motion:3/beastcard:id:1">1</cardRef>
	<cardRef path="beastcard:id:1/motion:3/beastcard:id:1">2</cardRef>
	<cardRef path="beastcard:id:2/motion:0/beastcard:id:1">1</cardRef>
</cardRefs>
---
　ネスト可能数は、召喚獣が自分自身を呼び出したり、今呼び出しているのは自
分ではないが巡り巡ってやはり自分自身の呼出に辿り着く場合など、無限に再帰
呼出が発生してしまう場合に参照され、その回数に制限を設けます。
　ネスト可能数が10であれば、11回目の再帰呼出は無効となり、効果の召喚獣は
「無し」に設定されます。
　CardRef.wex中でネスト可能数が設定されていない召喚獣召喚効果は、ネスト可
能数 = 1 として扱います。
　Template.wexは次のような構造になっています:
---
<!DOCTYPE templates[
	<!ELEMENT templates (eventTemplates*)>
	<!ATTLIST templates dataVersion CDATA #FIXED "1">
	<!ELEMENT eventTemplate (eventTemplate*)>
	<!ATTLIST eventTemplate name CDATA #REQUIRED><!-- テンプレート名 -->
	<!ATTLIST eventTemplate mnemonic CDATA #IMPLIED><!-- アクセスキー -->
	<!ATTLIST eventTemplate hotkey CDATA #IMPLIED><!-- ショートカット -->
	<!ELEMENT eventTemplate (#PCDATA)><!-- CWXスクリプト -->
]>
---
　実際のデータは以下のようになります。
---
<?xml version="1.0"?>
<templates dataVersion="1">
  <eventTemplates>
    <eventTemplate name="1秒ウェイト" mnemonic="1" hotkey="Ctrl+Shift+1">wait 10</eventTemplate>
    <eventTemplate name="3秒ウェイト" mnemonic="2" >wait 30</eventTemplate>
  </eventTemplates>
</templates>
---

---------------------------------------------------------------------------
[ 12. CWXPathについて ]

　CWXEditorで開いたシナリオの各エリア・フラグ・コンテント等のリソースには
全て、統一書式のパスが割り振られます。以下のようなものです

 - battle:id:2
 - castcard:8/beastcard:0/event:0
 - area:3/event:0/:5/:1

　これが何を意味しているのかというと……

battle:id:2
	ID:2のバトル
castcard:8/beastcard:0/event:0
	8番目のキャスト
	 - が持つ0番目の召喚獣カード
	  - の下にある0番目のイベントツリー
area:3/event:0/:5/:1
	3番目のエリア
	 - の下にある0番目のイベントツリー
	  - の下にある0番目のスタートコンテント
	   - の下にある5番目のコンテント
	    - の下にある1番目のコンテント

　という感じです。番号は0から始まる事になっています。また、エリア等のIDを
持つリソースであれば":id"と記述する事によってIDを指定できます。
　リソースの種類毎に"area"や"castcard"のように名前がついてますが、イベント
コンテントは冗長になるので"名前無し"になっていたりします。
　以下にリソース名の一覧を示しておきます:

　area       .... エリア
　battle     .... バトル
　package    .... パッケージ

　castcard   .... キャストカード
　skillcard  .... スキルカード
　itemcard   .... アイテムカード
　beastcard  .... 召喚獣カード
　infocard   .... 情報カード

　menucard   .... エリアに配置されるカード
　enemycard  .... バトルに配置されるカード

　event      .... イベントツリー
　motion     .... 効果
　dialog     .... 台詞コンテント

　variable   .... 状態変数(フラグ・ステップ)のルート
　flag       .... フラグ
　step       .... ステップ
　dir        .... 状態変数のサブディレクトリ

　以下は、シナリオに含まれるリソースではないものの、各種のビューを開きたい
場合に使用されるパスです:

　tableview     .... テーブルビュー
　variableview  .... 状態変数ビュー
　castcardview  .... キャストカードビュー
　skillcardview .... 特殊技能カードビュー
　itemcardview  .... アイテムカードビュー
　beastcardview .... 召喚獣カードビュー
　infocardview  .... 情報カードビュー
　fileview      .... ファイルビュー

　CWXPathは、末尾に属性をつけて、開く際の細かい挙動を指示する事ができます。

 - area:id:1;shallow;eventview

　';'でパス本体、及び直前の属性と区切る事により、いくつでもつけられます。
　現在のところ、次の属性が使用できます。

　shallow    .... エリア・バトル・パッケージを指定する際、エリアビュー等を
　                開かず、テーブル上で選択状態にするだけにします。
　eventview  .... エリア・バトル、及びメニューカード・エネミーカードを指定
　                する際、シーンビューではなくイベントビューを開きます。
　opendialog .... 各種カードや、フラグ・ステップを指定する際、編集ダイアロ
　                グを開く事を許可します。

　空のパスは、シナリオ本体を示します。例えば";opendialog"というパスを指定
すると、シナリオの概略設定ダイアログが開きます。

---------------------------------------------------------------------------
[ 13. 外部リソースの読込み ]

　cwxeditor.exe と同じフォルダに resource というフォルダを作成し、そこに
特定の名前でアイコン等のリソースを格納しておくと、該当するリソースが必要に
なった際、resourceフォルダ内から優先して読み込むようになります。
　具体的には、以下のようなファイルを用意しておくと、

 - resource/cast.png

　CWXEditorを起動した際、キャストカードのアイコンが上記の画像に差し替えら
れます。これにより、全てのアイコンを好みのものに変更する事ができます。
　ファイル名については、CWXEditorのソースコードのアーカイブに含まれている
resourceフォルダ内を参考にしてください。

---------------------------------------------------------------------------
[ 14. 多言語化について ]

　cwxeditor.exeのあるフォルダにlangというフォルダを作成し、そこに言語ファ
イルを入れておく事により、各種メッセージの多言語化を行えます。
　言語の切替は設定ダイアログから行う事ができます。

# 言語ファイルの作成方法
　以下のようなオプションを付けて起動すると、CWXEditorはファイルen-US.xml
に全メッセージの設定情報を書きだして終了します。
---
cwxeditor -putlangfile en-US.xml
---
　こうして出力されたファイルを改造する事により、CWXEditorの言語ファイルを
作成する事ができます。
　言語ファイルの内容はバージョンアップの際に変更される可能性があるため、
ご注意ください。

# 言語ファイル編集時の注意
・message要素のlocale属性に適切なロケールIDを設定してください。
　例えばアメリカ英語の場合は"en-US"です。
　デフォルトでは"ja-JP"(日本語-日本)になっています。
・sex、period、nature、makingsの各子要素のkey属性の値は、CardWirthのシス
　テムが使用する値です。変更しないようにしてください。
