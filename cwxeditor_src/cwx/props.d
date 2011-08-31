
module cwx.props;

import cwx.flag;
import cwx.types;
import cwx.features;
import cwx.utils;
import cwx.area;
import cwx.card;
import cwx.summary;
import cwx.event;
import cwx.race;
import cwx.system;
import cwx.motion;
import cwx.background;
import cwx.cab;
import cwx.structs;

import std.conv;
import std.path;
import std.math;
import std.string;

version (Windows) {
	static immutable DIR = "フォルダ";
} else {
	static immutable DIR = "ディレクトリ";
}

class Msgs {
public:
	const string application() {return "CWXEditor";}
	const string dlgTitVersion() {return "バージョン情報";}
	const string appDesc() {return "Scenario editor for CardWirthPy.";}
	const string appVersion() {return splitLines(import("@version.txt"))[0];}
	const string appWebSiteURI() {return splitLines(import("@version.txt"))[1];}
	const string appBuild() {
		string buf = "Build: " ~ __TIMESTAMP__ ~ " ";
		debug {
			buf ~= "Debug";
		} else {
			buf ~= "Release";
		}
		return buf;
	}
	const string dlgTitUsage() {return "使い方 - CWXEditor";}
	const string usage() {
		return "使い方: cwxeditor [-help | -conf <PATH> | <OpenID ...>] <SCENARIO> [<CWXPath ...>]\n"
			~ "オプション:\n"
			~ "  -help         起動オプションの説明を表示して終了します。\n"
			~ "  -conf <PATH>  指定されたパスの基本設定ファイルを使用します。\n"
			~ "  <SCENARIO>    起動と同時に指定されたシナリオを開きます。\n"
			~ "                (*.wsn/Summary.xml/Summary.wsm/[フォルダ])\n"
			~ "OpenID:\n"
			~ "  -a <ID>       シナリオを開いた後、<ID>で指定したIDのエリアを開きます。\n"
			~ "  -b <ID>       シナリオを開いた後、<ID>で指定したIDのバトルを開きます。\n"
			~ "  -p <ID>       シナリオを開いた後、<ID>で指定したIDのパッケージを開きます。\n"
			~ "CWXPath:\n"
			~ "  <CWXPath>     シナリオを開いた後、<CWXPath>で指定したリソースを開きます。";
	}

	const string dlgTitError() {return "エラー - CWXEditor";}
	const string dlgTitWarning() {return "警告 - CWXEditor";}
	const string dlgTitQuestion() {return "確認 - CWXEditor";}
	const string unknownError() {
		version (Windows) {
			static const CWX_EDITOR = "cwxeditor.exe";
		} else {
			static const CWX_EDITOR = "cwxeditor";
		}
		return "処理の途中で" ~ application ~ "の制作者が意図していないエラーが発生しました。"
			~ "データが壊れている可能性を考慮して、シナリオを保存せずに終了する事をお勧めします。\n"
			~ "エラー内容は" ~ CWX_EDITOR ~ "と同じ" ~ DIR ~ "にあるcwxeditor_error.logに記録されます。";
	}

	const string dlgTextOK() {return "&OK";}
	const string dlgTextApply() {return "適用";}
	const string dlgTextCancel() {return "キャンセル";}

	const string filterAll() {
		return "すべてのファイル (*.*)";
	}

	const string fileCopyError(string path) {return path ~ "のコピー中にエラーが発生しました。";}
	const string reloadError(string path) {return path ~ "の再読込中にエラーが発生しました。";}
	const string loadProgress(string fname, uint max, uint worked) {
		return to!(string)(rndtol(cast(real) worked / max * 100.0)) ~ "% 完了 - " ~ getBaseName(fname) ~ "を展開中";
	}
	const string loading(string fname) {return fname ~ "の読込みを開始";}
	const string loaded(string sName) {return sName ~ "の読込みを完了";}
	const string loaded(size_t count) {return format("%d件の読込みを完了", count);}
	const string cwxPathOpenError(string path) {return "パス [" ~ path ~ "] を開けません。";}
	const string filePathOpenError(string path) {return "パス [" ~ path ~ "] を開けません。";}

	const string loadSkinError(string name) {return "デフォルトのスキン「" ~ name ~ "」が見つかりません。\n一部リソース画像が非表示になります。";}
	const string useDefaultSkin(string name, string defSkin) {return "スキン「" ~ name ~ "」が見つかりません。\nデフォルトのスキン「" ~ defSkin ~ "」を使用します。";}
	const string scenarioName() {return "シナリオ名";}
	const string type() {return "タイプ";}
	const string classic() {return "[クラシック]";}
	const string newClassicDir() {
		return "シナリオ作成先の選択";
	}
	const string newClassicDirDesc() {
		return "シナリオを作成する" ~ DIR ~ "を選択してください。";
	}
	const string notEmptyDir(string dir) {
		return dir ~ "は空ではありません。\n本当にここでシナリオを作成しますか？";
	}

	const string newScenarioName() {return "新規シナリオ";}

	const string dlgTitSaveBitmapImage() {
		return "格納イメージの保存";
	}
	const string filterBitmapImage() {
		return "ビットマップイメージ (*.bmp)";
	}

	const string dlgMsgDelete(string[] files) {
		return files.length == 1
			? getBaseName(files[0]) ~ "を完全に削除しますか？"
			: to!(string)(files.length) ~ "個の項目を完全に削除しますか？";
	}
	version (Windows) {
		const string dlgMsgDeleteRecycle(string[] files) {
			return files.length == 1
				? getBaseName(files[0]) ~ "をごみ箱に移動しますか？"
				: to!(string)(files.length) ~ "個の項目をごみ箱に移動しますか？";
		}
	}

	const string ttClosePane() {return "閉じる";}
	const string menuClosePane() {return ttClosePane ~ "(&C)";}
	const string ttClosePaneEtc() {return "他のタブを閉じる";}
	const string menuClosePaneEtc() {return ttClosePaneEtc ~ "(&W)";}
	const string ttClosePaneLeft() {return "左側のタブを閉じる";}
	const string menuClosePaneLeft() {return ttClosePaneLeft ~ "(&L)";}
	const string ttClosePaneRight() {return "右側のタブを閉じる";}
	const string menuClosePaneRight() {return ttClosePaneRight ~ "(&R)";}
	const string ttClosePaneAll() {return "全てのタブを閉じる";}
	const string menuClosePaneAll() {return ttClosePaneAll ~ "(&A)";}

	const string image() {return "イメージ";}
	const string pathDef() {return "[デフォルト]";}
	const string imageNone() {return "[イメージ無し]";}
	const string fileNone() {return "[ファイルを選択]";}
	const string imageIncluding() {return "[イメージ格納]";}
	const string seNone() {return "[サウンド無し]";}
	const string bgmStop() {return "[BGM停止]";}
	const string bgmNone() {return "[BGM無し]";}
	const string dlgMsgIsSaveBeforeReload(string name) {return "「" ~ name ~ "」は変更されています。再読込しますか？";}
	const string reloadBeforeSaveError(string name) {return "「" ~ name ~ "」は保存されていないため、再読込できません。";}
	const string dlgMsgIsSaveBeforeExit(string name) {return "「" ~ name ~ "」は変更されています。保存しますか？";}
	const string dlgMsgDropFiles(string[] paths) {
		return (paths.length == 1 ? paths[0] : (to!(string)(paths.length) ~ "個のファイル"))
			~ "をシナリオ" ~ DIR ~ "にコピーしますか？";
	}
	const string dlgMsgDropOverWriteFiles(string[] paths) {
		return (paths.length == 1
			? paths[0] ~ "は"
			: (to!(string)(paths.length) ~ "個の項目が"))
			~ "すでに存在します。上書きしますか？";
	}
	const string dlgTitDropFiles() {return "素材ファイルの追加";}
	const string dlgMsgCopyError() {return "いくつかのファイルのコピーに失敗しました。";}

	const string dlgMsgCopyMaterial(string[] fromPath, uint binImgCount) {
		if (!fromPath.length && binImgCount) {
			return "格納画像もコピーしますか？";
		} else if (fromPath.length && !binImgCount) {
			if (fromPath.length == 1u) {
				return "素材もコピーしますか？\n" ~ fromPath[0];
			} else {
				return "素材もコピーしますか？\n" ~ to!(string)(fromPath.length) ~ "個のファイル";
			}
		} else {
			return "素材もコピーしますか？\n"
				~ to!(string)(fromPath.length) ~ "個のファイルと" ~ to!(string)(binImgCount) ~ "個の格納画像";
		}
	}

	const string dlgTitSettings() {return "CWXEditorの設定";}

	/// メニュー。
	const string menuFile() {return "ファイル(&F)";}
	const string ttNew() {return "新規作成";}
	const string menuNew() {return ttNew ~ "(&N)..." ~ "\tCtrl+N";}
	const string ttOpen() {return "開く";}
	const string menuOpen() {return ttOpen ~ "(&O)..." ~ "\tCtrl+O";}
	const string ttClose() {return "閉じる";}
	const string menuClose() {return ttClose ~ "(&C)";}
	const string menuCloseWin() {return "閉じる(&C)";}
	const string ttSave() {return "上書き保存";}
	const string menuSave() {return ttSave ~ "(&S)" ~ "\tCtrl+S";}
	const string ttSaveA() {return "名前を付けて保存";}
	const string menuSaveA() {return ttSaveA ~ "(&A)...";}
	const string ttReload() {return "再読込";}
	const string menuReload() {return ttReload ~ "(&R)";}
	const string ttOpenDirectory() {
		return DIR ~ "を開く";
	}
	const string menuOpenDirectory() {return ttOpenDirectory ~ "(&O)";}
	const string ttOpenFilePlace() {
		return "ファイルの場所を開く";
	}
	const string menuOpenFilePlace() {return ttOpenFilePlace ~ "(&O)";}
	const string ttSaveIncludeImage() {
		return "格納イメージをファイルに保存";
	}
	const string ttImageList() {return "画像を一覧表示";}
	const string menuImageList() {return ttImageList ~ "(&L)";}

	const string ttChangeVH() {return "分割領域の縦横を切替";}
	const string menuChangeVH() {return ttChangeVH ~ "(&V)" ~ "";}

	const string menuEdit() {return "編集(&E)";}
	const string ttReplaceText() {return "検索と置換";}
	const string menuReplaceText() {return ttReplaceText ~ "(&F)...\tCtrl+F";}
	const string ttCEdit() {return "編集";}
	const string menuCEdit() {return ttCEdit ~ "(&E)" ~ "\tEnter";}
	const string ttRefresh() {return "最新の情報に更新";}
	const string ttRefreshS() {return "更新";}
	const string menuRefresh() {return ttRefresh ~ "(&R)" ~ "\tF5";}
	const string ttUndo() {return "元に戻す";}
	const string menuUndo() {return ttUndo ~ "(&U)" ~ "\tCtrl+Z";}
	const string ttRedo() {return "やり直し";}
	const string menuRedo() {return ttRedo ~ "(&R)" ~ "\tCtrl+Y";}
	const string ttCut() {return "切り取り";}
	const string menuCut() {return ttCut ~ "(&T)" ~ "\tCtrl+X";}
	const string ttCopy() {return "コピー";}
	const string menuCopy() {return ttCopy ~ "(&C)" ~ "\tCtrl+C";}
	const string ttPaste() {return "貼り付け";}
	const string menuPaste() {return ttPaste ~ "(&P)" ~ "\tCtrl+V";}
	const string ttDel() {return "削除";}
	const string menuDel() {return ttDel ~ "(&D)" ~ "\tDelete";}

	const string ttToXML() {return "コピーしたデータをXMLに変換";}
	const string menuToXML() {return ttToXML ~ "(&X)" ~ "";}

	const string menuView() {return "表示(&V)";}
	const string ttDataWin() {return "テーブルビュー";}
	const string menuDataWin() {return ttDataWin ~ "(&D)";}
	const string ttFlagWin() {return "状態変数ビュー";}
	const string menuFlagWin() {return ttFlagWin ~ "(&V)";}
	const string ttCardWin() {return "カードビュー";}
	const string menuCardWin() {return ttCardWin ~ "(&W)";}
	const string ttDirWin() {return "ファイルビュー";}
	const string menuDirWin() {return ttDirWin ~ "(&F)";}

	const string menuTools() {return "ツール(&T)";}
	const string ttExecEngine() {return "エンジン起動";}
	const string menuExecEngine() {return ttExecEngine ~ "(&G)";}
	const string menuExecEngineAuto() {return "自動選択(&G)\tF9";}
	const string ttSettings() {return "エディタ設定";}
	const string menuSettings() {return ttSettings ~ "(&O)...";}

	const string menuTable() {return "テーブル(&B)";}
	const string menuVariable() {return "状態変数(&R)";}

	const string menuHelp() {return "ヘルプ(&H)";}
	const string ttVersion() {return "バージョン情報";}
	const string menuVersion() {return ttVersion ~ "(&A)";}

	const string ttLockBar() {return "ツールバーを固定";}
	const string menuLockBar() {return ttLockBar ~ "(&L)";}
	const string ttResetBar() {return "配置をリセット";}
	const string menuResetBar() {return ttResetBar ~ "(&R)";}

	const string summary() {return "シナリオの設定";}
	const string area() {return "エリア";}
	const string battle() {return "バトル";}
	const string packages() {return "パッケージ";}

	const string dlgTitReplaceText() {return "検索と置換";}
	const string replForText() {return "テキスト検索";}
	const string replForID() {return "ID検索";}
	const string replForPath() {return "素材検索";}
	const string replForUnuse() {return "未使用検索";}
	const string replForError() {return "誤り検索";}

	const string allCheck() {return "全てチェック/全てチェックを外す(&L)";}

	const string replError() {return "重複する分岐(フラグ分岐が両方ともTRUEになっている等)・条件クーポンに抜けがある台詞コンテント・存在しない素材を参照しているコンテント等を検索します。";}

	const string replFrom() {return "検索(置換前)";}
	const string replTo() {return "置換後";}

	const string replText() {return "検索/置換するテキスト";}
	const string replTextTarget() {return "検索/置換対象";}
	const string replTextSummary() {return "貼り紙(&1)";}
	const string replTextMessage() {return "メッセージ(&2)";}
	const string replTextCardName() {return "カード名(&3)";}
	const string replTextCardDesc() {return "カード解説(&4)";}
	const string replTextEventText() {return "イベントテキスト(&5)";}
	const string replTextStart() {return "スタートコンテント(&6)";}
	const string replTextFlagAndStep() {return "フラグ/ステップ(&7)";}
	const string replTextCoupon() {return "クーポン(&8)";}
	const string replTextGossip() {return "ゴシップ(&9)";}
	const string replTextEndScenario() {return "終了印(&A)";}
	const string replTextAreaName() {return "エリア/バトル/パッケージ名(&B)";}
	const string replTextKeyCode() {return "キーコード(&D)";}
	const string replTextComment() {return "コメント(&E)";}

	const string replID() {return "検索/置換対象";}
	const string replIDKind() {return "対象";}
	const string replIDArea() {return "エリア";}
	const string replIDBattle() {return "バトル";}
	const string replIDPackage() {return "パッケージ";}
	const string replIDCast() {return "キャストカード";}
	const string replIDSkill() {return "スキルカード";}
	const string replIDItem() {return "アイテムカード";}
	const string replIDBeast() {return "召喚獣カード";}
	const string replIDInfo() {return "情報カード";}
	const string replSetID() {return "[IDを直接指定]";}

