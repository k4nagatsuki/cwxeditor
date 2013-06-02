
module cwx.msgs;

import cwx.types;
import cwx.features;
import cwx.structs;
import cwx.settings;
import cwx.versioninfo;
import cwx.utils;

version (Windows) {
	private immutable CARD_WIRTH_PY_EXE = "CardWirthPy.exe";
	private immutable CWX_EDITOR_EXE = "cwxeditor.exe";
	private immutable DIR = "フォルダ";
} else {
	private immutable CARD_WIRTH_PY_EXE = "CardWirthPy";
	private immutable CWX_EDITOR_EXE = "cwxeditor";
	private immutable DIR = "ディレクトリ";
}

private alias Prop!string Msg;
private alias AAProp!(string, string) AAMsg;

class Msgs : Properties {
	auto locale = PropAttr!string("locale", "ja-JP");
	auto version_ = PropAttr!ulong("version", APP_VERSION_NUM);

	auto application = Msg("application", "CWXEditor");
	auto localeName = Msg("localeName", "日本語");
	auto dlgTitVersion = Msg("dlgTitVersion", "バージョン情報");
	auto appDesc = Msg("appDesc", "CardWirthPy / CardWirth向けシナリオエディタ");

	auto dlgTitUsage = Msg("dlgTitUsage", "使い方 - CWXEditor");
	auto usage = Msg("usage", "使い方: cwxeditor [-help | -putlangfile <PATH> | -conf <PATH>\n"
		"                   | -create <NAME> [<SKIN>] | -createclassic <NAME> [<PATH>]\n"
		"                   | -selectfile <PATH> | -noload] <SCENARIO> [<CWXPath ...>]\n"
		"オプション:\n"
		"  -help         起動オプションの説明を表示して終了します。\n"
		"  -putlangfile <PATH> デフォルトの言語設定ファイル<PAHT>を出力して終了します。\n"
		"  -conf <PATH>  指定されたパスの基本設定ファイルを使用します。\n"
		"  -create        <NAME> [<SKIN>]  起動後にシナリオを新規作成します。\n"
		"  -createclassic <NAME> [<PATH>]  起動後、<PATH>で指定されたフォルダに\n"
		"                                  クラシックなシナリオを新規作成します。\n"
		"  -selectfile  <PATH> 指定されたファイルをファイルビューで選択します。\n"
		"  -noload       起動後、前回終了時の編集状態を復元しません。\n"
		"  <SCENARIO>    起動と同時に指定されたシナリオを開きます。\n"
		"                (*.wsn/Summary.xml/Summary.wsm/[フォルダ])\n"
		"OpenID:\n"
		"  -a <ID>       シナリオを開いた後、<ID>で指定したIDのエリアを開きます。\n"
		"  -b <ID>       シナリオを開いた後、<ID>で指定したIDのバトルを開きます。\n"
		"  -p <ID>       シナリオを開いた後、<ID>で指定したIDのパッケージを開きます。\n"
		"CWXPath:\n"
		"  <CWXPath>     シナリオを開いた後、<CWXPath>で指定したリソースを開きます。");

	auto dlgTitError = Msg("dlgTitError", "エラー - CWXEditor");
	auto dlgTitWarning = Msg("dlgTitWarning", "警告 - CWXEditor");
	auto dlgTitQuestion = Msg("dlgTitQuestion", "確認 - CWXEditor");
	auto unknownError = Msg("unknownError", "処理の途中でCWXEditorの制作者が意図していないエラーが発生しました。"
		"データが壊れている可能性を考慮して、シナリオを保存せずに終了する事をお勧めします。\n"
		"エラーの内容は%1$sに記録されます。");
	auto shutdown = Msg("shutdown", "強制終了");

	auto targetVersion = Msg("targetVersion", "対象エンジン");
	auto cardWirthPy = Msg("cardWirthPy", "CardWirthPy");
	auto cardWirthWithVersion = Msg("cardWirthWithVersion", "CardWirth %1$s");

	auto dlgTextOK = Msg("dlgTextOK", "&OK");
	auto dlgTextApply = Msg("dlgTextApply", "適用");
	auto dlgTextCancel = Msg("dlgTextCancel", "キャンセル");

	auto apply = Msg("apply", "適用");
	auto del = Msg("del", "削除");

	auto filterAll = Msg("filterAll", "すべてのファイル (*.*)");

	auto fileCopyError = Msg("fileCopyError", "%1$sのコピー中にエラーが発生しました。");
	auto reloadError = Msg("reloadError", "%1$sの再読込中にエラーが発生しました。");
	auto loadProgress = Msg("loadProgress", "%2$s%% 完了 - %1$sを展開中");
	auto loading = Msg("loading", "%1$sの読込みを開始");
	auto loaded = Msg("loaded", "%1$sの読込みを完了");
	auto loadedCount = Msg("loadedCount", "%1$s件の読込みを完了");
	auto reconstructionStatus = Msg("reconstructionStatus", "編集状態を復元中 (%1$s/%2$s)");
	auto cwxPathOpenError = Msg("cwxPathOpenError", "パス [%1$s] を開けません。");
	auto filePathOpenError = Msg("filePathOpenError", "パス [%1$s] を開けません。");

	auto loadSkinError = Msg("loadSkinError", "デフォルトのスキン「%1$s」が見つかりません。\n" ~ CARD_WIRTH_PY_EXE ~ "本体の場所が正しくないか、Data" ~ DIR ~ "が正しく配置されていない可能性があります。\nこのまま開始すると、一部リソース画像が非表示になります。");
	auto useDefaultSkin = Msg("useDefaultSkin", "スキン「%1$s」が見つかりません。\nデフォルトのスキン「%1$s」を使用します。");
	auto scenarioName = Msg("scenarioName", "シナリオ名");
	auto type = Msg("type", "タイプ");
	auto initialize = Msg("initialize", "初期設定");
	auto classic = Msg("classic", "[クラシック]");
	auto scenarioTemplate = Msg("scenarioTemplate", "テンプレート");
	auto templateDesc = Msg("templateDesc", "%1$s [%2$s]");
	auto noTemplate = Msg("noTemplate", "[テンプレート無し]");
	auto createClassicDir = Msg("createClassicDir", "シナリオの作成先");
	auto newClassicDir = Msg("newClassicDir", "シナリオ作成先の選択");
	auto newClassicDirDesc = Msg("newClassicDirDesc", "シナリオを作成する" ~ DIR ~ "を選択してください。");
	auto notEmptyDir = Msg("notEmptyDir", "%1$sは空ではありません。\n本当にここでシナリオを作成しますか？");
	auto createScenarioNameDir = Msg("createScenarioNameDir", "シナリオの" ~ DIR ~ "を新規作成する");

	auto newScenarioName = Msg("newScenarioName", "新規シナリオ");

	auto dlgTitSaveBitmapImage = Msg("dlgTitSaveBitmapImage", "格納イメージの保存");
	auto filterBitmapImage = Msg("filterBitmapImage", "ビットマップイメージ (*.bmp)");
	auto dlgMsgIncludeImage = Msg("dlgMsgIncludeImage", "%1$sをシナリオファイル内にコピーしますか？\n(元のファイルは削除されません)");

	auto newFolder = Msg("newFolder", "新規" ~ DIR);

	auto dlgMsgDeleteFile = Msg("dlgMsgDeleteFile", "%1$sを完全に削除しますか？");
	auto dlgMsgDeleteFiles = Msg("dlgMsgDeleteFiles", "%1$s個の項目を完全に削除しますか？");
	auto dlgMsgDeleteFileRecycle = Msg("dlgMsgDeleteFileRecycle", "%1$sをごみ箱に移動しますか？");
	auto dlgMsgDeleteFilesRecycle = Msg("dlgMsgDeleteFilesRecycle", "%1$s個の項目をごみ箱に移動しますか？");
	auto dlgMsgDeleteUnuse = Msg("dlgMsgDeleteUnuse", "%1$s個の未使用ファイル・" ~ DIR ~ "を完全に削除しますか？");
	auto dlgMsgDeleteRecycleUnuse = Msg("dlgMsgDeleteRecycleUnuse", "%1$s個の未使用ファイル・" ~ DIR ~ "をごみ箱に移動しますか？");

	auto image = Msg("image", "イメージ");
	auto pathDef = Msg("pathDef", "[デフォルト]");
	auto imageNone = Msg("imageNone", "[イメージ無し]");
	auto fileNone = Msg("fileNone", "[ファイルを選択]");
	auto imageIncluding = Msg("imageIncluding", "[イメージ格納]");
	auto pcNumber = Msg("pcNumber", "[プレイヤー%1$s]");
	auto seNone = Msg("seNone", "[サウンド無し]");
	auto bgmStop = Msg("bgmStop", "[BGM停止]");
	auto bgmNone = Msg("bgmNone", "[BGM無し]");
	auto useNoCardSizeImage = Msg("useNoCardSizeImage", "74×94以外も許容");
	auto dlgMsgIsSaveBeforeReload = Msg("dlgMsgIsSaveBeforeReload", "「%1$s」は変更されています。再読込しますか？");
	auto reloadBeforeSaveError = Msg("reloadBeforeSaveError", "「%1$s」は保存されていないため、再読込できません。");
	auto dlgMsgIsSaveBeforeExit = Msg("dlgMsgIsSaveBeforeExit", "「%1$s」は変更されています。保存しますか？");
	auto dlgMsgDropFile = Msg("dlgMsgDropFile", "%1$sをシナリオ" ~ DIR ~ "にコピーしますか？");
	auto dlgMsgDropFiles = Msg("dlgMsgDropFiles", "%1$s個のファイルをシナリオ" ~ DIR ~ "にコピーしますか？");
	auto dlgMsgDropOverWriteFile = Msg("dlgMsgDropOverWriteFile", "%1$sはすでに存在します。上書きしますか？");
	auto dlgMsgDropOverWriteFiles = Msg("dlgMsgDropOverWriteFiles", "%1$s個の項目がすでに存在します。上書きしますか？");
	auto dlgTitDropFiles = Msg("dlgTitDropFiles", "素材ファイルの追加");
	auto dlgMsgCopyError = Msg("dlgMsgCopyError", "いくつかのファイルのコピーに失敗しました。");

	auto dlgMsgCopyMaterial1 = Msg("dlgMsgCopyMaterial1", "格納画像もコピーしますか？");
	auto dlgMsgCopyMaterial2 = Msg("dlgMsgCopyMaterial2", "素材もコピーしますか？\n%1$s");
	auto dlgMsgCopyMaterial3 = Msg("dlgMsgCopyMaterial3", "素材もコピーしますか？\n%1$s個のファイル");
	auto dlgMsgCopyMaterial4 = Msg("dlgMsgCopyMaterial4", "素材もコピーしますか？\n%1$s個のファイルと%2$s個の格納画像");

	auto incSearchContains = Msg("incSearchContains", "名前の一部");
	auto incSearchWildcard = Msg("incSearchWildcard", "ワイルドカード");
	auto incSearchRegex = Msg("incSearchRegex", "正規表現");

	auto dlgTitSettings = Msg("dlgTitSettings", "CWXEditorの設定");

	auto refreshS = Msg("refreshS", "更新");

	auto summary = Msg("summary", "シナリオの設定");
	auto area = Msg("area", "エリア");
	auto battle = Msg("battle", "バトル");
	auto cwPackage = Msg("cwPackage", "パッケージ");

	auto dlgTitReplaceText = Msg("dlgTitReplaceText", "検索と置換");
	auto replForText = Msg("replForText", "テキスト検索");
	auto replForID = Msg("replForID", "ID検索");
	auto replForPath = Msg("replForPath", "素材検索");
	auto replContents = Msg("replContents", "コンテント検索");
	auto replForCoupon = Msg("replForCoupon", "称号・名称一覧");
	auto replForUnuse = Msg("replForUnuse", "未使用検索");
	auto replForError = Msg("replForError", "誤り検索");
	auto replGrep = Msg("replGrep", "外部シナリオ");

	auto searchRange = Msg("searchRange", "検索対象");
	auto flagsAndSteps = Msg("flagsAndSteps", "フラグとステップ");
	auto allCheckRange = Msg("allCheckRange", "全てチェック/全てチェックを外す");

	auto allCheck = Msg("allCheck", "全てチェック/全てチェックを外す(&L)");
	auto allSelect = Msg("allSelect", "全て選択/全て選択を外す(&L)");

	auto replError = Msg("replError", "重複する分岐(フラグ分岐が両方ともTRUEになっている等)・条件クーポンに抜けがある台詞コンテント・存在しない素材を参照しているコンテント等を検索します。");

	auto replFrom = Msg("replFrom", "検索(置換前)");
	auto replTo = Msg("replTo", "置換後");
	auto grepFrom = Msg("replFrom", "検索");

	auto replText = Msg("replText", "検索/置換するテキスト");
	auto replTextTarget = Msg("replTextTarget", "検索/置換対象");
	auto replTextSummary = Msg("replTextSummary", "貼り紙");
	auto replTextMessage = Msg("replTextMessage", "メッセージ");
	auto replTextCardName = Msg("replTextCardName", "カード名");
	auto replTextCardDesc = Msg("replTextCardDesc", "カード解説");
	auto replTextEventText = Msg("replTextEventText", "イベントテキスト");
	auto replTextStart = Msg("replTextStart", "スタートコンテント");
	auto replTextFlagAndStep = Msg("replTextFlagAndStep", "フラグ/ステップ");
	auto replTextCoupon = Msg("replTextCoupon", "クーポン");
	auto replTextGossip = Msg("replTextGossip", "ゴシップ");
	auto replTextEndScenario = Msg("replTextEndScenario", "終了印");
	auto replTextAreaName = Msg("replTextAreaName", "エリア/バトル/パッケージ名");
	auto replTextKeyCode = Msg("replTextKeyCode", "キーコード");
	auto replTextFile = Msg("replTextFile", "ファイル名");
	auto replTextComment = Msg("replTextComment", "コメント");
	auto replTextJptx = Msg("replTextJptx", "JPTX/テキストセル");

	auto replID = Msg("replID", "検索/置換対象");
	auto replIDKind = Msg("replIDKind", "対象");
	auto replIDArea = Msg("replIDArea", "エリア");
	auto replIDBattle = Msg("replIDBattle", "バトル");
	auto replIDPackage = Msg("replIDPackage", "パッケージ");
	auto replIDCast = Msg("replIDCast", "キャストカード");
	auto replIDSkill = Msg("replIDSkill", "特殊技能カード");
	auto replIDItem = Msg("replIDItem", "アイテムカード");
	auto replIDBeast = Msg("replIDBeast", "召喚獣カード");
	auto replIDInfo = Msg("replIDInfo", "情報カード");
	auto replSetID = Msg("replSetID", "[IDを直接指定]");

	auto replPath = Msg("replPath", "検索/置換する素材");

	auto replUnuseTarget = Msg("replUnuseTarget", "検索対象");
	auto replUnuseFlag = Msg("replUnuseFlag", "フラグ");
	auto replUnuseStep = Msg("replUnuseStep", "ステップ");
	auto replUnuseArea = Msg("replUnuseArea", "エリア");
	auto replUnuseBattle = Msg("replUnuseBattle", "バトル");
	auto replUnusePackage = Msg("replUnusePackage", "パッケージ");
	auto replUnuseCast = Msg("replUnuseCast", "キャストカード");
	auto replUnuseSkill = Msg("replUnuseSkill", "特殊技能カード");
	auto replUnuseItem = Msg("replUnuseItem", "アイテムカード");
	auto replUnuseBeast = Msg("replUnuseBeast", "召喚獣カード");
	auto replUnuseInfo = Msg("replUnuseInfo", "情報カード");
	auto replUnuseStart = Msg("replUnuseStart", "スタートコンテント");
	auto replUnusePath = Msg("replUnusePath", "素材");

	auto replNotIgnoreCase = Msg("replNotIgnoreCase", "大文字と小文字を区別する(&C)");
	auto replRegExp = Msg("replRegExp", "正規表現(&E) (. = 任意1文字, * = 直前の文字の任意数繰返し, $1 = 1つめの文字列グループ ...)");
	auto regexError = Msg("regexError", "正規表現が正しくありません。");
	auto replWildcard = Msg("replWildcard", "ワイルドカード(&W) (* = 任意文字列, ? = 任意1文字, \\* = *, \\? = ?, \\\\ = \\)");
	auto replExactMatch = Msg("replExactMatch", "完全一致(&X)");
	auto replCond = Msg("replCond", "検索条件");
	auto search = Msg("search", "検索(&F)");
	auto replace = Msg("replace", "全て置換(&R)");
	auto cautionOfReplace = Msg("cautionOfReplace", "%1$sを%2$sに置換します。よろしいですか？");
	auto replaceValue = Msg("replaceValue", "「%1$s」");
	auto emptyText = Msg("emptyText", "空文字列");
	auto emptyPath = Msg("emptyPath", "空のパス");
	auto idValue = Msg("idValue", "ID:%1$sの%2$s");
	auto searchCancel = Msg("searchCancel", "キャンセル(&C)");
	auto replaceExit = Msg("replaceExit", "閉じる");
	auto searchResultEmpty = Msg("searchResultEmpty", "0件の検索結果");
	auto searchResult = Msg("searchResult", "%1$s件の検索結果(%2$s)");
	auto searchResultGrep1 = Msg("searchResultGrep1", "%1$s件の検索結果(%2$sを読込中...)");
	auto searchResultGrep2 = Msg("searchResultGrep2", "%1$s件の検索結果(%2$sを検索中...)");
	auto searchResultRealtime = Msg("searchResultRealtime", "リアルタイム更新");
	auto replResultEmpty = Msg("replResultEmpty", "0箇所の置換");
	auto replResult = Msg("replResult", "%1$s箇所の置換(%2$s)");
	auto replaceUndo = Msg("replaceUndo", "%1$s件を元に戻しました");
	auto replaceRedo = Msg("replaceRedo", "%1$s件をやり直しました");

	auto grepText = Msg("grepText", "検索するテキスト");
	auto grepTarget = Msg("grepTarget", "検索対象");
	auto grepDir = Msg("grepDir", "外部シナリオ検索");
	auto grepDirDesc = Msg("grepDirDesc", "検索対象のシナリオが含まれる" ~ DIR ~ "を選択してください。");
	auto grepCurrent = Msg("grepCurrent", "現" ~ DIR);
	auto grepSubDir = Msg("grepSubDir", "サブ" ~ DIR ~ "も検索する");
	auto grepScenario = Msg("grepScenario", "%1$s[%2$s]");

	auto searchResultColumnMain = Msg("searchResultColumnMain", "マッチ箇所");
	auto searchResultColumnParent = Msg("searchResultColumnParent", "所属");
	auto searchResultColumnCoupon = Msg("searchResultColumnCoupon", "称号・名称");
	auto searchResultColumnCouponCount = Msg("searchResultColumnCouponCount", "利用数");
	auto searchResultColumnError = Msg("searchResultColumnError", "誤り箇所");
	auto searchResultColumnErrorDesc = Msg("searchResultColumnErrorDesc", "解説");
	auto searchResultColumnScenario = Msg("searchResultColumnScenario", "シナリオ");

	auto searchResultSummary = Msg("searchResultSummary", "シナリオの概要 - %1$s");

