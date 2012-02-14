
module cwx.msgs;

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
import cwx.skin;
import cwx.graphics;

import std.conv;
import std.path;
import std.math;
import std.string;

enum MenuID : int {
	Refresh,
	CEdit,
	Undo,
	Redo,
	Cut,
	Copy,
	Paste,
	Del,
	ToXML,
	New,
	Open,
	Close,
	CloseWin,
	Save,
	SaveAs,
	DataWin,
	FlagWin,
	CardWin,
	CastWin,
	SkillWin,
	ItemWin,
	BeastWin,
	InfoWin,
	DirWin,
	ChangeVH,
	ExecEngine,
	Settings,
	Summary,
	NewArea,
	NewBattle,
	NewPackage,
	NewFlagDir,
	NewFlag,
	NewStep,
	ViewParty,
	ViewMsg,
	Fixed,
	EnemyCardDebugView,
	ViewCards,
	ViewBacks,
	Up,
	Down,
	NewMenuCard,
	NewEnemyCard,
	NewBack,
	Auto,
	Custom,
	Mask,
	DoEscape,
	PosTop,
	PosBottom,
	PosLeft,
	PosRight,
	PosEven,
	ScaleMin,
	ScaleMiddle,
	ScaleMax,
	ScaleEvenBig,
	ScaleEvenSmall,
	NewEventTree,
	NewEventFire,
	TreeOpen,
	TreeClose,
	ShowCardLife,
	ShowCardList,
	ShowCardTable,
	AddScenario,
	NewCast,
	NewSkill,
	NewItem,
	NewBeast,
	NewInfo,
	Add,
	EditHand,
	OpenHand,
	EditUseEvent,
	OpenDirectory,
	ReNumbering,
	ReNumberingAll,
	NewFolder,
	ReplacePath,
	DeleteUnuse,
	ReplaceText,
	Reload,
	StartToPackage,
	ConvertContent,
	Version,
	ToScript,
	ToScriptAll,
	CreateArchive,
	OpenTableView,
	OpenFlagView,
	OpenCardView,
	OpenFileView,
	CopyFilePath,
	OpenEventTreeView,
	WriteComment,
	EditScene,
	EditEvent,
	KeyCodeTimingUse,
	KeyCodeTimingSuccess,
	KeyCodeTimingFailure,
	OpenView,
}

class Msgs {
private:
	version (Windows) {
		static immutable DIR = "フォルダ";
	} else {
		static immutable DIR = "ディレクトリ";
	}
public:
	@property const string application() {return "CWXEditor";}
	@property const string dlgTitVersion() {return "バージョン情報";}
	@property const string appDesc() {return "Scenario editor for CardWirthPy.";}

