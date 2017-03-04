
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
	private immutable DIR = "ヂ�レクトリ";
}

private alias Prop!string Msg;
private alias AAProp!(string, string) AAMsg;

class Msgs : Properties {
	auto locale = PropAttr!string("locale", "ja-JP");
	auto version_ = PropAttr!ulong("version", APP_VERSION_NUM);

	auto application = Msg("application", "CWXEditor");
	auto localeName = Msg("localeName", "日本�);
	auto dlgTitVersion = Msg("dlgTitVersion", "バ�ジョン惱");
	auto appDesc = Msg("appDesc", "CardWirthPy / CardWirth向けシナリオエヂ�タ");

	auto dlgTitUsage = Msg("dlgTitUsage", "使ざ� - CWXEditor");
	auto usage = Msg("usage", "使ざ�: cwxeditor [-help | -putlangfile <PATH> | -conf <PATH>\n"
		~ "                   | -create <NAME> [<SKIN>] | -createclassic <NAME> [<PATH>]\n"
		~ "                   | -selectfile <PATH> | -noload] <SCENARIO> [<CWXPath ...>]\n"
		~ "オプション:\n"
		~ "  -help         起動オプションの説明を表示して終亁�ます�n"
		~ "  -putlangfile <PATH> ッ�ォルト�言語設定ファイル<PAHT>を�力して終亁�ます�n"
		~ "  -conf <PATH>  挮�されたパスの基本設定ファイルを使用します�n"
		~ "  -create        <NAME> [<SKIN>]  起動後にシナリオを新規作�します�n"
		~ "  -createclassic <NAME> [<PATH>]  起動後�PATH>で挮�されたフォルダに\n"
		~ "                                  クラシヂ�なシナリオを新規作�します�n"
		~ "  -selectfile  <PATH> 挮�されたファイルをファイルビューで選択します�n"
		~ "  -noload       起動後、前回終亙�の編雊�態を復允�ません�n"
		~ "  <SCENARIO>    起動と同時に挮�されたシナリオを開きます�n"
		~ "                (*.wsn/Summary.xml/Summary.wsm/[フォルダ])\n"
		~ "OpenID:\n"
		~ "  -a <ID>       シナリオを開ぁ�後�ID>で挮�したIDのエリアを開きます�n"
		~ "  -b <ID>       シナリオを開ぁ�後�ID>で挮�したIDのバトルを開きます�n"
		~ "  -p <ID>       シナリオを開ぁ�後�ID>で挮�したIDのパッケージを開きます�n"
		~ "CWXPath:\n"
		~ "  <CWXPath>     シナリオを開ぁ�後�CWXPath>で挮�したリソースを開きます�);

	auto dlgTitError = Msg("dlgTitError", "エラー - CWXEditor");
	auto dlgTitWarning = Msg("dlgTitWarning", "警�- CWXEditor");
	auto dlgTitQuestion = Msg("dlgTitQuestion", "確�- CWXEditor");
	auto unknownError = Msg("unknownError", "処�途中でCWXEditorの制作老�意図してぁ�あ�ラーが発生しました�
		~ "�タが壊れてあ�可能性を�して、シナリオを保存せずに終亁�る事をお勧めします�n"
		~ "エラーの冮�は%1$sに記録されます�);
	auto shutdown = Msg("shutdown", "強制終�);

	auto targetVersion = Msg("targetVersion", "対象エンジン");
	auto targetVersionHint = Msg("targetVersion", "※ 警告と誤り検索の結果に影響しま�);
	auto cardWirthPy = Msg("cardWirthPy", "CardWirthPy");
	auto cardWirthWithVersion = Msg("cardWirthWithVersion", "CardWirth %1$s");

	auto dlgTextOK = Msg("dlgTextOK", "&OK");
	auto dlgTextApply = Msg("dlgTextApply", "適用(&A)");
	auto dlgTextCancel = Msg("dlgTextCancel", "キャンセル(&C)");
	auto dlgTextClose = Msg("dlgTextClose", "閉じ�&C)");

	auto apply = Msg("apply", "適用");
	auto del = Msg("del", "削除");

	auto filterAll = Msg("filterAll", "すべてのファイル (*.*)");

	auto fileCopyError = Msg("fileCopyError", "%1$sのコピ�中にエラーが発生しました�);
	auto reloadError = Msg("reloadError", "%1$sの再読込中にエラーが発生しました�);
	auto loadProgress = Msg("loadProgress", "%2$s%% 完�- %1$sを展開中");
	auto loading = Msg("loading", "%1$sの読込みを開�);
	auto loadingWithFile = Msg("loading", "%1$sを読込んでぁ��.. (%2$s)");
	auto loaded = Msg("loaded", "%1$sの読込みを完�);
	auto loadedCount = Msg("loadedCount", "%1$s件の読込みを完�);
	auto reconstructionStatus = Msg("reconstructionStatus", "編雊�態を復典� (%1$s/%2$s)");
	auto cwxPathOpenError = Msg("cwxPathOpenError", "パス [%1$s] を開けません�);
	auto filePathOpenError = Msg("filePathOpenError", "パス [%1$s] を開けません�);

	auto loadSkinError = Msg("loadSkinError", "ッ�ォルト�スキン�1$s」が見つかりません�n" ~ CARD_WIRTH_PY_EXE ~ "本体�場所が正しくなぁ�、Data" ~ DIR ~ "が正しく配置されてぁ�く�能性があります�nこ�まま開始すると、一部リソース画像が非表示になります�);
	auto useDefaultSkin = Msg("useDefaultSkin", "スキン�1$s」が見つかりません�nッ�ォルト�スキン�1$s」を使用します�);
	auto scenarioName = Msg("scenarioName", "シナリオ�);
	auto type = Msg("type", "タイ�);
	auto initialize = Msg("initialize", "初期設�);
	auto classic = Msg("classic", "クラシヂ�");
	auto scenarioTemplate = Msg("scenarioTemplate", "ッ�プレー�);
	auto templateDesc = Msg("templateDesc", "%1$s [%2$s]");
	auto noTemplate = Msg("noTemplate", "ッ�プレート無�);
	auto createClassicDir = Msg("createClassicDir", "シナリオの作��);
	auto newClassicDir = Msg("newClassicDir", "シナリオ作�先�選�);
	auto newClassicDirDesc = Msg("newClassicDirDesc", "シナリオを作�する" ~ DIR ~ "を選択してください�);
	auto notEmptyDir = Msg("notEmptyDir", "%1$sは空ではありません�n本当にここでシナリオを作�しますか);
	auto createScenarioNameDir = Msg("createScenarioNameDir", "シナリオの" ~ DIR ~ "を新規作�する");
	auto notClassicWarning = Msg("notClassicWarning", "※ 「クラシヂ�」以外�タイプ�CardWirthPy専用形式となりま�);

	auto newScenarioName = Msg("newScenarioName", "新規シナリオ");
	auto newAreaName = Msg("newAreaName", "開始エリア");

	auto dlgTitSaveBitmapImage = Msg("dlgTitSaveBitmapImage", "格納イメージの保�);
	auto filterBitmapImage = Msg("filterBitmapImage", "ビット��イメージ (*.bmp)");
	auto dlgMsgIncludeImage = Msg("dlgMsgIncludeImage", "%1$sをシナリオファイル冁�コピ�しますか�\n(�ファイルは削除されません)");
	auto dlgMsgExcludeImage = Msg("dlgMsgExcludeImage", "WSN形式�シナリオでは格納イメージは使用できません�n格納イメージを外部化しますか�\n(外部化しなかった�合、�納イメージは消滁�ま�");

	auto cardImagePosition = Msg("cardImagePosition", "イメージの配置方�");

	const string cardImagePositionName(CardImagePosition id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CardImagePosition, "cardImagePositionName"));
	}
	auto cardImagePositionNameDefault = Msg("cardImagePositionNameDefault", "挮�しな�);
	auto cardImagePositionNameCenter = Msg("cardImagePositionNameCenter", "中央寁�");
	auto cardImagePositionNameTopLeft = Msg("cardImagePositionNameTopLeft", "左上寁�");

	auto dlgTitImageLayerWindow = Msg("dlgTitImageLayerWindow", "レイヤの編�);
	auto dlgTitImageLayerWindowReadOnly = Msg("dlgTitImageLayerWindowReadOnly", "レイヤの一覧");
	auto layerName = Msg("layerName", "レイヤ %1$s");
	auto warningLayer = Msg("warningLayer", "レイヤの挮��Wsn.1以降�形式�シナリオでしか行えません�);
	auto layerValues = Msg("layerValues", "%1$s = 背景セル\n%2$s = メニュー・エネミーカード\n%3$s = プレイヤーカード\n%4$s = メヂ�ージ");
	auto warningBgImageSmoothing = Msg("warningBgImageSmoothing", "背景セルを滑らかに拡大・縮小するかの挮��Wsn.2以降�形式�シナリオでしか行えません�);

	auto smoothing = Msg("smoothing", "サイズ変更時�処�);
	const string smoothingName(Smoothing id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Smoothing, "smoothingName"));
	}
	auto smoothingNameDefault = Msg("smoothingNameDefault", "挮�しな�);
	auto smoothingNameTrue = Msg("smoothingNameTrue", "滑らかにする");
	auto smoothingNameFalse = Msg("smoothingNameFalse", "滑らかにしな�);

	auto newFolder = Msg("newFolder", "新� ~ DIR);

	auto dlgMsgDeleteFile = Msg("dlgMsgDeleteFile", "%1$sを完�に削除しますか);
	auto dlgMsgDeleteFiles = Msg("dlgMsgDeleteFiles", "%1$s個�頛�を完�に削除しますか);
	auto dlgMsgDeleteFileRecycle = Msg("dlgMsgDeleteFileRecycle", "%1$sをごみ箱に移動しますか);
	auto dlgMsgDeleteFilesRecycle = Msg("dlgMsgDeleteFilesRecycle", "%1$s個�頛�をごみ箱に移動しますか);
	auto dlgMsgDeleteUnuse = Msg("dlgMsgDeleteUnuse", "%1$s個�未使用ファイル・" ~ DIR ~ "を完�に削除しますか);
	auto dlgMsgDeleteRecycleUnuse = Msg("dlgMsgDeleteRecycleUnuse", "%1$s個�未使用ファイル・" ~ DIR ~ "をごみ箱に移動しますか);

	auto image = Msg("image", "イメージ");
	auto pathDef = Msg("pathDef", "ッ�ォル�);
	auto pathWsnBasic = Msg("pathWsnBasic", "%1$s 標�);
	auto imageNone = Msg("imageNone", "イメージ無�);
	auto fileNone = Msg("fileNone", "ファイルを選�);
	auto imageIncluding = Msg("imageIncluding", "イメージ格�);
	auto pcNumber = Msg("pcNumber", "プレイヤー%1$s");
	auto pc = Msg("pc", "%1$s番目のメン�);
	auto bgmStop = Msg("bgmStop", "BGM停止");
	auto bgmNone = Msg("bgmNone", "BGM無�);
	auto useNoCardSizeImage = Msg("useNoCardSizeImage", "%1$s�2$s以外も許容");
	auto dlgMsgForceCancelDialogs = Msg("dlgMsgForceCancelDialogs", "%1$s件のダイアログが変更されたまま適用されてぁ�せん。無視して操作を続行しますか);
	auto dlgMsgForceCancelDialogsQuit = Msg("dlgMsgForceCancelDialogsQuit", "%1$s件のダイアログが変更されたまま適用されてぁ�せん。無視して終亁�ますか);
	auto dlgMsgIsSaveBeforeReload = Msg("dlgMsgIsSaveBeforeReload", "�1$s」�変更されてぁ�す。�読込しますか);
	auto reloadBeforeSaveError = Msg("reloadBeforeSaveError", "�1$s」�保存されてぁ�ぁ�め、�読込できません�);
	auto dlgMsgIsSaveBeforeExit = Msg("dlgMsgIsSaveBeforeExit", "�1$s」�変更されてぁ�す。保存しますか);
	auto dlgMsgDropFile = Msg("dlgMsgDropFile", "%1$sをシナリオ" ~ DIR ~ "にコピ�しますか);
	auto dlgMsgDropFiles = Msg("dlgMsgDropFiles", "%1$s個�ファイルをシナリオ" ~ DIR ~ "にコピ�しますか);
	auto dlgMsgDropOverWriteFile = Msg("dlgMsgDropOverWriteFile", "%1$sはすでに存在します。上書きしますか);
	auto dlgMsgDropOverWriteFiles = Msg("dlgMsgDropOverWriteFiles", "%1$s個�頛�がすでに存在します。上書きしますか);
	auto dlgTitDropFiles = Msg("dlgTitDropFiles", "�材ファイルの追�");
	auto dlgMsgCopyError = Msg("dlgMsgCopyError", "ぁ�つか�ファイルのコピ�に失敗しました�);

	auto dlgMsgCopyMaterial1 = Msg("dlgMsgCopyMaterial1", "格納画像もコピ�しますか);
	auto dlgMsgCopyMaterial2 = Msg("dlgMsgCopyMaterial2", "�材もコピ�しますか�\n%1$s");
	auto dlgMsgCopyMaterial3 = Msg("dlgMsgCopyMaterial3", "�材もコピ�しますか�\n%1$s個�ファイル");
	auto dlgMsgCopyMaterial4 = Msg("dlgMsgCopyMaterial4", "�材もコピ�しますか�\n%1$s個�ファイルと%2$s個�格納画�);

	auto incSearchContains = Msg("incSearchContains", "名前の一部");
	auto incSearchWildcard = Msg("incSearchWildcard", "ワイルドカー�);
	auto incSearchRegex = Msg("incSearchRegex", "正規表現");

	auto dlgTitSettings = Msg("dlgTitSettings", "CWXEditorの設�);

	auto refreshS = Msg("refreshS", "更新");

	auto summary = Msg("summary", "シナリオの設�);
	auto area = Msg("area", "エリア");
	auto battle = Msg("battle", "バトル");
	auto cwPackage = Msg("cwPackage", "パッケージ");

	auto dlgTitReplaceText = Msg("dlgTitReplaceText", "検索と置�);
	auto replForText = Msg("replForText", "ヂ�スト検索");
	auto replForID = Msg("replForID", "ID検索");
	auto replForPath = Msg("replForPath", "�材検索");
	auto replContents = Msg("replContents", "コンッ�ト検索");
	auto replForCoupon = Msg("replForCoupon", "称号・名称一覧");
	auto replForUnuse = Msg("replForUnuse", "未使用検索");
	auto replForError = Msg("replForError", "誤り検索");
	auto replGrep = Msg("replGrep", "外部シナリオ");
	auto replStartUsers = Msg("replStartUsers", "スタート�参�");

	auto searchRange = Msg("searchRange", "検索対象");
	auto flagsAndSteps = Msg("flagsAndSteps", "フラグとスッ��);
	auto allCheckRange = Msg("allCheckRange", "全てチェヂ�/全てチェヂ�を外す");

	auto allCheck = Msg("allCheck", "全てチェヂ�/全てチェヂ�を外す(&L)");
	auto allSelect = Msg("allSelect", "全て選�全て選択を外す(&L)");

	auto replError = Msg("replError", "重褁�る��フラグ刲�が両方ともTRUEになってあ��・条件クーポンに抜けがある台詞コンッ�ト�存在しなぴ材を参�してあ�コンッ�ト等を検索します�);

	auto replFrom = Msg("replFrom", "検索(置換前)");
	auto replTo = Msg("replTo", "置換�);
	auto grepFrom = Msg("replFrom", "検索");

	auto replText = Msg("replText", "検索/置換するテキス�);
	auto replTextTarget = Msg("replTextTarget", "検索/置換対象");
	auto replTextSummary = Msg("replTextSummary", "貼�);
	auto replTextMessage = Msg("replTextMessage", "メヂ�ージ");
	auto replTextCardName = Msg("replTextCardName", "カード名");
	auto replTextCardDesc = Msg("replTextCardDesc", "カード解説");
	auto replTextEventText = Msg("replTextEventText", "イベントテキス�);
	auto replTextStart = Msg("replTextStart", "スタートコンッ��);
	auto replTextFlagAndStep = Msg("replTextFlagAndStep", "フラグ/スッ��);
	auto replTextCoupon = Msg("replTextCoupon", "クーポン");
	auto replTextGossip = Msg("replTextGossip", "ゴシ�");
	auto replTextEndScenario = Msg("replTextEndScenario", "終亍�");
	auto replTextAreaName = Msg("replTextAreaName", "エリア/バトル/パッケージ�);
	auto replTextKeyCode = Msg("replTextKeyCode", "キーコー�);
	auto replTextCellName = Msg("replTextCellName", "セル名称");
	auto replTextFile = Msg("replTextFile", "ファイル�);
	auto replTextComment = Msg("replTextComment", "コメン�);
	auto replTextJptx = Msg("replTextJptx", "JPTX/ヂ�ストセル");
	auto replTextScenario = Msg("replTextScenario", "シナリオ�);
	auto replTextAuthor = Msg("replTextAuthor", "作耐�");

	auto replID = Msg("replID", "検索/置換対象");
	auto replIDKind = Msg("replIDKind", "対象");
	auto replIDArea = Msg("replIDArea", "エリア");
	auto replIDBattle = Msg("replIDBattle", "バトル");
	auto replIDPackage = Msg("replIDPackage", "パッケージ");
	auto replIDCast = Msg("replIDCast", "キャストカー�);
	auto replIDSkill = Msg("replIDSkill", "特殊技能カー�);
	auto replIDItem = Msg("replIDItem", "アイッ�カー�);
	auto replIDBeast = Msg("replIDBeast", "召喚獣カー�);
	auto replIDInfo = Msg("replIDInfo", "惱カー�);
	auto replIDFlag = Msg("replIDFlag", "フラグ");
	auto replIDStep = Msg("replIDStep", "スッ��);
	auto replIDCoupon = Msg("replIDCoupon", "クーポン");
	auto replIDGossip = Msg("replIDGossip", "ゴシ�");
	auto replIDCompleteStamp = Msg("replIDCompleteStamp", "終亍�");
	auto replIDKeyCode = Msg("replIDKeyCode", "キーコー�);
	auto replIDCellName = Msg("replIDCellName", "セル名称");
	auto replSetID = Msg("replSetID", "IDを直接挮);

	auto replPath = Msg("replPath", "検索/置換する��);

	auto replUnuseTarget = Msg("replUnuseTarget", "検索対象");
	auto replUnuseFlag = Msg("replUnuseFlag", "フラグ");
	auto replUnuseStep = Msg("replUnuseStep", "スッ��);
	auto replUnuseArea = Msg("replUnuseArea", "エリア");
	auto replUnuseBattle = Msg("replUnuseBattle", "バトル");
	auto replUnusePackage = Msg("replUnusePackage", "パッケージ");
	auto replUnuseCast = Msg("replUnuseCast", "キャストカー�);
	auto replUnuseSkill = Msg("replUnuseSkill", "特殊技能カー�);
	auto replUnuseItem = Msg("replUnuseItem", "アイッ�カー�);
	auto replUnuseBeast = Msg("replUnuseBeast", "召喚獣カー�);
	auto replUnuseInfo = Msg("replUnuseInfo", "惱カー�);
	auto replUnuseStart = Msg("replUnuseStart", "スタートコンッ��);
	auto replUnusePath = Msg("replUnusePath", "��);

	auto replNotIgnoreCase = Msg("replNotIgnoreCase", "大断�と小文字を区別する(&C)");
	auto replRegExp = Msg("replRegExp", "正規表現(&E) (. = 任�断 * = 直前�断��任意数繰返し, $1 = 1つめ�断��グルー�...)");
	auto regexError = Msg("regexError", "正規表現が正しくありません�);
	auto replWildcard = Msg("replWildcard", "ワイルドカー�&W) (* = 任意文字�, ? = 任�断 \\* = *, \\? = ?, \\\\ = \\)");
	auto replExactMatch = Msg("replExactMatch", "完�一致(&X)");
	auto replIgnoreReturnCode = Msg("replIgnoreReturnCode", "改行と前後�空白を無�&I) (置換�できません)");
	auto wildcardDesc = Msg("wildcardDesc", "ワイルドカードが使用できま�* = 任意文字�, ? = 任�断 \\* = *, \\? = ?, \\\\ = \\)");
	auto replCond = Msg("replCond", "検索条件");
	auto search = Msg("search", "検索(&F)");
	auto replace = Msg("replace", "全て置�&R)");
	auto cautionOfReplace = Msg("cautionOfReplace", "%1$s�2$sに置換します。よろしぁ�すか);
	auto replaceValue = Msg("replaceValue", "�1$s�);
	auto emptyText = Msg("emptyText", "空断��");
	auto emptyPath = Msg("emptyPath", "空のパス");
	auto idValue = Msg("idValue", "ID:%1$sの%2$s");
	auto searchCancel = Msg("searchCancel", "キャンセル(&C)");
	auto searchResultEmpty = Msg("searchResultEmpty", "0件の検索結果");
	auto searchResult = Msg("searchResult", "%1$s件の検索結果(%2$s)");
	auto searchResultGrep1 = Msg("searchResultGrep1", "%1$s件のシナリオ�%2$s件の検索結果(%3$sを読込中...)");
	auto searchResultGrep2 = Msg("searchResultGrep2", "%1$s件のシナリオ�%2$s件の検索結果(%3$sを検索中...)");
	auto searchResultGrep3 = Msg("searchResultGrep3", "%1$s件のシナリオ�%2$s件の検索結果(%3$s)");
	auto searchResultRealtime = Msg("searchResultRealtime", "リアルタイ�更新(&R)");
	auto replResultEmpty = Msg("replResultEmpty", "0箉�の置�);
	auto replResult = Msg("replResult", "%1$s箉�の置�%2$s)");
	auto replaceUndo = Msg("replaceUndo", "%1$s件を�に戻しました");
	auto replaceRedo = Msg("replaceRedo", "%1$s件をやり直しました");

	auto grepText = Msg("grepText", "検索するヂ�ス�);
	auto grepTarget = Msg("grepTarget", "検索対象");
	auto grepDir = Msg("grepDir", "外部シナリオ検索");
	auto grepDirDesc = Msg("grepDirDesc", "検索対象のシナリオが含まれる" ~ DIR ~ "を選択してください�);
	auto grepCurrent = Msg("grepCurrent", "現" ~ DIR);
	auto grepSubDir = Msg("grepSubDir", "サ� ~ DIR ~ "も検索する");
	auto grepScenario = Msg("grepScenario", "%1$s[%2$s]");

	auto searchResultColumnMain = Msg("searchResultColumnMain", "マッチ箉�");
	auto searchResultColumnParent = Msg("searchResultColumnParent", "所�);
	auto searchResultColumnCoupon = Msg("searchResultColumnCoupon", "称号・名称");
	auto searchResultColumnCouponCount = Msg("searchResultColumnCouponCount", "利用数");
	auto searchResultColumnError = Msg("searchResultColumnError", "誤り箉�");
	auto searchResultColumnErrorDesc = Msg("searchResultColumnErrorDesc", "解説");
	auto searchResultColumnScenario = Msg("searchResultColumnScenario", "シナリオ");

	auto searchResultSummary = Msg("searchResultSummary", "シナリオの概�- %1$s");

	auto searchResultImageCell = Msg("searchResultBgImage", "背景画�[%1$s]");
	auto searchResultTextCell = Msg("searchResultTextCell", "ヂ�ストセル [%1$s]");
	auto searchResultColorCell = Msg("searchResultColorCell", "カラーセル [%1$s]");
	auto searchResultPCCell = Msg("searchResultPCCell", "プレイヤーキャラクタセル [%1$s]");
	auto searchResultIds = Msg("searchResultIds", "%1$s [%2$s.%3$s]");

	auto searchResultFlag = Msg("searchResultFlag", "フラグ [%1$s]");
	auto searchResultStep = Msg("searchResultStep", "スッ��[%1$s]");
	auto searchResultFlagDir = Msg("searchResultFlagDir", "ヂ�レクトリ [%1$s]");
	auto searchResultEventTree = Msg("searchResultEventTree", "イベントツリー [%1$s]");
	auto searchResultMenuCard = Msg("searchResultMenuCard", "メニューカー�[%1$s]");
	auto searchResultMenuCardWithDesc = Msg("searchResultMenuCardWithDesc", "メニューカー�[%1$s] - %2$s");
	auto searchResultEnemyCard = Msg("searchResultEnemyCard", "エネミーカー�[%1$s]");

	auto searchResultJpy1 = Msg("searchResultJpy1", "JPY1ファイル [%1$s]");
	auto searchResultJpdc = Msg("searchResultJpdc", "JPDCファイル [%1$s]");

	auto searchErrorReversalLevel = Msg("searchErrorReversalLevel", "レベルの上限と下限が逻�してぁ�す�);
	auto searchErrorNoImage = Msg("searchErrorNoImage", "イメージが指定されてぁ�せん�);
	auto searchErrorImageNotFound = Msg("searchErrorImageNotFound", "存在しなあ�メージファイル(%1$s)が指定されてぁ�す�);
	auto searchErrorBGMNotFound = Msg("searchErrorBGMNotFound", "存在しないBGMファイル(%1$s)が指定されてぁ�す�);
	auto searchErrorSENotFound = Msg("searchErrorSENotFound", "存在しなお�果音ファイル(%1$s)が指定されてぁ�す�);
	auto searchErrorStartAreaNotFound = Msg("searchErrorStartAreaNotFound", "開始エリアが設定されてぁ�せん�);
	auto searchErrorFlagNotFound = Msg("searchErrorFlagNotFound", "存在しなぃ�ラグ(%1$s)が指定されてぁ�す�);
	auto searchErrorStepNotFound = Msg("searchErrorStepNotFound", "存在しなあ�ッ��%1$s)が指定されてぁ��);
	auto searchErrorDupNextContent = Msg("searchErrorDupNextContent", "刲�条件が重褁�てぁ�す�);
	auto searchErrorSPFontIsNotSJIS1ByteChar = Msg("searchErrorSPFontIsNotSJIS1ByteChar", "�1$s」�無効です。クラシヂ�なシナリオの特殊フォント指定にはShift JISの1バイト文字しか使用できません�);
	auto searchErrorSPFontNotFound = Msg("searchErrorSPFontNotFound", "特殊フォントイメージ(%1$s)が見つかりません�);
	auto searchErrorNoRCouponsDialog = Msg("searchErrorNoRCouponsDialog", "最終雮以外にクーポン挮�無し雮があります�);
	auto searchErrorAreaNotFound = Msg("searchErrorAreaNotFound", "存在しなあ�リア(ID:%1$s)が指定されてぁ�す�);
	auto searchErrorBattleNotFound = Msg("searchErrorBattleNotFound", "存在しなぃ�トル(ID:%1$s)が指定されてぁ�す�);
	auto searchErrorPackageNotFound = Msg("searchErrorPackageNotFound", "存在しなぃ�ヂ�ージ(ID:%1$s)が指定されてぁ�す�);
	auto searchErrorCastNotFound = Msg("searchErrorCastNotFound", "存在しなあ�ャストカー�ID:%1$s)が指定されてぁ�す�);
	auto searchErrorSkillNotFound = Msg("searchErrorSkillNotFound", "存在しなぉ�殊技能カー�ID:%1$s)が指定されてぁ�す�);
	auto searchErrorItemNotFound = Msg("searchErrorItemNotFound", "存在しなあ�イッ�カー�ID:%1$s)が指定されてぁ�す�);
	auto searchErrorBeastNotFound = Msg("searchErrorBeastNotFound", "存在しなく�喚獣カー�ID:%1$s)が指定されてぁ�す�);
	auto searchErrorInfoNotFound = Msg("searchErrorInfoNotFound", "存在しなぃ�報カー�ID:%1$s)が指定されてぁ�す�);
	auto searchErrorStartNotFound = Msg("searchErrorStartNotFound", "存在しなあ�タートコンッ�ト�1$s」が挮�されてぁ�す�);
	auto searchErrorIgnoreWait = Msg("searchErrorIgnoreWait", "後続コンッ�トが無ぁ�め、空白時間が無視されます�);
	auto searchErrorLinkIdSkillNotFound = Msg("searchErrorLinkIdSkillNotFound", "参�先�特殊技能カー�ID:%1$s)が見つかりません�);
	auto searchErrorLinkIdItemNotFound = Msg("searchErrorLinkIdItemNotFound", "参�先�アイッ�カー�ID:%1$s)が見つかりません�);
	auto searchErrorLinkIdBeastNotFound = Msg("searchErrorLinkIdBeastNotFound", "参�先�召喚獣カー�ID:%1$s)が見つかりません�);
	auto searchErrorEmptyFile = Msg("searchErrorEmptyFile", "ファイルの冮�が存在しません�);
	auto searchErrorDupFile = Msg("searchErrorDupFile", "同一のファイル�1$s」が存在します�);
	auto searchErrorSourceIsTarget = Msg("searchErrorSourceIsTarget", "ソース変数とターゲッ�変数が同一です�);
	auto searchErrorSystemCoupon = Msg("searchErrorSystemCoupon", "�1$s」�シスッ�クーポンとして扱われるため、正しく機�しなぴ合があります�);
	auto searchErrorSystemVariable = Msg("searchErrorSystemVariable", "�1$s」�シスッ�変数として扱われるため、正しく機�しなぴ合があります�);
	auto searchErrorKeyCodeMatchingAll = Msg("searchErrorKeyCodeMatchingAll", "「MatchingType=All」�シスッ�で使用されてあ�キーコード�ため、正しく機�しなぴ合があります�);
	auto searchErrorBranchRoundInArea = Msg("searchErrorBranchRoundInArea", "ラウンド�岐がエリアイベントで使用されてぁ�す�);

	auto searchErrorNoArea = Msg("searchErrorNoArea", "エリアが指定されてぁ�せん�);
	auto searchErrorNoBattle = Msg("searchErrorNoBattle", "バトルが指定されてぁ�せん�);
	auto searchErrorNoPackage = Msg("searchErrorNoPackage", "パッケージが指定されてぁ�せん�);
	auto searchErrorNoSkill = Msg("searchErrorNoSkill", "特殊技能カードが挮�されてぁ�せん�);
	auto searchErrorNoItem = Msg("searchErrorNoItem", "アイッ�カードが挮�されてぁ�せん�);
	auto searchErrorNoCast = Msg("searchErrorNoCast", "キャストカードが挮�されてぁ�せん�);
	auto searchErrorNoBeast = Msg("searchErrorNoBeast", "召喚獣カードが挮�されてぁ�せん�);
	auto searchErrorNoInfo = Msg("searchErrorNoInfo", "惱カードが挮�されてぁ�せん�);
	auto searchErrorNoFlag = Msg("searchErrorNoFlag", "フラグが指定されてぁ�せん�);
	auto searchErrorNoStep = Msg("searchErrorNoStep", "スッ�プが挮�されてぁ�せん�);
	auto searchErrorNoSoundPath = Msg("searchErrorNoSoundPath", "効果音が指定されてぁ�せん�);
	auto searchErrorNoCoupon = Msg("searchErrorNoCoupon", "クーポンが指定されてぁ�せん�);
	auto searchErrorNoGossip = Msg("searchErrorNoGossip", "ゴシ�が指定されてぁ�せん�);
	auto searchErrorNoCompleteStamp = Msg("searchErrorNoCompleteStamp", "シナリオ名が挮�されてぁ�せん�);
	auto searchErrorNoKeyCode = Msg("searchErrorNoKeyCode", "キーコードが挮�されてぁ�せん�);
	auto searchErrorNoCellName = Msg("searchErrorNoCellName", "セル名称が指定されてぁ�せん�);

	auto searchOpenDialog = Msg("searchOpenDialog", "検索結果へジャンプする時、ダイアログを開�&J)");

	/// イベント設定�	auto dlgTitContent = Msg("dlgTitContent", "イベント�設�[ %1$s ]");

	auto afterClear = Msg("afterClear", "シナリオ終亾);
	auto afterClearEndMark = Msg("afterClearEndMark", "シナリオに済印を付け�);
	auto afterClearNoEndMark = Msg("afterClearNoEndMark", "何もしな�);

	auto couponName = Msg("couponName", "クーポン�);
	auto couponValue = Msg("couponValue", "得点");
	auto couponValueRange = Msg("couponValueRange", "(%1$s2$s)");
	auto range = Msg("range", "適用篛�");
	auto matchingType = Msg("matchingType", "マッチングタイ�); // Wsn.2
	auto gossipName = Msg("gossipName", "ゴシ��);
	auto endName = Msg("endName", "シナリオ�);
	auto cardType = Msg("cardType", "カード�種�);
	auto keyCode = Msg("keyCode", "キーコー�);
	auto talker = Msg("talker", "話�);
	auto initValue = Msg("initValue", "初期点");
	auto toneCoupons = Msg("toneCoupons", "口調条件");
	auto valued = Msg("valued", "評価条件");
	auto valuedTalkerMaxIsLess0 = Msg("valuedTalkerMaxIsLess0", "最大値 = %1$s (発言しな�\n最小値 = %2$s (発言しな�");
	auto valuedTalkerMaxMin = Msg("valuedTalkerMaxMin", "最大値 = %1$s\n最小値 = %2$s");
	auto valuedTalkerMaxMinLess0 = Msg("valuedTalkerMaxMinLess0", "最大値 = %1$s\n最小値 = %2$s (発言しな�");
	auto selectMemberValuedMaxIsLess0 = Msg("selectMemberValuedMaxIsLess0", "最大値 = %1$s (選択失�\n最小値 = %2$s (選択失�");
	auto selectMemberValuedMaxMin = Msg("selectMemberValuedMaxMin", "最大値 = %1$s\n最小値 = %2$s");
	auto selectMemberValuedMaxMinLess0 = Msg("selectMemberValuedMaxMinLess0", "最大値 = %1$s\n最小値 = %2$s (選択失�");
	auto cellName = Msg("cellName", "対象セル名称");
	auto moveCell = Msg("moveCell", "位置の変更");
	auto resizeCell = Msg("resizeCell", "サイズの変更");
	auto horizontalValue = Msg("horizontalValue", "横の値");
	auto verticalValue = Msg("verticalValue", "縦の値");

	auto canNotGetMusicLength = Msg("canNotGetMusicLength", "SDL方式では音声の長さを取得できません");

	auto couponHide = Msg("couponHide", "�蔽クーポン");

	const string couponTypeDesc(CouponType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CouponType, "couponTypeDesc"));
	}
	auto couponTypeDescNormal = Msg("couponTypeDescNormal", "ノ�マル");
	auto couponTypeDescHide = Msg("couponTypeDescHide", "�蔽");
	auto couponTypeDescSystem = Msg("couponTypeDescSystem", "シスッ�");
	auto couponTypeDescDur = Msg("couponTypeDescDur", "時限");
	auto couponTypeDescDurBattle = Msg("couponTypeDescDurBattle", "戦闘中時限");

	const string couponTypeLongDesc(CouponType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CouponType, "couponTypeLongDesc"));
	}
	auto couponTypeLongDescNormal = Msg("couponTypeLongDescNormal", "ノ�マル");
	auto couponTypeLongDescHide = Msg("couponTypeLongDescHide", "[%1$s...] �蔽(称号一覧で非表示)");
	auto couponTypeLongDescSystem = Msg("couponTypeLongDescSystem", "[%1$s...] シスッ�");
	auto couponTypeLongDescDur = Msg("couponTypeLongDescDur", "[%1$s...] 時限(点数�時間経過及�シナリオ終亙�に消�");
	auto couponTypeLongDescDurBattle = Msg("couponTypeLongDescDurBattle", "[%1$s...] 戦闘中時限(点数�時間経過及�戦闘終亙�に消�");

	const string couponTypeShortDesc(CouponType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CouponType, "couponTypeShortDesc"));
	}
	auto couponTypeShortDescNormal = Msg("couponTypeShortDescNormal", "一般");
	auto couponTypeShortDescHide = Msg("couponTypeShortDescHide", "�蔽");
	auto couponTypeShortDescSystem = Msg("couponTypeShortDescSystem", "特�);
	auto couponTypeShortDescDur = Msg("couponTypeShortDescDur", "時限");
	auto couponTypeShortDescDurBattle = Msg("couponTypeShortDescDurBattle", "戦�);

	const string couponTypeName(CouponType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CouponType, "couponTypeName"));
	}
	auto couponTypeNameNormal = Msg("couponTypeNameNormal", "通常");
	auto couponTypeNameHide = Msg("couponTypeNameHide", "�蔽");
	auto couponTypeNameSystem = Msg("couponTypeNameSystem", "シスッ�");
	auto couponTypeNameDur = Msg("couponTypeNameDur", "時限");
	auto couponTypeNameDurBattle = Msg("couponTypeNameDurBattle", "戦�);

	const string matchingTypeName(MatchingType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(MatchingType, "matchingTypeName"));
	}
	auto matchingTypeNameAnd = Msg("matchingTypeNameAnd", "全てに一致");
	auto matchingTypeNameOr = Msg("matchingTypeNameOr", "どれか一つに一致");

	auto imageMessage = Msg("imageMessage", "イメージ付きメヂ�ージ");
	auto noImageMessage = Msg("noImageMessage", "イメージ無しメヂ�ージ");
	auto spCharsTitle = Msg("spCharsTitle", "特殊文�);
	auto colorW = Msg("colorW", "ッ�ォル�&W)");
	auto colorR = Msg("colorR", "赤色(&R)");
	auto colorB = Msg("colorB", "青色(&B)");
	auto colorG = Msg("colorG", "緑色(&G)");
	auto colorY = Msg("colorY", "黉�(&Y)");
	auto colorO = Msg("colorO", "橙色(&O)"); // CardWirth 1.50
	auto colorP = Msg("colorP", "紫色(&P)"); // CardWirth 1.50
	auto colorL = Msg("colorL", "明る�色(&L)"); // CardWirth 1.50
	auto colorD = Msg("colorD", "暗い灰色(&D)"); // CardWirth 1.50
	const string scTalkerName(Talker id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Talker, "scTalkerName"));
	}
	auto scTalkerNameSelected = Msg("scTalkerNameSelected", "選択メンバ名(#M)");
	auto scTalkerNameUnselected = Msg("scTalkerNameUnselected", "選択外ランダ�メンバ名(#U)");
	auto scTalkerNameRandom = Msg("scTalkerNameRandom", "ランダ�メンバ名(#R)");
	auto scTalkerNameCard = Msg("scTalkerNameCard", "選択カード名(#C)");
	auto scTalkerNameNarration = Msg("scTalkerNameNarration", "話耄��);
	auto scTalkerNameImage = Msg("scTalkerNameImage", "画�);
	auto scTalkerNameValued = Msg("scTalkerNameValued", "評価メン�);
	auto scRef = Msg("scRef", "話�#I)");
	auto scTeam = Msg("scTeam", "チ���#T)");
	auto scYado = Msg("scYado", "宿屋名(#Y)");
	auto addMsgRefFlag = Msg("addMsgRefFlag", "フラグ参�の追�");
	auto addMsgRefStep = Msg("addMsgRefStep", "スッ�プ参照の追�");
	auto addMsgRefImageFont = Msg("addMsgRefImageFont", "画像参照の追�");
	auto createDialog = Msg("createDialog", "台詞�作�");
	auto deleteDialog = Msg("deleteDialog", "台詞�削除");
	auto copyToDialogs = Msg("copyToDialogs", "台詞を全体にコピ�");
	auto copyToUpper = Msg("copyToUpper", "台詞を上方にコピ�");
	auto copyToLower = Msg("copyToLower", "台詞を下方にコピ�");
	auto setTalkerCoupon = Msg("setTalkerCoupon", "追�");
	auto messagePreview = Msg("messagePreview", "プレビュー(&P)");
	auto dlgTitMessagePreview = Msg("dlgTitMessagePreview", "プレビュー");
	auto messageVarKindColumn = Msg("messageVarKindColumn", "状態変数");
	auto messageVarValueColumn = Msg("messageVarValueColumn", "サンプル値");

	auto transition = Msg("transition", "背景创�方�);
	const string transitionName(Transition id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Transition, "transitionName"));
	}
	auto transitionNameDefault = Msg("transitionNameDefault", "プレイヤーの設定を使用");
	auto transitionNameNone = Msg("transitionNameNone", "アニメーション無�);
	auto transitionNameBlinds = Msg("transitionNameBlinds", "短�スレッ�)�);
	auto transitionNamePixelDissolve = Msg("transitionNamePixelDissolve", "ドット置�シェー��);
	auto transitionNameFade = Msg("transitionNameFade", "色置�フェー��);
	auto transitionSpeed = Msg("transitionSpeed", "背景创�ウェイ�);
	auto waitName = Msg("waitName", "空白時間(0.1秒単�");
	auto moneyName = Msg("moneyName", "金�);
	auto randomName = Msg("randomName", "確�%)");
	auto partyNumName = Msg("partyNumName", "パ�ヂ�の人数");
	auto judgeTarget = Msg("judgeTarget", "判定対象");
	auto flag = Msg("flag", "フラグ");
	auto step = Msg("step", "スッ��);
	auto flagValue = Msg("flagValue", "値");
	auto stepValue = Msg("stepValue", "段�);
	auto selectMember = Msg("selectMember", "選択対象");
	auto activeMember = Msg("activeMember", "動けるメンバから選�);
	auto allMember = Msg("allMember", "パ�ヂ�全員から選�);
	auto selectMethod = Msg("selectMethod", "選択方�);
	auto manualMethod = Msg("manualMethod", "手動で選�);
	auto randomMethod = Msg("randomMethod", "ランダ�で選�);
	auto valuedMethod = Msg("valuedMethod", "評価条件で選�);
	auto judgeSleep = Msg("judgeSleep", "�り判�);
	auto sleepDisabled = Msg("sleepDisabled", "睡�・呪縛耄�効");
	auto sleepEnabled = Msg("sleepEnabled", "睡�・呪縛耜�効");
	auto selectedLevel = Msg("selectedLevel", "現在選択中のメン�);
	auto allMemberLevel = Msg("allMemberLevel", "パ�ヂ�全員の平址�");
	auto judgeLevel = Msg("judgeLevel", "判定レベル");
	auto judgeState = Msg("judgeState", "判定状�);
	auto stateHint = Msg("stateHint", "ヒン�);
	auto cardNumber = Msg("cardNumber", "枚数");
	auto cardAllDelete = Msg("cardAllDelete", "全て削除する");
	auto cardEventRange = Msg("cardEventRange", "適用篛�");
	auto transitionType = Msg("transitionType", "背景创�方�);
	auto substituteSource = Msg("flagSubstituteSource", "ソース変数(代入�");
	auto substituteTarget = Msg("flagSubstituteTarget", "ターゲッ�変数(代入�");
	auto cmpSource = Msg("flagCmpSource", "ソース変数(比�)");
	auto cmpTarget = Msg("flagCmpTarget", "ターゲッ�変数(比�)");
	auto randomSelectHasLevel = Msg("randomSelectHasLevel", "レベルを限�);
	auto randomSelectHasStatus = Msg("randomSelectHasStatus", "状態を限�);
	auto stepValueIs = Msg("stepValueIs", "スッ�プ�1$s」が[%2$s]");
	auto roundCondition = Msg("roundCondition", "ラウンド条件");
	auto roundIs = Msg("roundIs", "バトル�);
	auto roundCmpIs = Msg("roundCmpIs", "ラウン�);
	auto doAnime = Msg("doAnime", "JPY1アニメーションを実行す�); // Wsn.1
	auto ignoreEffectBooster = Msg("ignoreEffectBooster", "エフェクトブースター関係�セルを無視す�); // Wsn.1
	auto selectionColumns = Msg("selectionColumns", "選択肢の列数"); // Wsn.1
	auto centeringY = Msg("centeringY", "縦方向に中央寁�"); // Wsn.2
	auto centeringYOn = Msg("centeringYOn", "縦の中央寁�"); // Wsn.2
	auto boundaryCheck = Msg("boundaryCheck", "禁則処�); // Wsn.2
	auto boundaryCheckOn = Msg("boundaryCheckOn", "禁則処琁��); // Wsn.2
	auto boundaryCheckDesc = Msg("boundaryCheckDesc", "禁則処�結果は尝�変化するかもしれません�nメヂ�ージの行数には余裕を持たせておく事をお勧めします�); // Wsn.2

	const string blendModeName(BlendMode id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(BlendMode, "blendModeName"));
	}
	auto blendModeNameNormal = Msg("blendModeNameNormal", "通常");
	auto blendModeNameMask = Msg("blendModeNameMask", "マスク");
	auto blendModeNameAdd = Msg("blendModeNameAdd", "��);
	auto blendModeNameSubtract = Msg("blendModeNameSubtract", "減�);
	auto blendModeNameMultiply = Msg("blendModeNameMultiply", "乗�);

	const string gradientDirName(GradientDir id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(GradientDir, "gradientDirName"));
	}
	auto gradientDirNameNone = Msg("gradientDirNameNone", "グラ�ション無�);
	auto gradientDirNameLeftToRight = Msg("gradientDirNameLeftToRight", "左から右へ");
	auto gradientDirNameTopToBottom = Msg("gradientDirNameTopToBottom", "上から下へ");

	const string borderingTypeName(BorderingType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(BorderingType, "borderingTypeName"));
	}
	auto borderingTypeNameNone = Msg("borderingTypeNameNone", "縁取り無�);
	auto borderingTypeNameOutline = Msg("borderingTypeNameOutline", "形�");
	auto borderingTypeNameInline = Msg("borderingTypeNameInline", "形�");

	const string coordinateTypeName(CoordinateType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CoordinateType, "coordinateTypeName"));
	}
	auto coordinateTypeNameNone = Msg("coordinateTypeNameNone", "変更無�);
	auto coordinateTypeNameAbsolute = Msg("coordinateTypeNameAbsolute", "直接挮);
	auto coordinateTypeNameRelative = Msg("coordinateTypeNameRelative", "現在値基�);
	auto coordinateTypeNamePercentage = Msg("coordinateTypeNamePercentage", "パ�セン�ジ");

	auto startAction = Msg("startAction", "戦闘行動開始タイミング");
	const string startActionName(StartAction id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(StartAction, "startActionName"));
	}
	auto startActionNameNow = Msg("startActionNameNow", "すぐに行動");
	auto startActionNameCurrentRound = Msg("startActionNameCurrentRound", "�入ラウンドから行動");
	auto startActionNameNextRound = Msg("startActionNameNextRound", "次のラウンドから行動");

	auto igniteTitle = Msg("igniteTitle", "イベント発火の有無");
	auto ignite = Msg("ignite", "効果適用時にキーコードイベントと死亡イベントを発火させ�);
	auto igniteTrue = Msg("igniteTrue", "イベント発火あり");
	auto igniteFalse = Msg("igniteFalse", "イベント発火無�);
	auto igniteHint = Msg("igniteHint", "※ 発火したイベント�で選択メンバが変更される可能性がありま�);

	auto refAbilityTitle = Msg("refAbilityTitle", "能力参照");
	auto refAbility = Msg("refAbility", "成功玁�効果値の計算に選択中のメンバ�レベルと能力を使用する");

	/// イベント�	auto evtArrow = Msg("evtArrow", "イベント編�);

	auto allExpanded = Msg("allExpanded", "全て開く/全て閉じ�&E)");

	auto evtAutoOpen = Msg("evtAutoOpen", "配置と同時に編�);
	auto evtInsertFirst = Msg("evtInsertFirst", "他�子コンッ�トより前に配置");

	auto eventTreeViewHint = Msg("eventTreeViewHint", "Shift+配置: 選択コンッ�ト�上へ挿入, Alt+配置: 「�置と同時に編雀�設定を反転, Ctrl+配置: 「他�子コンッ�トより前に配置」設定を反転");

	const string contentName(CType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CType, "contentName"));
	}
	auto contentNameStart = Msg("contentNameStart", "スター�);
	auto contentNameStartBattle = Msg("contentNameStartBattle", "バトル開�);
	auto contentNameEnd = Msg("contentNameEnd", "シナリオクリア");
	auto contentNameEndBadEnd = Msg("contentNameEndBadEnd", "敗北・ゲー�オーバ�");
	auto contentNameChangeArea = Msg("contentNameChangeArea", "エリア移�);
	auto contentNameChangeBgImage = Msg("contentNameChangeBgImage", "背景変更");
	auto contentNameEffect = Msg("contentNameEffect", "効�);
	auto contentNameEffectBreak = Msg("contentNameEffectBreak", "効果中断");
	auto contentNameLinkStart = Msg("contentNameLinkStart", "スタートへのリンク");
	auto contentNameLinkPackage = Msg("contentNameLinkPackage", "パッケージへのリンク");
	auto contentNameTalkMessage = Msg("contentNameTalkMessage", "メヂ�ージ");
	auto contentNameTalkDialog = Msg("contentNameTalkDialog", "セリ�);
	auto contentNamePlayBgm = Msg("contentNamePlayBgm", "BGM変更");
	auto contentNamePlaySound = Msg("contentNamePlaySound", "効果音");
	auto contentNameWait = Msg("contentNameWait", "空白時間挿入");
	auto contentNameElapseTime = Msg("contentNameElapseTime", "時間経過");
	auto contentNameCallStart = Msg("contentNameCallStart", "スタート�呼び出�);
	auto contentNameCallPackage = Msg("contentNameCallPackage", "パッケージの呼び出�);
	auto contentNameBranchFlag = Msg("contentNameBranchFlag", "フラグ刲);
	auto contentNameBranchMultiStep = Msg("contentNameBranchMultiStep", "スッ�プ多岐��);
	auto contentNameBranchStep = Msg("contentNameBranchStep", "スッ�プ上下��);
	auto contentNameBranchSelect = Msg("contentNameBranchSelect", "メンバ選択��);
	auto contentNameBranchAbility = Msg("contentNameBranchAbility", "能力判定��);
	auto contentNameBranchRandom = Msg("contentNameBranchRandom", "ランダ�刲);
	auto contentNameBranchLevel = Msg("contentNameBranchLevel", "レベル判定��);
	auto contentNameBranchStatus = Msg("contentNameBranchStatus", "状態判定��);
	auto contentNameBranchPartyNumber = Msg("contentNameBranchPartyNumber", "人数判定��);
	auto contentNameBranchArea = Msg("contentNameBranchArea", "エリア刲);
	auto contentNameBranchBattle = Msg("contentNameBranchBattle", "バトル刲);
	auto contentNameBranchIsBattle = Msg("contentNameBranchIsBattle", "バトル判定��);
	auto contentNameBranchCast = Msg("contentNameBranchCast", "キャスト存在刲);
	auto contentNameBranchItem = Msg("contentNameBranchItem", "アイッ�所持��);
	auto contentNameBranchSkill = Msg("contentNameBranchSkill", "スキル所持��);
	auto contentNameBranchInfo = Msg("contentNameBranchInfo", "惱所持��);
	auto contentNameBranchBeast = Msg("contentNameBranchBeast", "召喚獣存在刲);
	auto contentNameBranchMoney = Msg("contentNameBranchMoney", "所持�刲);
	auto contentNameBranchCoupon = Msg("contentNameBranchCoupon", "クーポン刲);
	auto contentNameBranchCompleteStamp = Msg("contentNameBranchCompleteStamp", "終亂�ナリオ刲);
	auto contentNameBranchGossip = Msg("contentNameBranchGossip", "ゴシ�刲);
	auto contentNameSetFlag = Msg("contentNameSetFlag", "フラグ変更");
	auto contentNameSetStep = Msg("contentNameSetStep", "スッ�プ変更");
	auto contentNameSetStepUp = Msg("contentNameSetStepUp", "スッ�プ増加");
	auto contentNameSetStepDown = Msg("contentNameSetStepDown", "スッ�プ減�);
	auto contentNameReverseFlag = Msg("contentNameReverseFlag", "フラグ反転");
	auto contentNameCheckFlag = Msg("contentNameCheckFlag", "フラグ判�);
	auto contentNameGetCast = Msg("contentNameGetCast", "キャスト加入");
	auto contentNameGetItem = Msg("contentNameGetItem", "アイッ�入�);
	auto contentNameGetSkill = Msg("contentNameGetSkill", "スキル取�);
	auto contentNameGetInfo = Msg("contentNameGetInfo", "惱入�);
	auto contentNameGetBeast = Msg("contentNameGetBeast", "召喚獣獲�);
	auto contentNameGetMoney = Msg("contentNameGetMoney", "所持�増加");
	auto contentNameGetCoupon = Msg("contentNameGetCoupon", "クーポン取�);
	auto contentNameGetCompleteStamp = Msg("contentNameGetCompleteStamp", "終亂�ナリオ設�);
	auto contentNameGetGossip = Msg("contentNameGetGossip", "ゴシ�追�");
	auto contentNameLoseCast = Msg("contentNameLoseCast", "キャスト離脱");
	auto contentNameLoseItem = Msg("contentNameLoseItem", "アイッ�喪失");
	auto contentNameLoseSkill = Msg("contentNameLoseSkill", "スキル喪失");
	auto contentNameLoseInfo = Msg("contentNameLoseInfo", "惱喪失");
	auto contentNameLoseBeast = Msg("contentNameLoseBeast", "召喚獣消去");
	auto contentNameLoseMoney = Msg("contentNameLoseMoney", "所持�減�);
	auto contentNameLoseCoupon = Msg("contentNameLoseCoupon", "クーポン削除");
	auto contentNameLoseCompleteStamp = Msg("contentNameLoseCompleteStamp", "終亂�ナリオ削除");
	auto contentNameLoseGossip = Msg("contentNameLoseGossip", "ゴシ�削除");
	auto contentNameShowParty = Msg("contentNameShowParty", "パ�ヂ�表示");
	auto contentNameHideParty = Msg("contentNameHideParty", "パ�ヂ��蔽");
	auto contentNameRedisplay = Msg("contentNameRedisplay", "画面再構�);
	auto contentNameSubstituteStep = Msg("contentNameSubstituteStep", "スッ�プ代入");
	auto contentNameSubstituteFlag = Msg("contentNameSubstituteFlag", "フラグ代入");
	auto contentNameBranchStepCmp = Msg("contentNameBranchStepCmp", "スッ�プ比��);
	auto contentNameBranchFlagCmp = Msg("contentNameBranchFlagCmp", "フラグ比��);
	auto contentNameBranchRandomSelect = Msg("contentNameBranchRandomSelect", "ランダ�選�);
	auto contentNameBranchKeyCode = Msg("contentNameBranchKeyCode", "キーコード所持��);
	auto contentNameCheckStep = Msg("contentNameCheckStep", "スッ�プ判�);
	auto contentNameBranchRound = Msg("contentNameBranchRound", "ラウンド��);
	auto contentNameMoveBgImage = Msg("contentNameMoveBgImage", "背景再�置"); // Wsn.1
	auto contentNameReplaceBgImage = Msg("contentNameReplaceBgImage", "背景置�); // Wsn.1
	auto contentNameLoseBgImage = Msg("contentNameLoseBgImage", "背景削除"); // Wsn.1
	auto contentNameBranchMultiCoupon = Msg("contentNameBranchMultiCoupon", "クーポン多岐��); // Wsn.2
	auto contentNameBranchMultiRandom = Msg("contentNameBranchMultiRandom", "ランダ�多岐��); // Wsn.2

	const string contentDesc(CType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CType, "contentDesc"));
	}
	auto contentDescStart = Msg("contentDescStart", "イベントツリーの起点です�);
	auto contentDescStartBattle = Msg("contentDescStartBattle", "イベントを終亁�て任意�バトルを開始します。バトル開始後もイベントを続けたい場合�〖�始するバトルの「バトル開始」イベントを作�してください�);
	auto contentDescEnd = Msg("contentDescEnd", "シナリオを終亁�ます。済印をつけた場合、このシナリオは解決済みとなって再�レイできなくなります�);
	auto contentDescEndBadEnd = Msg("contentDescEndBadEnd", "ゲー�オーバ�にしてシナリオを終亁�ます。バトル中に実行した�合�、敗北扱ぁ�なります�);
	auto contentDescChangeArea = Msg("contentDescChangeArea", "イベントを終亁�て任意�エリアへ移動します。移動後もイベントを続けたい場合�、移動�エリアの「到着」イベントを作�してください�);
	auto contentDescChangeBgImage = Msg("contentDescChangeBgImage", "背景セルを追�もしく�全て交換し、背景を�描画します。画面全体を要�背景イメージを最背面に配置した場合、これまで配置されてぁ�背景セルは全て消去されます�);
	auto contentDescEffect = Msg("contentDescEffect", "ダメージ・回復・状態変更などの効果を任意�キャラクタに対して発生させます�);
	auto contentDescEffectBreak = Msg("contentDescEffectBreak", "イベントを終亁�ます。使用時イベント中に使った�合�、カード�使用自体が中止されます�);
	auto contentDescLinkStart = Msg("contentDescLinkStart", "現在のイベントツリーの実行を終亁�、任意�イベントツリーを実行します�);
	auto contentDescLinkPackage = Msg("contentDescLinkPackage", "現在のイベント�実行を終亁�、任意�パッケージイベントを実行します�);
	auto contentDescTalkMessage = Msg("contentDescTalkMessage", "メヂ�ージを表示します。褕�の後続コンッ�トがある場合�、�択肢が表示されます�);
	auto contentDescTalkDialog = Msg("contentDescTalkDialog", "メヂ�ージを表示します。話�所持クーポンによってメヂ�ージの冮�を変える事ができます。褕�の後続コンッ�トがある場合�、�択肢が表示されます�);
	auto contentDescPlayBgm = Msg("contentDescPlayBgm", "BGMを�生もしくは停止します�);
	auto contentDescPlaySound = Msg("contentDescPlaySound", "効果音を�生します�);
	auto contentDescWait = Msg("contentDescWait", "演�などのために、何も起こらなま��時間を任意秒数入れます�);
	auto contentDescElapseTime = Msg("contentDescElapseTime", "ゲー�写�間を経過させ、効果時間�減少や毒�ダメージなどを発生させます。バトルラウンド�経過しません�);
	auto contentDescCallStart = Msg("contentDescCallStart", "任意�イベントツリーを実行し、実行後に現在のイベントツリーへ処琂�戻します�);
	auto contentDescCallPackage = Msg("contentDescCallPackage", "任意�パッケージイベントを実行し、実行後に現在のイベントへ処琂�戻します�);
	auto contentDescBranchFlag = Msg("contentDescBranchFlag", "フラグの値によって処琂�刲�させます�);
	auto contentDescBranchMultiStep = Msg("contentDescBranchMultiStep", "スッ�プ�値がいくつかによって処琂�刲�させます�);
	auto contentDescBranchStep = Msg("contentDescBranchStep", "スッ�プ�値が任意�値以上�未満のどちらかによって処琂�刲�させます�);
	auto contentDescBranchSelect = Msg("contentDescBranchSelect", "手動また�自動でキャラクタを選択し、�択に成功したか、キャンセルもしく�選択に失敗したかによって処琂�刲�させます�);
	auto contentDescBranchAbility = Msg("contentDescBranchAbility", "キャラクタの能力に応じた�功判定を行い、�功したか失敗したかによって処琂�刲�させます。判定に成功したキャラクタは選択状態になります�);
	auto contentDescBranchRandom = Msg("contentDescBranchRandom", "任意�確玁�ランダ�に処琂�刲�させます�);
	auto contentDescBranchLevel = Msg("contentDescBranchLevel", "キャラクタのレベルが任意�値以上�未満のどちらかによって処琂�刲�させます�);
	auto contentDescBranchStatus = Msg("contentDescBranchStatus", "キャラクタが任意�状態かそうでなぁ�によって処琂�刲�させます�);
	auto contentDescBranchPartyNumber = Msg("contentDescBranchPartyNumber", "パ�ヂ�の人数が任意�数以上�未満のどちらかによって処琂�刲�させます�);
	auto contentDescBranchArea = Msg("contentDescBranchArea", "現在どのエリアにあ�かによって処琂�刲�させます。バトル中の場合�、バトル直前にぁ�エリアによって判定を行います�);
	auto contentDescBranchBattle = Msg("contentDescBranchBattle", "現在どのバトルを実行中かによって処琂�刲�させます。バトル中でなぴ合�、常に「その他」へ刲�します�);
	auto contentDescBranchIsBattle = Msg("contentDescBranchIsBattle", "現在バトル中かそぁ�なぁ�によって処琂�刲�させます�);
	auto contentDescBranchCast = Msg("contentDescBranchCast", "任意�キャストが同行中かそぁ�なぁ�によって処琂�刲�させます�);
	auto contentDescBranchItem = Msg("contentDescBranchItem", "任意�アイッ�カードを所持してあ�かいなぁ�によって処琂�刲�させます。所持判定において、名前と解説が一致するカード�同一とみなされます。カードを所持してあ�キャラクタは選択状態になります�);
	auto contentDescBranchSkill = Msg("contentDescBranchSkill", "任意�特殊技能カードを所持してあ�かいなぁ�によって処琂�刲�させます。所持判定において、名前と解説が一致するカード�同一とみなされます。カードを所持してあ�キャラクタは選択状態になります�);
	auto contentDescBranchInfo = Msg("contentDescBranchInfo", "任意�惱カードを所持してあ�かいなぁ�によって処琂�刲�させます�);
	auto contentDescBranchBeast = Msg("contentDescBranchBeast", "任意�召喚獣を所持してあ�かいなぁ�によって処琂�刲�させます。所持判定において、名前と解説が一致するカード�同一とみなされます。カードを所持してあ�キャラクタは選択状態になります�);
	auto contentDescBranchMoney = Msg("contentDescBranchMoney", "パ�ヂ�が任意�金額を所持してあ�かいなぁ�によって処琂�刲�させます�);
	auto contentDescBranchCoupon = Msg("contentDescBranchCoupon", "キャラクタが任意�クーポン(称号)を所持してあ�かいなぁ�によって処琂�刲�させます。クーポンを所持してあ�キャラクタは選択状態になります�);
	auto contentDescBranchCompleteStamp = Msg("contentDescBranchCompleteStamp", "任意�シナリオに済印がつぁ�あ�かいなぁ�によって処琂�刲�させます�);
	auto contentDescBranchGossip = Msg("contentDescBranchGossip", "任意�ゴシ�(宿全体で所持するクーポン)があるかなぁ�によって処琂�刲�させます�);
	auto contentDescSetFlag = Msg("contentDescSetFlag", "任意�フラグの値を設定します。指定されたフラグを設定してあ�カード�、TRUEに設定した時に表示され、FALSEに設定した時に非表示にされます。背景セルの表示可否は冃�皁�変更され、「画面再構築」コンッ�トなどで背景の再描画を行った時に反映されます�);
	auto contentDescSetStep = Msg("contentDescSetStep", "任意�スッ�プ�値を設定します�);
	auto contentDescSetStepUp = Msg("contentDescSetStepUp", "任意�スッ�プ�値�段階増加させます。すでに段階数の最大に達してあ�場合�何もしません�);
	auto contentDescSetStepDown = Msg("contentDescSetStepDown", "任意�スッ�プ�値�段階減少させます。すでに段階数の最小に達してあ�場合�何もしません�);
	auto contentDescReverseFlag = Msg("contentDescReverseFlag", "任意�フラグの値がTRUEの時�FALSEに、FALSEの時�TRUEに設定します�);
	auto contentDescCheckFlag = Msg("contentDescCheckFlag", "任意�フラグの値がTRUEの時だけ後続�イベントを実行します。メヂ�ージわ�詞�選択肢として使用した場合�、TRUEの時だけ選択肢が表示されます�);
	auto contentDescGetCast = Msg("contentDescGetCast", "任意�キャストをパ�ヂ�に同行させます。すでに同行してあ�場合�何もしません�);
	auto contentDescGetItem = Msg("contentDescGetItem", "任意�アイッ�カードを、キャラクタの所持カードや荷物袋に追�します。所持カードに追�しよぁ�してできなかった�合�、荷物袋に入ります�);
	auto contentDescGetSkill = Msg("contentDescGetSkill", "任意�特殊技能カードを、キャラクタの所持カードや荷物袋に追�します。所持カードに追�しよぁ�してできなかった�合�、荷物袋に入ります�);
	auto contentDescGetInfo = Msg("contentDescGetInfo", "任意�惱カードを入手します。すでに入手済みの場合�何もしません�);
	auto contentDescGetBeast = Msg("contentDescGetBeast", "任意�召喚獣カードを、キャラクタの所持カードや荷物袋に追�します。所持カードに追�しよぁ�してできなかった�合�、荷物袋に入ります�);
	auto contentDescGetMoney = Msg("contentDescGetMoney", "パ�ヂ�の所持�を任意額だけ増加させます�);
	auto contentDescGetCoupon = Msg("contentDescGetCoupon", "任意�クーポン(称号)をキャラクタの経歴に追�します。すでに同一名称のクーポンがある�合�、上書きされます�);
	auto contentDescGetCompleteStamp = Msg("contentDescGetCompleteStamp", "任意�シナリオに済印をつけます�);
	auto contentDescGetGossip = Msg("contentDescGetGossip", "任意�ゴシ�(宿全体で所持するクーポン)を追�します�);
	auto contentDescLoseCast = Msg("contentDescLoseCast", "任意�キャスト�同行を解除します�);
	auto contentDescLoseItem = Msg("contentDescLoseItem", "任意�アイッ�カードを所持カードや荷物袋から削除します。削除対象かどぁ�の判定において、名前と解説が一致するカード�同一と見なされます�);
	auto contentDescLoseSkill = Msg("contentDescLoseSkill", "任意�特殊技能カードを所持カードや荷物袋から削除します。削除対象かどぁ�の判定において、名前と解説が一致するカード�同一と見なされます�);
	auto contentDescLoseInfo = Msg("contentDescLoseInfo", "任意�惱カードを削除します�);
	auto contentDescLoseBeast = Msg("contentDescLoseBeast", "任意�召喚獣カードを所持カードや荷物袋から削除します。削除対象かどぁ�の判定において、名前と解説が一致するカード�同一と見なされます�);
	auto contentDescLoseMoney = Msg("contentDescLoseMoney", "パ�ヂ�の所持�を任意額だけ減少させます�);
	auto contentDescLoseCoupon = Msg("contentDescLoseCoupon", "任意�クーポン(称号)をキャラクタの経歴から除去します�);
	auto contentDescLoseCompleteStamp = Msg("contentDescLoseCompleteStamp", "任意�シナリオの済印を除去します�);
	auto contentDescLoseGossip = Msg("contentDescLoseGossip", "任意�ゴシ�(宿全体で所持するクーポン)を削除します�);
	auto contentDescShowParty = Msg("contentDescShowParty", "�蔽してあ�パ�ヂ�を表示します�);
	auto contentDescHideParty = Msg("contentDescHideParty", "表示中のパ�ヂ�を画面下へ動かして�蔽します�);
	auto contentDescRedisplay = Msg("contentDescRedisplay", "背景を�描画し、フラグ変更などで表示・非表示状態が冃�皁�変更された背景セルの状態を画面に反映します�);
	auto contentDescSubstituteStep = Msg("contentDescSubstituteStep", "任意�スッ�プ�値また�ランダ�な値を別のスッ�プへ代入します�);
	auto contentDescSubstituteFlag = Msg("contentDescSubstituteFlag", "任意�フラグの値また�ランダ�な値を別のフラグへ代入します�);
	auto contentDescBranchStepCmp = Msg("contentDescBranchStepCmp", "任意�2つのスッ�プ�値を比輁�た結果によって処琂�刲�させます�);
	auto contentDescBranchFlagCmp = Msg("contentDescBranchFlagCmp", "任意�2つのフラグの値を比輁�た結果によって処琂�刲�させます�);
	auto contentDescBranchRandomSelect = Msg("contentDescBranchRandomSelect", "パ�ヂ�メンバ�エネミー・同行キャスト�中から任意�条件で選択を行い、�択に成功したか失敗したかによって処琂�刲�させます�);
	auto contentDescBranchKeyCode = Msg("contentDescBranchKeyCode", "キャラクタ・荷物袋�パ�ヂ�全体で任意�キーコードを持つカードを所持してあ�かいなぁ�によって処琂�刲�させます。該当カードを所持してあ�キャラクタは選択状態になります�);
	auto contentDescCheckStep = Msg("contentDescCheckStep", "任意�スッ�プが挮�された状態�時だけ後続�イベントを実行します。メヂ�ージわ�詞�選択肢として使用した場合�、条件を満たす時だけ選択肢が表示されます�);
	auto contentDescBranchRound = Msg("contentDescBranchRound", "現在のバトルのラウンド数が任意�値以上�未満のどちらかによって処琂�刲�させます。バトル中でなぴ合�、常に未満側へ刲�します�);
	auto contentDescMoveBgImage = Msg("contentDescMoveBgImage", "セル名称のつけられた背景セルを移動�サイズ変更します�); // Wsn.1
	auto contentDescReplaceBgImage = Msg("contentDescReplaceBgImage", "セル名称のつけられた背景セルを新しい背景セルに置換します�); // Wsn.1
	auto contentDescLoseBgImage = Msg("contentDescLoseBgImage", "セル名称のつけられた背景セルを削除します�); // Wsn.1
	auto contentDescBranchMultiCoupon = Msg("contentDescBranchMultiCoupon", "選択中のメンバがどのクーポン(称号)を所有してあ�かによって処琂�刲�させます。どれも所有してぁ�ぴ合�「�て所有してぁ�぀�へ刲�します�); // Wsn.2
	auto contentDescBranchMultiRandom = Msg("contentDescBranchMultiRandom", "褕�の後続コンッ�トへ等確玁�ランダ�で刲�します�); // Wsn.2
	auto contentDescWsnN = Msg("contentDescWsnN", "%1$sWsn.%2$s以降�シナリオ形式で使用可能です�);

	auto msnGroupVitality = Msg("msnGroupVitality", "生命�);
	auto msnGroupPhysical = Msg("msnGroupPhysical", "肉�);
	auto msnGroupSkill = Msg("msnGroupSkill", "技能");
	auto msnGroupMental = Msg("msnGroupMental", "精�);
	auto msnGroupMagic = Msg("msnGroupMagic", "魔�);
	auto msnGroupEnhance = Msg("msnGroupEnhance", "能�);
	auto msnGroupVanish = Msg("msnGroupVanish", "消�);
	auto msnGroupCard = Msg("msnGroupCard", "カー�);
	auto msnGroupBeast = Msg("msnGroupBeast", "召�);

	auto msnDelete = Msg("msnDelete", "効果削除");

	auto msnDesc = Msg("msnDesc", "%1$s - %2$s");

	const string motionName(MType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(MType, "motionName"));
	}
	auto motionNameHeal = Msg("motionNameHeal", "回復");
	auto motionNameDamage = Msg("motionNameDamage", "ダメージ");
	auto motionNameAbsorb = Msg("motionNameAbsorb", "吸�);
	auto motionNameParalyze = Msg("motionNameParalyze", "麻痺");
	auto motionNameDisParalyze = Msg("motionNameDisParalyze", "麻痺解除");
	auto motionNamePoison = Msg("motionNamePoison", "中�);
	auto motionNameDisPoison = Msg("motionNameDisPoison", "中毒解除");
	auto motionNameGetSkillPower = Msg("motionNameGetSkillPower", "精神力回復");
	auto motionNameLoseSkillPower = Msg("motionNameLoseSkillPower", "精神力喪失");
	auto motionNameSleep = Msg("motionNameSleep", "睡�状�);
	auto motionNameConfuse = Msg("motionNameConfuse", "混乱状�);
	auto motionNameOverheat = Msg("motionNameOverheat", "激昂状�);
	auto motionNameBrave = Msg("motionNameBrave", "動�状�);
	auto motionNamePanic = Msg("motionNamePanic", "恐�状�);
	auto motionNameNormal = Msg("motionNameNormal", "正常状�);
	auto motionNameBind = Msg("motionNameBind", "呪�);
	auto motionNameDisBind = Msg("motionNameDisBind", "呪縛解除");
	auto motionNameSilence = Msg("motionNameSilence", "沈�);
	auto motionNameDisSilence = Msg("motionNameDisSilence", "沈黙解除");
	auto motionNameFaceUp = Msg("motionNameFaceUp", "暴露");
	auto motionNameFaceDown = Msg("motionNameFaceDown", "暴露解除");
	auto motionNameAntiMagic = Msg("motionNameAntiMagic", "魔法無効�);
	auto motionNameDisAntiMagic = Msg("motionNameDisAntiMagic", "魔法無効化解除");
	auto motionNameEnhanceAction = Msg("motionNameEnhanceAction", "行動力変化");
	auto motionNameEnhanceAvoid = Msg("motionNameEnhanceAvoid", "回避力変化");
	auto motionNameEnhanceDefense = Msg("motionNameEnhanceDefense", "防御力変化");
	auto motionNameEnhanceResist = Msg("motionNameEnhanceResist", "抵抗力変化");
	auto motionNameVanishTarget = Msg("motionNameVanishTarget", "対象消去");
	auto motionNameVanishCard = Msg("motionNameVanishCard", "手札消去");
	auto motionNameVanishBeast = Msg("motionNameVanishBeast", "召喚獣消去");
	auto motionNameDealAttackCard = Msg("motionNameDealAttackCard", "通常攻�);
	auto motionNameDealPowerfulAttackCard = Msg("motionNameDealPowerfulAttackCard", "渾身の一�);
	auto motionNameDealCriticalAttackCard = Msg("motionNameDealCriticalAttackCard", "会�一�);
	auto motionNameDealFeintCard = Msg("motionNameDealFeintCard", "フェイン�);
	auto motionNameDealDefenseCard = Msg("motionNameDealDefenseCard", "防御");
	auto motionNameDealDistanceCard = Msg("motionNameDealDistanceCard", "見��);
	auto motionNameDealConfuseCard = Msg("motionNameDealConfuseCard", "混乱");
	auto motionNameDealSkillCard = Msg("motionNameDealSkillCard", "特殊技能");
	auto motionNameSummonBeast = Msg("motionNameSummonBeast", "召喚獣召�);
	auto motionNameCancelAction = Msg("motionNameCancelAction", "行動キャンセル"); // CardWirth 1.50

	const string motionDesc(MType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(MType, "motionDesc"));
	}
	auto motionDescHeal = Msg("motionDescHeal", "対象の生命点を増加させます�);
	auto motionDescDamage = Msg("motionDescDamage", "対象の生命点を減少させます�);
	auto motionDescAbsorb = Msg("motionDescAbsorb", "対象の生命点を減少させた刁�け使用�生命点を回復させます�);
	auto motionDescParalyze = Msg("motionDescParalyze", "対象を麻痺させます。麻痺の値�0を趁�た�合�石化扱ぁ�なります。麻痺の最大値は40です。�員が麻痺状態になった�合�全滁�ます�);
	auto motionDescDisParalyze = Msg("motionDescDisParalyze", "対象の麻痺を緩和します�);
	auto motionDescPoison = Msg("motionDescPoison", "対象を中毒状態にします。中毒状態�キャラクタは時間経過でダメージを受けます。中毒�最大値は40です�);
	auto motionDescDisPoison = Msg("motionDescDisPoison", "対象の中毒を緩和します�);
	auto motionDescGetSkillPower = Msg("motionDescGetSkillPower", "対象の特殊技能の使用回数を増加させます�);
	auto motionDescLoseSkillPower = Msg("motionDescLoseSkillPower", "対象の特殊技能の使用回数を減少させます�);
	auto motionDescSleep = Msg("motionDescSleep", "対象を睡�状態にします。睡�状態�キャラクタは、行動・回避・抵抗ができなくなります�);
	auto motionDescConfuse = Msg("motionDescConfuse", "対象を混乱状態にします。混乱状態�キャラクタは、手札に「混乱」が配付されます�);
	auto motionDescOverheat = Msg("motionDescOverheat", "対象を激昂状態にします。激昂状態�キャラクタは、手札に「渾身の一撀�が配付されます�);
	auto motionDescBrave = Msg("motionDescBrave", "対象を勇敢状態にします。勇敢状態�キャラクタは、手札に「防御」「見�り」が配付されなくなります�);
	auto motionDescPanic = Msg("motionDescPanic", "対象を恐慌状態にします。恐慌状態�キャラクタは、手札に「防御」「見�り」だけが配付されます�);
	auto motionDescNormal = Msg("motionDescNormal", "対象の精神状態を通常に戻します�);
	auto motionDescBind = Msg("motionDescBind", "対象を呪縛します。呪縛されたキャラクタは、行動・回避ができなくなります�);
	auto motionDescDisBind = Msg("motionDescDisBind", "対象の呪縛を解除します�);
	auto motionDescSilence = Msg("motionDescSilence", "対象を沈黙状態にします。沈黙状態�キャラクタは、発声が忦�なカードを使用できなくなります�);
	auto motionDescDisSilence = Msg("motionDescDisSilence", "対象の沈黙状態を解除します�);
	auto motionDescFaceUp = Msg("motionDescFaceUp", "対象を暴露状態にします。暴露状態�キャラクタは、そのス�タスガ�ラウンド�行動を見る事ができます�);
	auto motionDescFaceDown = Msg("motionDescFaceDown", "対象の暴露状態を解除します�);
	auto motionDescAntiMagic = Msg("motionDescAntiMagic", "対象を魔法無効化状態にします。魔法無効化状態�キャラクタは魔法�物琚�魔法属性の効果を受けなくなり、これらの属性のカードを使用できなくなります�);
	auto motionDescDisAntiMagic = Msg("motionDescDisAntiMagic", "対象の魔法無効化状態を解除します�);
	auto motionDescEnhanceAction = Msg("motionDescEnhanceAction", "対象の行動力を変化させます。行動力�増減�行動の成功判定や能力判定�結果に影響します�);
	auto motionDescEnhanceAvoid = Msg("motionDescEnhanceAvoid", "対象の回避力を変化させます。回避力�増減�効果�回避判定�結果に影響します�10の場合�忁�回避が�功します�10の場合�忁�失敗します�);
	auto motionDescEnhanceDefense = Msg("motionDescEnhanceDefense", "対象の防御力を変化させます。防御力�増減�ダメージ計算�結果に影響します�10の場合�ダメージを受けません�10の場合�3倍�ダメージを受けます�);
	auto motionDescEnhanceResist = Msg("motionDescEnhanceResist", "対象の抵抗力を変化させます。抵抗力の増減�効果への抵抗判定�結果に影響します�10の場合�忁�抵抗が成功します�10の場合�忁�失敗します�);
	auto motionDescVanishTarget = Msg("motionDescVanishTarget", "対象を消去します。消去されたキャラクタが戻ってくる事�ありません�);
	auto motionDescVanishCard = Msg("motionDescVanishCard", "対象の手札を消去します。対象は、次のラウンドで消去された��け山札からカードを引きます�);
	auto motionDescVanishBeast = Msg("motionDescVanishBeast", "対象が所持する召喚獣を消去します。付帯能�召喚獣召喚効果以外で付与された召喚獣カー�は消去されません�);
	auto motionDescDealAttackCard = Msg("motionDescDealAttackCard", "対象の山札の一番上に「攻撀�を配付します�);
	auto motionDescDealPowerfulAttackCard = Msg("motionDescDealPowerfulAttackCard", "対象の山札の一番上に「渾身の一撀�を配付します�);
	auto motionDescDealCriticalAttackCard = Msg("motionDescDealCriticalAttackCard", "対象の山札の一番上に「会�一撀�を配付します�);
	auto motionDescDealFeintCard = Msg("motionDescDealFeintCard", "対象の山札の一番上に「フェイント」を配付します�);
	auto motionDescDealDefenseCard = Msg("motionDescDealDefenseCard", "対象の山札の一番上に「防御」を配付します。「防御」を選択したキャラクタは抵抗力が増加し、受けるダメージが減少します�);
	auto motionDescDealDistanceCard = Msg("motionDescDealDistanceCard", "対象の山札の一番上に「見�り」を配付します。「見�り」を選択したキャラクタは回避力が増加します�);
	auto motionDescDealConfuseCard = Msg("motionDescDealConfuseCard", "対象の山札の一番上に「混乱」を配付します。「混乱」を選択したキャラクタは、�択したラウンド中の行動・回避・抵抗ができなくなります�);
	auto motionDescDealSkillCard = Msg("motionDescDealSkillCard", "対象の山札の一番上に、対象が使用できる特殊技能カードを配付します。使用回数が尽きてあ�場合�配付されません�);
	auto motionDescSummonBeast = Msg("motionDescSummonBeast", "対象に任意�召喚獣カードを付与します�);
	auto motionDescCancelAction = Msg("motionDescCancelAction", "対象の現在のラウンド�行動をキャンセルします。すでに行動済みの場合�何もしません�); // CardWirth 1.50

	auto dialogText = Msg("dialogText", "%2$s: %1$s");
	auto dialogTextNoCoupon = Msg("dialogTextNoCoupon", "%1$s");

	auto ctStart = Msg("ctStart", "スタートコンッ�ト�1$s�);
	auto ctStartBattle = Msg("ctStartBattle", "バトルの開始�1$s�);
	auto ctChangeArea = Msg("ctChangeArea", "エリア移動�1$s�创�方�= %2$s ウェイ�= %3$s");
	auto ctChangeAreaClassic = Msg("ctChangeAreaClassic", "エリア移動�1$s�);
	auto ctEndComplete = Msg("ctEndComplete", "済印をつけて終�);
	auto ctEndNoComplete = Msg("ctEndNoComplete", "済印をつけずに終�);
	auto ctGameOver = Msg("ctGameOver", "敗北・ゲー�オーバ�コンッ��);
	auto ctChangeBgImage = Msg("ctChangeBgImage", "背景ファイル = %1$s 创�方�= %2$s ウェイ�= %3$s");
	auto ctChangeBgImageClassic = Msg("ctChangeBgImageClassic", "背景ファイル = %1$s");
	auto ctChangeBgImageFile = Msg("ctChangeBgImageFile", "[%1$s]");
	auto ctEffectSound = Msg("ctEffectSound", "�1$s」を再生");
	auto ctEffectNoSound = Msg("ctEffectNoSound", "音声無�);
	auto ctEffect = Msg("ctEffect", "%1$s レベル%2$s %3$s/%4$s 成功�5$s%6$s %7$s %8$s 効�= %9$s %10$s %11$s");
	auto ctEffectRefAbility = Msg("ctEffectRefAbility", "%1$s %2$s/%3$s 成功�4$s%5$s %6$s %7$s 効�= %8$s 参�能�= %9$sと%10$s %11$s %12$s");
	auto ctEffectMotion = Msg("ctEffectMotion", "[%1$s]");
	auto ctKeyCodes = Msg("ctKeyCodes", "キーコー�= %1$s");
	auto ctNoKeyCode = Msg("ctNoKeyCode", "キーコード無�);
	auto ctEffectBreak = Msg("ctEffectBreak", "効果中断コンッ��);
	auto ctLinkStart = Msg("ctLinkStart", "スタートコンッ�ト�1$s」へのリンク");
	auto ctLinkPackage = Msg("ctLinkPackage", "パッケージ�1$s」へのリンク");
	auto ctTalkMessageImage = Msg("ctTalkMessageImage", "[%1$s]");
	auto ctTalkMessage = Msg("ctTalkMessage", "%1$s: %2$s");
	auto ctTalkMessageWithAttrs = Msg("ctTalkMessageWithAttrs", "%1$s: %2$s (%3$s)");
	auto ctTalkMessageNarration = Msg("ctTalkMessageNarration", "%1$s");
	auto ctTalkMessageNarrationWithAttrs = Msg("ctTalkMessageNarrationWithAttrs", "%1$s (%2$s)");
	auto ctTalkDialog = Msg("ctTalkDialog", "%1$s %2$s: %3$s");
	auto ctTalkDialogWithAttrs = Msg("ctTalkDialogWithAttrs", "%1$s %2$s: %3$s (%4$s)");
	auto ctTalkDialogNoCoupon = Msg("ctTalkDialogNoCoupon", "%1$s: %2$s");
	auto ctTalkDialogNoCouponWithAttrs = Msg("ctTalkDialogNoCouponWithAttrs", "%1$s: %2$s (%3$s)");
	auto ctColumns = Msg("ctColumns", "%1$s列�選択肢");
	auto ctPlayBGM = Msg("ctPlayBGM", "BGMとして�1$s」を演�Ch. = %2$s フェードイン時間 = %3$s �0.1�音�= %4$s%% ループ回数 = %5$s");
	auto ctStopBGM = Msg("ctStopBGM", "BGM停止 Ch. = %1$s フェードアウト時�= %2$s �0.1�);
	auto ctPlaySound = Msg("ctPlaySound", "効果音�1$s」を鳴らす Ch. = %2$s フェードイン時間 = %3$s �0.1�音�= %4$s%% ループ回数 = %5$s");
	auto ctWait = Msg("ctWait", "空白時間 = %1$s �0.1�);
	auto ctElapseTime = Msg("ctElapseTime", "ターン数経過コンッ��);
	auto ctCallStart = Msg("ctCallStart", "スタートコンッ�ト�1$s」�コール");
	auto ctCallPackage = Msg("ctCallPackage", "パッケージ�1$s」�コール");
	auto ctBranchFlag = Msg("ctBranchFlag", "フラグ�1$s」�値で刲);
	auto ctBranchMultiStep = Msg("ctBranchMultiStep", "スッ�プ�1$s」�値で刲);
	auto ctBranchStep = Msg("ctBranchStep", "スッ�プ�1$s」�値が[%2$s]以上�未満で刲);
	auto ctBranchSelectAll = Msg("ctBranchSelectAll", "パ�ヂ�全員");
	auto ctBranchSelectActive = Msg("ctBranchSelectActive", "動けるメン�);
	auto ctBranchSelectAuto = Msg("ctBranchSelectAuto", "ランダ�");
	auto ctBranchSelectManual = Msg("ctBranchSelectManual", "手動");
	auto ctBranchSelectValued = Msg("ctBranchSelectValued", "評価条件(%1$s)");
	auto initialValue = Msg("initialValue", "初期値 = %1$s");
	auto couponValues = Msg("couponValues", "%1$s = %2$s");
	auto ctBranchSelect = Msg("ctBranchSelect", "%1$sから%2$sでメンバを選�);
	auto ctBranchAbility = Msg("ctBranchAbility", "%1$s(%2$s)の%3$sと%4$sで能力判�レベル%5$s)");
	auto ctBranchRandom = Msg("ctBranchRandom", "確�= %1$s%%");
	auto ctBranchLevelAverage = Msg("ctBranchLevelAverage", "パ�ヂ�全員");
	auto ctBranchLevelSelected = Msg("ctBranchLevelSelected", "選択中のメン�);
	auto ctBranchLevel = Msg("ctBranchLevel", "%1$sのレベル�2$s以上�未満で刲);
	auto ctBranchStatus = Msg("ctBranchStatus", "%1$s�2$s状態か否かで刲);
	auto ctBranchPartyNumber = Msg("ctBranchPartyNumber", "人数 = %1$s人");
	auto ctBranchArea = Msg("ctBranchArea", "エリア刲�コンッ��);
	auto ctBranchBattle = Msg("ctBranchBattle", "バトル刲�コンッ��);
	auto ctBranchIsBattle = Msg("ctBranchIsBattle", "戦闘中判定�岐コンッ��);
	auto ctBranchCast = Msg("ctBranchCast", "キャストカード�1$s」�同行有無で刲);
	auto ctBranchSkill = Msg("ctBranchSkill", "特殊技能カード�1$s」�有無で刲%2$sに%3$s�");
	auto ctBranchItem = Msg("ctBranchItem", "アイッ�カード�1$s」�有無で刲%2$sに%3$s�");
	auto ctBranchBeast = Msg("ctBranchBeast", "召喚獣カード�1$s」�有無で刲%2$sに%3$s�");
	auto ctBranchInfo = Msg("ctBranchInfo", "惱カード�1$s」�有無で刲);
	auto ctBranchMoney = Msg("ctBranchMoney", "刲����= %1$ssp");
	auto ctBranchCoupon = Msg("ctBranchCoupon", "称号�1$s」�有無で刲%2$s)");
	auto ctBranchCouponMulti = Msg("ctBranchCouponMulti", "称号%1$sの%2$sの有無で刲%3$s)"); // Wsn.2
	auto ctBranchCompleteStamp = Msg("ctBranchCompleteStamp", "シナリオ�1$s」が終亸�みか否かで刲);
	auto ctBranchGossip = Msg("ctBranchGossip", "ゴシ��1$s」�有無で刲);
	auto ctSetFlag = Msg("ctSetFlag", "フラグ�1$s」を[%2$s]に変更");
	auto ctSetStep = Msg("ctSetStep", "スッ�プ�1$s」を[%2$s]に変更");
	auto ctSetStepUp = Msg("ctSetStepUp", "スッ�プ�1$s」�値�増加");
	auto ctSetStepDown = Msg("ctSetStepDown", "スッ�プ�1$s」�値�減�);
	auto ctReverseFlag = Msg("ctReverseFlag", "フラグ�1$s」�値を反転");
	auto ctCheckFlag = Msg("ctCheckFlag", "フラグ�1$s」�値が[%2$s]であれば後続�イベントが出現");
	auto ctGetCast = Msg("ctGetCast", "キャストカード�1$s」を同行させる(%2$s)");
	auto ctGetSkill = Msg("ctGetSkill", "特殊技能カード�1$s」を獲�%2$sに%3$s�");
	auto ctGetItem = Msg("ctGetItem", "アイッ�カード�1$s」を獲�%2$sに%3$s�");
	auto ctGetBeast = Msg("ctGetBeast", "召喚獣カード�1$s」を獲�%2$sに%3$s�");
	auto ctGetInfo = Msg("ctGetInfo", "惱カード�1$s」を獲�);
	auto ctGetMoney = Msg("ctGetMoney", "獲得���= %1$ssp");
	auto ctGetCoupon = Msg("ctGetCoupon", "称号�1$s(%2$s)」を獲�%3$s)");
	auto ctGetCompleteStamp = Msg("ctGetCompleteStamp", "シナリオ�1$s」を終亸�みにする");
	auto ctGetGossip = Msg("ctGetGossip", "ゴシ��1$s」を獲�);
	auto ctLoseCardAll = Msg("ctLoseCardAll", "全て");
	auto ctLoseCardCount = Msg("ctLoseCardCount", "%1$s�);
	auto ctLoseCast = Msg("ctLoseCast", "キャストカード�1$s」�同行を解除");
	auto ctLoseSkill = Msg("ctLoseSkill", "特殊技能カード�1$s」を喪失(%2$sから%3$s)");
	auto ctLoseItem = Msg("ctLoseItem", "アイッ�カード�1$s」を喪失(%2$sから%3$s)");
	auto ctLoseBeast = Msg("ctLoseBeast", "召喚獣カード�1$s」を喪失(%2$sから%3$s)");
	auto ctLoseInfo = Msg("ctLoseInfo", "惱カード�1$s」を喪失");
	auto ctLoseMoney = Msg("ctLoseMoney", "喪失金�= %1$ssp");
	auto ctLoseCoupon = Msg("ctLoseCoupon", "称号�1$s」を喪失(%2$s)");
	auto ctLoseCompleteStamp = Msg("ctLoseCompleteStamp", "シナリオ%1$sの終亍�を削除");
	auto ctLoseGossip = Msg("ctLoseGossip", "ゴシ��1$s」を喪失");
	auto ctShowParty = Msg("ctShowParty", "パ�ヂ�表示コンッ��);
	auto ctHideParty = Msg("ctHideParty", "パ�ヂ��蔽コンッ��);
	auto ctRedisplay = Msg("ctRedisplay", "创�方�= %1$s ウェイ�= %2$s");
	auto ctRedisplayClassic = Msg("ctRedisplayClassic", "画面再構築コンッ��);
	auto ctSubstituteStep = Msg("ctSubstituteStep", "スッ��[%1$s] の値をスッ��[%2$s] に代入");
	auto ctSubstituteFlag = Msg("ctSubstituteFlag", "フラグ [%1$s] の値をフラグ [%2$s] に代入");
	auto ctBranchStepCmp = Msg("ctBranchStepCmp", "スッ��[%1$s] と [%2$s] の値を比�);
	auto ctBranchFlagCmp = Msg("ctBranchFlagCmp", "フラグ [%1$s] と [%2$s] の値を比�);
	auto ctSubstituteStepFromRandom = Msg("ctSubstituteStepFromRandom", "ランダ�値をスッ��[%1$s] に代入");
	auto ctSubstituteFlagFromRandom = Msg("ctSubstituteFlagFromRandom", "ランダ�値をフラグ [%1$s] に代入");
	auto randomValue = Msg("randomValue", "ランダ�値");
	auto ctRandomSelect = Msg("ctRandomSelect", "%2$sのキャラクタを選�%1$s)");
	auto ctRandomSelectN = Msg("ctRandomSelectN", "キャラクタを選�%1$s)");
	auto castRange0 = Msg("castRange0", "対象無�);
	auto castRange1 = Msg("castRange1", "%1$s全�);
	auto castRange2 = Msg("castRange2", "%1$s全体また�%2$s全�);
	auto castRange3 = Msg("castRange3", "フィールド��);
	auto ctBranchKeyCodeAllType = Msg("ctBranchKeyCodeAllType", "キーコード�1$s」を含むカード�有無で刲%2$s)");
	auto ctBranchKeyCode = Msg("ctBranchKeyCode", "キーコード�1$s」を含む%2$sの有無で刲%3$s)");
	auto ctCheckStep = Msg("ctCheckStep", "スッ�プ�1$s」が[%2$s]%3$s後続�イベントが出現");
	auto ctBranchRound = Msg("ctBranchRound", "バトル�1$sラウン�2$sか否かで刲);
	auto ctMoveAndResizeBgImage = Msg("ctMoveAndResizeBgImage", "背景�1$s」を%2$sで右へ%3$s、下へ%4$sポイント移動し�5$sで%6$s�7$sにリサイズ(创�方�= %8$s ウェイ�= %9$s)");
	auto ctMoveBgImage = Msg("ctMoveBgImage", "背景�1$s」を%2$sで右へ%3$s、下へ%4$sポイント移�创�方�= %5$s ウェイ�= %6$s)");
	auto ctResizeBgImage = Msg("ctResizeBgImage", "背景�1$s」を%2$sで%3$s�4$sにリサイズ(创�方�= %5$s ウェイ�= %6$s)");
	auto ctMoveAndResizeBgImageClassic = Msg("ctMoveAndResizeBgImageClassic", "背景�1$s」を%2$sで右へ%3$s、下へ%4$sポイント移動し�5$sで%6$s�7$sにリサイズ");
	auto ctMoveBgImageClassic = Msg("ctMoveBgImageClassic", "背景�1$s」を%2$sで右へ%3$s、下へ%4$sポイント移�);
	auto ctResizeBgImageClassic = Msg("ctResizeBgImageClassic", "背景�1$s」を%2$sで%3$s�4$sにリサイズ");
	auto ctMoveBgImageNoSet = Msg("ctMoveBgImageNoSet", "背景�1$s」に対して何も行わな�);
	auto ctReplaceBgImage = Msg("ctReplaceBgImage", "背景�1$s」を置�背景ファイル = %2$s 创�方�= %3$s ウェイ�= %4$s)");
	auto ctReplaceBgImageClassic = Msg("ctReplaceBgImageClassic", "背景�1$s」を置�背景ファイル = %2$s)");
	auto ctLoseBgImage = Msg("ctLoseBgImage", "背景�1$s」を削除(创�方�= %2$s ウェイ�= %3$s)");
	auto ctLoseBgImageClassic = Msg("ctLoseBgImageClassic", "背景�1$s」を削除");
	auto ctBranchMultiCoupon = Msg("ctBranchMultiCoupon", "%1$sの称号所有状態で刲); // Wsn.2
	auto ctBranchMultiRandom = Msg("ctBranchMultiRandom", "ランダ�多岐�岐コンッ��); // Wsn.2
	auto couponNames = Msg("couponNames", "�1$s�); // Wsn.2
	auto couponNamesSeparator = Msg("couponNamesSeparator", ""); // Wsn.2
	auto matchingTypeAnd = Msg("matchingTypeAnd", "全て"); // Wsn.2
	auto matchingTypeOr = Msg("matchingTypeOr", "どれか一つ"); // Wsn.2

	auto nameWithID = Msg("nameWithID", "%1$s.%2$s");

	auto defaultStartName = Msg("defaultStartName", "イベント開�);

	auto oggMayNotCorrespond = Msg("oggMayNotCorrespond", "Oggはプレイヤーの環墁�よって再生できなぺ�があります�);
	auto mp3LoopMayNotCorrespond = Msg("mp3LoopMayNotCorrespond", "MP3はプレイヤーの環墁�よってループ�生されなぺ�があります�);

	auto playingOption = Msg("playingOption", "再生オプション"); // Wsn.1
	auto playingVolume = Msg("playingVolume", "音�); // Wsn.1
	auto playingVolumePer = Msg("playingVolumePer", "%"); // Wsn.1
	auto loopCount = Msg("loopCount", "ループ回数"); // Wsn.1
	auto loopCountHint = Msg("loopCountHint", "(0 = �"); // Wsn.1
	auto playingChannel = Msg("playingChannel", "Ch."); // Wsn.1
	auto mainChannel = Msg("mainChannel", "主音声"); // Wsn.1
	auto subChannel = Msg("subChannel", "副音声"); // Wsn.1
	auto fadeIn = Msg("fadeIn", "フェードイン時間"); // Wsn.1
	auto fadeInHint = Msg("fadeInHint", "�0.1�); // Wsn.1
	auto warningVolume = Msg("warningVolume", "音量�設定�Wsn.1以降�形式�シナリオしか使用できません�); // Wsn.1
	auto warningLoopCount = Msg("warningLoopCount", "ループ回数の設定�Wsn.1以降�形式�シナリオしか使用できません�); // Wsn.1
	auto warningChannel= Msg("warningChannel", "再生チャンネルの設定�Wsn.1以降�形式�シナリオしか使用できません�); // Wsn.1
	auto warningFadeIn = Msg("warningFadeIn", "フェードイン時間の設定�Wsn.1以降�形式�シナリオしか使用できません�); // Wsn.1

	/// メインウィンドウ�	auto mainWindowName = Msg("mainWindowName", "%1$s [ %2$s ] - CWXEditor");
	auto mainWindowNameChanged = Msg("mainWindowNameChanged", "*%1$s [ %2$s ] - CWXEditor");
	auto mainWindowNameEmpty = Msg("mainWindowNameEmpty", "CWXEditor");
	auto errorExecEngine = Msg("errorExecEngine", "%1$sの起動に失敗しました�);

	/// シナリオ選択ダイアログ
	auto dlgTitNewScenario = Msg("dlgTitNewScenario", "新規シナリオの作�");
	auto dlgTitNewScenarioAtNewWin = Msg("dlgTitNewScenarioAtNewWin", "新しいウィンドウで新規シナリオの作�");
	auto dlgTitOpenScenario = Msg("dlgTitOpenScenario", "シナリオを開�);
	auto dlgTitOpenScenarioAtNewWin = Msg("dlgTitOpenScenarioAtNewWin", "新しいウィンドウでシナリオを開�);
	auto filterScenario = Msg("filterScenario", "シナリオファイル (%1$s)");
	auto filterParts = Msg("filterParts", "エリア・カードファイル (%1$s)");
	auto dlgTitSaveScenario = Msg("dlgTitSaveScenario", "名前を付けて保�);
	auto filterScenarioSave = Msg("filterScenarioSave", "XML形式�シナリオ (*.wsn)");
	auto filterScenarioSaveDir = Msg("filterScenarioSaveDir", "展開されたXML形式シナリオ (Summary.xml)");
	auto filterScenarioSaveClassic = Msg("filterScenarioSaveClassic", "クラシヂ�シナリオ (Summary.wsm)");
	auto filterScenarioSaveZip = Msg("filterScenarioSaveZip", "ZIP圧縮されたクラシヂ�シナリオ (*.zip)");
	auto filterScenarioSaveCab = Msg("filterScenarioSaveCab", "CAB圧縮されたクラシヂ�シナリオ (*.cab)");
	auto warningXToClassic = Msg("warningXToClassic", "XML形式�シナリオをクラシヂ�形式に変換すると一部�タが失われる可能性がある他、対応してぁ�ぽ�式��材で不�合が発生する恐れがあります�nクラシヂ�形式で保存しますか);
	auto saveToNotEmptyDir = Msg("saveToNotEmptyDir", "%1$sは空ではありません�n本当にここにシナリオを保存しますか);
	auto notScenario = Msg("notScenario", "%1$sはシナリオ圧縮ファイルではありません");
	auto zipError = Msg("zipError", "%1$sの展開に失敗しました�);
	auto loadError = Msg("loadError", "%1$sの読込みに失敗しました�);
	auto saveError = Msg("saveError", "%1$sの保存に失敗しました�);
	auto loadErrorStatus = Msg("loadErrorStatus", "%1$sの読込みに失�);
	auto loadErrorStatusCount = Msg("loadErrorStatusCount", "%1$s件のシナリオの読込みに失�);
	auto scenarioNotFound = Msg("scenarioNotFound", "%1$sは存在しなぁ�、シナリオではありません。履歴から削除しますか);

	/// �タウィンドウ
	auto areasTabName = Msg("areasTabName", "�ブル");
	auto areaStatus = Msg("areaStatus", "%2$s件の%1$s");
	auto flagTabName = Msg("flagTabName", "状態変数");
	auto flagStatus = Msg("flagStatus", "%2$s個�%1$s");
	auto flagStatusSel = Msg("flagStatusSel", "%1$s (%2$s個を選�");
	auto scenarioView = Msg("scenarioView", "シナリオビューリス�);
	auto variableView = Msg("variableView", "状態変数インスペクタ");

	auto reNumberingAll = Msg("reNumberingAll", "全てのエリアも�ード�IDの1から振り直します�nよろしいですか);

	auto dlgTitReNumbering = Msg("dlgTitReNumbering", "IDの振り直�);
	auto reNumbering = Msg("reNumbering", "IDの振り直�);
	auto reNumbering1 = Msg("reNumbering1", "%1$s�2$s」以降�ID�);
	auto reNumbering2 = Msg("reNumbering2", "番から頁�振り直�); // reNumbering1と同様�パラメータを取�
	/// エリアの�ブル�	auto areaDirRoot = Msg("areaDirRoot", "Scenario");
	auto areaDirNew = Msg("areaDirNew", "新規フォルダ");
	auto areaId = Msg("areaId", "ID");
	auto areaName = Msg("areaName", "名称");
	auto areaCount = Msg("areaCount", "利用数");
	auto areaNew = Msg("areaNew", "新規エリア");
	auto battleNew = Msg("battleNew", "新規バトル");
	auto packageNew = Msg("packageNew", "新規パヂ�ージ");

	/// フラグのヂ�レクトリ�	auto flagDirRoot = Msg("flagDirRoot", "Data");
	auto flagDirNew = Msg("flagDirNew", "新規フォルダ");

	/// フラグ/スッ�プ��ブル�	auto flagName = Msg("flagName", "名称");
	auto flagInit = Msg("flagInit", "初期値");
	auto flagCount = Msg("flagCount", "利用数");

	/// フラグ設定ダイアログ関連�	auto dlgTitFlag = Msg("dlgTitFlag", "フラグの設�);
	auto dlgLblFlagName = Msg("dlgLblFlagName", "フラグ�);
	auto dlgLblFlagInit = Msg("dlgLblFlagInit", "初期値");
	auto dlgLblFlagTrue = Msg("dlgLblFlagTrue", "TRUE");
	auto dlgLblFlagFalse = Msg("dlgLblFlagFalse", "FALSE");

	/// スッ�プ設定ダイアログ関連�	auto dlgTitStep = Msg("dlgTitStep", "スッ�プ�設�);
	auto dlgLblStepName = Msg("dlgLblStepName", "スッ�プ名");
	auto dlgLblStepInit = Msg("dlgLblStepInit", "初期値");
	auto dlgTxtStep = Msg("dlgTxtStep", "Step - %1$s");
	auto stepCount = Msg("stepCount", "段階数");

	/// 貼紙設定ダイアログ関連�	auto dlgTitSummary = Msg("dlgTitSummary", "概略の設�- [ %1$s ]");
	auto summaryPreview = Msg("summaryPreview", "表示イメージ");
	auto baseData = Msg("baseData", "基本�タ");
	auto etcData = Msg("etcData", "詳細�タ");
	auto targetLevelSame = Msg("targetLevelSame", "対象レベル %1$s");
	auto targetLevelHL = Msg("targetLevelHL", "対象レベル %1$s2$s");
	auto targetLevelL = Msg("targetLevelL", "対象レベル %1$s);
	auto targetLevelH = Msg("targetLevelH", "対象レベル 1$s");
	auto summaryPageDummy = Msg("summaryPageDummy", "1/1");
	auto title = Msg("title", "シナリオタイトル");
	auto author = Msg("author", "作耐�");
	auto targetLevel = Msg("targetLevel", "対象レベル");
	auto desc = Msg("desc", "解説");
	auto levSep = Msg("levSep", ");
	auto qualification = Msg("qualification", "シナリオ出現条件");
	auto rCouponNum = Msg("rCouponNum", "忦�数");
	auto rCoupons = Msg("rCoupons", "忦�とする称号");
	auto startArea = Msg("startArea", "シナリオ開始エリア");

	auto scenarioType = Msg("scenarioType", "シナリオタイ�);
	auto sTypeXML = Msg("sTypeXML", "スキンを指�);
	auto sTypeClassic = Msg("sTypeClassic", "クラシヂ�エンジンを使用");

	auto dataVersion = Msg("dataVersion", "�タバ�ジョン");
	auto dataVersionName = Msg("dataVersionName", "%1$s - %2$s");

	auto loadScaledImage = Msg("loadScaledImage", "スケーリングされたイメージを使用する");
	auto loadScaledImageHint = Msg("loadScaledImageHint", "\"image.bmp\"とぁ�名前のファイル�倍スケールで表示する時、\n\"image.x2.bmp\"があれ�代わりに表示しま�);

	auto pngMayNotCorrespond = Msg("pngMayNotCorrespond", "PNGイメージはプレイヤーの環墁�よって表示エラーとなる事があります�);
	auto gifMayNotCorrespond = Msg("gifMayNotCorrespond", "GIFイメージはプレイヤーの環墁�よって表示エラーとなる事があります�);

	/// エリア・戦闘�パッケージウィンドウ�	auto noRefArea = Msg("noRefArea", "カード�置参�無�);
	auto areaViewFlagDesc = Msg("areaViewFlagDesc", "フラグ");
	auto areaViewRefAreaDesc = Msg("areaViewRefAreaDesc", "参�");
	auto refFlags = Msg("refFlags", "参�フラグ");
	auto allCheckFlag = Msg("allCheckFlag", "全てTRUE/全てFALSE");

	auto left = Msg("left", "X");
	auto top = Msg("top", "Y");
	auto width = Msg("width", "�);
	auto height = Msg("height", "�);
	auto scale = Msg("scale", "拡大�);
	auto scalePer = Msg("scalePer", "%");
	auto layer = Msg("layer", "レイヤ");
	auto layerHint = Msg("layerHint", "(標�= %1$s)");
	auto bgImageForeground = Msg("bgImageForeground", "カードよりも前に表示");
	auto bgImageCellName = Msg("bgImageCellName", "セル名称");

	auto areaViewStatus = Msg("areaViewStatus", "%1$s [%2$s] - %3$s");
	auto areaViewStatusNoSummary = Msg("areaViewStatusNoSummary", "%1$s [%2$s]");
	auto areaViewStatusNoFlag = Msg("areaViewStatusNoFlag", "フラグ挮�無�);
	auto areaViewStatusInvalidFlag = Msg("areaViewStatusInvalidFlag", "存在しなぃ�ラグ(%1$s)");
	auto areaViewStatusWithFlag = Msg("areaViewStatusWithFlag", "フラグ = %1$s");
	auto areaViewStatusImageIncluding = Msg("areaViewStatusImageIncluding", "イメージ格�);
	auto areaViewStatusSelCard = Msg("areaViewStatusSelCard", "%1$s枚�カー�);
	auto areaViewStatusSelBack = Msg("areaViewStatusSelBack", "%1$s枚�背景");
	auto areaViewStatusEnemyCard = Msg("areaViewStatusEnemyCard", "%1$s.%2$s");

	auto viewNameSceneTab = Msg("viewNameSceneTab", "%2$s.%3$s");
	auto viewNameEventTab = Msg("viewNameEventTab", "%2$s.%3$s");

	auto cardCount = Msg("cardCount", "利用数");

	auto cardAndBackView = Msg("cardAndBackView", "カードと背景");
	auto enemyCardView = Msg("enemyCardView", "エネミーカー�);
	auto menuCards = Msg("menuCards", "カー�);
	auto enemyCards = Msg("enemyCards", "カー�);
	auto backs = Msg("backs", "背景");
	auto eventView = Msg("eventView", "イベン�);
	auto menuCard = Msg("menuCard", "メニューカー�);
	auto enemyCard = Msg("enemyCard", "エネミーカー�);
	auto back = Msg("back", "背景画�);
	auto textCell = Msg("textCell", "ヂ�ストセル");
	auto colorCell = Msg("colorCell", "カラーセル");
	auto pcCell = Msg("pcCell", "プレイヤーキャラクタセル");
	auto pcCellNoSet = Msg("pcCellNoSet", "(挮�無�");
	auto cellPCNumber = Msg("cellPCNumber", "表示するキャラクタ");
	auto cellNoSet = Msg("cellNoSet", "(挮�無�");

	auto nameWithCellName = Msg("nameWithCellName", "[%1$s] %2$s");

	/// カー�背景配置領域関連�	auto dlgTitDropCard = Msg("dlgTitDropCard", "カード画像�追�");
	auto dlgMsgDropCard = Msg("dlgMsgDropCard", "カード画像をシナリオ" ~ DIR ~ "にコピ�しますか�\n%1$s");
	auto dlgTitDropBack = Msg("dlgTitDropBack", "背景画像�追�");
	auto dlgMsgDropBack = Msg("dlgMsgDropBack", "背景画像をシナリオ" ~ DIR ~ "にコピ�しますか�\n%1$s");

	auto refFlag = Msg("refFlag", "フラグ参��);
	auto refStep = Msg("refStep", "スッ�プ参照�);
	auto noFlagRef = Msg("noFlagRef", "参�無�);
	auto cardPosition = Msg("cardPosition", "カード位置");
	auto backPosition = Msg("backPosition", "配置");
	auto bgImageSettings = Msg("bgImageSettings", "簡単設�);
	auto bgImageSettingCustom = Msg("bgImageSettingCustom", "カスタ�");
	auto bgImageSettingOriginal = Msg("bgImageSettingOriginal", "�サイズ");
	auto enemyCardBase = Msg("enemyCardBase", "基本設�);
	auto dlgTitMenuCard = Msg("dlgTitMenuCard", "メニューカード�設�[ %1$s ]");
	auto dlgTitNewMenuCard = Msg("dlgTitNewMenuCard", "メニューカード�作�");
	auto dlgTitBgImage = Msg("dlgTitBgImage", "背景画像�設�);
	auto dlgTitNewBgImage = Msg("dlgTitNewBgImage", "背景画像�作�");
	auto dlgTitTextCell = Msg("dlgTitTextCell", "ヂ�ストセルの設�);
	auto dlgTitNewTextCell = Msg("dlgTitNewTextCell", "ヂ�ストセルの作�");
	auto dlgTitColorCell = Msg("dlgTitColorCell", "カラーセルの設�);
	auto dlgTitNewColorCell = Msg("dlgTitNewColorCell", "カラーセルの作�");
	auto dlgTitPCCell = Msg("dlgTitPCCell", "プレイヤーキャラクタセルの設�);
	auto dlgTitNewPCCell = Msg("dlgTitNewPCCell", "プレイヤーキャラクタセルの作�");
	auto dlgTitEnemyCard = Msg("dlgTitEnemyCard", "エネミーカード�設�[ %1$s ]");
	auto dlgTitNewEnemyCard = Msg("dlgTitNewEnemyCard", "エネミーカード�作�");
	auto alphaChannel = Msg("alphaChannel", "不透�度:");
	auto blendMode = Msg("blendMode", "合�方�);
	auto colorCellBaseColor = Msg("colorCellBaseColor", "基本色");
	auto gradient = Msg("gradient", "グラ�ション");
	auto direction = Msg("direction", "方�");
	auto endColor = Msg("endColor", "終端色");
	auto text = Msg("text", "ヂ�ス�);
	auto font = Msg("font", "フォン�);
	auto size = Msg("size", "サイズ:");
	auto pixel = Msg("pixel", "ピクセル");
	auto fontColor = Msg("fontColor", "ヂ�スト色");
	auto fontStyle = Msg("fontStyle", "書�);
	auto bold = Msg("bold", "太�);
	auto italic = Msg("italic", "斜�);
	auto underline = Msg("underline", "下�);
	auto strike = Msg("strike", "取り消し�);
	auto vertical = Msg("vertical", "縦書�);
	auto bordering = Msg("bordering", "縁取�);
	auto borderingWidth = Msg("borderingWidth", "�");
	auto borderingColor = Msg("borderingColor", "縁取り色");
	auto pcCellExpanding = Msg("pcCellExpanding", "セルに合わせて拡大・縮小す�);

	auto areaViewKeyboardHint = Msg("areaViewKeyboardHint", "選�上下左右: 移� Shift+上下左右: サイズ変更, Ctrl+Altで10ピクセル単位操� Alt+クリヂ�で篛�選択開�);

	/// イベントビュー�	auto playerCard = Msg("playerCard", "プレイヤーカー�);
	auto tools = Msg("tools", "イベントコンッ��);
	auto startEnter = Msg("startEnter", "到着");
	auto startSelect = Msg("startSelect", "クリヂ�");
	auto startDead = Msg("startDead", "死亡");
	auto startVictory = Msg("startVictory", "勝利");
	auto startEscape = Msg("startEscape", "逵�");
	auto startLose = Msg("startLose", "敗北");
	auto startEveryRound = Msg("startEveryRound", "毎ラウン�);
	auto startRound0 = Msg("startRound0", "バトル開�);
	auto startPackage = Msg("startPackage", "パッケージ");
	auto startUse = Msg("startUse", "使用�);
	auto startRound = Msg("startRound", "ラウン�= %1$s");
	auto keyCodeTimingUse = Msg("keyCodeTimingUse", "使用");
	auto keyCodeTimingSuccess = Msg("keyCodeTimingSuccess", "成功");
	auto keyCodeTimingFailure = Msg("keyCodeTimingFailure", "失�);
	auto keyCodeTimingHasNot = Msg("keyCodeTimingHasNot", "不保有");

	auto manyRounds = Msg("manyRounds", "追�する発火ラウンド�篛�");
	auto dlgTitAddManyRounds = Msg("dlgTitAddManyRounds", "追�する発火ラウンド�篛�");
	auto roundSep = Msg("roundSep", ");

	auto enterTree = Msg("enterTree", "到着");
	auto selectTree = Msg("selectTree", "クリヂ�");
	auto deadTree = Msg("deadTree", "死亡");
	auto victoryTree = Msg("victoryTree", "勝利");
	auto escapeTree = Msg("escapeTree", "逵�");
	auto loseTree = Msg("loseTree", "敗北");
	auto everyRoundTree = Msg("everyRoundTree", "毎ラウン�);
	auto round0Tree = Msg("round0Tree", "バトル開�);
	auto packageTree = Msg("packageTree", "パッケージイベン�);
	auto useTree = Msg("useTree", "使用時イベン�);
	auto keyCodeTree = Msg("keyCodeTree", "[%1$s]");
	auto roundTree = Msg("roundTree", "ラウン�%1$s");

	auto eventTreeKindSystem = Msg("eventTreeKindSystem", "シスッ�");
	auto eventTreeKindKeyCode = Msg("eventTreeKindKeyCode", "キーコー�);
	auto eventTreeKindRound = Msg("eventTreeKindRound", "ラウン�);

	auto eventTreeSlope = Msg("eventTreeSlope", "傾�);

	auto startUseCount = Msg("startUseCount", "利用数");

	auto flagOn = Msg("flagOn", "TRUE");
	auto flagOff = Msg("flagOff", "FALSE");
	auto evtChildBrVar = Msg("evtChildBrVar", "%1$s = %2$s");
	auto etc = Msg("etc", "そ��);
	auto stepMoreThan = Msg("stepMoreThan", "スッ�プ�1$s」が�2$s」以�);
	auto stepLessThan = Msg("stepLessThan", "スッ�プ�1$s」が�2$s」未満");
	auto partyAll = Msg("partyAll", "パ�ヂ�全員");
	auto partyActive = Msg("partyActive", "動けるメン�);
	auto autoSelect = Msg("autoSelect", "自�);
	auto manualSelect = Msg("manualSelect", "手動");
	auto valuedSelect = Msg("valuedSelect", "評価条件");
	auto selectMemberSuccess = Msg("selectMemberSuccess", "%1$sから%2$sでキャラクタを選�);
	auto selectMemberCancel = Msg("selectMemberCancel", "%1$sから%2$sでのキャラクタ選択をキャンセル");
	auto selectMemberFailure = Msg("selectMemberFailure", "%1$sから%2$sでのキャラクタ選択に失�);
	auto branchAbilitySuccess = Msg("branchAbilitySuccess", "%1$sがレベル%2$sで%3$sと%4$sで行う判定に成功");
	auto branchAbilityFailure = Msg("branchAbilityFailure", "%1$sがレベル%2$sで%3$sと%4$sで行う判定に失�);
	auto branchRandomSuccess = Msg("branchRandomSuccess", "%1$s%%成功");
	auto branchRandomFailure = Msg("branchRandomFailure", "%1$s%%失�);
	auto levelAverage = Msg("levelAverage", "パ�ヂ�全員の平址�");
	auto levelSelected = Msg("levelSelected", "選択中のメン�);
	auto branchLevelSuccess = Msg("branchLevelSuccess", "%1$sがレベル%2$s以�);
	auto branchLevelFailure = Msg("branchLevelFailure", "%1$sがレベル%2$s未満");
	auto branchStatusSuccess = Msg("branchStatusSuccess", "%1$sでの�2$s」�判定に成功");
	auto branchStatusFailure = Msg("branchStatusFailure", "%1$sでの�2$s」�判定に失�);
	auto branchNumberSuccess = Msg("branchNumberSuccess", "パ�ヂ�に%1$s人以上い�);
	auto branchNumberFailure = Msg("branchNumberFailure", "パ�ヂ�は%1$s人未満");
	auto branchArea = Msg("branchArea", "エリア = %1$s");
	auto branchAreaWithId = Msg("branchAreaWithId", "エリア = %1$s.%2$s");
	auto branchBattle = Msg("branchBattle", "バトル = %1$s");
	auto branchBattleWithId = Msg("branchBattleWithId", "バトル = %1$s.%2$s");
	auto branchOnBattleSuccess = Msg("branchOnBattleSuccess", "イベント発生時の状況が戦闘中");
	auto branchOnBattleFailure = Msg("branchOnBattleFailure", "イベント発生時の状況が戦闘中以�);
	auto branchCastSuccess = Msg("branchCastSuccess", "�1$s」が�わってあ�");
	auto branchCastFailure = Msg("branchCastFailure", "�1$s」が�わってぁ��);
	auto branchEffectCardSuccess = Msg("branchEffectCardSuccess", "�2$s」を所有してあ�(%1$s)");
	auto branchEffectCardFailure = Msg("branchEffectCardFailure", "�2$s」を所有してぁ��%1$s)");
	auto branchInfoSuccess = Msg("branchInfoSuccess", "�1$s」を所有してあ�");
	auto branchInfoFailure = Msg("branchInfoFailure", "�1$s」を所有してぁ��);
	auto branchMoneySuccess = Msg("branchMoneySuccess", "%1$ssp以上所持してあ�");
	auto branchMoneyFailure = Msg("branchMoneyFailure", "%1$ssp以上所持してぁ��);
	auto branchCouponSuccess = Msg("branchCouponSuccess", "称号�2$s」を所有してあ�(%1$s)");
	auto branchCouponFailure = Msg("branchCouponFailure", "称号�2$s」を所有してぁ��%1$s)");
	auto branchCouponMultiSuccess = Msg("branchCouponMultiSuccess", "称号%2$s�3$s所有してあ�(%1$s)"); // Wsn.2
	auto branchCouponMultiFailure = Msg("branchCouponMultiFailure", "称号%2$s�3$s所有してぁ��%1$s)"); // Wsn.2
	auto branchCompleteSuccess = Msg("branchCompleteSuccess", "シナリオ�1$s」が終亸�みである");
	auto branchCompleteFailure = Msg("branchCompleteFailure", "シナリオ�1$s」が終亸�みでな�);
	auto branchGossipSuccess = Msg("branchGossipSuccess", "ゴシ��1$s」が宿屋にある");
	auto branchGossipFailure = Msg("branchGossipFailure", "ゴシ��1$s」が宿屋に無�);
	auto branchStepCmpGreater = Msg("branchStepCmpGreater", "スッ�プ�1$s」が�2$s」より大きい");
	auto branchStepCmpLesser = Msg("branchStepCmpLesser", "スッ�プ�1$s」が�2$s」より小さ�);
	auto branchStepCmpEq = Msg("branchStepCmpEq", "スッ�プ�1$s」が�2$s」と同値");
	auto branchFlagCmpNotEq = Msg("branchFlagCmpNotEq", "フラグ�1$s」と�2$s」�値が異な�);
	auto branchFlagCmpEq = Msg("branchFlagCmpEq", "フラグ�1$s」が�2$s」と同値");
	auto branchRandomSelectSuccess = Msg("branchRandomSelectSuccess", "%2$sのキャラクタを選�%1$s)");
	auto branchRandomSelectFailure = Msg("branchRandomSelectFailure", "%2$sのキャラクタ選択に失�%1$s)");
	auto branchRandomSelectSuccessN = Msg("branchRandomSelectSuccessN", "キャラクタを選�%1$s)");
	auto branchRandomSelectFailureN = Msg("branchRandomSelectFailureN", "キャラクタ選択に失�%1$s)");
	auto randomSelectCondition1 = Msg("randomSelectCondition1", "レベル%1$s2$s");
	auto randomSelectCondition2 = Msg("randomSelectCondition2", "状態が%1$s");
	auto randomSelectCondition3 = Msg("randomSelectCondition3", "レベル%1$s2$sで状態が%3$s");
	auto branchKeyCodeAllTypeSuccess = Msg("branchKeyCodeAllTypeSuccess", "キーコード�1$s」を含むカードを所有してあ�(%2$s)");
	auto branchKeyCodeAllTypeFailure = Msg("branchKeyCodeAllTypeFailure", "キーコード�1$s」を含むカードを所有してぁ��%2$s)");
	auto branchKeyCodeSuccess = Msg("branchKeyCodeSuccess", "キーコード�1$s」を含む%2$sを所有してあ�(%3$s)");
	auto branchKeyCodeFailure = Msg("branchKeyCodeFailure", "キーコード�1$s」を含む%2$sを所有してぁ��%3$s)");
	auto targetIsSkill = Msg("targetIsSkill", "特殊技能");
	auto targetIsItem = Msg("targetIsItem", "アイッ�");
	auto targetIsBeast = Msg("targetIsBeast", "召喚獣");
	auto targetIsHand = Msg("targetIsHand", "手札");
	auto targetSeparator = Msg("targetSeparator", "・");
	auto branchRound = Msg("branchRound", "バトル�1$sラウン�2$s");
	auto branchMultiCouponSuccess = Msg("branchMultiCouponSuccess", "%1$sが称号�2$s」を所有してあ�"); // Wsn.2
	auto branchMultiCouponFailure = Msg("branchMultiCouponFailure", "%1$sが�ての称号を所有してぁ��); // Wsn.2

	const string physicalName(Physical id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Physical, "physicalName"));
	}
	auto physicalNameDex = Msg("physicalNameDex", "器用度");
	auto physicalNameAgl = Msg("physicalNameAgl", "敏捷度");
	auto physicalNameInt = Msg("physicalNameInt", "知�);
	auto physicalNameStr = Msg("physicalNameStr", "筋力");
	auto physicalNameVit = Msg("physicalNameVit", "生命�);
	auto physicalNameMin = Msg("physicalNameMin", "精神力");
	const string mentalName(Mental id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Mental, "mentalName"));
	}
	auto mentalNameAggressive = Msg("mentalNameAggressive", "好戦性");
	auto mentalNameUnaggressive = Msg("mentalNameUnaggressive", "平和性");
	auto mentalNameCheerful = Msg("mentalNameCheerful", "社交性");
	auto mentalNameUncheerful = Msg("mentalNameUncheerful", "冐�性");
	auto mentalNameBrave = Msg("mentalNameBrave", "勌�性");
	auto mentalNameUnbrave = Msg("mentalNameUnbrave", "臗�性");
	auto mentalNameCautious = Msg("mentalNameCautious", "慎重性");
	auto mentalNameUncautious = Msg("mentalNameUncautious", "大胀�");
	auto mentalNameTrickish = Msg("mentalNameTrickish", "狡猾性");
	auto mentalNameUntrickish = Msg("mentalNameUntrickish", "正直性");
	const string statusName(Status id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Status, "statusName"));
	}
	auto statusNameActive = Msg("statusNameActive", "行動可能");
	auto statusNameInactive = Msg("statusNameInactive", "行動不可");
	auto statusNameAlive = Msg("statusNameAlive", "生�);
	auto statusNameDead = Msg("statusNameDead", "非生�);
	auto statusNameFine = Msg("statusNameFine", "健康");
	auto statusNameInjured = Msg("statusNameInjured", "�傷");
	auto statusNameHeavyInjured = Msg("statusNameHeavyInjured", "重傷");
	auto statusNameUnconscious = Msg("statusNameUnconscious", "意識不�");
	auto statusNamePoison = Msg("statusNamePoison", "中�);
	auto statusNameSleep = Msg("statusNameSleep", "��);
	auto statusNameBind = Msg("statusNameBind", "呪�);
	auto statusNameParalyze = Msg("statusNameParalyze", "麻痺/石�);
	auto statusNameConfuse = Msg("statusNameConfuse", "混乱");
	auto statusNameOverheat = Msg("statusNameOverheat", "激�);
	auto statusNameBrave = Msg("statusNameBrave", "動�");
	auto statusNamePanic = Msg("statusNamePanic", "恐�");
	auto statusNameSilence = Msg("statusNameSilence", "沈�);
	auto statusNameFaceUp = Msg("statusNameFaceUp", "暴露");
	auto statusNameAntiMagic = Msg("statusNameAntiMagic", "魔法無効�);
	auto statusNameUpAction = Msg("statusNameUpAction", "行動力上�");
	auto statusNameUpAvoid = Msg("statusNameUpAvoid", "回避力上�");
	auto statusNameUpResist = Msg("statusNameUpResist", "抵抗力上�");
	auto statusNameUpDefense = Msg("statusNameUpDefense", "防御力上�");
	auto statusNameDownAction = Msg("statusNameDownAction", "行動力低�);
	auto statusNameDownAvoid = Msg("statusNameDownAvoid", "回避力低�);
	auto statusNameDownResist = Msg("statusNameDownResist", "抵抗力低�);
	auto statusNameDownDefense = Msg("statusNameDownDefense", "防御力低�);
	auto statusNameNone = Msg("statusNameNone", "状態指定無�);
	auto effectTypeElement = Msg("effectTypeElement", "%1$s属性");
	const string effectTypeName(EffectType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(EffectType, "effectTypeName"));
	}
	auto effectTypeNamePhysic = Msg("effectTypeNamePhysic", "物�);
	auto effectTypeNameMagic = Msg("effectTypeNameMagic", "魔�);
	auto effectTypeNameMagicalPhysic = Msg("effectTypeNameMagicalPhysic", "魔法的物�);
	auto effectTypeNamePhysicalMagic = Msg("effectTypeNamePhysicalMagic", "物琚�魔�);
	auto effectTypeNameNone = Msg("effectTypeNameNone", "無");
	const string effectTypeDesc(EffectType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(EffectType, "effectTypeDesc"));
	}
	auto effectTypeDescPhysic = Msg("effectTypeDescPhysic", "武器が効かなね�在には無効");
	auto effectTypeDescMagic = Msg("effectTypeDescMagic", "魔法が効かなね�在には無効");
	auto effectTypeDescMagicalPhysic = Msg("effectTypeDescMagicalPhysic", "武器と魔法�両方が効かなね�在には無効");
	auto effectTypeDescPhysicalMagic = Msg("effectTypeDescPhysicalMagic", "武器と魔法�どちらかが効かなね�在には無効");
	auto effectTypeDescNone = Msg("effectTypeDescNone", "全ての存在に有効");
	const string resistName(Resist id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Resist, "resistName"));
	}
	auto resistNameAvoid = Msg("resistNameAvoid", "回避属性");
	auto resistNameResist = Msg("resistNameResist", "抵抗属性");
	auto resistNameUnfail = Msg("resistNameUnfail", "忸�属性");
	const string resistDesc(Resist id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Resist, "resistDesc"));
	}
	auto resistDescAvoid = Msg("resistDescAvoid", "回避された�合�効果無�);
	auto resistDescResist = Msg("resistDescResist", "抵抗された場合�効果半�);
	auto resistDescUnfail = Msg("resistDescUnfail", "絶対成功");
	const string cardTargetName(CardTarget id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CardTarget, "cardTargetName"));
	}
	auto cardTargetNameNone = Msg("cardTargetNameNone", "対象無�);
	auto cardTargetNameUser = Msg("cardTargetNameUser", "使用�);
	auto cardTargetNameParty = Msg("cardTargetNameParty", "味方");
	auto cardTargetNameEnemy = Msg("cardTargetNameEnemy", "敵方");
	auto cardTargetNameBoth = Msg("cardTargetNameBoth", "双方");
	auto cardTargetOne = Msg("cardTargetOne", "一�);
	auto cardTargetAll = Msg("cardTargetAll", "全�);
	const string cardVisualName(CardVisual id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CardVisual, "cardVisualName"));
	}
	auto cardVisualNameNone = Msg("cardVisualNameNone", "視覚効果無�);
	auto cardVisualNameReverse = Msg("cardVisualNameReverse", "対象を反転");
	auto cardVisualNameHorizontal = Msg("cardVisualNameHorizontal", "対象を横に霋�");
	auto cardVisualNameVertical = Msg("cardVisualNameVertical", "対象を縦に霋�");
	const string premiumName(Premium id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Premium, "premiumName"));
	}
	auto premiumNameNormal = Msg("premiumNameNormal", "日用�(買戻し不可/破棏�)");
	auto premiumNameRare = Msg("premiumNameRare", "希少品 (買戻し可/破棏�)");
	auto premiumNamePremium = Msg("premiumNamePremium", "貴重品 (買戻し可/破棸�可)");
	const string enhanceName(Enhance id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Enhance, "enhanceName"));
	}
	auto enhanceNameAction = Msg("enhanceNameAction", "行動");
	auto enhanceNameAvoid = Msg("enhanceNameAvoid", "回避");
	auto enhanceNameResist = Msg("enhanceNameResist", "抵�);
	auto enhanceNameDefense = Msg("enhanceNameDefense", "防御");
	auto mentality = Msg("mentality", "精神状�);
	const string mentalityName(Mentality id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Mentality, "mentalityName"));
	}
	auto mentalityNameNormal = Msg("mentalityNameNormal", "正常");
	auto mentalityNameSleep = Msg("mentalityNameSleep", "睡�");
	auto mentalityNameConfuse = Msg("mentalityNameConfuse", "混乱");
	auto mentalityNameOverheat = Msg("mentalityNameOverheat", "激�);
	auto mentalityNameBrave = Msg("mentalityNameBrave", "動�");
	auto mentalityNamePanic = Msg("mentalityNamePanic", "恐�");

	auto enhanceBonus = Msg("enhanceBonus", "%1$sボ�ナス");
	auto statusActive = Msg("statusActive", "※ 行動可能 = (健康 | �傷 | 重傷 | 中�");
	auto statusInactive = Msg("statusInactive", "※ 行動不可 = (意識不� | 麻痺/石�| 呪�| ��");
	auto statusAlive = Msg("statusAlive", "※ 生�= (健康 | �傷 | 重傷 | 中�| 呪�| ��");
	auto statusDead = Msg("statusDead", "※ 非生�= (意識不� | 麻痺/石�");
	const string targetName(Target.M id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch2!(Target.M, "Target.M", "targetName"));
	}
	auto targetNameSelected = Msg("targetNameSelected", "選択中のメン�);
	auto targetNameUnselected = Msg("targetNameUnselected", "選択中以外�メン�);
	auto targetNameRandom = Msg("targetNameRandom", "誰か一人");
	auto targetNameParty = Msg("targetNameParty", "パ�ヂ�全員");
	const string talkerName(Talker id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Talker, "talkerName"));
	}
	auto talkerNameSelected = Msg("talkerNameSelected", "選択中");
	auto talkerNameUnselected = Msg("talkerNameUnselected", "選択中以�);
	auto talkerNameRandom = Msg("talkerNameRandom", "ランダ�");
	auto talkerNameCard = Msg("talkerNameCard", "カー�);
	auto talkerNameNarration = Msg("talkerNameNarration", "話耄��);
	auto talkerNameImage = Msg("talkerNameImage", "画�);
	auto talkerNameValued = Msg("talkerNameValued", "評価メン�);
	const string rangeName(Range id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Range, "rangeName"));
	}
	auto rangeNameSelected = Msg("rangeNameSelected", "現在選択中のメン�);
	auto rangeNameRandom = Msg("rangeNameRandom", "パ�ヂ�の誰か一人");
	auto rangeNameParty = Msg("rangeNameParty", "パ�ヂ�の全員");
	auto rangeNameBackpack = Msg("rangeNameBackpack", "荷物�);
	auto rangeNamePartyAndBackpack = Msg("rangeNamePartyAndBackpack", "全�荷物袋含む)");
	auto rangeNameField = Msg("rangeNameField", "フィールド��);
	auto rangeNameCouponHolder = Msg("rangeNameCouponHolder", "称号所有�);
	auto rangeWithCoupon = Msg("rangeWithCoupon", "称号所有�%1$s)");
	auto rangeWithNoCoupon = Msg("rangeWithNoCoupon", "称号所有�挮�無�");
	auto rangeDescField = Msg("rangeDescField", "パ�ヂ�・荷物袋�エネミーカードを含む");
	auto rangeNameCardTarget = Msg("rangeNameCardTarget", "カード�使用対象");
	auto rangeDescCardTarget = Msg("rangeDescCardTarget", "使用時イベント中でなぴ合、対象無しになりま�);
	const string castRangeName(CastRange id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(CastRange, "castRangeName"));
	}
	auto castRangeNameParty = Msg("castRangeNameParty", "パ�ヂ�");
	auto castRangeNameEnemy = Msg("castRangeNameEnemy", "敵");
	auto castRangeNameNpc = Msg("castRangeNameNpc", "同行キャス�);
	const string damageTypeName(DamageType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(DamageType, "damageTypeName"));
	}
	auto damageTypeNameLevelRatio = Msg("damageTypeNameLevelRatio", "レベルに対応する値");
	auto damageTypeNameNormal = Msg("damageTypeNameNormal", "値の直接入�);
	auto damageTypeNameMax = Msg("damageTypeNameMax", "最大値処�);
	auto damageTypeNameFixed = Msg("damageTypeNameFixed", "固定値");
	const string elementName(Element id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Element, "elementName"));
	}
	auto elementNameAll = Msg("elementNameAll", "全");
	auto elementNameHealth = Msg("elementNameHealth", "肉�);
	auto elementNameMind = Msg("elementNameMind", "精�);
	auto elementNameMiracle = Msg("elementNameMiracle", "神聖");
	auto elementNameMagic = Msg("elementNameMagic", "魔力");
	auto elementNameFire = Msg("elementNameFire", "�);
	auto elementNameIce = Msg("elementNameIce", "冷�);
	const string elementDesc(Element id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Element, "elementDesc"));
	}
	auto elementDescAll = Msg("elementDescAll", "全ての存在に有効");
	auto elementDescHealth = Msg("elementDescHealth", "肉体を持つ存在に有効");
	auto elementDescMind = Msg("elementDescMind", "精神を持つ存在に有効");
	auto elementDescMiracle = Msg("elementDescMiracle", "不流�存在に有効");
	auto elementDescMagic = Msg("elementDescMagic", "魔法的な存在に有効");
	auto elementDescFire = Msg("elementDescFire", "炎が無効でなね�在に有効");
	auto elementDescIce = Msg("elementDescIce", "冷気が無効でなね�在に有効");

	auto sexUnknown = Msg("sexUnknown", "�);
	auto periodUnknown = Msg("periodUnknown", "不�");
	auto natureUnknown = Msg("natureUnknown", "そ��);

	const string effectCardTypeName(EffectCardType id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(EffectCardType, "effectCardTypeName"));
	}
	auto effectCardTypeNameAll = Msg("effectCardTypeNameAll", "全てのカー�);
	auto effectCardTypeNameSkill = Msg("effectCardTypeNameSkill", "特殊技能カー�);
	auto effectCardTypeNameItem = Msg("effectCardTypeNameItem", "アイッ�カー�);
	auto effectCardTypeNameBeast = Msg("effectCardTypeNameBeast", "召喚獣カー�);
	auto effectCardTypeNameHand = Msg("effectCardTypeNameHand", "戦闘時の手札"); // Wsn.2

	const string comparison4Name(Comparison4 id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Comparison4, "comparison4Name"));
	}
	auto comparison4NameEq = Msg("comparison4NameEq", "であれば");
	auto comparison4NameNe = Msg("comparison4NameNe", "でなければ");
	auto comparison4NameLt = Msg("comparison4NameLt", "より大きけれ�");
	auto comparison4NameGt = Msg("comparison4NameGt", "より小さければ");

	const string comparison3Name(Comparison3 id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Comparison3, "comparison3Name"));
	}
	auto comparison3NameEq = Msg("comparison3NameEq", "である");
	auto comparison3NameLt = Msg("comparison3NameLt", "より大きい");
	auto comparison3NameGt = Msg("comparison3NameGt", "より小さ�);

	const string comparison3FalseName(Comparison3 id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Comparison3, "comparison3FalseName"));
	}
	auto comparison3FalseNameEq = Msg("comparison3FalseNameEq", "ではな�);
	auto comparison3FalseNameLt = Msg("comparison3FalseNameLt", "以�);
	auto comparison3FalseNameGt = Msg("comparison3FalseNameGt", "以�);

	auto dlgTitComment = Msg("dlgTitComment", "コメント�記述");

	/// カードウィンドウ�	auto cardTabName = Msg("cardTabName", "%1$s");
	auto handCardTabName = Msg("handCardTabName", "%1$s.%2$s");
	auto importSourceTabName = Msg("importSourceTabName", "%1$s");
	auto cardTitle = Msg("cardTitle", "%1$s.%2$s");
	auto dlgTitImportOption = Msg("dlgTitImportOption", "参�先�インポ��);
	auto importOptionMaterials = Msg("importOptionMaterials", "外部��);
	auto importOptionVariables = Msg("importOptionVariables", "状態変数");
	auto importOptionCasts = Msg("importOptionCasts", "キャストカー�);
	auto importOptionSkills = Msg("importOptionSkills", "特殊技能カー�);
	auto importOptionItems = Msg("importOptionItems", "アイッ�カー�);
	auto importOptionBeasts = Msg("importOptionBeasts", "召喚獣カー�);
	auto importOptionInfos = Msg("importOptionInfos", "惱カー�);
	auto importOptionAreas = Msg("importOptionAreas", "エリア");
	auto importOptionBattles = Msg("importOptionBattles", "バトル");
	auto importOptionPackages = Msg("importOptionPackages", "パッケージ");
	auto importOptionIncludedFiles = Msg("importOptionIncludedFiles", "格納カードイメージ");
	auto importOptionIncludedBgImages = Msg("importOptionIncludedBgImages", "格納背景イメージ");
	auto importOptionHands = Msg("importOptionHands", "キャスト�持ち札");
	auto importOptionBeastsInMotions = Msg("importOptionBeastsInMotions", "効果中の召喚獣");
	const string importTypeIncludedName(ImportTypeIncluded id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(ImportTypeIncluded, "importTypeIncludedName"));
	}
	auto importTypeIncludedNameExclude = Msg("importTypeIncludedNameExclude", "格納であれば外部出力す�);
	auto importTypeIncludedNameInclude = Msg("importTypeIncludedNameInclude", "参�であれば格納す�);
	auto importTypeIncludedNameAsIs = Msg("importTypeIncludedNameAsIs", "そ�ままにする");
	const string importTypeReference1Name(ImportTypeReference1 id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(ImportTypeReference1, "importTypeReference1Name"));
	}
	auto importTypeReference1NameRename = Msg("importTypeReference1NameRename", "重褁�た�合�名前を変更する");
	auto importTypeReference1NameNoOverwrite = Msg("importTypeReference1NameNoOverwrite", "重褁�た�合�インポ�トしな�);
	auto importTypeReference1NameOverwrite = Msg("importTypeReference1NameOverwrite", "重褁�た�合�上書きす�);
	auto importTypeReference1NameNoImport = Msg("importTypeReference1NameNoImport", "インポ�トしな�);
	const string importTypeReference2Name(ImportTypeReference2 id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(ImportTypeReference2, "importTypeReference2Name"));
	}
	auto importTypeReference2NameRename = Msg("importTypeReference1NameRename", "新しいIDでインポ�トす�);
	auto importTypeReference2NameNoImport = Msg("importTypeReference1NameNoImport", "インポ�トしな�);
	auto importOverwriteScenarioInfo = Msg("importOverwriteScenarioInfo", "カード�シナリオ名及びシナリオ作�惱を書き換える");

	auto dlgTitAddScenario = Msg("dlgTitAddScenario", "インポ�ト�の選�);
	auto dlgTitImportResult = Msg("dlgTitImportResult", "インポ�ト対象の選�);
	auto importResourceList = Msg("importResourceList", "次のリソースのぁ�、チェヂ�を�れたも�がインポ�トされます�);
	auto overwriteMark = Msg("overwriteMark", "%1$s (上書�");

	auto cardIsReference = Msg("cardIsReference", "�1$s.%2$s」を参�してぁ��);
	auto referencedCardIsNotFound = Msg("referencedCardIsNotFound", "参�先�カードが見つかりません(ID:%1$s)");

	auto cardStatus = Msg("cardStatus", "%1$s枚�カー�);
	auto cardStatusSelOne = Msg("cardStatusSelOne", "%1$s枚�カー�(ID = %2$s)");
	auto cardStatusSelMulti = Msg("cardStatusSelMulti", "%1$s枚�カー�(%2$s枚を選択中)");
	auto handCardStatus = Msg("handCardStatus", "%1$s枚�カー�(有効枚数 = %2$s)");
	auto handCardStatusSelOne = Msg("handCardStatusSelOne", "%1$s枚�カー�(有効枚数 = %2$s) (ID = %3$s)");
	auto handCardStatusSelMulti = Msg("handCardStatusSelMulti", "%1$s枚�カー�(有効枚数 = %2$s) (%3$s枚を選択中)");

	auto cwCast = Msg("cwCast", "キャス�);
	auto skill = Msg("skill", "特殊技能");
	auto item = Msg("item", "アイッ�");
	auto beast = Msg("beast", "召喚獣");
	auto info = Msg("info", "惱");

	auto noSelectImage = Msg("noSelectImage", "(挮�無�");
	auto noImage = Msg("noImage", "存在しなあ�メージ(パス:%1$s)");
	auto noSelectBGM = Msg("noSelectBGM", "(挮�無�");
	auto noBGM = Msg("noBGM", "存在しないBGM(パス:%1$s)");
	auto noSelectSE = Msg("noSelectSE", "(挮�無�");
	auto noSE = Msg("noSE", "存在しなお�果音(パス:%1$s)");
	auto noSelectArea = Msg("noSelectArea", "(挮�無�");
	auto noArea = Msg("noArea", "存在しなあ�リア(ID:%1$s)");
	auto noSelectBattle = Msg("noSelectBattle", "(挮�無�");
	auto noBattle = Msg("noBattle", "存在しなぃ�トル(ID:%1$s)");
	auto noSelectPackage = Msg("noSelectPackage", "(挮�無�");
	auto noPackage = Msg("noPackage", "存在しなぃ�ヂ�ージ(ID:%1$s)");
	auto noSelectCast = Msg("noSelectCast", "(挮�無�");
	auto noCast = Msg("noCast", "存在しなあ�ャストカー�ID:%1$s)");
	auto noSelectSkill = Msg("noSelectSkill", "(挮�無�");
	auto noSkill = Msg("noSkill", "存在しなぉ�殊技能カー�ID:%1$s)");
	auto noSelectItem = Msg("noSelectItem", "(挮�無�");
	auto noItem = Msg("noItem", "存在しなあ�イッ�カー�ID:%1$s)");
	auto noSelectBeast = Msg("noSelectBeast", "(挮�無�");
	auto noBeast = Msg("noBeast", "存在しなく�喚獣カー�ID:%1$s)");
	auto noSelectInfo = Msg("noSelectInfo", "(挮�無�");
	auto noInfo = Msg("noInfo", "存在しなぃ�報カー�ID:%1$s)");
	auto noSelectFlag = Msg("noSelectFlag", "(挮�無�");
	auto noFlag = Msg("noFlag", "存在しなぃ�ラグ(パス:%1$s)");
	auto noSelectStep = Msg("noSelectStep", "(挮�無�");
	auto noStep = Msg("noStep", "存在しなあ�ッ��パス:%1$s)");
	auto noSelectStart = Msg("noSelectStart", "(挮�無�");
	auto noStart = Msg("noStart", "存在しなあ�タートコンッ��パス:%1$s)");
	auto noSelectCoupon = Msg("noSelectCoupon", "(挮�無�");
	auto noSelectCompleteStamp = Msg("noSelectCompleteStamp", "(挮�無�");
	auto noSelectGossip = Msg("noSelectGossip", "(挮�無�");
	auto noSelectCellName = Msg("noSelectCellName", "(挮�無�");
	auto noSelectTarget = Msg("noSelectTarget", "(挮�無�");
	auto noEffect = Msg("noEffect", "(挮�無�");
	auto noKeyCode = Msg("noKeyCode", "(挮�無�");

	auto cardId = Msg("cardId", "ID");
	auto cardName = Msg("cardName", "名称");
	auto cardDesc = Msg("cardDesc", "説�);
	auto infinity = Msg("infinity", "�);

	auto dlgTitNewCast = Msg("dlgTitNewCast", "キャストカード�作�");
	auto dlgTitNewSkill = Msg("dlgTitNewSkill", "特殊技能カード�作�");
	auto dlgTitNewItem = Msg("dlgTitNewItem", "アイッ�カード�作�");
	auto dlgTitNewBeast = Msg("dlgTitNewBeast", "召喚獣カード�作�");
	auto dlgTitNewInfo = Msg("dlgTitNewInfo", "惱カード�作�");
	auto dlgTitCast = Msg("dlgTitCast", "キャストカード�設�[ %1$s ]");
	auto dlgTitSkill = Msg("dlgTitSkill", "特殊技能カード�設�[ %1$s ]");
	auto dlgTitItem = Msg("dlgTitItem", "アイッ�カード�設�[ %1$s ]");
	auto dlgTitBeast = Msg("dlgTitBeast", "召喚獣カード�設�[ %1$s ]");
	auto dlgTitInfo = Msg("dlgTitInfo", "惱カード�設�[ %1$s ]");

	auto name = Msg("name", "名前");
	auto nameLimit = Msg("nameLimit", "(%2$s断�まで)"); // %1$s = 断�数�2$s = 断�数 / 2
	auto level = Msg("level", "レベル");
	auto life = Msg("life", "体力");
	auto lifeCalc = Msg("lifeCalc", "標準値");
	auto history = Msg("history", "経歴");
	auto coupons = Msg("coupons", "経歴");
	auto addCoupon = Msg("addCoupon", "新規クーポンの追�");
	auto altCoupon = Msg("altCoupon", "クーポンの上書�);
	auto delCoupon = Msg("delCoupon", "クーポンの削除");
	auto sexTitle = Msg("sexTitle", "性別");
	auto periodTitle = Msg("periodTitle", "年代");
	auto race = Msg("race", "種�);
	auto noRace = Msg("noRace", "未挮);
	auto natureTitle = Msg("natureTitle", "�質");
	auto makingsTitle = Msg("makingsTitle", "特性");
	auto tolerant = Msg("tolerant", "対属性");
	auto tolerantBase = Msg("tolerantBase", "対カード属性");
	auto tolerantElement = Msg("tolerantElement", "対効果属性");
	auto resistWeapon = Msg("resistWeapon", "武器が効かな�);
	auto resistMagic = Msg("resistMagic", "魔法が効かな�);
	auto undead = Msg("undead", "命を持たな�);
	auto automaton = Msg("automaton", "忂�持たな�);
	auto unholy = Msg("unholy", "不流�存在");
	auto constructure = Msg("constructure", "魔法生物");
	auto resistText = Msg("resistText", "%1$sに耐性を持つ");
	auto weaknessText = Msg("weaknessText", "%1$sに弱�);
	auto descResistWeapon = Msg("descResistWeapon", "(物琱�性のカードが無効)");
	auto descResistMagic = Msg("descResistMagic", "(魔法属性のカードが無効)");
	auto descUndead = Msg("descUndead", "(肉体属性の効果が無効)");
	auto descAutomaton = Msg("descAutomaton", "(精神属性の効果が無効)");
	auto descUnholy = Msg("descUnholy", "(神聖属性の効果に影響)");
	auto descConstructure = Msg("descConstructure", "(魔力属性の効果に影響)");
	auto descResist = Msg("descResist", "(%1$s属性の効果が無効)");
	auto descWeakness = Msg("descWeakness", "(%1$s属性の効果に影響)");
	auto basicResist = Msg("basicResist", "標準値");
	auto physicalParams = Msg("physicalParams", "身体��);
	auto physicalSum = Msg("physicalSum", "合計値: %1$s");
	auto physicalCalc = Msg("physicalCalc", "標準値");
	auto mentalParams = Msg("mentalParams", "精神傾�);
	auto mentalCalc = Msg("mentalCalc", "標準値");
	auto castEnhance = Msg("castEnhance", "能力修正");
	auto basicEnhance = Msg("basicEnhance", "標準値");

	auto liveStatus = Msg("liveStatus", "初期状�);
	auto lifeAndMentality = Msg("lifeAndMentality", "体力と精神状�);
	auto enhanceLiveBonus = Msg("enhanceLiveBonus", "能力�ーナス/ペナルヂ�");
	const string enhanceLiveBonusName(Enhance id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(Enhance, "enhanceLiveBonusName"));
	}
	auto enhanceLiveBonusNameAction = Msg("enhanceLiveBonusNameAction", "行動");
	auto enhanceLiveBonusNameAvoid = Msg("enhanceLiveBonusNameAvoid", "回避");
	auto enhanceLiveBonusNameResist = Msg("enhanceLiveBonusNameResist", "抵�);
	auto enhanceLiveBonusNameDefense = Msg("enhanceLiveBonusNameDefense", "防御");
	auto useMax = Msg("useMax", "最大値を使用");
	auto status = Msg("status", "異常状�);
	auto paralyze = Msg("paralyze", "麻痺/石�);
	auto poison = Msg("poison", "中�);
	auto bind = Msg("bind", "呪�);
	auto silence = Msg("silence", "沈�);
	auto faceUp = Msg("faceUp", "暴露");
	auto antiMagic = Msg("antiMagic", "魔法無効");
	auto unitValue = Msg("unitValue", "点");
	auto unitRound = Msg("unitRound", "ラウン�);
	auto resetLiveStatus = Msg("resetLiveStatus", "通常状態に戻�);

	auto workConditionGroup = Msg("workConditionGroup", "発動条件");
	auto needSpell = Msg("needSpell", "沈黙時に発動不可");
	auto elementProps = Msg("elementProps", "効果属性");
	auto linkOption = Msg("linkOption", "参�設�);
	auto beastMaxNest = Msg("beastMaxNest", "ネスト可能回数");
	auto resistProps = Msg("resistProps", "抵抗属性");
	auto aptPhysical = Msg("aptPhysical", "身体的要�");
	auto aptMental = Msg("aptMental", "精神的要�");
	auto skillLevel = Msg("skillLevel", "技能レベル");
	auto useCount = Msg("useCount", "使用回数");
	auto useCountGroup = Msg("useCountGroup", "使用可能回数");
	auto useCountRange = Msg("useCountRange", "(01$s : 0 = �");
	auto useCountCur = Msg("useCountCur", "現在");
	auto useCountMax = Msg("useCountMax", "最大");
	auto useCountIsMax = Msg("useCountIsMax", "最大回数を使用");
	auto price = Msg("price", "価格");
	auto priceAuto = Msg("priceAuto", "(参耔�)");
	auto useModify = Msg("useModify", "使用�能力値修正");
	auto haveModify = Msg("haveModify", "所有時 能力値修正");
	auto motionKind = Msg("motionKind", "効果種別");
	auto motionElement = Msg("motionElement", "属性");
	auto motionDamageType = Msg("motionDamageType", "タイ�);
	auto calcType = Msg("calcType", "効果値タイ�);
	auto motionValue = Msg("motionValue", "値");
	auto motionBeast = Msg("motionBeast", "召喚するカー�);
	auto beastNone = Msg("beastNone", "召喚獣無�);
	auto setBeast = Msg("setBeast", "選�);
	auto motionRound = Msg("motionRound", "継続時�(ラウンド数)");
	auto motionEnhValue = Msg("motionEnhValue", "変化値");
	auto effectTarget = Msg("effectTarget", "効果目�);
	auto effectRange = Msg("effectRange", "効果篛�");
	auto effectVisual = Msg("effectVisual", "視覚効�);
	auto cardPremium = Msg("cardPremium", "カード�価値");
	auto successRate = Msg("successRate", "成功玿�正値");
	auto allFail = Msg("allFail", "絶対失敗\n(-5)");
	auto allSuccess = Msg("allSuccess", "絶対成功\n(+5)");
	auto se = Msg("se", "効果音");
	auto se1 = Msg("se1", "初期効�);
	auto se2 = Msg("se2", "二次効�);
	auto soundNone = Msg("soundNone", "効果音無�);
	auto keyCodes = Msg("keyCodes", "イベント発火のキーコー�);
	auto addKeyCode = Msg("addKeyCode", "キーコード�追�");
	auto delKeyCode = Msg("delKeyCode", "キーコード�削除");

	auto warningNotDefaultSE = Msg("warningNotDefaultSE", "標準以外�効果音はシナリオの外では鳴らなく�能性があります�);
	auto warningEffectTypeNone = Msg("warningEffectTypeNone", "無属性のカードをシナリオ外に持ち出した場合、予期せぬ動作�原因になります�);
	auto warningVanishCast = Msg("warningVanishCast", "神聖属性以外�対象消去効果を持つカードをシナリオ外に持ち出した場合、予期せぬ動作�原因になります�);
	auto warningNameLenOver = Msg("warningNameLenOver", "名前の長さが%2$s断�を趁�てぁ�す。メヂ�ージにカード名が表示された際に不�合が発生する可能性があります�); // %1$s = 断�数�2$s = 断�数 / 2
	auto warningPCNumberClassic = Msg("warningPCNumberClassic", "プレイヤーキャラクタのイメージはCardWirth 1.30より前�バ�ジョンでは表示されません�);
	auto warningUnknownContent = Msg("warningUnknownContent", "イベン�[%1$s] はCardWirth %2$sより前�バ�ジョンでは使用できません�);
	auto warningUnknownContentWsn = Msg("warningUnknownContentWsn", "イベン�[%1$s] はWsn.%2$sより前�バ�ジョンでは使用できません�);
	auto warningBranchCouponAtField = Msg("warningBranchCouponAtField", "フィールド�体でのクーポン所持判定�、CardWirth 1.30より前�バ�ジョンでは使用できません�);
	auto warningSystemVarName = Msg("warningSystemVarName", "%1$sで始まる名前�状態変数は、�レイヤーの環墁�よっては正しく機�しなぺ�があります�);
	auto warningSystemCoupon = Msg("warningSystemCoupon", "%1$sで始まる名前�クーポンを操作する事�できません�);
	auto warningBranchStatusMental = Msg("warningBranchStatusMental", "%1$s状態�判定�、CardWirth %2$sより前�バ�ジョンでは使用できません�);
	auto warningValuedTalker = Msg("warningValuedTalker", "評価メンバ�、CardWirth 1.50より前�バ�ジョンでは使用できません�);
	auto warningTextCell = Msg("warningTextCell", "ヂ�ストセルは、CardWirth 1.50より前�バ�ジョンでは使用できません�);
	auto warningColorCell = Msg("warningColorCell", "カラーセルは、CardWirth 1.50より前�バ�ジョンでは使用できません�);
	auto warningPCCell = Msg("warningPCCell", "プレイヤーキャラクタセルは、Wsn.1以降�形式�シナリオでしか使用できません�);
	auto warningEffectBoosterFileWithReplaceBgImage = Msg("warningEffectBoosterFileWithReplaceBgImage", "エフェクトブースター関係�背景セルは無視するよぁ�挮�されてぁ�す�);
	auto warningBgImageIncluded = Msg("warningBgImageForeground", "背景セルのイメージ格納�、CardWirth 1.60より前�バ�ジョンでは行えません�);
	auto warningBgImageForeground = Msg("warningBgImageForeground", "カードよりも前�表示は、CardWirth 1.60より前�バ�ジョンでは行えません�);
	auto warningBgImageCellName = Msg("warningBgImageCellName", "背景セル名称は、Wsn.1以降�形式�シナリオでしか設定できません�);
	auto warningSelectionBarIsMany = Msg("warningSelectionBarIsMany", "選択肢�1$s行ありますが�2$s行までしか表示できません�);
	auto warningEveryRound = Msg("warningEveryRound", "イベント発火条件「毎ラウンド」�、CardWirth 1.50より前�バ�ジョンでは使用できません�);
	auto warningRound0 = Msg("warningRound0", "イベント発火条件「バトル開始」�、CardWirth 1.50より前�バ�ジョンでは使用できません�);
	auto warningUnknownMotion = Msg("warningUnknownMotion", "効�[%1$s] は、CardWirth %2$sより前�バ�ジョンでは使用できません�);
	auto warningTextColor = Msg("warningTextColor", "ヂ�スト色 [%1$s] は、CardWirth %2$sより前�バ�ジョンでは使用できません�);
	auto warningStepCount = Msg("warningStepCount", "%1$s段階以外�スッ�プ�クラシヂ�なシナリオでは使用できません�);
	auto warningStepOverCount = Msg("warningStepOverCount", "スッ�プ�1$s」�段階数 [%2$s] より大きなスッ�プ値 [%3$s] が指定されてぁ�す�);
	auto warningKeyCodeCount = Msg("warningKeyCodeCount", "%1$s件より多くのキーコード�クラシヂ�なシナリオでは設定できません�);
	auto warningValuedSelectionMethod = Msg("warningValuedSelectionMethod", "評価条件によるメンバ選択�岐�、Wsn.1以降�形式�シナリオしか行えません�);
	auto warningSkillPowerWithFixedValue = Msg("warningSkillPowerWithFixedValue", "精神力操作�固定値挮��、Wsn.1以降�形式�シナリオしか行えません�); // Wsn.1
	auto warningIncludedImage = Msg("warningIncludedImage", "WSN形式�シナリオでは格納イメージは使用できません�);
	auto warningSelectionColumns = Msg("warningSelectionColumns", "選択肢の褕�列表示は、Wsn.1以降�形式�シナリオしか行えません�);
	auto warningRunawayCard = Msg("warningRunawayCard", "キーコード�1$s」付きのカード�死亡イベントを発生させなぁ�め、シナリオを誤動作させる可能性があります�);
	auto warningEndOrChangeAreaInRound0 = Msg("warningEndOrChangeAreaInRound0", "クラシヂ�エンジンのバグにより、バトル開始イベント中にシナリオ終亂�エリア移動を行うと、�レイヤーの�タの破損を含めた異常が発生する可能性があります�);
	auto warningWsnSystemCoupon = Msg("warningWsnSystemCoupon", "シスッ�クーポン�1$s」�Wsn.%2$s以降�形式�シナリオでしか機�しません�); // Wsn.2
	auto warningCanNotGetSetCoupon = Msg("warningCanNotGetSetCoupon", "シスッ�クーポン�1$s」を操作する事�できません�); // Wsn.2
	auto warningCardImagePosition = Msg("warningCardImagePosition", "イメージの配置形式�挮��、Wsn.2以降�形式�シナリオでしか行えません�); // Wsn.2
	auto warningStartAction = Msg("warningStartAction", "戦闘行動開始タイミングの挮��、Wsn.2以降�形式�シナリオしか行えません�); // Wsn.2
	auto warningIgnite = Msg("warningIgnite", "イベント�発火有無の挮��、Wsn.2以降�形式�シナリオしか行えません�); // Wsn.2
	auto warningIgnoreKeyCode = Msg("warningIgnoreKeyCode", "イベント発火無しに挮�されてあ�ため、設定されたキーコード�機�しません�); // Wsn.2
	auto warningBranchKeyCodeAtClassic = Msg("warningBranchKeyCodeAtClassic", "クラシヂ�なシナリオにおけるキーコード所持�岐�、カード�種類に特殊技能・アイッ�及�手札・召喚獣のぁ�れか単独、また�それら�てを指定しなければ正しく機�しません�); // Wsn.2
	auto warningBranchKeyCodeAtWsn1 = Msg("warningBranchKeyCodeAtWsn1", "Wsn.1以前�シナリオにおけるキーコード所持�岐�、カード�種類に特殊技能・アイッ�・召喚獣のぁ�れか単独、また�それら�てを指定しなければ正しく機�しません�); // Wsn.2
	auto warningBranchKeyCodeWithItem = Msg("warningBranchKeyCodeWithItem", "クラシヂ�なシナリオにおけるキーコード所持�岐でカード�種類にアイッ�が含まれてあ�場合�、戦闘時の手札も検索対象となります�);
	auto warningLoadScaledImage = Msg("warningLoadScaledImage", "スケーリングされたイメージファイルの読み込みは、Wsn.2以降�形式�シナリオに対応したエンジンでしか機�しません�); // Wsn.2
	auto warningPlayerCardEvents = Msg("warningPlayerCardEvents", "プレイヤーカードに対するイベント設定�、Wsn.2以降�形式�シナリオしか行えません�); // Wsn.2
	auto warningCouponHolder = Msg("warningCouponHolder", "適用篛� [称号所有� の挮��、Wsn.2以降�形式�シナリオしか行えません�); // Wsn.2
	auto warningNoHoldingCoupon = Msg("warningNoHoldingCoupon", "篛�挮�用の称号が設定されてぁ�せん�); // Wsn.2
	auto warningCardTarget = Msg("warningCardTarget", "適用篛� [カード�使用対象] の挮��、Wsn.2以降�形式�シナリオしか行えません�); // Wsn.2
	auto warningRefAbility = Msg("warningRefAbility", "選択メンバ�能力参照は、Wsn.2以降�形式�シナリオでしか行えません�); // Wsn.2
	auto warningCenteringY = Msg("warningCenteringY", "縦方向�中央寁�表示は、Wsn.2以降�形式�シナリオでしか行えません�); // Wsn.2
	auto warningBoundaryCheck = Msg("warningBoundaryCheck", "メヂ�ージの禁則処�、Wsn.2以降�形式�シナリオでしか行えません�); // Wsn.2
	auto warningBranchCouponMulti = Msg("warningBranchCouponMulti", "クーポン刲��クーポンの褕�挮��、Wsn.2以降�形式�シナリオしか行えません�); // Wsn.2

	auto unknownStepValue = Msg("unknownStepValue", "存在しなあ�ッ�プ値(%1$s)");

	auto card = Msg("card", "カー�);
	auto apt = Msg("apt", "要�");
	auto useCountAndDesc = Msg("useCountAndDesc", "使用回数/解説");
	auto levelAndDesc = Msg("levelAndDesc", "レベル/解説");
	auto useBonus = Msg("useBonus", "使用ボ�ナス");
	auto haveBonus = Msg("haveBonus", "所持�ーナス");
	auto motion = Msg("motion", "効�);
	auto cardProps = Msg("cardProps", "属性");
	auto settings = Msg("settings", "設�);
	auto seAndKeyCode = Msg("seAndKeyCode", "効果音/キーコー�);
	auto eventIgnite = Msg("eventIgnite", "イベント発火");

	auto rangeHint = Msg("rangeHint", "(%1$s2$s)");
	auto source = Msg("source", "出典");
	auto sourceScenario = Msg("sourceScenario", "シナリオ�);
	auto sourceAuthor = Msg("sourceAuthor", "シナリオ作�);
	auto resetSource = Msg("resetSource", "現在のシナリオを�典に設�);
	auto diffSource = Msg("diffSource", "出典のシナリオ名と作耐�が現在のシナリオと異なるため、使用時イベント�カード�手、エリア移動、パヂ�ージのコール等�実行されません�);

	/// ファイルビュー�	auto dirTabName = Msg("dirTabName", "ファイル");
	auto dirStatus = Msg("dirStatus", "%1$s個�ファイル (%2$s)");
	auto dirStatusSel = Msg("dirStatusSel", "%1$s個�ファイル (%2$s) (%3$s個を選択中)");
	auto fileName = Msg("fileName", "ファイル�);
	auto fileExt = Msg("fileExt", "拡張�);
	auto fileCount = Msg("fileCount", "利用数");
	auto errorExec = Msg("errorExec", "%1$sの起動に失敗しました�);
	auto filterDescZip = Msg("filterDescZip", "ZIP アーカイ�(*.zip)");
	auto filterDescCab = Msg("filterDescCab", "CAB アーカイ�(*.cab)");
	auto filterDescWsn = Msg("filterDescWsn", "シナリオファイル (*.wsn)");
	auto dlgTitCreateArchive = Msg("dlgTitCreateArchive", "シナリオの圧縮");
	auto failedCreateArchive = Msg("failedCreateArchive", "シナリオの圧縮に失�);
	auto dlgMsgIsSaveBeforeCreateArchive = Msg("dlgMsgIsSaveBeforeCreateArchive", "�1$s」�変更されてぁ�す。保存しますか);

	/// エヂ�タ設定ダイアログ�	auto baseSettings = Msg("baseSettings", "基本設�);
	auto reference = Msg("reference", "...");
	auto enginePath = Msg("enginePath", "%1$sの場所");
	auto filterEnginePath = Msg("filterEnginePath", "CardWirthPy (%1$s)");
	auto findEnginePath = Msg("findEnginePath", "シナリオの場所から自動的に探�);
	auto dlgTitEnginePath = Msg("dlgTitEnginePath", "%1$sの場所");
	auto tempDir = Msg("tempDir", "シナリオの一時展開�);
	auto tempDirDesc = Msg("tempDirDesc", "wsn圧縮されたシナリオの一時的な展開先を選択してください�);
	auto backupDir = Msg("backupDir", "自動バヂ�ア�");
	auto backupEnabled = Msg("backupEnabled", "自動バヂ�ア�を行う");
	auto autoSave = Msg("autoSave", "バックア�時に上書き保存す�);
	auto backupArchived = Msg("backupArchived", "圧縮してバックア�する");
	auto backupRefAuthor = Msg("backupRefAuthor", "作老�一致したシナリオのみバックア�する");
	auto backupPath = Msg("backupPath", "保存�");
	auto backupDirDesc = Msg("backupDirDesc", "シナリオを定期皁�自動バヂ�ア�する" ~ DIR ~ "を選択してください�);
	auto backupIntervalTime = Msg("backupIntervalTime", "時間間隔で行う");
	auto backupIntervalEdit = Msg("backupIntervalEdit", "編雛�数で行う");
	auto minute = Msg("minute", "�);
	auto count = Msg("count", "�);
	auto backupCount = Msg("backupCount", "最大保存数");
	auto backupBeforeSaveDir = Msg("backupBeforeSaveDir", "保存時バックア�");
	auto backupBeforeSave = Msg("backupBeforeSave", "保存時バックア�");
	auto backupBeforeSaveDirDesc = Msg("backupDirDesc", "シナリオファイルのバックア�コピ�を作�する" ~ DIR ~ "を選択してください�);
	auto backupBeforeSaveEnabled = Msg("backupBeforeSaveEnabled", "保存時にシナリオファイルのバックア�コピ�を作�する");
	auto backupBeforeSavePath = Msg("backupBeforeSavePath", "保存�");
	auto skin = Msg("skin", "スキン");
	auto scenarioAuthor = Msg("scenarioAuthor", "シナリオ作�新規作�時に自動設定されま�");
	auto historiesSettings = Msg("historiesSettings", "履歴");
	auto openHistoryMax = Msg("openHistoryMax", "シナリオ履歴保存件数");
	auto openHistoryClear = Msg("openHistoryClear", "クリア");
	auto dlgMsgHistoryClear = Msg("dlgMsgHistoryClear", "シナリオ履歴を削除してよろしいですか);
	auto searchHistoryMax = Msg("searchHistoryMax", "検索/置換履歴保存件数");
	auto searchHistoryClear = Msg("searchHistoryClear", "クリア");
	auto dlgMsgSearchHistoryClear = Msg("dlgMsgSearchHistoryClear", "検索/置換履歴を削除してよろしいですか);
	auto ignorePaths = Msg("ignorePaths", "無視ファイル(改行区刂�)");
	auto etcSettings = Msg("etcSettings", "そ��);

	auto etcSettingsTitle = Msg("etcSettingsTitle", "詳細");

	auto imageScale = Msg("imageScale", "表示倍率");
	auto imageScaleValue = Msg("imageScaleValue", "%s�);

	auto languageSetting = Msg("languageSetting", "言�);
	auto languageSystem = Msg("languageSystem", "シスッ�の言�);
	auto languageCaution = Msg("languageCaution", "※ 次回起動時から適用されま�);

	auto etcSettingsCommon = Msg("etcSettingsCommon", "全般");
	auto showImagePreview = Msg("showImagePreview", "カードや背景のプレビュー表示を行う");
	auto maskCardImagePreview = Msg("maskCardImagePreview", "カードサイズの画像�プレビュー表示で背景を透�化す�);
	auto switchTabWheel = Msg("switchTabWheel", "マウスホイールでタブ�替を行う");
	auto closeTabWithMiddleClick = Msg("closeTabWithMiddleClick", "中ボタンクリヂ�でタブを閉じ�);
	auto openTabAtRightOfCurrentTab = Msg("openTabAtRightOfCurrentTab", "新しいタブを現在のタブ�直後に開く");
	auto showCloseButtonAllTab = Msg("showCloseButtonAllTab", "全てのタブに閉じる�タンを表示する");
	auto comboListVisible = Msg("comboListVisible", "コンボ�ヂ�スでの編雖�始時にリストを開く");
	auto editTriggerTypeIsQuick = Msg("editTriggerTypeIsQuick", "選択雮のクリヂ�ですぐにヂ�スト�編雂�開始す�);
	auto xmlCopy = Msg("xmlCopy", "コピ��り取りを常にXML形式で行う");
	auto logicalSort = Msg("logicalSort", "数値参�型ソートを行う(1, 10, 2, 3, ... �1, 2, 3, 10, ...)");
	auto canVanishWorkAreaInMainWindow = Msg("canVanishWorkAreaInMainWindow", "サブウィンドウに編雂�リアがあれ�メインウィンドウの編雂�リアを閉じる");

	auto etcSettingsLoad = Msg("etcSettingsLoad", "読込と保�);
	auto saveNeedChanged = Msg("saveNeedChanged", "変更があった時�け上書き保存を有効にする");
	auto applyDialogsBeforeSave = Msg("applyDialogsBeforeSave", "保存前にダイアログの編�容を適用する");
	auto doubleIO = Msg("doubleIO", "刉�読込・保存を行う(ッ�アルコア以上�環墁�高速化)");
	auto archiveInNewThread = Msg("archiveInNewThread", "保存時の圧縮を別スレッ�で行う(圧縮シナリオの保存�高速化)");
	auto saveChangedOnly = Msg("saveChangedOnly", "上書き時に更新されたファイル�けを保存す�);
	auto expandXMLs = Msg("expandXMLs", "圧縮されたシナリオの読込み時にXMLファイルを展開する");
	auto xmlFileNameIsIDOnly = Msg("xmlFileNameIsIDOnly", "XMLファイルの名前にエリア名などを含めずIDのみで設定す�);
	auto saveInnerImagePath = Msg("saveInnerImagePath", "クラシヂ�なシナリオで格納イメージのファイルパスを保存す�);
	auto addNewClassicEngine = Msg("addNewClassicEngine", "未知のクラシヂ�エンジンを見つけたら記�する");
	auto openLastScenario = Msg("openLastScenario", "終亙�に開いてぁ�シナリオを次の起動時に開く");
	auto reconstruction = Msg("reconstruction", "シナリオごとにタブ�配置を記�する");
	auto createStartArea = Msg("createStartArea", "シナリオの新規作�時に開始エリアを作�する");

	auto etcSettingsFile = Msg("etcSettingsFile", "ファイルの追跡");
	auto traceDirectories = Msg("traceDirectories", "ファイル・" ~ DIR ~ "の変更を�動的に追跡する");
	auto autoUpdateJpy1File = Msg("autoUpdateJpy1File", "ファイル名が変更された時に関係するJPY1・JPDCファイルを�動的に更新する");

	auto etcSettingsFind = Msg("etcSettingsFind", "検索と置�);
	auto startIncrementalSearchWhenKeyDown = Msg("startIncrementalSearchWhenKeyDown", "何かキーを押した時に絞り込み検索を開始す�);
	auto cautionBeforeReplace = Msg("cautionBeforeReplace", "全て置換する前に確認ダイアログを表示する");

	auto etcSettingsTable = Msg("etcSettingsTable", "�ブルビューの設�);
	auto showAreaDirTree = Msg("showAreaDirTree", "�ブルビューを階層表示する");
	auto showSummaryInAreaTable = Msg("showSummaryInAreaTable", "�ブルビューにシナリオの概要を表示する");
	auto clickIsOpenEvent = Msg("clickIsOpenEvent", "左クリヂ�でイベントビューを開�);

	auto etcSettingsScene = Msg("etcSettingsScene", "シーンビューの設�);
	auto smoothingCard = Msg("smoothingCard", "カード�サイズ変更時にス�ージングを行う");
	auto ignoreBackgroundInRange = Msg("ignoreBackgroundInRange", "篛�選択でフルサイズの背景セルを無視す�);
	auto copyDesc = Msg("copyDesc", "カードをエリアに貼り付け・ドロ�した時、解説もコピ�する");

	auto etcSettingsEvent = Msg("etcSettingsEvent", "イベントビューの設�);
	auto showContentsGroupName = Msg("showContentsGroupName", "コンッ��ヂ�スにグループ名を表示する");
	auto showEventContentDescription = Msg("showEventContentDescription", "イベントコンッ�ト�解説をツールチップで表示する");
	auto contentsFloat = Msg("contentsFloat", "コンッ��ヂ�スを別ウィンドウで表示する");
	auto contentsAutoHide = Msg("contentsAutoHide", "コンッ��ヂ�スを�動的に��);
	auto straightEventTreeView = Msg("straightEventTreeView", "イベントツリーを垂直に表示する");
	auto forceIndentBranchContent = Msg("forceIndentBranchContent", "垂直表示時に刲�コンッ�ト�後続コンッ�ト�忁�右へ移動す�);
	auto showTerminalMark = Msg("showTerminalMark", "垂直表示時にイベントツリーの終端を�示する");
	auto classicStyleTree = Msg("classicStyleTree", "ッ�ー表示時、イベントツリーの開閉ボタンを省略する");
	auto clickIconIsStartEdit = Msg("clickIconIsStartEdit", "イベントコンッ�ト�アイコンのクリヂ�でダイアログを開�);
	auto adjustContentName = Msg("adjustContentName", "イベントコンッ�ト�移動時にヂ�ストを再設定す�);
	auto showVariableValuesInEventText = Msg("showVariableValuesInEventText", "選択肢のヂ�スト�の変数を�レビュー表示する(#M -> [選択中]...)");
	auto refCardsAtEditBgImage = Msg("refCardsAtEditBgImage", "背景変更コンッ�ト�編雂�開始する際、最初からカード�置の参�を行う");
	auto floatMessagePreview = Msg("floatMessagePreview", "台詞�メヂ�ージのプレビューをフロートさせる");
	auto selectVariableWithTree = Msg("selectVariableWithTree", "状態変数選択ビューでヂ�レクトリの階層表示を行う");
	auto useNamesAfterStandard = Msg("useNamesAfterStandard", "シナリオで使用中の称号・キーコードを標準�称号・キーコード�後に配置する");
	auto expandChooserItems = Msg("expandChooserItems", "エリアり�態変数等を選択するビューでは全て開いた状態を初期状態とする");

	auto etcSettingsCard = Msg("etcSettingsCard", "カードビューの設�);
	auto showEventTreeMark = Msg("showEventTreeMark", "カード�詳細惱表示時に使用時イベント�有無を表示する");
	auto ignoreEmptyStart = Msg("ignoreEmptyStart", "空のイベントツリーしか持たなぽ�用時イベント�無視す�);
	auto showCardListHeader = Msg("showCardListHeader", "カード�画像表示時にヘッダを表示する");
	auto showCardListTitle = Msg("showCardListTitle", "カード�画像表示時にIDと名前を表示する");
	auto showSkillCardLevel = Msg("showSkillCardLevel", "カード�画像表示時に特殊技能カード�レベルを表示する");
	auto showMotionDescription = Msg("showMotionDescription", "効果�解説をツールチップで表示する");
	auto showSpNature = Msg("showSpNature", "特殊型を表示する");
	auto radarStyleParams = Msg("radarStyleParams", "レーダー型コントロールでパラメータ値を設定す�);
	auto linkCard = Msg("linkCard", "クラシヂ�なシナリオでキャスト�所有カードや召喚対象カードを参�で設定す�);

	auto soundPlayType = Msg("soundPlayType", "BGM再生方�);
	auto soundPlayTypeDef = Msg("soundPlayTypeDef", "自動選�);
	auto soundPlayTypeSDL = Msg("soundPlayTypeSDL", "SDL(CardWirthPy方�");
	auto soundPlayTypeMCI = Msg("soundPlayTypeMCI", "WinMM(CardWirth方�");
	auto soundPlayTypeApp = Msg("soundPlayTypeApp", "関連付けされたアプリケーションで開く");
	auto soundEffectPlayType = Msg("soundEffectPlayType", "効果音再生方�);
	auto soundPlaySameBGM = Msg("soundPlaySameBGM", "BGMに合わせる");
	auto soundVolume = Msg("soundVolume", "音�);
	auto soundVolumePer = Msg("soundVolumePer", "%");
	auto soundCaution = Msg("soundCaution", "※ WinMM方式�時〟�量�反映されません");

	auto flagInitValue = Msg("flagInitValue", "フラグの初期値");
	auto stepInitValue = Msg("stepInitValue", "スッ�プ�初期値");

	auto keyBind = Msg("keyBind", "キーバイン�);
	auto mnemonic = Msg("mnemonic", "アクセスキー");
	auto hotkey = Msg("hotkey", "ショートカッ�");

	auto wallpaper = Msg("wallpaper", "エヂ�タの壁�);
	auto filterWallpaper = Msg("filterWallpaper", "画像ファイル (*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.ico;*.icon)");
	auto dlgTitWallpaper = Msg("dlgTitWallpaper", "壁紙画像�選�);
	auto wallpaperStyle = Msg("wallpaperStyle", "表示形�);
	const string wallpaperStyleName(WallpaperStyle id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(WallpaperStyle, "wallpaperStyleName"));
	}
	auto wallpaperStyleNameCenter = Msg("wallpaperStyleNameCenter", "中央に表示");
	auto wallpaperStyleNameTile = Msg("wallpaperStyleNameTile", "並べて表示");
	auto wallpaperStyleNameExpandFull = Msg("wallpaperStyleNameExpandFull", "拡大して表示");
	auto wallpaperStyleNameExpand = Msg("wallpaperStyleNameExpand", "はみ出さなあ�ぁ�拡大");

	auto bgImageAndSelections = Msg("bgImageAndSelections", "背景と選択肢");
	auto standardSelections = Msg("standardSelections", "標準�選択肢");
	auto standardKeyCode = Msg("standardKeyCode", "標準�キーコー�);

	auto errorEnginePath = Msg("errorEnginePath", "%1$sの場所が正しくありません�);
	auto errorTempPath = Msg("errorTempPath", "一時展開先が正しくありません�);
	auto errorBackupPath = Msg("errorBackupPath", "自動バヂ�ア�先が正しくありません�);
	auto errorBackupBeforeSavePath = Msg("errorBackupBeforeSavePath", "保存時バックア�先が正しくありません�);

	auto sNew = Msg("sNew", "新規作�");
	auto sAlt = Msg("sAlt", "上書�);
	auto sDel = Msg("sDel", "削除");
	auto dlgMsgForceApply = Msg("dlgMsgForceApply", "次の設定が変更されたまま適用されてぁ�せん。適用して設定を更新しますか�\n%1$s");
	auto dlgMsgForceApplySingle = Msg("dlgMsgForceApplySingle", "%1$sが変更されたまま適用されてぁ�せん。適用して設定を更新しますか);
	auto dlgMsgForceApplySelection = Msg("dlgMsgForceApplySelection", "�1$s」が変更されたまま適用されてぁ�せん。適用して他�頛�を選択しますか);
	auto noNameData = Msg("noNameData", "(名前無し�頛�)");

	auto outerToolsAndClassicEngines = Msg("outerToolsAndClassicEngines", "外部�ルとクラシヂ�エンジン");
	auto outerToolsTitle = Msg("outerToolsTitle", "外部�ルの設�);
	auto outerToolName = Msg("outerToolName", "外部�ル�);
	auto outerToolCommand = Msg("outerToolCommand", "コマン�);
	auto dlgTitOuterTool = Msg("dlgTitOuterTool", "外部�ルの選�);
	auto toolsHint1 = Msg("toolsHint1", "$F = ファイル�);
	auto toolsHint3 = Msg("toolsHint3", "$$ = $");
	auto outerToolWorkDir = Msg("outerToolWorkDir", "作業" ~ DIR);
	auto toolWorkDir = Msg("toolWorkDir", "作業" ~ DIR ~ "の選�);
	auto toolWorkDirDesc = Msg("toolWorkDirDesc", "外部�ルの作業" ~ DIR ~ "を選択してください�);
	auto toolsHint2 = Msg("toolsHint2", "$S = シナリオの" ~ DIR);

	auto templates = Msg("templates", "ッ�プレー�);
	auto eventTemplatesTitle = Msg("eventTemplatesTitle", "イベントテンプレート�設�);
	auto eventTemplateName = Msg("eventTemplateName", "ッ�プレート名");
	auto eventTemplateScript = Msg("eventTemplateScript", "スクリプト");

	auto scenarioTemplatesTitle = Msg("scenarioTemplatesTitle", "シナリオッ�プレート�設�);
	auto scenarioTemplateName = Msg("scenarioTemplateName", "ッ�プレート名");
	auto scenarioTemplatePath = Msg("scenarioTemplatePath", "シナリオの場所");
	auto dlgTitScTemplate = Msg("dlgTitScTemplate", "ッ�プレートシナリオの選�);

	auto exeFileDescExe = Msg("exeFileDescExe", "実行ファイル (*.exe)");
	auto exeFileDescAll = Msg("exeFileDescAll", "すべてのファイル (*.*)");

	auto classicEnginesTitle = Msg("classicEnginesTitle", "クラシヂ�エンジンの設�);
	auto classicEngineName = Msg("classicEngineName", "エンジン�);
	auto classicEnginePath = Msg("classicEnginePath", "実行ファイルパス");
	auto classicEngineDataDirName = Msg("classicEngineDataDirName", "�タフォルダ");
	auto classicEngineDataDirNameDesc = Msg("classicEngineDataDirNameDesc", "クラシヂ�エンジンの�タフォルダを選択してください�);
	auto classicEngineExecute = Msg("classicEngineExecute", "代替実行ファイル");
	auto classicEngineHint1 = Msg("classicEngineHint1", "※ 代替実行ファイルを指定すると、エンジン本体�代わりに実行されま�);
	auto dlgTitClassicEnginePath = Msg("dlgTitClassicEnginePath", "クラシヂ�エンジンの選�);
	auto dlgTitClassicEngineExecute = Msg("dlgTitClassicEngineExecute", "代替実行ファイルの選�);

	auto featureName = Msg("featureName", "シスッ�断��");
	auto dlgTitFeatureName = Msg("dlgTitFeatureName", "シスッ�断��");
	auto featureDefaultName = Msg("featureDefaultName", "標�);
	auto featureVariantName = Msg("featureVariantName", "バリアン�);
	auto featureManualName = Msg("featureManualName", "ユーザ設�);

	auto bgImagesDefault = Msg("bgImagesDefault", "ッ�ォルト背景");
	auto setBgImagesDefault = Msg("setBgImagesDefault", "ッ�ォルト背景の設�..");
	auto dlgTitBgImagesDefault = Msg("dlgTitBgImagesDefault", "ッ�ォルト背景の設�);

	auto systemSounds = Msg("systemSounds", "シスッ�音声");
	auto soundSaved = Msg("soundSaved", "保存完�);
	auto playableSounds = Msg("playableSounds", "サウンドファイル (%1$s)");
	auto dlgTitSystemSound = Msg("dlgTitSystemSound", "シスッ�音声の選�);

	auto undoMax = Msg("undoMax", "「�に戻す」回数");
	auto undoMaxMainView = Msg("undoMaxMainView", "エリア/カー�フラグ");
	auto undoMaxEvent = Msg("undoMaxEvent", "メニュー/エネミー/背景/イベン�);
	auto undoMaxReplace = Msg("undoMaxReplace", "置�);
	auto undoMaxEtc = Msg("undoMaxEtc", "ヂ�ス�そ��);

	auto dialogStatus = Msg("dialogStatus", "台詞コンッ�ト�ス�タス");
	const string dialogStatusName(DialogStatus id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(DialogStatus, "dialogStatusName"));
	}
	auto dialogStatusNameTop = Msg("dialogStatusNameTop", "最上位�台�);
	auto dialogStatusNameUnder = Msg("dialogStatusNameUnder", "最下位�台�);
	auto dialogStatusNameUnderWithCoupon = Msg("dialogStatusNameUnderWithCoupon", "最下位�台�条件クーポン設定あ�");

	auto dlgTitEvTemplates = Msg("dlgTitEvTemplates", "イベントテンプレー�- %1$s");
	auto eventTemplateHint1 = Msg("eventTemplateHint1", "下記�ようにスクリプトの冒�に値の無つ�数を置くと、テンプレートから�配置時に値を設定できます�);
	auto eventTemplateHint2 = Msg("eventTemplateHint2", "$時間\nwait $時間");

	auto dlgTitCustomizeToolBar = Msg("dlgTitCustomizeToolBar", "�ルバ�の編�);
	auto toolBarName = Msg("toolBarName", "�ルバ� (%1$s)");
	auto toolGroupName = Msg("toolGroupName", "グルー�(%1$s)");

	/// スクリプト関係�	auto dlgTitScriptError = Msg("dlgTitScriptError", "CWXスクリプトエラー");
	auto scriptError = Msg("scriptError", "CWXスクリプトのコンパイル中にエラーが発生しました�);
	auto scriptErrorOver100Error = Msg("scriptErrorOver100Error", "エラー�00件を趁�たため、スクリプトの解析を終亁�ます�);
	auto scriptErrorInvalidToken = Msg("scriptErrorInvalidToken", "スクリプトに使用できなざ�字が含まれてぁ�す�);
	auto scriptErrorInvalidSyntax = Msg("scriptErrorInvalidSyntax", "構文が正しくありません�);
	auto scriptErrorInvalidString = Msg("scriptErrorInvalidString", "ここに断��が忦�です�);
	auto scriptErrorUnCloseString = Msg("scriptErrorUnCloseString", "断��が閉じられてぁ�せん�);
	auto scriptErrorUnOpenComment = Msg("scriptErrorUnOpenComment", "コメント�開始されてぁ�せん�);
	auto scriptErrorUnCloseComment = Msg("scriptErrorUnCloseComment", "コメントが閉じられてぁ�せん�);
	auto scriptErrorInvalidNumber = Msg("scriptErrorInvalidNumber", "数値が正しくありません�);
	auto scriptErrorCloseBracketNotFound = Msg("scriptErrorCloseBracketNotFound", "閉じ括弧が見つかりません�);
	auto scriptErrorCloseParenNotFound = Msg("scriptErrorCloseParenNotFound", "閉じ括弧が見つかりません�);
	auto scriptErrorZeroDivision = Msg("scriptErrorZeroDivision", "0で除算を行いました�);
	auto scriptErrorInvalidAttr = Msg("scriptErrorInvalidAttr", "属性が正しくありません�);
	auto scriptErrorInvalidVar = Msg("scriptErrorInvalidVar", "変数が正しくありません�);
	auto scriptErrorInvalidVarVal = Msg("scriptErrorInvalidVarVal", "変数の値が正しくありません�);
	auto scriptErrorNoStartText = Msg("scriptErrorNoStartText", "スタートコンッ�ト�名前がありません�);
	auto scriptErrorInvalidStatement = Msg("scriptErrorInvalidStatement", "斁�正しくありません�);
	auto scriptErrorInvalidBranch = Msg("scriptErrorInvalidBranch", "刲��構�が正しくありません�);
	auto scriptErrorNoIfContents = Msg("scriptErrorNoIfContents", "刲��のコンッ�トが見つかりません�);
	auto scriptErrorInvalidKeyword = Msg("scriptErrorInvalidKeyword", "未知のキーワードです�);
	auto scriptErrorInvalidKeyword2 = Msg("scriptErrorInvalidKeyword2", "キーワードが正しくありません�);
	auto scriptErrorInvalidValuesOpen = Msg("scriptErrorInvalidValuesOpen", "パラメータ列ではありません�);
	auto scriptErrorInvalidValuesClose = Msg("scriptErrorInvalidValuesClose", "閉じ括弧が見つかりません�);
	auto scriptErrorNoVarSet = Msg("scriptErrorNoVarSet", "変数に値をセッ�してぁ�せん�);
	auto scriptErrorNoVarVal = Msg("scriptErrorNoVarVal", "変数の値がありません�);
	auto scriptErrorInvalidCalc = Msg("scriptErrorInvalidCalc", "計算式が不正です�);
	auto scriptErrorInvalidBoolVal = Msg("scriptErrorInvalidBoolVal", "キーワードが正しくありません�);
	auto scriptErrorInvalidTransition = Msg("scriptErrorInvalidTransition", "未知の画面创�方式です�);
	auto scriptErrorInvalidRange = Msg("scriptErrorInvalidRange", "未知の篛�です�);
	auto scriptErrorInvalidStatus = Msg("scriptErrorInvalidStatus", "未知のス�タスです�);
	auto scriptErrorInvalidTarget = Msg("scriptErrorInvalidTarget", "未知のターゲッ�です�);
	auto scriptErrorInvalidEffectType = Msg("scriptErrorInvalidEffectType", "未知の効果属性です�);
	auto scriptErrorInvalidResist = Msg("scriptErrorInvalidResist", "未知の命中属性です�);
	auto scriptErrorInvalidCardVisual = Msg("scriptErrorInvalidCardVisual", "未知の視覚効果です�);
	auto scriptErrorInvalidMental = Msg("scriptErrorInvalidMental", "未知の精神要�です�);
	auto scriptErrorInvalidPhysical = Msg("scriptErrorInvalidPhysical", "未知の肉体要�です�);
	auto scriptErrorInvalidMotionType = Msg("scriptErrorInvalidMotionType", "未知の効果タイプです�);
	auto scriptErrorInvalidMotion = Msg("scriptErrorInvalidMotion", "効果が正しくありません�);
	auto scriptErrorInvalidElement = Msg("scriptErrorInvalidElement", "未知の属性です�);
	auto scriptErrorInvalidDamageType = Msg("scriptErrorInvalidDamageType", "未知のダメージタイプです�);
	auto scriptErrorInvalidEffectCardType = Msg("scriptErrorInvalidEffectCardType", "未知の効果カードタイプです�);
	auto scriptErrorInvalidComparison4 = Msg("scriptErrorInvalidComparison4", "未知の比輝�件です�);
	auto scriptErrorInvalidComparison3 = Msg("scriptErrorInvalidComparison3", "未知の比輝�件です�);
	auto scriptErrorInvalidBgImage = Msg("scriptErrorInvalidBgImage", "背景画像が正しくありません�);
	auto scriptErrorInvalidColor = Msg("scriptErrorInvalidColor", "色が正しくありません�);
	auto scriptErrorInvalidBlendMode = Msg("scriptErrorInvalidBlendMode", "未知の合�方式です�);
	auto scriptErrorInvalidGradientDir = Msg("scriptErrorInvalidGradientDir", "未知のグラ�ション方向です�);
	auto scriptErrorInvalidSelectionMethod = Msg("scriptErrorInvalidSelectionMethod", "未知のメンバ選択方法です�);
	auto scriptErrorInvalidDialog = Msg("scriptErrorInvalidDialog", "台詞が正しくありません�);
	auto scriptErrorInvalidTalker = Msg("scriptErrorInvalidTalker", "話老�正しくありません�);
	auto scriptErrorInvalidCoupon = Msg("scriptErrorInvalidCoupon", "評価条件が正しくありません�);
	auto scriptErrorUndefinedSymbol = Msg("scriptErrorUndefinedSymbol", "未知のシンボルです�);
	auto scriptErrorInvalidSif = Msg("scriptErrorInvalidSif", "ここにsifが現れる事�できません�);
	auto scriptErrorInvalidCommand = Msg("scriptErrorInvalidCommand", "命令が正しくありません�);
	auto scriptErrorCanNotHaveContent = Msg("scriptErrorCanNotHaveContent", "こ�コンッ�トが後続コンッ�トを持つ事�できません�);
	auto scriptErrorInvalidStr = Msg("scriptErrorInvalidStr", "断��が正しくありません�);
	auto scriptErrorReqNumber = Msg("scriptErrorReqNumber", "ここに数値が忦�です�);
	auto scriptErrorReqID = Msg("scriptErrorReqID", "ここにIDが忦�です�);
	auto scriptErrorUndefinedVar = Msg("scriptErrorUndefinedVar", "存在しなつ�数です�);
	auto scriptErrorInvalidValue = Msg("scriptErrorInvalidValue", "値が正しくありません�);
	auto scriptErrorInvalidCoordinateType = Msg("scriptErrorInvalidCoordinateType", "未知の位置・サイズ形式です�);
	auto scriptErrorInvalidArray = Msg("scriptErrorInvalidArray", "ここに配�が忦�です�);
	auto scriptErrorSystem = Msg("scriptErrorSystem", "サイズが大きすぎるため、CWXスクリプトをコンパイルできません�);
	auto scriptErrorInvalidCardImagePosition = Msg("scriptErrorInvalidCardImagePosition", "イメージの配置形式が正しくありません�);
	auto scriptErrorInvalidStartAction = Msg("scriptErrorInvalidStartAction", "未知の戦闘行動開始タイミングです�); // Wsn.2
	auto scriptErrorInvalidMatchingType = Msg("scriptErrorInvalidMatchingType", "未知の判定条件です�); // Wsn.2

	auto dlgTitScriptVarSet = Msg("dlgTitScriptVarSet", "値が未決定�変数の設�);
	auto scriptVarSet = Msg("scriptVarSet", "変数に値を��);
	auto scriptVarNameColumn = Msg("scriptVarNameColumn", "変数�);
	auto scriptVarValueColumn = Msg("scriptVarValueColumn", "値");
	auto material = Msg("material", "ファイル");
	auto coupon = Msg("coupon", "クーポン");
	auto gossip = Msg("gossip", "ゴシ�");
	auto completeStamp = Msg("completeStamp", "終亍�");

	auto jpyErrorInfoWithoutFile = Msg("jpyErrorInfoWithoutFile", "%1$s (%2$s 行目)");
	auto jpyError = Msg("jpyError", "%1$s\n%2$s の %3$s 行目");
	auto jpyErrorDupSection = Msg("jpyErrorDupSection", "セクション名が重褁�てま� %1$s");
	auto jpyErrorInvalidPoint = Msg("jpyErrorInvalidPoint", "位置の書式が正しくありません: %1$s");
	auto jpyErrorInvalidRect = Msg("jpyErrorInvalidRect", "位置とサイズの書式が正しくありません: %1$s");
	auto jpyErrorInvalidRGB = Msg("jpyErrorInvalidRGB", "値が正しくありません: %1$s");
	auto jpyErrorInvalidEnum = Msg("jpyErrorInvalidEnum", "数値でなければなりません: %1$s");
	auto jpyErrorInvalidStr = Msg("jpyErrorInvalidStr", "断�コードが正しくありません: %1$s");
	auto jpyErrorInvalidInt = Msg("jpyErrorInvalidInt", "数値でなければなりません: %1$s");
	auto jpyErrorInvalidBool = Msg("jpyErrorInvalidBool", "真偽値が正しくありません: %1$s");
	auto jpyErrorInvalidEncoding = Msg("jpyErrorInvalidEncoding", "断�コードが不正です�);
	auto jpyErrorInvalidLine = Msg("jpyErrorInvalidLine", "コマンドか値のどちらかが�けてぁ�� %1$s");
	auto jpyErrorInvalidCommand = Msg("jpyErrorInvalidCommand", "コマンドが正しくありません: %1$s");
	auto jpyErrorInvalidStartTag = Msg("jpyErrorInvalidStartTag", "開始タグが正しくありません: %1$s");
	auto jpyErrorLabelNotFound = Msg("jpyErrorLabelNotFound", "セクションがありません�);

	/// メニュー�	const string menuText(MenuID id) { mixin(S_TRACE);
		mixin(EnumToStringSwitch!(MenuID, "menuText"));
	}

	auto menuTextNone = Msg("menuTextNone", "");

	auto menuTextFile = Msg("menuTextFile", "ファイル");
	auto menuTextEdit = Msg("menuTextEdit", "編�);
	auto menuTextView = Msg("menuTextView", "表示");
	auto menuTextTool = Msg("menuTextTool", "�ル");
	auto menuTextTable = Msg("menuTextTable", "�ブル");
	auto menuTextVariable = Msg("menuTextVariable", "状態変数");
	auto menuTextHelp = Msg("menuTextHelp", "ヘル�);
	auto menuTextCard = Msg("menuTextCard", "カー�);
	auto menuTextCardsAndBacks = Msg("menuTextCardsAndBacks", "カードと背景");

	auto menuTextDelNotUsedFile = Msg("menuTextDelNotUsedFile", "未使用のファイルを削除");
	auto menuTextCreateSubWindow = Msg("menuTextCreateSubWindow", "新しいウィンドウで開く");
	auto menuTextLeftPane = Msg("menuTextLeftPane", "左のタ�);
	auto menuTextRightPane = Msg("menuTextRightPane", "右のタ�);
	auto menuTextClosePane = Msg("menuTextClosePane", "閉じ�);
	auto menuTextClosePaneExcept = Msg("menuTextClosePaneExcept", "他�タブを閉じ�);
	auto menuTextClosePaneLeft = Msg("menuTextClosePaneLeft", "左側のタブを閉じ�);
	auto menuTextClosePaneRight = Msg("menuTextClosePaneRight", "右側のタブを閉じ�);
	auto menuTextClosePaneAll = Msg("menuTextClosePaneAll", "全てのタブを閉じ�);
	auto menuTextNew = Msg("menuTextNew", "新規作�");
	auto menuTextOpen = Msg("menuTextOpen", "開く");
	auto menuTextNewAtNewWindow = Msg("menuTextNewAtNewWindow", "新しいウィンドウで新規作�");
	auto menuTextOpenAtNewWindow = Msg("menuTextOpenAtNewWindow", "新しいウィンドウで開く");
	auto menuTextClose = Msg("menuTextClose", "閉じ�);
	auto menuTextCloseWin = Msg("menuTextCloseWin", "閉じ�);
	auto menuTextSave = Msg("menuTextSave", "上書き保�);
	auto menuTextSaveAs = Msg("menuTextSaveAs", "名前を付けて保�);
	auto menuTextReload = Msg("menuTextReload", "再読込");
	auto menuTextOpenDir = Msg("menuTextOpenDir", "シナリオの" ~ DIR ~ "を開�);
	auto menuTextOpenBackupDir = Msg("menuTextOpenBackupDir", "バックア�" ~ DIR ~ "を開�);
	auto menuTextOpenPlace = Msg("menuTextOpenPlace", "ファイルの場所を開�);
	auto menuTextSaveImage = Msg("menuTextSaveImage", "格納イメージをファイルに保�);
	auto menuTextIncludeImage = Msg("menuTextIncludeImage", "イメージを�納す�);
	auto menuTextLookImages = Msg("menuTextLookImages", "画像を一覧表示");
	auto menuTextEditLayers = Msg("menuTextEditLayers", "レイヤの編�);
	auto menuTextAddLayer = Msg("menuTextAddLayer", "レイヤの追�");
	auto menuTextRemoveLayer = Msg("menuTextRemoveLayer", "レイヤの削除");
	auto menuTextShowMainToolBar = Msg("menuTextShowMainToolBar", "全体ツールバ�を表示");
	auto menuTextShowSceneToolBar = Msg("menuTextShowSceneToolBar", "シーンビューの�ルバ�を表示");
	auto menuTextShowEventToolBar = Msg("menuTextShowEventToolBar", "イベントビューの�ルバ�を表示");
	auto menuTextChangeVH = Msg("menuTextChangeVH", "刉�領域の縦横を�替");
	auto menuTextSelectConnectedResource = Msg("menuTextSelectConnectedResource", "関係するリソースを選�);
	auto menuTextFind = Msg("menuTextFind", "検索と置�);
	auto menuTextFindID = Msg("menuTextFindID", "参�を検索");
	auto menuTextIncSearch = Msg("menuTextIncSearch", "絞り込み検索");
	auto menuTextCloseIncSearch = Msg("menuTextCloseIncSearch", "閉じ�);
	auto menuTextEditProp = Msg("menuTextEditProp", "編�);
	auto menuTextShowProp = Msg("menuTextShowProp", "詳細");
	auto menuTextRefresh = Msg("menuTextRefresh", "最新の惱に更新");
	auto menuTextUndo = Msg("menuTextUndo", "允�戻�);
	auto menuTextRedo = Msg("menuTextRedo", "も�直�);
	auto menuTextCut = Msg("menuTextCut", "刂�取り");
	auto menuTextCopy = Msg("menuTextCopy", "コピ�");
	auto menuTextPaste = Msg("menuTextPaste", "貼り付け");
	auto menuTextDelete = Msg("menuTextDelete", "削除");
	auto menuTextCut1Content = Msg("menuTextCut1Content", "1コンッ�ト�り取�);
	auto menuTextCopy1Content = Msg("menuTextCopy1Content", "1コンッ�トコピ�");
	auto menuTextDelete1Content = Msg("menuTextDelete1Content", "1コンッ�ト削除");
	auto menuTextPasteInsert = Msg("menuTextPasteInsert", "クリ�ボ�ドから挿入");
	auto menuTextClone = Msg("menuTextClone", "褣�");
	auto menuTextSelectAll = Msg("menuTextSelectAll", "すべて選�);
	auto menuTextCopyAll = Msg("menuTextCopyAll", "すべてコピ�");
	auto menuTextToXMLText = Msg("menuTextToXMLText", "コピ�した�タをXMLに変換");
	auto menuTextTableView = Msg("menuTextTableView", "�ブルビュー");
	auto menuTextVarView = Msg("menuTextVarView", "状態変数ビュー");
	auto menuTextCardView = Msg("menuTextCardView", "カードビュー");
	auto menuTextCastView = Msg("menuTextCastView", "キャストカードビュー");
	auto menuTextSkillView = Msg("menuTextSkillView", "特殊技能カードビュー");
	auto menuTextItemView = Msg("menuTextItemView", "アイッ�カードビュー");
	auto menuTextBeastView = Msg("menuTextBeastView", "召喚獣カードビュー");
	auto menuTextInfoView = Msg("menuTextInfoView", "惱カードビュー");
	auto menuTextFileView = Msg("menuTextFileView", "ファイルビュー");
	auto menuTextExecEngine = Msg("menuTextExecEngine", "エンジン起�);
	auto menuTextExecEngineAuto = Msg("menuTextExecEngineAuto", "自動選�);
	auto menuTextExecEngineMain = Msg("menuTextExecEngineMain", "CardWirthPy");
	auto menuTextExecEngineWithParty = Msg("menuTextExecEngineWithParty", "シナリオを開�);
	auto menuTextExecEngineWithLastParty = Msg("menuTextExecEngineWithLastParty", "前回のパ�ヂ�で開�);
	auto menuTextOuterTools = Msg("menuTextOuterTools", "外部�ル");
	auto menuTextSettings = Msg("menuTextSettings", "エヂ�タ設�);
	auto menuTextVersionInfo = Msg("menuTextVersionInfo", "バ�ジョン惱");
	auto menuTextLockToolBar = Msg("menuTextLockToolBar", "�ルバ�を固�);
	auto menuTextResetToolBar = Msg("menuTextResetToolBar", "配置をリセッ�");
	auto menuTextCopyAsText = Msg("menuTextCopyAsText", "ヂ�ストとしてコピ�");
	auto menuTextOpenAtView = Msg("menuTextOpenAtView", "ビューで開く");
	auto menuTextEventToPackage = Msg("menuTextEventToPackage", "こ�イベントをパッケージ化す�);
	auto menuTextStartToPackage = Msg("menuTextStartToPackage", "こ�ッ�ーをパヂ�ージ化す�);
	auto menuTextWrapTree = Msg("menuTextWrapTree", "ここから別のッ�ーにする");
	auto menuTextCreateContent = Msg("menuTextCreateContent", "コンッ�ト�作�");
	auto menuTextConvertContent = Msg("menuTextConvertContent", "変換");
	auto menuTextCGroupTerminal = Msg("menuTextCGroupTerminal", "開�終端");
	auto menuTextCGroupStandard = Msg("menuTextCGroupStandard", "基本");
	auto menuTextCGroupData = Msg("menuTextCGroupData", "変数操�刲);
	auto menuTextCGroupUtility = Msg("menuTextCGroupUtility", "状況��);
	auto menuTextCGroupBranch = Msg("menuTextCGroupBranch", "保有刲);
	auto menuTextCGroupGet = Msg("menuTextCGroupGet", "取�);
	auto menuTextCGroupLost = Msg("menuTextCGroupLost", "喪失");
	auto menuTextCGroupVisual = Msg("menuTextCGroupVisual", "外観操�);
	auto menuTextEditSummary = Msg("menuTextEditSummary", "シナリオの設�);
	auto menuTextNewAreaDir = Msg("menuTextNewAreaDir", "フォルダの作�");
	auto menuTextNewArea = Msg("menuTextNewArea", "エリアの作�");
	auto menuTextNewBattle = Msg("menuTextNewBattle", "バトルの作�");
	auto menuTextNewPackage = Msg("menuTextNewPackage", "パッケージの作�");
	auto menuTextReNumberingAll = Msg("menuTextReNumberingAll", "全てのID�から振り直�);
	auto menuTextReNumbering = Msg("menuTextReNumbering", "IDの振り直�);
	auto menuTextEditScene = Msg("menuTextEditScene", "シーンビューを開�);
	auto menuTextEditSceneDup = Msg("menuTextEditSceneDup", "新しいビューを開�);
	auto menuTextEditEvent = Msg("menuTextEditEvent", "イベントビューを開�);
	auto menuTextEditEventDup = Msg("menuTextEditEventDup", "新しいビューを開�);
	auto menuTextSetStartArea = Msg("menuTextSetStartArea", "開始エリアにする");
	auto menuTextNewFlagDir = Msg("menuTextNewFlagDir", "フォルダの作�");
	auto menuTextNewFlag = Msg("menuTextNewFlag", "フラグの作�");
	auto menuTextNewStep = Msg("menuTextNewStep", "スッ�プ�作�");
	auto menuTextCreateStepValues = Msg("menuTextCreateStepValues", "スッ�プ値の自動生�);
	auto menuTextCreateVariableEventTree = Msg("menuTextCreateVariableEventTree", "イベントツリーとしてコピ�");
	auto menuTextInitVariablesTree = Msg("menuTextInitVariablesTree", "初期値の設�);
	auto menuTextCopyVariablePath = Msg("menuTextCopyVariablePath", "状態変数のパスをコピ�");
	auto menuTextUp = Msg("menuTextUp", "選択中のアイッ�を上へ移�);
	auto menuTextDown = Msg("menuTextDown", "選択中のアイッ�を下へ移�);
	auto menuTextReverse = Msg("menuTextReverse", "送�する");
	auto menuTextSwapToParent = Msg("menuTextSwapToParent", "親コンッ�トと入れ替える");
	auto menuTextSwapToChild = Msg("menuTextSwapToChild", "子コンッ�トと入れ替える");
	auto menuTextOverDialog = Msg("menuTextOverDialog", "上�台詞へ移�);
	auto menuTextUnderDialog = Msg("menuTextUnderDialog", "下�台詞へ移�);
	auto menuTextShowParty = Msg("menuTextShowParty", "パ�ヂ�カード�表示");
	auto menuTextShowMsg = Msg("menuTextShowMsg", "メヂ�ージ�の表示");
	auto menuTextShowRefCards = Msg("menuTextShowRefCards", "カード参照の表示");
	auto menuTextFixedCards = Msg("menuTextFixedCards", "カード�固�);
	auto menuTextFixedCells = Msg("menuTextFixedCells", "背景の固�);
	auto menuTextFixedBackground = Msg("menuTextFixedBackground", "最初�フルサイズ背景の固�);
	auto menuTextShowGrid = Msg("menuTextShowGrid", "グリッ�の表示");
	auto menuTextShowEnemyCardProp = Msg("menuTextShowEnemyCardProp", "レベルとライフを表示");
	auto menuTextShowCard = Msg("menuTextShowCard", "カード�表示");
	auto menuTextShowBack = Msg("menuTextShowBack", "背景の表示");
	auto menuTextNewMenuCard = Msg("menuTextNewMenuCard", "メニューカード�作�");
	auto menuTextNewEnemyCard = Msg("menuTextNewEnemyCard", "エネミーカード�作�");
	auto menuTextNewBack = Msg("menuTextNewBack", "背景の作�");
	auto menuTextNewTextCell = Msg("menuTextNewTextCell", "ヂ�ストセルの作�");
	auto menuTextNewColorCell = Msg("menuTextNewColorCell", "カラーセルの作�");
	auto menuTextNewPCCell = Msg("menuTextNewPCCell", "プレイヤーキャラクタセルの作�");
	auto menuTextAutoArrange = Msg("menuTextAutoArrange", "カードを自動的に並べ�);
	auto menuTextManualArrange = Msg("menuTextManualArrange", "カード�位置を�刁�決定す�);
	auto menuTextMask = Msg("menuTextMask", "透�色を使用");
	auto menuTextEscape = Msg("menuTextEscape", "逵�の有無");
	auto menuTextChangePos = Msg("menuTextChangePos", "位置とサイズの変更");
	auto menuTextPosTop = Msg("menuTextPosTop", "上に揁��);
	auto menuTextPosBottom = Msg("menuTextPosBottom", "下に揁��);
	auto menuTextPosLeft = Msg("menuTextPosLeft", "左に揁��);
	auto menuTextPosRight = Msg("menuTextPosRight", "右に揁��);
	auto menuTextPosEven = Msg("menuTextPosEven", "等間隔に並べ�);
	auto menuTextNearTop = Msg("menuTextNearTop", "上へ寁��);
	auto menuTextNearBottom = Msg("menuTextNearBottom", "下へ寁��);
	auto menuTextNearLeft = Msg("menuTextNearLeft", "左へ寁��);
	auto menuTextNearRight = Msg("menuTextNearRight", "右へ寁��);
	auto menuTextNearCenterH = Msg("menuTextNearCenterH", "横方向�中央へ寁��);
	auto menuTextNearCenterV = Msg("menuTextNearCenterV", "縦方向�中央へ寁��);
	auto menuTextNearCenter = Msg("menuTextNearCenter", "中央へ寁��);
	auto menuTextScaleMin = Msg("menuTextScaleMin", "最小�カードスケール");
	auto menuTextScaleMiddle = Msg("menuTextScaleMiddle", "標準�カードスケール");
	auto menuTextScaleMax = Msg("menuTextScaleMax", "最大のカードスケール");
	auto menuTextScaleBig = Msg("menuTextScaleBig", "大きく揁��);
	auto menuTextScaleSmall = Msg("menuTextScaleSmall", "小さく揃える");
	auto menuTextExpandBack = Msg("menuTextExpandBack", "背景セルを最大�);
	auto menuTextStopBGM = Msg("menuTextStopBGM", "%1$sの再生を停止");
	auto menuTextPlayBGM = Msg("menuTextPlayBGM", "再生");
	auto menuTextKeyCodeTiming = Msg("menuTextKeyCodeTiming", "キーコード発火タイミング");
	auto menuTextKeyCodeTimingUse = Msg("menuTextKeyCodeTimingUse", "使用");
	auto menuTextKeyCodeTimingSuccess = Msg("menuTextKeyCodeTimingSuccess", "成功");
	auto menuTextKeyCodeTimingFailure = Msg("menuTextKeyCodeTimingFailure", "失�);
	auto menuTextKeyCodeTimingHasNot = Msg("menuTextKeyCodeTimingHasNot", "不保有");
	auto menuTextKeyCodeCond = Msg("menuTextKeyCodeCond", "キーコード発火条件");
	auto menuTextKeyCodeCondOr = Msg("menuTextKeyCodeCondOr", "どれか一つに一致");
	auto menuTextKeyCodeCondAnd = Msg("menuTextKeyCodeCondAnd", "全てに一致");
	auto menuTextAddRangeOfRound = Msg("menuTextAddRangeOfRound", "褕�のラウンドを追�");
	auto menuTextOpenAtTableView = Msg("menuTextOpenAtTableView", "�ブルビューで開く");
	auto menuTextOpenAtVarView = Msg("menuTextOpenAtVarView", "状態変数ビューで開く");
	auto menuTextOpenAtCardView = Msg("menuTextOpenAtCardView", "カードビューで開く");
	auto menuTextOpenAtFileView = Msg("menuTextOpenAtFileView", "ファイルビューで開く");
	auto menuTextOpenAtEventView = Msg("menuTextOpenAtEventView", "イベントビューで開く");
	auto menuTextComment = Msg("menuTextComment", "コメントを記述");
	auto menuTextShowCardProp = Msg("menuTextShowCardProp", "詳細惱を表示");
	auto menuTextShowCardImage = Msg("menuTextShowCardImage", "カード表示");
	auto menuTextShowCardDetail = Msg("menuTextShowCardDetail", "詳細表示");
	auto menuTextOpenImportSource = Msg("menuTextOpenImportSource", "外部シナリオから追�");
	auto menuTextNewCast = Msg("menuTextNewCast", "キャストカード�作�");
	auto menuTextNewSkill = Msg("menuTextNewSkill", "特殊技能カード�作�");
	auto menuTextNewItem = Msg("menuTextNewItem", "アイッ�カード�作�");
	auto menuTextNewBeast = Msg("menuTextNewBeast", "召喚獣カード�作�");
	auto menuTextNewInfo = Msg("menuTextNewInfo", "惱カード�作�");
	auto menuTextImport = Msg("menuTextImport", "シナリオに追�");
	auto menuTextOpenHand = Msg("menuTextOpenHand", "所有カー�);
	auto menuTextAddHand = Msg("menuTextAddHand", "所有カード�追�");
	auto menuTextRemoveRef = Msg("menuTextRemoveRef", "参�から格納へ変更する");
	auto menuTextEditEventAtTimeOfUsing = Msg("menuTextEditEventAtTimeOfUsing", "使用時イベント�設�);
	auto menuTextHold = Msg("menuTextHold", "カード�ホ�ル�);
	auto menuTextPlaySE = Msg("menuTextPlaySE", "再生");
	auto menuTextStopSE = Msg("menuTextStopSE", "停止");
	auto menuTextNewDir = Msg("menuTextNewDir", "新� ~ DIR);
	auto menuTextCopyFilePath = Msg("menuTextCopyFilePath", "�材�パスをコピ�");
	auto menuTextReplFilePath = Msg("menuTextReplFilePath", "�材�差替�);
	auto menuTextCreateArchive = Msg("menuTextCreateArchive", "シナリオを圧縮");
	auto menuTextPutQuick = Msg("menuTextPutQuick", "すぐに配置する");
	auto menuTextPutSelect = Msg("menuTextPutSelect", "配置先を選択す�);
	auto menuTextPutContinue = Msg("menuTextPutContinue", "配置先を選択して連続で配置する");
	auto menuTextToScript = Msg("menuTextToScript", "スクリプトに変換してコピ�");
	auto menuTextToScript1Content = Msg("menuTextToScript1Content", "1コンッ�トをスクリプトに変換");
	auto menuTextToScriptAll = Msg("menuTextToScriptAll", "全てをスクリプトに変換してコピ�");
	auto menuTextEvTemplates = Msg("menuTextEvTemplates", "イベントテンプレー�);
	auto menuTextEvTemplatesOfScenario = Msg("menuTextEvTemplatesOfScenario", "シナリオのッ�プレートを編�);
	auto menuTextExpand = Msg("menuTextExpand", "ッ�ーを開�);
	auto menuTextCollapse = Msg("menuTextCollapse", "ッ�ーを閉じる");
	auto menuTextSelectCurrentEvent = Msg("menuTextSelectCurrentEvent", "表示中のイベントを選�);
	auto menuTextResetPreviewValues = Msg("menuTextResetPreviewValues", "初期値に戻�);
	auto menuTextResetPreviewValuesAll = Msg("menuTextResetPreviewValuesAll", "全て初期値に戻�);
	auto menuTextCustomizeToolBar = Msg("menuTextCustomizeToolBar", "�ルバ�の編�);
	auto menuTextAddTool = Msg("menuTextAddTool", "追�");
	auto menuTextAddToolBar = Msg("menuTextAddToolBar", "バ�の追�");
	auto menuTextAddToolGroup = Msg("menuTextAddToolGroup", "グループ�追�");
	auto menuTextResetToolBarSettings = Msg("menuTextResetToolBarSettings", "初期設定に戻�);

	auto execEngineWithLastParty = Msg("execEngineWithLastParty", "前回のパ�ヂ�で開始\n(%1$s > %2$s > %3$s)");

	auto upSelection = Msg("upSelection", "上へ");
	auto downSelection = Msg("downSelection", "下へ");

	auto setFlagTrue = Msg("setFlagTrue", "TRUEを設�);
	auto setFlagFalse = Msg("setFlagFalse", "FALSEを設�);
	auto setStepValue = Msg("setStepValue", "%1$sを設�);

	auto bgm = Msg("bgm", "BGM");
	auto newEvent = Msg("newEvent", "イベント�作�");
	auto newIgnition = Msg("newIgnition", "イベント発火条件の作�");
	auto expandTree = Msg("expandTree", "全コンッ�トツリーを開�);
	auto foldTree = Msg("foldTree", "全コンッ�トツリーを閉じる");
	auto showEventTreeDetail = Msg("showEventTreeDetail", "イベントコンッ�ト�詳細を表示");
	auto showEventTreeLineNumber = Msg("showEventTreeLineNumber", "行番号を表示");

	auto sex = AAMsg("sex", "key", "name");
	auto period = AAMsg("period", "key", "name");
	auto nature = AAMsg("nature", "key", "name");
	auto makings = AAMsg("makings", "key", "name");

	/// 吀�想配�を�期化する�	this () { mixin(S_TRACE);
		sex.value = [
			"�:"�,
			"♀":"♀",
		];
		period.value = [
			"子�:"子�,
			"若�:"若�,
			"大人":"大人",
			"老人":"老人",
		];
		nature.value = [
			"他種�:"他種�, // darkwirth
			"標準型":"標準型",
			"琀��:"琀��, // s_c_wirth
			"参謀�:"参謀�, // oedowirth
			"妖木�:"妖木�, // darkwirth
			"知尞�":"知尞�",
			"�寞�":"�寞�", // oedowirth
			"人獣�:"人獣�, // darkwirth
			"��:"��,
			"秀才型":"秀才型", // s_c_wirth
			"小悪�:"小悪�, // darkwirth
			"策士�:"策士�,
			"根性�:"根性�, // s_c_wirth
			"剣客�:"剣客�, // oedowirth
			"悪鬼�:"悪鬼�, // darkwirth
			"勰��":"勰��",
			"熱血�:"熱血�, // s_c_wirth
			"蜥蜴�:"蜥蜴�, // darkwirth
			"豪傑型":"豪傑型",
			"秀英�:"秀英�, // s_c_wirth
			"人狼�:"人狼�, // darkwirth
			"英明型":"英明型",
			"剣豪�:"剣豪�, // oedowirth
			"鬼人�:"鬼人�, // darkwirth
			"無双型":"無双型",
			"賢才型":"賢才型", // oedowirth
			"大悪�:"大悪�, // darkwirth
			"天才型":"天才型",
			"努力型":"努力型", // s_c_wirth
			"晩成型":"晩成型", // oedowirth
			"妖虫�:"妖虫�, // darkwirth
			"凡庸�:"凡庸�,
			"趺��:"趺��, // s_c_wirth
			"要��:"要��, // oedowirth
			"��:"��, // darkwirth
			"英雞�":"英雞�",
			"神竜族":"神竜族", // darkwirth
			"神仙型":"神仙型",
		];
		makings.value = [
			"秀�:"秀�,
			"醜悪":"醜悪",
			"高貴の出":"高貴の出",
			"下賎�出":"下賎�出",
			"都会育ち":"都会育ち",
			"田舎育ち":"田舎育ち",
			"裕�:"裕�,
			"貧�:"貧�,
			"厚き信仰":"厚き信仰",
			"不忾��:"不忾��,
			"��:"��,
			"不�:"不�,
			"冷静沈着":"冷静沈着",
			"猪突猛進":"猪突猛進",
			"貪欲":"貪欲",
			"無欲":"無欲",
			"献身�:"献身�,
			"利己�:"利己�,
			"秩序派":"秩序派",
			"混沌派":"混沌派",
			"進取派":"進取派",
			"保守派":"保守派",
			"神経質":"神経質",
			"鈍感":"鈍感",
			"好奿���:"好奿���,
			"無頓着":"無頓着",
			"過激":"過激",
			"穏健":"穏健",
			"楽観�:"楽観�,
			"悲観�:"悲観�,
			"勤�:"勤�,
			"遊�人":"遊�人",
			"陽�:"陽�,
			"冰:"冰,
			"派�:"派�,
			"地味":"地味",
			"高�":"高�",
			"謙虚":"謙虚",
			"上品":"上品",
			"粗野":"粗野",
			"武骨":"武骨",
			"繊細":"繊細",
			"硬派":"硬派",
			"軟派":"軟派",
			"お人好�:"お人好�,
			"ひねくれ�:"ひねくれ�,
			"名誉こそ命":"名誉こそ命",
			"愛に生き�:"愛に生き�,
		];
	}

	const
	string defaultSelection(string s) { mixin(S_TRACE);
		return .format("[%s]", s);
	}

	mixin XMLFuncs!(typeof(this), "message");
}
