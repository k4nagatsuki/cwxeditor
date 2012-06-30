
module cwx.msgs;

import cwx.types;
import cwx.features;
import cwx.event;
import cwx.motion;
import cwx.structs;
import cwx.menu;
import cwx.utils;
import cwx.settings;
import cwx.xml;

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
public:
	mixin PropertyAttr!("locale", string, "ja-JP", true);

	mixin Property!("application", string, "CWXEditor", true);
	mixin Property!("localeName", string, "日本語", true);
	mixin Property!("dlgTitVersion", string, "バージョン情報", true);
	mixin Property!("appDesc", string, "CardWirthPy向けシナリオエディタ", true);

	mixin Property!("dlgTitUsage", string, "使い方 - CWXEditor", true);
	mixin Property!("usage", string, "使い方: cwxeditor [-help | -putlangfile <PATH> | -conf <PATH>\n"
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
		"  <CWXPath>     シナリオを開いた後、<CWXPath>で指定したリソースを開きます。", true);

	mixin Property!("dlgTitError", string, "エラー - CWXEditor", true);
	mixin Property!("dlgTitWarning", string, "警告 - CWXEditor", true);
	mixin Property!("dlgTitQuestion", string, "確認 - CWXEditor", true);
	mixin Property!("unknownError", string, "処理の途中でCWXEditorの制作者が意図していないエラーが発生しました。"
		"データが壊れている可能性を考慮して、シナリオを保存せずに終了する事をお勧めします。\n"
		"エラー内容は" ~ CWX_EDITOR_EXE ~ "と同じ" ~ DIR ~ "にあるcwxeditor_error.logに記録されます。", true);
	mixin Property!("shutdown", string, "強制終了", true);

	mixin Property!("dlgTextOK", string, "&OK", true);
	mixin Property!("dlgTextApply", string, "適用", true);
	mixin Property!("dlgTextCancel", string, "キャンセル", true);

	mixin Property!("apply", string, "適用", true);
	mixin Property!("del", string, "削除", true);

	mixin Property!("filterAll", string, "すべてのファイル (*.*)", true);

	mixin Property!("fileCopyError", string, "%1$sのコピー中にエラーが発生しました。", true);
	mixin Property!("reloadError", string, "%1$sの再読込中にエラーが発生しました。", true);
	mixin Property!("loadProgress", string, "%2$s%% 完了 - %1$sを展開中", true);
	mixin Property!("loading", string, "%1$sの読込みを開始", true);
	mixin Property!("loaded", string, "%1$sの読込みを完了", true);
	mixin Property!("loadedCount", string, "%1$s件の読込みを完了", true);
	mixin Property!("reconstructionStatus", string, "編集状態を復元中 (%1$s/%2$s)", true);
	mixin Property!("cwxPathOpenError", string, "パス [%1$s] を開けません。", true);
	mixin Property!("filePathOpenError", string, "パス [%1$s] を開けません。", true);

	mixin Property!("loadSkinError", string, "デフォルトのスキン「%1$s」が見つかりません。\n" ~ CARD_WIRTH_PY_EXE ~ "本体の場所が正しくないか、Data" ~ DIR ~ "が正しく配置されていない可能性があります。\nこのまま開始すると、一部リソース画像が非表示になります。", true);
	mixin Property!("useDefaultSkin", string, "スキン「%1$s」が見つかりません。\nデフォルトのスキン「%1$s」を使用します。", true);
	mixin Property!("scenarioName", string, "シナリオ名", true);
	mixin Property!("type", string, "タイプ", true);
	mixin Property!("initialize", string, "初期設定", true);
	mixin Property!("classic", string, "[クラシック]", true);
	mixin Property!("scenarioTemplate", string, "テンプレート", true);
	mixin Property!("templateDesc", string, "%1$s [%2$s]", true);
	mixin Property!("noTemplate", string, "[テンプレート無し]", true);
	mixin Property!("newClassicDir", string, "シナリオ作成先の選択", true);
	mixin Property!("newClassicDirDesc", string, "シナリオを作成する" ~ DIR ~ "を選択してください。", true);
	mixin Property!("notEmptyDir", string, "%1$sは空ではありません。\n本当にここでシナリオを作成しますか？", true);

	mixin Property!("newScenarioName", string, "新規シナリオ", true);

	mixin Property!("dlgTitSaveBitmapImage", string, "格納イメージの保存", true);
	mixin Property!("filterBitmapImage", string, "ビットマップイメージ (*.bmp)", true);

	mixin Property!("newFolder", string, "新規" ~ DIR);

	mixin Property!("dlgMsgDeleteFile", string, "%1$sを完全に削除しますか？", true);
	mixin Property!("dlgMsgDeleteFiles", string, "%1$s個の項目を完全に削除しますか？", true);
	mixin Property!("dlgMsgDeleteFileRecycle", string, "%1$sをごみ箱に移動しますか？", true);
	mixin Property!("dlgMsgDeleteFilesRecycle", string, "%1$s個の項目をごみ箱に移動しますか？", true);
	mixin Property!("dlgMsgDeleteUnuse", string, "%1$s個の未使用ファイル・" ~ DIR ~ "を完全に削除しますか？", true);
	mixin Property!("dlgMsgDeleteRecycleUnuse", string, "%1$s個の未使用ファイル・" ~ DIR ~ "をごみ箱に移動しますか？", true);

	mixin Property!("image", string, "イメージ", true);
	mixin Property!("pathDef", string, "[デフォルト]", true);
	mixin Property!("imageNone", string, "[イメージ無し]", true);
	mixin Property!("fileNone", string, "[ファイルを選択]", true);
	mixin Property!("imageIncluding", string, "[イメージ格納]", true);
	mixin Property!("seNone", string, "[サウンド無し]", true);
	mixin Property!("bgmStop", string, "[BGM停止]", true);
	mixin Property!("bgmNone", string, "[BGM無し]", true);
	mixin Property!("dlgMsgIsSaveBeforeReload", string, "「%1$s」は変更されています。再読込しますか？", true);
	mixin Property!("reloadBeforeSaveError", string, "「%1$s」は保存されていないため、再読込できません。", true);
	mixin Property!("dlgMsgIsSaveBeforeExit", string, "「%1$s」は変更されています。保存しますか？", true);
	mixin Property!("dlgMsgDropFile", string, "%1$sをシナリオ" ~ DIR ~ "にコピーしますか？", true);
	mixin Property!("dlgMsgDropFiles", string, "%1$s個のファイルをシナリオ" ~ DIR ~ "にコピーしますか？", true);
	mixin Property!("dlgMsgDropOverWriteFile", string, "%1$sはすでに存在します。上書きしますか？", true);
	mixin Property!("dlgMsgDropOverWriteFiles", string, "%1$s個の項目がすでに存在します。上書きしますか？", true);
	mixin Property!("dlgTitDropFiles", string, "素材ファイルの追加", true);
	mixin Property!("dlgMsgCopyError", string, "いくつかのファイルのコピーに失敗しました。", true);

	mixin Property!("dlgMsgCopyMaterial1", string, "格納画像もコピーしますか？", true);
	mixin Property!("dlgMsgCopyMaterial2", string, "素材もコピーしますか？\n%1$s", true);
	mixin Property!("dlgMsgCopyMaterial3", string, "素材もコピーしますか？\n%1$s個のファイル", true);
	mixin Property!("dlgMsgCopyMaterial4", string, "素材もコピーしますか？\n%1$s個のファイルと%2$s個の格納画像", true);

	mixin Property!("incSearchContains", string, "名前の一部", true);
	mixin Property!("incSearchWildcard", string, "ワイルドカード", true);
	mixin Property!("incSearchRegex", string, "正規表現", true);

	mixin Property!("dlgTitSettings", string, "CWXEditorの設定", true);

	mixin Property!("refreshS", string, "更新", true);

	mixin Property!("summary", string, "シナリオの設定", true);
	mixin Property!("area", string, "エリア", true);
	mixin Property!("battle", string, "バトル", true);
	mixin Property!("cwPackage", string, "パッケージ", true);

	mixin Property!("dlgTitReplaceText", string, "検索と置換", true);
	mixin Property!("replForText", string, "テキスト検索", true);
	mixin Property!("replForID", string, "ID検索", true);
	mixin Property!("replForPath", string, "素材検索", true);
	mixin Property!("replContents", string, "コンテント検索", true);
	mixin Property!("replForCoupon", string, "称号・名称一覧", true);
	mixin Property!("replForUnuse", string, "未使用検索", true);
	mixin Property!("replForError", string, "誤り検索", true);

	mixin Property!("searchRange", string, "検索対象", true);
	mixin Property!("flagsAndSteps", string, "フラグとステップ", true);
	mixin Property!("allCheckRange", string, "全てチェック/全てチェックを外す", true);

	mixin Property!("allCheck", string, "全てチェック/全てチェックを外す(&L)", true);
	mixin Property!("allSelect", string, "全て選択/全て選択を外す(&L)", true);

	mixin Property!("replError", string, "重複する分岐(フラグ分岐が両方ともTRUEになっている等)・条件クーポンに抜けがある台詞コンテント・存在しない素材を参照しているコンテント等を検索します。", true);

	mixin Property!("replFrom", string, "検索(置換前)", true);
	mixin Property!("replTo", string, "置換後", true);

	mixin Property!("replText", string, "検索/置換するテキスト", true);
	mixin Property!("replTextTarget", string, "検索/置換対象", true);
	mixin Property!("replTextSummary", string, "貼り紙", true);
	mixin Property!("replTextMessage", string, "メッセージ", true);
	mixin Property!("replTextCardName", string, "カード名", true);
	mixin Property!("replTextCardDesc", string, "カード解説", true);
	mixin Property!("replTextEventText", string, "イベントテキスト", true);
	mixin Property!("replTextStart", string, "スタートコンテント", true);
	mixin Property!("replTextFlagAndStep", string, "フラグ/ステップ", true);
	mixin Property!("replTextCoupon", string, "クーポン", true);
	mixin Property!("replTextGossip", string, "ゴシップ", true);
	mixin Property!("replTextEndScenario", string, "終了印", true);
	mixin Property!("replTextAreaName", string, "エリア/バトル/パッケージ名", true);
	mixin Property!("replTextKeyCode", string, "キーコード", true);
	mixin Property!("replTextFile", string, "ファイル名", true);
	mixin Property!("replTextComment", string, "コメント", true);
	mixin Property!("replTextJptx", string, "JPTXテキスト", true);

	mixin Property!("replID", string, "検索/置換対象", true);
	mixin Property!("replIDKind", string, "対象", true);
	mixin Property!("replIDArea", string, "エリア", true);
	mixin Property!("replIDBattle", string, "バトル", true);
	mixin Property!("replIDPackage", string, "パッケージ", true);
	mixin Property!("replIDCast", string, "キャストカード", true);
	mixin Property!("replIDSkill", string, "特殊技能カード", true);
	mixin Property!("replIDItem", string, "アイテムカード", true);
	mixin Property!("replIDBeast", string, "召喚獣カード", true);
	mixin Property!("replIDInfo", string, "情報カード", true);
	mixin Property!("replSetID", string, "[IDを直接指定]", true);

	mixin Property!("replPath", string, "検索/置換する素材", true);

	mixin Property!("replUnuseTarget", string, "検索対象", true);
	mixin Property!("replUnuseFlag", string, "フラグ", true);
	mixin Property!("replUnuseStep", string, "ステップ", true);
	mixin Property!("replUnuseArea", string, "エリア", true);
	mixin Property!("replUnuseBattle", string, "バトル", true);
	mixin Property!("replUnusePackage", string, "パッケージ", true);
	mixin Property!("replUnuseCast", string, "キャストカード", true);
	mixin Property!("replUnuseSkill", string, "特殊技能カード", true);
	mixin Property!("replUnuseItem", string, "アイテムカード", true);
	mixin Property!("replUnuseBeast", string, "召喚獣カード", true);
	mixin Property!("replUnuseInfo", string, "情報カード", true);
	mixin Property!("replUnuseStart", string, "スタートコンテント", true);
	mixin Property!("replUnusePath", string, "素材", true);

	mixin Property!("replNotIgnoreCase", string, "大文字と小文字を区別する(&C)", true);
	mixin Property!("replRegExp", string, "正規表現(&E) (. = 任意1文字, * = 直前の文字の任意数繰返し, $1 = 1つめの文字列グループ ...)", true);
	mixin Property!("regexError", string, "正規表現が正しくありません。", true);
	mixin Property!("replWildcard", string, "ワイルドカード(&W) (* = 任意文字列, ? = 任意1文字, \\* = *, \\? = ?, \\\\ = \\)", true);
	mixin Property!("replCond", string, "検索条件", true);
	mixin Property!("search", string, "検索(&F)", true);
	mixin Property!("replace", string, "全て置換(&R)", true);
	mixin Property!("replaceExit", string, "閉じる", true);
	mixin Property!("searchResultEmpty", string, "0件の検索結果", true);
	mixin Property!("searchResult", string, "%1$s件の検索結果(%2$s)", true);
	mixin Property!("replResultEmpty", string, "0箇所の置換", true);
	mixin Property!("replResult", string, "%1$s箇所の置換(%2$s)", true);
	mixin Property!("replaceUndo", string, "%1$s件を元に戻しました", true);
	mixin Property!("replaceRedo", string, "%1$s件をやり直しました", true);

	mixin Property!("searchResultBgImage", string, "背景画像 [%1$s]", true);
	mixin Property!("searchResultIds", string, "%1$s [%2$s.%3$s]", true);

	mixin Property!("searchResultFlag", string, "フラグ [%1$s]", true);
	mixin Property!("searchResultStep", string, "ステップ [%1$s]", true);
	mixin Property!("searchResultFlagDir", string, "ディレクトリ [%1$s]", true);
	mixin Property!("searchResultEventTree", string, "イベントツリー [%1$s]", true);
	mixin Property!("searchResultMenuCard", string, "メニューカード [%1$s]", true);
	mixin Property!("searchResultEnemyCard", string, "エネミーカード [%1$s]", true);

	mixin Property!("searchErrorNoImage", string, "イメージ指定無し", true);
	mixin Property!("searchErrorImageNotFound", string, "イメージファイルが見つからない", true);
	mixin Property!("searchErrorBGMNotFound", string, "BGMファイルが見つからない", true);
	mixin Property!("searchErrorSENotFound", string, "効果音ファイルが見つからない", true);
	mixin Property!("searchErrorStartAreaNotFound", string, "開始エリア無し", true);
	mixin Property!("searchErrorFlagNotFound", string, "フラグが見つからない", true);
	mixin Property!("searchErrorStepNotFound", string, "ステップが見つからない", true);
	mixin Property!("searchErrorNoCast", string, "キャストカード指定無し", true);
	mixin Property!("searchErrorNoBeast", string, "召喚獣カード指定無し", true);
	mixin Property!("searchErrorDupNextContent", string, "分岐条件の重複", true);
	mixin Property!("searchErrorSPFontNotFound", string, "特殊フォントイメージが見つからない", true);
	mixin Property!("searchErrorNoRCouponsDialog", string, "最終項目以外にクーポン指定無し項目あり", true);
	mixin Property!("searchErrorAreaNotFound", string, "エリアが見つからない", true);
	mixin Property!("searchErrorBattleNotFound", string, "バトルが見つからない", true);
	mixin Property!("searchErrorPackageNotFound", string, "パッケージが見つからない", true);
	mixin Property!("searchErrorCastNotFound", string, "キャストカードが見つからない", true);
	mixin Property!("searchErrorSkillNotFound", string, "スキルカードが見つからない", true);
	mixin Property!("searchErrorItemNotFound", string, "アイテムカードが見つからない", true);
	mixin Property!("searchErrorBeastNotFound", string, "召喚獣カードが見つからない", true);
	mixin Property!("searchErrorInfoNotFound", string, "情報カードが見つからない", true);
	mixin Property!("searchErrorStartNotFound", string, "スタートコンテントが見つからない", true);
	mixin Property!("searchErrorIgnoreWait", string, "後続コンテントが無いため、空白時間が無視される", true);
	mixin Property!("searchOpenDialog", string, "検索結果へジャンプする時、ダイアログを開く", true);

	/// イベント設定。
	mixin Property!("dlgTitContent", string, "イベントの設定 [ %1$s ]", true);

	mixin Property!("afterClear", string, "シナリオ終了後", true);
	mixin Property!("afterClearEndMark", string, "シナリオに済印を付ける", true);
	mixin Property!("afterClearNoEndMark", string, "何もしない", true);

	mixin Property!("couponName", string, "クーポン名", true);
	mixin Property!("couponValue", string, "得点", true);
	mixin Property!("couponValueRange", string, "(%1$s～%2$s)", true);
	mixin Property!("range", string, "適用範囲", true);
	mixin Property!("gossipName", string, "ゴシップ名", true);
	mixin Property!("endName", string, "シナリオ名", true);

	mixin Property!("couponHide", string, "隠蔽クーポン", true);

	mixin(EnumToStringMethod!(CouponType, "couponTypeDesc", "couponTypeDesc"));
	mixin Property!("couponTypeDescNormal", string, "ノーマル", true);
	mixin Property!("couponTypeDescHide", string, "[＿...] 隠蔽(称号一覧で非表示)", true);
	mixin Property!("couponTypeDescSystem", string, "[＠...] システム", true);
	mixin Property!("couponTypeDescDur", string, "[：...] 時限(点数分の時間経過及びシナリオ終了時に消滅)", true);
	mixin Property!("couponTypeDescDurBattle", string, "[；...] 戦闘中時限(点数分の時間経過及び戦闘終了時に消滅)", true);

	mixin Property!("imageMessage", string, "イメージ付きメッセージ", true);
	mixin Property!("noImageMessage", string, "イメージ無しメッセージ", true);
	mixin Property!("spCharsTitle", string, "特殊文字", true);
	mixin Property!("colorW", string, "デフォルト(&W)", true);
	mixin Property!("colorR", string, "赤(&R)", true);
	mixin Property!("colorB", string, "青(&B)", true);
	mixin Property!("colorG", string, "緑(&G)", true);
	mixin Property!("colorY", string, "黄(&Y)", true);
	mixin(EnumToStringMethod!(Talker, "scTalkerName", "scTalkerName"));
	mixin Property!("scTalkerNameSelected", string, "選択メンバ名(#M)", true);
	mixin Property!("scTalkerNameUnselected", string, "選択外ランダムメンバ名(#U)", true);
	mixin Property!("scTalkerNameRandom", string, "ランダムメンバ名(#R)", true);
	mixin Property!("scTalkerNameCard", string, "選択カード名(#C)", true);
	mixin Property!("scTalkerNameNarration", string, "話者無し", true);
	mixin Property!("scTalkerNameImage", string, "画像", true);
	mixin Property!("scRef", string, "話者(#I)", true);
	mixin Property!("scTeam", string, "チーム名(#T)", true);
	mixin Property!("scYado", string, "宿屋名(#Y)", true);
	mixin Property!("addMsgRefFlag", string, "フラグ参照の追加", true);
	mixin Property!("addMsgRefStep", string, "ステップ参照の追加", true);
	mixin Property!("createDialog", string, "台詞の作成", true);
	mixin Property!("deleteDialog", string, "台詞の削除", true);
	mixin Property!("copyToDialogs", string, "台詞を全体にコピー", true);
	mixin Property!("copyToUpper", string, "台詞を上方にコピー", true);
	mixin Property!("copyToLower", string, "台詞を下方にコピー", true);
	mixin Property!("setTalkerCoupon", string, "追加", true);
	mixin Property!("messagePreview", string, "プレビュー", true);
	mixin Property!("dlgTitMessagePreview", string, "プレビュー", true);
	mixin Property!("messageVarKindColumn", string, "状態変数", true);
	mixin Property!("messageVarValueColumn", string, "サンプル値", true);

	mixin Property!("transition", string, "背景切替方式", true);
	mixin(EnumToStringMethod!(Transition, "transitionName", "transitionName"));
	mixin Property!("transitionNameDefault", string, "[プレイヤーの設定を使用]", true);
	mixin Property!("transitionNameNone", string, "アニメーション無し", true);
	mixin Property!("transitionNameFade", string, "フェード式", true);
	mixin Property!("transitionNamePixelDissolve", string, "ピクセルディゾルブ式", true);
	mixin Property!("transitionNameBlinds", string, "ブラインド式", true);
	mixin Property!("transitionSpeed", string, "背景切替ウェイト", true);
	mixin Property!("waitName", string, "空白時間(0.1秒単位)", true);
	mixin Property!("moneyName", string, "金額", true);
	mixin Property!("randomName", string, "確率(%)", true);
	mixin Property!("partyNumName", string, "パーティの人数", true);
	mixin Property!("judgeTarget", string, "判定対象", true);
	mixin Property!("flag", string, "フラグ", true);
	mixin Property!("step", string, "ステップ", true);
	mixin Property!("flagValue", string, "値", true);
	mixin Property!("stepValue", string, "段階", true);
	mixin Property!("selectMember", string, "選択対象", true);
	mixin Property!("activeMember", string, "動けるメンバから選択", true);
	mixin Property!("allMember", string, "パーティ全員から選択", true);
	mixin Property!("selectMethod", string, "選択方法", true);
	mixin Property!("manualMethod", string, "手動で選択", true);
	mixin Property!("randomMethod", string, "ランダムで選択", true);
	mixin Property!("judgeSleep", string, "眠り判定", true);
	mixin Property!("sleepDisabled", string, "睡眠者無効", true);
	mixin Property!("sleepEnabled", string, "睡眠者有効", true);
	mixin Property!("selectedLevel", string, "現在選択中のメンバ", true);
	mixin Property!("allMemberLevel", string, "パーティ全員の平均値", true);
	mixin Property!("judgeLevel", string, "判定レベル", true);
	mixin Property!("judgeState", string, "判定状態", true);
	mixin Property!("stateHint", string, "ヒント", true);
	mixin Property!("cardNumber", string, "枚数", true);
	mixin Property!("cardAllDelete", string, "全て削除する", true);
	mixin Property!("cardEventRange", string, "適用範囲", true);
	mixin Property!("transitionType", string, "背景切替方式", true);

	/// イベント。
	mixin Property!("evtArrow", string, "イベント編集", true);

	mixin Property!("evtAddContinue", string, "連続で配置", true);
	mixin Property!("evtAutoOpen", string, "配置と同時に編集", true);

	mixin(EnumToStringMethod!(CType, "contentName", "contentName"));
	mixin Property!("contentNameStart", string, "スタート", true);
	mixin Property!("contentNameStartBattle", string, "バトル開始", true);
	mixin Property!("contentNameEnd", string, "シナリオクリア", true);
	mixin Property!("contentNameEndBadEnd", string, "ゲームオーバー", true);
	mixin Property!("contentNameChangeArea", string, "エリア移動", true);
	mixin Property!("contentNameChangeBgImage", string, "背景変更", true);
	mixin Property!("contentNameEffect", string, "効果", true);
	mixin Property!("contentNameEffectBreak", string, "効果中断", true);
	mixin Property!("contentNameLinkStart", string, "スタートへのリンク", true);
	mixin Property!("contentNameLinkPackage", string, "パッケージへのリンク", true);
	mixin Property!("contentNameTalkMessage", string, "メッセージ", true);
	mixin Property!("contentNameTalkDialog", string, "セリフ", true);
	mixin Property!("contentNamePlayBgm", string, "BGM変更", true);
	mixin Property!("contentNamePlaySound", string, "効果音", true);
	mixin Property!("contentNameWait", string, "空白時間挿入", true);
	mixin Property!("contentNameElapseTime", string, "時間経過", true);
	mixin Property!("contentNameCallStart", string, "スタートの呼び出し", true);
	mixin Property!("contentNameCallPackage", string, "パッケージの呼び出し", true);
	mixin Property!("contentNameBranchFlag", string, "フラグ分岐", true);
	mixin Property!("contentNameBranchMultiStep", string, "ステップ多岐分岐", true);
	mixin Property!("contentNameBranchStep", string, "ステップ上下分岐", true);
	mixin Property!("contentNameBranchSelect", string, "メンバ選択分岐", true);
	mixin Property!("contentNameBranchAbility", string, "能力判定分岐", true);
	mixin Property!("contentNameBranchRandom", string, "ランダム分岐", true);
	mixin Property!("contentNameBranchLevel", string, "レベル判定分岐", true);
	mixin Property!("contentNameBranchStatus", string, "状態判定分岐", true);
	mixin Property!("contentNameBranchPartyNumber", string, "人数判定分岐", true);
	mixin Property!("contentNameBranchArea", string, "エリア分岐", true);
	mixin Property!("contentNameBranchBattle", string, "バトル分岐", true);
	mixin Property!("contentNameBranchIsBattle", string, "バトル判定分岐", true);
	mixin Property!("contentNameBranchCast", string, "キャスト存在分岐", true);
	mixin Property!("contentNameBranchItem", string, "アイテム所持分岐", true);
	mixin Property!("contentNameBranchSkill", string, "スキル所持分岐", true);
	mixin Property!("contentNameBranchInfo", string, "情報所持分岐", true);
	mixin Property!("contentNameBranchBeast", string, "召喚獣存在分岐", true);
	mixin Property!("contentNameBranchMoney", string, "所持金分岐", true);
	mixin Property!("contentNameBranchCoupon", string, "クーポン分岐", true);
	mixin Property!("contentNameBranchCompleteStamp", string, "終了シナリオ分岐", true);
	mixin Property!("contentNameBranchGossip", string, "ゴシップ分岐", true);
	mixin Property!("contentNameSetFlag", string, "フラグ変更", true);
	mixin Property!("contentNameSetStep", string, "ステップ変更", true);
	mixin Property!("contentNameSetStepUp", string, "ステップ増加", true);
	mixin Property!("contentNameSetStepDown", string, "ステップ減少", true);
	mixin Property!("contentNameReverseFlag", string, "フラグ反転", true);
	mixin Property!("contentNameCheckFlag", string, "フラグ判定", true);
	mixin Property!("contentNameGetCast", string, "キャスト加入", true);
	mixin Property!("contentNameGetItem", string, "アイテム入手", true);
	mixin Property!("contentNameGetSkill", string, "スキル取得", true);
	mixin Property!("contentNameGetInfo", string, "情報入手", true);
	mixin Property!("contentNameGetBeast", string, "召喚獣獲得", true);
	mixin Property!("contentNameGetMoney", string, "所持金増加", true);
	mixin Property!("contentNameGetCoupon", string, "クーポン取得", true);
	mixin Property!("contentNameGetCompleteStamp", string, "終了シナリオ設定", true);
	mixin Property!("contentNameGetGossip", string, "ゴシップ追加", true);
	mixin Property!("contentNameLoseCast", string, "キャスト離脱", true);
	mixin Property!("contentNameLoseItem", string, "アイテム喪失", true);
	mixin Property!("contentNameLoseSkill", string, "スキル喪失", true);
	mixin Property!("contentNameLoseInfo", string, "情報喪失", true);
	mixin Property!("contentNameLoseBeast", string, "召喚獣消去", true);
	mixin Property!("contentNameLoseMoney", string, "所持金減少", true);
	mixin Property!("contentNameLoseCoupon", string, "クーポン削除", true);
	mixin Property!("contentNameLoseCompleteStamp", string, "終了シナリオ削除", true);
	mixin Property!("contentNameLoseGossip", string, "ゴシップ削除", true);
	mixin Property!("contentNameShowParty", string, "パーティ表示", true);
	mixin Property!("contentNameHideParty", string, "パーティ隠蔽", true);
	mixin Property!("contentNameRedisplay", string, "画面再構築", true);

	mixin Property!("msnGroupVitality", string, "生命力", true);
	mixin Property!("msnGroupPhysical", string, "肉体", true);
	mixin Property!("msnGroupSkill", string, "技能", true);
	mixin Property!("msnGroupMental", string, "精神", true);
	mixin Property!("msnGroupMagic", string, "魔法", true);
	mixin Property!("msnGroupEnhance", string, "能力", true);
	mixin Property!("msnGroupVanish", string, "消滅", true);
	mixin Property!("msnGroupCard", string, "カード", true);
	mixin Property!("msnGroupBeast", string, "召喚", true);

	mixin Property!("msnDelete", string, "効果削除", true);

	mixin Property!("msnDesc", string, "%1$s - %2$s", true);

	mixin(EnumToStringMethod!(MType, "motionName", "motionName"));
	mixin Property!("motionNameHeal", string, "回復", true);
	mixin Property!("motionNameDamage", string, "ダメージ", true);
	mixin Property!("motionNameAbsorb", string, "吸収", true);
	mixin Property!("motionNameParalyze", string, "麻痺", true);
	mixin Property!("motionNameDisParalyze", string, "麻痺解除", true);
	mixin Property!("motionNamePoison", string, "中毒", true);
	mixin Property!("motionNameDisPoison", string, "中毒解除", true);
	mixin Property!("motionNameGetSkillPower", string, "精神力回復", true);
	mixin Property!("motionNameLoseSkillPower", string, "精神力喪失", true);
	mixin Property!("motionNameSleep", string, "睡眠状態", true);
	mixin Property!("motionNameConfuse", string, "混乱状態", true);
	mixin Property!("motionNameOverheat", string, "激昂状態", true);
	mixin Property!("motionNameBrave", string, "勇敢状態", true);
	mixin Property!("motionNamePanic", string, "恐慌状態", true);
	mixin Property!("motionNameNormal", string, "正常状態", true);
	mixin Property!("motionNameBind", string, "呪縛", true);
	mixin Property!("motionNameDisBind", string, "呪縛解除", true);
	mixin Property!("motionNameSilence", string, "沈黙", true);
	mixin Property!("motionNameDisSilence", string, "沈黙解除", true);
	mixin Property!("motionNameFaceUp", string, "暴露", true);
	mixin Property!("motionNameFaceDown", string, "暴露解除", true);
	mixin Property!("motionNameAntiMagic", string, "魔法無効化", true);
	mixin Property!("motionNameDisAntiMagic", string, "魔法無効化解除", true);
	mixin Property!("motionNameEnhanceAction", string, "行動力変化", true);
	mixin Property!("motionNameEnhanceAvoid", string, "回避力変化", true);
	mixin Property!("motionNameEnhanceDefense", string, "防御力変化", true);
	mixin Property!("motionNameEnhanceResist", string, "抵抗力変化", true);
	mixin Property!("motionNameVanishTarget", string, "対象消去", true);
	mixin Property!("motionNameVanishCard", string, "手札消去", true);
	mixin Property!("motionNameVanishBeast", string, "召喚獣消去", true);
	mixin Property!("motionNameDealAttackCard", string, "通常攻撃", true);
	mixin Property!("motionNameDealPowerfulAttackCard", string, "渾身の一撃", true);
	mixin Property!("motionNameDealCriticalAttackCard", string, "会心の一撃", true);
	mixin Property!("motionNameDealFeintCard", string, "フェイント", true);
	mixin Property!("motionNameDealDefenseCard", string, "防御", true);
	mixin Property!("motionNameDealDistanceCard", string, "見切り", true);
	mixin Property!("motionNameDealConfuseCard", string, "混乱", true);
	mixin Property!("motionNameDealSkillCard", string, "特殊技能", true);
	mixin Property!("motionNameSummonBeast", string, "召喚獣召喚", true);

	mixin Property!("dialogText", string, "%2$s: %1$s", true);
	mixin Property!("dialogTextNoCoupon", string, "%1$s", true);

	mixin Property!("ctStart", string, "スタートコンテント「%1$s」", true);
	mixin Property!("ctStartBattle", string, "バトルの開始「%1$s」", true);
	mixin Property!("ctChangeArea", string, "エリア移動「%1$s」 切替方式 = %2$s ウェイト = %3$s", true);
	mixin Property!("ctChangeAreaClassic", string, "エリア移動「%1$s」", true);
	mixin Property!("ctEndComplete", string, "済印をつけて終了", true);
	mixin Property!("ctEndNoComplete", string, "済印をつけずに終了", true);
	mixin Property!("ctGameOver", string, "ゲームオーバーコンテント", true);
	mixin Property!("ctChangeBgImage", string, "背景ファイル = %1$s 切替方式 = %2$s ウェイト = %3$s", true);
	mixin Property!("ctChangeBgImageClassic", string, "背景ファイル = %1$s", true);
	mixin Property!("ctChangeBgImageFile", string, "[%1$s]", true);
	mixin Property!("ctEffectSound", string, "「%1$s」を再生", true);
	mixin Property!("ctEffectNoSound", string, "音声無し", true);
	mixin Property!("ctEffect", string, "%1$s レベル%2$s %3$s/%4$s 成功率%5$s%6$s %7$s %8$s 効果 = %9$s", true);
	mixin Property!("ctEffectMotion", string, "[%1$s]", true);
	mixin Property!("ctEffectBreak", string, "効果中断コンテント", true);
	mixin Property!("ctStopBGM", string, "BGM停止", true);
	mixin Property!("ctLinkStart", string, "スタートコンテント「%1$s」へのリンク", true);
	mixin Property!("ctLinkPackage", string, "パッケージ「%1$s」へのリンク", true);
	mixin Property!("ctTalkMessage", string, "%1$s: %2$s", true);
	mixin Property!("ctTalkMessageImage", string, "[%1$s]", true);
	mixin Property!("ctTalkDialog", string, "%1$s %2$s: %3$s", true);
	mixin Property!("ctTalkDialogNoCoupon", string, "%1$s: %2$s", true);
	mixin Property!("ctPlayBGM", string, "BGMとして「%1$s」を演奏", true);
	mixin Property!("ctPlaySound", string, "効果音「%1$s」を鳴らす", true);
	mixin Property!("ctWait", string, "空白時間 = %1$s × 0.1秒", true);
	mixin Property!("ctElapseTime", string, "ターン数経過コンテント", true);
	mixin Property!("ctCallStart", string, "スタートコンテント「%1$s」のコール", true);
	mixin Property!("ctCallPackage", string, "パッケージ「%1$s」のコール", true);
	mixin Property!("ctBranchFlag", string, "フラグ「%1$s」の値で分岐", true);
	mixin Property!("ctBranchMultiStep", string, "ステップ「%1$s」の値で分岐", true);
	mixin Property!("ctBranchStep", string, "ステップ「%1$s」の値が[%2$s]以上・未満で分岐", true);
	mixin Property!("ctBranchSelectAll", string, "パーティ全員", true);
	mixin Property!("ctBranchSelectActive", string, "動けるメンバ", true);
	mixin Property!("ctBranchSelectAuto", string, "ランダム", true);
	mixin Property!("ctBranchSelectManual", string, "手動", true);
	mixin Property!("ctBranchSelect", string, "%1$sから%2$sでメンバを選択", true);
	mixin Property!("ctBranchAbility", string, "%1$s(%2$s)の%3$sと%4$sで能力判定(レベル%5$s)", true);
	mixin Property!("ctBranchRandom", string, "確率 = %1$s%%", true);
	mixin Property!("ctBranchLevelAverage", string, "パーティ全員", true);
	mixin Property!("ctBranchLevelSelected", string, "選択中のメンバ", true);
	mixin Property!("ctBranchLevel", string, "%1$sのレベルが%2$s以上・未満で分岐", true);
	mixin Property!("ctBranchStatus", string, "%1$sが%2$s状態か否かで分岐", true);
	mixin Property!("ctBranchPartyNumber", string, "人数 = %1$s人", true);
	mixin Property!("ctBranchArea", string, "エリア分岐コンテント", true);
	mixin Property!("ctBranchBattle", string, "バトル分岐コンテント", true);
	mixin Property!("ctBranchIsBattle", string, "戦闘中判定分岐コンテント", true);
	mixin Property!("ctBranchCast", string, "キャストカード「%1$s」の同行有無で分岐", true);
	mixin Property!("ctBranchSkill", string, "特殊技能カード「%1$s」の有無で分岐(%2$sに%3$s枚)", true);
	mixin Property!("ctBranchItem", string, "アイテムカード「%1$s」の有無で分岐(%2$sに%3$s枚)", true);
	mixin Property!("ctBranchBeast", string, "召喚獣カード「%1$s」の有無で分岐(%2$sに%3$s枚)", true);
	mixin Property!("ctBranchInfo", string, "情報カード「%1$s」の有無で分岐", true);
	mixin Property!("ctBranchMoney", string, "分岐金額 = %1$ssp", true);
	mixin Property!("ctBranchCoupon", string, "称号「%1$s」の有無で分岐(%2$s)", true);
	mixin Property!("ctBranchCompleteStamp", string, "シナリオ「%1$s」が終了済みか否かで分岐", true);
	mixin Property!("ctBranchGossip", string, "ゴシップ「%1$s」の有無で分岐", true);
	mixin Property!("ctSetFlag", string, "フラグ「%1$s」を[%2$s]に変更", true);
	mixin Property!("ctSetStep", string, "ステップ「%1$s」を[%2$s]に変更", true);
	mixin Property!("ctSetStepUp", string, "ステップ「%1$s」の値を1増加", true);
	mixin Property!("ctSetStepDown", string, "ステップ「%1$s」の値を1減少", true);
	mixin Property!("ctReverseFlag", string, "フラグ「%1$s」の値を反転", true);
	mixin Property!("ctCheckFlag", string, "フラグ「%1$s」の値が[%2$s]であれば出現", true);
	mixin Property!("ctGetCast", string, "キャストカード「%1$s」を同行させる", true);
	mixin Property!("ctGetSkill", string, "特殊技能カード「%1$s」を獲得(%2$sに%3$s枚)", true);
	mixin Property!("ctGetItem", string, "アイテムカード「%1$s」を獲得(%2$sに%3$s枚)", true);
	mixin Property!("ctGetBeast", string, "召喚獣カード「%1$s」を獲得(%2$sに%3$s枚)", true);
	mixin Property!("ctGetInfo", string, "情報カード「%1$s」を獲得", true);
	mixin Property!("ctGetMoney", string, "獲得金額 = %1$ssp", true);
	mixin Property!("ctGetCoupon", string, "称号「%1$s」を獲得(%2$s)", true);
	mixin Property!("ctGetCompleteStamp", string, "シナリオ%1$sを終了済みにする", true);
	mixin Property!("ctGetGossip", string, "ゴシップ「%1$s」を獲得", true);
	mixin Property!("ctLoseCardAll", string, "全て", true);
	mixin Property!("ctLoseCardCount", string, "%1$s枚", true);
	mixin Property!("ctLoseCast", string, "キャストカード「%1$s」の同行を解除", true);
	mixin Property!("ctLoseSkill", string, "特殊技能カード「%1$s」を喪失(%2$sから%3$s)", true);
	mixin Property!("ctLoseItem", string, "アイテムカード「%1$s」を喪失(%2$sから%3$s)", true);
	mixin Property!("ctLoseBeast", string, "召喚獣カード「%1$s」を喪失(%2$sから%3$s)", true);
	mixin Property!("ctLoseInfo", string, "情報カード「%1$s」を喪失", true);
	mixin Property!("ctLoseMoney", string, "喪失金額 = %1$ssp", true);
	mixin Property!("ctLoseCoupon", string, "称号「%1$s」を喪失(%2$s)", true);
	mixin Property!("ctLoseCompleteStamp", string, "シナリオ%1$sの終了印を削除", true);
	mixin Property!("ctLoseGossip", string, "ゴシップ「%1$s」を喪失", true);
	mixin Property!("ctShowParty", string, "パーティ表示コンテント", true);
	mixin Property!("ctHideParty", string, "パーティ隠蔽コンテント", true);
	mixin Property!("ctRedisplay", string, "切替方式 = %1$s ウェイト = %2$s", true);
	mixin Property!("ctRedisplayClassic", string, "画面再構築コンテント", true);

	mixin Property!("defaultStartName", string, "イベント開始", true);

	mixin Property!("oggMayNotCorrespond", string, "Oggはプレイヤーの環境によって再生できない事があります。", true);
	mixin Property!("mp3LoopMayNotCorrespond", string, "MP3はプレイヤーの環境によってループ再生されない事があります。", true);

	/// メインウィンドウ。
	mixin Property!("mainWindowName", string, "%1$s [ %2$s ] - CWXEditor", true);
	mixin Property!("mainWindowNameChanged", string, "*%1$s [ %2$s ] - CWXEditor", true);
	mixin Property!("mainWindowNameEmpty", string, "CWXEditor", true);
	mixin Property!("errorExecEngine", string, "%1$sの起動に失敗しました。", true);

	/// シナリオ選択ダイアログ
	mixin Property!("dlgTitNewScenario", string, "新規シナリオの作成", true);
	mixin Property!("dlgTitNewScenarioAtNewWin", string, "新しいウィンドウで新規シナリオの作成", true);
	mixin Property!("dlgTitOpenScenario", string, "シナリオを開く", true);
	mixin Property!("dlgTitOpenScenarioAtNewWin", string, "新しいウィンドウでシナリオを開く", true);
	mixin Property!("filterScenario", string, "シナリオファイル (%1$s)", true);
	mixin Property!("filterParts", string, "エリア・カードファイル (%1$s)", true);
	mixin Property!("dlgTitSaveScenario", string, "名前を付けて保存", true);
	mixin Property!("filterScenarioSave", string, "XMLシナリオファイル (*.wsn)", true);
	mixin Property!("notScenario", string, "%1$sはシナリオ圧縮ファイルではありません", true);
	mixin Property!("zipError", string, "%1$sの展開に失敗しました。", true);
	mixin Property!("loadError", string, "%1$sの読込みに失敗しました。", true);
	mixin Property!("saveError", string, "%1$sの保存に失敗しました。", true);
	mixin Property!("loadErrorStatus", string, "%1$sの読込みに失敗", true);
	mixin Property!("loadErrorStatusCount", string, "%1$s件のシナリオの読込みに失敗", true);
	mixin Property!("scenarioNotFound", string, "%1$sは存在しないか、シナリオではありません。履歴から削除しますか？", true);

	/// データウィンドウ
	mixin Property!("dataTabName", string, "データ", true);
	mixin Property!("dataWindowName", string, "データ - [ %1$s ] - %2$s", true);
	mixin Property!("areasTabName", string, "テーブル", true);
	mixin Property!("areasWindowName", string, "テーブル - [ %1$s ] - %2$s", true);
	mixin Property!("areaStatus", string, "%2$s件の%1$s", true);
	mixin Property!("flagTabName", string, "状態変数", true);
	mixin Property!("flagWindowName", string, "状態変数 - [ %1$s ] - %2$s", true);
	mixin Property!("flagStatus", string, "%2$s個の%1$s", true);
	mixin Property!("flagStatusSel", string, "%1$s (%2$s個を選択)", true);
	mixin Property!("scenarioView", string, "シナリオビューリスト", true);
	mixin Property!("variableView", string, "状態変数インスペクタ", true);

	mixin Property!("reNumberingAll", string, "全てのエリアやカードのIDの1から振り直します。\nよろしいですか？", true);

	mixin Property!("dlgTitReNumbering", string, "IDの振り直し", true);
	mixin Property!("reNumbering", string, "IDの振り直し", true);
	mixin Property!("reNumbering1", string, "%1$s「%2$s」以降のIDを", true);
	mixin Property!("reNumbering2", string, "番から順に振り直す", true); // reNumbering1と同様のパラメータを取る

	/// エリアのテーブル。
	mixin Property!("areaId", string, "ID", true);
	mixin Property!("areaName", string, "名称", true);
	mixin Property!("areaCount", string, "利用数", true);
	mixin Property!("areaNew", string, "新規エリア", true);
	mixin Property!("battleNew", string, "新規バトル", true);
	mixin Property!("packageNew", string, "新規パッケージ", true);

	/// フラグのディレクトリ。
	mixin Property!("flagDirRoot", string, "Data", true);
	mixin Property!("flagDirNew", string, "新規フォルダ", true);

	/// フラグ/ステップのテーブル。
	mixin Property!("flagName", string, "名称", true);
	mixin Property!("flagInit", string, "初期値", true);
	mixin Property!("flagCount", string, "利用数", true);

	/// フラグ設定ダイアログ関連。
	mixin Property!("dlgTitFlag", string, "フラグの設定", true);
	mixin Property!("dlgLblFlagName", string, "フラグ名", true);
	mixin Property!("dlgLblFlagInit", string, "初期値", true);
	mixin Property!("dlgLblFlagTrue", string, "TRUE", true);
	mixin Property!("dlgLblFlagFalse", string, "FALSE", true);

	/// ステップ設定ダイアログ関連。
	mixin Property!("dlgTitStep", string, "ステップの設定", true);
	mixin Property!("dlgLblStepName", string, "ステップ名", true);
	mixin Property!("dlgLblStepInit", string, "初期値", true);
	mixin Property!("dlgLblStep", string, "Step - %1$s", true);
	mixin Property!("dlgTxtStep", string, "Step - %1$s", true);

	/// 貼り紙設定ダイアログ関連。
	mixin Property!("dlgTitSummary", string, "概略の設定 - [ %1$s ]", true);
	mixin Property!("summaryPreview", string, "表示イメージ", true);
	mixin Property!("baseData", string, "基本データ", true);
	mixin Property!("etcData", string, "詳細データ", true);
	mixin Property!("targetLevelSame", string, "対象レベル %1$s", true);
	mixin Property!("targetLevelHL", string, "対象レベル %1$s～%2$s", true);
	mixin Property!("targetLevelL", string, "対象レベル %1$s～", true);
	mixin Property!("targetLevelH", string, "対象レベル ～%1$s", true);
	mixin Property!("summaryPageDummy", string, "1/1", true);
	mixin Property!("title", string, "シナリオタイトル", true);
	mixin Property!("author", string, "作者名", true);
	mixin Property!("targetLevel", string, "対象レベル", true);
	mixin Property!("desc", string, "解説", true);
	mixin Property!("levSep", string, "～", true);
	mixin Property!("qualification", string, "シナリオ出現条件", true);
	mixin Property!("rCouponNum", string, "必要数", true);
	mixin Property!("rCoupons", string, "必要とする称号", true);
	mixin Property!("startArea", string, "シナリオ開始エリア", true);

	mixin Property!("scenarioType", string, "シナリオタイプ", true);
	mixin Property!("sTypeXML", string, "スキンを指定", true);
	mixin Property!("sTypeClassic", string, "クラシックエンジンを使用", true);
	mixin Property!("currentEngineSkin", string, "[%1$s]", true);

	mixin Property!("pngMayNotCorrespond", string, "PNGイメージはプレイヤーの環境によって表示エラーとなる事があります。", true);

	/// エリア・戦闘・パッケージウィンドウ。
	mixin Property!("noRefArea", string, "[カード配置参照無し]", true);
	mixin Property!("areaViewFlagDesc", string, "フラグ", true);
	mixin Property!("areaViewRefAreaDesc", string, "参照", true);

	mixin Property!("left", string, "X", true);
	mixin Property!("top", string, "Y", true);
	mixin Property!("width", string, "幅", true);
	mixin Property!("height", string, "高", true);
	mixin Property!("scale", string, "拡大率", true);

	mixin Property!("areaViewStatus", string, "%1$s [%2$s] - %3$s", true);
	mixin Property!("areaViewStatusNoSummary", string, "%1$s [%2$s]", true);
	mixin Property!("areaViewStatusNoFlag", string, "フラグ指定無し", true);
	mixin Property!("areaViewStatusInvalidFlag", string, "存在しないフラグ(%1$s)", true);
	mixin Property!("areaViewStatusWithFlag", string, "フラグ = %1$s", true);
	mixin Property!("areaViewStatusImageIncluding", string, "イメージ格納", true);
	mixin Property!("areaViewStatusSelCard", string, "%1$s枚のカード", true);
	mixin Property!("areaViewStatusSelBack", string, "%1$s枚の背景", true);
	mixin Property!("areaViewStatusEnemyCard", string, "%1$s.%2$s", true);

	mixin Property!("viewNameTab", string, "%2$s.%3$s", true);
	mixin Property!("viewNameSceneTab", string, "%2$s.%3$s", true);
	mixin Property!("viewNameEventTab", string, "%2$s.%3$s", true);
	mixin Property!("viewName", string, "[%1$s] - %2$s - %3$s", true);
	mixin Property!("viewNameScene", string, "[%1$s カードと背景] - %2$s - %3$s", true);
	mixin Property!("viewNameEvent", string, "[%1$s イベント] - %2$s - %3$s", true);

	mixin Property!("cardCount", string, "使用数", true);

	mixin Property!("cardAndBackView", string, "カードと背景", true);
	mixin Property!("enemyCardView", string, "エネミーカード", true);
	mixin Property!("menuCards", string, "カード", true);
	mixin Property!("enemyCards", string, "カード", true);
	mixin Property!("backs", string, "背景", true);
	mixin Property!("eventView", string, "イベント", true);
	mixin Property!("menuCard", string, "メニューカード", true);
	mixin Property!("enemyCard", string, "エネミーカード", true);
	mixin Property!("back", string, "背景画像", true);

	/// カード/背景配置領域関連。
	mixin Property!("dlgTitDropCard", string, "カード画像の追加", true);
	mixin Property!("dlgMsgDropCard", string, "カード画像をシナリオ" ~ DIR ~ "にコピーしますか？\n%1$s", true);
	mixin Property!("dlgTitDropBack", string, "背景画像の追加", true);
	mixin Property!("dlgMsgDropBack", string, "背景画像をシナリオ" ~ DIR ~ "にコピーしますか？\n%1$s", true);

	mixin Property!("refFlag", string, "フラグ参照先", true);
	mixin Property!("refStep", string, "ステップ参照先", true);
	mixin Property!("noFlagRef", string, "[参照無し]", true);
	mixin Property!("cardPosition", string, "カード位置", true);
	mixin Property!("backPosition", string, "位置", true);
	mixin Property!("bgImageSettings", string, "簡単設定", true);
	mixin Property!("bgImageSettingCustom", string, "[カスタム]", true);
	mixin Property!("bgImageSettingOriginal", string, "[元のサイズ]", true);
	mixin Property!("enemyCardBase", string, "基本設定", true);
	mixin Property!("dlgTitMenuCard", string, "メニューカードの設定 [ %1$s ]", true);
	mixin Property!("dlgTitNewMenuCard", string, "メニューカードの作成", true);
	mixin Property!("dlgTitBgImage", string, "背景画像の設定", true);
	mixin Property!("dlgTitNewBgImage", string, "背景画像の作成", true);
	mixin Property!("dlgTitEnemyCard", string, "エネミーカードの設定 [ %1$s ]", true);
	mixin Property!("dlgTitNewEnemyCard", string, "エネミーカードの作成", true);

	/// イベントビュー。
	mixin Property!("tools", string, "イベントコンテント", true);
	mixin Property!("startEnter", string, "到着", true);
	mixin Property!("startSelect", string, "クリック", true);
	mixin Property!("startDead", string, "死亡", true);
	mixin Property!("startVictory", string, "勝利", true);
	mixin Property!("startEscape", string, "逃走", true);
	mixin Property!("startLose", string, "敗北", true);
	mixin Property!("startPackage", string, "パッケージ", true);
	mixin Property!("startUse", string, "使用時", true);
	mixin Property!("startRound", string, "ラウンド = %1$s", true);
	mixin Property!("keyCodeTimingUse", string, "使用", true);
	mixin Property!("keyCodeTimingSuccess", string, "成功", true);
	mixin Property!("keyCodeTimingFailure", string, "失敗", true);

	mixin Property!("manyRounds", string, "追加する発火ラウンドの範囲", true);
	mixin Property!("dlgTitAddManyRounds", string, "追加する発火ラウンドの範囲", true);
	mixin Property!("roundSep", string, "～", true);

	mixin Property!("enterTree", string, "到着", true);
	mixin Property!("selectTree", string, "クリック", true);
	mixin Property!("deadTree", string, "死亡", true);
	mixin Property!("victoryTree", string, "勝利", true);
	mixin Property!("escapeTree", string, "逃走", true);
	mixin Property!("loseTree", string, "敗北", true);
	mixin Property!("packageTree", string, "パッケージイベント", true);
	mixin Property!("useTree", string, "使用時イベント", true);
	mixin Property!("keyCodeTree", string, "[%1$s]", true);
	mixin Property!("roundTree", string, "ラウンド %1$s", true);

	mixin Property!("eventTreeKindSystem", string, "システム", true);
	mixin Property!("eventTreeKindKeyCode", string, "キーコード", true);
	mixin Property!("eventTreeKindRound", string, "ラウンド", true);

	mixin Property!("startUseCount", string, "利用数", true);

	mixin Property!("flagOn", string, "TRUE", true);
	mixin Property!("flagOff", string, "FALSE", true);
	mixin Property!("evtChildBrVar", string, "%1$s = %2$s", true);
	mixin Property!("etc", string, "その他", true);
	mixin Property!("stepMoreThan", string, "ステップ「%1$s」が「%2$s」以上", true);
	mixin Property!("stepLessThan", string, "ステップ「%1$s」が「%2$s」未満", true);
	mixin Property!("partyAll", string, "パーティ全員", true);
	mixin Property!("partyActive", string, "動けるメンバ", true);
	mixin Property!("autoSelect", string, "自動", true);
	mixin Property!("manualSelect", string, "手動", true);
	mixin Property!("selectMemberSuccess", string, "%1$sから%2$sでキャラクターを選択", true);
	mixin Property!("selectMemberFailure", string, "%1$sから%2$sでのキャラクター選択をキャンセル", true);
	mixin Property!("branchAbilitySuccess", string, "%1$sがレベル%2$sで%3$sと%4$sで行う判定に成功", true);
	mixin Property!("branchAbilityFailure", string, "%1$sがレベル%2$sで%3$sと%4$sで行う判定に失敗", true);
	mixin Property!("branchRandomSuccess", string, "%1$s%%成功", true);
	mixin Property!("branchRandomFailure", string, "%1$s%%失敗", true);
	mixin Property!("levelAverage", string, "パーティ全員の平均値", true);
	mixin Property!("levelSelected", string, "選択中のメンバ", true);
	mixin Property!("branchLevelSuccess", string, "%1$sがレベル%2$s以上", true);
	mixin Property!("branchLevelFailure", string, "%1$sがレベル%2$s未満", true);
	mixin Property!("branchStatusSuccess", string, "%1$sでの「%2$s」の判定に成功", true);
	mixin Property!("branchStatusFailure", string, "%1$sでの「%2$s」の判定に失敗", true);
	mixin Property!("branchNumberSuccess", string, "パーティに%1$s人以上いる", true);
	mixin Property!("branchNumberFailure", string, "パーティは%1$s人未満", true);
	mixin Property!("branchArea", string, "エリア = %1$s", true);
	mixin Property!("branchBattle", string, "バトル = %1$s", true);
	mixin Property!("branchOnBattleSuccess", string, "イベント発生時の状況が戦闘中", true);
	mixin Property!("branchOnBattleFailure", string, "イベント発生時の状況が戦闘中以外", true);
	mixin Property!("branchCastSuccess", string, "「%1$s」が加わっている", true);
	mixin Property!("branchCastFailure", string, "「%1$s」が加わっていない", true);
	mixin Property!("branchEffectCardSuccess", string, "%1$sで「%2$s」を所有している", true);
	mixin Property!("branchEffectCardFailure", string, "%1$sで「%2$s」が所有していない", true);
	mixin Property!("branchInfoSuccess", string, "「%1$s」を所有している", true);
	mixin Property!("branchInfoFailure", string, "「%1$s」が所有していない", true);
	mixin Property!("branchMoneySuccess", string, "%1$ssp以上所持している", true);
	mixin Property!("branchMoneyFailure", string, "%1$ssp以上所持していない", true);
	mixin Property!("branchCouponSuccess", string, "%1$sがクーポン「%2$s」を所有している", true);
	mixin Property!("branchCouponFailure", string, "%1$sがクーポン「%2$s」を所有していない", true);
	mixin Property!("branchCompleteSuccess", string, "シナリオ「%1$s」が終了済みである", true);
	mixin Property!("branchCompleteFailure", string, "シナリオ「%1$s」が終了済みでない", true);
	mixin Property!("branchGossipSuccess", string, "ゴシップ「%1$s」が宿屋にある", true);
	mixin Property!("branchGossipFailure", string, "ゴシップ「%1$s」が宿屋に無い", true);

	mixin(EnumToStringMethod!(Physical, "physicalName", "physicalName"));
	mixin Property!("physicalNameDex", string, "器用度", true);
	mixin Property!("physicalNameAgl", string, "敏捷度", true);
	mixin Property!("physicalNameInt", string, "知力", true);
	mixin Property!("physicalNameStr", string, "筋力", true);
	mixin Property!("physicalNameVit", string, "生命力", true);
	mixin Property!("physicalNameMin", string, "精神力", true);
	mixin(EnumToStringMethod!(Mental, "mentalName", "mentalName"));
	mixin Property!("mentalNameAggressive", string, "好戦性", true);
	mixin Property!("mentalNameUnaggressive", string, "平和性", true);
	mixin Property!("mentalNameCheerful", string, "社交性", true);
	mixin Property!("mentalNameUncheerful", string, "内向性", true);
	mixin Property!("mentalNameBrave", string, "勇猛性", true);
	mixin Property!("mentalNameUnbrave", string, "臆病性", true);
	mixin Property!("mentalNameCautious", string, "慎重性", true);
	mixin Property!("mentalNameUncautious", string, "大胆性", true);
	mixin Property!("mentalNameTrickish", string, "狡猾性", true);
	mixin Property!("mentalNameUntrickish", string, "正直性", true);
	mixin(EnumToStringMethod!(Status, "statusName", "statusName"));
	mixin Property!("statusNameActive", string, "行動可能", true);
	mixin Property!("statusNameInactive", string, "行動不可", true);
	mixin Property!("statusNameAlive", string, "生存", true);
	mixin Property!("statusNameDead", string, "非生存", true);
	mixin Property!("statusNameFine", string, "健康", true);
	mixin Property!("statusNameInjured", string, "負傷", true);
	mixin Property!("statusNameHeavyInjured", string, "重傷", true);
	mixin Property!("statusNameUnconscious", string, "意識不明", true);
	mixin Property!("statusNamePoison", string, "中毒", true);
	mixin Property!("statusNameSleep", string, "眠り", true);
	mixin Property!("statusNameBind", string, "呪縛", true);
	mixin Property!("statusNameParalyze", string, "麻痺/石化", true);
	mixin Property!("effectTypeElement", string, "%1$s属性", true);
	mixin(EnumToStringMethod!(EffectType, "effectTypeName", "effectTypeName"));
	mixin Property!("effectTypeNamePhysic", string, "物理", true);
	mixin Property!("effectTypeNameMagic", string, "魔法", true);
	mixin Property!("effectTypeNameMagicalPhysic", string, "魔法的物理", true);
	mixin Property!("effectTypeNamePhysicalMagic", string, "物理的魔法", true);
	mixin Property!("effectTypeNameNone", string, "無", true);
	mixin(EnumToStringMethod!(Resist, "resistName", "resistName"));
	mixin Property!("resistNameAvoid", string, "回避属性", true);
	mixin Property!("resistNameResist", string, "抵抗属性", true);
	mixin Property!("resistNameUnfail", string, "必中属性", true);
	mixin(EnumToStringMethod!(CardTarget, "cardTargetName", "cardTargetName"));
	mixin Property!("cardTargetNameNone", string, "対象無し", true);
	mixin Property!("cardTargetNameUser", string, "使用者", true);
	mixin Property!("cardTargetNameParty", string, "味方", true);
	mixin Property!("cardTargetNameEnemy", string, "敵方", true);
	mixin Property!("cardTargetNameBoth", string, "双方", true);
	mixin Property!("cardTargetOne", string, "一体", true);
	mixin Property!("cardTargetAll", string, "全体", true);
	mixin(EnumToStringMethod!(CardVisual, "cardVisualName", "cardVisualName"));
	mixin Property!("cardVisualNameNone", string, "視覚効果無し", true);
	mixin Property!("cardVisualNameReverse", string, "対象を反転", true);
	mixin Property!("cardVisualNameHorizontal", string, "対象を横に震動", true);
	mixin Property!("cardVisualNameVertical", string, "対象を縦に震動", true);
	mixin(EnumToStringMethod!(Premium, "premiumName", "premiumName"));
	mixin Property!("premiumNameNormal", string, "日用品 (買戻し不可/破棄可)", true);
	mixin Property!("premiumNameRare", string, "希少品 (買戻し可/破棄可)", true);
	mixin Property!("premiumNamePremium", string, "貴重品 (買戻し可/破棄不可)", true);
	mixin(EnumToStringMethod!(Enhance, "enhanceName", "enhanceName"));
	mixin Property!("enhanceNameAction", string, "行動", true);
	mixin Property!("enhanceNameAvoid", string, "回避", true);
	mixin Property!("enhanceNameResist", string, "抵抗", true);
	mixin Property!("enhanceNameDefense", string, "防御", true);
	mixin Property!("mentality", string, "精神状態", true);
	mixin(EnumToStringMethod!(Mentality, "mentalityName", "mentalityName"));
	mixin Property!("mentalityNameNormal", string, "正常", true);
	mixin Property!("mentalityNameSleep", string, "睡眠", true);
	mixin Property!("mentalityNameConfuse", string, "混乱", true);
	mixin Property!("mentalityNameOverheat", string, "激昂", true);
	mixin Property!("mentalityNameBrave", string, "勇敢", true);
	mixin Property!("mentalityNamePanic", string, "恐慌", true);

	mixin Property!("enhanceBonus", string, "%1$sボーナス", true);
	mixin Property!("statusActive", string, "※ 行動可能 = (健康 | 負傷 | 重傷 | 中毒)", true);
	mixin Property!("statusInactive", string, "※ 行動不可 = (意識不明 | 麻痺/石化 | 呪縛 | 眠り)", true);
	mixin Property!("statusAlive", string, "※ 生存 = (健康 | 負傷 | 重傷 | 中毒 | 呪縛 | 眠り)", true);
	mixin Property!("statusDead", string, "※ 非生存 = (意識不明 | 麻痺/石化)", true);
	mixin(EnumToStringMethod2!(Target.M, "Target.M", "targetName", "targetName"));
	mixin Property!("targetNameSelected", string, "選択中のメンバ", true);
	mixin Property!("targetNameUnselected", string, "選択中以外のメンバ", true);
	mixin Property!("targetNameRandom", string, "誰か一人", true);
	mixin Property!("targetNameParty", string, "パーティ全員", true);
	mixin(EnumToStringMethod!(Talker, "talkerName", "talkerName"));
	mixin Property!("talkerNameSelected", string, "[選択中]", true);
	mixin Property!("talkerNameUnselected", string, "[選択中以外]", true);
	mixin Property!("talkerNameRandom", string, "[ランダム]", true);
	mixin Property!("talkerNameCard", string, "[カード]", true);
	mixin Property!("talkerNameNarration", string, "[話者無し]", true);
	mixin Property!("talkerNameImage", string, "[画像]", true);
	mixin(EnumToStringMethod!(Range, "rangeName", "rangeName"));
	mixin Property!("rangeNameSelected", string, "現在選択中のメンバ", true);
	mixin Property!("rangeNameRandom", string, "パーティの誰か一人", true);
	mixin Property!("rangeNameParty", string, "パーティの全員", true);
	mixin Property!("rangeNameBackpack", string, "荷物袋", true);
	mixin Property!("rangeNamePartyAndBackpack", string, "全体(荷物袋含む)", true);
	mixin Property!("rangeNameField", string, "フィールド全体", true);
	mixin(EnumToStringMethod!(DamageType, "damageTypeName", "damageTypeName"));
	mixin Property!("damageTypeNameLevelRatio", string, "レベルに対応する値", true);
	mixin Property!("damageTypeNameNormal", string, "値の直接入力", true);
	mixin Property!("damageTypeNameMax", string, "最大値処理", true);
	mixin(EnumToStringMethod!(Element, "elementName", "elementName"));
	mixin Property!("elementNameAll", string, "全", true);
	mixin Property!("elementNameHealth", string, "肉体", true);
	mixin Property!("elementNameMind", string, "精神", true);
	mixin Property!("elementNameMiracle", string, "神聖", true);
	mixin Property!("elementNameMagic", string, "魔力", true);
	mixin Property!("elementNameFire", string, "炎", true);
	mixin Property!("elementNameIce", string, "冷気", true);

	mixin(EnumToStringMethod!(Sex, "sexName", "sexName"));
	mixin Property!("sexNameMale", string, "男/♂", true);
	mixin Property!("sexNameFemale", string, "女/♀", true);
	mixin Property!("sexUnknown", string, "謎/？", true);
	mixin Property!("periodUnknown", string, "不明", true);
	mixin Property!("natureUnknown", string, "その他", true);

	mixin Property!("dlgTitComment", string, "コメントの記述", true);

	/// カードウィンドウ。
	mixin Property!("mainCardWindowName", string, "カード - [ %1$s ] - %2$s", true);
	mixin Property!("mainCardWindowNameNoSummary", string, "カード", true);
	mixin Property!("mainCardTabName", string, "カード", true);
	mixin Property!("cardWindowName", string, "%1$s - [ %2$s ] - %3$s", true);
	mixin Property!("cardWindowNameNoSummary", string, "%1$s", true);
	mixin Property!("cardTabName", string, "%1$s", true);
	mixin Property!("handCardWindowName", string, "[所有カード] - %1$s.%2$s", true);
	mixin Property!("handCardTabName", string, "%1$s.%2$s", true);
	mixin Property!("importSourceWindowName", string, "カードのインポート - [ %1$s ] - %2$s", true);
	mixin Property!("importSourceTabName", string, "%1$s", true);

	mixin Property!("dlgTitAddScenario", string, "インポート元の選択", true);

	mixin Property!("cardStatus", string, "%1$s枚のカード", true);
	mixin Property!("cardStatusSelOne", string, "%1$s枚のカード (ID = %2$s)", true);
	mixin Property!("cardStatusSelMulti", string, "%1$s枚のカード (%2$s枚を選択中)", true);
	mixin Property!("handCardStatus", string, "%1$s枚のカード (有効枚数 = %2$s)", true);
	mixin Property!("handCardStatusSelOne", string, "%1$s枚のカード (有効枚数 = %2$s) (ID = %3$s)", true);
	mixin Property!("handCardStatusSelMulti", string, "%1$s枚のカード (有効枚数 = %2$s) (%3$s枚を選択中)", true);

	mixin Property!("cwCast", string, "キャスト", true);
	mixin Property!("skill", string, "特殊技能", true);
	mixin Property!("item", string, "アイテム", true);
	mixin Property!("beast", string, "召喚獣", true);
	mixin Property!("info", string, "情報", true);

	mixin Property!("noSelectImage", string, "(指定無し)", true);
	mixin Property!("noImage", string, "存在しないイメージ(パス:%1$s)", true);
	mixin Property!("noSelectBGM", string, "(指定無し)", true);
	mixin Property!("noBGM", string, "存在しないBGM(パス:%1$s)", true);
	mixin Property!("noSelectSE", string, "(指定無し)", true);
	mixin Property!("noSE", string, "存在しない効果音(パス:%1$s)", true);
	mixin Property!("noSelectArea", string, "(指定無し)", true);
	mixin Property!("noArea", string, "存在しないエリア(ID:%1$s)", true);
	mixin Property!("noSelectBattle", string, "(指定無し)", true);
	mixin Property!("noBattle", string, "存在しないバトル(ID:%1$s)", true);
	mixin Property!("noSelectPackage", string, "(指定無し)", true);
	mixin Property!("noPackage", string, "存在しないパッケージ(ID:%1$s)", true);
	mixin Property!("noSelectCast", string, "(指定無し)", true);
	mixin Property!("noCast", string, "存在しないキャストカード(ID:%1$s)", true);
	mixin Property!("noSelectSkill", string, "(指定無し)", true);
	mixin Property!("noSkill", string, "存在しない特殊技能カード(ID:%1$s)", true);
	mixin Property!("noSelectItem", string, "(指定無し)", true);
	mixin Property!("noItem", string, "存在しないアイテムカード(ID:%1$s)", true);
	mixin Property!("noSelectBeast", string, "(指定無し)", true);
	mixin Property!("noBeast", string, "存在しない召喚獣カード(ID:%1$s)", true);
	mixin Property!("noSelectInfo", string, "(指定無し)", true);
	mixin Property!("noInfo", string, "存在しない情報カード(ID:%1$s)", true);
	mixin Property!("noSelectFlag", string, "(指定無し)", true);
	mixin Property!("noFlag", string, "存在しないフラグ(パス:%1$s)", true);
	mixin Property!("noSelectStep", string, "(指定無し)", true);
	mixin Property!("noStep", string, "存在しないステップ(パス:%1$s)", true);
	mixin Property!("noSelectStart", string, "(指定無し)", true);
	mixin Property!("noStart", string, "存在しないスタートコンテント(パス:%1$s)", true);
	mixin Property!("noSelectCoupon", string, "(指定無し)", true);
	mixin Property!("noSelectCompleteStamp", string, "(指定無し)", true);
	mixin Property!("noSelectGossip", string, "(指定無し)", true);

	mixin Property!("cardId", string, "ID", true);
	mixin Property!("cardName", string, "名称", true);
	mixin Property!("cardDesc", string, "説明", true);

	mixin Property!("dlgTitNewCast", string, "キャストカードの作成", true);
	mixin Property!("dlgTitNewSkill", string, "特殊技能カードの作成", true);
	mixin Property!("dlgTitNewItem", string, "アイテムカードの作成", true);
	mixin Property!("dlgTitNewBeast", string, "召喚獣カードの作成", true);
	mixin Property!("dlgTitNewInfo", string, "情報カードの作成", true);
	mixin Property!("dlgTitCast", string, "キャストカードの設定 [ %1$s ]", true);
	mixin Property!("dlgTitSkill", string, "特殊技能カードの設定 [ %1$s ]", true);
	mixin Property!("dlgTitItem", string, "アイテムカードの設定 [ %1$s ]", true);
	mixin Property!("dlgTitBeast", string, "召喚獣カードの設定 [ %1$s ]", true);
	mixin Property!("dlgTitInfo", string, "情報カードの設定 [ %1$s ]", true);

	mixin Property!("name", string, "名前", true);
	mixin Property!("nameLimit", string, "(%2$s文字まで)", true); // %1$s = 文字数、%2$s = 文字数 / 2
	mixin Property!("level", string, "レベル", true);
	mixin Property!("life", string, "体力", true);
	mixin Property!("lifeCalc", string, "標準値", true);
	mixin Property!("history", string, "経歴", true);
	mixin Property!("coupons", string, "経歴", true);
	mixin Property!("addCoupon", string, "新規クーポンの追加", true);
	mixin Property!("altCoupon", string, "クーポンの上書き", true);
	mixin Property!("delCoupon", string, "クーポンの削除", true);
	mixin Property!("sex", string, "性別", true);
	mixin Property!("period", string, "年代", true);
	mixin Property!("race", string, "種族", true);
	mixin Property!("noRace", string, "[未指定]", true);
	mixin Property!("nature", string, "素質", true);
	mixin Property!("makings", string, "特性", true);
	mixin Property!("tolerant", string, "対属性", true);
	mixin Property!("tolerantBase", string, "対カード属性", true);
	mixin Property!("tolerantElement", string, "対効果属性", true);
	mixin Property!("resistWeapon", string, "武器が効かない", true);
	mixin Property!("resistMagic", string, "魔法が効かない", true);
	mixin Property!("undead", string, "命を持たない", true);
	mixin Property!("automaton", string, "心を持たない", true);
	mixin Property!("unholy", string, "不浄な存在", true);
	mixin Property!("constructure", string, "魔法生物", true);
	mixin Property!("resistText", string, "%1$sに耐性を持つ", true);
	mixin Property!("weaknessText", string, "%1$sに弱い", true);
	mixin Property!("descResistWeapon", string, "(物理属性のカードが無効)", true);
	mixin Property!("descResistMagic", string, "(魔法属性のカードが無効)", true);
	mixin Property!("descUndead", string, "(肉体属性の効果が無効)", true);
	mixin Property!("descAutomaton", string, "(精神属性の効果が無効)", true);
	mixin Property!("descUnholy", string, "(神聖属性の効果に影響)", true);
	mixin Property!("descConstructure", string, "(魔力属性の効果に影響)", true);
	mixin Property!("descResist", string, "(%1$s属性の効果が無効)", true);
	mixin Property!("descWeakness", string, "(%1$s属性の効果に影響)", true);
	mixin Property!("basicResist", string, "標準値", true);
	mixin Property!("physicalParams", string, "身体能力", true);
	mixin Property!("physicalCalc", string, "標準値", true);
	mixin Property!("mentalParams", string, "精神傾向", true);
	mixin Property!("mentalCalc", string, "標準値", true);
	mixin Property!("castEnhance", string, "能力修正", true);
	mixin Property!("basicEnhance", string, "標準値", true);

	mixin Property!("liveStatus", string, "初期状態", true);
	mixin Property!("lifeAndMentality", string, "体力と精神状態", true);
	mixin Property!("enhanceLiveBonus", string, "能力ボーナス/ペナルティ", true);
	mixin(EnumToStringMethod!(Enhance, "enhanceLiveBonusName", "enhanceLiveBonusName"));
	mixin Property!("enhanceLiveBonusNameAction", string, "行動", true);
	mixin Property!("enhanceLiveBonusNameAvoid", string, "回避", true);
	mixin Property!("enhanceLiveBonusNameResist", string, "抵抗", true);
	mixin Property!("enhanceLiveBonusNameDefense", string, "防御", true);
	mixin Property!("useMax", string, "最大値を使用", true);
	mixin Property!("status", string, "異常状態", true);
	mixin Property!("paralyze", string, "麻痺/石化", true);
	mixin Property!("poison", string, "中毒", true);
	mixin Property!("bind", string, "呪縛", true);
	mixin Property!("silence", string, "沈黙", true);
	mixin Property!("faceUp", string, "暴露", true);
	mixin Property!("antiMagic", string, "魔法無効", true);
	mixin Property!("unitValue", string, "点", true);
	mixin Property!("unitRound", string, "ラウンド", true);
	mixin Property!("resetLiveStatus", string, "通常状態に戻す", true);

	mixin Property!("needSpellGroup", string, "発声による発動", true);
	mixin Property!("needSpell", string, "沈黙時に使用不可", true);
	mixin Property!("elementProps", string, "効果属性", true);
	mixin Property!("resistProps", string, "抵抗属性", true);
	mixin Property!("aptPhysical", string, "身体的要素", true);
	mixin Property!("aptMental", string, "精神的要素", true);
	mixin Property!("skillLevel", string, "技能レベル", true);
	mixin Property!("useCountGroup", string, "使用可能回数", true);
	mixin Property!("useCountRange", string, "(0～%1$s : 0 = ∞)", true);
	mixin Property!("price", string, "価格", true);
	mixin Property!("priceAuto", string, "(参考用)", true);
	mixin Property!("useModify", string, "使用時 能力値修正", true);
	mixin Property!("haveModify", string, "所有時 能力値修正", true);
	mixin Property!("motionKind", string, "効果種別", true);
	mixin Property!("motionElement", string, "属性", true);
	mixin Property!("motionDamageType", string, "タイプ", true);
	mixin Property!("motionValue", string, "値", true);
	mixin Property!("motionBeast", string, "召喚するカード", true);
	mixin Property!("beastNone", string, "[召喚獣無し]", true);
	mixin Property!("setBeast", string, "選択", true);
	mixin Property!("motionRound", string, "継続時間 (ラウンド数)", true);
	mixin Property!("motionEnhValue", string, "変化値", true);
	mixin Property!("effectTarget", string, "効果目標", true);
	mixin Property!("effectRange", string, "効果範囲", true);
	mixin Property!("effectVisual", string, "視覚効果", true);
	mixin Property!("cardPremium", string, "カードの価値", true);
	mixin Property!("successRate", string, "成功率修正値", true);
	mixin Property!("allFail", string, "絶対失敗\n(-5)", true);
	mixin Property!("allSuccess", string, "絶対成功\n(+5)", true);
	mixin Property!("se", string, "効果音", true);
	mixin Property!("se1", string, "初期効果", true);
	mixin Property!("se2", string, "二次効果", true);
	mixin Property!("soundNone", string, "[効果音無し]", true);
	mixin Property!("keyCodes", string, "イベント発火のキーコード", true);

	mixin Property!("warningEffectTypeNone", string, "無属性のカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。", true);
	mixin Property!("warningVanishCast", string, "神聖属性以外の対象消去効果を持つカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。", true);
	mixin Property!("warningNameLenOver", string, "名前の長さが%2$s文字を超えています。メッセージにカード名が表示された際に不具合が発生する可能性があります。", true); // %1$s = 文字数、%2$s = 文字数 / 2

	mixin Property!("card", string, "カード", true);
	mixin Property!("apt", string, "要素", true);
	mixin Property!("useCountAndDesc", string, "使用回数/解説", true);
	mixin Property!("levelAndDesc", string, "レベル/解説", true);
	mixin Property!("useBonus", string, "使用ボーナス", true);
	mixin Property!("haveBonus", string, "所持ボーナス", true);
	mixin Property!("motion", string, "効果", true);
	mixin Property!("cardProps", string, "属性", true);
	mixin Property!("settings", string, "設定", true);
	mixin Property!("seAndKeyCode", string, "効果音/キーコード", true);

	mixin Property!("rangeHint", string, "(%1$s～%2$s)", true);
	mixin Property!("source", string, "出典", true);
	mixin Property!("sourceScenario", string, "シナリオ名", true);
	mixin Property!("sourceAuthor", string, "シナリオ作者", true);
	mixin Property!("resetSource", string, "現在のシナリオを出典に設定", true);
	mixin Property!("diffSource", string, "出典のシナリオ名と作者名が現在のシナリオと異なるため、使用時イベントは実行されません。", true);

	/// ファイルビュー。
	mixin Property!("dirTabName", string, "ファイル", true);
	mixin Property!("dirWindowName", string, "ファイル - [ %1$s ] - %2$s", true);
	mixin Property!("dirStatus", string, "%1$s個のファイル (%2$s)", true);
	mixin Property!("dirStatusSel", string, "%1$s個のファイル (%2$s) (%3$s個を選択中)", true);
	mixin Property!("fileName", string, "ファイル名", true);
	mixin Property!("fileExt", string, "拡張子", true);
	mixin Property!("fileCount", string, "使用数", true);
	mixin Property!("errorExec", string, "%1$sの起動に失敗しました。", true);
	mixin Property!("filterDescZip", string, "ZIP アーカイブ (*.zip)", true);
	mixin Property!("filterDescCab", string, "CAB アーカイブ (*.cab)", true);
	mixin Property!("filterDescWsn", string, "シナリオファイル (*.wsn)", true);
	mixin Property!("dlgTitCreateArchive", string, "シナリオの圧縮", true);
	mixin Property!("failedCreateArchive", string, "シナリオの圧縮に失敗", true);
	mixin Property!("dlgMsgIsSaveBeforeCreateArchive", string, "「%1$s」は変更されています。保存しますか？", true);

	/// エディタ設定ダイアログ。
	mixin Property!("baseSettings", string, "基本設定", true);
	mixin Property!("reference", string, "...", true);
	mixin Property!("enginePath", string, "%1$sの場所", true);
	mixin Property!("enginePathAtten", string, "※ クラシックなシナリオのみに使用する場合は空欄にしてください", true);
	mixin Property!("dlgTitEnginePath", string, "%1$sの場所", true);
	mixin Property!("tempDir", string, "シナリオの一時展開先", true);
	mixin Property!("tempDirDesc", string, "wsn圧縮されたシナリオの一時的な展開先を選択してください。", true);
	mixin Property!("backupDir", string, "自動バックアップ", true);
	mixin Property!("backupEnabled", string, "自動バックアップを行う", true);
	mixin Property!("backupPath", string, "保存先", true);
	mixin Property!("backupDirDesc", string, "シナリオを定期的に自動バックアップする" ~ DIR ~ "を選択してください。", true);
	mixin Property!("backupInterval", string, "保存間隔", true);
	mixin Property!("minute", string, "分", true);
	mixin Property!("backupCount", string, "最大保存数", true);
	mixin Property!("skin", string, "スキン", true);
	mixin Property!("scenarioAuthor", string, "シナリオ作者(新規作成時に自動設定されます)", true);
	mixin Property!("historiesSettings", string, "履歴", true);
	mixin Property!("openHistoryMax", string, "シナリオ履歴保存件数", true);
	mixin Property!("openHistoryClear", string, "クリア", true);
	mixin Property!("dlgMsgHistoryClear", string, "シナリオ履歴を削除してよろしいですか？", true);
	mixin Property!("searchHistoryMax", string, "検索/置換履歴保存件数", true);
	mixin Property!("searchHistoryClear", string, "クリア", true);
	mixin Property!("dlgMsgSearchHistoryClear", string, "検索/置換履歴を削除してよろしいですか？", true);
	mixin Property!("ignorePaths", string, "無視ファイル(改行区切り)", true);
	mixin Property!("etcSettings", string, "その他", true);

	mixin Property!("etcSettingsTitle", string, "詳細", true);

	mixin Property!("languageSetting", string, "言語", true);
	mixin Property!("languageSystem", string, "[システムの言語]", true);
	mixin Property!("languageCaution", string, "※ 次回起動時から適用されます", true);

	mixin Property!("singleWindow", string, "シングルウィンドウモード(再起動後に反映されます)", true);
	mixin Property!("smoothingCard", string, "カードのサイズ変更時にスムージングを行う", true);
	mixin Property!("showImagePreview", string, "カードや背景のプレビュー表示を行う", true);
	mixin Property!("expandXMLs", string, "圧縮されたシナリオの読込み時にXMLファイルを展開する", true);
	mixin Property!("contentsFloat", string, "コンテンツボックスを別ウィンドウで表示する", true);
	mixin Property!("contentsAutoHide", string, "コンテンツボックスを自動的に隠す", true);
	mixin Property!("xmlCopy", string, "コピーや切り取りを常にXML形式で行う", true);
	mixin Property!("saveInnerImagePath", string, "クラシックなシナリオで格納イメージのファイルパスを保存する", true);
	mixin Property!("traceDirectories", string, "ファイル・" ~ DIR ~ "の変更を自動的に追跡する", true);
	mixin Property!("logicalSort", string, "数値参照型ソートを行う(1, 10, 2, 3, ... → 1, 2, 3, 10, ...)", true);
	mixin Property!("copyDesc", string, "カードをエリアに貼り付け・ドロップした時、解説もコピーする", true);
	mixin Property!("refCardsAtEditBgImage", string, "背景変更コンテントの編集を開始する際、最初からカード配置の参照を行う", true);
	mixin Property!("floatMessagePreview", string, "台詞・メッセージのプレビューをフロートさせる", true);
	mixin Property!("addNewClassicEngine", string, "未知のクラシックエンジンを見つけたら記憶する", true);
	mixin Property!("doubleIO", string, "分割読込・保存を行う(デュアルコア以上の環境で高速化)", true);
	mixin Property!("switchTabWheel", string, "マウスホイールでタブ切替を行う", true);
	mixin Property!("openTabAtRightOfCurrentTab", string, "新しいタブを現在のタブの直後に開く", true);
	mixin Property!("reconstruction", string, "シナリオごとにタブの配置を記憶する", true);
	mixin Property!("openLastScenario", string, "終了時に開いていたシナリオを次の起動時に開く", true);
	mixin Property!("soundPlayType", string, "BGM再生方式", true);
	mixin Property!("soundPlayTypeDef", string, "自動選択", true);
	mixin Property!("soundPlayTypeSDL", string, "SDL(CardWirthPy方式)", true);
	mixin Property!("soundPlayTypeMCI", string, "WinMM(CardWirth方式)", true);
	mixin Property!("soundPlayTypeApp", string, "関連付けされたアプリケーションで開く", true);
	mixin Property!("soundEffectPlayType", string, "効果音再生方式", true);
	mixin Property!("soundPlaySameBGM", string, "BGMに合わせる", true);
	mixin Property!("soundVolume", string, "音量", true);
	mixin Property!("soundVolumePer", string, "%", true);
	mixin Property!("soundCaution", string, "※ WinMM方式の時、音量は反映されません", true);

	mixin Property!("keyBind", string, "キーバインド", true);
	mixin Property!("mnemonic", string, "アクセスキー", true);
	mixin Property!("hotkey", string, "ショートカット", true);

	mixin Property!("wallpaper", string, "エディタの壁紙", true);
	mixin Property!("filterWallpaper", string, "画像ファイル (*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.ico;*.icon)", true);
	mixin Property!("dlgTitWallpaper", string, "壁紙画像の選択", true);
	mixin Property!("wallpaperStyle", string, "表示形式", true);
	mixin(EnumToStringMethod!(WallpaperStyle, "wallpaperStyleName", "wallpaperStyleName"));
	mixin Property!("wallpaperStyleNameCenter", string, "中央に表示", true);
	mixin Property!("wallpaperStyleNameTile", string, "並べて表示", true);
	mixin Property!("wallpaperStyleNameExpandFull", string, "拡大して表示", true);
	mixin Property!("wallpaperStyleNameExpand", string, "はみ出さないように拡大", true);

	mixin Property!("bgImageAndKeyCode", string, "背景とキーコード", true);
	mixin Property!("standardKeyCode", string, "標準のキーコード", true);

	mixin Property!("errorEnginePath", string, "%1$sの場所が正しくありません。", true);
	mixin Property!("errorTempPath", string, "一時展開先が正しくありません。", true);
	mixin Property!("errorBackupPath", string, "自動バックアップ先が正しくありません。", true);

	mixin Property!("sNew", string, "新規作成", true);
	mixin Property!("sAlt", string, "上書き", true);
	mixin Property!("sDel", string, "削除", true);

	mixin Property!("outerToolsAndClassicEngines", string, "外部ツールとクラシックエンジン", true);
	mixin Property!("outerToolsTitle", string, "外部ツールの設定", true);
	mixin Property!("outerToolName", string, "外部ツール名", true);
	mixin Property!("outerToolCommand", string, "コマンド", true);
	mixin Property!("dlgTitOuterTool", string, "外部ツールの選択", true);
	mixin Property!("toolsHint1", string, "$F = ファイル名", true);
	mixin Property!("toolsHint3", string, "$$ = $", true);
	mixin Property!("outerToolWorkDir", string, "作業" ~ DIR);
	mixin Property!("toolWorkDir", string, "作業" ~ DIR ~ "の選択", true);
	mixin Property!("toolWorkDirDesc", string, "外部ツールの作業" ~ DIR ~ "を選択してください。", true);
	mixin Property!("toolsHint2", string, "$S = シナリオの" ~ DIR);

	mixin Property!("templates", string, "テンプレート", true);
	mixin Property!("eventTemplatesTitle", string, "イベントテンプレートの設定", true);
	mixin Property!("eventTemplateName", string, "テンプレート名", true);
	mixin Property!("eventTemplateScript", string, "スクリプト", true);

	mixin Property!("scenarioTemplatesTitle", string, "シナリオテンプレートの設定", true);
	mixin Property!("scenarioTemplateName", string, "テンプレート名", true);
	mixin Property!("scenarioTemplatePath", string, "シナリオの場所", true);
	mixin Property!("dlgTitScTemplate", string, "テンプレートシナリオの選択", true);

	mixin Property!("exeFileDescExe", string, "実行ファイル (*.exe)", true);
	mixin Property!("exeFileDescAll", string, "すべてのファイル (*.*)", true);

	mixin Property!("classicEnginesTitle", string, "クラシックエンジンの設定", true);
	mixin Property!("classicEngineName", string, "エンジン名", true);
	mixin Property!("classicEnginePath", string, "実行ファイルパス", true);
	mixin Property!("classicEngineDataDirName", string, "データフォルダ", true);
	mixin Property!("classicEngineDataDirNameDesc", string, "クラシックエンジンのデータフォルダを選択してください。", true);
	mixin Property!("classicEngineExecute", string, "代替実行ファイル", true);
	mixin Property!("classicEngineHint1", string, "※ 代替実行ファイルを指定すると、エンジン本体の代わりに実行されます", true);
	mixin Property!("dlgTitClassicEnginePath", string, "クラシックエンジンの選択", true);
	mixin Property!("dlgTitClassicEngineExecute", string, "代替実行ファイルの選択", true);

	mixin Property!("bgImagesDefault", string, "デフォルト背景", true);
	mixin Property!("setBgImagesDefault", string, "デフォルト背景の設定...", true);
	mixin Property!("dlgTitBgImagesDefault", string, "デフォルト背景の設定", true);

	mixin Property!("systemSounds", string, "システム音声", true);
	mixin Property!("soundSaved", string, "保存完了", true);
	mixin Property!("playableSounds", string, "サウンドファイル (%1$s)", true);
	mixin Property!("dlgTitSystemSound", string, "システム音声の選択", true);

	mixin Property!("undoMax", string, "「元に戻す」回数", true);
	mixin Property!("undoMaxMainView", string, "エリア/カード/フラグ", true);
	mixin Property!("undoMaxEvent", string, "メニュー/エネミー/背景/イベント", true);
	mixin Property!("undoMaxReplace", string, "置換", true);
	mixin Property!("undoMaxEtc", string, "テキスト/その他", true);

	mixin Property!("dialogStatus", string, "台詞コンテントのステータス", true);
	mixin(EnumToStringMethod!(DialogStatus, "dialogStatusName", "dialogStatusName"));
	mixin Property!("dialogStatusNameTop", string, "最上位の台詞", true);
	mixin Property!("dialogStatusNameUnder", string, "最下位の台詞", true);
	mixin Property!("dialogStatusNameUnderWithCoupon", string, "最下位の台詞(条件クーポン設定あり)", true);

	/// スクリプト関係。
	mixin Property!("dlgTitScriptError", string, "CWXスクリプトエラー", true);
	mixin Property!("scriptError", string, "CWXスクリプトのコンパイル中にエラーが発生しました。", true);
	mixin Property!("scriptErrorOver100Error", string, "エラーが100件を超えたため、スクリプトの解析を終了します。", true);
	mixin Property!("scriptErrorInvalidToken", string, "スクリプトに使用できない文字が含まれています。", true);
	mixin Property!("scriptErrorInvalidSyntax", string, "構文が正しくありません。", true);
	mixin Property!("scriptErrorInvalidString", string, "ここに文字列が必要です。", true);
	mixin Property!("scriptErrorUnCloseString", string, "文字列が閉じられていません。", true);
	mixin Property!("scriptErrorUnOpenComment", string, "コメントは開始されていません。", true);
	mixin Property!("scriptErrorUnCloseComment", string, "コメントが閉じられていません。", true);
	mixin Property!("scriptErrorInvalidNumber", string, "数値が正しくありません。", true);
	mixin Property!("scriptErrorCloseBracketNotFound", string, "閉じ括弧が見つかりません。", true);
	mixin Property!("scriptErrorCloseParenNotFound", string, "閉じ括弧が見つかりません。", true);
	mixin Property!("scriptErrorZeroDivision", string, "0で除算を行いました。", true);
	mixin Property!("scriptErrorInvalidAttr", string, "属性が正しくありません。", true);
	mixin Property!("scriptErrorInvalidVar", string, "変数が正しくありません。", true);
	mixin Property!("scriptErrorInvalidVarVal", string, "変数の値が正しくありません。", true);
	mixin Property!("scriptErrorNoStartText", string, "スタートコンテントの名前がありません。", true);
	mixin Property!("scriptErrorInvalidStatement", string, "文が正しくありません。", true);
	mixin Property!("scriptErrorInvalidBranch", string, "分岐の構成が正しくありません。", true);
	mixin Property!("scriptErrorNoIfText", string, "ifの条件が見つかりません。", true);
	mixin Property!("scriptErrorNoIfContents", string, "分岐先のコンテントが見つかりません。", true);
	mixin Property!("scriptErrorInvalidKeyword", string, "未知のキーワードです。", true);
	mixin Property!("scriptErrorInvalidValuesOpen", string, "パラメータ列ではありません。", true);
	mixin Property!("scriptErrorInvalidValuesClose", string, "閉じ括弧が見つかりません。", true);
	mixin Property!("scriptErrorNoVarSet", string, "変数に値をセットしていません。", true);
	mixin Property!("scriptErrorNoVarVal", string, "変数の値がありません。", true);
	mixin Property!("scriptErrorInvalidCalc", string, "計算式が不正です。", true);
	mixin Property!("scriptErrorInvalidBoolVal", string, "キーワードが正しくありません。", true);
	mixin Property!("scriptErrorInvalidTransition", string, "未知の画面切替方式です。", true);
	mixin Property!("scriptErrorInvalidRange", string, "未知の範囲です。", true);
	mixin Property!("scriptErrorInvalidStatus", string, "未知のステータスです。", true);
	mixin Property!("scriptErrorInvalidTarget", string, "未知のターゲットです。", true);
	mixin Property!("scriptErrorInvalidEffectType", string, "未知の効果属性です。", true);
	mixin Property!("scriptErrorInvalidResist", string, "未知の命中属性です。", true);
	mixin Property!("scriptErrorInvalidCardVisual", string, "未知の視覚効果です。", true);
	mixin Property!("scriptErrorInvalidMental", string, "未知の精神要素です。", true);
	mixin Property!("scriptErrorInvalidPhysical", string, "未知の肉体要素です。", true);
	mixin Property!("scriptErrorInvalidMotionType", string, "未知の効果タイプです。", true);
	mixin Property!("scriptErrorInvalidMotion", string, "効果が正しくありません。", true);
	mixin Property!("scriptErrorInvalidElement", string, "未知の属性です。", true);
	mixin Property!("scriptErrorInvalidDamageType", string, "未知のダメージタイプです。", true);
	mixin Property!("scriptErrorInvalidBgImage", string, "背景画像が正しくありません。", true);
	mixin Property!("scriptErrorInvalidDialog", string, "台詞が正しくありません。", true);
	mixin Property!("scriptErrorInvalidTalker", string, "話者が正しくありません。", true);
	mixin Property!("scriptErrorUndefinedSymbol", string, "未知のシンボルです。", true);
	mixin Property!("scriptErrorInvalidSif", string, "ここにsifが現れる事はできません。", true);
	mixin Property!("scriptErrorNoSifText", string, "sifのテキストが見つかりません。", true);
	mixin Property!("scriptErrorInvalidCommand", string, "命令が正しくありません。", true);
	mixin Property!("scriptErrorCanNotHaveContent", string, "このコンテントが後続コンテントを持つ事はできません。", true);
	mixin Property!("scriptErrorInvalidStr", string, "文字列が正しくありません。", true);
	mixin Property!("scriptErrorReqNumber", string, "ここに数値が必要です。", true);
	mixin Property!("scriptErrorReqID", string, "ここにIDが必要です。", true);
	mixin Property!("scriptErrorUndefinedVar", string, "存在しない変数です。", true);
	mixin Property!("scriptErrorInvalidValue", string, "値が正しくありません。", true);
	mixin Property!("scriptErrorSystem", string, "サイズが大きすぎるため、CWXスクリプトをコンパイルできません。", true);

	/// メニュー。
	mixin(EnumToStringMethod!(MenuID, "menuText", "menuText"));

	mixin Property!("menuTextNone", string, "", true);

	mixin Property!("menuTextFile", string, "ファイル", true);
	mixin Property!("menuTextEdit", string, "編集", true);
	mixin Property!("menuTextView", string, "表示", true);
	mixin Property!("menuTextTool", string, "ツール", true);
	mixin Property!("menuTextTable", string, "テーブル", true);
	mixin Property!("menuTextVariable", string, "状態変数", true);
	mixin Property!("menuTextHelp", string, "ヘルプ", true);
	mixin Property!("menuTextCard", string, "カード", true);
	mixin Property!("menuTextCardsAndBacks", string, "カードと背景", true);

	mixin Property!("menuTextDelNotUsedFile", string, "未使用のファイルを削除", true);
	mixin Property!("menuTextClosePane", string, "閉じる", true);
	mixin Property!("menuTextClosePaneExcept", string, "他のタブを閉じる", true);
	mixin Property!("menuTextClosePaneLeft", string, "左側のタブを閉じる", true);
	mixin Property!("menuTextClosePaneRight", string, "右側のタブを閉じる", true);
	mixin Property!("menuTextClosePaneAll", string, "全てのタブを閉じる", true);
	mixin Property!("menuTextNew", string, "新規作成", true);
	mixin Property!("menuTextOpen", string, "開く", true);
	mixin Property!("menuTextNewAtNewWindow", string, "新しいウィンドウで新規作成", true);
	mixin Property!("menuTextOpenAtNewWindow", string, "新しいウィンドウで開く", true);
	mixin Property!("menuTextClose", string, "閉じる", true);
	mixin Property!("menuTextCloseWin", string, "閉じる", true);
	mixin Property!("menuTextSave", string, "上書き保存", true);
	mixin Property!("menuTextSaveAs", string, "名前を付けて保存", true);
	mixin Property!("menuTextReload", string, "再読込", true);
	mixin Property!("menuTextOpenDir", string, DIR ~ "を開く", true);
	mixin Property!("menuTextOpenPlace", string, "ファイルの場所を開く", true);
	mixin Property!("menuTextSaveImage", string, "格納イメージをファイルに保存", true);
	mixin Property!("menuTextLookImages", string, "画像を一覧表示", true);
	mixin Property!("menuTextShowMainToolBar", string, "全体ツールバーを表示", true);
	mixin Property!("menuTextShowSceneToolBar", string, "シーンビューのツールバーを表示", true);
	mixin Property!("menuTextShowEventToolBar", string, "イベントビューのツールバーを表示", true);
	mixin Property!("menuTextChangeVH", string, "分割領域の縦横を切替", true);
	mixin Property!("menuTextFind", string, "検索と置換", true);
	mixin Property!("menuTextIncSearch", string, "絞り込み検索", true);
	mixin Property!("menuTextCloseIncSearch", string, "閉じる", true);
	mixin Property!("menuTextEditProp", string, "編集", true);
	mixin Property!("menuTextRefresh", string, "最新の情報に更新", true);
	mixin Property!("menuTextUndo", string, "元に戻す", true);
	mixin Property!("menuTextRedo", string, "やり直し", true);
	mixin Property!("menuTextCut", string, "切り取り", true);
	mixin Property!("menuTextCopy", string, "コピー", true);
	mixin Property!("menuTextPaste", string, "貼り付け", true);
	mixin Property!("menuTextDelete", string, "削除", true);
	mixin Property!("menuTextSelectAll", string, "すべて選択", true);
	mixin Property!("menuTextToXMLText", string, "コピーしたデータをXMLに変換", true);
	mixin Property!("menuTextTableView", string, "テーブルビュー", true);
	mixin Property!("menuTextVarView", string, "状態変数ビュー", true);
	mixin Property!("menuTextCardView", string, "カードビュー", true);
	mixin Property!("menuTextCastView", string, "キャストカードビュー", true);
	mixin Property!("menuTextSkillView", string, "特殊技能カードビュー", true);
	mixin Property!("menuTextItemView", string, "アイテムカードビュー", true);
	mixin Property!("menuTextBeastView", string, "召喚獣カードビュー", true);
	mixin Property!("menuTextInfoView", string, "情報カードビュー", true);
	mixin Property!("menuTextFileView", string, "ファイルビュー", true);
	mixin Property!("menuTextExecEngine", string, "エンジン起動", true);
	mixin Property!("menuTextExecEngineAuto", string, "自動選択", true);
	mixin Property!("menuTextExecEngineMain", string, "CardWirthPy", true);
	mixin Property!("menuTextOuterTools", string, "外部ツール", true);
	mixin Property!("menuTextSettings", string, "エディタ設定", true);
	mixin Property!("menuTextVersionInfo", string, "バージョン情報", true);
	mixin Property!("menuTextLockToolBar", string, "ツールバーを固定", true);
	mixin Property!("menuTextResetToolBar", string, "配置をリセット", true);
	mixin Property!("menuTextCopyAsText", string, "テキストとしてコピー", true);
	mixin Property!("menuTextOpenAtView", string, "ビューで開く", true);
	mixin Property!("menuTextStartToPackage", string, "このツリーをパッケージ化する", true);
	mixin Property!("menuTextConvertContent", string, "変換", true);
	mixin Property!("menuTextCGroupTerminal", string, "開始/終端", true);
	mixin Property!("menuTextCGroupStandard", string, "基本", true);
	mixin Property!("menuTextCGroupData", string, "変数操作/分岐", true);
	mixin Property!("menuTextCGroupUtility", string, "状況分岐", true);
	mixin Property!("menuTextCGroupBranch", string, "保有分岐", true);
	mixin Property!("menuTextCGroupGet", string, "取得", true);
	mixin Property!("menuTextCGroupLost", string, "喪失", true);
	mixin Property!("menuTextCGroupVisual", string, "外観操作", true);
	mixin Property!("menuTextEditSummary", string, "シナリオの設定", true);
	mixin Property!("menuTextNewArea", string, "エリアの作成", true);
	mixin Property!("menuTextNewBattle", string, "バトルの作成", true);
	mixin Property!("menuTextNewPackage", string, "パッケージの作成", true);
	mixin Property!("menuTextReNumberingAll", string, "全てのIDを1から振り直す", true);
	mixin Property!("menuTextReNumbering", string, "IDの振り直し", true);
	mixin Property!("menuTextEditScene", string, "シーンビューを開く", true);
	mixin Property!("menuTextEditEvent", string, "イベントビューを開く", true);
	mixin Property!("menuTextNewFlagDir", string, "フォルダの作成", true);
	mixin Property!("menuTextNewFlag", string, "フラグの作成", true);
	mixin Property!("menuTextNewStep", string, "ステップの作成", true);
	mixin Property!("menuTextUp", string, "上へ", true);
	mixin Property!("menuTextDown", string, "下へ", true);
	mixin Property!("menuTextShowParty", string, "パーティカードの表示", true);
	mixin Property!("menuTextShowMsg", string, "メッセージ枠の表示", true);
	mixin Property!("menuTextShowRefCards", string, "カード参照の表示", true);
	mixin Property!("menuTextFixedImage", string, "イメージの固定", true);
	mixin Property!("menuTextShowEnemyCardProp", string, "レベルとライフを表示", true);
	mixin Property!("menuTextShowCard", string, "カードの表示", true);
	mixin Property!("menuTextShowBack", string, "背景の表示", true);
	mixin Property!("menuTextNewMenuCard", string, "メニューカードの作成", true);
	mixin Property!("menuTextNewEnemyCard", string, "エネミーカードの作成", true);
	mixin Property!("menuTextNewBack", string, "背景の作成", true);
	mixin Property!("menuTextAutoArrange", string, "カードを自動的に並べる", true);
	mixin Property!("menuTextManualArrange", string, "カードの位置を自分で決定する", true);
	mixin Property!("menuTextMask", string, "透明色を使用", true);
	mixin Property!("menuTextEscape", string, "逃走の有無", true);
	mixin Property!("menuTextPosTop", string, "上に揃える", true);
	mixin Property!("menuTextPosBottom", string, "下に揃える", true);
	mixin Property!("menuTextPosLeft", string, "左に揃える", true);
	mixin Property!("menuTextPosRight", string, "右に揃える", true);
	mixin Property!("menuTextPosEven", string, "等間隔に並べる", true);
	mixin Property!("menuTextScaleMin", string, "最小のカードスケール", true);
	mixin Property!("menuTextScaleMiddle", string, "標準のカードスケール", true);
	mixin Property!("menuTextScaleMax", string, "最大のカードスケール", true);
	mixin Property!("menuTextScaleBig", string, "大きく揃える", true);
	mixin Property!("menuTextScaleSmall", string, "小さく揃える", true);
	mixin Property!("menuTextStopBGM", string, "%1$sの再生を停止", true);
	mixin Property!("menuTextPlayBGM", string, "再生", true);
	mixin Property!("menuTextKeyCodeTiming", string, "キーコード発火タイミング", true);
	mixin Property!("menuTextKeyCodeTimingUse", string, "使用", true);
	mixin Property!("menuTextKeyCodeTimingSuccess", string, "成功", true);
	mixin Property!("menuTextKeyCodeTimingFailure", string, "失敗", true);
	mixin Property!("menuTextAddRangeOfRound", string, "複数のラウンドを追加", true);
	mixin Property!("menuTextOpenAtTableView", string, "テーブルビューで開く", true);
	mixin Property!("menuTextOpenAtVarView", string, "状態変数ビューで開く", true);
	mixin Property!("menuTextOpenAtCardView", string, "カードビューで開く", true);
	mixin Property!("menuTextOpenAtFileView", string, "ファイルビューで開く", true);
	mixin Property!("menuTextOpenAtEventView", string, "イベントビューで開く", true);
	mixin Property!("menuTextComment", string, "コメントを記述", true);
	mixin Property!("menuTextShowCardProp", string, "レベルとライフを表示", true);
	mixin Property!("menuTextShowCardImage", string, "カード表示", true);
	mixin Property!("menuTextShowCardDetail", string, "詳細表示", true);
	mixin Property!("menuTextOpenImportSource", string, "外部シナリオから追加", true);
	mixin Property!("menuTextNewCast", string, "キャストカードの作成", true);
	mixin Property!("menuTextNewSkill", string, "スキルカードの作成", true);
	mixin Property!("menuTextNewItem", string, "アイテムカードの作成", true);
	mixin Property!("menuTextNewBeast", string, "召喚獣カードの作成", true);
	mixin Property!("menuTextNewInfo", string, "情報カードの作成", true);
	mixin Property!("menuTextImport", string, "シナリオに追加", true);
	mixin Property!("menuTextOpenHand", string, "所有カード", true);
	mixin Property!("menuTextEditEventAtTimeOfUsing", string, "使用時イベントの設定", true);
	mixin Property!("menuTextPlaySE", string, "再生", true);
	mixin Property!("menuTextStopSE", string, "停止", true);
	mixin Property!("menuTextNewDir", string, "新規" ~ DIR);
	mixin Property!("menuTextCopyFilePath", string, "素材のパスをコピー", true);
	mixin Property!("menuTextReplFilePath", string, "素材の差替え", true);
	mixin Property!("menuTextCreateArchive", string, "シナリオを圧縮", true);
	mixin Property!("menuTextToScript", string, "スクリプトに変換してコピー", true);
	mixin Property!("menuTextToScriptAll", string, "全てをスクリプトに変換してコピー", true);
	mixin Property!("menuTextEvTemplates", string, "テンプレートから作成", true);

	mixin Property!("bgm", string, "BGM", true);
	mixin Property!("newEvent", string, "イベントの作成", true);
	mixin Property!("newIgnition", string, "イベント発火条件の作成", true);
	mixin Property!("expandTree", string, "全コンテントツリーを開く", true);
	mixin Property!("foldTree", string, "全コンテントツリーを閉じる", true);

	mixin XMLFuncs!(typeof(this), "message");
}
