
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

import std.path;
import std.math;
import std.string;

version (Windows) {
	static const DIR = "フォルダ";
} else {
	static const DIR = "ディレクトリ";
}

class Msgs {
public:
	string application() {return "CWXEditor";}
	string dlgTitVersion() {return "バージョン情報";}
	string appDesc() {return "Scenario editor for CardWirthPy.";}
	string appVersion() {return splitlines(import("@version.txt"))[0];}
	string appWebSiteURI() {return splitlines(import("@version.txt"))[1];}
	string appBuild() {
		string buf = "Build: " ~ __TIMESTAMP__ ~ " ";
		debug {
			buf ~= "Debug";
		} else {
			buf ~= "Release";
		}
		return buf;
	}

	string dlgTitError() {return "エラー - CWXEditor";}
	string dlgTitWarning() {return "警告 - CWXEditor";}
	string dlgTitQuestion() {return "確認 - CWXEditor";}
	string unknownError() {
		version (Windows) {
			static const CWX_EDITOR = "cwxeditor.exe";
		} else {
			static const CWX_EDITOR = "cwxeditor";
		}
		return "処理の途中で" ~ application ~ "の制作者が意図していないエラーが発生しました。"
			~ "データが壊れている可能性を考慮して、シナリオを保存せずに終了する事をお勧めします。\n"
			~ "エラー内容は" ~ CWX_EDITOR ~ "と同じ" ~ DIR ~ "にあるcwxeditor_error.logに記録されます。";
	}

	string dlgTextOK() {return "&OK";}
	string dlgTextApply() {return "適用";}
	string dlgTextCancel() {return "キャンセル";}

	string fileCopyError(string path) {return path ~ "のコピー中にエラーが発生しました。";}
	string reloadError(string path) {return path ~ "の再読込中にエラーが発生しました。";}
	string loadProgress(string fname, uint max, uint worked) {
		return to!(string)(rndtol(cast(real) worked / max * 100.0)) ~ "% 完了 - " ~ getBaseName(fname) ~ "を展開中";
	}
	string loading(string fname) {return fname ~ "の読込みを開始";}
	string loaded(string sName) {return sName ~ "の読込みを完了";}
	string loaded(size_t count) {return format("%d件の読込みを完了", count);}
	string cwxPathOpenError(string path) {return "パス [" ~ path ~ "] を開けません。";}
	string filePathOpenError(string path) {return "パス [" ~ path ~ "] を開けません。";}

	string loadSkinError(string name) {return "デフォルトのスキン「" ~ name ~ "」が見つかりません。\n一部リソース画像が非表示になります。";}
	string useDefaultSkin(string name, string defSkin) {return "スキン「" ~ name ~ "」が見つかりません。\nデフォルトのスキン「" ~ defSkin ~ "」を使用します。";}
	string scenarioName() {return "シナリオ名";}
	string type() {return "タイプ";}
	string classic() {return "[クラシック]";}
	string newClassicDir() {
		return "シナリオ作成先の選択";
	}
	string newClassicDirDesc() {
		return "シナリオを作成する" ~ DIR ~ "を選択してください。";
	}
	string notEmptyDir(string dir) {
		return dir ~ "は空ではありません。\n本当にここでシナリオを作成しますか？";
	}

	string newScenarioName() {return "新規シナリオ";}

	string dlgTitSaveBitmapImage() {
		return "格納イメージの保存";
	}
	string filterBitmapImage() {
		return "ビットマップイメージ (*.bmp)";
	}

	string dlgMsgDelete(string[] files) {
		return files.length == 1
			? getBaseName(files[0]) ~ "を完全に削除しますか？"
			: to!(string)(files.length) ~ "個の項目を完全に削除しますか？";
	}
	version (Windows) {
		string dlgMsgDeleteRecycle(string[] files) {
			return files.length == 1
				? getBaseName(files[0]) ~ "をごみ箱に移動しますか？"
				: to!(string)(files.length) ~ "個の項目をごみ箱に移動しますか？";
		}
	}

	string ttClosePane() {return "閉じる";}
	string menuClosePane() {return ttClosePane ~ "(&C)";}
	string ttClosePaneEtc() {return "他のタブを閉じる";}
	string menuClosePaneEtc() {return ttClosePaneEtc ~ "(&W)";}
	string ttClosePaneLeft() {return "左側のタブを閉じる";}
	string menuClosePaneLeft() {return ttClosePaneLeft ~ "(&L)";}
	string ttClosePaneRight() {return "右側のタブを閉じる";}
	string menuClosePaneRight() {return ttClosePaneRight ~ "(&R)";}
	string ttClosePaneAll() {return "全てのタブを閉じる";}
	string menuClosePaneAll() {return ttClosePaneAll ~ "(&A)";}

	string image() {return "イメージ";}
	string pathDef() {return "[デフォルト]";}
	string imageNone() {return "[イメージ無し]";}
	string fileNone() {return "[ファイルを選択]";}
	string imageIncluding() {return "[イメージ格納]";}
	string seNone() {return "[サウンド無し]";}
	string bgmStop() {return "[BGM停止]";}
	string bgmNone() {return "[BGM無し]";}
	string dlgMsgIsSaveBeforeReload(string name) {return name ~ "は変更されています。再読込しますか？";}
	string reloadBeforeSaveError(string name) {return name ~ "は保存されていないため、再読込できません。";}
	string dlgMsgIsSaveBeforeExit(string name) {return name ~ "は変更されています。保存しますか？";}
	string dlgMsgDropFiles(string[] paths) {
		return (paths.length == 1 ? paths[0] : (to!(string)(paths.length) ~ "個のファイル"))
			~ "をシナリオ" ~ DIR ~ "にコピーしますか？";
	}
	string dlgMsgDropOverWriteFiles(string[] paths) {
		return (paths.length == 1
			? paths[0] ~ "は"
			: (to!(string)(paths.length) ~ "個の項目が"))
			~ "すでに存在します。上書きしますか？";
	}
	string dlgTitDropFiles() {return "素材ファイルの追加";}
	string dlgMsgCopyError() {return "いくつかのファイルのコピーに失敗しました。";}

