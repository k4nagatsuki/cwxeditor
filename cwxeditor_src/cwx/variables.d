
module cwx.variables;

import cwx.xml;
import cwx.structs;

import cwx.settings;

class FlexEtcProps : Properties {
	mixin Property!("languageDir", string, "lang", true);
	mixin Property!("languageFile", string, "");
	mixin Property!("useSystemLanguage", bool, true);

	mixin Property!("singleWindow", bool, true);
	mixin Property!("toolsLock", bool, false);
	mixin Property!("toolsOrder", int[], []);
	mixin Property!("toolsWrapIndices", int[], [8]);
	mixin Property!("comboVisibleItemCount", int, 20, true);
	mixin Property!("directorySashL", int, 2);
	mixin Property!("directorySashR", int, 5);
	mixin Property!("directorySashV", bool, false);
	mixin Property!("filesSortColumn", int, 1);
	mixin Property!("filesSortDirection", int, SortDir.Up);
	mixin Property!("fileNameColumn", int, 300);
	mixin Property!("fileExtColumn", int, 60);
	mixin Property!("fileCountColumn", int, 60);
	mixin Property!("areaIdColumn", int, 50);
	mixin Property!("areaNameColumn", int, 400);
	mixin Property!("areaCountColumn", int, 60);
	mixin Property!("summaryParamSashL", int, 2);
	mixin Property!("summaryParamSashR", int, 1);
	mixin Property!("rCouponsStartAreaSashL", int, 1);
	mixin Property!("rCouponsStartAreaSashR", int, 1);
	mixin Property!("areaViewL", int, 1);
	mixin Property!("areaViewR", int, 4);
	mixin Property!("partyCardAlpha", int, 176, true);
	mixin Property!("viewPartyCardsArea", bool, true);
	mixin Property!("viewPartyCardsBattle", bool, true);
	mixin Property!("viewEnemyCardDebug", bool, false);
	mixin Property!("viewPartyCardsEvent", bool, true);
	mixin Property!("messageAlpha", int, 176, true);
	mixin Property!("viewMessageArea", bool, false);
	mixin Property!("viewMessageBattle", bool, false);
	mixin Property!("viewMessageEvent", bool, false);
	mixin Property!("viewReferenceCards", bool, true);
	mixin Property!("fixedImagesArea", bool, false);
	mixin Property!("fixedImagesBattle", bool, false);
	mixin Property!("fixedImagesEvent", bool, false);
	mixin Property!("viewCards", bool, true);
	mixin Property!("viewBgImages", bool, true);
	mixin Property!("areaSashT", int, 5);
	mixin Property!("areaSashB", int, 4);
	mixin Property!("flagSashL", int, 3);
	mixin Property!("flagSashR", int, 7);
	mixin Property!("flagSashV", bool, false);
	mixin Property!("flagsWidth", int, 150, true);
	mixin Property!("flagsHeight", int, 200, true);
	mixin Property!("menuCardSashL", int, 5);
	mixin Property!("menuCardSashR", int, 3);
	mixin Property!("enemyCardSashL", int, 3);
	mixin Property!("enemyCardSashR", int, 5);
	mixin Property!("backSashL", int, 5);
	mixin Property!("backSashR", int, 3);
	mixin Property!("bgImageSampleWidth", int, 150, true);
	mixin Property!("bgImageSampleHeight", int, 150, true);
	mixin Property!("cardIdColumn", int, 50);
	mixin Property!("cardNameColumn", int, 100);
	mixin Property!("cardDescriptionColumn", int, 280);
	mixin Property!("cardCountColumn", int, 60);
	mixin Property!("couponWidth", int, 150, true);
	mixin Property!("couponValueColumn", int, 40, true);
	mixin Property!("idColumn", int, 50);
	mixin Property!("nameTableWidth", int, 250, true);
	mixin Property!("nameTableHeight", int, 250, true);
	mixin Property!("flagEventSashL", int, 3);
	mixin Property!("flagEventSashR", int, 2);
	mixin Property!("nameWidth", int, 300, true);
	mixin Property!("firesWidth", int, 120, true);
	mixin Property!("flagNameWidth", int, 150, true);
	mixin Property!("flagInitWidth", int, 50, true);
	mixin Property!("flagValueWidth", int, 50, true);
	mixin Property!("flagNameColumn", int, 190);
	mixin Property!("flagInitColumn", int, 90);
	mixin Property!("flagCountColumn", int, 60);
	mixin Property!("filesWidth", int, 150, true);
	mixin Property!("filesHeight", int, 150, true);
	mixin Property!("talkersWidth", int, 100, true);
	mixin Property!("motionsWidth", int, 150, true);
	mixin Property!("incrementalSearchBoxWidth", int, 100, true);
	mixin Property!("showMainToolBar", bool, true);
	mixin Property!("showSceneToolBar", bool, true);
	mixin Property!("showEventToolBar", bool, true);