	auto searchResultImageCell = Msg("searchResultBgImage", "背景画像 [%1$s]");
	auto searchResultTextCell = Msg("searchResultTextCell", "テキストセル [%1$s]");
	auto searchResultColorCell = Msg("searchResultColorCell", "カラーセル [%1$s]");
	auto searchResultIds = Msg("searchResultIds", "%1$s [%2$s.%3$s]");

	auto searchResultFlag = Msg("searchResultFlag", "フラグ [%1$s]");
	auto searchResultStep = Msg("searchResultStep", "ステップ [%1$s]");
	auto searchResultFlagDir = Msg("searchResultFlagDir", "ディレクトリ [%1$s]");
	auto searchResultEventTree = Msg("searchResultEventTree", "イベントツリー [%1$s]");
	auto searchResultMenuCard = Msg("searchResultMenuCard", "メニューカード [%1$s]");
	auto searchResultEnemyCard = Msg("searchResultEnemyCard", "エネミーカード [%1$s]");

	auto searchErrorReversalLevel = Msg("searchErrorReversalLevel", "レベルの上限と下限が逆転しています。");
	auto searchErrorNoImage = Msg("searchErrorNoImage", "イメージが指定されていません。");
	auto searchErrorImageNotFound = Msg("searchErrorImageNotFound", "存在しないイメージファイルが指定されています。");
	auto searchErrorBGMNotFound = Msg("searchErrorBGMNotFound", "存在しないBGMファイルが指定されています。");
	auto searchErrorSENotFound = Msg("searchErrorSENotFound", "存在しない効果音ファイルが指定されています。");
	auto searchErrorStartAreaNotFound = Msg("searchErrorStartAreaNotFound", "開始エリアが設定されていません。");
	auto searchErrorFlagNotFound = Msg("searchErrorFlagNotFound", "存在しないフラグが指定されています。");
	auto searchErrorStepNotFound = Msg("searchErrorStepNotFound", "存在しないステップが指定されています");
	auto searchErrorNoCast = Msg("searchErrorNoCast", "キャストカードが指定されていません。");
	auto searchErrorNoBeast = Msg("searchErrorNoBeast", "召喚獣カードが指定されていません。");
	auto searchErrorDupNextContent = Msg("searchErrorDupNextContent", "分岐条件が重複しています。");
	auto searchErrorSPFontNotFound = Msg("searchErrorSPFontNotFound", "特殊フォントイメージが見つかりません。");
	auto searchErrorNoRCouponsDialog = Msg("searchErrorNoRCouponsDialog", "最終項目以外にクーポン指定無し項目があります。");
	auto searchErrorAreaNotFound = Msg("searchErrorAreaNotFound", "存在しないエリアが指定されています。");
	auto searchErrorBattleNotFound = Msg("searchErrorBattleNotFound", "存在しないバトルが指定されています。");
	auto searchErrorPackageNotFound = Msg("searchErrorPackageNotFound", "存在しないパッケージが指定されています。");
	auto searchErrorCastNotFound = Msg("searchErrorCastNotFound", "存在しないキャストカードが指定されています。");
	auto searchErrorSkillNotFound = Msg("searchErrorSkillNotFound", "存在しないスキルカードが指定されています。");
	auto searchErrorItemNotFound = Msg("searchErrorItemNotFound", "存在しないアイテムカードが指定されています。");
	auto searchErrorBeastNotFound = Msg("searchErrorBeastNotFound", "存在しない召喚獣カードが指定されています。");
	auto searchErrorInfoNotFound = Msg("searchErrorInfoNotFound", "存在しない情報カードが指定されています。");
	auto searchErrorStartNotFound = Msg("searchErrorStartNotFound", "存在しないスタートコンテントが指定されています。");
	auto searchErrorIgnoreWait = Msg("searchErrorIgnoreWait", "後続コンテントが無いため、空白時間が無視されます。");
	auto searchErrorLinkIdNotFound = Msg("searchErrorLinkIdNotFound", "参照先のカードが見つかりません。");
	auto searchErrorEmptyFile = Msg("searchErrorEmptyFile", "ファイルの内容が存在しません。");
	auto searchErrorDupFile = Msg("searchErrorDupFile", "同一のファイル「%1$s」が存在します。");
	auto searchErrorSouceIsTarget = Msg("searchErrorSouceIsTarget", "ソース変数とターゲット変数が同一です。");
	auto searchErrorSystemName = Msg("searchErrorSystemName", "システムで使用されている名前のため、正しく機能しない場合があります。");
	auto searchErrorKeyCodeMatchingAll = Msg("searchErrorKeyCodeMatchingAll", "「MatchingType=All」はシステムで使用されているキーコードのため、正しく機能しない場合があります。");
	auto searchErrorBranchRoundInArea = Msg("searchErrorBranchRoundInArea", "ラウンド分岐がエリアイベントで使用されています。");

	auto searchOpenDialog = Msg("searchOpenDialog", "検索結果へジャンプする時、ダイアログを開く");

	/// イベント設定。
	auto dlgTitContent = Msg("dlgTitContent", "イベントの設定 [ %1$s ]");

	auto afterClear = Msg("afterClear", "シナリオ終了後");
	auto afterClearEndMark = Msg("afterClearEndMark", "シナリオに済印を付ける");
	auto afterClearNoEndMark = Msg("afterClearNoEndMark", "何もしない");

	auto couponName = Msg("couponName", "クーポン名");
	auto couponValue = Msg("couponValue", "得点");
	auto couponValueRange = Msg("couponValueRange", "(%1$s～%2$s)");
	auto range = Msg("range", "適用範囲");
	auto gossipName = Msg("gossipName", "ゴシップ名");
	auto endName = Msg("endName", "シナリオ名");
	auto cardType = Msg("cardType", "カードの種類");
	auto keyCode = Msg("keyCode", "キーコード");
	auto talker = Msg("talker", "話者");
	auto initValue = Msg("initValue", "初期点");
	auto toneCoupons = Msg("toneCoupons", "口調条件");
	auto valued = Msg("valued", "評価条件");
	auto valuedTalkerMaxMin = Msg("valuedTalkerMaxMin", "最大値 = %1$s\n最小値 = %2$s");
	auto valuedTalkerMaxMinLess0 = Msg("valuedTalkerMaxMinLess0", "最大値 = %1$s\n最小値 = %2$s (発言しない)");

	auto couponHide = Msg("couponHide", "隠蔽クーポン");

	const string couponTypeDesc(CouponType id) {
		mixin(EnumToStringSwitch!(CouponType, "couponTypeDesc"));
	}
	auto couponTypeDescNormal = Msg("couponTypeDescNormal", "ノーマル");
	auto couponTypeDescHide = Msg("couponTypeDescHide", "[＿...] 隠蔽(称号一覧で非表示)");
	auto couponTypeDescSystem = Msg("couponTypeDescSystem", "[＠...] システム");
	auto couponTypeDescDur = Msg("couponTypeDescDur", "[：...] 時限(点数分の時間経過及びシナリオ終了時に消滅)");
	auto couponTypeDescDurBattle = Msg("couponTypeDescDurBattle", "[；...] 戦闘中時限(点数分の時間経過及び戦闘終了時に消滅)");

	const string couponTypeName(CouponType id) {
		mixin(EnumToStringSwitch!(CouponType, "couponTypeName"));
	}
	auto couponTypeNameNormal = Msg("couponTypeNameNormal", "通常");
	auto couponTypeNameHide = Msg("couponTypeNameHide", "隠蔽");
	auto couponTypeNameSystem = Msg("couponTypeNameSystem", "システム");
	auto couponTypeNameDur = Msg("couponTypeNameDur", "時限");
	auto couponTypeNameDurBattle = Msg("couponTypeNameDurBattle", "戦時");

	auto imageMessage = Msg("imageMessage", "イメージ付きメッセージ");
	auto noImageMessage = Msg("noImageMessage", "イメージ無しメッセージ");
	auto spCharsTitle = Msg("spCharsTitle", "特殊文字");
	auto colorW = Msg("colorW", "デフォルト(&W)");
	auto colorR = Msg("colorR", "赤色(&R)");
	auto colorB = Msg("colorB", "青色(&B)");
	auto colorG = Msg("colorG", "緑色(&G)");
	auto colorY = Msg("colorY", "黄色(&Y)");
	auto colorO = Msg("colorO", "橙色(&O)"); // CardWirth 1.50
	auto colorP = Msg("colorP", "紫色(&P)"); // CardWirth 1.50
	auto colorL = Msg("colorL", "明るい灰色(&L)"); // CardWirth 1.50
	auto colorD = Msg("colorD", "暗い灰色(&D)"); // CardWirth 1.50
	const string scTalkerName(Talker id) {
		mixin(EnumToStringSwitch!(Talker, "scTalkerName"));
	}
	auto scTalkerNameSelected = Msg("scTalkerNameSelected", "選択メンバ名(#M)");
	auto scTalkerNameUnselected = Msg("scTalkerNameUnselected", "選択外ランダムメンバ名(#U)");
	auto scTalkerNameRandom = Msg("scTalkerNameRandom", "ランダムメンバ名(#R)");
	auto scTalkerNameCard = Msg("scTalkerNameCard", "選択カード名(#C)");
	auto scTalkerNameNarration = Msg("scTalkerNameNarration", "話者無し");
	auto scTalkerNameImage = Msg("scTalkerNameImage", "画像");
	auto scTalkerNameValued = Msg("scTalkerNameValued", "評価メンバ");
	auto scRef = Msg("scRef", "話者(#I)");
	auto scTeam = Msg("scTeam", "チーム名(#T)");
	auto scYado = Msg("scYado", "宿屋名(#Y)");
	auto addMsgRefFlag = Msg("addMsgRefFlag", "フラグ参照の追加");
	auto addMsgRefStep = Msg("addMsgRefStep", "ステップ参照の追加");
	auto createDialog = Msg("createDialog", "台詞の作成");
	auto deleteDialog = Msg("deleteDialog", "台詞の削除");
	auto copyToDialogs = Msg("copyToDialogs", "台詞を全体にコピー");
	auto copyToUpper = Msg("copyToUpper", "台詞を上方にコピー");
	auto copyToLower = Msg("copyToLower", "台詞を下方にコピー");
	auto setTalkerCoupon = Msg("setTalkerCoupon", "追加");
	auto messagePreview = Msg("messagePreview", "プレビュー");
	auto dlgTitMessagePreview = Msg("dlgTitMessagePreview", "プレビュー");
	auto messageVarKindColumn = Msg("messageVarKindColumn", "状態変数");
	auto messageVarValueColumn = Msg("messageVarValueColumn", "サンプル値");

	auto transition = Msg("transition", "背景切替方式");
	const string transitionName(Transition id) {
		mixin(EnumToStringSwitch!(Transition, "transitionName"));
	}
	auto transitionNameDefault = Msg("transitionNameDefault", "[プレイヤーの設定を使用]");
	auto transitionNameNone = Msg("transitionNameNone", "アニメーション無し");
	auto transitionNameFade = Msg("transitionNameFade", "フェード式");
	auto transitionNamePixelDissolve = Msg("transitionNamePixelDissolve", "ピクセルディゾルブ式");
	auto transitionNameBlinds = Msg("transitionNameBlinds", "ブラインド式");
	auto transitionSpeed = Msg("transitionSpeed", "背景切替ウェイト");
	auto waitName = Msg("waitName", "空白時間(0.1秒単位)");
	auto moneyName = Msg("moneyName", "金額");
	auto randomName = Msg("randomName", "確率(%)");
	auto partyNumName = Msg("partyNumName", "パーティの人数");
	auto judgeTarget = Msg("judgeTarget", "判定対象");
	auto flag = Msg("flag", "フラグ");
	auto step = Msg("step", "ステップ");
	auto flagValue = Msg("flagValue", "値");
	auto stepValue = Msg("stepValue", "段階");
	auto selectMember = Msg("selectMember", "選択対象");
	auto activeMember = Msg("activeMember", "動けるメンバから選択");
	auto allMember = Msg("allMember", "パーティ全員から選択");
	auto selectMethod = Msg("selectMethod", "選択方法");
	auto manualMethod = Msg("manualMethod", "手動で選択");
	auto randomMethod = Msg("randomMethod", "ランダムで選択");
	auto judgeSleep = Msg("judgeSleep", "眠り判定");
	auto sleepDisabled = Msg("sleepDisabled", "睡眠者無効");
	auto sleepEnabled = Msg("sleepEnabled", "睡眠者有効");
	auto selectedLevel = Msg("selectedLevel", "現在選択中のメンバ");
	auto allMemberLevel = Msg("allMemberLevel", "パーティ全員の平均値");
	auto judgeLevel = Msg("judgeLevel", "判定レベル");
	auto judgeState = Msg("judgeState", "判定状態");
	auto stateHint = Msg("stateHint", "ヒント");
	auto cardNumber = Msg("cardNumber", "枚数");
	auto cardAllDelete = Msg("cardAllDelete", "全て削除する");
	auto cardEventRange = Msg("cardEventRange", "適用範囲");
	auto transitionType = Msg("transitionType", "背景切替方式");
	auto substituteSource = Msg("flagSubstituteSource", "ソース変数(代入元)");
	auto substituteTarget = Msg("flagSubstituteTarget", "ターゲット変数(代入先)");
	auto cmpSource = Msg("flagCmpSource", "ソース変数(比較元)");
	auto cmpTarget = Msg("flagCmpTarget", "ターゲット変数(比較元)");
	auto randomSelectHasLevel = Msg("randomSelectHasLevel", "レベルを限定");
	auto randomSelectHasStatus = Msg("randomSelectHasStatus", "状態を限定");
	auto stepValueIs = Msg("stepValueIs", "ステップ「%1$s」が[%2$s]");
	auto roundCondition = Msg("roundCondition", "ラウンド条件");
	auto roundIs = Msg("roundIs", "バトルが");
	auto roundCmpIs = Msg("roundCmpIs", "ラウンド");

	const string blendModeName(BlendMode id) {
		mixin(EnumToStringSwitch!(BlendMode, "blendModeName"));
	}
	auto blendModeNameNormal = Msg("blendModeNameNormal", "通常");
	auto blendModeNameMask = Msg("blendModeNameMask", "マスク");
	auto blendModeNameAdd = Msg("blendModeNameAdd", "加算");
	auto blendModeNameSubtract = Msg("blendModeNameSubtract", "減算");
	auto blendModeNameMultiply = Msg("blendModeNameMultiply", "乗算");

	const string gradientDirName(GradientDir id) {
		mixin(EnumToStringSwitch!(GradientDir, "gradientDirName"));
	}
	auto gradientDirNameNone = Msg("gradientDirNameNone", "グラデーション無し");
	auto gradientDirNameLeftToRight = Msg("gradientDirNameLeftToRight", "左から右へ");
	auto gradientDirNameTopToBottom = Msg("gradientDirNameTopToBottom", "上から下へ");

	const string borderingTypeName(BorderingType id) {
		mixin(EnumToStringSwitch!(BorderingType, "borderingTypeName"));
	}
	auto borderingTypeNameNone = Msg("borderingTypeNameNone", "縁取り無し");
	auto borderingTypeNameOutline = Msg("borderingTypeNameOutline", "形式1");
	auto borderingTypeNameInline = Msg("borderingTypeNameInline", "形式2");

	/// イベント。
	auto evtArrow = Msg("evtArrow", "イベント編集");

	auto evtAddContinue = Msg("evtAddContinue", "連続で配置");
	auto evtAutoOpen = Msg("evtAutoOpen", "配置と同時に編集");

	const string contentName(CType id) {
		mixin(EnumToStringSwitch!(CType, "contentName"));
	}
	auto contentNameStart = Msg("contentNameStart", "スタート");
	auto contentNameStartBattle = Msg("contentNameStartBattle", "バトル開始");
	auto contentNameEnd = Msg("contentNameEnd", "シナリオクリア");
	auto contentNameEndBadEnd = Msg("contentNameEndBadEnd", "ゲームオーバー");
	auto contentNameChangeArea = Msg("contentNameChangeArea", "エリア移動");
	auto contentNameChangeBgImage = Msg("contentNameChangeBgImage", "背景変更");
	auto contentNameEffect = Msg("contentNameEffect", "効果");
	auto contentNameEffectBreak = Msg("contentNameEffectBreak", "効果中断");
	auto contentNameLinkStart = Msg("contentNameLinkStart", "スタートへのリンク");
	auto contentNameLinkPackage = Msg("contentNameLinkPackage", "パッケージへのリンク");
	auto contentNameTalkMessage = Msg("contentNameTalkMessage", "メッセージ");
	auto contentNameTalkDialog = Msg("contentNameTalkDialog", "セリフ");
	auto contentNamePlayBgm = Msg("contentNamePlayBgm", "BGM変更");
	auto contentNamePlaySound = Msg("contentNamePlaySound", "効果音");
	auto contentNameWait = Msg("contentNameWait", "空白時間挿入");
	auto contentNameElapseTime = Msg("contentNameElapseTime", "時間経過");
	auto contentNameCallStart = Msg("contentNameCallStart", "スタートの呼び出し");
	auto contentNameCallPackage = Msg("contentNameCallPackage", "パッケージの呼び出し");
	auto contentNameBranchFlag = Msg("contentNameBranchFlag", "フラグ分岐");
	auto contentNameBranchMultiStep = Msg("contentNameBranchMultiStep", "ステップ多岐分岐");
	auto contentNameBranchStep = Msg("contentNameBranchStep", "ステップ上下分岐");
	auto contentNameBranchSelect = Msg("contentNameBranchSelect", "メンバ選択分岐");
	auto contentNameBranchAbility = Msg("contentNameBranchAbility", "能力判定分岐");
	auto contentNameBranchRandom = Msg("contentNameBranchRandom", "ランダム分岐");
	auto contentNameBranchLevel = Msg("contentNameBranchLevel", "レベル判定分岐");
	auto contentNameBranchStatus = Msg("contentNameBranchStatus", "状態判定分岐");
	auto contentNameBranchPartyNumber = Msg("contentNameBranchPartyNumber", "人数判定分岐");
	auto contentNameBranchArea = Msg("contentNameBranchArea", "エリア分岐");
	auto contentNameBranchBattle = Msg("contentNameBranchBattle", "バトル分岐");
	auto contentNameBranchIsBattle = Msg("contentNameBranchIsBattle", "バトル判定分岐");
	auto contentNameBranchCast = Msg("contentNameBranchCast", "キャスト存在分岐");
	auto contentNameBranchItem = Msg("contentNameBranchItem", "アイテム所持分岐");
	auto contentNameBranchSkill = Msg("contentNameBranchSkill", "スキル所持分岐");
	auto contentNameBranchInfo = Msg("contentNameBranchInfo", "情報所持分岐");
	auto contentNameBranchBeast = Msg("contentNameBranchBeast", "召喚獣存在分岐");
	auto contentNameBranchMoney = Msg("contentNameBranchMoney", "所持金分岐");
	auto contentNameBranchCoupon = Msg("contentNameBranchCoupon", "クーポン分岐");
	auto contentNameBranchCompleteStamp = Msg("contentNameBranchCompleteStamp", "終了シナリオ分岐");
	auto contentNameBranchGossip = Msg("contentNameBranchGossip", "ゴシップ分岐");
	auto contentNameSetFlag = Msg("contentNameSetFlag", "フラグ変更");
	auto contentNameSetStep = Msg("contentNameSetStep", "ステップ変更");
	auto contentNameSetStepUp = Msg("contentNameSetStepUp", "ステップ増加");
	auto contentNameSetStepDown = Msg("contentNameSetStepDown", "ステップ減少");
	auto contentNameReverseFlag = Msg("contentNameReverseFlag", "フラグ反転");
	auto contentNameCheckFlag = Msg("contentNameCheckFlag", "フラグ判定");
	auto contentNameGetCast = Msg("contentNameGetCast", "キャスト加入");
	auto contentNameGetItem = Msg("contentNameGetItem", "アイテム入手");
	auto contentNameGetSkill = Msg("contentNameGetSkill", "スキル取得");
	auto contentNameGetInfo = Msg("contentNameGetInfo", "情報入手");
	auto contentNameGetBeast = Msg("contentNameGetBeast", "召喚獣獲得");
	auto contentNameGetMoney = Msg("contentNameGetMoney", "所持金増加");
	auto contentNameGetCoupon = Msg("contentNameGetCoupon", "クーポン取得");
	auto contentNameGetCompleteStamp = Msg("contentNameGetCompleteStamp", "終了シナリオ設定");
	auto contentNameGetGossip = Msg("contentNameGetGossip", "ゴシップ追加");
	auto contentNameLoseCast = Msg("contentNameLoseCast", "キャスト離脱");
	auto contentNameLoseItem = Msg("contentNameLoseItem", "アイテム喪失");
	auto contentNameLoseSkill = Msg("contentNameLoseSkill", "スキル喪失");
	auto contentNameLoseInfo = Msg("contentNameLoseInfo", "情報喪失");
	auto contentNameLoseBeast = Msg("contentNameLoseBeast", "召喚獣消去");
	auto contentNameLoseMoney = Msg("contentNameLoseMoney", "所持金減少");
	auto contentNameLoseCoupon = Msg("contentNameLoseCoupon", "クーポン削除");
	auto contentNameLoseCompleteStamp = Msg("contentNameLoseCompleteStamp", "終了シナリオ削除");
	auto contentNameLoseGossip = Msg("contentNameLoseGossip", "ゴシップ削除");
	auto contentNameShowParty = Msg("contentNameShowParty", "パーティ表示");
	auto contentNameHideParty = Msg("contentNameHideParty", "パーティ隠蔽");
	auto contentNameRedisplay = Msg("contentNameRedisplay", "画面再構築");
	auto contentNameSubstituteStep = Msg("contentNameSubstituteStep", "ステップ代入");
	auto contentNameSubstituteFlag = Msg("contentNameSubstituteFlag", "フラグ代入");
	auto contentNameBranchStepCmp = Msg("contentNameBranchStepCmp", "ステップ比較分岐");
	auto contentNameBranchFlagCmp = Msg("contentNameBranchFlagCmp", "フラグ比較分岐");
	auto contentNameBranchRandomSelect = Msg("contentNameBranchRandomSelect", "ランダム選択");
	auto contentNameBranchKeyCode = Msg("contentNameBranchKeyCode", "キーコード所持分岐");
	auto contentNameCheckStep = Msg("contentNameCheckStep", "ステップ判定");
	auto contentNameBranchRound = Msg("contentNameBranchRound", "ラウンド分岐");

