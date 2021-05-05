
module cwx.msgs;

import cwx.types;
import cwx.features;
import cwx.structs;
import cwx.settings;
import cwx.versioninfo;
import cwx.enumutils;
import cwx.perf;

import std.string : format;

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
		~ "                   | -create <NAME> [<SKIN TYPE> [<SKIN NAME>]] | -createclassic <NAME> [<PATH>]\n"
		~ "                   | -selectfile <PATH> | -noload] <SCENARIO> [<CWXPath ...>]\n"
		~ "オプション:\n"
		~ "  -help         起動オプションの説明を表示して終了します。\n"
		~ "  -putlangfile <PATH> デフォルトの言語設定ファイル<PAHT>を出力して終了します。\n"
		~ "  -conf <PATH>  指定されたパスの基本設定ファイルを使用します。\n"
		~ "  -create        <NAME> [<SKIN TYPE> [<SKIN NAME>]]  起動後にシナリオを新規作成します。\n"
		~ "  -createclassic <NAME> [<PATH>]  起動後、<PATH>で指定されたフォルダに\n"
		~ "                                  クラシックなシナリオを新規作成します。\n"
		~ "  -selectfile  <PATH> 指定されたファイルをファイルビューで選択します。\n"
		~ "  -noload       起動後、前回終了時の編集状態を復元しません。\n"
		~ "  <SCENARIO>    起動と同時に指定されたシナリオを開きます。\n"
		~ "                (*.wsn/Summary.xml/Summary.wsm/[フォルダ])\n"
		~ "OpenID:\n"
		~ "  -a <ID>       シナリオを開いた後、<ID>で指定したIDのエリアを開きます。\n"
		~ "  -b <ID>       シナリオを開いた後、<ID>で指定したIDのバトルを開きます。\n"
		~ "  -p <ID>       シナリオを開いた後、<ID>で指定したIDのパッケージを開きます。\n"
		~ "CWXPath:\n"
		~ "  <CWXPath>     シナリオを開いた後、<CWXPath>で指定したリソースを開きます。");

	auto dlgTitError = Msg("dlgTitError", "エラー - CWXEditor");
	auto dlgTitWarning = Msg("dlgTitWarning", "警告 - CWXEditor");
	auto dlgTitQuestion = Msg("dlgTitQuestion", "確認 - CWXEditor");
	auto unknownError = Msg("unknownError", "処理の途中でCWXEditorの制作者が意図していないエラーが発生しました。"
		~ "データが壊れている可能性を考慮して、シナリオを保存せずに終了する事をお勧めします。\n"
		~ "エラーの内容は%1$sに記録されます。");
	auto shutdown = Msg("shutdown", "強制終了");

	auto warningWindowsHandleCount = Msg("warningWindowsHandleCount", "大量のタブやウィンドウを開いているため、Windowsハンドルを大量に消費しています。\nこのままハンドルを消費し続けると強制終了する恐れがあるため、不要なタブやウィンドウを閉じる事をお勧めします。");

	auto targetVersion = Msg("targetVersion", "対象エンジン");
	auto targetVersionHint = Msg("targetVersion", "※ 警告と誤り検索の結果に影響します");
	auto cardWirthPy = Msg("cardWirthPy", "CardWirthPy");
	auto cardWirthWithVersion = Msg("cardWirthWithVersion", "CardWirth %1$s");

	auto dlgTextOK = Msg("dlgTextOK", "&OK");
	auto dlgTextApply = Msg("dlgTextApply", "適用(&A)");
	auto dlgTextCancel = Msg("dlgTextCancel", "キャンセル(&C)");
	auto dlgTextClose = Msg("dlgTextClose", "閉じる(&C)");

	auto apply = Msg("apply", "適用");
	auto del = Msg("del", "削除");

	auto filterAll = Msg("filterAll", "全てのファイル (*.*)");

	auto fileCopyError = Msg("fileCopyError", "%1$sのコピー中にエラーが発生しました。");
	auto reloadError = Msg("reloadError", "%1$sの再読込中にエラーが発生しました。");
	auto loadProgress = Msg("loadProgress", "%2$s%% 完了 - %1$sを展開中");
	auto loading = Msg("loading", "%1$sの読込みを開始");
	auto loadingWithFile = Msg("loading", "%1$sを読込んでいます... (%2$s)");
	auto loaded = Msg("loaded", "%1$sの読込みを完了");
	auto loadedCount = Msg("loadedCount", "%1$s件の読込みを完了");
	auto reconstructionStatus = Msg("reconstructionStatus", "編集状態を復元中 (%1$s/%2$s)");
	auto cwxPathOpenError = Msg("cwxPathOpenError", "パス [%1$s] を開けません。");
	auto filePathOpenError = Msg("filePathOpenError", "パス [%1$s] を開けません。");
	auto editScenarioHistory = Msg("editScenarioHistory", "履歴とブックマークの編集");
	auto editImportHistory = Msg("editImportHistory", "追加元の履歴とブックマークの編集");
	auto scenarioBookmarkHint = Msg("scenarioBookmarkHint", "ブックマークに登録したいシナリオはチェックしてください。");
	auto historyScenarioFileName = Msg("historyScenarioFileName", "ファイル名");
	auto historyScenarioPath = Msg("historyScenarioPath", "場所");
	auto warningHistoryTooMany = Msg("warningHistoryTooMany", "履歴が多すぎます(%1$s件)。%2$s件を超えた分は適用時に破棄されます。");

	auto editExecutedPartyHistory = Msg("editExecutedPartyHistory", "パーティの履歴とブックマークの編集");
	auto executionPartyBookmarkHint = Msg("executionPartyBookmarkHint", "ブックマークに登録したいパーティはチェックしてください。");
	auto executionPartyName = Msg("executionPartyName", "パーティ");
	auto executionPartyYado = Msg("executionPartyYado", "拠点");
	auto executionPartyEngine = Msg("executionPartyEngine", "エンジン");

	auto loadSkinError = Msg("loadSkinError", "デフォルトのスキン「%1$s」が見つかりません。\n" ~ CARD_WIRTH_PY_EXE ~ "本体の場所が正しくないか、Data" ~ DIR ~ "が正しく配置されていない可能性があります。\nこのまま開始すると、一部リソース画像が非表示になります。");
	auto useDefaultSkin = Msg("useDefaultSkin", "スキン「%1$s」が見つかりません。\nデフォルトのスキン「%1$s」を使用します。");
	auto scenarioName = Msg("scenarioName", "シナリオ名");
	auto type = Msg("type", "タイプ");
	auto initialize = Msg("initialize", "初期設定");
	auto classic = Msg("classic", "クラシック");
	auto scenarioTemplate = Msg("scenarioTemplate", "テンプレート");
	auto templateDesc = Msg("templateDesc", "%1$s [%2$s]");
	auto noTemplate = Msg("noTemplate", "テンプレート無し");
	auto createClassicDir = Msg("createClassicDir", "シナリオの作成先");
	auto newClassicDir = Msg("newClassicDir", "シナリオ作成先の選択");
	auto newClassicDirDesc = Msg("newClassicDirDesc", "シナリオを作成する" ~ DIR ~ "を選択してください。");
	auto notEmptyDir = Msg("notEmptyDir", "%1$sは空ではありません。\n本当にここでシナリオを作成しますか？");
	auto createScenarioNameDir = Msg("createScenarioNameDir", "シナリオの" ~ DIR ~ "を新規作成する");
	auto notClassicWarning = Msg("notClassicWarning", "※ 「クラシック」以外のタイプはWSN形式となります");

	auto dlgTitSaveBitmapImage = Msg("dlgTitSaveBitmapImage", "格納イメージの保存");
	auto filterBitmapImage = Msg("filterBitmapImage", "ビットマップイメージ (*.bmp)");
	auto filterJPEGImage = Msg("filterJPEGImage", "JPEGイメージ (*.jpg)");
	auto filterGIFImage = Msg("filterGIFImage", "GIFイメージ (*.gif)");
	auto filterTIFFImage = Msg("filterTIFFImage", "TIFFイメージ (*.tiff)");
	auto filterPNGImage = Msg("filterPNGImage", "PNGイメージ (*.png)");
	auto filterICOImage = Msg("filterICOImage", "アイコン (*.ico)");
	auto dlgMsgIncludeImage = Msg("dlgMsgIncludeImage", "%1$sをシナリオファイル内にコピーしますか？\n(元のファイルは削除されません)");
	auto dlgMsgExcludeImage = Msg("dlgMsgExcludeImage", "WSN形式のシナリオでは格納イメージは使用できません。\n格納イメージを外部化しますか？\n(外部化しなかった場合、格納イメージは消滅します)");

	auto cardImagePosition = Msg("cardImagePosition", "イメージの配置方式:");

	const string cardImagePositionName(CardImagePosition id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "cardImagePositionName"));
	}
	auto cardImagePositionNameDefault = Msg("cardImagePositionNameDefault", "指定しない");
	auto cardImagePositionNameCenter = Msg("cardImagePositionNameCenter", "中央寄せ");
	auto cardImagePositionNameTopLeft = Msg("cardImagePositionNameTopLeft", "左上寄せ");

	auto dlgTitImageLayerWindow = Msg("dlgTitImageLayerWindow", "レイヤの編集");
	auto dlgTitImageLayerWindowReadOnly = Msg("dlgTitImageLayerWindowReadOnly", "レイヤの一覧");
	auto layerName = Msg("layerName", "レイヤ %1$s");
	auto warningLayer = Msg("warningLayer", "レイヤの指定はWsn.1以降の形式のシナリオでしか行えません。");
	auto layerValues = Msg("layerValues", "%1$s = 背景セル\n%2$s = メニュー・エネミーカード\n%3$s = プレイヤーカード\n%4$s = メッセージ");
	auto warningBgImageSmoothing = Msg("warningBgImageSmoothing", "背景セルを滑らかに拡大・縮小するかの指定はWsn.2以降の形式のシナリオでしか行えません。");

	auto smoothing = Msg("smoothing", "サイズ変更時の処理");
	const string smoothingName(Smoothing id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "smoothingName"));
	}
	auto smoothingNameDefault = Msg("smoothingNameDefault", "指定しない");
	auto smoothingNameTrue = Msg("smoothingNameTrue", "滑らかにする");
	auto smoothingNameFalse = Msg("smoothingNameFalse", "滑らかにしない");

	auto newFolder = Msg("newFolder", "新規" ~ DIR);

	auto dlgMsgDeleteFile = Msg("dlgMsgDeleteFile", "%1$sを完全に削除しますか？");
	auto dlgMsgDeleteFiles = Msg("dlgMsgDeleteFiles", "%1$s個の項目を完全に削除しますか？");
	auto dlgMsgDeleteFileRecycle = Msg("dlgMsgDeleteFileRecycle", "%1$sをごみ箱に移動しますか？");
	auto dlgMsgDeleteFilesRecycle = Msg("dlgMsgDeleteFilesRecycle", "%1$s個の項目をごみ箱に移動しますか？");
	auto dlgMsgDeleteUnuse = Msg("dlgMsgDeleteUnuse", "%1$s個の未使用ファイル・" ~ DIR ~ "を完全に削除しますか？");
	auto dlgMsgDeleteRecycleUnuse = Msg("dlgMsgDeleteRecycleUnuse", "%1$s個の未使用ファイル・" ~ DIR ~ "をごみ箱に移動しますか？");
	auto findUnusedHint = Msg("findUnusedHint", "※ 式で動的に生成された名前で状態変数を参照している場合は、使用を検出できません");

	auto image = Msg("image", "イメージ");
	auto pathDef = Msg("pathDef", "デフォルト");
	auto pathWsnBasic = Msg("pathWsnBasic", "%1$s 標準");
	auto imageNone = Msg("imageNone", "イメージ無し");
	auto fileNone = Msg("fileNone", "ファイルを選択");
	auto imageIncluding = Msg("imageIncluding", "イメージ格納");
	auto pcNumber = Msg("pcNumber", "プレイヤー%1$s");
	auto pc = Msg("pc", "%1$s番目のメンバ");
	auto bgmStop = Msg("bgmStop", "BGM停止");
	auto continueBGM = Msg("continueBGM", "再生中のBGMを継続");
	auto bgmNone = Msg("bgmNone", "BGM無し");
	auto useNoCardSizeImage = Msg("useNoCardSizeImage", "%1$s×%2$s以外も許容");
	auto excludeCardSizeImage = Msg("excludeCardSizeImage", "カードイメージを除外する");
	auto dlgMsgForceCancelDialogs = Msg("dlgMsgForceCancelDialogs", "%1$s件のダイアログが変更されたまま適用されていません。無視して操作を続行しますか？");
	auto dlgMsgForceCancelDialogsQuit = Msg("dlgMsgForceCancelDialogsQuit", "%1$s件のダイアログが変更されたまま適用されていません。無視して終了しますか？");
	auto dlgMsgIsSaveBeforeReload = Msg("dlgMsgIsSaveBeforeReload", "「%1$s」は変更されています。再読込しますか？");
	auto dlgMsgIsSaveBeforeExit = Msg("dlgMsgIsSaveBeforeExit", "「%1$s」は変更されています。保存しますか？");
	auto dlgMsgDropFile = Msg("dlgMsgDropFile", "%1$sをシナリオ" ~ DIR ~ "にコピーしますか？");
	auto dlgMsgDropFiles = Msg("dlgMsgDropFiles", "%1$s個のファイルをシナリオ" ~ DIR ~ "にコピーしますか？");
	auto dlgMsgDropOverWriteFile = Msg("dlgMsgDropOverWriteFile", "%1$sはすでに存在します。上書きしますか？");
	auto dlgMsgDropOverWriteFiles = Msg("dlgMsgDropOverWriteFiles", "%1$s個の項目がすでに存在します。上書きしますか？");
	auto dlgTitDropFiles = Msg("dlgTitDropFiles", "素材ファイルの追加");
	auto dlgMsgCopyError = Msg("dlgMsgCopyError", "いくつかのファイルのコピーに失敗しました。");

	auto dlgMsgCopyMaterial1 = Msg("dlgMsgCopyMaterial1", "格納イメージを参照に変更してコピーしますか？");
	auto dlgMsgCopyMaterial2 = Msg("dlgMsgCopyMaterial2", "参照された素材もコピーしますか？\n%1$s");
	auto dlgMsgCopyMaterial3 = Msg("dlgMsgCopyMaterial3", "参照された素材もコピーしますか？\n%1$s個のファイル");

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
	auto replStartUsers = Msg("replStartUsers", "スタートの参照");
	auto replLocalVariables = Msg("replLocalVariables", "ローカル変数の参照");

	auto searchRange = Msg("searchRange", "検索対象");
	auto flagsAndSteps = Msg("flagsAndSteps", "フラグとステップ");
	auto allCheckRange = Msg("allCheckRange", "全てチェック/全てチェックを外す");

	auto allCheck = Msg("allCheck", "全てチェック/全てチェックを外す(&L)");
	auto allSelect = Msg("allSelect", "全て選択/全て選択を外す(&L)");

	auto replError = Msg("replError", "重複する分岐(フラグ分岐が両方ともTRUEになっている等)・条件クーポンに抜けがあるセリフコンテント・存在しない素材を参照しているコンテント・基準とするバージョンのCardWirthに存在しない機能の使用等を検出します。");
	auto searchErrorCondition = Msg("searchErrorCondition", "検出条件");
	auto searchErrorTargetVersion = Msg("searchErrorTargetVersion", "基準とするバージョン");
	auto searchErrorTargetVersionNotSet = Msg("searchErrorTargetVersionNotSet", "[自動選択]");
	auto searchErrorTargetVersionHint = Msg("searchErrorTargetVersionHint", "※ 自動選択では、シナリオのデータバージョン及び対象エンジン設定が採用されます");
	auto searchErrorTargetVersionName = Msg("searchErrorTargetVersionName", "%1$s (%2$s)");

	auto replFrom = Msg("replFrom", "検索(置換前)");
	auto replTo = Msg("replTo", "置換後");
	auto grepFrom = Msg("replFrom", "検索");

	auto replText = Msg("replText", "検索/置換するテキスト");
	auto replTextTarget = Msg("replTextTarget", "検索/置換対象");
	auto replTextSummary = Msg("replTextSummary", "貼紙");
	auto replTextMessage = Msg("replTextMessage", "メッセージ");
	auto replTextCardName = Msg("replTextCardName", "カード名");
	auto replTextCardDesc = Msg("replTextCardDesc", "カード解説");
	auto replTextEventText = Msg("replTextEventText", "イベントテキスト");
	auto replTextStart = Msg("replTextStart", "スタートコンテント");
	auto replTextVariableName = Msg("replTextVariableName", "状態変数名");
	auto replTextVariableValue = Msg("replTextVariableValue", "変数の値");
	auto replTextExpression = Msg("replTextExpression", "式");
	auto replTextCoupon = Msg("replTextCoupon", "クーポン");
	auto replTextGossip = Msg("replTextGossip", "ゴシップ");
	auto replTextEndScenario = Msg("replTextEndScenario", "終了印");
	auto replTextAreaName = Msg("replTextAreaName", "エリア/バトル/パッケージ名");
	auto replTextKeyCode = Msg("replTextKeyCode", "キーコード");
	auto replTextCellName = Msg("replTextCellName", "セル名称");
	auto replTextCardGroup = Msg("replTextCardGroup", "カードグループ");
	auto replTextFile = Msg("replTextFile", "ファイル名");
	auto replTextComment = Msg("replTextComment", "コメント");
	auto replTextJptx = Msg("replTextJptx", "JPTX/テキストセル");
	auto replTextTextFile = Msg("replTextTextFile", "テキストファイル");
	auto replTextScenario = Msg("replTextScenario", "シナリオ名");
	auto replTextAuthor = Msg("replTextAuthor", "作者名");

	auto replacePlainTextHint = Msg("replacePlainTextHint", "文字コード Shift JIS または UTF-8 のみ有効\n(%1$s)");
	auto replacePlainTextHintNoExt = Msg("replacePlainTextHintNoExt", "文字コード Shift JIS または UTF-8 のみ有効");

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
	auto replIDFlag = Msg("replIDFlag", "フラグ");
	auto replIDStep = Msg("replIDStep", "ステップ");
	auto replIDVariant = Msg("replIDVariant", "コモン");
	auto replIDCoupon = Msg("replIDCoupon", "クーポン");
	auto replIDGossip = Msg("replIDGossip", "ゴシップ");
	auto replIDCompleteStamp = Msg("replIDCompleteStamp", "終了印");
	auto replIDKeyCode = Msg("replIDKeyCode", "キーコード");
	auto replIDCellName = Msg("replIDCellName", "セル名称");
	auto replIDCardGroup = Msg("replIDCardGroup", "カードグループ");
	auto replSetID = Msg("replSetID", "IDを直接指定");

	auto replPath = Msg("replPath", "検索/置換する素材");

	auto replUnuseTarget = Msg("replUnuseTarget", "検索対象");
	auto replUnuseFlag = Msg("replUnuseFlag", "フラグ");
	auto replUnuseStep = Msg("replUnuseStep", "ステップ");
	auto replUnuseVariant = Msg("replUnuseVariant", "コモン");
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
	auto replIgnoreReturnCode = Msg("replIgnoreReturnCode", "改行と前後の空白を無視(&I) (置換はできません)");
	auto wildcardDesc = Msg("wildcardDesc", "ワイルドカードが使用できます(* = 任意文字列, ? = 任意1文字, \\* = *, \\? = ?, \\\\ = \\)");
	auto replCond = Msg("replCond", "検索条件");
	auto search = Msg("search", "検索(&F)");
	auto replace = Msg("replace", "全て置換(&R)");
	auto cautionOfReplace = Msg("cautionOfReplace", "%1$sを%2$sに置換します。よろしいですか？");
	auto replaceValue = Msg("replaceValue", "「%1$s」");
	auto emptyText = Msg("emptyText", "空文字列");
	auto emptyPath = Msg("emptyPath", "空のパス");
	auto idValue = Msg("idValue", "ID:%1$sの%2$s");
	auto commentText = Msg("commentText", "コメント [ %1$s ]");
	auto searchCancel = Msg("searchCancel", "キャンセル(&C)");
	auto searchResultEmpty = Msg("searchResultEmpty", "0件の検索結果");
	auto searchResult = Msg("searchResult", "%1$s件の検索結果(%2$s)");
	auto searchResultGrep1 = Msg("searchResultGrep1", "%1$s件のシナリオ内の%2$s件の検索結果(%3$sを読込中...)");
	auto searchResultGrep2 = Msg("searchResultGrep2", "%1$s件のシナリオ内の%2$s件の検索結果(%3$sを検索中...)");
	auto searchResultGrep3 = Msg("searchResultGrep3", "%1$s件のシナリオ内の%2$s件の検索結果(%3$s)");
	auto searchResultRealtime = Msg("searchResultRealtime", "リアルタイム更新(&R)");
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

	auto searchResultImageCell = Msg("searchResultBgImage", "背景画像「%1$s」");
	auto searchResultTextCell = Msg("searchResultTextCell", "テキストセル「%1$s」");
	auto searchResultColorCell = Msg("searchResultColorCell", "カラーセル「%1$s」");
	auto searchResultPCCell = Msg("searchResultPCCell", "プレイヤーキャラクタセル「%1$s」");
	auto searchResultIds = Msg("searchResultIds", "%1$s「%2$s.%3$s」");
	auto searchResultIdsWithDesc = Msg("searchResultIdsWithDesc", "%1$s「%2$s.%3$s」 - %4$s");

	auto searchResultFlag = Msg("searchResultFlag", "フラグ「%1$s」");
	auto searchResultStep = Msg("searchResultStep", "ステップ「%1$s」");
	auto searchResultVariant = Msg("searchResultVariant", "コモン「%1$s」");
	auto searchResultFlagDir = Msg("searchResultFlagDir", "ディレクトリ「%1$s」");
	auto searchResultEventTree = Msg("searchResultEventTree", "イベントツリー「%1$s」");
	auto searchResultMenuCard = Msg("searchResultMenuCard", "メニューカード「%1$s」");
	auto searchResultMenuCardWithDesc = Msg("searchResultMenuCardWithDesc", "メニューカード「%1$s」 - %2$s");
	auto searchResultEnemyCard = Msg("searchResultEnemyCard", "エネミーカード「%1$s」");

	auto searchResultJpy1 = Msg("searchResultJpy1", "JPY1ファイル「%1$s」");
	auto searchResultJpdc = Msg("searchResultJpdc", "JPDCファイル「%1$s」");

	auto searchErrorReversalLevel = Msg("searchErrorReversalLevel", "対象レベルの上限と下限が逆転しています。");
	auto warningNoLevelMax = Msg("warningNoLevelMax", "最大対象レベルが設定されていません。");
	auto warningNoLevelMin = Msg("warningNoLevelMin", "最小対象レベルが設定されていません。");
	auto searchErrorNoImage = Msg("searchErrorNoImage", "イメージが指定されていません。");
	auto searchErrorImageNotFound = Msg("searchErrorImageNotFound", "存在しないイメージファイル(%1$s)が指定されています。");
	auto searchErrorBGMNotFound = Msg("searchErrorBGMNotFound", "存在しないBGMファイル(%1$s)が指定されています。");
	auto searchErrorSENotFound = Msg("searchErrorSENotFound", "存在しない効果音ファイル(%1$s)が指定されています。");
	auto searchErrorStartAreaNotFound = Msg("searchErrorStartAreaNotFound", "開始エリアが設定されていません。");
	auto searchErrorFlagNotFound = Msg("searchErrorFlagNotFound", "存在しないフラグ(%1$s)が指定されています。");
	auto searchErrorStepNotFound = Msg("searchErrorStepNotFound", "存在しないステップ(%1$s)が指定されています。");
	auto searchErrorStepValueNotFound = Msg("searchErrorStepValueNotFound", "存在しないステップ値(%1$s)が指定されています。");
	auto searchErrorVariantNotFound = Msg("searchErrorVariantNotFound", "存在しないコモン(%1$s)が指定されています。");
	auto searchErrorDupNextContent = Msg("searchErrorDupNextContent", "分岐条件が重複しています。");
	auto searchErrorSPFontIsNotSJIS1ByteChar = Msg("searchErrorSPFontIsNotSJIS1ByteChar", "「%1$s」は無効です。クラシックなシナリオの特殊フォント指定にはShift JISの1バイト文字しか使用できません。");
	auto searchErrorSPFontNotFound = Msg("searchErrorSPFontNotFound", "特殊フォントイメージ(%1$s)が見つかりません。");
	auto searchErrorNoRCouponsDialog = Msg("searchErrorNoRCouponsDialog", "最終項目以外にクーポン指定無し項目があります。");
	auto searchErrorAreaNotFound = Msg("searchErrorAreaNotFound", "存在しないエリア(ID:%1$s)が指定されています。");
	auto searchErrorBattleNotFound = Msg("searchErrorBattleNotFound", "存在しないバトル(ID:%1$s)が指定されています。");
	auto searchErrorPackageNotFound = Msg("searchErrorPackageNotFound", "存在しないパッケージ(ID:%1$s)が指定されています。");
	auto searchErrorCastNotFound = Msg("searchErrorCastNotFound", "存在しないキャストカード(ID:%1$s)が指定されています。");
	auto searchErrorSkillNotFound = Msg("searchErrorSkillNotFound", "存在しない特殊技能カード(ID:%1$s)が指定されています。");
	auto searchErrorItemNotFound = Msg("searchErrorItemNotFound", "存在しないアイテムカード(ID:%1$s)が指定されています。");
	auto searchErrorBeastNotFound = Msg("searchErrorBeastNotFound", "存在しない召喚獣カード(ID:%1$s)が指定されています。");
	auto searchErrorInfoNotFound = Msg("searchErrorInfoNotFound", "存在しない情報カード(ID:%1$s)が指定されています。");
	auto searchErrorStartNotFound = Msg("searchErrorStartNotFound", "存在しないスタートコンテント「%1$s」が指定されています。");
	auto searchErrorLinkIdSkillNotFound = Msg("searchErrorLinkIdSkillNotFound", "参照先の特殊技能カード(ID:%1$s)が見つかりません。");
	auto searchErrorLinkIdItemNotFound = Msg("searchErrorLinkIdItemNotFound", "参照先のアイテムカード(ID:%1$s)が見つかりません。");
	auto searchErrorLinkIdBeastNotFound = Msg("searchErrorLinkIdBeastNotFound", "参照先の召喚獣カード(ID:%1$s)が見つかりません。");
	auto searchErrorEmptyFile = Msg("searchErrorEmptyFile", "ファイルの内容が存在しません。");
	auto searchErrorDupFile = Msg("searchErrorDupFile", "同一のファイル「%1$s」が存在します。");
	auto searchErrorSourceIsTarget = Msg("searchErrorSourceIsTarget", "ソース変数とターゲット変数が同一です。");
	auto searchErrorSystemCoupon = Msg("searchErrorSystemCoupon", "「%1$s」はシステムクーポンとして扱われるため、正しく機能しない場合があります。");
	auto searchErrorSystemVariable = Msg("searchErrorSystemVariable", "「%1$s」はシステム変数として扱われるため、正しく機能しない場合があります。");
	auto searchErrorKeyCodeMatchingAll = Msg("searchErrorKeyCodeMatchingAll", "「MatchingType=All」はシステムで使用されているキーコードのため、正しく機能しない場合があります。");
	auto searchErrorBranchRoundInArea = Msg("searchErrorBranchRoundInArea", "ラウンド分岐がエリアイベントで使用されています。");

	auto searchErrorNoArea = Msg("searchErrorNoArea", "エリアが指定されていません。");
	auto searchErrorNoBattle = Msg("searchErrorNoBattle", "バトルが指定されていません。");
	auto searchErrorNoPackage = Msg("searchErrorNoPackage", "パッケージが指定されていません。");
	auto searchErrorNoSkill = Msg("searchErrorNoSkill", "特殊技能カードが指定されていません。");
	auto searchErrorNoItem = Msg("searchErrorNoItem", "アイテムカードが指定されていません。");
	auto searchErrorNoCast = Msg("searchErrorNoCast", "キャストカードが指定されていません。");
	auto searchErrorNoBeast = Msg("searchErrorNoBeast", "召喚獣カードが指定されていません。");
	auto searchErrorNoInfo = Msg("searchErrorNoInfo", "情報カードが指定されていません。");
	auto searchErrorNoFlag = Msg("searchErrorNoFlag", "フラグが指定されていません。");
	auto searchErrorNoStep = Msg("searchErrorNoStep", "ステップが指定されていません。");
	auto searchErrorNoVariant = Msg("searchErrorNoVariant", "コモンが指定されていません。");
	auto searchErrorNoExpressionTarget = Msg("searchErrorNoExpressionTarget", "代入先が指定されていません。");
	auto searchErrorNoSoundPath = Msg("searchErrorNoSoundPath", "効果音が指定されていません。");
	auto searchErrorNoCoupon = Msg("searchErrorNoCoupon", "クーポンが指定されていません。");
	auto searchErrorNoGossip = Msg("searchErrorNoGossip", "ゴシップが指定されていません。");
	auto searchErrorNoCompleteStamp = Msg("searchErrorNoCompleteStamp", "シナリオ名が指定されていません。");
	auto searchErrorNoKeyCode = Msg("searchErrorNoKeyCode", "キーコードが指定されていません。");
	auto searchErrorNoCellName = Msg("searchErrorNoCellName", "セル名称が指定されていません。");
	auto searchErrorNoCardGroup = Msg("searchErrorNoCardGroup", "カードグループが指定されていません。");
	auto searchErrorNoExpression = Msg("searchErrorNoExpression", "式がありません。");

	auto searchOpenDialog = Msg("searchOpenDialog", "検索結果へジャンプする時、ダイアログを開く(&J)");
	auto searchOpenDialogHint = Msg("searchOpenDialogHint", "Shiftキーで一時的に切り替え");

	/// イベント設定。
	auto dlgTitContent = Msg("dlgTitContent", "イベントの設定 [ %1$s ]");

	auto contentInitializer = Msg("contentInitializer", "コンテントの初期値");
	auto baseInitializers = Msg("baseInitializers", "基本");
	auto editedInitializer = Msg("editedInitializer", "*");

	auto afterClear = Msg("afterClear", "シナリオ終了後");
	auto afterClearEndMark = Msg("afterClearEndMark", "シナリオに済印を付ける");
	auto afterClearNoEndMark = Msg("afterClearNoEndMark", "何もしない");

	auto message = Msg("message", "メッセージ");
	auto couponName = Msg("couponName", "クーポン名");
	auto couponValue = Msg("couponValue", "得点");
	auto couponValueRange = Msg("couponValueRange", "(%1$s～%2$s)");
	auto resultType = Msg("resultType", "成功条件");
	auto resultTypeNormal = Msg("resultTypeNormal", "所有している");
	auto resultTypeInvert = Msg("resultTypeInvert", "所有していない");
	auto matchingConditionForKeyCode = Msg("matchingConditionForKeyCode", "カードのマッチング");
	auto matchingConditionForKeyCodeNormalDesc = Msg("matchingConditionForKeyCodeNormalDesc", "キーコードを含む場合に成功");
	auto matchingConditionForKeyCodeInvertDesc = Msg("matchingConditionForKeyCodeInvertDesc", "キーコードを含まない場合に成功");
	auto matchedCard = Msg("matchedCard", "マッチしたカード");
	auto resultTypeNormalDesc = Msg("resultTypeNormalDesc", "所有している場合に成功");
	auto resultTypeInvertDesc = Msg("resultTypeInvertDesc", "所有していない場合に成功");
	auto resultTypeNormalForStatus = Msg("resultTypeNormalForStatus", "状態を持つ");
	auto resultTypeInvertForStatus = Msg("resultTypeInvertForStatus", "状態を持たない");
	auto resultTypeInvertForAbility = Msg("resultTypeInvertForAbility", "能力不足時に成功する");
	auto resultTypeNormalForCondition = Msg("resultTypeNormalForCondition", "条件に合う");
	auto resultTypeInvertForCondition = Msg("resultTypeInvertForCondition", "条件に合わない");
	auto range = Msg("range", "適用範囲");
	auto couponForRange = Msg("couponForRange", "適用範囲の称号");
	auto matchingType = Msg("matchingType", "マッチングタイプ"); // Wsn.2
	auto gossipName = Msg("gossipName", "ゴシップ名");
	auto endName = Msg("endName", "シナリオ名");
	auto cardType = Msg("cardType", "カードの種類");
	auto keyCode = Msg("keyCode", "キーコード");
	auto talker = Msg("talker", "話者");
	auto initValue = Msg("initValue", "初期点");
	auto toneCoupons = Msg("toneCoupons", "口調条件");
	auto valued = Msg("valued", "評価条件");
	auto valuedTalkerMaxIsLess0 = Msg("valuedTalkerMaxIsLess0", "最大値 = %1$s (発言しない)\n最小値 = %2$s (発言しない)");
	auto valuedTalkerMaxMin = Msg("valuedTalkerMaxMin", "最大値 = %1$s\n最小値 = %2$s");
	auto valuedTalkerMaxMinLess0 = Msg("valuedTalkerMaxMinLess0", "最大値 = %1$s\n最小値 = %2$s (発言しない)");
	auto selectMemberValuedMaxIsLess0 = Msg("selectMemberValuedMaxIsLess0", "最大値 = %1$s (選択失敗)\n最小値 = %2$s (選択失敗)");
	auto selectMemberValuedMaxMin = Msg("selectMemberValuedMaxMin", "最大値 = %1$s\n最小値 = %2$s");
	auto selectMemberValuedMaxMinLess0 = Msg("selectMemberValuedMaxMinLess0", "最大値 = %1$s\n最小値 = %2$s (選択失敗)");
	auto cellName = Msg("cellName", "対象セル名称");
	auto targetCardGroup = Msg("targetCardGroup", "対象カードグループ");
	auto moveCell = Msg("moveCell", "位置の変更");
	auto moveCard = Msg("moveCard", "位置の変更");
	auto resizeCell = Msg("resizeCell", "サイズの変更");
	auto horizontalValue = Msg("horizontalValue", "横の値");
	auto verticalValue = Msg("verticalValue", "縦の値");
	auto selectFoundCard = Msg("selectFoundCard", "見つかったカードを選択状態にする"); // Wsn.3
	auto selectTalker = Msg("selectTalker", "話者を選択状態にする");// Wsn.3
	auto invertResult = Msg("invertResult", "条件に合わない場合に成功とする");// Wsn.4
	auto matchingCondition = Msg("matchingCondition", "マッチ条件");// Wsn.5
	auto changeLayer = Msg("changeLayer", "レイヤを変更する");
	auto changeScale = Msg("changeScale", "拡大率を変更する");

	const string matchingConditionName(MatchingCondition id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "matchingConditionName"));
	}
	auto matchingConditionNameHas = Msg("matchingConditionNameHas", "保有");
	auto matchingConditionNameHasNot = Msg("matchingConditionNameHasNot", "不保有");

	const string matchingConditionKeyCodeDesc(MatchingCondition id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "matchingConditionKeyCodeDesc"));
	}
	auto matchingConditionKeyCodeDescHas = Msg("matchingConditionKeyCodeDescHas", "指定キーコードを持つ");
	auto matchingConditionKeyCodeDescHasNot = Msg("matchingConditionKeyCodeDescHasNot", "指定キーコードを持たない");

	auto canNotGetMusicLength = Msg("canNotGetMusicLength", "SDL方式では音声の長さを取得できません");

	auto couponHide = Msg("couponHide", "隠蔽クーポン");

	const string couponTypeDesc(CouponType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "couponTypeDesc"));
	}
	auto couponTypeDescNormal = Msg("couponTypeDescNormal", "ノーマル");
	auto couponTypeDescHide = Msg("couponTypeDescHide", "隠蔽");
	auto couponTypeDescSystem = Msg("couponTypeDescSystem", "システム");
	auto couponTypeDescDur = Msg("couponTypeDescDur", "時限");
	auto couponTypeDescDurBattle = Msg("couponTypeDescDurBattle", "戦闘中時限");

	const string couponTypeLongDesc(CouponType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "couponTypeLongDesc"));
	}
	auto couponTypeLongDescNormal = Msg("couponTypeLongDescNormal", "ノーマル");
	auto couponTypeLongDescHide = Msg("couponTypeLongDescHide", "[%1$s...] 隠蔽(称号一覧で非表示)");
	auto couponTypeLongDescSystem = Msg("couponTypeLongDescSystem", "[%1$s...] システム");
	auto couponTypeLongDescDur = Msg("couponTypeLongDescDur", "[%1$s...] 時限(点数分の時間経過及びシナリオ終了時に消滅)");
	auto couponTypeLongDescDurBattle = Msg("couponTypeLongDescDurBattle", "[%1$s...] 戦闘中時限(点数分の時間経過及び戦闘終了時に消滅)");

	const string couponTypeShortDesc(CouponType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "couponTypeShortDesc"));
	}
	auto couponTypeShortDescNormal = Msg("couponTypeShortDescNormal", "一般");
	auto couponTypeShortDescHide = Msg("couponTypeShortDescHide", "隠蔽");
	auto couponTypeShortDescSystem = Msg("couponTypeShortDescSystem", "特殊");
	auto couponTypeShortDescDur = Msg("couponTypeShortDescDur", "時限");
	auto couponTypeShortDescDurBattle = Msg("couponTypeShortDescDurBattle", "戦闘");

	const string couponTypeName(CouponType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "couponTypeName"));
	}
	auto couponTypeNameNormal = Msg("couponTypeNameNormal", "通常");
	auto couponTypeNameHide = Msg("couponTypeNameHide", "隠蔽");
	auto couponTypeNameSystem = Msg("couponTypeNameSystem", "システム");
	auto couponTypeNameDur = Msg("couponTypeNameDur", "時限");
	auto couponTypeNameDurBattle = Msg("couponTypeNameDurBattle", "戦時");

	const string matchingTypeName(MatchingType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "matchingTypeName"));
	}
	auto matchingTypeNameAnd = Msg("matchingTypeNameAnd", "全てに一致");
	auto matchingTypeNameOr = Msg("matchingTypeNameOr", "どれか一つに一致");

	auto imageMessage = Msg("imageMessage", "イメージ付きメッセージ");
	auto noImageMessage = Msg("noImageMessage", "イメージ無しメッセージ");
	auto singleLineMessage = Msg("singleLineMessage", "単行メッセージ");
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
	const string scTalkerName(Talker id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "scTalkerName"));
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
	auto selectedPlayerCardNumber = Msg("selectedPlayerCardNumber", "選択メンバ番号($??SelectedPlayer$)"); // Wsn.2
	auto playerCardName = Msg("playerCardName", "プレイヤーカード名%1$s($??Player%1$s$)"); // Wsn.2
	auto addMsgRefFlag = Msg("addMsgRefFlag", "フラグ参照の追加");
	auto addMsgRefStep = Msg("addMsgRefStep", "ステップ参照の追加");
	auto addMsgRefVariant = Msg("addMsgRefVariant", "コモン参照の追加");
	auto addMsgRefImageFont = Msg("addMsgRefImageFont", "画像参照の追加");
	auto setTalkerCoupon = Msg("setTalkerCoupon", "追加");
	auto messagePreview = Msg("messagePreview", "プレビュー(&P)");
	auto dlgTitMessagePreview = Msg("dlgTitMessagePreview", "プレビュー");
	auto messageVarKindColumn = Msg("messageVarKindColumn", "状態変数");
	auto messageVarValueColumn = Msg("messageVarValueColumn", "サンプル値");
	auto warningSPCharsInSelections = Msg("warningSPCharsInSelections", "選択肢内の特殊文字は、CardWirth 1.50より前のバージョンでは展開されません。"); // CardWirth 1.50
	auto warningSelectedPlayerCardNumber = Msg("warningSelectedPlayerCardNumber", "選択メンバ番号($??SelectedPlayer$)の表示は、Wsn.2以降の形式のシナリオでしか行えません。"); // Wsn.2
	auto warningPlayerCardName = Msg("warningPlayerCardName", "プレイヤーカード名($??Player%1$s$)の表示は、Wsn.2以降の形式のシナリオでしか行えません。"); // Wsn.2
	auto warningUnknownSystemValue = Msg("warningUnknownSystemValue", "未知のシステム値(%1$s)です。");
	auto warningSelectedPlayerValue = Msg("warningSelectedPlayerValue", "選択メンバ番号の代入は、Wsn.2以降の形式のシナリオでしか行えません。"); // Wsn.2

	auto transition = Msg("transition", "背景切替方式");
	const string transitionName(Transition id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "transitionName"));
	}
	auto transitionNameDefault = Msg("transitionNameDefault", "プレイヤーの設定を使用");
	auto transitionNameNone = Msg("transitionNameNone", "アニメーション無し");
	auto transitionNameBlinds = Msg("transitionNameBlinds", "短冊(スレッド)式");
	auto transitionNamePixelDissolve = Msg("transitionNamePixelDissolve", "ドット置換(シェーブ)式");
	auto transitionNameFade = Msg("transitionNameFade", "色置換(フェード)式");
	auto transitionSpeed = Msg("transitionSpeed", "背景切替ウェイト");
	auto cardSpeed = Msg("cardSpeed", "アニメーション");
	auto overrideAnimationSpeed = Msg("overrideAnimationSpeed", "速度を指定する");
	auto overrideCardAnimationSpeed = Msg("overrideCardAnimationSpeed", "カードのアニメーション速度を指定する");
	auto forceOverrideCardAnimationSpeed = Msg("forceOverrideCardAnimationSpeed", "カード本体の設定より優先する");
	auto warningCardAnimationSpeed = Msg("warningCardAnimationSpeed", "カードのアニメーション速度の指定はWsn.4以降の形式のシナリオでしか行えません。");
	auto waitName = Msg("waitName", "空白時間(0.1秒単位)");
	auto moneyName = Msg("moneyName", "金額");
	auto randomName = Msg("randomName", "確率(%)");
	auto partyNumName = Msg("partyNumName", "パーティの人数");
	auto judgeTarget = Msg("judgeTarget", "判定対象");
	auto flag = Msg("flag", "フラグ");
	auto step = Msg("step", "ステップ");
	auto variant = Msg("variant", "コモン");
	auto flagValue = Msg("flagValue", "値");
	auto stepValue = Msg("stepValue", "段階");
	auto spChars = Msg("spChars", "特殊文字");
	auto warningLimitForNumberOfVariant = Msg("warningLimitForNumberOfVariant", "数値の桁数が大きすぎるため、ビット数の制限による誤差が発生する可能性があります。");
	auto expandSPChars = Msg("expandSPChars", "特殊文字を展開する");
	auto expandSPCharsHint = Msg("expandSPCharsHint", "#M = 選択メンバ名, #R = ランダムメンバ名 ...");
	auto selectMember = Msg("selectMember", "選択対象");
	auto activeMember = Msg("activeMember", "動けるメンバから選択");
	auto allMember = Msg("allMember", "パーティ全員から選択");
	auto selectMethod = Msg("selectMethod", "選択方法");
	auto manualMethod = Msg("manualMethod", "手動で選択");
	auto randomMethod = Msg("randomMethod", "ランダムで選択");
	auto valuedMethod = Msg("valuedMethod", "評価条件で選択");
	auto judgeSleep = Msg("judgeSleep", "眠り判定");
	auto sleepDisabled = Msg("sleepDisabled", "睡眠・呪縛者無効");
	auto sleepEnabled = Msg("sleepEnabled", "睡眠・呪縛者有効");
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
	auto doAnime = Msg("doAnime", "JPY1アニメーションを実行する"); // Wsn.1
	auto ignoreEffectBooster = Msg("ignoreEffectBooster", "エフェクトブースター関係のセルを無視する"); // Wsn.1
	auto selectionColumns = Msg("selectionColumns", "選択肢の列数"); // Wsn.1
	auto centeringX = Msg("centeringX", "横方向に中央寄せ"); // Wsn.2
	auto centeringXOn = Msg("centeringXOn", "横の中央寄せ"); // Wsn.2
	auto centeringY = Msg("centeringY", "縦方向に中央寄せ"); // Wsn.2
	auto centeringYOn = Msg("centeringYOn", "縦の中央寄せ"); // Wsn.2
	auto centeringXYOn = Msg("centeringXYOn", "縦横の中央寄せ"); // Wsn.2
	auto boundaryCheck = Msg("boundaryCheck", "禁則処理"); // Wsn.2
	auto boundaryCheckOn = Msg("boundaryCheckOn", "禁則処理あり"); // Wsn.2
	auto boundaryCheckDesc = Msg("boundaryCheckDesc", "禁則処理の結果は将来変化するかもしれません。\nメッセージの行数には余裕を持たせておく事をお勧めします。"); // Wsn.2
	auto consumeCard = Msg("consumeCard", "イベントを発火させたカードの使用回数を消費する"); // Wsn.3
	auto environmentStatus = Msg("environmentStatus", "状況の設定"); // Wsn.4
	const string environmentStatusName(EnvironmentStatus id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "environmentStatusName"));
	}
	auto environmentStatusNameNotSet = Msg("environmentStatusNameNotSet", "設定しない");
	auto environmentStatusNameEnable = Msg("environmentStatusNameEnable", "使用可能にする");
	auto environmentStatusNameDisable = Msg("environmentStatusNameDisable", "使用不能にする");
	auto backpack = Msg("backpack", "荷物袋");
	const string environmentStatusNameEnabled(EnvironmentStatus id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "environmentStatusNameEnabled"));
	}
	auto environmentStatusNameEnabledNotSet = Msg("environmentStatusNameEnabledNotSet", "設定しない");
	auto environmentStatusNameEnabledEnable = Msg("environmentStatusNameEnabledEnable", "有効にする");
	auto environmentStatusNameEnabledDisable = Msg("environmentStatusNameEnabledDisable", "無効にする");
	auto gameOver = Msg("gameOver", "敗北・ゲームオーバー");
	auto runAway = Msg("runAway", "逃走");
	auto warningEnvironmentEnabled = Msg("warningEnvironmentEnabled", "%1$sの有効・無効はWsn.%2$s以降の形式のシナリオでしか設定できません。");

	auto expression = Msg("expression", "式");
	auto operators = Msg("operators", "演算子:");
	auto operatorList = Msg("operatorList", "加算: A + B, 減算: A - B, 乗算: A * B, 除算: A / B, 剰余: A % B, 文字列連結: A ~ B, 一致: A = B, 不一致: A <> B, 大小比較: A <= B, A >= B, A < B, A > B, 論理演算: A and B, A or B, 真偽値反転: not A");
	auto expressionTarget = Msg("expressionTarget", "設定対象");
	auto selectFunction = Msg("selectFunction", "関数");
	auto functionDeclaration = Msg("functionDeclaration", "書式");
	auto functionDescription = Msg("functionDescription", "解説");
	auto functionExample = Msg("functionExample", "例");
	auto insertFlagIntoExpression = Msg("insertFlagIntoExpression", "フラグ名または関数の挿入");
	auto insertFlagPath = Msg("insertFlagPath", "フラグ名の挿入");
	auto insertStepIntoExpression = Msg("insertStepIntoExpression", "ステップ名または関数の挿入");
	auto insertStepPath = Msg("insertStepPath", "ステップ名の挿入");
	auto insertVariantIntoExpression = Msg("insertVariantIntoExpression", "コモン名または参照の挿入");
	auto insertVariantPath = Msg("insertVariantPath", "コモン名の挿入");
	auto insertVariantReference = Msg("insertVariantReference", "コモン参照の挿入");
	auto insertFunctionIntoExpression = Msg("insertFunctionIntoExpression", "関数の挿入");
	auto insertFunctionIntoExpressionButton = Msg("insertFunctionIntoExpressionButton", "式へ挿入(&I)");
	auto functionArgumentName = Msg("functionArgumentName", "引数");
	auto functionArgumentType = Msg("functionArgumentType", "タイプ");
	auto functionArgumentValue = Msg("functionArgumentValue", "値");
	auto constantValue = Msg("constantValue", "直接入力");
	auto variantReference = Msg("variantReference", "コモン参照");
	auto noArgument = Msg("noArgument", "指定しない");

	auto variableType = Msg("variableType", "状態変数タイプ");
	const string variableTypeName(VariableType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "variableTypeName"));
	}
	auto variableTypeNameFlag = Msg("variableTypeNameFlag", "フラグ");
	auto variableTypeNameStep = Msg("variableTypeNameStep", "ステップ");
	auto variableTypeNameVariant = Msg("variableTypeNameVariant", "コモン");

	auto functionCategory = Msg("functionCategory", "分類");
	auto allFunctions = Msg("allFunctions", "全て");
	const string functionCategoryName(FunctionCategory id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "functionCategoryName"));
	}
	auto functionCategoryNameStringOperation = Msg("functionCategoryNameStringOperation", "文字列操作");
	auto functionCategoryNameNumberOperation = Msg("functionCategoryNameNumberOperation", "数値操作");
	auto functionCategoryNameListOperation = Msg("functionCategoryNameListOperation", "リスト操作"); // Wsn.5
	auto functionCategoryNameConversion = Msg("functionCategoryNameConversion", "型変換");
	auto functionCategoryNameVariableOperation = Msg("functionCategoryNameVariableOperation", "状態変数");
	auto functionCategoryNameCastInformation = Msg("functionCategoryNameCastInformation", "キャラクター情報");
	auto functionCategoryNameCardInformation = Msg("functionCategoryNameCardInformation", "カード情報"); // Wsn.5
	auto functionCategoryNameCouponInformation = Msg("functionCategoryNameCouponInformation", "称号情報");
	auto functionCategoryNamePlayingInformation = Msg("functionCategoryNamePlayingOperation", "プレイ情報"); // Wsn.5
	auto functionCategoryNameEtc = Msg("functionCategoryNameEtc", "その他");

	const string blendModeName(BlendMode id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "blendModeName"));
	}
	auto blendModeNameNormal = Msg("blendModeNameNormal", "通常");
	auto blendModeNameMask = Msg("blendModeNameMask", "マスク");
	auto blendModeNameAdd = Msg("blendModeNameAdd", "加算");
	auto blendModeNameSubtract = Msg("blendModeNameSubtract", "減算");
	auto blendModeNameMultiply = Msg("blendModeNameMultiply", "乗算");

	const string gradientDirName(GradientDir id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "gradientDirName"));
	}
	auto gradientDirNameNone = Msg("gradientDirNameNone", "グラデーション無し");
	auto gradientDirNameLeftToRight = Msg("gradientDirNameLeftToRight", "左から右へ");
	auto gradientDirNameTopToBottom = Msg("gradientDirNameTopToBottom", "上から下へ");

	auto moveColors = Msg("moveColors", "色");

	const string borderingTypeName(BorderingType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "borderingTypeName"));
	}
	auto borderingTypeNameNone = Msg("borderingTypeNameNone", "縁取り無し");
	auto borderingTypeNameOutline = Msg("borderingTypeNameOutline", "形式1");
	auto borderingTypeNameInline = Msg("borderingTypeNameInline", "形式2");

	const string coordinateTypeName(CoordinateType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "coordinateTypeName"));
	}
	auto coordinateTypeNameNone = Msg("coordinateTypeNameNone", "変更無し");
	auto coordinateTypeNameAbsolute = Msg("coordinateTypeNameAbsolute", "直接指定");
	auto coordinateTypeNameRelative = Msg("coordinateTypeNameRelative", "現在値基準");
	auto coordinateTypeNamePercentage = Msg("coordinateTypeNamePercentage", "パーセンテージ");

	auto startAction = Msg("startAction", "戦闘行動開始タイミング");
	const string startActionName(StartAction id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "startActionName"));
	}
	auto startActionNameNow = Msg("startActionNameNow", "すぐに行動");
	auto startActionNameCurrentRound = Msg("startActionNameCurrentRound", "加入ラウンドから行動");
	auto startActionNameNextRound = Msg("startActionNameNextRound", "次のラウンドから行動");

	auto igniteTitle = Msg("igniteTitle", "イベント発火の有無");
	auto ignite = Msg("ignite", "効果適用時にキーコードイベントと死亡イベントを発火させる");
	auto igniteTrue = Msg("igniteTrue", "イベント発火あり");
	auto igniteFalse = Msg("igniteFalse", "イベント発火無し");
	auto igniteHint = Msg("igniteHint", "※ 発火したイベント内で選択メンバが変更される可能性があります");

	auto refAbilityTitle = Msg("refAbilityTitle", "能力参照");
	auto refAbility = Msg("refAbility", "成功率と効果値の計算に選択中のメンバのレベルと能力を使用する");

	auto absorbSettings = Msg("absorbSettings", "吸収効果");
	auto absorbToSelected = Msg("absorbToSelected", "選択メンバを吸収者にする");

	/// イベント。
	auto evtArrow = Msg("evtArrow", "イベント編集");

	auto allExpanded = Msg("allExpanded", "全て開く/全て閉じる(&E)");

	auto evtAutoOpen = Msg("evtAutoOpen", "配置と同時に編集");
	auto evtInsertFirst = Msg("evtInsertFirst", "他の子コンテントより前に配置");

	auto eventTreeViewHint = Msg("eventTreeViewHint", "Shift+配置: 選択コンテントの上へ挿入, Alt+配置: 「配置と同時に編集」設定を反転, Ctrl+配置: 「他の子コンテントより前に配置」設定を反転");

	auto contentNameForWarning = Msg("contentNameForWarning", "コンテント名");

	const string contentName(CType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "contentName"));
	}
	auto contentNameStart = Msg("contentNameStart", "スタート");
	auto contentNameStartBattle = Msg("contentNameStartBattle", "バトル開始");
	auto contentNameEnd = Msg("contentNameEnd", "シナリオクリア");
	auto contentNameEndBadEnd = Msg("contentNameEndBadEnd", "敗北・ゲームオーバー");
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
	auto contentNameMoveBgImage = Msg("contentNameMoveBgImage", "背景再配置"); // Wsn.1
	auto contentNameReplaceBgImage = Msg("contentNameReplaceBgImage", "背景置換"); // Wsn.1
	auto contentNameLoseBgImage = Msg("contentNameLoseBgImage", "背景削除"); // Wsn.1
	auto contentNameBranchMultiCoupon = Msg("contentNameBranchMultiCoupon", "クーポン多岐分岐"); // Wsn.2
	auto contentNameBranchMultiRandom = Msg("contentNameBranchMultiRandom", "ランダム多岐分岐"); // Wsn.2
	auto contentNameMoveCard = Msg("contentNameMoveCard", "カード再配置"); // Wsn.3
	auto contentNameChangeEnvironment = Msg("contentNameChangeEnvironment", "状況設定"); // Wsn.4
	auto contentNameBranchVariant = Msg("contentNameBranchVariant", "コモン分岐"); // Wsn.4
	auto contentNameSetVariant = Msg("contentNameSetVariant", "コモン設定"); // Wsn.4
	auto contentNameCheckVariant = Msg("contentNameCheckVariant", "コモン判定"); // Wsn.4

	const string contentDesc(CType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "contentDesc"));
	}
	auto contentDescStart = Msg("contentDescStart", "イベントツリーの起点です。");
	auto contentDescStartBattle = Msg("contentDescStartBattle", "イベントを終了して任意のバトルを開始します。バトル開始後もイベントを続けたい場合は、開始するバトルの「バトル開始」イベントを作成してください。");
	auto contentDescEnd = Msg("contentDescEnd", "シナリオを終了します。済印をつけた場合、このシナリオは解決済みとなって再プレイできなくなります。");
	auto contentDescEndBadEnd = Msg("contentDescEndBadEnd", "ゲームオーバーにしてシナリオを終了します。バトル中に実行した場合は、敗北扱いとなります。");
	auto contentDescChangeArea = Msg("contentDescChangeArea", "イベントを終了して任意のエリアへ移動します。移動後もイベントを続けたい場合は、移動先エリアの「到着」イベントを作成してください。");
	auto contentDescChangeBgImage = Msg("contentDescChangeBgImage", "背景セルを追加もしくは全て交換し、背景を再描画します。画面全体を覆う背景イメージを最背面に配置した場合、これまで配置されていた背景セルは全て消去されます。");
	auto contentDescEffect = Msg("contentDescEffect", "ダメージ・回復・状態変更などの効果を任意のキャラクタに対して発生させます。");
	auto contentDescEffectBreak = Msg("contentDescEffectBreak", "イベントを終了します。使用時イベント中に使った場合は、カードの使用自体が中止されます。");
	auto contentDescLinkStart = Msg("contentDescLinkStart", "現在のイベントツリーの実行を終了し、任意のイベントツリーを実行します。");
	auto contentDescLinkPackage = Msg("contentDescLinkPackage", "現在のイベントの実行を終了し、任意のパッケージイベントを実行します。");
	auto contentDescTalkMessage = Msg("contentDescTalkMessage", "メッセージを表示します。複数の後続コンテントがある場合は、選択肢が表示されます。");
	auto contentDescTalkDialog = Msg("contentDescTalkDialog", "メッセージを表示します。話者の所持クーポンによってメッセージの内容を変える事ができます。複数の後続コンテントがある場合は、選択肢が表示されます。");
	auto contentDescPlayBgm = Msg("contentDescPlayBgm", "BGMを再生もしくは停止します。");
	auto contentDescPlaySound = Msg("contentDescPlaySound", "効果音を再生します。");
	auto contentDescWait = Msg("contentDescWait", "演出などのために、何も起こらない待ち時間を任意秒数入れます。");
	auto contentDescElapseTime = Msg("contentDescElapseTime", "ゲーム内時間を経過させ、効果時間の減少や毒のダメージなどを発生させます。バトルラウンドは経過しません。");
	auto contentDescCallStart = Msg("contentDescCallStart", "任意のイベントツリーを実行し、実行後に現在のイベントツリーへ処理を戻します。");
	auto contentDescCallPackage = Msg("contentDescCallPackage", "任意のパッケージイベントを実行し、実行後に現在のイベントへ処理を戻します。");
	auto contentDescBranchFlag = Msg("contentDescBranchFlag", "フラグの値によって処理を分岐させます。");
	auto contentDescBranchMultiStep = Msg("contentDescBranchMultiStep", "ステップの値がいくつかによって処理を分岐させます。");
	auto contentDescBranchStep = Msg("contentDescBranchStep", "ステップの値が任意の値以上・未満のどちらかによって処理を分岐させます。");
	auto contentDescBranchSelect = Msg("contentDescBranchSelect", "手動または自動でキャラクタを選択し、選択に成功したか、キャンセルもしくは選択に失敗したかによって処理を分岐させます。");
	auto contentDescBranchAbility = Msg("contentDescBranchAbility", "キャラクタの能力に応じた成功判定を行い、成功したか失敗したかによって処理を分岐させます。判定に成功したキャラクタは選択状態になります。");
	auto contentDescBranchRandom = Msg("contentDescBranchRandom", "任意の確率でランダムに処理を分岐させます。");
	auto contentDescBranchLevel = Msg("contentDescBranchLevel", "キャラクタのレベルが任意の値以上・未満のどちらかによって処理を分岐させます。");
	auto contentDescBranchStatus = Msg("contentDescBranchStatus", "キャラクタが任意の状態かそうでないかによって処理を分岐させます。");
	auto contentDescBranchPartyNumber = Msg("contentDescBranchPartyNumber", "パーティの人数が任意の数以上・未満のどちらかによって処理を分岐させます。");
	auto contentDescBranchArea = Msg("contentDescBranchArea", "現在どのエリアにいるかによって処理を分岐させます。バトル中の場合は、バトル直前にいたエリアによって判定を行います。");
	auto contentDescBranchBattle = Msg("contentDescBranchBattle", "現在どのバトルを実行中かによって処理を分岐させます。バトル中でない場合は、常に「その他」へ分岐します。");
	auto contentDescBranchIsBattle = Msg("contentDescBranchIsBattle", "現在バトル中かそうでないかによって処理を分岐させます。");
	auto contentDescBranchCast = Msg("contentDescBranchCast", "任意のキャストが同行中かそうでないかによって処理を分岐させます。");
	auto contentDescBranchItem = Msg("contentDescBranchItem", "任意のアイテムカードを所持しているかいないかによって処理を分岐させます。所持判定において、名前と解説が一致するカードは同一とみなされます。カードを所持しているキャラクタは選択状態になります。");
	auto contentDescBranchSkill = Msg("contentDescBranchSkill", "任意の特殊技能カードを所持しているかいないかによって処理を分岐させます。所持判定において、名前と解説が一致するカードは同一とみなされます。カードを所持しているキャラクタは選択状態になります。");
	auto contentDescBranchInfo = Msg("contentDescBranchInfo", "任意の情報カードを所持しているかいないかによって処理を分岐させます。");
	auto contentDescBranchBeast = Msg("contentDescBranchBeast", "任意の召喚獣を所持しているかいないかによって処理を分岐させます。所持判定において、名前と解説が一致するカードは同一とみなされます。カードを所持しているキャラクタは選択状態になります。");
	auto contentDescBranchMoney = Msg("contentDescBranchMoney", "パーティが任意の金額を所持しているかいないかによって処理を分岐させます。");
	auto contentDescBranchCoupon = Msg("contentDescBranchCoupon", "キャラクタが任意のクーポン(称号)を所持しているかいないかによって処理を分岐させます。クーポンを所持しているキャラクタは選択状態になります。");
	auto contentDescBranchCompleteStamp = Msg("contentDescBranchCompleteStamp", "任意のシナリオに済印がついているかいないかによって処理を分岐させます。");
	auto contentDescBranchGossip = Msg("contentDescBranchGossip", "任意のゴシップ(宿全体で所持するクーポン)があるかないかによって処理を分岐させます。");
	auto contentDescSetFlag = Msg("contentDescSetFlag", "任意のフラグの値を設定します。指定されたフラグを設定しているカードは、TRUEに設定した時に表示され、FALSEに設定した時に非表示にされます。背景セルの表示可否は内部的に変更され、「画面再構築」コンテントなどで背景の再描画を行った時に反映されます。");
	auto contentDescSetStep = Msg("contentDescSetStep", "任意のステップの値を設定します。");
	auto contentDescSetStepUp = Msg("contentDescSetStepUp", "任意のステップの値を1段階増加させます。すでに段階数の最大に達している場合は何もしません。");
	auto contentDescSetStepDown = Msg("contentDescSetStepDown", "任意のステップの値を1段階減少させます。すでに段階数の最小に達している場合は何もしません。");
	auto contentDescReverseFlag = Msg("contentDescReverseFlag", "任意のフラグの値がTRUEの時はFALSEに、FALSEの時はTRUEに設定します。");
	auto contentDescCheckFlag = Msg("contentDescCheckFlag", "任意のフラグの値がTRUEの時だけ後続のイベントを実行します。メッセージやセリフの選択肢として使用した場合は、TRUEの時だけ選択肢が表示されます。");
	auto contentDescGetCast = Msg("contentDescGetCast", "任意のキャストをパーティに同行させます。すでに同行している場合は何もしません。");
	auto contentDescGetItem = Msg("contentDescGetItem", "任意のアイテムカードを、キャラクタの所持カードや荷物袋に追加します。所持カードに追加しようとしてできなかった場合は、荷物袋に入ります。");
	auto contentDescGetSkill = Msg("contentDescGetSkill", "任意の特殊技能カードを、キャラクタの所持カードや荷物袋に追加します。所持カードに追加しようとしてできなかった場合は、荷物袋に入ります。");
	auto contentDescGetInfo = Msg("contentDescGetInfo", "任意の情報カードを入手します。すでに入手済みの場合は何もしません。");
	auto contentDescGetBeast = Msg("contentDescGetBeast", "任意の召喚獣カードを、キャラクタの所持カードや荷物袋に追加します。所持カードに追加しようとしてできなかった場合は、荷物袋に入ります。");
	auto contentDescGetMoney = Msg("contentDescGetMoney", "パーティの所持金を任意額だけ増加させます。");
	auto contentDescGetCoupon = Msg("contentDescGetCoupon", "任意のクーポン(称号)をキャラクタの経歴に追加します。すでに同一名称のクーポンがある場合は、上書きされます。");
	auto contentDescGetCompleteStamp = Msg("contentDescGetCompleteStamp", "任意のシナリオに済印をつけます。");
	auto contentDescGetGossip = Msg("contentDescGetGossip", "任意のゴシップ(宿全体で所持するクーポン)を追加します。");
	auto contentDescLoseCast = Msg("contentDescLoseCast", "任意のキャストの同行を解除します。");
	auto contentDescLoseItem = Msg("contentDescLoseItem", "任意のアイテムカードを所持カードや荷物袋から削除します。削除対象かどうかの判定において、名前と解説が一致するカードは同一と見なされます。");
	auto contentDescLoseSkill = Msg("contentDescLoseSkill", "任意の特殊技能カードを所持カードや荷物袋から削除します。削除対象かどうかの判定において、名前と解説が一致するカードは同一と見なされます。");
	auto contentDescLoseInfo = Msg("contentDescLoseInfo", "任意の情報カードを削除します。");
	auto contentDescLoseBeast = Msg("contentDescLoseBeast", "任意の召喚獣カードを所持カードや荷物袋から削除します。削除対象かどうかの判定において、名前と解説が一致するカードは同一と見なされます。");
	auto contentDescLoseMoney = Msg("contentDescLoseMoney", "パーティの所持金を任意額だけ減少させます。");
	auto contentDescLoseCoupon = Msg("contentDescLoseCoupon", "任意のクーポン(称号)をキャラクタの経歴から除去します。");
	auto contentDescLoseCompleteStamp = Msg("contentDescLoseCompleteStamp", "任意のシナリオの済印を除去します。");
	auto contentDescLoseGossip = Msg("contentDescLoseGossip", "任意のゴシップ(宿全体で所持するクーポン)を削除します。");
	auto contentDescShowParty = Msg("contentDescShowParty", "隠蔽しているパーティを表示します。");
	auto contentDescHideParty = Msg("contentDescHideParty", "表示中のパーティを画面下へ動かして隠蔽します。");
	auto contentDescRedisplay = Msg("contentDescRedisplay", "背景を再描画し、フラグ変更などで表示・非表示状態が内部的に変更された背景セルの状態を画面に反映します。");
	auto contentDescSubstituteStep = Msg("contentDescSubstituteStep", "任意のステップの値またはランダムな値を別のステップへ代入します。");
	auto contentDescSubstituteFlag = Msg("contentDescSubstituteFlag", "任意のフラグの値またはランダムな値を別のフラグへ代入します。");
	auto contentDescBranchStepCmp = Msg("contentDescBranchStepCmp", "任意の2つのステップの値を比較した結果によって処理を分岐させます。");
	auto contentDescBranchFlagCmp = Msg("contentDescBranchFlagCmp", "任意の2つのフラグの値を比較した結果によって処理を分岐させます。");
	auto contentDescBranchRandomSelect = Msg("contentDescBranchRandomSelect", "パーティメンバ・エネミー・同行キャストの中から任意の条件で選択を行い、選択に成功したか失敗したかによって処理を分岐させます。");
	auto contentDescBranchKeyCode = Msg("contentDescBranchKeyCode", "キャラクタ・荷物袋・パーティ全体で任意のキーコードを持つカードを所持しているかいないかによって処理を分岐させます。該当カードを所持しているキャラクタは選択状態になります。");
	auto contentDescCheckStep = Msg("contentDescCheckStep", "任意のステップが指定された状態の時だけ後続のイベントを実行します。メッセージやセリフの選択肢として使用した場合は、条件を満たす時だけ選択肢が表示されます。");
	auto contentDescBranchRound = Msg("contentDescBranchRound", "現在のバトルのラウンド数が任意の値以上・未満のどちらかによって処理を分岐させます。バトル中でない場合は、常に未満側へ分岐します。");
	auto contentDescMoveBgImage = Msg("contentDescMoveBgImage", "セル名称のつけられた背景セルを移動・サイズ変更します。"); // Wsn.1
	auto contentDescReplaceBgImage = Msg("contentDescReplaceBgImage", "セル名称のつけられた背景セルを新しい背景セルに置換します。"); // Wsn.1
	auto contentDescLoseBgImage = Msg("contentDescLoseBgImage", "セル名称のつけられた背景セルを削除します。"); // Wsn.1
	auto contentDescBranchMultiCoupon = Msg("contentDescBranchMultiCoupon", "選択中のメンバがどのクーポン(称号)を所有しているかによって処理を分岐させます。どれも所有していない場合は「全て所有していない」へ分岐します。"); // Wsn.2
	auto contentDescBranchMultiRandom = Msg("contentDescBranchMultiRandom", "複数の後続コンテントへ等確率でランダムで分岐します。"); // Wsn.2
	auto contentDescMoveCard = Msg("contentDescMoveCard", "メニューカードやエネミーカードを移動・サイズ変更します。"); // Wsn.3
	auto contentDescChangeEnvironment = Msg("contentDescChangeEnvironment", "荷物袋の使用の可否など、パーティの状況を設定します。"); // Wsn.4
	auto contentDescBranchVariant = Msg("contentDescBranchVariant", "式の結果の真偽値によって処理を分岐します。"); // Wsn.4
	auto contentDescSetVariant = Msg("contentDescSetVariant", "式の結果をコモン・フラグ・ステップへ代入します。式の結果は、フラグへ代入する場合は真偽値に、ステップへ代入する場合は数値にする必要があります。"); // Wsn.4
	auto contentDescCheckVariant = Msg("contentDescCheckVariant", "式の結果がTRUEの時だけ後続のイベントを実行します。メッセージやセリフの選択肢として使用した場合は、条件を満たす時だけ選択肢が表示されます。"); // Wsn.4
	auto contentDescWsnN = Msg("contentDescWsnN", "%1$sWsn.%2$s以降のシナリオ形式で使用可能です。");

	auto msnGroupVitality = Msg("msnGroupVitality", "生命力");
	auto msnGroupPhysical = Msg("msnGroupPhysical", "肉体");
	auto msnGroupSkill = Msg("msnGroupSkill", "技能");
	auto msnGroupMental = Msg("msnGroupMental", "精神");
	auto msnGroupMagic = Msg("msnGroupMagic", "魔法");
	auto msnGroupEnhance = Msg("msnGroupEnhance", "能力");
	auto msnGroupVanish = Msg("msnGroupVanish", "消滅");
	auto msnGroupCard = Msg("msnGroupCard", "カード");
	auto msnGroupBeast = Msg("msnGroupBeast", "召喚");
	auto msnGroupEtc = Msg("msnGroupEtc", "その他");

	auto msnDelete = Msg("msnDelete", "効果削除");

	auto msnDesc = Msg("msnDesc", "%1$s - %2$s");

	const string motionName(MType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "motionName"));
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
	auto motionNameCancelAction = Msg("motionNameCancelAction", "行動キャンセル"); // CardWirth 1.50
	auto motionNameNoEffect = Msg("motionNameNoEffect", "効果無し"); // Wsn.2

	const string motionDesc(MType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "motionDesc"));
	}
	auto motionDescHeal = Msg("motionDescHeal", "対象の生命点を増加させます。");
	auto motionDescDamage = Msg("motionDescDamage", "対象の生命点を減少させます。");
	auto motionDescAbsorb = Msg("motionDescAbsorb", "対象の生命点を減少させた分だけ使用者の生命点を回復させます。");
	auto motionDescParalyze = Msg("motionDescParalyze", "対象を麻痺させます。麻痺の値が20を超えた場合は石化扱いとなります。麻痺の最大値は40です。全員が麻痺状態になった場合は全滅します。");
	auto motionDescDisParalyze = Msg("motionDescDisParalyze", "対象の麻痺を緩和します。");
	auto motionDescPoison = Msg("motionDescPoison", "対象を中毒状態にします。中毒状態のキャラクタは時間経過でダメージを受けます。中毒の最大値は40です。");
	auto motionDescDisPoison = Msg("motionDescDisPoison", "対象の中毒を緩和します。");
	auto motionDescGetSkillPower = Msg("motionDescGetSkillPower", "対象の特殊技能の使用回数を増加させます。");
	auto motionDescLoseSkillPower = Msg("motionDescLoseSkillPower", "対象の特殊技能の使用回数を減少させます。");
	auto motionDescSleep = Msg("motionDescSleep", "対象を睡眠状態にします。睡眠状態のキャラクタは、行動・回避・抵抗ができなくなります。");
	auto motionDescConfuse = Msg("motionDescConfuse", "対象を混乱状態にします。混乱状態のキャラクタは、手札に「混乱」が配付されます。");
	auto motionDescOverheat = Msg("motionDescOverheat", "対象を激昂状態にします。激昂状態のキャラクタは、手札に「渾身の一撃」が配付されます。");
	auto motionDescBrave = Msg("motionDescBrave", "対象を勇敢状態にします。勇敢状態のキャラクタは、手札に「防御」「見切り」が配付されなくなります。");
	auto motionDescPanic = Msg("motionDescPanic", "対象を恐慌状態にします。恐慌状態のキャラクタは、手札に「防御」「見切り」だけが配付されます。");
	auto motionDescNormal = Msg("motionDescNormal", "対象の精神状態を通常に戻します。");
	auto motionDescBind = Msg("motionDescBind", "対象を呪縛します。呪縛されたキャラクタは、行動・回避ができなくなります。");
	auto motionDescDisBind = Msg("motionDescDisBind", "対象の呪縛を解除します。");
	auto motionDescSilence = Msg("motionDescSilence", "対象を沈黙状態にします。沈黙状態のキャラクタは、発声が必要なカードを使用できなくなります。");
	auto motionDescDisSilence = Msg("motionDescDisSilence", "対象の沈黙状態を解除します。");
	auto motionDescFaceUp = Msg("motionDescFaceUp", "対象を暴露状態にします。暴露状態のキャラクタは、そのステータスや次ラウンドの行動を見る事ができます。");
	auto motionDescFaceDown = Msg("motionDescFaceDown", "対象の暴露状態を解除します。");
	auto motionDescAntiMagic = Msg("motionDescAntiMagic", "対象を魔法無効化状態にします。魔法無効化状態のキャラクタは魔法・物理的魔法属性の効果を受けなくなり、これらの属性のカードを使用できなくなります。");
	auto motionDescDisAntiMagic = Msg("motionDescDisAntiMagic", "対象の魔法無効化状態を解除します。");
	auto motionDescEnhanceAction = Msg("motionDescEnhanceAction", "対象の行動力を変化させます。行動力の増減は行動の成功判定や能力判定の結果に影響します。");
	auto motionDescEnhanceAvoid = Msg("motionDescEnhanceAvoid", "対象の回避力を変化させます。回避力の増減は効果の回避判定の結果に影響します。+10の場合は必ず回避が成功します。-10の場合は必ず失敗します。");
	auto motionDescEnhanceDefense = Msg("motionDescEnhanceDefense", "対象の防御力を変化させます。防御力の増減はダメージ計算の結果に影響します。+10の場合はダメージを受けません。-10の場合は4倍のダメージを受けます。");
	auto motionDescEnhanceResist = Msg("motionDescEnhanceResist", "対象の抵抗力を変化させます。抵抗力の増減は効果への抵抗判定の結果に影響します。+10の場合は必ず抵抗が成功します。-10の場合は必ず失敗します。");
	auto motionDescVanishTarget = Msg("motionDescVanishTarget", "対象を消去します。消去されたキャラクタが戻ってくる事はありません。");
	auto motionDescVanishCard = Msg("motionDescVanishCard", "対象の手札を消去します。対象は、次のラウンドで消去された分だけ山札からカードを引きます。");
	auto motionDescVanishBeast = Msg("motionDescVanishBeast", "対象が所持する召喚獣を消去します。付帯能力(召喚獣召喚効果以外で付与された召喚獣カード)は消去されません。");
	auto motionDescDealAttackCard = Msg("motionDescDealAttackCard", "対象の山札の一番上に「攻撃」を配付します。");
	auto motionDescDealPowerfulAttackCard = Msg("motionDescDealPowerfulAttackCard", "対象の山札の一番上に「渾身の一撃」を配付します。");
	auto motionDescDealCriticalAttackCard = Msg("motionDescDealCriticalAttackCard", "対象の山札の一番上に「会心の一撃」を配付します。");
	auto motionDescDealFeintCard = Msg("motionDescDealFeintCard", "対象の山札の一番上に「フェイント」を配付します。");
	auto motionDescDealDefenseCard = Msg("motionDescDealDefenseCard", "対象の山札の一番上に「防御」を配付します。「防御」を選択したキャラクタは抵抗力が増加し、受けるダメージが減少します。");
	auto motionDescDealDistanceCard = Msg("motionDescDealDistanceCard", "対象の山札の一番上に「見切り」を配付します。「見切り」を選択したキャラクタは回避力が増加します。");
	auto motionDescDealConfuseCard = Msg("motionDescDealConfuseCard", "対象の山札の一番上に「混乱」を配付します。「混乱」を選択したキャラクタは、選択したラウンド中の行動・回避・抵抗ができなくなります。");
	auto motionDescDealSkillCard = Msg("motionDescDealSkillCard", "対象の山札の一番上に、対象が使用できる特殊技能カードを配付します。使用回数が尽きている場合は配付されません。");
	auto motionDescSummonBeast = Msg("motionDescSummonBeast", "対象に任意の召喚獣カードを付与します。");
	auto motionDescCancelAction = Msg("motionDescCancelAction", "対象の現在のラウンドの行動をキャンセルします。すでに行動済みの場合は何もしません。"); // CardWirth 1.50
	auto motionDescNoEffect = Msg("motionDescNoEffect", "いかなる効果も発生しません。視覚効果だけを適用したいなどの時に使用します。"); // Wsn.2

	auto have = Msg("have", "所有");
	auto haveNot = Msg("haveNot", "不所有");
	auto contains = Msg("contains", "含む");
	auto notContains = Msg("notContains", "含まない");
	auto exists = Msg("exists", "存在する");
	auto notExists = Msg("notExists", "存在しない");
	auto matchCard = Msg("matchCard", "一致");
	auto notMatchCard = Msg("notMatchCard", "不一致");
	auto haveForStatus = Msg("haveForStatus", "状態か");
	auto haveNotForStatus = Msg("haveNotForStatus", "状態でないか");

	auto transitionWithSpeed = Msg("transitionWithSpeed", "切替方式 = %1$s ウェイト = %2$s");
	auto transitionNoSpeed = Msg("transitionNoSpeed", "切替方式 = %1$s");

	auto ctStart = Msg("ctStart", "スタートコンテント「%1$s」");
	auto ctStartBattle = Msg("ctStartBattle", "バトルの開始「%1$s」");
	auto ctChangeArea = Msg("ctChangeArea", "エリア移動「%1$s」 切替方式 = %2$s ウェイト = %3$s");
	auto ctChangeAreaWithTransition = Msg("ctChangeAreaWithTransition", "エリア移動「%1$s」 %2$s");
	auto ctChangeAreaClassic = Msg("ctChangeAreaClassic", "エリア移動「%1$s」");
	auto ctEndComplete = Msg("ctEndComplete", "済印をつけて終了");
	auto ctEndNoComplete = Msg("ctEndNoComplete", "済印をつけずに終了");
	auto ctGameOver = Msg("ctGameOver", "敗北・ゲームオーバーコンテント");
	auto ctChangeBgImageWithTransition = Msg("ctChangeBgImageWithTransition", "背景ファイル = %1$s %2$s");
	auto ctChangeBgImageClassic = Msg("ctChangeBgImageClassic", "背景ファイル = %1$s");
	auto ctChangeBgImageFile = Msg("ctChangeBgImageFile", "[%1$s]");
	auto ctEffectSound = Msg("ctEffectSound", "「%1$s」を再生");
	auto ctInitialEffect = Msg("ctInitialEffect", "初期効果あり");
	auto ctInitialEffectWithSound = Msg("ctInitialEffectWithSound", "初期効果あり(%1$s)");
	auto ctIgnite = Msg("ctIgnite", "イベント発火あり");
	auto ctIgniteWithKeyCode = Msg("ctIgniteWithKeyCode", "イベント発火あり(%1$s)");
	auto ctRefAbility = Msg("ctRefAbility", "参照能力 = %1$sと%2$s");
	auto ctAbsorbToSelected = Msg("ctAbsorbToSelected", "吸収者 = 選択メンバ");
	auto ctEffectSimple = Msg("ctEffectSimple", "%1$s レベル%2$s %3$s/%4$s 成功率%5$s%6$s 効果 = %7$s");
	auto ctEffectWith = Msg("ctEffectWith", "%1$s レベル%2$s %3$s/%4$s 成功率%5$s%6$s 効果 = %7$s %8$s");
	auto ctEffectMotion = Msg("ctEffectMotion", "[%1$s]");
	auto ctKeyCodes = Msg("ctKeyCodes", "キーコード = %1$s");
	auto ctNoKeyCode = Msg("ctNoKeyCode", "キーコード無し");
	auto ctEffectBreakConsumeCard = Msg("ctEffectBreakConsumeCard", "効果中断");
	auto ctEffectBreakNoConsumeCard = Msg("ctEffectBreakNoConsumeCard", "効果中断(使用中のカードを消費しない)");
	auto cardVisualWithSpeed = Msg("cardVisualWithSpeed", "%1$s(速度 = %2$s)");
	auto cardVisualWithOverrideSpeed = Msg("cardVisualWithOverrideSpeed", "%1$s(速度 = %2$s カードより優先)");
	auto ctLinkStart = Msg("ctLinkStart", "スタートコンテント「%1$s」へのリンク");
	auto ctLinkPackage = Msg("ctLinkPackage", "パッケージ「%1$s」へのリンク");
	auto ctTalkMessageImage = Msg("ctTalkMessageImage", "[%1$s]");
	auto ctTalkMessage = Msg("ctTalkMessage", "%1$s: %2$s");
	auto ctTalkMessageWithAttrs = Msg("ctTalkMessageWithAttrs", "%1$s: %2$s (%3$s)");
	auto ctTalkMessageNarration = Msg("ctTalkMessageNarration", "%1$s");
	auto ctTalkMessageNarrationWithAttrs = Msg("ctTalkMessageNarrationWithAttrs", "%1$s (%2$s)");
	auto ctTalkMessageSingleLine = Msg("ctTalkMessageSingleLine", "[単行]: %1$s");
	auto ctTalkMessageSingleLineWithAttrs = Msg("ctTalkMessageSingleLineWithAttrs", "[単行]: %1$s (%2$s)");
	auto ctTalkDialog = Msg("ctTalkDialog", "%1$s %2$s: %3$s");
	auto ctTalkDialogWithAttrs = Msg("ctTalkDialogWithAttrs", "%1$s %2$s: %3$s (%4$s)");
	auto ctTalkDialogNoCoupon = Msg("ctTalkDialogNoCoupon", "%1$s: %2$s");
	auto ctTalkDialogNoCouponWithAttrs = Msg("ctTalkDialogNoCouponWithAttrs", "%1$s: %2$s (%3$s)");
	auto ctColumns = Msg("ctColumns", "%1$s列の選択肢");
	auto ctSelectTalker = Msg("ctSelectTalker", "話者を選択する");
	auto ctPlayBGM = Msg("ctPlayBGM", "BGMとして「%1$s」を演奏 Ch. = %2$s フェードイン時間 = %3$s × 0.1秒 音量 = %4$s%% ループ回数 = %5$s");
	auto ctStopBGM = Msg("ctStopBGM", "BGM停止 Ch. = %1$s フェードアウト時間 = %2$s × 0.1秒");
	auto ctPlaySound = Msg("ctPlaySound", "効果音「%1$s」を鳴らす Ch. = %2$s フェードイン時間 = %3$s × 0.1秒 音量 = %4$s%% ループ回数 = %5$s");
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
	auto ctBranchSelectValued = Msg("ctBranchSelectValued", "評価条件(%1$s)");
	auto initialValue = Msg("initialValue", "初期値 = %1$s");
	auto couponValues = Msg("couponValues", "%1$s = %2$s");
	auto ctBranchSelect = Msg("ctBranchSelect", "%1$sから%2$sでメンバを選択");
	auto ctBranchAbility = Msg("ctBranchAbility", "%1$s(%2$s)の%3$sと%4$sで%5$s判定(レベル%6$s)");
	auto ctBranchRandom = Msg("ctBranchRandom", "確率 = %1$s%%");
	auto ctBranchLevelAverage = Msg("ctBranchLevelAverage", "パーティ全員");
	auto ctBranchLevelSelected = Msg("ctBranchLevelSelected", "選択中のメンバ");
	auto ctBranchLevel = Msg("ctBranchLevel", "%1$sのレベルが%2$s以上・未満で分岐");
	auto ctBranchStatus = Msg("ctBranchStatus", "%1$sが%2$s%3$s否かで分岐");
	auto ctBranchPartyNumber = Msg("ctBranchPartyNumber", "人数 = %1$s人");
	auto ctBranchArea = Msg("ctBranchArea", "エリア分岐コンテント");
	auto ctBranchBattle = Msg("ctBranchBattle", "バトル分岐コンテント");
	auto ctBranchIsBattle = Msg("ctBranchIsBattle", "戦闘中判定分岐コンテント");
	auto ctBranchCast = Msg("ctBranchCast", "キャストカード「%1$s」の同行有無で分岐");
	auto ctBranchSkill = Msg("ctBranchSkill", "特殊技能カード「%1$s」の%2$sで分岐(%3$sに%4$s枚) %5$s");
	auto ctBranchItem = Msg("ctBranchItem", "アイテムカード「%1$s」の%2$sで分岐(%3$sに%4$s枚) %5$s");
	auto ctBranchBeast = Msg("ctBranchBeast", "召喚獣カード「%1$s」の%2$sで分岐(%3$sに%4$s枚) %5$s");
	auto ctBranchInfo = Msg("ctBranchInfo", "情報カード「%1$s」の有無で分岐");
	auto ctBranchMoney = Msg("ctBranchMoney", "分岐金額 = %1$ssp");
	auto ctBranchCoupon = Msg("ctBranchCoupon", "称号「%1$s」の%2$sで分岐(%3$s)");
	auto ctBranchCouponExpandSPChars = Msg("ctBranchCouponExpandSPChars", "称号「%1$s」の%2$sで分岐(%3$s) 特殊文字を展開する"); // Wsn.4
	auto ctBranchCouponMulti = Msg("ctBranchCouponMulti", "称号%1$sの%2$sの%3$sで分岐(%4$s)"); // Wsn.2
	auto ctBranchCouponMultiExpandSPChars = Msg("ctBranchCouponMultiExpandSPChars", "称号%1$sの%2$sの%3$sで分岐(%4$s) 特殊文字を展開する"); // Wsn.4
	auto ctBranchCompleteStamp = Msg("ctBranchCompleteStamp", "シナリオ「%1$s」が終了済みか否かで分岐");
	auto ctBranchGossip = Msg("ctBranchGossip", "ゴシップ「%1$s」の有無で分岐");
	auto ctBranchGossipExpandSPChars = Msg("ctBranchGossipExpandSPChars", "ゴシップ「%1$s」の有無で分岐 特殊文字を展開する"); // Wsn.4
	auto ctSetFlag = Msg("ctSetFlag", "フラグ「%1$s」を[%2$s]に変更 %3$s");
	auto ctCardSpeed = Msg("ctCardSpeed", "カード速度 = %1$s");
	auto ctCardSpeedDefault = Msg("ctCardSpeedDefault", "標準");
	auto ctOverrideCardSpeed = Msg("ctOverrideCardSpeed", "カード速度 = %1$s (カード本体より優先)");
	auto ctSetStep = Msg("ctSetStep", "ステップ「%1$s」を[%2$s]に変更");
	auto ctSetStepUp = Msg("ctSetStepUp", "ステップ「%1$s」の値を1増加");
	auto ctSetStepDown = Msg("ctSetStepDown", "ステップ「%1$s」の値を1減少");
	auto ctReverseFlag = Msg("ctReverseFlag", "フラグ「%1$s」の値を反転 %2$s");
	auto ctCheckFlag = Msg("ctCheckFlag", "フラグ「%1$s」の値が[%2$s]であれば後続のイベントが出現");
	auto ctGetCast = Msg("ctGetCast", "キャストカード「%1$s」を同行させる(%2$s)");
	auto ctGetSkill = Msg("ctGetSkill", "特殊技能カード「%1$s」を獲得(%2$sに%3$s枚)");
	auto ctGetItem = Msg("ctGetItem", "アイテムカード「%1$s」を獲得(%2$sに%3$s枚)");
	auto ctGetBeast = Msg("ctGetBeast", "召喚獣カード「%1$s」を獲得(%2$sに%3$s枚)");
	auto ctGetInfo = Msg("ctGetInfo", "情報カード「%1$s」を獲得");
	auto ctGetMoney = Msg("ctGetMoney", "獲得金額 = %1$ssp");
	auto ctGetCoupon = Msg("ctGetCoupon", "称号「%1$s(%2$s)」を獲得(%3$s)");
	auto ctGetCouponExpandSPChars = Msg("ctGetCouponExpandSPChars", "称号「%1$s(%2$s)」を獲得(%3$s) 特殊文字を展開する"); // Wsn.4
	auto ctGetCompleteStamp = Msg("ctGetCompleteStamp", "シナリオ「%1$s」を終了済みにする");
	auto ctGetGossip = Msg("ctGetGossip", "ゴシップ「%1$s」を獲得");
	auto ctGetGossipExpandSPChars = Msg("ctGetGossipExpandSPChars", "ゴシップ「%1$s」を獲得 特殊文字を展開する"); // Wsn.4
	auto ctLoseCardAll = Msg("ctLoseCardAll", "全て");
	auto ctLoseCardCount = Msg("ctLoseCardCount", "%1$s枚");
	auto ctLoseCast = Msg("ctLoseCast", "キャストカード「%1$s」の同行を解除");
	auto ctLoseSkill = Msg("ctLoseSkill", "特殊技能カード「%1$s」を喪失(%2$sから%3$s)");
	auto ctLoseItem = Msg("ctLoseItem", "アイテムカード「%1$s」を喪失(%2$sから%3$s)");
	auto ctLoseBeast = Msg("ctLoseBeast", "召喚獣カード「%1$s」を喪失(%2$sから%3$s)");
	auto ctLoseInfo = Msg("ctLoseInfo", "情報カード「%1$s」を喪失");
	auto ctLoseMoney = Msg("ctLoseMoney", "喪失金額 = %1$ssp");
	auto ctLoseCoupon = Msg("ctLoseCoupon", "称号「%1$s」を喪失(%2$s)");
	auto ctLoseCouponExpandSPChars = Msg("ctLoseCouponExpandSPChars", "称号「%1$s」を喪失(%2$s) 特殊文字を展開する"); // Wsn.4
	auto ctLoseCompleteStamp = Msg("ctLoseCompleteStamp", "シナリオ「%1$s」の終了印を削除");
	auto ctLoseGossip = Msg("ctLoseGossip", "ゴシップ「%1$s」を喪失");
	auto ctLoseGossipExpandSPChars = Msg("ctLoseGossipExpandSPChars", "ゴシップ「%1$s」を喪失 特殊文字を展開する"); // Wsn.4
	auto ctShowParty = Msg("ctShowParty", "パーティの表示 %1$s");
	auto ctHideParty = Msg("ctHideParty", "パーティの隠蔽 %1$s");
	auto ctRedisplayWithTransition = Msg("ctRedisplayWithTransition", "%1$s");
	auto ctRedisplayClassic = Msg("ctRedisplayClassic", "画面再構築コンテント");
	auto ctSubstituteStep = Msg("ctSubstituteStep", "ステップ [%1$s] の値をステップ [%2$s] に代入");
	auto ctSubstituteFlag = Msg("ctSubstituteFlag", "フラグ [%1$s] の値をフラグ [%2$s] に代入 %3$s");
	auto ctBranchStepCmp = Msg("ctBranchStepCmp", "ステップ [%1$s] と [%2$s] の値を比較");
	auto ctBranchFlagCmp = Msg("ctBranchFlagCmp", "フラグ [%1$s] と [%2$s] の値を比較");
	auto ctSubstituteStepFromRandom = Msg("ctSubstituteStepFromRandom", "ランダム値をステップ [%1$s] に代入");
	auto ctSubstituteStepFromSelectedPlayer = Msg("ctSubstituteStepFromSelectedPlayer", "選択メンバ番号をステップ [%1$s] に代入"); // Wsn.2
	auto ctSubstituteFlagFromRandom = Msg("ctSubstituteFlagFromRandom", "ランダム値をフラグ [%1$s] に代入 %2$s");
	auto randomValue = Msg("randomValue", "ランダム値");
	auto selectedPlayerValue = Msg("selectedPlayerValue", "選択メンバ番号"); // Wsn.2
	auto ctRandomSelect = Msg("ctRandomSelect", "%2$sのキャラクタを選択(%1$s)");
	auto ctRandomSelectN = Msg("ctRandomSelectN", "キャラクタを選択(%1$s)");
	auto ctRandomSelectInvert = Msg("ctRandomSelectInvert", "%2$sでないキャラクタを選択(%1$s)");
	auto castRange0 = Msg("castRange0", "対象無し");
	auto castRange1 = Msg("castRange1", "%1$s全体");
	auto castRange2 = Msg("castRange2", "%1$s全体または%2$s全体");
	auto castRange3 = Msg("castRange3", "フィールド全体");
	auto ctBranchKeyCodeWithConditionAllType = Msg("ctBranchKeyCodeWithConditionAllType", "キーコード「%1$s」を%2$sカードの%3$sで分岐(%4$s) %5$s");
	auto ctBranchKeyCodeWithCondition = Msg("ctBranchKeyCodeWithCondition", "キーコード「%1$s」を%2$s%3$sカードの%4$sで分岐(%5$s) %6$s");
	auto ctBranchKeyCodeWithConditionAllTypeForSelectedCard = Msg("ctBranchKeyCodeWithConditionAllTypeForSelectedCard", "キーコード「%1$s」を%2$s選択カードが%3$sか否かで分岐");
	auto ctBranchKeyCodeWithConditionForSelectedCard = Msg("ctBranchKeyCodeWithConditionForSelectedCard", "キーコード「%1$s」を%2$s%3$sの選択カードが%4$sか否かで分岐");
	auto ctSelectFoundCard = Msg("ctSelectFoundCard", "該当カードを選択する");
	auto noSelectFoundCard = Msg("noSelectFoundCard", "該当カードを選択しない");
	auto ctCheckStep = Msg("ctCheckStep", "ステップ「%1$s」が[%2$s]%3$s後続のイベントが出現");
	auto ctBranchRound = Msg("ctBranchRound", "バトルが%1$sラウンド%2$sか否かで分岐");
	auto ctMoveAndResizeBgImageWithTransition = Msg("ctMoveAndResizeBgImageWithTransition", "背景「%1$s」を%2$sで右へ%3$s、下へ%4$sポイント移動し、%5$sで%6$s×%7$sにリサイズ %8$s");
	auto ctMoveBgImageWithTransition = Msg("ctMoveBgImageWithTransition", "背景「%1$s」を%2$sで右へ%3$s、下へ%4$sポイント移動 %5$s");
	auto ctResizeBgImageWithTransition = Msg("ctResizeBgImageWithTransition", "背景「%1$s」を%2$sで%3$s×%4$sにリサイズ %5$s");
	auto ctMoveAndResizeBgImageClassic = Msg("ctMoveAndResizeBgImageClassic", "背景「%1$s」を%2$sで右へ%3$s、下へ%4$sポイント移動し、%5$sで%6$s×%7$sにリサイズ");
	auto ctMoveBgImageClassic = Msg("ctMoveBgImageClassic", "背景「%1$s」を%2$sで右へ%3$s、下へ%4$sポイント移動");
	auto ctResizeBgImageClassic = Msg("ctResizeBgImageClassic", "背景「%1$s」を%2$sで%3$s×%4$sにリサイズ");
	auto ctMoveBgImageNoSet = Msg("ctMoveBgImageNoSet", "背景「%1$s」に対して何も行わない");
	auto ctReplaceBgImageWithTransition = Msg("ctReplaceBgImageWithTransition", "背景「%1$s」を置換 背景ファイル = %2$s %3$s");
	auto ctReplaceBgImageClassic = Msg("ctReplaceBgImageClassic", "背景「%1$s」を置換 背景ファイル = %2$s");
	auto ctLoseBgImageWithTransition = Msg("ctLoseBgImageWithTransition", "背景「%1$s」を削除 %2$s");
	auto ctLoseBgImageClassic = Msg("ctLoseBgImageClassic", "背景「%1$s」を削除");
	auto ctBranchMultiCoupon = Msg("ctBranchMultiCoupon", "%1$sの称号所有状態で分岐"); // Wsn.2
	auto ctBranchMultiCouponExpandSPChars = Msg("ctBranchMultiCouponExpandSPChars", "%1$sの称号所有状態で分岐 特殊文字を展開する"); // Wsn.4
	auto ctBranchMultiRandom = Msg("ctBranchMultiRandom", "ランダム多岐分岐コンテント"); // Wsn.2
	auto couponNames = Msg("couponNames", "「%1$s」"); // Wsn.2
	auto couponNamesSeparator = Msg("couponNamesSeparator", ""); // Wsn.2
	auto matchingTypeAnd = Msg("matchingTypeAnd", "全て"); // Wsn.2
	auto matchingTypeOr = Msg("matchingTypeOr", "どれか一つ"); // Wsn.2
	auto ctMoveCard = Msg("ctMoveCard", "カードグループ「%1$s」を%2$sで右へ%3$s、下へ%4$sポイント移動(スケール = %5$s レイヤ = %6$s) %7$s"); // Wsn.3
	auto ctMoveCardNoSet = Msg("ctMoveCardNoSet", "カードグループ「%1$s」を移動しない(スケール = %2$s レイヤ = %3$s) %4$s"); // Wsn.3
	auto noChangeScale = Msg("noChangeScale", "変更無し"); // Wsn.3
	auto noChangeLayer = Msg("noChangeLayer", "変更無し"); // Wsn.3
	auto ctChangeEnvironmentNotSet = Msg("ctChangeEnvironmentNotSet", "状況を変更しない"); // Wsn.4
	auto ctChangeEnvironment = Msg("ctChangeEnvironment", "%1$s"); // Wsn.4
	auto ctEnvironmentEnabled = Msg("ctEnvironmentEnabled", "%1$sを%2$s"); // Wsn.5
	auto ctBranchVariant = Msg("ctBranchVariant", "式〔 %1$s 〕"); // Wsn.4
	auto ctSetVariant = Msg("ctSetVariant", "%1$s =〔 %2$s 〕"); // Wsn.4
	auto ctFlagName = Msg("ctFlagName", "フラグ「%1$s」"); // Wsn.4
	auto ctStepName = Msg("ctStepName", "ステップ「%1$s」"); // Wsn.4
	auto ctVariantName = Msg("ctVariantName", "コモン「%1$s」"); // Wsn.4
	auto ctCheckVariant = Msg("ctCheckVariant", "式〔 %1$s 〕"); // Wsn.4

	auto ctBranchSkillForSelectedCard = Msg("ctBranchSkillForSelectedCard", "特殊技能カード「%1$s」と選択カードの%2$sで分岐");
	auto ctBranchItemForSelectedCard = Msg("ctBranchItemForSelectedCard", "アイテムカード「%1$s」と選択カードの%2$sで分岐");
	auto ctBranchBeastForSelectedCard = Msg("ctBranchBeastForSelectedCard", "召喚獣カード「%1$s」と選択カードの%2$sで分岐");
	auto ctGetSkillForSelectedCard = Msg("ctGetSkillForSelectedCard", "特殊技能カード「%1$s」を獲得(選択カードと交換)");
	auto ctGetItemForSelectedCard = Msg("ctGetItemForSelectedCard", "アイテムカード「%1$s」を獲得(選択カードと交換)");
	auto ctGetBeastForSelectedCard = Msg("ctGetBeastForSelectedCard", "召喚獣カード「%1$s」を獲得(選択カードと交換)");
	auto ctLoseSkillForSelectedCard = Msg("ctLoseSkillForSelectedCard", "特殊技能カードを喪失(選択カード)");
	auto ctLoseItemForSelectedCard = Msg("ctLoseItemForSelectedCard", "アイテムカードを喪失(選択カード)");
	auto ctLoseBeastForSelectedCard = Msg("ctLoseBeastForSelectedCard", "召喚獣カードを喪失(選択カード)");

	auto nameWithID = Msg("nameWithID", "%1$s.%2$s");

	auto defaultStartName = Msg("defaultStartName", "イベント開始");

	auto oggMayNotCorrespond = Msg("oggMayNotCorrespond", "Oggはプレイヤーの環境によって再生できない事があります。");
	auto mp3LoopMayNotCorrespond = Msg("mp3LoopMayNotCorrespond", "MP3はプレイヤーの環境によってループ再生されない事があります。");

	auto playingOption = Msg("playingOption", "再生オプション"); // Wsn.1
	auto playingVolume = Msg("playingVolume", "音量"); // Wsn.1
	auto playingVolumePer = Msg("playingVolumePer", "%"); // Wsn.1
	auto loopCount = Msg("loopCount", "ループ回数"); // Wsn.1
	auto loopCountHint = Msg("loopCountHint", "(0 = ∞)"); // Wsn.1
	auto playingChannel = Msg("playingChannel", "Ch."); // Wsn.1
	auto mainChannel = Msg("mainChannel", "主音声"); // Wsn.1
	auto subChannel = Msg("subChannel", "副音声"); // Wsn.1
	auto fadeIn = Msg("fadeIn", "フェードイン時間"); // Wsn.1
	auto fadeInHint = Msg("fadeInHint", "× 0.1秒"); // Wsn.1
	auto warningVolume = Msg("warningVolume", "音量の設定はWsn.1以降の形式のシナリオしか使用できません。"); // Wsn.1
	auto warningLoopCount = Msg("warningLoopCount", "ループ回数の設定はWsn.1以降の形式のシナリオしか使用できません。"); // Wsn.1
	auto warningChannel= Msg("warningChannel", "再生チャンネルの設定はWsn.1以降の形式のシナリオしか使用できません。"); // Wsn.1
	auto warningFadeIn = Msg("warningFadeIn", "フェードイン時間の設定はWsn.1以降の形式のシナリオしか使用できません。"); // Wsn.1
	auto warningContinueBGM = Msg("warningContinueBGM", "バトル開始時のBGM継続はWsn.3以降の形式のシナリオでしか機能しません。"); // Wsn.3

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
	auto filterScenarioSave = Msg("filterScenarioSave", "WSN(XML)形式のシナリオ (*.wsn)");
	auto filterScenarioSaveDir = Msg("filterScenarioSaveDir", "展開されたWSN(XML)形式シナリオ (Summary.xml)");
	auto filterScenarioSaveClassic = Msg("filterScenarioSaveClassic", "クラシックシナリオ (Summary.wsm)");
	auto filterScenarioSaveClassic7 = Msg("filterScenarioSaveClassic7", "CardWirthNext 1.60形式としてエクスポート (Summary.wsm)");
	auto filterScenarioSaveZip = Msg("filterScenarioSaveZip", "ZIP圧縮されたクラシックシナリオ (*.zip)");
	auto filterScenarioSaveCab = Msg("filterScenarioSaveCab", "CAB圧縮されたクラシックシナリオ (*.cab)");
	auto filterScenarioSaveZip7 = Msg("filterScenarioSaveZip7", "ZIP圧縮されたCardWirthNext 1.60形式としてエクスポート (*.zip)");
	auto filterScenarioSaveCab7 = Msg("filterScenarioSaveCab7", "CAB圧縮されたCardWirthNext 1.60形式としてエクスポート (*.cab)");
	auto warningXToClassic = Msg("warningXToClassic", "WSN(XML)形式のシナリオをクラシック形式に変換すると一部データが失われる可能性がある他、対応していない形式の素材で不具合が発生する恐れがあります。\nクラシック形式で保存しますか？");
	auto saveToNotEmptyDir = Msg("saveToNotEmptyDir", "%1$sは空ではありません。\n本当にここにシナリオを保存しますか？");
	auto notScenario = Msg("notScenario", "%1$sはシナリオ圧縮ファイルではありません");
	auto zipError = Msg("zipError", "%1$sの展開に失敗しました。");
	auto loadError = Msg("loadError", "%1$sの読み込みに失敗しました。");
	auto saveError = Msg("saveError", "%1$sの保存に失敗しました。");
	auto loadErrorStatus = Msg("loadErrorStatus", "%1$sの読み込みに失敗");
	auto loadErrorStatusCount = Msg("loadErrorStatusCount", "%1$s件のシナリオの読み込みに失敗");
	auto scenarioNotFound = Msg("scenarioNotFound", "%1$sは存在しないか、シナリオではありません。履歴から削除しますか？");
	auto scenarioNotFoundForBookmark = Msg("scenarioNotFoundForBookmark", "%1$sは存在しないか、シナリオではありません。ブックマークを削除しますか？");

	auto dlgTitScenarioLoadErrors = Msg("dlgTitScenarioLoadErrors", "シナリオファイル読込エラー");
	auto scenarioLoadErrors = Msg("scenarioLoadErrors", "「%1$s(%2$s)」の読み込み中に、以下のファイルでエラーが発生しました。これらのファイルは無視され、次回の保存時に削除されます。\nこのままシナリオを開いてよろしいですか？");
	auto scenarioLoadErrorsNoFileName = Msg("scenarioLoadErrorsNoFileName", "「%1$s」の読み込み中に、以下のファイルでエラーが発生しました。これらのファイルは無視され、次回の保存時に削除されます。\nこのままシナリオを開いてよろしいですか？");

	/// データウィンドウ
	auto areasTabName = Msg("areasTabName", "テーブル");
	auto areaStatus = Msg("areaStatus", "%2$s件の%1$s");
	auto flagTabName = Msg("flagTabName", "状態変数");
	auto flagStatus = Msg("flagStatus", "%2$s個の%1$s");
	auto flagStatusSel = Msg("flagStatusSel", "%1$s (%2$s個を選択)");
	auto scenarioView = Msg("scenarioView", "シナリオビューリスト");
	auto variableView = Msg("variableView", "状態変数インスペクタ");

	auto reNumberingAll = Msg("reNumberingAll", "全てのエリアやカードのIDを1から振り直します。\nよろしいですか？");

	auto dlgTitReNumbering = Msg("dlgTitReNumbering", "IDの振り直し");
	auto reNumbering = Msg("reNumbering", "IDの振り直し");
	auto reNumbering1 = Msg("reNumbering1", "%1$s「%2$s」以降のIDを");
	auto reNumbering2 = Msg("reNumbering2", "番から順に振り直す"); // reNumbering1と同様のパラメータを取る

	/// エリアのテーブル。
	auto areaDirRoot = Msg("areaDirRoot", "Scenario");
	auto areaDirNew = Msg("areaDirNew", "新規フォルダ");
	auto areaId = Msg("areaId", "ID");
	auto areaName = Msg("areaName", "名称");
	auto areaCount = Msg("areaCount", "利用数");
	auto areaNew = Msg("areaNew", "新規エリア");
	auto battleNew = Msg("battleNew", "新規バトル");
	auto packageNew = Msg("packageNew", "新規パッケージ");
	auto areaDirName = Msg("areaDirName", "フォルダ名");

	/// フラグのディレクトリ。
	auto flagDirRoot = Msg("flagDirRoot", "Data");
	auto flagDirNew = Msg("flagDirNew", "新規フォルダ");

	/// フラグ/ステップのテーブル。
	auto flagName = Msg("flagName", "名称");
	auto flagInit = Msg("flagInit", "初期値");
	auto flagCount = Msg("flagCount", "利用数");

	auto variableInitialization = Msg("variableInitialization", "初期化タイミング"); /// Wsn.4
	const string variableInitializationName(VariableInitialization id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "variableInitializationName"));
	}
	auto variableInitializationNameLeave = Msg("variableInitializationNameLeave", "シナリオ終了時");
	auto variableInitializationNameComplete = Msg("variableInitializationNameComplete", "済印をつけた時");
	auto variableInitializationNameEventExit = Msg("variableInitializationNameEventExit", "イベント終了時");
	auto variableInitializationNameNone = Msg("variableInitializationNameNone", "初期化しない");

	auto variableInitializationShort = Msg("variableInitializationShort", "初期化"); /// Wsn.4
	const string variableInitializationShortName(VariableInitialization id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "variableInitializationShortName"));
	}
	auto variableInitializationShortNameLeave = Msg("variableInitializationShortNameLeave", "シナリオ終了");
	auto variableInitializationShortNameComplete = Msg("variableInitializationShortNameComplete", "済印つき終了");
	auto variableInitializationShortNameEventExit = Msg("variableInitializationShortNameEventExit", "イベント終了");
	auto variableInitializationShortNameNone = Msg("variableInitializationShortNameNone", "しない");

	const string warningVariableInitialization = Msg("warningVariableInitialization", "初期化タイミングの指定は、Wsn.4以降の形式のシナリオでしか行なえません。");

	/// フラグ設定ダイアログ関連。
	auto dlgTitFlag = Msg("dlgTitFlag", "フラグの設定");
	auto dlgLblFlagName = Msg("dlgLblFlagName", "フラグ名");
	auto dlgLblFlagInit = Msg("dlgLblFlagInit", "初期値");
	auto dlgLblFlagTrue = Msg("dlgLblFlagTrue", "TRUE");
	auto dlgLblFlagFalse = Msg("dlgLblFlagFalse", "FALSE");
	auto flagOnValue = Msg("flagOnValue", "TRUEの値");
	auto flagOffValue = Msg("flagOffValue", "FALSEの値");

	/// ステップ設定ダイアログ関連。
	auto dlgTitStep = Msg("dlgTitStep", "ステップの設定");
	auto dlgLblStepName = Msg("dlgLblStepName", "ステップ名");
	auto dlgLblStepInit = Msg("dlgLblStepInit", "初期値");
	auto stepValueForWarning = Msg("stepValueForWarning", "値");
	auto stepCount = Msg("stepCount", "段階数");

	/// コモン設定ダイアログ関連。
	auto dlgTitVariant = Msg("dlgTitVariant", "コモンの設定");
	auto variantName = Msg("variantName", "コモン名");
	auto numberValue = Msg("numberValue", "数値");
	auto stringValue = Msg("stringValue", "文字列値");
	auto booleanValue = Msg("booleanValue", "真偽値");
	auto listValue = Msg("listValue", "リスト"); // Wsn.5
	auto structValue = Msg("structValue", "構造体(%$1s)"); // Wsn.5

	auto variantValueHint = Msg("variantValueHint", "書式:\n数値 = 9999\n文字列 = \"文字列\"\n真偽値 = TRUE または FALSE\n※ 文字列内に\"を入れる時は\"\"と記述");
	auto warningInvalidVariantValue = Msg("warningInvalidVariantValue", "書式が正しくありません。\n\n%1$s");

	/// 貼紙設定ダイアログ関連。
	auto dlgTitSummary = Msg("dlgTitSummary", "概略の設定 - [ %1$s ]");
	auto summaryPreview = Msg("summaryPreview", "表示イメージ");
	auto baseData = Msg("baseData", "基本データ");
	auto etcData = Msg("etcData", "詳細データ");
	auto targetLevelSame = Msg("targetLevelSame", "対象レベル：%1$s");
	auto targetLevelHL = Msg("targetLevelHL", "対象レベル：%1$s ～ %2$s");
	auto targetLevelL = Msg("targetLevelL", "対象レベル：%1$s ～");
	auto targetLevelH = Msg("targetLevelH", "対象レベル： ～ %1$s");
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

	auto dataVersion = Msg("dataVersion", "データバージョン");
	auto dataVersionName = Msg("dataVersionName", "%1$s - %2$s");

	auto loadScaledImage = Msg("loadScaledImage", "スケーリングされたイメージを使用する");
	auto loadScaledImageHint = Msg("loadScaledImageHint", "\"image.bmp\"という名前のファイルを2倍スケールで表示する時、\n\"image.x2.bmp\"があれば代わりに表示します");

	auto warningIncludedPNGImage = Msg("warningIncludedPNGImage", "CardWirth 1.50以前では、格納されたPNGイメージの読み込みでエラーが発生します。メニューカード・背景セル・メッセージの話者以外では使用しないでください。");
	auto warningIncludedGIFImage = Msg("warningIncludedGIFImage", "CardWirth 1.50以前では、格納されたGIFイメージの読み込みでエラーが発生します。メニューカード・背景セル・メッセージの話者以外では使用しないでください。");
	auto pngMayNotCorrespond = Msg("pngMayNotCorrespond", "CardWirth 1.29以前では、PNGイメージの読み込みでエラーが発生します。");
	auto gifMayNotCorrespond = Msg("gifMayNotCorrespond", "CardWirth 1.29以前では、GIFイメージの読み込みでエラーが発生します。");

	auto warningInvalidFileExtensionImage = Msg("warningInvalidFileExtensionImage", "イメージとして使用できない拡張子のファイルが指定されています。");
	auto warningInvalidFileExtensionSound = Msg("warningInvalidFileExtensionSound", "音声として使用できない拡張子のファイルが指定されています。");

	auto warningInvalidSJISCharacter = Msg("warningInvalidSJISCharacter", "クラシックなシナリオで使用できない文字「%1$s」が含まれています。");
	auto warningInvalidSJISCharacterWithName = Msg("warningInvalidSJISCharacterWithName", "%1$sにクラシックなシナリオで使用できない文字「%2$s」が含まれています。");

	/// エリア・戦闘・パッケージウィンドウ。
	auto noRefArea = Msg("noRefArea", "カード配置参照無し");
	auto areaViewFlagDesc = Msg("areaViewFlagDesc", "フラグ");
	auto areaViewRefAreaDesc = Msg("areaViewRefAreaDesc", "参照");
	auto refFlags = Msg("refFlags", "参照フラグ");
	auto allCheckFlag = Msg("allCheckFlag", "全てTRUE/全てFALSE");

	auto inheritBackground = Msg("inheritBackground", "背景継承あり");
	auto inheritBackgroundHint = Msg("inheritBackgroundHint", "これまでに表示されている背景セルを消去せず、新しいセルを追加します。\nフラグ・セル名称・レイヤ設定の無いフルサイズのイメージセルを1枚目に設定した場合は、\n背景継承を行いません。");
	auto notInheritBackground = Msg("notInheritBackground", "背景継承無し");
	auto notInheritBackgroundHint = Msg("notInheritBackgroundHint", "これまでに表示されている背景セルを消去して新しいセルを表示します。\nフラグ・セル名称・レイヤ設定の無いフルサイズのイメージセルを1枚目に設定した場合は、\n背景継承を行いません。");

	auto left = Msg("left", "X");
	auto top = Msg("top", "Y");
	auto width = Msg("width", "幅");
	auto height = Msg("height", "高");
	auto scale = Msg("scale", "拡大率");
	auto scalePer = Msg("scalePer", "%");
	auto layer = Msg("layer", "レイヤ");
	auto layerHint = Msg("layerHint", "(標準 = %1$s)");
	auto bgImageForeground = Msg("bgImageForeground", "カードよりも前に表示");
	auto bgImageCellName = Msg("bgImageCellName", "セル名称");
	auto hasActions = Msg("hasActions", "アクションの有無");

	auto areaViewStatus = Msg("areaViewStatus", "%1$s [%2$s] - %3$s");
	auto areaViewStatusNoSummary = Msg("areaViewStatusNoSummary", "%1$s [%2$s]");
	auto areaViewStatusNoFlag = Msg("areaViewStatusNoFlag", "フラグ指定無し");
	auto areaViewStatusWithFlag = Msg("areaViewStatusWithFlag", "フラグ = %1$s");
	auto areaViewStatusWithLayer = Msg("areaViewStatusWithLayer", "レイヤ = %1$s"); // Wsn.1
	auto areaViewStatusWithCardSpeed = Msg("areaViewStatusWithCardSpeed", "速度 = %1$s"); // Wsn.4
	auto areaViewStatusImageIncluding = Msg("areaViewStatusImageIncluding", "イメージ格納");
	auto areaViewStatusSelCard = Msg("areaViewStatusSelCard", "%1$s枚のカード");
	auto areaViewStatusSelBack = Msg("areaViewStatusSelBack", "%1$s枚の背景");
	auto areaViewStatusEnemyCard = Msg("areaViewStatusEnemyCard", "%1$s.%2$s");

	auto viewNameSceneTab = Msg("viewNameSceneTab", "%2$s.%3$s");
	auto viewNameEventTab = Msg("viewNameEventTab", "%2$s.%3$s");

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
	auto pcCell = Msg("pcCell", "プレイヤーキャラクタセル");
	auto pcCellNoSet = Msg("pcCellNoSet", "(指定無し)");
	auto cellPCNumber = Msg("cellPCNumber", "表示するキャラクタ");
	auto cellNoSet = Msg("cellNoSet", "(指定無し)");
	auto cardGroup = Msg("cardGroup", "カードグループ");

	auto nameWithCellName = Msg("nameWithCellName", "[%1$s] %2$s");
	auto nameWithCardGroup = Msg("nameWithCardGroup", "[%1$s] %2$s");

	/// カード/背景配置領域関連。
	auto dlgTitDropCard = Msg("dlgTitDropCard", "カード画像の追加");
	auto dlgMsgDropCard = Msg("dlgMsgDropCard", "カード画像をシナリオ" ~ DIR ~ "にコピーしますか？\n%1$s");
	auto dlgTitDropBack = Msg("dlgTitDropBack", "背景画像の追加");
	auto dlgMsgDropBack = Msg("dlgMsgDropBack", "背景画像をシナリオ" ~ DIR ~ "にコピーしますか？\n%1$s");

	auto refFlag = Msg("refFlag", "フラグ参照先");
	auto noFlagRef = Msg("noFlagRef", "参照無し");
	auto cardPosition = Msg("cardPosition", "カード位置");
	auto backPosition = Msg("backPosition", "配置");
	auto bgImageSettings = Msg("bgImageSettings", "簡単設定");
	auto bgImageSettingCustom = Msg("bgImageSettingCustom", "カスタム");
	auto bgImageSettingOriginal = Msg("bgImageSettingOriginal", "元のサイズ");
	auto enemyCardBase = Msg("enemyCardBase", "基本設定");
	auto dlgTitMenuCard = Msg("dlgTitMenuCard", "メニューカードの設定 [ %1$s ]");
	auto dlgTitNewMenuCard = Msg("dlgTitNewMenuCard", "メニューカードの作成");
	auto dlgTitBgImage = Msg("dlgTitBgImage", "背景画像の設定");
	auto dlgTitNewBgImage = Msg("dlgTitNewBgImage", "背景画像の作成");
	auto dlgTitTextCell = Msg("dlgTitTextCell", "テキストセルの設定");
	auto dlgTitNewTextCell = Msg("dlgTitNewTextCell", "テキストセルの作成");
	auto dlgTitColorCell = Msg("dlgTitColorCell", "カラーセルの設定");
	auto dlgTitNewColorCell = Msg("dlgTitNewColorCell", "カラーセルの作成");
	auto dlgTitPCCell = Msg("dlgTitPCCell", "プレイヤーキャラクタセルの設定");
	auto dlgTitNewPCCell = Msg("dlgTitNewPCCell", "プレイヤーキャラクタセルの作成");
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
	auto antialias = Msg("antialias", "アンチエイリアス"); // Wsn.4
	auto bordering = Msg("bordering", "縁取り");
	auto borderingWidth = Msg("borderingWidth", "幅:");
	auto borderingColor = Msg("borderingColor", "縁取り色");
	auto pcCellExpanding = Msg("pcCellExpanding", "セルに合わせて拡大・縮小する");
	auto overrideEnemyCardVisual = Msg("overrideEnemyCardVisual", "外観の上書き");
	auto updateType = Msg("updateType", "再表示時の処理");
	const string updateTypeName(UpdateType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "updateTypeName"));
	}
	auto updateTypeNameFixed = Msg("updateTypeNameFixed", "最初に表示した内容に固定");
	auto updateTypeNameVariables = Msg("updateTypeNameVariables", "状態変数値を更新する");
	auto updateTypeNameAll = Msg("updateTypeNameAll", "全て更新する");
	auto warningUpdateTypeNotFixed = Msg("warningUpdateTypeNotFixed", "テキストセルの内容の更新は、クラシックなシナリオでは行う事ができません。");
	auto warningUpdateType = Msg("warningUpdateType", "テキストセルの更新方法の指定は、Wsn.4以降の形式のシナリオでしか行なえません。"); // Wsn.4
	auto warningAntialiasedTextCell = Msg("warningAntialiasedTextCell", "テキストセルの文字のアンチエイリアスはWsn.4以降の形式のシナリオでしか行なえません。"); // Wsn.4

	auto areaViewKeyboardHint = Msg("areaViewKeyboardHint", "選択+上下左右: 移動, Shift+上下左右: サイズ変更, Ctrl+Altで10ピクセル単位操作, Alt+クリックで範囲選択開始, 中クリックで背後のアイテムを選択");

	/// 称号・名称ビュー。
	auto couponTabName = Msg("couponTabName", "クーポン");
	auto gossipTabName = Msg("gossipTabName", "ゴシップ");
	auto completeStampTabName = Msg("completeStampTabName", "終了印");
	auto keyCodeTabName = Msg("keyCodeTabName", "キーコード");
	auto cellNameTabName = Msg("cellNameTabName", "セル名称");
	auto cardGroupTabName = Msg("cardGroupTabName", "カードグループ");

	auto idName = Msg("idName", "名称");
	auto idCount = Msg("idCount", "利用数");

	auto idStatus = Msg("idStatus", "%2$s件の%1$s");
	auto idStatusSel = Msg("idStatusSel", "%1$s (%2$s件を選択)");

	/// イベントビュー。
	auto eventName = Msg("eventName", "イベント名");
	auto playerCard = Msg("playerCard", "プレイヤーカード");
	auto tools = Msg("tools", "イベントコンテント");
	auto startEnter = Msg("startEnter", "到着");
	auto startSelect = Msg("startSelect", "クリック");
	auto startDead = Msg("startDead", "死亡");
	auto startVictory = Msg("startVictory", "勝利");
	auto startEscape = Msg("startEscape", "逃走");
	auto startLose = Msg("startLose", "敗北");
	auto startEveryRound = Msg("startEveryRound", "毎ラウンド");
	auto startRoundEnd = Msg("startRoundEnd", "ラウンド終了");
	auto startRound0 = Msg("startRound0", "バトル開始");
	auto startPackage = Msg("startPackage", "パッケージ");
	auto startUse = Msg("startUse", "使用時");
	auto startRound = Msg("startRound", "ラウンド = %1$s");
	auto dlgTitNewEvent = Msg("dlgTitNewEvent", "イベントの作成");
	auto dlgTitEventTree = Msg("dlgTitEventTree", "イベントの設定 [ %1$s ]");
	auto addRound = Msg("addRound", "ラウンドの追加");
	auto delRound = Msg("delRound", "ラウンドの削除");
	auto warningNoIgnition = Msg("warningNoIgnition", "イベントの発火条件がありません。");
	auto warningKeyCodeMatchingTypeAnd = Msg("warningKeyCodeMatchingTypeAnd", "キーコードのマッチング条件「全てに一致」は、CardWirth 1.50より前のバージョンでは使用できません。");
	auto localVariables = Msg("localVariables", "ローカル変数");
	auto localVariablesOwner = Msg("localVariablesOwner", "[%1$s.%2$s]");

	const string keyCodeTiming(FKCKind id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "keyCodeTiming"));
	}
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
	auto roundEndTree = Msg("roundEndTree", "ラウンド終了");
	auto round0Tree = Msg("round0Tree", "バトル開始");
	auto packageTree = Msg("packageTree", "パッケージイベント");
	auto useTree = Msg("useTree", "使用時イベント");
	auto keyCodeTree = Msg("keyCodeTree", "[%1$s]");
	auto roundTree = Msg("roundTree", "ラウンド %1$s");

	auto eventTreeKindSystem = Msg("eventTreeKindSystem", "システム");
	auto eventTreeKindKeyCode = Msg("eventTreeKindKeyCode", "キーコード");
	auto eventTreeKindRound = Msg("eventTreeKindRound", "ラウンド");

	auto eventTreeSlope = Msg("eventTreeSlope", "傾き");

	auto startUseCount = Msg("startUseCount", "利用数");

	auto unknownBranchCondition = Msg("unknownBranchCondition", "不明な分岐条件「%1$s」が指定されています。");
	auto unknownBranchConditionNoText = Msg("unknownBranchConditionNoText", "分岐条件が空文字列になっています。");
	auto invalidNextName = Msg("invalidNextName", "不正なコンテント名「%1$s」が指定されています。");

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
	auto valuedSelect = Msg("valuedSelect", "評価条件");
	auto selectMemberSuccess = Msg("selectMemberSuccess", "%1$sから%2$sでキャラクタを選択");
	auto selectMemberCancel = Msg("selectMemberCancel", "%1$sから%2$sでのキャラクタ選択をキャンセル");
	auto selectMemberFailure = Msg("selectMemberFailure", "%1$sから%2$sでのキャラクタ選択に失敗");
	auto branchAbilitySuccess = Msg("branchAbilitySuccess", "%1$sがレベル%2$sで%3$sと%4$sで行う%5$s判定に成功");
	auto branchAbilityFailure = Msg("branchAbilityFailure", "%1$sがレベル%2$sで%3$sと%4$sで行う%5$s判定に失敗");
	auto abilityHighest = Msg("abilityHighest", "能力");
	auto abilityLowest = Msg("abilityLowest", "能力不足");
	auto branchRandomSuccess = Msg("branchRandomSuccess", "%1$s%%成功");
	auto branchRandomFailure = Msg("branchRandomFailure", "%1$s%%失敗");
	auto levelAverage = Msg("levelAverage", "パーティ全員の平均値");
	auto levelSelected = Msg("levelSelected", "選択中のメンバ");
	auto branchLevelSuccess = Msg("branchLevelSuccess", "%1$sがレベル%2$s以上");
	auto branchLevelFailure = Msg("branchLevelFailure", "%1$sがレベル%2$s未満");
	auto branchStatusSuccess = Msg("branchStatusSuccess", "%1$sが「%2$s」状態である");
	auto branchStatusFailure = Msg("branchStatusFailure", "%1$sが「%2$s」状態でない");
	auto branchNumberSuccess = Msg("branchNumberSuccess", "パーティに%1$s人以上いる");
	auto branchNumberFailure = Msg("branchNumberFailure", "パーティは%1$s人未満");
	auto branchArea = Msg("branchArea", "エリア = %1$s");
	auto branchAreaWithId = Msg("branchAreaWithId", "エリア = %1$s.%2$s");
	auto branchBattle = Msg("branchBattle", "バトル = %1$s");
	auto branchBattleWithId = Msg("branchBattleWithId", "バトル = %1$s.%2$s");
	auto branchOnBattleSuccess = Msg("branchOnBattleSuccess", "イベント発生時の状況が戦闘中");
	auto branchOnBattleFailure = Msg("branchOnBattleFailure", "イベント発生時の状況が戦闘中以外");
	auto branchCastSuccess = Msg("branchCastSuccess", "「%1$s」が加わっている");
	auto branchCastFailure = Msg("branchCastFailure", "「%1$s」が加わっていない");
	auto branchEffectCardSuccess = Msg("branchEffectCardSuccess", "「%2$s」を所有している(%1$s)");
	auto branchEffectCardFailure = Msg("branchEffectCardFailure", "「%2$s」を所有していない(%1$s)");
	auto branchEffectCardForSelectedCardSuccess = Msg("branchEffectCardForSelectedCardSuccess", "「%1$s」と選択カードが一致する");
	auto branchEffectCardForSelectedCardFailure = Msg("branchEffectCardForSelectedCardFailure", "「%1$s」と選択カードが一致しない");
	auto branchInfoSuccess = Msg("branchInfoSuccess", "「%1$s」を所有している");
	auto branchInfoFailure = Msg("branchInfoFailure", "「%1$s」を所有していない");
	auto branchMoneySuccess = Msg("branchMoneySuccess", "%1$ssp以上所持している");
	auto branchMoneyFailure = Msg("branchMoneyFailure", "%1$ssp以上所持していない");
	auto branchCouponSuccess = Msg("branchCouponSuccess", "称号「%2$s」を所有している(%1$s)");
	auto branchCouponFailure = Msg("branchCouponFailure", "称号「%2$s」を所有していない(%1$s)");
	auto branchCouponMultiSuccess = Msg("branchCouponMultiSuccess", "称号%2$sを%3$s所有している(%1$s)"); // Wsn.2
	auto branchCouponMultiFailure = Msg("branchCouponMultiFailure", "称号%2$sを%3$s所有していない(%1$s)"); // Wsn.2
	auto branchCompleteSuccess = Msg("branchCompleteSuccess", "シナリオ「%1$s」が終了済みである");
	auto branchCompleteFailure = Msg("branchCompleteFailure", "シナリオ「%1$s」が終了済みでない");
	auto branchGossipSuccess = Msg("branchGossipSuccess", "ゴシップ「%1$s」が宿屋にある");
	auto branchGossipFailure = Msg("branchGossipFailure", "ゴシップ「%1$s」が宿屋に無い");
	auto branchStepCmpGreater = Msg("branchStepCmpGreater", "ステップ「%1$s」が「%2$s」より大きい");
	auto branchStepCmpLesser = Msg("branchStepCmpLesser", "ステップ「%1$s」が「%2$s」より小さい");
	auto branchStepCmpEq = Msg("branchStepCmpEq", "ステップ「%1$s」が「%2$s」と同値");
	auto branchFlagCmpNotEq = Msg("branchFlagCmpNotEq", "フラグ「%1$s」と「%2$s」の値が異なる");
	auto branchFlagCmpEq = Msg("branchFlagCmpEq", "フラグ「%1$s」が「%2$s」と同値");
	auto branchRandomSelectSuccess = Msg("branchRandomSelectSuccess", "%2$sのキャラクタを選択(%1$s)");
	auto branchRandomSelectFailure = Msg("branchRandomSelectFailure", "%2$sのキャラクタ選択に失敗(%1$s)");
	auto branchRandomSelectSuccessInvert = Msg("branchRandomSelectSuccessInvert", "%2$sでないキャラクタを選択(%1$s)");
	auto branchRandomSelectFailureInvert = Msg("branchRandomSelectFailureInvert", "%2$sでないキャラクタ選択に失敗(%1$s)");
	auto branchRandomSelectSuccessN = Msg("branchRandomSelectSuccessN", "キャラクタを選択(%1$s)");
	auto branchRandomSelectFailureN = Msg("branchRandomSelectFailureN", "キャラクタ選択に失敗(%1$s)");
	auto randomSelectCondition1 = Msg("randomSelectCondition1", "レベル%1$s～%2$s");
	auto randomSelectCondition2 = Msg("randomSelectCondition2", "状態が%1$s");
	auto randomSelectCondition3 = Msg("randomSelectCondition3", "レベル%1$s～%2$sで状態が%3$s");
	auto branchKeyCodeWithConditionAllTypeSuccess = Msg("branchKeyCodeWithConditionAllTypeSuccess", "キーコード「%1$s」を%2$sカードを所有している(%3$s)");
	auto branchKeyCodeWithConditionAllTypeFailure = Msg("branchKeyCodeWithConditionAllTypeFailure", "キーコード「%1$s」を%2$sカードを所有していない(%3$s)");
	auto branchKeyCodeWithConditionSuccess = Msg("branchKeyCodeWithConditionSuccess", "キーコード「%1$s」を%2$s%3$sを所有している(%4$s)");
	auto branchKeyCodeWithConditionFailure = Msg("branchKeyCodeWithConditionFailure", "キーコード「%1$s」を%2$s%3$sを所有していない(%4$s)");
	auto branchKeyCodeWithConditionAllTypeForSelectedCardSuccess = Msg("branchKeyCodeWithConditionAllTypeForSelectedCardSuccess", "キーコード「%1$s」を%2$s選択カードが存在する");
	auto branchKeyCodeWithConditionAllTypeForSelectedCardFailure = Msg("branchKeyCodeWithConditionAllTypeForSelectedCardFailure", "キーコード「%1$s」を%2$s選択カードが存在しない");
	auto branchKeyCodeWithConditionForSelectedCardSuccess = Msg("branchKeyCodeWithConditionForSelectedCardSuccess", "キーコード「%1$s」を%2$s%3$sの選択カードが存在する");
	auto branchKeyCodeWithConditionForSelectedCardFailure = Msg("branchKeyCodeWithConditionForSelectedCardFailure", "キーコード「%1$s」を%2$s%3$sの選択カードが存在しない");
	auto targetIsSkill = Msg("targetIsSkill", "特殊技能");
	auto targetIsItem = Msg("targetIsItem", "アイテム");
	auto targetIsBeast = Msg("targetIsBeast", "召喚獣");
	auto targetIsHand = Msg("targetIsHand", "手札");
	auto targetSeparator = Msg("targetSeparator", "・");
	auto branchRound = Msg("branchRound", "バトルが%1$sラウンド%2$s");
	auto branchMultiCouponSuccess = Msg("branchMultiCouponSuccess", "%1$sが称号「%2$s」を所有している"); // Wsn.2
	auto branchMultiCouponFailure = Msg("branchMultiCouponFailure", "%1$sが全ての称号を所有していない"); // Wsn.2
	auto branchVariantSuccess = Msg("branchVariantSuccess", "TRUE =〔 %1$s 〕"); // Wsn.4
	auto branchVariantFailure = Msg("branchVariantFailure", "FALSE =〔 %1$s 〕"); // Wsn.4

	const string physicalName(Physical id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "physicalName"));
	}
	auto physicalNameDex = Msg("physicalNameDex", "器用度");
	auto physicalNameAgl = Msg("physicalNameAgl", "敏捷度");
	auto physicalNameInt = Msg("physicalNameInt", "知力");
	auto physicalNameStr = Msg("physicalNameStr", "筋力");
	auto physicalNameVit = Msg("physicalNameVit", "生命力");
	auto physicalNameMin = Msg("physicalNameMin", "精神力");
	const string mentalName(Mental id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "mentalName"));
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
	const string statusName(Status id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "statusName"));
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
	const string effectTypeName(EffectType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "effectTypeName"));
	}
	auto effectTypeNamePhysic = Msg("effectTypeNamePhysic", "物理");
	auto effectTypeNameMagic = Msg("effectTypeNameMagic", "魔法");
	auto effectTypeNameMagicalPhysic = Msg("effectTypeNameMagicalPhysic", "魔法的物理");
	auto effectTypeNamePhysicalMagic = Msg("effectTypeNamePhysicalMagic", "物理的魔法");
	auto effectTypeNameNone = Msg("effectTypeNameNone", "無");
	const string effectTypeDesc(EffectType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "effectTypeDesc"));
	}
	auto effectTypeDescPhysic = Msg("effectTypeDescPhysic", "武器が効かない存在には無効");
	auto effectTypeDescMagic = Msg("effectTypeDescMagic", "魔法が効かない存在には無効");
	auto effectTypeDescMagicalPhysic = Msg("effectTypeDescMagicalPhysic", "武器と魔法の両方が効かない存在には無効");
	auto effectTypeDescPhysicalMagic = Msg("effectTypeDescPhysicalMagic", "武器と魔法のどちらかが効かない存在には無効");
	auto effectTypeDescNone = Msg("effectTypeDescNone", "全ての存在に有効");
	const string resistName(Resist id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "resistName"));
	}
	auto resistNameAvoid = Msg("resistNameAvoid", "回避属性");
	auto resistNameResist = Msg("resistNameResist", "抵抗属性");
	auto resistNameUnfail = Msg("resistNameUnfail", "必中属性");
	const string resistDesc(Resist id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "resistDesc"));
	}
	auto resistDescAvoid = Msg("resistDescAvoid", "回避された場合は効果無し");
	auto resistDescResist = Msg("resistDescResist", "抵抗された場合は効果半減");
	auto resistDescUnfail = Msg("resistDescUnfail", "絶対成功");
	const string cardTargetName(CardTarget id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "cardTargetName"));
	}
	auto cardTargetNameNone = Msg("cardTargetNameNone", "対象無し");
	auto cardTargetNameUser = Msg("cardTargetNameUser", "使用者");
	auto cardTargetNameParty = Msg("cardTargetNameParty", "味方");
	auto cardTargetNameEnemy = Msg("cardTargetNameEnemy", "敵方");
	auto cardTargetNameBoth = Msg("cardTargetNameBoth", "双方");
	auto cardTargetOne = Msg("cardTargetOne", "一体");
	auto cardTargetAll = Msg("cardTargetAll", "全体");
	const string cardVisualName(CardVisual id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "cardVisualName"));
	}
	auto cardVisualNameNone = Msg("cardVisualNameNone", "視覚効果無し");
	auto cardVisualNameReverse = Msg("cardVisualNameReverse", "対象を反転");
	auto cardVisualNameHorizontal = Msg("cardVisualNameHorizontal", "対象を横に震動");
	auto cardVisualNameVertical = Msg("cardVisualNameVertical", "対象を縦に震動");
	const string premiumName(Premium id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "premiumName"));
	}
	auto premiumNameNormal = Msg("premiumNameNormal", "日用品 (破棄可)");
	auto premiumNameRare = Msg("premiumNameRare", "希少品 (破棄可)");
	auto premiumNamePremium = Msg("premiumNamePremium", "貴重品 (破棄不可)");
	const string enhanceName(Enhance id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "enhanceName"));
	}
	auto enhanceNameAction = Msg("enhanceNameAction", "行動");
	auto enhanceNameAvoid = Msg("enhanceNameAvoid", "回避");
	auto enhanceNameResist = Msg("enhanceNameResist", "抵抗");
	auto enhanceNameDefense = Msg("enhanceNameDefense", "防御");
	auto mentality = Msg("mentality", "精神状態");
	const string mentalityName(Mentality id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "mentalityName"));
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
	const string targetName(Target.M id) { mixin(S_TRACE);
		with (Target) {
			mixin(EnumToStringSwitch!(typeof(id), "targetName"));
		}
	}
	auto targetNameSelected = Msg("targetNameSelected", "選択中のメンバ");
	auto targetNameUnselected = Msg("targetNameUnselected", "選択中以外のメンバ");
	auto targetNameRandom = Msg("targetNameRandom", "誰か一人");
	auto targetNameParty = Msg("targetNameParty", "パーティ全員");
	const string talkerName(Talker id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "talkerName"));
	}
	auto talkerNameSelected = Msg("talkerNameSelected", "選択中");
	auto talkerNameUnselected = Msg("talkerNameUnselected", "選択中以外");
	auto talkerNameRandom = Msg("talkerNameRandom", "ランダム");
	auto talkerNameCard = Msg("talkerNameCard", "カード");
	auto talkerNameNarration = Msg("talkerNameNarration", "話者無し");
	auto talkerNameImage = Msg("talkerNameImage", "画像");
	auto talkerNameValued = Msg("talkerNameValued", "評価メンバ");
	const string rangeName(Range id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "rangeName"));
	}
	auto rangeNameSelected = Msg("rangeNameSelected", "現在選択中のメンバ");
	auto rangeNameRandom = Msg("rangeNameRandom", "パーティの誰か一人");
	auto rangeNameParty = Msg("rangeNameParty", "パーティの全員");
	auto rangeNameBackpack = Msg("rangeNameBackpack", "荷物袋");
	auto rangeNamePartyAndBackpack = Msg("rangeNamePartyAndBackpack", "全体(荷物袋含む)");
	auto rangeNameField = Msg("rangeNameField", "フィールド全体");
	auto rangeNameCouponHolder = Msg("rangeNameCouponHolder", "称号所有者");
	auto rangeNameCardTarget = Msg("rangeNameCardTarget", "カードの使用対象"); // Wsn.2
	auto rangeNameSelectedCard = Msg("rangeNameSelectedCard", "選択カード"); // Wsn.3
	auto rangeNameNpc = Msg("rangeNameNpc", "同行キャスト"); // Wsn.5
	auto rangeWithCoupon = Msg("rangeWithCoupon", "称号所有者(%1$s)");
	auto rangeWithNoCoupon = Msg("rangeWithNoCoupon", "称号所有者(指定無し)");
	auto rangeDescField = Msg("rangeDescField", "パーティ・荷物袋・エネミーカードを含む");
	auto rangeDescCardTarget = Msg("rangeDescCardTarget", "使用時イベント中でない場合、対象無しになります"); // Wsn.2
	auto rangeNameSelectedCardForReplace = Msg("rangeNameSelectedCardForReplace", "選択カード(交換)"); // Wsn.3
	const string castRangeName(CastRange id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "castRangeName"));
	}
	auto castRangeNameParty = Msg("castRangeNameParty", "パーティ");
	auto castRangeNameEnemy = Msg("castRangeNameEnemy", "敵");
	auto castRangeNameNpc = Msg("castRangeNameNpc", "同行キャスト");
	const string damageTypeName(DamageType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "damageTypeName"));
	}
	auto damageTypeNameLevelRatio = Msg("damageTypeNameLevelRatio", "レベルに対応する値");
	auto damageTypeNameNormal = Msg("damageTypeNameNormal", "値の直接入力");
	auto damageTypeNameMax = Msg("damageTypeNameMax", "最大値処理");
	auto damageTypeNameFixed = Msg("damageTypeNameFixed", "固定値");
	const string elementName(Element id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "elementName"));
	}
	auto elementNameAll = Msg("elementNameAll", "全");
	auto elementNameHealth = Msg("elementNameHealth", "肉体");
	auto elementNameMind = Msg("elementNameMind", "精神");
	auto elementNameMiracle = Msg("elementNameMiracle", "神聖");
	auto elementNameMagic = Msg("elementNameMagic", "魔力");
	auto elementNameFire = Msg("elementNameFire", "炎");
	auto elementNameIce = Msg("elementNameIce", "冷気");

	auto elementNameHearing = Msg("elementNameHearing", "音");
	auto elementNameVision = Msg("elementNameVision", "視覚");
	auto elementNameElectronic = Msg("elementNameElectronic", "電子");

	auto elementEffectiveAll = Msg("elementEffectiveAll", "全ての存在に有効");
	auto elementNoEffective = Msg("elementNoEffective", "%1$s存在には無効");
	auto elementEffective = Msg("elementEffective", "%1$sに有効");
	auto elementWeaknessOrResist = Msg("elementWeaknessOrResist", "対象によって弱点または無効");

	auto sexUnknown = Msg("sexUnknown", "謎/？");
	auto periodUnknown = Msg("periodUnknown", "不明");
	auto natureUnknown = Msg("natureUnknown", "その他");

	const string effectCardTypeName(EffectCardType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "effectCardTypeName"));
	}
	auto effectCardTypeNameAll = Msg("effectCardTypeNameAll", "全てのカード");
	auto effectCardTypeNameSkill = Msg("effectCardTypeNameSkill", "特殊技能カード");
	auto effectCardTypeNameItem = Msg("effectCardTypeNameItem", "アイテムカード");
	auto effectCardTypeNameBeast = Msg("effectCardTypeNameBeast", "召喚獣カード");
	auto effectCardTypeNameHand = Msg("effectCardTypeNameHand", "戦闘時の手札"); // Wsn.2

	const string comparison4Name(Comparison4 id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "comparison4Name"));
	}
	auto comparison4NameEq = Msg("comparison4NameEq", "であれば");
	auto comparison4NameNe = Msg("comparison4NameNe", "でなければ");
	auto comparison4NameLt = Msg("comparison4NameLt", "より大きければ");
	auto comparison4NameGt = Msg("comparison4NameGt", "より小さければ");

	const string comparison3Name(Comparison3 id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "comparison3Name"));
	}
	auto comparison3NameEq = Msg("comparison3NameEq", "である");
	auto comparison3NameLt = Msg("comparison3NameLt", "より大きい");
	auto comparison3NameGt = Msg("comparison3NameGt", "より小さい");

	const string comparison3FalseName(Comparison3 id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "comparison3FalseName"));
	}
	auto comparison3FalseNameEq = Msg("comparison3FalseNameEq", "ではない");
	auto comparison3FalseNameLt = Msg("comparison3FalseNameLt", "以下");
	auto comparison3FalseNameGt = Msg("comparison3FalseNameGt", "以上");

	auto dlgTitComment = Msg("dlgTitComment", "コメントの記述");
	auto dlgTitCommentWith = Msg("dlgTitCommentWith", "[ %1$s ] へのコメント");

	/// カードウィンドウ。
	auto cardTabName = Msg("cardTabName", "%1$s");
	auto handCardTabName = Msg("handCardTabName", "%1$s.%2$s");
	auto importSourceTabName = Msg("importSourceTabName", "%1$s");
	auto cardTitle = Msg("cardTitle", "%1$s.%2$s");
	auto dlgTitImportOption = Msg("dlgTitImportOption", "参照先のインポート");
	auto importOptionMaterials = Msg("importOptionMaterials", "外部素材");
	auto importOptionVariables = Msg("importOptionVariables", "状態変数");
	auto importOptionCasts = Msg("importOptionCasts", "キャストカード");
	auto importOptionSkills = Msg("importOptionSkills", "特殊技能カード");
	auto importOptionItems = Msg("importOptionItems", "アイテムカード");
	auto importOptionBeasts = Msg("importOptionBeasts", "召喚獣カード");
	auto importOptionInfos = Msg("importOptionInfos", "情報カード");
	auto importOptionAreas = Msg("importOptionAreas", "エリア");
	auto importOptionBattles = Msg("importOptionBattles", "バトル");
	auto importOptionPackages = Msg("importOptionPackages", "パッケージ");
	auto importOptionIncludedFiles = Msg("importOptionIncludedFiles", "格納カードイメージ");
	auto importOptionIncludedBgImages = Msg("importOptionIncludedBgImages", "格納背景イメージ");
	auto importOptionHands = Msg("importOptionHands", "キャストの持ち札");
	auto importOptionBeastsInMotions = Msg("importOptionBeastsInMotions", "効果中の召喚獣");
	const string importTypeIncludedName(ImportTypeIncluded id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "importTypeIncludedName"));
	}
	auto importTypeIncludedNameExclude = Msg("importTypeIncludedNameExclude", "格納であれば外部出力する");
	auto importTypeIncludedNameInclude = Msg("importTypeIncludedNameInclude", "参照であれば格納する");
	auto importTypeIncludedNameAsIs = Msg("importTypeIncludedNameAsIs", "そのままにする");
	const string importTypeReference1Name(ImportTypeReference1 id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "importTypeReference1Name"));
	}
	auto importTypeReference1NameRename = Msg("importTypeReference1NameRename", "重複した場合は名前を変更する");
	auto importTypeReference1NameNoOverwrite = Msg("importTypeReference1NameNoOverwrite", "重複した場合はインポートしない");
	auto importTypeReference1NameOverwrite = Msg("importTypeReference1NameOverwrite", "重複した場合は上書きする");
	auto importTypeReference1NameNoImport = Msg("importTypeReference1NameNoImport", "インポートしない");
	const string importTypeReference2Name(ImportTypeReference2 id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "importTypeReference2Name"));
	}
	auto importTypeReference2NameRename = Msg("importTypeReference1NameRename", "新しいIDでインポートする");
	auto importTypeReference2NameNoImport = Msg("importTypeReference1NameNoImport", "インポートしない");
	auto importOverwriteScenarioInfo = Msg("importOverwriteScenarioInfo", "カードのシナリオ名及びシナリオ作者の情報を書き換える");

	auto dlgTitAddScenario = Msg("dlgTitAddScenario", "インポート元の選択");
	auto dlgTitImportResult = Msg("dlgTitImportResult", "インポート対象の選択");
	auto importResourceList = Msg("importResourceList", "次のリソースのうち、チェックを入れたものがインポートされます。");
	auto overwriteMark = Msg("overwriteMark", "%1$s (上書き)");

	auto cardIsReference = Msg("cardIsReference", "「%1$s.%2$s」を参照しています");
	auto referencedCardIsNotFound = Msg("referencedCardIsNotFound", "参照先のカードが見つかりません(ID:%1$s)");

	auto cardStatus = Msg("cardStatus", "%1$s枚のカード");
	auto cardStatusSelOne = Msg("cardStatusSelOne", "%1$s枚のカード (ID = %2$s)");
	auto cardStatusSelMulti = Msg("cardStatusSelMulti", "%1$s枚のカード (%2$s枚を選択中)");
	auto handCardStatus = Msg("handCardStatus", "%1$s枚のカード (有効枚数 = %2$s)");
	auto handCardStatusSelOne = Msg("handCardStatusSelOne", "%1$s枚のカード (有効枚数 = %2$s) (ID = %3$s)");
	auto handCardStatusSelMulti = Msg("handCardStatusSelMulti", "%1$s枚のカード (有効枚数 = %2$s) (%3$s枚を選択中)");

	auto showStatusTime = Msg("showStatusTime", "状態の強度と持続時間");
	const string showStatusTimeName(ShowStatusTime id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "showStatusTimeName"));
	}
	auto showStatusTimeNameAlways = Msg("showStatusTimeNameAlways", "常に表示");
	auto showStatusTimeNameWithSkin = Msg("showStatusTimeNameWithSkin", "スキン使用時のみ表示");
	auto showStatusTimeNameNo = Msg("showStatusTimeNameNo", "表示しない");

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
	auto noSelectVariant = Msg("noSelectVariant", "(指定無し)");
	auto noVariant = Msg("noVariant", "存在しないコモン(パス:%1$s)");
	auto noSelectStart = Msg("noSelectStart", "(指定無し)");
	auto noStart = Msg("noStart", "存在しないスタートコンテント(パス:%1$s)");
	auto noSelectCoupon = Msg("noSelectCoupon", "(指定無し)");
	auto noSelectCompleteStamp = Msg("noSelectCompleteStamp", "(指定無し)");
	auto noSelectGossip = Msg("noSelectGossip", "(指定無し)");
	auto noSelectCellName = Msg("noSelectCellName", "(指定無し)");
	auto noSelectCardGroup = Msg("noSelectCardGroup", "(指定無し)");
	auto noSelectTarget = Msg("noSelectTarget", "(指定無し)");
	auto noEffect = Msg("noEffect", "(指定無し)");
	auto noKeyCode = Msg("noKeyCode", "(指定無し)");
	auto noText = Msg("noText", "(文章無し)");
	auto noExpression = Msg("noExpression", "(式無し)");
	auto noInformation = Msg("noInformation", "(情報を取得できません)");

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
	auto noRace = Msg("noRace", "未指定");
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
	auto descEffective = Msg("descEffective", "(%1$s属性の効果が有効)");
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
	auto aptitude = Msg("aptitude", "適性");
	auto actionOrder = Msg("actionOrder", "先駆け");
	auto actionOrderDesc = Msg("actionOrderDesc", "バトルでの行動順に影響します");
	auto resilience = Msg("resilience", "回復力");
	auto resilienceDesc = Msg("resilienceDesc", "中毒や麻痺の回復速度に影響します");
	auto avoidance = Msg("avoidance", "回避力");
	auto avoidanceDesc = Msg("avoidanceDesc", "回避の成功率に影響します");
	auto resistance = Msg("resistance", "抵抗力");
	auto resistanceDesc = Msg("resistanceDesc", "抵抗の成功率に影響します");
	auto runAwaySpeed = Msg("runAwaySpeed", "逃げ足");
	auto runAwaySpeedDesc = Msg("runAwaySpeedDesc", "パーティの逃走の成功率に影響します");
	auto aptitudeHint = Msg("aptitudeHint", "%1$s(%2$s+%3$s)");

	auto liveStatus = Msg("liveStatus", "初期状態");
	auto lifeAndMentality = Msg("lifeAndMentality", "体力と精神状態");
	auto enhanceLiveBonus = Msg("enhanceLiveBonus", "能力ボーナス/ペナルティ");
	const string enhanceLiveBonusName(Enhance id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "enhanceLiveBonusName"));
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

	const string showStyleName(ShowStyle id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "showStyleName"));
	}
	auto showStyleNameInvisible = Msg("showStyleNameInvisible", "表示しない"); // Wsn.4
	auto showStyleNameCenter = Msg("showStyleNameCenter", "画面中央に表示"); // Wsn.4
	auto showStyleNameFrontOfUser = Msg("showStyleNameFrontOfUser", "使用者の手前に表示"); // Wsn.4

	auto workConditionGroup = Msg("workConditionGroup", "発動条件");
	auto needSpell = Msg("needSpell", "沈黙時に発動不可");
	auto needSpellAndActive = Msg("needSpellAndActive", "沈黙・行動不能時に発動不可");
	auto elementProps = Msg("elementProps", "効果属性");
	auto linkOption = Msg("linkOption", "参照設定");
	auto beastMaxNest = Msg("beastMaxNest", "ネスト可能回数");
	auto showStyleForBeastCard = Msg("showStyleForBeastCard", "発動時の視覚効果"); // Wsn.4
	auto warningShowStyleForBeastCard = Msg("warningShowStyleForBeastCard", "発動時の視覚効果の設定は、Wsn.4以降の形式のシナリオでしか行えません。"); // Wsn.4
	auto resistProps = Msg("resistProps", "抵抗属性");
	auto aptPhysical = Msg("aptPhysical", "身体的要素");
	auto aptMental = Msg("aptMental", "精神的要素");
	auto skillLevel = Msg("skillLevel", "技能レベル");
	auto useCount = Msg("useCount", "使用回数");
	auto useCountGroup = Msg("useCountGroup", "使用可能回数");
	auto useCountRange = Msg("useCountRange", "(0～%1$s : 0 = ∞)");
	auto useCountCur = Msg("useCountCur", "現在");
	auto useCountMax = Msg("useCountMax", "最大");
	auto useCountIsMax = Msg("useCountIsMax", "最大回数を使用");
	auto price = Msg("price", "価格");
	auto priceAuto = Msg("priceAuto", "(参考用)");
	auto useModify = Msg("useModify", "使用時 能力値修正");
	auto haveModify = Msg("haveModify", "所有時 能力値修正");
	auto motionKind = Msg("motionKind", "効果種別");
	auto motionElement = Msg("motionElement", "属性");
	auto motionDamageType = Msg("motionDamageType", "タイプ");
	auto calcType = Msg("calcType", "効果値タイプ");
	auto motionValue = Msg("motionValue", "値");
	auto motionBeast = Msg("motionBeast", "召喚するカード");
	auto beastNone = Msg("beastNone", "召喚獣無し");
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
	auto initialEffectAndSound = Msg("initialEffectAndSound", "効果音と初期効果"); /// Wsn.4
	auto hasInitialEffect = Msg("hasInitialEffect", "色反転と初期効果音の再生を行う"); // Wsn.4
	auto warningInitialEffect = Msg("warningInitialEffect", "色反転と初期効果音再生の指定はWsn.4以降の形式のシナリオでしか行えません。"); // Wsn.4
	auto warningAbsorbToSelected = Msg("warningAbsorbToSelected", "吸収者の指定はWsn.4以降の形式のシナリオでしか行えません。"); // Wsn.4
	auto soundNone = Msg("soundNone", "効果音無し");
	auto noSelect = Msg("noSelect", "指定無し");
	auto keyCodes = Msg("keyCodes", "イベント発火のキーコード");
	auto addKeyCode = Msg("addKeyCode", "キーコードの追加");
	auto delKeyCode = Msg("delKeyCode", "キーコードの削除");
	auto selectFeatures = Msg("selectFeatures", "キーコードの自動生成");
	auto selectFeaturesHint = Msg("selectFeaturesHint", "特徴と効果からキーコードを自動生成します。\n全体的な特徴を選択してください。");
	auto addKeyCodesError = Msg("addKeyCodesError", "追加できなかったキーコード");
	auto addKeyCodesErrorDesc = Msg("addKeyCodesErrorDesc", "クラシックなシナリオではキーコードが%1$s件までに制限されているため、次のキーコードは追加できませんでした。");

	auto behaviorOfBeastCard = Msg("behaviorOfBeastCard", "発動/消滅");
	auto invocationCondition = Msg("invocationCondition", "発動条件");
	auto removalCondition = Msg("removalCondition", "消滅条件");
	auto removeWithUnconscious = Msg("removeWithUnconscious", "意識不明時に消滅する");

	auto warningNotDefaultSE = Msg("warningNotDefaultSE", "標準以外の効果音はシナリオの外では鳴らない可能性があります。");
	auto warningEffectTypeNone = Msg("warningEffectTypeNone", "無属性のカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。");
	auto warningVanishCast = Msg("warningVanishCast", "神聖属性以外の対象消去効果を持つカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。");
	auto warningNameLenOver = Msg("warningNameLenOver", "名前の長さが%2$s文字を超えています。メッセージにカード名が表示された際に不具合が発生する可能性があります。"); // %1$s = 文字数、%2$s = 文字数 / 2
	auto warningPCNumberClassic = Msg("warningPCNumberClassic", "プレイヤーキャラクタのイメージはCardWirth 1.30より前のバージョンでは表示されません。");
	auto warningUnknownContent = Msg("warningUnknownContent", "イベント [%1$s] はCardWirth %2$sより前のバージョンでは使用できません。");
	auto warningUnknownContentWsn = Msg("warningUnknownContentWsn", "イベント [%1$s] はWsn.%2$sより前のバージョンでは使用できません。");
	auto warningBranchCouponAtField = Msg("warningBranchCouponAtField", "フィールド全体でのクーポン所持判定は、CardWirth 1.30より前のバージョンでは使用できません。");
	auto warningBranchCouponAtNpc = Msg("warningBranchCouponAtNpc", "同行キャストのクーポン所持判定は、Wsn.5以降の形式のシナリオでしか行えません。");
	auto warningSexCoupon = Msg("warningSexCoupon", "「%1$s」は性別を示すクーポンであるため、経歴に使用できません。");
	auto warningPeriodCoupon = Msg("warningPeriodCoupon", "「%1$s」は年代を示すクーポンであるため、経歴に使用できません。");
	auto warningNatureCoupon = Msg("warningNatureCoupon", "「%1$s」は素質を示すクーポンであるため、経歴に使用できません。");
	auto warningMakingCoupon = Msg("warningMakingCoupon", "「%1$s」は特性を示すクーポンであるため、経歴に使用できません。");
	auto warningSystemVarName = Msg("warningSystemVarName", "%1$sで始まる名前の状態変数は、プレイヤーの環境によっては正しく機能しない事があります。");
	auto warningSystemCoupon = Msg("warningSystemCoupon", "%1$sで始まる名前のクーポンを操作する事はできません。");
	auto warningSystemCouponForHistory = Msg("warningSystemCouponForHistory", "キャストカードに設定されたシステムクーポンは正常に動作しない可能性があります。");
	auto warningBranchStatusMental = Msg("warningBranchStatusMental", "%1$s状態の判定は、CardWirth %2$sより前のバージョンでは使用できません。");
	auto warningValuedTalker = Msg("warningValuedTalker", "評価メンバは、CardWirth 1.50より前のバージョンでは使用できません。");
	auto warningTextCell = Msg("warningTextCell", "テキストセルは、CardWirth 1.50より前のバージョンでは使用できません。");
	auto warningColorCell = Msg("warningColorCell", "カラーセルは、CardWirth 1.50より前のバージョンでは使用できません。");
	auto warningColorCellNoGradientAlphaBlend160 = Msg("warningColorCellNoGradientAlphaBlend160", "CardWirth 1.60では「通常」以外の合成方法で不透明度255未満、かつグラデーション無しの時に表示がおかしくなります。基本色と終端色が同色のグラデーションにする事で回避できます。");
	auto warningPCCell = Msg("warningPCCell", "プレイヤーキャラクタセルは、Wsn.1以降の形式のシナリオでしか使用できません。");
	auto warningExpandedPCCell = Msg("warningExpandedPCCell", "セルに合わせて拡大・縮小するプレイヤーキャラクタセルは、Wsn.1以降の形式のシナリオでしか使用できません。");
	auto warningEffectBoosterFileWithReplaceBgImage = Msg("warningEffectBoosterFileWithReplaceBgImage", "エフェクトブースター関係の背景セルは無視するように指定されています。");
	auto warningBgImageIncluded = Msg("warningBgImageIncluded", "背景セルのイメージ格納は、CardWirth 1.60より前のバージョンでは行えません。");
	auto warningBgImageCellName = Msg("warningBgImageCellName", "背景セル名称は、Wsn.1以降の形式のシナリオでしか設定できません。");
	auto warningCardGroup = Msg("warningCardGroup", "カードグループは、Wsn.3以降の形式のシナリオでしか設定できません。");
	auto warningSelectionBarIsMany = Msg("warningSelectionBarIsMany", "選択肢が%1$s行ありますが、%2$s行までしか表示できません。");
	auto warningEveryRound = Msg("warningEveryRound", "イベント発火条件「毎ラウンド」は、CardWirth 1.50より前のバージョンでは使用できません。");
	auto warningRoundEnd = Msg("warningRoundEnd", "イベント発火条件「ラウンド終了」は、Wsn.4以降の形式のシナリオでしか機能しません。"); // Wsn.4
	auto warningRound0 = Msg("warningRound0", "イベント発火条件「バトル開始」は、CardWirth 1.50より前のバージョンでは使用できません。");
	auto warningUnknownMotion = Msg("warningUnknownMotion", "効果 [%1$s] は、CardWirth %2$sより前のバージョンでは使用できません。");
	auto warningUnknownMotionWsn = Msg("warningUnknownMotionWsn", "効果 [%1$s] は、Wsn.%2$sより前のバージョンでは使用できません。");
	auto warningTextColor = Msg("warningTextColor", "テキスト色 [%1$s] は、CardWirth %2$sより前のバージョンでは使用できません。");
	auto warningStepCount = Msg("warningStepCount", "%1$s段階以外のステップはクラシックなシナリオでは使用できません。");
	auto warningStepOverCount = Msg("warningStepOverCount", "ステップ「%1$s」の段階数 [%2$s] より大きなステップ値 [%3$s] が指定されています。");
	auto warningKeyCodeCount = Msg("warningKeyCodeCount", "%1$s件より多くのキーコードはクラシックなシナリオでは設定できません。");
	auto warningHasNotKeyCode = Msg("warningHasNotKeyCode", "キーコードの不保有発火条件はCardWirth 1.50より前のバージョンでは機能しません。");
	auto warningValuedSelectionMethod = Msg("warningValuedSelectionMethod", "評価条件によるメンバ選択分岐は、Wsn.1以降の形式のシナリオしか行えません。");
	auto warningSkillPowerWithFixedValue = Msg("warningSkillPowerWithFixedValue", "精神力操作の固定値指定は、Wsn.1以降の形式のシナリオしか行えません。"); // Wsn.1
	auto warningIncludedImage = Msg("warningIncludedImage", "WSN形式のシナリオでは格納イメージは使用できません。");
	auto warningTransitionType = Msg("warningTransitionType", "背景切替方式の指定は、WSN形式のシナリオでしか行なえません。");
	auto warningSingleLineMessage = Msg("warningSingleLineMessage", "単行メッセージは、Wsn.5以降の形式のシナリオでしか使用できません。");
	auto warningSelectionColumns = Msg("warningSelectionColumns", "選択肢の複数列表示は、Wsn.1以降の形式のシナリオしか行えません。");
	auto warningRunAwayCard = Msg("warningRunAwayCard", "キーコード「%1$s」付きのカードは死亡イベントを発生させないため、シナリオを誤動作させる可能性があります。");
	auto warningEndOrChangeAreaInRound0 = Msg("warningEndOrChangeAreaInRound0", "クラシックエンジンのバグにより、バトル開始イベント中にシナリオ終了やエリア移動を行うと、プレイヤーのデータの破損を含めた異常が発生する可能性があります。");
	auto warningWsnSystemCoupon = Msg("warningWsnSystemCoupon", "システムクーポン「%1$s」はWsn.%2$s以降の形式のシナリオでしか機能しません。"); // Wsn.2
	auto warningCanNotGetSetCoupon = Msg("warningCanNotGetSetCoupon", "システムクーポン「%1$s」を操作する事はできません。"); // Wsn.2
	auto warningCardImagePosition = Msg("warningCardImagePosition", "イメージの配置形式の指定は、Wsn.2以降の形式のシナリオでしか行えません。"); // Wsn.2
	auto warningStartAction = Msg("warningStartAction", "戦闘行動開始タイミングの指定は、Wsn.2以降の形式のシナリオしか行えません。"); // Wsn.2
	auto warningIgnite = Msg("warningIgnite", "イベントの発火有無の指定は、Wsn.2以降の形式のシナリオしか行えません。"); // Wsn.2
	auto warningIgnoreKeyCode = Msg("warningIgnoreKeyCode", "イベント発火無しに指定されているため、設定されたキーコードは機能しません。"); // Wsn.2
	auto warningBranchKeyCodeAtClassic = Msg("warningBranchKeyCodeAtClassic", "クラシックなシナリオにおけるキーコード所持分岐は、カードの種類に特殊技能・アイテム及び手札・召喚獣のいずれか単独、またはそれら全てを指定しなければ正しく機能しません。"); // Wsn.2
	auto warningBranchKeyCodeAtWsn1 = Msg("warningBranchKeyCodeAtWsn1", "Wsn.1以前のシナリオにおけるキーコード所持分岐は、カードの種類に特殊技能・アイテム・召喚獣のいずれか単独、またはそれら全てを指定しなければ正しく機能しません。"); // Wsn.2
	auto warningBranchKeyCodeWithItem = Msg("warningBranchKeyCodeWithItem", "クラシックなシナリオにおけるキーコード所持分岐でカードの種類にアイテムが含まれている場合は、戦闘時の手札も検索対象となります。");
	auto warningLoadScaledImage = Msg("warningLoadScaledImage", "スケーリングされたイメージファイルの読み込みは、Wsn.2以降の形式のシナリオに対応したエンジンでしか機能しません。"); // Wsn.2
	auto warningPlayerCardEvents = Msg("warningPlayerCardEvents", "プレイヤーカードに対するイベント設定は、Wsn.2以降の形式のシナリオしか行えません。"); // Wsn.2
	auto warningCouponHolder = Msg("warningCouponHolder", "%1$sコンテントにおける適用範囲 [称号所有者] の指定は、Wsn.%2$s以降の形式のシナリオしか行えません。"); // Wsn.2, Wsn.3
	auto warningNoHoldingCoupon = Msg("warningNoHoldingCoupon", "範囲指定用の称号が設定されていません。"); // Wsn.2
	auto warningCardTarget = Msg("warningCardTarget", "適用範囲 [カードの使用対象] の指定は、Wsn.2以降の形式のシナリオしか行えません。"); // Wsn.2
	auto warningRefAbility = Msg("warningRefAbility", "選択メンバの能力参照は、Wsn.2以降の形式のシナリオでしか行えません。"); // Wsn.2
	auto warningCenteringX = Msg("warningCenteringX", "横方向の中央寄せ表示は、Wsn.2以降の形式のシナリオでしか行えません。"); // Wsn.2
	auto warningCenteringY = Msg("warningCenteringY", "縦方向の中央寄せ表示は、Wsn.2以降の形式のシナリオでしか行えません。"); // Wsn.2
	auto warningBoundaryCheck = Msg("warningBoundaryCheck", "メッセージの禁則処理は、Wsn.2以降の形式のシナリオでしか行えません。"); // Wsn.2
	auto warningBranchCouponMulti = Msg("warningBranchCouponMulti", "クーポン分岐のクーポンの複数指定は、Wsn.2以降の形式のシナリオしか行えません。"); // Wsn.2
	auto warningExpandSPChars = Msg("warningExpandSPChars", "状態変数内の特殊文字の展開は、Wsn.2以降の形式のシナリオしか行えません。"); // Wsn.2
	auto warningExpandSPCharsInCoupon = Msg("warningExpandSPCharsInCoupon", "クーポン内の特殊文字の展開は、Wsn.4以降の形式のシナリオしか行えません。"); // Wsn.4
	auto warningExpandSPCharsInGossip = Msg("warningExpandSPCharsInGossip", "ゴシップ内の特殊文字の展開は、Wsn.4以降の形式のシナリオしか行えません。"); // Wsn.4
	auto warningExpandSPCharsInMenuCardName = Msg("warningExpandSPCharsInMenuCardName", "メニューカード名内の特殊文字の展開は、Wsn.4以降の形式のシナリオしか行えません。"); // Wsn.4
	auto warningSelectCard = Msg("warningSelectCard", "選択カードの変更は、Wsn.3以降の形式のシナリオしか行えません。"); // Wsn.3
	auto warningRangeSelectedCard = Msg("warningRangeSelectedCard", "選択カードは、Wsn.3以降の形式のシナリオでしか指定できません。"); // Wsn.3
	auto warningSelectTalker = Msg("warningSelectTalker", "話者の選択は、Wsn.3以降の形式のシナリオしか行えません。"); // Wsn.3
	auto warningInvertResult = Msg("warningInvertResult", "条件に合わない場合に成功とする事は、Wsn.4以降の形式のシナリオでしかできません。"); // Wsn.4
	auto warningInvertResultBranchKeyCode = Msg("warningInvertResultBranchKeyCode", "条件該当カードの不保有で成功とする事は、Wsn.4以降の形式のシナリオでしかできません。"); // Wsn.4
	auto warningHasNotBranchKeyCode = Msg("warningHasNotBranchKeyCode", "キーコードを持たないカードで成功とする事は、Wsn.5以降の形式のシナリオでしかできません。"); // Wsn.5
	auto warningInvocationCondition = Msg("warningInvocationCondition", "「生存」以外の条件で発動する召喚獣は、Wsn.3以降の形式のシナリオでしか機能しません。"); // Wsn.3
	auto warningRemoveWithUnconscious = Msg("warningRemoveWithUnconscious", "意識不明時に消滅しない召喚獣は、Wsn.3以降の形式のシナリオでしか機能しません。"); // Wsn.3
	auto warningInconsistencyStatus = Msg("warningInconsistencyStatus", "%1$s状態と%2$s状態を同時に設定する事はできません。");
	auto warningUnconsciousCondition = Msg("warningUnconsciousCondition", "意識不明時に消滅するにもかかわらず意識不明状態が発動条件になっています。"); // Wsn.3
	auto warningPossibleToRunAway = Msg("warningPossibleToRunAway", "バトルの逃走不可設定はWsn.3以降の形式のシナリオでしか機能しません。"); // Wsn.3
	auto warningNoIgniteRunAway = Msg("warningNoIgniteRunAway", "逃走できないバトルのイベントに逃走発火条件が設定されています。"); // Wsn.3
	auto warningConsumeCard = Msg("warningConsumeCard", "カード消費の抑止は、Wsn.3以降の形式のシナリオでしか機能しません。"); // Wsn.3
	auto warningOverrideEnemyCardName = Msg("warningOverrideEnemyCardName", "エネミーカードの名前の上書きは、Wsn.4以降の形式のシナリオしか行えません。"); // Wsn.4
	auto warningOverrideEnemyCardImage = Msg("warningOverrideEnemyCardImage", "エネミーカードのイメージの上書きは、Wsn.4以降の形式のシナリオしか行えません。"); // Wsn.4
	auto warningVariant = Msg("warningVariant", "コモンはWsn.4以降の形式のシナリオでしか使用できません。"); // Wsn.4
	auto warningLocalVariablesOfEffectCard = Msg("warningLocalVariablesOfEffectCard", "カードのローカル変数はWsn.4以降の形式のシナリオでしか使用できません。"); // Wsn.4
	auto warningExchangeIsItemInClassic = Msg("warningExchangeIsItemInClassic", "クラシックなシナリオでは、最初のアイテムカードとして「%1$s」と同名のカードを所有していると、本来の「%1$s」が配付されません。");
	auto warningNoActionCard = Msg("warningNoActionCard", "エネミーカードのアクション有無の指定は、Wsn.4以降の形式のシナリオでしか行えません。"); // Wsn.4

	auto warningLayerV7 = Msg("warningLayerV7", "前面セルにはレイヤ値%1$sを指定してください。");
	auto warningReplaceBgImageV7 = Msg("warningReplaceBgImageV7", "CardWirthNext 1.60の背景置換コンテントでは、JPY1のアニメーションは実行されず、エフェクトブースターのセルは無視されます。");
	auto warningLoseBgImageV7 = Msg("warningLoseBgImageV7", "CardWirthNext 1.60の背景置換コンテントでは、JPY1のアニメーションは実行され、エフェクトブースターのセルは無視されます。");
	auto warningMoveBgImageV7 = Msg("warningMoveBgImageV7", "CardWirthNext 1.60の背景置換コンテントでは、JPY1のアニメーションは実行され、エフェクトブースターのセルは無視されます。");
	auto warningMoveCardV7 = Msg("warningMoveCardV7", "CardWirthNext 1.60のカード移動コンテントでは、拡大率変更・レイヤ変更・アニメーション有無以外のアニメーション速度指定は行えません。");
	auto warningChangeEnvironmentV7 = Msg("warningChangeEnvironmentV7", "CardWirthNext 1.60の禁止コンテントでは、禁止状態を未指定にする事はできません。");
	auto warningIgnoreKeyCodeV7 = Msg("warningIgnoreKeyCodeV7", "CardWirthNext 1.60では、効果コンテントにキーコードは指定できません。");
	auto warningIgniteDeadEvent = Msg("warningIgniteDeadEvent", "CardWirthNext 1.60では、効果コンテントで死亡イベントが発火します。");
	auto warningIgniteNoDeadEvent = Msg("warningIgniteNoDeadEvent", "効果コンテントに死亡イベント発火要因となる効果が含まれていません。");
	auto warningCheckFlagV7 = Msg("warningCheckFlagV7", "CardWirthNext 1.60では、フラグ値の変更の直後にフラグ判定を行うと、値の変化が判定結果に反映されません。");
	auto warningCheckStepV7 = Msg("warningCheckStepV7", "CardWirthNext 1.60では、ステップ値の変更の直後にステップ判定を行うと、値の変化が判定結果に反映されません。");

	auto unknownStepValue = Msg("unknownStepValue", "存在しないステップ値(%1$s)");

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
	auto eventIgnite = Msg("eventIgnite", "イベント発火");

	auto rangeHint = Msg("rangeHint", "(%1$s～%2$s)");
	auto source = Msg("source", "出典");
	auto sourceScenario = Msg("sourceScenario", "シナリオ名");
	auto sourceAuthor = Msg("sourceAuthor", "シナリオ作者");
	auto resetSource = Msg("resetSource", "現在のシナリオを出典に設定");
	auto diffSource = Msg("diffSource", "出典のシナリオ名と作者名が現在のシナリオと異なるため、使用時イベントのカード入手、エリア移動、パッケージのコール等は実行されません。");

	auto exportedImageName = Msg("exportedImageName", "%1$s");
	auto exportedImageNameWithAuthor = Msg("exportedImageNameWithAuthor", "%1$s(%2$s)");
	auto exportedImageNameWithCard = Msg("exportedImageNameWithCard", "%1$s_%2$s");

	/// ファイルビュー。
	auto dirTabName = Msg("dirTabName", "ファイル");
	auto dirStatus = Msg("dirStatus", "%1$s個のファイル (%2$s)");
	auto dirStatusSel = Msg("dirStatusSel", "%1$s個のファイル (%2$s) (%3$s個を選択中)");
	auto dirName = Msg("dirName", DIR ~ "名");
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
	auto warningFileExtension = Msg("warningFileExtension", "このファイルの本来の拡張子は「*%1$s」です。");

	/// エディタ設定ダイアログ。
	auto baseSettings = Msg("baseSettings", "基本設定");
	auto reference = Msg("reference", "...");
	auto enginePath = Msg("enginePath", "%1$sの場所");
	auto filterEnginePath = Msg("filterEnginePath", "CardWirthPy (%1$s)");
	auto findEnginePath = Msg("findEnginePath", "シナリオの場所から自動的に探す");
	auto dlgTitEnginePath = Msg("dlgTitEnginePath", "%1$sの場所");
	auto tempDir = Msg("tempDir", "シナリオの一時展開先");
	auto tempDirDesc = Msg("tempDirDesc", "wsn圧縮されたシナリオの一時的な展開先を選択してください。");
	auto backupDir = Msg("backupDir", "自動バックアップ");
	auto backupEnabled = Msg("backupEnabled", "自動バックアップを行う");
	auto autoSave = Msg("autoSave", "バックアップ時に上書き保存する");
	auto backupArchived = Msg("backupArchived", "圧縮してバックアップする");
	auto backupRefAuthor = Msg("backupRefAuthor", "作者が一致したシナリオのみバックアップする");
	auto backupPath = Msg("backupPath", "保存先");
	auto backupDirDesc = Msg("backupDirDesc", "シナリオを定期的に自動バックアップする" ~ DIR ~ "を選択してください。");
	auto backupIntervalTime = Msg("backupIntervalTime", "時間間隔で行う");
	auto backupIntervalEdit = Msg("backupIntervalEdit", "編集回数で行う");
	auto minute = Msg("minute", "分");
	auto count = Msg("count", "回");
	auto backupCount = Msg("backupCount", "最大保存数");
	auto backupBeforeSaveDir = Msg("backupBeforeSaveDir", "保存時バックアップ");
	auto backupBeforeSave = Msg("backupBeforeSave", "保存時バックアップ");
	auto backupBeforeSaveDirDesc = Msg("backupDirDesc", "シナリオファイルのバックアップコピーを作成する" ~ DIR ~ "を選択してください。");
	auto backupBeforeSaveEnabled = Msg("backupBeforeSaveEnabled", "保存時にシナリオファイルのバックアップコピーを作成する");
	auto backupBeforeSavePath = Msg("backupBeforeSavePath", "保存先");
	auto skin = Msg("skin", "スキン");
	auto scenarioAuthor = Msg("scenarioAuthor", "シナリオ作者(新規作成時に自動設定されます)");
	auto startAreaName = Msg("startAreaName", "新規作成時の開始エリア名(空欄 = 開始エリア無し)");
	auto historiesSettings = Msg("historiesSettings", "履歴");
	auto openHistoryMax = Msg("openHistoryMax", "シナリオ履歴保存件数");
	auto openHistoryClear = Msg("openHistoryClear", "クリア");
	auto dlgMsgHistoryClear = Msg("dlgMsgHistoryClear", "シナリオ履歴を削除してよろしいですか？");
	auto searchHistoryMax = Msg("searchHistoryMax", "検索/置換履歴保存件数");
	auto searchHistoryClear = Msg("searchHistoryClear", "クリア");
	auto dlgMsgSearchHistoryClear = Msg("dlgMsgSearchHistoryClear", "検索/置換履歴を削除してよろしいですか？");
	auto executedPartiesMax = Msg("executedPartiesMax", "パーティ履歴保存件数");
	auto executedPartiesClear = Msg("executedPartiesClear", "クリア");
	auto dlgMsgExecutedPartiesClear = Msg("dlgMsgExecutedPartiesClear", "パーティ履歴を削除してよろしいですか？");
	auto ignorePaths = Msg("ignorePaths", "無視ファイル(改行区切り)");
	auto etcSettings = Msg("etcSettings", "その他");

	auto etcSettingsTitle = Msg("etcSettingsTitle", "詳細");

	auto previewScale = Msg("previewScale", "拡大率");
	auto imageScale = Msg("imageScale", "表示");
	auto drawingScale = Msg("drawingScale", "描画");
	auto imageScaleValue = Msg("imageScaleValue", "%s倍");

	auto languageSetting = Msg("languageSetting", "言語");
	auto languageSystem = Msg("languageSystem", "システムの言語");
	auto languageCaution = Msg("languageCaution", "※ 次回起動時から適用されます");

	auto etcSettingsCommon = Msg("etcSettingsCommon", "全般");
	auto showImagePreview = Msg("showImagePreview", "カードや背景のプレビュー表示を行う");
	auto maskCardImagePreview = Msg("maskCardImagePreview", "カードサイズの画像のプレビュー表示で背景を透明化する");
	auto switchTabWheel = Msg("switchTabWheel", "マウスホイールでタブ切替を行う");
	auto closeTabWithMiddleClick = Msg("closeTabWithMiddleClick", "中ボタンクリックでタブを閉じる");
	auto openTabAtRightOfCurrentTab = Msg("openTabAtRightOfCurrentTab", "新しいタブを現在のタブの直後に開く");
	auto showCloseButtonAllTab = Msg("showCloseButtonAllTab", "全てのタブに閉じるボタンを表示する");
	auto comboListVisible = Msg("comboListVisible", "コンボボックスでの編集開始時にリストを開く");
	auto showCurrentValueOnTopAlways = Msg("showCurrentValueOnTopAlways", "コンボボックスで現在の値を常に最上段に表示する");
	auto editTriggerTypeIsQuick = Msg("editTriggerTypeIsQuick", "選択項目のクリックですぐにテキストの編集を開始する");
	auto xmlCopy = Msg("xmlCopy", "コピーや切り取りを常にXML形式で行う");
	auto logicalSort = Msg("logicalSort", "数値参照型ソートを行う(1, 10, 2, 3, ... → 1, 2, 3, 10, ...)");
	auto canVanishWorkAreaInMainWindow = Msg("canVanishWorkAreaInMainWindow", "サブウィンドウに編集エリアがあればメインウィンドウの編集エリアを閉じる");
	auto useCoolBar = Msg("useCoolBar", "配置変更可能なツールバーを使用する");

	auto etcSettingsLoad = Msg("etcSettingsLoad", "読込と保存");
	auto saveSkinName = Msg("saveSkinName", "WSN(XML)形式のシナリオでスキンタイプに加えてスキン名称も保存する");
	auto saveNeedChanged = Msg("saveNeedChanged", "変更があった時だけ上書き保存を有効にする");
	auto applyDialogsBeforeSave = Msg("applyDialogsBeforeSave", "保存前にダイアログの編集内容を適用する");
	auto doubleIO = Msg("doubleIO", "分割読込・保存を行う(デュアルコア以上の環境で高速化)");
	auto cautionToScenarioLoadErrors = Msg("cautionToScenarioLoadErrors", "シナリオの一部ファイルの読み込みに失敗した場合に警告する");
	auto archiveInNewThread = Msg("archiveInNewThread", "保存時の圧縮を別スレッドで行う(圧縮シナリオの保存の高速化)");
	auto saveChangedOnlyWsn = Msg("saveChangedOnlyWsn", "WSN形式のシナリオの上書き時に更新されたファイルだけを保存する");
	auto saveChangedOnlyClassic = Msg("saveChangedOnlyClassic", "クラシックなシナリオの上書き時に更新されたファイルだけを保存する");
	auto expandXMLs = Msg("expandXMLs", "圧縮されたシナリオの読込み時にXMLファイルを展開する");
	auto xmlFileNameIsIDOnly = Msg("xmlFileNameIsIDOnly", "XMLファイルの名前にエリア名などを含めずIDのみで設定する");
	auto replaceClassicResourceExtension = Msg("replaceClassicResourceExtension", "クラシックなシナリオの保存時にスキン付属リソースの拡張子を変換する");
	auto saveInnerImagePath = Msg("saveInnerImagePath", "クラシックなシナリオで格納イメージのファイルパスを保存する");
	auto addNewClassicEngine = Msg("addNewClassicEngine", "未知のクラシックエンジンを見つけたら記憶する");
	auto openLastScenario = Msg("openLastScenario", "終了時に開いていたシナリオを次の起動時に開く");
	auto reconstruction = Msg("reconstruction", "シナリオごとにタブの配置を記憶する");

	auto etcSettingsFile = Msg("etcSettingsFile", "ファイルの追跡");
	auto traceDirectories = Msg("traceDirectories", "ファイル・" ~ DIR ~ "の変更を自動的に追跡する");
	auto autoUpdateJpy1File = Msg("autoUpdateJpy1File", "ファイル名が変更された時に関係するJPY1・JPDCファイルを自動的に更新する");

	auto etcSettingsFind = Msg("etcSettingsFind", "検索と置換");
	auto startIncrementalSearchWhenKeyDown = Msg("startIncrementalSearchWhenKeyDown", "何かキーを押した時に絞り込み検索を開始する");
	auto cautionBeforeReplace = Msg("cautionBeforeReplace", "全て置換する前に確認ダイアログを表示する");

	auto etcSettingsTable = Msg("etcSettingsTable", "テーブルビューの設定");
	auto showAreaDirTree = Msg("showAreaDirTree", "テーブルビューを階層表示する");
	auto showSummaryInAreaTable = Msg("showSummaryInAreaTable", "テーブルビューにシナリオの概要を表示する");
	auto clickIsOpenEvent = Msg("clickIsOpenEvent", "左クリックでイベントビューを開く");
	auto incrementNewAreaName = Msg("incrementNewAreaName", "エリア等の作成時に既存のアイテムと重複しない名前を生成する");

	auto etcSettingsScene = Msg("etcSettingsScene", "シーンビューの設定");
	auto switchFixedWithCheckBox = Msg("switchFixedWithCheckBox", "チェックボックスで個別のカードと背景セルの固定状態を切り替える");
	auto resizingImageWithRatio = Msg("resizingImageWithRatio", "複数のカードと背景セルのサイズ変更時に相対的な位置とサイズを維持する");
	auto showSceneViewSelectionFilter = Msg("showSceneViewSelectionFilter", "選択されたカードの上に半透明のカーテンをかける");
	auto drawXORSelectionLine = Msg("drawXORSelectionLine", "選択枠を色の反転で描画する");
	auto smoothingCard = Msg("smoothingCard", "カードのサイズ変更時にスムージングを行う");
	auto ignoreBackgroundInRange = Msg("ignoreBackgroundInRange", "範囲選択でフルサイズの背景セルを無視する");
	auto copyDesc = Msg("copyDesc", "カードをエリアに貼り付け・ドロップした時、解説もコピーする");
	auto showItemNumberOfSceneAndEventView = Msg("showItemNumberOfSceneAndEventView", "メニュー・エネミーカード及び背景セルの番号を表示する");
	auto showCardStatusUnderPointer = Msg("showCardStatusUnderPointer", "マウスカーソル下のメニュー・エネミーカードの情報をステータスバーに表示する");

	auto etcSettingsEvent = Msg("etcSettingsEvent", "イベントビューの設定");
	auto showContentsGroupName = Msg("showContentsGroupName", "コンテンツボックスにグループ名を表示する");
	auto showEventContentDescription = Msg("showEventContentDescription", "イベントコンテントの解説をツールチップで表示する");
	auto contentsFloat = Msg("contentsFloat", "コンテンツボックスを別ウィンドウで表示する");
	auto contentsAutoHide = Msg("contentsAutoHide", "コンテンツボックスを自動的に隠す");
	auto straightEventTreeView = Msg("straightEventTreeView", "イベントツリーを垂直に表示する");
	auto forceIndentBranchContent = Msg("forceIndentBranchContent", "分岐コンテントの後続コンテントは必ず右へ移動する");
	auto showTerminalMark = Msg("showTerminalMark", "イベントツリーの終端を明示する");
	auto showTargetStartLineNumber = Msg("showTargetStartLineNumber", "スタートへのリンク・コールの関係を行番号で表示する");
	auto classicStyleTree = Msg("classicStyleTree", "イベントツリーの開閉ボタンを省略する");
	auto clickIconIsStartEdit = Msg("clickIconIsStartEdit", "イベントコンテントのアイコンのクリックでダイアログを開く");
	auto adjustContentName = Msg("adjustContentName", "イベントコンテントの移動時にテキストを再設定する");
	auto showVariableValuesInEventText = Msg("showVariableValuesInEventText", "選択肢のテキスト内の変数をプレビュー表示する(#M -> [選択中]...)");
	auto editSelectionWithCombo = Msg("editSelectionWithCombo", "選択肢を編集する時、「標準の選択肢」をコンボボックスで選択可能にする");
	auto refCardsAtEditBgImage = Msg("refCardsAtEditBgImage", "背景変更コンテントの編集を開始する際、最初からカード配置の参照を行う");
	auto floatMessagePreview = Msg("floatMessagePreview", "セリフ・メッセージのプレビューをフロートさせる");
	auto useMessageWindowColorInTextContentDialog = Msg("useMessageWindowColorInTextContentDialog", "セリフ・メッセージの編集欄でメッセージウィンドウの色を使用する");
	auto selectVariableWithTree = Msg("selectVariableWithTree", "状態変数選択ビューでディレクトリの階層表示を行う");
	auto useNamesAfterStandard = Msg("useNamesAfterStandard", "シナリオで使用中の称号・キーコードを標準の称号・キーコードの後に配置する");
	auto expandChooserItems = Msg("expandChooserItems", "エリアや状態変数等を選択するビューでは全て開いた状態を初期状態とする");
	auto restorePositionOfEventTreeView = Msg("restorePositionOfEventTreeView", "イベントごとにイベントツリービューの表示位置を記憶する");

	auto etcSettingsCard = Msg("etcSettingsCard", "カードビューの設定");
	auto showHandMark = Msg("showHandMark", "キャストカードの詳細情報表示時に所有カードの有無を表示する");
	auto showEventTreeMark = Msg("showEventTreeMark", "効果系カードの詳細情報表示時に使用時イベントの有無を表示する");
	auto ignoreEmptyStart = Msg("ignoreEmptyStart", "空のイベントツリーしか持たない使用時イベントは無視する");
	auto showCardListHeader = Msg("showCardListHeader", "カードの画像表示時にヘッダを表示する");
	auto showCardListTitle = Msg("showCardListTitle", "カードの画像表示時にIDと名前を表示する");
	auto showSkillCardLevel = Msg("showSkillCardLevel", "カードの画像表示時に特殊技能カードのレベルを表示する");
	auto showMotionDescription = Msg("showMotionDescription", "効果の解説をツールチップで表示する");
	auto showSpNature = Msg("showSpNature", "特殊型を表示する");
	auto radarStyleParams = Msg("radarStyleParams", "レーダー型コントロールでパラメータ値を設定する");
	auto showAptitudeOnCastCardEditor = Msg("showAptitudeOnCastCardEditor", "キャストカードの身体能力と精神傾向の編集時にで各種適性を表示する");
	auto linkCard = Msg("linkCard", "クラシックなシナリオでキャストの所有カードや召喚対象カードを参照で設定する");

	auto soundPlayType = Msg("soundPlayType", "BGM再生方式");
	auto soundPlayTypeDef = Msg("soundPlayTypeDef", "自動選択");
	auto soundPlayTypeSDL = Msg("soundPlayTypeSDL", "SDL_mixer(旧方式)");
	auto soundPlayTypeMCI = Msg("soundPlayTypeMCI", "WinMM(CardWirth方式)");
	auto soundPlayTypeApp = Msg("soundPlayTypeApp", "関連付けされたアプリケーションで開く");
	auto soundEffectPlayType = Msg("soundEffectPlayType", "効果音再生方式");
	auto soundPlaySameBGM = Msg("soundPlaySameBGM", "BGMに合わせる");
	auto soundVolume = Msg("soundVolume", "音量");
	auto soundVolumePer = Msg("soundVolumePer", "%");
	auto soundCaution = Msg("soundCaution", "※ WinMM方式の時、音量は反映されません");

	auto flagInitValue = Msg("flagInitValue", "フラグの初期値");
	auto stepInitValue = Msg("stepInitValue", "ステップの初期値");
	auto stepValueName = Msg("stepValueName", "ステップ値($N = 数値)");

	auto keyBind = Msg("keyBind", "キーバインド");
	auto mnemonic = Msg("mnemonic", "アクセスキー");
	auto hotkey = Msg("hotkey", "ショートカット");

	auto wallpaper = Msg("wallpaper", "エディタの壁紙");
	auto filterImage = Msg("filterImage", "画像ファイル (*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.ico;*.icon)");
	auto dlgTitWallpaper = Msg("dlgTitWallpaper", "壁紙画像の選択");
	auto wallpaperStyle = Msg("wallpaperStyle", "表示形式");
	const string wallpaperStyleName(WallpaperStyle id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "wallpaperStyleName"));
	}
	auto wallpaperStyleNameCenter = Msg("wallpaperStyleNameCenter", "中央に表示");
	auto wallpaperStyleNameTile = Msg("wallpaperStyleNameTile", "並べて表示");
	auto wallpaperStyleNameExpandFull = Msg("wallpaperStyleNameExpandFull", "拡大して表示");
	auto wallpaperStyleNameExpand = Msg("wallpaperStyleNameExpand", "はみ出さないように拡大");

	auto bgImageAndSelections = Msg("bgImageAndSelections", "背景と選択肢");
	auto standardSelections = Msg("standardSelections", "標準の選択肢");
	auto standardKeyCode = Msg("standardKeyCode", "標準のキーコード");
	auto keyCodesByFeatures = Msg("keyCodesByFeatures", "特徴とキーコードの対応");
	auto cardFeature = Msg("cardFeature", "カードの特徴");
	auto keyCodesByMotions = Msg("keyCodesByMotions", "効果とキーコードの対応");
	auto noElement = Msg("noElement", "指定無し");
	auto elementOverrides = Msg("elementOverrides", "効果属性の上書き");
	auto elementOverrideName = Msg("elementOverrideName", "属性名");
	auto elementOverrideTargetType = Msg("elementOverrideTargetType", "対属性");
	auto elementAllTargetType = Msg("elementAllTargetType", "(対属性無し)");
	auto elementWeaknessAndResistTargetType = Msg("elementWeaknessAndResistTargetType", "(弱点または無効)");
	auto selectElementIcon = Msg("selectElementIcon", "効果属性のアイコンを選択");

	auto errorEnginePath = Msg("errorEnginePath", "%1$sの場所が正しくありません。");
	auto errorTempPath = Msg("errorTempPath", "一時展開先が正しくありません。");
	auto errorBackupPath = Msg("errorBackupPath", "自動バックアップ先が正しくありません。");
	auto errorBackupBeforeSavePath = Msg("errorBackupBeforeSavePath", "保存時バックアップ先が正しくありません。");

	auto sNew = Msg("sNew", "新規作成");
	auto sAlt = Msg("sAlt", "上書き");
	auto sDel = Msg("sDel", "削除");
	auto dlgMsgForceApply = Msg("dlgMsgForceApply", "次の設定が変更されたまま適用されていません。適用して設定を更新しますか？\n%1$s");
	auto dlgMsgForceApplySingle = Msg("dlgMsgForceApplySingle", "%1$sが変更されたまま適用されていません。適用して設定を更新しますか？");
	auto dlgMsgForceApplySelection = Msg("dlgMsgForceApplySelection", "「%1$s」が変更されたまま適用されていません。適用して他の項目を選択しますか？");
	auto noNameData = Msg("noNameData", "(名前無しの項目)");

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
	auto exeFileDescAll = Msg("exeFileDescAll", "全てのファイル (*.*)");

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

	auto selectSkinType = Msg("selectSkinType", "設定対象のスキンタイプ");
	auto defaultSettings = Msg("defaultSettings", "デフォルト");
	auto editSkinTypeName = Msg("editSkinTypeName", "スキンタイプ名の編集");
	auto editSkinTypeNameDesc = Msg("editSkinTypeNameDesc", "スキンタイプの名前");
	auto addSkinType = Msg("addSkinType", "スキンタイプの追加");
	auto addSkinTypeDesc = Msg("addSkinTypeDesc", "追加するスキンタイプの名前");
	auto delSkinType = Msg("delSkinType", "スキンタイプ別設定の削除");
	auto delSkinTypeDesc = Msg("delSkinTypeDesc", "スキンタイプ「%1$s」の設定を削除してよろしいですか？");
	auto cloneSkinType = Msg("cloneSkinType", "スキンタイプ別設定の複製");
	auto cloneSkinTypeDesc = Msg("cloneSkinTypeDesc", "複製先のスキンタイプの名前");
	auto overrideDefaultSettings = Msg("overrideDefaultSettings", "スキンタイプ別設定によるデフォルト設定の上書き");
	auto overrideBgImagesSettings = Msg("overrideBgImagesSettings", "背景設定を上書きする");
	auto overrideSelectionsSettings = Msg("overrideSelectionsSettings", "選択肢設定を上書きする");
	auto overrideKeyCodesSettings = Msg("overrideKeyCodesSettings", "キーコード設定を上書きする");

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

	auto dialogStatus = Msg("dialogStatus", "セリフコンテントのステータス");
	const string dialogStatusName(DialogStatus id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "dialogStatusName"));
	}
	auto dialogStatusNameTop = Msg("dialogStatusNameTop", "最上位のセリフ");
	auto dialogStatusNameUnder = Msg("dialogStatusNameUnder", "最下位のセリフ");
	auto dialogStatusNameUnderWithCoupon = Msg("dialogStatusNameUnderWithCoupon", "最下位のセリフ(条件クーポン設定あり)");

	auto dlgTitEvTemplates = Msg("dlgTitEvTemplates", "イベントテンプレート - %1$s");
	auto eventTemplateHint1 = Msg("eventTemplateHint1", "下記のようにスクリプトの冒頭に値の無い変数を置くと、テンプレートからの配置時に値を設定できます。");
	auto eventTemplateHint2 = Msg("eventTemplateHint2", "$時間\nwait $時間");

	auto dlgTitCustomizeToolBar = Msg("dlgTitCustomizeToolBar", "ツールバーの編集");
	auto toolBarName = Msg("toolBarName", "ツールバー (%1$s)");
	auto toolGroupName = Msg("toolGroupName", "グループ (%1$s)");

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
	auto scriptErrorNoIfContents = Msg("scriptErrorNoIfContents", "分岐先のコンテントが見つかりません。");
	auto scriptErrorInvalidKeyword = Msg("scriptErrorInvalidKeyword", "未知のキーワードです。");
	auto scriptErrorInvalidKeyword2 = Msg("scriptErrorInvalidKeyword2", "キーワードが正しくありません。");
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
	auto scriptErrorInvalidSelectionMethod = Msg("scriptErrorInvalidSelectionMethod", "未知のメンバ選択方法です。");
	auto scriptErrorInvalidDialog = Msg("scriptErrorInvalidDialog", "セリフが正しくありません。");
	auto scriptErrorInvalidTalker = Msg("scriptErrorInvalidTalker", "話者が正しくありません。");
	auto scriptErrorInvalidCoupon = Msg("scriptErrorInvalidCoupon", "評価条件が正しくありません。");
	auto scriptErrorUndefinedSymbol = Msg("scriptErrorUndefinedSymbol", "未知のシンボルです。");
	auto scriptErrorInvalidSif = Msg("scriptErrorInvalidSif", "ここにsifが現れる事はできません。");
	auto scriptErrorInvalidCommand = Msg("scriptErrorInvalidCommand", "命令が正しくありません。");
	auto scriptErrorCanNotHaveContent = Msg("scriptErrorCanNotHaveContent", "%1$sコンテントが後続コンテントを持つ事はできません。");
	auto scriptErrorInvalidStr = Msg("scriptErrorInvalidStr", "文字列が正しくありません。");
	auto scriptErrorReqNumber = Msg("scriptErrorReqNumber", "ここに数値が必要です。");
	auto scriptErrorReqID = Msg("scriptErrorReqID", "ここにIDが必要です。");
	auto scriptErrorUndefinedVar = Msg("scriptErrorUndefinedVar", "存在しない変数です。");
	auto scriptErrorInvalidValue = Msg("scriptErrorInvalidValue", "値が正しくありません。");
	auto scriptErrorInvalidCoordinateType = Msg("scriptErrorInvalidCoordinateType", "未知の位置・サイズ形式です。");
	auto scriptErrorInvalidArray = Msg("scriptErrorInvalidArray", "ここに配列が必要です。");
	auto scriptErrorSystem = Msg("scriptErrorSystem", "サイズが大きすぎるため、CWXスクリプトをコンパイルできません。");
	auto scriptErrorInvalidCardImagePosition = Msg("scriptErrorInvalidCardImagePosition", "イメージの配置形式が正しくありません。");
	auto scriptErrorInvalidStartAction = Msg("scriptErrorInvalidStartAction", "未知の戦闘行動開始タイミングです。"); // Wsn.2
	auto scriptErrorInvalidMatchingType = Msg("scriptErrorInvalidMatchingType", "未知の判定条件です。"); // Wsn.2
	auto scriptErrorInvalidMatchingCondition = Msg("scriptErrorInvalidMatchingCondition", "未知のマッチング条件です。"); // Wsn.5
	auto scriptErrorInvalidUpdateType = Msg("scriptErrorInvalidUpdateType", "未知の更新タイプです。"); // Wsn.4
	auto scriptErrorInvalidEnvironmentStatus = Msg("scriptErrorInvalidEnvironmentStatus", "未知の状況です。"); // Wsn.4
	auto scriptErrorInvalidVariableType = Msg("scriptErrorInvalidVariableType", "未知の状態変数です。"); // Wsn.4
	auto scriptErrorInvalidAbsorbTo = Msg("scriptErrorInvalidAbsorbTo", "未知の吸収者です。"); // Wsn.4

	auto dlgTitScriptVarSet = Msg("dlgTitScriptVarSet", "値が未決定の変数の設定");
	auto scriptVarSet = Msg("scriptVarSet", "変数に値を入力");
	auto scriptVarNameColumn = Msg("scriptVarNameColumn", "変数名");
	auto scriptVarValueColumn = Msg("scriptVarValueColumn", "値");
	auto material = Msg("material", "ファイル");
	auto coupon = Msg("coupon", "クーポン");
	auto gossip = Msg("gossip", "ゴシップ");
	auto completeStamp = Msg("completeStamp", "終了印");

	auto jpyErrorInfoWithoutFile = Msg("jpyErrorInfoWithoutFile", "%1$s (%2$s 行目)");
	auto jpyError = Msg("jpyError", "%1$s\n%2$s の %3$s 行目");
	auto jpyErrorDupSection = Msg("jpyErrorDupSection", "セクション名が重複してます: %1$s");
	auto jpyErrorInvalidPoint = Msg("jpyErrorInvalidPoint", "位置の書式が正しくありません: %1$s");
	auto jpyErrorInvalidRect = Msg("jpyErrorInvalidRect", "位置とサイズの書式が正しくありません: %1$s");
	auto jpyErrorInvalidRGB = Msg("jpyErrorInvalidRGB", "値が正しくありません: %1$s");
	auto jpyErrorInvalidEnum = Msg("jpyErrorInvalidEnum", "数値でなければなりません: %1$s");
	auto jpyErrorInvalidStr = Msg("jpyErrorInvalidStr", "文字コードが正しくありません: %1$s");
	auto jpyErrorInvalidInt = Msg("jpyErrorInvalidInt", "数値でなければなりません: %1$s");
	auto jpyErrorInvalidBool = Msg("jpyErrorInvalidBool", "真偽値が正しくありません: %1$s");
	auto jpyErrorInvalidEncoding = Msg("jpyErrorInvalidEncoding", "文字コードが不正です。");
	auto jpyErrorInvalidLine = Msg("jpyErrorInvalidLine", "コマンドか値のどちらかが欠けています: %1$s");
	auto jpyErrorInvalidCommand = Msg("jpyErrorInvalidCommand", "コマンドが正しくありません: %1$s");
	auto jpyErrorInvalidStartTag = Msg("jpyErrorInvalidStartTag", "開始タグが正しくありません: %1$s");
	auto jpyErrorLabelNotFound = Msg("jpyErrorLabelNotFound", "セクションがありません。");

	/// 式。
	auto expressionErrorFunctionIsNotExistsInTargetVersion = Msg("expressionErrorFunctionIsNotExistsInTargetVersion", "%1$sはWsn.%2$s以降でなければ使用できません。");
	auto expressionErrorStructureIsNotExistsInTargetVersion = Msg("expressionErrorStructureIsNotExistsInTargetVersion", "%1$sはWsn.%2$s以降でなければ使用できません。");
	auto expressionErrorStructureMemberIsNotExistsInTargetVersion = Msg("expressionErrorStructureMemberIsNotExistsInTargetVersion", "%1$s.%2$sはWsn.%3$s以降でなければ使用できません。");
	auto expressionErrorPermissionOfStructure = Msg("expressionErrorPermissionOfStructure", "%1$sは関数で生成しなければなりません。");
	auto expressionErrorPermissionOfStructureMember = Msg("expressionErrorPermissionOfStructureMember", "%1$s.%2$sは参照できません。");
	auto expressionErrorFunctionIsNotDefined = Msg("expressionErrorFunctionIsNotDefined", "%1$sという名前の関数はありません。");
	auto expressionErrorValueIsNotString = Msg("expressionErrorValueIsNotString", "演算対象が文字列ではありません。"); // Wsn.5
	auto expressionErrorValueIsNotNumber = Msg("expressionErrorValueIsNotNumber", "演算対象が数値ではありません。");
	auto expressionErrorValueIsNotBoolean = Msg("expressionErrorValueIsNotBoolean", "演算対象が真偽値ではありません。");
	auto expressionErrorValueIsNotList = Msg("expressionErrorValueIsNotList", "演算対象がリストではありません。"); // Wsn.5
	auto expressionErrorValueIsNotStructure = Msg("expressionErrorValueIsNotStructure", "構造体ではありません。"); // Wsn.5
	auto expressionErrorDivisionByZero = Msg("expressionErrorDivisionByZero", "ゼロによる除算が行われました。");
	auto expressionErrorInvalidCharacter = Msg("expressionErrorInvalidCharacter", "式に使用できない文字が含まれています。");
	auto expressionErrorInvalidFunctionCall = Msg("expressionErrorInvalidFunctionCall", "関数の呼び出し方が正しくありません。");
	auto expressionErrorNeedOpenParen = Msg("expressionErrorNeedOpenParen", "開き括弧が必要です。");
	auto expressionErrorNoArgument = Msg("expressionErrorNoArgument", "引数がありません。");
	auto expressionErrorNeedBoolean = Msg("expressionErrorNeedBoolean", "真偽値が必要です。");
	auto expressionErrorNeedSymbolOrNumber = Msg("expressionErrorNeedSymbolOrNumber", "数値または関数呼び出しが必要です。");
	auto expressionErrorNeedOperator = Msg("expressionErrorNeedOperator", "演算子が必要です。");
	auto expressionErrorInvalidNumber = Msg("expressionErrorInvalidNumber", "数値が大きすぎます。");
	auto expressionErrorInvalidSemantics = Msg("expressionErrorInvalidSemantics", "式の構文が正しくありません。");
	auto expressionErrorUnknownSymbol = Msg("expressionErrorUnknownSymbol", "未知のシンボルです: %1$s");
	auto expressionErrorInvalidArgumentCount = Msg("expressionErrorInvalidArgumentCount", "%1$sの引数は%2$s件でなければなりません。");
	auto expressionErrorInvalidArgumentCount2 = Msg("expressionErrorInvalidArgumentCount2", "%1$sの引数は%2$s～%3$s件でなければなりません。");
	auto expressionErrorArgumentIsNotNumber = Msg("expressionErrorArgumentIsNotNumber", "%1$sの%2$s番目の引数は数値でなければなりません。");
	auto expressionErrorArgumentIsNotString = Msg("expressionErrorArgumentIsNotString", "%1$sの%2$s番目の引数は文字列でなければなりません。");
	auto expressionErrorArgumentIsNotBoolean = Msg("expressionErrorArgumentIsNotBoolean", "%1$sの%2$s番目の引数は真偽値でなければなりません。");
	auto expressionErrorArgumentIsNotList = Msg("expressionErrorArgumentIsNotList", "%1$sの%2$s番目の引数はリストでなければなりません。"); // Wsn.5
	auto expressionErrorArgumentIsNotStructure = Msg("expressionErrorArgumentIsNotStructure", "%1$sの%2$s番目の引数は%3$sでなければなりません。"); // Wsn.5
	auto expressionErrorMinimumValue = Msg("expressionErrorMinimumValue", "%1$sの%2$s番目の引数は%3$s以上でなければなりません: %4$s < %3$s");
	auto expressionErrorNoArgumentWithFunctionName = Msg("expressionErrorNoArgumentWithFunctionName", "%1$sの引数がありません。");
	auto expressionErrorConversionToNumber = Msg("expressionErrorConversionToNumber", "数値に変換できません: %1$s");
	auto expressionErrorVariantNotFound = Msg("expressionErrorVariantNotFound", "コモン「%1$s」は存在しません。");
	auto expressionErrorFlagNotFound = Msg("expressionErrorFlagNotFound", "フラグ「%1$s」は存在しません。");
	auto expressionErrorStepNotFound = Msg("expressionErrorStepNotFound", "ステップ「%1$s」は存在しません。");
	auto expressionErrorInvalidStepValue = Msg("expressionErrorInvalidStepValue", "ステップ「%1$s」の最大値より大きな値です: %2$s");
	auto expressionErrorListIndexIsOutOfRange = Msg("expressionErrorListIndexIsOutOfRange", "リストに%1$s番目の要素は存在しません: リストの長さ = %2$s"); // Wsn.5
	auto expressionErrorCompareDifferentStructures = Msg("expressionErrorCompareDifferentStructures", "異なる種類の構造体を比較しようとしました: %1$s <> %2$s"); // Wsn.5
	auto expressionErrorTokenIsNotStructureMemberName = Msg("expressionErrorTokenIsNotStructureMemberName", "構造体のメンバ名が正しくありません: %1$s"); // Wsn.5
	auto expressionErrorSymbolIsNotStructureMemberNameOne = Msg("expressionErrorSymbolIsNotStructureMemberNameOne", "%1$sのメンバ名が正しくありません。%2$sのみ参照可能です。"); // Wsn.5
	auto expressionErrorSymbolIsNotStructureMemberName = Msg("expressionErrorSymbolIsNotStructureMemberName", "%1$sのメンバ名が正しくありません。%2$sのいずれかである必要があります。"); // Wsn.5
	auto expressionErrorStructureHasNotPublicMember = Msg("expressionErrorStructureHasNotPublicMember", "%1$sには参照可能なメンバがありません。"); // Wsn.5
	auto warningExpression = Msg("warningExpression", "%1$s → %2$s");
	auto warningExpressionPosition = Msg("warningExpressionPosition", " >>>");
	auto warningExpressionEnd = Msg("warningExpressionEnd", " <<<");
	auto warningExpressionNeedBooleanReturnType = Msg("warningExpressionNeedBooleanReturnType", "式の結果は%1$sですが、%2$sコンテントでは真偽値でなければなりません。");
	auto warningExpressionToFlag = Msg("warningExpressionToFlag", "式の結果は%1$sになるため、フラグへ代入できません。");
	auto warningExpressionToStep = Msg("warningExpressionToStep", "式の結果は%1$sになるため、ステップへ代入できません。");

	auto functionNameWithDescription = Msg("functionNameWithDescription", "%1$s - %2$s");

	auto argNumber = Msg("argNumber", "数値");
	auto argString = Msg("argString", "文字列");
	auto argFlag = Msg("argFlag", "フラグ名");
	auto argStep = Msg("argStep", "ステップ名");
	auto argVariant = Msg("argVariant", "コモン名");
	auto argBoolean = Msg("argBoolean", "真偽値");
	auto argList = Msg("argList", "リスト"); // Wsn.5
	auto argCardInfo = Msg("argCardInfo", "カード情報"); // Wsn.5
	auto argAny = Msg("argAny", "任意の値");
	auto argNumberOrString = Msg("argNumberOrString", "文字列または数値");
	auto functionAs = Msg("functionAs", "%1$s → %2$s");

	auto funcDescLen = Msg("funcDescLen", "文字列の長さ(文字数)を返します。");
	auto funcDescFind = Msg("funcDescFind", "対象文字列内に検索文字列があった場合は位置(1～)を返します。見つからなかった場合は0を返します。");
	auto funcDescLeft = Msg("funcDescLeft", "文字列の左側を返します。");
	auto funcDescRight = Msg("funcDescRight", "文字列の右側を返します。");
	auto funcDescMid = Msg("funcDescMid", "文字列の中間部分を返します。長さを省略した場合は、指定位置より右側を返します。");
	auto funcDescStr = Msg("funcDescStr", "任意の値を文字列に変換します。");
	auto funcDescValue = Msg("funcDescValue", "任意の値を数値に変換します。");
	auto funcDescInt = Msg("funcDescInt", "任意の値を整数に変換します。小数点以下の値は切り捨てられます。");
	auto funcDescIf = Msg("funcDescIf", "真偽値がTRUEであれば2つめの引数を、FALSEであれば3つめの引数を返します。");
	auto funcDescDice = Msg("funcDescDice", "任意面数のダイスを振って結果の値を返します。");
	auto funcDescMax = Msg("funcDescMax", "引数の中で最大の数値を返します。");
	auto funcDescMin = Msg("funcDescMin", "引数の中で最小の数値を返します。");
	auto funcDescVar = Msg("funcDescVar", "コモンの値を返します。@\"コモン名\"と書く事もできます。");
	auto funcDescFlagValue = Msg("funcDescFlagValue", "フラグの値(真偽値)を返します。");
	auto funcDescFlagText = Msg("funcDescFlagText", "フラグの値のテキストを返します。2つめの引数を省略した場合は、フラグの現在値のテキストを返します。");
	auto funcDescStepValue = Msg("funcDescStepValue", "ステップの値(数値)を返します。");
	auto funcDescStepText = Msg("funcDescStepText", "ステップの値のテキストを返します。2つめの引数を省略した場合は、ステップの現在値のテキストを返します。");
	auto funcDescStepMax = Msg("funcDescStepMax", "ステップの最大値を返します。");
	auto funcDescSelected = Msg("funcDescSelected", "選択メンバの番号を1以上の数値で返します。選択メンバがいない場合は0を返します。");
	auto funcDescCastType = Msg("funcDescCastType", "キャラクターのタイプを返します(1=プレイヤー, 2=エネミー, 3=同行キャスト)。該当者がいない場合は0を返します。");
	auto funcDescCastName = Msg("funcDescCastName", "キャラクターの名前を返します。該当者がいない場合は空文字列を返します。");
	auto funcDescFindCoupon = Msg("funcDescFindCoupon", "キャラクターの所持するクーポンを検索し、クーポン番号を返します。見つからなかった場合は0を返します。次の特殊文字が使用できます。\n* = 任意文字列, ? = 任意1文字, [ABC] = A・B・Cのいずれか1文字, [!ABC] = A・B・Cのいずれでもない1文字。\n特殊文字を普通の文字のように検索したい時は[[]のように[]で囲います。");
	auto funcDescCouponText = Msg("funcDescCouponText", "キャラクターの所持するクーポンの名前を返します。見つからなかった場合は空文字列を返します。");
	auto funcDescFindGossip = Msg("funcDescFindGossip", "ゴシップを検索し、ゴシップ番号を返します。見つからなかった場合は0を返します。次の特殊文字が使用できます。\n* = 任意文字列, ? = 任意1文字, [ABC] = A・B・Cのいずれか1文字, [!ABC] = A・B・Cのいずれでもない1文字。\n特殊文字を普通の文字のように検索したい時は[[]のように[]で囲います。");
	auto funcDescGossipText = Msg("funcDescGossipText", "ゴシップの名前を返します。見つからなかった場合は空文字列を返します。");
	auto funcDescPartyName = Msg("funcDescPartyName", "操作中のパーティの名前を返します。");
	auto funcDescList = Msg("funcDescList", "リストを生成します。"); // Wsn.5
	auto funcDescAt = Msg("funcDescAt", "リストの要素を返します。"); // Wsn.5
	auto funcDescLLen = Msg("funcDescLLen", "リストの長さ(要素数)を返します。"); // Wsn.5
	auto funcDescLFind = Msg("funcDescLFind", "対象リスト内に検索値があった場合は位置(1～)を返します。見つからなかった場合は0を返します。"); // Wsn.5
	auto funcDescLLeft = Msg("funcDescLLeft", "リストの左側を返します。"); // Wsn.5
	auto funcDescLRight = Msg("funcDescLRight", "リストの右側を返します。"); // Wsn.5
	auto funcDescLMid = Msg("funcDescLMid", "リストの中間部分を返します。長さを省略した場合は、指定位置より右側を返します。"); // Wsn.5
	auto funcDescPartyMoney = Msg("funcDescPartyMoney", "操作中のパーティの所持金を返します。"); // Wsn.5
	auto funcDescPartyNumber = Msg("funcDescPartyNumber", "操作中のパーティの人数を返します。"); // Wsn.5
	auto funcDescYadoName = Msg("funcDescYadoName", "操作中の拠点名を返します。"); // Wsn.5
	auto funcDescSkinType = Msg("funcDescSkinType", "操作中のスキンタイプの名称を返します。戻り値は以下の通りです。\n\n中世ファンタジーⅠ型→\"MedievalFantasy\"\n現代Ⅰ型→\"Modern\"\n現代学園ものバリアントエンジン→\"School\"\nカアドワアス大江戸バリアント→\"Oedo\"\nＳＦバリアント→\"ScienceFiction\"\n妖魔バリアント→\"Monsters\""); // Wsn.5
	auto funcDescBattleRound = Msg("funcDescBattleRound", "現在のバトルのラウンド数を返します。バトル中ではない場合は-1を返します。"); // Wsn.5
	auto funcDescCastLevel = Msg("funcDescCastLevel", "キャラクターのレベルを返します。該当者がいない場合は0を返します。"); // Wsn.5
	auto funcDescCouponValue = Msg("funcDescCouponValue", "キャラクターの所持するクーポン名の点数を返します。該当者またはクーポンが見つからなかった場合は0を返します。"); // Wsn.5
	auto funcDescLifeRatio = Msg("funcDescLifeRatio", "キャラクターのライフ残量を0.0～1.0の割合で返します。該当者がいない場合は-1を返します。"); // Wsn.5
	auto funcDescStatusValue = Msg("funcDescStatusValue", "キャラクターの状態の強度・修正値を返します。該当者がいない・指定した状態ではない場合は0を返します。強度・修正値を持たない状態にある場合は1を返します。二番目の引数に与える数値は以下の通りです。\n\n中毒→8\n睡眠→9\n呪縛→10\n麻痺・石化→11\n混乱→12\n激昂→13\n勇敢→14\n恐慌→15\n沈黙→16\n暴露→17\n魔法無効化→18\n行動力上昇→19\n回避力上昇→20\n抵抗力上昇→21\n防御力上昇→22\n行動力低下→23\n回避力低下→24\n抵抗力低下→25\n防御力低下→26"); // Wsn.5
	auto funcDescStatusRound = Msg("funcDescStatusRound", "キャラクターの状態の残りラウンド数を返します。該当者がいない・指定した状態ではない場合は0を返します。二番目の引数に与える数値は以下の通りです。\n\n中毒→8\n睡眠→9\n呪縛→10\n麻痺・石化→11\n混乱→12\n激昂→13\n勇敢→14\n恐慌→15\n沈黙→16\n暴露→17\n魔法無効化→18\n行動力上昇→19\n回避力上昇→20\n抵抗力上昇→21\n防御力上昇→22\n行動力低下→23\n回避力低下→24\n抵抗力低下→25\n防御力低下→26"); // Wsn.5
	auto funcDescSelectedCard = Msg("funcDescSelectedCard", "選択カードのカード情報を返します。選択カードが存在しない場合は無効なカード情報を返します。"); // Wsn.5
	auto funcDescCardName = Msg("funcDescCardName", "カード名を返します。カード情報が無効な場合は空文字列を返します。"); // Wsn.5
	auto funcDescCardType = Msg("funcDescCardType", "カードのタイプを返します(1=特殊技能, 2=アイテム, 3=召喚獣)。カード情報が無効な場合は0を返します。"); // Wsn.5
	auto funcDescCardRarity = Msg("funcDescCardRarity", "カードの希少度を返します(1=一般, 2=レア, 3=プレミア)。カード情報が無効な場合は0を返します。"); // Wsn.5
	auto funcDescCardPrice = Msg("funcDescCardPrice", "カードの価格を返します。カード情報が無効な場合は-1を返します。"); // Wsn.5
	auto funcDescCardLevel = Msg("funcDescCardLevel", "特殊技能カードのレベルを返します。カード情報が無効か、特殊技能カードでない場合は-1を返します。"); // Wsn.5
	auto funcDescCardCount = Msg("funcDescCardCount", "カードの残り使用回数を返します。カード情報が無効な場合は-1を返します。\n使用回数0のアイテムカードと召喚獣は無限に使用できるカードとなりますが、リサイクルカードの場合は例外として使用できない状態になります。"); // Wsn.5

	auto funcShortDescLen = Msg("funcShortDescLen", "文字列の長さを返す");
	auto funcShortDescFind = Msg("funcDescFind", "文字列内を検索");
	auto funcShortDescLeft = Msg("funcShortDescLeft", "文字列の左側を返す");
	auto funcShortDescRight = Msg("funcShortDescRight", "文字列の右側を返す");
	auto funcShortDescMid = Msg("funcShortDescMid", "文字列の中間部分を返す");
	auto funcShortDescStr = Msg("funcShortDescStr", "文字列へ変換");
	auto funcShortDescValue = Msg("funcShortDescValue", "数値へ変換");
	auto funcShortDescInt = Msg("funcShortDescInt", "整数へ変換");
	auto funcShortDescIf = Msg("funcShortDescIf", "真偽値でどちらかの値を返す");
	auto funcShortDescDice = Msg("funcShortDescDice", "ダイスを振る");
	auto funcShortDescMax = Msg("funcShortDescMax", "最大値を返す");
	auto funcShortDescMin = Msg("funcShortDescMin", "最小値を返す");
	auto funcShortDescVar = Msg("funcShortDescVar", "コモンの値を返す");
	auto funcShortDescFlagValue = Msg("funcShortDescFlagValue", "フラグの値を返す");
	auto funcShortDescFlagText = Msg("funcShortDescFlagText", "フラグのテキストを返す");
	auto funcShortDescStepValue = Msg("funcShortDescStepValue", "ステップの値を返す");
	auto funcShortDescStepText = Msg("funcShortDescStepText", "ステップのテキストを返す");
	auto funcShortDescStepMax = Msg("funcShortDescStepMax", "ステップの最大値を返す");
	auto funcShortDescSelected = Msg("funcShortDescSelected", "選択メンバを返す");
	auto funcShortDescCastType = Msg("funcShortDescCastType", "キャラクターのタイプを返す");
	auto funcShortDescCastName = Msg("funcShortDescCastName", "キャラクターの名前を返す");
	auto funcShortDescFindCoupon = Msg("funcShortDescFindCoupon", "クーポンを検索");
	auto funcShortDescCouponText = Msg("funcShortDescCouponText", "クーポン名を取得");
	auto funcShortDescFindGossip = Msg("funcShortDescFindGossip", "ゴシップを検索");
	auto funcShortDescGossipText = Msg("funcShortDescGossipText", "ゴシップ名を取得");
	auto funcShortDescPartyName = Msg("funcShortDescPartyName", "パーティ名を取得");
	auto funcShortDescList = Msg("funcShortDescList", "リストを生成する"); // Wsn.5
	auto funcShortDescAt = Msg("funcShortDescAt", "リストの要素を返す"); // Wsn.5
	auto funcShortDescLLen = Msg("funcShortDescLLen", "リストの長さを返す"); // Wsn.5
	auto funcShortDescLFind = Msg("funcDescLFind", "リスト内を検索"); // Wsn.5
	auto funcShortDescLLeft = Msg("funcShortDescLLeft", "リストの左側を返す"); // Wsn.5
	auto funcShortDescLRight = Msg("funcShortDescLRight", "リストの右側を返す"); // Wsn.5
	auto funcShortDescLMid = Msg("funcShortDescLMid", "リストの中間部分を返す"); // Wsn.5
	auto funcShortDescPartyMoney = Msg("funcShortDescPartyMoney", "パーティの所持金を取得"); // Wsn.5
	auto funcShortDescPartyNumber = Msg("funcShortDescPartyNumber", "パーティの人数を取得"); // Wsn.5
	auto funcShortDescYadoName = Msg("funcShortDescYadoName", "拠点名を取得"); // Wsn.5
	auto funcShortDescSkinType = Msg("funcShortDescSkinType", "スキンタイプを取得"); // Wsn.5
	auto funcShortDescBattleRound = Msg("funcShortDescBattleRound", "バトルラウンドを取得"); // Wsn.5
	auto funcShortDescCastLevel = Msg("funcShortDescCastLevel", "キャラクターのレベルを返す"); // Wsn.5
	auto funcShortDescCouponValue = Msg("funcShortDescCouponValue", "クーポンの点数を返す"); // Wsn.5
	auto funcShortDescLifeRatio = Msg("funcShortDescLifeRatio", "キャラクターのライフ残量を返す"); // Wsn.5
	auto funcShortDescStatusValue = Msg("funcShortDescStatusValue", "キャラクターの状態の強度・修正値を返す"); // Wsn.5
	auto funcShortDescStatusRound = Msg("funcShortDescStatusRound", "キャラクターの状態の残ラウンド数を返す"); // Wsn.5
	auto funcShortDescSelectedCard = Msg("funcShortDescSelectedCard", "選択カードを返す。"); // Wsn.5
	auto funcShortDescCardName = Msg("funcShortDescCardName", "カード名を返す。"); // Wsn.5
	auto funcShortDescCardType = Msg("funcShortDescCardType", "カードのタイプを返す。"); // Wsn.5
	auto funcShortDescCardRarity = Msg("funcShortDescCardRarity", "カードの希少度を返す。"); // Wsn.5
	auto funcShortDescCardPrice = Msg("funcShortDescCardPrice", "カードの価格を返す。"); // Wsn.5
	auto funcShortDescCardLevel = Msg("funcShortDescCardLevel", "カードのレベルを返す。"); // Wsn.5
	auto funcShortDescCardCount = Msg("funcShortDescCardCount", "カードの使用回数を返す。"); // Wsn.5

	auto funcExampleLen = Msg("funcExampleLen", "LEN(\"対象文字列\") = 5");
	auto funcExampleFind = Msg("funcExampleFind", "FIND(\"文字\", \"対象文字列\") = 3");
	auto funcExampleLeft = Msg("funcExampleLeft", "LEFT(\"対象文字列\", 2) = \"対象\"");
	auto funcExampleRight = Msg("funcExampleRight", "RIGHT(\"対象文字列\", 3) = \"文字列\"");
	auto funcExampleMid = Msg("funcExampleMid", "MID(\"対象文字列\", 3, 2) = \"文字\"");
	auto funcExampleStr = Msg("funcExampleStr", "STR(999.9) = \"999.9\"");
	auto funcExampleValue = Msg("funcExampleValue", "VALUE(\"999.9\") = 999.9");
	auto funcExampleInt = Msg("funcExampleInt", "INT(\"999.9\") = 999");
	auto funcExampleIf = Msg("funcExampleIf", "IF(42 = 99, \"真\", \"偽\") = \"偽\"");
	auto funcExampleDice = Msg("funcExampleDice", "DICE(2, 6) = 12");
	auto funcExampleMax = Msg("funcExampleMax", "MAX(1, 23, 4, 5) = 23");
	auto funcExampleMin = Msg("funcExampleMin", "MIN(12, 3, 4, 5) = 3");
	auto funcExampleVar = Msg("funcExampleVar", "VAR(\"コモンA\") = \"コモンAの値\"");
	auto funcExampleFlagValue = Msg("funcExampleFlagValue", "FLAGVALUE(\"フラグA\") = TRUE");
	auto funcExampleFlagText = Msg("funcExampleFlagText", "FLAGTEXT(\"フラグA\", TRUE) = \"真\"");
	auto funcExampleStepValue = Msg("funcExampleStepValue", "STEPVALUE(\"ステップA\") = 5");
	auto funcExampleStepText = Msg("funcExampleStepText", "STEPTEXT(\"ステップA\", 5) = \"Step - 5\"");
	auto funcExampleStepMax = Msg("funcExampleStepMax", "STEPMAX(\"ステップA\") = 9");
	auto funcExampleSelected = Msg("funcExampleSelected", "SELECTED() <> 0");
	auto funcExampleCastType = Msg("funcExampleCastType", "CASTTYPE(SELECTED()) = 1");
	auto funcExampleCastName = Msg("funcExampleCastName", "CASTNAME(SELECTED()) = \"コボルト\"");
	auto funcExampleFindCoupon = Msg("funcExampleFindCoupon", "FINDCOUPON(SELECTED(), \"*退治\") <> 0");
	auto funcExampleCouponText = Msg("funcExampleCouponText", "COUPONTEXT(SELECTED(), FINDCOUPON(SELECTED(), \"*退治\")) = \"ゴブリン退治\"");
	auto funcExampleFindGossip = Msg("funcExampleFindGossip", "FINDGOSSIP(\"*生存\") <> 0");
	auto funcExampleGossipText = Msg("funcExampleGossipText", "GOSSIPTEXT(FINDGOSSIP(\"*生存\")) = \"ゴブリン生存\"");
	auto funcExamplePartyName = Msg("funcExamplePartyName", "PARTYNAME()");
	auto funcExampleList = Msg("funcExampleList", "LIST(42, \"STR\", TRUE)"); // Wsn.5
	auto funcExampleAt = Msg("funcExampleAt", "AT(LIST(41, 42, 43), 2) = 42"); // Wsn.5
	auto funcExampleLLen = Msg("funcExampleLLen", "LLEN(LIST(1, 2, 3, 5)) = 4"); // Wsn.5
	auto funcExampleLFind = Msg("funcExampleLFind", "LFIND(42, LIST(41, 42, 43)) = 2"); // Wsn.5
	auto funcExampleLLeft = Msg("funcExampleLLeft", "LEFT(LIST(1, 2, 3), 2) = LIST(1, 2)"); // Wsn.5
	auto funcExampleLRight = Msg("funcExampleLRight", "RIGHT(LIST(1, 2, 3), 2) = LIST(2, 3)"); // Wsn.5
	auto funcExampleLMid = Msg("funcExampleLMid", "MID(LIST(1, 2, 3, 4, 5), 2, 3) = LIST(2, 3, 4)"); // Wsn.5
	auto funcExamplePartyMoney = Msg("funcExamplePartyMoney", "PARTYMONEY() < 4000"); // Wsn.5
	auto funcExamplePartyNumber = Msg("funcExamplePartyNumber", "PARTYNUMBER() = 1"); // Wsn.5
	auto funcExampleYadoName = Msg("funcExampleYadoName", "YADONAME()"); // Wsn.5
	auto funcExampleSkinType = Msg("funcExampleSkinType", "SKINTYPE() = \"MedievalFantasy\""); // Wsn.5
	auto funcExampleBattleRound = Msg("funcExampleBattleRound", "BATTLEROUND() = 1"); // Wsn.5
	auto funcExampleCastLevel = Msg("funcExampleCastLevel", "CASTLEVEL(SELECTED()) = 1"); // Wsn.5
	auto funcExampleCouponValue = Msg("funcExampleCouponValue", "COUPONVALUE(SELECTED(), \"ゴブリン退治\")"); // Wsn.5
	auto funcExampleLifeRatio = Msg("funcExampleLifeRatio", "LIFERATIO(SELECTED()) < 0.5"); // Wsn.5
	auto funcExampleStatusValue = Msg("funcExampleStatusValue", "STATUSVALUE(SELECTED(), 8) > 20"); // Wsn.5
	auto funcExampleStatusRound = Msg("funcExampleStatusRound", "STATUSROUND(SELECTED(), 9) > 10"); // Wsn.5
	auto funcExampleSelectedCard = Msg("funcExampleSelectedCard", "SELECTEDCARD()"); // Wsn.5
	auto funcExampleCardName = Msg("funcExampleCardName", "CARDNAME(SELECTEDCARD()) = \"居合斬り\""); // Wsn.5
	auto funcExampleCardType = Msg("funcExampleCardType", "CARDTYPE(SELECTEDCARD()) = 1"); // Wsn.5
	auto funcExampleCardRarity = Msg("funcExampleCardRarity", "CARDRARITY(SELECTEDCARD()) = 2"); // Wsn.5
	auto funcExampleCardPrice = Msg("funcExampleCardPrice", "CARDPRICE(SELECTEDCARD()) < 2200"); // Wsn.5
	auto funcExampleCardLevel = Msg("funcExampleCardLevel", "CARDLEVEL(SELECTEDCARD()) < 3"); // Wsn.5
	auto funcExampleCardCount = Msg("funcExampleCardCount", "CARDCOUNT(SELECTEDCARD()) = 0"); // Wsn.5

	auto exprStringDesc = Msg("exprStringDesc", "文字列");
	auto exprFindStringDesc = Msg("exprFindStringDesc", "検索文字列");
	auto exprTargetStringDesc = Msg("exprTargetStringDesc", "対象文字列");
	auto exprStringLengthDesc = Msg("exprStringLengthDesc", "長さ(文字数)");
	auto exprStringPositionDesc = Msg("exprStringPositionDesc", "位置(1～)");
	auto exprAnyValueDesc = Msg("exprAnyValueDesc", "任意の値");
	auto exprValueArgDesc = Msg("exprValueArgDesc", "文字列または数値");
	auto exprBooleanDesc = Msg("exprBooleanDesc", "真偽値");
	auto exprIfTrueDesc = Msg("exprIfTrueDesc", "TRUEの結果");
	auto exprIfFalseDesc = Msg("exprIfFalseDesc", "FALSEの結果");
	auto exprDiceTimesDesc = Msg("exprDiceTimesDesc", "個数");
	auto exprDiceSidesDesc = Msg("exprDiceSidesDesc", "面数");
	auto exprVariableLengthNumberDesc = Msg("exprVariableLengthNumberDesc", "数値 %1$s");
	auto exprVariantDesc = Msg("exprVariantDesc", "コモン名");
	auto exprFlagDesc = Msg("exprFlagDesc", "フラグ名");
	auto exprFlagValueDesc = Msg("exprFlagValueDesc", "フラグ値");
	auto exprStepDesc = Msg("exprStepDesc", "ステップ名");
	auto exprStepValueDesc = Msg("exprStepValueDesc", "ステップ値");
	auto exprCastNumberDesc = Msg("exprCastNumberDesc", "キャラクター番号");
	auto exprFindPatternDesc = Msg("exprFindPatternDesc", "検索文字列");
	auto exprCouponNameDesc = Msg("exprCouponNameDesc", "クーポン名");
	auto exprCouponNumberDesc = Msg("exprCouponNumberDesc", "クーポン番号");
	auto exprGossipNumberDesc = Msg("exprGossipNumberDesc", "ゴシップ番号");
	auto exprFindStartPositionDesc = Msg("exprFindStartPositionDesc", "検索開始位置");
	auto exprListDesc = Msg("exprListDesc", "リスト"); // Wsn.5
	auto exprAnyFindValueDesc = Msg("exprAnyFindValueDesc", "検索値"); // Wsn.5
	auto exprListLengthDesc = Msg("exprListLengthDesc", "長さ(要素数)"); // Wsn.5
	auto exprListPositionDesc = Msg("exprListPositionDesc", "位置(1～)"); // Wsn.5
	auto exprCardInfoDesc = Msg("exprCardInfoDesc", "カード情報"); // Wsn.5
	auto exprCastStatusDesc = Msg("exprCastStatusDesc", "状態の番号"); // Wsn.5

	/// メニュー。
	const string menuText(MenuID id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(typeof(id), "menuText"));
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
	auto menuTextCreateSubWindow = Msg("menuTextCreateSubWindow", "新しいウィンドウで開く");
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
	auto menuTextEditScenarioHistory = Msg("menuTextEditScenarioHistory", "履歴とブックマークの編集");
	auto menuTextEditImportHistory = Msg("menuTextEditImportHistory", "履歴とブックマークの編集");
	auto menuTextEditExecutedPartyHistory = Msg("menuTextEditExecutedPartyHistory", "履歴とブックマークの編集");
	auto menuTextPutParty = Msg("menuTextPutParty", "パーティを選択して追加");
	auto menuTextOpenDir = Msg("menuTextOpenDir", "シナリオの" ~ DIR ~ "を開く");
	auto menuTextOpenBackupDir = Msg("menuTextOpenBackupDir", "バックアップ" ~ DIR ~ "を開く");
	auto menuTextOpenPlace = Msg("menuTextOpenPlace", "ファイルの場所を開く");
	auto menuTextSaveImage = Msg("menuTextSaveImage", "格納イメージをファイルに保存");
	auto menuTextIncludeImage = Msg("menuTextIncludeImage", "イメージを格納する");
	auto menuTextLookImages = Msg("menuTextLookImages", "画像を一覧表示");
	auto menuTextEditLayers = Msg("menuTextEditLayers", "レイヤの編集");
	auto menuTextAddLayer = Msg("menuTextAddLayer", "レイヤの追加");
	auto menuTextRemoveLayer = Msg("menuTextRemoveLayer", "レイヤの削除");
	auto menuTextChangeVH = Msg("menuTextChangeVH", "分割領域の縦横を切替");
	auto menuTextSelectConnectedResource = Msg("menuTextSelectConnectedResource", "関係するリソースを選択");
	auto menuTextFind = Msg("menuTextFind", "検索と置換");
	auto menuTextFindID = Msg("menuTextFindID", "参照を検索");
	auto menuTextIncSearch = Msg("menuTextIncSearch", "絞り込み検索");
	auto menuTextCloseIncSearch = Msg("menuTextCloseIncSearch", "閉じる");
	auto menuTextEditProp = Msg("menuTextEditProp", "編集");
	auto menuTextShowProp = Msg("menuTextShowProp", "詳細");
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
	auto menuTextSelectAll = Msg("menuTextSelectAll", "全て選択");
	auto menuTextCopyAll = Msg("menuTextCopyAll", "全てコピー");
	auto menuTextToXMLText = Msg("menuTextToXMLText", "コピーしたデータをXMLに変換");
	auto menuTextAddItem = Msg("menuTextAddItem", "追加");
	auto menuTextDelItem = Msg("menuTextDelItem", "削除");
	auto menuTextTableView = Msg("menuTextTableView", "テーブルビュー");
	auto menuTextVarView = Msg("menuTextVarView", "状態変数ビュー");
	auto menuTextCardView = Msg("menuTextCardView", "カードビュー");
	auto menuTextCastView = Msg("menuTextCastView", "キャストカードビュー");
	auto menuTextSkillView = Msg("menuTextSkillView", "特殊技能カードビュー");
	auto menuTextItemView = Msg("menuTextItemView", "アイテムカードビュー");
	auto menuTextBeastView = Msg("menuTextBeastView", "召喚獣カードビュー");
	auto menuTextInfoView = Msg("menuTextInfoView", "情報カードビュー");
	auto menuTextFileView = Msg("menuTextFileView", "ファイルビュー");
	auto menuTextCouponView = Msg("menuTextCouponView", "クーポンビュー");
	auto menuTextGossipView = Msg("menuTextGossipView", "ゴシップビュー");
	auto menuTextCompleteStampView = Msg("menuTextCompleteStampView", "終了印ビュー");
	auto menuTextKeyCodeView = Msg("menuTextKeyCodeView", "キーコードビュー");
	auto menuTextCellNameView = Msg("menuTextCellNameView", "セル名称ビュー");
	auto menuTextCardGroupView = Msg("menuTextCardGroupView", "カードグループビュー");
	auto menuTextExecEngine = Msg("menuTextExecEngine", "エンジン起動");
	auto menuTextExecEngineAuto = Msg("menuTextExecEngineAuto", "自動選択");
	auto menuTextExecEngineMain = Msg("menuTextExecEngineMain", "CardWirthPy");
	auto menuTextExecEngineWithParty = Msg("menuTextExecEngineWithParty", "シナリオを開始");
	auto menuTextExecEngineWithLastParty = Msg("menuTextExecEngineWithLastParty", "前回のパーティで開始");
	auto menuTextDeleteNotExistsParties = Msg("menuTextDeleteNotExistsParties", "存在しないパーティを履歴から削除");
	auto menuTextOuterTools = Msg("menuTextOuterTools", "外部ツール");
	auto menuTextSettings = Msg("menuTextSettings", "エディタ設定");
	auto menuTextVersionInfo = Msg("menuTextVersionInfo", "バージョン情報");
	auto menuTextLockToolBar = Msg("menuTextLockToolBar", "ツールバーを固定");
	auto menuTextResetToolBar = Msg("menuTextResetToolBar", "配置をリセット");
	auto menuTextCopyAsText = Msg("menuTextCopyAsText", "テキストとしてコピー");
	auto menuTextOpenAtView = Msg("menuTextOpenAtView", "ビューで開く");
	auto menuTextEventToPackage = Msg("menuTextEventToPackage", "このイベントをパッケージ化する");
	auto menuTextStartToPackage = Msg("menuTextStartToPackage", "このツリーをパッケージ化する");
	auto menuTextWrapTree = Msg("menuTextWrapTree", "ここから別のツリーにする");
	auto menuTextCreateContent = Msg("menuTextCreateContent", "コンテントの作成");
	auto menuTextConvertContent = Msg("menuTextConvertContent", "変換");
	auto menuTextCGroupTerminal = Msg("menuTextCGroupTerminal", "開始/終端");
	auto menuTextCGroupStandard = Msg("menuTextCGroupStandard", "基本");
	auto menuTextCGroupData = Msg("menuTextCGroupData", "変数操作/分岐");
	auto menuTextCGroupUtility = Msg("menuTextCGroupUtility", "状況分岐");
	auto menuTextCGroupBranch = Msg("menuTextCGroupBranch", "保有分岐");
	auto menuTextCGroupGet = Msg("menuTextCGroupGet", "取得");
	auto menuTextCGroupLost = Msg("menuTextCGroupLost", "喪失");
	auto menuTextCGroupVisual = Msg("menuTextCGroupVisual", "外観操作");
	auto menuTextCGroupVariant = Msg("menuTextCGroupVariant", "演算");
	auto menuTextEditSummary = Msg("menuTextEditSummary", "シナリオの設定");
	auto menuTextNewAreaDir = Msg("menuTextNewAreaDir", "フォルダの作成");
	auto menuTextNewArea = Msg("menuTextNewArea", "エリアの作成");
	auto menuTextNewBattle = Msg("menuTextNewBattle", "バトルの作成");
	auto menuTextNewPackage = Msg("menuTextNewPackage", "パッケージの作成");
	auto menuTextReNumberingAll = Msg("menuTextReNumberingAll", "全てのIDを1から振り直す");
	auto menuTextReNumbering = Msg("menuTextReNumbering", "IDの振り直し");
	auto menuTextEditScene = Msg("menuTextEditScene", "シーンビューを開く");
	auto menuTextEditSceneDup = Msg("menuTextEditSceneDup", "新しいシーンビューを開く");
	auto menuTextEditEvent = Msg("menuTextEditEvent", "イベントビューを開く");
	auto menuTextEditEventDup = Msg("menuTextEditEventDup", "新しいイベントビューを開く");
	auto menuTextSetStartArea = Msg("menuTextSetStartArea", "開始エリアにする");
	auto menuTextNewFlagDir = Msg("menuTextNewFlagDir", "フォルダの作成");
	auto menuTextNewFlag = Msg("menuTextNewFlag", "フラグの作成");
	auto menuTextNewStep = Msg("menuTextNewStep", "ステップの作成");
	auto menuTextNewVariant = Msg("menuTextNewVariant", "コモンの作成");
	auto menuTextCreateStepValues = Msg("menuTextCreateStepValues", "ステップ値の自動生成");
	auto menuTextPutSPChar = Msg("menuTextPutSPChar", "特殊文字の挿入");
	auto menuTextPutFlagValue = Msg("menuTextPutFlagValue", "フラグ値");
	auto menuTextPutStepValue = Msg("menuTextPutStepValue", "ステップ値");
	auto menuTextPutVariantValue = Msg("menuTextPutVariantValue", "コモン値");
	auto menuTextPutColor = Msg("menuTextPutColor", "文字色");
	auto menuTextPutSkinSPChar = Msg("menuTextPutSkinSPChar", "記号");
	auto menuTextPutImageFont = Msg("menuTextPutImageFont", "画像参照");
	auto menuTextCreateVariableEventTree = Msg("menuTextCreateVariableEventTree", "イベントツリーとしてコピー");
	auto menuTextInitVariablesTree = Msg("menuTextInitVariablesTree", "初期値の設定");
	auto menuTextCopyVariablePath = Msg("menuTextCopyVariablePath", "状態変数のパスをコピー");
	auto menuTextUp = Msg("menuTextUp", "選択中のアイテムを上へ移動");
	auto menuTextDown = Msg("menuTextDown", "選択中のアイテムを下へ移動");
	auto menuTextConvertCouponType = Msg("menuTextConvertCouponType", "クーポンの種類の変更");
	auto menuTextConvertCouponTypeNormal = Msg("menuTextConvertCouponTypeNormal", "ノーマル");
	auto menuTextConvertCouponTypeHide = Msg("menuTextConvertCouponTypeHide", "[＿...] 隠蔽");
	auto menuTextConvertCouponTypeDur = Msg("menuTextConvertCouponTypeDur", "[：...] 時限");
	auto menuTextConvertCouponTypeDurBattle = Msg("menuTextConvertCouponTypeDurBattle", "[；...] 戦闘中時限");
	auto menuTextConvertCouponTypeSystem = Msg("menuTextConvertCouponTypeSystem", "[＠...] システム");
	auto menuTextCopyTypeConvertedCoupon = Msg("menuTextCopyTypeConvertedCoupon", "種類を指定してコピー");
	auto menuTextCopyTypeConvertedCouponNormal = Msg("menuTextCopyTypeConvertedCouponNormal", "ノーマル");
	auto menuTextCopyTypeConvertedCouponHide = Msg("menuTextCopyTypeConvertedCouponHide", "[＿...] 隠蔽");
	auto menuTextCopyTypeConvertedCouponDur = Msg("menuTextCopyTypeConvertedCouponDur", "[：...] 時限");
	auto menuTextCopyTypeConvertedCouponDurBattle = Msg("menuTextCopyTypeConvertedCouponDurBattle", "[；...] 戦闘中時限");
	auto menuTextCopyTypeConvertedCouponSystem = Msg("menuTextCopyTypeConvertedCouponSystem", "[＠...] システム");
	auto menuTextAddInitialCoupons = Msg("menuTextAddInitialCoupons", "種族と年代の初期クーポンを追加");
	auto menuTextReverseSignOfValues = Msg("menuTextReverseSignOfValues", "得点の正負を反転する");
	auto menuTextReverse = Msg("menuTextReverse", "逆順にする");
	auto menuTextSwapToParent = Msg("menuTextSwapToParent", "親コンテントと入れ替える");
	auto menuTextSwapToChild = Msg("menuTextSwapToChild", "子コンテントと入れ替える");
	auto menuTextOverDialog = Msg("menuTextOverDialog", "上のセリフへ移動");
	auto menuTextUnderDialog = Msg("menuTextUnderDialog", "下のセリフへ移動");
	auto menuTextCreateDialog = Msg("menuTextCreateDialog", "セリフの作成");
	auto menuTextDeleteDialog = Msg("menuTextDeleteDialog", "セリフの削除");
	auto menuTextCopyToAllDialogs = Msg("menuTextCopyToAllDialogs", "セリフを全体にコピー");
	auto menuTextCopyToUpperDialogs = Msg("menuTextCopyToUpperDialogs", "セリフを上方にコピー");
	auto menuTextCopyToLowerDialogs = Msg("menuTextCopyToLowerDialogs", "セリフを下方にコピー");
	auto menuTextShowParty = Msg("menuTextShowParty", "パーティカードの表示");
	auto menuTextShowMsg = Msg("menuTextShowMsg", "メッセージ枠の表示");
	auto menuTextShowRefCards = Msg("menuTextShowRefCards", "カード参照の表示");
	auto menuTextFixedCards = Msg("menuTextFixedCards", "カードの固定");
	auto menuTextFixedCells = Msg("menuTextFixedCells", "背景の固定");
	auto menuTextFixedBackground = Msg("menuTextFixedBackground", "最初のフルサイズ背景の固定");
	auto menuTextShowGrid = Msg("menuTextShowGrid", "グリッドの表示");
	auto menuTextShowEnemyCardProp = Msg("menuTextShowEnemyCardProp", "レベルとライフを表示");
	auto menuTextShowCard = Msg("menuTextShowCard", "カードの表示");
	auto menuTextShowBack = Msg("menuTextShowBack", "背景の表示");
	auto menuTextNewMenuCard = Msg("menuTextNewMenuCard", "メニューカードの作成");
	auto menuTextNewEnemyCard = Msg("menuTextNewEnemyCard", "エネミーカードの作成");
	auto menuTextNewBack = Msg("menuTextNewBack", "背景の作成");
	auto menuTextNewTextCell = Msg("menuTextNewTextCell", "テキストセルの作成");
	auto menuTextNewColorCell = Msg("menuTextNewColorCell", "カラーセルの作成");
	auto menuTextNewPCCell = Msg("menuTextNewPCCell", "プレイヤーキャラクタセルの作成");
	auto menuTextAutoArrange = Msg("menuTextAutoArrange", "カードを自動的に並べる");
	auto menuTextManualArrange = Msg("menuTextManualArrange", "カードの位置を自分で決定する");
	auto menuTextPossibleToRunAway = Msg("menuTextPossibleToRunAway", "パーティの逃走を許可");
	auto menuTextSortWithPosition = Msg("menuTextSortWithPosition", "左上から右下の順で整列");
	auto menuTextMask = Msg("menuTextMask", "透明色を使用");
	auto menuTextEscape = Msg("menuTextEscape", "エネミーの逃走の有無");
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
	auto menuTextNearCenterH = Msg("menuTextNearCenterH", "横方向の中央へ寄せる");
	auto menuTextNearCenterV = Msg("menuTextNearCenterV", "縦方向の中央へ寄せる");
	auto menuTextNearCenter = Msg("menuTextNearCenter", "中央へ寄せる");
	auto menuTextScaleMin = Msg("menuTextScaleMin", "最小のカードスケール");
	auto menuTextScaleMiddle = Msg("menuTextScaleMiddle", "標準のカードスケール");
	auto menuTextScaleMax = Msg("menuTextScaleMax", "最大のカードスケール");
	auto menuTextScaleBig = Msg("menuTextScaleBig", "大きく揃える");
	auto menuTextScaleSmall = Msg("menuTextScaleSmall", "小さく揃える");
	auto menuTextExpandBack = Msg("menuTextExpandBack", "背景セルを最大化");
	auto menuTextCopyColor1ToColor2 = Msg("menuTextCopyColor1ToColor2", "基本色を終端色へコピー");
	auto menuTextCopyColor2ToColor1 = Msg("menuTextCopyColor2ToColor1", "終端色を基本色へコピー");
	auto menuTextExchangeColors = Msg("menuTextExchangeColors", "終端色と基本色を交換");
	auto menuTextStopBGM = Msg("menuTextStopBGM", "%1$sの再生を停止");
	auto menuTextPlayBGM = Msg("menuTextPlayBGM", "再生");
	auto menuTextNewEvent = Msg("menuTextNewEvent", "イベントの作成");
	auto menuTextNewEventWithDialog = Msg("menuTextNewEventWithDialog", "イベントの作成");
	auto menuTextKeyCodeTiming = Msg("menuTextKeyCodeTiming", "発火タイミングの変更");
	auto menuTextKeyCodeTimingUse = Msg("menuTextKeyCodeTimingUse", "使用");
	auto menuTextKeyCodeTimingSuccess = Msg("menuTextKeyCodeTimingSuccess", "[...○] 成功");
	auto menuTextKeyCodeTimingFailure = Msg("menuTextKeyCodeTimingFailure", "[...×] 失敗");
	auto menuTextKeyCodeTimingHasNot = Msg("menuTextKeyCodeTimingHasNot", "[！...] 不保有");
	auto menuTextCopyTimingConvertedKeyCode = Msg("menuTextCopyTimingConvertedKeyCode", "発火タイミングを指定してコピー");
	auto menuTextCopyTimingConvertedKeyCodeUse = Msg("menuTextCopyTimingConvertedKeyCodeUse", "使用");
	auto menuTextCopyTimingConvertedKeyCodeSuccess = Msg("menuTextCopyTimingConvertedKeyCodeSuccess", "[...○] 成功");
	auto menuTextCopyTimingConvertedKeyCodeFailure = Msg("menuTextCopyTimingConvertedKeyCodeFailure", "[...×] 失敗");
	auto menuTextCopyTimingConvertedKeyCodeHasNot = Msg("menuTextCopyTimingConvertedKeyCodeHasNot", "[！...] 不保有");
	auto menuTextAddKeyCodesByFeatures = Msg("menuAddKeyCodesByFeatures", "特徴と効果からキーコードを生成");
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
	auto menuTextShowCardProp = Msg("menuTextShowCardProp", "カード表示");
	auto menuTextShowCardImage = Msg("menuTextShowCardImage", "簡略カード表示");
	auto menuTextShowCardDetail = Msg("menuTextShowCardDetail", "詳細表示");
	auto menuTextOpenImportSource = Msg("menuTextOpenImportSource", "外部シナリオから追加");
	auto menuTextSelectImportSource = Msg("menuTextSelectImportSource", "追加元のシナリオを選択");
	auto menuTextNewCast = Msg("menuTextNewCast", "キャストカードの作成");
	auto menuTextNewSkill = Msg("menuTextNewSkill", "特殊技能カードの作成");
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
	auto menuTextCreateArchive = Msg("menuTextCreateArchive", "シナリオを圧縮");
	auto menuTextPutQuick = Msg("menuTextPutQuick", "すぐに配置する");
	auto menuTextPutSelect = Msg("menuTextPutSelect", "配置先を選択する");
	auto menuTextPutContinue = Msg("menuTextPutContinue", "配置先を選択して連続で配置する");
	auto menuTextToScript = Msg("menuTextToScript", "スクリプトに変換してコピー");
	auto menuTextToScript1Content = Msg("menuTextToScript1Content", "1コンテントをスクリプトに変換");
	auto menuTextToScriptAll = Msg("menuTextToScriptAll", "全てをスクリプトに変換してコピー");
	auto menuTextEvTemplates = Msg("menuTextEvTemplates", "イベントテンプレート");
	auto menuTextEvTemplatesOfScenario = Msg("menuTextEvTemplatesOfScenario", "シナリオのテンプレートを編集");
	auto menuTextEditSelection = Msg("menuTextEditSelection", "選択肢の編集");
	auto menuTextExpand = Msg("menuTextExpand", "ツリーを開く");
	auto menuTextCollapse = Msg("menuTextCollapse", "ツリーを閉じる");
	auto menuTextSelectCurrentEvent = Msg("menuTextSelectCurrentEvent", "表示中のイベントを選択");
	auto menuTextResetValues = Msg("menuTextResetValues", "初期値に戻す");
	auto menuTextResetValuesAll = Msg("menuTextResetValuesAll", "全て初期値に戻す");
	auto menuTextCustomizeToolBar = Msg("menuTextCustomizeToolBar", "ツールバーの編集");
	auto menuTextAddTool = Msg("menuTextAddTool", "追加");
	auto menuTextAddToolBar = Msg("menuTextAddToolBar", "バーの追加");
	auto menuTextAddToolGroup = Msg("menuTextAddToolGroup", "グループの追加");
	auto menuTextResetToolBarSettings = Msg("menuTextResetToolBarSettings", "初期設定に戻す");
	auto menuTextDeleteNotExistsHistory = Msg("menuTextDeleteNotExistsHistory", "存在しないシナリオを履歴から削除");
	auto menuTextSelectIcon = Msg("menuTextSelectIcon", "アイコンを選択");
	auto menuTextSelectPresetIcon = Msg("menuTextSelectPresetIcon", "既成のアイコンから選択");
	auto menuTextDeleteIcon = Msg("menuTextDeleteIcon", "アイコンの削除");

	auto execEngineWithLastParty = Msg("execEngineWithLastParty", "前回のパーティで開始\n(%1$s > %2$s > %3$s)");
	auto execEngineWithParty = Msg("execEngineWithParty", "%1$s > %2$s > %3$s");

	auto upSelection = Msg("upSelection", "上へ");
	auto downSelection = Msg("downSelection", "下へ");

	auto setFlagTrue = Msg("setFlagTrue", "TRUEを設定");
	auto setFlagFalse = Msg("setFlagFalse", "FALSEを設定");
	auto setStepValue = Msg("setStepValue", "%1$sを設定");

	auto bgm = Msg("bgm", "BGM");
	auto newIgnition = Msg("newIgnition", "イベント発火条件の作成");
	auto expandTree = Msg("expandTree", "全コンテントツリーを開く");
	auto foldTree = Msg("foldTree", "全コンテントツリーを閉じる");
	auto showEventTreeDetail = Msg("showEventTreeDetail", "イベントコンテントの詳細を表示");
	auto showEventTreeLineNumber = Msg("showEventTreeLineNumber", "行番号を表示");

	auto convertFromNextWarning = Msg("convertFromNextWarning", "@@@NEXT: %1$s");
	auto convertFromNextWarningBackpackOnly = Msg("convertFromNextWarningBackpackOnly", "「荷物袋のみ」の指定");
	auto convertFromNextWarningBackpackOfSelectedMember = Msg("convertFromNextWarningBackpackOfSelectedMember", "「選択メンバのバックパック」の指定");
	auto convertFromNextWarningNoForbid = Msg("convertFromNextWarningNoForbid", "制限コンテント(制限解除)");
	auto convertFromNextWarningForbidSave = Msg("convertFromNextWarningForbidSave", "セーブ・中断の制限");
	auto convertFromNextWarningForbidCamp = Msg("convertFromNextWarningForbidCamp", "キャンプの制限");
	auto convertFromNextWarningWaitMillis = Msg("convertFromNextWarningWaitMillis", "ミリ秒単位の空白時間(%1$sミリ秒)");

	auto sex = AAMsg("sex", "key", "name");
	auto period = AAMsg("period", "key", "name");
	auto nature = AAMsg("nature", "key", "name");
	auto makings = AAMsg("makings", "key", "name");

	/// 各連想配列を初期化する。
	this () { mixin(S_TRACE);
		sex.value = [
			"♂":"♂",
			"♀":"♀",
		];
		period.value = [
			"子供":"子供",
			"若者":"若者",
			"大人":"大人",
			"老人":"老人",
		];
		nature.value = [
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
		makings.value = [
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

	const
	string defaultSelection(string s) { mixin(S_TRACE);
		return .format("[%s]", s);
	}

	mixin XMLFuncs!(typeof(this), "message");
}