	mixin Property!("partyMax", uint, 6, true);
	mixin Property!("cardScaleMax", int, 300);
	mixin Property!("cardScaleMin", int, 50);
	mixin Property!("posLeftMax", uint, 9999, true);
	mixin Property!("posTopMax", uint, 9999, true);
	mixin Property!("backWidthMax", uint, 9999, true);
	mixin Property!("backHeightMax", uint, 9999, true);
	mixin Property!("castLevelMax", uint, 99, true);
	mixin Property!("lifeMax", uint, 999, true);
	mixin Property!("couponValueMax", uint, 999, true);
	mixin Property!("physicalMax", uint, 15, true);
	mixin Property!("mentalMax", uint, 4, true);
	mixin Property!("skillLevelMax", uint, 999, true);
	mixin Property!("useCountMax", uint, 999, true);
	mixin Property!("priceMax", uint, 999999, true);
	mixin Property!("enhanceMax", uint, 10, true);
	mixin Property!("roundMax", uint, 999, true);
	mixin Property!("paralyzeMax", uint, 40, true);
	mixin Property!("poisonMax", uint, 40, true);
	mixin Property!("cardNumberMax", uint, 99, true);
	mixin Property!("waitMax", uint, 1000, true);
	mixin Property!("uValueMax", uint, 999, true);

	mixin Property!("imageListWidth", int, 380);
	mixin Property!("imageListHeight", int, 300);
	mixin Property!("cardLife", bool, false);
	mixin Property!("cardDetails", bool, false);
	mixin Property!("cardsMarginX", int, 5, true);
	mixin Property!("cardsSpaceX", int, 8, true);
	mixin Property!("cardsMarginY", int, 5, true);
	mixin Property!("cardsSpaceY", int, 8, true);
	mixin Property!("cardsDefaultWrap", int, 4, true);
	mixin Property!("seKeyCodeSashL", int, 4);
	mixin Property!("seKeyCodeSashR", int, 7);
	mixin Property!("talkSashL", int, 1);
	mixin Property!("talkSashR", int, 1);
	mixin Property!("msgBackR", int, 0, true);
	mixin Property!("msgBackG", int, 0, true);
	mixin Property!("msgBackB", int, 128, true);
	mixin Property!("msgForeR", int, 255, true);
	mixin Property!("msgForeG", int, 255, true);
	mixin Property!("msgForeB", int, 255, true);
	mixin Property!("textTabs", int, 4, true);

	mixin Property!("contentsOrder", int[], []);
	mixin Property!("contentsLock", bool, false);
	mixin Property!("contentsWrapIndices", int[], [4, 6, 8]);
	mixin Property!("contentsAutoOpen", bool, true);
	mixin Property!("contentsContinue", bool, false);
	mixin Property!("contentsFloat", bool, false);
	mixin Property!("contentsAutoHide", bool, false);
	mixin Property!("showContentsBoxHeightWhenNoToolBar", int, 8, true);
	mixin Property!("smoothingCard", bool, true);
	mixin Property!("ignorePathsWidth", int, 50, true);
	mixin Property!("menuSettingsHeight", int, 150, true);
	mixin Property!("settingListWidth", int, 150, true);
	mixin Property!("settingListHeight", int, 150, true);