	auto msnGroupVitality = Msg("msnGroupVitality", "生命力");
	auto msnGroupPhysical = Msg("msnGroupPhysical", "肉体");
	auto msnGroupSkill = Msg("msnGroupSkill", "技能");
	auto msnGroupMental = Msg("msnGroupMental", "精神");
	auto msnGroupMagic = Msg("msnGroupMagic", "魔法");
	auto msnGroupEnhance = Msg("msnGroupEnhance", "能力");
	auto msnGroupVanish = Msg("msnGroupVanish", "消滅");
	auto msnGroupCard = Msg("msnGroupCard", "カード");
	auto msnGroupBeast = Msg("msnGroupBeast", "召喚");

	auto msnDelete = Msg("msnDelete", "効果削除");

	auto msnDesc = Msg("msnDesc", "%1$s - %2$s");

	const string motionName(MType id) {
		mixin(EnumToStringSwitch!(MType, "motionName"));
	}
	auto motionNameHeal = Msg("motionNameHeal", "回復");
	auto motionNameDamage = Msg("motionNameDamage", "ダメージ");
	auto motionNameAbsorb = Msg("motionNameAbsorb", "吸収");
	auto motionNameParalyze = Msg("motionNameParalyze", "麻痺");
	auto motionNameDisParalyze = Msg("motionNameDisParalyze", "麻痺解除");
	auto motionNamePoison = Msg("motionNamePoison", "中毒");
	auto motionNameDisPoison = Msg("motionNameDisPoison", "中毒解除");
	auto motionNameGetSkillPower = Msg("motionNameGetSkillPower", "精神力回復");
	auto motionNameLoseSkillPower = Msg("motionNameLoseSkillPower", "精神力喪失");
	auto motionNameSleep = Msg("motionNameSleep", "睡眠状態");
	auto motionNameConfuse = Msg("motionNameConfuse", "混乱状態");
	auto motionNameOverheat = Msg("motionNameOverheat", "激昂状態");
	auto motionNameBrave = Msg("motionNameBrave", "勇敢状態");
	auto motionNamePanic = Msg("motionNamePanic", "恐慌状態");
	auto motionNameNormal = Msg("motionNameNormal", "正常状態");
	auto motionNameBind = Msg("motionNameBind", "呪縛");
	auto motionNameDisBind = Msg("motionNameDisBind", "呪縛解除");
	auto motionNameSilence = Msg("motionNameSilence", "沈黙");
	auto motionNameDisSilence = Msg("motionNameDisSilence", "沈黙解除");
	auto motionNameFaceUp = Msg("motionNameFaceUp", "暴露");
	auto motionNameFaceDown = Msg("motionNameFaceDown", "暴露解除");
	auto motionNameAntiMagic = Msg("motionNameAntiMagic", "魔法無効化");
	auto motionNameDisAntiMagic = Msg("motionNameDisAntiMagic", "魔法無効化解除");
	auto motionNameEnhanceAction = Msg("motionNameEnhanceAction", "行動力変化");
	auto motionNameEnhanceAvoid = Msg("motionNameEnhanceAvoid", "回避力変化");
	auto motionNameEnhanceDefense = Msg("motionNameEnhanceDefense", "防御力変化");
	auto motionNameEnhanceResist = Msg("motionNameEnhanceResist", "抵抗力変化");
	auto motionNameVanishTarget = Msg("motionNameVanishTarget", "対象消去");
	auto motionNameVanishCard = Msg("motionNameVanishCard", "手札消去");
	auto motionNameVanishBeast = Msg("motionNameVanishBeast", "召喚獣消去");
	auto motionNameDealAttackCard = Msg("motionNameDealAttackCard", "通常攻撃");
	auto motionNameDealPowerfulAttackCard = Msg("motionNameDealPowerfulAttackCard", "渾身の一撃");
	auto motionNameDealCriticalAttackCard = Msg("motionNameDealCriticalAttackCard", "会心の一撃");
	auto motionNameDealFeintCard = Msg("motionNameDealFeintCard", "フェイント");
	auto motionNameDealDefenseCard = Msg("motionNameDealDefenseCard", "防御");
	auto motionNameDealDistanceCard = Msg("motionNameDealDistanceCard", "見切り");
	auto motionNameDealConfuseCard = Msg("motionNameDealConfuseCard", "混乱");
	auto motionNameDealSkillCard = Msg("motionNameDealSkillCard", "特殊技能");
	auto motionNameSummonBeast = Msg("motionNameSummonBeast", "召喚獣召喚");
	auto motionNameCancelAction = Msg("motionNameCancelAction", "行動キャンセル"); // CardWirthNext

	auto dialogText = Msg("dialogText", "%2$s: %1$s");
	auto dialogTextNoCoupon = Msg("dialogTextNoCoupon", "%1$s");

	auto ctStart = Msg("ctStart", "スタートコンテント「%1$s」");
	auto ctStartBattle = Msg("ctStartBattle", "バトルの開始「%1$s」");
	auto ctChangeArea = Msg("ctChangeArea", "エリア移動「%1$s」 切替方式 = %2$s ウェイト = %3$s");
	auto ctChangeAreaClassic = Msg("ctChangeAreaClassic", "エリア移動「%1$s」");
	auto ctEndComplete = Msg("ctEndComplete", "済印をつけて終了");
	auto ctEndNoComplete = Msg("ctEndNoComplete", "済印をつけずに終了");
	auto ctGameOver = Msg("ctGameOver", "ゲームオーバーコンテント");
	auto ctChangeBgImage = Msg("ctChangeBgImage", "背景ファイル = %1$s 切替方式 = %2$s ウェイト = %3$s");
	auto ctChangeBgImageClassic = Msg("ctChangeBgImageClassic", "背景ファイル = %1$s");
	auto ctChangeBgImageFile = Msg("ctChangeBgImageFile", "[%1$s]");
	auto ctEffectSound = Msg("ctEffectSound", "「%1$s」を再生");
	auto ctEffectNoSound = Msg("ctEffectNoSound", "音声無し");
	auto ctEffect = Msg("ctEffect", "%1$s レベル%2$s %3$s/%4$s 成功率%5$s%6$s %7$s %8$s 効果 = %9$s");
	auto ctEffectMotion = Msg("ctEffectMotion", "[%1$s]");
	auto ctEffectBreak = Msg("ctEffectBreak", "効果中断コンテント");
	auto ctLinkStart = Msg("ctLinkStart", "スタートコンテント「%1$s」へのリンク");
	auto ctLinkPackage = Msg("ctLinkPackage", "パッケージ「%1$s」へのリンク");
	auto ctTalkMessage = Msg("ctTalkMessage", "%1$s: %2$s");
	auto ctTalkMessageImage = Msg("ctTalkMessageImage", "[%1$s]");
	auto ctTalkDialog = Msg("ctTalkDialog", "%1$s %2$s: %3$s");
	auto ctTalkDialogNoCoupon = Msg("ctTalkDialogNoCoupon", "%1$s: %2$s");
	auto ctPlayBGM = Msg("ctPlayBGM", "BGMとして「%1$s」を演奏");
	auto ctStopBGM = Msg("ctStopBGM", "BGM停止");
	auto ctPlaySound = Msg("ctPlaySound", "効果音「%1$s」を鳴らす");
	auto ctWait = Msg("ctWait", "空白時間 = %1$s × 0.1秒");
	auto ctElapseTime = Msg("ctElapseTime", "ターン数経過コンテント");
	auto ctCallStart = Msg("ctCallStart", "スタートコンテント「%1$s」のコール");
	auto ctCallPackage = Msg("ctCallPackage", "パッケージ「%1$s」のコール");
	auto ctBranchFlag = Msg("ctBranchFlag", "フラグ「%1$s」の値で分岐");
	auto ctBranchMultiStep = Msg("ctBranchMultiStep", "ステップ「%1$s」の値で分岐");
	auto ctBranchStep = Msg("ctBranchStep", "ステップ「%1$s」の値が[%2$s]以上・未満で分岐");
	auto ctBranchSelectAll = Msg("ctBranchSelectAll", "パーティ全員");
	auto ctBranchSelectActive = Msg("ctBranchSelectActive", "動けるメンバ");
	auto ctBranchSelectAuto = Msg("ctBranchSelectAuto", "ランダム");
	auto ctBranchSelectManual = Msg("ctBranchSelectManual", "手動");
	auto ctBranchSelect = Msg("ctBranchSelect", "%1$sから%2$sでメンバを選択");
	auto ctBranchAbility = Msg("ctBranchAbility", "%1$s(%2$s)の%3$sと%4$sで能力判定(レベル%5$s)");
	auto ctBranchRandom = Msg("ctBranchRandom", "確率 = %1$s%%");
	auto ctBranchLevelAverage = Msg("ctBranchLevelAverage", "パーティ全員");
	auto ctBranchLevelSelected = Msg("ctBranchLevelSelected", "選択中のメンバ");
	auto ctBranchLevel = Msg("ctBranchLevel", "%1$sのレベルが%2$s以上・未満で分岐");
	auto ctBranchStatus = Msg("ctBranchStatus", "%1$sが%2$s状態か否かで分岐");
	auto ctBranchPartyNumber = Msg("ctBranchPartyNumber", "人数 = %1$s人");
	auto ctBranchArea = Msg("ctBranchArea", "エリア分岐コンテント");
	auto ctBranchBattle = Msg("ctBranchBattle", "バトル分岐コンテント");
	auto ctBranchIsBattle = Msg("ctBranchIsBattle", "戦闘中判定分岐コンテント");
	auto ctBranchCast = Msg("ctBranchCast", "キャストカード「%1$s」の同行有無で分岐");
	auto ctBranchSkill = Msg("ctBranchSkill", "特殊技能カード「%1$s」の有無で分岐(%2$sに%3$s枚)");
	auto ctBranchItem = Msg("ctBranchItem", "アイテムカード「%1$s」の有無で分岐(%2$sに%3$s枚)");
	auto ctBranchBeast = Msg("ctBranchBeast", "召喚獣カード「%1$s」の有無で分岐(%2$sに%3$s枚)");
	auto ctBranchInfo = Msg("ctBranchInfo", "情報カード「%1$s」の有無で分岐");
	auto ctBranchMoney = Msg("ctBranchMoney", "分岐金額 = %1$ssp");
	auto ctBranchCoupon = Msg("ctBranchCoupon", "称号「%1$s」の有無で分岐(%2$s)");
	auto ctBranchCompleteStamp = Msg("ctBranchCompleteStamp", "シナリオ「%1$s」が終了済みか否かで分岐");
	auto ctBranchGossip = Msg("ctBranchGossip", "ゴシップ「%1$s」の有無で分岐");
	auto ctSetFlag = Msg("ctSetFlag", "フラグ「%1$s」を[%2$s]に変更");
	auto ctSetStep = Msg("ctSetStep", "ステップ「%1$s」を[%2$s]に変更");
	auto ctSetStepUp = Msg("ctSetStepUp", "ステップ「%1$s」の値を1増加");
	auto ctSetStepDown = Msg("ctSetStepDown", "ステップ「%1$s」の値を1減少");
	auto ctReverseFlag = Msg("ctReverseFlag", "フラグ「%1$s」の値を反転");
	auto ctCheckFlag = Msg("ctCheckFlag", "フラグ「%1$s」の値が[%2$s]であれば後続のイベントが出現");
	auto ctGetCast = Msg("ctGetCast", "キャストカード「%1$s」を同行させる");
	auto ctGetSkill = Msg("ctGetSkill", "特殊技能カード「%1$s」を獲得(%2$sに%3$s枚)");
	auto ctGetItem = Msg("ctGetItem", "アイテムカード「%1$s」を獲得(%2$sに%3$s枚)");
	auto ctGetBeast = Msg("ctGetBeast", "召喚獣カード「%1$s」を獲得(%2$sに%3$s枚)");
	auto ctGetInfo = Msg("ctGetInfo", "情報カード「%1$s」を獲得");
	auto ctGetMoney = Msg("ctGetMoney", "獲得金額 = %1$ssp");
	auto ctGetCoupon = Msg("ctGetCoupon", "称号「%1$s」を獲得(%2$s)");
	auto ctGetCompleteStamp = Msg("ctGetCompleteStamp", "シナリオ%1$sを終了済みにする");
	auto ctGetGossip = Msg("ctGetGossip", "ゴシップ「%1$s」を獲得");
	auto ctLoseCardAll = Msg("ctLoseCardAll", "全て");
	auto ctLoseCardCount = Msg("ctLoseCardCount", "%1$s枚");
	auto ctLoseCast = Msg("ctLoseCast", "キャストカード「%1$s」の同行を解除");
	auto ctLoseSkill = Msg("ctLoseSkill", "特殊技能カード「%1$s」を喪失(%2$sから%3$s)");
	auto ctLoseItem = Msg("ctLoseItem", "アイテムカード「%1$s」を喪失(%2$sから%3$s)");
	auto ctLoseBeast = Msg("ctLoseBeast", "召喚獣カード「%1$s」を喪失(%2$sから%3$s)");
	auto ctLoseInfo = Msg("ctLoseInfo", "情報カード「%1$s」を喪失");
	auto ctLoseMoney = Msg("ctLoseMoney", "喪失金額 = %1$ssp");
	auto ctLoseCoupon = Msg("ctLoseCoupon", "称号「%1$s」を喪失(%2$s)");
	auto ctLoseCompleteStamp = Msg("ctLoseCompleteStamp", "シナリオ%1$sの終了印を削除");
	auto ctLoseGossip = Msg("ctLoseGossip", "ゴシップ「%1$s」を喪失");
	auto ctShowParty = Msg("ctShowParty", "パーティ表示コンテント");
	auto ctHideParty = Msg("ctHideParty", "パーティ隠蔽コンテント");
	auto ctRedisplay = Msg("ctRedisplay", "切替方式 = %1$s ウェイト = %2$s");
	auto ctRedisplayClassic = Msg("ctRedisplayClassic", "画面再構築コンテント");
	auto ctSubstituteStep = Msg("ctSubstituteStep", "ステップ [%1$s] の値をステップ [%2$s] に代入");
	auto ctSubstituteFlag = Msg("ctSubstituteFlag", "フラグ [%1$s] の値をフラグ [%2$s] に代入");
	auto ctBranchStepCmp = Msg("ctBranchStepCmp", "ステップ [%1$s] と [%2$s] の値を比較");
	auto ctBranchFlagCmp = Msg("ctBranchFlagCmp", "フラグ [%1$s] と [%2$s] の値を比較");
	auto ctSubstituteStepFromRandom = Msg("ctSubstituteStepFromRandom", "ランダム値をステップ [%1$s] に代入");
	auto ctSubstituteFlagFromRandom = Msg("ctSubstituteFlagFromRandom", "ランダム値をフラグ [%1$s] に代入");
	auto randomValue = Msg("randomValue", "[ランダム]");
	auto ctRandomSelect = Msg("ctRandomSelect", "%2$sのキャラクターを選択(%1$s)");
	auto ctRandomSelectN = Msg("ctRandomSelectN", "キャラクターを選択(%1$s)");
	auto castRange0 = Msg("castRange0", "対象無し");
	auto castRange1 = Msg("castRange1", "%1$s全体");
	auto castRange2 = Msg("castRange2", "%1$s全体または%2$s全体");
	auto castRange3 = Msg("castRange3", "フィールド全体");
	auto ctBranchKeyCodeAllType = Msg("ctBranchKeyCodeAllType", "キーコード「%1$s」を含むカードの有無で分岐(%2$s)");
	auto ctBranchKeyCode = Msg("ctBranchKeyCode", "キーコード「%1$s」を含む%2$sの有無で分岐(%3$s)");
	auto ctCheckStep = Msg("ctCheckStep", "ステップ「%1$s」が[%2$s]%3$s後続のイベントが出現");
	auto ctBranchRound = Msg("ctBranchRound", "バトルが%1$sラウンド%2$sか否かで分岐");

	auto nameWithID = Msg("nameWithID", "%1$s.%2$s");

	auto defaultStartName = Msg("defaultStartName", "イベント開始");

	auto oggMayNotCorrespond = Msg("oggMayNotCorrespond", "Oggはプレイヤーの環境によって再生できない事があります。");
	auto mp3LoopMayNotCorrespond = Msg("mp3LoopMayNotCorrespond", "MP3はプレイヤーの環境によってループ再生されない事があります。");

