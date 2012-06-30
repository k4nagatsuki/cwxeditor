
module cwx.msgs;

import cwx.types;
import cwx.features;
import cwx.event;
import cwx.motion;
import cwx.structs;
import cwx.menu;
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
class Msgs {
public:
	@property const string application() {return "CWXEditor";}
	@property const string dlgTitVersion() {return "バージョン情報";}
	@property const string appDesc() {return "CardWirthPy向けシナリオエディタ";}

	@property const string dlgTitUsage() {return "使い方 - CWXEditor";}
	@property const string usage() {
		return "使い方: cwxeditor [-help | -conf <PATH> | -create <NAME> [<SKIN>]\n"
			~ "                   | -createclassic <NAME> [<PATH>]] <SCENARIO> [<CWXPath ...>]\n"
			~ "オプション:\n"
			~ "  -help         起動オプションの説明を表示して終了します。\n"
			~ "  -conf <PATH>  指定されたパスの基本設定ファイルを使用します。\n"
			~ "  -create        <NAME> [<SKIN>]  起動後にシナリオを新規作成します。\n"
			~ "  -createclassic <NAME> [<PATH>]  起動後、<PATH>で指定されたフォルダに\n"
			~ "                                  クラシックなシナリオを新規作成します。\n"
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
	@property const string unknownError() {		return "処理の途中で" ~ application ~ "の制作者が意図していないエラーが発生しました。"
			~ "データが壊れている可能性を考慮して、シナリオを保存せずに終了する事をお勧めします。\n"
			~ "エラー内容は" ~ CWX_EDITOR_EXE ~ "と同じ" ~ DIR ~ "にあるcwxeditor_error.logに記録されます。";
	}
	@property const string shutdown() {return "強制終了";}

	@property const string dlgTextOK() {return "&OK";}
	@property const string dlgTextApply() {return "適用";}
	@property const string dlgTextCancel() {return "キャンセル";}

	@property const string apply() {return "適用";}
	@property const string del() {return "削除";}

	@property const string filterAll() {
		return "すべてのファイル (*.*)";
	}

	@property const string fileCopyError() {return "%1$sのコピー中にエラーが発生しました。";}
	@property const string reloadError() {return "%1$sの再読込中にエラーが発生しました。";}
	@property const string loadProgress() {return "%2$s%% 完了 - %1$sを展開中";}
	@property const string loading() {return "%1$sの読込みを開始";}
	@property const string loaded() {return "%1$sの読込みを完了";}
	@property const string loadedCount() {return "%1$s件の読込みを完了";}
	@property const string reconstructionStatus() {return "編集状態を復元中 (%1$s/%2$s)";}
	@property const string cwxPathOpenError() {return "パス [%1$s] を開けません。";}
	@property const string filePathOpenError() {return "パス [%1$s] を開けません。";}

	@property const string loadSkinError() {
		return "デフォルトのスキン「%1$s」が見つかりません。\n" ~ CARD_WIRTH_PY_EXE ~ "の場所が正しくないか、Data" ~ DIR ~ "が正しく配置されていない可能性があります。\nこのまま開始すると、一部リソース画像が非表示になります。";
	}
	@property const string useDefaultSkin() {return "スキン「%1$s」が見つかりません。\nデフォルトのスキン「%1$s」を使用します。";}
	@property const string scenarioName() {return "シナリオ名";}
	@property const string type() {return "タイプ";}
	@property const string initialize() {return "初期設定";}
	@property const string classic() {return "[クラシック]";}
	@property const string scenarioTemplate() {return "テンプレート";}
	@property const string templateDesc() {return "%1$s [%2$s]";}
	@property const string noTemplate() {return "[テンプレート無し]";}
	@property const string newClassicDir() {
		return "シナリオ作成先の選択";
	}
	@property const string newClassicDirDesc() {
		return "シナリオを作成する" ~ DIR ~ "を選択してください。";
	}
	@property const string notEmptyDir() {
		return "%1$sは空ではありません。\n本当にここでシナリオを作成しますか？";
	}

	@property const string newScenarioName() {return "新規シナリオ";}

	@property const string dlgTitSaveBitmapImage() {
		return "格納イメージの保存";
	}
	@property const string filterBitmapImage() {
		return "ビットマップイメージ (*.bmp)";
	}

	@property const string newFolder() {return "新規" ~ DIR;}

	@property const string dlgMsgDeleteFile() {
		return "%1$sを完全に削除しますか？";
	}
	@property const string dlgMsgDeleteFiles() {
		return "%1$s個の項目を完全に削除しますか？";
	}
	@property const string dlgMsgDeleteFileRecycle() {
		return "%1$sをごみ箱に移動しますか？";
	}
	@property const string dlgMsgDeleteFilesRecycle() {
		return "%1$s個の項目をごみ箱に移動しますか？";
	}
	@property const string dlgMsgDeleteUnuse() {
		return "%1$s個の未使用ファイル・" ~ DIR ~ "を完全に削除しますか？";
	}
	@property const string dlgMsgDeleteRecycleUnuse() {
		return "%1$s個の未使用ファイル・" ~ DIR ~ "をごみ箱に移動しますか？";
	}

	@property const string image() {return "イメージ";}
	@property const string pathDef() {return "[デフォルト]";}
	@property const string imageNone() {return "[イメージ無し]";}
	@property const string fileNone() {return "[ファイルを選択]";}
	@property const string imageIncluding() {return "[イメージ格納]";}
	@property const string seNone() {return "[サウンド無し]";}
	@property const string bgmStop() {return "[BGM停止]";}
	@property const string bgmNone() {return "[BGM無し]";}
	@property const string dlgMsgIsSaveBeforeReload() {return "「%1$s」は変更されています。再読込しますか？";}
	@property const string reloadBeforeSaveError() {return "「%1$s」は保存されていないため、再読込できません。";}
	@property const string dlgMsgIsSaveBeforeExit() {return "「%1$s」は変更されています。保存しますか？";}
	@property const string dlgMsgDropFile() {
		return "%1$sをシナリオ" ~ DIR ~ "にコピーしますか？";
	}
	@property const string dlgMsgDropFiles() {
		return "%1$s個のファイルをシナリオ" ~ DIR ~ "にコピーしますか？";
	}
	@property const string dlgMsgDropOverWriteFile() {
		return "%1$sはすでに存在します。上書きしますか？";
	}
	@property const string dlgMsgDropOverWriteFiles() {
		return "%1$s個の項目がすでに存在します。上書きしますか？";
	}
	@property const string dlgTitDropFiles() {return "素材ファイルの追加";}
	@property const string dlgMsgCopyError() {return "いくつかのファイルのコピーに失敗しました。";}

	@property const string dlgMsgCopyMaterial1() {return "格納画像もコピーしますか？";}
	@property const string dlgMsgCopyMaterial2() {return "素材もコピーしますか？\n%1$s";}
	@property const string dlgMsgCopyMaterial3() {return "素材もコピーしますか？\n%1$s個のファイル";}
	@property const string dlgMsgCopyMaterial4() {return "素材もコピーしますか？\n%1$s個のファイルと%2$s個の格納画像";}

	@property const string incSearchContains() {return "名前の一部";}
	@property const string incSearchWildcard() {return "ワイルドカード";}
	@property const string incSearchRegex() {return "正規表現";}

	@property const string dlgTitSettings() {return "CWXEditorの設定";}

	@property const string refreshS() {return "更新";}

	@property const string summary() {return "シナリオの設定";}
	@property const string area() {return "エリア";}
	@property const string battle() {return "バトル";}
	@property const string cwPackage() {return "パッケージ";}

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
	@property const string replTextFile() {return "ファイル名";}
	@property const string replTextComment() {return "コメント";}
	@property const string replTextJptx() {return "JPTXテキスト";}

	@property const string replID() {return "検索/置換対象";}
	@property const string replIDKind() {return "対象";}
	@property const string replIDArea() {return "エリア";}
	@property const string replIDBattle() {return "バトル";}
	@property const string replIDPackage() {return "パッケージ";}
	@property const string replIDCast() {return "キャストカード";}
	@property const string replIDSkill() {return "特殊技能カード";}
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
	@property const string replUnuseSkill() {return "特殊技能カード";}
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
	@property const string searchResultEmpty() {return "0件の検索結果";}
	@property const string searchResult() {return "%1$s件の検索結果(%2$s)";}
	@property const string replResultEmpty() {return "0箇所の置換";}
	@property const string replResult() {return "%1$s箇所の置換(%2$s)";}
	@property const string replaceUndo() {return "%1$s件を元に戻しました";}
	@property const string replaceRedo() {return "%1$s件をやり直しました";}

	@property const string searchResultBgImage() {return "背景画像 [%1$s]";}
	@property const string searchResultIds() {return "%1$s [%2$s.%3$s]";}

	@property const string searchResultFlag() {return "フラグ [%1$s]";}
	@property const string searchResultStep() {return "ステップ [%1$s]";}
	@property const string searchResultFlagDir() {return "ディレクトリ [%1$s]";}
	@property const string searchResultEventTree() {return "イベントツリー [%1$s]";}
	@property const string searchResultMenuCard() {return "メニューカード [%1$s]";}
	@property const string searchResultEnemyCard() {return "エネミーカード [%1$s]";}

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

	/// イベント設定。
	@property const string dlgTitContent() {return "イベントの設定 [ %1$s ]";}

	@property const string afterClear() {return "シナリオ終了後";}
	@property const string afterClearEndMark() {return "シナリオに済印を付ける";}
	@property const string afterClearNoEndMark() {return "何もしない";}

	@property const string couponName() {return "クーポン名";}
	@property const string couponValue() {return "得点";}
	@property const string couponValueRange() {return "(%1$s～%2$s)";}
	@property const string range() {return "適用範囲";}
	@property const string gossipName() {return "ゴシップ名";}
	@property const string endName() {return "シナリオ名";}

	@property const string couponHide() {return "隠蔽クーポン";}

	mixin(EnumToStringMethod!(CouponType, "couponTypeDesc", "couponTypeDesc"));
	@property const string couponTypeDescNormal() {return "ノーマル";}
	@property const string couponTypeDescHide() {return "[＿...] 隠蔽(称号一覧で非表示)";}
	@property const string couponTypeDescSystem() {return "[＠...] システム";}
	@property const string couponTypeDescDur() {return "[：...] 時限(点数分の時間経過及びシナリオ終了時に消滅)";}
	@property const string couponTypeDescDurBattle() {return "[；...] 戦闘中時限(点数分の時間経過及び戦闘終了時に消滅)";}

	@property const string imageMessage() {return "イメージ付きメッセージ";}
	@property const string noImageMessage() {return "イメージ無しメッセージ";}
	@property const string spCharsTitle() {return "特殊文字";}
	@property const string colorW() {return "デフォルト(&W)";}
	@property const string colorR() {return "赤(&R)";}
	@property const string colorB() {return "青(&B)";}
	@property const string colorG() {return "緑(&G)";}
	@property const string colorY() {return "黄(&Y)";}
	mixin(EnumToStringMethod!(Talker, "scTalkerName", "scTalkerName"));
	@property const string scTalkerNameSelected() {return "選択メンバ名(#M)";}
	@property const string scTalkerNameUnselected() {return "選択外ランダムメンバ名(#U)";}
	@property const string scTalkerNameRandom() {return "ランダムメンバ名(#R)";}
	@property const string scTalkerNameCard() {return "選択カード名(#C)";}
	@property const string scTalkerNameNarration() {return "話者無し";}
	@property const string scTalkerNameImage() {return "画像";}
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
	mixin(EnumToStringMethod!(Transition, "transitionName", "transitionName"));
	@property const string transitionNameDefault() {return "[プレイヤーの設定を使用]";}
	@property const string transitionNameNone() {return "アニメーション無し";}
	@property const string transitionNameFade() {return "フェード式";}
	@property const string transitionNamePixelDissolve() {return "ピクセルディゾルブ式";}
	@property const string transitionNameBlinds() {return "ブラインド式";}
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

	mixin(EnumToStringMethod!(CType, "contentName", "contentName"));
	@property const string contentNameStart() {return "スタート";}
	@property const string contentNameStartBattle() {return "バトル開始";}
	@property const string contentNameEnd() {return "シナリオクリア";}
	@property const string contentNameEndBadEnd() {return "ゲームオーバー";}
	@property const string contentNameChangeArea() {return "エリア移動";}
	@property const string contentNameChangeBgImage() {return "背景変更";}
	@property const string contentNameEffect() {return "効果";}
	@property const string contentNameEffectBreak() {return "効果中断";}
	@property const string contentNameLinkStart() {return "スタートへのリンク";}
	@property const string contentNameLinkPackage() {return "パッケージへのリンク";}
	@property const string contentNameTalkMessage() {return "メッセージ";}
	@property const string contentNameTalkDialog() {return "セリフ";}
	@property const string contentNamePlayBgm() {return "BGM変更";}
	@property const string contentNamePlaySound() {return "効果音";}
	@property const string contentNameWait() {return "空白時間挿入";}
	@property const string contentNameElapseTime() {return "時間経過";}
	@property const string contentNameCallStart() {return "スタートの呼び出し";}
	@property const string contentNameCallPackage() {return "パッケージの呼び出し";}
	@property const string contentNameBranchFlag() {return "フラグ分岐";}
	@property const string contentNameBranchMultiStep() {return "ステップ多岐分岐";}
	@property const string contentNameBranchStep() {return "ステップ上下分岐";}
	@property const string contentNameBranchSelect() {return "メンバ選択分岐";}
	@property const string contentNameBranchAbility() {return "能力判定分岐";}
	@property const string contentNameBranchRandom() {return "ランダム分岐";}
	@property const string contentNameBranchLevel() {return "レベル判定分岐";}
	@property const string contentNameBranchStatus() {return "状態判定分岐";}
	@property const string contentNameBranchPartyNumber() {return "人数判定分岐";}
	@property const string contentNameBranchArea() {return "エリア分岐";}
	@property const string contentNameBranchBattle() {return "バトル分岐";}
	@property const string contentNameBranchIsBattle() {return "バトル判定分岐";}
	@property const string contentNameBranchCast() {return "キャスト存在分岐";}
	@property const string contentNameBranchItem() {return "アイテム所持分岐";}
	@property const string contentNameBranchSkill() {return "スキル所持分岐";}
	@property const string contentNameBranchInfo() {return "情報所持分岐";}
	@property const string contentNameBranchBeast() {return "召喚獣存在分岐";}
	@property const string contentNameBranchMoney() {return "所持金分岐";}
	@property const string contentNameBranchCoupon() {return "クーポン分岐";}
	@property const string contentNameBranchCompleteStamp() {return "終了シナリオ分岐";}
	@property const string contentNameBranchGossip() {return "ゴシップ分岐";}
	@property const string contentNameSetFlag() {return "フラグ変更";}
	@property const string contentNameSetStep() {return "ステップ変更";}
	@property const string contentNameSetStepUp() {return "ステップ増加";}
	@property const string contentNameSetStepDown() {return "ステップ減少";}
	@property const string contentNameReverseFlag() {return "フラグ反転";}
	@property const string contentNameCheckFlag() {return "フラグ判定";}
	@property const string contentNameGetCast() {return "キャスト加入";}
	@property const string contentNameGetItem() {return "アイテム入手";}
	@property const string contentNameGetSkill() {return "スキル取得";}
	@property const string contentNameGetInfo() {return "情報入手";}
	@property const string contentNameGetBeast() {return "召喚獣獲得";}
	@property const string contentNameGetMoney() {return "所持金増加";}
	@property const string contentNameGetCoupon() {return "クーポン取得";}
	@property const string contentNameGetCompleteStamp() {return "終了シナリオ設定";}
	@property const string contentNameGetGossip() {return "ゴシップ追加";}
	@property const string contentNameLoseCast() {return "キャスト離脱";}
	@property const string contentNameLoseItem() {return "アイテム喪失";}
	@property const string contentNameLoseSkill() {return "スキル喪失";}
	@property const string contentNameLoseInfo() {return "情報喪失";}
	@property const string contentNameLoseBeast() {return "召喚獣消去";}
	@property const string contentNameLoseMoney() {return "所持金減少";}
	@property const string contentNameLoseCoupon() {return "クーポン削除";}
	@property const string contentNameLoseCompleteStamp() {return "終了シナリオ削除";}
	@property const string contentNameLoseGossip() {return "ゴシップ削除";}
	@property const string contentNameShowParty() {return "パーティ表示";}
	@property const string contentNameHideParty() {return "パーティ隠蔽";}
	@property const string contentNameRedisplay() {return "画面再構築";}

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

	@property const string msnDesc() {return "%1$s - %2$s";}

	mixin(EnumToStringMethod!(MType, "motionName", "motionName"));
	@property const string motionNameHeal() {return "回復";}
	@property const string motionNameDamage() {return "ダメージ";}
	@property const string motionNameAbsorb() {return "吸収";}
	@property const string motionNameParalyze() {return "麻痺";}
	@property const string motionNameDisParalyze() {return "麻痺解除";}
	@property const string motionNamePoison() {return "中毒";}
	@property const string motionNameDisPoison() {return "中毒解除";}
	@property const string motionNameGetSkillPower() {return "精神力回復";}
	@property const string motionNameLoseSkillPower() {return "精神力喪失";}
	@property const string motionNameSleep() {return "睡眠状態";}
	@property const string motionNameConfuse() {return "混乱状態";}
	@property const string motionNameOverheat() {return "激昂状態";}
	@property const string motionNameBrave() {return "勇敢状態";}
	@property const string motionNamePanic() {return "恐慌状態";}
	@property const string motionNameNormal() {return "正常状態";}
	@property const string motionNameBind() {return "呪縛";}
	@property const string motionNameDisBind() {return "呪縛解除";}
	@property const string motionNameSilence() {return "沈黙";}
	@property const string motionNameDisSilence() {return "沈黙解除";}
	@property const string motionNameFaceUp() {return "暴露";}
	@property const string motionNameFaceDown() {return "暴露解除";}
	@property const string motionNameAntiMagic() {return "魔法無効化";}
	@property const string motionNameDisAntiMagic() {return "魔法無効化解除";}
	@property const string motionNameEnhanceAction() {return "行動力変化";}
	@property const string motionNameEnhanceAvoid() {return "回避力変化";}
	@property const string motionNameEnhanceDefense() {return "防御力変化";}
	@property const string motionNameEnhanceResist() {return "抵抗力変化";}
	@property const string motionNameVanishTarget() {return "対象消去";}
	@property const string motionNameVanishCard() {return "手札消去";}
	@property const string motionNameVanishBeast() {return "召喚獣消去";}
	@property const string motionNameDealAttackCard() {return "通常攻撃";}
	@property const string motionNameDealPowerfulAttackCard() {return "渾身の一撃";}
	@property const string motionNameDealCriticalAttackCard() {return "会心の一撃";}
	@property const string motionNameDealFeintCard() {return "フェイント";}
	@property const string motionNameDealDefenseCard() {return "防御";}
	@property const string motionNameDealDistanceCard() {return "見切り";}
	@property const string motionNameDealConfuseCard() {return "混乱";}
	@property const string motionNameDealSkillCard() {return "特殊技能";}
	@property const string motionNameSummonBeast() {return "召喚獣召喚";}

	@property const string dialogText() {return "%2$s: %1$s";}
	@property const string dialogTextNoCoupon() {return "%1$s";}

	@property const string ctStart() {return "スタートコンテント「%1$s」";}
	@property const string ctStartBattle() {return "バトルの開始「%1$s」";}
	@property const string ctChangeArea() {return "エリア移動「%1$s」 切替方式 = %2$s ウェイト = %3$s";}
	@property const string ctChangeAreaClassic() {return "エリア移動「%1$s」";}
	@property const string ctEndComplete() {return "済印をつけて終了";}
	@property const string ctEndNoComplete() {return "済印をつけずに終了";}
	@property const string ctGameOver() {return "ゲームオーバーコンテント";}
	@property const string ctChangeBgImage() {return "背景ファイル = %1$s 切替方式 = %2$s ウェイト = %3$s";}
	@property const string ctChangeBgImageClassic() {return "背景ファイル = %1$s";}
	@property const string ctChangeBgImageFile() {return "[%1$s]";}
	@property const string ctEffectSound() {return "「%1$s」を再生";}
	@property const string ctEffectNoSound() {return "音声無し";}
	@property const string ctEffect() {return "%1$s レベル%2$s %3$s/%4$s 成功率%5$s%6$s %7$s %8$s 効果 = %9$s";}
	@property const string ctEffectMotion() {return "[%1$s]";}
	@property const string ctEffectBreak() {return "効果中断コンテント";}
	@property const string ctStopBGM() {return "BGM停止";}
	@property const string ctLinkStart() {return "スタートコンテント「%1$s」へのリンク";}
	@property const string ctLinkPackage() {return "パッケージ「%1$s」へのリンク";}
	@property const string ctTalkMessage() {return "%1$s: %2$s";}
	@property const string ctTalkMessageImage() {return "[%1$s]";}
	@property const string ctTalkDialog() {return "%1$s %2$s: %3$s";}
	@property const string ctTalkDialogNoCoupon() {return "%1$s: %2$s";}
	@property const string ctPlayBGM() {return "BGMとして「%1$s」を演奏";}
	@property const string ctPlaySound() {return "効果音「%1$s」を鳴らす";}
	@property const string ctWait() {return "空白時間 = %1$s × 0.1秒";}
	@property const string ctElapseTime() {return "ターン数経過コンテント";}
	@property const string ctCallStart() {return "スタートコンテント「%1$s」のコール";}
	@property const string ctCallPackage() {return "パッケージ「%1$s」のコール";}
	@property const string ctBranchFlag() {return "フラグ「%1$s」の値で分岐";}
	@property const string ctBranchMultiStep() {return "ステップ「%1$s」の値で分岐";}
	@property const string ctBranchStep() {return "ステップ「%1$s」の値が[%2$s]以上・未満で分岐";}
	@property const string ctBranchSelectAll() {return "パーティ全員";}
	@property const string ctBranchSelectActive() {return "動けるメンバ";}
	@property const string ctBranchSelectAuto() {return "ランダム";}
	@property const string ctBranchSelectManual() {return "手動";}
	@property const string ctBranchSelect() {return "%1$sから%2$sでメンバを選択";}
	@property const string ctBranchAbility() {return "%1$s(%2$s)の%3$sと%4$sで能力判定(レベル%5$s)";}
	@property const string ctBranchRandom() {return "確率 = %1$s%%";}
	@property const string ctBranchLevelAverage() {return "パーティ全員";}
	@property const string ctBranchLevelSelected() {return "選択中のメンバ";}
	@property const string ctBranchLevel() {return "%1$sのレベルが%2$s以上・未満で分岐";}
	@property const string ctBranchStatus() {return "%1$sが%2$s状態か否かで分岐";}
	@property const string ctBranchPartyNumber() {return "人数 = %1$s人";}
	@property const string ctBranchArea() {return "エリア分岐コンテント";}
	@property const string ctBranchBattle() {return "バトル分岐コンテント";}
	@property const string ctBranchIsBattle() {return "戦闘中判定分岐コンテント";}
	@property const string ctBranchCast() {return "キャストカード「%1$s」の同行有無で分岐";}
	@property const string ctBranchSkill() {return "特殊技能カード「%1$s」の有無で分岐(%2$sに%3$s枚)";}
	@property const string ctBranchItem() {return "アイテムカード「%1$s」の有無で分岐(%2$sに%3$s枚)";}
	@property const string ctBranchBeast() {return "召喚獣カード「%1$s」の有無で分岐(%2$sに%3$s枚)";}
	@property const string ctBranchInfo() {return "情報カード「%1$s」の有無で分岐";}
	@property const string ctBranchMoney() {return "分岐金額 = %1$ssp";}
	@property const string ctBranchCoupon() {return "称号「%1$s」の有無で分岐(%2$s)";}
	@property const string ctBranchCompleteStamp() {return "シナリオ「%1$s」が終了済みか否かで分岐";}
	@property const string ctBranchGossip() {return "ゴシップ「%1$s」の有無で分岐";}
	@property const string ctSetFlag() {return "フラグ「%1$s」を[%2$s]に変更";}
	@property const string ctSetStep() {return "ステップ「%1$s」を[%2$s]に変更";}
	@property const string ctSetStepUp() {return "ステップ「%1$s」の値を1増加";}
	@property const string ctSetStepDown() {return "ステップ「%1$s」の値を1減少";}
	@property const string ctReverseFlag() {return "フラグ「%1$s」の値を反転";}
	@property const string ctCheckFlag() {return "フラグ「%1$s」の値が[%2$s]であれば出現";}
	@property const string ctGetCast() {return "キャストカード「%1$s」を同行させる";}
	@property const string ctGetSkill() {return "特殊技能カード「%1$s」を獲得(%2$sに%3$s枚)";}
	@property const string ctGetItem() {return "アイテムカード「%1$s」を獲得(%2$sに%3$s枚)";}
	@property const string ctGetBeast() {return "召喚獣カード「%1$s」を獲得(%2$sに%3$s枚)";}
	@property const string ctGetInfo() {return "情報カード「%1$s」を獲得";}
	@property const string ctGetMoney() {return "獲得金額 = %1$ssp";}
	@property const string ctGetCoupon() {return "称号「%1$s」を獲得(%2$s)";}
	@property const string ctGetCompleteStamp() {return "シナリオ%1$sを終了済みにする";}
	@property const string ctGetGossip() {return "ゴシップ「%1$s」を獲得";}
	@property const string ctLoseCardAll() {return "全て";}
	@property const string ctLoseCardCount() {return "%1$s枚";}
	@property const string ctLoseCast() {return "キャストカード「%1$s」の同行を解除";}
	@property const string ctLoseSkill() {return "特殊技能カード「%1$s」を喪失(%2$sから%3$s)";}
	@property const string ctLoseItem() {return "アイテムカード「%1$s」を喪失(%2$sから%3$s)";}
	@property const string ctLoseBeast() {return "召喚獣カード「%1$s」を喪失(%2$sから%3$s)";}
	@property const string ctLoseInfo() {return "情報カード「%1$s」を喪失";}
	@property const string ctLoseMoney() {return "喪失金額 = %1$ssp";}
	@property const string ctLoseCoupon() {return "称号「%1$s」を喪失(%2$s)";}
	@property const string ctLoseCompleteStamp() {return "シナリオ%1$sの終了印を削除";}
	@property const string ctLoseGossip() {return "ゴシップ「%1$s」を喪失";}
	@property const string ctShowParty() {return "パーティ表示コンテント";}
	@property const string ctHideParty() {return "パーティ隠蔽コンテント";}
	@property const string ctRedisplay() {return "切替方式 = %1$s ウェイト = %2$s";}
	@property const string ctRedisplayClassic() {return "画面再構築コンテント";}

	@property const string defaultStartName() {return "イベント開始";}

	@property const string oggMayNotCorrespond() {return "Oggはプレイヤーの環境によって再生できない事があります。";}
	@property const string mp3LoopMayNotCorrespond() {return "MP3はプレイヤーの環境によってループ再生されない事があります。";}

	/// メインウィンドウ。
	@property const string mainWindowName() {return "%1$s [ %2$s ] - CWXEditor";}
	@property const string mainWindowNameChanged() {return "*%1$s [ %2$s ] - CWXEditor";}
	@property const string mainWindowNameEmpty() {return "CWXEditor";}
	@property const string errorExecEngine() {return "%1$sの起動に失敗しました。";}

	/// シナリオ選択ダイアログ
	@property const string dlgTitNewScenario() {return "新規シナリオの作成";}
	@property const string dlgTitNewScenarioAtNewWin() {return "新しいウィンドウで新規シナリオの作成";}
	@property const string dlgTitOpenScenario() {return "シナリオを開く";}
	@property const string dlgTitOpenScenarioAtNewWin() {return "新しいウィンドウでシナリオを開く";}
	@property const string filterScenario() {return "シナリオファイル (%1$s)";}
	@property const string filterParts() {return "エリア・カードファイル (%1$s)";}
	@property const string dlgTitSaveScenario() {return "名前を付けて保存";}
	@property const string filterScenarioSave() {return "XMLシナリオファイル (*.wsn)";}
	@property const string notScenario() {return "%1$sはシナリオ圧縮ファイルではありません";}
	@property const string zipError() {return "%1$sの展開に失敗しました。";}
	@property const string loadError() {return "%1$sの読込みに失敗しました。";}
	@property const string saveError() {return "%1$sの保存に失敗しました。";}
	@property const string loadErrorStatus() {return "%1$sの読込みに失敗";}
	@property const string loadErrorStatusCount() {return "%1$s件のシナリオの読込みに失敗";}
	@property const string scenarioNotFound() {
		return "%1$sは存在しないか、シナリオではありません。履歴から削除しますか？";
	}

	/// データウィンドウ
	@property const string dataTabName() {return "データ";}
	@property const string dataWindowName() {return "データ - [ %1$s ] - %2$s";}
	@property const string areasTabName() {return "テーブル";}
	@property const string areasWindowName() {return "テーブル - [ %1$s ] - %2$s";}
	@property const string areaStatus() {return "%2$s件の%1$s";}
	@property const string flagTabName() {return "状態変数";}
	@property const string flagWindowName() {return "状態変数 - [ %1$s ] - %2$s";}
	@property const string flagStatus() {return "%2$s個の%1$s";}
	@property const string flagStatusSel() {return "%1$s (%2$s個を選択)";}
	@property const string scenarioView() {return "シナリオビューリスト";}
	@property const string variableView() {return "状態変数インスペクタ";}

	@property const string reNumberingAll() {
		return "全てのエリアやカードのIDの1から振り直します。\nよろしいですか？";
	}

	@property const string dlgTitReNumbering() {return "IDの振り直し";}
	@property const string reNumbering() {return "IDの振り直し";}
	@property const string reNumbering1() {return "%1$s「%2$s」以降のIDを";}
	@property const string reNumbering2() {return "番から順に振り直す";} // reNumbering1と同様のパラメータを取る

	/// エリアのテーブル。
	@property const string areaId() {return "ID";}
	@property const string areaName() {return "名称";}
	@property const string areaCount() {return "利用数";}
	@property const string areaNew() {return "新規エリア";}
	@property const string battleNew() {return "新規バトル";}
	@property const string packageNew() {return "新規パッケージ";}

	/// フラグのディレクトリ。
	@property const string flagDirRoot() {return "Data";}
	@property const string flagDirNew() {return "新規フォルダ";}

	/// フラグ/ステップのテーブル。
	@property const string flagName() {return "名称";}
	@property const string flagInit() {return "初期値";}
	@property const string flagCount() {return "利用数";}

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
	@property const string dlgLblStep() {return "Step - %1$s";}
	@property const string dlgTxtStep() {return "Step - %1$s";}

	/// 貼り紙設定ダイアログ関連。
	@property const string dlgTitSummary() {return "概略の設定 - [ %1$s ]";}
	@property const string summaryPreview() {return "表示イメージ";}
	@property const string baseData() {return "基本データ";}
	@property const string etcData() {return "詳細データ";}
	@property const string targetLevelSame() {return "対象レベル %1$s";}
	@property const string targetLevelHL() {return "対象レベル %1$s～%2$s";}
	@property const string targetLevelL() {return "対象レベル %1$s～";}
	@property const string targetLevelH() {return "対象レベル ～%1$s";}
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
	@property const string sTypeXML() {return "スキンを指定";}
	@property const string sTypeClassic() {return "クラシックエンジンを使用";}
	@property const string currentEngineSkin() {return "[%1$s]";}

	@property const string pngMayNotCorrespond() {return "PNGイメージはプレイヤーの環境によって表示エラーとなる事があります。";}

	/// エリア・戦闘・パッケージウィンドウ。
	@property const string noRefArea() {return "[カード配置参照無し]";}
	@property const string areaViewFlagDesc() {return "フラグ";}
	@property const string areaViewRefAreaDesc() {return "参照";}

	@property const string left() {return "X";}
	@property const string top() {return "Y";}
	@property const string width() {return "幅";}
	@property const string height() {return "高";}
	@property const string scale() {return "拡大率";}

	@property const string areaViewStatus() {return "%1$s [%2$s] - %3$s";}
	@property const string areaViewStatusNoSummary() {return "%1$s [%2$s]";}
	@property const string areaViewStatusNoFlag() {return "フラグ指定無し";}
	@property const string areaViewStatusInvalidFlag() {return "存在しないフラグ(%1$s)";}
	@property const string areaViewStatusWithFlag() {return "フラグ = %1$s";}
	@property const string areaViewStatusImageIncluding() {return "イメージ格納";}
	@property const string areaViewStatusSelCard() {return "%1$s枚のカード";}
	@property const string areaViewStatusSelBack() {return "%1$s枚の背景";}
	@property const string areaViewStatusEnemyCard() {return "%1$s.%2$s";}

	@property const string viewNameTab() {return "%2$s.%3$s";}
	@property const string viewNameSceneTab() {return "%2$s.%3$s";}
	@property const string viewNameEventTab() {return "%2$s.%3$s";}
	@property const string viewName() {return "[%1$s] - %2$s - %3$s";}
	@property const string viewNameScene() {return "[%1$s カードと背景] - %2$s - %3$s";}
	@property const string viewNameEvent() {return "[%1$s イベント] - %2$s - %3$s";}

	@property const string cardCount() {return "使用数";}

	@property const string cardAndBackView() {return "カードと背景";}
	@property const string enemyCardView() {return "エネミーカード";}
	@property const string menuCards() {return "カード";}
	@property const string enemyCards() {return "カード";}
	@property const string backs() {return "背景";}
	@property const string eventView() {return "イベント";}
	@property const string menuCard() {return "メニューカード";}
	@property const string enemyCard() {return "エネミーカード";}
	@property const string back() {return "背景画像";}

	/// カード/背景配置領域関連。
	@property const string dlgTitDropCard() {return "カード画像の追加";}
	@property const string dlgMsgDropCard() {return "カード画像をシナリオ" ~ DIR ~ "にコピーしますか？\n%1$s";}
	@property const string dlgTitDropBack() {return "背景画像の追加";}
	@property const string dlgMsgDropBack() {return "背景画像をシナリオ" ~ DIR ~ "にコピーしますか？\n%1$s";}

	@property const string refFlag() {return "フラグ参照先";}
	@property const string refStep() {return "ステップ参照先";}
	@property const string noFlagRef() {return "[参照無し]";}
	@property const string cardPosition() {return "カード位置";}
	@property const string backPosition() {return "位置";}
	@property const string bgImageSettings() {return "簡単設定";}
	@property const string bgImageSettingCustom() {return "[カスタム]";}
	@property const string bgImageSettingOriginal() {return "[元のサイズ]";}
	@property const string enemyCardBase() {return "基本設定";}
	@property const string dlgTitMenuCard() {return "メニューカードの設定 [ %1$s ]";}
	@property const string dlgTitNewMenuCard() {return "メニューカードの作成";}
	@property const string dlgTitBgImage() {return "背景画像の設定";}
	@property const string dlgTitNewBgImage() {return "背景画像の作成";}
	@property const string dlgTitEnemyCard() {return "エネミーカードの設定 [ %1$s ]";}
	@property const string dlgTitNewEnemyCard() {return "エネミーカードの作成";}

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
	@property const string startRound() {return "ラウンド = %1$s";}
	@property const string keyCodeTimingUse() {return "使用";}
	@property const string keyCodeTimingSuccess() {return "成功";}
	@property const string keyCodeTimingFailure() {return "失敗";}

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
	@property const string keyCodeTree() {return "[%1$s]";}
	@property const string roundTree() {return "ラウンド %1$s";}

	@property const string eventTreeKindSystem() {return "システム";}
	@property const string eventTreeKindKeyCode() {return "キーコード";}
	@property const string eventTreeKindRound() {return "ラウンド";}

	@property const string startUseCount() {return "利用数";}

	@property const string flagOn() {return "TRUE";}
	@property const string flagOff() {return "FALSE";}
	@property const string evtChildBrVar() {return "%1$s = %2$s";}
	@property const string etc() {return "その他";}
	@property const string stepMoreThan() {return "ステップ「%1$s」が「%2$s」以上";}
	@property const string stepLessThan() {return "ステップ「%1$s」が「%2$s」未満";}
	@property const string partyAll() {return "パーティ全員";}
	@property const string partyActive() {return "動けるメンバ";}
	@property const string autoSelect() {return "自動";}
	@property const string manualSelect() {return "手動";}
	@property const string selectMemberSuccess() {return "%1$sから%2$sでキャラクターを選択";}
	@property const string selectMemberFailure() {return "%1$sから%2$sでのキャラクター選択をキャンセル";}
	@property const string branchAbilitySuccess() {return "%1$sがレベル%2$sで%3$sと%4$sで行う判定に成功";}
	@property const string branchAbilityFailure() {return "%1$sがレベル%2$sで%3$sと%4$sで行う判定に失敗";}
	@property const string branchRandomSuccess() {return "%1$s%%成功";}
	@property const string branchRandomFailure() {return "%1$s%%失敗";}
	@property const string levelAverage() {return "パーティ全員の平均値";}
	@property const string levelSelected() {return "選択中のメンバ";}
	@property const string branchLevelSuccess() {return "%1$sがレベル%2$s以上";}
	@property const string branchLevelFailure() {return "%1$sがレベル%2$s未満";}
	@property const string branchStatusSuccess() {return "%1$sでの「%2$s」の判定に成功";}
	@property const string branchStatusFailure() {return "%1$sでの「%2$s」の判定に失敗";}
	@property const string branchNumberSuccess() {return "パーティに%1$s人以上いる";}
	@property const string branchNumberFailure() {return "パーティは%1$s人未満";}
	@property const string branchArea() {return "エリア = %1$s";}
	@property const string branchBattle() {return "バトル = %1$s";}
	@property const string branchOnBattleSuccess() {return "イベント発生時の状況が戦闘中";}
	@property const string branchOnBattleFailure() {return "イベント発生時の状況が戦闘中以外";}
	@property const string branchCastSuccess() {return "「%1$s」が加わっている";}
	@property const string branchCastFailure() {return "「%1$s」が加わっていない";}
	@property const string branchEffectCardSuccess() {return "%1$sで「%2$s」を所有している";}
	@property const string branchEffectCardFailure() {return "%1$sで「%2$s」が所有していない";}
	@property const string branchInfoSuccess() {return "「%1$s」を所有している";}
	@property const string branchInfoFailure() {return "「%1$s」が所有していない";}
	@property const string branchMoneySuccess() {return "%1$ssp以上所持している";}
	@property const string branchMoneyFailure() {return "%1$ssp以上所持していない";}
	@property const string branchCouponSuccess() {return "%1$sがクーポン「%2$s」を所有している";}
	@property const string branchCouponFailure() {return "%1$sがクーポン「%2$s」を所有していない";}
	@property const string branchCompleteSuccess() {return "シナリオ「%1$s」が終了済みである";}
	@property const string branchCompleteFailure() {return "シナリオ「%1$s」が終了済みでない";}
	@property const string branchGossipSuccess() {return "ゴシップ「%1$s」が宿屋にある";}
	@property const string branchGossipFailure() {return "ゴシップ「%1$s」が宿屋に無い";}

	mixin(EnumToStringMethod!(Physical, "physicalName", "physicalName"));
	@property const string physicalNameDex() {return "器用度";}
	@property const string physicalNameAgl() {return "敏捷度";}
	@property const string physicalNameInt() {return "知力";}
	@property const string physicalNameStr() {return "筋力";}
	@property const string physicalNameVit() {return "生命力";}
	@property const string physicalNameMin() {return "精神力";}
	mixin(EnumToStringMethod!(Mental, "mentalName", "mentalName"));
	@property const string mentalNameAggressive() {return "好戦性";}
	@property const string mentalNameUnaggressive() {return "平和性";}
	@property const string mentalNameCheerful() {return "社交性";}
	@property const string mentalNameUncheerful() {return "内向性";}
	@property const string mentalNameBrave() {return "勇猛性";}
	@property const string mentalNameUnbrave() {return "臆病性";}
	@property const string mentalNameCautious() {return "慎重性";}
	@property const string mentalNameUncautious() {return "大胆性";}
	@property const string mentalNameTrickish() {return "狡猾性";}
	@property const string mentalNameUntrickish() {return "正直性";}
	mixin(EnumToStringMethod!(Status, "statusName", "statusName"));
	@property const string statusNameActive() {return "行動可能";}
	@property const string statusNameInactive() {return "行動不可";}
	@property const string statusNameAlive() {return "生存";}
	@property const string statusNameDead() {return "非生存";}
	@property const string statusNameFine() {return "健康";}
	@property const string statusNameInjured() {return "負傷";}
	@property const string statusNameHeavyInjured() {return "重傷";}
	@property const string statusNameUnconscious() {return "意識不明";}
	@property const string statusNamePoison() {return "中毒";}
	@property const string statusNameSleep() {return "眠り";}
	@property const string statusNameBind() {return "呪縛";}
	@property const string statusNameParalyze() {return "麻痺/石化";}
	@property const string effectTypeElement() {return "%1$s属性";}
	mixin(EnumToStringMethod!(EffectType, "effectTypeName", "effectTypeName"));
	@property const string effectTypeNamePhysic() {return "物理";}
	@property const string effectTypeNameMagic() {return "魔法";}
	@property const string effectTypeNameMagicalPhysic() {return "魔法的物理";}
	@property const string effectTypeNamePhysicalMagic() {return "物理的魔法";}
	@property const string effectTypeNameNone() {return "無";}
	mixin(EnumToStringMethod!(Resist, "resistName", "resistName"));
	@property const string resistNameAvoid() {return "回避属性";}
	@property const string resistNameResist() {return "抵抗属性";}
	@property const string resistNameUnfail() {return "必中属性";}
	mixin(EnumToStringMethod!(CardTarget, "cardTargetName", "cardTargetName"));
	@property const string cardTargetNameNone() {return "対象無し";}
	@property const string cardTargetNameUser() {return "使用者";}
	@property const string cardTargetNameParty() {return "味方";}
	@property const string cardTargetNameEnemy() {return "敵方";}
	@property const string cardTargetNameBoth() {return "双方";}
	@property const string cardTargetOne() {return "一体";}
	@property const string cardTargetAll() {return "全体";}
	mixin(EnumToStringMethod!(CardVisual, "cardVisualName", "cardVisualName"));
	@property const string cardVisualNameNone() {return "視覚効果無し";}
	@property const string cardVisualNameReverse() {return "対象を反転";}
	@property const string cardVisualNameHorizontal() {return "対象を横に震動";}
	@property const string cardVisualNameVertical() {return "対象を縦に震動";}
	mixin(EnumToStringMethod!(Premium, "premiumName", "premiumName"));
	@property const string premiumNameNormal() {return "日用品 (買戻し不可/破棄可)";}
	@property const string premiumNameRare() {return "希少品 (買戻し可/破棄可)";}
	@property const string premiumNamePremium() {return "貴重品 (買戻し可/破棄不可)";}
	mixin(EnumToStringMethod!(Enhance, "enhanceName", "enhanceName"));
	@property const string enhanceNameAction() {return "行動";}
	@property const string enhanceNameAvoid() {return "回避";}
	@property const string enhanceNameResist() {return "抵抗";}
	@property const string enhanceNameDefense() {return "防御";}
	@property const string mentality() {
		return "精神状態";
	}
	mixin(EnumToStringMethod!(Mentality, "mentalityName", "mentalityName"));
	@property const string mentalityNameNormal() {return "正常";}
	@property const string mentalityNameSleep() {return "睡眠";}
	@property const string mentalityNameConfuse() {return "混乱";}
	@property const string mentalityNameOverheat() {return "激昂";}
	@property const string mentalityNameBrave() {return "勇敢";}
	@property const string mentalityNamePanic() {return "恐慌";}

	@property const string enhanceBonus() {return "%1$sボーナス";}
	@property const string statusActive() {return "※ 行動可能 = (健康 | 負傷 | 重傷 | 中毒)";}
	@property const string statusInactive() {return "※ 行動不可 = (意識不明 | 麻痺/石化 | 呪縛 | 眠り)";}
	@property const string statusAlive() {return "※ 生存 = (健康 | 負傷 | 重傷 | 中毒 | 呪縛 | 眠り)";}
	@property const string statusDead() {return "※ 非生存 = (意識不明 | 麻痺/石化)";}
	mixin(EnumToStringMethod2!(Target.M, "Target.M", "targetName", "targetName"));
	@property const string targetNameSelected() {return "選択中のメンバ";}
	@property const string targetNameUnselected() {return "選択中以外のメンバ";}
	@property const string targetNameRandom() {return "誰か一人";}
	@property const string targetNameParty() {return "パーティ全員";}
	mixin(EnumToStringMethod!(Talker, "talkerName", "talkerName"));
	@property const string talkerNameSelected() {return "[選択中]";}
	@property const string talkerNameUnselected() {return "[選択中以外]";}
	@property const string talkerNameRandom() {return "[ランダム]";}
	@property const string talkerNameCard() {return "[カード]";}
	@property const string talkerNameNarration() {return "[話者無し]";}
	@property const string talkerNameImage() {return "[画像]";}
	mixin(EnumToStringMethod!(Range, "rangeName", "rangeName"));
	@property const string rangeNameSelected() {return "現在選択中のメンバ";}
	@property const string rangeNameRandom() {return "パーティの誰か一人";}
	@property const string rangeNameParty() {return "パーティの全員";}
	@property const string rangeNameBackpack() {return "荷物袋";}
	@property const string rangeNamePartyAndBackpack() {return "全体(荷物袋含む)";}
	@property const string rangeNameField() {return "フィールド全体";}
	mixin(EnumToStringMethod!(DamageType, "damageTypeName", "damageTypeName"));
	@property const string damageTypeNameLevelRatio() {return "レベルに対応する値";}
	@property const string damageTypeNameNormal() {return "値の直接入力";}
	@property const string damageTypeNameMax() {return "最大値処理";}
	mixin(EnumToStringMethod!(Element, "elementName", "elementName"));
	@property const string elementNameAll() {return "全";}
	@property const string elementNameHealth() {return "肉体";}
	@property const string elementNameMind() {return "精神";}
	@property const string elementNameMiracle() {return "神聖";}
	@property const string elementNameMagic() {return "魔力";}
	@property const string elementNameFire() {return "炎";}
	@property const string elementNameIce() {return "冷気";}

	mixin(EnumToStringMethod!(Sex, "sexName", "sexName"));
	@property const string sexNameMale() {return "男/♂";}
	@property const string sexNameFemale() {return "女/♀";}
	@property const string sexUnknown() {return "謎/？";}
	@property const string periodUnknown() {return "不明";}
	@property const string natureUnknown() {return "その他";}

	@property const string dlgTitComment() {return "コメントの記述";}

	/// カードウィンドウ。
	@property const string mainCardWindowName() {return "カード - [ %1$s ] - %2$s";}
	@property const string mainCardWindowNameNoSummary() {return "カード";}
	@property const string mainCardTabName() {return "カード";}
	@property const string cardWindowName() {return "%1$s - [ %2$s ] - %3$s";}
	@property const string cardWindowNameNoSummary() {return "%1$s";}
	@property const string cardTabName() {return "%1$s";}
	@property const string handCardWindowName() {return "[所有カード] - %1$s.%2$s";}
	@property const string handCardTabName() {return "%1$s.%2$s";}
	@property const string importSourceWindowName() {return "カードのインポート - [ %1$s ] - %2$s";}
	@property const string importSourceTabName() {return "%1$s";}

	@property const string dlgTitAddScenario() {return "インポート元の選択";}

	@property const string cardStatus() {return "%1$s枚のカード";}
	@property const string cardStatusSelOne() {return "%1$s枚のカード (ID = %2$s)";}
	@property const string cardStatusSelMulti() {return "%1$s枚のカード (%2$s枚を選択中)";}
	@property const string handCardStatus() {return "%1$s枚のカード (有効枚数 = %2$s)";}
	@property const string handCardStatusSelOne() {return "%1$s枚のカード (有効枚数 = %2$s) (ID = %3$s)";}
	@property const string handCardStatusSelMulti() {return "%1$s枚のカード (有効枚数 = %2$s) (%3$s枚を選択中)";}

	@property const string cwCast() {return "キャスト";}
	@property const string skill() {return "特殊技能";}
	@property const string item() {return "アイテム";}
	@property const string beast() {return "召喚獣";}
	@property const string info() {return "情報";}

	@property const string noSelectImage() {return "(指定無し)";}
	@property const string noImage() {return "存在しないイメージ(パス:%1$s)";}
	@property const string noSelectBGM() {return "(指定無し)";}
	@property const string noBGM() {return "存在しないBGM(パス:%1$s)";}
	@property const string noSelectSE() {return "(指定無し)";}
	@property const string noSE() {return "存在しない効果音(パス:%1$s)";}
	@property const string noSelectArea() {return "(指定無し)";}
	@property const string noArea() {return "存在しないエリア(ID:%1$s)";}
	@property const string noSelectBattle() {return "(指定無し)";}
	@property const string noBattle() {return "存在しないバトル(ID:%1$s)";}
	@property const string noSelectPackage() {return "(指定無し)";}
	@property const string noPackage() {return "存在しないパッケージ(ID:%1$s)";}
	@property const string noSelectCast() {return "(指定無し)";}
	@property const string noCast() {return "存在しないキャストカード(ID:%1$s)";}
	@property const string noSelectSkill() {return "(指定無し)";}
	@property const string noSkill() {return "存在しない特殊技能カード(ID:%1$s)";}
	@property const string noSelectItem() {return "(指定無し)";}
	@property const string noItem() {return "存在しないアイテムカード(ID:%1$s)";}
	@property const string noSelectBeast() {return "(指定無し)";}
	@property const string noBeast() {return "存在しない召喚獣カード(ID:%1$s)";}
	@property const string noSelectInfo() {return "(指定無し)";}
	@property const string noInfo() {return "存在しない情報カード(ID:%1$s)";}
	@property const string noSelectFlag() {return "(指定無し)";}
	@property const string noFlag() {return "存在しないフラグ(パス:%1$s)";}
	@property const string noSelectStep() {return "(指定無し)";}
	@property const string noStep() {return "存在しないステップ(パス:%1$s)";}
	@property const string noSelectStart() {return "(指定無し)";}
	@property const string noStart() {return "存在しないスタートコンテント(パス:%1$s)";}
	@property const string noSelectCoupon() {return "(指定無し)";}
	@property const string noSelectCompleteStamp() {return "(指定無し)";}
	@property const string noSelectGossip() {return "(指定無し)";}

	@property const string cardId() {return "ID";}
	@property const string cardName() {return "名称";}
	@property const string cardDesc() {return "説明";}

	@property const string dlgTitNewCast() {return "キャストカードの作成";}
	@property const string dlgTitNewSkill() {return "特殊技能カードの作成";}
	@property const string dlgTitNewItem() {return "アイテムカードの作成";}
	@property const string dlgTitNewBeast() {return "召喚獣カードの作成";}
	@property const string dlgTitNewInfo() {return "情報カードの作成";}
	@property const string dlgTitCast() {return "キャストカードの設定 [ %1$s ]";}
	@property const string dlgTitSkill() {return "特殊技能カードの設定 [ %1$s ]";}
	@property const string dlgTitItem() {return "アイテムカードの設定 [ %1$s ]";}
	@property const string dlgTitBeast() {return "召喚獣カードの設定 [ %1$s ]";}
	@property const string dlgTitInfo() {return "情報カードの設定 [ %1$s ]";}

	@property const string name() {return "名前";}
	@property const string nameLimit() {return "(%2$s文字まで)";} // %1$s = 文字数、%2$s = 文字数 / 2
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
	@property const string nature() {return "素質";}
	@property const string makings() {return "特性";}
	@property const string tolerant() {return "対属性";}
	@property const string tolerantBase() {return "対カード属性";}
	@property const string tolerantElement() {return "対効果属性";}
	@property const string resistWeapon() {return "武器が効かない";}
	@property const string resistMagic() {return "魔法が効かない";}
	@property const string undead() {return "命を持たない";}
	@property const string automaton() {return "心を持たない";}
	@property const string unholy() {return "不浄な存在";}
	@property const string constructure() {return "魔法生物";}
	@property const string resistText() {return "%1$sに耐性を持つ";}
	@property const string weaknessText() {return "%1$sに弱い";}
	@property const string descResistWeapon() {return "(物理属性のカードが無効)";}
	@property const string descResistMagic() {return "(魔法属性のカードが無効)";}
	@property const string descUndead() {return "(肉体属性の効果が無効)";}
	@property const string descAutomaton() {return "(精神属性の効果が無効)";}
	@property const string descUnholy() {return "(神聖属性の効果に影響)";}
	@property const string descConstructure() {return "(魔力属性の効果に影響)";}
	@property const string descResist() {return "(%1$s属性の効果が無効)";}
	@property const string descWeakness() {return "(%1$s属性の効果に影響)";}
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
	mixin(EnumToStringMethod!(Enhance, "enhanceLiveBonusName", "enhanceLiveBonusName"));
	@property const string enhanceLiveBonusNameAction() {return "行動";}
	@property const string enhanceLiveBonusNameAvoid() {return "回避";}
	@property const string enhanceLiveBonusNameResist() {return "抵抗";}
	@property const string enhanceLiveBonusNameDefense() {return "防御";}
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
	@property const string useCountRange() {return "(0～%1$s : 0 = ∞)";}
	@property const string price() {return "価格";}
	@property const string priceAuto() {return "(参考用)";}
	@property const string useModify() {return "使用時 能力値修正";}
	@property const string haveModify() {return "所有時 能力値修正";}
	@property const string motionKind() {return "効果種別";}
	@property const string motionElement() {return "属性";}
	@property const string motionDamageType() {return "タイプ";}
	@property const string motionValue() {return "値";}
	@property const string motionBeast() {return "召喚するカード";}
	@property const string beastNone() {return "[召喚獣無し]";}
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
	@property const string keyCodes() {return "イベント発火のキーコード";}

	@property const string warningEffectTypeNone() {return "無属性のカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。";}
	@property const string warningVanishCast() {return "神聖属性以外の対象消去効果を持つカードをシナリオ外に持ち出した場合、予期せぬ動作の原因になります。";}
	@property const string warningNameLenOver() {return "名前の長さが%2$s文字を超えています。メッセージにカード名が表示された際に不具合が発生する可能性があります。";} // %1$s = 文字数、%2$s = 文字数 / 2

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

	@property const string rangeHint() {return "(%1$s～%2$s)";}
	@property const string source() {return "出典";}
	@property const string sourceScenario() {return "シナリオ名";}
	@property const string sourceAuthor() {return "シナリオ作者";}
	@property const string resetSource() {return "現在のシナリオを出典に設定";}
	@property const string diffSource() {return "出典のシナリオ名と作者名が現在のシナリオと異なるため、使用時イベントは実行されません。";}

	/// ファイルビュー。
	@property const string dirTabName() {return "ファイル";}
	@property const string dirWindowName() {return "ファイル - [ %1$s ] - %2$s";}
	@property const string dirStatus() {return "%1$s個のファイル (%2$s)";}
	@property const string dirStatusSel() {return "%1$s個のファイル (%2$s) (%3$s個を選択中)";}
	@property const string fileName() {return "ファイル名";}
	@property const string fileExt() {return "拡張子";}
	@property const string fileCount() {return "使用数";}
	@property const string errorExec() {return "%1$sの起動に失敗しました。";}
	@property const string filterDescZip() {return "ZIP アーカイブ (*.zip)";}
	@property const string filterDescCab() {return "CAB アーカイブ (*.cab)";}
	@property const string filterDescWsn() {return "シナリオファイル (*.wsn)";}
	@property const string dlgTitCreateArchive() {return "シナリオの圧縮";}
	@property const string failedCreateArchive() {return "シナリオの圧縮に失敗";}
	@property const string dlgMsgIsSaveBeforeCreateArchive() {return "「%1$s」は変更されています。保存しますか？";}

	/// エディタ設定ダイアログ。
	@property const string baseSettings() {return "基本設定";}
	@property const string reference() {return "...";}
	@property const string enginePath() {return "%1$sの場所";}
	@property const string enginePathAtten() {return "※ クラシックなシナリオのみに使用する場合は空欄にしてください";}
	@property const string dlgTitEnginePath() {return "%1$sの場所";}
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
	@property const string saveInnerImagePath() {return "クラシックなシナリオで格納イメージのファイルパスを保存する";}
	@property const string traceDirectories() {return "ファイル・" ~ DIR ~ "の変更を自動的に追跡する";}
	@property const string logicalSort() {return "数値参照型ソートを行う(1, 10, 2, 3, ... → 1, 2, 3, 10, ...)";}
	@property const string copyDesc() {return "カードをエリアに貼り付け・ドロップした時、解説もコピーする";}
	@property const string refCardsAtEditBgImage() {return "背景変更コンテントの編集を開始する際、最初からカード配置の参照を行う";}
	@property const string floatMessagePreview() {return "台詞・メッセージのプレビューをフロートさせる";}
	@property const string addNewClassicEngine() {return "未知のクラシックエンジンを見つけたら記憶する";}
	@property const string doubleIO() {return "分割読込・保存を行う(デュアルコア以上の環境で高速化)";}
	@property const string switchTabWheel() {return "マウスホイールでタブ切替を行う";}
	@property const string openTabAtRightOfCurrentTab() {return "新しいタブを現在のタブの直後に開く";}
	@property const string reconstruction() {return "シナリオごとにタブの配置を記憶する";}
	@property const string openLastScenario() {return "終了時に開いていたシナリオを次の起動時に開く";}
	@property const string soundPlayType() {return "BGM再生方式";}
	@property const string soundPlayTypeDef() {return "自動選択";}
	@property const string soundPlayTypeSDL() {return "SDL(CardWirthPy方式)";}
	@property const string soundPlayTypeMCI() {return "WinMM(CardWirth方式)";}
	@property const string soundPlayTypeApp() {return "関連付けされたアプリケーションで開く";}
	@property const string soundEffectPlayType() {return "効果音再生方式";}
	@property const string soundPlaySameBGM() {return "BGMに合わせる";}
	@property const string soundVolume() {return "音量";}
	@property const string soundVolumePer() {return "%";}
	@property const string soundCaution() {return "※ WinMM方式の時、音量は反映されません";}

	@property const string keyBind() {return "キーバインド";}
	@property const string mnemonic() {return "アクセスキー";}
	@property const string hotkey() {return "ショートカット";}

	@property const string wallpaper() {return "エディタの壁紙";}
	@property const string filterWallpaper() {return "画像ファイル (*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.ico;*.icon)";}
	@property const string dlgTitWallpaper() {return "壁紙画像の選択";}
	@property const string wallpaperStyle() {return "表示形式";}
	mixin(EnumToStringMethod!(WallpaperStyle, "wallpaperStyleName", "wallpaperStyleName"));
	@property const string wallpaperStyleNameCenter() {return "中央に表示";}
	@property const string wallpaperStyleNameTile() {return "並べて表示";}
	@property const string wallpaperStyleNameExpandFull() {return "拡大して表示";}
	@property const string wallpaperStyleNameExpand() {return "はみ出さないように拡大";}

	@property const string bgImageAndKeyCode() {return "背景とキーコード";}
	@property const string standardKeyCode() {return "標準のキーコード";}

	@property const string errorEnginePath() {return "%1$sの場所が正しくありません。";}
	@property const string errorTempPath() {return "一時展開先が正しくありません。";}
	@property const string errorBackupPath() {return "自動バックアップ先が正しくありません。";}

	@property const string sNew() {return "新規作成";}
	@property const string sAlt() {return "上書き";}
	@property const string sDel() {return "削除";}

	@property const string outerToolsAndClassicEngines() {return "外部ツールとクラシックエンジン";}
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

	@property const string templates() {return "テンプレート";}
	@property const string eventTemplatesTitle() {return "イベントテンプレートの設定";}
	@property const string eventTemplateName() {return "テンプレート名";}
	@property const string eventTemplateScript() {return "スクリプト";}

	@property const string scenarioTemplatesTitle() {return "シナリオテンプレートの設定";}
	@property const string scenarioTemplateName() {return "テンプレート名";}
	@property const string scenarioTemplatePath() {return "シナリオの場所";}
	@property const string dlgTitScTemplate() {return "テンプレートシナリオの選択";}

	@property const string exeFileDescExe() {return "実行ファイル (*.exe)";}
	@property const string exeFileDescAll() {return "すべてのファイル (*.*)";}

	@property const string classicEnginesTitle() {return "クラシックエンジンの設定";}
	@property const string classicEngineName() {return "エンジン名";}
	@property const string classicEnginePath() {return "実行ファイルパス";}
	@property const string classicEngineDataDirName() {return "データフォルダ";}
	@property const string classicEngineDataDirNameDesc() {return "クラシックエンジンのデータフォルダを選択してください。";}
	@property const string classicEngineExecute() {return "代替実行ファイル";}
	@property const string classicEngineHint1() {return "※ 代替実行ファイルを指定すると、エンジン本体の代わりに実行されます";}
	@property const string dlgTitClassicEnginePath() {return "クラシックエンジンの選択";}
	@property const string dlgTitClassicEngineExecute() {return "代替実行ファイルの選択";}

	@property const string bgImagesDefault() {return "デフォルト背景";}
	@property const string setBgImagesDefault() {return "デフォルト背景の設定...";}
	@property const string dlgTitBgImagesDefault() {return "デフォルト背景の設定";}

	@property const string systemSounds() {return "システム音声";}
	@property const string soundSaved() {return "保存完了";}
	@property const string playableSounds() {return "サウンドファイル (%1$s)";}
	@property const string dlgTitSystemSound() {return "システム音声の選択";}

	@property const string undoMax() {return "「元に戻す」回数";}
	@property const string undoMaxMainView() {return "エリア/カード/フラグ";}
	@property const string undoMaxEvent() {return "メニュー/エネミー/背景/イベント";}
	@property const string undoMaxReplace() {return "置換";}
	@property const string undoMaxEtc() {return "テキスト/その他";}

	@property const string dialogStatus() {return "台詞コンテントのステータス";}
	mixin(EnumToStringMethod!(DialogStatus, "dialogStatusName", "dialogStatusName"));
	@property const string dialogStatusNameTop() {return "最上位の台詞";}
	@property const string dialogStatusNameUnder() {return "最下位の台詞";}
	@property const string dialogStatusNameUnderWithCoupon() {return "最下位の台詞(条件クーポン設定あり)";}

	/// スクリプト関係。
	@property const string dlgTitScriptError() {return "CWXスクリプトエラー";}
	@property const string scriptError() {return "CWXスクリプトのコンパイル中にエラーが発生しました。";}
	@property const string scriptErrorOver100Error() {return "エラーが100件を超えたため、スクリプトの解析を終了します。";}
	@property const string scriptErrorInvalidToken() {return "スクリプトに使用できない文字が含まれています。";}
	@property const string scriptErrorInvalidSyntax() {return "構文が正しくありません。";}
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
	@property const string scriptErrorInvalidSif() {return "ここにsifが現れる事はできません。";}
	@property const string scriptErrorNoSifText() {return "sifのテキストが見つかりません。";}
	@property const string scriptErrorInvalidCommand() {return "命令が正しくありません。";}
	@property const string scriptErrorCanNotHaveContent() {return "このコンテントが後続コンテントを持つ事はできません。";}
	@property const string scriptErrorInvalidStr() {return "文字列が正しくありません。";}
	@property const string scriptErrorReqNumber() {return "ここに数値が必要です。";}
	@property const string scriptErrorReqID() {return "ここにIDが必要です。";}
	@property const string scriptErrorUndefinedVar() {return "存在しない変数です。";}
	@property const string scriptErrorInvalidValue() {return "値が正しくありません。";}
	@property const string scriptErrorSystem() {return "サイズが大きすぎるため、CWXスクリプトをコンパイルできません。";}

	/// メニュー。
	mixin(EnumToStringMethod!(MenuID, "menuText", "menuText"));

	@property const string menuTextNone() {return "";}

	@property const string menuTextFile() {return "ファイル";}
	@property const string menuTextEdit() {return "編集";}
	@property const string menuTextView() {return "表示";}
	@property const string menuTextTool() {return "ツール";}
	@property const string menuTextTable() {return "テーブル";}
	@property const string menuTextVariable() {return "状態変数";}
	@property const string menuTextHelp() {return "ヘルプ";}
	@property const string menuTextCard() {return "カード";}
	@property const string menuTextCardsAndBacks() {return "カードと背景";}

	@property const string menuTextDelNotUsedFile() {return "未使用のファイルを削除";}
	@property const string menuTextClosePane() {return "閉じる";}
	@property const string menuTextClosePaneExcept() {return "他のタブを閉じる";}
	@property const string menuTextClosePaneLeft() {return "左側のタブを閉じる";}
	@property const string menuTextClosePaneRight() {return "右側のタブを閉じる";}
	@property const string menuTextClosePaneAll() {return "全てのタブを閉じる";}
	@property const string menuTextNew() {return "新規作成";}
	@property const string menuTextOpen() {return "開く";}
	@property const string menuTextNewAtNewWindow() {return "新しいウィンドウで新規作成";}
	@property const string menuTextOpenAtNewWindow() {return "新しいウィンドウで開く";}
	@property const string menuTextClose() {return "閉じる";}
	@property const string menuTextCloseWin() {return "閉じる";}
	@property const string menuTextSave() {return "上書き保存";}
	@property const string menuTextSaveAs() {return "名前を付けて保存";}
	@property const string menuTextReload() {return "再読込";}
	@property const string menuTextOpenDir() {return DIR ~ "を開く";}
	@property const string menuTextOpenPlace() {return "ファイルの場所を開く";}
	@property const string menuTextSaveImage() {return "格納イメージをファイルに保存";}
	@property const string menuTextLookImages() {return "画像を一覧表示";}
	@property const string menuTextShowMainToolBar() {return "全体ツールバーを表示";}
	@property const string menuTextShowSceneToolBar() {return "シーンビューのツールバーを表示";}
	@property const string menuTextShowEventToolBar() {return "イベントビューのツールバーを表示";}
	@property const string menuTextChangeVH() {return "分割領域の縦横を切替";}
	@property const string menuTextFind() {return "検索と置換";}
	@property const string menuTextIncSearch() {return "絞り込み検索";}
	@property const string menuTextCloseIncSearch() {return "閉じる";}
	@property const string menuTextEditProp() {return "編集";}
	@property const string menuTextRefresh() {return "最新の情報に更新";}
	@property const string menuTextUndo() {return "元に戻す";}
	@property const string menuTextRedo() {return "やり直し";}
	@property const string menuTextCut() {return "切り取り";}
	@property const string menuTextCopy() {return "コピー";}
	@property const string menuTextPaste() {return "貼り付け";}
	@property const string menuTextDelete() {return "削除";}
	@property const string menuTextSelectAll() {return "すべて選択";}
	@property const string menuTextToXMLText() {return "コピーしたデータをXMLに変換";}
	@property const string menuTextTableView() {return "テーブルビュー";}
	@property const string menuTextVarView() {return "状態変数ビュー";}
	@property const string menuTextCardView() {return "カードビュー";}
	@property const string menuTextCastView() {return "キャストカードビュー";}
	@property const string menuTextSkillView() {return "特殊技能カードビュー";}
	@property const string menuTextItemView() {return "アイテムカードビュー";}
	@property const string menuTextBeastView() {return "召喚獣カードビュー";}
	@property const string menuTextInfoView() {return "情報カードビュー";}
	@property const string menuTextFileView() {return "ファイルビュー";}
	@property const string menuTextExecEngine() {return "エンジン起動";}
	@property const string menuTextExecEngineAuto() {return "自動選択";}
	@property const string menuTextExecEngineMain() {return "CardWirthPy";}
	@property const string menuTextOuterTools() {return "外部ツール";}
	@property const string menuTextSettings() {return "エディタ設定";}
	@property const string menuTextVersionInfo() {return "バージョン情報";}
	@property const string menuTextLockToolBar() {return "ツールバーを固定";}
	@property const string menuTextResetToolBar() {return "配置をリセット";}
	@property const string menuTextCopyAsText() {return "テキストとしてコピー";}
	@property const string menuTextOpenAtView() {return "ビューで開く";}
	@property const string menuTextStartToPackage() {return "このツリーをパッケージ化する";}
	@property const string menuTextConvertContent() {return "変換";}
	@property const string menuTextCGroupTerminal() {return "開始/終端";}
	@property const string menuTextCGroupStandard() {return "基本";}
	@property const string menuTextCGroupData() {return "変数操作/分岐";}
	@property const string menuTextCGroupUtility() {return "状況分岐";}
	@property const string menuTextCGroupBranch() {return "保有分岐";}
	@property const string menuTextCGroupGet() {return "取得";}
	@property const string menuTextCGroupLost() {return "喪失";}
	@property const string menuTextCGroupVisual() {return "外観操作";}
	@property const string menuTextEditSummary() {return "シナリオの設定";}
	@property const string menuTextNewArea() {return "エリアの作成";}
	@property const string menuTextNewBattle() {return "バトルの作成";}
	@property const string menuTextNewPackage() {return "パッケージの作成";}
	@property const string menuTextReNumberingAll() {return "全てのIDを1から振り直す";}
	@property const string menuTextReNumbering() {return "IDの振り直し";}
	@property const string menuTextEditScene() {return "シーンビューを開く";}
	@property const string menuTextEditEvent() {return "イベントビューを開く";}
	@property const string menuTextNewFlagDir() {return "フォルダの作成";}
	@property const string menuTextNewFlag() {return "フラグの作成";}
	@property const string menuTextNewStep() {return "ステップの作成";}
	@property const string menuTextUp() {return "上へ";}
	@property const string menuTextDown() {return "下へ";}
	@property const string menuTextShowParty() {return "パーティカードの表示";}
	@property const string menuTextShowMsg() {return "メッセージ枠の表示";}
	@property const string menuTextShowRefCards() {return "カード参照の表示";}
	@property const string menuTextFixedImage() {return "イメージの固定";}
	@property const string menuTextShowEnemyCardProp() {return "レベルとライフを表示";}
	@property const string menuTextShowCard() {return "カードの表示";}
	@property const string menuTextShowBack() {return "背景の表示";}
	@property const string menuTextNewMenuCard() {return "メニューカードの作成";}
	@property const string menuTextNewEnemyCard() {return "エネミーカードの作成";}
	@property const string menuTextNewBack() {return "背景の作成";}
	@property const string menuTextAutoArrange() {return "カードを自動的に並べる";}
	@property const string menuTextManualArrange() {return "カードの位置を自分で決定する";}
	@property const string menuTextMask() {return "透明色を使用";}
	@property const string menuTextEscape() {return "逃走の有無";}
	@property const string menuTextPosTop() {return "上に揃える";}
	@property const string menuTextPosBottom() {return "下に揃える";}
	@property const string menuTextPosLeft() {return "左に揃える";}
	@property const string menuTextPosRight() {return "右に揃える";}
	@property const string menuTextPosEven() {return "等間隔に並べる";}
	@property const string menuTextScaleMin() {return "最小のカードスケール";}
	@property const string menuTextScaleMiddle() {return "標準のカードスケール";}
	@property const string menuTextScaleMax() {return "最大のカードスケール";}
	@property const string menuTextScaleBig() {return "大きく揃える";}
	@property const string menuTextScaleSmall() {return "小さく揃える";}
	@property const string menuTextStopBGM() {return "%1$sの再生を停止";}
	@property const string menuTextPlayBGM() {return "再生";}
	@property const string menuTextKeyCodeTiming() {return "キーコード発火タイミング";}
	@property const string menuTextKeyCodeTimingUse() {return "使用";}
	@property const string menuTextKeyCodeTimingSuccess() {return "成功";}
	@property const string menuTextKeyCodeTimingFailure() {return "失敗";}
	@property const string menuTextAddRangeOfRound() {return "複数のラウンドを追加";}
	@property const string menuTextOpenAtTableView() {return "テーブルビューで開く";}
	@property const string menuTextOpenAtVarView() {return "状態変数ビューで開く";}
	@property const string menuTextOpenAtCardView() {return "カードビューで開く";}
	@property const string menuTextOpenAtFileView() {return "ファイルビューで開く";}
	@property const string menuTextOpenAtEventView() {return "イベントビューで開く";}
	@property const string menuTextComment() {return "コメントを記述";}
	@property const string menuTextShowCardProp() {return "レベルとライフを表示";}
	@property const string menuTextShowCardImage() {return "カード表示";}
	@property const string menuTextShowCardDetail() {return "詳細表示";}
	@property const string menuTextOpenImportSource() {return "外部シナリオから追加";}
	@property const string menuTextNewCast() {return "キャストカードの作成";}
	@property const string menuTextNewSkill() {return "スキルカードの作成";}
	@property const string menuTextNewItem() {return "アイテムカードの作成";}
	@property const string menuTextNewBeast() {return "召喚獣カードの作成";}
	@property const string menuTextNewInfo() {return "情報カードの作成";}
	@property const string menuTextImport() {return "シナリオに追加";}
	@property const string menuTextOpenHand() {return "所有カード";}
	@property const string menuTextEditEventAtTimeOfUsing() {return "使用時イベントの設定";}
	@property const string menuTextPlaySE() {return "再生";}
	@property const string menuTextStopSE() {return "停止";}
	@property const string menuTextNewDir() {return "新規" ~ DIR;}
	@property const string menuTextCopyFilePath() {return "素材のパスをコピー";}
	@property const string menuTextReplFilePath() {return "素材の差替え";}
	@property const string menuTextCreateArchive() {return "シナリオを圧縮";}
	@property const string menuTextToScript() {return "スクリプトに変換してコピー";}
	@property const string menuTextToScriptAll() {return "全てをスクリプトに変換してコピー";}
	@property const string menuTextEvTemplates() {return "テンプレートから作成";}

	@property const string bgm() {return "BGM";}
	@property const string newEvent() {return "イベントの作成";}
	@property const string newIgnition() {return "イベント発火条件の作成";}
	@property const string expandTree() {return "全コンテントツリーを開く";}
	@property const string foldTree() {return "全コンテントツリーを閉じる";}
}