	mixin Property!("wallpaper", string, "");
	mixin Property!("wallpaperStyle", int, WallpaperStyle.Tile);
	mixin Property!("wallColorR", int, 0);
	mixin Property!("wallColorG", int, 0);
	mixin Property!("wallColorB", int, 128);
	mixin Property!("bgImagesDefault", BgImageS[], [BgImageS("MapOfWirth", 0, 0, 632, 420, false)]);
	mixin Property!("bgImageSettingsSashL", int, 1);
	mixin Property!("bgImageSettingsSashR", int, 1);
	mixin Property!("bgImageKeyCodeSashL", int, 2);
	mixin Property!("bgImageKeyCodeSashR", int, 1);
	mixin Property!("outerToolsSashL", int, 1);
	mixin Property!("outerToolsSashR", int, 2);
	mixin Property!("outerToolShortcutSashL", int, 1);
	mixin Property!("outerToolShortcutSashR", int, 3);
	mixin Property!("classicEnginesSashL", int, 1);
	mixin Property!("classicEnginesSashR", int, 2);
	mixin Property!("classicEngineShortcutSashL", int, 1);
	mixin Property!("classicEngineShortcutSashR", int, 3);
	mixin Property!("eventTemplatesSashL", int, 1);
	mixin Property!("eventTemplatesSashR", int, 2);
	mixin Property!("scenarioTemplatesSashL", int, 1);
	mixin Property!("scenarioTemplatesSashR", int, 2);
	mixin Property!("templatesSashL", int, 1);
	mixin Property!("templatesSashR", int, 1);
	mixin Property!("toolsClassicEnginesSashL", int, 1);
	mixin Property!("toolsClassicEnginesSashR", int, 1);
	mixin Property!("keyCodeWidth", int, 100, true);
	mixin Property!("scenarioPath", string, "");
	mixin Property!("tempPath", string, "temp");
	mixin Property!("backupPath", string, "backup");
	mixin Property!("backupEnabled", bool, true);
	mixin Property!("backupInterval", int, 15);
	mixin Property!("backupCount", int, 10);
	mixin Property!("ignoreMenuSashL", int, 2);
	mixin Property!("ignoreMenuSashR", int, 1);

	mixin Property!("openHistories", string[], []);
	mixin Property!("historyMax", int, 9);
	mixin Property!("historySnipLength", int, 30);
	mixin Property!("lastScenario", string, "");
	mixin Property!("searchResultTableWidth", int, 400, true);
	mixin Property!("searchResultTableHeight", int, 200, true);
	version (Windows) {
		mixin Property!("engine", string, "CardWirthPy.exe", true);
		mixin Property!("enginePath", string, "CardWirthPy.exe");
	} else {
		mixin Property!("engine", string, "CardWirthPy", true);
		mixin Property!("enginePath", string, "CardWirthPy");
	}
	mixin Property!("defaultSkin", string, "MedievalFantasy", true);
	mixin Property!("defaultAuthor", string, "");
	mixin Property!("canCreateClassic", bool, false);

	mixin Property!("expandXMLs", bool, false);
	mixin Property!("xmlCopy", bool, false);
	mixin Property!("saveInnerImagePath", bool, false);
	mixin Property!("traceDirectories", bool, true);
	mixin Property!("logicalSort", bool, true);
	mixin Property!("copyDesc", bool, false);
	mixin Property!("refCardsAtEditBgImage", bool, true);
	mixin Property!("showImagePreview", bool, true);
	mixin Property!("switchTabWheel", bool, true);
	mixin Property!("openTabAtRightOfCurrentTab", bool, true);

	mixin Property!("soundPlayType", int, 0);
	mixin Property!("soundEffectPlayType", int, -1);
	mixin Property!("bgmVolume", int, 100);
	mixin Property!("seVolume", int, 100);

	mixin Property!("searchPlan", int, 0);
	mixin Property!("searchIDKind", int, 0);
	mixin Property!("searchHistories", string[], []);
	mixin Property!("replaceHistories", string[], []);
	mixin Property!("searchHistoryMax", int, 50);
	mixin Property!("replaceRangeSashL", int, 3);
	mixin Property!("replaceRangeSashR", int, 1);
	mixin Property!("replaceTextNotIgnoreCase", bool, false);
	mixin Property!("replaceTextRegExp", bool, false);
	mixin Property!("replaceTextWildcard", bool, false);