	/// メインウィンドウ。
	auto mainWindowName = Msg("mainWindowName", "%1$s [ %2$s ] - CWXEditor");
	auto mainWindowNameChanged = Msg("mainWindowNameChanged", "*%1$s [ %2$s ] - CWXEditor");
	auto mainWindowNameEmpty = Msg("mainWindowNameEmpty", "CWXEditor");
	auto errorExecEngine = Msg("errorExecEngine", "%1$sの起動に失敗しました。");

	/// シナリオ選択ダイアログ
	auto dlgTitNewScenario = Msg("dlgTitNewScenario", "新規シナリオの作成");
	auto dlgTitNewScenarioAtNewWin = Msg("dlgTitNewScenarioAtNewWin", "新しいウィンドウで新規シナリオの作成");
	auto dlgTitOpenScenario = Msg("dlgTitOpenScenario", "シナリオを開く");
	auto dlgTitOpenScenarioAtNewWin = Msg("dlgTitOpenScenarioAtNewWin", "新しいウィンドウでシナリオを開く");
	auto filterScenario = Msg("filterScenario", "シナリオファイル (%1$s)");
	auto filterParts = Msg("filterParts", "エリア・カードファイル (%1$s)");
	auto dlgTitSaveScenario = Msg("dlgTitSaveScenario", "名前を付けて保存");
	auto filterScenarioSave = Msg("filterScenarioSave", "XML形式のシナリオ (*.wsn)");
	auto filterScenarioSaveDir = Msg("filterScenarioSaveDir", "展開されたXML形式シナリオ (Summary.xml)");
	auto filterScenarioSaveClassic = Msg("filterScenarioSaveClassic", "クラシックシナリオ (Summary.wsm)");
	auto filterScenarioSaveZip = Msg("filterScenarioSaveZip", "ZIP圧縮されたクラシックシナリオ (*.zip)");
	auto filterScenarioSaveCab = Msg("filterScenarioSaveCab", "CAB圧縮されたクラシックシナリオ (*.cab)");
	auto warningXToClassic = Msg("warningXToClassic", "XML形式のシナリオをクラシック形式に変換すると一部データが失われる可能性がある他、対応していない形式の素材で不具合が発生する恐れがあります。\nクラシック形式で保存しますか？");
	auto saveToNotEmptyDir = Msg("saveToNotEmptyDir", "%1$sは空ではありません。\n本当にここにシナリオを保存しますか？");
	auto notScenario = Msg("notScenario", "%1$sはシナリオ圧縮ファイルではありません");
	auto zipError = Msg("zipError", "%1$sの展開に失敗しました。");
	auto loadError = Msg("loadError", "%1$sの読込みに失敗しました。");
	auto saveError = Msg("saveError", "%1$sの保存に失敗しました。");
	auto loadErrorStatus = Msg("loadErrorStatus", "%1$sの読込みに失敗");
	auto loadErrorStatusCount = Msg("loadErrorStatusCount", "%1$s件のシナリオの読込みに失敗");
	auto scenarioNotFound = Msg("scenarioNotFound", "%1$sは存在しないか、シナリオではありません。履歴から削除しますか？");

	/// データウィンドウ
	auto dataTabName = Msg("dataTabName", "データ");
	auto dataWindowName = Msg("dataWindowName", "データ - [ %1$s ] - %2$s");
	auto areasTabName = Msg("areasTabName", "テーブル");
	auto areasWindowName = Msg("areasWindowName", "テーブル - [ %1$s ] - %2$s");
	auto areaStatus = Msg("areaStatus", "%2$s件の%1$s");
	auto flagTabName = Msg("flagTabName", "状態変数");
	auto flagWindowName = Msg("flagWindowName", "状態変数 - [ %1$s ] - %2$s");
	auto flagStatus = Msg("flagStatus", "%2$s個の%1$s");
	auto flagStatusSel = Msg("flagStatusSel", "%1$s (%2$s個を選択)");
	auto scenarioView = Msg("scenarioView", "シナリオビューリスト");
	auto variableView = Msg("variableView", "状態変数インスペクタ");

	auto reNumberingAll = Msg("reNumberingAll", "全てのエリアやカードのIDの1から振り直します。\nよろしいですか？");

	auto dlgTitReNumbering = Msg("dlgTitReNumbering", "IDの振り直し");
	auto reNumbering = Msg("reNumbering", "IDの振り直し");
	auto reNumbering1 = Msg("reNumbering1", "%1$s「%2$s」以降のIDを");
	auto reNumbering2 = Msg("reNumbering2", "番から順に振り直す"); // reNumbering1と同様のパラメータを取る

	/// エリアのテーブル。
	auto areaId = Msg("areaId", "ID");
	auto areaName = Msg("areaName", "名称");
	auto areaCount = Msg("areaCount", "利用数");
	auto areaNew = Msg("areaNew", "新規エリア");
	auto battleNew = Msg("battleNew", "新規バトル");
	auto packageNew = Msg("packageNew", "新規パッケージ");

	/// フラグのディレクトリ。
	auto flagDirRoot = Msg("flagDirRoot", "Data");
	auto flagDirNew = Msg("flagDirNew", "新規フォルダ");

	/// フラグ/ステップのテーブル。
	auto flagName = Msg("flagName", "名称");
	auto flagInit = Msg("flagInit", "初期値");
	auto flagCount = Msg("flagCount", "利用数");

	/// フラグ設定ダイアログ関連。
	auto dlgTitFlag = Msg("dlgTitFlag", "フラグの設定");
	auto dlgLblFlagName = Msg("dlgLblFlagName", "フラグ名");
	auto dlgLblFlagInit = Msg("dlgLblFlagInit", "初期値");
	auto dlgLblFlagTrue = Msg("dlgLblFlagTrue", "TRUE");
	auto dlgLblFlagFalse = Msg("dlgLblFlagFalse", "FALSE");

	/// ステップ設定ダイアログ関連。
	auto dlgTitStep = Msg("dlgTitStep", "ステップの設定");
	auto dlgLblStepName = Msg("dlgLblStepName", "ステップ名");
	auto dlgLblStepInit = Msg("dlgLblStepInit", "初期値");
	auto dlgLblStep = Msg("dlgLblStep", "Step - %1$s");
	auto dlgTxtStep = Msg("dlgTxtStep", "Step - %1$s");

	/// 貼り紙設定ダイアログ関連。
	auto dlgTitSummary = Msg("dlgTitSummary", "概略の設定 - [ %1$s ]");
	auto summaryPreview = Msg("summaryPreview", "表示イメージ");
	auto baseData = Msg("baseData", "基本データ");
	auto etcData = Msg("etcData", "詳細データ");
	auto targetLevelSame = Msg("targetLevelSame", "対象レベル %1$s");
	auto targetLevelHL = Msg("targetLevelHL", "対象レベル %1$s～%2$s");
	auto targetLevelL = Msg("targetLevelL", "対象レベル %1$s～");
	auto targetLevelH = Msg("targetLevelH", "対象レベル ～%1$s");
	auto summaryPageDummy = Msg("summaryPageDummy", "1/1");
	auto title = Msg("title", "シナリオタイトル");
	auto author = Msg("author", "作者名");
	auto targetLevel = Msg("targetLevel", "対象レベル");
	auto desc = Msg("desc", "解説");
	auto levSep = Msg("levSep", "～");
	auto qualification = Msg("qualification", "シナリオ出現条件");
	auto rCouponNum = Msg("rCouponNum", "必要数");
	auto rCoupons = Msg("rCoupons", "必要とする称号");
	auto startArea = Msg("startArea", "シナリオ開始エリア");

	auto scenarioType = Msg("scenarioType", "シナリオタイプ");
	auto sTypeXML = Msg("sTypeXML", "スキンを指定");
	auto sTypeClassic = Msg("sTypeClassic", "クラシックエンジンを使用");
	auto currentEngineSkin = Msg("currentEngineSkin", "[%1$s]");

	auto pngMayNotCorrespond = Msg("pngMayNotCorrespond", "PNGイメージはプレイヤーの環境によって表示エラーとなる事があります。");
	auto gifMayNotCorrespond = Msg("gifMayNotCorrespond", "GIFイメージはプレイヤーの環境によって表示エラーとなる事があります。");

	/// エリア・戦闘・パッケージウィンドウ。
	auto noRefArea = Msg("noRefArea", "[カード配置参照無し]");
	auto areaViewFlagDesc = Msg("areaViewFlagDesc", "フラグ");
	auto areaViewRefAreaDesc = Msg("areaViewRefAreaDesc", "参照");
	auto refFlags = Msg("refFlags", "参照フラグ");
	auto allCheckFlag = Msg("allCheckFlag", "全てTRUE/全てFALSE");

	auto left = Msg("left", "X");
	auto top = Msg("top", "Y");
	auto width = Msg("width", "幅");
	auto height = Msg("height", "高");
	auto scale = Msg("scale", "拡大率");

	auto areaViewStatus = Msg("areaViewStatus", "%1$s [%2$s] - %3$s");
	auto areaViewStatusNoSummary = Msg("areaViewStatusNoSummary", "%1$s [%2$s]");
	auto areaViewStatusNoFlag = Msg("areaViewStatusNoFlag", "フラグ指定無し");
	auto areaViewStatusInvalidFlag = Msg("areaViewStatusInvalidFlag", "存在しないフラグ(%1$s)");
	auto areaViewStatusWithFlag = Msg("areaViewStatusWithFlag", "フラグ = %1$s");
	auto areaViewStatusImageIncluding = Msg("areaViewStatusImageIncluding", "イメージ格納");
	auto areaViewStatusSelCard = Msg("areaViewStatusSelCard", "%1$s枚のカード");
	auto areaViewStatusSelBack = Msg("areaViewStatusSelBack", "%1$s枚の背景");
	auto areaViewStatusEnemyCard = Msg("areaViewStatusEnemyCard", "%1$s.%2$s");

	auto viewNameTab = Msg("viewNameTab", "%2$s.%3$s");
	auto viewNameSceneTab = Msg("viewNameSceneTab", "%2$s.%3$s");
	auto viewNameEventTab = Msg("viewNameEventTab", "%2$s.%3$s");
	auto viewName = Msg("viewName", "[%1$s] - %2$s - %3$s");
	auto viewNameScene = Msg("viewNameScene", "[%1$s カードと背景] - %2$s - %3$s");
	auto viewNameEvent = Msg("viewNameEvent", "[%1$s イベント] - %2$s - %3$s");

	auto cardCount = Msg("cardCount", "利用数");

	auto cardAndBackView = Msg("cardAndBackView", "カードと背景");
	auto enemyCardView = Msg("enemyCardView", "エネミーカード");
	auto menuCards = Msg("menuCards", "カード");
	auto enemyCards = Msg("enemyCards", "カード");
	auto backs = Msg("backs", "背景");
	auto eventView = Msg("eventView", "イベント");
	auto menuCard = Msg("menuCard", "メニューカード");
	auto enemyCard = Msg("enemyCard", "エネミーカード");
	auto back = Msg("back", "背景画像");
	auto textCell = Msg("textCell", "テキストセル");
	auto colorCell = Msg("colorCell", "カラーセル");

	/// カード/背景配置領域関連。
	auto dlgTitDropCard = Msg("dlgTitDropCard", "カード画像の追加");
	auto dlgMsgDropCard = Msg("dlgMsgDropCard", "カード画像をシナリオ" ~ DIR ~ "にコピーしますか？\n%1$s");
	auto dlgTitDropBack = Msg("dlgTitDropBack", "背景画像の追加");
	auto dlgMsgDropBack = Msg("dlgMsgDropBack", "背景画像をシナリオ" ~ DIR ~ "にコピーしますか？\n%1$s");

	auto refFlag = Msg("refFlag", "フラグ参照先");
	auto refStep = Msg("refStep", "ステップ参照先");
	auto noFlagRef = Msg("noFlagRef", "[参照無し]");
	auto cardPosition = Msg("cardPosition", "カード位置");
	auto backPosition = Msg("backPosition", "位置");
	auto bgImageSettings = Msg("bgImageSettings", "簡単設定");
	auto bgImageSettingCustom = Msg("bgImageSettingCustom", "[カスタム]");
	auto bgImageSettingOriginal = Msg("bgImageSettingOriginal", "[元のサイズ]");
	auto enemyCardBase = Msg("enemyCardBase", "基本設定");
	auto dlgTitMenuCard = Msg("dlgTitMenuCard", "メニューカードの設定 [ %1$s ]");
	auto dlgTitNewMenuCard = Msg("dlgTitNewMenuCard", "メニューカードの作成");
	auto dlgTitBgImage = Msg("dlgTitBgImage", "背景画像の設定");
	auto dlgTitNewBgImage = Msg("dlgTitNewBgImage", "背景画像の作成");
	auto dlgTitTextCell = Msg("dlgTitTextCell", "テキストセルの設定");
	auto dlgTitNewTextCell = Msg("dlgTitNewTextCell", "テキストセルの作成");
	auto dlgTitColorCell = Msg("dlgTitColorCell", "カラーセルの設定");
	auto dlgTitNewColorCell = Msg("dlgTitNewColorCell", "カラーセルの作成");
	auto dlgTitEnemyCard = Msg("dlgTitEnemyCard", "エネミーカードの設定 [ %1$s ]");
	auto dlgTitNewEnemyCard = Msg("dlgTitNewEnemyCard", "エネミーカードの作成");
	auto alphaChannel = Msg("alphaChannel", "不透明度:");
	auto blendMode = Msg("blendMode", "合成方法");
	auto colorCellBaseColor = Msg("colorCellBaseColor", "基本色");
	auto gradient = Msg("gradient", "グラデーション");
	auto direction = Msg("direction", "方向:");
	auto endColor = Msg("endColor", "終端色");
	auto text = Msg("text", "テキスト");
	auto font = Msg("font", "フォント");
	auto size = Msg("size", "サイズ:");
	auto pixel = Msg("pixel", "ピクセル");
	auto fontColor = Msg("fontColor", "テキスト色");
	auto fontStyle = Msg("fontStyle", "書式");
	auto bold = Msg("bold", "太字");
	auto italic = Msg("italic", "斜体");
	auto underline = Msg("underline", "下線");
	auto strike = Msg("strike", "取り消し線");
	auto vertical = Msg("vertical", "縦書き");
	auto bordering = Msg("bordering", "縁取り");
	auto borderingWidth = Msg("borderingWidth", "幅:");
	auto borderingColor = Msg("borderingColor", "縁取り色");

	/// イベントビュー。
	auto tools = Msg("tools", "イベントコンテント");
	auto startEnter = Msg("startEnter", "到着");
	auto startSelect = Msg("startSelect", "クリック");
	auto startDead = Msg("startDead", "死亡");
	auto startVictory = Msg("startVictory", "勝利");
	auto startEscape = Msg("startEscape", "逃走");
	auto startLose = Msg("startLose", "敗北");
	auto startEveryRound = Msg("startEveryRound", "毎ラウンド");
	auto startRound0 = Msg("startRound0", "バトル開始");
	auto startPackage = Msg("startPackage", "パッケージ");
	auto startUse = Msg("startUse", "使用時");
	auto startRound = Msg("startRound", "ラウンド = %1$s");
	auto keyCodeTimingUse = Msg("keyCodeTimingUse", "使用");
	auto keyCodeTimingSuccess = Msg("keyCodeTimingSuccess", "成功");
	auto keyCodeTimingFailure = Msg("keyCodeTimingFailure", "失敗");
	auto keyCodeTimingHasNot = Msg("keyCodeTimingHasNot", "不保有");

	auto manyRounds = Msg("manyRounds", "追加する発火ラウンドの範囲");
	auto dlgTitAddManyRounds = Msg("dlgTitAddManyRounds", "追加する発火ラウンドの範囲");
	auto roundSep = Msg("roundSep", "～");

	auto enterTree = Msg("enterTree", "到着");
	auto selectTree = Msg("selectTree", "クリック");
	auto deadTree = Msg("deadTree", "死亡");
	auto victoryTree = Msg("victoryTree", "勝利");
	auto escapeTree = Msg("escapeTree", "逃走");
	auto loseTree = Msg("loseTree", "敗北");
	auto everyRoundTree = Msg("everyRoundTree", "毎ラウンド");
	auto round0Tree = Msg("round0Tree", "バトル開始");
	auto packageTree = Msg("packageTree", "パッケージイベント");
	auto useTree = Msg("useTree", "使用時イベント");
	auto keyCodeTree = Msg("keyCodeTree", "[%1$s]");
	auto roundTree = Msg("roundTree", "ラウンド %1$s");

	auto eventTreeKindSystem = Msg("eventTreeKindSystem", "システム");
	auto eventTreeKindKeyCode = Msg("eventTreeKindKeyCode", "キーコード");
	auto eventTreeKindRound = Msg("eventTreeKindRound", "ラウンド");

	auto startUseCount = Msg("startUseCount", "利用数");

