
module cwx.msgs;

import cwx.types;
import cwx.features;
import cwx.event;
import cwx.motion;
import cwx.structs;
import cwx.menu;
import cwx.utils;
import cwx.settings;
import cwx.versioninfo;

version (Windows) {
	private immutable CARD_WIRTH_PY_EXE = "CardWirthPy.exe";
	private immutable CWX_EDITOR_EXE = "cwxeditor.exe";
	private immutable DIR = "フォルダ";
} else {
	private immutable CARD_WIRTH_PY_EXE = "CardWirthPy";
	private immutable CWX_EDITOR_EXE = "cwxeditor";
	private immutable DIR = "ディレクトリ";
}

class Msgs : Properties {
	private template Msg(string Name, string Default) {
		mixin Property!(Name, string, Default, true);
	}

	mixin PropertyAttr!("locale", string, "ja-JP", true);
	mixin PropertyAttr!("version", ulong, APP_VERSION_NUM, true);

	mixin Msg!("application", "CWXEditor");
	mixin Msg!("localeName", "日本語");
	mixin Msg!("dlgTitVersion", "バージョン情報");
	mixin Msg!("appDesc", "CardWirthPy向けシナリオエディタ");

	mixin Msg!("dlgTitUsage", "使い方 - CWXEditor");
	mixin Msg!("usage", "使い方: cwxeditor [-help | -putlangfile <PATH> | -conf <PATH>\n"
		"                   | -create <NAME> [<SKIN>] | -createclassic <NAME> [<PATH>]]\n"
		"                   <SCENARIO> [<CWXPath ...>]\n"
		"オプション:\n"
		"  -help         起動オプションの説明を表示して終了します。\n"
		"  -putlangfile <PATH> デフォルトの言語設定ファイル<PAHT>を出力して終了します。\n"
		"  -conf <PATH>  指定されたパスの基本設定ファイルを使用します。\n"
		"  -create        <NAME> [<SKIN>]  起動後にシナリオを新規作成します。\n"
		"  -createclassic <NAME> [<PATH>]  起動後、<PATH>で指定されたフォルダに\n"
		"                                  クラシックなシナリオを新規作成します。\n"
		"  <SCENARIO>    起動と同時に指定されたシナリオを開きます。\n"
		"                (*.wsn/Summary.xml/Summary.wsm/[フォルダ])\n"
		"OpenID:\n"
		"  -a <ID>       シナリオを開いた後、<ID>で指定したIDのエリアを開きます。\n"
		"  -b <ID>       シナリオを開いた後、<ID>で指定したIDのバトルを開きます。\n"
		"  -p <ID>       シナリオを開いた後、<ID>で指定したIDのパッケージを開きます。\n"
		"CWXPath:\n"
		"  <CWXPath>     シナリオを開いた後、<CWXPath>で指定したリソースを開きます。");

	mixin Msg!("dlgTitError", "エラー - CWXEditor");
	mixin Msg!("dlgTitWarning", "警告 - CWXEditor");
	mixin Msg!("dlgTitQuestion", "確認 - CWXEditor");
	mixin Msg!("unknownError", "処理の途中でCWXEditorの制作者が意図していないエラーが発生しました。"
		"データが壊れている可能性を考慮して、シナリオを保存せずに終了する事をお勧めします。\n"
		"エラー内容は" ~ CWX_EDITOR_EXE ~ "と同じ" ~ DIR ~ "にあるcwxeditor_error.logに記録されます。");
	mixin Msg!("shutdown", "強制終了");

	mixin Msg!("dlgTextOK", "&OK");
	mixin Msg!("dlgTextApply", "適用");
	mixin Msg!("dlgTextCancel", "キャンセル");

	mixin Msg!("apply", "適用");
	mixin Msg!("del", "削除");

	mixin Msg!("filterAll", "すべてのファイル (*.*)");

	mixin Msg!("fileCopyError", "%1$sのコピー中にエラーが発生しました。");
	mixin Msg!("reloadError", "%1$sの再読込中にエラーが発生しました。");
	mixin Msg!("loadProgress", "%2$s%% 完了 - %1$sを展開中");
	mixin Msg!("loading", "%1$sの読込みを開始");
	mixin Msg!("loaded", "%1$sの読込みを完了");
	mixin Msg!("loadedCount", "%1$s件の読込みを完了");
	mixin Msg!("reconstructionStatus", "編集状態を復元中 (%1$s/%2$s)");
	mixin Msg!("cwxPathOpenError", "パス [%1$s] を開けません。");
	mixin Msg!("filePathOpenError", "パス [%1$s] を開けません。");

	mixin Msg!("loadSkinError", "デフォルトのスキン「%1$s」が見つかりません。\n" ~ CARD_WIRTH_PY_EXE ~ "本体の場所が正しくないか、Data" ~ DIR ~ "が正しく配置されていない可能性があります。\nこのまま開始すると、一部リソース画像が非表示になります。");
	mixin Msg!("useDefaultSkin", "スキン「%1$s」が見つかりません。\nデフォルトのスキン「%1$s」を使用します。");
	mixin Msg!("scenarioName", "シナリオ名");
	mixin Msg!("type", "タイプ");
	mixin Msg!("initialize", "初期設定");
	mixin Msg!("classic", "[クラシック]");
	mixin Msg!("scenarioTemplate", "テンプレート");
	mixin Msg!("templateDesc", "%1$s [%2$s]");
	mixin Msg!("noTemplate", "[テンプレート無し]");
	mixin Msg!("newClassicDir", "シナリオ作成先の選択");
	mixin Msg!("newClassicDirDesc", "シナリオを作成する" ~ DIR ~ "を選択してください。");
	mixin Msg!("notEmptyDir", "%1$sは空ではありません。\n本当にここでシナリオを作成しますか？");

	mixin Msg!("newScenarioName", "新規シナリオ");

	mixin Msg!("dlgTitSaveBitmapImage", "格納イメージの保存");
	mixin Msg!("filterBitmapImage", "ビットマップイメージ (*.bmp)");

	mixin Msg!("newFolder", "新規" ~ DIR);

	mixin Msg!("dlgMsgDeleteFile", "%1$sを完全に削除しますか？");
	mixin Msg!("dlgMsgDeleteFiles", "%1$s個の項目を完全に削除しますか？");
	mixin Msg!("dlgMsgDeleteFileRecycle", "%1$sをごみ箱に移動しますか？");
	mixin Msg!("dlgMsgDeleteFilesRecycle", "%1$s個の項目をごみ箱に移動しますか？");
	mixin Msg!("dlgMsgDeleteUnuse", "%1$s個の未使用ファイル・" ~ DIR ~ "を完全に削除しますか？");
	mixin Msg!("dlgMsgDeleteRecycleUnuse", "%1$s個の未使用ファイル・" ~ DIR ~ "をごみ箱に移動しますか？");

	mixin Msg!("image", "イメージ");
	mixin Msg!("pathDef", "[デフォルト]");
	mixin Msg!("imageNone", "[イメージ無し]");
	mixin Msg!("fileNone", "[ファイルを選択]");
	mixin Msg!("imageIncluding", "[イメージ格納]");
	mixin Msg!("seNone", "[サウンド無し]");
	mixin Msg!("bgmStop", "[BGM停止]");
	mixin Msg!("bgmNone", "[BGM無し]");
	mixin Msg!("dlgMsgIsSaveBeforeReload", "「%1$s」は変更されています。再読込しますか？");
	mixin Msg!("reloadBeforeSaveError", "「%1$s」は保存されていないため、再読込できません。");
	mixin Msg!("dlgMsgIsSaveBeforeExit", "「%1$s」は変更されています。保存しますか？");
	mixin Msg!("dlgMsgDropFile", "%1$sをシナリオ" ~ DIR ~ "にコピーしますか？");
	mixin Msg!("dlgMsgDropFiles", "%1$s個のファイルをシナリオ" ~ DIR ~ "にコピーしますか？");
	mixin Msg!("dlgMsgDropOverWriteFile", "%1$sはすでに存在します。上書きしますか？");
	mixin Msg!("dlgMsgDropOverWriteFiles", "%1$s個の項目がすでに存在します。上書きしますか？");
	mixin Msg!("dlgTitDropFiles", "素材ファイルの追加");
	mixin Msg!("dlgMsgCopyError", "いくつかのファイルのコピーに失敗しました。");

	mixin Msg!("dlgMsgCopyMaterial1", "格納画像もコピーしますか？");
	mixin Msg!("dlgMsgCopyMaterial2", "素材もコピーしますか？\n%1$s");
	mixin Msg!("dlgMsgCopyMaterial3", "素材もコピーしますか？\n%1$s個のファイル");
	mixin Msg!("dlgMsgCopyMaterial4", "素材もコピーしますか？\n%1$s個のファイルと%2$s個の格納画像");

	mixin Msg!("incSearchContains", "名前の一部");
	mixin Msg!("incSearchWildcard", "ワイルドカード");
	mixin Msg!("incSearchRegex", "正規表現");

	mixin Msg!("dlgTitSettings", "CWXEditorの設定");

	mixin Msg!("refreshS", "更新");

	mixin Msg!("summary", "シナリオの設定");
	mixin Msg!("area", "エリア");
	mixin Msg!("battle", "バトル");
	mixin Msg!("cwPackage", "パッケージ");

	mixin Msg!("dlgTitReplaceText", "検索と置換");
	mixin Msg!("replForText", "テキスト検索");
	mixin Msg!("replForID", "ID検索");
	mixin Msg!("replForPath", "素材検索");
	mixin Msg!("replContents", "コンテント検索");
	mixin Msg!("replForCoupon", "称号・名称一覧");
	mixin Msg!("replForUnuse", "未使用検索");
	mixin Msg!("replForError", "誤り検索");

	mixin Msg!("searchRange", "検索対象");
	mixin Msg!("flagsAndSteps", "フラグとステップ");
	mixin Msg!("allCheckRange", "全てチェック/全てチェックを外す");

	mixin Msg!("allCheck", "全てチェック/全てチェックを外す(&L)");
	mixin Msg!("allSelect", "全て選択/全て選択を外す(&L)");

	mixin Msg!("replError", "重複する分岐(フラグ分岐が両方ともTRUEになっている等)・条件クーポンに抜けがある台詞コンテント・存在しない素材を参照しているコンテント等を検索します。");

	mixin Msg!("replFrom", "検索(置換前)");
	mixin Msg!("replTo", "置換後");

	mixin Msg!("replText", "検索/置換するテキスト");
	mixin Msg!("replTextTarget", "検索/置換対象");
	mixin Msg!("replTextSummary", "貼り紙");
	mixin Msg!("replTextMessage", "メッセージ");
	mixin Msg!("replTextCardName", "カード名");
	mixin Msg!("replTextCardDesc", "カード解説");
	mixin Msg!("replTextEventText", "イベントテキスト");
	mixin Msg!("replTextStart", "スタートコンテント");
	mixin Msg!("replTextFlagAndStep", "フラグ/ステップ");
	mixin Msg!("replTextCoupon", "クーポン");
	mixin Msg!("replTextGossip", "ゴシップ");
	mixin Msg!("replTextEndScenario", "終了印");
	mixin Msg!("replTextAreaName", "エリア/バトル/パッケージ名");
	mixin Msg!("replTextKeyCode", "キーコード");
	mixin Msg!("replTextFile", "ファイル名");
	mixin Msg!("replTextComment", "コメント");
	mixin Msg!("replTextJptx", "JPTXテキスト");

	mixin Msg!("replID", "検索/置換対象");
	mixin Msg!("replIDKind", "対象");
	mixin Msg!("replIDArea", "エリア");
	mixin Msg!("replIDBattle", "バトル");
	mixin Msg!("replIDPackage", "パッケージ");
	mixin Msg!("replIDCast", "キャストカード");
	mixin Msg!("replIDSkill", "特殊技能カード");
	mixin Msg!("replIDItem", "アイテムカード");
	mixin Msg!("replIDBeast", "召喚獣カード");
	mixin Msg!("replIDInfo", "情報カード");
	mixin Msg!("replSetID", "[IDを直接指定]");

	mixin Msg!("replPath", "検索/置換する素材");

	mixin Msg!("replUnuseTarget", "検索対象");
	mixin Msg!("replUnuseFlag", "フラグ");
	mixin Msg!("replUnuseStep", "ステップ");
	mixin Msg!("replUnuseArea", "エリア");
	mixin Msg!("replUnuseBattle", "バトル");
	mixin Msg!("replUnusePackage", "パッケージ");
	mixin Msg!("replUnuseCast", "キャストカード");
	mixin Msg!("replUnuseSkill", "特殊技能カード");
	mixin Msg!("replUnuseItem", "アイテムカード");
	mixin Msg!("replUnuseBeast", "召喚獣カード");
	mixin Msg!("replUnuseInfo", "情報カード");
	mixin Msg!("replUnuseStart", "スタートコンテント");
	mixin Msg!("replUnusePath", "素材");