	const string replPath() {return "検索/置換する素材";}

	const string replUnuseTarget() {return "検索対象";}
	const string replUnuseFlag() {return "フラグ(&1)";}
	const string replUnuseStep() {return "ステップ(&2)";}
	const string replUnuseArea() {return "エリア(&3)";}
	const string replUnuseBattle() {return "バトル(&4)";}
	const string replUnusePackage() {return "パッケージ(&5)";}
	const string replUnuseCast() {return "キャストカード(&6)";}
	const string replUnuseSkill() {return "スキルカード(&7)";}
	const string replUnuseItem() {return "アイテムカード(&8)";}
	const string replUnuseBeast() {return "召喚獣カード(&9)";}
	const string replUnuseInfo() {return "情報カード(&A)";}
	const string replUnuseStart() {return "スタートコンテント(&B)";}
	const string replUnusePath() {return "素材(&C)";}

	const string replNotIgnoreCase() {return "大文字と小文字を区別する(&C)";}
	const string replRegExp() {return "正規表現(&E) (. = 任意1文字, * = 直前の文字の任意数繰返し, $1 = 1つめの文字列グループ ...)";}
	const string regexError() {return "正規表現が正しくありません。";}
	const string replWildcard() {return "ワイルドカード(&W) (* = 任意文字列, ? = 任意1文字, \\* = *, \\? = ?, \\\\ = \\)";}
	const string replCond() {return "検索条件";}
	const string search() {return "検索(&F)";}
	const string replace() {return "全て置換(&R)";}
	const string replaceExit() {return "閉じる";}
	const string searchResult(size_t count, string kind) {
		string r = to!(string)(count) ~ "件の検索結果";
		return kind.length ? r ~ "(" ~ kind ~ ")" : r;
	}
	const string replResult(size_t count, string kind) {
		string r = to!(string)(count) ~ "箇所の置換";
		return kind.length ? r ~ "(" ~ kind ~ ")" : r;
	}
	const string searchResultBgImage(in BgImage back) {
		return "背景画像 - " ~ encodePath(back.path);
	}
	const string searchResultIds(C)(in C c) {
		string name;
		static if (is(C : Area)) {
			name = "エリア";
		} else static if (is(C : Battle)) {
			name = "バトル";
		} else static if (is(C : Package)) {
			name = "パッケージ";
		} else static if (is(C : CastCard)) {
			name = "キャスト";
		} else static if (is(C : SkillCard)) {
			name = "スキル";
		} else static if (is(C : ItemCard)) {
			name = "アイテム";
		} else static if (is(C : BeastCard)) {
			name = "召喚獣";
		} else static if (is(C : InfoCard)) {
			name = "情報";
		} else static assert (0);
		return name ~ "(" ~ to!(string)(c.id) ~ ") - " ~ c.name;
	}
	const string searchResultFlags(F)(in F f) {
		static if (is(F : Flag)) {
			return "フラグ - " ~ f.path;
		} else static if (is(F : Step)) {
			return "ステップ - " ~ f.path;
		} else static if (is(F : FlagDir)) {
			return "ディレクトリ - " ~ f.path;
		} else static assert (0);
	}
	const string searchResultEventTree(in EventTree evt) {
		return "イベントツリー - " ~ evt.name;
	}
	const string searchResultMenuCard(in MenuCard c) {
		return "メニューカード - " ~ c.name;
	}
	const string searchResultEnemyCard(in EnemyCard c, in Summary summ) {
		auto card = summ.casts(c.id);
		return "エネミーカード - " ~ (card ? card.name : "[対象無し]");
	}

	const string searchErrorNoImage() {return "イメージ指定無し";}
	const string searchErrorImageNotFound() {return "イメージファイルが見つからない";}
	const string searchErrorBGMNotFound() {return "BGMファイルが見つからない";}
	const string searchErrorSENotFound() {return "効果音ファイルが見つからない";}
	const string searchErrorStartAreaNotFound() {return "開始エリア無し";}
	const string searchErrorFlagNotFound() {return "フラグが見つからない";}
	const string searchErrorStepNotFound() {return "ステップが見つからない";}
	const string searchErrorNoCast() {return "キャストカード指定無し";}
	const string searchErrorNoBeast() {return "召喚獣カード指定無し";}
	const string searchErrorDupNextContent() {return "分岐条件の重複";}
	const string searchErrorSPFontNotFound() {return "特殊フォントイメージが見つからない";}
	const string searchErrorNoRCouponsDialog() {return "最終項目以外にクーポン指定無し項目あり";}
	const string searchErrorAreaNotFound() {return "エリアが見つからない";}
	const string searchErrorBattleNotFound() {return "バトルが見つからない";}
	const string searchErrorPackageNotFound() {return "パッケージが見つからない";}
	const string searchErrorCastNotFound() {return "キャストカードが見つからない";}
	const string searchErrorSkillNotFound() {return "スキルカードが見つからない";}
	const string searchErrorItemNotFound() {return "アイテムカードが見つからない";}
	const string searchErrorBeastNotFound() {return "召喚獣カードが見つからない";}
	const string searchErrorInfoNotFound() {return "情報カードが見つからない";}
	const string searchErrorStartNotFound() {return "スタートコンテントが見つからない";}

	/// イベント設定。
	const string ttStartToPackage() {return "このツリーをパッケージ化する";}
	const string menuStartToPackage() {return ttStartToPackage ~ "(&P)";}
	const string ttConvertContent() {return "変換";}
	const string menuConvertContent() {return ttConvertContent ~ "(&R)";}

	const string dlgTitContent(CType type) {
		final switch (type) {
		case CType.START: assert (0);
		case CType.START_BATTLE: return "バトルの選択";
		case CType.END: return "クリアイベントの設定";
		case CType.END_BAD_END: assert (0);
		case CType.CHANGE_AREA: return "エリアの選択";
		case CType.CHANGE_BG_IMAGE: return "背景変更イベントの設定";
		case CType.EFFECT: return "効果イベントの設定";
		case CType.EFFECT_BREAK: assert (0);
		case CType.LINK_START: return "リンクイベントの設定";
		case CType.LINK_PACKAGE: return "パッケージの選択";
		case CType.TALK_MESSAGE: return "メッセージイベントの設定";
		case CType.TALK_DIALOG: return "台詞イベントの設定";
		case CType.PLAY_BGM: return "効果音再生イベントの設定";
		case CType.PLAY_SOUND: return "BGM再生イベントの設定";
		case CType.WAIT: return "空白時間イベントの設定";
		case CType.ELAPSE_TIME: assert (0);
		case CType.CALL_START: return "リンクイベントの設定";
		case CType.CALL_PACKAGE: return "パッケージの選択";
		case CType.BRANCH_FLAG: return "フラグ分岐イベントの設定";
		case CType.BRANCH_MULTI_STEP: return "ステップ多岐分岐イベントの設定";
		case CType.BRANCH_STEP: return "ステップ上下分岐イベントの設定";
		case CType.BRANCH_SELECT: return "メンバ選択分岐イベントの設定";
		case CType.BRANCH_ABILITY: return "能力判定分岐イベントの設定";
		case CType.BRANCH_RANDOM: return "ランダム分岐イベントの設定";
		case CType.BRANCH_LEVEL: return "レベル分岐イベントの設定";
		case CType.BRANCH_STATUS: return "状態分岐イベントの設定";
		case CType.BRANCH_PARTY_NUMBER: return "パーティ人数分岐イベントの設定";
		case CType.BRANCH_AREA: assert (0);
		case CType.BRANCH_BATTLE: assert (0);
		case CType.BRANCH_IS_BATTLE: assert (0);
		case CType.BRANCH_CAST: return "キャストカードの選択";
		case CType.BRANCH_ITEM: return "アイテム所持分岐イベントの設定";
		case CType.BRANCH_SKILL: return "スキル所持分岐イベントの設定";
		case CType.BRANCH_INFO: return "情報カードの選択";
		case CType.BRANCH_BEAST: return "召喚獣存在分岐イベントの設定";
		case CType.BRANCH_MONEY: return "所持金イベントの設定";
		case CType.BRANCH_COUPON: return "クーポンイベントの設定";
		case CType.BRANCH_COMPLETE_STAMP: return "終了済みシナリオイベントの設定";
		case CType.BRANCH_GOSSIP: return "ゴシップイベントの設定";
		case CType.SET_FLAG: return "フラグ変更イベントの設定";
		case CType.SET_STEP: return "ステップ変更イベントの設定";
		case CType.SET_STEP_UP: return "ステップ増加イベントの設定";
		case CType.SET_STEP_DOWN: return "ステップ減少イベントの設定";
		case CType.REVERSE_FLAG: return "フラグ反転イベントの設定";
		case CType.CHECK_FLAG: return "フラグ判定イベントの設定";
		case CType.GET_CAST: return "キャストカードの選択";
		case CType.GET_ITEM: return "アイテム入手イベントの設定";
		case CType.GET_SKILL: return "スキル取得イベントの設定";
		case CType.GET_INFO: return "情報カードの選択";
		case CType.GET_BEAST: return "召喚獣獲得イベントの設定";
		case CType.GET_MONEY: return "所持金イベントの設定";
		case CType.GET_COUPON: return "クーポンイベントの設定";
		case CType.GET_COMPLETE_STAMP: return "終了済みシナリオイベントの設定";
		case CType.GET_GOSSIP: return "ゴシップイベントの設定";
		case CType.LOSE_CAST: return "キャストカードの選択";
		case CType.LOSE_ITEM: return "アイテム喪失イベントの設定";
		case CType.LOSE_SKILL: return "スキル喪失イベントの設定";
		case CType.LOSE_INFO: return "情報カードの選択";
		case CType.LOSE_BEAST: return "召喚獣消去イベントの設定";
		case CType.LOSE_MONEY: return "所持金イベントの設定";
		case CType.LOSE_COUPON: return "クーポンイベントの設定";
		case CType.LOSE_COMPLETE_STAMP: return "終了済みシナリオイベントの設定";
		case CType.LOSE_GOSSIP: return "ゴシップイベントの設定";
		case CType.SHOW_PARTY: assert (0);
		case CType.HIDE_PARTY: assert (0);
		case CType.REDISPLAY: return "画面再構築イベントの設定";
		}
	}

	const string afterClear() {return "シナリオ終了後";}
	const string afterClearEndMark() {return "シナリオに済印を付ける";}
	const string afterClearNoEndMark() {return "何もしない";}

	const string couponName() {return "クーポン名";}
	const string couponValue() {return "得点";}
	const string couponValueRange(uint r) {return "(" ~ to!(string)(-(cast(int) r)) ~ "～" ~ to!(string)(r) ~ ")";}
	const string range() {return "適用範囲";}
	const string gossipName() {return "ゴシップ名";}
	const string endName() {return "シナリオ名";}

	const string imageMessage() {return "イメージ付きメッセージ";}
	const string noImageMessage() {return "イメージ無しメッセージ";}
	const string spCharsTitle() {return "特殊文字";}
	const string defaultColor() {return "デフォルト(&W)";}
	const string red() {return "赤(&R)";}
	const string blue() {return "青(&B)";}
	const string green() {return "緑(&G)";}
	const string yellow() {return "黄(&Y)";}
	const string scTalker(Talker talker) {
		final switch (talker) {
		case Talker.SELECTED:
			return "選択メンバ名(#M)";
		case Talker.UNSELECTED:
			return "選択外ランダムメンバ名(#U)";
		case Talker.RANDOM:
			return "ランダムメンバ名(#R)";
		case Talker.CARD:
			return "選択カード名(#C)";
		case Talker.NARRATION:
			return "話者無し";
		case Talker.IMAGE:
			return "画像";
		}
	}
	const string scRef() {return "参照文字列(#I)";}
	const string scTeam() {return "チーム名(#T)";}
	const string scYado() {return "宿屋名(#Y)";}
	const string createDialog() {return "台詞の作成";}
	const string deleteDialog() {return "台詞の削除";}
	const string copyToDialogs() {return "台詞を全体にコピー";}
	const string copyToUpper() {return "台詞を上方にコピー";}
	const string copyToLower() {return "台詞を下方にコピー";}
	const string setTalkerCoupon() {return "追加";}

	const string transition() {return "背景切替方式";}
	const string transition(Transition t) {
		final switch (t) {
		case Transition.DEFAULT:
			return "[プレイヤーの設定を使用]";
		case Transition.NONE:
			return "アニメーション無し";
		case Transition.FADE:
			return "フェード式";
		case Transition.PIXEL_DISSOLVE:
			return "ピクセルディゾルブ式";
		case Transition.BLINDS:
			return "ブラインド式";
		}
	}
	const string transitionSpeed() {return "背景切替ウェイト";}
	const string waitName() {return "空白時間(0.1秒単位)";}
	const string moneyName() {return "金額";}
	const string randomName() {return "確率(%)";}
	const string partyNumName() {return "パーティの人数";}
	const string judgeTarget() {return "判定対象";}
	const string flag() {return "フラグ";}
	const string step() {return "ステップ";}
	const string flagValue() {return "値";}
	const string stepValue() {return "段階";}
	const string selectMember() {return "選択対象";}
	const string activeMember() {return "動けるメンバから選択";}
	const string allMember() {return "パーティ全員から選択";}
	const string selectMethod() {return "選択方法";}
	const string manualMethod() {return "手動で選択";}
	const string randomMethod() {return "ランダムで選択";}
	const string judgeSleep() {return "眠り判定";}
	const string sleepDisabled() {return "睡眠者無効";}
	const string sleepEnabled() {return "睡眠者有効";}
	const string selectedLevel() {return "現在選択中のメンバ";}
	const string allMemberLevel() {return "パーティ全員の平均値";}
	const string judgeLevel() {return "判定レベル";}
	const string judgeState() {return "判定状態";}
	const string stateHint() {return "ヒント";}
	const string cardNumber() {return "枚数";}
	const string cardAllDelete() {return "全て削除する";}
	const string cardEventRange() {return "適用範囲";}
	const string transitionType() {return "背景切替方式";}

	/// イベント。
	const string evtArrow() {return "イベント編集";}

	const string evtAddContinue() {return "連続で配置";}
	const string evtAutoOpen() {return "配置と同時に編集";}

	const string ttEvtTerminal() {return "開始/終端";}
	const string menuEvtTerminal() {return ttEvtTerminal ~ "(&T)";}
	const string ttEvtStandard() {return "基本";}
	const string menuEvtStandard() {return ttEvtStandard ~ "(&S)";}
	const string ttEvtData() {return "変数操作/分岐";}
	const string menuEvtData() {return ttEvtData ~ "(&D)";}
	const string ttEvtUtility() {return "状況分岐";}
	const string menuEvtUtility() {return ttEvtUtility ~ "(&U)";}
	const string ttEvtBranch() {return "保有分岐";}
	const string menuEvtBranch() {return ttEvtBranch ~ "(&B)";}
	const string ttEvtGet() {return "取得";}
	const string menuEvtGet() {return ttEvtGet ~ "(&G)";}
	const string ttEvtLost() {return "喪失";}
	const string menuEvtLost() {return ttEvtLost ~ "(&L)";}
	const string ttEvtVisual() {return "外観操作";}
	const string menuEvtVisual() {return ttEvtVisual ~ "(&V)";}