	mixin Property!("replaceTextSummary", bool, true);
	mixin Property!("replaceTextMessage", bool, true);
	mixin Property!("replaceTextCardName", bool, true);
	mixin Property!("replaceTextCardDescription", bool, true);
	mixin Property!("replaceTextEventText", bool, true);
	mixin Property!("replaceTextStart", bool, true);
	mixin Property!("replaceTextFlagAndStep", bool, true);
	mixin Property!("replaceTextCoupon", bool, true);
	mixin Property!("replaceTextGossip", bool, true);
	mixin Property!("replaceTextEndScenario", bool, true);
	mixin Property!("replaceTextAreaName", bool, true);
	mixin Property!("replaceTextKeyCode", bool, true);
	mixin Property!("replaceTextFile", bool, false);
	mixin Property!("replaceTextComment", bool, true);
	mixin Property!("replaceTextJptx", bool, false);

	mixin Property!("replaceNameCoupon", bool, true);
	mixin Property!("replaceNameGossip", bool, true);
	mixin Property!("replaceNameEndScenario", bool, true);
	mixin Property!("replaceNameKeyCode", bool, true);

	mixin Property!("searchContentsStart", bool, false);
	mixin Property!("searchContentsStartBattle", bool, false);
	mixin Property!("searchContentsEnd", bool, false);
	mixin Property!("searchContentsEndBadEnd", bool, false);
	mixin Property!("searchContentsChangeArea", bool, false);
	mixin Property!("searchContentsChangeBgImage", bool, false);
	mixin Property!("searchContentsEffect", bool, false);
	mixin Property!("searchContentsEffectBreak", bool, false);
	mixin Property!("searchContentsLinkStart", bool, false);
	mixin Property!("searchContentsLinkPackage", bool, false);
	mixin Property!("searchContentsTalkMessage", bool, false);
	mixin Property!("searchContentsTalkDialog", bool, false);
	mixin Property!("searchContentsPlayBgm", bool, false);
	mixin Property!("searchContentsPlaySound", bool, false);
	mixin Property!("searchContentsWait", bool, false);
	mixin Property!("searchContentsElapseTime", bool, false);
	mixin Property!("searchContentsCallStart", bool, false);
	mixin Property!("searchContentsCallPackage", bool, false);
	mixin Property!("searchContentsBranchFlag", bool, false);
	mixin Property!("searchContentsBranchMultiStep", bool, false);
	mixin Property!("searchContentsBranchStep", bool, false);
	mixin Property!("searchContentsBranchSelect", bool, false);
	mixin Property!("searchContentsBranchAbility", bool, false);
	mixin Property!("searchContentsBranchRandom", bool, false);
	mixin Property!("searchContentsBranchLevel", bool, false);
	mixin Property!("searchContentsBranchStatus", bool, false);
	mixin Property!("searchContentsBranchPartyNumber", bool, false);
	mixin Property!("searchContentsBranchArea", bool, false);
	mixin Property!("searchContentsBranchBattle", bool, false);
	mixin Property!("searchContentsBranchIsBattle", bool, false);
	mixin Property!("searchContentsBranchCast", bool, false);
	mixin Property!("searchContentsBranchItem", bool, false);
	mixin Property!("searchContentsBranchSkill", bool, false);
	mixin Property!("searchContentsBranchInfo", bool, false);
	mixin Property!("searchContentsBranchBeast", bool, false);
	mixin Property!("searchContentsBranchMoney", bool, false);
	mixin Property!("searchContentsBranchCoupon", bool, false);
	mixin Property!("searchContentsBranchCompleteStamp", bool, false);
	mixin Property!("searchContentsBranchGossip", bool, false);
	mixin Property!("searchContentsSetFlag", bool, false);
	mixin Property!("searchContentsSetStep", bool, false);
	mixin Property!("searchContentsSetStepUp", bool, false);
	mixin Property!("searchContentsSetStepDown", bool, false);
	mixin Property!("searchContentsReverseFlag", bool, false);
	mixin Property!("searchContentsCheckFlag", bool, false);
	mixin Property!("searchContentsGetCast", bool, false);
	mixin Property!("searchContentsGetItem", bool, false);
	mixin Property!("searchContentsGetSkill", bool, false);
	mixin Property!("searchContentsGetInfo", bool, false);
	mixin Property!("searchContentsGetBeast", bool, false);
	mixin Property!("searchContentsGetMoney", bool, false);
	mixin Property!("searchContentsGetCoupon", bool, false);
	mixin Property!("searchContentsGetCompleteStamp", bool, false);
	mixin Property!("searchContentsGetGossip", bool, false);
	mixin Property!("searchContentsLoseCast", bool, false);
	mixin Property!("searchContentsLoseItem", bool, false);
	mixin Property!("searchContentsLoseSkill", bool, false);
	mixin Property!("searchContentsLoseInfo", bool, false);
	mixin Property!("searchContentsLoseBeast", bool, false);
	mixin Property!("searchContentsLoseMoney", bool, false);
	mixin Property!("searchContentsLoseCoupon", bool, false);
	mixin Property!("searchContentsLoseCompleteStamp", bool, false);
	mixin Property!("searchContentsLoseGossip", bool, false);
	mixin Property!("searchContentsShowParty", bool, false);
	mixin Property!("searchContentsHideParty", bool, false);
	mixin Property!("searchContentsRedisplay", bool, false);