	mixin Msg!("replNotIgnoreCase", "大文字と小文字を区別する(&C)");
	mixin Msg!("replRegExp", "正規表現(&E) (. = 任意1文字, * = 直前の文字の任意数繰返し, $1 = 1つめの文字列グループ ...)");
	mixin Msg!("regexError", "正規表現が正しくありません。");
	mixin Msg!("replWildcard", "ワイルドカード(&W) (* = 任意文字列, ? = 任意1文字, \\* = *, \\? = ?, \\\\ = \\)");
	mixin Msg!("replCond", "検索条件");
	mixin Msg!("search", "検索(&F)");
	mixin Msg!("replace", "全て置換(&R)");
	mixin Msg!("replaceExit", "閉じる");
	mixin Msg!("searchResultEmpty", "0件の検索結果");
	mixin Msg!("searchResult", "%1$s件の検索結果(%2$s)");
	mixin Msg!("replResultEmpty", "0箇所の置換");
	mixin Msg!("replResult", "%1$s箇所の置換(%2$s)");
	mixin Msg!("replaceUndo", "%1$s件を元に戻しました");
	mixin Msg!("replaceRedo", "%1$s件をやり直しました");

	mixin Msg!("searchResultBgImage", "背景画像 [%1$s]");
	mixin Msg!("searchResultIds", "%1$s [%2$s.%3$s]");

	mixin Msg!("searchResultFlag", "フラグ [%1$s]");
	mixin Msg!("searchResultStep", "ステップ [%1$s]");
	mixin Msg!("searchResultFlagDir", "ディレクトリ [%1$s]");
	mixin Msg!("searchResultEventTree", "イベントツリー [%1$s]");
	mixin Msg!("searchResultMenuCard", "メニューカード [%1$s]");
	mixin Msg!("searchResultEnemyCard", "エネミーカード [%1$s]");

	mixin Msg!("searchErrorNoImage", "イメージ指定無し");
	mixin Msg!("searchErrorImageNotFound", "イメージファイルが見つからない");
	mixin Msg!("searchErrorBGMNotFound", "BGMファイルが見つからない");
	mixin Msg!("searchErrorSENotFound", "効果音ファイルが見つからない");
	mixin Msg!("searchErrorStartAreaNotFound", "開始エリア無し");
	mixin Msg!("searchErrorFlagNotFound", "フラグが見つからない");
	mixin Msg!("searchErrorStepNotFound", "ステップが見つからない");
	mixin Msg!("searchErrorNoCast", "キャストカード指定無し");
	mixin Msg!("searchErrorNoBeast", "召喚獣カード指定無し");
	mixin Msg!("searchErrorDupNextContent", "分岐条件の重複");
	mixin Msg!("searchErrorSPFontNotFound", "特殊フォントイメージが見つからない");
	mixin Msg!("searchErrorNoRCouponsDialog", "最終項目以外にクーポン指定無し項目あり");
	mixin Msg!("searchErrorAreaNotFound", "エリアが見つからない");
	mixin Msg!("searchErrorBattleNotFound", "バトルが見つからない");
	mixin Msg!("searchErrorPackageNotFound", "パッケージが見つからない");
	mixin Msg!("searchErrorCastNotFound", "キャストカードが見つからない");
	mixin Msg!("searchErrorSkillNotFound", "スキルカードが見つからない");
	mixin Msg!("searchErrorItemNotFound", "アイテムカードが見つからない");
	mixin Msg!("searchErrorBeastNotFound", "召喚獣カードが見つからない");
	mixin Msg!("searchErrorInfoNotFound", "情報カードが見つからない");
	mixin Msg!("searchErrorStartNotFound", "スタートコンテントが見つからない");
	mixin Msg!("searchErrorIgnoreWait", "後続コンテントが無いため、空白時間が無視される");
	mixin Msg!("searchErrorLinkIdNotFound", "参照先のカードが見つからない");
	mixin Msg!("searchOpenDialog", "検索結果へジャンプする時、ダイアログを開く");

	/// イベント設定。
	mixin Msg!("dlgTitContent", "イベントの設定 [ %1$s ]");

	mixin Msg!("afterClear", "シナリオ終了後");
	mixin Msg!("afterClearEndMark", "シナリオに済印を付ける");
	mixin Msg!("afterClearNoEndMark", "何もしない");

	mixin Msg!("couponName", "クーポン名");
	mixin Msg!("couponValue", "得点");
	mixin Msg!("couponValueRange", "(%1$s～%2$s)");
	mixin Msg!("range", "適用範囲");
	mixin Msg!("gossipName", "ゴシップ名");
	mixin Msg!("endName", "シナリオ名");

	mixin Msg!("couponHide", "隠蔽クーポン");

	mixin(EnumToStringMethod!(CouponType, "couponTypeDesc", "couponTypeDesc"));
	mixin Msg!("couponTypeDescNormal", "ノーマル");
	mixin Msg!("couponTypeDescHide", "[＿...] 隠蔽(称号一覧で非表示)");
	mixin Msg!("couponTypeDescSystem", "[＠...] システム");
	mixin Msg!("couponTypeDescDur", "[：...] 時限(点数分の時間経過及びシナリオ終了時に消滅)");
	mixin Msg!("couponTypeDescDurBattle", "[；...] 戦闘中時限(点数分の時間経過及び戦闘終了時に消滅)");

	mixin Msg!("imageMessage", "イメージ付きメッセージ");
	mixin Msg!("noImageMessage", "イメージ無しメッセージ");
	mixin Msg!("spCharsTitle", "特殊文字");
	mixin Msg!("colorW", "デフォルト(&W)");
	mixin Msg!("colorR", "赤(&R)");
	mixin Msg!("colorB", "青(&B)");
	mixin Msg!("colorG", "緑(&G)");
	mixin Msg!("colorY", "黄(&Y)");
	mixin(EnumToStringMethod!(Talker, "scTalkerName", "scTalkerName"));
	mixin Msg!("scTalkerNameSelected", "選択メンバ名(#M)");
	mixin Msg!("scTalkerNameUnselected", "選択外ランダムメンバ名(#U)");
	mixin Msg!("scTalkerNameRandom", "ランダムメンバ名(#R)");
	mixin Msg!("scTalkerNameCard", "選択カード名(#C)");
	mixin Msg!("scTalkerNameNarration", "話者無し");
	mixin Msg!("scTalkerNameImage", "画像");
	mixin Msg!("scRef", "話者(#I)");
	mixin Msg!("scTeam", "チーム名(#T)");
	mixin Msg!("scYado", "宿屋名(#Y)");
	mixin Msg!("addMsgRefFlag", "フラグ参照の追加");
	mixin Msg!("addMsgRefStep", "ステップ参照の追加");
	mixin Msg!("createDialog", "台詞の作成");
	mixin Msg!("deleteDialog", "台詞の削除");
	mixin Msg!("copyToDialogs", "台詞を全体にコピー");
	mixin Msg!("copyToUpper", "台詞を上方にコピー");
	mixin Msg!("copyToLower", "台詞を下方にコピー");
	mixin Msg!("setTalkerCoupon", "追加");
	mixin Msg!("messagePreview", "プレビュー");
	mixin Msg!("dlgTitMessagePreview", "プレビュー");
	mixin Msg!("messageVarKindColumn", "状態変数");
	mixin Msg!("messageVarValueColumn", "サンプル値");

	mixin Msg!("transition", "背景切替方式");
	mixin(EnumToStringMethod!(Transition, "transitionName", "transitionName"));
	mixin Msg!("transitionNameDefault", "[プレイヤーの設定を使用]");
	mixin Msg!("transitionNameNone", "アニメーション無し");
	mixin Msg!("transitionNameFade", "フェード式");
	mixin Msg!("transitionNamePixelDissolve", "ピクセルディゾルブ式");
	mixin Msg!("transitionNameBlinds", "ブラインド式");
	mixin Msg!("transitionSpeed", "背景切替ウェイト");
	mixin Msg!("waitName", "空白時間(0.1秒単位)");
	mixin Msg!("moneyName", "金額");
	mixin Msg!("randomName", "確率(%)");
	mixin Msg!("partyNumName", "パーティの人数");
	mixin Msg!("judgeTarget", "判定対象");
	mixin Msg!("flag", "フラグ");
	mixin Msg!("step", "ステップ");
	mixin Msg!("flagValue", "値");
	mixin Msg!("stepValue", "段階");
	mixin Msg!("selectMember", "選択対象");
	mixin Msg!("activeMember", "動けるメンバから選択");
	mixin Msg!("allMember", "パーティ全員から選択");
	mixin Msg!("selectMethod", "選択方法");
	mixin Msg!("manualMethod", "手動で選択");
	mixin Msg!("randomMethod", "ランダムで選択");
	mixin Msg!("judgeSleep", "眠り判定");
	mixin Msg!("sleepDisabled", "睡眠者無効");
	mixin Msg!("sleepEnabled", "睡眠者有効");
	mixin Msg!("selectedLevel", "現在選択中のメンバ");
	mixin Msg!("allMemberLevel", "パーティ全員の平均値");
	mixin Msg!("judgeLevel", "判定レベル");
	mixin Msg!("judgeState", "判定状態");
	mixin Msg!("stateHint", "ヒント");
	mixin Msg!("cardNumber", "枚数");
	mixin Msg!("cardAllDelete", "全て削除する");
	mixin Msg!("cardEventRange", "適用範囲");
	mixin Msg!("transitionType", "背景切替方式");

	/// イベント。
	mixin Msg!("evtArrow", "イベント編集");

	mixin Msg!("evtAddContinue", "連続で配置");
	mixin Msg!("evtAutoOpen", "配置と同時に編集");

	mixin(EnumToStringMethod!(CType, "contentName", "contentName"));
	mixin Msg!("contentNameStart", "スタート");
	mixin Msg!("contentNameStartBattle", "バトル開始");
	mixin Msg!("contentNameEnd", "シナリオクリア");
	mixin Msg!("contentNameEndBadEnd", "ゲームオーバー");
	mixin Msg!("contentNameChangeArea", "エリア移動");
	mixin Msg!("contentNameChangeBgImage", "背景変更");
	mixin Msg!("contentNameEffect", "効果");
	mixin Msg!("contentNameEffectBreak", "効果中断");
	mixin Msg!("contentNameLinkStart", "スタートへのリンク");
	mixin Msg!("contentNameLinkPackage", "パッケージへのリンク");
	mixin Msg!("contentNameTalkMessage", "メッセージ");
	mixin Msg!("contentNameTalkDialog", "セリフ");
	mixin Msg!("contentNamePlayBgm", "BGM変更");
	mixin Msg!("contentNamePlaySound", "効果音");
	mixin Msg!("contentNameWait", "空白時間挿入");
	mixin Msg!("contentNameElapseTime", "時間経過");
	mixin Msg!("contentNameCallStart", "スタートの呼び出し");
	mixin Msg!("contentNameCallPackage", "パッケージの呼び出し");
	mixin Msg!("contentNameBranchFlag", "フラグ分岐");
	mixin Msg!("contentNameBranchMultiStep", "ステップ多岐分岐");
	mixin Msg!("contentNameBranchStep", "ステップ上下分岐");
	mixin Msg!("contentNameBranchSelect", "メンバ選択分岐");
	mixin Msg!("contentNameBranchAbility", "能力判定分岐");
	mixin Msg!("contentNameBranchRandom", "ランダム分岐");
	mixin Msg!("contentNameBranchLevel", "レベル判定分岐");
	mixin Msg!("contentNameBranchStatus", "状態判定分岐");
	mixin Msg!("contentNameBranchPartyNumber", "人数判定分岐");
	mixin Msg!("contentNameBranchArea", "エリア分岐");
	mixin Msg!("contentNameBranchBattle", "バトル分岐");
	mixin Msg!("contentNameBranchIsBattle", "バトル判定分岐");
	mixin Msg!("contentNameBranchCast", "キャスト存在分岐");
	mixin Msg!("contentNameBranchItem", "アイテム所持分岐");
	mixin Msg!("contentNameBranchSkill", "スキル所持分岐");
	mixin Msg!("contentNameBranchInfo", "情報所持分岐");
	mixin Msg!("contentNameBranchBeast", "召喚獣存在分岐");
	mixin Msg!("contentNameBranchMoney", "所持金分岐");
	mixin Msg!("contentNameBranchCoupon", "クーポン分岐");
	mixin Msg!("contentNameBranchCompleteStamp", "終了シナリオ分岐");
	mixin Msg!("contentNameBranchGossip", "ゴシップ分岐");
	mixin Msg!("contentNameSetFlag", "フラグ変更");
	mixin Msg!("contentNameSetStep", "ステップ変更");
	mixin Msg!("contentNameSetStepUp", "ステップ増加");
	mixin Msg!("contentNameSetStepDown", "ステップ減少");
	mixin Msg!("contentNameReverseFlag", "フラグ反転");
	mixin Msg!("contentNameCheckFlag", "フラグ判定");
	mixin Msg!("contentNameGetCast", "キャスト加入");
	mixin Msg!("contentNameGetItem", "アイテム入手");
	mixin Msg!("contentNameGetSkill", "スキル取得");
	mixin Msg!("contentNameGetInfo", "情報入手");
	mixin Msg!("contentNameGetBeast", "召喚獣獲得");
	mixin Msg!("contentNameGetMoney", "所持金増加");
	mixin Msg!("contentNameGetCoupon", "クーポン取得");
	mixin Msg!("contentNameGetCompleteStamp", "終了シナリオ設定");
	mixin Msg!("contentNameGetGossip", "ゴシップ追加");
	mixin Msg!("contentNameLoseCast", "キャスト離脱");
	mixin Msg!("contentNameLoseItem", "アイテム喪失");
	mixin Msg!("contentNameLoseSkill", "スキル喪失");
	mixin Msg!("contentNameLoseInfo", "情報喪失");
	mixin Msg!("contentNameLoseBeast", "召喚獣消去");
	mixin Msg!("contentNameLoseMoney", "所持金減少");
	mixin Msg!("contentNameLoseCoupon", "クーポン削除");
	mixin Msg!("contentNameLoseCompleteStamp", "終了シナリオ削除");
	mixin Msg!("contentNameLoseGossip", "ゴシップ削除");
	mixin Msg!("contentNameShowParty", "パーティ表示");
	mixin Msg!("contentNameHideParty", "パーティ隠蔽");
	mixin Msg!("contentNameRedisplay", "画面再構築");