	auto flagOn = Msg("flagOn", "TRUE");
	auto flagOff = Msg("flagOff", "FALSE");
	auto evtChildBrVar = Msg("evtChildBrVar", "%1$s = %2$s");
	auto etc = Msg("etc", "その他");
	auto stepMoreThan = Msg("stepMoreThan", "ステップ「%1$s」が「%2$s」以上");
	auto stepLessThan = Msg("stepLessThan", "ステップ「%1$s」が「%2$s」未満");
	auto partyAll = Msg("partyAll", "パーティ全員");
	auto partyActive = Msg("partyActive", "動けるメンバ");
	auto autoSelect = Msg("autoSelect", "自動");
	auto manualSelect = Msg("manualSelect", "手動");
	auto selectMemberSuccess = Msg("selectMemberSuccess", "%1$sから%2$sでキャラクターを選択");
	auto selectMemberFailure = Msg("selectMemberFailure", "%1$sから%2$sでのキャラクター選択をキャンセル");
	auto branchAbilitySuccess = Msg("branchAbilitySuccess", "%1$sがレベル%2$sで%3$sと%4$sで行う判定に成功");
	auto branchAbilityFailure = Msg("branchAbilityFailure", "%1$sがレベル%2$sで%3$sと%4$sで行う判定に失敗");
	auto branchRandomSuccess = Msg("branchRandomSuccess", "%1$s%%成功");
	auto branchRandomFailure = Msg("branchRandomFailure", "%1$s%%失敗");
	auto levelAverage = Msg("levelAverage", "パーティ全員の平均値");
	auto levelSelected = Msg("levelSelected", "選択中のメンバ");
	auto branchLevelSuccess = Msg("branchLevelSuccess", "%1$sがレベル%2$s以上");
	auto branchLevelFailure = Msg("branchLevelFailure", "%1$sがレベル%2$s未満");
	auto branchStatusSuccess = Msg("branchStatusSuccess", "%1$sでの「%2$s」の判定に成功");
	auto branchStatusFailure = Msg("branchStatusFailure", "%1$sでの「%2$s」の判定に失敗");
	auto branchNumberSuccess = Msg("branchNumberSuccess", "パーティに%1$s人以上いる");
	auto branchNumberFailure = Msg("branchNumberFailure", "パーティは%1$s人未満");
	auto branchArea = Msg("branchArea", "エリア = %1$s");
	auto branchBattle = Msg("branchBattle", "バトル = %1$s");
	auto branchOnBattleSuccess = Msg("branchOnBattleSuccess", "イベント発生時の状況が戦闘中");
	auto branchOnBattleFailure = Msg("branchOnBattleFailure", "イベント発生時の状況が戦闘中以外");
	auto branchCastSuccess = Msg("branchCastSuccess", "「%1$s」が加わっている");
	auto branchCastFailure = Msg("branchCastFailure", "「%1$s」が加わっていない");
	auto branchEffectCardSuccess = Msg("branchEffectCardSuccess", "「%2$s」を所有している(%1$s)");
	auto branchEffectCardFailure = Msg("branchEffectCardFailure", "「%2$s」を所有していない(%1$s)");
	auto branchInfoSuccess = Msg("branchInfoSuccess", "「%1$s」を所有している");
	auto branchInfoFailure = Msg("branchInfoFailure", "「%1$s」を所有していない");
	auto branchMoneySuccess = Msg("branchMoneySuccess", "%1$ssp以上所持している");
	auto branchMoneyFailure = Msg("branchMoneyFailure", "%1$ssp以上所持していない");
	auto branchCouponSuccess = Msg("branchCouponSuccess", "クーポン「%2$s」を所有している(%1$s)");
	auto branchCouponFailure = Msg("branchCouponFailure", "クーポン「%2$s」を所有していない(%1$s)");
	auto branchCompleteSuccess = Msg("branchCompleteSuccess", "シナリオ「%1$s」が終了済みである");
	auto branchCompleteFailure = Msg("branchCompleteFailure", "シナリオ「%1$s」が終了済みでない");
	auto branchGossipSuccess = Msg("branchGossipSuccess", "ゴシップ「%1$s」が宿屋にある");
	auto branchGossipFailure = Msg("branchGossipFailure", "ゴシップ「%1$s」が宿屋に無い");
	auto branchStepCmpGreater = Msg("branchStepCmpGreater", "ステップ「%1$s」が「%2$s」より大きい");
	auto branchStepCmpLesser = Msg("branchStepCmpLesser", "ステップ「%1$s」が「%2$s」より小さい");
	auto branchStepCmpEq = Msg("branchStepCmpEq", "ステップ「%1$s」が「%2$s」と同値");
	auto branchFlagCmpNotEq = Msg("branchFlagCmpNotEq", "フラグ「%1$s」と「%2$s」の値が異なる");
	auto branchFlagCmpEq = Msg("branchFlagCmpEq", "フラグ「%1$s」が「%2$s」と同値");
	auto branchRandomSelectSuccess = Msg("branchRandomSelectSuccess", "%2$sのキャラクターを選択(%1$s)");
	auto branchRandomSelectFailure = Msg("branchRandomSelectFailure", "%2$sのキャラクター選択に失敗(%1$s)");
	auto branchRandomSelectSuccessN = Msg("branchRandomSelectSuccessN", "キャラクターを選択(%1$s)");
	auto branchRandomSelectFailureN = Msg("branchRandomSelectFailureN", "キャラクター選択に失敗(%1$s)");
	auto randomSelectCondition1 = Msg("randomSelectCondition1", "レベル%1$s～%2$s");
	auto randomSelectCondition2 = Msg("randomSelectCondition2", "状態が%1$s");
	auto randomSelectCondition3 = Msg("randomSelectCondition3", "レベル%1$s～%2$sで状態が%3$s");
	auto branchKeyCodeAllTypeSuccess = Msg("branchKeyCodeAllTypeSuccess", "キーコード「%1$s」を含むカードを所有している(%2$s)");
	auto branchKeyCodeAllTypeFailure = Msg("branchKeyCodeAllTypeFailure", "キーコード「%1$s」を含むカードを所有していない(%2$s)");
	auto branchKeyCodeSuccess = Msg("branchKeyCodeSuccess", "キーコード「%1$s」を含む%2$sを所有している(%3$s)");
	auto branchKeyCodeFailure = Msg("branchKeyCodeFailure", "キーコード「%1$s」を含む%2$sを所有していない(%3$s)");
	auto branchRound = Msg("branchRound", "バトルが%1$sラウンド%2$s");

	const string physicalName(Physical id) {
		mixin(EnumToStringSwitch!(Physical, "physicalName"));
	}
	auto physicalNameDex = Msg("physicalNameDex", "器用度");
	auto physicalNameAgl = Msg("physicalNameAgl", "敏捷度");
	auto physicalNameInt = Msg("physicalNameInt", "知力");
	auto physicalNameStr = Msg("physicalNameStr", "筋力");
	auto physicalNameVit = Msg("physicalNameVit", "生命力");
	auto physicalNameMin = Msg("physicalNameMin", "精神力");
	const string mentalName(Mental id) {
		mixin(EnumToStringSwitch!(Mental, "mentalName"));
	}
	auto mentalNameAggressive = Msg("mentalNameAggressive", "好戦性");
	auto mentalNameUnaggressive = Msg("mentalNameUnaggressive", "平和性");
	auto mentalNameCheerful = Msg("mentalNameCheerful", "社交性");
	auto mentalNameUncheerful = Msg("mentalNameUncheerful", "内向性");
	auto mentalNameBrave = Msg("mentalNameBrave", "勇猛性");
	auto mentalNameUnbrave = Msg("mentalNameUnbrave", "臆病性");
	auto mentalNameCautious = Msg("mentalNameCautious", "慎重性");
	auto mentalNameUncautious = Msg("mentalNameUncautious", "大胆性");
	auto mentalNameTrickish = Msg("mentalNameTrickish", "狡猾性");
	auto mentalNameUntrickish = Msg("mentalNameUntrickish", "正直性");
	const string statusName(Status id) {
		mixin(EnumToStringSwitch!(Status, "statusName"));
	}
	auto statusNameActive = Msg("statusNameActive", "行動可能");
	auto statusNameInactive = Msg("statusNameInactive", "行動不可");
	auto statusNameAlive = Msg("statusNameAlive", "生存");
	auto statusNameDead = Msg("statusNameDead", "非生存");
	auto statusNameFine = Msg("statusNameFine", "健康");
	auto statusNameInjured = Msg("statusNameInjured", "負傷");
	auto statusNameHeavyInjured = Msg("statusNameHeavyInjured", "重傷");
	auto statusNameUnconscious = Msg("statusNameUnconscious", "意識不明");
	auto statusNamePoison = Msg("statusNamePoison", "中毒");
	auto statusNameSleep = Msg("statusNameSleep", "眠り");
	auto statusNameBind = Msg("statusNameBind", "呪縛");
	auto statusNameParalyze = Msg("statusNameParalyze", "麻痺/石化");
	auto statusNameConfuse = Msg("statusNameConfuse", "混乱");
	auto statusNameOverheat = Msg("statusNameOverheat", "激昂");
	auto statusNameBrave = Msg("statusNameBrave", "勇敢");
	auto statusNamePanic = Msg("statusNamePanic", "恐慌");
	auto statusNameSilence = Msg("statusNameSilence", "沈黙");
	auto statusNameFaceUp = Msg("statusNameFaceUp", "暴露");
	auto statusNameAntiMagic = Msg("statusNameAntiMagic", "魔法無効化");
	auto statusNameUpAction = Msg("statusNameUpAction", "行動力上昇");
	auto statusNameUpAvoid = Msg("statusNameUpAvoid", "回避力上昇");
	auto statusNameUpResist = Msg("statusNameUpResist", "抵抗力上昇");
	auto statusNameUpDefense = Msg("statusNameUpDefense", "防御力上昇");
	auto statusNameDownAction = Msg("statusNameDownAction", "行動力低下");
	auto statusNameDownAvoid = Msg("statusNameDownAvoid", "回避力低下");
	auto statusNameDownResist = Msg("statusNameDownResist", "抵抗力低下");
	auto statusNameDownDefense = Msg("statusNameDownDefense", "防御力低下");
	auto statusNameNone = Msg("statusNameNone", "状態指定無し");
	auto effectTypeElement = Msg("effectTypeElement", "%1$s属性");
	const string effectTypeName(EffectType id) {
		mixin(EnumToStringSwitch!(EffectType, "effectTypeName"));
	}
	auto effectTypeNamePhysic = Msg("effectTypeNamePhysic", "物理");
	auto effectTypeNameMagic = Msg("effectTypeNameMagic", "魔法");
	auto effectTypeNameMagicalPhysic = Msg("effectTypeNameMagicalPhysic", "魔法的物理");
	auto effectTypeNamePhysicalMagic = Msg("effectTypeNamePhysicalMagic", "物理的魔法");
	auto effectTypeNameNone = Msg("effectTypeNameNone", "無");
	const string effectTypeDesc(EffectType id) {
		mixin(EnumToStringSwitch!(EffectType, "effectTypeDesc"));
	}
	auto effectTypeDescPhysic = Msg("effectTypeDescPhysic", "武器が効かない存在には無効");
	auto effectTypeDescMagic = Msg("effectTypeDescMagic", "魔法が効かない存在には無効");
	auto effectTypeDescMagicalPhysic = Msg("effectTypeDescMagicalPhysic", "武器と魔法の両方が効かない存在には無効");
	auto effectTypeDescPhysicalMagic = Msg("effectTypeDescPhysicalMagic", "武器と魔法のどちらかが効かない存在には無効");
	auto effectTypeDescNone = Msg("effectTypeDescNone", "全ての存在に有効");
	const string resistName(Resist id) {
		mixin(EnumToStringSwitch!(Resist, "resistName"));
	}
	auto resistNameAvoid = Msg("resistNameAvoid", "回避属性");
	auto resistNameResist = Msg("resistNameResist", "抵抗属性");
	auto resistNameUnfail = Msg("resistNameUnfail", "必中属性");
	const string resistDesc(Resist id) {
		mixin(EnumToStringSwitch!(Resist, "resistDesc"));
	}
	auto resistDescAvoid = Msg("resistDescAvoid", "回避された場合は効果無し");
	auto resistDescResist = Msg("resistDescResist", "抵抗された場合は効果半減");
	auto resistDescUnfail = Msg("resistDescUnfail", "絶対成功");
	const string cardTargetName(CardTarget id) {
		mixin(EnumToStringSwitch!(CardTarget, "cardTargetName"));
	}
	auto cardTargetNameNone = Msg("cardTargetNameNone", "対象無し");
	auto cardTargetNameUser = Msg("cardTargetNameUser", "使用者");
	auto cardTargetNameParty = Msg("cardTargetNameParty", "味方");
	auto cardTargetNameEnemy = Msg("cardTargetNameEnemy", "敵方");
	auto cardTargetNameBoth = Msg("cardTargetNameBoth", "双方");
	auto cardTargetOne = Msg("cardTargetOne", "一体");
	auto cardTargetAll = Msg("cardTargetAll", "全体");
	const string cardVisualName(CardVisual id) {
		mixin(EnumToStringSwitch!(CardVisual, "cardVisualName"));
	}
	auto cardVisualNameNone = Msg("cardVisualNameNone", "視覚効果無し");
	auto cardVisualNameReverse = Msg("cardVisualNameReverse", "対象を反転");
	auto cardVisualNameHorizontal = Msg("cardVisualNameHorizontal", "対象を横に震動");
	auto cardVisualNameVertical = Msg("cardVisualNameVertical", "対象を縦に震動");
	const string premiumName(Premium id) {
		mixin(EnumToStringSwitch!(Premium, "premiumName"));
	}
	auto premiumNameNormal = Msg("premiumNameNormal", "日用品 (買戻し不可/破棄可)");
	auto premiumNameRare = Msg("premiumNameRare", "希少品 (買戻し可/破棄可)");
	auto premiumNamePremium = Msg("premiumNamePremium", "貴重品 (買戻し可/破棄不可)");
	const string enhanceName(Enhance id) {
		mixin(EnumToStringSwitch!(Enhance, "enhanceName"));
	}
	auto enhanceNameAction = Msg("enhanceNameAction", "行動");
	auto enhanceNameAvoid = Msg("enhanceNameAvoid", "回避");
	auto enhanceNameResist = Msg("enhanceNameResist", "抵抗");
	auto enhanceNameDefense = Msg("enhanceNameDefense", "防御");
	auto mentality = Msg("mentality", "精神状態");
	const string mentalityName(Mentality id) {
		mixin(EnumToStringSwitch!(Mentality, "mentalityName"));
	}
	auto mentalityNameNormal = Msg("mentalityNameNormal", "正常");
	auto mentalityNameSleep = Msg("mentalityNameSleep", "睡眠");
	auto mentalityNameConfuse = Msg("mentalityNameConfuse", "混乱");
	auto mentalityNameOverheat = Msg("mentalityNameOverheat", "激昂");
	auto mentalityNameBrave = Msg("mentalityNameBrave", "勇敢");
	auto mentalityNamePanic = Msg("mentalityNamePanic", "恐慌");

	auto enhanceBonus = Msg("enhanceBonus", "%1$sボーナス");
	auto statusActive = Msg("statusActive", "※ 行動可能 = (健康 | 負傷 | 重傷 | 中毒)");
	auto statusInactive = Msg("statusInactive", "※ 行動不可 = (意識不明 | 麻痺/石化 | 呪縛 | 眠り)");
	auto statusAlive = Msg("statusAlive", "※ 生存 = (健康 | 負傷 | 重傷 | 中毒 | 呪縛 | 眠り)");
	auto statusDead = Msg("statusDead", "※ 非生存 = (意識不明 | 麻痺/石化)");
	const string targetName(Target.M id) {
		mixin(EnumToStringSwitch2!(Target.M, "Target.M", "targetName"));
	}
	auto targetNameSelected = Msg("targetNameSelected", "選択中のメンバ");
	auto targetNameUnselected = Msg("targetNameUnselected", "選択中以外のメンバ");
	auto targetNameRandom = Msg("targetNameRandom", "誰か一人");
	auto targetNameParty = Msg("targetNameParty", "パーティ全員");
	const string talkerName(Talker id) {
		mixin(EnumToStringSwitch!(Talker, "talkerName"));
	}
	auto talkerNameSelected = Msg("talkerNameSelected", "[選択中]");
	auto talkerNameUnselected = Msg("talkerNameUnselected", "[選択中以外]");
	auto talkerNameRandom = Msg("talkerNameRandom", "[ランダム]");
	auto talkerNameCard = Msg("talkerNameCard", "[カード]");
	auto talkerNameNarration = Msg("talkerNameNarration", "[話者無し]");
	auto talkerNameImage = Msg("talkerNameImage", "[画像]");
	auto talkerNameValued = Msg("talkerNameValued", "[評価メンバ]");
	const string rangeName(Range id) {
		mixin(EnumToStringSwitch!(Range, "rangeName"));
	}
	auto rangeNameSelected = Msg("rangeNameSelected", "現在選択中のメンバ");
	auto rangeNameRandom = Msg("rangeNameRandom", "パーティの誰か一人");
	auto rangeNameParty = Msg("rangeNameParty", "パーティの全員");
	auto rangeNameBackpack = Msg("rangeNameBackpack", "荷物袋");
	auto rangeNamePartyAndBackpack = Msg("rangeNamePartyAndBackpack", "全体(荷物袋含む)");
	auto rangeNameField = Msg("rangeNameField", "フィールド全体");
	const string castRangeName(CastRange id) {
		mixin(EnumToStringSwitch!(CastRange, "castRangeName"));
	}
	auto castRangeNameParty = Msg("castRangeNameParty", "パーティ");
	auto castRangeNameEnemy = Msg("castRangeNameEnemy", "敵");
	auto castRangeNameNpc = Msg("castRangeNameNpc", "同行キャスト");
	const string damageTypeName(DamageType id) {
		mixin(EnumToStringSwitch!(DamageType, "damageTypeName"));
	}
	auto damageTypeNameLevelRatio = Msg("damageTypeNameLevelRatio", "レベルに対応する値");
	auto damageTypeNameNormal = Msg("damageTypeNameNormal", "値の直接入力");
	auto damageTypeNameMax = Msg("damageTypeNameMax", "最大値処理");
	const string elementName(Element id) {
		mixin(EnumToStringSwitch!(Element, "elementName"));
	}
	auto elementNameAll = Msg("elementNameAll", "全");
	auto elementNameHealth = Msg("elementNameHealth", "肉体");
	auto elementNameMind = Msg("elementNameMind", "精神");
	auto elementNameMiracle = Msg("elementNameMiracle", "神聖");
	auto elementNameMagic = Msg("elementNameMagic", "魔力");
	auto elementNameFire = Msg("elementNameFire", "炎");
	auto elementNameIce = Msg("elementNameIce", "冷気");
	const string elementDesc(Element id) {
		mixin(EnumToStringSwitch!(Element, "elementDesc"));
	}
	auto elementDescAll = Msg("elementDescAll", "全ての存在に有効");
	auto elementDescHealth = Msg("elementDescHealth", "肉体を持つ存在に有効");
	auto elementDescMind = Msg("elementDescMind", "精神を持つ存在に有効");
	auto elementDescMiracle = Msg("elementDescMiracle", "不浄な存在に有効");
	auto elementDescMagic = Msg("elementDescMagic", "魔法的な存在に有効");
	auto elementDescFire = Msg("elementDescFire", "炎が無効でない存在に有効");
	auto elementDescIce = Msg("elementDescIce", "冷気が無効でない存在に有効");

	const string sexName(Sex id) {
		mixin(EnumToStringSwitch!(Sex, "sexName"));
	}
	auto sexNameMale = Msg("sexNameMale", "男/♂");
	auto sexNameFemale = Msg("sexNameFemale", "女/♀");
	auto sexUnknown = Msg("sexUnknown", "謎/？");
	auto periodUnknown = Msg("periodUnknown", "不明");
	auto natureUnknown = Msg("natureUnknown", "その他");

	const string effectCardTypeName(EffectCardType id) {
		mixin(EnumToStringSwitch!(EffectCardType, "effectCardTypeName"));
	}
	auto effectCardTypeNameAll = Msg("effectCardTypeNameAll", "全てのカード");
	auto effectCardTypeNameSkill = Msg("effectCardTypeNameSkill", "特殊技能カード");
	auto effectCardTypeNameItem = Msg("effectCardTypeNameItem", "アイテムカード");
	auto effectCardTypeNameBeast = Msg("effectCardTypeNameBeast", "召喚獣カード");

	const string comparison4Name(Comparison4 id) {
		mixin(EnumToStringSwitch!(Comparison4, "comparison4Name"));
	}
	auto comparison4NameEq = Msg("comparison4NameEq", "であれば");
	auto comparison4NameNe = Msg("comparison4NameNe", "でなければ");
	auto comparison4NameLt = Msg("comparison4NameLt", "より大きければ");
	auto comparison4NameGt = Msg("comparison4NameGt", "より小さければ");

	const string comparison3Name(Comparison3 id) {
		mixin(EnumToStringSwitch!(Comparison3, "comparison3Name"));
	}
	auto comparison3NameEq = Msg("comparison3NameEq", "である");
	auto comparison3NameLt = Msg("comparison3NameLt", "より大きい");
	auto comparison3NameGt = Msg("comparison3NameGt", "より小さい");

	const string comparison3FalseName(Comparison3 id) {
		mixin(EnumToStringSwitch!(Comparison3, "comparison3FalseName"));
	}
	auto comparison3FalseNameEq = Msg("comparison3FalseNameEq", "ではない");
	auto comparison3FalseNameLt = Msg("comparison3FalseNameLt", "以下");
	auto comparison3FalseNameGt = Msg("comparison3FalseNameGt", "以上");

	auto dlgTitComment = Msg("dlgTitComment", "コメントの記述");