	mixin Property!("searchUnusedFlag", bool, true);
	mixin Property!("searchUnusedStep", bool, true);
	mixin Property!("searchUnusedArea", bool, true);
	mixin Property!("searchUnusedBattle", bool, true);
	mixin Property!("searchUnusedPackage", bool, true);
	mixin Property!("searchUnusedCast", bool, true);
	mixin Property!("searchUnusedSkill", bool, true);
	mixin Property!("searchUnusedItem", bool, true);
	mixin Property!("searchUnusedBeast", bool, true);
	mixin Property!("searchUnusedInfo", bool, true);
	mixin Property!("searchUnusedStart", bool, true);
	mixin Property!("searchUnusedPath", bool, true);
	mixin Property!("searchOpenDialog", bool, false);

	mixin Property!("incrementalSearchType", int, 0);

	mixin Property!("flagTrues", string[], ["TRUE", "表示", "ON", "有", "可", "済み"], true);
	mixin Property!("flagFalses", string[], ["FALSE", "非表示", "OFF", "無", "不可", "まだ"], true);

	mixin Property!("bgImageSettings", BgImageSetting[], [
		BgImageSetting("冒険者の宿", 116, 15, 400, 260, false),
		BgImageSetting("冒険者の宿(フレーム)", 116, 14, 400, 261, true),
		BgImageSetting("フル", 0, 0, 632, 420, false),
		BgImageSetting("フル(マスク)", 0, 0, 632, 420, true),
		BgImageSetting("カード", 0, 0, 74, 94, true),
		BgImageSetting("冒険者カード", 0, 0, 95, 130, false),
		BgImageSetting("ゲームオーバー", 116, 55, 400, 260, false),
		BgImageSetting("Qubes 地面", 160, 80, 320, 160, true),
		BgImageSetting("Qubes 左後", 80, 0, 240, 160, true),
		BgImageSetting("Qubes 右後", 320, 0, 240, 160, true),
		BgImageSetting("Qubes 左前", 80, 80, 240, 200, true),
		BgImageSetting("Qubes 右前", 320, 80, 240, 200, true)
	]);
	mixin Property!("standardCoupons", string[], [
		"：Ｒ", "＿１", "＿２", "＿３", "＿４", "＿５", "＿６", "＿消滅予約", "：レベル補正中"
	], true);
	mixin Property!("standardKeyCodes", string[], [
		"攻撃",
		"治療",
		"魔法",
		"召喚獣",
		"気功法",
		"遠距離攻撃",
		"神聖な攻撃",
		"魔法による攻撃",
		"炎による攻撃",
		"冷気による攻撃",
		"暗殺",
		"精神を回復",
		"中毒を解除",
		"麻痺を解除",
		"眠り",
		"麻痺",
		"中毒",
		"呪縛",
		"沈黙",
		"召喚",
		"鑑定",
		"解錠",
		"呪縛を解除",
		"沈黙を解除",
		"魔法を解除",
		"",
		"魔力感知",
		"生命感知",
		"魔法の鍵",
		"解読",
		"石化",
		"石化を解除",
		"蝙蝠変化",
		"明かり",
		"目つぶし",
		"魅了",
		"透明",
		"召喚獣を付与",
		"暴露",
		"即死",
		"一撃必殺",
		"対象消去",
		"恐慌",
		"不浄な攻撃",
		"呪い",
		"飛行",
		"浮遊",
		"灯火",
		"",
		"フェイント",
		"防御",
		"逃走",
		"カード交換",
		"ペナルティ",
		"リサイクル"
		"",
		"一撃",
		"守備",
	]);
	version (Windows) {
		mixin Property!("outerTools", OuterTool[], [
			OuterTool("メモ帳", "notepad $F", "", "", ""),
			OuterTool("ペイント", "mspaint $F", "", "", "")
		]);
	} else {
		mixin Property!("outerTools", OuterTool[], []);
	}
	version (Windows) {
		mixin Property!("ignorePaths", string[], [".*", "Thumbs.db"]);
	} else {
		mixin Property!("ignorePaths", string[], [".*"]);
	}