	mixin Msg!("msnGroupVitality", "生命力");
	mixin Msg!("msnGroupPhysical", "肉体");
	mixin Msg!("msnGroupSkill", "技能");
	mixin Msg!("msnGroupMental", "精神");
	mixin Msg!("msnGroupMagic", "魔法");
	mixin Msg!("msnGroupEnhance", "能力");
	mixin Msg!("msnGroupVanish", "消滅");
	mixin Msg!("msnGroupCard", "カード");
	mixin Msg!("msnGroupBeast", "召喚");

	mixin Msg!("msnDelete", "効果削除");

	mixin Msg!("msnDesc", "%1$s - %2$s");

	mixin(EnumToStringMethod!(MType, "motionName", "motionName"));
	mixin Msg!("motionNameHeal", "回復");
	mixin Msg!("motionNameDamage", "ダメージ");
	mixin Msg!("motionNameAbsorb", "吸収");
	mixin Msg!("motionNameParalyze", "麻痺");
	mixin Msg!("motionNameDisParalyze", "麻痺解除");
	mixin Msg!("motionNamePoison", "中毒");
	mixin Msg!("motionNameDisPoison", "中毒解除");
	mixin Msg!("motionNameGetSkillPower", "精神力回復");
	mixin Msg!("motionNameLoseSkillPower", "精神力喪失");
	mixin Msg!("motionNameSleep", "睡眠状態");
	mixin Msg!("motionNameConfuse", "混乱状態");
	mixin Msg!("motionNameOverheat", "激昂状態");
	mixin Msg!("motionNameBrave", "勇敢状態");
	mixin Msg!("motionNamePanic", "恐慌状態");
	mixin Msg!("motionNameNormal", "正常状態");
	mixin Msg!("motionNameBind", "呪縛");
	mixin Msg!("motionNameDisBind", "呪縛解除");
	mixin Msg!("motionNameSilence", "沈黙");
	mixin Msg!("motionNameDisSilence", "沈黙解除");
	mixin Msg!("motionNameFaceUp", "暴露");
	mixin Msg!("motionNameFaceDown", "暴露解除");
	mixin Msg!("motionNameAntiMagic", "魔法無効化");
	mixin Msg!("motionNameDisAntiMagic", "魔法無効化解除");
	mixin Msg!("motionNameEnhanceAction", "行動力変化");
	mixin Msg!("motionNameEnhanceAvoid", "回避力変化");
	mixin Msg!("motionNameEnhanceDefense", "防御力変化");
	mixin Msg!("motionNameEnhanceResist", "抵抗力変化");
	mixin Msg!("motionNameVanishTarget", "対象消去");
	mixin Msg!("motionNameVanishCard", "手札消去");
	mixin Msg!("motionNameVanishBeast", "召喚獣消去");
	mixin Msg!("motionNameDealAttackCard", "通常攻撃");
	mixin Msg!("motionNameDealPowerfulAttackCard", "渾身の一撃");
	mixin Msg!("motionNameDealCriticalAttackCard", "会心の一撃");
	mixin Msg!("motionNameDealFeintCard", "フェイント");
	mixin Msg!("motionNameDealDefenseCard", "防御");
	mixin Msg!("motionNameDealDistanceCard", "見切り");
	mixin Msg!("motionNameDealConfuseCard", "混乱");
	mixin Msg!("motionNameDealSkillCard", "特殊技能");
	mixin Msg!("motionNameSummonBeast", "召喚獣召喚");

	mixin Msg!("dialogText", "%2$s: %1$s");
	mixin Msg!("dialogTextNoCoupon", "%1$s");

	mixin Msg!("ctStart", "スタートコンテント「%1$s」");
	mixin Msg!("ctStartBattle", "バトルの開始「%1$s」");
	mixin Msg!("ctChangeArea", "エリア移動「%1$s」 切替方式 = %2$s ウェイト = %3$s");
	mixin Msg!("ctChangeAreaClassic", "エリア移動「%1$s」");
	mixin Msg!("ctEndComplete", "済印をつけて終了");
	mixin Msg!("ctEndNoComplete", "済印をつけずに終了");
	mixin Msg!("ctGameOver", "ゲームオーバーコンテント");
	mixin Msg!("ctChangeBgImage", "背景ファイル = %1$s 切替方式 = %2$s ウェイト = %3$s");
	mixin Msg!("ctChangeBgImageClassic", "背景ファイル = %1$s");
	mixin Msg!("ctChangeBgImageFile", "[%1$s]");
	mixin Msg!("ctEffectSound", "「%1$s」を再生");
	mixin Msg!("ctEffectNoSound", "音声無し");
	mixin Msg!("ctEffect", "%1$s レベル%2$s %3$s/%4$s 成功率%5$s%6$s %7$s %8$s 効果 = %9$s");
	mixin Msg!("ctEffectMotion", "[%1$s]");
	mixin Msg!("ctEffectBreak", "効果中断コンテント");
	mixin Msg!("ctStopBGM", "BGM停止");
	mixin Msg!("ctLinkStart", "スタートコンテント「%1$s」へのリンク");
	mixin Msg!("ctLinkPackage", "パッケージ「%1$s」へのリンク");
	mixin Msg!("ctTalkMessage", "%1$s: %2$s");
	mixin Msg!("ctTalkMessageImage", "[%1$s]");
	mixin Msg!("ctTalkDialog", "%1$s %2$s: %3$s");
	mixin Msg!("ctTalkDialogNoCoupon", "%1$s: %2$s");
	mixin Msg!("ctPlayBGM", "BGMとして「%1$s」を演奏");
	mixin Msg!("ctPlaySound", "効果音「%1$s」を鳴らす");
	mixin Msg!("ctWait", "空白時間 = %1$s × 0.1秒");
	mixin Msg!("ctElapseTime", "ターン数経過コンテント");
	mixin Msg!("ctCallStart", "スタートコンテント「%1$s」のコール");
	mixin Msg!("ctCallPackage", "パッケージ「%1$s」のコール");
	mixin Msg!("ctBranchFlag", "フラグ「%1$s」の値で分岐");
	mixin Msg!("ctBranchMultiStep", "ステップ「%1$s」の値で分岐");
	mixin Msg!("ctBranchStep", "ステップ「%1$s」の値が[%2$s]以上・未満で分岐");
	mixin Msg!("ctBranchSelectAll", "パーティ全員");
	mixin Msg!("ctBranchSelectActive", "動けるメンバ");
	mixin Msg!("ctBranchSelectAuto", "ランダム");
	mixin Msg!("ctBranchSelectManual", "手動");
	mixin Msg!("ctBranchSelect", "%1$sから%2$sでメンバを選択");
	mixin Msg!("ctBranchAbility", "%1$s(%2$s)の%3$sと%4$sで能力判定(レベル%5$s)");
	mixin Msg!("ctBranchRandom", "確率 = %1$s%%");
	mixin Msg!("ctBranchLevelAverage", "パーティ全員");
	mixin Msg!("ctBranchLevelSelected", "選択中のメンバ");
	mixin Msg!("ctBranchLevel", "%1$sのレベルが%2$s以上・未満で分岐");
	mixin Msg!("ctBranchStatus", "%1$sが%2$s状態か否かで分岐");
	mixin Msg!("ctBranchPartyNumber", "人数 = %1$s人");
	mixin Msg!("ctBranchArea", "エリア分岐コンテント");
	mixin Msg!("ctBranchBattle", "バトル分岐コンテント");
	mixin Msg!("ctBranchIsBattle", "戦闘中判定分岐コンテント");
	mixin Msg!("ctBranchCast", "キャストカード「%1$s」の同行有無で分岐");
	mixin Msg!("ctBranchSkill", "特殊技能カード「%1$s」の有無で分岐(%2$sに%3$s枚)");
	mixin Msg!("ctBranchItem", "アイテムカード「%1$s」の有無で分岐(%2$sに%3$s枚)");
	mixin Msg!("ctBranchBeast", "召喚獣カード「%1$s」の有無で分岐(%2$sに%3$s枚)");
	mixin Msg!("ctBranchInfo", "情報カード「%1$s」の有無で分岐");
	mixin Msg!("ctBranchMoney", "分岐金額 = %1$ssp");
	mixin Msg!("ctBranchCoupon", "称号「%1$s」の有無で分岐(%2$s)");
	mixin Msg!("ctBranchCompleteStamp", "シナリオ「%1$s」が終了済みか否かで分岐");
	mixin Msg!("ctBranchGossip", "ゴシップ「%1$s」の有無で分岐");
	mixin Msg!("ctSetFlag", "フラグ「%1$s」を[%2$s]に変更");
	mixin Msg!("ctSetStep", "ステップ「%1$s」を[%2$s]に変更");
	mixin Msg!("ctSetStepUp", "ステップ「%1$s」の値を1増加");
	mixin Msg!("ctSetStepDown", "ステップ「%1$s」の値を1減少");
	mixin Msg!("ctReverseFlag", "フラグ「%1$s」の値を反転");
	mixin Msg!("ctCheckFlag", "フラグ「%1$s」の値が[%2$s]であれば出現");
	mixin Msg!("ctGetCast", "キャストカード「%1$s」を同行させる");
	mixin Msg!("ctGetSkill", "特殊技能カード「%1$s」を獲得(%2$sに%3$s枚)");
	mixin Msg!("ctGetItem", "アイテムカード「%1$s」を獲得(%2$sに%3$s枚)");
	mixin Msg!("ctGetBeast", "召喚獣カード「%1$s」を獲得(%2$sに%3$s枚)");
	mixin Msg!("ctGetInfo", "情報カード「%1$s」を獲得");
	mixin Msg!("ctGetMoney", "獲得金額 = %1$ssp");
	mixin Msg!("ctGetCoupon", "称号「%1$s」を獲得(%2$s)");
	mixin Msg!("ctGetCompleteStamp", "シナリオ%1$sを終了済みにする");
	mixin Msg!("ctGetGossip", "ゴシップ「%1$s」を獲得");
	mixin Msg!("ctLoseCardAll", "全て");
	mixin Msg!("ctLoseCardCount", "%1$s枚");
	mixin Msg!("ctLoseCast", "キャストカード「%1$s」の同行を解除");
	mixin Msg!("ctLoseSkill", "特殊技能カード「%1$s」を喪失(%2$sから%3$s)");
	mixin Msg!("ctLoseItem", "アイテムカード「%1$s」を喪失(%2$sから%3$s)");
	mixin Msg!("ctLoseBeast", "召喚獣カード「%1$s」を喪失(%2$sから%3$s)");
	mixin Msg!("ctLoseInfo", "情報カード「%1$s」を喪失");
	mixin Msg!("ctLoseMoney", "喪失金額 = %1$ssp");
	mixin Msg!("ctLoseCoupon", "称号「%1$s」を喪失(%2$s)");
	mixin Msg!("ctLoseCompleteStamp", "シナリオ%1$sの終了印を削除");
	mixin Msg!("ctLoseGossip", "ゴシップ「%1$s」を喪失");
	mixin Msg!("ctShowParty", "パーティ表示コンテント");
	mixin Msg!("ctHideParty", "パーティ隠蔽コンテント");
	mixin Msg!("ctRedisplay", "切替方式 = %1$s ウェイト = %2$s");
	mixin Msg!("ctRedisplayClassic", "画面再構築コンテント");

	mixin Msg!("defaultStartName", "イベント開始");

	mixin Msg!("oggMayNotCorrespond", "Oggはプレイヤーの環境によって再生できない事があります。");
	mixin Msg!("mp3LoopMayNotCorrespond", "MP3はプレイヤーの環境によってループ再生されない事があります。");

	/// メインウィンドウ。
	mixin Msg!("mainWindowName", "%1$s [ %2$s ] - CWXEditor");
	mixin Msg!("mainWindowNameChanged", "*%1$s [ %2$s ] - CWXEditor");
	mixin Msg!("mainWindowNameEmpty", "CWXEditor");
	mixin Msg!("errorExecEngine", "%1$sの起動に失敗しました。");