	const string content(CType type) {
		switch (type) {
		case CType.START: return "スタート";
		case CType.START_BATTLE: return "バトル開始";
		case CType.END: return "シナリオクリア";
		case CType.END_BAD_END: return "ゲームオーバー";
		case CType.CHANGE_AREA: return "エリア移動";
		case CType.CHANGE_BG_IMAGE: return "背景変更";
		case CType.EFFECT: return "効果";
		case CType.EFFECT_BREAK: return "効果中断";
		case CType.LINK_START: return "スタートへのリンク";
		case CType.LINK_PACKAGE: return "パッケージへのリンク";
		case CType.TALK_MESSAGE: return "メッセージ";
		case CType.TALK_DIALOG: return "セリフ";
		case CType.PLAY_BGM: return "BGM変更";
		case CType.PLAY_SOUND: return "効果音";
		case CType.WAIT: return "空白時間挿入";
		case CType.ELAPSE_TIME: return "時間経過";
		case CType.CALL_START: return "スタートの呼び出し";
		case CType.CALL_PACKAGE: return "パッケージの呼び出し";
		case CType.BRANCH_FLAG: return "フラグ分岐";
		case CType.BRANCH_MULTI_STEP: return "ステップ多岐分岐";
		case CType.BRANCH_STEP: return "ステップ上下分岐";
		case CType.BRANCH_SELECT: return "メンバ選択分岐";
		case CType.BRANCH_ABILITY: return "能力判定分岐";
		case CType.BRANCH_RANDOM: return "ランダム分岐";
		case CType.BRANCH_LEVEL: return "レベル判定分岐";
		case CType.BRANCH_STATUS: return "状態判定分岐";
		case CType.BRANCH_PARTY_NUMBER: return "人数判定分岐";
		case CType.BRANCH_AREA: return "エリア分岐";
		case CType.BRANCH_BATTLE: return "バトル分岐";
		case CType.BRANCH_IS_BATTLE: return "バトル判定分岐";
		case CType.BRANCH_CAST: return "キャスト存在分岐";
		case CType.BRANCH_ITEM: return "アイテム所持分岐";
		case CType.BRANCH_SKILL: return "スキル所持分岐";
		case CType.BRANCH_INFO: return "情報所持分岐";
		case CType.BRANCH_BEAST: return "召喚獣存在分岐";
		case CType.BRANCH_MONEY: return "所持金分岐";
		case CType.BRANCH_COUPON: return "クーポン分岐";
		case CType.BRANCH_COMPLETE_STAMP: return "終了シナリオ分岐";
		case CType.BRANCH_GOSSIP: return "ゴシップ分岐";
		case CType.SET_FLAG: return "フラグ変更";
		case CType.SET_STEP: return "ステップ変更";
		case CType.SET_STEP_UP: return "ステップ増加";
		case CType.SET_STEP_DOWN: return "ステップ減少";
		case CType.REVERSE_FLAG: return "フラグ反転";
		case CType.CHECK_FLAG: return "フラグ判定";
		case CType.GET_CAST: return "キャスト加入";
		case CType.GET_ITEM: return "アイテム入手";
		case CType.GET_SKILL: return "スキル取得";
		case CType.GET_INFO: return "情報入手";
		case CType.GET_BEAST: return "召喚獣獲得";
		case CType.GET_MONEY: return "所持金増加";
		case CType.GET_COUPON: return "クーポン取得";
		case CType.GET_COMPLETE_STAMP: return "終了シナリオ設定";
		case CType.GET_GOSSIP: return "ゴシップ追加";
		case CType.LOSE_CAST: return "キャスト離脱";
		case CType.LOSE_ITEM: return "アイテム喪失";
		case CType.LOSE_SKILL: return "スキル喪失";
		case CType.LOSE_INFO: return "情報喪失";
		case CType.LOSE_BEAST: return "召喚獣消去";
		case CType.LOSE_MONEY: return "所持金減少";
		case CType.LOSE_COUPON: return "クーポン削除";
		case CType.LOSE_COMPLETE_STAMP: return "終了シナリオ削除";
		case CType.LOSE_GOSSIP: return "ゴシップ削除";
		case CType.SHOW_PARTY: return "パーティ表示";
		case CType.HIDE_PARTY: return "パーティ隠蔽";
		case CType.REDISPLAY: return "画面再構築";
		default: assert (0);
		}
	}

	const string msnGroupVitality() {return "生命力";}
	const string msnGroupPhysical() {return "肉体";}
	const string msnGroupSkill() {return "技能";}
	const string msnGroupMental() {return "精神";}
	const string msnGroupMagic() {return "魔法";}
	const string msnGroupEnhance() {return "能力";}
	const string msnGroupVanish() {return "消滅";}
	const string msnGroupCard() {return "カード";}
	const string msnGroupBeast() {return "召喚";}

	const string msnDelete() {return "効果削除";}

	const string msnDesc(string group, string name) {return group ~ " - " ~ name;}

	const string motion(MType type) {
		switch (type) {
		case MType.HEAL: return "回復";
		case MType.DAMAGE: return "ダメージ";
		case MType.ABSORB: return "吸収";
		case MType.PARALYZE: return "麻痺";
		case MType.DIS_PARALYZE: return "麻痺解除";
		case MType.POISON: return "中毒";
		case MType.DIS_POISON: return "中毒解除";
		case MType.GET_SKILL_POWER: return "精神力回復";
		case MType.LOSE_SKILL_POWER: return "精神力喪失";
		case MType.SLEEP: return "睡眠状態";
		case MType.CONFUSE: return "混乱状態";
		case MType.OVERHEAT: return "激昂状態";
		case MType.BRAVE: return "勇敢状態";
		case MType.PANIC: return "恐慌状態";
		case MType.NORMAL: return "正常状態";
		case MType.BIND: return "呪縛";
		case MType.DIS_BIND: return "呪縛解除";
		case MType.SILENCE: return "沈黙";
		case MType.DIS_SILENCE: return "沈黙解除";
		case MType.FACE_UP: return "暴露";
		case MType.FACE_DOWN: return "暴露解除";
		case MType.ANTI_MAGIC: return "魔法無効化";
		case MType.DIS_ANTI_MAGIC: return "魔法無効化解除";
		case MType.ENHANCE_ACTION: return "行動力変化";
		case MType.ENHANCE_AVOID: return "回避力変化";
		case MType.ENHANCE_DEFENSE: return "防御力変化";
		case MType.ENHANCE_RESIST: return "抵抗力変化";
		case MType.VANISH_TARGET: return "対象消去";
		case MType.VANISH_CARD: return "手札消去";
		case MType.VANISH_BEAST: return "召喚獣消去";
		case MType.DEAL_ATTACK_CARD: return "通常攻撃";
		case MType.DEAL_POWERFUL_ATTACK_CARD: return "渾身の一撃";
		case MType.DEAL_CRITICAL_ATTACK_CARD: return "会心の一撃";
		case MType.DEAL_FEINT_CARD: return "フェイント";
		case MType.DEAL_DEFENSE_CARD: return "防御";
		case MType.DEAL_DISTANCE_CARD: return "見切り";
		case MType.DEAL_CONFUSE_CARD: return "混乱";
		case MType.DEAL_SKILL_CARD: return "特殊技能";
		case MType.SUMMON_BEAST: return "召喚獣召喚";
		default: assert (0);
		}
	}