	mixin Property!("selectedArchiveFilter", string, "zip");

	mixin Property!("classicEngines", ClassicEngine[], []);
	mixin Property!("addNewClassicEngine", bool, true);

	mixin Property!("drawCountOfUseOfStart", bool, true);
	mixin Property!("drawContentTreeLine", bool, true);
	mixin Property!("commentBoxDistance", int, 50, true);

	mixin Property!("doubleIO", bool, true);
	mixin Property!("reconstruction", bool, true);
	mixin Property!("openLastScenario", bool, true);
	mixin Property!("imageCache", bool, true);

	mixin Property!("savedSound", string, "");

	mixin Property!("bindCardViews", bool, false);
	mixin Property!("bindSceneWithEvent", bool, false);

	mixin Property!("previewAlpha", int, 255, true);
	mixin Property!("previewMaxWidth", int, 150, true);
	mixin Property!("previewMaxHeight", int, 150, true);

	mixin Property!("undoMaxMainView", int, 1024);
	mixin Property!("undoMaxEvent", int, 1024);
	mixin Property!("undoMaxEtc", int, 1024);
	mixin Property!("undoMaxLimit", int, short.max);
	mixin Property!("undoMaxReplace", int, 16);

	mixin Property!("dialogStatus", int, DialogStatus.Top);

	mixin Property!("showInputGuide", bool, true);

	mixin Property!("showSummaryPreview", bool, true);

	mixin Property!("floatMessagePreview", bool, false);
	mixin Property!("showDialogPreview", bool, true);
	mixin Property!("showMessagePreview", bool, true);
	mixin Property!("messageVarKindColumn", int, 200);
	mixin Property!("messageVarValueColumn", int, 250);
	mixin Property!("messageVarTableHeight", int, 300, true);
	mixin Property!("messageVarSelected", string, "[選択中----14]");
	mixin Property!("messageVarUnselected", string, "[選択外----14]");
	mixin Property!("messageVarRandom", string, "[ランダム--14]");
	mixin Property!("messageVarCard", string, "[カード--12]");
	mixin Property!("messageVarRef", string, "[話者------14]");
	mixin Property!("messageVarTeam", string, "[チーム名------------------30]");
	mixin Property!("messageVarYado", string, "[宿屋名--------18]");

	mixin Property!("scenarioTemplates", ScTemplate[], []);
	mixin Property!("defaultScenarioTemplate", string, "");
	mixin Property!("defaultIsTemplate", bool, false);

	mixin Property!("eventTemplates", EvTemplate[], []);

	mixin Property!("archivePath", string, "");

	mixin XMLFuncs!(FlexEtcProps);
}