	@property const string dlgTitUsage() {return "使い方 - CWXEditor";}
	@property const string usage() {
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

	@property const string dlgTitError() {return "エラー - CWXEditor";}
	@property const string dlgTitWarning() {return "警告 - CWXEditor";}
	@property const string dlgTitQuestion() {return "確認 - CWXEditor";}
	@property const string unknownError() {
		version (Windows) {
			static const CWX_EDITOR = "cwxeditor.exe";
		} else {
			static const CWX_EDITOR = "cwxeditor";
		}
		return "処理の途中で" ~ application ~ "の制作者が意図していないエラーが発生しました。"
			~ "データが壊れている可能性を考慮して、シナリオを保存せずに終了する事をお勧めします。\n"
			~ "エラー内容は" ~ CWX_EDITOR ~ "と同じ" ~ DIR ~ "にあるcwxeditor_error.logに記録されます。";
	}
	@property const string shutdown() {return "強制終了";}

	@property const string dlgTextOK() {return "&OK";}
	@property const string dlgTextApply() {return "適用";}
	@property const string dlgTextCancel() {return "キャンセル";}

	@property const string filterAll() {
		return "すべてのファイル (*.*)";
	}

	const string fileCopyError(string path) {return path ~ "のコピー中にエラーが発生しました。";}
	const string reloadError(string path) {return path ~ "の再読込中にエラーが発生しました。";}
	const string loadProgress(string fname, uint max, uint worked) {
		return to!(string)(rndtol(cast(real) worked / max * 100.0)) ~ "% 完了 - " ~ baseName(fname) ~ "を展開中";
	}
	const string loading(string fname) {return fname ~ "の読込みを開始";}
	const string loaded(string sName) {return sName ~ "の読込みを完了";}
	const string loaded(size_t count) {return format("%d件の読込みを完了", count);}
	const string reconstructionStatus(size_t count, size_t max) {return .format("編集状態を復元中 (%d/%d)", count, max);}
	const string cwxPathOpenError(string path) {return "パス [" ~ path ~ "] を開けません。";}
	const string filePathOpenError(string path) {return "パス [" ~ path ~ "] を開けません。";}

	const string loadSkinError(string name) {
		version (Windows) {
			string cwp = "CardWirthPy.exe";
		} else {
			string cwp = "CardWirthPy";
		}
		return "デフォルトのスキン「" ~ name ~ "」が見つかりません。\n" ~ cwp ~ "の場所が正しくないか、Data" ~ DIR ~ "が正しく配置されていない可能性があります。\nこのまま開始すると、一部リソース画像が非表示になります。";
	}
	const string useDefaultSkin(string name, string defSkin) {return "スキン「" ~ name ~ "」が見つかりません。\nデフォルトのスキン「" ~ defSkin ~ "」を使用します。";}
	@property const string scenarioName() {return "シナリオ名";}
	@property const string type() {return "タイプ";}
	@property const string classic() {return "[クラシック]";}
	@property const string newClassicDir() {
		return "シナリオ作成先の選択";
	}
	@property const string newClassicDirDesc() {
		return "シナリオを作成する" ~ DIR ~ "を選択してください。";
	}
	const string notEmptyDir(string dir) {
		return dir ~ "は空ではありません。\n本当にここでシナリオを作成しますか？";
	}

	@property const string newScenarioName() {return "新規シナリオ";}

	@property const string dlgTitSaveBitmapImage() {
		return "格納イメージの保存";
	}
	@property const string filterBitmapImage() {
		return "ビットマップイメージ (*.bmp)";
	}

	const string dlgMsgDelete(string[] files) {
		return files.length == 1
			? baseName(files[0]) ~ "を完全に削除しますか？"
			: to!(string)(files.length) ~ "個の項目を完全に削除しますか？";
	}
	version (Windows) {
		const string dlgMsgDeleteRecycle(string[] files) {
			return files.length == 1
				? baseName(files[0]) ~ "をごみ箱に移動しますか？"
				: to!(string)(files.length) ~ "個の項目をごみ箱に移動しますか？";
		}
	}
	@property const string ttDeleteUnuse() {return "未使用のファイルを削除";}
	@property const string menuDeleteUnuse() {return ttDeleteUnuse ~ "(&U)";}
	const string dlgMsgDeleteUnuse(string[] files) {
		return .format("%d個の未使用ファイルを完全に削除しますか？", files.length);
	}
	const string dlgMsgDeleteRecycleUnuse(string[] files) {
		return .format("%d個の未使用ファイルをごみ箱に移動しますか？", files.length);
	}

	@property const string ttClosePane() {return "閉じる";}
	@property const string menuClosePane() {return ttClosePane ~ "(&C)";}
	@property const string ttClosePaneEtc() {return "他のタブを閉じる";}
	@property const string menuClosePaneEtc() {return ttClosePaneEtc ~ "(&W)";}
	@property const string ttClosePaneLeft() {return "左側のタブを閉じる";}
	@property const string menuClosePaneLeft() {return ttClosePaneLeft ~ "(&L)";}
	@property const string ttClosePaneRight() {return "右側のタブを閉じる";}
	@property const string menuClosePaneRight() {return ttClosePaneRight ~ "(&R)";}
	@property const string ttClosePaneAll() {return "全てのタブを閉じる";}
	@property const string menuClosePaneAll() {return ttClosePaneAll ~ "(&A)";}

	@property const string image() {return "イメージ";}
	@property const string pathDef() {return "[デフォルト]";}
	@property const string imageNone() {return "[イメージ無し]";}
	@property const string fileNone() {return "[ファイルを選択]";}
	@property const string imageIncluding() {return "[イメージ格納]";}
	@property const string seNone() {return "[サウンド無し]";}
	@property const string bgmStop() {return "[BGM停止]";}
	@property const string bgmNone() {return "[BGM無し]";}
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
	@property const string dlgTitDropFiles() {return "素材ファイルの追加";}
	@property const string dlgMsgCopyError() {return "いくつかのファイルのコピーに失敗しました。";}

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

	@property const string dlgTitSettings() {return "CWXEditorの設定";}

	/// メニュー。
	@property const string menuFile() {return "ファイル(&F)";}
	@property const string ttNew() {return "新規作成";}
	@property const string menuNew() {return ttNew ~ "(&N)..." ~ "\tCtrl+N";}
	@property const string ttOpen() {return "開く";}
	@property const string menuOpen() {return ttOpen ~ "(&O)..." ~ "\tCtrl+O";}
	@property const string ttClose() {return "閉じる";}
	@property const string menuClose() {return ttClose ~ "(&C)";}
	@property const string menuCloseWin() {return "閉じる(&C)";}
	@property const string ttSave() {return "上書き保存";}
	@property const string menuSave() {return ttSave ~ "(&S)" ~ "\tCtrl+S";}
	@property const string ttSaveAs() {return "名前を付けて保存";}
	@property const string menuSaveAs() {return ttSaveAs ~ "(&A)...";}
	@property const string ttReload() {return "再読込";}
	@property const string menuReload() {return ttReload ~ "(&R)";}
	@property const string ttOpenDirectory() {
		return DIR ~ "を開く";
	}
	@property const string menuOpenDirectory() {return ttOpenDirectory ~ "(&O)";}
	@property const string ttOpenFilePlace() {
		return "ファイルの場所を開く";
	}
	@property const string menuOpenFilePlace() {return ttOpenFilePlace ~ "(&O)";}
	@property const string ttSaveIncludeImage() {
		return "格納イメージをファイルに保存";
	}
	@property const string ttImageList() {return "画像を一覧表示";}
	@property const string menuImageList() {return ttImageList ~ "(&L)";}

	@property const string ttChangeVH() {return "分割領域の縦横を切替";}
	@property const string menuChangeVH() {return ttChangeVH ~ "(&V)" ~ "";}

	@property const string menuEdit() {return "編集(&E)";}
	@property const string ttReplaceText() {return "検索と置換";}
	@property const string menuReplaceText() {return ttReplaceText ~ "(&F)...\tCtrl+F";}
	@property const string ttCEdit() {return "編集";}
	@property const string menuCEdit() {return ttCEdit ~ "(&E)" ~ "\tEnter";}
	@property const string ttRefresh() {return "最新の情報に更新";}
	@property const string ttRefreshS() {return "更新";}
	@property const string menuRefresh() {return ttRefresh ~ "(&R)" ~ "\tF5";}
	@property const string ttUndo() {return "元に戻す";}
	@property const string menuUndo() {return ttUndo ~ "(&U)" ~ "\tCtrl+Z";}
	@property const string ttRedo() {return "やり直し";}
	@property const string menuRedo() {return ttRedo ~ "(&R)" ~ "\tCtrl+Y";}
	@property const string ttCut() {return "切り取り";}
	@property const string menuCut() {return ttCut ~ "(&T)" ~ "\tCtrl+X";}
	@property const string ttCopy() {return "コピー";}
	@property const string menuCopy() {return ttCopy ~ "(&C)" ~ "\tCtrl+C";}
	@property const string ttPaste() {return "貼り付け";}
	@property const string menuPaste() {return ttPaste ~ "(&P)" ~ "\tCtrl+V";}
	@property const string ttDel() {return "削除";}
	@property const string menuDel() {return ttDel ~ "(&D)" ~ "\tDelete";}
	@property const string ttSelectAll() {return "すべて選択";}
	@property const string menuSelectAll() {return ttSelectAll ~ "(&A)" ~ "\tCtrl+A";}

	@property const string ttToXML() {return "コピーしたデータをXMLに変換";}
	@property const string menuToXML() {return ttToXML ~ "(&X)" ~ "";}

	@property const string menuView() {return "表示(&V)";}
	@property const string ttDataWin() {return "テーブルビュー";}
	@property const string menuDataWin() {return ttDataWin ~ "(&D)";}
	@property const string ttFlagWin() {return "状態変数ビュー";}
	@property const string menuFlagWin() {return ttFlagWin ~ "(&V)";}
	@property const string ttCardWin() {return "カードビュー";}
	@property const string menuCardWin() {return ttCardWin ~ "(&W)";}
	@property const string ttCastWin() {return "キャストカードビュー";}
	@property const string menuCastWin() {return ttCastWin ~ "(&C)";}
	@property const string ttSkillWin() {return "特殊技能カードビュー";}
	@property const string menuSkillWin() {return ttSkillWin ~ "(&S)";}
	@property const string ttItemWin() {return "アイテムカードビュー";}
	@property const string menuItemWin() {return ttItemWin ~ "(&I)";}
	@property const string ttBeastWin() {return "召喚獣カードビュー";}
	@property const string menuBeastWin() {return ttBeastWin ~ "(&B)";}
	@property const string ttInfoWin() {return "情報カードビュー";}
	@property const string menuInfoWin() {return ttInfoWin ~ "(&N)";}
	@property const string ttDirWin() {return "ファイルビュー";}
	@property const string menuDirWin() {return ttDirWin ~ "(&F)";}

	@property const string menuTools() {return "ツール(&T)";}
	@property const string ttExecEngine() {return "エンジン起動";}
	@property const string menuExecEngine() {return ttExecEngine ~ "(&G)";}
	@property const string menuExecEngineAuto() {return "自動選択(&G)\tF9";}
	@property const string ttSettings() {return "エディタ設定";}
	@property const string menuSettings() {return ttSettings ~ "(&O)...";}

	@property const string menuTable() {return "テーブル(&B)";}
	@property const string menuVariable() {return "状態変数(&R)";}

	@property const string menuHelp() {return "ヘルプ(&H)";}
	@property const string ttVersion() {return "バージョン情報";}
	@property const string menuVersion() {return ttVersion ~ "(&A)";}

	@property const string ttLockBar() {return "ツールバーを固定";}
	@property const string menuLockBar() {return ttLockBar ~ "(&L)";}
	@property const string ttResetBar() {return "配置をリセット";}
	@property const string menuResetBar() {return ttResetBar ~ "(&R)";}

	@property const string summary() {return "シナリオの設定";}
	@property const string area() {return "エリア";}
	@property const string battle() {return "バトル";}
	@property const string packages() {return "パッケージ";}

	@property const string dlgTitReplaceText() {return "検索と置換";}
	@property const string replForText() {return "テキスト検索";}
	@property const string replForID() {return "ID検索";}
	@property const string replForPath() {return "素材検索";}
	@property const string replContents() {return "コンテント検索";}
	@property const string replForCoupon() {return "称号・名称一覧";}
	@property const string replForUnuse() {return "未使用検索";}
	@property const string replForError() {return "誤り検索";}

	@property const string searchRange() {return "検索対象";}
	@property const string flagsAndSteps() {return "フラグとステップ";}
	@property const string allCheckRange() {return "全てチェック/全てチェックを外す";}

	@property const string allCheck() {return "全てチェック/全てチェックを外す(&L)";}
	@property const string allSelect() {return "全て選択/全て選択を外す(&L)";}

	@property const string replError() {return "重複する分岐(フラグ分岐が両方ともTRUEになっている等)・条件クーポンに抜けがある台詞コンテント・存在しない素材を参照しているコンテント等を検索します。";}

	@property const string replFrom() {return "検索(置換前)";}
	@property const string replTo() {return "置換後";}

	@property const string replText() {return "検索/置換するテキスト";}
	@property const string replTextTarget() {return "検索/置換対象";}
	@property const string replTextSummary() {return "貼り紙";}
	@property const string replTextMessage() {return "メッセージ";}
	@property const string replTextCardName() {return "カード名";}
	@property const string replTextCardDesc() {return "カード解説";}
	@property const string replTextEventText() {return "イベントテキスト";}
	@property const string replTextStart() {return "スタートコンテント";}
	@property const string replTextFlagAndStep() {return "フラグ/ステップ";}
	@property const string replTextCoupon() {return "クーポン";}
	@property const string replTextGossip() {return "ゴシップ";}
	@property const string replTextEndScenario() {return "終了印";}
	@property const string replTextAreaName() {return "エリア/バトル/パッケージ名";}
	@property const string replTextKeyCode() {return "キーコード";}
	@property const string replTextFile() {return "ファイル";}
	@property const string replTextComment() {return "コメント";}

	@property const string replID() {return "検索/置換対象";}
	@property const string replIDKind() {return "対象";}
	@property const string replIDArea() {return "エリア";}
	@property const string replIDBattle() {return "バトル";}
	@property const string replIDPackage() {return "パッケージ";}
	@property const string replIDCast() {return "キャストカード";}
	@property const string replIDSkill() {return "スキルカード";}
	@property const string replIDItem() {return "アイテムカード";}
	@property const string replIDBeast() {return "召喚獣カード";}
	@property const string replIDInfo() {return "情報カード";}
	@property const string replSetID() {return "[IDを直接指定]";}

	@property const string replPath() {return "検索/置換する素材";}

	@property const string replUnuseTarget() {return "検索対象";}
	@property const string replUnuseFlag() {return "フラグ";}
	@property const string replUnuseStep() {return "ステップ";}
	@property const string replUnuseArea() {return "エリア";}
	@property const string replUnuseBattle() {return "バトル";}
	@property const string replUnusePackage() {return "パッケージ";}
	@property const string replUnuseCast() {return "キャストカード";}
	@property const string replUnuseSkill() {return "スキルカード";}
	@property const string replUnuseItem() {return "アイテムカード";}
	@property const string replUnuseBeast() {return "召喚獣カード";}
	@property const string replUnuseInfo() {return "情報カード";}
	@property const string replUnuseStart() {return "スタートコンテント";}
	@property const string replUnusePath() {return "素材";}

	@property const string replNotIgnoreCase() {return "大文字と小文字を区別する(&C)";}
	@property const string replRegExp() {return "正規表現(&E) (. = 任意1文字, * = 直前の文字の任意数繰返し, $1 = 1つめの文字列グループ ...)";}
	@property const string regexError() {return "正規表現が正しくありません。";}
	@property const string replWildcard() {return "ワイルドカード(&W) (* = 任意文字列, ? = 任意1文字, \\* = *, \\? = ?, \\\\ = \\)";}
	@property const string replCond() {return "検索条件";}
	@property const string search() {return "検索(&F)";}
	@property const string replace() {return "全て置換(&R)";}
	@property const string replaceExit() {return "閉じる";}
	const string searchResult(size_t count, string kind) {
		string r = to!(string)(count) ~ "件の検索結果";
		return kind.length ? r ~ "(" ~ kind ~ ")" : r;
	}
	const string replResult(size_t count, string kind) {
		string r = to!(string)(count) ~ "箇所の置換";
		return kind.length ? r ~ "(" ~ kind ~ ")" : r;
	}
	const string replaceUndo(size_t count) {
		return to!(string)(count) ~ "件を元に戻しました";
	}
	const string replaceRedo(size_t count) {
		return to!(string)(count) ~ "件をやり直しました";
	}
	@property const string ttSearchResultCopy() {return "テキストとしてコピー";}
	@property const string menuSearchResultCopy() {return ttSearchResultCopy ~ "(&C)" ~ "\tCtrl+C";}

	const string searchResultBgImage(in BgImage back) {
		return "背景画像 [" ~ encodePath(back.path) ~ "]";
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
		return name ~ " [" ~ to!(string)(c.id) ~ "." ~ c.name ~ "]";
	}
	const string searchResultFlags(F)(in F f) {
		static if (is(F : Flag)) {
			return "フラグ [" ~ f.path ~ "]";
		} else static if (is(F : Step)) {
			return "ステップ [" ~ f.path ~ "]";
		} else static if (is(F : FlagDir)) {
			return "ディレクトリ [" ~ f.path ~ "]";
		} else static assert (0);
	}
	const string searchResultEventTree(in EventTree evt) {
		return "イベントツリー [" ~ evt.name ~ "]";
	}
	const string searchResultMenuCard(in MenuCard c) {
		return "メニューカード [" ~ c.name ~ "]";
	}
	const string searchResultEnemyCard(in EnemyCard c, in Summary summ) {
		auto card = summ.cwCast(c.id);
		return "エネミーカード [" ~ (card ? card.name : "対象無し") ~ "]";
	}

	@property const string searchErrorNoImage() {return "イメージ指定無し";}
	@property const string searchErrorImageNotFound() {return "イメージファイルが見つからない";}
	@property const string searchErrorBGMNotFound() {return "BGMファイルが見つからない";}
	@property const string searchErrorSENotFound() {return "効果音ファイルが見つからない";}
	@property const string searchErrorStartAreaNotFound() {return "開始エリア無し";}
	@property const string searchErrorFlagNotFound() {return "フラグが見つからない";}
	@property const string searchErrorStepNotFound() {return "ステップが見つからない";}
	@property const string searchErrorNoCast() {return "キャストカード指定無し";}
	@property const string searchErrorNoBeast() {return "召喚獣カード指定無し";}
	@property const string searchErrorDupNextContent() {return "分岐条件の重複";}
	@property const string searchErrorSPFontNotFound() {return "特殊フォントイメージが見つからない";}
	@property const string searchErrorNoRCouponsDialog() {return "最終項目以外にクーポン指定無し項目あり";}
	@property const string searchErrorAreaNotFound() {return "エリアが見つからない";}
	@property const string searchErrorBattleNotFound() {return "バトルが見つからない";}
	@property const string searchErrorPackageNotFound() {return "パッケージが見つからない";}
	@property const string searchErrorCastNotFound() {return "キャストカードが見つからない";}
	@property const string searchErrorSkillNotFound() {return "スキルカードが見つからない";}
	@property const string searchErrorItemNotFound() {return "アイテムカードが見つからない";}
	@property const string searchErrorBeastNotFound() {return "召喚獣カードが見つからない";}
	@property const string searchErrorInfoNotFound() {return "情報カードが見つからない";}
	@property const string searchErrorStartNotFound() {return "スタートコンテントが見つからない";}
	@property const string searchErrorIgnoreWait() {return "後続コンテントが無いため、空白時間が無視される";}
	@property const string searchOpenDialog() {return "検索結果へジャンプする時、ダイアログを開く";}
	@property const string menuOpenView() {return "ビューで開く(&V)";}

	/// イベント設定。
	@property const string ttStartToPackage() {return "このツリーをパッケージ化する";}
	@property const string menuStartToPackage() {return ttStartToPackage ~ "(&P)";}
	@property const string ttConvertContent() {return "変換";}
	@property const string menuConvertContent() {return ttConvertContent ~ "(&R)";}

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
		case CType.PLAY_SOUND: return "効果音再生イベントの設定";
		case CType.PLAY_BGM: return "BGM再生イベントの設定";
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

	@property const string afterClear() {return "シナリオ終了後";}
	@property const string afterClearEndMark() {return "シナリオに済印を付ける";}
	@property const string afterClearNoEndMark() {return "何もしない";}

	@property const string couponName() {return "クーポン名";}
	@property const string couponValue() {return "得点";}
	const string couponValueRange(uint r) {return "(" ~ to!(string)(-(cast(int) r)) ~ "～" ~ to!(string)(r) ~ ")";}
	@property const string range() {return "適用範囲";}
	@property const string gossipName() {return "ゴシップ名";}
	@property const string endName() {return "シナリオ名";}

	@property const string imageMessage() {return "イメージ付きメッセージ";}
	@property const string noImageMessage() {return "イメージ無しメッセージ";}
	@property const string spCharsTitle() {return "特殊文字";}
	@property const string defaultColor() {return "デフォルト(&W)";}
	@property const string red() {return "赤(&R)";}
	@property const string blue() {return "青(&B)";}
	@property const string green() {return "緑(&G)";}
	@property const string yellow() {return "黄(&Y)";}
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
	@property const string scRef() {return "話者(#I)";}
	@property const string scTeam() {return "チーム名(#T)";}
	@property const string scYado() {return "宿屋名(#Y)";}
	@property const string addMsgRefFlag() {return "フラグ参照の追加";}
	@property const string addMsgRefStep() {return "ステップ参照の追加";}
	@property const string createDialog() {return "台詞の作成";}
	@property const string deleteDialog() {return "台詞の削除";}
	@property const string copyToDialogs() {return "台詞を全体にコピー";}
	@property const string copyToUpper() {return "台詞を上方にコピー";}
	@property const string copyToLower() {return "台詞を下方にコピー";}
	@property const string setTalkerCoupon() {return "追加";}
	@property const string messagePreview() {return "プレビュー";}
	@property const string dlgTitMessagePreview() {return "プレビュー";}
	@property const string messageVarKindColumn() {return "状態変数";}
	@property const string messageVarValueColumn() {return "サンプル値";}

	@property const string transition() {return "背景切替方式";}
	const string transitionName(Transition t) {
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
	@property const string transitionSpeed() {return "背景切替ウェイト";}
	@property const string waitName() {return "空白時間(0.1秒単位)";}
	@property const string moneyName() {return "金額";}
	@property const string randomName() {return "確率(%)";}
	@property const string partyNumName() {return "パーティの人数";}
	@property const string judgeTarget() {return "判定対象";}
	@property const string flag() {return "フラグ";}
	@property const string step() {return "ステップ";}
	@property const string flagValue() {return "値";}
	@property const string stepValue() {return "段階";}
	@property const string selectMember() {return "選択対象";}
	@property const string activeMember() {return "動けるメンバから選択";}
	@property const string allMember() {return "パーティ全員から選択";}
	@property const string selectMethod() {return "選択方法";}
	@property const string manualMethod() {return "手動で選択";}
	@property const string randomMethod() {return "ランダムで選択";}
	@property const string judgeSleep() {return "眠り判定";}
	@property const string sleepDisabled() {return "睡眠者無効";}
	@property const string sleepEnabled() {return "睡眠者有効";}
	@property const string selectedLevel() {return "現在選択中のメンバ";}
	@property const string allMemberLevel() {return "パーティ全員の平均値";}
	@property const string judgeLevel() {return "判定レベル";}
	@property const string judgeState() {return "判定状態";}
	@property const string stateHint() {return "ヒント";}
	@property const string cardNumber() {return "枚数";}
	@property const string cardAllDelete() {return "全て削除する";}
	@property const string cardEventRange() {return "適用範囲";}
	@property const string transitionType() {return "背景切替方式";}

	/// イベント。
	@property const string evtArrow() {return "イベント編集";}

	@property const string evtAddContinue() {return "連続で配置";}
	@property const string evtAutoOpen() {return "配置と同時に編集";}

	const string ttEvtGroup(CTypeGroup cGrp) {
		final switch (cGrp) {
		case CTypeGroup.Terminal: return "開始/終端";
		case CTypeGroup.Standard: return "基本";
		case CTypeGroup.Data: return "変数操作/分岐";
		case CTypeGroup.Utility: return "状況分岐";
		case CTypeGroup.Branch: return "保有分岐";
		case CTypeGroup.Get: return "取得";
		case CTypeGroup.Lost: return "喪失";
		case CTypeGroup.Visual: return "外観操作";
		}
	}
	const string menuEvtGroup(CTypeGroup cGrp) {
		string tt = ttEvtGroup(cGrp);
		final switch (cGrp) {
		case CTypeGroup.Terminal: return tt ~ "(&T)";
		case CTypeGroup.Standard: return tt ~ "(&S)";
		case CTypeGroup.Data: return tt ~ "(&D)";
		case CTypeGroup.Utility: return tt ~ "(&U)";
		case CTypeGroup.Branch: return tt ~ "(&B)";
		case CTypeGroup.Get: return tt ~ "(&G)";
		case CTypeGroup.Lost: return tt ~ "(&L)";
		case CTypeGroup.Visual: return tt ~ "(&V)";
		}
	}

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

	@property const string msnGroupVitality() {return "生命力";}
	@property const string msnGroupPhysical() {return "肉体";}
	@property const string msnGroupSkill() {return "技能";}
	@property const string msnGroupMental() {return "精神";}
	@property const string msnGroupMagic() {return "魔法";}
	@property const string msnGroupEnhance() {return "能力";}
	@property const string msnGroupVanish() {return "消滅";}
	@property const string msnGroupCard() {return "カード";}
	@property const string msnGroupBeast() {return "召喚";}

	@property const string msnDelete() {return "効果削除";}

	const string msnDesc(string group, string name) {return group ~ " - " ~ name;}

	const string motionName(MType type) {
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

	const string dialogText(in SDialog dlg) {
		auto rCoupons = dlg.rCoupons;
		if (rCoupons.length > 0) {
			string rBuf = "";
			foreach (i, rc; rCoupons) {
				rBuf ~= rc;
				rBuf ~= i + 1 < rCoupons.length ? " " : ": ";
			}
			auto text = dlg.text;
			return rBuf ~ std.array.replace(text, "\n", "");
		} else {
			auto text = dlg.text;
			return std.array.replace(text, "\n", "");
		}
	}
	const string contentText(in Skin skin, in Content evt, in Summary summ, DialogStatus dlgStat) {
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
			string buf = targetName(evt.targetNS.m);
			buf ~= " レベル" ~ to!(string)(evt.signedLevel);
			buf ~= " " ~ effectType(evt.effectType, evt.resist);
			buf ~= " 成功率" ~ (evt.successRate >= 0 ? "+" : "") ~ to!(string)(evt.successRate);
			buf ~= " " ~ (evt.soundPath.length ? "「" ~ evt.soundPath ~ "」を再生" : "音声無し");
			buf ~= " " ~ cardVisual(evt.cardVisual);
			buf ~= " 効果 = ";
			foreach (i, m; evt.motions) {
				buf ~= "[" ~ motionName(m.type) ~ "]";
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
			auto p = summ.cwPackage(evt.packages);
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
				if (evt.cardPath is null || !evt.cardPath.length) return "カード指定無し";
				auto path = skin.findPath(evt.cardPath, skin.extImage, skin.tableDir, summ.scenarioPath);
				string image;
				if (path.length) {
					image = encodePath(evt.cardPath);
				} else {
					image = "存在しないイメージ(ファイル:" ~ encodePath(evt.cardPath) ~ ")";
				}
				return "[" ~ image ~ "]: " ~ std.array.replace(text, "\n", "");
			default: assert (0);
			}
		} case CType.TALK_DIALOG: {
			assert (evt.dialogs.length);
			final switch (dlgStat) {
			case DialogStatus.Top:
				return dialogText(evt.dialogs[0]);
			case DialogStatus.Under:
				return dialogText(evt.dialogs[$ - 1]);
			case DialogStatus.UnderWithCoupon:
				foreach_reverse (dlg; evt.dialogs) {
					if (dlg.rCoupons.length) {
						return dialogText(dlg);
					}
				}
				assert (0);
			}
		} case CType.PLAY_BGM: {
			if (evt.bgmPath is null || !evt.bgmPath.length) return "BGM停止";
			auto path = skin.findPath(evt.bgmPath, skin.extBgm, skin.bgmDir, summ.scenarioPath);
			if (!path.length) {
				return "存在しないBGM(ファイル:" ~ encodePath(evt.bgmPath) ~ ")";
			}
			return "BGMとして「" ~ encodePath(evt.bgmPath) ~ "」を演奏";
		} case CType.PLAY_SOUND: {
			if (evt.soundPath is null || !evt.soundPath.length) return "効果音指定無し";
			auto path = skin.findPath(evt.soundPath, skin.extSound, skin.seDir, summ.scenarioPath);
			if (!path.length) {
				return "存在しない効果音(ファイル:" ~ encodePath(evt.soundPath) ~ ")";
			}
			return "効果音「" ~ encodePath(evt.soundPath) ~ "」を鳴らす";
		} case CType.WAIT: {
			return "空白時間 = " ~ to!(string)(evt.wait) ~ " × 0.1秒";
		} case CType.ELAPSE_TIME: {
			return "ターン数経過コンテント";
		} case CType.CALL_START: {
			if (evt.start is null || !evt.start.length) return "スタートコンテント指定無し";
			return !evt.tree.hasStart(evt.start) ? .format("存在しないスタートコンテント(名称:%s)", evt.start) : "スタートコンテント「" ~ evt.start ~ "」のコール";
		} case CType.CALL_PACKAGE: {
			if (0 == evt.packages) return "パッケージ指定無し";
			auto p = summ.cwPackage(evt.packages);
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
			string buf = targetName(evt.targetS.m) ~ "の";
			buf ~= physicalName(evt.physical) ~ "と";
			buf ~= mentalName(evt.mental) ~ "で能力判定";
			buf ~= "(レベル" ~ to!(string)(evt.signedLevel) ~ ")";
			return buf;
		} case CType.BRANCH_RANDOM: {
			return "確率 = " ~ to!(string)(evt.percent) ~ "%";
		} case CType.BRANCH_LEVEL: {
			string buf = evt.average ? "パーティ全員" : "選択中のメンバ";
			buf ~= "のレベルが" ~ to!(string)(evt.unsignedLevel) ~ "以上・未満で分岐";
			return buf;
		} case CType.BRANCH_STATUS: {
			string buf = targetName(evt.targetNS.m) ~ "が";
			buf ~= statusName(evt.status) ~ "状態か否かで分岐";
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
			auto c = summ.cwCast(evt.casts);
			return c is null ? .format("存在しないキャストカード(ID:%d)", evt.casts) : "キャストカード「" ~ c.name ~ "」の同行有無で分岐";
		} case CType.BRANCH_ITEM: {
			if (0 == evt.item) return "アイテムカード指定無し";
			auto c = summ.item(evt.item);
			string buf = c is null ? .format("存在しないアイテムカード(ID:%d)", evt.item) : "アイテムカード「" ~ c.name ~ "」";
			buf ~= "の有無で分岐(";
			buf ~= rangeName(evt.range) ~ "に";
			buf ~= to!(string)(evt.cardNumber) ~ "枚)";
			return buf;
		} case CType.BRANCH_SKILL: {
			if (0 == evt.skill) return "特殊技能カード指定無し";
			auto c = summ.skill(evt.skill);
			string buf = c is null ? .format("存在しない特殊技能カード(ID:%d)", evt.skill) : "特殊技能カード「" ~ c.name ~ "」";
			buf ~= "の有無で分岐(";
			buf ~= rangeName(evt.range) ~ "に";
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
			buf ~= rangeName(evt.range) ~ "に";
			buf ~= to!(string)(evt.cardNumber) ~ "枚)";
			return buf;
		} case CType.BRANCH_MONEY: {
			return "分岐金額 = " ~ to!(string)(evt.money) ~ " sp";
		} case CType.BRANCH_COUPON: {
			if (evt.coupon is null || evt.coupon.length == 0) {
				return "指定無し";
			} else {
				return "称号「" ~ evt.coupon ~ "」の有無で分岐(" ~ rangeName(evt.range) ~ ")";
			}
		} case CType.BRANCH_COMPLETE_STAMP: {
			return evt.completeStamp is null || evt.completeStamp.length == 0 ? "指定無し" : "シナリオ「" ~ evt.completeStamp ~ "」が終了済みか否かで分岐";
		} case CType.BRANCH_GOSSIP: {
			return evt.gossip is null || evt.gossip.length == 0 ? "指定無し" : "ゴシップ「" ~ evt.gossip ~ "」の有無で分岐";
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
			auto c = summ.cwCast(evt.casts);
			return c is null ? .format("存在しないキャストカード(ID:%d)", evt.casts) : "キャストカード「" ~ c.name ~ "」を同行させる";
		} case CType.GET_ITEM: {
			if (0 == evt.item) return "アイテムカード指定無し";
			auto c = summ.item(evt.item);
			string buf = c is null ? .format("存在しないアイテムカード(ID:%d)", evt.item) : "アイテムカード「" ~ c.name ~ "」";
			buf ~= "を獲得(";
			buf ~= rangeName(evt.range) ~ "に";
			buf ~= to!(string)(evt.cardNumber) ~ "枚)";
			return buf;
		} case CType.GET_SKILL: {
			if (0 == evt.skill) return "特殊技能カード指定無し";
			auto c = summ.skill(evt.skill);
			string buf = c is null ? .format("存在しない特殊技能カード(ID:%d)", evt.skill) : "特殊技能カード「" ~ c.name ~ "」";
			buf ~= "を獲得(";
			buf ~= rangeName(evt.range) ~ "に";
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
			buf ~= rangeName(evt.range) ~ "に";
			buf ~= to!(string)(evt.cardNumber) ~ "枚)";
			return buf;
		} case CType.GET_MONEY: {
			return "獲得金額 = " ~ to!(string)(evt.money) ~ " sp";
		} case CType.GET_COUPON: {
			if (evt.coupon is null || evt.coupon.length == 0) {
				return "指定無し";
			} else {
				return "称号「" ~ evt.coupon ~ "」を獲得(" ~ rangeName(evt.range) ~ ")";
			}
		} case CType.GET_COMPLETE_STAMP: {
			return evt.completeStamp is null || evt.completeStamp.length == 0 ? "指定無し" : "シナリオ「" ~ evt.completeStamp ~ "」を終了済みにする";
		} case CType.GET_GOSSIP: {
			return evt.gossip is null || evt.gossip.length == 0 ? "指定無し" : "ゴシップ「" ~ evt.gossip ~ "」を獲得";
		} case CType.LOSE_CAST: {
			if (0 == evt.casts) return "キャストカード指定無し";
			auto c = summ.cwCast(evt.casts);
			return c is null ? .format("存在しないキャストカード(ID:%d)", evt.casts) : "キャストカード「" ~ c.name ~ "」の同行を解除";
		} case CType.LOSE_ITEM: {
			if (0 == evt.item) return "アイテムカード指定無し";
			auto c = summ.item(evt.item);
			string buf = c is null ? .format("存在しないアイテムカード(ID:%d)", evt.item) : "アイテムカード「" ~ c.name ~ "」";
			buf ~= "を喪失(";
			buf ~= rangeName(evt.range) ~ "から";
			buf ~= evt.cardNumber == 0 ? "全て" : to!(string)(evt.cardNumber) ~ "枚";
			buf ~= ")";
			return buf;
		} case CType.LOSE_SKILL: {
			if (0 == evt.skill) return "特殊技能カード指定無し";
			auto c = summ.skill(evt.skill);
			string buf = c is null ? .format("存在しない特殊技能カード(ID:%d)", evt.skill) : "特殊技能カード「" ~ c.name ~ "」";
			buf ~= "を喪失(";
			buf ~= rangeName(evt.range) ~ "から";
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
			buf ~= rangeName(evt.range) ~ "から";
			buf ~= evt.cardNumber == 0 ? "全て" : to!(string)(evt.cardNumber) ~ "枚";
			buf ~= ")";
			return buf;
		} case CType.LOSE_MONEY: {
			return "喪失金額 = " ~ to!(string)(evt.money) ~ " sp";
		} case CType.LOSE_COUPON: {
			if (evt.coupon is null || evt.coupon.length == 0) {
				return "指定無し";
			} else {
				return "称号「" ~ evt.coupon ~ "」を喪失(" ~ rangeName(evt.range) ~ ")";
			}
		} case CType.LOSE_COMPLETE_STAMP: {
			return evt.completeStamp is null || evt.completeStamp.length == 0 ? "指定無し" : "シナリオ「" ~ evt.completeStamp ~ "」の終了印を削除";
		} case CType.LOSE_GOSSIP: {
			return evt.gossip is null || evt.gossip.length == 0 ? "指定無し" : "ゴシップ「" ~ evt.gossip ~ "」を喪失";
		} case CType.SHOW_PARTY: {
			return "パーティ表示コンテント";
		} case CType.HIDE_PARTY: {
			return "パーティ隠蔽コンテント";
		} case CType.REDISPLAY: {
			return "画面再構築コンテント";
		} default: assert (0);
		}
	}

	@property const string defaultStartName() {return "イベント開始";}

	/// メインウィンドウ。
	const string mainWindowName(string name, string path, bool changed) {
		if (name && path) {
			string buf;
			if (changed) {
				buf ~= "*";
			}
			return buf ~ name ~ " [ " ~ path ~ " ] - CWXEditor";
		} else {
			return "CWXEditor";
		}
	}
	const string errorExecEngine(string enginePath) {
		return baseName(enginePath) ~ "の起動に失敗しました。";
	}

	/// シナリオ選択ダイアログ
	@property const string dlgTitNewScenario() {return "新規シナリオの作成";}
	const string createError(string path) {return path ~ "でシナリオの作成に失敗しました。";}
	@property const string dlgTitOpenScenario() {return "シナリオを開く";}
	@property const string[] filterScenario() {
		string[] r;
		if (canUncab) {
			r ~= "シナリオファイル (*.wsn;Summary.xml;*.cab;*.zip;Summary.wsm)";
		} else {
			r ~= "シナリオファイル (*.wsn;Summary.xml;*.zip;Summary.wsm)";
		}
		r ~= "エリア・カードファイル (*.xml;*.wid)";
		return r;
	}
	@property const string dlgTitSaveScenario() {return "名前を付けて保存";}
	@property const string filterScenarioSave() {return "XMLシナリオファイル (*.wsn)";}
	const string notScenario(string name) {return name ~ "はシナリオ圧縮ファイルではありません";}
	const string zipError(string name) {return name ~ "の展開に失敗しました。";}
	const string loadError(string name) {return name ~ "の読込みに失敗しました。";}
	const string saveError(string name) {return name ~ "の保存に失敗しました。";}
	@property const string dlgTitUnzip() {return "圧縮ファイルの展開 - CWXEditor";}
	const string unzip(string name) {return name ~ "を展開しています……";}
	const string loadErrorStatus(string name) {return name ~ "の読込みに失敗";}
	const string loadErrorStatus(in string[] name) {
		if (name.length == 1) {
			return loadErrorStatus(name[0]);
		}
		return to!(string)(name.length) ~ "件のシナリオの読込みに失敗";
	}
	const string scenarioNotFound(string fname) {
		return fname ~ "は存在しないか、シナリオではありません。履歴から削除しますか？";
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
	@property const string scenarioView() {return "シナリオビューリスト";}
	@property const string variableView() {return "状態変数インスペクタ";}
	@property const string ttSummary() {return "シナリオの設定";}
	@property const string ttNewArea() {return "エリアの作成";}
	@property const string ttNewBattle() {return "バトルの作成";}
	@property const string ttNewPackage() {return "パッケージの作成";}

	@property const string menuSummary() {return ttSummary ~ "(&S)...";}
	@property const string menuNewArea() {return ttNewArea ~ "(&A)";}
	@property const string menuNewBattle() {return ttNewBattle ~ "(&B)";}
	@property const string menuNewPackage() {return ttNewPackage ~ "(&K)";}

	@property const string ttReNumberingAll() {return "全てのIDを1から振り直す";}
	@property const string menuReNumberingAll() {return ttReNumberingAll ~ "(&A)";}
	@property const string reNumberingAll() {
		return "全てのエリアやカードのIDの1から振り直します。\nよろしいですか？";
	}

	@property const string ttReNumbering() {return "IDの振り直し";}
	@property const string menuReNumbering() {return ttReNumbering ~ "(&N)";}
	@property const string dlgTitReNumbering() {return "IDの振り直し";}
	@property const string reNumbering() {return "IDの振り直し";}
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
	@property const string areaId() {return "ID";}
	@property const string areaName() {return "名称";}
	@property const string areaCount() {return "利用数";}
	@property const string areaNew() {return "新規エリア";}
	@property const string battleNew() {return "新規バトル";}
	@property const string packageNew() {return "新規パッケージ";}
	@property const string ttEditScene() {return "シーンビューを開く";}
	@property const string menuEditScene() {return ttEditScene ~ "(&S)\tF3";}
	@property const string ttEditEvent() {return "イベントビューを開く";}
	@property const string menuEditEvent() {return ttEditEvent ~ "(&E)\tF4";}

	/// フラグのディレクトリ。
	@property const string flagDirRoot() {return "Data";}
	@property const string flagDirNew() {return "新規フォルダ";}
	@property const string ttNewFlagDir() {return "フォルダの作成";}
	@property const string menuNewFlagDir() {return ttNewFlagDir ~ "(&N)...";}
	@property const int menuNewDirA() {return -1;}

	/// フラグ/ステップのテーブル。
	@property const string flagName() {return "名称";}
	@property const string flagInit() {return "初期値";}
	@property const string flagCount() {return "利用数";}
	@property const string ttNewFlag() {return "フラグの作成";}
	@property const string menuNewFlag() {return ttNewFlag ~ "(&F)..." ~ "\tCtrl+L";}
	@property const string ttNewStep() {return "ステップの作成";}
	@property const string menuNewStep() {return ttNewStep ~ "(&S)..." ~ "\tCtrl+P";}

	/// フラグ設定ダイアログ関連。
	@property const string dlgTitFlag() {return "フラグの設定";}
	@property const string dlgLblFlagName() {return "フラグ名";}
	@property const string dlgLblFlagInit() {return "初期値";}
	@property const string dlgLblFlagTrue() {return "TRUE";}
	@property const string dlgLblFlagFalse() {return "FALSE";}

	/// ステップ設定ダイアログ関連。
	@property const string dlgTitStep() {return "ステップの設定";}
	@property const string dlgLblStepName() {return "ステップ名";}
	@property const string dlgLblStepInit() {return "初期値";}
	const string dlgLblStep(uint index) {return dlgTxtStep(index);}
	const string dlgTxtStep(uint index) {
		return "Step - " ~ to!(string)(index);
	}

	/// 貼り紙設定ダイアログ関連。
	const string dlgTitSummary(string sname) {return "概略の設定 - [ " ~ sname ~ " ]";}
	@property const string summaryImage() {return "表示イメージ";}
	@property const string baseData() {return "基本データ";}
	@property const string etcData() {return "詳細データ";}
	const string targetLevelText(uint levL, uint levH) {
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
	@property const string summaryPageDummy() {return "1/1";}
	@property const string title() {return "シナリオタイトル";}
	@property const string author() {return "作者名";}
	@property const string targetLevel() {return "対象レベル";}
	@property const string desc() {return "解説";}
	@property const string levSep() {return "～";}
	@property const string qualification() {return "シナリオ出現条件";}
	@property const string rCouponNum() {return "必要数";}
	@property const string rCoupons() {return "必要とする称号";}
	@property const string startArea() {return "シナリオ開始エリア";}

	@property const string scenarioType() {return "シナリオタイプ";}
	@property const string sTypeXML() {
		return "スキンを指定";
	}
	@property const string sTypeClassic() {
		return "クラシックエンジンを使用";
	}
	const string currentEngineSkin(string lEnginePath) {
		return "[" ~ baseName(lEnginePath) ~ "]";
	}

	/// エリア・戦闘・パッケージウィンドウ。
	@property const string ttUp() {return "上へ";}
	@property const string menuUp() {return ttUp ~ "(&U)" ~ "\tCtrl+Arrow_Up";}
	@property const string ttDown() {return "下へ";}
	@property const string menuDown() {return ttDown ~ "(&D)" ~ "\tCtrl+Arrow_Down";}
	@property const string menuCardsAndBacks() {return "カードと背景" ~ "(&A)";}
	@property const string ttViewParty() {return "パーティカードの表示";}
	@property const string menuViewParty() {return ttViewParty ~ "(&P)";}
	@property const string ttViewMsg() {return "メッセージ枠の表示";}
	@property const string menuViewMsg() {return ttViewMsg ~ "(&M)";}
	@property const string ttFixed() {return "イメージの固定";}
	@property const string menuFixed() {return ttFixed ~ "(&F)";}
	@property const string ttEnemyCardDebugView() {return "レベルとライフを表示";}
	@property const string menuEnemyCardDebugView() {return ttEnemyCardDebugView ~ "(&L)";}
	@property const string ttViewCards() {return "カードの表示";}
	@property const string menuViewCards() {return ttViewCards ~ "(&V)";}
	@property const string ttViewBacks() {return "背景の表示";}
	@property const string menuViewBacks() {return ttViewBacks ~ "(&I)";}
	@property const string ttNewMenuCard() {return "メニューカードの作成";}
	@property const string menuNewMenuCard() {return ttNewMenuCard ~ "(&C)...";}
	@property const string ttNewEnemyCard() {return "エネミーカードの作成";}
	@property const string menuNewEnemyCard() {return ttNewEnemyCard ~ "(&C)...";}
	@property const string ttNewBack() {return "背景の作成";}
	@property const string menuNewBack() {return ttNewBack ~ "(&B)...";}
	@property const string ttAuto() {return "カードを自動的に並べる";}
	@property const string menuAuto() {return ttAuto ~ "(&A)";}
	@property const string ttCustom() {return "カードの位置を自分で決定する";}
	@property const string menuCustom() {return ttCustom ~ "(&U)";}
	@property const string ttMask() {return "透明色を使用";}
	@property const string menuMask() {return ttMask ~ "(&M)";}
	@property const string ttDoEscape() {return "逃走の有無";}
	@property const string menuDoEscape() {return ttMask ~ "(&E)";}
	@property const string noRefArea() {return "[カード配置参照無し]";}
	@property const string areaViewFlagDesc() {return "フラグ";}
	@property const string areaViewRefAreaDesc() {return "参照";}

	@property const string menuPosTop() {return "上に揃える" ~ "(&U)";}
	@property const string menuPosBottom() {return "下に揃える" ~ "(&D)";}
	@property const string menuPosLeft() {return "左に揃える" ~ "(&L)";}
	@property const string menuPosRight() {return "右に揃える" ~ "(&R)";}
	@property const string menuPosEven() {return "等間隔に並べる" ~ "(&E)";}
	@property const string menuScaleMin() {return "最小のカードスケール" ~ "(&S)";}
	@property const string menuScaleMiddle() {return "標準のカードスケール" ~ "(&I)";}
	@property const string menuScaleMax() {return "最大のカードスケール" ~ "(&G)";}
	@property const string menuScaleEvenBig() {return "大きく揃える" ~ "(&L)";}
	@property const string menuScaleEvenSmall() {return "小さく揃える" ~ "(&N)";}

	@property const string left() {return "X";}
	@property const string top() {return "Y";}
	@property const string width() {return "幅";}
	@property const string height() {return "高";}
	@property const string scale() {return "拡大率";}

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
				auto casts = summ.cwCast(enemy.id);
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
	const string areaSceneViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string areaEventViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string battleViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string battleSceneViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string battleEventViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string packageViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string skillViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string itemViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string beastViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	const string areaViewName(ulong id, string name) {return __viewName("エリア", id, name);}
	const string areaSceneViewName(ulong id, string name) {return __viewName("エリア カードと背景", id, name);}
	const string areaEventViewName(ulong id, string name) {return __viewName("エリア イベント", id, name);}
	const string battleViewName(ulong id, string name) {return __viewName("バトル", id, name);}
	const string battleSceneViewName(ulong id, string name) {return __viewName("バトル カードと背景", id, name);}
	const string battleEventViewName(ulong id, string name) {return __viewName("バトル イベント", id, name);}
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
	@property const string cardCount() {return "使用数";}
	const string addCardWindow(string name, string path) {
		return "カードのインポート - [ " ~ name ~ " ] - " ~ path;
	}
	const string addCardTab(string name, string path) {
		return name;
	}

	@property const string cardAndBackView() {return "カードと背景";}
	@property const string enemyCardView() {return "エネミーカード";}
	@property const string menuCards() {return "カード";}
	@property const string enemyCards() {return "カード";}
	@property const string backs() {return "背景";}
	@property const string eventView() {return "イベント";}
	/// カード/背景配置領域関連。
	@property const string dlgTitDropCard() {return "カード画像の追加";}
	const string dlgMsgDropCard(string fname) {
		return "カード画像をシナリオ" ~ DIR ~ "にコピーしますか？\n" ~ fname;
	}
	@property const string dlgTitDropBack() {return "背景画像の追加";}
	const string dlgMsgDropBack(string fname) {
		return "背景画像をシナリオ" ~ DIR ~ "にコピーしますか？\n" ~ fname;
	}

	@property const string refFlag() {return "フラグ参照先";}
	@property const string refStep() {return "ステップ参照先";}
	@property const string noFlag() {return "[参照無し]";}
	@property const string cardPosition() {return "カード位置";}
	@property const string backPosition() {return "位置";}
	@property const string bgImageSettings() {return "簡単設定";}
	@property const string bgImageSettingCustom() {return "[カスタム]";}
	@property const string bgImageSettingOriginal() {return "[元のサイズ]";}
	@property const string enemyCardBase() {return "基本設定";}
	const string dlgTitMenuCard(string name) {return "メニューカードの設定 [ " ~ name ~ " ]";}
	@property const string dlgTitNewMenuCard() {return "メニューカードの作成";}
	@property const string dlgTitBgImage() {return "背景画像の設定";}
	@property const string dlgTitNewBgImage() {return "背景画像の作成";}
	const string dlgTitEnemyCard(string name) {return "エネミーカードの設定 [ " ~ name ~ " ]";}
	@property const string dlgTitNewEnemyCard() {return "エネミーカードの作成";}
	const string stopBGM(string playingFile) {return baseName(playingFile) ~ "の再生を停止";}
	@property const string playBGM() {return "再生";}
	const string menuStopBGM(string playingFile) {return stopBGM(playingFile) ~ "(&P)";}
	@property const string menuPlayBGM() {return playBGM ~ "(&P)";}

	/// イベントビュー。
	@property const string tools() {return "イベントコンテント";}
	@property const string startEnter() {return "到着";}
	@property const string startSelect() {return "クリック";}
	@property const string startDead() {return "死亡";}
	@property const string startVictory() {return "勝利";}
	@property const string startEscape() {return "逃走";}
	@property const string startLose() {return "敗北";}
	@property const string startPackage() {return "パッケージ";}
	@property const string startUse() {return "使用時";}
	const string startRound(uint round) {return "ラウンド = " ~ to!(string)(round);}
	@property const string keyCodeTimingUse() {return "使用";}
	@property const string keyCodeTimingSuccess() {return "成功";}
	@property const string keyCodeTimingFailure() {return "失敗";}
	@property const string menuKeyCodeTiming() {return "キーコード発火タイミング(&K)";}
	@property const string menuKeyCodeTimingUse() {return "使用(&U)";}
	@property const string menuKeyCodeTimingSuccess() {return "成功(&S)";}
	@property const string menuKeyCodeTimingFailure() {return "失敗(&F)";}

	@property const string menuAddManyRounds() {return "複数のラウンドを追加";}
	@property const string manyRounds() {return "追加する発火ラウンドの範囲";}
	@property const string dlgTitAddManyRounds() {return "追加する発火ラウンドの範囲";}
	@property const string roundSep() {return "～";}

	@property const string enterTree() {return "到着";}
	@property const string selectTree() {return "クリック";}
	@property const string deadTree() {return "死亡";}
	@property const string victoryTree() {return "勝利";}
	@property const string escapeTree() {return "逃走";}
	@property const string loseTree() {return "敗北";}
	@property const string packageTree() {return "パッケージイベント";}
	@property const string useTree() {return "使用時イベント";}
	const string keyCodeTree(string keyCode) {return "[" ~ keyCode ~ "]";}
	const string roundTree(uint round) {return "ラウンド" ~ to!(string)(round);}

	@property const string ttNewEventTree() {return "イベントの作成";}
	@property const string ttNewEventFire() {return "イベント発火条件の作成";}
	@property const string ttNewTreeOpen() {return "全コンテントツリーを開く";}
	@property const string ttNewTreeClose() {return "全コンテントツリーを閉じる";}
	@property const string eventTreeKindSystem() {return "システム";}
	@property const string eventTreeKindKeyCode() {return "キーコード";}
	@property const string eventTreeKindRound() {return "ラウンド";}

	@property const string startUseCount() {return "利用数";}

	@property const string evtChildTrue() {return "○";}
	@property const string evtChildFalse() {return "×";}
	@property const string evtChildDefault() {return "Default";}
	@property const string evtChildOK() {return "ＯＫ";}

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
		return targetName(targ) ~ "がレベル" ~ to!(string)(lev) ~ "で"
			~ physicalName(p) ~ "と" ~ mentalName(m) ~ "で行う判定に" ~ (val ? "成功" : "失敗");
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
		return targetName(targ) ~ "での「" ~ statusName(stat) ~ "」" ~ "の判定に"
			~ (val ? "成功" : "失敗");
	}
	const string evtChildBrNum(int num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "パーティに" ~ to!(string)(num) ~ "人" ~  (val ? "以上いる" : "いない");
	}
	const string evtChildBrArea(in Area[] areas, ref string text) {
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
		return rangeName(r) ~ "で「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	const string evtChildBrSkill(in SkillCard c, Range r, uint num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return rangeName(r) ~ "で「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	const string evtChildBrBeast(in BeastCard c, Range r, uint num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return rangeName(r) ~ "で「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
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
		return rangeName(r) ~ "がクーポン「" ~ coupon ~ "」を所有して" ~ (val ? "いる" : "いない");
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
	const string physicalName(Physical p) {
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
	const string mentalName(Mental m) {
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
	const string statusName(Status stat) {
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
	@property const string cardTargetOne() {return "一体";}
	@property const string cardTargetAll() {return "全体";}
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
	@property const string mentality() {
		return "精神状態";
	}
	const string mentalityName(Mentality m) {
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
	@property const string statusActive() {
		return "※ 行動可能 = (健康 | 負傷 | 重傷 | 中毒)";
	}
	@property const string statusInactive() {
		return "※ 行動不可 = (意識不明 | 麻痺/石化 | 呪縛 | 眠り)";
	}
	@property const string statusAlive() {
		return "※ 生存 = (健康 | 負傷 | 重傷 | 中毒 | 呪縛 | 眠り)";
	}
	@property const string statusDead() {
		return "※ 非生存 = (意識不明 | 麻痺/石化)";
	}
	const string targetName(Target targ) {
		return targetName(targ.m);
	}
	const string targetName(Target.M m) {
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
	const string talkerName(Talker talker) {
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
	const string rangeName(Range r) {
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
	const string elementName(Element el) {
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
	@property const string sexUnknown() {return "謎/？";}
	@property const string periodUnknown() {return "不明";}
	@property const string natureUnknown() {return "その他";}

	@property const string ttOpenTableView() {return "テーブルビューで開く";}
	@property const string menuOpenTableView() {return ttOpenTableView ~ "(&V)";}
	@property const string ttOpenFlagView() {return "フラグビューで開く";}
	@property const string menuOpenFlagView() {return ttOpenFlagView ~ "(&V)";}
	@property const string ttOpenCardView() {return "カードビューで開く";}
	@property const string menuOpenCardView() {return ttOpenCardView ~ "(&V)";}
	@property const string ttOpenFileView() {return "ファイルビューで開く";}
	@property const string menuOpenFileView() {return ttOpenFileView ~ "(&V)";}
	@property const string ttOpenEventTreeView() {return "イベントビューで開く";}
	@property const string menuOpenEventTreeView() {return ttOpenEventTreeView ~ "(&V)";}

	@property const string ttWriteComment() {return "コメントを記述";}
	@property const string menuWriteComment() {return ttWriteComment ~ "(&M)\tCtrl+M";}
	@property const string dlgTitComment() {return "コメントの記述";}

	/// カードウィンドウ。
	const string cardTabName(in Summary summ) {
		return "カード";
	}
	const string castTabName(in Summary summ) {
		return "キャスト";
	}
	const string skillTabName(in Summary summ) {
		return "特殊技能";
	}
	const string itemTabName(in Summary summ) {
		return "アイテム";
	}
	const string beastTabName(in Summary summ) {
		return "召喚獣";
	}
	const string infoTabName(in Summary summ) {
		return "情報";
	}
	const string cardWindowName(in Summary summ) {
		if (summ) {
			return "カード - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "カード";
		}
	}
	const string castWindowName(in Summary summ) {
		if (summ) {
			return "キャスト - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "キャスト";
		}
	}
	const string skillWindowName(in Summary summ) {
		if (summ) {
			return "特殊技能 - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "特殊技能";
		}
	}
	const string itemWindowName(in Summary summ) {
		if (summ) {
			return "アイテム - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "アイテム";
		}
	}
	const string beastWindowName(in Summary summ) {
		if (summ) {
			return "召喚獣 - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "召喚獣";
		}
	}
	const string infoWindowName(in Summary summ) {
		if (summ) {
			return "情報 - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "情報";
		}
	}
	@property const string dlgTitAddScenario() {return "インポート元の選択";}

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

	@property const string ttShowCardLife() {return "レベルとライフを表示";}
	@property const string menuShowCardLife() {return ttShowCardLife ~ "(&L)";}
	@property const string ttShowCardList() {return "カード表示";}
	@property const string menuShowCardList() {return ttShowCardList ~ "(&C)";}
	@property const string ttShowCardTable() {return "詳細表示";}
	@property const string menuShowCardTable() {return ttShowCardTable ~ "(&D)";}
	@property const string menuNewCards() {return "カード" ~ "(&C)";}

	@property const string ttAddScenario() {return "外部シナリオから追加";}
	@property const string menuAddScenario() {return ttAddScenario ~ "(&A)...";}
	@property const string ttNewCast() {return "キャストカードの作成";}
	@property const string menuNewCast() {return ttNewCast ~ "(&C)...";}
	@property const string ttNewSkill() {return "スキルカードの作成";}
	@property const string menuNewSkill() {return ttNewSkill ~ "(&S)...";}
	@property const string ttNewItem() {return "アイテムカードの作成";}
	@property const string menuNewItem() {return ttNewItem ~ "(&I)...";}
	@property const string ttNewBeast() {return "召喚獣カードの作成";}
	@property const string menuNewBeast() {return ttNewBeast ~ "(&B)...";}
	@property const string ttNewInfo() {return "情報カードの作成";}
	@property const string menuNewInfo() {return ttNewInfo ~ "(&F)...";}

	@property const string ttAdd() {return "シナリオに追加";}
	@property const string menuAdd() {return ttAdd ~ "(&A)" ~ "\tCtrl+P";}

	@property const string menuEditHand() {return "所有カードの設定" ~ "(&H)";}
	@property const string menuOpenHand() {return "所有カード" ~ "(&H)";}
	@property const string menuEditUseEvent() {return "使用時イベントの設定" ~ "(&E)";}

	@property const string casts() {return "キャスト";}
	@property const string skill() {return "スキル";}
	@property const string item() {return "アイテム";}
	@property const string beast() {return "召喚獣";}
	@property const string info() {return "情報";}

	@property const string cardId() {return "ID";}
	@property const string cardName() {return "名称";}
	@property const string cardDesc() {return "説明";}

	@property const string dlgTitNewCast() {return "キャストカードの作成";}
	@property const string dlgTitNewSkill() {return "特殊技能カードの作成";}
	@property const string dlgTitNewItem() {return "アイテムカードの作成";}
	@property const string dlgTitNewBeast() {return "召喚獣カードの作成";}
	@property const string dlgTitNewInfo() {return "情報カードの作成";}
	const string dlgTitCast(string name) {return "キャストカードの設定 [ " ~ name ~ " ]";}
	const string dlgTitSkill(string name) {return "特殊技能カードの設定 [ " ~ name ~ " ]";}
	const string dlgTitItem(string name) {return "アイテムカードの設定 [ " ~ name ~ " ]";}
	const string dlgTitBeast(string name) {return "召喚獣カードの設定 [ " ~ name ~ " ]";}
	const string dlgTitInfo(string name) {return "情報カードの設定 [ " ~ name ~ " ]";}

	@property const string name() {return "名前";}
	const string nameLimit(uint limit) {return "(" ~ to!(string)(limit / 2) ~ "文字まで)";}
	@property const string level() {return "レベル";}
	@property const string life() {return "体力";}
	@property const string lifeCalc() {return "標準値";}
	@property const string history() {return "経歴";}
	@property const string coupons() {return "経歴";}
	@property const string addCoupon() {return "新規クーポンの追加";}
	@property const string altCoupon() {return "クーポンの上書き";}
	@property const string delCoupon() {return "クーポンの削除";}
	@property const string sex() {return "性別";}
	@property const string period() {return "年代";}
	@property const string race() {return "種族";}
	@property const string noRace() {return "[未指定]";}
	const string raceCoupon(Race race) {return "＠Ｒ" ~ race.name;}
	@property const string nature() {return "素質";}
	@property const string makings() {return "特徴";}
	@property const string tolerant() {return "対属性";}
	@property const string tolerantBase() {return "対カード属性";}
	@property const string tolerantElement() {return "対効果属性";}
	@property const string resistWeapon() {return "武器が効かない";}
	@property const string resistMagic() {return "魔法が効かない";}
	@property const string undead() {return "命を持たない";}
	@property const string automaton() {return "心を持たない";}
	@property const string unholy() {return "不浄な存在";}
	@property const string constructure() {return "魔法生物";}
	const string resistName(Element e) {return elementName(e) ~ "に耐性を持つ";}
	const string weaknessName(Element e) {return elementName(e) ~ "に弱い";}
	@property const string descResistWeapon() {return "(物理属性のカードが無効)";}
	@property const string descResistMagic() {return "(魔法属性のカードが無効)";}
	@property const string descUndead() {return "(肉体属性の効果が無効)";}
	@property const string descAutomaton() {return "(精神属性の効果が無効)";}
	@property const string descUnholy() {return "(神聖属性の効果に影響)";}
	@property const string descConstructure() {return "(魔力属性の効果に影響)";}
	const string descResist(Element e) {return "(" ~ elementName(e) ~ "属性の効果が無効)";}
	const string descWeakness(Element e) {return "(" ~ elementName(e) ~ "属性の効果に影響)";}
	@property const string basicResist() {return "標準値";}
	@property const string physicalParams() {return "身体能力";}
	@property const string physicalCalc() {return "標準値";}
	@property const string mentalParams() {return "精神傾向";}
	@property const string mentalCalc() {return "標準値";}
	@property const string castEnhance() {return "能力修正";}
	@property const string basicEnhance() {return "標準値";}

	@property const string liveStatus() {return "初期状態";}
	@property const string lifeAndMentality() {return "体力と精神状態";}
	@property const string enhanceLiveBonus() {return "能力ボーナス/ペナルティ";}
	const string enhanceLiveBonusName(Enhance enh) {
		switch (enh) {
		case Enhance.ACTION: return "行動";
		case Enhance.AVOID: return "回避";
		case Enhance.RESIST: return "抵抗";
		case Enhance.DEFENSE: return "防御";
		default: assert (0);
		}
	}
	@property const string useMax() {return "最大値を使用";}
	@property const string status() {return "異常状態";}
	@property const string paralyze() {return "麻痺/石化";}
	@property const string poison() {return "中毒";}
	@property const string bind() {return "呪縛";}
	@property const string silence() {return "沈黙";}
	@property const string faceUp() {return "暴露";}
	@property const string antiMagic() {return "魔法無効";}
	@property const string unitValue() {return "点";}
	@property const string unitRound() {return "ラウンド";}
	@property const string resetLiveStatus() {return "通常状態に戻す";}

	@property const string needSpellGroup() {return "発声による発動";}
	@property const string needSpell() {return "沈黙時に使用不可";}
	@property const string elementProps() {return "効果属性";}
	@property const string resistProps() {return "抵抗属性";}
	@property const string aptPhysical() {return "身体的要素";}
	@property const string aptMental() {return "精神的要素";}
	@property const string skillLevel() {return "技能レベル";}
	@property const string useCountGroup() {return "使用可能回数";}
	const string useCountRange(uint max) {return "(0～" ~ to!(string)(max) ~ " : 0 = ∞)";}
	@property const string price() {return "価格";}
	@property const string priceAuto() {return "(参考用)";}
	@property const string useModify() {return "使用時 能力値修正";}
	@property const string haveModify() {return "所有時 能力値修正";}
	@property const string motionKind() {return "効果種別";}
	@property const string motionElement() {return "属性";}
	@property const string motionDamageType() {return "タイプ";}
	@property const string motionValue() {return "値";}
	@property const string motionBeast() {return "召喚するカード";}
	@property const string beastNone() {return "召喚獣無し";}
	@property const string setBeast() {return "選択";}
	@property const string motionRound() {return "継続時間 (ラウンド数)";}
	@property const string motionEnhValue() {return "変化値";}
	@property const string effectTarget() {return "効果目標";}
	@property const string effectRange() {return "効果範囲";}
	@property const string effectVisual() {return "視覚効果";}
	@property const string cardPremium() {return "カードの価値";}
	@property const string successRate() {return "成功率修正値";}
	@property const string allFail() {return "絶対失敗\n(-5)";}
	@property const string allSuccess() {return "絶対成功\n(+5)";}
	@property const string se() {return "効果音";}
	@property const string se1() {return "初期効果";}
	@property const string se2() {return "二次効果";}
	@property const string soundNone() {return "[効果音無し]";}
	@property const string stopSound() {return "停止";}
	@property const string playSound() {return "再生";}
	@property const string menuStopSound() {return stopSound ~ "(&S)";}
	@property const string menuPlaySound() {return playSound ~ "(&P)";}
	@property const string keyCodes() {return "イベント発火のキーコード";}

	@property const string warningEffectTypeNone() {
		return "無属性のカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。";
	}
	@property const string warningVanishCast() {
		return "神聖属性以外の対象消去効果を持つカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。";
	}
	const string warningNameLenOver(uint limit) {
		return "名前の長さが" ~ to!string(limit / 2) ~ "文字を超えています。メッセージにカード名が表示された際に不具合が発生する可能性があります。";
	}

	@property const string card() {return "カード";}
	@property const string apt() {return "要素";}
	@property const string useCountAndDesc() {return "使用回数/解説";}
	@property const string levelAndDesc() {return "レベル/解説";}
	@property const string useBonus() {return "使用ボーナス";}
	@property const string haveBonus() {return "所持ボーナス";}
	@property const string motion() {return "効果";}
	@property const string cardProps() {return "属性";}
	@property const string settings() {return "設定";}
	@property const string seAndKeyCode() {return "効果音/キーコード";}

	const string rangeHint(int min, int max) {
		return "(" ~ to!(string)(min) ~ "～" ~ to!(string)(max) ~ ")";
	}
	@property const string source() {return "出典";}
	@property const string sourceScenario() {return "シナリオ名";}
	@property const string sourceAuthor() {return "シナリオ作者";}
	@property const string resetSource() {return "現在のシナリオを出典に設定";}
	@property const string diffSource() {return "出典のシナリオ名と作者名が現在のシナリオと異なるため、使用時イベントは実行されません。";}

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
	@property const string fileName() {return "ファイル名";}
	@property const string fileExt() {return "拡張子";}
	@property const string fileCount() {return "使用数";}
	const string errorExec(string appName) {return appName ~ "の起動に失敗しました。";}
	@property const string ttNewFolder() {return "新規" ~ DIR;}
	@property const string menuNewFolder() {return ttNewFolder ~ "(&I)";}
	@property const string newFolder() {return ttNewFolder;}
	@property const string ttCopyFilePath() {return "素材のパスをコピー";}
	@property const string menuCopyFilePath() {return ttCopyFilePath ~ "(&M)";}
	@property const string ttReplacePath() {return "素材の差替え";}
	@property const string menuReplacePath() {return ttReplacePath ~ "(&R)...";}
	@property const string ttCreateArchive() {return "シナリオを圧縮";}
	@property const string menuCreateArchive() {return ttCreateArchive ~ "(&A)...";}
	@property const string[] filterArchive() {
		string[] r;
		r ~= "ZIP アーカイブ (*.zip)";
		if (canUncab) {
			r ~= "CAB アーカイブ (*.cab)";
		}
		r ~= "シナリオファイル (*.wsn)";
		return r;
	}
	@property const string dlgTitCreateArchive() {return "シナリオの圧縮";}
	@property const string failedCreateArchive() {return "シナリオの圧縮に失敗";}
	const string dlgMsgIsSaveBeforeCreateArchive(string name) {return "「" ~ name ~ "」は変更されています。保存しますか？";}

	/// エディタ設定ダイアログ。
	@property const string baseSettings() {return "基本設定";}
	@property const string reference() {return "...";}
	const string enginePath(string appName) {return appName ~ "の場所";}
	@property const string enginePathAtten() {return "※ クラシックなシナリオのみに使用する場合は空欄にしてください";}
	const string dlgTitEnginePath(string appName) {return appName ~ "の場所";}
	@property const string tempDir() {return "シナリオの一時展開先";}
	@property const string tempDirDesc() {return "wsn圧縮されたシナリオの一時的な展開先を選択してください。";}
	@property const string backupDir() {return "自動バックアップ";}
	@property const string backupEnabled() {return "自動バックアップを行う";}
	@property const string backupPath() {return "保存先";}
	@property const string backupDirDesc() {return "シナリオを定期的に自動バックアップする" ~ DIR ~ "を選択してください。";}
	@property const string backupInterval() {return "保存間隔";}
	@property const string minute() {return "分";}
	@property const string backupCount() {return "最大保存数";}
	@property const string skin() {return "スキン";}
	@property const string scenarioAuthor() {return "シナリオ作者(新規作成時に自動設定されます)";}
	@property const string historiesSettings() {return "履歴";}
	@property const string openHistoryMax() {return "シナリオ履歴保存件数";}
	@property const string openHistoryClear() {return "クリア";}
	@property const string dlgMsgHistoryClear() {return "シナリオ履歴を削除してよろしいですか？";}
	@property const string searchHistoryMax() {return "検索/置換履歴保存件数";}
	@property const string searchHistoryClear() {return "クリア";}
	@property const string dlgMsgSearchHistoryClear() {return "検索/置換履歴を削除してよろしいですか？";}
	@property const string ignorePaths() {return "無視ファイル(改行区切り)";}
	@property const string etcSettings() {return "その他";}
	@property const string etcSettingsTitle() {return "詳細";}
	@property const string singleWindow() {return "シングルウィンドウモード(再起動後に反映されます)";}
	@property const string smoothingCard() {return "カードのサイズ変更時にスムージングを行う";}
	@property const string showImagePreview() {return "カードや背景のプレビュー表示を行う";}
	@property const string expandXMLs() {return "圧縮されたシナリオの読込み時にXMLファイルを展開する";}
	@property const string contentsFloat() {return "コンテンツボックスを別ウィンドウで表示する";}
	@property const string contentsAutoHide() {return "コンテンツボックスを自動的に隠す";}
	@property const string xmlCopy() {return "コピーや切り取りを常にXML形式で行う";}
	@property const string saveInnerImagePath() {return "クラシックなシナリオで格納イメージにファイルパスを埋め込む";}
	@property const string traceDirectories() {
		return "ファイル・" ~ DIR ~ "の変更を自動的に追跡する";
	}
	@property const string logicalSort() {return "数値参照型ソートを行う(1, 10, 2, 3, ... → 1, 2, 3, 10, ...)";}
	@property const string copyDesc() {return "カードをエリアに貼り付け・ドロップした時、解説もコピーする";}
	@property const string refCardsAtEditBgImage() {return "背景変更コンテントの編集を開始する際、最初からカード配置の参照を行う";}
	@property const string addNewClassicEngine() {return "未知のクラシックエンジンを見つけたら記憶する";}
	@property const string doubleIO() {return "分割読込・保存を行う(デュアルコア以上の環境で高速化)";}
	@property const string switchTabWheel() {return "マウスホイールでタブ切替を行う";}
	@property const string openTabAtRightOfCurrentTab() {return "新しいタブを現在のタブの直後に開く";}
	@property const string reconstruction() {return "シナリオごとにタブの配置を記憶する";}
	@property const string openLastScenario() {return "終了時に開いていたシナリオを次の起動時に開く";}
	@property const string soundPlayType() {return "音声再生方法";}
	@property const string soundPlayTypeDef() {return "自動選択";}
	@property const string soundPlayTypeSDL() {return "SDL(CardWirthPy形式)";}
	version (Windows) {
		@property const string soundPlayTypeMCI() {return "MCI(CardWirth形式)";}
	}
	@property const string soundPlayTypeApp() {return "関連付けされたアプリケーションで開く";}

	@property const string wallpaper() {
		return "エディタの壁紙";
	}
	@property const string filterWallpaper() {
		return "画像ファイル (*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.ico;*.icon)";
	}
	@property const string dlgTitWallpaper() {return "壁紙画像の選択";}
	@property const string wallpaperStyle() {
		return "表示形式";
	}
	const string wallpaperStyleName(WallpaperStyle s) {
		final switch (s) {
		case WallpaperStyle.Center:
			return "中央に表示";
		case WallpaperStyle.Tile:
			return "並べて表示";
		case WallpaperStyle.ExpandFull:
			return "拡大して表示";
		case WallpaperStyle.Expand:
			return "はみ出さないように拡大";
		}
	}

	@property const string bgImageAndKeyCode() {return "背景とキーコード";}
	@property const string newBgImageSetting() {return "新規作成";}
	@property const string altBgImageSetting() {return "上書き";}
	@property const string delBgImageSetting() {return "削除";}
	@property const string standardKeyCode() {return "標準のキーコード";}

	const string errorEnginePath(string appName) {return appName ~ "の場所が正しくありません。";}
	@property const string errorTempPath() {return "一時展開先が正しくありません。";}
	@property const string errorBackupPath() {return "自動バックアップ先が正しくありません。";}

	@property const string outerTools() {return "外部ツール";}
	@property const string outerToolsTitle() {return "外部ツールの設定";}
	@property const string outerToolName() {return "外部ツール名";}
	@property const string outerToolCommand() {return "コマンド";}
	@property const string dlgTitOuterTool() {return "外部ツールの選択";}
	@property const string toolsHint1() {return "$F = ファイル名";}
	@property const string toolsHint3() {return "$$ = $";}
	@property const string outerToolWorkDir() {return "作業" ~ DIR;}
	@property const string toolWorkDir() {return "作業" ~ DIR ~ "の選択";}
	@property const string toolWorkDirDesc() {return "外部ツールの作業" ~ DIR ~ "を選択してください。";}
	@property const string toolsHint2() {return "$S = シナリオの" ~ DIR;}
	version (Windows) {
		@property const string[] toolTName() {return ["実行ファイル (*.exe)", "すべてのファイル (*.*)"];}
	} else {
		@property const string[] toolTName() {return ["すべてのファイル (*.*)"];}
	}
	@property const string newOuterTool() {return "新規作成";}
	@property const string altOuterTool() {return "上書き";}
	@property const string delOuterTool() {return "削除";}

	@property const string classicEngines() {return "クラシックエンジン";}
	@property const string classicEnginesTitle() {return "クラシックエンジンの設定";}
	@property const string classicEngineName() {return "エンジン名";}
	@property const string classicEnginePath() {return "実行ファイルパス";}
	@property const string classicEngineDataDirName() {return "データフォルダ";}
	@property const string classicEngineDataDirNameDesc() {return "クラシックエンジンのデータフォルダを選択してください。";}
	@property const string classicEngineExecute() {return "代替実行ファイル";}
	@property const string classicEngineHint1() {return "※ 代替実行ファイルを指定すると、エンジン本体の代わりに実行されます";}
	version (Windows) {
		@property const string[] classicEnginePathTName() {return ["実行ファイル (*.exe)", "すべてのファイル (*.*)"];}
	} else {
		@property const string[] classicEnginePathTName() {return ["すべてのファイル (*.*)"];}
	}
	@property const string dlgTitClassicEnginePath() {return "クラシックエンジンの選択";}
	version (Windows) {
		@property const string[] classicEngineExecuteTName() {return ["実行ファイル (*.exe)", "すべてのファイル (*.*)"];}
	} else {
		@property const string[] classicEngineExecuteTName() {return ["すべてのファイル (*.*)"];}
	}
	@property const string dlgTitClassicEngineExecute() {return "代替実行ファイルの選択";}
	@property const string newClassicEngine() {return "新規作成";}
	@property const string altClassicEngine() {return "上書き";}
	@property const string delClassicEngine() {return "削除";}

	@property const string bgImagesDefault() {return "デフォルト背景";}
	@property const string setBgImagesDefault() {return "デフォルト背景の設定...";}
	@property const string dlgTitBgImagesDefault() {return "デフォルト背景の設定";}

	@property const string systemSounds() {return "システム音声";}
	@property const string soundSaved() {return "保存完了";}
	const string playableSounds(string exts) {return "サウンドファイル (" ~ exts ~ ")";}
	@property const string dlgTitSystemSound() {return "システム音声の選択";}

	@property const string undoMax() {return "「元に戻す」回数";}
	@property const string undoMaxMainView() {return "エリア/カード/フラグ";}
	@property const string undoMaxEvent() {return "メニュー/エネミー/背景/イベント";}
	@property const string undoMaxReplace() {return "置換";}
	@property const string undoMaxEtc() {return "テキスト/その他";}

	@property const string dialogStatus() {return "台詞コンテントのステータス";}
	const string dialogStatusName(DialogStatus dlgStat) {
		final switch (dlgStat) {
		case DialogStatus.Top: return "最上位の台詞";
		case DialogStatus.Under: return "最下位の台詞";
		case DialogStatus.UnderWithCoupon: return "最下位の台詞(条件クーポン設定あり)";
		}
	}

	/// スクリプト関係。
	@property const string ttToScript() {return "スクリプトに変換してコピー";}
	@property const string menuToScript() {return ttToScript ~ "(&S)\tCtrl+G";}
	@property const string ttToScriptAll() {return "全てをスクリプトに変換してコピー";}
	@property const string menuToScriptAll() {return ttToScriptAll ~ "(&P)\tCtrl+B";}
	@property const string dlgTitScriptError() {
		return "CWXスクリプトエラー";
	}
	@property const string scriptError() {
		return "CWXスクリプトのコンパイル中にエラーが発生しました。";
	}
	@property const string scriptErrorOver100Error() {return "エラーが100件を超えたため、スクリプトの解析を終了します。";}
	@property const string scriptErrorInvalidToken() {return "スクリプトに使用できない文字が含まれています。";}
	@property const string scriptErrorInvalidString() {return "ここに文字列が必要です。";}
	@property const string scriptErrorUnCloseString() {return "文字列が閉じられていません。";}
	@property const string scriptErrorUnOpenComment() {return "コメントは開始されていません。";}
	@property const string scriptErrorUnCloseComment() {return "コメントが閉じられていません。";}
	@property const string scriptErrorInvalidNumber() {return "数値が正しくありません。";}
	@property const string scriptErrorCloseBracketNotFound() {return "閉じ括弧が見つかりません。";}
	@property const string scriptErrorCloseParenNotFound() {return "閉じ括弧が見つかりません。";}
	@property const string scriptErrorZeroDivision() {return "0で除算を行いました。";}
	@property const string scriptErrorInvalidAttr() {return "属性が正しくありません。";}
	@property const string scriptErrorInvalidVar() {return "変数が正しくありません。";}
	@property const string scriptErrorInvalidVarVal() {return "変数の値が正しくありません。";}
	@property const string scriptErrorNoStartText() {return "スタートコンテントの名前がありません。";}
	@property const string scriptErrorInvalidStatement() {return "文が正しくありません。";}
	@property const string scriptErrorInvalidBranch() {return "分岐の構成が正しくありません。";}
	@property const string scriptErrorNoIfText() {return "ifの条件が見つかりません。";}
	@property const string scriptErrorNoIfContents() {return "分岐先のコンテントが見つかりません。";}
	@property const string scriptErrorInvalidKeyword() {return "未知のキーワードです。";}
	@property const string scriptErrorInvalidValuesOpen() {return "パラメータ列ではありません。";}
	@property const string scriptErrorInvalidValuesClose() {return "閉じ括弧が見つかりません。";}
	@property const string scriptErrorNoVarSet() {return "変数に値をセットしていません。";}
	@property const string scriptErrorNoVarVal() {return "変数の値がありません。";}
	@property const string scriptErrorInvalidCalc() {return "計算式が不正です。";}
	@property const string scriptErrorInvalidBoolVal() {return "キーワードが正しくありません。";}
	@property const string scriptErrorInvalidTransition() {return "未知の画面切替方式です。";}
	@property const string scriptErrorInvalidRange() {return "未知の範囲です。";}
	@property const string scriptErrorInvalidStatus() {return "未知のステータスです。";}
	@property const string scriptErrorInvalidTarget() {return "未知のターゲットです。";}
	@property const string scriptErrorInvalidEffectType() {return "未知の効果属性です。";}
	@property const string scriptErrorInvalidResist() {return "未知の命中属性です。";}
	@property const string scriptErrorInvalidCardVisual() {return "未知の視覚効果です。";}
	@property const string scriptErrorInvalidMental() {return "未知の精神要素です。";}
	@property const string scriptErrorInvalidPhysical() {return "未知の肉体要素です。";}
	@property const string scriptErrorInvalidMotionType() {return "未知の効果タイプです。";}
	@property const string scriptErrorInvalidMotion() {return "効果が正しくありません。";}
	@property const string scriptErrorInvalidElement() {return "未知の属性です。";}
	@property const string scriptErrorInvalidDamageType() {return "未知のダメージタイプです。";}
	@property const string scriptErrorInvalidBgImage() {return "背景画像が正しくありません。";}
	@property const string scriptErrorInvalidDialog() {return "台詞が正しくありません。";}
	@property const string scriptErrorInvalidTalker() {return "話者が正しくありません。";}
	@property const string scriptErrorUndefinedSymbol() {return "未知のシンボルです。";}
	@property const string scriptErrorStartsMixedContent() {return "スタートコンテントの中に他のコンテントが混入しています。";}
	@property const string scriptErrorContentsMixedStart() {return "ここにスタートコンテントが現れる事はできません。";}
	@property const string scriptErrorInvalidCommand() {return "命令が正しくありません。";}
	@property const string scriptErrorCanNotHaveContent() {return "このコンテントが後続コンテントを持つ事はできません。";}
	@property const string scriptErrorInvalidStr() {return "文字列が正しくありません。";}
	@property const string scriptErrorReqNumber() {return "ここに数値が必要です。";}
	@property const string scriptErrorReqID() {return "ここにIDが必要です。";}
	@property const string scriptErrorUndefinedVar() {return "存在しない変数です。";}
	@property const string scriptErrorInvalidValue() {return "値が正しくありません。";}
	@property const string scriptErrorCommaNotFound() {return "パラメータの区切りにカンマがありません。";}
}