	/// シナリオ選択ダイアログ
	mixin Msg!("dlgTitNewScenario", "新規シナリオの作成");
	mixin Msg!("dlgTitNewScenarioAtNewWin", "新しいウィンドウで新規シナリオの作成");
	mixin Msg!("dlgTitOpenScenario", "シナリオを開く");
	mixin Msg!("dlgTitOpenScenarioAtNewWin", "新しいウィンドウでシナリオを開く");
	mixin Msg!("filterScenario", "シナリオファイル (%1$s)");
	mixin Msg!("filterParts", "エリア・カードファイル (%1$s)");
	mixin Msg!("dlgTitSaveScenario", "名前を付けて保存");
	mixin Msg!("filterScenarioSave", "XMLシナリオファイル (*.wsn)");
	mixin Msg!("notScenario", "%1$sはシナリオ圧縮ファイルではありません");
	mixin Msg!("zipError", "%1$sの展開に失敗しました。");
	mixin Msg!("loadError", "%1$sの読込みに失敗しました。");
	mixin Msg!("saveError", "%1$sの保存に失敗しました。");
	mixin Msg!("loadErrorStatus", "%1$sの読込みに失敗");
	mixin Msg!("loadErrorStatusCount", "%1$s件のシナリオの読込みに失敗");
	mixin Msg!("scenarioNotFound", "%1$sは存在しないか、シナリオではありません。履歴から削除しますか？");

	/// データウィンドウ
	mixin Msg!("dataTabName", "データ");
	mixin Msg!("dataWindowName", "データ - [ %1$s ] - %2$s");
	mixin Msg!("areasTabName", "テーブル");
	mixin Msg!("areasWindowName", "テーブル - [ %1$s ] - %2$s");
	mixin Msg!("areaStatus", "%2$s件の%1$s");
	mixin Msg!("flagTabName", "状態変数");
	mixin Msg!("flagWindowName", "状態変数 - [ %1$s ] - %2$s");
	mixin Msg!("flagStatus", "%2$s個の%1$s");
	mixin Msg!("flagStatusSel", "%1$s (%2$s個を選択)");
	mixin Msg!("scenarioView", "シナリオビューリスト");
	mixin Msg!("variableView", "状態変数インスペクタ");

	mixin Msg!("reNumberingAll", "全てのエリアやカードのIDの1から振り直します。\nよろしいですか？");

	mixin Msg!("dlgTitReNumbering", "IDの振り直し");
	mixin Msg!("reNumbering", "IDの振り直し");
	mixin Msg!("reNumbering1", "%1$s「%2$s」以降のIDを");
	mixin Msg!("reNumbering2", "番から順に振り直す"); // reNumbering1と同様のパラメータを取る

	/// エリアのテーブル。
	mixin Msg!("areaId", "ID");
	mixin Msg!("areaName", "名称");
	mixin Msg!("areaCount", "利用数");
	mixin Msg!("areaNew", "新規エリア");
	mixin Msg!("battleNew", "新規バトル");
	mixin Msg!("packageNew", "新規パッケージ");

	/// フラグのディレクトリ。
	mixin Msg!("flagDirRoot", "Data");
	mixin Msg!("flagDirNew", "新規フォルダ");

	/// フラグ/ステップのテーブル。
	mixin Msg!("flagName", "名称");
	mixin Msg!("flagInit", "初期値");
	mixin Msg!("flagCount", "利用数");

	/// フラグ設定ダイアログ関連。
	mixin Msg!("dlgTitFlag", "フラグの設定");
	mixin Msg!("dlgLblFlagName", "フラグ名");
	mixin Msg!("dlgLblFlagInit", "初期値");
	mixin Msg!("dlgLblFlagTrue", "TRUE");
	mixin Msg!("dlgLblFlagFalse", "FALSE");

	/// ステップ設定ダイアログ関連。
	mixin Msg!("dlgTitStep", "ステップの設定");
	mixin Msg!("dlgLblStepName", "ステップ名");
	mixin Msg!("dlgLblStepInit", "初期値");
	mixin Msg!("dlgLblStep", "Step - %1$s");
	mixin Msg!("dlgTxtStep", "Step - %1$s");

	/// 貼り紙設定ダイアログ関連。
	mixin Msg!("dlgTitSummary", "概略の設定 - [ %1$s ]");
	mixin Msg!("summaryPreview", "表示イメージ");
	mixin Msg!("baseData", "基本データ");
	mixin Msg!("etcData", "詳細データ");
	mixin Msg!("targetLevelSame", "対象レベル %1$s");
	mixin Msg!("targetLevelHL", "対象レベル %1$s～%2$s");
	mixin Msg!("targetLevelL", "対象レベル %1$s～");
	mixin Msg!("targetLevelH", "対象レベル ～%1$s");
	mixin Msg!("summaryPageDummy", "1/1");
	mixin Msg!("title", "シナリオタイトル");
	mixin Msg!("author", "作者名");
	mixin Msg!("targetLevel", "対象レベル");
	mixin Msg!("desc", "解説");
	mixin Msg!("levSep", "～");
	mixin Msg!("qualification", "シナリオ出現条件");
	mixin Msg!("rCouponNum", "必要数");
	mixin Msg!("rCoupons", "必要とする称号");
	mixin Msg!("startArea", "シナリオ開始エリア");

	mixin Msg!("scenarioType", "シナリオタイプ");
	mixin Msg!("sTypeXML", "スキンを指定");
	mixin Msg!("sTypeClassic", "クラシックエンジンを使用");
	mixin Msg!("currentEngineSkin", "[%1$s]");

	mixin Msg!("pngMayNotCorrespond", "PNGイメージはプレイヤーの環境によって表示エラーとなる事があります。");

	/// エリア・戦闘・パッケージウィンドウ。
	mixin Msg!("noRefArea", "[カード配置参照無し]");
	mixin Msg!("areaViewFlagDesc", "フラグ");
	mixin Msg!("areaViewRefAreaDesc", "参照");

	mixin Msg!("left", "X");
	mixin Msg!("top", "Y");
	mixin Msg!("width", "幅");
	mixin Msg!("height", "高");
	mixin Msg!("scale", "拡大率");

	mixin Msg!("areaViewStatus", "%1$s [%2$s] - %3$s");
	mixin Msg!("areaViewStatusNoSummary", "%1$s [%2$s]");
	mixin Msg!("areaViewStatusNoFlag", "フラグ指定無し");
	mixin Msg!("areaViewStatusInvalidFlag", "存在しないフラグ(%1$s)");
	mixin Msg!("areaViewStatusWithFlag", "フラグ = %1$s");
	mixin Msg!("areaViewStatusImageIncluding", "イメージ格納");
	mixin Msg!("areaViewStatusSelCard", "%1$s枚のカード");
	mixin Msg!("areaViewStatusSelBack", "%1$s枚の背景");
	mixin Msg!("areaViewStatusEnemyCard", "%1$s.%2$s");

	mixin Msg!("viewNameTab", "%2$s.%3$s");
	mixin Msg!("viewNameSceneTab", "%2$s.%3$s");
	mixin Msg!("viewNameEventTab", "%2$s.%3$s");
	mixin Msg!("viewName", "[%1$s] - %2$s - %3$s");
	mixin Msg!("viewNameScene", "[%1$s カードと背景] - %2$s - %3$s");
	mixin Msg!("viewNameEvent", "[%1$s イベント] - %2$s - %3$s");

	mixin Msg!("cardCount", "使用数");

	mixin Msg!("cardAndBackView", "カードと背景");
	mixin Msg!("enemyCardView", "エネミーカード");
	mixin Msg!("menuCards", "カード");
	mixin Msg!("enemyCards", "カード");
	mixin Msg!("backs", "背景");
	mixin Msg!("eventView", "イベント");
	mixin Msg!("menuCard", "メニューカード");
	mixin Msg!("enemyCard", "エネミーカード");
	mixin Msg!("back", "背景画像");

	/// カード/背景配置領域関連。
	mixin Msg!("dlgTitDropCard", "カード画像の追加");
	mixin Msg!("dlgMsgDropCard", "カード画像をシナリオ" ~ DIR ~ "にコピーしますか？\n%1$s");
	mixin Msg!("dlgTitDropBack", "背景画像の追加");
	mixin Msg!("dlgMsgDropBack", "背景画像をシナリオ" ~ DIR ~ "にコピーしますか？\n%1$s");

	mixin Msg!("refFlag", "フラグ参照先");
	mixin Msg!("refStep", "ステップ参照先");
	mixin Msg!("noFlagRef", "[参照無し]");
	mixin Msg!("cardPosition", "カード位置");
	mixin Msg!("backPosition", "位置");
	mixin Msg!("bgImageSettings", "簡単設定");
	mixin Msg!("bgImageSettingCustom", "[カスタム]");
	mixin Msg!("bgImageSettingOriginal", "[元のサイズ]");
	mixin Msg!("enemyCardBase", "基本設定");
	mixin Msg!("dlgTitMenuCard", "メニューカードの設定 [ %1$s ]");
	mixin Msg!("dlgTitNewMenuCard", "メニューカードの作成");
	mixin Msg!("dlgTitBgImage", "背景画像の設定");
	mixin Msg!("dlgTitNewBgImage", "背景画像の作成");
	mixin Msg!("dlgTitEnemyCard", "エネミーカードの設定 [ %1$s ]");
	mixin Msg!("dlgTitNewEnemyCard", "エネミーカードの作成");

	/// イベントビュー。
	mixin Msg!("tools", "イベントコンテント");
	mixin Msg!("startEnter", "到着");
	mixin Msg!("startSelect", "クリック");
	mixin Msg!("startDead", "死亡");
	mixin Msg!("startVictory", "勝利");
	mixin Msg!("startEscape", "逃走");
	mixin Msg!("startLose", "敗北");
	mixin Msg!("startPackage", "パッケージ");
	mixin Msg!("startUse", "使用時");
	mixin Msg!("startRound", "ラウンド = %1$s");
	mixin Msg!("keyCodeTimingUse", "使用");
	mixin Msg!("keyCodeTimingSuccess", "成功");
	mixin Msg!("keyCodeTimingFailure", "失敗");

	mixin Msg!("manyRounds", "追加する発火ラウンドの範囲");
	mixin Msg!("dlgTitAddManyRounds", "追加する発火ラウンドの範囲");
	mixin Msg!("roundSep", "～");

	mixin Msg!("enterTree", "到着");
	mixin Msg!("selectTree", "クリック");
	mixin Msg!("deadTree", "死亡");
	mixin Msg!("victoryTree", "勝利");
	mixin Msg!("escapeTree", "逃走");
	mixin Msg!("loseTree", "敗北");
	mixin Msg!("packageTree", "パッケージイベント");
	mixin Msg!("useTree", "使用時イベント");
	mixin Msg!("keyCodeTree", "[%1$s]");
	mixin Msg!("roundTree", "ラウンド %1$s");

	mixin Msg!("eventTreeKindSystem", "システム");
	mixin Msg!("eventTreeKindKeyCode", "キーコード");
	mixin Msg!("eventTreeKindRound", "ラウンド");

	mixin Msg!("startUseCount", "利用数");

	mixin Msg!("flagOn", "TRUE");
	mixin Msg!("flagOff", "FALSE");
	mixin Msg!("evtChildBrVar", "%1$s = %2$s");
	mixin Msg!("etc", "その他");
	mixin Msg!("stepMoreThan", "ステップ「%1$s」が「%2$s」以上");
	mixin Msg!("stepLessThan", "ステップ「%1$s」が「%2$s」未満");
	mixin Msg!("partyAll", "パーティ全員");
	mixin Msg!("partyActive", "動けるメンバ");
	mixin Msg!("autoSelect", "自動");
	mixin Msg!("manualSelect", "手動");
	mixin Msg!("selectMemberSuccess", "%1$sから%2$sでキャラクターを選択");
	mixin Msg!("selectMemberFailure", "%1$sから%2$sでのキャラクター選択をキャンセル");
	mixin Msg!("branchAbilitySuccess", "%1$sがレベル%2$sで%3$sと%4$sで行う判定に成功");
	mixin Msg!("branchAbilityFailure", "%1$sがレベル%2$sで%3$sと%4$sで行う判定に失敗");
	mixin Msg!("branchRandomSuccess", "%1$s%%成功");
	mixin Msg!("branchRandomFailure", "%1$s%%失敗");
	mixin Msg!("levelAverage", "パーティ全員の平均値");
	mixin Msg!("levelSelected", "選択中のメンバ");
	mixin Msg!("branchLevelSuccess", "%1$sがレベル%2$s以上");
	mixin Msg!("branchLevelFailure", "%1$sがレベル%2$s未満");
	mixin Msg!("branchStatusSuccess", "%1$sでの「%2$s」の判定に成功");
	mixin Msg!("branchStatusFailure", "%1$sでの「%2$s」の判定に失敗");
	mixin Msg!("branchNumberSuccess", "パーティに%1$s人以上いる");
	mixin Msg!("branchNumberFailure", "パーティは%1$s人未満");
	mixin Msg!("branchArea", "エリア = %1$s");
	mixin Msg!("branchBattle", "バトル = %1$s");
	mixin Msg!("branchOnBattleSuccess", "イベント発生時の状況が戦闘中");
	mixin Msg!("branchOnBattleFailure", "イベント発生時の状況が戦闘中以外");
	mixin Msg!("branchCastSuccess", "「%1$s」が加わっている");
	mixin Msg!("branchCastFailure", "「%1$s」が加わっていない");
	mixin Msg!("branchEffectCardSuccess", "%1$sで「%2$s」を所有している");
	mixin Msg!("branchEffectCardFailure", "%1$sで「%2$s」が所有していない");
	mixin Msg!("branchInfoSuccess", "「%1$s」を所有している");
	mixin Msg!("branchInfoFailure", "「%1$s」が所有していない");
	mixin Msg!("branchMoneySuccess", "%1$ssp以上所持している");
	mixin Msg!("branchMoneyFailure", "%1$ssp以上所持していない");
	mixin Msg!("branchCouponSuccess", "%1$sがクーポン「%2$s」を所有している");
	mixin Msg!("branchCouponFailure", "%1$sがクーポン「%2$s」を所有していない");
	mixin Msg!("branchCompleteSuccess", "シナリオ「%1$s」が終了済みである");
	mixin Msg!("branchCompleteFailure", "シナリオ「%1$s」が終了済みでない");
	mixin Msg!("branchGossipSuccess", "ゴシップ「%1$s」が宿屋にある");
	mixin Msg!("branchGossipFailure", "ゴシップ「%1$s」が宿屋に無い");