	/// カードウィンドウ。
	auto mainCardWindowName = Msg("mainCardWindowName", "カード - [ %1$s ] - %2$s");
	auto mainCardWindowNameNoSummary = Msg("mainCardWindowNameNoSummary", "カード");
	auto mainCardTabName = Msg("mainCardTabName", "カード");
	auto cardWindowName = Msg("cardWindowName", "%1$s - [ %2$s ] - %3$s");
	auto cardWindowNameNoSummary = Msg("cardWindowNameNoSummary", "%1$s");
	auto cardTabName = Msg("cardTabName", "%1$s");
	auto handCardWindowName = Msg("handCardWindowName", "[所有カード] - %1$s.%2$s");
	auto handCardTabName = Msg("handCardTabName", "%1$s.%2$s");
	auto importSourceWindowName = Msg("importSourceWindowName", "カードのインポート - [ %1$s ] - %2$s");
	auto importSourceTabName = Msg("importSourceTabName", "%1$s");
	auto cardTitle = Msg("cardTitle", "%1$s.%2$s");

	auto dlgTitAddScenario = Msg("dlgTitAddScenario", "インポート元の選択");

	auto importLinkCondition = Msg("importLinkCondition", "参照先のカードを");
	auto importLinkConditionNoChange = Msg("importLinkConditionNoChange", "参照のままにする");
	auto importLinkConditionInclude = Msg("importLinkConditionInclude", "インポート時に格納する");

	auto cardStatus = Msg("cardStatus", "%1$s枚のカード");
	auto cardStatusSelOne = Msg("cardStatusSelOne", "%1$s枚のカード (ID = %2$s)");
	auto cardStatusSelMulti = Msg("cardStatusSelMulti", "%1$s枚のカード (%2$s枚を選択中)");
	auto handCardStatus = Msg("handCardStatus", "%1$s枚のカード (有効枚数 = %2$s)");
	auto handCardStatusSelOne = Msg("handCardStatusSelOne", "%1$s枚のカード (有効枚数 = %2$s) (ID = %3$s)");
	auto handCardStatusSelMulti = Msg("handCardStatusSelMulti", "%1$s枚のカード (有効枚数 = %2$s) (%3$s枚を選択中)");

	auto cwCast = Msg("cwCast", "キャスト");
	auto skill = Msg("skill", "特殊技能");
	auto item = Msg("item", "アイテム");
	auto beast = Msg("beast", "召喚獣");
	auto info = Msg("info", "情報");

	auto noSelectImage = Msg("noSelectImage", "(指定無し)");
	auto noImage = Msg("noImage", "存在しないイメージ(パス:%1$s)");
	auto noSelectBGM = Msg("noSelectBGM", "(指定無し)");
	auto noBGM = Msg("noBGM", "存在しないBGM(パス:%1$s)");
	auto noSelectSE = Msg("noSelectSE", "(指定無し)");
	auto noSE = Msg("noSE", "存在しない効果音(パス:%1$s)");
	auto noSelectArea = Msg("noSelectArea", "(指定無し)");
	auto noArea = Msg("noArea", "存在しないエリア(ID:%1$s)");
	auto noSelectBattle = Msg("noSelectBattle", "(指定無し)");
	auto noBattle = Msg("noBattle", "存在しないバトル(ID:%1$s)");
	auto noSelectPackage = Msg("noSelectPackage", "(指定無し)");
	auto noPackage = Msg("noPackage", "存在しないパッケージ(ID:%1$s)");
	auto noSelectCast = Msg("noSelectCast", "(指定無し)");
	auto noCast = Msg("noCast", "存在しないキャストカード(ID:%1$s)");
	auto noSelectSkill = Msg("noSelectSkill", "(指定無し)");
	auto noSkill = Msg("noSkill", "存在しない特殊技能カード(ID:%1$s)");
	auto noSelectItem = Msg("noSelectItem", "(指定無し)");
	auto noItem = Msg("noItem", "存在しないアイテムカード(ID:%1$s)");
	auto noSelectBeast = Msg("noSelectBeast", "(指定無し)");
	auto noBeast = Msg("noBeast", "存在しない召喚獣カード(ID:%1$s)");
	auto noSelectInfo = Msg("noSelectInfo", "(指定無し)");
	auto noInfo = Msg("noInfo", "存在しない情報カード(ID:%1$s)");
	auto noSelectFlag = Msg("noSelectFlag", "(指定無し)");
	auto noFlag = Msg("noFlag", "存在しないフラグ(パス:%1$s)");
	auto noSelectStep = Msg("noSelectStep", "(指定無し)");
	auto noStep = Msg("noStep", "存在しないステップ(パス:%1$s)");
	auto noSelectStart = Msg("noSelectStart", "(指定無し)");
	auto noStart = Msg("noStart", "存在しないスタートコンテント(パス:%1$s)");
	auto noSelectCoupon = Msg("noSelectCoupon", "(指定無し)");
	auto noSelectCompleteStamp = Msg("noSelectCompleteStamp", "(指定無し)");
	auto noSelectGossip = Msg("noSelectGossip", "(指定無し)");

	auto cardId = Msg("cardId", "ID");
	auto cardName = Msg("cardName", "名称");
	auto cardDesc = Msg("cardDesc", "説明");
	auto infinity = Msg("infinity", "∞");

	auto dlgTitNewCast = Msg("dlgTitNewCast", "キャストカードの作成");
	auto dlgTitNewSkill = Msg("dlgTitNewSkill", "特殊技能カードの作成");
	auto dlgTitNewItem = Msg("dlgTitNewItem", "アイテムカードの作成");
	auto dlgTitNewBeast = Msg("dlgTitNewBeast", "召喚獣カードの作成");
	auto dlgTitNewInfo = Msg("dlgTitNewInfo", "情報カードの作成");
	auto dlgTitCast = Msg("dlgTitCast", "キャストカードの設定 [ %1$s ]");
	auto dlgTitSkill = Msg("dlgTitSkill", "特殊技能カードの設定 [ %1$s ]");
	auto dlgTitItem = Msg("dlgTitItem", "アイテムカードの設定 [ %1$s ]");
	auto dlgTitBeast = Msg("dlgTitBeast", "召喚獣カードの設定 [ %1$s ]");
	auto dlgTitInfo = Msg("dlgTitInfo", "情報カードの設定 [ %1$s ]");

	auto name = Msg("name", "名前");
	auto nameLimit = Msg("nameLimit", "(%2$s文字まで)"); // %1$s = 文字数、%2$s = 文字数 / 2
	auto level = Msg("level", "レベル");
	auto life = Msg("life", "体力");
	auto lifeCalc = Msg("lifeCalc", "標準値");
	auto history = Msg("history", "経歴");
	auto coupons = Msg("coupons", "経歴");
	auto addCoupon = Msg("addCoupon", "新規クーポンの追加");
	auto altCoupon = Msg("altCoupon", "クーポンの上書き");
	auto delCoupon = Msg("delCoupon", "クーポンの削除");
	auto sexTitle = Msg("sexTitle", "性別");
	auto periodTitle = Msg("periodTitle", "年代");
	auto race = Msg("race", "種族");
	auto noRace = Msg("noRace", "[未指定]");
	auto natureTitle = Msg("natureTitle", "素質");
	auto makingsTitle = Msg("makingsTitle", "特性");
	auto tolerant = Msg("tolerant", "対属性");
	auto tolerantBase = Msg("tolerantBase", "対カード属性");
	auto tolerantElement = Msg("tolerantElement", "対効果属性");
	auto resistWeapon = Msg("resistWeapon", "武器が効かない");
	auto resistMagic = Msg("resistMagic", "魔法が効かない");
	auto undead = Msg("undead", "命を持たない");
	auto automaton = Msg("automaton", "心を持たない");
	auto unholy = Msg("unholy", "不浄な存在");
	auto constructure = Msg("constructure", "魔法生物");
	auto resistText = Msg("resistText", "%1$sに耐性を持つ");
	auto weaknessText = Msg("weaknessText", "%1$sに弱い");
	auto descResistWeapon = Msg("descResistWeapon", "(物理属性のカードが無効)");
	auto descResistMagic = Msg("descResistMagic", "(魔法属性のカードが無効)");
	auto descUndead = Msg("descUndead", "(肉体属性の効果が無効)");
	auto descAutomaton = Msg("descAutomaton", "(精神属性の効果が無効)");
	auto descUnholy = Msg("descUnholy", "(神聖属性の効果に影響)");
	auto descConstructure = Msg("descConstructure", "(魔力属性の効果に影響)");
	auto descResist = Msg("descResist", "(%1$s属性の効果が無効)");
	auto descWeakness = Msg("descWeakness", "(%1$s属性の効果に影響)");
	auto basicResist = Msg("basicResist", "標準値");
	auto physicalParams = Msg("physicalParams", "身体能力");
	auto physicalSum = Msg("physicalSum", "合計値: %1$s");
	auto physicalCalc = Msg("physicalCalc", "標準値");
	auto mentalParams = Msg("mentalParams", "精神傾向");
	auto mentalCalc = Msg("mentalCalc", "標準値");
	auto castEnhance = Msg("castEnhance", "能力修正");
	auto basicEnhance = Msg("basicEnhance", "標準値");

	auto liveStatus = Msg("liveStatus", "初期状態");
	auto lifeAndMentality = Msg("lifeAndMentality", "体力と精神状態");
	auto enhanceLiveBonus = Msg("enhanceLiveBonus", "能力ボーナス/ペナルティ");
	const string enhanceLiveBonusName(Enhance id) {
		mixin(EnumToStringSwitch!(Enhance, "enhanceLiveBonusName"));
	}
	auto enhanceLiveBonusNameAction = Msg("enhanceLiveBonusNameAction", "行動");
	auto enhanceLiveBonusNameAvoid = Msg("enhanceLiveBonusNameAvoid", "回避");
	auto enhanceLiveBonusNameResist = Msg("enhanceLiveBonusNameResist", "抵抗");
	auto enhanceLiveBonusNameDefense = Msg("enhanceLiveBonusNameDefense", "防御");
	auto useMax = Msg("useMax", "最大値を使用");
	auto status = Msg("status", "異常状態");
	auto paralyze = Msg("paralyze", "麻痺/石化");
	auto poison = Msg("poison", "中毒");
	auto bind = Msg("bind", "呪縛");
	auto silence = Msg("silence", "沈黙");
	auto faceUp = Msg("faceUp", "暴露");
	auto antiMagic = Msg("antiMagic", "魔法無効");
	auto unitValue = Msg("unitValue", "点");
	auto unitRound = Msg("unitRound", "ラウンド");
	auto resetLiveStatus = Msg("resetLiveStatus", "通常状態に戻す");

	auto needSpellGroup = Msg("needSpellGroup", "発声による発動");
	auto needSpell = Msg("needSpell", "沈黙時に使用不可");
	auto elementProps = Msg("elementProps", "効果属性");
	auto linkOption = Msg("linkOption", "参照設定");
	auto beastMaxNest = Msg("beastMaxNest", "ネスト可能回数");
	auto resistProps = Msg("resistProps", "抵抗属性");
	auto aptPhysical = Msg("aptPhysical", "身体的要素");
	auto aptMental = Msg("aptMental", "精神的要素");
	auto skillLevel = Msg("skillLevel", "技能レベル");
	auto useCount = Msg("useCount", "使用回数");
	auto useCountGroup = Msg("useCountGroup", "使用可能回数");
	auto useCountRange = Msg("useCountRange", "(0～%1$s : 0 = ∞)");
	auto price = Msg("price", "価格");
	auto priceAuto = Msg("priceAuto", "(参考用)");
	auto useModify = Msg("useModify", "使用時 能力値修正");
	auto haveModify = Msg("haveModify", "所有時 能力値修正");
	auto motionKind = Msg("motionKind", "効果種別");
	auto motionElement = Msg("motionElement", "属性");
	auto motionDamageType = Msg("motionDamageType", "タイプ");
	auto motionValue = Msg("motionValue", "値");
	auto motionBeast = Msg("motionBeast", "召喚するカード");
	auto beastNone = Msg("beastNone", "[召喚獣無し]");
	auto setBeast = Msg("setBeast", "選択");
	auto motionRound = Msg("motionRound", "継続時間 (ラウンド数)");
	auto motionEnhValue = Msg("motionEnhValue", "変化値");
	auto effectTarget = Msg("effectTarget", "効果目標");
	auto effectRange = Msg("effectRange", "効果範囲");
	auto effectVisual = Msg("effectVisual", "視覚効果");
	auto cardPremium = Msg("cardPremium", "カードの価値");
	auto successRate = Msg("successRate", "成功率修正値");
	auto allFail = Msg("allFail", "絶対失敗\n(-5)");
	auto allSuccess = Msg("allSuccess", "絶対成功\n(+5)");
	auto se = Msg("se", "効果音");
	auto se1 = Msg("se1", "初期効果");
	auto se2 = Msg("se2", "二次効果");
	auto soundNone = Msg("soundNone", "[効果音無し]");
	auto keyCodes = Msg("keyCodes", "イベント発火のキーコード");

	auto warningNotDefaultSE = Msg("warningNotDefaultSE", "標準以外の効果音はシナリオの外では鳴らない可能性があります。");
	auto warningEffectTypeNone = Msg("warningEffectTypeNone", "無属性のカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。");
	auto warningVanishCast = Msg("warningVanishCast", "神聖属性以外の対象消去効果を持つカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。");
	auto warningNameLenOver = Msg("warningNameLenOver", "名前の長さが%2$s文字を超えています。メッセージにカード名が表示された際に不具合が発生する可能性があります。"); // %1$s = 文字数、%2$s = 文字数 / 2
	auto warningPCNumberClassic = Msg("warningPCNumberClassic", "プレイヤーキャラクタのイメージはCardWirth 1.30より前のバージョンでは表示されません。");
	auto warningUnknownContent = Msg("warningUnknownContent", "イベント [%1$s] はCardWirth %2$sより前のバージョンでは使用できません。");
	auto warningBranchCouponAtField = Msg("warningBranchCouponAtField", "フィールド全体でのクーポン所持判定は、CardWirth 1.30より前のバージョンでは使用できません。");
	auto warningSystemVarName = Msg("warningSystemVarName", "%1$sで始まる名前の状態変数は、プレイヤーの環境によっては正しく機能しない事があります。");
	auto warningSystemCoupon = Msg("warningSystemCoupon", "%1$sで始まる名前のクーポンを操作する事はできません。");
	auto warningBranchStatusMental = Msg("warningBranchStatusMental", "%1$s状態の判定は、CardWirth %2$sより前のバージョンでは使用できません。");
	auto warningNoCardSizeImage = Msg("warningNoCardSizeImage", "カードサイズ以外の画像を使用すると、プレイヤーの環境によっては意図したように表示されない事があります。");
	auto warningValuedTalker = Msg("warningValuedTalker", "評価メンバは、CardWirth 1.50より前のバージョンでは使用できません。");
	auto warningTextCell = Msg("warningTextCell", "テキストセルは、CardWirth 1.50より前のバージョンでは使用できません。");
	auto warningColorCell = Msg("warningColorCell", "カラーセルは、CardWirth 1.50より前のバージョンでは使用できません。");

	auto card = Msg("card", "カード");
	auto apt = Msg("apt", "要素");
	auto useCountAndDesc = Msg("useCountAndDesc", "使用回数/解説");
	auto levelAndDesc = Msg("levelAndDesc", "レベル/解説");
	auto useBonus = Msg("useBonus", "使用ボーナス");
	auto haveBonus = Msg("haveBonus", "所持ボーナス");
	auto motion = Msg("motion", "効果");
	auto cardProps = Msg("cardProps", "属性");
	auto settings = Msg("settings", "設定");
	auto seAndKeyCode = Msg("seAndKeyCode", "効果音/キーコード");

	auto rangeHint = Msg("rangeHint", "(%1$s～%2$s)");
	auto source = Msg("source", "出典");
	auto sourceScenario = Msg("sourceScenario", "シナリオ名");
	auto sourceAuthor = Msg("sourceAuthor", "シナリオ作者");
	auto resetSource = Msg("resetSource", "現在のシナリオを出典に設定");
	auto diffSource = Msg("diffSource", "出典のシナリオ名と作者名が現在のシナリオと異なるため、使用時イベントのカード入手、エリア移動、パッケージのコール等は実行されません。");

	/// ファイルビュー。
	auto dirTabName = Msg("dirTabName", "ファイル");
	auto dirWindowName = Msg("dirWindowName", "ファイル - [ %1$s ] - %2$s");
	auto dirStatus = Msg("dirStatus", "%1$s個のファイル (%2$s)");
	auto dirStatusSel = Msg("dirStatusSel", "%1$s個のファイル (%2$s) (%3$s個を選択中)");
	auto fileName = Msg("fileName", "ファイル名");
	auto fileExt = Msg("fileExt", "拡張子");
	auto fileCount = Msg("fileCount", "利用数");
	auto errorExec = Msg("errorExec", "%1$sの起動に失敗しました。");
	auto filterDescZip = Msg("filterDescZip", "ZIP アーカイブ (*.zip)");
	auto filterDescCab = Msg("filterDescCab", "CAB アーカイブ (*.cab)");
	auto filterDescWsn = Msg("filterDescWsn", "シナリオファイル (*.wsn)");
	auto dlgTitCreateArchive = Msg("dlgTitCreateArchive", "シナリオの圧縮");
	auto failedCreateArchive = Msg("failedCreateArchive", "シナリオの圧縮に失敗");
	auto dlgMsgIsSaveBeforeCreateArchive = Msg("dlgMsgIsSaveBeforeCreateArchive", "「%1$s」は変更されています。保存しますか？");

	/// エディタ設定ダイアログ。
	auto baseSettings = Msg("baseSettings", "基本設定");
	auto reference = Msg("reference", "...");
	auto enginePath = Msg("enginePath", "%1$sの場所");
	auto findEnginePath = Msg("findEnginePath", "シナリオの場所から自動的に探す");
	auto dlgTitEnginePath = Msg("dlgTitEnginePath", "%1$sの場所");
	auto tempDir = Msg("tempDir", "シナリオの一時展開先");
	auto tempDirDesc = Msg("tempDirDesc", "wsn圧縮されたシナリオの一時的な展開先を選択してください。");
	auto backupDir = Msg("backupDir", "自動バックアップ");
	auto backupEnabled = Msg("backupEnabled", "自動バックアップを行う");
	auto autoSave = Msg("autoSave", "バックアップ時に上書き保存する");
	auto backupRefAuthor = Msg("backupRefAuthor", "作者が一致したシナリオのみバックアップする");
	auto backupPath = Msg("backupPath", "保存先");
	auto backupDirDesc = Msg("backupDirDesc", "シナリオを定期的に自動バックアップする" ~ DIR ~ "を選択してください。");
	auto backupInterval = Msg("backupInterval", "保存間隔");
	auto minute = Msg("minute", "分");
	auto backupCount = Msg("backupCount", "最大保存数");
	auto backupBeforeSaveDir = Msg("backupBeforeSaveDir", "保存時バックアップ");
	auto backupBeforeSave = Msg("backupBeforeSave", "保存時バックアップ");
	auto backupBeforeSaveDirDesc = Msg("backupDirDesc", "シナリオファイルのバックアップコピーを作成する" ~ DIR ~ "を選択してください。");
	auto backupBeforeSaveEnabled = Msg("backupBeforeSaveEnabled", "保存時にシナリオファイルのバックアップコピーを作成する");
	auto backupBeforeSavePath = Msg("backupBeforeSavePath", "保存先");
	auto skin = Msg("skin", "スキン");
	auto scenarioAuthor = Msg("scenarioAuthor", "シナリオ作者(新規作成時に自動設定されます)");
	auto historiesSettings = Msg("historiesSettings", "履歴");
	auto openHistoryMax = Msg("openHistoryMax", "シナリオ履歴保存件数");
	auto openHistoryClear = Msg("openHistoryClear", "クリア");
	auto dlgMsgHistoryClear = Msg("dlgMsgHistoryClear", "シナリオ履歴を削除してよろしいですか？");
	auto searchHistoryMax = Msg("searchHistoryMax", "検索/置換履歴保存件数");
	auto searchHistoryClear = Msg("searchHistoryClear", "クリア");
	auto dlgMsgSearchHistoryClear = Msg("dlgMsgSearchHistoryClear", "検索/置換履歴を削除してよろしいですか？");
	auto ignorePaths = Msg("ignorePaths", "無視ファイル(改行区切り)");
	auto etcSettings = Msg("etcSettings", "その他");