	string dlgMsgCopyMaterial(string[] fromPath, uint binImgCount) {
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

	string dlgTitSettings() {return "CWXEditorの設定";}

	/// メニュー。
	string menuFile() {return "ファイル(&F)";}
	string ttNew() {return "新規作成";}
	string menuNew() {return ttNew ~ "(&N)..." ~ "\tCtrl+N";}
	string ttOpen() {return "開く";}
	string menuOpen() {return ttOpen ~ "(&O)..." ~ "\tCtrl+O";}
	string ttClose() {return "閉じる";}
	string menuClose() {return ttClose ~ "(&C)";}
	string menuCloseWin() {return "閉じる(&C)";}
	string ttSave() {return "上書き保存";}
	string menuSave() {return ttSave ~ "(&S)" ~ "\tCtrl+S";}
	string ttSaveA() {return "名前を付けて保存";}
	string menuSaveA() {return ttSaveA ~ "(&A)...";}
	string ttReload() {return "再読込";}
	string menuReload() {return ttReload ~ "(&R)";}
	string ttOpenDirectory() {
		return DIR ~ "を開く";
	}
	string menuOpenDirectory() {return ttOpenDirectory ~ "(&O)";}
	string ttSaveIncludeImage() {
		return "格納イメージをファイルに保存";
	}

	string ttChangeVH() {return "分割領域の縦横を切替";}
	string menuChangeVH() {return ttChangeVH ~ "(&V)" ~ "";}

	string menuEdit() {return "編集(&E)";}
	string ttReplaceText() {return "検索と置換";}
	string menuReplaceText() {return ttReplaceText ~ "(&F)...\tCtrl+F";}
	string ttCEdit() {return "編集";}
	string menuCEdit() {return ttCEdit ~ "(&E)" ~ "\tEnter";}
	string ttRefresh() {return "最新の情報に更新";}
	string ttRefreshS() {return "更新";}
	string menuRefresh() {return ttRefresh ~ "(&R)" ~ "\tF5";}
	string ttUndo() {return "元に戻す";}
	string menuUndo() {return ttUndo ~ "(&U)" ~ "\tCtrl+Z";}
	string ttRedo() {return "やり直し";}
	string menuRedo() {return ttRedo ~ "(&R)" ~ "\tCtrl+Y";}
	string ttCut() {return "切り取り";}
	string menuCut() {return ttCut ~ "(&T)" ~ "\tCtrl+X";}
	string ttCopy() {return "コピー";}
	string menuCopy() {return ttCopy ~ "(&C)" ~ "\tCtrl+C";}
	string ttPaste() {return "貼り付け";}
	string menuPaste() {return ttPaste ~ "(&P)" ~ "\tCtrl+V";}
	string ttDel() {return "削除";}
	string menuDel() {return ttDel ~ "(&D)" ~ "\tDelete";}

	string ttToXML() {return "コピーしたデータをXMLに変換";}
	string menuToXML() {return ttToXML ~ "(&X)" ~ "";}

	string menuView() {return "表示(&V)";}
	string ttDataWin() {return "データウィンドウ";}
	string menuDataWin() {return ttDataWin ~ "(&D)";}
	string ttFlagWin() {return "状態変数ウィンドウ";}
	string menuFlagWin() {return ttFlagWin ~ "(&V)";}
	string ttCardWin() {return "カードウィンドウ";}
	string menuCardWin() {return ttCardWin ~ "(&W)";}
	string ttDirWin() {return "素材管理ウィンドウ";}
	string menuDirWin() {return ttDirWin ~ "(&F)";}

	string menuTools() {return "ツール(&T)";}
	string ttExecEngine() {return "エンジン起動";}
	string menuExecEngine() {return ttExecEngine ~ "(&G)" ~ "\tF9";}
	string ttSettings() {return "エディタ設定";}
	string menuSettings() {return ttSettings ~ "(&O)...";}

	string menuTable() {return "テーブル(&B)";}
	string menuVariable() {return "状態変数(&R)";}

	string menuHelp() {return "ヘルプ(&H)";}
	string ttVersion() {return "バージョン情報";}
	string menuVersion() {return ttVersion ~ "(&A)";}

	string ttLockBar() {return "ツールバーを固定";}
	string menuLockBar() {return ttLockBar ~ "(&L)";}
	string ttResetBar() {return "配置をリセット";}
	string menuResetBar() {return ttResetBar ~ "(&R)";}

	string summary() {return "シナリオの設定";}
	string area() {return "エリア";}
	string battle() {return "バトル";}
	string packages() {return "パッケージ";}

	string dlgTitReplaceText() {return "検索と置換";}
	string replForText() {return "テキスト検索";}
	string replForID() {return "ID検索";}
	string replForPath() {return "素材検索";}
	string replForUnuse() {return "未使用検索";}
	string replForError() {return "誤り検索";}

	string replError() {return "重複する分岐(フラグ分岐が両方ともTRUEになっている等)・条件クーポンに抜けがある台詞コンテント・存在しない素材を参照しているコンテント等を検索します。";}

	string replFrom() {return "検索(置換前)";}
	string replTo() {return "置換後";}

	string replText() {return "検索/置換するテキスト";}
	string replTextTarget() {return "検索/置換対象";}
	string replTextSummary() {return "貼り紙";}
	string replTextMessage() {return "メッセージ";}
	string replTextCardName() {return "カード名";}
	string replTextCardDesc() {return "カード解説";}
	string replTextEventText() {return "イベントテキスト";}
	string replTextStart() {return "スタートコンテント";}
	string replTextFlagAndStep() {return "フラグ/ステップ";}
	string replTextCoupon() {return "クーポン";}
	string replTextGossip() {return "ゴシップ";}
	string replTextEndScenario() {return "終了印";}
	string replTextAreaName() {return "エリア/バトル/パッケージ名";}
	string replTextKeyCode() {return "キーコード";}

	string replID() {return "検索/置換対象";}
	string replIDKind() {return "対象";}
	string replIDArea() {return "エリア";}
	string replIDBattle() {return "バトル";}
	string replIDPackage() {return "パッケージ";}
	string replIDCast() {return "キャストカード";}
	string replIDSkill() {return "スキルカード";}
	string replIDItem() {return "アイテムカード";}
	string replIDBeast() {return "召喚獣カード";}
	string replIDInfo() {return "情報カード";}
	string replSetID() {return "[IDを直接指定]";}

	string replPath() {return "検索/置換する素材";}

	string replUnuseTarget() {return "検索対象";}
	string replUnuseFlag() {return "フラグ";}
	string replUnuseStep() {return "ステップ";}
	string replUnuseArea() {return "エリア";}
	string replUnuseBattle() {return "バトル";}
	string replUnusePackage() {return "パッケージ";}
	string replUnuseCast() {return "キャストカード";}
	string replUnuseSkill() {return "スキルカード";}
	string replUnuseItem() {return "アイテムカード";}
	string replUnuseBeast() {return "召喚獣カード";}
	string replUnuseInfo() {return "情報カード";}
	string replUnuseStart() {return "スタートコンテント";}
	string replUnusePath() {return "素材";}

	string replNotIgnoreCase() {return "大文字と小文字を区別する(&C)";}
	string replRegExp() {return "正規表現(&E) (. = 任意1文字, * = 直前の文字の任意数繰返し, $1 = 1つめの文字列グループ ...)";}
	string regexError() {return "正規表現が正しくありません。";}
	string replWildcard() {return "ワイルドカード(&W) (* = 任意文字列, ? = 任意1文字, \\* = *, \\? = ?, \\\\ = \\)";}
	string replCond() {return "検索条件";}
	string search() {return "検索(&F)";}
	string replace() {return "全て置換(&R)";}
	string replaceExit() {return "閉じる";}
	string searchResult(size_t count) {
		return to!(string)(count) ~ "件の検索結果";
	}
	string replResult(size_t count) {
		return to!(string)(count) ~ "箇所の置換";
	}
	string searchResultBgImage(BgImage back) {
		return "背景画像 - " ~ encodePath(back.path);
	}
	string searchResultIds(C)(C c) {
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
	string searchResultFlags(F)(F f) {
		static if (is(F : Flag)) {
			return "フラグ - " ~ f.path;
		} else static if (is(F : Step)) {
			return "ステップ - " ~ f.path;
		} else static if (is(F : FlagDir)) {
			return "ディレクトリ - " ~ f.path;
		} else static assert (0);
	}
	string searchResultEventTree(EventTree evt) {
		return "イベントツリー - " ~ evt.name;
	}
	string searchResultMenuCard(MenuCard c) {
		return "メニューカード - " ~ c.name;
	}
	string searchResultEnemyCard(EnemyCard c, in Summary summ) {
		auto card = summ.casts(c.id);
		return "エネミーカード - " ~ (card ? card.name : "[対象無し]");
	}

	/// イベント設定。
	string ttStartToPackage() {return "このツリーをパッケージ化する";}
	string menuStartToPackage() {return ttStartToPackage ~ "(&P)";}
	string ttConvertContent() {return "変換";}
	string menuConvertContent() {return ttConvertContent ~ "(&R)";}

	string dlgTitAreaSelect() {return "エリアの選択";}
	string dlgTitBattleSelect() {return "バトルの選択";}
	string dlgTitPackageSelect() {return "パッケージの選択";}
	string dlgTitCastSelect() {return "キャストカードの選択";}
	string dlgTitInfoSelect() {return "情報カードの選択";}

	string dlgTitClear() {return "クリアイベントの設定";}
	string afterClear() {return "シナリオ終了後";}
	string afterClearEndMark() {return "シナリオに済印を付ける";}
	string afterClearNoEndMark() {return "何もしない";}

	string dlgTitCoupon() {return "クーポンイベントの設定";}
	string couponName() {return "クーポン名";}
	string couponValue() {return "得点";}
	string couponValueRange(uint r) {return "(" ~ to!(string)(-(cast(int) r)) ~ "～" ~ to!(string)(r) ~ ")";}
	string range() {return "適用範囲";}
	string dlgTitGossip() {return "ゴシップイベントの設定";}
	string gossipName() {return "ゴシップ名";}
	string dlgTitEnd() {return "終了済みシナリオイベントの設定";}
	string endName() {return "シナリオ名";}
	string dlgTitStartSelect() {return "リンクイベントの設定";}

	string dlgTitSpeak() {return "台詞イベントの設定";}
	string dlgTitMessage() {return "メッセージイベントの設定";}
	string imageMessage() {return "イメージ付きメッセージ";}
	string noImageMessage() {return "イメージ無しメッセージ";}
	string spCharsTitle() {return "特殊文字";}
	string defaultColor() {return "デフォルト(&W)";}
	string red() {return "赤(&R)";}
	string blue() {return "青(&B)";}
	string green() {return "緑(&G)";}
	string yellow() {return "黄(&Y)";}
	string scTalker(Talker talker) {
		switch (talker) {
		case Talker.SELECTED:
			return "選択メンバ名(#M)";
		case Talker.UNSELECTED:
			return "選択外ランダムメンバ名(#U)";
		case Talker.RANDOM:
			return "ランダムメンバ名(#R)";
		case Talker.CARD:
			return "選択カード名(#C)";
		}
	}
	string scRef() {return "参照文字列(#I)";}
	string scTeam() {return "チーム名(#T)";}
	string scYado() {return "宿屋名(#Y)";}
	string createDialog() {return "台詞の作成";}
	string deleteDialog() {return "台詞の削除";}
	string copyToDialogs() {return "台詞を全体にコピー";}
	string copyToUpper() {return "台詞を上方にコピー";}
	string copyToLower() {return "台詞を下方にコピー";}
	string setTalkerCoupon() {return "追加";}

	string dlgTitBgImages() {return "背景変更イベントの設定";}
	string transition() {return "背景切替方式";}
	string transition(Transition t) {
		switch (t) {
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
	string transitionSpeed() {return "背景切替ウェイト";}
	string dlgTitSE() {return "効果音再生イベントの設定";}
	string dlgTitBGM() {return "BGM再生イベントの設定";}
	string dlgTitWait() {return "空白時間イベントの設定";}
	string waitName() {return "空白時間(0.1秒単位)";}
	string dlgTitMoney() {return "所持金イベントの設定";}
	string moneyName() {return "金額";}
	string dlgTitBrRandom() {return "ランダム分岐イベントの設定";}
	string randomName() {return "確率(%)";}
	string dlgTitPartyNum() {return "パーティ人数分岐イベントの設定";}
	string partyNumName() {return "パーティの人数";}
	string dlgTitEffect() {return "効果イベントの設定";}
	string judgeTarget() {return "判定対象";}
	string dlgTitBrFlag() {return "フラグ分岐イベントの設定";}
	string dlgTitBrStepN() {return "ステップ多岐分岐イベントの設定";}
	string dlgTitBrStepUL() {return "ステップ上下分岐イベントの設定";}
	string flag() {return "フラグ";}
	string step() {return "ステップ";}
	string flagValue() {return "値";}
	string stepValue() {return "段階";}
	string dlgTitFlagSet() {return "フラグ変更イベントの設定";}
	string dlgTitStepSet() {return "ステップ変更イベントの設定";}
	string dlgTitStepPlus() {return "ステップ増加イベントの設定";}
	string dlgTitStepMinus() {return "ステップ減少イベントの設定";}
	string dlgTitFlagR() {return "フラグ反転イベントの設定";}
	string dlgTitFlagJudge() {return "フラグ判定イベントの設定";}
	string dlgTitBrMember() {return "メンバ選択分岐イベントの設定";}
	string selectMember() {return "選択対象";}
	string activeMember() {return "動けるメンバから選択";}
	string allMember() {return "パーティ全員から選択";}
	string selectMethod() {return "選択方法";}
	string manualMethod() {return "手動で選択";}
	string randomMethod() {return "ランダムで選択";}
	string dlgTitBrPower() {return "能力判定分岐イベントの設定";}
	string judgeSleep() {return "眠り判定";}
	string sleepDisabled() {return "睡眠者無効";}
	string sleepEnabled() {return "睡眠者有効";}
	string dlgTitBrLevel() {return "レベル分岐イベントの設定";}
	string selectedLevel() {return "現在選択中のメンバ";}
	string allMemberLevel() {return "パーティ全員の平均値";}
	string judgeLevel() {return "判定レベル";}
	string dlgTitBrState() {return "状態分岐イベントの設定";}
	string judgeState() {return "判定状態";}
	string stateHint() {return "ヒント";}
	string cardNumber() {return "枚数";}
	string cardAllDelete() {return "全て削除する";}
	string cardEventRange() {return "適用範囲";}
	string dlgTitBrSkill() {return "スキル所持分岐イベントの設定";}
	string dlgTitBrItem() {return "アイテム所持分岐イベントの設定";}
	string dlgTitBrBeast() {return "召喚獣存在分岐イベントの設定";}
	string dlgTitGetSkill() {return "スキル取得イベントの設定";}
	string dlgTitGetItem() {return "アイテム入手イベントの設定";}
	string dlgTitGetBeast() {return "召喚獣獲得イベントの設定";}
	string dlgTitLostSkill() {return "スキル喪失イベントの設定";}
	string dlgTitLostItem() {return "アイテム喪失イベントの設定";}
	string dlgTitLostBeast() {return "召喚獣消去イベントの設定";}
	string dlgTitRefresh() {return "画面再構築イベントの設定";}
	string transitionType() {return "背景切替方式";}

	/// イベント。
	string evtArrow() {return "イベント編集";}

	string evtAddContinue() {return "連続で配置";}
	string evtAutoOpen() {return "配置と同時に編集";}

	string ttEvtTerminal() {return "開始/終端";}
	string menuEvtTerminal() {return ttEvtTerminal ~ "(&T)";}
	string ttEvtStandard() {return "基本";}
	string menuEvtStandard() {return ttEvtStandard ~ "(&S)";}
	string ttEvtData() {return "変数操作/分岐";}
	string menuEvtData() {return ttEvtData ~ "(&D)";}
	string ttEvtUtility() {return "状況分岐";}
	string menuEvtUtility() {return ttEvtUtility ~ "(&U)";}
	string ttEvtBranch() {return "保有分岐";}
	string menuEvtBranch() {return ttEvtBranch ~ "(&B)";}
	string ttEvtGet() {return "取得";}
	string menuEvtGet() {return ttEvtGet ~ "(&G)";}
	string ttEvtLost() {return "喪失";}
	string menuEvtLost() {return ttEvtLost ~ "(&L)";}
	string ttEvtVisual() {return "外観操作";}
	string menuEvtVisual() {return ttEvtVisual ~ "(&V)";}

	string content(CType type) {
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

	string msnGroupVitality() {return "生命力";}
	string msnGroupPhysical() {return "肉体";}
	string msnGroupSkill() {return "技能";}
	string msnGroupMental() {return "精神";}
	string msnGroupMagic() {return "魔法";}
	string msnGroupEnhance() {return "能力";}
	string msnGroupVanish() {return "消滅";}
	string msnGroupCard() {return "カード";}
	string msnGroupBeast() {return "召喚";}

	string msnDelete() {return "効果削除";}

	string msnDesc(string group, string name) {return group ~ " - " ~ name;}

	string motion(MType type) {
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

	string contentText(in Content evt, in Summary summ) {
		switch (evt.type) {
		case CType.START: {
			return "スタートコンテント: " ~ evt.name;
		} case CType.START_BATTLE: {
			auto b = summ.battle(evt.battle);
			return b is null ? "指定無し" : "バトルビュー「" ~ b.name ~ "」";
		} case CType.END: {
			return evt.complete ? "済印をつけて終了" : "済印をつけずに終了";
		} case CType.END_BAD_END: {
			return "ゲームオーバーコンテント";
		} case CType.CHANGE_AREA: {
			auto a = summ.area(evt.area);
			return a is null ? "指定無し" : "エリアビュー「" ~ a.name ~ "」";
		} case CType.CHANGE_BG_IMAGE: {
			string buf = "背景ファイル = ";
			foreach (i, b; evt.backs) {
				buf ~= "[" ~ encodePath(b.path) ~ "]";
				if (i + 1 < evt.backs.length) buf ~= " ";
			}
			return buf;
		} case CType.EFFECT: {
			string buf = target(evt.targetNS.m);
			buf ~= " レベル" ~ to!(string)(evt.level);
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
			return evt.start is null
				? "指定無し" : "スタートコンテント「" ~ evt.start ~ "」へのリンク";
		} case CType.LINK_PACKAGE: {
			auto p = summ.packages(evt.packages);
			return p is null ? "指定無し" : "パッケージビュー「" ~ p.name ~ "」";
		} case CType.TALK_MESSAGE: {
			switch (evt.talkerC) {
			case Talker.NARRATION:
				return std.string.replace(evt.text, "\n", "");
			case Talker.SELECTED:
				return "[選択中]: " ~ std.string.replace(evt.text, "\n", "");
			case Talker.UNSELECTED:
				return "[選択外]: " ~ std.string.replace(evt.text, "\n", "");
			case Talker.RANDOM:
				return "[ランダム]: " ~ std.string.replace(evt.text, "\n", "");
			case Talker.CARD:
				return "[カード]: " ~ std.string.replace(evt.text, "\n", "");
			case Talker.IMAGE:
				return "[" ~ encodePath(evt.cardPath) ~ "]: " ~ std.string.replace(evt.text, "\n", "");
			default: assert (0);
			}
		} case CType.TALK_DIALOG: {
			if (evt.dialogs[0].rCoupons.length > 0) {
				string rBuf = "";
				foreach (i, rc; evt.dialogs[0].rCoupons) {
					rBuf ~= rc;
					rBuf ~= i + 1 < evt.dialogs[0].rCoupons.length ? " " : ": ";
				}
				return rBuf ~ std.string.replace(evt.dialogs[0].text, "\n", "");
			} else {
				return std.string.replace(evt.dialogs[0].text, "\n", "");
			}
		} case CType.PLAY_BGM: {
			return evt.bgmPath is null || evt.bgmPath.length == 0 ? "BGM停止" : "BGMとして「" ~ encodePath(evt.bgmPath) ~ "」を演奏";
		} case CType.PLAY_SOUND: {
			return evt.soundPath is null || evt.soundPath.length == 0 ? "指定無し" : "効果音「" ~ encodePath(evt.soundPath) ~ "」を鳴らす";
		} case CType.WAIT: {
			return "空白時間 = " ~ to!(string)(evt.wait) ~ " × 0.1秒";
		} case CType.ELAPSE_TIME: {
			return "ターン数経過コンテント";
		} case CType.CALL_START: {
			return evt.start is null ? "指定無し" : "スタートコンテント「" ~ evt.start ~ "」のコール";
		} case CType.CALL_PACKAGE: {
			auto p = summ.packages(evt.packages);
			return p is null ? "指定無し" : "パッケージビュー「" ~ p.name ~ "」のコール";
		} case CType.BRANCH_FLAG: {
			auto f = summ.flagDirRoot.findFlag(evt.flag);
			return f is null ? "指定無し" : "フラグ「" ~ f.path ~ "」の値で分岐";
		} case CType.BRANCH_MULTI_STEP: {
			auto s = summ.flagDirRoot.findStep(evt.step);
			return s is null ? "指定無し" : "ステップ多岐分岐コンテント: " ~ s.path;
		} case CType.BRANCH_STEP: {
			auto s = summ.flagDirRoot.findStep(evt.step);
			if (s) {
				string val = s.getValue(evt.stepValue);
				return "ステップ「" ~ s.path ~ "」の値が[" ~ val ~ "]以上・未満で分岐";
			} else {
				return "指定無し";
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
			buf ~= "(レベル" ~ to!(string)(evt.level) ~ ")";
			return buf;
		} case CType.BRANCH_RANDOM: {
			return "確率 = " ~ to!(string)(evt.percent) ~ "%";
		} case CType.BRANCH_LEVEL: {
			string buf = evt.average ? "パーティ全員" : "選択中のメンバ";
			buf ~= "のレベルが" ~ to!(string)(evt.level) ~ "以上・未満で分岐";
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
			auto c = summ.casts(evt.casts);
			return c is null ? "指定無し" : "キャスト「" ~ c.name ~ "」の同行有無で分岐";
		} case CType.BRANCH_ITEM: {
			auto c = summ.item(evt.item);
			if (c) {
				string buf = "アイテムカード「" ~ c.name ~ "」の有無で分岐(";
				buf ~= range(evt.range) ~ "に";
				buf ~= to!(string)(evt.cardNumber) ~ "枚)";
				return buf;
			} else {
				return "指定無し";
			}
		} case CType.BRANCH_SKILL: {
			auto c = summ.skill(evt.skill);
			if (c) {
				string buf = "特殊技能カード「" ~ c.name ~ "」の有無で分岐(";
				buf ~= range(evt.range) ~ "に";
				buf ~= to!(string)(evt.cardNumber) ~ "枚)";
				return buf;
			} else {
				return "指定無し";
			}
		} case CType.BRANCH_INFO: {
			auto c = summ.info(evt.info);
			return c is null ? "指定無し" : "情報カード「" ~ c.name ~ "」の有無で分岐";
		} case CType.BRANCH_BEAST: {
			auto c = summ.beast(evt.beast);
			if (c) {
				string buf = "召喚獣カード「" ~ c.name ~ "」の有無で分岐(";
				buf ~= range(evt.range) ~ "に";
				buf ~= to!(string)(evt.cardNumber) ~ "枚)";
				return buf;
			} else {
				return "指定無し";
			}
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
			auto f = summ.flagDirRoot.findFlag(evt.flag);
			return f is null ? "指定無し" : "フラグ「" ~ f.path ~ "」を[" ~ (evt.flagValue ? f.on : f.off) ~ "]に変更";
		} case CType.SET_STEP: {
			auto s = summ.flagDirRoot.findStep(evt.step);
			return s is null ? "指定無し" : "ステップ「" ~ s.path ~ "」を[" ~ s.getValue(evt.stepValue) ~ "]に変更";
		} case CType.SET_STEP_UP: {
			auto s = summ.flagDirRoot.findStep(evt.step);
			return s is null ? "指定無し" : "ステップ「" ~ s.path ~ "」の値を1増加";
		} case CType.SET_STEP_DOWN: {
			auto s = summ.flagDirRoot.findStep(evt.step);
			return s is null ? "指定無し" : "ステップ「" ~ s.path ~ "」の値を1減少";
		} case CType.REVERSE_FLAG: {
			auto f = summ.flagDirRoot.findFlag(evt.flag);
			return f is null ? "指定無し" : "フラグ「" ~ f.path ~ "」の値を反転";
		} case CType.CHECK_FLAG: {
			auto f = summ.flagDirRoot.findFlag(evt.flag);
			return f is null ? "指定無し" : "フラグ「" ~ f.path ~ "」の値が[" ~ f.on ~ "]であれば出現";
		} case CType.GET_CAST: {
			auto c = summ.casts(evt.casts);
			return c is null ? "指定無し" : "キャストカード「" ~ c.name ~ "」を同行させる";
		} case CType.GET_ITEM: {
			auto c = summ.item(evt.item);
			if (c) {
				string buf = "アイテムカード「" ~ c.name ~ "」を獲得(";
				buf ~= range(evt.range) ~ "に";
				buf ~= to!(string)(evt.cardNumber) ~ "枚)";
				return buf;
			} else {
				return "指定無し";
			}
		} case CType.GET_SKILL: {
			auto c = summ.skill(evt.skill);
			if (c) {
				string buf = "特殊技能カード「" ~ c.name ~ "」を獲得(";
				buf ~= range(evt.range) ~ "に";
				buf ~= to!(string)(evt.cardNumber) ~ "枚)";
				return buf;
			} else {
				return "指定無し";
			}
		} case CType.GET_INFO: {
			auto c = summ.info(evt.info);
			return c is null ? "指定無し" : "情報カード「" ~ c.name ~ "」を獲得";
		} case CType.GET_BEAST: {
			auto c = summ.beast(evt.beast);
			if (c) {
				string buf = "召喚獣カード「" ~ c.name ~ "」を獲得(";
				buf ~= range(evt.range) ~ "に";
				buf ~= to!(string)(evt.cardNumber) ~ "枚)";
				return buf;
			} else {
				return "指定無し";
			}
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
			auto c = summ.casts(evt.casts);
			return c is null ? "指定無し" : "キャスト「" ~ c.name ~ "」の同行を解除";
		} case CType.LOSE_ITEM: {
			auto c = summ.item(evt.item);
			if (c) {
				string buf = "アイテムカード「" ~ c.name ~ "」を喪失(";
				buf ~= range(evt.range) ~ "から";
				buf ~= evt.cardNumber == 0 ? "全て" : to!(string)(evt.cardNumber) ~ "枚";
				buf ~= ")";
				return buf;
			} else {
				return "指定無し";
			}
		} case CType.LOSE_SKILL: {
			auto c = summ.skill(evt.skill);
			if (c) {
				string buf = "特殊技能カード「" ~ c.name ~ "」を喪失(";
				buf ~= range(evt.range) ~ "から";
				buf ~= evt.cardNumber == 0 ? "全て" : to!(string)(evt.cardNumber) ~ "枚";
				buf ~= ")";
				return buf;
			} else {
				return "指定無し";
			}
		} case CType.LOSE_INFO: {
			auto c = summ.info(evt.info);
			return c is null ? "指定無し" : "情報カード「" ~ c.name ~ "」を喪失";
		} case CType.LOSE_BEAST: {
			auto c = summ.beast(evt.beast);
			if (c) {
				string buf = "召喚獣カード「" ~ c.name ~ "」を喪失(";
				buf ~= range(evt.range) ~ "から";
				buf ~= evt.cardNumber == 0 ? "全て" : to!(string)(evt.cardNumber) ~ "枚";
				buf ~= ")";
				return buf;
			} else {
				return "指定無し";
			}
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

	string defaultStartName() {return "イベント開始";}

	/// メインウィンドウ。
	string mainWindowName(string name, string path) {
		return name !is null ? "" ~ name ~ " [ " ~ path ~ " ] - CWXEditor" : "CWXEditor";
	}
	string errorExecEngine(string enginePath) {
		return getBaseName(enginePath) ~ "の起動に失敗しました。";
	}

	/// シナリオ選択ダイアログ
	string dlgTitNewScenario() {return "新規シナリオの作成";}
	string createError(string path) {return path ~ "でシナリオの作成に失敗しました。";}
	string dlgTitOpenScenario() {return "シナリオを開く";}
	string filterScenario() {
		if (canUncab) {
			return "シナリオファイル (*.wsn;Summary.xml;*.cab;*.zip;Summary.wsm;*.wid)";
		} else {
			return "シナリオファイル (*.wsn;Summary.xml;*.zip;Summary.wsm;*.wid)";
		}
	}
	string dlgTitSaveScenario() {return "名前を付けて保存";}
	string filterScenarioSave() {return "XMLシナリオファイル (*.wsn)";}
	string notScenario(string name) {return name ~ "はシナリオ圧縮ファイルではありません";}
	string zipError(string name) {return name ~ "の展開に失敗しました。";}
	string loadError(string name) {return name ~ "の読込みに失敗しました。";}
	string saveError(string name) {return name ~ "の保存に失敗しました。";}
	string dlgTitUnzip() {return "圧縮ファイルの展開 - CWXEditor";}
	string unzip(string name) {return name ~ "を展開しています……";}
	string loadErrorStatus(string name) {return name ~ "の読込みに失敗";}
	string loadErrorStatus(string[] name) {
		if (name.length == 1) {
			return loadErrorStatus(name[0]);
		}
		return to!(string)(name.length) ~ "件のシナリオの読込みに失敗";
	}

	/// データウィンドウ
	string dataTabName(Summary summ) {
		return "データ";
	}
	string dataWindowName(Summary summ) {
		if (summ) {
			return "データ - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "データ";
		}
	}
	string areasTabName(Summary summ) {
		return "エリア";
	}
	string areasWindowName(Summary summ) {
		if (summ) {
			return "エリア - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "エリア";
		}
	}
	string areaStatus(Area[] as, Battle[] bs, Package[] ps, AbstractArea sel) {
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
	string flagTabName(Summary summ) {
		return "状態変数";
	}
	string flagWindowName(Summary summ) {
		if (summ) {
			return "状態変数 - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "状態変数";
		}
	}
	string flagStatus(Flag[] flags, Step[] steps, Flag[] selFlags, Step[] selSteps) {
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
	string scenarioView() {return "シナリオビューリスト";}
	string variableView() {return "状態変数インスペクタ";}
	string ttSummary() {return "シナリオの設定";}
	string ttNewArea() {return "エリアの作成";}
	string ttNewBattle() {return "バトルの作成";}
	string ttNewPackage() {return "パッケージの作成";}

	string menuSummary() {return ttSummary ~ "(&S)...";}
	string menuNewArea() {return ttNewArea ~ "(&A)";}
	string menuNewBattle() {return ttNewBattle ~ "(&B)";}
	string menuNewPackage() {return ttNewPackage ~ "(&K)";}

	string ttReNumberingAll() {return "全てのIDを1から振り直す";}
	string menuReNumberingAll() {return ttReNumberingAll ~ "(&A)";}
	string reNumberingAll() {
		return "全てのエリアやカードのIDの1から振り直します。\nよろしいですか？";
	}

	string ttReNumbering() {return "IDの振り直し";}
	string menuReNumbering() {return ttReNumbering ~ "(&N)";}
	string dlgTitReNumbering() {return "IDの振り直し";}
	string reNumbering() {return "IDの振り直し";}
	string reNumbering1(Card card, ulong min, ulong max) {
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
	string reNumbering1(AbstractArea area, ulong min, ulong max) {
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
	string reNumbering2(Card card, ulong min, ulong max) {
		return "番から順に振り直す";
	}
	string reNumbering2(AbstractArea area, ulong min, ulong max) {
		return "番から順に振り直す";
	}

	/// エリアのテーブル。
	string areaId() {return "ID";}
	string areaName() {return "名称";}
	string areaCount() {return "利用数";}
	string areaNew() {return "新規エリア";}
	string battleNew() {return "新規バトル";}
	string packageNew() {return "新規パッケージ";}

	/// フラグのディレクトリ。
	string flagDirRoot() {return "Data";}
	string flagDirNew() {return "新規フォルダ";}
	string ttNewFlagDir() {return "フォルダの作成";}
	string menuNewFlagDir() {return ttNewFlagDir ~ "(&N)...";}
	int menuNewDirA() {return -1;}

	/// フラグ/ステップのテーブル。
	string flagName() {return "名称";}
	string flagInit() {return "初期値";}
	string flagCount() {return "利用数";}
	string ttNewFlag() {return "フラグの作成";}
	string menuNewFlag() {return ttNewFlag ~ "(&F)..." ~ "\tCtrl+L";}
	string ttNewStep() {return "ステップの作成";}
	string menuNewStep() {return ttNewStep ~ "(&S)..." ~ "\tCtrl+P";}

	/// フラグ設定ダイアログ関連。
	string dlgTitFlag() {return "フラグの設定";}
	string dlgLblFlagName() {return "フラグ名";}
	string dlgLblFlagInit() {return "初期値";}
	string dlgLblFlagTrue() {return "TRUE";}
	string dlgLblFlagFalse() {return "FALSE";}

	/// ステップ設定ダイアログ関連。
	string dlgTitStep() {return "ステップの設定";}
	string dlgLblStepName() {return "ステップ名";}
	string dlgLblStepInit() {return "初期値";}
	string dlgLblStep(uint index) {return dlgTxtStep(index);}
	string dlgTxtStep(uint index) {
		return "Step - " ~ to!(string)(index);
	}

	/// 貼り紙設定ダイアログ関連。
	string dlgTitSummary(string sname) {return "概略の設定 - [ " ~ sname ~ " ]";}
	string summaryImage() {return "表示イメージ";}
	string baseData() {return "基本データ";}
	string etcData() {return "詳細データ";}
	string targetLevel(uint levL, uint levH) {
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
	string summaryPageDummy() {return "1/1";}
	string title() {return "シナリオタイトル";}
	string author() {return "作者名";}
	string targetLevel() {return "対象レベル";}
	string desc() {return "解説";}
	string levSep() {return "～";}
	string scenarioType() {return "シナリオタイプ";}
	string qualification() {return "シナリオ出現条件";}
	string rCouponNum() {return "必要数";}
	string rCoupons() {return "必要とする称号";}
	string startArea() {return "シナリオ開始エリア";}
	string legacyEngineSkin(string lEnginePath) {
		return "[" ~ getBaseName(lEnginePath) ~ "のリソースを使用]";
	}

	/// エリア・戦闘・パッケージウィンドウ。
	string ttUp() {return "上へ";}
	string menuUp() {return ttUp ~ "(&U)" ~ "\tCtrl+Arrow_Up";}
	string ttDown() {return "下へ";}
	string menuDown() {return ttDown ~ "(&D)" ~ "\tCtrl+Arrow_Down";}
	string menuCardsAndBacks() {return "カードと背景" ~ "(&A)";}
	string ttViewParty() {return "パーティカードの表示";}
	string menuViewParty() {return ttViewParty ~ "(&P)";}
	string ttViewMsg() {return "メッセージ枠の表示";}
	string menuViewMsg() {return ttViewMsg ~ "(&M)";}
	string ttFixed() {return "イメージの固定";}
	string menuFixed() {return ttFixed ~ "(&F)";}
	string ttEnemyCardDebugView() {return "レベルとライフを表示";}
	string menuEnemyCardDebugView() {return ttEnemyCardDebugView ~ "(&L)";}
	string ttViewCards() {return "カードの表示";}
	string menuViewCards() {return ttViewCards ~ "(&V)";}
	string ttViewBacks() {return "背景の表示";}
	string menuViewBacks() {return ttViewBacks ~ "(&I)";}
	string ttNewMenuCard() {return "メニューカードの作成";}
	string menuNewMenuCard() {return ttNewMenuCard ~ "(&C)...";}
	string ttNewEnemyCard() {return "エネミーカードの作成";}
	string menuNewEnemyCard() {return ttNewEnemyCard ~ "(&C)...";}
	string ttNewBack() {return "背景の作成";}
	string menuNewBack() {return ttNewBack ~ "(&B)...";}
	string ttAuto() {return "カードを自動的に並べる";}
	string menuAuto() {return ttAuto ~ "(&A)";}
	string ttCustom() {return "カードの位置を自分で決定する";}
	string menuCustom() {return ttCustom ~ "(&U)";}
	string ttMask() {return "透明色を使用";}
	string menuMask() {return ttMask ~ "(&M)";}
	string ttDoEscape() {return "逃走の有無";}
	string menuDoEscape() {return ttMask ~ "(&E)";}

	string menuPosTop() {return "上に揃える" ~ "(&U)";}
	string menuPosBottom() {return "下に揃える" ~ "(&D)";}
	string menuPosLeft() {return "左に揃える" ~ "(&L)";}
	string menuPosRight() {return "右に揃える" ~ "(&R)";}
	string menuPosEven() {return "等間隔に並べる" ~ "(&E)";}
	string menuScaleMin() {return "最小のカードスケール" ~ "(&S)";}
	string menuScaleMiddle() {return "標準のカードスケール" ~ "(&I)";}
	string menuScaleMax() {return "最大のカードスケール" ~ "(&G)";}
	string menuScaleEvenBig() {return "大きく揃える" ~ "(&L)";}
	string menuScaleEvenSmall() {return "小さく揃える" ~ "(&N)";}

	string left() {return "X";}
	string top() {return "Y";}
	string width() {return "幅";}
	string height() {return "高";}
	string scale() {return "拡大率";}

	string areaViewStatus(AbstractSpCard[] cards, BgImage[] backs, bool useFlag) {
		if (cards.length == 1 && backs.length == 0 && useFlag) {
			return cards[0].flag == "" ? "フラグ指定無し" : "フラグ = " ~ cards[0].flag;
		} else if (cards.length == 0 && backs.length == 1 && useFlag) {
			return backs[0].flag == "" ? "フラグ指定無し" : "フラグ = " ~ backs[0].flag;
		} else if (cards.length > 0 && backs.length == 0) {
			return to!(string)(cards.length) ~ "枚のカード";
		} else if (cards.length == 0 && backs.length > 0) {
			return to!(string)(backs.length) ~ "枚の背景";
		} else if (cards.length > 0 && backs.length > 0) {
			return to!(string)(cards.length) ~ "枚のカード " ~ to!(string)(backs.length) ~ "枚の背景";
		} else {
			return "";
		}
	}

	private string __viewNameTab(ulong id, string name) {
		return to!(string)(id) ~ "." ~ name;
	}
	private string __viewName(string kind, ulong id, string name) {
		return "[" ~ kind ~ "] - " ~ to!(string)(id) ~ " - " ~ name;
	}
	string areaViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	string battleViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	string packageViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	string skillViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	string itemViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	string beastViewNameTab(ulong id, string name) {return __viewNameTab(id, name);}
	string areaViewName(ulong id, string name) {return __viewName("エリア", id, name);}
	string battleViewName(ulong id, string name) {return __viewName("バトル", id, name);}
	string packageViewName(ulong id, string name) {return __viewName("パッケージ", id, name);}
	string skillViewName(ulong id, string name) {return __viewName("スキル", id, name);}
	string itemViewName(ulong id, string name) {return __viewName("アイテム", id, name);}
	string beastViewName(ulong id, string name) {return __viewName("召喚獣", id, name);}

	string handCards(ulong id, string name) {
		return __viewName("所有カード", id, name);
	}
	string handCardsTab(ulong id, string name) {
		return __viewNameTab(id, name);
	}
	string cardCount() {return "使用数";}
	string addCardWindow(string name, string path) {
		return "カードのインポート - [ " ~ name ~ " ] - " ~ path;
	}
	string addCardTab(string name, string path) {
		return name;
	}

	string cardAndBackView() {return "カードと背景";}
	string enemyCardView() {return "エネミーカード";}
	string menuCards() {return "カード";}
	string enemyCards() {return "カード";}
	string backs() {return "背景";}
	string eventView() {return "イベント";}
	/// カード/背景配置領域関連。
	string dlgTitDropCard() {return "カード画像の追加";}
	string dlgMsgDropCard(string fname) {
		return "カード画像をシナリオ" ~ DIR ~ "にコピーしますか？\n" ~ fname;
	}
	string dlgTitDropBack() {return "背景画像の追加";}
	string dlgMsgDropBack(string fname) {
		return "背景画像をシナリオ" ~ DIR ~ "にコピーしますか？\n" ~ fname;
	}

	string refFlag() {return "フラグ参照先";}
	string refStep() {return "ステップ参照先";}
	string noFlag() {return "[参照無し]";}
	string cardPosition() {return "カード位置";}
	string backPosition() {return "位置";}
	string bgImageSettings() {return "簡単設定";}
	string bgImageSettingCustom() {return "[カスタム]";}
	string bgImageSettingOriginal() {return "[元のサイズ]";}
	string enemyCardBase() {return "基本設定";}
	string dlgTitMenuCard(string name) {return "メニューカードの設定 [ " ~ name ~ " ]";}
	string dlgTitNewMenuCard() {return "メニューカードの作成";}
	string dlgTitBgImage() {return "背景画像の設定";}
	string dlgTitNewBgImage() {return "背景画像の作成";}
	string dlgTitEnemyCard(string name) {return "エネミーカードの設定 [ " ~ name ~ " ]";}
	string dlgTitNewEnemyCard() {return "エネミーカードの作成";}
	string stopBGM(string playingFile) {return getBaseName(playingFile) ~ "の再生を停止";}
	string playBGM() {return "再生";}

	/// イベントビュー。
	string tools() {return "イベントコンテント";}
	string startEnter() {return "到着";}
	string startSelect() {return "クリック";}
	string startDead() {return "死亡";}
	string startVictory() {return "勝利";}
	string startEscape() {return "逃走";}
	string startLose() {return "敗北";}
	string startPackage() {return "パッケージ";}
	string startUse() {return "使用時";}
	string startRound(uint round) {return "ラウンド = " ~ to!(string)(round);}

	string menuAddManyRounds() {return "複数のラウンドを追加";}
	string manyRounds() {return "追加する発火ラウンドの範囲";}
	string dlgTitAddManyRounds() {return "追加する発火ラウンドの範囲";}
	string roundSep() {return "～";}

	string enterTree() {return "到着";}
	string selectTree() {return "クリック";}
	string deadTree() {return "死亡";}
	string victoryTree() {return "勝利";}
	string escapeTree() {return "逃走";}
	string loseTree() {return "敗北";}
	string packageTree() {return "パッケージイベント";}
	string useTree() {return "使用時イベント";}
	string keyCodeTree(string keyCode) {return "[" ~ keyCode ~ "]";}
	string roundTree(uint round) {return "ラウンド" ~ to!(string)(round);}

	string ttNewEventTree() {return "イベントの作成";}
	string ttNewEventFire() {return "イベント発火条件の作成";}
	string ttNewTreeOpen() {return "全コンテントツリーを開く";}
	string ttNewTreeClose() {return "全コンテントツリーを閉じる";}
	string eventTreeKindSystem() {return "システム";}
	string eventTreeKindKeyCode() {return "キーコード";}
	string eventTreeKindRound() {return "ラウンド";}

	string evtChildTrue() {return "○";}
	string evtChildFalse() {return "×";}
	string evtChildDefault() {return "Default";}

	string evtChildBrFlag(Flag flag, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		if (flag is null) {
			return "指定無し = " ~ (val ? "TRUE" : "FALSE");
		} else {
			return flag.path ~ " = " ~ (val ? flag.on : flag.off);
		}
	}
	string evtChildBrStepN(Step step, ref string text) {
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
	string evtChildBrStepUL(Step step, int num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		if (step is null) {
			return "ステップ「指定無し」が「Step - " ~ to!(string)(num) ~ "」" ~ (val ? "以上" : "未満");
		} else {
			return "ステップ「" ~ step.path ~ "」が「" ~ step.getValue(num) ~ "」" ~ (val ? "以上" : "未満");
		}
	}
	string evtChildBrMember(bool all, bool random, ref string text) {
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
	string evtChildBrPower(Target targ, Physical p, Mental m, int lev, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return target(targ) ~ "がレベル" ~ to!(string)(lev) ~ "で"
			~ physical(p) ~ "と" ~ mental(m) ~ "で行う判定に" ~ (val ? "成功" : "失敗");
	}
	string evtChildBrRandom(int percent, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return to!(string)(percent) ~ "%" ~ (val ? "成功" : "失敗");
	}
	string evtChildBrLevel(int lev, bool avg, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return (avg  ? "全員の平均値" : "選択中のメンバ") ~ "がレベル"
			~ to!(string)(lev) ~ (val ? "以上" : "未満");
	}
	string evtChildBrState(Target targ, Status stat, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return target(targ) ~ "での「" ~ status(stat) ~ "」" ~ "の判定に"
			~ (val ? "成功" : "失敗");
	}
	string evtChildBrNum(int num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "パーティに" ~ to!(string)(num) ~ "人" ~  (val ? "以上いる" : "いない");
	}
	string evtChildBrArea(Area[] areas, ref string text) {
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
	string evtChildBrBattle(Battle[] btls, ref string text) {
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
	string evtChildBrOnBattle(ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "イベント発生時の状況が" ~ (val ? "戦闘中" : "戦闘中以外");
	}
	string evtChildBrCast(CastCard c, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "「" ~ (c is null ? "指定無し" : c.name) ~ "」が加わって" ~ (val ? "いる" : "いない");
	}
	string evtChildBrItem(ItemCard c, Range r, uint num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return range(r) ~ "で「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	string evtChildBrSkill(SkillCard c, Range r, uint num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return range(r) ~ "で「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	string evtChildBrBeast(BeastCard c, Range r, uint num, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return range(r) ~ "で「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	string evtChildBrInfo(InfoCard c, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "「" ~ (c is null ? "指定無し" : c.name) ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	string evtChildBrMoney(uint sp, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return to!(string)(sp) ~ "sp以上所持して" ~ (val ? "いる" : "いない");
	}
	string evtChildBrCoupon(Range r, string coupon, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return range(r) ~ "がクーポン「" ~ coupon ~ "」を所有して" ~ (val ? "いる" : "いない");
	}
	string evtChildBrEnd(string scenario, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "シナリオ「" ~ scenario ~ "」が終了済みで" ~ (val ? "ある" : "ない");
	}
	string evtChildBrGossip(string gossip, ref string text) {
		bool val = (text != evtChildFalse);
		text = val ? evtChildTrue : evtChildFalse;
		return "クーポン「" ~ gossip ~ "」が宿屋に" ~ (val ? "ある" : "無い");
	}
	string physical(Physical p) {
		switch (p) {
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
	string mental(Mental m) {
		switch (m) {
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
	string status(Status stat) {
		switch (stat) {
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
	string effectType(EffectType t, Resist r) {
		return effectType2(t) ~ "/" ~ resist(r);
	}
	string effectType(EffectType t) {
		return effectType2(t) ~ "属性";
	}
	private string effectType2(EffectType t) {
		switch (t) {
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
	string resist(Resist r) {
		switch (r) {
		case Resist.AVOID:
			return "回避属性";
		case Resist.RESIST:
			return "抵抗属性";
		case Resist.UNFAIL:
			return "必中属性";
		}
	}
	string cardTarget(CardTarget r) {
		switch (r) {
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
	string cardTargetOne() {return "一体";}
	string cardTargetAll() {return "全体";}
	string cardVisual(CardVisual vis) {
		switch (vis) {
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
	string premium(Premium r) {
		switch (r) {
		case Premium.NORMAL:
			return "日用品 (買戻し不可/破棄可)";
		case Premium.RARE:
			return "希少品 (買戻し可/破棄可)";
		case Premium.PREMIUM:
			return "貴重品 (買戻し可/破棄不可)";
		}
	}
	string enhance(Enhance r) {
		switch (r) {
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
	string mentality() {
		return "精神状態";
	}
	string mentality(Mentality m) {
		switch (m) {
		case Mentality.NORMAL: return "正常";
		case Mentality.SLEEP: return "睡眠";
		case Mentality.CONFUSE: return "混乱";
		case Mentality.OVERHEAT: return "激昂";
		case Mentality.BRAVE: return "勇敢";
		case Mentality.PANIC: return "恐慌";
		default: assert (0);
		}
	}

	string enhanceBonus(Enhance r) {
		return enhance(r) ~ "ボーナス";
	}
	string statusActive() {
		return "※ 行動可能 = (健康 | 負傷 | 重傷 | 中毒)";
	}
	string statusInactive() {
		return "※ 行動不可 = (意識不明 | 麻痺/石化 | 呪縛 | 眠り)";
	}
	string statusAlive() {
		return "※ 生存 = (健康 | 負傷 | 重傷 | 中毒 | 呪縛 | 眠り)";
	}
	string statusDead() {
		return "※ 非生存 = (意識不明 | 麻痺/石化)";
	}
	string target(Target targ) {
		return target(targ.m);
	}
	string target(Target.M m) {
		switch (m) {
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
	string talker(Talker talker) {
		switch (talker) {
		case Talker.SELECTED:
			return "[選択中]";
		case Talker.UNSELECTED:
			return "[選択中以外]";
		case Talker.RANDOM:
			return "[ランダム]";
		case Talker.CARD:
			return "[カード]";
		}
	}
	string range(Range r) {
		switch (r) {
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
	string damageType(DamageType dtyp) {
		switch (dtyp) {
		case DamageType.LEVEL_RATIO:
			return "レベルに対応する値";
		case DamageType.NORMAL:
			return "値の直接入力";
		case DamageType.MAX:
			return "最大値処理";
		}
	}
	string element(Element el) {
		switch (el) {
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

	string sexName(Sex s) {
		switch (s) {
		case Sex.MALE: return "男/♂";
		case Sex.FEMALE: return "女/♀";
		}
	}
	string sexUnknown() {return "謎/？";}
	string periodUnknown() {return "不明";}
	string natureUnknown() {return "その他";}

	/// カードウィンドウ。
	string cardTabName(Summary summ) {
		return "カード";
	}
	string cardWindowName(Summary summ) {
		if (summ) {
			return "カード - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "カード";
		}
	}
	string dlgTitAddScenario() {return "インポート元の選択";}

	string cardStatus(C)(size_t cardCount, C[] selCards) {
		string r = to!(string)(cardCount) ~ "枚のカード";
		if (selCards.length == 1) {
			r ~= " (ID = " ~ to!(string)(selCards[0].id) ~ ")";
		} else if (selCards.length) {
			r ~= " (" ~ to!(string)(selCards.length) ~ "枚を選択中)";
		}
		return r;
	}
	string handCardStatus(C)(size_t cardCount, C[] selCards, int max) {
		return to!(string)(cardCount) ~ "枚のカード (有効枚数 = " ~ to!(string)(max) ~ ")";
	}

	string ttShowCardLife() {return "レベルとライフを表示";}
	string menuShowCardLife() {return ttShowCardLife ~ "(&L)";}
	string ttShowCardList() {return "カード表示";}
	string menuShowCardList() {return ttShowCardList ~ "(&C)";}
	string ttShowCardTable() {return "詳細表示";}
	string menuShowCardTable() {return ttShowCardTable ~ "(&D)";}
	string menuNewCards() {return "カード" ~ "(&C)";}

	string ttAddScenario() {return "外部シナリオから追加";}
	string menuAddScenario() {return ttAddScenario ~ "(&A)...";}
	string ttNewCast() {return "キャストカードの作成";}
	string menuNewCast() {return ttNewCast ~ "(&C)...";}
	string ttNewSkill() {return "スキルカードの作成";}
	string menuNewSkill() {return ttNewSkill ~ "(&S)...";}
	string ttNewItem() {return "アイテムカードの作成";}
	string menuNewItem() {return ttNewItem ~ "(&I)...";}
	string ttNewBeast() {return "召喚獣カードの作成";}
	string menuNewBeast() {return ttNewBeast ~ "(&B)...";}
	string ttNewInfo() {return "情報カードの作成";}
	string menuNewInfo() {return ttNewInfo ~ "(&F)...";}

	string ttAdd() {return "シナリオに追加";}
	string menuAdd() {return ttAdd ~ "(&A)" ~ "\tCtrl+P";}

	string menuEditHand() {return "所有カードの設定" ~ "(&H)";}
	string menuOpenHand() {return "所有カード" ~ "(&H)";}
	string menuEditUseEvent() {return "使用時イベントの設定" ~ "(&E)";}

	string casts() {return "キャスト";}
	string skill() {return "スキル";}
	string item() {return "アイテム";}
	string beast() {return "召喚獣";}
	string info() {return "情報";}

	string cardId() {return "ID";}
	string cardName() {return "名称";}
	string cardDesc() {return "説明";}

	string dlgTitNewCast() {return "キャストカードの作成";}
	string dlgTitNewSkill() {return "特殊技能カードの作成";}
	string dlgTitNewItem() {return "アイテムカードの作成";}
	string dlgTitNewBeast() {return "召喚獣カードの作成";}
	string dlgTitNewInfo() {return "情報カードの作成";}
	string dlgTitCast(string name) {return "キャストカードの設定 [ " ~ name ~ " ]";}
	string dlgTitSkill(string name) {return "特殊技能カードの設定 [ " ~ name ~ " ]";}
	string dlgTitItem(string name) {return "アイテムカードの設定 [ " ~ name ~ " ]";}
	string dlgTitBeast(string name) {return "召喚獣カードの設定 [ " ~ name ~ " ]";}
	string dlgTitInfo(string name) {return "情報カードの設定 [ " ~ name ~ " ]";}

	string name() {return "名前";}
	string nameLimit(uint limit) {return "(" ~ to!(string)(limit / 2) ~ "文字まで)";}
	string level() {return "レベル";}
	string life() {return "体力";}
	string lifeCalc() {return "標準値";}
	string history() {return "経歴";}
	string coupons() {return "経歴";}
	string addCoupon() {return "新規クーポンの追加";}
	string altCoupon() {return "クーポンの上書き";}
	string delCoupon() {return "クーポンの削除";}
	string sex() {return "性別";}
	string period() {return "年代";}
	string race() {return "種族";}
	string noRace() {return "[未指定]";}
	string raceCoupon(Race race) {return "＠Ｒ" ~ race.name;}
	string nature() {return "素質";}
	string makings() {return "特徴";}
	string tolerant() {return "対属性";}
	string tolerantBase() {return "対カード属性";}
	string tolerantElement() {return "対効果属性";}
	string resistWeapon() {return "武器が効かない";}
	string resistMagic() {return "魔法が効かない";}
	string undead() {return "命を持たない";}
	string automaton() {return "心を持たない";}
	string unholy() {return "不浄な存在";}
	string constructure() {return "魔法生物";}
	string resist(Element e) {return element(e) ~ "に耐性を持つ";}
	string weakness(Element e) {return element(e) ~ "に弱い";}
	string descResistWeapon() {return "(物理属性のカードが無効)";}
	string descResistMagic() {return "(魔法属性のカードが無効)";}
	string descUndead() {return "(肉体属性の効果が無効)";}
	string descAutomaton() {return "(精神属性の効果が無効)";}
	string descUnholy() {return "(神聖属性の効果に影響)";}
	string descConstructure() {return "(魔力属性の効果に影響)";}
	string descResist(Element e) {return "(" ~ element(e) ~ "属性の効果が無効)";}
	string descWeakness(Element e) {return "(" ~ element(e) ~ "属性の効果に影響)";}
	string basicResist() {return "標準値";}
	string physicalParams() {return "身体能力";}
	string physicalCalc() {return "標準値";}
	string mentalParams() {return "精神傾向";}
	string mentalCalc() {return "標準値";}
	string castEnhance() {return "能力修正";}
	string basicEnhance() {return "標準値";}

	string liveStatus() {return "初期状態";}
	string lifeAndMentality() {return "体力と精神状態";}
	string enhanceLiveBonus() {return "能力ボーナス/ペナルティ";}
	string enhanceLiveBonus(Enhance enh) {
		switch (enh) {
		case Enhance.ACTION: return "行動";
		case Enhance.AVOID: return "回避";
		case Enhance.RESIST: return "抵抗";
		case Enhance.DEFENSE: return "防御";
		default: assert (0);
		}
	}
	string useMax() {return "最大値を使用";}
	string status() {return "異常状態";}
	string paralyze() {return "麻痺/石化";}
	string poison() {return "中毒";}
	string bind() {return "呪縛";}
	string silence() {return "沈黙";}
	string faceUp() {return "暴露";}
	string antiMagic() {return "魔法無効";}
	string unitValue() {return "点";}
	string unitRound() {return "ラウンド";}
	string resetLiveStatus() {return "通常状態に戻す";}

	string needSpellGroup() {return "発声による発動";}
	string needSpell() {return "沈黙時に使用不可";}
	string elementProps() {return "効果属性";}
	string resistProps() {return "抵抗属性";}
	string aptPhysical() {return "身体的要素";}
	string aptMental() {return "精神的要素";}
	string skillLevel() {return "技能レベル";}
	string useCountGroup() {return "使用可能回数";}
	string useCountRange(uint max) {return "(0～" ~ to!(string)(max) ~ " : 0 = ∞)";}
	string price() {return "価格";}
	string priceAuto() {return "(参考用)";}
	string useModify() {return "使用時 能力値修正";}
	string haveModify() {return "所有時 能力値修正";}
	string motionKind() {return "効果種別";}
	string motionElement() {return "属性";}
	string motionDamageType() {return "タイプ";}
	string motionValue() {return "値";}
	string motionBeast() {return "召喚するカード";}
	string beastNone() {return "召喚獣無し";}
	string setBeast() {return "選択";}
	string motionRound() {return "継続時間 (ラウンド数)";}
	string motionEnhValue() {return "変化値";}
	string effectTarget() {return "効果目標";}
	string effectRange() {return "効果範囲";}
	string effectVisual() {return "視覚効果";}
	string cardPremium() {return "カードの価値";}
	string successRate() {return "成功率修正値";}
	string allFail() {return "絶対失敗\n(-5)";}
	string allSuccess() {return "絶対成功\n(+5)";}
	string se() {return "効果音";}
	string se1() {return "初期効果";}
	string se2() {return "二次効果";}
	string soundNone() {return "[効果音無し]";}
	string stopSound() {return "停止";}
	string playSound() {return "再生";}
	string keyCodes() {return "イベント発火のキーコード";}

	string warningEffectTypeNone() {
		return "無属性のカードをシナリオ外に持ち出した場合、予期せぬバグの原因になります。"
			~ "\nこのまま無属性を設定しますか？";
	}
	string warningVanishCast() {
		return "神聖属性以外の対象消去効果を持つカードをシナリオ外に持ち出した場合、予期せぬバグの原因になります。"
			~ "\nこのまま設定しますか？";
	}

	string card() {return "カード";}
	string apt() {return "要素";}
	string useCountAndDesc() {return "使用回数/解説";}
	string levelAndDesc() {return "レベル/解説";}
	string useBonus() {return "使用ボーナス";}
	string haveBonus() {return "所持ボーナス";}
	string motion() {return "効果";}
	string cardProps() {return "属性";}
	string settings() {return "設定";}
	string seAndKeyCode() {return "効果音/キーコード";}

	string rangeHint(int min, int max) {
		return "(" ~ to!(string)(min) ~ "～" ~ to!(string)(max) ~ ")";
	}

	/// 素材管理ウィンドウ。
	string dirTabName(Summary summ) {
		return "ファイル";
	}
	string dirWindowName(Summary summ) {
		if (summ) {
			return "ファイル - [ " ~ summ.scenarioName ~ " ] - " ~ summ.scenarioPath;
		} else {
			return "ファイル";
		}
	}
	string dirStatus(uint fileCount, ulong size, string[] selFiles) {
		auto r = to!(string)(fileCount) ~ "個のファイル (" ~ formatNum(size / 1024) ~ " KB)";
		if (selFiles.length) {
			r ~= " (" ~ to!(string)(selFiles.length) ~ "個を選択中)";
		}
		return r;
	}
	string fileName() {return "ファイル名";}
	string fileExt() {return "拡張子";}
	string fileCount() {return "使用数";}
	string errorExec(string appName) {return appName ~ "の起動に失敗しました。";}
	string ttNewFolder() {return "新規" ~ DIR;}
	string menuNewFolder() {return ttNewFolder ~ "(&I)";}
	string newFolder() {return ttNewFolder;}
	string ttReplacePath() {return "素材の差替え";}
	string menuReplacePath() {return ttReplacePath ~ "(&R)...";}

	/// エディタ設定ダイアログ。
	string baseSettings() {return "基本設定";}
	string reference() {return "参照...";}
	string enginePath(string appName) {return appName ~ "の場所(原則必須)";}
	string enginePathAtten() {return "※ クラシックなシナリオのみに使用する場合は空欄にしてください";}
	string dlgTitEnginePath(string appName) {return appName ~ "の場所";}
	string tempDir() {return "シナリオの一時展開先";}
	string tempDirDesc() {return "wsn圧縮されたシナリオの一時的な展開先を選択してください。";}
	string skin() {return "スキン";}
	string scenarioAuthor() {return "シナリオ作者(新規作成時に自動設定されます)";}
	string historiesSettings() {return "履歴";}
	string openHistoryMax() {return "シナリオ履歴保存件数";}
	string openHistoryClear() {return "クリア";}
	string dlgMsgHistoryClear() {return "シナリオ履歴を削除してよろしいですか？";}
	string searchHistoryMax() {return "検索/置換履歴保存件数";}
	string searchHistoryClear() {return "クリア";}
	string dlgMsgSearchHistoryClear() {return "検索/置換履歴を削除してよろしいですか？";}
	string ignorePaths() {return "無視ファイル(改行区切り)";}
	string settingEtc() {return "その他";}
	string singleWindow() {return "シングルウィンドウモード(再起動後に反映されます)";}
	string smoothingCard() {return "カードのサイズ変更時にスムージングを行う";}
	string expandXMLs() {return "圧縮されたシナリオの読込み時にXMLファイルを展開する";}
	string contentsFloat() {return "コンテンツボックスを別ウィンドウで表示する";}
	string xmlCopy() {return "コピーや切り取りを常にXML形式で行う";}
	string saveInnerImagePath() {return "クラシックなシナリオで格納イメージにファイルパスを埋め込む";}
	string traceDirectories() {
		return "ファイル・" ~ DIR ~ "の変更を自動的に追跡する";
	}

	string bgImageAndKeyCode() {return "背景とキーコード";}
	string newBgImageSetting() {return "新規作成";}
	string delBgImageSetting() {return "削除";}
	string newBgImageSettingName() {return "新規設定";}
	string standardKeyCode() {return "標準のキーコード";}

	string errorEnginePath(string appName) {return appName ~ "の場所が正しくありません。";}
	string errorTempPath() {return "一時展開先が正しくありません。";}

	string outerTools() {return "外部ツール";}
	string outerToolsTitle() {return "外部ツールの設定";}
	string outerToolName() {return "外部ツール名";}
	string outerToolCommand() {return "コマンド";}
	string dlgTitOuterTool() {return "外部ツールの選択";}
	string newOuterToolName() {return "新規外部ツール";}
	string toolsHint1() {return "$F = ファイル名";}
	string toolsHint3() {return "$$ = $";}
	string outerToolWorkDir() {return "作業" ~ DIR;}
	string toolWorkDir() {return "作業" ~ DIR ~ "の選択";}
	string toolWorkDirDesc() {return "外部ツールの作業" ~ DIR ~ "を選択してください。";}
	string toolsHint2() {return "$S = シナリオの" ~ DIR;}
	version (Windows) {
		string[] toolTName() {return ["実行ファイル (*.exe)", "すべてのファイル (*.*)"];}
	} else {
		string[] toolTName() {return ["すべてのファイル (*.*)"];}
	}
	string newOuterTool() {return "新規作成";}
	string delOuterTool() {return "削除";}

	string bgImagesDefault() {return "デフォルト背景";}
	string setBgImagesDefault() {return "デフォルト背景の設定";}
	string dlgTitBgImagesDefault() {return "デフォルト背景の設定";}
}

public class Looks {
public:
	uint cardNameMax() {return 12;}
	string[] fontFiles() {
		return [
			"Data" ~ sep ~ "Font" ~ sep ~ "gothic.ttf",
			"Data" ~ sep ~ "Font" ~ sep ~ "mincho.ttf",
			"Data" ~ sep ~ "Font" ~ sep ~ "uigothic.ttf"
		];
	}
	CPoint castCardNamePoint(){return CPoint(5, 5);}
	CPoint menuCardNamePoint(){return CPoint(5, 5);}
	CPoint cardNamePoint(){return CPoint(5, 5);}
	CSize cardSize(){return CSize(74, 94);}
	CSize summarySize() {return CSize(400, 370);}
	CPoint summaryImageXY() {return CPoint(163, 65);}
	int summaryLevelY() {return 15;}
	int summaryTitleY() {return 35;}
	CPoint summaryDescXY() {return CPoint(65, 175);}
	int summaryDescLen() {return 38;}
	int summaryDescLine() {return 11;}
	int summaryPageY() {return 340;}
	CRGB summaryLevelColor() {return CRGB(32, 128, 128);}
	int posLeftMax() {return 9999;}
	int posLeftMin() {return -9999;}
	int posTopMax() {return 9999;}
	int posTopMin() {return -9999;}
	int backWidthMax() {return 9999;}
	int backWidthMin() {return -9999;}
	int backHeightMax() {return 9999;}
	int backHeightMin() {return -9999;}
	double cardSizeMin(){return 0.50;}
	double cardSizeMax(){return 3.0;}
	CInsets castCardInsets(){return CInsets(18, 11, 18, 10);}
	CInsets menuCardInsets(){return CInsets(13, 3, 3, 3);}
	CInsets cardInsets(){return menuCardInsets;}
	uint partyMax() {return 6;}
	CPoint[] partyCardXY() {
		return [
			CPoint(8, 285),
			CPoint(112, 285),
			CPoint(216, 285),
			CPoint(320, 285),
			CPoint(424, 285),
			CPoint(528, 285)
		];
	}

	CRect messageBounds() {return CRect(81, 50, 470, 180);}
	int messageButtonHeight() {return 26;}
	CRGB messageLineColor1() {return CRGB(0, 0, 0);}
	CRGB messageLineColor2() {return CRGB(128, 0, 0);}
	CRGB messageBackColor() {return CRGB(0, 0, 128);}
	int levelMax() {return 15;}

	int aptVeryHigh() {return 15;}
	int aptHigh() {return 9;}
	int aptNormal() {return 3;}

	CPoint useStoneXY() {return CPoint(60, 75);}
	CPoint aptStoneXY() {return CPoint(60, 90);}

	CPoint premiumXY() {return CPoint(5, 5);}
	uint itemCardMaxNum(uint lev) {
		int r = (lev + 1) / 2 + 2;
		return r <= 10 ? r : 10;
	}
	uint skillCardMaxNum(uint lev) {
		int r = (lev + 1) / 2 + 2;
		return r <= 10 ? r : 10;
	}
	uint beastCardMaxNum(uint lev) {
		int r = (lev + 1) / 4 + 1;
		return r <= 10 ? r : 10;
	}
	int cardDescLen() {return 38;}
	int cardDescLine() {return 7;}

	int messageImageLen() {return 34;}
	int messageLen() {return 44;}
	int messageLine() {return 7;}

	int stepMaxCount() {return 10;}

	uint nameLimit() {return 12;}
	uint castLevelMax() {return 99;}
	uint effectLevelMax() {return 99;}
	uint cardNumberMax() {return 99;}
	uint lifeMax() {return 999;}
	uint lifeCalc(uint lev, uint vit, uint spi) {
		return cast(uint) (((lev + 1.0) * (vit / 2.0 + 4.0)) + (spi / 2.0));
	}
	uint couponValueMax() {return 999;}
	uint physicalMax() {return 15;}
	uint physicalCutMin() {return 1;}
	uint physicalCutMaxBase() {return 6;}
	uint physicalNormal() {return 6;}
	uint[] physicalBorders() {return [1, 6, 12];}
	uint mentalMax() {return 4;}
	uint mentalCut() {return 3;}
	uint[] mentalBorders() {return [3];}

	uint skillLevelMax() {return 999;}
	int skillPrice(int lev) {return (lev + 2) * 200;}
	int beastPrice() {return 500;}
	uint useCountMax() {return 999;}
	uint priceMax() {return 999999;}
	uint enhanceMax() {return 10;}
	int successRateMax() {return 5;}
	int keyCodesMaxLegacy() {return 5;}
	int keyCodesMax() {return 10;}
	uint motionRoundDefault() {return 10;}
	uint motionAbilityValueMax() {return 10;}
	uint motionMaxRound() {return 999;}
	uint motionValueMax() {return 999;}
	uint moneyMax() {return priceMax;}
	uint waitMax() {return 1000;}
	uint roundMax() {return 999;}
	uint paralyzeMax() {return 40;}
	uint poisonMax() {return 40;}
	uint stoneBorder() {return 20;}

	uint idMax() {return 99999;}

	uint transitionSpeedMax() {return 10;}
	uint transitionSpeedDef() {return 5;}

	CSize viewSize() {return CSize(632, 420);}

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
	CFont castCardNameFont(bool legacy){return CFont(uigothic(legacy), 9, true, false);}
	CFont castCardLevelFont(bool legacy){return CFont(mincho(legacy), 24, true, true);}
	CInsets castCardLevelInsets(){return CInsets(2, 8, 0, 0);}
	CRGB castCardLevelColor() {return CRGB(0, 0, 0, 128);}
	CPoint castLifeBarPoint() {return CPoint(8, 110);}
	int statusX() {return 7;}
	uint statusVerMax() {return 6;}
		CFont beastNumFont(bool legacy){return CFont(pgothic(legacy), 9, false, false);}

	CFont menuCardNameFont(bool legacy){return castCardNameFont(legacy);}
	CFont cardNameFont(bool legacy){return castCardNameFont(legacy);}
	CFont useCountFont(bool legacy){return CFont(mincho(legacy), 12, true, false);}
	CPoint useCountPoint(){return CPoint(10, 90);}
	CRGB recycleNumColor() {return CRGB(255, 255, 0);}
	CFont summaryLevelFont(bool legacy) {return CFont(mincho(legacy), 10, true, true);}
	CFont summaryTitleFont(bool legacy) {return CFont(mincho(legacy), 16, true, false);}
	CFont summaryDescFont(bool legacy) {
		version (Windows) {
			if (legacy) return CFont(mincho(legacy), 10, true, false);
		}
		return CFont(gothic(legacy), 10, true, false);
	}
	CFont summaryPageFont(bool legacy) {return CFont(gothic(legacy), 9, true, false);}
	CFont cardDescFont(bool legacy) {return CFont(gothic(legacy), 10, false, false);}
	CFont messageFont(bool legacy) {
		version (Windows) {
			if (legacy) return CFont(mincho(legacy), 16, true, false);
		}
		return CFont(gothic(legacy), 16, false, false);
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
	string appPath() {return _appPath;}
	cwx.system.System sys() {return _sys;}
	Msgs msgs() {return _msgs;}
	Looks looks() {return _looks;}
}