	const string contentText(in Content evt, in Summary summ) {
		switch (evt.type) {
		case CType.START: {
			return "スタートコンテント: " ~ evt.name;
		} case CType.START_BATTLE: {
			if (0 == evt.battle) return "バトル指定無し";
			auto b = summ.battle(evt.battle);
			return b is null ? .format("存在しないバトル(ID:%d)", evt.battle) : "バトルビュー「" ~ b.name ~ "」";
		} case CType.END: {
			return evt.complete ? "済印をつけて終了" : "済印をつけずに終了";
		} case CType.END_BAD_END: {
			return "ゲームオーバーコンテント";
		} case CType.CHANGE_AREA: {
			if (0 == evt.area) return "エリア指定無し";
			auto a = summ.area(evt.area);
			return a is null ? .format("存在しないエリア(ID:%d)", evt.area) : "エリアビュー「" ~ a.name ~ "」";
		} case CType.CHANGE_BG_IMAGE: {
			string buf = "背景ファイル = ";
			foreach (i, b; evt.backs) {
				buf ~= "[" ~ encodePath(b.path) ~ "]";
				if (i + 1 < evt.backs.length) buf ~= " ";
			}
			return buf;
		} case CType.EFFECT: {
			string buf = target(evt.targetNS.m);
			buf ~= " レベル" ~ to!(string)(evt.signedLevel);
			buf ~= " " ~ effectType(evt.effectType, evt.resist);
			buf ~= " 成功率" ~ (evt.successRate >= 0 ? "+" : "") ~ to!(string)(evt.successRate);
			buf ~= " " ~ (evt.soundPath.length ? "「" ~ evt.soundPath ~ "」を再生" : "音声無し");
			buf ~= " " ~ cardVisual(evt.cardVisual);
			buf ~= " 効果 = ";
			foreach (i, m; evt.motions) {
				buf ~= "[" ~ motion(m.type) ~ "]";
				if (i + 1 < evt.motions.length) buf ~= " ";
			}
			return buf;
		} case CType.EFFECT_BREAK: {
			return "効果中断コンテント";
		} case CType.LINK_START: {
			if (evt.start is null || !evt.start.length) return "スタートコンテント指定無し";
			return !evt.tree.hasStart(evt.start)
				? .format("存在しないスタートコンテント(名称:%s)", evt.start) : "スタートコンテント「" ~ evt.start ~ "」へのリンク";
		} case CType.LINK_PACKAGE: {
			if (0 == evt.packages) return "パッケージ指定無し";
			auto p = summ.packages(evt.packages);
			return p is null ? .format("存在しないパッケージ(ID:%d)", evt.packages) : "パッケージビュー「" ~ p.name ~ "」";
		} case CType.TALK_MESSAGE: {
			string text = evt.text;
			switch (evt.talkerC) {
			case Talker.NARRATION:
				return std.array.replace(text, "\n", "");
			case Talker.SELECTED:
				return "[選択中]: " ~ std.array.replace(text, "\n", "");
			case Talker.UNSELECTED:
				return "[選択外]: " ~ std.array.replace(text, "\n", "");
			case Talker.RANDOM:
				return "[ランダム]: " ~ std.array.replace(text, "\n", "");
			case Talker.CARD:
				return "[カード]: " ~ std.array.replace(text, "\n", "");
			case Talker.IMAGE:
				return "[" ~ encodePath(evt.cardPath) ~ "]: " ~ std.array.replace(text, "\n", "");
			default: assert (0);
			}
		} case CType.TALK_DIALOG: {
			auto rCoupons = evt.dialogs[0].rCoupons;
			if (rCoupons.length > 0) {
				string rBuf = "";
				foreach (i, rc; rCoupons) {
					rBuf ~= rc;
					rBuf ~= i + 1 < rCoupons.length ? " " : ": ";
				}
				auto text = evt.dialogs[0].text;
				return rBuf ~ std.array.replace(text, "\n", "");
			} else {
				auto text = evt.dialogs[0].text;
				return std.array.replace(text, "\n", "");
			}
		} case CType.PLAY_BGM: {
			return evt.bgmPath is null || evt.bgmPath.length == 0 ? "BGM停止" : "BGMとして「" ~ encodePath(evt.bgmPath) ~ "」を演奏";
		} case CType.PLAY_SOUND: {
			if (evt.soundPath is null || !evt.soundPath.length) return "効果音指定無し";
			return evt.soundPath is null || evt.soundPath.length == 0 ? .format("存在しない効果音(ファイル:%s)", evt.soundPath) : "効果音「" ~ encodePath(evt.soundPath) ~ "」を鳴らす";
		} case CType.WAIT: {
			return "空白時間 = " ~ to!(string)(evt.wait) ~ " × 0.1秒";
		} case CType.ELAPSE_TIME: {
			return "ターン数経過コンテント";
		} case CType.CALL_START: {
			if (evt.start is null || !evt.start.length) return "スタートコンテント指定無し";
			return !evt.tree.hasStart(evt.start) ? .format("存在しないスタートコンテント(名称:%s)", evt.start) : "スタートコンテント「" ~ evt.start ~ "」のコール";
		} case CType.CALL_PACKAGE: {
			if (0 == evt.packages) return "パッケージ指定無し";
			auto p = summ.packages(evt.packages);
			return p is null ? .format("存在しないパッケージ(ID:%d)", evt.packages) : "パッケージビュー「" ~ p.name ~ "」のコール";
		} case CType.BRANCH_FLAG: {
			if (evt.flag is null || !evt.flag.length) return "フラグ指定無し";
			auto f = summ.flagDirRoot.findFlag(evt.flag);
			return f is null ? .format("存在しないフラグ(パス:%s)", evt.flag) : "フラグ「" ~ f.path ~ "」の値で分岐";
		} case CType.BRANCH_MULTI_STEP: {
			if (evt.step is null || !evt.step.length) return "ステップ指定無し";
			auto s = summ.flagDirRoot.findStep(evt.step);
			return s is null ? .format("存在しないステップ(パス:%s)", evt.step) : "ステップ多岐分岐コンテント: " ~ s.path;
		} case CType.BRANCH_STEP: {
			auto s = summ.flagDirRoot.findStep(evt.step);
			if (s) {
				string val = s.getValue(evt.stepValue);
				return "ステップ「" ~ s.path ~ "」の値が[" ~ val ~ "]以上・未満で分岐";
			} else {
				string val = "Step - " ~ .text(evt.stepValue);
				return "存在しないステップ「" ~ evt.step ~ "」の値が[" ~ val ~ "]以上・未満で分岐";
			}
		} case CType.BRANCH_SELECT: {
			string buf = evt.targetAll ? "パーティ全員" : "動けるメンバ";
			buf ~= "から";
			buf ~= evt.random ? "ランダム" : "手動";
			buf ~= "でメンバを選択";
			return buf;
		} case CType.BRANCH_ABILITY: {
			string buf = target(evt.targetS.m) ~ "の";
			buf ~= physical(evt.physical) ~ "と";
			buf ~= mental(evt.mental) ~ "で能力判定";
			buf ~= "(レベル" ~ to!(string)(evt.signedLevel) ~ ")";
			return buf;
		} case CType.BRANCH_RANDOM: {
			return "確率 = " ~ to!(string)(evt.percent) ~ "%";
		} case CType.BRANCH_LEVEL: {
			string buf = evt.average ? "パーティ全員" : "選択中のメンバ";
			buf ~= "のレベルが" ~ to!(string)(evt.unsignedLevel) ~ "以上・未満で分岐";
			return buf;
		} case CType.BRANCH_STATUS: {
			string buf = target(evt.targetNS.m) ~ "が";
			buf ~= status(evt.status) ~ "状態か否かで分岐";
			return buf;
		} case CType.BRANCH_PARTY_NUMBER: {
			return "人数 = " ~ to!(string)(evt.partyNumber) ~ "人";
		} case CType.BRANCH_AREA: {
			return "エリア分岐コンテント";
		} case CType.BRANCH_BATTLE: {
			return "バトル分岐コンテント";
		} case CType.BRANCH_IS_BATTLE: {
			return "戦闘中判定分岐コンテント";
		} case CType.BRANCH_CAST: {
			if (0 == evt.casts) return "キャストカード指定無し";
			auto c = summ.casts(evt.casts);
			return c is null ? .format("存在しないキャストカード(ID:%d)", evt.casts) : "キャストカード「" ~ c.name ~ "」の同行有無で分岐";
		} case CType.BRANCH_ITEM: {
			if (0 == evt.item) return "アイテムカード指定無し";
			auto c = summ.item(evt.item);
			string buf = c is null ? .format("存在しないアイテムカード(ID:%d)", evt.item) : "アイテムカード「" ~ c.name ~ "」";
			buf ~= "の有無で分岐(";
			buf ~= range(evt.range) ~ "に";
			buf ~= to!(string)(evt.cardNumber) ~ "枚)";
			return buf;
		} case CType.BRANCH_SKILL: {
			if (0 == evt.skill) return "特殊技能カード指定無し";
			auto c = summ.skill(evt.skill);
			string buf = c is null ? .format("存在しない特殊技能カード(ID:%d)", evt.skill) : "特殊技能カード「" ~ c.name ~ "」";
			buf ~= "の有無で分岐(";
			buf ~= range(evt.range) ~ "に";
			buf ~= to!(string)(evt.cardNumber) ~ "枚)";
			return buf;
		} case CType.BRANCH_INFO: {
			if (0 == evt.info) return "情報カード指定無し";
			auto c = summ.info(evt.info);
			return c is null ? .format("存在しない情報カード(ID:%d)", evt.info) : "情報カード「" ~ c.name ~ "」の有無で分岐";
		} case CType.BRANCH_BEAST: {
			if (0 == evt.beast) return "召喚獣カード指定無し";
			auto c = summ.beast(evt.beast);
			string buf = c is null ? .format("存在しない召喚獣カード(ID:%d)", evt.beast) : "召喚獣カード「" ~ c.name ~ "」";
			buf ~= "の有無で分岐(";
			buf ~= range(evt.range) ~ "に";
			buf ~= to!(string)(evt.cardNumber) ~ "枚)";
			return buf;
		} case CType.BRANCH_MONEY: {
			return "分岐金額 = " ~ to!(string)(evt.money) ~ " sp";
		} case CType.BRANCH_COUPON: {
			if (evt.coupon is null || evt.coupon.length == 0) {
				return "指定無し";
			} else {
				return "称号「" ~ evt.coupon ~ "」の有無で分岐(" ~ range(evt.range) ~ ")";
			}
		} case CType.BRANCH_COMPLETE_STAMP: {
			return evt.completeStamp is null || evt.completeStamp.length == 0 ? "指定無し" : "シナリオ「" ~ evt.completeStamp ~ "」が終了済みか否かで分岐";
		} case CType.BRANCH_GOSSIP: {
			return evt.gossip is null || evt.gossip.length == 0 ? "指定無し" : "宿屋クーポン「" ~ evt.gossip ~ "」の有無で分岐";
		} case CType.SET_FLAG: {
			if (evt.flag is null || !evt.flag.length) return "フラグ指定無し";
			auto f = summ.flagDirRoot.findFlag(evt.flag);
			return f is null ? .format("存在しないフラグ(パス:%s)", evt.flag) : "フラグ「" ~ f.path ~ "」を[" ~ (evt.flagValue ? f.on : f.off) ~ "]に変更";
		} case CType.SET_STEP: {
			if (evt.step is null || !evt.step.length) return "ステップ指定無し";
			auto s = summ.flagDirRoot.findStep(evt.step);
			return s is null ? .format("存在しないステップ(パス:%s)", evt.step) : "ステップ「" ~ s.path ~ "」を[" ~ s.getValue(evt.stepValue) ~ "]に変更";
		} case CType.SET_STEP_UP: {
			if (evt.step is null || !evt.step.length) return "ステップ指定無し";
			auto s = summ.flagDirRoot.findStep(evt.step);
			return s is null ? .format("存在しないステップ(パス:%s)", evt.step) : "ステップ「" ~ s.path ~ "」の値を1増加";
		} case CType.SET_STEP_DOWN: {
			if (evt.step is null || !evt.step.length) return "ステップ指定無し";
			auto s = summ.flagDirRoot.findStep(evt.step);
			return s is null ? .format("存在しないステップ(パス:%s)", evt.step) : "ステップ「" ~ s.path ~ "」の値を1減少";
		} case CType.REVERSE_FLAG: {
			if (evt.flag is null || !evt.flag.length) return "フラグ指定無し";
			auto f = summ.flagDirRoot.findFlag(evt.flag);
			return f is null ? .format("存在しないフラグ(パス:%s)", evt.flag) : "フラグ「" ~ f.path ~ "」の値を反転";
		} case CType.CHECK_FLAG: {
			if (evt.flag is null || !evt.flag.length) return "フラグ指定無し";
			auto f = summ.flagDirRoot.findFlag(evt.flag);
			return f is null ? .format("存在しないフラグ(パス:%s)", evt.flag) : "フラグ「" ~ f.path ~ "」の値が[" ~ f.on ~ "]であれば出現";
		} case CType.GET_CAST: {
			if (0 == evt.casts) return "キャストカード指定無し";
			auto c = summ.casts(evt.casts);
			return c is null ? .format("存在しないキャストカード(ID:%d)", evt.casts) : "キャストカード「" ~ c.name ~ "」を同行させる";
		} case CType.GET_ITEM: {
			if (0 == evt.item) return "アイテムカード指定無し";
			auto c = summ.item(evt.item);
			string buf = c is null ? .format("存在しないアイテムカード(ID:%d)", evt.item) : "アイテムカード「" ~ c.name ~ "」";
			buf ~= "を獲得(";
			buf ~= range(evt.range) ~ "に";
			buf ~= to!(string)(evt.cardNumber) ~ "枚)";
			return buf;
		} case CType.GET_SKILL: {
			if (0 == evt.skill) return "特殊技能カード指定無し";
			auto c = summ.skill(evt.skill);
			string buf = c is null ? .format("存在しない特殊技能カード(ID:%d)", evt.skill) : "特殊技能カード「" ~ c.name ~ "」";
			buf ~= "を獲得(";
			buf ~= range(evt.range) ~ "に";
			buf ~= to!(string)(evt.cardNumber) ~ "枚)";
			return buf;
		} case CType.GET_INFO: {
			if (0 == evt.info) return "情報カード指定無し";
			auto c = summ.info(evt.info);
			return c is null ? .format("存在しない情報カード(ID:%d)", evt.info) : "情報カード「" ~ c.name ~ "」を獲得";
		} case CType.GET_BEAST: {
			if (0 == evt.beast) return "召喚獣カード指定無し";
			auto c = summ.beast(evt.beast);
			string buf = c is null ? .format("存在しない召喚獣カード(ID:%d)", evt.beast) : "召喚獣カード「" ~ c.name ~ "」";
			buf ~= "を獲得(";
			buf ~= range(evt.range) ~ "に";
			buf ~= to!(string)(evt.cardNumber) ~ "枚)";
			return buf;
		} case CType.GET_MONEY: {
			return "獲得金額 = " ~ to!(string)(evt.money) ~ " sp";
		} case CType.GET_COUPON: {
			if (evt.coupon is null || evt.coupon.length == 0) {
				return "指定無し";
			} else {
				return "称号「" ~ evt.coupon ~ "」を獲得(" ~ range(evt.range) ~ ")";
			}
		} case CType.GET_COMPLETE_STAMP: {
			return evt.completeStamp is null || evt.completeStamp.length == 0 ? "指定無し" : "シナリオ「" ~ evt.completeStamp ~ "」を終了済みにする";
		} case CType.GET_GOSSIP: {
			return evt.gossip is null || evt.gossip.length == 0 ? "指定無し" : "宿屋クーポン「" ~ evt.gossip ~ "」を獲得";
		} case CType.LOSE_CAST: {
			if (0 == evt.casts) return "キャストカード指定無し";
			auto c = summ.casts(evt.casts);
			return c is null ? .format("存在しないキャストカード(ID:%d)", evt.casts) : "キャストカード「" ~ c.name ~ "」の同行を解除";
		} case CType.LOSE_ITEM: {
			if (0 == evt.item) return "アイテムカード指定無し";
			auto c = summ.item(evt.item);
			string buf = c is null ? .format("存在しないアイテムカード(ID:%d)", evt.item) : "アイテムカード「" ~ c.name ~ "」";
			buf ~= "を喪失(";
			buf ~= range(evt.range) ~ "から";
			buf ~= evt.cardNumber == 0 ? "全て" : to!(string)(evt.cardNumber) ~ "枚";
			buf ~= ")";
			return buf;
		} case CType.LOSE_SKILL: {
			if (0 == evt.skill) return "特殊技能カード指定無し";
			auto c = summ.skill(evt.skill);
			string buf = c is null ? .format("存在しない特殊技能カード(ID:%d)", evt.skill) : "特殊技能カード「" ~ c.name ~ "」";
			buf ~= "を喪失(";
			buf ~= range(evt.range) ~ "から";
			buf ~= evt.cardNumber == 0 ? "全て" : to!(string)(evt.cardNumber) ~ "枚";
			buf ~= ")";
			return buf;
		} case CType.LOSE_INFO: {
			if (0 == evt.info) return "情報カード指定無し";
			auto c = summ.info(evt.info);
			return c is null ? .format("存在しない情報カード(ID:%d)", evt.info) : "情報カード「" ~ c.name ~ "」を喪失";
		} case CType.LOSE_BEAST: {
			if (0 == evt.beast) return "召喚獣カード指定無し";
			auto c = summ.beast(evt.beast);
			string buf = c is null ? .format("存在しない召喚獣カード(ID:%d)", evt.beast) : "召喚獣カード「" ~ c.name ~ "」";
			buf ~= "を喪失(";
			buf ~= range(evt.range) ~ "から";
			buf ~= evt.cardNumber == 0 ? "全て" : to!(string)(evt.cardNumber) ~ "枚";
			buf ~= ")";
			return buf;
		} case CType.LOSE_MONEY: {
			return "喪失金額 = " ~ to!(string)(evt.money) ~ " sp";
		} case CType.LOSE_COUPON: {
			if (evt.coupon is null || evt.coupon.length == 0) {
				return "指定無し";
			} else {
				return "称号「" ~ evt.coupon ~ "」を喪失(" ~ range(evt.range) ~ ")";
			}
		} case CType.LOSE_COMPLETE_STAMP: {
			return evt.completeStamp is null || evt.completeStamp.length == 0 ? "指定無し" : "シナリオ「" ~ evt.completeStamp ~ "」の終了印を削除";
		} case CType.LOSE_GOSSIP: {
			return evt.gossip is null || evt.gossip.length == 0 ? "指定無し" : "宿屋クーポン「" ~ evt.gossip ~ "」を喪失";
		} case CType.SHOW_PARTY: {
			return "パーティ表示コンテント";
		} case CType.HIDE_PARTY: {
			return "パーティ隠蔽コンテント";
		} case CType.REDISPLAY: {
			return "画面再構築コンテント";
		} default: assert (0);
		}
	}

	const string defaultStartName() {return "イベント開始";}

	/// メインウィンドウ。
	const string mainWindowName(string name, string path) {
		return name !is null ? "" ~ name ~ " [ " ~ path ~ " ] - CWXEditor" : "CWXEditor";
	}
	const string errorExecEngine(string enginePath) {
		return getBaseName(enginePath) ~ "の起動に失敗しました。";
	}

	/// シナリオ選択ダイアログ
	const string dlgTitNewScenario() {return "新規シナリオの作成";}
	const string createError(string path) {return path ~ "でシナリオの作成に失敗しました。";}
	const string dlgTitOpenScenario() {return "シナリオを開く";}
	const string[] filterScenario() {
		string[] r;
		if (canUncab) {
			r ~= "シナリオファイル (*.wsn;Summary.xml;*.cab;*.zip;Summary.wsm)";
		} else {
			r ~= "シナリオファイル (*.wsn;Summary.xml;*.zip;Summary.wsm)";
		}
		r ~= "エリア・カードファイル (*.xml;*.wid)";
		return r;
	}
	const string dlgTitSaveScenario() {return "名前を付けて保存";}
	const string filterScenarioSave() {return "XMLシナリオファイル (*.wsn)";}
	const string notScenario(string name) {return name ~ "はシナリオ圧縮ファイルではありません";}
	const string zipError(string name) {return name ~ "の展開に失敗しました。";}
	const string loadError(string name) {return name ~ "の読込みに失敗しました。";}
	const string saveError(string name) {return name ~ "の保存に失敗しました。";}
	const string dlgTitUnzip() {return "圧縮ファイルの展開 - CWXEditor";}
	const string unzip(string name) {return name ~ "を展開しています……";}
	const string loadErrorStatus(string name) {return name ~ "の読込みに失敗";}
	const string loadErrorStatus(in string[] name) {
		if (name.length == 1) {
			return loadErrorStatus(name[0]);
		}
		return to!(string)(name.length) ~ "件のシナリオの読込みに失敗";
	}

	/// データウィンドウ
	const string dataTabName(in Summary summ) {
		return "データ";
	}
	const string dataWindowName(in Summary summ) {
		if (summ) {
			return "データ - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "データ";
		}
	}
	const string areasTabName(in Summary summ) {
		return "テーブル";
	}
	const string areasWindowName(in Summary summ) {
		if (summ) {
			return "テーブル - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "テーブル";
		}
	}
	const string areaStatus(in Area[] as, in Battle[] bs, in Package[] ps, in AbstractArea sel) {
		string[] l;
		if (as.length) l ~= format("%d件のエリア", as.length);
		if (bs.length) l ~= format("%d件のバトル", bs.length);
		if (ps.length) l ~= format("%d件のパッケージ", ps.length);
		string r;
		foreach (i, s; l) {
			if (i > 0) r ~= " ";
			r ~= s;
		}
		return r;
	}
	const string flagTabName(in Summary summ) {
		return "状態変数";
	}
	const string flagWindowName(in Summary summ) {
		if (summ) {
			return "状態変数 - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "状態変数";
		}
	}
	const string flagStatus(in Flag[] flags, in Step[] steps, in Flag[] selFlags, in Step[] selSteps) {
		string r;
		if (flags.length && steps.length) {
			r = format("%d個のフラグと%d個のステップ", flags.length, steps.length);
		} else if (flags.length) {
			r = format("%d個のフラグ", flags.length);
		} else if (steps.length) {
			r = format("%d個のステップ", steps.length);
		} else {
			r = "";
		}
		if (selFlags.length || selSteps.length) {
			r ~= format(" (%d個を選択)", selFlags.length + selSteps.length);
		}
		return r;
	}
	const string scenarioView() {return "シナリオビューリスト";}
	const string variableView() {return "状態変数インスペクタ";}
	const string ttSummary() {return "シナリオの設定";}
	const string ttNewArea() {return "エリアの作成";}
	const string ttNewBattle() {return "バトルの作成";}
	const string ttNewPackage() {return "パッケージの作成";}