	mixin(EnumToStringMethod!(Physical, "physicalName", "physicalName"));
	mixin Msg!("physicalNameDex", "器用度");
	mixin Msg!("physicalNameAgl", "敏捷度");
	mixin Msg!("physicalNameInt", "知力");
	mixin Msg!("physicalNameStr", "筋力");
	mixin Msg!("physicalNameVit", "生命力");
	mixin Msg!("physicalNameMin", "精神力");
	mixin(EnumToStringMethod!(Mental, "mentalName", "mentalName"));
	mixin Msg!("mentalNameAggressive", "好戦性");
	mixin Msg!("mentalNameUnaggressive", "平和性");
	mixin Msg!("mentalNameCheerful", "社交性");
	mixin Msg!("mentalNameUncheerful", "内向性");
	mixin Msg!("mentalNameBrave", "勇猛性");
	mixin Msg!("mentalNameUnbrave", "臆病性");
	mixin Msg!("mentalNameCautious", "慎重性");
	mixin Msg!("mentalNameUncautious", "大胆性");
	mixin Msg!("mentalNameTrickish", "狡猾性");
	mixin Msg!("mentalNameUntrickish", "正直性");
	mixin(EnumToStringMethod!(Status, "statusName", "statusName"));
	mixin Msg!("statusNameActive", "行動可能");
	mixin Msg!("statusNameInactive", "行動不可");
	mixin Msg!("statusNameAlive", "生存");
	mixin Msg!("statusNameDead", "非生存");
	mixin Msg!("statusNameFine", "健康");
	mixin Msg!("statusNameInjured", "負傷");
	mixin Msg!("statusNameHeavyInjured", "重傷");
	mixin Msg!("statusNameUnconscious", "意識不明");
	mixin Msg!("statusNamePoison", "中毒");
	mixin Msg!("statusNameSleep", "眠り");
	mixin Msg!("statusNameBind", "呪縛");
	mixin Msg!("statusNameParalyze", "麻痺/石化");
	mixin Msg!("effectTypeElement", "%1$s属性");
	mixin(EnumToStringMethod!(EffectType, "effectTypeName", "effectTypeName"));
	mixin Msg!("effectTypeNamePhysic", "物理");
	mixin Msg!("effectTypeNameMagic", "魔法");
	mixin Msg!("effectTypeNameMagicalPhysic", "魔法的物理");
	mixin Msg!("effectTypeNamePhysicalMagic", "物理的魔法");
	mixin Msg!("effectTypeNameNone", "無");
	mixin(EnumToStringMethod!(Resist, "resistName", "resistName"));
	mixin Msg!("resistNameAvoid", "回避属性");
	mixin Msg!("resistNameResist", "抵抗属性");
	mixin Msg!("resistNameUnfail", "必中属性");
	mixin(EnumToStringMethod!(CardTarget, "cardTargetName", "cardTargetName"));
	mixin Msg!("cardTargetNameNone", "対象無し");
	mixin Msg!("cardTargetNameUser", "使用者");
	mixin Msg!("cardTargetNameParty", "味方");
	mixin Msg!("cardTargetNameEnemy", "敵方");
	mixin Msg!("cardTargetNameBoth", "双方");
	mixin Msg!("cardTargetOne", "一体");
	mixin Msg!("cardTargetAll", "全体");
	mixin(EnumToStringMethod!(CardVisual, "cardVisualName", "cardVisualName"));
	mixin Msg!("cardVisualNameNone", "視覚効果無し");
	mixin Msg!("cardVisualNameReverse", "対象を反転");
	mixin Msg!("cardVisualNameHorizontal", "対象を横に震動");
	mixin Msg!("cardVisualNameVertical", "対象を縦に震動");
	mixin(EnumToStringMethod!(Premium, "premiumName", "premiumName"));
	mixin Msg!("premiumNameNormal", "日用品 (買戻し不可/破棄可)");
	mixin Msg!("premiumNameRare", "希少品 (買戻し可/破棄可)");
	mixin Msg!("premiumNamePremium", "貴重品 (買戻し可/破棄不可)");
	mixin(EnumToStringMethod!(Enhance, "enhanceName", "enhanceName"));
	mixin Msg!("enhanceNameAction", "行動");
	mixin Msg!("enhanceNameAvoid", "回避");
	mixin Msg!("enhanceNameResist", "抵抗");
	mixin Msg!("enhanceNameDefense", "防御");
	mixin Msg!("mentality", "精神状態");
	mixin(EnumToStringMethod!(Mentality, "mentalityName", "mentalityName"));
	mixin Msg!("mentalityNameNormal", "正常");
	mixin Msg!("mentalityNameSleep", "睡眠");
	mixin Msg!("mentalityNameConfuse", "混乱");
	mixin Msg!("mentalityNameOverheat", "激昂");
	mixin Msg!("mentalityNameBrave", "勇敢");
	mixin Msg!("mentalityNamePanic", "恐慌");

	mixin Msg!("enhanceBonus", "%1$sボーナス");
	mixin Msg!("statusActive", "※ 行動可能 = (健康 | 負傷 | 重傷 | 中毒)");
	mixin Msg!("statusInactive", "※ 行動不可 = (意識不明 | 麻痺/石化 | 呪縛 | 眠り)");
	mixin Msg!("statusAlive", "※ 生存 = (健康 | 負傷 | 重傷 | 中毒 | 呪縛 | 眠り)");
	mixin Msg!("statusDead", "※ 非生存 = (意識不明 | 麻痺/石化)");
	mixin(EnumToStringMethod2!(Target.M, "Target.M", "targetName", "targetName"));
	mixin Msg!("targetNameSelected", "選択中のメンバ");
	mixin Msg!("targetNameUnselected", "選択中以外のメンバ");
	mixin Msg!("targetNameRandom", "誰か一人");
	mixin Msg!("targetNameParty", "パーティ全員");
	mixin(EnumToStringMethod!(Talker, "talkerName", "talkerName"));
	mixin Msg!("talkerNameSelected", "[選択中]");
	mixin Msg!("talkerNameUnselected", "[選択中以外]");
	mixin Msg!("talkerNameRandom", "[ランダム]");
	mixin Msg!("talkerNameCard", "[カード]");
	mixin Msg!("talkerNameNarration", "[話者無し]");
	mixin Msg!("talkerNameImage", "[画像]");
	mixin(EnumToStringMethod!(Range, "rangeName", "rangeName"));
	mixin Msg!("rangeNameSelected", "現在選択中のメンバ");
	mixin Msg!("rangeNameRandom", "パーティの誰か一人");
	mixin Msg!("rangeNameParty", "パーティの全員");
	mixin Msg!("rangeNameBackpack", "荷物袋");
	mixin Msg!("rangeNamePartyAndBackpack", "全体(荷物袋含む)");
	mixin Msg!("rangeNameField", "フィールド全体");
	mixin(EnumToStringMethod!(DamageType, "damageTypeName", "damageTypeName"));
	mixin Msg!("damageTypeNameLevelRatio", "レベルに対応する値");
	mixin Msg!("damageTypeNameNormal", "値の直接入力");
	mixin Msg!("damageTypeNameMax", "最大値処理");
	mixin(EnumToStringMethod!(Element, "elementName", "elementName"));
	mixin Msg!("elementNameAll", "全");
	mixin Msg!("elementNameHealth", "肉体");
	mixin Msg!("elementNameMind", "精神");
	mixin Msg!("elementNameMiracle", "神聖");
	mixin Msg!("elementNameMagic", "魔力");
	mixin Msg!("elementNameFire", "炎");
	mixin Msg!("elementNameIce", "冷気");

	mixin(EnumToStringMethod!(Sex, "sexName", "sexName"));
	mixin Msg!("sexNameMale", "男/♂");
	mixin Msg!("sexNameFemale", "女/♀");
	mixin Msg!("sexUnknown", "謎/？");
	mixin Msg!("periodUnknown", "不明");
	mixin Msg!("natureUnknown", "その他");

	mixin Msg!("dlgTitComment", "コメントの記述");

	/// カードウィンドウ。
	mixin Msg!("mainCardWindowName", "カード - [ %1$s ] - %2$s");
	mixin Msg!("mainCardWindowNameNoSummary", "カード");
	mixin Msg!("mainCardTabName", "カード");
	mixin Msg!("cardWindowName", "%1$s - [ %2$s ] - %3$s");
	mixin Msg!("cardWindowNameNoSummary", "%1$s");
	mixin Msg!("cardTabName", "%1$s");
	mixin Msg!("handCardWindowName", "[所有カード] - %1$s.%2$s");
	mixin Msg!("handCardTabName", "%1$s.%2$s");
	mixin Msg!("importSourceWindowName", "カードのインポート - [ %1$s ] - %2$s");
	mixin Msg!("importSourceTabName", "%1$s");

	mixin Msg!("dlgTitAddScenario", "インポート元の選択");

	mixin Msg!("cardStatus", "%1$s枚のカード");
	mixin Msg!("cardStatusSelOne", "%1$s枚のカード (ID = %2$s)");
	mixin Msg!("cardStatusSelMulti", "%1$s枚のカード (%2$s枚を選択中)");
	mixin Msg!("handCardStatus", "%1$s枚のカード (有効枚数 = %2$s)");
	mixin Msg!("handCardStatusSelOne", "%1$s枚のカード (有効枚数 = %2$s) (ID = %3$s)");
	mixin Msg!("handCardStatusSelMulti", "%1$s枚のカード (有効枚数 = %2$s) (%3$s枚を選択中)");

	mixin Msg!("cwCast", "キャスト");
	mixin Msg!("skill", "特殊技能");
	mixin Msg!("item", "アイテム");
	mixin Msg!("beast", "召喚獣");
	mixin Msg!("info", "情報");

	mixin Msg!("noSelectImage", "(指定無し)");
	mixin Msg!("noImage", "存在しないイメージ(パス:%1$s)");
	mixin Msg!("noSelectBGM", "(指定無し)");
	mixin Msg!("noBGM", "存在しないBGM(パス:%1$s)");
	mixin Msg!("noSelectSE", "(指定無し)");
	mixin Msg!("noSE", "存在しない効果音(パス:%1$s)");
	mixin Msg!("noSelectArea", "(指定無し)");
	mixin Msg!("noArea", "存在しないエリア(ID:%1$s)");
	mixin Msg!("noSelectBattle", "(指定無し)");
	mixin Msg!("noBattle", "存在しないバトル(ID:%1$s)");
	mixin Msg!("noSelectPackage", "(指定無し)");
	mixin Msg!("noPackage", "存在しないパッケージ(ID:%1$s)");
	mixin Msg!("noSelectCast", "(指定無し)");
	mixin Msg!("noCast", "存在しないキャストカード(ID:%1$s)");
	mixin Msg!("noSelectSkill", "(指定無し)");
	mixin Msg!("noSkill", "存在しない特殊技能カード(ID:%1$s)");
	mixin Msg!("noSelectItem", "(指定無し)");
	mixin Msg!("noItem", "存在しないアイテムカード(ID:%1$s)");
	mixin Msg!("noSelectBeast", "(指定無し)");
	mixin Msg!("noBeast", "存在しない召喚獣カード(ID:%1$s)");
	mixin Msg!("noSelectInfo", "(指定無し)");
	mixin Msg!("noInfo", "存在しない情報カード(ID:%1$s)");
	mixin Msg!("noSelectFlag", "(指定無し)");
	mixin Msg!("noFlag", "存在しないフラグ(パス:%1$s)");
	mixin Msg!("noSelectStep", "(指定無し)");
	mixin Msg!("noStep", "存在しないステップ(パス:%1$s)");
	mixin Msg!("noSelectStart", "(指定無し)");
	mixin Msg!("noStart", "存在しないスタートコンテント(パス:%1$s)");
	mixin Msg!("noSelectCoupon", "(指定無し)");
	mixin Msg!("noSelectCompleteStamp", "(指定無し)");
	mixin Msg!("noSelectGossip", "(指定無し)");