	auto etcSettingsTitle = Msg("etcSettingsTitle", "詳細");

	auto languageSetting = Msg("languageSetting", "言語");
	auto languageSystem = Msg("languageSystem", "[システムの言語]");
	auto languageCaution = Msg("languageCaution", "※ 次回起動時から適用されます");

	auto singleWindow = Msg("singleWindow", "シングルウィンドウモード(再起動後に反映されます)");
	auto clickIsOpenEvent = Msg("clickIsOpenEvent", "左クリックでイベントビューを開く");
	auto smoothingCard = Msg("smoothingCard", "カードのサイズ変更時にスムージングを行う");
	auto showImagePreview = Msg("showImagePreview", "カードや背景のプレビュー表示を行う");
	auto classicStyleTree = Msg("classicStyleTree", "イベントツリーの開閉ボタンを省略する");
	auto adjustContentName = Msg("adjustContentName", "イベントコンテントの移動時にテキストを再設定する");
	auto radarStyleParams = Msg("radarStyleParams", "レーダー型コントロールでパラメータ値を設定する");
	auto editTriggerTypeIsQuick = Msg("editTriggerTypeIsQuick", "選択項目のクリックですぐにテキストの編集を開始する");
	auto showEventTreeMark = Msg("showEventTreeMark", "カードの詳細情報表示時に使用時イベントの有無を表示する");
	auto showCardListHeader = Msg("showCardListHeader", "カードの画像表示時にヘッダを表示する");
	auto showCardListTitle = Msg("showCardListTitle", "カードの画像表示時にIDと名前を表示する");
	auto showSkillCardLevel = Msg("showSkillCardLevel", "カードの画像表示時にスキルカードのレベルを表示する");
	auto ignoreEmptyStart = Msg("ignoreEmptyStart", "空のイベントツリーしか持たない使用時イベントは無視する");
	auto expandXMLs = Msg("expandXMLs", "圧縮されたシナリオの読込み時にXMLファイルを展開する");
	auto contentsFloat = Msg("contentsFloat", "コンテンツボックスを別ウィンドウで表示する");
	auto contentsAutoHide = Msg("contentsAutoHide", "コンテンツボックスを自動的に隠す");
	auto comboListVisible = Msg("comboListVisible", "コンボボックスでの編集開始時にリストを開く");
	auto xmlCopy = Msg("xmlCopy", "コピーや切り取りを常にXML形式で行う");
	auto showSpNature = Msg("showSpNature", "特殊型を表示する");
	auto saveInnerImagePath = Msg("saveInnerImagePath", "クラシックなシナリオで格納イメージのファイルパスを保存する");
	auto linkCard = Msg("linkCard", "キャストの所有カードや召喚対象のカードを参照で設定する");
	auto traceDirectories = Msg("traceDirectories", "ファイル・" ~ DIR ~ "の変更を自動的に追跡する");
	auto logicalSort = Msg("logicalSort", "数値参照型ソートを行う(1, 10, 2, 3, ... → 1, 2, 3, 10, ...)");
	auto copyDesc = Msg("copyDesc", "カードをエリアに貼り付け・ドロップした時、解説もコピーする");
	auto refCardsAtEditBgImage = Msg("refCardsAtEditBgImage", "背景変更コンテントの編集を開始する際、最初からカード配置の参照を行う");
	auto floatMessagePreview = Msg("floatMessagePreview", "台詞・メッセージのプレビューをフロートさせる");
	auto addNewClassicEngine = Msg("addNewClassicEngine", "未知のクラシックエンジンを見つけたら記憶する");
	auto doubleIO = Msg("doubleIO", "分割読込・保存を行う(デュアルコア以上の環境で高速化)");
	auto switchTabWheel = Msg("switchTabWheel", "マウスホイールでタブ切替を行う");
	auto closeTabWithMiddleClick = Msg("closeTabWithMiddleClick", "中ボタンクリックでタブを閉じる");
	auto openTabAtRightOfCurrentTab = Msg("openTabAtRightOfCurrentTab", "新しいタブを現在のタブの直後に開く");
	auto reconstruction = Msg("reconstruction", "シナリオごとにタブの配置を記憶する");
	auto openLastScenario = Msg("openLastScenario", "終了時に開いていたシナリオを次の起動時に開く");
	auto showVariableValuesInEventText = Msg("showVariableValuesInEventText", "選択肢のテキスト内の変数をプレビュー表示する(#M -> [選択中]...)");
	auto cautionBeforeReplace = Msg("cautionBeforeReplace", "全て置換する前に確認ダイアログを表示する");
	auto applyDialogsBeforeSave = Msg("applyDialogsBeforeSave", "保存前にダイアログの編集内容を適用する");
	auto useNamesAfterStandard = Msg("useNamesAfterStandard", "シナリオで使用中の称号・キーコードを標準の称号・キーコードの後に配置する");
	auto soundPlayType = Msg("soundPlayType", "BGM再生方式");
	auto soundPlayTypeDef = Msg("soundPlayTypeDef", "自動選択");
	auto soundPlayTypeSDL = Msg("soundPlayTypeSDL", "SDL(CardWirthPy方式)");
	auto soundPlayTypeMCI = Msg("soundPlayTypeMCI", "WinMM(CardWirth方式)");
	auto soundPlayTypeApp = Msg("soundPlayTypeApp", "関連付けされたアプリケーションで開く");
	auto soundEffectPlayType = Msg("soundEffectPlayType", "効果音再生方式");
	auto soundPlaySameBGM = Msg("soundPlaySameBGM", "BGMに合わせる");
	auto soundVolume = Msg("soundVolume", "音量");
	auto soundVolumePer = Msg("soundVolumePer", "%");
	auto soundCaution = Msg("soundCaution", "※ WinMM方式の時、音量は反映されません");

	auto keyBind = Msg("keyBind", "キーバインド");
	auto mnemonic = Msg("mnemonic", "アクセスキー");
	auto hotkey = Msg("hotkey", "ショートカット");

	auto wallpaper = Msg("wallpaper", "エディタの壁紙");
	auto filterWallpaper = Msg("filterWallpaper", "画像ファイル (*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.ico;*.icon)");
	auto dlgTitWallpaper = Msg("dlgTitWallpaper", "壁紙画像の選択");
	auto wallpaperStyle = Msg("wallpaperStyle", "表示形式");
	const string wallpaperStyleName(WallpaperStyle id) {
		mixin(EnumToStringSwitch!(WallpaperStyle, "wallpaperStyleName"));
	}
	auto wallpaperStyleNameCenter = Msg("wallpaperStyleNameCenter", "中央に表示");
	auto wallpaperStyleNameTile = Msg("wallpaperStyleNameTile", "並べて表示");
	auto wallpaperStyleNameExpandFull = Msg("wallpaperStyleNameExpandFull", "拡大して表示");
	auto wallpaperStyleNameExpand = Msg("wallpaperStyleNameExpand", "はみ出さないように拡大");

	auto bgImageAndKeyCode = Msg("bgImageAndKeyCode", "背景とキーコード");
	auto standardKeyCode = Msg("standardKeyCode", "標準のキーコード");

	auto errorEnginePath = Msg("errorEnginePath", "%1$sの場所が正しくありません。");
	auto errorTempPath = Msg("errorTempPath", "一時展開先が正しくありません。");
	auto errorBackupPath = Msg("errorBackupPath", "自動バックアップ先が正しくありません。");
	auto errorBackupBeforeSavePath = Msg("errorBackupBeforeSavePath", "保存時バックアップ先が正しくありません。");

	auto sNew = Msg("sNew", "新規作成");
	auto sAlt = Msg("sAlt", "上書き");
	auto sDel = Msg("sDel", "削除");

	auto outerToolsAndClassicEngines = Msg("outerToolsAndClassicEngines", "外部ツールとクラシックエンジン");
	auto outerToolsTitle = Msg("outerToolsTitle", "外部ツールの設定");
	auto outerToolName = Msg("outerToolName", "外部ツール名");
	auto outerToolCommand = Msg("outerToolCommand", "コマンド");
	auto dlgTitOuterTool = Msg("dlgTitOuterTool", "外部ツールの選択");
	auto toolsHint1 = Msg("toolsHint1", "$F = ファイル名");
	auto toolsHint3 = Msg("toolsHint3", "$$ = $");
	auto outerToolWorkDir = Msg("outerToolWorkDir", "作業" ~ DIR);
	auto toolWorkDir = Msg("toolWorkDir", "作業" ~ DIR ~ "の選択");
	auto toolWorkDirDesc = Msg("toolWorkDirDesc", "外部ツールの作業" ~ DIR ~ "を選択してください。");
	auto toolsHint2 = Msg("toolsHint2", "$S = シナリオの" ~ DIR);

	auto templates = Msg("templates", "テンプレート");
	auto eventTemplatesTitle = Msg("eventTemplatesTitle", "イベントテンプレートの設定");
	auto eventTemplateName = Msg("eventTemplateName", "テンプレート名");
	auto eventTemplateScript = Msg("eventTemplateScript", "スクリプト");

	auto scenarioTemplatesTitle = Msg("scenarioTemplatesTitle", "シナリオテンプレートの設定");
	auto scenarioTemplateName = Msg("scenarioTemplateName", "テンプレート名");
	auto scenarioTemplatePath = Msg("scenarioTemplatePath", "シナリオの場所");
	auto dlgTitScTemplate = Msg("dlgTitScTemplate", "テンプレートシナリオの選択");

	auto exeFileDescExe = Msg("exeFileDescExe", "実行ファイル (*.exe)");
	auto exeFileDescAll = Msg("exeFileDescAll", "すべてのファイル (*.*)");

	auto classicEnginesTitle = Msg("classicEnginesTitle", "クラシックエンジンの設定");
	auto classicEngineName = Msg("classicEngineName", "エンジン名");
	auto classicEnginePath = Msg("classicEnginePath", "実行ファイルパス");
	auto classicEngineDataDirName = Msg("classicEngineDataDirName", "データフォルダ");
	auto classicEngineDataDirNameDesc = Msg("classicEngineDataDirNameDesc", "クラシックエンジンのデータフォルダを選択してください。");
	auto classicEngineExecute = Msg("classicEngineExecute", "代替実行ファイル");
	auto classicEngineHint1 = Msg("classicEngineHint1", "※ 代替実行ファイルを指定すると、エンジン本体の代わりに実行されます");
	auto dlgTitClassicEnginePath = Msg("dlgTitClassicEnginePath", "クラシックエンジンの選択");
	auto dlgTitClassicEngineExecute = Msg("dlgTitClassicEngineExecute", "代替実行ファイルの選択");

	auto featureName = Msg("featureName", "システム文字列");
	auto dlgTitFeatureName = Msg("dlgTitFeatureName", "システム文字列");
	auto featureDefaultName = Msg("featureDefaultName", "標準");
	auto featureVariantName = Msg("featureVariantName", "バリアント");
	auto featureManualName = Msg("featureManualName", "ユーザ設定");

	auto bgImagesDefault = Msg("bgImagesDefault", "デフォルト背景");
	auto setBgImagesDefault = Msg("setBgImagesDefault", "デフォルト背景の設定...");
	auto dlgTitBgImagesDefault = Msg("dlgTitBgImagesDefault", "デフォルト背景の設定");

	auto systemSounds = Msg("systemSounds", "システム音声");
	auto soundSaved = Msg("soundSaved", "保存完了");
	auto playableSounds = Msg("playableSounds", "サウンドファイル (%1$s)");
	auto dlgTitSystemSound = Msg("dlgTitSystemSound", "システム音声の選択");

	auto undoMax = Msg("undoMax", "「元に戻す」回数");
	auto undoMaxMainView = Msg("undoMaxMainView", "エリア/カード/フラグ");
	auto undoMaxEvent = Msg("undoMaxEvent", "メニュー/エネミー/背景/イベント");
	auto undoMaxReplace = Msg("undoMaxReplace", "置換");
	auto undoMaxEtc = Msg("undoMaxEtc", "テキスト/その他");

	auto dialogStatus = Msg("dialogStatus", "台詞コンテントのステータス");
	const string dialogStatusName(DialogStatus id) {
		mixin(EnumToStringSwitch!(DialogStatus, "dialogStatusName"));
	}
	auto dialogStatusNameTop = Msg("dialogStatusNameTop", "最上位の台詞");
	auto dialogStatusNameUnder = Msg("dialogStatusNameUnder", "最下位の台詞");
	auto dialogStatusNameUnderWithCoupon = Msg("dialogStatusNameUnderWithCoupon", "最下位の台詞(条件クーポン設定あり)");

	/// スクリプト関係。
	auto dlgTitScriptError = Msg("dlgTitScriptError", "CWXスクリプトエラー");
	auto scriptError = Msg("scriptError", "CWXスクリプトのコンパイル中にエラーが発生しました。");
	auto scriptErrorOver100Error = Msg("scriptErrorOver100Error", "エラーが100件を超えたため、スクリプトの解析を終了します。");
	auto scriptErrorInvalidToken = Msg("scriptErrorInvalidToken", "スクリプトに使用できない文字が含まれています。");
	auto scriptErrorInvalidSyntax = Msg("scriptErrorInvalidSyntax", "構文が正しくありません。");
	auto scriptErrorInvalidString = Msg("scriptErrorInvalidString", "ここに文字列が必要です。");
	auto scriptErrorUnCloseString = Msg("scriptErrorUnCloseString", "文字列が閉じられていません。");
	auto scriptErrorUnOpenComment = Msg("scriptErrorUnOpenComment", "コメントは開始されていません。");
	auto scriptErrorUnCloseComment = Msg("scriptErrorUnCloseComment", "コメントが閉じられていません。");
	auto scriptErrorInvalidNumber = Msg("scriptErrorInvalidNumber", "数値が正しくありません。");
	auto scriptErrorCloseBracketNotFound = Msg("scriptErrorCloseBracketNotFound", "閉じ括弧が見つかりません。");
	auto scriptErrorCloseParenNotFound = Msg("scriptErrorCloseParenNotFound", "閉じ括弧が見つかりません。");
	auto scriptErrorZeroDivision = Msg("scriptErrorZeroDivision", "0で除算を行いました。");
	auto scriptErrorInvalidAttr = Msg("scriptErrorInvalidAttr", "属性が正しくありません。");
	auto scriptErrorInvalidVar = Msg("scriptErrorInvalidVar", "変数が正しくありません。");
	auto scriptErrorInvalidVarVal = Msg("scriptErrorInvalidVarVal", "変数の値が正しくありません。");
	auto scriptErrorNoStartText = Msg("scriptErrorNoStartText", "スタートコンテントの名前がありません。");
	auto scriptErrorInvalidStatement = Msg("scriptErrorInvalidStatement", "文が正しくありません。");
	auto scriptErrorInvalidBranch = Msg("scriptErrorInvalidBranch", "分岐の構成が正しくありません。");
	auto scriptErrorNoIfText = Msg("scriptErrorNoIfText", "ifの条件が見つかりません。");
	auto scriptErrorNoIfContents = Msg("scriptErrorNoIfContents", "分岐先のコンテントが見つかりません。");
	auto scriptErrorInvalidKeyword = Msg("scriptErrorInvalidKeyword", "未知のキーワードです。");
	auto scriptErrorInvalidValuesOpen = Msg("scriptErrorInvalidValuesOpen", "パラメータ列ではありません。");
	auto scriptErrorInvalidValuesClose = Msg("scriptErrorInvalidValuesClose", "閉じ括弧が見つかりません。");
	auto scriptErrorNoVarSet = Msg("scriptErrorNoVarSet", "変数に値をセットしていません。");
	auto scriptErrorNoVarVal = Msg("scriptErrorNoVarVal", "変数の値がありません。");
	auto scriptErrorInvalidCalc = Msg("scriptErrorInvalidCalc", "計算式が不正です。");
	auto scriptErrorInvalidBoolVal = Msg("scriptErrorInvalidBoolVal", "キーワードが正しくありません。");
	auto scriptErrorInvalidTransition = Msg("scriptErrorInvalidTransition", "未知の画面切替方式です。");
	auto scriptErrorInvalidRange = Msg("scriptErrorInvalidRange", "未知の範囲です。");
	auto scriptErrorInvalidStatus = Msg("scriptErrorInvalidStatus", "未知のステータスです。");
	auto scriptErrorInvalidTarget = Msg("scriptErrorInvalidTarget", "未知のターゲットです。");
	auto scriptErrorInvalidEffectType = Msg("scriptErrorInvalidEffectType", "未知の効果属性です。");
	auto scriptErrorInvalidResist = Msg("scriptErrorInvalidResist", "未知の命中属性です。");
	auto scriptErrorInvalidCardVisual = Msg("scriptErrorInvalidCardVisual", "未知の視覚効果です。");
	auto scriptErrorInvalidMental = Msg("scriptErrorInvalidMental", "未知の精神要素です。");
	auto scriptErrorInvalidPhysical = Msg("scriptErrorInvalidPhysical", "未知の肉体要素です。");
	auto scriptErrorInvalidMotionType = Msg("scriptErrorInvalidMotionType", "未知の効果タイプです。");
	auto scriptErrorInvalidMotion = Msg("scriptErrorInvalidMotion", "効果が正しくありません。");
	auto scriptErrorInvalidElement = Msg("scriptErrorInvalidElement", "未知の属性です。");
	auto scriptErrorInvalidDamageType = Msg("scriptErrorInvalidDamageType", "未知のダメージタイプです。");
	auto scriptErrorInvalidEffectCardType = Msg("scriptErrorInvalidEffectCardType", "未知の効果カードタイプです。");
	auto scriptErrorInvalidComparison4 = Msg("scriptErrorInvalidComparison4", "未知の比較条件です。");
	auto scriptErrorInvalidComparison3 = Msg("scriptErrorInvalidComparison3", "未知の比較条件です。");
	auto scriptErrorInvalidBgImage = Msg("scriptErrorInvalidBgImage", "背景画像が正しくありません。");
	auto scriptErrorInvalidColor = Msg("scriptErrorInvalidColor", "色が正しくありません。");
	auto scriptErrorInvalidBlendMode = Msg("scriptErrorInvalidBlendMode", "未知の合成方式です。");
	auto scriptErrorInvalidGradientDir = Msg("scriptErrorInvalidGradientDir", "未知のグラデーション方向です。");
	auto scriptErrorInvalidDialog = Msg("scriptErrorInvalidDialog", "台詞が正しくありません。");
	auto scriptErrorInvalidTalker = Msg("scriptErrorInvalidTalker", "話者が正しくありません。");
	auto scriptErrorInvalidCoupon = Msg("scriptErrorInvalidCoupon", "評価条件が正しくありません。");
	auto scriptErrorUndefinedSymbol = Msg("scriptErrorUndefinedSymbol", "未知のシンボルです。");
	auto scriptErrorInvalidSif = Msg("scriptErrorInvalidSif", "ここにsifが現れる事はできません。");
	auto scriptErrorNoSifText = Msg("scriptErrorNoSifText", "sifのテキストが見つかりません。");
	auto scriptErrorInvalidCommand = Msg("scriptErrorInvalidCommand", "命令が正しくありません。");
	auto scriptErrorCanNotHaveContent = Msg("scriptErrorCanNotHaveContent", "このコンテントが後続コンテントを持つ事はできません。");
	auto scriptErrorInvalidStr = Msg("scriptErrorInvalidStr", "文字列が正しくありません。");
	auto scriptErrorReqNumber = Msg("scriptErrorReqNumber", "ここに数値が必要です。");
	auto scriptErrorReqID = Msg("scriptErrorReqID", "ここにIDが必要です。");
	auto scriptErrorUndefinedVar = Msg("scriptErrorUndefinedVar", "存在しない変数です。");
	auto scriptErrorInvalidValue = Msg("scriptErrorInvalidValue", "値が正しくありません。");
	auto scriptErrorSystem = Msg("scriptErrorSystem", "サイズが大きすぎるため、CWXスクリプトをコンパイルできません。");