	const string menuSummary() {return ttSummary ~ "(&S)...";}
	const string menuNewArea() {return ttNewArea ~ "(&A)";}
	const string menuNewBattle() {return ttNewBattle ~ "(&B)";}
	const string menuNewPackage() {return ttNewPackage ~ "(&K)";}

	const string ttReNumberingAll() {return "全てのIDを1から振り直す";}
	const string menuReNumberingAll() {return ttReNumberingAll ~ "(&A)";}
	const string reNumberingAll() {
		return "全てのエリアやカードのIDの1から振り直します。\nよろしいですか？";
	}

	const string ttReNumbering() {return "IDの振り直し";}
	const string menuReNumbering() {return ttReNumbering ~ "(&N)";}
	const string dlgTitReNumbering() {return "IDの振り直し";}
	const string reNumbering() {return "IDの振り直し";}
	const string reNumbering1(in Card card, ulong min, ulong max) {
		string buf;
		if (cast(CastCard) card) {
			buf = "キャスト";
		} else if (cast(SkillCard) card) {
			buf = "特殊技能";
		} else if (cast(ItemCard) card) {
			buf = "アイテム";
		} else if (cast(BeastCard) card) {
			buf = "召喚獣";
		} else {
			assert (cast(InfoCard) card);
			buf = "情報";
		}
		return buf ~ "「" ~ card.name ~ "」以降のIDを";
	}
	const string reNumbering1(in AbstractArea area, ulong min, ulong max) {
		string buf;
		if (cast(Area) area) {
			buf = "エリア";
		} else if (cast(Battle) area) {
			buf = "バトル";
		} else {
			assert (cast(Package) area);
			buf = "パッケージ";
		}
		return buf ~ "「" ~ area.name ~ "」以降のIDを";
	}
	const string reNumbering2(in Card card, ulong min, ulong max) {
		return "番から順に振り直す";
	}
	const string reNumbering2(in AbstractArea area, ulong min, ulong max) {
		return "番から順に振り直す";
	}

	/// エリアのテーブル。
	const string areaId() {return "ID";}
	const string areaName() {return "名称";}
	const string areaCount() {return "利用数";}
	const string areaNew() {return "新規エリア";}
	const string battleNew() {return "新規バトル";}
	const string packageNew() {return "新規パッケージ";}

	/// フラグのディレクトリ。
	const string flagDirRoot() {return "Data";}
	const string flagDirNew() {return "新規フォルダ";}
	const string ttNewFlagDir() {return "フォルダの作成";}
	const string menuNewFlagDir() {return ttNewFlagDir ~ "(&N)...";}
	const int menuNewDirA() {return -1;}

	/// フラグ/ステップのテーブル。
	const string flagName() {return "名称";}
	const string flagInit() {return "初期値";}
	const string flagCount() {return "利用数";}
	const string ttNewFlag() {return "フラグの作成";}
	const string menuNewFlag() {return ttNewFlag ~ "(&F)..." ~ "\tCtrl+L";}
	const string ttNewStep() {return "ステップの作成";}
	const string menuNewStep() {return ttNewStep ~ "(&S)..." ~ "\tCtrl+P";}

	/// フラグ設定ダイアログ関連。
	const string dlgTitFlag() {return "フラグの設定";}
	const string dlgLblFlagName() {return "フラグ名";}
	const string dlgLblFlagInit() {return "初期値";}
	const string dlgLblFlagTrue() {return "TRUE";}
	const string dlgLblFlagFalse() {return "FALSE";}

	/// ステップ設定ダイアログ関連。
	const string dlgTitStep() {return "ステップの設定";}
	const string dlgLblStepName() {return "ステップ名";}
	const string dlgLblStepInit() {return "初期値";}
	const string dlgLblStep(uint index) {return dlgTxtStep(index);}
	const string dlgTxtStep(uint index) {
		return "Step - " ~ to!(string)(index);
	}

	/// 貼り紙設定ダイアログ関連。
	const string dlgTitSummary(string sname) {return "概略の設定 - [ " ~ sname ~ " ]";}
	const string summaryImage() {return "表示イメージ";}
	const string baseData() {return "基本データ";}
	const string etcData() {return "詳細データ";}
	const string targetLevel(uint levL, uint levH) {
		if (levL > 0 && levL == levH) {
			return "対象レベル " ~ to!(string)(levL);
		} else if (levL > 0 && levH > 0) {
			return "対象レベル " ~ to!(string)(levL) ~ "～" ~ to!(string)(levH);
		} else if (levL > 0 && levH == 0) {
			return "対象レベル " ~ to!(string)(levL) ~ "～";
		} else if (levL == 0 && levH > 0) {
			return "対象レベル " ~ "～" ~ to!(string)(levH);
		} else {
			return "";
		}
	}
	const string summaryPageDummy() {return "1/1";}
	const string title() {return "シナリオタイトル";}
	const string author() {return "作者名";}
	const string targetLevel() {return "対象レベル";}
	const string desc() {return "解説";}
	const string levSep() {return "～";}
	const string qualification() {return "シナリオ出現条件";}
	const string rCouponNum() {return "必要数";}
	const string rCoupons() {return "必要とする称号";}
	const string startArea() {return "シナリオ開始エリア";}

	const string scenarioType() {return "シナリオタイプ";}
	const string sTypeXML() {
		return "スキンを指定";
	}
	const string sTypeClassic() {
		return "クラシックエンジンを使用";
	}
	const string currentEngineSkin(string lEnginePath) {
		return "[" ~ getBaseName(lEnginePath) ~ "]";
	}

	/// エリア・戦闘・パッケージウィンドウ。
	const string ttUp() {return "上へ";}
	const string menuUp() {return ttUp ~ "(&U)" ~ "\tCtrl+Arrow_Up";}
	const string ttDown() {return "下へ";}
	const string menuDown() {return ttDown ~ "(&D)" ~ "\tCtrl+Arrow_Down";}
	const string menuCardsAndBacks() {return "カードと背景" ~ "(&A)";}
	const string ttViewParty() {return "パーティカードの表示";}
	const string menuViewParty() {return ttViewParty ~ "(&P)";}
	const string ttViewMsg() {return "メッセージ枠の表示";}
	const string menuViewMsg() {return ttViewMsg ~ "(&M)";}
	const string ttFixed() {return "イメージの固定";}
	const string menuFixed() {return ttFixed ~ "(&F)";}
	const string ttEnemyCardDebugView() {return "レベルとライフを表示";}
	const string menuEnemyCardDebugView() {return ttEnemyCardDebugView ~ "(&L)";}
	const string ttViewCards() {return "カードの表示";}
	const string menuViewCards() {return ttViewCards ~ "(&V)";}
	const string ttViewBacks() {return "背景の表示";}
	const string menuViewBacks() {return ttViewBacks ~ "(&I)";}
	const string ttNewMenuCard() {return "メニューカードの作成";}
	const string menuNewMenuCard() {return ttNewMenuCard ~ "(&C)...";}
	const string ttNewEnemyCard() {return "エネミーカードの作成";}
	const string menuNewEnemyCard() {return ttNewEnemyCard ~ "(&C)...";}
	const string ttNewBack() {return "背景の作成";}
	const string menuNewBack() {return ttNewBack ~ "(&B)...";}
	const string ttAuto() {return "カードを自動的に並べる";}
	const string menuAuto() {return ttAuto ~ "(&A)";}
	const string ttCustom() {return "カードの位置を自分で決定する";}
	const string menuCustom() {return ttCustom ~ "(&U)";}
	const string ttMask() {return "透明色を使用";}
	const string menuMask() {return ttMask ~ "(&M)";}
	const string ttDoEscape() {return "逃走の有無";}
	const string menuDoEscape() {return ttMask ~ "(&E)";}
	const string noRefArea() {return "[カード配置参照無し]";}

	const string menuPosTop() {return "上に揃える" ~ "(&U)";}
	const string menuPosBottom() {return "下に揃える" ~ "(&D)";}
	const string menuPosLeft() {return "左に揃える" ~ "(&L)";}
	const string menuPosRight() {return "右に揃える" ~ "(&R)";}
	const string menuPosEven() {return "等間隔に並べる" ~ "(&E)";}
	const string menuScaleMin() {return "最小のカードスケール" ~ "(&S)";}
	const string menuScaleMiddle() {return "標準のカードスケール" ~ "(&I)";}
	const string menuScaleMax() {return "最大のカードスケール" ~ "(&G)";}
	const string menuScaleEvenBig() {return "大きく揃える" ~ "(&L)";}
	const string menuScaleEvenSmall() {return "小さく揃える" ~ "(&N)";}

	const string left() {return "X";}
	const string top() {return "Y";}
	const string width() {return "幅";}
	const string height() {return "高";}
	const string scale() {return "拡大率";}

	const string areaViewStatus(Summary summ, AbstractSpCard[] cards, BgImage[] backs, bool useFlag) {
		if (cards.length == 1 && backs.length == 0 && useFlag) {
			return cards[0].flag == "" ? "フラグ指定無し" : "フラグ = " ~ cards[0].flag;
			auto flag = "] - " ~ (cards[0].flag == "" ? "フラグ指定無し" : "フラグ = " ~ cards[0].flag);
			auto menu = cast(MenuCard) cards[0];
			if (menu) {
				auto path = isBinImg(menu.path) ? "イメージ格納" : encodePath(menu.path);
				return "メニューカード [" ~ menu.name ~ "] - [" ~ path ~ flag;
			}
			auto enemy = cast(EnemyCard) cards[0];
			if (enemy && summ) {
				auto casts = summ.casts(enemy.id);
				return "エネミーカード [" ~ (casts ? (to!(string)(enemy.id) ~ "." ~  casts.name) : "対象無し") ~ flag;
			}
		} else if (cards.length == 0 && backs.length == 1 && useFlag) {
			return backs[0].flag == "" ? "フラグ指定無し" : "フラグ = " ~ backs[0].flag;
			auto flag = "] - " ~ (backs[0].flag == "" ? "フラグ指定無し" : "フラグ = " ~ backs[0].flag);
			return "背景画像 [" ~ encodePath(backs[0].path) ~ flag;
		} else if (cards.length > 0 && backs.length == 0) {
			return to!(string)(cards.length) ~ "枚のカード";
		} else if (cards.length == 0 && backs.length > 0) {
			return to!(string)(backs.length) ~ "枚の背景";
		} else if (cards.length > 0 && backs.length > 0) {
			return to!(string)(cards.length) ~ "枚のカード " ~ to!(string)(backs.length) ~ "枚の背景";
		} else {
			return "";
		}
		return "";
	}

	const private string __viewNameTab(ulong id, string name) {
		return to!(string)(id) ~ "." ~ name;
	}
	const private string __viewName(string kind, ulong id, string name) {
		return "[" ~ kind ~ "] - " ~ to!(string)(id) ~ " - " ~ name;
	}
	const string areaViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string battleViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string packageViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string skillViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string itemViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string beastViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string areaViewName(ulong id, string name) {return __viewName("エリア", id, name);}
	const string battleViewName(ulong id, string name) {return __viewName("バトル", id, name);}
	const string packageViewName(ulong id, string name) {return __viewName("パッケージ", id, name);}
	const string skillViewName(ulong id, string name) {return __viewName("スキル", id, name);}
	const string itemViewName(ulong id, string name) {return __viewName("アイテム", id, name);}
	const string beastViewName(ulong id, string name) {return __viewName("召喚獣", id, name);}

	const string handCards(ulong id, string name) {
		return __viewName("所有カード", id, name);
	}
	const string handCardsTab(ulong id, string name) {
		return __viewNameTab(id, name);
	}
	const string cardCount() {return "使用数";}
	const string addCardWindow(string name, string path) {
		return "カードのインポート - [ " ~ name ~ " ] - " ~ path;
	}
	const string addCardTab(string name, string path) {
		return name;
	}

	const string cardAndBackView() {return "カードと背景";}
	const string enemyCardView() {return "エネミーカード";}
	const string menuCards() {return "カード";}
	const string enemyCards() {return "カード";}
	const string backs() {return "背景";}
	const string eventView() {return "イベント";}
	/// カード/背景配置領域関連。
	const string dlgTitDropCard() {return "カード画像の追加";}
	const string dlgMsgDropCard(string fname) {
		return "カード画像をシナリオ" ~ DIR ~ "にコピーしますか？\n" ~ fname;
	}
	const string dlgTitDropBack() {return "背景画像の追加";}
	const string dlgMsgDropBack(string fname) {
		return "背景画像をシナリオ" ~ DIR ~ "にコピーしますか？\n" ~ fname;
	}

	const string refFlag() {return "フラグ参照先";}
	const string refStep() {return "ステップ参照先";}
	const string noFlag() {return "[参照無し]";}
	const string cardPosition() {return "カード位置";}
	const string backPosition() {return "位置";}
	const string bgImageSettings() {return "簡単設定";}
	const string bgImageSettingCustom() {return "[カスタム]";}
	const string bgImageSettingOriginal() {return "[元のサイズ]";}
	const string enemyCardBase() {return "基本設定";}
	const string dlgTitMenuCard(string name) {return "メニューカードの設定 [ " ~ name ~ " ]";}
	const string dlgTitNewMenuCard() {return "メニューカードの作成";}
	const string dlgTitBgImage() {return "背景画像の設定";}
	const string dlgTitNewBgImage() {return "背景画像の作成";}
	const string dlgTitEnemyCard(string name) {return "エネミーカードの設定 [ " ~ name ~ " ]";}
	const string dlgTitNewEnemyCard() {return "エネミーカードの作成";}
	const string stopBGM(string playingFile) {return getBaseName(playingFile) ~ "の再生を停止";}
	const string playBGM() {return "再生";}
	const string menuStopBGM(string playingFile) {return stopBGM(playingFile) ~ "(&P)";}
	const string menuPlayBGM() {return playBGM ~ "(&P)";}

	/// イベントビュー。
	const string tools() {return "イベントコンテント";}
	const string startEnter() {return "到着";}
	const string startSelect() {return "クリック";}
	const string startDead() {return "死亡";}
	const string startVictory() {return "勝利";}
	const string startEscape() {return "逃走";}
	const string startLose() {return "敗北";}
	const string startPackage() {return "パッケージ";}
	const string startUse() {return "使用時";}
	const string startRound(uint round) {return "ラウンド = " ~ to!(string)(round);}

	const string menuAddManyRounds() {return "複数のラウンドを追加";}
	const string manyRounds() {return "追加する発火ラウンドの範囲";}
	const string dlgTitAddManyRounds() {return "追加する発火ラウンドの範囲";}
	const string roundSep() {return "～";}

	const string enterTree() {return "到着";}
	const string selectTree() {return "クリック";}
	const string deadTree() {return "死亡";}
	const string victoryTree() {return "勝利";}
	const string escapeTree() {return "逃走";}
	const string loseTree() {return "敗北";}
	const string packageTree() {return "パッケージイベント";}
	const string useTree() {return "使用時イベント";}
	const string keyCodeTree(string keyCode) {return "[" ~ keyCode ~ "]";}
	const string roundTree(uint round) {return "ラウンド" ~ to!(string)(round);}