	mixin Msg!("cardId", "ID");
	mixin Msg!("cardName", "名称");
	mixin Msg!("cardDesc", "説明");

	mixin Msg!("dlgTitNewCast", "キャストカードの作成");
	mixin Msg!("dlgTitNewSkill", "特殊技能カードの作成");
	mixin Msg!("dlgTitNewItem", "アイテムカードの作成");
	mixin Msg!("dlgTitNewBeast", "召喚獣カードの作成");
	mixin Msg!("dlgTitNewInfo", "情報カードの作成");
	mixin Msg!("dlgTitCast", "キャストカードの設定 [ %1$s ]");
	mixin Msg!("dlgTitSkill", "特殊技能カードの設定 [ %1$s ]");
	mixin Msg!("dlgTitItem", "アイテムカードの設定 [ %1$s ]");
	mixin Msg!("dlgTitBeast", "召喚獣カードの設定 [ %1$s ]");
	mixin Msg!("dlgTitInfo", "情報カードの設定 [ %1$s ]");

	mixin Msg!("name", "名前");
	mixin Msg!("nameLimit", "(%2$s文字まで)"); // %1$s = 文字数、%2$s = 文字数 / 2
	mixin Msg!("level", "レベル");
	mixin Msg!("life", "体力");
	mixin Msg!("lifeCalc", "標準値");
	mixin Msg!("history", "経歴");
	mixin Msg!("coupons", "経歴");
	mixin Msg!("addCoupon", "新規クーポンの追加");
	mixin Msg!("altCoupon", "クーポンの上書き");
	mixin Msg!("delCoupon", "クーポンの削除");
	mixin Msg!("sexTitle", "性別");
	mixin Msg!("periodTitle", "年代");
	mixin Msg!("race", "種族");
	mixin Msg!("noRace", "[未指定]");
	mixin Msg!("natureTitle", "素質");
	mixin Msg!("makingsTitle", "特性");
	mixin Msg!("tolerant", "対属性");
	mixin Msg!("tolerantBase", "対カード属性");
	mixin Msg!("tolerantElement", "対効果属性");
	mixin Msg!("resistWeapon", "武器が効かない");
	mixin Msg!("resistMagic", "魔法が効かない");
	mixin Msg!("undead", "命を持たない");
	mixin Msg!("automaton", "心を持たない");
	mixin Msg!("unholy", "不浄な存在");
	mixin Msg!("constructure", "魔法生物");
	mixin Msg!("resistText", "%1$sに耐性を持つ");
	mixin Msg!("weaknessText", "%1$sに弱い");
	mixin Msg!("descResistWeapon", "(物理属性のカードが無効)");
	mixin Msg!("descResistMagic", "(魔法属性のカードが無効)");
	mixin Msg!("descUndead", "(肉体属性の効果が無効)");
	mixin Msg!("descAutomaton", "(精神属性の効果が無効)");
	mixin Msg!("descUnholy", "(神聖属性の効果に影響)");
	mixin Msg!("descConstructure", "(魔力属性の効果に影響)");
	mixin Msg!("descResist", "(%1$s属性の効果が無効)");
	mixin Msg!("descWeakness", "(%1$s属性の効果に影響)");
	mixin Msg!("basicResist", "標準値");
	mixin Msg!("physicalParams", "身体能力");
	mixin Msg!("physicalCalc", "標準値");
	mixin Msg!("mentalParams", "精神傾向");
	mixin Msg!("mentalCalc", "標準値");
	mixin Msg!("castEnhance", "能力修正");
	mixin Msg!("basicEnhance", "標準値");

	mixin Msg!("liveStatus", "初期状態");
	mixin Msg!("lifeAndMentality", "体力と精神状態");
	mixin Msg!("enhanceLiveBonus", "能力ボーナス/ペナルティ");
	mixin(EnumToStringMethod!(Enhance, "enhanceLiveBonusName", "enhanceLiveBonusName"));
	mixin Msg!("enhanceLiveBonusNameAction", "行動");
	mixin Msg!("enhanceLiveBonusNameAvoid", "回避");
	mixin Msg!("enhanceLiveBonusNameResist", "抵抗");
	mixin Msg!("enhanceLiveBonusNameDefense", "防御");
	mixin Msg!("useMax", "最大値を使用");
	mixin Msg!("status", "異常状態");
	mixin Msg!("paralyze", "麻痺/石化");
	mixin Msg!("poison", "中毒");
	mixin Msg!("bind", "呪縛");
	mixin Msg!("silence", "沈黙");
	mixin Msg!("faceUp", "暴露");
	mixin Msg!("antiMagic", "魔法無効");
	mixin Msg!("unitValue", "点");
	mixin Msg!("unitRound", "ラウンド");
	mixin Msg!("resetLiveStatus", "通常状態に戻す");

	mixin Msg!("needSpellGroup", "発声による発動");
	mixin Msg!("needSpell", "沈黙時に使用不可");
	mixin Msg!("elementProps", "効果属性");
	mixin Msg!("resistProps", "抵抗属性");
	mixin Msg!("aptPhysical", "身体的要素");
	mixin Msg!("aptMental", "精神的要素");
	mixin Msg!("skillLevel", "技能レベル");
	mixin Msg!("useCountGroup", "使用可能回数");
	mixin Msg!("useCountRange", "(0～%1$s : 0 = ∞)");
	mixin Msg!("price", "価格");
	mixin Msg!("priceAuto", "(参考用)");
	mixin Msg!("useModify", "使用時 能力値修正");
	mixin Msg!("haveModify", "所有時 能力値修正");
	mixin Msg!("motionKind", "効果種別");
	mixin Msg!("motionElement", "属性");
	mixin Msg!("motionDamageType", "タイプ");
	mixin Msg!("motionValue", "値");
	mixin Msg!("motionBeast", "召喚するカード");
	mixin Msg!("beastNone", "[召喚獣無し]");
	mixin Msg!("setBeast", "選択");
	mixin Msg!("motionRound", "継続時間 (ラウンド数)");
	mixin Msg!("motionEnhValue", "変化値");
	mixin Msg!("effectTarget", "効果目標");
	mixin Msg!("effectRange", "効果範囲");
	mixin Msg!("effectVisual", "視覚効果");
	mixin Msg!("cardPremium", "カードの価値");
	mixin Msg!("successRate", "成功率修正値");
	mixin Msg!("allFail", "絶対失敗\n(-5)");
	mixin Msg!("allSuccess", "絶対成功\n(+5)");
	mixin Msg!("se", "効果音");
	mixin Msg!("se1", "初期効果");
	mixin Msg!("se2", "二次効果");
	mixin Msg!("soundNone", "[効果音無し]");
	mixin Msg!("keyCodes", "イベント発火のキーコード");

	mixin Msg!("warningNotDefaultSE", "標準以外の効果音はシナリオの外では鳴らない可能性があります。");
	mixin Msg!("warningEffectTypeNone", "無属性のカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。");
	mixin Msg!("warningVanishCast", "神聖属性以外の対象消去効果を持つカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。");
	mixin Msg!("warningNameLenOver", "名前の長さが%2$s文字を超えています。メッセージにカード名が表示された際に不具合が発生する可能性があります。"); // %1$s = 文字数、%2$s = 文字数 / 2

	mixin Msg!("card", "カード");
	mixin Msg!("apt", "要素");
	mixin Msg!("useCountAndDesc", "使用回数/解説");
	mixin Msg!("levelAndDesc", "レベル/解説");
	mixin Msg!("useBonus", "使用ボーナス");
	mixin Msg!("haveBonus", "所持ボーナス");
	mixin Msg!("motion", "効果");
	mixin Msg!("cardProps", "属性");
	mixin Msg!("settings", "設定");
	mixin Msg!("seAndKeyCode", "効果音/キーコード");

	mixin Msg!("rangeHint", "(%1$s～%2$s)");
	mixin Msg!("source", "出典");
	mixin Msg!("sourceScenario", "シナリオ名");
	mixin Msg!("sourceAuthor", "シナリオ作者");
	mixin Msg!("resetSource", "現在のシナリオを出典に設定");
	mixin Msg!("diffSource", "出典のシナリオ名と作者名が現在のシナリオと異なるため、使用時イベントは実行されません。");

	/// ファイルビュー。
	mixin Msg!("dirTabName", "ファイル");
	mixin Msg!("dirWindowName", "ファイル - [ %1$s ] - %2$s");
	mixin Msg!("dirStatus", "%1$s個のファイル (%2$s)");
	mixin Msg!("dirStatusSel", "%1$s個のファイル (%2$s) (%3$s個を選択中)");
	mixin Msg!("fileName", "ファイル名");
	mixin Msg!("fileExt", "拡張子");
	mixin Msg!("fileCount", "使用数");
	mixin Msg!("errorExec", "%1$sの起動に失敗しました。");
	mixin Msg!("filterDescZip", "ZIP アーカイブ (*.zip)");
	mixin Msg!("filterDescCab", "CAB アーカイブ (*.cab)");
	mixin Msg!("filterDescWsn", "シナリオファイル (*.wsn)");
	mixin Msg!("dlgTitCreateArchive", "シナリオの圧縮");
	mixin Msg!("failedCreateArchive", "シナリオの圧縮に失敗");
	mixin Msg!("dlgMsgIsSaveBeforeCreateArchive", "「%1$s」は変更されています。保存しますか？");

	/// エディタ設定ダイアログ。
	mixin Msg!("baseSettings", "基本設定");
	mixin Msg!("reference", "...");
	mixin Msg!("enginePath", "%1$sの場所");
	mixin Msg!("findEnginePath", "シナリオの場所から自動的に探す");
	mixin Msg!("dlgTitEnginePath", "%1$sの場所");
	mixin Msg!("tempDir", "シナリオの一時展開先");
	mixin Msg!("tempDirDesc", "wsn圧縮されたシナリオの一時的な展開先を選択してください。");
	mixin Msg!("backupDir", "自動バックアップ");
	mixin Msg!("backupEnabled", "自動バックアップを行う");
	mixin Msg!("backupPath", "保存先");
	mixin Msg!("backupDirDesc", "シナリオを定期的に自動バックアップする" ~ DIR ~ "を選択してください。");
	mixin Msg!("backupInterval", "保存間隔");
	mixin Msg!("minute", "分");
	mixin Msg!("backupCount", "最大保存数");
	mixin Msg!("skin", "スキン");
	mixin Msg!("scenarioAuthor", "シナリオ作者(新規作成時に自動設定されます)");
	mixin Msg!("historiesSettings", "履歴");
	mixin Msg!("openHistoryMax", "シナリオ履歴保存件数");
	mixin Msg!("openHistoryClear", "クリア");
	mixin Msg!("dlgMsgHistoryClear", "シナリオ履歴を削除してよろしいですか？");
	mixin Msg!("searchHistoryMax", "検索/置換履歴保存件数");
	mixin Msg!("searchHistoryClear", "クリア");
	mixin Msg!("dlgMsgSearchHistoryClear", "検索/置換履歴を削除してよろしいですか？");
	mixin Msg!("ignorePaths", "無視ファイル(改行区切り)");
	mixin Msg!("etcSettings", "その他");

	mixin Msg!("etcSettingsTitle", "詳細");

	mixin Msg!("languageSetting", "言語");
	mixin Msg!("languageSystem", "[システムの言語]");
	mixin Msg!("languageCaution", "※ 次回起動時から適用されます");

	mixin Msg!("singleWindow", "シングルウィンドウモード(再起動後に反映されます)");
	mixin Msg!("smoothingCard", "カードのサイズ変更時にスムージングを行う");
	mixin Msg!("showImagePreview", "カードや背景のプレビュー表示を行う");
	mixin Msg!("expandXMLs", "圧縮されたシナリオの読込み時にXMLファイルを展開する");
	mixin Msg!("contentsFloat", "コンテンツボックスを別ウィンドウで表示する");
	mixin Msg!("contentsAutoHide", "コンテンツボックスを自動的に隠す");
	mixin Msg!("xmlCopy", "コピーや切り取りを常にXML形式で行う");
	mixin Msg!("saveInnerImagePath", "クラシックなシナリオで格納イメージのファイルパスを保存する");
	mixin Msg!("linkCard", "キャストの所有カードや召喚対象のカードを参照で設定する");
	mixin Msg!("traceDirectories", "ファイル・" ~ DIR ~ "の変更を自動的に追跡する");
	mixin Msg!("logicalSort", "数値参照型ソートを行う(1, 10, 2, 3, ... → 1, 2, 3, 10, ...)");
	mixin Msg!("copyDesc", "カードをエリアに貼り付け・ドロップした時、解説もコピーする");
	mixin Msg!("refCardsAtEditBgImage", "背景変更コンテントの編集を開始する際、最初からカード配置の参照を行う");
	mixin Msg!("floatMessagePreview", "台詞・メッセージのプレビューをフロートさせる");
	mixin Msg!("addNewClassicEngine", "未知のクラシックエンジンを見つけたら記憶する");
	mixin Msg!("doubleIO", "分割読込・保存を行う(デュアルコア以上の環境で高速化)");
	mixin Msg!("switchTabWheel", "マウスホイールでタブ切替を行う");
	mixin Msg!("openTabAtRightOfCurrentTab", "新しいタブを現在のタブの直後に開く");
	mixin Msg!("reconstruction", "シナリオごとにタブの配置を記憶する");
	mixin Msg!("openLastScenario", "終了時に開いていたシナリオを次の起動時に開く");
	mixin Msg!("soundPlayType", "BGM再生方式");
	mixin Msg!("soundPlayTypeDef", "自動選択");
	mixin Msg!("soundPlayTypeSDL", "SDL(CardWirthPy方式)");
	mixin Msg!("soundPlayTypeMCI", "WinMM(CardWirth方式)");
	mixin Msg!("soundPlayTypeApp", "関連付けされたアプリケーションで開く");
	mixin Msg!("soundEffectPlayType", "効果音再生方式");
	mixin Msg!("soundPlaySameBGM", "BGMに合わせる");
	mixin Msg!("soundVolume", "音量");
	mixin Msg!("soundVolumePer", "%");
	mixin Msg!("soundCaution", "※ WinMM方式の時、音量は反映されません");