	auto dlgTitScriptVarSet = Msg("dlgTitScriptVarSet", "値が未決定の変数の設定");
	auto scriptVarSet = Msg("scriptVarSet", "変数に値を入力");
	auto scriptVarNameColumn = Msg("scriptVarNameColumn", "変数名");
	auto scriptVarValueColumn = Msg("scriptVarValueColumn", "値");
	auto material = Msg("material", "ファイル");
	auto coupon = Msg("coupon", "クーポン");
	auto gossip = Msg("gossip", "ゴシップ");
	auto completeStamp = Msg("completeStamp", "終了印");

	/// メニュー。
	const string menuText(MenuID id) {
		mixin(EnumToStringSwitch!(MenuID, "menuText"));
	}

	auto menuTextNone = Msg("menuTextNone", "");

	auto menuTextFile = Msg("menuTextFile", "ファイル");
	auto menuTextEdit = Msg("menuTextEdit", "編集");
	auto menuTextView = Msg("menuTextView", "表示");
	auto menuTextTool = Msg("menuTextTool", "ツール");
	auto menuTextTable = Msg("menuTextTable", "テーブル");
	auto menuTextVariable = Msg("menuTextVariable", "状態変数");
	auto menuTextHelp = Msg("menuTextHelp", "ヘルプ");
	auto menuTextCard = Msg("menuTextCard", "カード");
	auto menuTextCardsAndBacks = Msg("menuTextCardsAndBacks", "カードと背景");

	auto menuTextDelNotUsedFile = Msg("menuTextDelNotUsedFile", "未使用のファイルを削除");
	auto menuTextLeftPane = Msg("menuTextLeftPane", "左のタブ");
	auto menuTextRightPane = Msg("menuTextRightPane", "右のタブ");
	auto menuTextClosePane = Msg("menuTextClosePane", "閉じる");
	auto menuTextClosePaneExcept = Msg("menuTextClosePaneExcept", "他のタブを閉じる");
	auto menuTextClosePaneLeft = Msg("menuTextClosePaneLeft", "左側のタブを閉じる");
	auto menuTextClosePaneRight = Msg("menuTextClosePaneRight", "右側のタブを閉じる");
	auto menuTextClosePaneAll = Msg("menuTextClosePaneAll", "全てのタブを閉じる");
	auto menuTextNew = Msg("menuTextNew", "新規作成");
	auto menuTextOpen = Msg("menuTextOpen", "開く");
	auto menuTextNewAtNewWindow = Msg("menuTextNewAtNewWindow", "新しいウィンドウで新規作成");
	auto menuTextOpenAtNewWindow = Msg("menuTextOpenAtNewWindow", "新しいウィンドウで開く");
	auto menuTextClose = Msg("menuTextClose", "閉じる");
	auto menuTextCloseWin = Msg("menuTextCloseWin", "閉じる");
	auto menuTextSave = Msg("menuTextSave", "上書き保存");
	auto menuTextSaveAs = Msg("menuTextSaveAs", "名前を付けて保存");
	auto menuTextReload = Msg("menuTextReload", "再読込");
	auto menuTextOpenDir = Msg("menuTextOpenDir", DIR ~ "を開く");
	auto menuTextOpenPlace = Msg("menuTextOpenPlace", "ファイルの場所を開く");
	auto menuTextSaveImage = Msg("menuTextSaveImage", "格納イメージをファイルに保存");
	auto menuTextIncludeImage = Msg("menuTextIncludeImage", "イメージを格納する");
	auto menuTextLookImages = Msg("menuTextLookImages", "画像を一覧表示");
	auto menuTextShowMainToolBar = Msg("menuTextShowMainToolBar", "全体ツールバーを表示");
	auto menuTextShowSceneToolBar = Msg("menuTextShowSceneToolBar", "シーンビューのツールバーを表示");
	auto menuTextShowEventToolBar = Msg("menuTextShowEventToolBar", "イベントビューのツールバーを表示");
	auto menuTextChangeVH = Msg("menuTextChangeVH", "分割領域の縦横を切替");
	auto menuTextFind = Msg("menuTextFind", "検索と置換");
	auto menuTextIncSearch = Msg("menuTextIncSearch", "絞り込み検索");
	auto menuTextCloseIncSearch = Msg("menuTextCloseIncSearch", "閉じる");
	auto menuTextEditProp = Msg("menuTextEditProp", "編集");
	auto menuTextRefresh = Msg("menuTextRefresh", "最新の情報に更新");
	auto menuTextUndo = Msg("menuTextUndo", "元に戻す");
	auto menuTextRedo = Msg("menuTextRedo", "やり直し");
	auto menuTextCut = Msg("menuTextCut", "切り取り");
	auto menuTextCopy = Msg("menuTextCopy", "コピー");
	auto menuTextPaste = Msg("menuTextPaste", "貼り付け");
	auto menuTextDelete = Msg("menuTextDelete", "削除");
	auto menuTextCut1Content = Msg("menuTextCut1Content", "1コンテント切り取り");
	auto menuTextCopy1Content = Msg("menuTextCopy1Content", "1コンテントコピー");
	auto menuTextDelete1Content = Msg("menuTextDelete1Content", "1コンテント削除");
	auto menuTextPasteInsert = Msg("menuTextPasteInsert", "クリップボードから挿入");
	auto menuTextClone = Msg("menuTextClone", "複製");
	auto menuTextSelectAll = Msg("menuTextSelectAll", "すべて選択");
	auto menuTextToXMLText = Msg("menuTextToXMLText", "コピーしたデータをXMLに変換");
	auto menuTextTableView = Msg("menuTextTableView", "テーブルビュー");
	auto menuTextVarView = Msg("menuTextVarView", "状態変数ビュー");
	auto menuTextCardView = Msg("menuTextCardView", "カードビュー");
	auto menuTextCastView = Msg("menuTextCastView", "キャストカードビュー");
	auto menuTextSkillView = Msg("menuTextSkillView", "特殊技能カードビュー");
	auto menuTextItemView = Msg("menuTextItemView", "アイテムカードビュー");
	auto menuTextBeastView = Msg("menuTextBeastView", "召喚獣カードビュー");
	auto menuTextInfoView = Msg("menuTextInfoView", "情報カードビュー");
	auto menuTextFileView = Msg("menuTextFileView", "ファイルビュー");
	auto menuTextExecEngine = Msg("menuTextExecEngine", "エンジン起動");
	auto menuTextExecEngineAuto = Msg("menuTextExecEngineAuto", "自動選択");
	auto menuTextExecEngineMain = Msg("menuTextExecEngineMain", "CardWirthPy");
	auto menuTextOuterTools = Msg("menuTextOuterTools", "外部ツール");
	auto menuTextSettings = Msg("menuTextSettings", "エディタ設定");
	auto menuTextVersionInfo = Msg("menuTextVersionInfo", "バージョン情報");
	auto menuTextLockToolBar = Msg("menuTextLockToolBar", "ツールバーを固定");
	auto menuTextResetToolBar = Msg("menuTextResetToolBar", "配置をリセット");
	auto menuTextCopyAsText = Msg("menuTextCopyAsText", "テキストとしてコピー");
	auto menuTextOpenAtView = Msg("menuTextOpenAtView", "ビューで開く");
	auto menuTextStartToPackage = Msg("menuTextStartToPackage", "このツリーをパッケージ化する");
	auto menuTextConvertContent = Msg("menuTextConvertContent", "変換");
	auto menuTextCGroupTerminal = Msg("menuTextCGroupTerminal", "開始/終端");
	auto menuTextCGroupStandard = Msg("menuTextCGroupStandard", "基本");
	auto menuTextCGroupData = Msg("menuTextCGroupData", "変数操作/分岐");
	auto menuTextCGroupUtility = Msg("menuTextCGroupUtility", "状況分岐");
	auto menuTextCGroupBranch = Msg("menuTextCGroupBranch", "保有分岐");
	auto menuTextCGroupGet = Msg("menuTextCGroupGet", "取得");
	auto menuTextCGroupLost = Msg("menuTextCGroupLost", "喪失");
	auto menuTextCGroupVisual = Msg("menuTextCGroupVisual", "外観操作");
	auto menuTextEditSummary = Msg("menuTextEditSummary", "シナリオの設定");
	auto menuTextNewArea = Msg("menuTextNewArea", "エリアの作成");
	auto menuTextNewBattle = Msg("menuTextNewBattle", "バトルの作成");
	auto menuTextNewPackage = Msg("menuTextNewPackage", "パッケージの作成");
	auto menuTextReNumberingAll = Msg("menuTextReNumberingAll", "全てのIDを1から振り直す");
	auto menuTextReNumbering = Msg("menuTextReNumbering", "IDの振り直し");
	auto menuTextEditScene = Msg("menuTextEditScene", "シーンビューを開く");
	auto menuTextEditEvent = Msg("menuTextEditEvent", "イベントビューを開く");
	auto menuTextNewFlagDir = Msg("menuTextNewFlagDir", "フォルダの作成");
	auto menuTextNewFlag = Msg("menuTextNewFlag", "フラグの作成");
	auto menuTextNewStep = Msg("menuTextNewStep", "ステップの作成");
	auto menuTextCopyVariablePath = Msg("menuTextCopyVariablePath", "状態変数のパスをコピー");
	auto menuTextUp = Msg("menuTextUp", "上へ");
	auto menuTextDown = Msg("menuTextDown", "下へ");
	auto menuTextOverDialog = Msg("menuTextOverDialog", "上の台詞へ移動");
	auto menuTextUnderDialog = Msg("menuTextUnderDialog", "下の台詞へ移動");
	auto menuTextShowParty = Msg("menuTextShowParty", "パーティカードの表示");
	auto menuTextShowMsg = Msg("menuTextShowMsg", "メッセージ枠の表示");
	auto menuTextShowRefCards = Msg("menuTextShowRefCards", "カード参照の表示");
	auto menuTextFixedCards = Msg("menuTextFixedCards", "カードの固定");
	auto menuTextFixedCells = Msg("menuTextFixedCells", "背景の固定");
	auto menuTextShowGrid = Msg("menuTextShowGrid", "グリッドの表示");
	auto menuTextShowEnemyCardProp = Msg("menuTextShowEnemyCardProp", "レベルとライフを表示");
	auto menuTextShowCard = Msg("menuTextShowCard", "カードの表示");
	auto menuTextShowBack = Msg("menuTextShowBack", "背景の表示");
	auto menuTextNewMenuCard = Msg("menuTextNewMenuCard", "メニューカードの作成");
	auto menuTextNewEnemyCard = Msg("menuTextNewEnemyCard", "エネミーカードの作成");
	auto menuTextNewBack = Msg("menuTextNewBack", "背景の作成");
	auto menuTextNewTextCell = Msg("menuTextNewTextCell", "テキストセルの作成");
	auto menuTextNewColorCell = Msg("menuTextNewColorCell", "カラーセルの作成");
	auto menuTextAutoArrange = Msg("menuTextAutoArrange", "カードを自動的に並べる");
	auto menuTextManualArrange = Msg("menuTextManualArrange", "カードの位置を自分で決定する");
	auto menuTextMask = Msg("menuTextMask", "透明色を使用");
	auto menuTextEscape = Msg("menuTextEscape", "逃走の有無");
	auto menuTextChangePos = Msg("menuTextChangePos", "位置とサイズの変更");
	auto menuTextPosTop = Msg("menuTextPosTop", "上に揃える");
	auto menuTextPosBottom = Msg("menuTextPosBottom", "下に揃える");
	auto menuTextPosLeft = Msg("menuTextPosLeft", "左に揃える");
	auto menuTextPosRight = Msg("menuTextPosRight", "右に揃える");
	auto menuTextPosEven = Msg("menuTextPosEven", "等間隔に並べる");
	auto menuTextNearTop = Msg("menuTextNearTop", "上へ寄せる");
	auto menuTextNearBottom = Msg("menuTextNearBottom", "下へ寄せる");
	auto menuTextNearLeft = Msg("menuTextNearLeft", "左へ寄せる");
	auto menuTextNearRight = Msg("menuTextNearRight", "右へ寄せる");
	auto menuTextNearCenter = Msg("menuTextNearCenter", "中央へ寄せる");
	auto menuTextScaleMin = Msg("menuTextScaleMin", "最小のカードスケール");
	auto menuTextScaleMiddle = Msg("menuTextScaleMiddle", "標準のカードスケール");
	auto menuTextScaleMax = Msg("menuTextScaleMax", "最大のカードスケール");
	auto menuTextScaleBig = Msg("menuTextScaleBig", "大きく揃える");
	auto menuTextScaleSmall = Msg("menuTextScaleSmall", "小さく揃える");
	auto menuTextExpandBack = Msg("menuTextExpandBack", "背景セルを最大化");
	auto menuTextStopBGM = Msg("menuTextStopBGM", "%1$sの再生を停止");
	auto menuTextPlayBGM = Msg("menuTextPlayBGM", "再生");
	auto menuTextKeyCodeTiming = Msg("menuTextKeyCodeTiming", "キーコード発火タイミング");
	auto menuTextKeyCodeTimingUse = Msg("menuTextKeyCodeTimingUse", "使用");
	auto menuTextKeyCodeTimingSuccess = Msg("menuTextKeyCodeTimingSuccess", "成功");
	auto menuTextKeyCodeTimingFailure = Msg("menuTextKeyCodeTimingFailure", "失敗");
	auto menuTextKeyCodeTimingHasNot = Msg("menuTextKeyCodeTimingHasNot", "不保有");
	auto menuTextKeyCodeCond = Msg("menuTextKeyCodeCond", "キーコード発火条件");
	auto menuTextKeyCodeCondOr = Msg("menuTextKeyCodeCondOr", "どれか一つに一致");
	auto menuTextKeyCodeCondAnd = Msg("menuTextKeyCodeCondAnd", "全てに一致");
	auto menuTextAddRangeOfRound = Msg("menuTextAddRangeOfRound", "複数のラウンドを追加");
	auto menuTextOpenAtTableView = Msg("menuTextOpenAtTableView", "テーブルビューで開く");
	auto menuTextOpenAtVarView = Msg("menuTextOpenAtVarView", "状態変数ビューで開く");
	auto menuTextOpenAtCardView = Msg("menuTextOpenAtCardView", "カードビューで開く");
	auto menuTextOpenAtFileView = Msg("menuTextOpenAtFileView", "ファイルビューで開く");
	auto menuTextOpenAtEventView = Msg("menuTextOpenAtEventView", "イベントビューで開く");
	auto menuTextComment = Msg("menuTextComment", "コメントを記述");
	auto menuTextShowCardProp = Msg("menuTextShowCardProp", "詳細情報を表示");
	auto menuTextShowCardImage = Msg("menuTextShowCardImage", "カード表示");
	auto menuTextShowCardDetail = Msg("menuTextShowCardDetail", "詳細表示");
	auto menuTextOpenImportSource = Msg("menuTextOpenImportSource", "外部シナリオから追加");
	auto menuTextNewCast = Msg("menuTextNewCast", "キャストカードの作成");
	auto menuTextNewSkill = Msg("menuTextNewSkill", "スキルカードの作成");
	auto menuTextNewItem = Msg("menuTextNewItem", "アイテムカードの作成");
	auto menuTextNewBeast = Msg("menuTextNewBeast", "召喚獣カードの作成");
	auto menuTextNewInfo = Msg("menuTextNewInfo", "情報カードの作成");
	auto menuTextImport = Msg("menuTextImport", "シナリオに追加");
	auto menuTextOpenHand = Msg("menuTextOpenHand", "所有カード");
	auto menuTextAddHand = Msg("menuTextAddHand", "所有カードの追加");
	auto menuTextRemoveRef = Msg("menuTextRemoveRef", "参照から格納へ変更する");
	auto menuTextEditEventAtTimeOfUsing = Msg("menuTextEditEventAtTimeOfUsing", "使用時イベントの設定");
	auto menuTextHold = Msg("menuTextHold", "カードのホールド");
	auto menuTextPlaySE = Msg("menuTextPlaySE", "再生");
	auto menuTextStopSE = Msg("menuTextStopSE", "停止");
	auto menuTextNewDir = Msg("menuTextNewDir", "新規" ~ DIR);
	auto menuTextCopyFilePath = Msg("menuTextCopyFilePath", "素材のパスをコピー");
	auto menuTextReplFilePath = Msg("menuTextReplFilePath", "素材の差替え");
	auto menuTextCreateArchive = Msg("menuTextCreateArchive", "シナリオを圧縮");
	auto menuTextToScript = Msg("menuTextToScript", "スクリプトに変換してコピー");
	auto menuTextToScriptAll = Msg("menuTextToScriptAll", "全てをスクリプトに変換してコピー");
	auto menuTextEvTemplates = Msg("menuTextEvTemplates", "テンプレートから作成");
	auto menuTextResetPreviewValues = Msg("menuTextResetPreviewValues", "初期値に戻す");
	auto menuTextResetPreviewValuesAll = Msg("menuTextResetPreviewValuesAll", "全て初期値に戻す");

	auto bgm = Msg("bgm", "BGM");
	auto newEvent = Msg("newEvent", "イベントの作成");
	auto newIgnition = Msg("newIgnition", "イベント発火条件の作成");
	auto expandTree = Msg("expandTree", "全コンテントツリーを開く");
	auto foldTree = Msg("foldTree", "全コンテントツリーを閉じる");

	auto sex = AAMsg("sex", "key", "name");
	auto period = AAMsg("period", "key", "name");
	auto nature = AAMsg("nature", "key", "name");
	auto makings = AAMsg("makings", "key", "name");

	/// 各連想配列を初期化する。
	this () {
		sex = [
			"♂":"♂",
			"♀":"♀",
		];
		period = [
			"子供":"子供",
			"若者":"若者",
			"大人":"大人",
			"老人":"老人",
		];
		nature = [
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
		];
		makings = [
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
		];
	}

	mixin XMLFuncs!(typeof(this), "message");
}