	const string ttNewEventTree() {return "イベントの作成";}
	const string ttNewEventFire() {return "イベント発火条件の作成";}
	const string ttNewTreeOpen() {return "全コンテントツリーを開く";}
	const string ttNewTreeClose() {return "全コンテントツリーを閉じる";}
	const string eventTreeKindSystem() {return "システム";}
	const string eventTreeKindKeyCode() {return "キーコード";}
	const string eventTreeKindRound() {return "ラウンド";}

	const string startUseCount() {return "利用数";}

	const string evtChildTrue() {return "○";}
	const string evtChildFalse() {return "×";}
	const string evtChildDefault() {return "Default";}
	const string evtChildOK() {return "ＯＫ";}

	const string evtChildBrFlag(in Flag flag, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		if (flag is null) {
			return "指定無し = " ~ (val ? "TRUE" : "FALSE");
		} else {
			return flag.path ~ " = " ~ (val ? flag.on : flag.off);
		}
	}
	const string evtChildBrStepN(in Step step, ref string text) {
		int val = -1;
		try {
			val = text == evtChildDefault ? -1 : (isNumeric(text) ? to!(int)(text) : -1);
		} catch {}
		if (step is null) {
			return "指定無し = " ~ (val >= 0 ? "Step - " ~ to!(string)(val) : "その他");
		} else {
			if (val < 0 || step.count <= val) {
				text = evtChildDefault;
			}
			return step.path ~ " = " ~ (val >= 0 ? step.getValue(val) : "その他");
		}
	}
	const string evtChildBrStepUL(in Step step, int num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		if (step is null) {
			return "ステップ「指定無し」が「Step - " ~ to!(string)(num) ~ "」" ~ (val ? "以上" : "未満");
		} else {
			return "ステップ「" ~ step.path ~ "」が「" ~ step.getValue(num) ~ "」" ~ (val ? "以上" : "未満");
		}
	}
	const string evtChildBrMember(bool all, bool random, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		string buf;
		buf ~= (all ? "パーティ全員" : "動けるメンバ") ~ "から";
		buf ~= (random ? "自動" : "手動") ~ "でキャラクターを選択";
		if (!val) {
			buf ~= "をキャンセル";
		}
		return buf;
	}
	const string evtChildBrPower(Target targ, Physical p, Mental m, int lev, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return target(targ) ~ "がレベル" ~ to!(string)(lev) ~ "で"
			~ physical(p) ~ "と" ~ mental(m) ~ "で行う判定に" ~ (val ? "成功" : "失敗");
	}
	const string evtChildBrRandom(int percent, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return to!(string)(percent) ~ "%" ~ (val ? "成功" : "失敗");
	}
	const string evtChildBrLevel(int lev, bool avg, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return (avg  ? "全員の平均値" : "選択中のメンバ") ~ "がレベル"
			~ to!(string)(lev) ~ (val ? "以上" : "未満");
	}
	const string evtChildBrState(Target targ, Status stat, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return target(targ) ~ "での「" ~ status(stat) ~ "」" ~ "の判定に"
			~ (val ? "成功" : "失敗");
	}
	const string evtChildBrNum(int num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "パーティに" ~ to!(string)(num) ~ "人" ~  (val ? "以上いる" : "いない");
	}
	const string evtChildBrArea(in Area[] areas, ref string text) {
		assert (areas == areas.sort);
		if (text.length > 0) {
			try {
				long val = text == evtChildDefault ? -1 : (isNumeric(text) ? to!(long)(text) : -1);
				if (val >= 0) {
					foreach (a; areas) {
						if (a.id == val) {
							return "エリア = " ~ a.name;
						}
					}
				}
			} catch {}
		}
		text = evtChildDefault;
		return "エリア = その他";
	}
	const string evtChildBrBattle(in Battle[] btls, ref string text) {
		assert (btls == btls.sort);
		if (text.length > 0) {
			try {
				long val = text == evtChildDefault ? -1 : (isNumeric(text) ? to!(long)(text) : -1);
				if (val >= 0) {
					foreach (b; btls) {
						if (b.id == val) {
							return "バトル = " ~ b.name;
						}
					}
				}
			} catch {}
		}
		text = evtChildDefault;
		return "バトル = その他";
	}
	const string evtChildBrOnBattle(ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "イベント発生時の状況が" ~ (val ? "戦闘中" : "戦闘中以外");
	}
	const string evtChildBrCast(in CastCard c, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "「" ~ (c is null ? "指定無し" : c.name) ~ "」が加わって" ~ (val ? "いる" : "いない");
	}
	const string evtChildBrItem(in ItemCard c, Range r, uint num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return range(r) ~ "で「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	const string evtChildBrSkill(in SkillCard c, Range r, uint num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return range(r) ~ "で「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	const string evtChildBrBeast(in BeastCard c, Range r, uint num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return range(r) ~ "で「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	const string evtChildBrInfo(in InfoCard c, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	const string evtChildBrMoney(uint sp, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return to!(string)(sp) ~ "sp以上所持して" ~ (val ? "いる" : "いない");
	}
	const string evtChildBrCoupon(Range r, string coupon, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return range(r) ~ "がクーポン「" ~ coupon ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	const string evtChildBrEnd(string scenario, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "シナリオ「" ~ scenario ~ "」が終了済みで" ~ (val ? "ある" : "ない");
	}
	const string evtChildBrGossip(string gossip, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "クーポン「" ~ gossip ~ "」が宿屋に" ~ (val ? "ある" : "無い");
	}
	const string physical(Physical p) {
		final switch (p) {
		case Physical.DEX:
			return "器用度";
		case Physical.AGL:
			return "敏捷度";
		case Physical.INT:
			return "知力";
		case Physical.STR:
			return "筋力";
		case Physical.VIT:
			return "生命力";
		case Physical.MIN:
			return "精神力";
		}
	}
	const string mental(Mental m) {
		final switch (m) {
		case Mental.AGGRESSIVE:
			return "好戦性";
		case Mental.UNAGGRESSIVE:
			return "平和性";
		case Mental.CHEERFUL:
			return "社交性";
		case Mental.UNCHEERFUL:
			return "内向性";
		case Mental.BRAVE:
			return "勇猛性";
		case Mental.UNBRAVE:
			return "臆病性";
		case Mental.CAUTIOUS:
			return "慎重性";
		case Mental.UNCAUTIOUS:
			return "大胆性";
		case Mental.TRICKISH:
			return "狡猾性";
		case Mental.UNTRICKISH:
			return "正直性";
		}
	}
	const string status(Status stat) {
		final switch (stat) {
		case Status.ACTIVE:
			return "行動可能";
		case Status.INACTIVE:
			return "行動不可";
		case Status.ALIVE:
			return "生存";
		case Status.DEAD:
			return "非生存";
		case Status.FINE:
			return "健康";
		case Status.INJURED:
			return "負傷";
		case Status.HEAVY_INJURED:
			return "重傷";
		case Status.UNCONSCIOUS:
			return "意識不明";
		case Status.POISON:
			return "中毒";
		case Status.SLEEP:
			return "眠り";
		case Status.BIND:
			return "呪縛";
		case Status.PARALYZE:
			return "麻痺/石化";
		}
	}
	const string effectType(EffectType t, Resist r) {
		return effectType2(t) ~ "/" ~ resist(r);
	}
	const string effectType(EffectType t) {
		return effectType2(t) ~ "属性";
	}
	const private string effectType2(EffectType t) {
		final switch (t) {
		case EffectType.PHYSIC:
			return "物理";
		case EffectType.MAGIC:
			return "魔法";
		case EffectType.MAGICAL_PHYSIC:
			return "魔法的物理";
		case EffectType.PHYSICAL_MAGIC:
			return "物理的魔法";
		case EffectType.NONE:
			return "無";
		}
	}
	const string resist(Resist r) {
		final switch (r) {
		case Resist.AVOID:
			return "回避属性";
		case Resist.RESIST:
			return "抵抗属性";
		case Resist.UNFAIL:
			return "必中属性";
		}
	}
	const string cardTarget(CardTarget r) {
		final switch (r) {
		case CardTarget.NONE:
			return "対象無し";
		case CardTarget.USER:
			return "使用者";
		case CardTarget.PARTY:
			return "味方";
		case CardTarget.ENEMY:
			return "敵方";
		case CardTarget.BOTH:
			return "双方";
		}
	}
	const string cardTargetOne() {return "一体";}
	const string cardTargetAll() {return "全体";}
	const string cardVisual(CardVisual vis) {
		final switch (vis) {
		case CardVisual.NONE:
			return "視覚効果無し";
		case CardVisual.REVERSE:
			return "対象を反転";
		case CardVisual.HORIZONTAL:
			return "対象を横に震動";
		case CardVisual.VERTICAL:
			return "対象を縦に震動";
		}
	}
	const string premium(Premium r) {
		final switch (r) {
		case Premium.NORMAL:
			return "日用品 (買戻し不可/破棄可)";
		case Premium.RARE:
			return "希少品 (買戻し可/破棄可)";
		case Premium.PREMIUM:
			return "貴重品 (買戻し可/破棄不可)";
		}
	}
	const string enhance(Enhance r) {
		final switch (r) {
		case Enhance.ACTION:
			return "行動";
		case Enhance.AVOID:
			return "回避";
		case Enhance.RESIST:
			return "抵抗";
		case Enhance.DEFENSE:
			return "防御";
		}
	}
	const string mentality() {
		return "精神状態";
	}
	const string mentality(Mentality m) {
		final switch (m) {
		case Mentality.NORMAL: return "正常";
		case Mentality.SLEEP: return "睡眠";
		case Mentality.CONFUSE: return "混乱";
		case Mentality.OVERHEAT: return "激昂";
		case Mentality.BRAVE: return "勇敢";
		case Mentality.PANIC: return "恐慌";
		}
	}

	const string enhanceBonus(Enhance r) {
		return enhance(r) ~ "ボーナス";
	}
	const string statusActive() {
		return "※ 行動可能 = (健康 | 負傷 | 重傷 | 中毒)";
	}
	const string statusInactive() {
		return "※ 行動不可 = (意識不明 | 麻痺/石化 | 呪縛 | 眠り)";
	}
	const string statusAlive() {
		return "※ 生存 = (健康 | 負傷 | 重傷 | 中毒 | 呪縛 | 眠り)";
	}
	const string statusDead() {
		return "※ 非生存 = (意識不明 | 麻痺/石化)";
	}
	const string target(Target targ) {
		return target(targ.m);
	}
	const string target(Target.M m) {
		final switch (m) {
		case Target.M.SELECTED:
			return "選択中のメンバ";
		case Target.M.UNSELECTED:
			return "選択中以外のメンバ";
		case Target.M.RANDOM:
			return "誰か一人";
		case Target.M.PARTY:
			return "パーティ全員";
		}
	}
	const string talker(Talker talker) {
		final switch (talker) {
		case Talker.SELECTED:
			return "[選択中]";
		case Talker.UNSELECTED:
			return "[選択中以外]";
		case Talker.RANDOM:
			return "[ランダム]";
		case Talker.CARD:
			return "[カード]";
		case Talker.NARRATION:
			return "[話者無し]";
		case Talker.IMAGE:
			return "[画像]";
		}
	}
	const string range(Range r) {
		final switch (r) {
		case Range.SELECTED:
			return "現在選択中のメンバ";
		case Range.RANDOM:
			return "パーティの誰か一人";
		case Range.PARTY:
			return "パーティの全員";
		case Range.BACKPACK:
			return "荷物袋";
		case Range.PARTY_AND_BACKPACK:
			return "全体(荷物袋含む)";
		case Range.FIELD:
			return "フィールド全体";
		}
	}
	const string damageType(DamageType dtyp) {
		final switch (dtyp) {
		case DamageType.LEVEL_RATIO:
			return "レベルに対応する値";
		case DamageType.NORMAL:
			return "値の直接入力";
		case DamageType.MAX:
			return "最大値処理";
		}
	}
	const string element(Element el) {
		final switch (el) {
		case Element.ALL:
			return "全";
		case Element.HEALTH:
			return "肉体";
		case Element.MIND:
			return "精神";
		case Element.MIRACLE:
			return "神聖";
		case Element.MAGIC:
			return "魔力";
		case Element.FIRE:
			return "炎";
		case Element.ICE:
			return "冷気";
		}
	}

	const string sexName(Sex s) {
		final switch (s) {
		case Sex.MALE: return "男/♂";
		case Sex.FEMALE: return "女/♀";
		}
	}
	const string sexUnknown() {return "謎/？";}
	const string periodUnknown() {return "不明";}
	const string natureUnknown() {return "その他";}

	const string ttOpenTableView() {return "テーブルビューで開く";}
	const string menuOpenTableView() {return ttOpenTableView ~ "(&V)";}
	const string ttOpenFlagView() {return "フラグビューで開く";}
	const string menuOpenFlagView() {return ttOpenFlagView ~ "(&V)";}
	const string ttOpenCardView() {return "カードビューで開く";}
	const string menuOpenCardView() {return ttOpenCardView ~ "(&V)";}
	const string ttOpenFileView() {return "ファイルビューで開く";}
	const string menuOpenFileView() {return ttOpenFileView ~ "(&V)";}
	const string ttOpenEventTreeView() {return "イベントビューで開く";}
	const string menuOpenEventTreeView() {return ttOpenEventTreeView ~ "(&V)";}

	const string ttWriteComment() {return "コメントを記述";}
	const string menuWriteComment() {return ttWriteComment ~ "(&M)\tCtrl+M";}
	const string dlgTitComment() {return "コメントの記述";}

	/// カードウィンドウ。
	const string cardTabName(in Summary summ) {
		return "カード";
	}
	const string cardWindowName(in Summary summ) {
		if (summ) {
			return "カード - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "カード";
		}
	}
	const string dlgTitAddScenario() {return "インポート元の選択";}

	const string cardStatus(C)(size_t cardCount, in C[] selCards) {
		string r = to!(string)(cardCount) ~ "枚のカード";
		if (selCards.length == 1) {
			r ~= " (ID = " ~ to!(string)(selCards[0].id) ~ ")";
		} else if (selCards.length) {
			r ~= " (" ~ to!(string)(selCards.length) ~ "枚を選択中)";
		}
		return r;
	}
	const string handCardStatus(C)(size_t cardCount, in C[] selCards, int max) {
		return to!(string)(cardCount) ~ "枚のカード (有効枚数 = " ~ to!(string)(max) ~ ")";
	}

	const string ttShowCardLife() {return "レベルとライフを表示";}
	const string menuShowCardLife() {return ttShowCardLife ~ "(&L)";}
	const string ttShowCardList() {return "カード表示";}
	const string menuShowCardList() {return ttShowCardList ~ "(&C)";}
	const string ttShowCardTable() {return "詳細表示";}
	const string menuShowCardTable() {return ttShowCardTable ~ "(&D)";}
	const string menuNewCards() {return "カード" ~ "(&C)";}

	const string ttAddScenario() {return "外部シナリオから追加";}
	const string menuAddScenario() {return ttAddScenario ~ "(&A)...";}
	const string ttNewCast() {return "キャストカードの作成";}
	const string menuNewCast() {return ttNewCast ~ "(&C)...";}
	const string ttNewSkill() {return "スキルカードの作成";}
	const string menuNewSkill() {return ttNewSkill ~ "(&S)...";}
	const string ttNewItem() {return "アイテムカードの作成";}
	const string menuNewItem() {return ttNewItem ~ "(&I)...";}
	const string ttNewBeast() {return "召喚獣カードの作成";}
	const string menuNewBeast() {return ttNewBeast ~ "(&B)...";}
	const string ttNewInfo() {return "情報カードの作成";}
	const string menuNewInfo() {return ttNewInfo ~ "(&F)...";}

	const string ttAdd() {return "シナリオに追加";}
	const string menuAdd() {return ttAdd ~ "(&A)" ~ "\tCtrl+P";}

	const string menuEditHand() {return "所有カードの設定" ~ "(&H)";}
	const string menuOpenHand() {return "所有カード" ~ "(&H)";}
	const string menuEditUseEvent() {return "使用時イベントの設定" ~ "(&E)";}

	const string casts() {return "キャスト";}
	const string skill() {return "スキル";}
	const string item() {return "アイテム";}
	const string beast() {return "召喚獣";}
	const string info() {return "情報";}

	const string cardId() {return "ID";}
	const string cardName() {return "名称";}
	const string cardDesc() {return "説明";}

	const string dlgTitNewCast() {return "キャストカードの作成";}
	const string dlgTitNewSkill() {return "特殊技能カードの作成";}
	const string dlgTitNewItem() {return "アイテムカードの作成";}
	const string dlgTitNewBeast() {return "召喚獣カードの作成";}
	const string dlgTitNewInfo() {return "情報カードの作成";}
	const string dlgTitCast(string name) {return "キャストカードの設定 [ " ~ name ~ " ]";}
	const string dlgTitSkill(string name) {return "特殊技能カードの設定 [ " ~ name ~ " ]";}
	const string dlgTitItem(string name) {return "アイテムカードの設定 [ " ~ name ~ " ]";}
	const string dlgTitBeast(string name) {return "召喚獣カードの設定 [ " ~ name ~ " ]";}
	const string dlgTitInfo(string name) {return "情報カードの設定 [ " ~ name ~ " ]";}

	const string name() {return "名前";}
	const string nameLimit(uint limit) {return "(" ~ to!(string)(limit / 2) ~ "文字まで)";}
	const string level() {return "レベル";}
	const string life() {return "体力";}
	const string lifeCalc() {return "標準値";}
	const string history() {return "経歴";}
	const string coupons() {return "経歴";}
	const string addCoupon() {return "新規クーポンの追加";}
	const string altCoupon() {return "クーポンの上書き";}
	const string delCoupon() {return "クーポンの削除";}
	const string sex() {return "性別";}
	const string period() {return "年代";}
	const string race() {return "種族";}
	const string noRace() {return "[未指定]";}
	const string raceCoupon(Race race) {return "＠Ｒ" ~ race.name;}
	const string nature() {return "素質";}
	const string makings() {return "特徴";}
	const string tolerant() {return "対属性";}
	const string tolerantBase() {return "対カード属性";}
	const string tolerantElement() {return "対効果属性";}
	const string resistWeapon() {return "武器が効かない";}
	const string resistMagic() {return "魔法が効かない";}
	const string undead() {return "命を持たない";}
	const string automaton() {return "心を持たない";}
	const string unholy() {return "不浄な存在";}
	const string constructure() {return "魔法生物";}
	const string resist(Element e) {return element(e) ~ "に耐性を持つ";}
	const string weakness(Element e) {return element(e) ~ "に弱い";}
	const string descResistWeapon() {return "(物理属性のカードが無効)";}
	const string descResistMagic() {return "(魔法属性のカードが無効)";}
	const string descUndead() {return "(肉体属性の効果が無効)";}
	const string descAutomaton() {return "(精神属性の効果が無効)";}
	const string descUnholy() {return "(神聖属性の効果に影響)";}
	const string descConstructure() {return "(魔力属性の効果に影響)";}
	const string descResist(Element e) {return "(" ~ element(e) ~ "属性の効果が無効)";}
	const string descWeakness(Element e) {return "(" ~ element(e) ~ "属性の効果に影響)";}
	const string basicResist() {return "標準値";}
	const string physicalParams() {return "身体能力";}
	const string physicalCalc() {return "標準値";}
	const string mentalParams() {return "精神傾向";}
	const string mentalCalc() {return "標準値";}
	const string castEnhance() {return "能力修正";}
	const string basicEnhance() {return "標準値";}

	const string liveStatus() {return "初期状態";}
	const string lifeAndMentality() {return "体力と精神状態";}
	const string enhanceLiveBonus() {return "能力ボーナス/ペナルティ";}
	const string enhanceLiveBonus(Enhance enh) {
		switch (enh) {
		case Enhance.ACTION: return "行動";
		case Enhance.AVOID: return "回避";
		case Enhance.RESIST: return "抵抗";
		case Enhance.DEFENSE: return "防御";
		default: assert (0);
		}
	}
	const string useMax() {return "最大値を使用";}
	const string status() {return "異常状態";}
	const string paralyze() {return "麻痺/石化";}
	const string poison() {return "中毒";}
	const string bind() {return "呪縛";}
	const string silence() {return "沈黙";}
	const string faceUp() {return "暴露";}
	const string antiMagic() {return "魔法無効";}
	const string unitValue() {return "点";}
	const string unitRound() {return "ラウンド";}
	const string resetLiveStatus() {return "通常状態に戻す";}

	const string needSpellGroup() {return "発声による発動";}
	const string needSpell() {return "沈黙時に使用不可";}
	const string elementProps() {return "効果属性";}
	const string resistProps() {return "抵抗属性";}
	const string aptPhysical() {return "身体的要素";}
	const string aptMental() {return "精神的要素";}
	const string skillLevel() {return "技能レベル";}
	const string useCountGroup() {return "使用可能回数";}
	const string useCountRange(uint max) {return "(0～" ~ to!(string)(max) ~ " : 0 = ∞)";}
	const string price() {return "価格";}
	const string priceAuto() {return "(参考用)";}
	const string useModify() {return "使用時 能力値修正";}
	const string haveModify() {return "所有時 能力値修正";}
	const string motionKind() {return "効果種別";}
	const string motionElement() {return "属性";}
	const string motionDamageType() {return "タイプ";}
	const string motionValue() {return "値";}
	const string motionBeast() {return "召喚するカード";}
	const string beastNone() {return "召喚獣無し";}
	const string setBeast() {return "選択";}
	const string motionRound() {return "継続時間 (ラウンド数)";}
	const string motionEnhValue() {return "変化値";}
	const string effectTarget() {return "効果目標";}
	const string effectRange() {return "効果範囲";}
	const string effectVisual() {return "視覚効果";}
	const string cardPremium() {return "カードの価値";}
	const string successRate() {return "成功率修正値";}
	const string allFail() {return "絶対失敗\n(-5)";}
	const string allSuccess() {return "絶対成功\n(+5)";}
	const string se() {return "効果音";}
	const string se1() {return "初期効果";}
	const string se2() {return "二次効果";}
	const string soundNone() {return "[効果音無し]";}
	const string stopSound() {return "停止";}
	const string playSound() {return "再生";}
	const string menuStopSound() {return stopSound ~ "(&S)";}
	const string menuPlaySound() {return playSound ~ "(&P)";}
	const string keyCodes() {return "イベント発火のキーコード";}

	const string warningEffectTypeNone() {
		return "無属性のカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。";
	}
	const string warningVanishCast() {
		return "神聖属性以外の対象消去効果を持つカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。";
	}
	const string warningNameLenOver(uint limit) {
		return "名前の長さが" ~ to!string(limit / 2) ~ "文字を超えています。メッセージにカード名が表示された際に不具合が発生する可能性があります。";
	}

	const string card() {return "カード";}
	const string apt() {return "要素";}
	const string useCountAndDesc() {return "使用回数/解説";}
	const string levelAndDesc() {return "レベル/解説";}
	const string useBonus() {return "使用ボーナス";}
	const string haveBonus() {return "所持ボーナス";}
	const string motion() {return "効果";}
	const string cardProps() {return "属性";}
	const string settings() {return "設定";}
	const string seAndKeyCode() {return "効果音/キーコード";}

	const string rangeHint(int min, int max) {
		return "(" ~ to!(string)(min) ~ "～" ~ to!(string)(max) ~ ")";
	}

	/// ファイルビュー。
	const string dirTabName(in Summary summ) {
		return "ファイル";
	}
	const string dirWindowName(in Summary summ) {
		if (summ) {
			return "ファイル - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "ファイル";
		}
	}
	const string dirStatus(uint fileCount, ulong size, in string[] selFiles) {
		auto r = to!(string)(fileCount) ~ "個のファイル (" ~ formatNum(size / 1024) ~ " KB)";
		if (selFiles.length) {
			r ~= " (" ~ to!(string)(selFiles.length) ~ "個を選択中)";
		}
		return r;
	}
	const string fileName() {return "ファイル名";}
	const string fileExt() {return "拡張子";}
	const string fileCount() {return "使用数";}
	const string errorExec(string appName) {return appName ~ "の起動に失敗しました。";}
	const string ttNewFolder() {return "新規" ~ DIR;}
	const string menuNewFolder() {return ttNewFolder ~ "(&I)";}
	const string newFolder() {return ttNewFolder;}
	const string ttCopyFilePath() {return "素材のパスをコピー";}
	const string menuCopyFilePath() {return ttCopyFilePath ~ "(&M)";}
	const string ttReplacePath() {return "素材の差替え";}
	const string menuReplacePath() {return ttReplacePath ~ "(&R)...";}
	const string ttCreateArchive() {return "シナリオを圧縮";}
	const string menuCreateArchive() {return ttCreateArchive ~ "(&A)...";}
	const string[] filterArchive() {
		string[] r;
		r ~= "ZIP アーカイブ (*.zip)";
		if (canUncab) {
			r ~= "CAB アーカイブ (*.cab)";
		}
		r ~= "シナリオファイル (*.wsn)";
		return r;
	}
	const string dlgTitCreateArchive() {return "シナリオの圧縮";}
	const string failedCreateArchive() {return "シナリオの圧縮に失敗";}
	const string dlgMsgIsSaveBeforeCreateArchive(string name) {return "「" ~ name ~ "」は変更されています。保存しますか？";}

	/// エディタ設定ダイアログ。
	const string baseSettings() {return "基本設定";}
	const string reference() {return "...";}
	const string enginePath(string appName) {return appName ~ "の場所";}
	const string enginePathAtten() {return "※ クラシックなシナリオのみに使用する場合は空欄にしてください";}
	const string dlgTitEnginePath(string appName) {return appName ~ "の場所";}
	const string tempDir() {return "シナリオの一時展開先";}
	const string tempDirDesc() {return "wsn圧縮されたシナリオの一時的な展開先を選択してください。";}
	const string backupDir() {return "自動バックアップ";}
	const string backupEnabled() {return "自動バックアップを行う";}
	const string backupPath() {return "保存先";}
	const string backupDirDesc() {return "シナリオを定期的に自動バックアップする" ~ DIR ~ "を選択してください。";}
	const string backupInterval() {return "保存間隔";}
	const string minute() {return "分";}
	const string backupCount() {return "最大保存数";}
	const string skin() {return "スキン";}
	const string scenarioAuthor() {return "シナリオ作者(新規作成時に自動設定されます)";}
	const string historiesSettings() {return "履歴";}
	const string openHistoryMax() {return "シナリオ履歴保存件数";}
	const string openHistoryClear() {return "クリア";}
	const string dlgMsgHistoryClear() {return "シナリオ履歴を削除してよろしいですか？";}
	const string searchHistoryMax() {return "検索/置換履歴保存件数";}
	const string searchHistoryClear() {return "クリア";}
	const string dlgMsgSearchHistoryClear() {return "検索/置換履歴を削除してよろしいですか？";}
	const string ignorePaths() {return "無視ファイル(改行区切り)";}
	const string etcSettings() {return "その他";}
	const string etcSettingsTitle() {return "詳細";}
	const string singleWindow() {return "シングルウィンドウモード(再起動後に反映されます)";}
	const string smoothingCard() {return "カードのサイズ変更時にスムージングを行う";}
	const string expandXMLs() {return "圧縮されたシナリオの読込み時にXMLファイルを展開する";}
	const string contentsFloat() {return "コンテンツボックスを別ウィンドウで表示する";}
	const string xmlCopy() {return "コピーや切り取りを常にXML形式で行う";}
	const string saveInnerImagePath() {return "クラシックなシナリオで格納イメージにファイルパスを埋め込む";}
	const string traceDirectories() {
		return "ファイル・" ~ DIR ~ "の変更を自動的に追跡する";
	}
	const string logicalSort() {return "数値参照型ソートを行う(1, 10, 2, 3, ... → 1, 2, 3, 10, ...)";}
	const string copyDesc() {return "カードをエリアに貼り付け・ドロップした時、解説もコピーする";}
	const string refCardsAtEditBgImage() {return "背景変更コンテントの編集を開始する際、最初からカード配置の参照を行う";}
	const string addNewClassicEngine() {return "未知のクラシックエンジンを見つけたら記憶する";}
	const string doubleIO() {return "分割読込・保存を行う(デュアルコア以上の環境で高速化)";}
	const string soundPlayType() {return "音声再生方法";}
	const string soundPlayTypeDef() {return "自動選択";}
	const string soundPlayTypeSDL() {return "SDL(CardWirthPy形式)";}
	const string soundPlayTypeMCI() {return "MCI(CardWirth形式)";}

	const string wallpaper() {
		return "エディタの壁紙";
	}
	const string filterWallpaper() {
		return "画像ファイル (*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.ico;*.icon)";
	}
	const string dlgTitWallpaper() {return "壁紙画像の選択";}

	const string bgImageAndKeyCode() {return "背景とキーコード";}
	const string newBgImageSetting() {return "新規作成";}
	const string delBgImageSetting() {return "削除";}
	const string newBgImageSettingName() {return "新規設定";}
	const string standardKeyCode() {return "標準のキーコード";}

	const string errorEnginePath(string appName) {return appName ~ "の場所が正しくありません。";}
	const string errorTempPath() {return "一時展開先が正しくありません。";}
	const string errorBackupPath() {return "自動バックアップ先が正しくありません。";}

	const string outerTools() {return "外部ツール";}
	const string outerToolsTitle() {return "外部ツールの設定";}
	const string outerToolName() {return "外部ツール名";}
	const string outerToolCommand() {return "コマンド";}
	const string dlgTitOuterTool() {return "外部ツールの選択";}
	const string newOuterToolName() {return "新規外部ツール";}
	const string toolsHint1() {return "$F = ファイル名";}
	const string toolsHint3() {return "$$ = $";}
	const string outerToolWorkDir() {return "作業" ~ DIR;}
	const string toolWorkDir() {return "作業" ~ DIR ~ "の選択";}
	const string toolWorkDirDesc() {return "外部ツールの作業" ~ DIR ~ "を選択してください。";}
	const string toolsHint2() {return "$S = シナリオの" ~ DIR;}
	version (Windows) {
		const string[] toolTName() {return ["実行ファイル (*.exe)", "すべてのファイル (*.*)"];}
	} else {
		const string[] toolTName() {return ["すべてのファイル (*.*)"];}
	}
	const string newOuterTool() {return "新規作成";}
	const string delOuterTool() {return "削除";}

	const string classicEngines() {return "クラシックエンジン";}
	const string classicEnginesTitle() {return "クラシックエンジンの設定";}
	const string classicEngineName() {return "エンジン名";}
	const string classicEnginePath() {return "実行ファイルパス";}
	const string classicEngineDataDirName() {return "データフォルダ";}
	const string classicEngineDataDirNameDesc() {return "クラシックエンジンのデータフォルダを選択してください。";}
	const string classicEngineExecute() {return "代替実行ファイル";}
	const string classicEngineHint1() {return "※ 代替実行ファイルを指定すると、エンジン本体の代わりに実行されます";}
	version (Windows) {
		const string[] classicEnginePathTName() {return ["実行ファイル (*.exe)", "すべてのファイル (*.*)"];}
	} else {
		const string[] classicEnginePathTName() {return ["すべてのファイル (*.*)"];}
	}
	const string dlgTitClassicEnginePath() {return "クラシックエンジンの選択";}
	version (Windows) {
		const string[] classicEngineExecuteTName() {return ["実行ファイル (*.exe)", "すべてのファイル (*.*)"];}
	} else {
		const string[] classicEngineExecuteTName() {return ["すべてのファイル (*.*)"];}
	}
	const string dlgTitClassicEngineExecute() {return "代替実行ファイルの選択";}
	const string newClassicEngineName() {return "新規クラシックエンジン";}
	const string newClassicEngine() {return "新規作成";}
	const string delClassicEngine() {return "削除";}

	const string bgImagesDefault() {return "デフォルト背景";}
	const string setBgImagesDefault() {return "デフォルト背景の設定...";}
	const string dlgTitBgImagesDefault() {return "デフォルト背景の設定";}

	/// スクリプト関係。
	const string ttToScript() {return "スクリプトに変換してコピー";}
	const string menuToScript() {return ttToScript ~ "(&S)\tCtrl+G";}
	const string ttToScriptAll() {return "全てをスクリプトに変換してコピー";}
	const string menuToScriptAll() {return ttToScriptAll ~ "(&P)\tCtrl+B";}
	const string dlgTitScriptError() {
		return "CWXスクリプトエラー";
	}
	const string scriptError() {
		return "CWXスクリプトのコンパイル中にエラーが発生しました。";
	}
	const string scriptErrorOver100Error() {return "エラーが100件を超えたため、スクリプトの解析を終了します。";}
	const string scriptErrorInvalidToken() {return "スクリプトに使用できない文字が含まれています。";}
	const string scriptErrorInvalidString() {return "ここに文字列が必要です。";}
	const string scriptErrorUnCloseString() {return "文字列が閉じられていません。";}
	const string scriptErrorUnOpenComment() {return "コメントは開始されていません。";}
	const string scriptErrorUnCloseComment() {return "コメントが閉じられていません。";}
	const string scriptErrorInvalidNumber() {return "数値が正しくありません。";}
	const string scriptErrorCloseBracketNotFound() {return "閉じ括弧が見つかりません。";}
	const string scriptErrorCloseParenNotFound() {return "閉じ括弧が見つかりません。";}
	const string scriptErrorZeroDivision() {return "0で除算を行いました。";}
	const string scriptErrorInvalidAttr() {return "属性が正しくありません。";}
	const string scriptErrorInvalidVar() {return "変数が正しくありません。";}
	const string scriptErrorInvalidVarVal() {return "変数の値が正しくありません。";}
	const string scriptErrorNoStartText() {return "スタートコンテントの名前がありません。";}
	const string scriptErrorInvalidStatement() {return "文が正しくありません。";}
	const string scriptErrorInvalidBranch() {return "分岐の構成が正しくありません。";}
	const string scriptErrorNoIfText() {return "ifの条件が見つかりません。";}
	const string scriptErrorNoIfContents() {return "分岐先のコンテントが見つかりません。";}
	const string scriptErrorInvalidKeyword() {return "未知のキーワードです。";}
	const string scriptErrorInvalidValuesOpen() {return "パラメータ列ではありません。";}
	const string scriptErrorInvalidValuesClose() {return "閉じ括弧が見つかりません。";}
	const string scriptErrorNoVarSet() {return "変数に値をセットしていません。";}
	const string scriptErrorNoVarVal() {return "変数の値がありません。";}
	const string scriptErrorInvalidCalc() {return "計算式が不正です。";}
	const string scriptErrorInvalidBoolVal() {return "キーワードが正しくありません。";}
	const string scriptErrorInvalidTransition() {return "未知の画面切替方式です。";}
	const string scriptErrorInvalidRange() {return "未知の範囲です。";}
	const string scriptErrorInvalidStatus() {return "未知のステータスです。";}
	const string scriptErrorInvalidTarget() {return "未知のターゲットです。";}
	const string scriptErrorInvalidEffectType() {return "未知の効果属性です。";}
	const string scriptErrorInvalidResist() {return "未知の命中属性です。";}
	const string scriptErrorInvalidCardVisual() {return "未知の視覚効果です。";}
	const string scriptErrorInvalidMental() {return "未知の精神要素です。";}
	const string scriptErrorInvalidPhysical() {return "未知の肉体要素です。";}
	const string scriptErrorInvalidMotionType() {return "未知の効果タイプです。";}
	const string scriptErrorInvalidMotion() {return "効果が正しくありません。";}
	const string scriptErrorInvalidElement() {return "未知の属性です。";}
	const string scriptErrorInvalidDamageType() {return "未知のダメージタイプです。";}
	const string scriptErrorInvalidBgImage() {return "背景画像が正しくありません。";}
	const string scriptErrorInvalidDialog() {return "台詞が正しくありません。";}
	const string scriptErrorInvalidTalker() {return "話者が正しくありません。";}
	const string scriptErrorUndefinedSymbol() {return "未知のシンボルです。";}
	const string scriptErrorStartsMixedContent() {return "スタートコンテントの中に他のコンテントが混入しています。";}
	const string scriptErrorContentsMixedStart() {return "ここにスタートコンテントが現れる事はできません。";}
	const string scriptErrorInvalidCommand() {return "命令が正しくありません。";}
	const string scriptErrorCanNotHaveContent() {return "このコンテントが後続コンテントを持つ事はできません。";}
	const string scriptErrorInvalidStr() {return "文字列が正しくありません。";}
	const string scriptErrorReqNumber() {return "ここに数値が必要です。";}
	const string scriptErrorReqID() {return "ここにIDが必要です。";}
	const string scriptErrorUndefinedVar() {return "存在しない変数です。";}
	const string scriptErrorInvalidValue() {return "値が正しくありません。";}
	const string scriptErrorCommaNotFound() {return "パラメータの区切りにカンマがありません。";}
}

public class Looks {
public:
	const string[] fontFiles() {
		return [
			"Data" ~ sep ~ "Font" ~ sep ~ "gothic.ttf",
			"Data" ~ sep ~ "Font" ~ sep ~ "mincho.ttf",
			"Data" ~ sep ~ "Font" ~ sep ~ "uigothic.ttf"
		];
	}
	const CPoint castCardNamePoint(){return CPoint(5, 5);}
	const CPoint menuCardNamePoint(){return CPoint(5, 5);}
	const CPoint cardNamePoint(){return CPoint(5, 5);}
	const CSize cardSize(){return CSize(74, 94);}
	const CSize summarySize() {return CSize(400, 370);}
	const CPoint summaryImageXY() {return CPoint(163, 65);}
	const int summaryLevelY() {return 15;}
	const int summaryTitleY() {return 35;}
	const CPoint summaryDescXY() {return CPoint(65, 175);}
	const int summaryDescLen() {return 38;}
	const int summaryDescLine() {return 11;}
	const int summaryPageY() {return 340;}
	const CRGB summaryLevelColor() {return CRGB(32, 128, 128);}
	const int posLeftMax() {return 9999;}
	const int posLeftMin() {return -9999;}
	const int posTopMax() {return 9999;}
	const int posTopMin() {return -9999;}
	const int backWidthMax() {return 9999;}
	const int backWidthMin() {return -9999;}
	const int backHeightMax() {return 9999;}
	const int backHeightMin() {return -9999;}
	const double cardSizeMin(){return 0.50;}
	const double cardSizeMax(){return 3.0;}
	const CInsets castCardInsets(){return CInsets(18, 11, 18, 10);}
	const CInsets menuCardInsets(){return CInsets(13, 3, 3, 3);}
	const CInsets cardInsets(){return menuCardInsets;}
	const uint partyMax() {return 6;}
	const CPoint[] partyCardXY() {
		return [
			CPoint(8, 285),
			CPoint(112, 285),
			CPoint(216, 285),
			CPoint(320, 285),
			CPoint(424, 285),
			CPoint(528, 285)
		];
	}

	const CRect messageBounds() {return CRect(81, 50, 470, 180);}
	const int messageButtonHeight() {return 26;}
	const CRGB messageLineColor1() {return CRGB(0, 0, 0);}
	const CRGB messageLineColor2() {return CRGB(128, 0, 0);}
	const CRGB messageBackColor() {return CRGB(0, 0, 128);}
	const int levelMax() {return 15;}

	const int aptVeryHigh() {return 15;}
	const int aptHigh() {return 9;}
	const int aptNormal() {return 3;}

	const CPoint useStoneXY() {return CPoint(60, 75);}
	const CPoint aptStoneXY() {return CPoint(60, 90);}

	const CPoint premiumXY() {return CPoint(5, 5);}
	const uint itemCardMaxNum(uint lev) {
		int r = (lev + 1) / 2 + 2;
		return r <= 10 ? r : 10;
	}
	const uint skillCardMaxNum(uint lev) {
		int r = (lev + 1) / 2 + 2;
		return r <= 10 ? r : 10;
	}
	const uint beastCardMaxNum(uint lev) {
		int r = (lev + 1) / 4 + 1;
		return r <= 10 ? r : 10;
	}
	const int cardDescLen() {return 38;}
	const int cardDescLine() {return 7;}

	const int messageImageLen() {return 34;}
	const int messageLen() {return 44;}
	const int messageLine() {return 7;}

	const int stepMaxCount() {return 10;}

	const uint castNameLimit() {return 14;}
	const uint nameLimit() {return 12;}
	const uint castLevelMax() {return 99;}
	const uint lifeMax() {return 999;}
	const uint lifeCalc(uint lev, uint vit, uint spi) {
		return cast(uint) (((lev + 1.0) * (vit / 2.0 + 4.0)) + (spi / 2.0));
	}
	const uint couponValueMax() {return Content.couponValue_max;}
	const uint physicalMax() {return 15;}
	const uint physicalCutMin() {return 1;}
	const uint physicalCutMaxBase() {return 6;}
	const uint physicalNormal() {return 6;}
	const uint[] physicalBorders() {return [1, 6, 12];}
	const uint mentalMax() {return 4;}
	const uint mentalCut() {return 3;}
	const uint[] mentalBorders() {return [3];}

	const uint skillLevelMax() {return 999;}
	const int skillPrice(int lev) {return (lev + 2) * 200;}
	const int beastPrice() {return 500;}
	const uint useCountMax() {return 999;}
	const uint priceMax() {return Content.money_max;}
	const uint enhanceMax() {return 10;}
	const int keyCodesMaxLegacy() {return 5;}
	const int keyCodesMax() {return 10;}
	const uint motionRoundDefault() {return 10;}
	const uint roundMax() {return 999;}
	const uint paralyzeMax() {return 40;}
	const uint poisonMax() {return 40;}
	const uint stoneBorder() {return 20;}

	const uint idMax() {return 99999;}

	const uint transitionSpeedDef() {
		return Content.transitionSpeed_min
			+ ((Content.transitionSpeed_max - Content.transitionSpeed_min) / 2);
	}

	const CSize viewSize() {return CSize(632, 420);}

	const string monospace() {
		version (Windows) {
			return "ＭＳ ゴシック";
		}
		return "IPAゴシック";
	}

	private static string gothic(bool legacy) {
		version (Windows) {
			if (legacy) return "ＭＳ ゴシック";
		}
		return "IPAゴシック";
	}
	private static string pgothic(bool legacy) {
		version (Windows) {
			if (legacy) return "ＭＳ Ｐゴシック";
		}
		return "IPA Pゴシック";
	}
	private static string mincho(bool legacy) {
		version (Windows) {
			if (legacy) return "ＭＳ 明朝";
		}
		return "IPA明朝";
	}
	private static string uigothic(bool legacy) {
		version (Windows) {
			if (legacy) return "MS UI Gothic";
		}
		return "IPA UIゴシック";
	}
	const CFont textDlgFont(uint defSize) {
		return CFont(gothic(true), defSize <= 0 ? 12 : defSize, false, false);
	}
	const CFont castCardNameFont(bool legacy) {return CFont(uigothic(legacy), 9, true, false);}
	const CFont castCardLevelFont(bool legacy) {return CFont(mincho(legacy), 24, true, true);}
	const CInsets castCardLevelInsets() {return CInsets(2, 8, 0, 0);}
	const CRGB castCardLevelColor() {return CRGB(0, 0, 0, 128);}
	const CPoint castLifeBarPoint() {return CPoint(8, 110);}
	const int statusX() {return 7;}
	const uint statusVerMax() {return 6;}
	const CFont beastNumFont(bool legacy){return CFont(pgothic(legacy), 9, false, false);}

	const CFont menuCardNameFont(bool legacy){return castCardNameFont(legacy);}
	const CFont cardNameFont(bool legacy){return castCardNameFont(legacy);}
	const CFont useCountFont(bool legacy){return CFont(mincho(legacy), 12, true, false);}
	const CPoint useCountPoint(){return CPoint(10, 90);}
	const CRGB recycleNumColor() {return CRGB(255, 255, 0);}
	const CFont summaryLevelFont(bool legacy) {return CFont(mincho(legacy), 10, true, true);}
	const CFont summaryTitleFont(bool legacy) {return CFont(mincho(legacy), 16, true, false);}
	const CFont summaryDescFont(bool legacy) {
		version (Windows) {
			if (legacy) return CFont(mincho(legacy), 10, true, false);
		}
		return CFont(gothic(legacy), 10, true, false);
	}
	const uint summaryDescLineHeightClassic() {
		return 15;
	}
	const CFont summaryPageFont(bool legacy) {return CFont(gothic(legacy), 9, true, false);}
	const CFont cardDescFont(bool legacy) {return CFont(gothic(legacy), 10, false, false);}
	const CFont messageFont(bool legacy) {
		version (Windows) {
			if (legacy) return CFont(mincho(legacy), 16, true, false);
		}
		return CFont(gothic(legacy), 16, false, false);
	}
	const CFont scriptErrorFont(uint defSize) {
		return textDlgFont(defSize);
	}
}

public class CProps {
private:
	cwx.system.System _sys;
	Msgs _msgs;
	Looks _looks;
	string _appPath;
public:
	this(string appPath, cwx.system.System sys) {
		_appPath = appPath;
		_sys = sys;
		_msgs = new Msgs;
		_looks = new Looks;
	}
	const string appPath() {return _appPath;}
	const const(cwx.system.System) sys() {return _sys;}
	const const(Msgs) msgs() {return _msgs;}
	const const(Looks) looks() {return _looks;}
	const string toAppAbs(string path) {
		if (cwx.utils.isabs(path)) return nabs(path);
		return nabs(std.path.join(_appPath, path));
	}
}