	mixin Msg!("keyBind", "キーバインド");
	mixin Msg!("mnemonic", "アクセスキー");
	mixin Msg!("hotkey", "ショートカット");

	mixin Msg!("wallpaper", "エディタの壁紙");
	mixin Msg!("filterWallpaper", "画像ファイル (*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.ico;*.icon)");
	mixin Msg!("dlgTitWallpaper", "壁紙画像の選択");
	mixin Msg!("wallpaperStyle", "表示形式");
	mixin(EnumToStringMethod!(WallpaperStyle, "wallpaperStyleName", "wallpaperStyleName"));
	mixin Msg!("wallpaperStyleNameCenter", "中央に表示");
	mixin Msg!("wallpaperStyleNameTile", "並べて表示");
	mixin Msg!("wallpaperStyleNameExpandFull", "拡大して表示");
	mixin Msg!("wallpaperStyleNameExpand", "はみ出さないように拡大");

	mixin Msg!("bgImageAndKeyCode", "背景とキーコード");
	mixin Msg!("standardKeyCode", "標準のキーコード");

	mixin Msg!("errorEnginePath", "%1$sの場所が正しくありません。");
	mixin Msg!("errorTempPath", "一時展開先が正しくありません。");
	mixin Msg!("errorBackupPath", "自動バックアップ先が正しくありません。");

	mixin Msg!("sNew", "新規作成");
	mixin Msg!("sAlt", "上書き");
	mixin Msg!("sDel", "削除");

	mixin Msg!("outerToolsAndClassicEngines", "外部ツールとクラシックエンジン");
	mixin Msg!("outerToolsTitle", "外部ツールの設定");
	mixin Msg!("outerToolName", "外部ツール名");
	mixin Msg!("outerToolCommand", "コマンド");
	mixin Msg!("dlgTitOuterTool", "外部ツールの選択");
	mixin Msg!("toolsHint1", "$F = ファイル名");
	mixin Msg!("toolsHint3", "$$ = $");
	mixin Msg!("outerToolWorkDir", "作業" ~ DIR);
	mixin Msg!("toolWorkDir", "作業" ~ DIR ~ "の選択");
	mixin Msg!("toolWorkDirDesc", "外部ツールの作業" ~ DIR ~ "を選択してください。");
	mixin Msg!("toolsHint2", "$S = シナリオの" ~ DIR);

	mixin Msg!("templates", "テンプレート");
	mixin Msg!("eventTemplatesTitle", "イベントテンプレートの設定");
	mixin Msg!("eventTemplateName", "テンプレート名");
	mixin Msg!("eventTemplateScript", "スクリプト");

	mixin Msg!("scenarioTemplatesTitle", "シナリオテンプレートの設定");
	mixin Msg!("scenarioTemplateName", "テンプレート名");
	mixin Msg!("scenarioTemplatePath", "シナリオの場所");
	mixin Msg!("dlgTitScTemplate", "テンプレートシナリオの選択");

	mixin Msg!("exeFileDescExe", "実行ファイル (*.exe)");
	mixin Msg!("exeFileDescAll", "すべてのファイル (*.*)");

	mixin Msg!("classicEnginesTitle", "クラシックエンジンの設定");
	mixin Msg!("classicEngineName", "エンジン名");
	mixin Msg!("classicEnginePath", "実行ファイルパス");
	mixin Msg!("classicEngineDataDirName", "データフォルダ");
	mixin Msg!("classicEngineDataDirNameDesc", "クラシックエンジンのデータフォルダを選択してください。");
	mixin Msg!("classicEngineExecute", "代替実行ファイル");
	mixin Msg!("classicEngineHint1", "※ 代替実行ファイルを指定すると、エンジン本体の代わりに実行されます");
	mixin Msg!("dlgTitClassicEnginePath", "クラシックエンジンの選択");
	mixin Msg!("dlgTitClassicEngineExecute", "代替実行ファイルの選択");

	mixin Msg!("bgImagesDefault", "デフォルト背景");
	mixin Msg!("setBgImagesDefault", "デフォルト背景の設定...");
	mixin Msg!("dlgTitBgImagesDefault", "デフォルト背景の設定");

	mixin Msg!("systemSounds", "システム音声");
	mixin Msg!("soundSaved", "保存完了");
	mixin Msg!("playableSounds", "サウンドファイル (%1$s)");
	mixin Msg!("dlgTitSystemSound", "システム音声の選択");

	mixin Msg!("undoMax", "「元に戻す」回数");
	mixin Msg!("undoMaxMainView", "エリア/カード/フラグ");
	mixin Msg!("undoMaxEvent", "メニュー/エネミー/背景/イベント");
	mixin Msg!("undoMaxReplace", "置換");
	mixin Msg!("undoMaxEtc", "テキスト/その他");

	mixin Msg!("dialogStatus", "台詞コンテントのステータス");
	mixin(EnumToStringMethod!(DialogStatus, "dialogStatusName", "dialogStatusName"));
	mixin Msg!("dialogStatusNameTop", "最上位の台詞");
	mixin Msg!("dialogStatusNameUnder", "最下位の台詞");
	mixin Msg!("dialogStatusNameUnderWithCoupon", "最下位の台詞(条件クーポン設定あり)");

	/// スクリプト関係。
	mixin Msg!("dlgTitScriptError", "CWXスクリプトエラー");
	mixin Msg!("scriptError", "CWXスクリプトのコンパイル中にエラーが発生しました。");
	mixin Msg!("scriptErrorOver100Error", "エラーが100件を超えたため、スクリプトの解析を終了します。");
	mixin Msg!("scriptErrorInvalidToken", "スクリプトに使用できない文字が含まれています。");
	mixin Msg!("scriptErrorInvalidSyntax", "構文が正しくありません。");
	mixin Msg!("scriptErrorInvalidString", "ここに文字列が必要です。");
	mixin Msg!("scriptErrorUnCloseString", "文字列が閉じられていません。");
	mixin Msg!("scriptErrorUnOpenComment", "コメントは開始されていません。");
	mixin Msg!("scriptErrorUnCloseComment", "コメントが閉じられていません。");
	mixin Msg!("scriptErrorInvalidNumber", "数値が正しくありません。");
	mixin Msg!("scriptErrorCloseBracketNotFound", "閉じ括弧が見つかりません。");
	mixin Msg!("scriptErrorCloseParenNotFound", "閉じ括弧が見つかりません。");
	mixin Msg!("scriptErrorZeroDivision", "0で除算を行いました。");
	mixin Msg!("scriptErrorInvalidAttr", "属性が正しくありません。");
	mixin Msg!("scriptErrorInvalidVar", "変数が正しくありません。");
	mixin Msg!("scriptErrorInvalidVarVal", "変数の値が正しくありません。");
	mixin Msg!("scriptErrorNoStartText", "スタートコンテントの名前がありません。");
	mixin Msg!("scriptErrorInvalidStatement", "文が正しくありません。");
	mixin Msg!("scriptErrorInvalidBranch", "分岐の構成が正しくありません。");
	mixin Msg!("scriptErrorNoIfText", "ifの条件が見つかりません。");
	mixin Msg!("scriptErrorNoIfContents", "分岐先のコンテントが見つかりません。");
	mixin Msg!("scriptErrorInvalidKeyword", "未知のキーワードです。");
	mixin Msg!("scriptErrorInvalidValuesOpen", "パラメータ列ではありません。");
	mixin Msg!("scriptErrorInvalidValuesClose", "閉じ括弧が見つかりません。");
	mixin Msg!("scriptErrorNoVarSet", "変数に値をセットしていません。");
	mixin Msg!("scriptErrorNoVarVal", "変数の値がありません。");
	mixin Msg!("scriptErrorInvalidCalc", "計算式が不正です。");
	mixin Msg!("scriptErrorInvalidBoolVal", "キーワードが正しくありません。");
	mixin Msg!("scriptErrorInvalidTransition", "未知の画面切替方式です。");
	mixin Msg!("scriptErrorInvalidRange", "未知の範囲です。");
	mixin Msg!("scriptErrorInvalidStatus", "未知のステータスです。");
	mixin Msg!("scriptErrorInvalidTarget", "未知のターゲットです。");
	mixin Msg!("scriptErrorInvalidEffectType", "未知の効果属性です。");
	mixin Msg!("scriptErrorInvalidResist", "未知の命中属性です。");
	mixin Msg!("scriptErrorInvalidCardVisual", "未知の視覚効果です。");
	mixin Msg!("scriptErrorInvalidMental", "未知の精神要素です。");
	mixin Msg!("scriptErrorInvalidPhysical", "未知の肉体要素です。");
	mixin Msg!("scriptErrorInvalidMotionType", "未知の効果タイプです。");
	mixin Msg!("scriptErrorInvalidMotion", "効果が正しくありません。");
	mixin Msg!("scriptErrorInvalidElement", "未知の属性です。");
	mixin Msg!("scriptErrorInvalidDamageType", "未知のダメージタイプです。");
	mixin Msg!("scriptErrorInvalidBgImage", "背景画像が正しくありません。");
	mixin Msg!("scriptErrorInvalidDialog", "台詞が正しくありません。");
	mixin Msg!("scriptErrorInvalidTalker", "話者が正しくありません。");
	mixin Msg!("scriptErrorUndefinedSymbol", "未知のシンボルです。");
	mixin Msg!("scriptErrorInvalidSif", "ここにsifが現れる事はできません。");
	mixin Msg!("scriptErrorNoSifText", "sifのテキストが見つかりません。");
	mixin Msg!("scriptErrorInvalidCommand", "命令が正しくありません。");
	mixin Msg!("scriptErrorCanNotHaveContent", "このコンテントが後続コンテントを持つ事はできません。");
	mixin Msg!("scriptErrorInvalidStr", "文字列が正しくありません。");
	mixin Msg!("scriptErrorReqNumber", "ここに数値が必要です。");
	mixin Msg!("scriptErrorReqID", "ここにIDが必要です。");
	mixin Msg!("scriptErrorUndefinedVar", "存在しない変数です。");
	mixin Msg!("scriptErrorInvalidValue", "値が正しくありません。");
	mixin Msg!("scriptErrorSystem", "サイズが大きすぎるため、CWXスクリプトをコンパイルできません。");

	/// メニュー。
	mixin(EnumToStringMethod!(MenuID, "menuText", "menuText"));

	mixin Msg!("menuTextNone", "");

	mixin Msg!("menuTextFile", "ファイル");
	mixin Msg!("menuTextEdit", "編集");
	mixin Msg!("menuTextView", "表示");
	mixin Msg!("menuTextTool", "ツール");
	mixin Msg!("menuTextTable", "テーブル");
	mixin Msg!("menuTextVariable", "状態変数");
	mixin Msg!("menuTextHelp", "ヘルプ");
	mixin Msg!("menuTextCard", "カード");
	mixin Msg!("menuTextCardsAndBacks", "カードと背景");

	mixin Msg!("menuTextDelNotUsedFile", "未使用のファイルを削除");
	mixin Msg!("menuTextClosePane", "閉じる");
	mixin Msg!("menuTextClosePaneExcept", "他のタブを閉じる");
	mixin Msg!("menuTextClosePaneLeft", "左側のタブを閉じる");
	mixin Msg!("menuTextClosePaneRight", "右側のタブを閉じる");
	mixin Msg!("menuTextClosePaneAll", "全てのタブを閉じる");
	mixin Msg!("menuTextNew", "新規作成");
	mixin Msg!("menuTextOpen", "開く");
	mixin Msg!("menuTextNewAtNewWindow", "新しいウィンドウで新規作成");
	mixin Msg!("menuTextOpenAtNewWindow", "新しいウィンドウで開く");
	mixin Msg!("menuTextClose", "閉じる");
	mixin Msg!("menuTextCloseWin", "閉じる");
	mixin Msg!("menuTextSave", "上書き保存");
	mixin Msg!("menuTextSaveAs", "名前を付けて保存");
	mixin Msg!("menuTextReload", "再読込");
	mixin Msg!("menuTextOpenDir", DIR ~ "を開く");
	mixin Msg!("menuTextOpenPlace", "ファイルの場所を開く");
	mixin Msg!("menuTextSaveImage", "格納イメージをファイルに保存");
	mixin Msg!("menuTextLookImages", "画像を一覧表示");
	mixin Msg!("menuTextShowMainToolBar", "全体ツールバーを表示");
	mixin Msg!("menuTextShowSceneToolBar", "シーンビューのツールバーを表示");
	mixin Msg!("menuTextShowEventToolBar", "イベントビューのツールバーを表示");
	mixin Msg!("menuTextChangeVH", "分割領域の縦横を切替");
	mixin Msg!("menuTextFind", "検索と置換");
	mixin Msg!("menuTextIncSearch", "絞り込み検索");
	mixin Msg!("menuTextCloseIncSearch", "閉じる");
	mixin Msg!("menuTextEditProp", "編集");
	mixin Msg!("menuTextRefresh", "最新の情報に更新");
	mixin Msg!("menuTextUndo", "元に戻す");
	mixin Msg!("menuTextRedo", "やり直し");
	mixin Msg!("menuTextCut", "切り取り");
	mixin Msg!("menuTextCopy", "コピー");
	mixin Msg!("menuTextPaste", "貼り付け");
	mixin Msg!("menuTextDelete", "削除");
	mixin Msg!("menuTextSelectAll", "すべて選択");
	mixin Msg!("menuTextToXMLText", "コピーしたデータをXMLに変換");
	mixin Msg!("menuTextTableView", "テーブルビュー");
	mixin Msg!("menuTextVarView", "状態変数ビュー");
	mixin Msg!("menuTextCardView", "カードビュー");
	mixin Msg!("menuTextCastView", "キャストカードビュー");
	mixin Msg!("menuTextSkillView", "特殊技能カードビュー");
	mixin Msg!("menuTextItemView", "アイテムカードビュー");
	mixin Msg!("menuTextBeastView", "召喚獣カードビュー");
	mixin Msg!("menuTextInfoView", "情報カードビュー");
	mixin Msg!("menuTextFileView", "ファイルビュー");
	mixin Msg!("menuTextExecEngine", "エンジン起動");
	mixin Msg!("menuTextExecEngineAuto", "自動選択");
	mixin Msg!("menuTextExecEngineMain", "CardWirthPy");
	mixin Msg!("menuTextOuterTools", "外部ツール");
	mixin Msg!("menuTextSettings", "エディタ設定");
	mixin Msg!("menuTextVersionInfo", "バージョン情報");
	mixin Msg!("menuTextLockToolBar", "ツールバーを固定");
	mixin Msg!("menuTextResetToolBar", "配置をリセット");
	mixin Msg!("menuTextCopyAsText", "テキストとしてコピー");
	mixin Msg!("menuTextOpenAtView", "ビューで開く");
	mixin Msg!("menuTextStartToPackage", "このツリーをパッケージ化する");
	mixin Msg!("menuTextConvertContent", "変換");
	mixin Msg!("menuTextCGroupTerminal", "開始/終端");
	mixin Msg!("menuTextCGroupStandard", "基本");
	mixin Msg!("menuTextCGroupData", "変数操作/分岐");
	mixin Msg!("menuTextCGroupUtility", "状況分岐");
	mixin Msg!("menuTextCGroupBranch", "保有分岐");
	mixin Msg!("menuTextCGroupGet", "取得");
	mixin Msg!("menuTextCGroupLost", "喪失");
	mixin Msg!("menuTextCGroupVisual", "外観操作");
	mixin Msg!("menuTextEditSummary", "シナリオの設定");
	mixin Msg!("menuTextNewArea", "エリアの作成");
	mixin Msg!("menuTextNewBattle", "バトルの作成");
	mixin Msg!("menuTextNewPackage", "パッケージの作成");
	mixin Msg!("menuTextReNumberingAll", "全てのIDを1から振り直す");
	mixin Msg!("menuTextReNumbering", "IDの振り直し");
	mixin Msg!("menuTextEditScene", "シーンビューを開く");
	mixin Msg!("menuTextEditEvent", "イベントビューを開く");
	mixin Msg!("menuTextNewFlagDir", "フォルダの作成");
	mixin Msg!("menuTextNewFlag", "フラグの作成");
	mixin Msg!("menuTextNewStep", "ステップの作成");
	mixin Msg!("menuTextUp", "上へ");
	mixin Msg!("menuTextDown", "下へ");
	mixin Msg!("menuTextShowParty", "パーティカードの表示");
	mixin Msg!("menuTextShowMsg", "メッセージ枠の表示");
	mixin Msg!("menuTextShowRefCards", "カード参照の表示");
	mixin Msg!("menuTextFixedImage", "イメージの固定");
	mixin Msg!("menuTextShowEnemyCardProp", "レベルとライフを表示");
	mixin Msg!("menuTextShowCard", "カードの表示");
	mixin Msg!("menuTextShowBack", "背景の表示");
	mixin Msg!("menuTextNewMenuCard", "メニューカードの作成");
	mixin Msg!("menuTextNewEnemyCard", "エネミーカードの作成");
	mixin Msg!("menuTextNewBack", "背景の作成");
	mixin Msg!("menuTextAutoArrange", "カードを自動的に並べる");
	mixin Msg!("menuTextManualArrange", "カードの位置を自分で決定する");
	mixin Msg!("menuTextMask", "透明色を使用");
	mixin Msg!("menuTextEscape", "逃走の有無");
	mixin Msg!("menuTextPosTop", "上に揃える");
	mixin Msg!("menuTextPosBottom", "下に揃える");
	mixin Msg!("menuTextPosLeft", "左に揃える");
	mixin Msg!("menuTextPosRight", "右に揃える");
	mixin Msg!("menuTextPosEven", "等間隔に並べる");
	mixin Msg!("menuTextScaleMin", "最小のカードスケール");
	mixin Msg!("menuTextScaleMiddle", "標準のカードスケール");
	mixin Msg!("menuTextScaleMax", "最大のカードスケール");
	mixin Msg!("menuTextScaleBig", "大きく揃える");
	mixin Msg!("menuTextScaleSmall", "小さく揃える");
	mixin Msg!("menuTextStopBGM", "%1$sの再生を停止");
	mixin Msg!("menuTextPlayBGM", "再生");
	mixin Msg!("menuTextKeyCodeTiming", "キーコード発火タイミング");
	mixin Msg!("menuTextKeyCodeTimingUse", "使用");
	mixin Msg!("menuTextKeyCodeTimingSuccess", "成功");
	mixin Msg!("menuTextKeyCodeTimingFailure", "失敗");
	mixin Msg!("menuTextAddRangeOfRound", "複数のラウンドを追加");
	mixin Msg!("menuTextOpenAtTableView", "テーブルビューで開く");
	mixin Msg!("menuTextOpenAtVarView", "状態変数ビューで開く");
	mixin Msg!("menuTextOpenAtCardView", "カードビューで開く");
	mixin Msg!("menuTextOpenAtFileView", "ファイルビューで開く");
	mixin Msg!("menuTextOpenAtEventView", "イベントビューで開く");
	mixin Msg!("menuTextComment", "コメントを記述");
	mixin Msg!("menuTextShowCardProp", "レベルとライフを表示");
	mixin Msg!("menuTextShowCardImage", "カード表示");
	mixin Msg!("menuTextShowCardDetail", "詳細表示");
	mixin Msg!("menuTextOpenImportSource", "外部シナリオから追加");
	mixin Msg!("menuTextNewCast", "キャストカードの作成");
	mixin Msg!("menuTextNewSkill", "スキルカードの作成");
	mixin Msg!("menuTextNewItem", "アイテムカードの作成");
	mixin Msg!("menuTextNewBeast", "召喚獣カードの作成");
	mixin Msg!("menuTextNewInfo", "情報カードの作成");
	mixin Msg!("menuTextImport", "シナリオに追加");
	mixin Msg!("menuTextOpenHand", "所有カード");
	mixin Msg!("menuTextAddHand", "所有カードの追加");
	mixin Msg!("menuTextEditEventAtTimeOfUsing", "使用時イベントの設定");
	mixin Msg!("menuTextHold", "カードのホールド");
	mixin Msg!("menuTextPlaySE", "再生");
	mixin Msg!("menuTextStopSE", "停止");
	mixin Msg!("menuTextNewDir", "新規" ~ DIR);
	mixin Msg!("menuTextCopyFilePath", "素材のパスをコピー");
	mixin Msg!("menuTextReplFilePath", "素材の差替え");
	mixin Msg!("menuTextCreateArchive", "シナリオを圧縮");
	mixin Msg!("menuTextToScript", "スクリプトに変換してコピー");
	mixin Msg!("menuTextToScriptAll", "全てをスクリプトに変換してコピー");
	mixin Msg!("menuTextEvTemplates", "テンプレートから作成");

	mixin Msg!("bgm", "BGM");
	mixin Msg!("newEvent", "イベントの作成");
	mixin Msg!("newIgnition", "イベント発火条件の作成");
	mixin Msg!("expandTree", "全コンテントツリーを開く");
	mixin Msg!("foldTree", "全コンテントツリーを閉じる");

	mixin AAProperty!("sex", string, string, `[
		"♂":"♂",
		"♀":"♀",
	]`, "key", "name");
	mixin AAProperty!("period", string, string, `[
		"子供":"子供",
		"若者":"若者",
		"大人":"大人",
		"老人":"老人",
	]`, "key", "name");
	mixin AAProperty!("nature", string, string, `[
		"他種族":"他種族", // darkwirth
		"標準型":"標準型",
		"理性型":"理性型", // s_c_wirth
		"参謀型":"参謀型", // oedowirth
		"妖木族":"妖木族", // darkwirth
		"知将型":"知将型",
		"隠密型":"隠密型", // oedowirth
		"人獣族":"人獣族", // darkwirth
		"万能型":"万能型",
		"秀才型":"秀才型", // s_c_wirth
		"小悪魔":"小悪魔", // darkwirth
		"策士型":"策士型",
		"根性型":"根性型", // s_c_wirth
		"剣客型":"剣客型", // oedowirth
		"悪鬼族":"悪鬼族", // darkwirth
		"勇将型":"勇将型",
		"熱血型":"熱血型", // s_c_wirth
		"蜥蜴族":"蜥蜴族", // darkwirth
		"豪傑型":"豪傑型",
		"秀英型":"秀英型", // s_c_wirth
		"人狼族":"人狼族", // darkwirth
		"英明型":"英明型",
		"剣豪型":"剣豪型", // oedowirth
		"鬼人族":"鬼人族", // darkwirth
		"無双型":"無双型",
		"賢才型":"賢才型", // oedowirth
		"大悪魔":"大悪魔", // darkwirth
		"天才型":"天才型",
		"努力型":"努力型", // s_c_wirth
		"晩成型":"晩成型", // oedowirth
		"妖虫族":"妖虫族", // darkwirth
		"凡庸型":"凡庸型",
		"超人型":"超人型", // s_c_wirth
		"覇道型":"覇道型", // oedowirth
		"闇の者":"闇の者", // darkwirth
		"英雄型":"英雄型",
		"神竜族":"神竜族", // darkwirth
		"神仙型":"神仙型",
	]`, "key", "name");
	mixin AAProperty!("makings", string, string, `[
		"秀麗":"秀麗",
		"醜悪":"醜悪",
		"高貴の出":"高貴の出",
		"下賎の出":"下賎の出",
		"都会育ち":"都会育ち",
		"田舎育ち":"田舎育ち",
		"裕福":"裕福",
		"貧乏":"貧乏",
		"厚き信仰":"厚き信仰",
		"不心得者":"不心得者",
		"誠実":"誠実",
		"不実":"不実",
		"冷静沈着":"冷静沈着",
		"猪突猛進":"猪突猛進",
		"貪欲":"貪欲",
		"無欲":"無欲",
		"献身的":"献身的",
		"利己的":"利己的",
		"秩序派":"秩序派",
		"混沌派":"混沌派",
		"進取派":"進取派",
		"保守派":"保守派",
		"神経質":"神経質",
		"鈍感":"鈍感",
		"好奇心旺盛":"好奇心旺盛",
		"無頓着":"無頓着",
		"過激":"過激",
		"穏健":"穏健",
		"楽観的":"楽観的",
		"悲観的":"悲観的",
		"勤勉":"勤勉",
		"遊び人":"遊び人",
		"陽気":"陽気",
		"内気":"内気",
		"派手":"派手",
		"地味":"地味",
		"高慢":"高慢",
		"謙虚":"謙虚",
		"上品":"上品",
		"粗野":"粗野",
		"武骨":"武骨",
		"繊細":"繊細",
		"硬派":"硬派",
		"軟派":"軟派",
		"お人好し":"お人好し",
		"ひねくれ者":"ひねくれ者",
		"名誉こそ命":"名誉こそ命",
		"愛に生きる":"愛に生きる",
	]`, "key", "name");

	/// 各連想配列を初期化する。
	this () {
		init_sex();
		init_period();
		init_nature();
		init_makings();
	}

	mixin XMLFuncs!(typeof(this), "message");
}
